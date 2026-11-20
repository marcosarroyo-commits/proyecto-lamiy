import 'package:lumina_app/config/app_config.dart';
import 'package:lumina_app/models/login/login_request.dart';
import 'package:lumina_app/models/sesion/sesion.dart';
import 'package:lumina_app/services/remote/api_service.dart';

class LoginService {
  final ApiService _api = ApiService(baseUrl: AppConfig.apiBaseUrl);

  /// POST /api/sesion  { usuario, clave }  →  { accessToken }
  Future<Sesion> login(LoginRequest request) async {
    try {
      final respuesta = await _api.post('/api/sesion', body: request.toJson());
      final sesion = Sesion.desdeLogin(respuesta);
      if (sesion.token.isEmpty) {
        throw const ApiException('El servidor devolvió una respuesta inesperada.');
      }
      return sesion;
    } on ApiException catch (e) {
      if (e.statusCode == 400 || e.statusCode == 401 || e.statusCode == 404) {
        throw ApiException('Usuario o clave incorrectos.', statusCode: e.statusCode);
      }
      rethrow;
    }
  }
}
