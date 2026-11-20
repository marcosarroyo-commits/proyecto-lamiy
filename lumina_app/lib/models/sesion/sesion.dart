import 'dart:convert';

import 'package:lumina_app/models/comun/json.dart';

abstract final class Rol {
  /// Rol administrativo de la API Ehily.
  static const gestor = 'GESTOR';
  static const profesional = 'PROFESIONAL';

  static String etiqueta(String rol) => switch (rol) {
    gestor => 'Administrador del centro',
    profesional => 'Profesional',
    _ => rol.isEmpty ? 'Usuario' : rol,
  };
}

/// Sesión iniciada con POST /api/sesion.
///
/// La API devuelve `accessToken` (JWT) con los claims:
/// sub, usuario, role (claim de Microsoft), empresaId, exp.
class Sesion {
  const Sesion({
    required this.token,
    required this.rol,
    required this.username,
    this.idUsuario,
    this.empresaId,
    this.nombre,
    this.expira,
  });

  final String token;
  final String rol;

  /// Usuario con el que inicia sesión (documento).
  final String username;
  final int? idUsuario;

  /// Requerido por los endpoints públicos (header X-Empresa-Id).
  final int? empresaId;

  /// Nombre amigable para el saludo (si se resuelve).
  final String? nombre;
  final DateTime? expira;

  static const _claimRol = 'http://schemas.microsoft.com/ws/2008/06/identity/claims/role';

  factory Sesion.desdeLogin(dynamic respuesta) {
    final json = Json.datos(respuesta);
    final token = Json.texto(json, ['accessToken', 'token', 'access_token']);
    final claims = _claims(token);
    final rolApi = '${claims[_claimRol] ?? claims['role'] ?? Json.texto(json, 'rol')}';
    return Sesion(
      token: token,
      rol: rolApi.toLowerCase().contains('gestor') || rolApi.toLowerCase().contains('admin')
          ? Rol.gestor
          : (rolApi.isEmpty ? Rol.profesional : rolApi.toUpperCase()),
      username: '${claims['usuario'] ?? claims['unique_name'] ?? ''}',
      idUsuario: int.tryParse('${claims['sub'] ?? ''}'),
      empresaId: int.tryParse('${claims['empresaId'] ?? ''}'),
      expira: _expiracion(claims),
    );
  }

  factory Sesion.fromJson(Map<String, dynamic> json) => Sesion(
    token: Json.texto(json, 'token'),
    rol: Json.texto(json, 'rol'),
    username: Json.texto(json, 'username'),
    idUsuario: Json.enteroONulo(json, 'idUsuario'),
    empresaId: Json.enteroONulo(json, 'empresaId'),
    nombre: Json.textoONulo(json, 'nombre'),
    expira: Json.fecha(json, 'expira'),
  );

  Map<String, dynamic> toJson() => {
    'token': token,
    'rol': rol,
    'username': username,
    'idUsuario': idUsuario,
    'empresaId': empresaId,
    'nombre': nombre,
    'expira': expira?.toIso8601String(),
  };

  Sesion conNombre(String? nuevo) => Sesion(
    token: token,
    rol: rol,
    username: username,
    idUsuario: idUsuario,
    empresaId: empresaId,
    nombre: nuevo,
    expira: expira,
  );

  bool get valida =>
      token.isNotEmpty && (expira == null || DateTime.now().isBefore(expira!));

  bool get esGestor => rol == Rol.gestor;

  bool get esProfesional => !esGestor;

  String get rolLegible => Rol.etiqueta(rol);

  String get nombreVisible => nombre ?? (esGestor ? 'Administrador' : username);

  static Map<String, dynamic> _claims(String token) {
    final partes = token.split('.');
    if (partes.length != 3) return const {};
    try {
      final carga = utf8.decode(base64Url.decode(base64Url.normalize(partes[1])));
      final json = jsonDecode(carga);
      return json is Map<String, dynamic> ? json : const {};
    } catch (_) {
      return const {};
    }
  }

  static DateTime? _expiracion(Map<String, dynamic> claims) {
    final exp = claims['exp'];
    return exp is num ? DateTime.fromMillisecondsSinceEpoch(exp.toInt() * 1000) : null;
  }
}
