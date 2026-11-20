import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:lumina_app/config/app_config.dart';
import 'package:lumina_app/domain/app_theme.dart';
import 'package:lumina_app/routes/app_routes.dart';
import 'package:lumina_app/services/local/catalogo_cache.dart';
import 'package:lumina_app/services/local/gestor_sesion.dart';
import 'package:lumina_app/services/remote/api_service.dart';
import 'package:lumina_app/theme/preferencia_tema.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await PreferenciaTema.cargar();
  ApiService.alSesionInvalida = ControlSesion.expirar;
  runApp(const MainApp());
}


abstract final class ControlSesion {
  static bool _redirigiendo = false;

  static Future<void> expirar() async {
    if (_redirigiendo) return;
    _redirigiendo = true;
    await GestorSesion.cerrar();
    CatalogoCache.invalidar();
    AppRoutes.navegador.currentState?.pushNamedAndRemoveUntil(
      AppRoutes.login,
      (ruta) => false,
      arguments: 'Tu sesión expiró o no es válida. Inicia sesión nuevamente.',
    );
    _redirigiendo = false;
  }
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: PreferenciaTema.modo,
      builder: (context, modo, _) {
        return MaterialApp(
          title: AppConfig.nombreApp,
          debugShowCheckedModeBanner: false,
          navigatorKey: AppRoutes.navegador,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: modo,
          locale: const Locale('es', 'CO'),
          supportedLocales: const [Locale('es', 'CO'), Locale('es')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          builder: (context, child) {
            final oscuro = Theme.of(context).brightness == Brightness.dark;
            return AnnotatedRegion<SystemUiOverlayStyle>(
              value: oscuro ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
              child: child!,
            );
          },
          initialRoute: AppRoutes.splash,
          onGenerateRoute: AppRoutes.generar,
        );
      },
    );
  }
}
