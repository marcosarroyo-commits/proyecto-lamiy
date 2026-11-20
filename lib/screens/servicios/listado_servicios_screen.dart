import 'package:flutter/material.dart';
import 'package:lumina_app/domain/app_theme.dart';
import 'package:lumina_app/domain/formatos.dart';
import 'package:lumina_app/models/comun/pagina.dart';
import 'package:lumina_app/models/especialidad/especialidad.dart';
import 'package:lumina_app/models/servicio/servicio.dart';
import 'package:lumina_app/routes/app_routes.dart';
import 'package:lumina_app/screens/servicios/detalle_servicio_screen.dart';
import 'package:lumina_app/screens/servicios/formulario_servicio_screen.dart';
import 'package:lumina_app/services/local/catalogo_cache.dart';
import 'package:lumina_app/services/remote/servicio_service.dart';
import 'package:lumina_app/theme/colores_app.dart';
import 'package:lumina_app/widgets/chip_estado.dart';
import 'package:lumina_app/widgets/encabezado_modulo.dart';
import 'package:lumina_app/widgets/estados_vista.dart';
import 'package:lumina_app/widgets/filtros.dart';
import 'package:lumina_app/widgets/selector_opciones.dart';
import 'package:lumina_app/widgets/tarjeta_base.dart';
import 'package:lumina_app/widgets/vista_paginada.dart';

class ListadoServiciosScreen extends StatefulWidget {
  const ListadoServiciosScreen({super.key});

  @override
  State<ListadoServiciosScreen> createState() => _ListadoServiciosScreenState();
}

class _ListadoServiciosScreenState extends State<ListadoServiciosScreen> {
  final ServicioService _servicio = ServicioService();
  late final ControladorPaginado<Servicio> _controlador = ControladorPaginado(_cargar);

  String _busqueda = '';
  bool? _activo;
  Especialidad? _especialidad;
  List<Especialidad> _especialidades = const [];

  @override
  void initState() {
    super.initState();
    _controlador.recargar();
    CatalogoCache.especialidades().then((lista) {
      if (mounted) setState(() => _especialidades = lista);
    }, onError: (_) {});
  }

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  Future<Pagina<Servicio>> _cargar(int pagina) => _servicio.listar(
    busqueda: _busqueda,
    especialidadId: _especialidad?.id,
    activo: _activo,
  );

  Future<void> _registrar() async {
    final creado = await abrir<bool>(context, const FormularioServicioScreen());
    if (creado == true && mounted) _controlador.recargar();
  }

  Future<void> _verDetalle(Servicio servicio) async {
    await abrir(context, DetalleServicioScreen(servicio: servicio));
    if (mounted) _controlador.recargar();
  }

  Future<void> _elegirEspecialidad() async {
    final opcion = await elegirOpcion<Especialidad?>(
      context,
      titulo: 'Filtrar por especialidad',
      seleccionado: _especialidad,
      opciones: [
        const OpcionFiltro(null, 'Todas las especialidades'),
        for (final e in _especialidades) OpcionFiltro(e, e.nombre),
      ],
    );
    if (opcion == null) return;
    setState(() => _especialidad = opcion.valor);
    _controlador.recargar();
  }

  void _limpiarFiltros() {
    setState(() {
      _activo = null;
      _especialidad = null;
    });
    _controlador.recargar();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    final hayFiltros = _busqueda.isNotEmpty || _activo != null || _especialidad != null;
    return Scaffold(
      backgroundColor: c.fondo,
      appBar: EncabezadoModulo(
        titulo: 'Servicios',
        subtitulo: 'Catálogo de servicios del centro',
        acciones: [
          AccionEncabezado(icono: Icons.add, tooltip: 'Nuevo servicio', alPresionar: _registrar),
        ],
      ),
      body: PantallaLista(
        filtros: Column(
          children: [
            CampoBusqueda(
              hint: 'Buscar por nombre o ID',
              alBuscar: (valor) {
                _busqueda = valor;
                _controlador.recargar();
              },
            ),
            const SizedBox(height: 10),
            BarraFiltros<bool?>(
              seleccionado: _activo,
              alCambiar: (valor) {
                setState(() => _activo = valor);
                _controlador.recargar();
              },
              extra: [
                PildoraFiltro(
                  texto: _especialidad?.nombre ?? 'Especialidad',
                  activa: _especialidad != null,
                  icono: Icons.category_outlined,
                  alTocar: _elegirEspecialidad,
                  alQuitar: _especialidad == null
                      ? null
                      : () {
                          setState(() => _especialidad = null);
                          _controlador.recargar();
                        },
                ),
              ],
              opciones: const [
                OpcionFiltro(null, 'Todos'),
                OpcionFiltro(true, 'Activos'),
                OpcionFiltro(false, 'Inactivos'),
              ],
            ),
          ],
        ),
        lista: VistaPaginada<Servicio>(
          controlador: _controlador,
          constructor: (context, servicio) =>
              _TarjetaServicio(servicio: servicio, alTocar: () => _verDetalle(servicio)),
          vacio: EstadoVacio(
            icono: Icons.content_cut_outlined,
            titulo: 'Sin servicios para mostrar',
            mensaje: hayFiltros
                ? 'Ningún servicio coincide con la búsqueda o los filtros.'
                : 'Crea el primer servicio del catálogo.',
            textoAccion: hayFiltros ? 'Limpiar filtros' : 'Nuevo servicio',
            iconoAccion: hayFiltros ? Icons.filter_alt_off_outlined : Icons.add,
            alAccion: hayFiltros ? _limpiarFiltros : _registrar,
          ),
        ),
      ),
    );
  }
}

class _TarjetaServicio extends StatelessWidget {
  const _TarjetaServicio({required this.servicio, required this.alTocar});

  final Servicio servicio;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    final s = servicio;
    final especialidad = s.especialidadNombre ??
        CatalogoCache.especialidad(s.especialidadId)?.nombre ??
        'Sin especialidad';
    return Opacity(
      opacity: s.activo ? 1 : 0.72,
      child: TarjetaBase(
        alTocar: alTocar,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const IconoCaja(icono: Icons.content_cut_outlined),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.nombre, style: AppTheme.cormorant(size: 16, color: c.textoOscuro)),
                      Text('${s.codigo} · $especialidad',
                          style: AppTheme.manrope(size: 12, color: c.textoSutil)),
                    ],
                  ),
                ),
                ChipEstado.activo(s.activo),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(Formato.moneda(s.precio),
                    style: AppTheme.cormorant(size: 18, color: c.primarioOscuro)),
                const SizedBox(width: 10),
                ChipEstado(
                  texto: Formato.duracion(s.duracion),
                  tono: TonoEstado.info,
                  icono: Icons.timer_outlined,
                ),
                const Spacer(),
                Icon(Icons.chevron_right, color: c.textoSutil),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
