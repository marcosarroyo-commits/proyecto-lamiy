import 'package:flutter/material.dart';
import 'package:lumina_app/screens/auth/login_screen.dart';
import 'package:lumina_app/screens/auth/recuperar_contrasena_screen.dart';
import 'package:lumina_app/screens/auth/verificar_otp_screen.dart';
import 'package:lumina_app/screens/inicio/inicio_screen.dart';
import 'package:lumina_app/screens/inicio/splash_screen.dart';

abstract final class AppRoutes {
  static final GlobalKey<NavigatorState> navegador = GlobalKey<NavigatorState>();

  static const String splash = '/';
  static const String login = '/login';
  static const String recuperar = '/recuperar';
  static const String verificarOtp = '/verificar-otp';
  static const String inicio = '/inicio';

  static Route<dynamic> generar(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return _ruta(const SplashScreen(), settings);
      case login:
        final mensaje = settings.arguments as String?;
        return _ruta(LoginScreen(mensaje: mensaje), settings);
      case recuperar:
        return _ruta(const RecuperarContrasenaScreen(), settings);
      case verificarOtp:
        final usuario = settings.arguments as String? ?? '';
        return _ruta(VerificarOtpScreen(usuario: usuario), settings);
      case inicio:
        return _ruta(const InicioScreen(), settings);
      default:
        return _ruta(const SplashScreen(), settings);
    }
  }

  static MaterialPageRoute<dynamic> _ruta(
    Widget pantalla,
    RouteSettings settings,
  ) {
    return MaterialPageRoute(builder: (_) => pantalla, settings: settings);
  }
}

/// Abre una pantalla interna y devuelve lo que esta entregue al cerrar.
Future<T?> abrir<T>(BuildContext context, Widget pantalla) {
  return Navigator.of(
    context,
  ).push<T>(MaterialPageRoute<T>(builder: (_) => pantalla));
}
