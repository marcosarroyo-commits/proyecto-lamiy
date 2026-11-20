import 'package:flutter/material.dart';
import 'package:lumina_app/domain/app_theme.dart';
import 'package:lumina_app/domain/fechas.dart';
import 'package:lumina_app/domain/formatos.dart';
import 'package:lumina_app/models/comision/comision.dart';
import 'package:lumina_app/models/liquidacion/liquidacion.dart';
import 'package:lumina_app/models/profesional/profesional.dart';
import 'package:lumina_app/routes/app_routes.dart';
import 'package:lumina_app/screens/cierres/detalle_cierre_screen.dart';
import 'package:lumina_app/screens/comisiones/detalle_comision_screen.dart';
import 'package:lumina_app/services/local/catalogo_cache.dart';
import 'package:lumina_app/services/remote/api_service.dart';
import 'package:lumina_app/services/remote/comision_service.dart';
import 'package:lumina_app/services/remote/liquidacion_service.dart';
import 'package:lumina_app/theme/colores_app.dart';
import 'package:lumina_app/widgets/encabezado_modulo.dart';
import 'package:lumina_app/widgets/estados_vista.dart';
import 'package:lumina_app/widgets/filtros.dart';
import 'package:lumina_app/widgets/marco_pantalla.dart';
import 'package:lumina_app/widgets/selector_opciones.dart';
import 'package:lumina_app/widgets/tarjeta_base.dart';
import 'package:lumina_app/widgets/tarjeta_metrica.dart';

/// Consulta de comisiones: elegir cierre, filtrar por profesional,
/// ver el consolidado y abrir el detalle.
class ListadoComisionesScreen extends StatefulWidget {
  const ListadoComisionesScreen({super.key, this.cierreInicial, this.profesionalInicial});

  final Liquidacion? cierreInicial;
  final Profesional? profesionalInicial;

  @override
  State<ListadoComisionesScreen> createState() => _ListadoComisionesScreenState();
}

class _ListadoComisionesScreenState extends State<ListadoComisionesScreen> {
  final ComisionService _servicio = ComisionService();
  List<Liquidacion> _cierres = const [];
  List<Profesional> _profesionales = const [];
  List<Comision> _comisiones = const [];
  late Liquidacion? _cierre = widget.cierreInicial;
  late Profesional? _profesional = widget.profesionalInicial;
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _iniciar();
  }

  Future<void> _iniciar() async {
    try {
      _cierres = await LiquidacionService().todas();
      _profesionales = await CatalogoCache.profesionales();
    } catch (_) {}
    // Por defecto, el cierre más reciente (si no se filtra por profesional).
    if (_cierre == null && _profesional == null && _cierres.isNotEmpty) _cierre = _cierres.first;
    await _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final lista = await _servicio.listar(cierreId: _cierre?.id, profesionalId: _profesional?.id);
      if (mounted) setState(() => _comisiones = lista);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _elegirCierre() async {
    final opcion = await elegirOpcion<Liquidacion?>(
      context,
      titulo: 'Seleccionar cierre',
      seleccionado: _cierre,
      opciones: [
        const OpcionFiltro(null, 'Todos los cierres'),
        for (final l in _cierres)
          OpcionFiltro(l, '${l.codigo}  ·  ${Fechas.corta(l.fechaInicio)} – ${Fechas.corta(l.fechaFin)}'),
      ],
    );
    if (opcion == null) return;
    setState(() => _cierre = opcion.valor);
    _cargar();
  }

  Future<void> _elegirProfesional() async {
    final opcion = await elegirOpcion<Profesional?>(
      context,
      titulo: 'Filtrar por profesional',
      seleccionado: _profesional,
      opciones: [
        const OpcionFiltro(null, 'Todos los profesionales'),
        for (final p in _profesionales) OpcionFiltro(p, p.nombreCompleto),
      ],
    );
    if (opcion == null) return;
    setState(() => _profesional = opcion.valor);
    _cargar();
  }

  Liquidacion? _cierreDe(Comision c) {
    for (final l in _cierres) {
      if (l.id == c.cierreId) return l;
    }
    return _cierre;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    final base = _comisiones.fold<double>(0, (a, x) => a + (x.base ?? 0));
    final valor = _comisiones.fold<double>(0, (a, x) => a + (x.valor ?? 0));
    final servicios = _comisiones.fold<int>(0, (a, x) => a + (x.cantidadServicios ?? 0));

    Widget cuerpo;
    if (_cargando && _comisiones.isEmpty) {
      cuerpo = const EstadoCarga(mensaje: 'Consultando comisiones...');
    } else if (_error != null) {
      cuerpo = EstadoError(mensaje: _error!, alReintentar: _cargar);
    } else {
      cuerpo = RefreshIndicator(
        onRefresh: _cargar,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          children: [
            TarjetaBase(
              colorFondo: c.badgeFondo,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Consolidado', style: AppTheme.cormorant(size: 17, color: c.primarioOscuro)),
                  Text(
                    _cierre == null
                        ? 'Todas las comisiones registradas'
                        : 'Cierre ${Fechas.corta(_cierre!.fechaInicio)} – ${Fechas.corta(_cierre!.fechaFin)}',
                    style: AppTheme.manrope(size: 12, color: c.textoSutil),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: TarjetaMetrica(icono: Icons.payments_outlined, valor: Formato.moneda(base), titulo: 'Base')),
              const SizedBox(width: 8),
              Expanded(child: TarjetaMetrica(icono: Icons.percent, valor: Formato.moneda(valor), titulo: 'Comisionado')),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: TarjetaMetrica(icono: Icons.content_cut_outlined, valor: '$servicios', titulo: 'Servicios')),
              const SizedBox(width: 8),
              Expanded(
                child: TarjetaMetrica(
                  icono: Icons.groups_outlined,
                  valor: '${_comisiones.map((x) => x.profesionalId).toSet().length}',
                  titulo: 'Profesionales',
                ),
              ),
            ]),
            const SizedBox(height: 18),
            Text('Detalle por profesional', style: AppTheme.cormorant(size: 17, color: c.primarioOscuro)),
            const SizedBox(height: 8),
            if (_comisiones.isEmpty)
              const EstadoVacio(
                icono: Icons.percent,
                titulo: 'Sin comisiones',
                mensaje: 'No hay comisiones para los filtros seleccionados.',
              ),
            for (final comision in _comisiones)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: TarjetaComision(
                  comision: comision,
                  alTocar: () => abrir(context, DetalleComisionScreen(comision: comision, cierre: _cierreDe(comision))),
                ),
              ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: c.fondo,
      appBar: const EncabezadoModulo(titulo: 'Comisiones', subtitulo: 'Consolidado y detalle por profesional'),
      body: ContenidoCentrado(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    PildoraFiltro(
                      texto: _cierre?.codigo ?? 'Todos los cierres',
                      activa: _cierre != null,
                      icono: Icons.receipt_long_outlined,
                      alTocar: _elegirCierre,
                    ),
                    const SizedBox(width: 8),
                    PildoraFiltro(
                      texto: _profesional?.nombreCorto ?? 'Profesional',
                      activa: _profesional != null,
                      icono: Icons.face_retouching_natural,
                      alTocar: _elegirProfesional,
                      alQuitar: _profesional == null
                          ? null
                          : () {
                              setState(() => _profesional = null);
                              _cargar();
                            },
                    ),
                  ],
                ),
              ),
            ),
            Expanded(child: cuerpo),
          ],
        ),
      ),
    );
  }
}
