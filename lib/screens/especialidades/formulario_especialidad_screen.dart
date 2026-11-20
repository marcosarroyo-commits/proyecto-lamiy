import 'package:flutter/material.dart';
import 'package:lumina_app/models/especialidad/especialidad.dart';
import 'package:lumina_app/services/remote/api_service.dart';
import 'package:lumina_app/services/remote/especialidad_service.dart';
import 'package:lumina_app/theme/colores_app.dart';
import 'package:lumina_app/widgets/barra_acciones.dart';
import 'package:lumina_app/widgets/campos_formulario.dart';
import 'package:lumina_app/widgets/dialogos.dart';
import 'package:lumina_app/widgets/encabezado_modulo.dart';
import 'package:lumina_app/widgets/marco_pantalla.dart';
import 'package:lumina_app/widgets/mensaje_error.dart';


class FormularioEspecialidadScreen extends StatefulWidget {
  const FormularioEspecialidadScreen({super.key, this.especialidad});

  final Especialidad? especialidad;

  @override
  State<FormularioEspecialidadScreen> createState() => _FormularioEspecialidadScreenState();
}

class _FormularioEspecialidadScreenState extends State<FormularioEspecialidadScreen> {
  final EspecialidadService _servicio = EspecialidadService();
  final GlobalKey<FormState> _formulario = GlobalKey<FormState>();
  late final TextEditingController _nombre =
      TextEditingController(text: widget.especialidad?.nombre ?? '');

  late bool _activa = widget.especialidad?.activa ?? true;
  bool _guardando = false;
  String? _errorServidor;

  bool get _editando => widget.especialidad != null;

  @override
  void initState() {
    super.initState();
    if (_editando) _refrescar();
  }

  
  Future<void> _refrescar() async {
    try {
      final actual = await _servicio.obtenerPorId(widget.especialidad!.id);
      if (!mounted) return;
      setState(() {
        _nombre.text = actual.nombre;
        _activa = actual.activa;
      });
    } on ApiException catch (_) {}
  }

  @override
  void dispose() {
    _nombre.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    FocusScope.of(context).unfocus();
    setState(() => _errorServidor = null);
    if (!(_formulario.currentState?.validate() ?? false)) return;
    setState(() => _guardando = true);
    try {
      if (_editando) {
        await _servicio.editar(widget.especialidad!.id, nombre: _nombre.text, activa: _activa);
      } else {
        await _servicio.registrar(_nombre.text);
      }
      if (!mounted) return;
      mostrarExito(context, _editando ? 'Especialidad actualizada.' : 'Especialidad creada.');
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (mounted) setState(() => _errorServidor = e.message);
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  Future<void> _eliminar() async {
    final confirmado = await confirmarAccion(
      context,
      titulo: 'Eliminar especialidad',
      mensaje: 'Esta acción no se puede deshacer. Si tiene servicios asociados, '
          'te recomendamos inactivarla en lugar de eliminarla.',
      textoConfirmar: 'Eliminar',
      peligrosa: true,
      icono: Icons.delete_outline,
    );
    if (!confirmado || !mounted) return;
    setState(() => _guardando = true);
    try {
      await _servicio.borrar(widget.especialidad!.id);
      if (!mounted) return;
      mostrarExito(context, 'Especialidad eliminada.');
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
    return Scaffold(
      backgroundColor: c.fondo,
      appBar: EncabezadoModulo(
        titulo: _editando ? 'Editar especialidad' : 'Nueva especialidad',
        subtitulo: _editando
            ? 'Actualiza el nombre y la disponibilidad'
            : 'Crea una categoría para tus servicios',
      ),
      body: Form(
        key: _formulario,
        child: ContenidoCentrado(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              if (_errorServidor != null) ...[
                MensajeError(_errorServidor!),
                const SizedBox(height: 16),
              ],
              CampoTexto(
                etiqueta: 'Nombre',
                controlador: _nombre,
                icono: Icons.category_outlined,
                hint: 'Ej. Maquillaje profesional',
                obligatorio: true,
                longitudMaxima: 60,
                mayusculas: TextCapitalization.sentences,
                validador: (v) => Validar.maximo(v, 60, 'el nombre'),
              ),
              if (_editando) ...[
                const SizedBox(height: 16),
                InterruptorCampo(
                  titulo: _activa ? 'Especialidad activa' : 'Especialidad inactiva',
                  descripcion: _activa
                      ? 'Disponible para crear servicios y asignar profesionales'
                      : 'No aparecerá al crear servicios ni profesionales',
                  valor: _activa,
                  alCambiar: (v) => setState(() => _activa = v),
                ),
                const SizedBox(height: 20),
                BotonSecundario(
                  texto: 'Eliminar especialidad',
                  icono: Icons.delete_outline,
                  peligro: true,
                  alPresionar: _guardando ? null : _eliminar,
                ),
              ],
            ],
          ),
        ),
      ),
      bottomNavigationBar: BarraAcciones(
        textoPrincipal: _editando ? 'Guardar cambios' : 'Guardar especialidad',
        alPrincipal: _guardar,
        cargando: _guardando,
      ),
    );
  }
}
