import 'package:lumina_app/config/app_config.dart';
import 'package:lumina_app/models/comun/json.dart';
import 'package:lumina_app/models/comun/pagina.dart';
import 'package:lumina_app/services/local/gestor_sesion.dart';
import 'package:lumina_app/services/remote/api_service.dart';
import 'package:lumina_app/services/remote/cabeceras_autenticadas.dart';

abstract class ServicioBase {
  final ApiService api = ApiService(baseUrl: AppConfig.apiBaseUrl);

  Map<String, String> get cabeceras => cabecerasAutenticadas();

  /// Endpoints públicos de la API (reserva de primera vez, profesionales por
  /// especialidad) que se identifican con la empresa en lugar del token.
  Map<String, String> get cabecerasEmpresa {
    final empresa = GestorSesion.actual?.empresaId;
    if (empresa == null) {
      throw const ApiException('No se encontró la empresa de la sesión.');
    }
    return {'X-Empresa-Id': '$empresa'};
  }

  /// La API Ehily devuelve listas completas: se convierten y se entregan
  /// como una sola página para reutilizar VistaPaginada.
  Future<List<T>> listarTodo<T>(
    String ruta,
    T Function(Map<String, dynamic> json) convertir, {
    Map<String, String> filtros = const {},
    Map<String, String>? headers,
  }) async {
    final respuesta = await api.get(
      ruta,
      queryParameters: filtros,
      headers: headers ?? cabeceras,
    );
    return _convertir(() => Json.lista(respuesta).map(convertir).toList());
  }

  Future<Pagina<T>> paginaLocal<T>(
    Future<List<T>> Function() cargar, {
    bool Function(T item)? donde,
  }) async {
    final items = await cargar();
    return Pagina.completa(donde == null ? items : items.where(donde).toList());
  }

  Future<T> obtener<T>(
    String ruta,
    T Function(Map<String, dynamic> json) convertir,
  ) async {
    final respuesta = await api.get(ruta, headers: cabeceras);
    final datos = Json.datos(respuesta);
    if (datos.isEmpty) throw const ApiException('No se encontró lo solicitado.', statusCode: 404);
    return _convertir(() => convertir(datos));
  }

  /// POST que devuelve la respuesta tal cual (algunos endpoints solo
  /// responden con un id o un mensaje).
  Future<dynamic> crear(
    String ruta,
    Map<String, dynamic> cuerpo, {
    bool publico = false,
  }) {
    return api.post(ruta, body: cuerpo, headers: publico ? cabecerasEmpresa : cabeceras);
  }

  Future<dynamic> actualizar(String ruta, Map<String, dynamic> cuerpo) {
    return api.put(ruta, body: cuerpo, headers: cabeceras);
  }

  Future<void> eliminar(String ruta, {Map<String, dynamic>? cuerpo}) async {
    await api.delete(ruta, body: cuerpo, headers: cabeceras);
  }

  T _convertir<T>(T Function() accion) {
    try {
      return accion();
    } on TypeError {
      throw const ApiException('El servidor devolvió una respuesta inesperada.');
    }
  }
}
