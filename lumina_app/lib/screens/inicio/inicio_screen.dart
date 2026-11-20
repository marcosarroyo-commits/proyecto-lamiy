import 'package:flutter/material.dart';
import 'package:lumina_app/domain/app_theme.dart';
import 'package:lumina_app/routes/app_routes.dart';
import 'package:lumina_app/screens/agenda/agenda_screen.dart';
import 'package:lumina_app/screens/cierres/listado_cierres_screen.dart';
import 'package:lumina_app/screens/clientes/listado_clientes_screen.dart';
import 'package:lumina_app/screens/comisiones/listado_comisiones_screen.dart';
import 'package:lumina_app/screens/especialidades/listado_especialidades_screen.dart';
import 'package:lumina_app/screens/horarios/listado_horarios_screen.dart';
import 'package:lumina_app/screens/inasistencias/listado_inasistencias_screen.dart';
import 'package:lumina_app/screens/inicio/dashboard_screen.dart';
import 'package:lumina_app/screens/mi_cuenta/inicio_profesional_screen.dart';
import 'package:lumina_app/screens/mi_cuenta/mis_servicios_screen.dart';
import 'package:lumina_app/screens/perfil/perfil_screen.dart';
import 'package:lumina_app/screens/profesionales/listado_profesionales_screen.dart';
import 'package:lumina_app/screens/servicios/listado_servicios_screen.dart';
import 'package:lumina_app/services/local/gestor_sesion.dart';
import 'package:lumina_app/theme/colores_app.dart';
import 'package:lumina_app/widgets/marco_pantalla.dart';
import 'package:lumina_app/widgets/panel_secciones.dart';

class _Pestana {
  const _Pestana(this.icono, this.iconoActivo, this.texto);

  final IconData icono;
  final IconData iconoActivo;
  final String texto;
}

class InicioScreen extends StatefulWidget {
  const InicioScreen({super.key});

  /// Permite que otra pantalla pida cambiar de pestaña (ej. "Ir a la agenda"
  /// después de crear una reserva).
  static final ValueNotifier<int?> pestanaSolicitada = ValueNotifier<int?>(null);
  /// Índice de "Reservas" (agenda) en el panel administrativo.
  static const pestanaAgenda = 4;

  @override
  State<InicioScreen> createState() => _InicioScreenState();
}

class _InicioScreenState extends State<InicioScreen> {
  int _indice = 0;
  final Set<int> _visitadas = {0};

  // Las 5 pestañas del diseño: Inicio · Catálogo · Equipo · Finanzas · Reservas.
  static const _pestanasAdministrativas = [
    _Pestana(Icons.home_outlined, Icons.home_rounded, 'Inicio'),
    _Pestana(Icons.menu_book_outlined, Icons.menu_book, 'Catálogo'),
    _Pestana(Icons.groups_outlined, Icons.groups, 'Equipo'),
    _Pestana(Icons.account_balance_wallet_outlined, Icons.account_balance_wallet, 'Finanzas'),
    _Pestana(Icons.calendar_month_outlined, Icons.calendar_month, 'Reservas'),
  ];

  static const _pestanasProfesional = [
    _Pestana(Icons.grid_view_outlined, Icons.grid_view_rounded, 'Inicio'),
    _Pestana(Icons.content_cut_outlined, Icons.content_cut, 'Mis servicios'),
    _Pestana(Icons.calendar_month_outlined, Icons.calendar_month, 'Mi agenda'),
    _Pestana(Icons.person_outline, Icons.person, 'Perfil'),
  ];

  @override
  void initState() {
    super.initState();
    InicioScreen.pestanaSolicitada.addListener(_alSolicitarPestana);
    if (GestorSesion.actual == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (ruta) => false);
      });
    }
  }

  @override
  void dispose() {
    InicioScreen.pestanaSolicitada.removeListener(_alSolicitarPestana);
    super.dispose();
  }

  void _alSolicitarPestana() {
    final indice = InicioScreen.pestanaSolicitada.value;
    if (indice == null || !mounted) return;
    InicioScreen.pestanaSolicitada.value = null;
    _irA(indice);
  }

  void _irA(int indice) {
    setState(() {
      _indice = indice;
      _visitadas.add(indice);
    });
  }

  List<Widget> _paginas(bool esProfesional) {
    if (esProfesional) {
      return [
        InicioProfesionalScreen(alCambiarPestana: _irA),
        const MisServiciosScreen(),
        const AgendaScreen(soloLectura: true),
        const PerfilScreen(),
      ];
    }
    return [
      DashboardScreen(alCambiarPestana: _irA),
      const PanelSecciones(secciones: [
        SeccionPanel('Clientes', Icons.people_outline, ListadoClientesScreen()),
        SeccionPanel('Especialidades', Icons.auto_awesome_outlined, ListadoEspecialidadesScreen()),
        SeccionPanel('Servicios', Icons.content_cut_outlined, ListadoServiciosScreen()),
      ]),
      const PanelSecciones(secciones: [
        SeccionPanel('Profesionales', Icons.face_retouching_natural, ListadoProfesionalesScreen()),
        SeccionPanel('Horarios', Icons.schedule, ListadoHorariosScreen()),
        SeccionPanel('Inasistencias', Icons.event_busy_outlined, ListadoInasistenciasScreen()),
      ]),
      const PanelSecciones(secciones: [
        SeccionPanel('Cierres', Icons.receipt_long_outlined, ListadoCierresScreen()),
        SeccionPanel('Comisiones', Icons.percent, ListadoComisionesScreen()),
      ]),
      const AgendaScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final sesion = GestorSesion.actual;
    if (sesion == null) {
      return Scaffold(backgroundColor: context.colores.fondo);
    }

    final paginas = _paginas(sesion.esProfesional);
    final pestanas = sesion.esProfesional ? _pestanasProfesional : _pestanasAdministrativas;

    return Scaffold(
      body: IndexedStack(
        index: _indice,
        children: [
          for (var i = 0; i < paginas.length; i++)
            _visitadas.contains(i) ? paginas[i] : const SizedBox.shrink(),
        ],
      ),
      bottomNavigationBar: _BarraNavegacion(
        pestanas: pestanas,
        indice: _indice,
        alSeleccionar: _irA,
      ),
    );
  }
}

class _BarraNavegacion extends StatelessWidget {
  const _BarraNavegacion({
    required this.pestanas,
    required this.indice,
    required this.alSeleccionar,
  });

  final List<_Pestana> pestanas;
  final int indice;
  final ValueChanged<int> alSeleccionar;

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    return Container(
      decoration: BoxDecoration(
        color: c.superficie,
        border: Border(top: BorderSide(color: c.bordeTarjeta)),
      ),
      child: SafeArea(
        top: false,
        child: ContenidoCentrado(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
            child: Row(
              children: [
                for (var i = 0; i < pestanas.length; i++)
                  Expanded(
                    child: _ItemNavegacion(
                      pestana: pestanas[i],
                      activo: i == indice,
                      alTocar: () => alSeleccionar(i),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ItemNavegacion extends StatelessWidget {
  const _ItemNavegacion({
    required this.pestana,
    required this.activo,
    required this.alTocar,
  });

  final _Pestana pestana;
  final bool activo;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    final color = activo ? c.primario : c.textoGris;

    return InkWell(
      onTap: alTocar,
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 54,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
              decoration: BoxDecoration(
                color: activo ? c.badgeFondo : Colors.transparent,
                borderRadius: BorderRadius.circular(9999),
              ),
              child: Icon(activo ? pestana.iconoActivo : pestana.icono, size: 22, color: color),
            ),
            const SizedBox(height: 4),
            Text(
              pestana.texto,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.manrope(
                size: 11,
                weight: activo ? FontWeight.w700 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
