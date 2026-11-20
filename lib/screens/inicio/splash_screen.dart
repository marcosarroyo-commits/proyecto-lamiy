import 'package:flutter/material.dart';
import 'package:lumina_app/config/app_config.dart';
import 'package:lumina_app/domain/app_theme.dart';
import 'package:lumina_app/routes/app_routes.dart';
import 'package:lumina_app/services/local/gestor_sesion.dart';
import 'package:lumina_app/theme/colores_app.dart';
import 'package:lumina_app/widgets/logo_lumina.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _iniciar();
  }

  Future<void> _iniciar() async {
    final resultados = await Future.wait<Object?>([
      GestorSesion.restaurar(),
      Future<void>.delayed(const Duration(milliseconds: 1600)),
    ]);
    if (!mounted) return;
    final haySesion = resultados.first != null;
    Navigator.pushReplacementNamed(
      context,
      haySesion ? AppRoutes.inicio : AppRoutes.login,
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    return Scaffold(
      backgroundColor: c.superficie,
      body: Stack(
        children: [
          const Positioned(
            top: -10,
            right: -70,
            width: 290,
            child: RamaDecorativa(),
          ),
          const Positioned(
            bottom: -10,
            left: -70,
            width: 290,
            child: RamaDecorativa(arriba: false),
          ),
          SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 3),
                const LogoLumina(ancho: 240, alto: 130),
                const SizedBox(height: 16),
                Text(
                  'Administración del centro',
                  style: AppTheme.manrope(
                    size: 12,
                    weight: FontWeight.w700,
                    color: c.acento,
                  ).copyWith(letterSpacing: 2),
                ),
                const Spacer(flex: 2),
                SizedBox(
                  width: 140,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(9999),
                    child: LinearProgressIndicator(
                      minHeight: 4,
                      color: c.acento,
                      backgroundColor: c.acentoFondo,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Verificando sesión...',
                  style: AppTheme.manrope(size: 12, color: c.textoSutil),
                ),
                const SizedBox(height: 40),
                Text(
                  'Lumina Beauty · v${AppConfig.version}',
                  style: AppTheme.manrope(
                    size: 11,
                    weight: FontWeight.w600,
                    color: c.hint,
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
