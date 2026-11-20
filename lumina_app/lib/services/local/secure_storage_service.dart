import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:lumina_app/models/sesion/sesion.dart';

class SecureStorageService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static const _claveSesion = 'sesion';
  static const _claveTema = 'tema_oscuro';

  Future<void> guardarSesion(Sesion sesion) =>
      _storage.write(key: _claveSesion, value: jsonEncode(sesion.toJson()));

  Future<Sesion?> leerSesion() async {
    try {
      final contenido = await _storage.read(key: _claveSesion);
      if (contenido == null || contenido.isEmpty) return null;
      final json = jsonDecode(contenido);
      return json is Map<String, dynamic> ? Sesion.fromJson(json) : null;
    } catch (_) {
      await borrarSesion();
      return null;
    }
  }

  Future<void> borrarSesion() => _storage.delete(key: _claveSesion);

  Future<void> guardarTemaOscuro(bool oscuro) =>
      _storage.write(key: _claveTema, value: oscuro ? '1' : '0');

  /// Datos locales en JSON (inasistencias, datos extra de reservas).
  Future<dynamic> leerJson(String clave) async {
    try {
      final contenido = await _storage.read(key: clave);
      if (contenido == null || contenido.isEmpty) return null;
      return jsonDecode(contenido);
    } catch (_) {
      return null;
    }
  }

  Future<void> guardarJson(String clave, Object valor) =>
      _storage.write(key: clave, value: jsonEncode(valor));

  Future<bool> leerTemaOscuro() async {
    try {
      return await _storage.read(key: _claveTema) == '1';
    } catch (_) {
      return false;
    }
  }
}
