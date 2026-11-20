import 'package:flutter/material.dart';
import 'package:lumina_app/domain/app_theme.dart';
import 'package:lumina_app/domain/fechas.dart';
import 'package:lumina_app/domain/formatos.dart';
import 'package:lumina_app/domain/reglas_reserva.dart';
import 'package:lumina_app/models/reserva/reserva.dart';
import 'package:lumina_app/routes/app_routes.dart';
import 'package:lumina_app/screens/reservas/reagendar_reserva_screen.dart';
import 'package:lumina_app/services/local/gestor_sesion.dart';
import 'package:lumina_app/services/remote/api_service.dart';
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




class DetalleReservaScreen extends StatefulWidget {
  const DetalleReservaScreen({super.key, this.reserva, this.reservaId})
    : assert(reserva != null || reservaId != null);

  final Reserva? reserva;
  final int? reservaId;

  @override
  State<DetalleReservaScreen> createState() => _DetalleReservaScreenState();
}

class _DetalleReservaScreenState extends State<DetalleReservaScreen> {
  final ReservaService _servicio = ReservaService();
  late Reserva? _r = widget.reserva;
  bool _procesando = false;
  String? _error;

  bool get _puedeGestionar => GestorSesion.actual?.esGestor ?? false;

  @override
  void initState() {
    super.initState();
    _refrescar();
  }

  Future<void> _refrescar() async {
    try {
      final actual = await _servicio.obtenerPorId(widget.reservaId ?? widget.reserva!.id);
      if (mounted) setState(() => _r = actual);
    } on ApiException catch (e) {
      if (mounted && _r == null) setState(() => _error = e.message);
    }
  }

  Future<void> _confirmarAsistencia() async {
    final r = _r!;
    final confirmado = await confirmarAccion(
      context,
      titulo: 'Confirmar asistencia',
      mensaje: '${r.clienteNombre ?? 'El cliente'} asistió y recibió "${r.servicioNombre ?? 'el servicio'}". '
          'El servicio contará para el cierre y las comisiones.',
      textoConfirmar: 'Marcar atendida',
      icono: Icons.verified_outlined,
    );
    if (!confirmado || !mounted) return;
    setState(() => _procesando = true);
    try {
      await _servicio.marcarAtendida(r);
      if (!mounted) return;
      mostrarExito(context, 'Reserva ${r.codigo} marcada como atendida.');
      await _refrescar();
    } on ApiException catch (e) {
      if (mounted) mostrarError(context, e.message);
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }

  Future<void> _cancelar() async {
    final motivo = await solicitarMotivo(
      context,
      titulo: 'Cancelar reserva',
      mensaje: 'El cliente informó que no asistirá. El estado cambiará a Cancelada. '
          'Ej.: ${MotivoCancelacion.opciones.first.toLowerCase()}.',
      etiqueta: 'Motivo de la cancelación',
      textoConfirmar: 'Cancelar cita',
    );
    if (motivo == null || !mounted) return;
    setState(() => _procesando = true);
    try {
      await _servicio.cancelar(_r!.id, motivo);
      if (!mounted) return;
      mostrarExito(context, 'Reserva cancelada.');
      await _refrescar();
    } on ApiException catch (e) {
      if (mounted) mostrarError(context, e.message);
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }

  Future<void> _reagendar() async {
    final guardado = await abrir<bool>(context, ReagendarReservaScreen(reserva: _r!));
    if (guardado == true && mounted) _refrescar();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    final r = _r;
    if (r == null) {
      return Scaffold(
        backgroundColor: c.fondo,
        appBar: const EncabezadoModulo(titulo: 'Detalle de reserva'),
        body: _error != null
            ? EstadoError(mensaje: _error!, alReintentar: _refrescar)
            : const EstadoCarga(mensaje: 'Consultando reserva...'),
      );
    }
    return Scaffold(
      backgroundColor: c.fondo,
      appBar: EncabezadoModulo(titulo: 'Detalle de reserva', subtitulo: 'Reserva ${r.codigo}'),
      body: ContenidoCentrado(
        child: RefreshIndicator(
          onRefresh: _refrescar,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              TarjetaBase(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    r.estado.chip,
                    const SizedBox(height: 10),
                    Text(r.servicioNombre ?? 'Servicio',
                        textAlign: TextAlign.center,
                        style: AppTheme.cormorant(size: 22, color: c.textoOscuro)),
                    const SizedBox(height: 4),
                    Text(Formato.moneda(r.precio),
                        style: AppTheme.cormorant(size: 26, weight: FontWeight.w800, color: c.primarioOscuro)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      alignment: WrapAlignment.center,
                      children: [
                        ChipEstado(texto: Formato.duracion(r.duracion), tono: TonoEstado.info, icono: Icons.timer_outlined),
                        if (r.medioPago != null)
                          ChipEstado(texto: r.medioPago!, tono: TonoEstado.neutro, icono: Icons.payments_outlined),
                      ],
                    ),
                  ],
                ),
              ),
              if (r.cancelada) ...[
                const SizedBox(height: 12),
                Aviso(
                  titulo: 'Reserva cancelada',
                  mensaje: r.motivoCancelacion == null ? 'Sin motivo registrado.' : 'Motivo: ${r.motivoCancelacion}',
                  tono: TonoEstado.peligro,
                ),
              ],
              if (r.atendida) ...[
                const SizedBox(height: 12),
                const Aviso(
                  titulo: 'Servicio realizado',
                  mensaje: 'Se incluirá en el próximo cierre y en las comisiones del profesional.',
                  tono: TonoEstado.exito,
                ),
              ],
              const SizedBox(height: 16),
              SeccionDetalle(
                titulo: 'Cita',
                icono: Icons.event_note_outlined,
                children: [
                  FilaDato(icono: Icons.tag, etiqueta: 'Identificador', valor: r.codigo),
                  FilaDato(icono: Icons.event_outlined, etiqueta: 'Fecha', valor: Fechas.fechaLarga(r.fecha)),
                  FilaDato(icono: Icons.schedule, etiqueta: 'Hora', valor: '${Fechas.hora12(r.fecha)} – ${Fechas.hora12(r.fin)}'),
                  FilaDato(
                    icono: Icons.face_retouching_natural,
                    etiqueta: 'Profesional',
                    valor: Formato.valorO(r.profesionalNombre, 'Por asignar'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SeccionDetalle(
                titulo: 'Cliente',
                icono: Icons.person_outline,
                children: [
                  FilaDato(icono: Icons.person_outline, etiqueta: 'Nombre', valor: Formato.valorO(r.clienteNombre)),
                  FilaDato(icono: Icons.badge_outlined, etiqueta: 'Documento', valor: Formato.valorO(r.clienteDocumento)),
                  FilaDato(icono: Icons.phone_iphone_outlined, etiqueta: 'Celular', valor: Formato.celular(r.clienteCelular)),
                  FilaDato(icono: Icons.alternate_email, etiqueta: 'Correo', valor: Formato.valorO(r.clienteCorreo)),
                ],
              ),
              const SizedBox(height: 16),
              PieTrazabilidad(
                registro: Fechas.fechaHora(r.fechaCreacion),
                actualizacion: Fechas.corta(DateTime.now()),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: !r.programada || !_puedeGestionar
          ? null
          : PieAcciones(
              children: [
                BotonSecundario(
                  texto: 'Cancelar',
                  icono: Icons.close,
                  peligro: true,
                  alPresionar: _procesando ? null : _cancelar,
                ),
                BotonSecundario(
                  texto: 'Reagendar',
                  icono: Icons.edit_calendar_outlined,
                  alPresionar: _procesando ? null : _reagendar,
                ),
                FilledButton.icon(
                  onPressed: _procesando ? null : _confirmarAsistencia,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.verde,
                    minimumSize: const Size(0, 52),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.verified_outlined, size: 20),
                  label: const Text('Atendida'),
                ),
              ],
            ),
    );
  }
}
