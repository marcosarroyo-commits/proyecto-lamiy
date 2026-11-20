import 'package:flutter/material.dart';
import 'package:lumina_app/domain/app_theme.dart';
import 'package:lumina_app/domain/fechas.dart';
import 'package:lumina_app/domain/formatos.dart';
import 'package:lumina_app/models/reserva/reserva.dart';
import 'package:lumina_app/routes/app_routes.dart';
import 'package:lumina_app/screens/cierres/detalle_cierre_screen.dart';
import 'package:lumina_app/services/local/catalogo_cache.dart';
import 'package:lumina_app/services/remote/api_service.dart';
import 'package:lumina_app/services/remote/liquidacion_service.dart';
import 'package:lumina_app/services/remote/reserva_service.dart';
import 'package:lumina_app/theme/colores_app.dart';
import 'package:lumina_app/widgets/barra_acciones.dart';
import 'package:lumina_app/widgets/chip_estado.dart';
import 'package:lumina_app/widgets/dialogos.dart';
import 'package:lumina_app/widgets/encabezado_modulo.dart';
import 'package:lumina_app/widgets/estados_vista.dart';
import 'package:lumina_app/widgets/marco_pantalla.dart';
import 'package:lumina_app/widgets/seccion_detalle.dart';
import 'package:lumina_app/widgets/tarjeta_base.dart';
import 'package:lumina_app/widgets/tarjeta_metrica.dart';

class _ResumenProfesional {
  _ResumenProfesional(this.nombre, this.porcentaje);

  final String nombre;
  final double porcentaje;
  int servicios = 0;
  int total = 0;

  double get comision => total * porcentaje / 100;
}


class ResumenCierreScreen extends StatefulWidget {
  const ResumenCierreScreen({super.key, required this.inicio, required this.fin});

  final DateTime inicio;
  final DateTime fin;

  @override
  State<ResumenCierreScreen> createState() => _ResumenCierreScreenState();
}

class _ResumenCierreScreenState extends State<ResumenCierreScreen> {
  List<Reserva>? _reservas;
  String? _error;
  bool _generando = false;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _error = null);
    try {
      final reservas = await ReservaService().entre(widget.inicio, widget.fin);
      await CatalogoCache.profesionales();
      if (mounted) setState(() => _reservas = reservas);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  Future<void> _generar() async {
    final confirmado = await confirmarAccion(
      context,
      titulo: 'Generar cierre',
      mensaje: 'Se consolidarán los servicios del ${Fechas.corta(widget.inicio)} al '
          '${Fechas.corta(widget.fin)} y se calcularán las comisiones. Un cierre generado no se modifica.',
      textoConfirmar: 'Generar cierre',
      icono: Icons.lock_clock,
    );
    if (!confirmado || !mounted) return;
    setState(() => _generando = true);
    try {
      final servicio = LiquidacionService();
      final creado = await servicio.generar(widget.inicio, widget.fin) ?? await servicio.ultima();
      if (!mounted) return;
      mostrarExito(context, 'Cierre generado correctamente.');
      if (creado != null) {
        await abrir(context, DetalleCierreScreen(cierre: creado));
      }
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (mounted) mostrarError(context, e.message);
    } finally {
      if (mounted) setState(() => _generando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    final reservas = _reservas;
    Widget cuerpo;
    if (_error != null) {
      cuerpo = EstadoError(mensaje: _error!, alReintentar: _cargar);
    } else if (reservas == null) {
      cuerpo = const EstadoCarga(mensaje: 'Calculando el resumen del periodo...');
    } else {
      final atendidas = reservas.where((r) => r.atendida).toList();
      final pendientes = reservas.where((r) => r.programada).length;
      final porProfesional = <int, _ResumenProfesional>{};
      for (final r in atendidas) {
        final p = CatalogoCache.profesional(r.profesionalId);
        porProfesional.putIfAbsent(
          r.profesionalId ?? -1,
          () => _ResumenProfesional(r.profesionalNombre ?? p?.nombreCompleto ?? 'Sin asignar', p?.porcentaje ?? 0),
        )
          ..servicios += 1
          ..total += r.precio ?? 0;
      }
      final total = atendidas.fold<int>(0, (a, r) => a + (r.precio ?? 0));
      final comisiones = porProfesional.values.fold<double>(0, (a, p) => a + p.comision);

      cuerpo = ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          TarjetaBase(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${Fechas.corta(widget.inicio)} – ${Fechas.corta(widget.fin)}',
                    style: AppTheme.cormorant(size: 18, color: c.textoOscuro)),
                Text('${atendidas.length} servicio(s) atendido(s)',
                    style: AppTheme.manrope(size: 13, color: c.textoSutil)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: TarjetaMetrica(icono: Icons.payments_outlined, valor: Formato.moneda(total), titulo: 'Total servicios')),
            const SizedBox(width: 8),
            Expanded(child: TarjetaMetrica(icono: Icons.percent, valor: Formato.moneda(comisiones), titulo: 'Comisiones (est.)')),
          ]),
          const SizedBox(height: 8),
          TarjetaMetrica(
            icono: Icons.storefront_outlined,
            valor: Formato.moneda(total - comisiones),
            titulo: 'Valor para el centro (estimado)',
          ),
          if (pendientes > 0) ...[
            const SizedBox(height: 12),
            Aviso(
              titulo: '$pendientes reserva(s) sin confirmar',
              mensaje: 'Confirma la asistencia o cancela esas reservas antes de cerrar el periodo.',
              tono: TonoEstado.alerta,
            ),
          ],
          const SizedBox(height: 16),
          SeccionDetalle(
            titulo: 'Profesionales incluidos',
            icono: Icons.groups_outlined,
            children: porProfesional.isEmpty
                ? [const FilaDato(etiqueta: 'Sin servicios', valor: 'No hay servicios atendidos en el periodo.')]
                : [
                    for (final p in porProfesional.values)
                      FilaDato(
                        icono: Icons.face_retouching_natural,
                        etiqueta: '${p.servicios} servicio(s) · Base ${Formato.moneda(p.total)} · ${Formato.porcentaje(p.porcentaje)}',
                        valor: '${p.nombre}: ${Formato.moneda(p.comision)}',
                      ),
                  ],
          ),
          const SizedBox(height: 12),
          Text(
            'Los valores estimados se calculan con las reservas atendidas y el porcentaje de cada '
            'profesional. El cálculo definitivo lo hace el sistema al generar el cierre.',
            style: AppTheme.manrope(size: 11.5, color: c.textoSutil),
          ),
        ],
      );
    }

    return Scaffold(
      backgroundColor: c.fondo,
      appBar: const EncabezadoModulo(titulo: 'Resumen del periodo', subtitulo: 'Revisa antes de confirmar'),
      body: ContenidoCentrado(child: cuerpo),
      bottomNavigationBar: BarraAcciones(
        textoPrincipal: 'Confirmar cierre',
        textoSecundario: 'Volver a editar',
        alPrincipal: reservas == null ? () {} : _generar,
        cargando: _generando || reservas == null,
      ),
    );
  }
}
