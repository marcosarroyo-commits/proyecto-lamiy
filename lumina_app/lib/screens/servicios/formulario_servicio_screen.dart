import 'package:flutter/material.dart';
import 'package:lumina_app/models/especialidad/especialidad.dart';
import 'package:lumina_app/models/servicio/servicio.dart';
import 'package:lumina_app/services/local/catalogo_cache.dart';
import 'package:lumina_app/services/remote/api_service.dart';
import 'package:lumina_app/services/remote/servicio_service.dart';
import 'package:lumina_app/theme/colores_app.dart';
import 'package:lumina_app/widgets/barra_acciones.dart';
import 'package:lumina_app/widgets/campos_formulario.dart';
import 'package:lumina_app/widgets/dialogos.dart';
import 'package:lumina_app/widgets/encabezado_modulo.dart';
import 'package:lumina_app/widgets/marco_pantalla.dart';
import 'package:lumina_app/widgets/mensaje_error.dart';
import 'package:lumina_app/widgets/seccion_detalle.dart';

/// Crear o editar servicio.
/// Regla: después de crearlo, descripción y especialidad son de solo lectura.
class FormularioServicioScreen extends StatefulWidget {
  const FormularioServicioScreen({super.key, this.servicio});

  final Servicio? servicio;

  @override
  State<FormularioServicioScreen> createState() => _FormularioServicioScreenState();
}

class _FormularioServicioScreenState extends State<FormularioServicioScreen> {
  final ServicioService _servicio = ServicioService();
  final GlobalKey<FormState> _formulario = GlobalKey<FormState>();
  late final TextEditingController _nombre = TextEditingController(text: widget.servicio?.nombre ?? '');
  late final TextEditingController _precio =
      TextEditingController(text: widget.servicio == null ? '' : '${widget.servicio!.precio}');
  late final TextEditingController _duracion =
      TextEditingController(text: widget.servicio == null ? '' : '${widget.servicio!.duracion}');
  final TextEditingController _descripcion = TextEditingController();

  late bool _activo = widget.servicio?.activo ?? true;
  int? _especialidadId;
  List<Especialidad> _especialidades = const [];
  bool _guardando = false;
  String? _errorServidor;

  bool get _editando => widget.servicio != null;

  @override
  void initState() {
    super.initState();
    CatalogoCache.especialidades().then((lista) {
      if (mounted) setState(() => _especialidades = lista.where((e) => e.activa).toList());
    }, onError: (_) {});
  }

  @override
  void dispose() {
    _nombre.dispose();
    _precio.dispose();
    _duracion.dispose();
    _descripcion.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    FocusScope.of(context).unfocus();
    setState(() => _errorServidor = null);
    if (!(_formulario.currentState?.validate() ?? false)) return;
    final precio = int.parse(_precio.text.replaceAll('.', ''));
    final duracion = int.parse(_duracion.text);
    setState(() => _guardando = true);
    try {
      if (_editando) {
        await _servicio.editar(widget.servicio!.id,
            nombre: _nombre.text, precio: precio, duracion: duracion, activo: _activo);
      } else {
        await _servicio.registrar(
          nombre: _nombre.text,
          precio: precio,
          descripcion: _descripcion.text,
          duracion: duracion,
          especialidadId: _especialidadId!,
        );
      }
      if (!mounted) return;
      mostrarExito(context, _editando ? 'Servicio actualizado.' : 'Servicio creado.');
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
    final s = widget.servicio;
    return Scaffold(
      backgroundColor: c.fondo,
      appBar: EncabezadoModulo(
        titulo: _editando ? 'Editar servicio' : 'Nuevo servicio',
        subtitulo: _editando ? '${s!.codigo} · ${s!.nombre}' : 'Completa los datos del servicio',
      ),
      body: Form(
        key: _formulario,
        child: ContenidoCentrado(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              if (_errorServidor != null) ...[MensajeError(_errorServidor!), const SizedBox(height: 16)],
              CampoTexto(
                etiqueta: 'Nombre',
                controlador: _nombre,
                icono: Icons.content_cut_outlined,
                hint: 'Ej. Corte + cepillado',
                obligatorio: true,
                longitudMaxima: 50,
                mayusculas: TextCapitalization.sentences,
                validador: (v) => Validar.maximo(v, 50, 'el nombre'),
              ),
              const SizedBox(height: 16),
              if (_editando)
                FilaDato(
                  icono: Icons.lock_outline,
                  etiqueta: 'Especialidad (solo lectura)',
                  valor: s!.especialidadNombre ??
                      CatalogoCache.especialidad(s!.especialidadId)?.nombre ??
                      'No disponible',
                )
              else
                CampoSelector<int>(
                  etiqueta: 'Especialidad',
                  valor: _especialidadId,
                  icono: Icons.category_outlined,
                  obligatorio: true,
                  hint: _especialidades.isEmpty ? 'Cargando especialidades...' : 'Seleccionar',
                  validador: (v) => Validar.seleccion(v, 'la especialidad'),
                  alCambiar: (v) => setState(() => _especialidadId = v),
                  opciones: [
                    for (final e in _especialidades) OpcionSelector(valor: e.id, texto: e.nombre),
                  ],
                ),
              const SizedBox(height: 16),
              if (_editando)
                FilaDato(
                  icono: Icons.lock_outline,
                  etiqueta: 'Descripción (solo lectura)',
                  valor: (s!.descripcion ?? '').isEmpty ? 'Sin descripción' : s!.descripcion!,
                )
              else
                CampoTexto(
                  etiqueta: 'Descripción',
                  controlador: _descripcion,
                  icono: Icons.notes,
                  hint: 'Describe brevemente el servicio',
                  lineas: 3,
                  mayusculas: TextCapitalization.sentences,
                ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: CampoTexto(
                      etiqueta: 'Precio (COP)',
                      controlador: _precio,
                      icono: Icons.attach_money,
                      hint: '45000',
                      obligatorio: true,
                      teclado: TextInputType.number,
                      formateadores: [Formateadores.soloDigitos],
                      validador: (v) => Validar.entero(v, 'el precio', permiteCero: true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CampoTexto(
                      etiqueta: 'Duración (min)',
                      controlador: _duracion,
                      icono: Icons.timer_outlined,
                      hint: '45',
                      obligatorio: true,
                      teclado: TextInputType.number,
                      formateadores: [Formateadores.soloDigitos],
                      validador: (v) => Validar.entero(v, 'la duración'),
                    ),
                  ),
                ],
              ),
              if (_editando) ...[
                const SizedBox(height: 16),
                InterruptorCampo(
                  titulo: _activo ? 'Servicio activo' : 'Servicio inactivo',
                  descripcion: _activo ? 'Disponible para nuevas reservas' : 'No se podrá elegir al reservar',
                  valor: _activo,
                  alCambiar: (v) => setState(() => _activo = v),
                ),
              ],
            ],
          ),
        ),
      ),
      bottomNavigationBar: BarraAcciones(
        textoPrincipal: _editando ? 'Guardar cambios' : 'Crear servicio',
        alPrincipal: _guardar,
        cargando: _guardando,
      ),
    );
  }
}
