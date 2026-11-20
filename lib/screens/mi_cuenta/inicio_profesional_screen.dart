import 'package:flutter/material.dart';
import 'package:lumina_app/domain/app_theme.dart';
import 'package:lumina_app/domain/fechas.dart';
import 'package:lumina_app/domain/formatos.dart';
import 'package:lumina_app/models/profesional/profesional.dart';
import 'package:lumina_app/models/reserva/reserva.dart';
import 'package:lumina_app/routes/app_routes.dart';
import 'package:lumina_app/screens/horarios/horario_profesional_screen.dart';
import 'package:lumina_app/screens/reservas/detalle_reserva_screen.dart';
import 'package:lumina_app/services/local/gestor_sesion.dart';
import 'package:lumina_app/services/remote/api_service.dart';
import 'package:lumina_app/services/remote/profesional_service.dart';
import 'package:lumina_app/services/remote/reserva_service.dart';
import 'package:lumina_app/theme/colores_app.dart';
import 'package:lumina_app/theme/preferencia_tema.dart';
import 'package:lumina_app/widgets/chip_estado.dart';
import 'package:lumina_app/widgets/estados_vista.dart';
import 'package:lumina_app/widgets/logo_lumina.dart';
import 'package:lumina_app/widgets/marco_pantalla.dart';
import 'package:lumina_app/widgets/seccion_detalle.dart';
import 'package:lumina_app/widgets/tarjeta_base.dart';
import 'package:lumina_app/widgets/tarjeta_metrica.dart';
import 'package:lumina_app/widgets/tarjeta_reserva.dart';


class InicioProfesionalScreen extends StatefulWidget {
  const InicioProfesionalScreen({super.key, required this.alCambiarPestana});

  final ValueChanged<int> alCambiarPestana;

  @override
  State<InicioProfesionalScreen> createState() => _InicioProfesionalScreenState();
}

class _InicioProfesionalScreenState extends State<InicioProfesionalScreen> {
  Profesional? _yo;
  List<Reserva> _hoy = const [];
  bool _cargando = true;
  String? _error;

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
      _yo ??= await ProfesionalService().porDocumento(GestorSesion.actual?.username ?? '');
      final hoy = Fechas.hoy;
      final reservas = await ReservaService().entre(hoy, hoy);
      if (!mounted) return;
      setState(() => _hoy = reservas.where((r) => _yo == null || r.profesionalId == _yo!.id).toList());
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    final sesion = GestorSesion.actual;
    final ahora = DateTime.now();
    final pendientes = _hoy.where((r) => r.programada).length;
    final atendidas = _hoy.where((r) => r.atendida).length;
    final vendido = _hoy.where((r) => r.atendida).fold<int>(0, (a, r) => a + (r.precio ?? 0));

    return Scaffold(
      backgroundColor: c.fondo,
      appBar: AppBar(
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
            Text('LUMINA', style: AppTheme.cormorant(size: 18, color: c.primarioOscuro).copyWith(letterSpacing: 1.5)),
          ],
        ),
        actions: [
          ValueListenableBuilder<ThemeMode>(
            valueListenable: PreferenciaTema.modo,
            builder: (context, modo, _) => IconButton(
              tooltip: modo == ThemeMode.dark ? 'Modo claro' : 'Modo oscuro',
              onPressed: PreferenciaTema.alternar,
              icon: Icon(modo == ThemeMode.dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                  color: c.primarioOscuro),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => widget.alCambiarPestana(3),
              child: AvatarIniciales(texto: Formato.iniciales(sesion?.nombreVisible ?? 'P'), tamano: 36),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _cargar,
        child: ContenidoCentrado(
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              Text(Fechas.fechaLarga(ahora), style: AppTheme.manrope(size: 12, color: c.textoSutil)),
              Text('${Fechas.saludo(ahora)}, ${sesion?.nombreVisible ?? ''}',
                  style: AppTheme.cormorant(size: 24, color: c.primarioOscuro)),
              const SizedBox(height: 8),
              ChipEstado(
                texto: _yo?.especialidadNombre ?? sesion?.rolLegible ?? 'Profesional',
                tono: TonoEstado.info,
                icono: Icons.verified_user_outlined,
              ),
              if (_yo == null && !_cargando) ...[
                const SizedBox(height: 12),
                const Aviso(
                  titulo: 'Perfil no vinculado',
                  mensaje: 'Tu usuario no coincide con el documento de un profesional registrado. '
                      'Se muestran las reservas del día sin filtrar.',
                  tono: TonoEstado.alerta,
                ),
              ],
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(child: TarjetaMetrica(icono: Icons.schedule, valor: '$pendientes', titulo: 'Pendientes hoy')),
                  const SizedBox(width: 8),
                  Expanded(child: TarjetaMetrica(icono: Icons.verified_outlined, valor: '$atendidas', titulo: 'Atendidas')),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TarjetaMetrica(icono: Icons.payments_outlined, valor: Formato.moneda(vendido), titulo: 'Vendido hoy'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => widget.alCambiarPestana(1),
                      icon: const Icon(Icons.content_cut_outlined, size: 18),
                      label: const Text('Mis servicios'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _yo == null ? null : () => abrir(context, HorarioProfesionalScreen(profesional: _yo!)),
                      icon: const Icon(Icons.schedule, size: 18),
                      label: const Text('Mi horario'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(child: Text('Mis citas de hoy', style: AppTheme.cormorant(size: 17, color: c.primarioOscuro))),
                  TextButton(onPressed: () => widget.alCambiarPestana(2), child: const Text('Ver agenda')),
                ],
              ),
              if (_cargando && _hoy.isEmpty)
                const SizedBox(height: 140, child: EstadoCarga(mensaje: 'Consultando tus citas...'))
              else if (_error != null)
                EstadoError(mensaje: _error!, alReintentar: _cargar)
              else if (_hoy.isEmpty)
                TarjetaBase(
                  child: Row(children: [
                    IconoCaja(icono: Icons.free_breakfast_outlined, color: c.acento, fondo: c.acentoFondo),
                    const SizedBox(width: 12),
                    Expanded(child: Text('No tienes citas programadas hoy.', style: AppTheme.manrope(size: 13, color: c.textoSutil))),
                  ]),
                )
              else
                for (final r in _hoy)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: TarjetaReserva(reserva: r, alTocar: () => abrir(context, DetalleReservaScreen(reserva: r))),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
