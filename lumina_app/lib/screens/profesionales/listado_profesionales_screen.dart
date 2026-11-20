import 'package:flutter/material.dart';
import 'package:lumina_app/domain/app_theme.dart';
import 'package:lumina_app/domain/formatos.dart';
import 'package:lumina_app/models/comun/pagina.dart';
import 'package:lumina_app/models/especialidad/especialidad.dart';
import 'package:lumina_app/models/profesional/profesional.dart';
import 'package:lumina_app/routes/app_routes.dart';
import 'package:lumina_app/screens/horarios/horario_profesional_screen.dart';
import 'package:lumina_app/screens/profesionales/detalle_profesional_screen.dart';
import 'package:lumina_app/screens/profesionales/formulario_profesional_screen.dart';
import 'package:lumina_app/services/local/catalogo_cache.dart';
import 'package:lumina_app/services/remote/profesional_service.dart';
import 'package:lumina_app/theme/colores_app.dart';
import 'package:lumina_app/widgets/chip_estado.dart';
import 'package:lumina_app/widgets/encabezado_modulo.dart';
import 'package:lumina_app/widgets/estados_vista.dart';
import 'package:lumina_app/widgets/filtros.dart';
import 'package:lumina_app/widgets/selector_opciones.dart';
import 'package:lumina_app/widgets/tarjeta_base.dart';
import 'package:lumina_app/widgets/vista_paginada.dart';

class ListadoProfesionalesScreen extends StatefulWidget {
  const ListadoProfesionalesScreen({super.key});

  @override
  State<ListadoProfesionalesScreen> createState() => _ListadoProfesionalesScreenState();
}

class _ListadoProfesionalesScreenState extends State<ListadoProfesionalesScreen> {
  final ProfesionalService _servicio = ProfesionalService();
  late final ControladorPaginado<Profesional> _controlador = ControladorPaginado(_cargar);

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

  Future<Pagina<Profesional>> _cargar(int pagina) => _servicio.listar(
    busqueda: _busqueda,
    especialidadId: _especialidad?.id,
    activo: _activo,
  );

  Future<void> _registrar() async {
    final creado = await abrir<bool>(context, const FormularioProfesionalScreen());
    if (creado == true && mounted) _controlador.recargar();
  }

  Future<void> _verDetalle(Profesional p) async {
    await abrir(context, DetalleProfesionalScreen(profesional: p));
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

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    return Scaffold(
      backgroundColor: c.fondo,
      appBar: EncabezadoModulo(
        titulo: 'Profesionales',
        subtitulo: 'Equipo del centro de belleza',
        acciones: [
          AccionEncabezado(icono: Icons.person_add_alt_1_outlined, tooltip: 'Agregar profesional', alPresionar: _registrar),
        ],
      ),
      body: PantallaLista(
        filtros: Column(
          children: [
            CampoBusqueda(
              hint: 'Buscar por nombre o documento',
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
        lista: VistaPaginada<Profesional>(
          controlador: _controlador,
          constructor: (context, p) => _TarjetaProfesional(
            profesional: p,
            alTocar: () => _verDetalle(p),
            alHorario: () => abrir(context, HorarioProfesionalScreen(profesional: p)),
          ),
          vacio: EstadoVacio(
            icono: Icons.person_search_outlined,
            titulo: 'Sin profesionales',
            mensaje: _busqueda.isEmpty && _especialidad == null && _activo == null
                ? 'Registra a los integrantes del equipo.'
                : 'Nadie coincide con la búsqueda o el filtro.',
            textoAccion: 'Agregar profesional',
            iconoAccion: Icons.person_add_alt_1_outlined,
            alAccion: _registrar,
          ),
        ),
      ),
    );
  }
}

class _TarjetaProfesional extends StatelessWidget {
  const _TarjetaProfesional({required this.profesional, required this.alTocar, required this.alHorario});

  final Profesional profesional;
  final VoidCallback alTocar;
  final VoidCallback alHorario;

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    final p = profesional;
    final especialidad = p.especialidadNombre ??
        CatalogoCache.especialidad(p.especialidadId)?.nombre ??
        'Sin especialidad';
    return Opacity(
      opacity: p.activo ? 1 : 0.72,
      child: TarjetaBase(
        alTocar: alTocar,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AvatarIniciales(texto: Formato.iniciales(p.nombreCompleto), tamano: 48),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.nombreCompleto, style: AppTheme.cormorant(size: 16, color: c.textoOscuro)),
                      Text('ID ${p.id} · CC ${p.documento}',
                          style: AppTheme.manrope(size: 12, color: c.textoSutil)),
                      Text(
                        '$especialidad · Comisión ${Formato.porcentaje(p.porcentaje)}',
                        style: AppTheme.manrope(size: 12, weight: FontWeight.w700, color: c.primario),
                      ),
                    ],
                  ),
                ),
                ChipEstado.activo(p.activo),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: alHorario,
                    icon: const Icon(Icons.schedule, size: 18),
                    label: const Text('Horario'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: alTocar,
                    style: FilledButton.styleFrom(backgroundColor: AppColors.primario),
                    icon: const Icon(Icons.visibility_outlined, size: 18),
                    label: const Text('Ver detalle'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
