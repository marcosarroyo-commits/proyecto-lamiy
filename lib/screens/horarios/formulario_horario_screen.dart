import 'package:flutter/material.dart';
import 'package:lumina_app/domain/app_theme.dart';
import 'package:lumina_app/domain/dias_semana.dart';
import 'package:lumina_app/domain/fechas.dart';
import 'package:lumina_app/models/horario/horario_laboral.dart';
import 'package:lumina_app/models/profesional/profesional.dart';
import 'package:lumina_app/services/remote/api_service.dart';
import 'package:lumina_app/services/remote/horario_service.dart';
import 'package:lumina_app/theme/colores_app.dart';
import 'package:lumina_app/widgets/barra_acciones.dart';
import 'package:lumina_app/widgets/campos_formulario.dart';
import 'package:lumina_app/widgets/dialogos.dart';
import 'package:lumina_app/widgets/encabezado_modulo.dart';
import 'package:lumina_app/widgets/filtros.dart';
import 'package:lumina_app/widgets/marco_pantalla.dart';
import 'package:lumina_app/widgets/mensaje_error.dart';


class FormularioHorarioScreen extends StatefulWidget {
  const FormularioHorarioScreen({
    super.key,
    required this.profesional,
    this.horario,
    this.diasOcupados = const {},
  });

  final Profesional profesional;
  final HorarioLaboral? horario;
  final Set<int> diasOcupados;

  @override
  State<FormularioHorarioScreen> createState() => _FormularioHorarioScreenState();
}

class _FormularioHorarioScreenState extends State<FormularioHorarioScreen> {
  final HorarioService _servicio = HorarioService();
  final Set<int> _dias = {};
  late TimeOfDay _inicio = widget.horario?.horaInicio ?? const TimeOfDay(hour: 8, minute: 0);
  late TimeOfDay _fin = widget.horario?.horaFin ?? const TimeOfDay(hour: 18, minute: 0);
  late bool _almuerzo = widget.horario?.tieneAlmuerzo ?? true;
  late TimeOfDay _inicioAlmuerzo =
      widget.horario?.inicioAlmuerzo ?? const TimeOfDay(hour: 12, minute: 0);
  late TimeOfDay _finAlmuerzo = widget.horario?.finAlmuerzo ?? const TimeOfDay(hour: 13, minute: 0);
  bool _guardando = false;
  String? _error;

  bool get _editando => widget.horario != null;

  @override
  void initState() {
    super.initState();
    if (_editando) _refrescar();
  }

  
  Future<void> _refrescar() async {
    try {
      final h = await _servicio.obtenerPorId(widget.horario!.id);
      if (!mounted) return;
      setState(() {
        _inicio = h.horaInicio;
        _fin = h.horaFin;
        _almuerzo = h.tieneAlmuerzo;
        _inicioAlmuerzo = h.inicioAlmuerzo ?? _inicioAlmuerzo;
        _finAlmuerzo = h.finAlmuerzo ?? _finAlmuerzo;
      });
    } on ApiException catch (_) {}
  }

  
  String? _validar() {
    if (!_editando && _dias.isEmpty) return 'Selecciona al menos un día.';
    if (Fechas.minutos(_inicio) >= Fechas.minutos(_fin)) {
      return 'La hora de inicio debe ser anterior a la hora de fin.';
    }
    if (_almuerzo) {
      final a = Fechas.minutos(_inicioAlmuerzo), b = Fechas.minutos(_finAlmuerzo);
      if (a >= b) return 'El inicio del almuerzo debe ser anterior a su fin.';
      if (a <= Fechas.minutos(_inicio) || b >= Fechas.minutos(_fin)) {
        return 'El almuerzo debe estar dentro de la jornada.';
      }
    }
    return null;
  }

  Future<void> _guardar() async {
    final error = _validar();
    setState(() => _error = error);
    if (error != null) return;
    final jornada = Jornada(
      inicio: _inicio,
      fin: _fin,
      almuerzo: _almuerzo,
      inicioAlmuerzo: _inicioAlmuerzo,
      finAlmuerzo: _finAlmuerzo,
    );
    setState(() => _guardando = true);
    try {
      if (_editando) {
        await _servicio.editar(widget.horario!.id, jornada);
      } else {
        await _servicio.registrar(
          profesionalId: widget.profesional.id,
          dias: DiasSemana.orden.where(_dias.contains).toList(),
          jornada: jornada,
        );
      }
      if (!mounted) return;
      mostrarExito(
        context,
        _editando
            ? 'Jornada actualizada.'
            : (_dias.length == 1 ? 'Jornada agregada.' : '${_dias.length} jornadas agregadas.'),
      );
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
    return Scaffold(
      backgroundColor: c.fondo,
      appBar: EncabezadoModulo(
        titulo: _editando ? 'Editar jornada' : 'Agregar jornada',
        subtitulo: _editando
            ? '${widget.horario!.dia} · ${widget.profesional.nombres}'
            : widget.profesional.nombreCompleto,
      ),
      body: ContenidoCentrado(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            if (_error != null) ...[MensajeError(_error!), const SizedBox(height: 16)],
            if (!_editando) ...[
              const TituloSeccionFormulario(
                titulo: 'Días',
                icono: Icons.calendar_view_week_outlined,
                descripcion: 'Varios días = registro masivo con la misma jornada',
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final d in DiasSemana.orden)
                    Opacity(
                      opacity: widget.diasOcupados.contains(d) ? 0.4 : 1,
                      child: PildoraFiltro(
                        texto: DiasSemana.corto(d),
                        activa: _dias.contains(d),
                        alTocar: () {
                          if (widget.diasOcupados.contains(d)) {
                            mostrarError(context, '${DiasSemana.nombre(d)} ya tiene jornada.');
                            return;
                          }
                          setState(() {
                            if (!_dias.remove(d)) _dias.add(d);
                          });
                        },
                      ),
                    ),
                ],
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () => setState(() {
                    _dias
                      ..clear()
                      ..addAll([1, 2, 3, 4, 5].where((d) => !widget.diasOcupados.contains(d)));
                  }),
                  child: const Text('Lunes a viernes'),
                ),
              ),
              const SizedBox(height: 8),
            ],
            const TituloSeccionFormulario(titulo: 'Jornada', icono: Icons.schedule),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: CampoHora(
                    etiqueta: 'Hora inicial',
                    valor: _inicio,
                    obligatorio: true,
                    alCambiar: (h) => setState(() => _inicio = h),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CampoHora(
                    etiqueta: 'Hora final',
                    valor: _fin,
                    obligatorio: true,
                    alCambiar: (h) => setState(() => _fin = h),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            InterruptorCampo(
              titulo: 'Pausa de almuerzo',
              descripcion: _almuerzo ? 'Se descuenta de la disponibilidad' : 'Jornada continua',
              valor: _almuerzo,
              alCambiar: (v) => setState(() => _almuerzo = v),
            ),
            if (_almuerzo) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: CampoHora(
                      etiqueta: 'Inicio almuerzo',
                      valor: _inicioAlmuerzo,
                      obligatorio: true,
                      alCambiar: (h) => setState(() => _inicioAlmuerzo = h),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CampoHora(
                      etiqueta: 'Fin almuerzo',
                      valor: _finAlmuerzo,
                      obligatorio: true,
                      alCambiar: (h) => setState(() => _finAlmuerzo = h),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            Text(
              'Resumen: ${Fechas.horaDelDia(_inicio)} – ${Fechas.horaDelDia(_fin)}'
              '${_almuerzo ? ' · almuerzo ${Fechas.horaDelDia(_inicioAlmuerzo)} – ${Fechas.horaDelDia(_finAlmuerzo)}' : ''}',
              style: AppTheme.manrope(size: 12.5, color: c.textoSutil),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BarraAcciones(
        textoPrincipal: _editando ? 'Guardar cambios' : 'Guardar jornada',
        alPrincipal: _guardar,
        cargando: _guardando,
      ),
    );
  }
}
