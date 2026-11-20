import 'package:flutter/material.dart';
import 'package:lumina_app/domain/app_theme.dart';
import 'package:lumina_app/domain/fechas.dart';
import 'package:lumina_app/domain/formatos.dart';
import 'package:lumina_app/models/comision/comision.dart';
import 'package:lumina_app/models/profesional/profesional.dart';
import 'package:lumina_app/models/reserva/reserva.dart';
import 'package:lumina_app/routes/app_routes.dart';
import 'package:lumina_app/screens/comisiones/detalle_comision_screen.dart';
import 'package:lumina_app/screens/reservas/detalle_reserva_screen.dart';
import 'package:lumina_app/services/local/gestor_sesion.dart';
import 'package:lumina_app/services/remote/api_service.dart';
import 'package:lumina_app/services/remote/comision_service.dart';
import 'package:lumina_app/services/remote/profesional_service.dart';
import 'package:lumina_app/services/remote/reserva_service.dart';
import 'package:lumina_app/theme/colores_app.dart';
import 'package:lumina_app/widgets/encabezado_modulo.dart';
import 'package:lumina_app/widgets/estados_vista.dart';
import 'package:lumina_app/widgets/filtros.dart';
import 'package:lumina_app/widgets/marco_pantalla.dart';
import 'package:lumina_app/widgets/tarjeta_base.dart';
import 'package:lumina_app/widgets/tarjeta_metrica.dart';
import 'package:lumina_app/widgets/tarjeta_reserva.dart';



class MisServiciosScreen extends StatefulWidget {
  const MisServiciosScreen({super.key});

  @override
  State<MisServiciosScreen> createState() => _MisServiciosScreenState();
}

class _MisServiciosScreenState extends State<MisServiciosScreen> {
  Profesional? _yo;
  late DateTime _desde = _inicioQuincena();
  DateTime _hasta = Fechas.hoy;
  List<Reserva> _reservas = const [];
  List<Comision> _comisiones = const [];
  bool _cargando = true;
  String? _error;

  static DateTime _inicioQuincena() {
    final h = DateTime.now();
    return DateTime(h.year, h.month, h.day <= 15 ? 1 : 16);
  }

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      _yo ??= await ProfesionalService().porDocumento(GestorSesion.actual?.username ?? '');
      final reservas = await ReservaService().entre(_desde, _hasta);
      var comisiones = <Comision>[];
      if (_yo != null) {
        try {
          comisiones = await ComisionService().listar(profesionalId: _yo!.id);
        } catch (_) {}
      }
      if (!mounted) return;
      setState(() {
        _reservas = reservas.where((r) => _yo == null || r.profesionalId == _yo!.id).toList().reversed.toList();
        _comisiones = comisiones;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    final atendidas = _reservas.where((r) => r.atendida).toList();
    final vendido = atendidas.fold<int>(0, (a, r) => a + (r.precio ?? 0));
    final estimado = vendido * (_yo?.porcentaje ?? 0) / 100;

    Widget cuerpo;
    if (_cargando && _reservas.isEmpty) {
      cuerpo = const EstadoCarga(mensaje: 'Consultando tus servicios...');
    } else if (_error != null) {
      cuerpo = EstadoError(mensaje: _error!, alReintentar: _cargar);
    } else {
      cuerpo = RefreshIndicator(
        onRefresh: _cargar,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          children: [
            Row(children: [
              Expanded(child: TarjetaMetrica(icono: Icons.verified_outlined, valor: '${atendidas.length}', titulo: 'Realizados')),
              const SizedBox(width: 8),
              Expanded(child: TarjetaMetrica(icono: Icons.payments_outlined, valor: Formato.moneda(vendido), titulo: 'Vendido')),
            ]),
            const SizedBox(height: 8),
            TarjetaMetrica(
              icono: Icons.percent,
              valor: Formato.moneda(estimado),
              titulo: 'Comisión estimada (${Formato.porcentaje(_yo?.porcentaje ?? 0)})',
            ),
            const SizedBox(height: 18),
            Text('Servicios del periodo', style: AppTheme.cormorant(size: 17, color: c.primarioOscuro)),
            if (_reservas.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: EstadoVacio(
                  icono: Icons.content_cut_outlined,
                  titulo: 'Sin servicios',
                  mensaje: 'No tienes servicios en el rango seleccionado.',
                ),
              ),
            for (final r in _reservas)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: TarjetaReserva(reserva: r, alTocar: () => abrir(context, DetalleReservaScreen(reserva: r))),
              ),
            if (_comisiones.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text('Comisiones liquidadas', style: AppTheme.cormorant(size: 17, color: c.primarioOscuro)),
              for (final comision in _comisiones)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: TarjetaBase(
                    alTocar: () => abrir(context, DetalleComisionScreen(comision: comision)),
                    child: Row(
                      children: [
                        IconoCaja(icono: Icons.receipt_long_outlined, color: c.acento, fondo: c.acentoFondo),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                comision.fechaInicio == null
                                    ? 'Cierre N.° ${comision.cierreId ?? comision.id}'
                                    : '${Fechas.corta(comision.fechaInicio)} – ${Fechas.corta(comision.fechaFin)}',
                                style: AppTheme.manrope(size: 13.5, weight: FontWeight.w700, color: c.textoOscuro),
                              ),
                              Text('${comision.cantidadServicios ?? '—'} servicio(s)',
                                  style: AppTheme.manrope(size: 12, color: c.textoSutil)),
                            ],
                          ),
                        ),
                        Text(comision.valor == null ? '—' : Formato.moneda(comision.valor),
                            style: AppTheme.cormorant(size: 17, color: c.primarioOscuro)),
                      ],
                    ),
                  ),
                ),
            ],
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: c.fondo,
      appBar: EncabezadoModulo(
        titulo: 'Mis servicios',
        subtitulo: _yo == null ? 'Servicios realizados y comisiones' : _yo!.nombreCompleto,
      ),
      body: ContenidoCentrado(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Row(
                children: [
                  FiltroFecha(
                    etiqueta: 'Desde',
                    valor: _desde,
                    alCambiar: (f) {
                      if (f == null) return;
                      setState(() => _desde = Fechas.soloFecha(f));
                      _cargar();
                    },
                  ),
                  const SizedBox(width: 8),
                  FiltroFecha(
                    etiqueta: 'Hasta',
                    valor: _hasta,
                    alCambiar: (f) {
                      if (f == null) return;
                      setState(() => _hasta = Fechas.soloFecha(f));
                      _cargar();
                    },
                  ),
                ],
              ),
            ),
            Expanded(child: cuerpo),
          ],
        ),
      ),
    );
  }
}
