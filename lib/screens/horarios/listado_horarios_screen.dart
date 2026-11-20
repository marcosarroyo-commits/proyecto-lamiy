import 'package:flutter/material.dart';
import 'package:lumina_app/domain/app_theme.dart';
import 'package:lumina_app/domain/dias_semana.dart';
import 'package:lumina_app/domain/formatos.dart';
import 'package:lumina_app/models/horario/horario_laboral.dart';
import 'package:lumina_app/models/profesional/profesional.dart';
import 'package:lumina_app/routes/app_routes.dart';
import 'package:lumina_app/screens/horarios/horario_profesional_screen.dart';
import 'package:lumina_app/services/local/catalogo_cache.dart';
import 'package:lumina_app/services/remote/api_service.dart';
import 'package:lumina_app/services/remote/horario_service.dart';
import 'package:lumina_app/theme/colores_app.dart';
import 'package:lumina_app/widgets/encabezado_modulo.dart';
import 'package:lumina_app/widgets/estados_vista.dart';
import 'package:lumina_app/widgets/marco_pantalla.dart';
import 'package:lumina_app/widgets/tarjeta_base.dart';


class ListadoHorariosScreen extends StatefulWidget {
  const ListadoHorariosScreen({super.key});

  @override
  State<ListadoHorariosScreen> createState() => _ListadoHorariosScreenState();
}

class _ListadoHorariosScreenState extends State<ListadoHorariosScreen> {
  List<Profesional> _profesionales = const [];
  Map<int, List<HorarioLaboral>> _porProfesional = const {};
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
      final profesionales = await CatalogoCache.profesionales();
      final horarios = await HorarioService().todos();
      final mapa = <int, List<HorarioLaboral>>{};
      for (final h in horarios) {
        mapa.putIfAbsent(h.profesionalId, () => []).add(h);
      }
      if (!mounted) return;
      setState(() {
        _profesionales = profesionales.where((p) => p.activo).toList();
        _porProfesional = mapa;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    Widget cuerpo;
    if (_cargando && _profesionales.isEmpty) {
      cuerpo = const EstadoCarga(mensaje: 'Consultando horarios...');
    } else if (_error != null) {
      cuerpo = EstadoError(mensaje: _error!, alReintentar: _cargar);
    } else if (_profesionales.isEmpty) {
      cuerpo = const EstadoVacio(
        icono: Icons.schedule,
        titulo: 'Sin profesionales activos',
        mensaje: 'Registra profesionales para configurar sus horarios.',
      );
    } else {
      cuerpo = RefreshIndicator(
        onRefresh: _cargar,
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          itemCount: _profesionales.length + 1,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, i) {
            if (i == 0) {
              return Text(
                'Selecciona un profesional para consultar o editar su semana.',
                style: AppTheme.manrope(size: 13, color: c.textoSutil),
              );
            }
            final p = _profesionales[i - 1];
            final horarios = _porProfesional[p.id] ?? const <HorarioLaboral>[];
            final dias = horarios.map((h) => h.diaSemana).toSet();
            final horas = horarios.fold<int>(0, (a, h) => a + h.minutosLaborales) / 60;
            return TarjetaBase(
              alTocar: () async {
                await abrir(context, HorarioProfesionalScreen(profesional: p));
                if (mounted) _cargar();
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      AvatarIniciales(texto: Formato.iniciales(p.nombreCompleto), tamano: 40),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.nombreCompleto, style: AppTheme.cormorant(size: 16, color: c.textoOscuro)),
                            Text(
                              horarios.isEmpty
                                  ? 'Sin horario configurado'
                                  : '${dias.length} día(s) · ${Formato.horas(horas)} semanales',
                              style: AppTheme.manrope(size: 12, color: c.textoSutil),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right, color: c.textoSutil),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      for (final d in DiasSemana.orden)
                        Container(
                          width: 34,
                          height: 34,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: dias.contains(d) ? AppColors.primario : c.bordeTarjeta,
                          ),
                          child: Text(
                            DiasSemana.inicial(d),
                            style: AppTheme.manrope(
                              size: 12.5,
                              weight: FontWeight.w800,
                              color: dias.contains(d) ? Colors.white : c.hint,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      );
    }
    return Scaffold(
      backgroundColor: c.fondo,
      appBar: const EncabezadoModulo(titulo: 'Horarios', subtitulo: 'Disponibilidad semanal del equipo'),
      body: ContenidoCentrado(child: cuerpo),
    );
  }
}
