import 'package:lumina_app/models/sesion/sesion.dart';
import 'package:lumina_app/services/local/secure_storage_service.dart';

abstract final class GestorSesion {
  static final SecureStorageService _almacen = SecureStorageService();

  static Sesion? _actual;

  static Sesion? get actual => _actual;

  static Future<void> iniciar(Sesion sesion, {required bool recordar}) async {
    _actual = sesion;
    if (recordar) {
      await _almacen.guardarSesion(sesion);
    } else {
      await _almacen.borrarSesion();
    }
  }

  static Future<Sesion?> restaurar() async {
    final sesion = await _almacen.leerSesion();
    if (sesion == null || !sesion.valida) {
      await _almacen.borrarSesion();
      _actual = null;
      return null;
    }
    _actual = sesion;
    return sesion;
  }

  /// Guarda el nombre real del usuario para el saludo (si la sesión se recuerda).
  static Future<void> actualizarNombre(String nombre) async {
    final anterior = _actual;
    if (anterior == null) return;
    _actual = anterior.conNombre(nombre);
    final guardada = await _almacen.leerSesion();
    if (guardada != null) await _almacen.guardarSesion(_actual!);
  }

  static Future<void> cerrar() async {
    _actual = null;
    await _almacen.borrarSesion();
  }
}
