import 'package:lumina_app/services/local/gestor_sesion.dart';
import 'package:lumina_app/services/remote/api_service.dart';

Map<String, String> cabecerasAutenticadas() {
  final sesion = GestorSesion.actual;
  if (sesion == null || !sesion.valida) {
    ApiService.alSesionInvalida?.call();
    throw const ApiException(
      'Tu sesión caducó. Inicia sesión de nuevo.',
      statusCode: 401,
    );
  }
  return {'Authorization': 'Bearer ${sesion.token}'};
}
