import 'package:lumina_app/services/local/secure_storage_service.dart';





abstract final class ReservaLocalService {
  static const _clave = 'reservas_extra';
  static final SecureStorageService _almacen = SecureStorageService();
  static Map<String, Map<String, dynamic>>? _datos;

  static Future<Map<String, Map<String, dynamic>>> todos() async {
    if (_datos != null) return _datos!;
    final json = await _almacen.leerJson(_clave);
    _datos = {
      if (json is Map)
        for (final e in json.entries)
          if (e.value is Map) '${e.key}': Map<String, dynamic>.from(e.value as Map),
    };
    return _datos!;
  }

  static Future<Map<String, dynamic>> de(int reservaId) async =>
      (await todos())['$reservaId'] ?? const {};

  static Future<void> guardar(int reservaId, String campo, Object? valor) async {
    final datos = await todos();
    datos.putIfAbsent('$reservaId', () => {})[campo] = valor;
    await _almacen.guardarJson(_clave, datos);
  }
}
