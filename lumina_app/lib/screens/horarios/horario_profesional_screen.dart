import 'package:flutter/material.dart';
import 'package:lumina_app/domain/app_theme.dart';
import 'package:lumina_app/domain/dias_semana.dart';
import 'package:lumina_app/domain/formatos.dart';
import 'package:lumina_app/models/horario/horario_laboral.dart';
import 'package:lumina_app/models/profesional/profesional.dart';
import 'package:lumina_app/routes/app_routes.dart';
import 'package:lumina_app/screens/horarios/formulario_horario_screen.dart';
import 'package:lumina_app/services/remote/api_service.dart';
import 'package:lumina_app/services/remote/horario_service.dart';
import 'package:lumina_app/theme/colores_app.dart';
import 'package:lumina_app/widgets/chip_estado.dart';
import 'package:lumina_app/widgets/dialogos.dart';
import 'package:lumina_app/widgets/encabezado_modulo.dart';
import 'package:lumina_app/widgets/estados_vista.dart';
import 'package:lumina_app/widgets/marco_pantalla.dart';
import 'package:lumina_app/widgets/tarjeta_base.dart';
import 'package:lumina_app/widgets/tarjeta_metrica.dart';

/// Semana laboral de un profesional
/// (GET /api/horarios-laboral/profesional/{id}).
class HorarioProfesionalScreen extends StatefulWidget {
  const HorarioProfesionalScreen({super.key, required this.profesional});

  final Profesional profesional;

  @override
  State<HorarioProfesionalScreen> createState() => _HorarioProfesionalScreenState();
}

class _HorarioProfesionalScreenState extends State<HorarioProfesionalScreen> {
  final HorarioService _servicio = HorarioService();
  List<HorarioLaboral> _horarios = const [];
  bool _cargando = true;
  String? _error;

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
      final horarios = await _servicio.deProfesional(widget.profesional.id);
      if (mounted) setState(() => _horarios = horarios);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _agregar() async {
    final guardado = await abrir<bool>(
      context,
      FormularioHorarioScreen(
        profesional: widget.profesional,
        diasOcupados: _horarios.map((h) => h.diaSemana).toSet(),
      ),
    );
    if (guardado == true && mounted) _cargar();
  }

  Future<void> _editar(HorarioLaboral h) async {
    final guardado = await abrir<bool>(
      context,
      FormularioHorarioScreen(profesional: widget.profesional, horario: h),
    );
    if (guardado == true && mounted) _cargar();
  }

  Future<void> _eliminar(HorarioLaboral h) async {
    final confirmado = await confirmarAccion(
      context,
      titulo: 'Quitar jornada del ${h.dia.toLowerCase()}',
      mensaje: '${widget.profesional.nombres} quedará sin disponibilidad ese día.',
      textoConfirmar: 'Quitar',
      peligrosa: true,
      icono: Icons.event_busy_outlined,
    );
    if (!confirmado || !mounted) return;
    try {
      await _servicio.borrar(h.id);
      if (!mounted) return;
      mostrarExito(context, 'Jornada eliminada.');
      _cargar();
    } on ApiException catch (e) {
      if (mounted) mostrarError(context, e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    final porDia = {for (final h in _horarios) h.diaSemana: h};
    final horas = _horarios.fold<int>(0, (a, h) => a + h.minutosLaborales) / 60;
    final libres = DiasSemana.orden.where((d) => !porDia.containsKey(d)).length;

    Widget cuerpo;
    if (_cargando && _horarios.isEmpty) {
      cuerpo = const EstadoCarga(mensaje: 'Consultando horario...');
    } else if (_error != null) {
      cuerpo = EstadoError(mensaje: _error!, alReintentar: _cargar);
    } else {
      cuerpo = RefreshIndicator(
        onRefresh: _cargar,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
          children: [
            Row(
              children: [
                Expanded(
                  child: TarjetaMetrica(icono: Icons.event_available_outlined, valor: '${porDia.length}', titulo: 'Días laborales'),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TarjetaMetrica(icono: Icons.timer_outlined, valor: Formato.horas(horas), titulo: 'Horas semanales'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            for (final d in DiasSemana.orden) ...[
              porDia[d] == null
                  ? _DiaLibre(dia: d, alAgregar: _agregar)
                  : _DiaJornada(
                      horario: porDia[d]!,
                      alEditar: () => _editar(porDia[d]!),
                      alEliminar: () => _eliminar(porDia[d]!),
                    ),
              const SizedBox(height: 10),
            ],
            Text(
              'Toca un día para editarlo. Los días sin jornada no tienen horarios para reservar.',
              style: AppTheme.manrope(size: 11.5, color: c.textoSutil),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: c.fondo,
      appBar: EncabezadoModulo(titulo: 'Horario semanal', subtitulo: widget.profesional.nombreCompleto),
      body: ContenidoCentrado(child: cuerpo),
      floatingActionButton: libres == 0 || _cargando
          ? null
          : FloatingActionButton.extended(
              heroTag: 'fab_horario',
              onPressed: _agregar,
              backgroundColor: AppColors.primario,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Agregar jornada'),
            ),
    );
  }
}

class _DiaJornada extends StatelessWidget {
  const _DiaJornada({required this.horario, required this.alEditar, required this.alEliminar});

  final HorarioLaboral horario;
  final VoidCallback alEditar;
  final VoidCallback alEliminar;

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    return TarjetaBase(
      alTocar: alEditar,
      child: Row(
        children: [
          IconoCaja(icono: Icons.event_available_outlined, color: c.verde),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(horario.dia, style: AppTheme.cormorant(size: 16, color: c.textoOscuro)),
                Text(horario.rango,
                    style: AppTheme.manrope(size: 13, weight: FontWeight.w700, color: c.verdeOscuro)),
                Text(
                  horario.almuerzo == null ? 'Sin pausa de almuerzo' : 'Almuerzo ${horario.almuerzo}',
                  style: AppTheme.manrope(size: 12, color: c.textoSutil),
                ),
              ],
            ),
          ),
          IconButton(tooltip: 'Editar', onPressed: alEditar, icon: Icon(Icons.edit_outlined, color: c.primario)),
          IconButton(
            tooltip: 'Quitar jornada',
            onPressed: alEliminar,
            icon: const Icon(Icons.delete_outline, color: AppColors.rojoAlerta),
          ),
        ],
      ),
    );
  }
}

class _DiaLibre extends StatelessWidget {
  const _DiaLibre({required this.dia, required this.alAgregar});

  final int dia;
  final VoidCallback alAgregar;

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    return Opacity(
      opacity: 0.8,
      child: TarjetaBase(
        alTocar: alAgregar,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(child: Text(DiasSemana.nombre(dia), style: AppTheme.cormorant(size: 15, color: c.textoGris))),
            const ChipEstado(texto: 'Sin jornada', tono: TonoEstado.neutro, icono: Icons.do_not_disturb_on_outlined),
          ],
        ),
      ),
    );
  }
}
