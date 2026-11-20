import 'package:flutter/material.dart';
import 'package:lumina_app/domain/app_theme.dart';
import 'package:lumina_app/domain/fechas.dart';
import 'package:lumina_app/domain/formatos.dart';
import 'package:lumina_app/models/liquidacion/liquidacion.dart';
import 'package:lumina_app/models/reserva/reserva.dart';
import 'package:lumina_app/routes/app_routes.dart';
import 'package:lumina_app/screens/cierres/listado_cierres_screen.dart';
import 'package:lumina_app/screens/comisiones/listado_comisiones_screen.dart';
import 'package:lumina_app/screens/especialidades/listado_especialidades_screen.dart';
import 'package:lumina_app/screens/horarios/listado_horarios_screen.dart';
import 'package:lumina_app/screens/inasistencias/listado_inasistencias_screen.dart';
import 'package:lumina_app/screens/inicio/inicio_screen.dart';
import 'package:lumina_app/screens/perfil/perfil_screen.dart';
import 'package:lumina_app/screens/profesionales/listado_profesionales_screen.dart';
import 'package:lumina_app/screens/reservas/detalle_reserva_screen.dart';
import 'package:lumina_app/screens/reservas/formulario_reserva_screen.dart';
import 'package:lumina_app/screens/servicios/listado_servicios_screen.dart';
import 'package:lumina_app/services/local/gestor_sesion.dart';
import 'package:lumina_app/services/local/inasistencia_local_service.dart';
import 'package:lumina_app/services/remote/liquidacion_service.dart';
import 'package:lumina_app/services/remote/reserva_service.dart';
import 'package:lumina_app/theme/colores_app.dart';
import 'package:lumina_app/theme/preferencia_tema.dart';
import 'package:lumina_app/widgets/chip_estado.dart';
import 'package:lumina_app/widgets/dialogos.dart';
import 'package:lumina_app/widgets/estados_vista.dart';
import 'package:lumina_app/widgets/logo_lumina.dart';
import 'package:lumina_app/widgets/marco_pantalla.dart';
import 'package:lumina_app/widgets/seccion_detalle.dart';
import 'package:lumina_app/widgets/tarjeta_base.dart';
import 'package:lumina_app/widgets/tarjeta_metrica.dart';
import 'package:lumina_app/widgets/tarjeta_reserva.dart';

class _Modulo {
  const _Modulo(this.icono, this.texto, this.pantalla);

  final IconData icono;
  final String texto;
  final Widget Function() pantalla;
}

/// Panel administrativo: resumen del día, próxima cita y accesos rápidos.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, required this.alCambiarPestana});

  final ValueChanged<int> alCambiarPestana;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ReservaService _reservas = ReservaService();
  final LiquidacionService _liquidaciones = LiquidacionService();

  List<Reserva> _hoy = const [];
  Liquidacion? _ultimoCierre;
  int _ausentesHoy = 0;
  bool _cargando = true;
  String? _error;

  static final List<_Modulo> _modulos = [
    _Modulo(Icons.event_available_outlined, 'Nueva reserva', () => const FormularioReservaScreen()),
    _Modulo(Icons.category_outlined, 'Especialidades', () => const ListadoEspecialidadesScreen()),
    _Modulo(Icons.content_cut_outlined, 'Servicios', () => const ListadoServiciosScreen()),
    _Modulo(Icons.face_retouching_natural, 'Profesionales', () => const ListadoProfesionalesScreen()),
    _Modulo(Icons.schedule_outlined, 'Horarios', () => const ListadoHorariosScreen()),
    _Modulo(Icons.event_busy_outlined, 'Inasistencias', () => const ListadoInasistenciasScreen()),
    _Modulo(Icons.receipt_long_outlined, 'Cierres', () => const ListadoCierresScreen()),
    _Modulo(Icons.percent_outlined, 'Comisiones', () => const ListadoComisionesScreen()),
  ];

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
      final hoy = Fechas.hoy;
      final reservas = await _reservas.entre(hoy, hoy);
      if (mounted) setState(() => _hoy = reservas);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
    try {
      final cierre = await _liquidaciones.ultima();
      if (mounted) setState(() => _ultimoCierre = cierre);
    } catch (_) {}
    final ausentes = await InasistenciaLocalService().ausentesEn(DateTime.now());
    if (mounted) {
      setState(() {
        _ausentesHoy = ausentes.length;
        _cargando = false;
      });
    }
  }

  Reserva? get _proxima {
    final ahora = DateTime.now();
    final pendientes = _hoy.where((r) => r.programada && r.fin.isAfter(ahora)).toList()
      ..sort((a, b) => a.fecha.compareTo(b.fecha));
    return pendientes.isEmpty ? null : pendientes.first;
  }

  Future<void> _verReserva(Reserva r) async {
    await abrir(context, DetalleReservaScreen(reserva: r));
    if (mounted) _cargar();
  }

  Future<void> _nuevaReserva() async {
    await abrir(context, const FormularioReservaScreen());
    if (mounted) _cargar();
  }

  Future<void> _marcarAtendida(Reserva r) async {
    final confirmado = await confirmarAccion(
      context,
      titulo: 'Confirmar asistencia',
      mensaje: '${r.clienteNombre ?? 'El cliente'} recibió "${r.servicioNombre ?? 'el servicio'}".',
      textoConfirmar: 'Marcar atendida',
      icono: Icons.verified_outlined,
    );
    if (!confirmado || !mounted) return;
    try {
      await _reservas.marcarAtendida(r);
      if (!mounted) return;
      mostrarExito(context, 'Reserva ${r.codigo} marcada como atendida.');
      _cargar();
    } catch (e) {
      if (mounted) mostrarError(context, e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    return Scaffold(
      backgroundColor: c.fondo,
      appBar: _encabezado(c),
      body: RefreshIndicator(
        onRefresh: _cargar,
        child: ContenidoCentrado(
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              _saludo(c),
              const SizedBox(height: 20),
              _metricas(),
              if (_ausentesHoy > 0) ...[
                const SizedBox(height: 16),
                InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => abrir(context, const ListadoInasistenciasScreen()),
                  child: Aviso(
                    titulo: _ausentesHoy == 1
                        ? '1 profesional ausente hoy'
                        : '$_ausentesHoy profesionales ausentes hoy',
                    mensaje: 'Sus horarios no aparecen al crear o reagendar reservas.',
                    tono: TonoEstado.alerta,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              _titulo(c, 'Próxima cita'),
              const SizedBox(height: 10),
              _tarjetaProxima(c),
              const SizedBox(height: 24),
              _titulo(c, 'Módulos de gestión'),
              const SizedBox(height: 12),
              _gridModulos(c),
              const SizedBox(height: 24),
              _titulo(
                c,
                'Citas de hoy',
                accion: TextButton(
                  onPressed: () => widget.alCambiarPestana(InicioScreen.pestanaAgenda),
                  child: const Text('Ver agenda'),
                ),
              ),
              ..._citasDeHoy(),
              if (_ultimoCierre != null) ...[
                const SizedBox(height: 24),
                _titulo(c, 'Último cierre'),
                const SizedBox(height: 10),
                TarjetaBase(
                  colorFondo: c.acentoFondo,
                  alTocar: () => abrir(context, const ListadoCierresScreen()),
                  child: Row(
                    children: [
                      IconoCaja(icono: Icons.receipt_long_outlined, color: c.acento, fondo: c.superficie),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '${Fechas.corta(_ultimoCierre!.fechaInicio)} – ${Fechas.corta(_ultimoCierre!.fechaFin)}',
                          style: AppTheme.manrope(size: 13.5, weight: FontWeight.w700, color: c.textoOscuro),
                        ),
                      ),
                      if (_ultimoCierre!.total != null)
                        Text(
                          Formato.moneda(_ultimoCierre!.total),
                          style: AppTheme.cormorant(size: 18, color: c.primarioOscuro),
                        ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_dashboard',
        onPressed: _nuevaReserva,
        backgroundColor: AppColors.primario,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Crear reserva'),
      ),
    );
  }

  PreferredSizeWidget _encabezado(ColoresApp c) {
    final sesion = GestorSesion.actual;
    return AppBar(
      backgroundColor: c.fondo,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      toolbarHeight: 64,
      automaticallyImplyLeading: false,
      titleSpacing: 16,
      title: Row(
        children: [
          const MonogramaLumina(tamano: 40),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'LUMINA',
                  style: AppTheme.cormorant(size: 18, color: c.primarioOscuro)
                      .copyWith(letterSpacing: 1.5),
                ),
                Text(
                  'Beauty Center · Panel administrativo',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.manrope(size: 11.5, color: c.textoSutil),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        ValueListenableBuilder<ThemeMode>(
          valueListenable: PreferenciaTema.modo,
          builder: (context, modo, _) => IconButton(
            tooltip: modo == ThemeMode.dark ? 'Modo claro' : 'Modo oscuro',
            onPressed: PreferenciaTema.alternar,
            icon: Icon(
              modo == ThemeMode.dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              color: c.primarioOscuro,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () => abrir(context, const PerfilScreen()),
            child: AvatarIniciales(
              texto: Formato.iniciales(sesion?.nombreVisible ?? 'Usuario'),
              tamano: 36,
            ),
          ),
        ),
      ],
    );
  }

  Widget _saludo(ColoresApp c) {
    final ahora = DateTime.now();
    final sesion = GestorSesion.actual;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(Fechas.fechaLarga(ahora), style: AppTheme.manrope(size: 12, color: c.textoSutil)),
        const SizedBox(height: 2),
        Text(
          '${Fechas.saludo(ahora)}, ${sesion?.nombreVisible ?? ''}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTheme.cormorant(size: 24, color: c.primarioOscuro),
        ),
        Text(
          'Hoy es un buen día para brillar',
          style: AppTheme.manrope(size: 13, color: c.textoSecundario),
        ),
        const SizedBox(height: 8),
        ChipEstado(
          texto: sesion?.rolLegible ?? 'Usuario',
          tono: TonoEstado.info,
          icono: Icons.verified_user_outlined,
        ),
      ],
    );
  }

  Widget _titulo(ColoresApp c, String texto, {Widget? accion}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(texto, style: AppTheme.cormorant(size: 17, color: c.primarioOscuro)),
        ?accion,
      ],
    );
  }

  String _valor(int total) => _cargando ? '…' : '$total';

  Widget _metricas() {
    final atendidas = _hoy.where((r) => r.atendida).length;
    final pendientes = _hoy.where((r) => r.programada).length;
    final canceladas = _hoy.where((r) => r.cancelada).length;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: TarjetaMetrica(
            icono: Icons.verified_outlined,
            valor: _valor(atendidas),
            titulo: 'Atendidas',
            alTocar: () => widget.alCambiarPestana(InicioScreen.pestanaAgenda),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TarjetaMetrica(
            icono: Icons.schedule,
            valor: _valor(pendientes),
            titulo: 'Pendientes',
            alTocar: () => widget.alCambiarPestana(InicioScreen.pestanaAgenda),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TarjetaMetrica(
            icono: Icons.cancel_outlined,
            valor: _valor(canceladas),
            titulo: 'Canceladas',
            alTocar: () => widget.alCambiarPestana(InicioScreen.pestanaAgenda),
          ),
        ),
      ],
    );
  }

  Widget _tarjetaProxima(ColoresApp c) {
    final r = _proxima;
    if (r == null) {
      return TarjetaBase(
        child: Row(
          children: [
            IconoCaja(icono: Icons.free_breakfast_outlined, color: c.acento, fondo: c.acentoFondo),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _cargando ? 'Consultando la agenda...' : 'No hay más citas pendientes por hoy.',
                style: AppTheme.manrope(size: 13, color: c.textoSutil),
              ),
            ),
          ],
        ),
      );
    }
    return TarjetaBase(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              AvatarIniciales(texto: Formato.iniciales(r.clienteNombre ?? 'C'), tamano: 46),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r.clienteNombre ?? 'Cliente',
                        style: AppTheme.cormorant(size: 16, color: c.textoOscuro)),
                    Text(r.servicioNombre ?? 'Servicio',
                        style: AppTheme.manrope(size: 12.5, color: c.textoSutil)),
                  ],
                ),
              ),
              Text(Fechas.hora12(r.fecha),
                  style: AppTheme.manrope(size: 13, weight: FontWeight.w800, color: c.primario)),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            children: [
              ChipEstado(texto: Formato.duracion(r.duracion), tono: TonoEstado.info, icono: Icons.timer_outlined),
              if (r.profesionalNombre != null)
                ChipEstado(
                  texto: r.profesionalNombre!.split(' ').first,
                  tono: TonoEstado.neutro,
                  icono: Icons.face_retouching_natural,
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _verReserva(r),
                  icon: const Icon(Icons.description_outlined, size: 18),
                  label: const Text('Ver detalle'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _marcarAtendida(r),
                  style: FilledButton.styleFrom(backgroundColor: AppColors.verde),
                  icon: const Icon(Icons.verified_outlined, size: 18),
                  label: const Text('Atendida'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _gridModulos(ColoresApp c) {
    return LayoutBuilder(
      builder: (context, restricciones) {
        const columnas = 4;
        const espacio = 10.0;
        final ancho = (restricciones.maxWidth - espacio * (columnas - 1)) / columnas;
        return Wrap(
          spacing: espacio,
          runSpacing: 14,
          children: [
            for (final modulo in _modulos)
              SizedBox(
                width: ancho,
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () async {
                    await abrir(context, modulo.pantalla());
                    if (mounted) _cargar();
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      children: [
                        Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            color: c.superficie,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: c.bordeTarjeta),
                            boxShadow: AppTheme.sombraSuave,
                          ),
                          child: Icon(modulo.icono, color: c.primario, size: 24),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          modulo.texto,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          style: AppTheme.manrope(size: 11.5, weight: FontWeight.w600, color: c.textoOscuro),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  List<Widget> _citasDeHoy() {
    if (_cargando && _hoy.isEmpty) {
      return const [SizedBox(height: 140, child: EstadoCarga(mensaje: 'Consultando la agenda...'))];
    }
    if (_error != null) {
      return [EstadoError(mensaje: _error!, alReintentar: _cargar)];
    }
    if (_hoy.isEmpty) {
      return [
        EstadoVacio(
          icono: Icons.event_available_outlined,
          titulo: 'Sin citas hoy',
          mensaje: 'Las reservas del día aparecerán aquí.',
          textoAccion: 'Crear reserva',
          alAccion: _nuevaReserva,
        ),
      ];
    }
    return [
      for (final r in _hoy.take(5))
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: TarjetaReserva(reserva: r, alTocar: () => _verReserva(r)),
        ),
    ];
  }
}
