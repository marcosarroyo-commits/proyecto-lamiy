import 'package:flutter/material.dart';
import 'package:lumina_app/domain/app_theme.dart';
import 'package:lumina_app/domain/fechas.dart';
import 'package:lumina_app/domain/formatos.dart';
import 'package:lumina_app/models/agenda/horario_disponible.dart';
import 'package:lumina_app/models/profesional/profesional.dart';
import 'package:lumina_app/models/servicio/servicio.dart';
import 'package:lumina_app/services/local/inasistencia_local_service.dart';
import 'package:lumina_app/services/remote/agenda_service.dart';
import 'package:lumina_app/services/remote/api_service.dart';
import 'package:lumina_app/services/remote/profesional_service.dart';
import 'package:lumina_app/theme/colores_app.dart';
import 'package:lumina_app/widgets/campos_formulario.dart';

/// Profesional + horario elegidos.
class SeleccionHorario {
  const SeleccionHorario({this.profesional, required this.horario});

  /// null = "Cualquiera".
  final Profesional? profesional;
  final HorarioDisponible horario;
}

/// Profesional → fecha → hora disponible.
/// Consume GET /api/profesionales/{esp}/especialiades y GET /api/agenda.
/// La hora se elige de una lista (no se escribe a mano).
class SelectorHorario extends StatefulWidget {
  const SelectorHorario({
    super.key,
    required this.servicio,
    required this.alCambiar,
    this.profesionalInicialId,
    this.fechaInicial,
    this.pasoInicial = 3,
  });

  final Servicio servicio;
  final ValueChanged<SeleccionHorario?> alCambiar;
  final int? profesionalInicialId;
  final DateTime? fechaInicial;
  final int pasoInicial;

  @override
  State<SelectorHorario> createState() => _SelectorHorarioState();
}

class _SelectorHorarioState extends State<SelectorHorario> {
  List<Profesional> _profesionales = const [];
  Set<int> _ausentes = const {};
  Profesional? _profesional;
  late DateTime _fecha = Fechas.soloFecha(widget.fechaInicial ?? DateTime.now());
  List<HorarioDisponible> _horarios = const [];
  HorarioDisponible? _horario;
  bool _cargandoProfesionales = true;
  bool _cargandoHorarios = false;
  String? _errorHorarios;
  int _consulta = 0;

  @override
  void initState() {
    super.initState();
    // Tras el primer frame, para no notificar al padre durante su build.
    WidgetsBinding.instance.addPostFrameCallback((_) => _cargarProfesionales());
  }

  Future<void> _cargarProfesionales() async {
    if (!mounted) return;
    setState(() => _cargandoProfesionales = true);
    var lista = <Profesional>[];
    final especialidad = widget.servicio.especialidadId;
    if (especialidad != null) {
      try {
        lista = await ProfesionalService().porEspecialidad(especialidad);
      } catch (_) {}
    }
    if (!mounted) return;
    setState(() {
      _profesionales = lista;
      _cargandoProfesionales = false;
      for (final p in lista) {
        if (p.id == widget.profesionalInicialId) _profesional = p;
      }
    });
    _cargarHorarios();
  }

  Future<void> _cargarHorarios() async {
    final consulta = ++_consulta;
    setState(() {
      _cargandoHorarios = true;
      _errorHorarios = null;
      _horario = null;
      _horarios = const [];
    });
    widget.alCambiar(null);
    try {
      final ausentes = await InasistenciaLocalService().ausentesEn(_fecha);
      if (_profesional != null && ausentes.contains(_profesional!.id)) {
        if (!mounted || consulta != _consulta) return;
        setState(() {
          _ausentes = ausentes;
          _errorHorarios = '${_profesional!.nombres} tiene una inasistencia registrada este día.';
        });
        return;
      }
      final horarios = await AgendaService().disponibles(
        fecha: _fecha,
        servicioId: widget.servicio.id,
        profesionalId: _profesional?.id,
      );
      if (!mounted || consulta != _consulta) return;
      // Con "Cualquiera" se muestra una opción por hora (la primera libre).
      final vistas = <String>{};
      setState(() {
        _ausentes = ausentes;
        _horarios = _profesional == null
            ? horarios.where((h) => vistas.add(Fechas.apiFechaHora(h.inicio))).toList()
            : horarios;
      });
    } on ApiException catch (e) {
      if (mounted && consulta == _consulta) setState(() => _errorHorarios = e.message);
    } finally {
      if (mounted && consulta == _consulta) setState(() => _cargandoHorarios = false);
    }
  }

  void _elegirProfesional(Profesional? p) {
    setState(() => _profesional = p);
    _cargarHorarios();
  }

  void _elegirFecha(DateTime f) {
    setState(() => _fecha = Fechas.soloFecha(f));
    _cargarHorarios();
  }

  Future<void> _otraFecha() async {
    final hoy = Fechas.hoy;
    final elegida = await showDatePicker(
      context: context,
      initialDate: _fecha.isBefore(hoy) ? hoy : _fecha,
      firstDate: hoy,
      lastDate: hoy.add(const Duration(days: 180)),
      helpText: 'Fecha de la reserva',
    );
    if (elegida != null) _elegirFecha(elegida);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    final hoy = Fechas.hoy;
    final dias = List.generate(21, (i) => hoy.add(Duration(days: i)));
    if (!dias.any((d) => Fechas.mismoDia(d, _fecha))) dias.insert(0, _fecha);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EtiquetaCampo('${widget.pasoInicial}. Profesional'),
        const SizedBox(height: 8),
        SizedBox(
          height: 104,
          child: _cargandoProfesionales
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _TarjetaProfesional(
                      nombre: 'Cualquiera',
                      detalle: 'Primer disponible',
                      seleccionada: _profesional == null,
                      icono: Icons.auto_awesome,
                      alTocar: () => _elegirProfesional(null),
                    ),
                    for (final p in _profesionales)
                      _TarjetaProfesional(
                        nombre: p.nombreCorto,
                        detalle: _ausentes.contains(p.id)
                            ? 'Ausente'
                            : Formato.valorO(p.especialidadNombre ?? widget.servicio.especialidadNombre, ''),
                        seleccionada: _profesional?.id == p.id,
                        deshabilitada: _ausentes.contains(p.id),
                        alTocar: () => _elegirProfesional(p),
                      ),
                  ],
                ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(child: EtiquetaCampo('${widget.pasoInicial + 1}. Fecha · ${Fechas.mesAnio(_fecha)}')),
            TextButton.icon(
              onPressed: _otraFecha,
              icon: const Icon(Icons.calendar_month_outlined, size: 18),
              label: const Text('Otra'),
            ),
          ],
        ),
        SizedBox(
          height: 76,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: dias.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final d = dias[i];
              final activa = Fechas.mismoDia(d, _fecha);
              return InkWell(
                onTap: () => _elegirFecha(d),
                borderRadius: BorderRadius.circular(14),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 58,
                  decoration: BoxDecoration(
                    color: activa ? AppColors.primario : c.superficie,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: activa ? AppColors.primario : c.borde),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(Fechas.diaCorto(d),
                          style: AppTheme.manrope(
                              size: 12, weight: FontWeight.w700, color: activa ? Colors.white70 : c.textoSutil)),
                      Text('${d.day}',
                          style: AppTheme.cormorant(size: 20, color: activa ? Colors.white : c.textoOscuro)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 18),
        EtiquetaCampo('${widget.pasoInicial + 2}. Hora disponible'),
        const SizedBox(height: 8),
        if (_cargandoHorarios)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_errorHorarios != null)
          _AvisoHorarios(icono: Icons.error_outline, texto: _errorHorarios!, alReintentar: _cargarHorarios)
        else if (_horarios.isEmpty)
          const _AvisoHorarios(
            icono: Icons.event_busy_outlined,
            texto: 'No hay horarios disponibles en esta fecha. Prueba otro día u otro profesional.',
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final h in _horarios)
                _ChipHora(
                  hora: h.hora,
                  detalle: _profesional == null ? h.profesionalNombre?.split(' ').first : null,
                  seleccionada: identical(h, _horario),
                  alTocar: () {
                    setState(() => _horario = h);
                    widget.alCambiar(SeleccionHorario(profesional: _profesional, horario: h));
                  },
                ),
            ],
          ),
      ],
    );
  }
}

class _TarjetaProfesional extends StatelessWidget {
  const _TarjetaProfesional({
    required this.nombre,
    required this.detalle,
    required this.seleccionada,
    required this.alTocar,
    this.deshabilitada = false,
    this.icono,
  });

  final String nombre;
  final String detalle;
  final bool seleccionada;
  final bool deshabilitada;
  final IconData? icono;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: Opacity(
        opacity: deshabilitada ? 0.45 : 1,
        child: InkWell(
          onTap: deshabilitada ? null : alTocar,
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 104,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: seleccionada ? c.badgeFondo : c.superficie,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: seleccionada ? c.primario : c.borde, width: seleccionada ? 1.6 : 1),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: icono != null ? c.acentoFondo : c.badgeFondo,
                  child: icono != null
                      ? Icon(icono, color: c.acento, size: 20)
                      : Text(Formato.iniciales(nombre),
                          style: AppTheme.manrope(size: 12, weight: FontWeight.w800, color: c.primario)),
                ),
                const SizedBox(height: 6),
                Text(nombre,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.manrope(size: 12.5, weight: FontWeight.w800, color: c.textoOscuro)),
                Text(detalle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.manrope(size: 10.5, color: c.textoSutil)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ChipHora extends StatelessWidget {
  const _ChipHora({required this.hora, required this.seleccionada, required this.alTocar, this.detalle});

  final String hora;
  final String? detalle;
  final bool seleccionada;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    return InkWell(
      onTap: alTocar,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 96,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: seleccionada ? AppColors.primario : c.superficie,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: seleccionada ? AppColors.primario : c.borde),
        ),
        child: Column(
          children: [
            Text(hora,
                style: AppTheme.manrope(
                    size: 13.5, weight: FontWeight.w800, color: seleccionada ? Colors.white : c.textoOscuro)),
            if (detalle != null)
              Text(detalle!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.manrope(size: 10.5, color: seleccionada ? Colors.white70 : c.textoSutil)),
          ],
        ),
      ),
    );
  }
}

class _AvisoHorarios extends StatelessWidget {
  const _AvisoHorarios({required this.icono, required this.texto, this.alReintentar});

  final IconData icono;
  final String texto;
  final VoidCallback? alReintentar;

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: c.bordeTarjeta, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          Icon(icono, color: c.textoSecundario),
          const SizedBox(width: 10),
          Expanded(child: Text(texto, style: AppTheme.manrope(size: 13, color: c.textoSecundario))),
          if (alReintentar != null) TextButton(onPressed: alReintentar, child: const Text('Reintentar')),
        ],
      ),
    );
  }
}
