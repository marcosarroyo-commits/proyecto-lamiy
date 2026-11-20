import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException(this.message, {this.statusCode});

  bool get noEncontrado => statusCode == 404;

  @override
  String toString() => message;
}

class ApiService {
  final String baseUrl;
  final Duration timeout;

  ApiService({
    required this.baseUrl,
    this.timeout = const Duration(seconds: 20),
  });

  static void Function()? alSesionInvalida;

  Map<String, String> _buildHeaders(Map<String, String>? headers) {
    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json; charset=UTF-8',
      ...?headers,
    };
  }

  Uri _buildUrl(String path, [Map<String, String>? queryParameters]) {
    final base = baseUrl.replaceFirst(RegExp(r'/+$'), '');
    final normalizedPath = path.replaceFirst(RegExp(r'^/+'), '');
    final parametros = <String, String>{
      for (final entrada in (queryParameters ?? const {}).entries)
        if (entrada.value.trim().isNotEmpty) entrada.key: entrada.value.trim(),
    };

    return Uri.parse(
      '$base/$normalizedPath',
    ).replace(queryParameters: parametros.isEmpty ? null : parametros);
  }

  String _mensajeDeError(int status, String cuerpo) {
    if (status < 500 && cuerpo.isNotEmpty) {
      try {
        final json = jsonDecode(cuerpo);
        if (json is Map) {
          final errores = json['errors'];
          if (errores is List && errores.isNotEmpty) {
            final primero = errores.first;
            if (primero is String && primero.isNotEmpty) return primero;
          }
          if (errores is Map && errores.isNotEmpty) {
            final primero = errores.values.first;
            if (primero is List && primero.isNotEmpty) {
              return primero.first.toString();
            }
          }
          for (final clave in ['mensaje', 'message', 'detail', 'title']) {
            final valor = json[clave];
            if (valor is String && valor.isNotEmpty) return valor;
          }
        }
      } catch (_) {}
    }

    switch (status) {
      case 400:
        return 'Los datos enviados no son válidos.';
      case 401:
        return 'Usuario o clave incorrectos, o la sesión caducó.';
      case 403:
        return 'No tienes permiso para realizar esta acción.';
      case 404:
        return 'No se encontró lo solicitado.';
      case 409:
        return 'Ya existe un registro con esos datos.';
      case 429:
        return 'Demasiadas solicitudes. Espera un momento e intenta de nuevo.';
      default:
        return status >= 500
            ? 'El servidor tuvo un problema. Intenta de nuevo más tarde.'
            : 'No se pudo completar la solicitud (código $status).';
    }
  }

  Future<dynamic> _send(
    Future<http.Response> Function() request, {
    required bool autenticada,
  }) async {
    try {
      final response = await request().timeout(timeout);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final cuerpo = utf8.decode(response.bodyBytes).trim();
        if (response.statusCode == 401 && autenticada) {
          alSesionInvalida?.call();
          throw const ApiException(
            'Tu sesión caducó. Inicia sesión de nuevo.',
            statusCode: 401,
          );
        }
        throw ApiException(
          _mensajeDeError(response.statusCode, cuerpo),
          statusCode: response.statusCode,
        );
      }

      final content = utf8.decode(response.bodyBytes);
      final json = content.trim().isEmpty ? null : jsonDecode(content);
      
      if (json is Map && json['success'] == false) {
        final mensaje = json['message'] ?? json['mensaje'];
        throw ApiException(
          mensaje is String && mensaje.isNotEmpty
              ? mensaje
              : 'No se pudo completar la operación.',
          statusCode: response.statusCode,
        );
      }
      return json;
    } on TimeoutException {
      throw const ApiException('El servidor tardó demasiado en responder.');
    } on http.ClientException {
      throw const ApiException('No se pudo conectar con el servidor.');
    } on FormatException {
      throw const ApiException('El servidor devolvió una respuesta inválida.');
    }
  }

  bool _esAutenticada(Map<String, String>? headers) =>
      headers?.containsKey('Authorization') ?? false;

  Future<dynamic> get(
    String path, {
    Map<String, String>? queryParameters,
    Map<String, String>? headers,
  }) async {
    final url = _buildUrl(path, queryParameters);
    final requestHeaders = _buildHeaders(headers);
    return _send(
      () => http.get(url, headers: requestHeaders),
      autenticada: _esAutenticada(headers),
    );
  }

  Future<dynamic> post(
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    final url = _buildUrl(path);
    final requestHeaders = _buildHeaders(headers);
    final content = jsonEncode(body ?? const <String, dynamic>{});
    return _send(
      () => http.post(url, headers: requestHeaders, body: content),
      autenticada: _esAutenticada(headers),
    );
  }

  Future<dynamic> put(
    String path, {
    required Map<String, dynamic> body,
    Map<String, String>? headers,
  }) async {
    final url = _buildUrl(path);
    final requestHeaders = _buildHeaders(headers);
    final content = jsonEncode(body);
    return _send(
      () => http.put(url, headers: requestHeaders, body: content),
      autenticada: _esAutenticada(headers),
    );
  }

  Future<dynamic> delete(
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    final url = _buildUrl(path);
    final requestHeaders = _buildHeaders(headers);
    final content = body == null ? null : jsonEncode(body);
    return _send(
      () => http.delete(url, headers: requestHeaders, body: content),
      autenticada: _esAutenticada(headers),
    );
  }
}
