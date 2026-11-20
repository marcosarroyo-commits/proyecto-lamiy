import 'package:lumina_app/models/comun/pagina.dart';
import 'package:lumina_app/models/servicio/servicio.dart';
import 'package:lumina_app/services/local/catalogo_cache.dart';
import 'package:lumina_app/services/remote/servicio_base.dart';


class ServicioService extends ServicioBase {
  static const _ruta = '/api/servicios';

  
  Future<List<Servicio>> todos() async {
    final lista = await listarTodo(_ruta, Servicio.fromJson);
    lista.sort((a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()));
    return lista;
  }

  Future<Pagina<Servicio>> listar({
    String busqueda = '',
    int? especialidadId,
    bool? activo,
  }) {
    final q = busqueda.toLowerCase();
    return paginaLocal(
      todos,
      donde: (s) =>
          (q.isEmpty ||
              s.nombre.toLowerCase().contains(q) ||
              '${s.id}' == q ||
              s.codigo.toLowerCase().contains(q)) &&
          (especialidadId == null || s.especialidadId == especialidadId) &&
          (activo == null || s.activo == activo),
    );
  }

  /// GET /api/servicios/{id}
  Future<Servicio> obtenerPorId(int id) => obtener('$_ruta/$id', Servicio.fromJson);

  /// POST /api/servicios
  Future<void> registrar({
    required String nombre,
    required int precio,
    required String descripcion,
    required int duracion,
    required int especialidadId,
  }) async {
    await crear(_ruta, {
      'nombre': nombre.trim(),
      'precio': precio,
      'descripcion': descripcion.trim(),
      'duracion': duracion,
      'especialidad': especialidadId,
    });
    CatalogoCache.invalidar();
  }

  /// PUT /api/servicios/{id}
  /// Regla de negocio: descripción y especialidad no se modifican.
  Future<void> editar(
    int id, {
    required String nombre,
    required int precio,
    required int duracion,
    required bool activo,
  }) async {
    await actualizar('$_ruta/$id', {
      'nombre': nombre.trim(),
      'precio': precio,
      'duracion': duracion,
      'activo': activo,
    });
    CatalogoCache.invalidar();
  }

  /// DELETE /api/servicios/{id}
  Future<void> borrar(int id) async {
    await eliminar('$_ruta/$id');
    CatalogoCache.invalidar();
  }
}
