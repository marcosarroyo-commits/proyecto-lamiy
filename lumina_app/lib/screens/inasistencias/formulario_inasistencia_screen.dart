import 'package:flutter/material.dart';
import 'package:lumina_app/domain/fechas.dart';
import 'package:lumina_app/domain/reglas_reserva.dart';
import 'package:lumina_app/models/inasistencia/inasistencia.dart';
import 'package:lumina_app/models/profesional/profesional.dart';
import 'package:lumina_app/services/local/catalogo_cache.dart';
import 'package:lumina_app/services/local/inasistencia_local_service.dart';
import 'package:lumina_app/services/remote/api_service.dart';
import 'package:lumina_app/theme/colores_app.dart';
import 'package:lumina_app/widgets/barra_acciones.dart';
import 'package:lumina_app/widgets/campos_formulario.dart';
import 'package:lumina_app/widgets/chip_estado.dart';
import 'package:lumina_app/widgets/dialogos.dart';
import 'package:lumina_app/widgets/encabezado_modulo.dart';
import 'package:lumina_app/widgets/filtros.dart';
import 'package:lumina_app/widgets/marco_pantalla.dart';
import 'package:lumina_app/widgets/mensaje_error.dart';
import 'package:lumina_app/widgets/seccion_detalle.dart';

/// Registrar o editar una inasistencia por día o por rango de fechas.
class FormularioInasistenciaScreen extends StatefulWidget {
  const FormularioInasistenciaScreen({super.key, this.inasistencia, this.profesional});

  final Inasistencia? inasistencia;

  /// Si viene, el profesional queda fijo (desde su detalle).
  final Profesional? profesional;

  @override
  State<FormularioInasistenciaScreen> createState() => _FormularioInasistenciaScreenState();
}

class _FormularioInasistenciaScreenState extends State<FormularioInasistenciaScreen> {
  final GlobalKey<FormState> _formulario = GlobalKey<FormState>();
  late final TextEditingController _observacion =
      TextEditingController(text: widget.inasistencia?.observacion ?? '');
  late int? _profesionalId = widget.inasistencia?.profesionalId ?? widget.profesional?.id;
  late bool _rango = widget.inasistencia != null && !widget.inasistencia!.unDia;
  late DateTime? _inicio = widget.inasistencia?.fechaInicio;
  late DateTime? _fin = widget.inasistencia?.fechaFin;
  late String _motivo = widget.inasistencia?.motivo ?? MotivoInasistencia.opciones.first;
  List<Profesional> _profesionales = const [];
  bool _guardando = false;
  String? _error;

  bool get _profesionalFijo => widget.profesional != null || widget.inasistencia != null;

  @override
  void initState() {
    super.initState();
    CatalogoCache.profesionales().then((lista) {
      if (mounted) setState(() => _profesionales = lista.where((p) => p.activo).toList());
    }, onError: (_) {});
  }

  @override
  void dispose() {
    _observacion.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    setState(() => _error = null);
    if (!(_formulario.currentState?.validate() ?? false)) return;
    final inicio = Fechas.soloFecha(_inicio!);
    final fin = _rango ? Fechas.soloFecha(_fin!) : inicio;
    if (fin.isBefore(inicio)) {
      setState(() => _error = 'La fecha final debe ser igual o posterior a la inicial.');
      return;
    }
    final nombre = widget.profesional?.nombreCompleto ??
        CatalogoCache.profesional(_profesionalId)?.nombreCompleto ??
        widget.inasistencia?.profesionalNombre ??
        'Profesional';
    setState(() => _guardando = true);
    try {
      await InasistenciaLocalService().guardar(Inasistencia(
        id: widget.inasistencia?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
        profesionalId: _profesionalId!,
        profesionalNombre: nombre,
        fechaInicio: inicio,
        fechaFin: fin,
        motivo: _motivo,
        observacion: _observacion.text.trim().isEmpty ? null : _observacion.text.trim(),
      ));
      if (!mounted) return;
      mostrarExito(context, 'Inasistencia registrada. Sus horarios se bloquean en la agenda.');
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
    final hace = DateTime.now().subtract(const Duration(days: 365));
    final dentro = DateTime.now().add(const Duration(days: 365));
    final motivos = {...MotivoInasistencia.opciones, _motivo}.toList();
    return Scaffold(
      backgroundColor: c.fondo,
      appBar: EncabezadoModulo(
        titulo: widget.inasistencia == null ? 'Nueva inasistencia' : 'Editar inasistencia',
        subtitulo: 'Bloquea la disponibilidad del profesional',
      ),
      body: Form(
        key: _formulario,
        child: ContenidoCentrado(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              if (_error != null) ...[MensajeError(_error!), const SizedBox(height: 16)],
              if (_profesionalFijo)
                FilaDato(
                  icono: Icons.face_retouching_natural,
                  etiqueta: 'Profesional',
                  valor: widget.profesional?.nombreCompleto ?? widget.inasistencia!.profesionalNombre,
                )
              else
                CampoSelector<int>(
                  etiqueta: 'Profesional',
                  valor: _profesionalId,
                  icono: Icons.face_retouching_natural,
                  obligatorio: true,
                  validador: (v) => Validar.seleccion(v, 'el profesional'),
                  alCambiar: (v) => setState(() => _profesionalId = v),
                  opciones: [
                    for (final p in _profesionales) OpcionSelector(valor: p.id, texto: p.nombreCompleto),
                  ],
                ),
              const SizedBox(height: 16),
              const EtiquetaCampo('Duración', obligatorio: true),
              const SizedBox(height: 6),
              BarraFiltros<bool>(
                seleccionado: _rango,
                alCambiar: (v) => setState(() => _rango = v),
                opciones: const [OpcionFiltro(false, 'Un día'), OpcionFiltro(true, 'Rango de fechas')],
              ),
              const SizedBox(height: 16),
              CampoFecha(
                etiqueta: _rango ? 'Fecha inicial' : 'Fecha',
                valor: _inicio,
                primera: hace,
                ultima: dentro,
                obligatorio: true,
                validador: (v) => Validar.fecha(v),
                alCambiar: (f) => setState(() => _inicio = f),
              ),
              if (_rango) ...[
                const SizedBox(height: 16),
                CampoFecha(
                  etiqueta: 'Fecha final',
                  valor: _fin,
                  primera: _inicio ?? hace,
                  ultima: dentro,
                  obligatorio: true,
                  validador: (v) {
                    if (v == null) return 'Selecciona la fecha final.';
                    if (_inicio != null && v.isBefore(_inicio!)) {
                      return 'Debe ser igual o posterior a la inicial.';
                    }
                    return null;
                  },
                  alCambiar: (f) => setState(() => _fin = f),
                ),
              ],
              const SizedBox(height: 16),
              CampoSelector<String>(
                etiqueta: 'Motivo',
                valor: _motivo,
                icono: Icons.notes,
                obligatorio: true,
                alCambiar: (v) => setState(() => _motivo = v ?? _motivo),
                opciones: [for (final m in motivos) OpcionSelector(valor: m, texto: m)],
              ),
              const SizedBox(height: 16),
              CampoTexto(
                etiqueta: 'Observación',
                controlador: _observacion,
                icono: Icons.edit_note,
                hint: 'Ej. Incapacidad médica',
                lineas: 2,
                mayusculas: TextCapitalization.sentences,
              ),
              const SizedBox(height: 16),
              const Aviso(
                titulo: 'Bloqueo en la agenda',
                mensaje: 'Durante estas fechas el profesional no aparecerá en los horarios disponibles para reservar.',
                tono: TonoEstado.info,
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BarraAcciones(
        textoPrincipal: 'Guardar inasistencia',
        alPrincipal: _guardar,
        cargando: _guardando,
      ),
    );
  }
}
