import 'package:lumina_app/models/comun/pagina.dart';
import 'package:lumina_app/models/inasistencia/inasistencia.dart';
import 'package:lumina_app/services/local/secure_storage_service.dart';
import 'package:lumina_app/services/remote/api_service.dart';

/// Inasistencias de profesionales (la API Ehily no tiene este recurso).
///
/// Se guardan en el dispositivo y la agenda las usa para ocultar los
/// horarios de profesionales ausentes al reservar o reagendar.
class InasistenciaLocalService {
  static const _clave = 'inasistencias';
  static final SecureStorageService _almacen = SecureStorageService();
  static List<Inasistencia>? _cache;

  Future<List<Inasistencia>> todas({int? profesionalId}) async {
    if (_cache == null) {
      final json = await _almacen.leerJson(_clave);
      _cache = json is List
          ? json.whereType<Map<String, dynamic>>().map(Inasistencia.fromJson).toList()
          : [];
    }
    final lista = profesionalId == null
        ? [..._cache!]
        : _cache!.where((i) => i.profesionalId == profesionalId).toList();
    lista.sort((a, b) => a.fechaInicio.compareTo(b.fechaInicio));
    return lista;
  }

  /// Próximas (vigentes o futuras) o historial.
  Future<Pagina<Inasistencia>> listar({required bool proximas}) async {
    final hoy = DateTime.now();
    final inicioHoy = DateTime(hoy.year, hoy.month, hoy.day);
    final lista = (await todas())
        .where((i) => proximas ? !i.fechaFin.isBefore(inicioHoy) : i.fechaFin.isBefore(inicioHoy))
        .toList();
    if (!proximas) lista.sort((a, b) => b.fechaInicio.compareTo(a.fechaInicio));
    return Pagina.completa(lista);
  }

  /// Crea o actualiza. Valida el rango y que no se cruce con otra.
  Future<void> guardar(Inasistencia nueva) async {
    if (nueva.fechaFin.isBefore(nueva.fechaInicio)) {
      throw const ApiException('La fecha final debe ser igual o posterior a la inicial.');
    }
    final existentes = await todas();
    final cruce = existentes.any((i) =>
        i.id != nueva.id &&
        i.profesionalId == nueva.profesionalId &&
        i.seCruzaCon(nueva.fechaInicio, nueva.fechaFin));
    if (cruce) {
      throw const ApiException('El profesional ya tiene una inasistencia en esas fechas.');
    }
    _cache!
      ..removeWhere((i) => i.id == nueva.id)
      ..add(nueva);
    await _persistir();
  }

  Future<void> eliminar(String id) async {
    await todas();
    _cache!.removeWhere((i) => i.id == id);
    await _persistir();
  }

  Future<Set<int>> ausentesEn(DateTime fecha) async =>
      (await todas()).where((i) => i.cubre(fecha)).map((i) => i.profesionalId).toSet();

  Future<void> _persistir() =>
      _almacen.guardarJson(_clave, _cache!.map((i) => i.toJson()).toList());
}
