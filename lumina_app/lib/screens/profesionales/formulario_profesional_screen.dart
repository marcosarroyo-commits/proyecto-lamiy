import 'package:flutter/material.dart';
import 'package:lumina_app/domain/fechas.dart';
import 'package:lumina_app/models/especialidad/especialidad.dart';
import 'package:lumina_app/models/profesional/profesional.dart';
import 'package:lumina_app/services/local/catalogo_cache.dart';
import 'package:lumina_app/services/remote/api_service.dart';
import 'package:lumina_app/services/remote/profesional_service.dart';
import 'package:lumina_app/theme/colores_app.dart';
import 'package:lumina_app/widgets/barra_acciones.dart';
import 'package:lumina_app/widgets/campos_formulario.dart';
import 'package:lumina_app/widgets/dialogos.dart';
import 'package:lumina_app/widgets/encabezado_modulo.dart';
import 'package:lumina_app/widgets/marco_pantalla.dart';
import 'package:lumina_app/widgets/mensaje_error.dart';
import 'package:lumina_app/widgets/seccion_detalle.dart';

/// Crear o editar profesional.
/// En edición, documento y especialidad son de solo lectura; nombres,
/// apellidos, nacimiento, comisión y estado sí se modifican.
class FormularioProfesionalScreen extends StatefulWidget {
  const FormularioProfesionalScreen({super.key, this.profesional});

  final Profesional? profesional;

  @override
  State<FormularioProfesionalScreen> createState() => _FormularioProfesionalScreenState();
}

class _FormularioProfesionalScreenState extends State<FormularioProfesionalScreen> {
  final ProfesionalService _servicio = ProfesionalService();
  final GlobalKey<FormState> _formulario = GlobalKey<FormState>();
  late final TextEditingController _documento =
      TextEditingController(text: widget.profesional?.documento ?? '');
  late final TextEditingController _nombres =
      TextEditingController(text: widget.profesional?.nombres ?? '');
  late final TextEditingController _apellidos =
      TextEditingController(text: widget.profesional?.apellidos ?? '');
  late final TextEditingController _porcentaje = TextEditingController(
    text: widget.profesional == null ? '' : _textoPorcentaje(widget.profesional!.porcentaje),
  );
  late DateTime? _nacimiento = widget.profesional?.fechaNacimiento;
  late bool _activo = widget.profesional?.activo ?? true;
  int? _especialidadId;
  List<Especialidad> _especialidades = const [];
  bool _guardando = false;
  String? _errorServidor;

  bool get _editando => widget.profesional != null;

  static String _textoPorcentaje(double v) => v.toStringAsFixed(v % 1 == 0 ? 0 : 1);

  @override
  void initState() {
    super.initState();
    CatalogoCache.especialidades().then((lista) {
      if (mounted) setState(() => _especialidades = lista.where((e) => e.activa).toList());
    }, onError: (_) {});
    if (_editando) _refrescar();
  }

  /// GET /api/profesionales/{id}
  Future<void> _refrescar() async {
    try {
      final p = await _servicio.obtenerPorId(widget.profesional!.id);
      if (!mounted) return;
      setState(() {
        _nombres.text = p.nombres;
        _apellidos.text = p.apellidos ?? '';
        _porcentaje.text = _textoPorcentaje(p.porcentaje);
        _nacimiento = p.fechaNacimiento;
        _activo = p.activo;
      });
    } on ApiException catch (_) {}
  }

  @override
  void dispose() {
    for (final c in [_documento, _nombres, _apellidos, _porcentaje]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _guardar() async {
    FocusScope.of(context).unfocus();
    setState(() => _errorServidor = null);
    if (!(_formulario.currentState?.validate() ?? false)) return;
    final porcentaje = double.parse(_porcentaje.text.replaceAll(',', '.'));
    setState(() => _guardando = true);
    try {
      if (_editando) {
        await _servicio.editar(
          widget.profesional!.id,
          nombres: _nombres.text,
          apellidos: _apellidos.text,
          fechaNacimiento: _nacimiento,
          porcentaje: porcentaje,
          estado: _activo,
        );
      } else {
        final existente = await _servicio.porDocumento(_documento.text);
        if (existente != null) {
          setState(() => _errorServidor = 'El documento ya pertenece a ${existente.nombreCompleto}.');
          return;
        }
        await _servicio.registrar(
          documento: _documento.text,
          nombres: _nombres.text,
          apellidos: _apellidos.text,
          fechaNacimiento: _nacimiento,
          porcentaje: porcentaje,
          estado: _activo,
          especialidadId: _especialidadId!,
        );
      }
      if (!mounted) return;
      mostrarExito(context, _editando ? 'Profesional actualizado.' : 'Profesional registrado.');
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (mounted) setState(() => _errorServidor = e.message);
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    final p = widget.profesional;
    return Scaffold(
      backgroundColor: c.fondo,
      appBar: EncabezadoModulo(
        titulo: _editando ? 'Editar profesional' : 'Nuevo profesional',
        subtitulo: _editando ? p!.nombreCompleto : 'Registra un integrante del equipo',
      ),
      body: Form(
        key: _formulario,
        child: ContenidoCentrado(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              if (_errorServidor != null) ...[MensajeError(_errorServidor!), const SizedBox(height: 16)],
              const TituloSeccionFormulario(titulo: 'Datos personales', icono: Icons.person_outline),
              const SizedBox(height: 10),
              if (_editando)
                FilaDato(icono: Icons.lock_outline, etiqueta: 'Documento (solo lectura)', valor: p!.documento)
              else
                CampoTexto(
                  etiqueta: 'Documento',
                  controlador: _documento,
                  icono: Icons.badge_outlined,
                  obligatorio: true,
                  teclado: TextInputType.number,
                  formateadores: [Formateadores.soloDigitos],
                  validador: Validar.documento,
                ),
              const SizedBox(height: 16),
              CampoTexto(
                etiqueta: 'Nombres',
                controlador: _nombres,
                icono: Icons.person_outline,
                obligatorio: true,
                mayusculas: TextCapitalization.words,
                validador: (v) => Validar.requerido(v, 'los nombres'),
              ),
              const SizedBox(height: 16),
              CampoTexto(
                etiqueta: 'Apellidos',
                controlador: _apellidos,
                icono: Icons.person_outline,
                mayusculas: TextCapitalization.words,
              ),
              const SizedBox(height: 16),
              CampoFecha(
                etiqueta: 'Fecha de nacimiento',
                valor: _nacimiento,
                primera: DateTime(1940),
                ultima: Fechas.hoy,
                icono: Icons.cake_outlined,
                alCambiar: (f) => setState(() => _nacimiento = f),
              ),
              const SizedBox(height: 20),
              const TituloSeccionFormulario(titulo: 'Trabajo en el centro', icono: Icons.work_outline),
              const SizedBox(height: 10),
              CampoTexto(
                etiqueta: 'Comisión (0 – 100 %)',
                controlador: _porcentaje,
                icono: Icons.percent,
                hint: '40',
                obligatorio: true,
                teclado: const TextInputType.numberWithOptions(decimal: true),
                validador: Validar.porcentaje,
              ),
              const SizedBox(height: 16),
              if (_editando)
                FilaDato(
                  icono: Icons.lock_outline,
                  etiqueta: 'Especialidad (solo lectura)',
                  valor: p!.especialidadNombre ??
                      CatalogoCache.especialidad(p!.especialidadId)?.nombre ??
                      'No disponible',
                )
              else
                CampoSelector<int>(
                  etiqueta: 'Especialidad',
                  valor: _especialidadId,
                  icono: Icons.category_outlined,
                  obligatorio: true,
                  validador: (v) => Validar.seleccion(v, 'la especialidad'),
                  alCambiar: (v) => setState(() => _especialidadId = v),
                  opciones: [
                    for (final e in _especialidades) OpcionSelector(valor: e.id, texto: e.nombre),
                  ],
                ),
              const SizedBox(height: 16),
              InterruptorCampo(
                titulo: _activo ? 'Profesional activo' : 'Profesional inactivo',
                descripcion: _activo
                    ? 'Puede recibir reservas según su horario'
                    : 'No aparecerá en el flujo de reservas',
                valor: _activo,
                alCambiar: (v) => setState(() => _activo = v),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BarraAcciones(
        textoPrincipal: _editando ? 'Guardar cambios' : 'Registrar profesional',
        alPrincipal: _guardar,
        cargando: _guardando,
      ),
    );
  }
}
