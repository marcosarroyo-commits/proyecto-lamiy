import 'package:flutter/material.dart';
import 'package:lumina_app/domain/fechas.dart';
import 'package:lumina_app/models/reserva/reserva.dart';
import 'package:lumina_app/models/servicio/servicio.dart';
import 'package:lumina_app/screens/reservas/selector_horario.dart';
import 'package:lumina_app/services/local/catalogo_cache.dart';
import 'package:lumina_app/services/remote/api_service.dart';
import 'package:lumina_app/services/remote/reserva_service.dart';
import 'package:lumina_app/theme/colores_app.dart';
import 'package:lumina_app/widgets/barra_acciones.dart';
import 'package:lumina_app/widgets/dialogos.dart';
import 'package:lumina_app/widgets/encabezado_modulo.dart';
import 'package:lumina_app/widgets/estados_vista.dart';
import 'package:lumina_app/widgets/marco_pantalla.dart';
import 'package:lumina_app/widgets/mensaje_error.dart';
import 'package:lumina_app/widgets/seccion_detalle.dart';

/// Reagendar: solo cambia fecha, hora y profesional.
/// Cliente y servicio se muestran como contexto (no editables).
class ReagendarReservaScreen extends StatefulWidget {
  const ReagendarReservaScreen({super.key, required this.reserva});

  final Reserva reserva;

  @override
  State<ReagendarReservaScreen> createState() => _ReagendarReservaScreenState();
}

class _ReagendarReservaScreenState extends State<ReagendarReservaScreen> {
  Servicio? _servicio;
  SeleccionHorario? _seleccion;
  bool _guardando = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final r = widget.reserva;
    Servicio? servicio;
    try {
      await CatalogoCache.servicios();
      servicio = CatalogoCache.servicio(r.servicioId);
    } catch (_) {}
    servicio ??= Servicio(
      id: r.servicioId ?? 0,
      nombre: r.servicioNombre ?? 'Servicio',
      precio: r.precio ?? 0,
      duracion: r.duracion ?? 0,
    );
    if (mounted) setState(() => _servicio = servicio);
  }

  Future<void> _guardar() async {
    final s = _seleccion;
    if (s == null) {
      setState(() => _error = 'Selecciona una nueva fecha y una hora disponible.');
      return;
    }
    setState(() {
      _guardando = true;
      _error = null;
    });
    try {
      await ReservaService().reagendar(
        widget.reserva,
        fecha: s.horario.inicio,
        profesionalId: s.profesional?.id ?? s.horario.profesionalId,
      );
      if (!mounted) return;
      mostrarExito(context,
          'Reserva reagendada para el ${Fechas.corta(s.horario.inicio)} a las ${Fechas.hora12(s.horario.inicio)}.');
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    final r = widget.reserva;
    return Scaffold(
      backgroundColor: c.fondo,
      appBar: EncabezadoModulo(titulo: 'Reagendar reserva', subtitulo: 'Reserva ${r.codigo}'),
      body: _servicio == null
          ? const EstadoCarga()
          : ContenidoCentrado(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  if (_error != null) ...[MensajeError(_error!), const SizedBox(height: 16)],
                  SeccionDetalle(
                    titulo: 'No editable en este flujo',
                    icono: Icons.lock_outline,
                    children: [
                      FilaDato(icono: Icons.person_outline, etiqueta: 'Cliente', valor: r.clienteNombre ?? '—'),
                      FilaDato(icono: Icons.content_cut_outlined, etiqueta: 'Servicio', valor: r.servicioNombre ?? '—'),
                      FilaDato(
                        icono: Icons.history,
                        etiqueta: 'Programada actualmente',
                        valor: '${Fechas.corta(r.fecha)} · ${Fechas.hora12(r.fecha)} · ${r.profesionalNombre ?? 'Sin profesional'}',
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SelectorHorario(
                    servicio: _servicio!,
                    profesionalInicialId: r.profesionalId,
                    fechaInicial: r.fecha.isBefore(DateTime.now()) ? DateTime.now() : r.fecha,
                    pasoInicial: 1,
                    alCambiar: (s) => setState(() => _seleccion = s),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: BarraAcciones(
        textoPrincipal: 'Guardar cambios',
        textoSecundario: 'Cancelar edición',
        alPrincipal: _guardar,
        cargando: _guardando,
      ),
    );
  }
}
