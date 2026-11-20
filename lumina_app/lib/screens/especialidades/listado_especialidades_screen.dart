import 'package:flutter/material.dart';
import 'package:lumina_app/domain/app_theme.dart';
import 'package:lumina_app/models/comun/pagina.dart';
import 'package:lumina_app/models/especialidad/especialidad.dart';
import 'package:lumina_app/routes/app_routes.dart';
import 'package:lumina_app/screens/especialidades/formulario_especialidad_screen.dart';
import 'package:lumina_app/services/remote/api_service.dart';
import 'package:lumina_app/services/remote/especialidad_service.dart';
import 'package:lumina_app/theme/colores_app.dart';
import 'package:lumina_app/widgets/chip_estado.dart';
import 'package:lumina_app/widgets/dialogos.dart';
import 'package:lumina_app/widgets/encabezado_modulo.dart';
import 'package:lumina_app/widgets/estados_vista.dart';
import 'package:lumina_app/widgets/filtros.dart';
import 'package:lumina_app/widgets/tarjeta_base.dart';
import 'package:lumina_app/widgets/vista_paginada.dart';

class ListadoEspecialidadesScreen extends StatefulWidget {
  const ListadoEspecialidadesScreen({super.key});

  @override
  State<ListadoEspecialidadesScreen> createState() => _ListadoEspecialidadesScreenState();
}

class _ListadoEspecialidadesScreenState extends State<ListadoEspecialidadesScreen> {
  final EspecialidadService _servicio = EspecialidadService();
  late final ControladorPaginado<Especialidad> _controlador = ControladorPaginado(_cargar);

  String _busqueda = '';
  bool? _activa;

  @override
  void initState() {
    super.initState();
    _controlador.recargar();
  }

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  Future<Pagina<Especialidad>> _cargar(int pagina) =>
      _servicio.listar(busqueda: _busqueda, activa: _activa);

  Future<void> _abrirFormulario([Especialidad? especialidad]) async {
    final guardado = await abrir<bool>(
      context,
      FormularioEspecialidadScreen(especialidad: especialidad),
    );
    if (guardado == true && mounted) _controlador.recargar();
  }

  Future<void> _cambiarEstado(Especialidad e) async {
    final activar = !e.activa;
    final confirmado = await confirmarAccion(
      context,
      titulo: activar ? 'Activar especialidad' : 'Inactivar especialidad',
      mensaje: activar
          ? '"${e.nombre}" volverá a estar disponible para servicios y profesionales.'
          : '"${e.nombre}" dejará de aparecer al crear servicios y profesionales.',
      textoConfirmar: activar ? 'Activar' : 'Inactivar',
      peligrosa: !activar,
      icono: activar ? Icons.play_circle_outline : Icons.pause_circle_outline,
    );
    if (!confirmado || !mounted) return;
    try {
      await _servicio.editar(e.id, nombre: e.nombre, activa: activar);
      if (!mounted) return;
      mostrarExito(context, activar ? 'Especialidad activada.' : 'Especialidad inactivada.');
      _controlador.recargar();
    } on ApiException catch (error) {
      if (mounted) mostrarError(context, error.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    return Scaffold(
      backgroundColor: c.fondo,
      appBar: EncabezadoModulo(
        titulo: 'Especialidades',
        subtitulo: 'Categorías que agrupan servicios y profesionales',
        acciones: [
          AccionEncabezado(
            icono: Icons.add,
            tooltip: 'Nueva especialidad',
            alPresionar: _abrirFormulario,
          ),
        ],
      ),
      body: PantallaLista(
        filtros: Column(
          children: [
            CampoBusqueda(
              hint: 'Buscar especialidad por nombre',
              alBuscar: (valor) {
                _busqueda = valor;
                _controlador.recargar();
              },
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: BarraFiltros<bool?>(
                seleccionado: _activa,
                alCambiar: (valor) {
                  setState(() => _activa = valor);
                  _controlador.recargar();
                },
                opciones: const [
                  OpcionFiltro(null, 'Todas'),
                  OpcionFiltro(true, 'Activas'),
                  OpcionFiltro(false, 'Inactivas'),
                ],
              ),
            ),
          ],
        ),
        lista: VistaPaginada<Especialidad>(
          controlador: _controlador,
          cabecera: ListenableBuilder(
            listenable: _controlador,
            builder: (context, _) => ContadorResultados(
              mostrados: _controlador.items.length,
              total: _controlador.totalItems,
              sustantivo: 'especialidades',
            ),
          ),
          constructor: (context, especialidad) => _TarjetaEspecialidad(
            especialidad: especialidad,
            alEditar: () => _abrirFormulario(especialidad),
            alCambiarEstado: () => _cambiarEstado(especialidad),
          ),
          vacio: EstadoVacio(
            icono: Icons.search_off,
            titulo: 'No encontramos coincidencias',
            mensaje: _busqueda.isEmpty && _activa == null
                ? 'Aún no hay especialidades registradas.'
                : 'Prueba con otro nombre o cambia el filtro.',
            textoAccion: 'Nueva especialidad',
            alAccion: _abrirFormulario,
          ),
        ),
      ),
    );
  }
}

class _TarjetaEspecialidad extends StatelessWidget {
  const _TarjetaEspecialidad({
    required this.especialidad,
    required this.alEditar,
    required this.alCambiarEstado,
  });

  final Especialidad especialidad;
  final VoidCallback alEditar;
  final VoidCallback alCambiarEstado;

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    final e = especialidad;
    return Opacity(
      opacity: e.activa ? 1 : 0.72,
      child: TarjetaBase(
        alTocar: alEditar,
        child: Row(
          children: [
            IconoCaja(
              icono: Icons.category_outlined,
              color: e.activa ? c.primario : c.textoSutil,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(e.nombre, style: AppTheme.cormorant(size: 16, color: c.textoOscuro)),
                  const SizedBox(height: 4),
                  ChipEstado.activo(e.activa, textoActivo: 'Activa', textoInactivo: 'Inactiva'),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Editar',
              onPressed: alEditar,
              icon: Icon(Icons.edit_outlined, color: c.primario),
            ),
            IconButton(
              tooltip: e.activa ? 'Inactivar' : 'Activar',
              onPressed: alCambiarEstado,
              icon: Icon(
                e.activa ? Icons.pause_circle_outline : Icons.play_circle_outline,
                color: e.activa ? c.textoSutil : c.verde,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
