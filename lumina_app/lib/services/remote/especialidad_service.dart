import 'package:lumina_app/models/comun/pagina.dart';
import 'package:lumina_app/models/especialidad/especialidad.dart';
import 'package:lumina_app/services/local/catalogo_cache.dart';
import 'package:lumina_app/services/remote/servicio_base.dart';

class EspecialidadService extends ServicioBase {
  static const _ruta = '/api/especialidades';

  /// GET /api/especialidades
  Future<List<Especialidad>> todas() async {
    final lista = await listarTodo(_ruta, Especialidad.fromJson);
    lista.sort((a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()));
    return lista;
  }

  /// Búsqueda por nombre y filtro por estado (en la app).
  Future<Pagina<Especialidad>> listar({String busqueda = '', bool? activa}) {
    final q = busqueda.toLowerCase();
    return paginaLocal(
      todas,
      donde: (e) =>
          (q.isEmpty || e.nombre.toLowerCase().contains(q)) &&
          (activa == null || e.activa == activa),
    );
  }

  /// GET /api/especialidades/{id}
  Future<Especialidad> obtenerPorId(int id) => obtener('$_ruta/$id', Especialidad.fromJson);

  /// POST /api/especialidades  { nombre }
  Future<void> registrar(String nombre) async {
    await crear(_ruta, {'nombre': nombre.trim()});
    CatalogoCache.invalidar();
  }

  /// PUT /api/especialidades/{id}  { nombre, activa }
  Future<void> editar(int id, {required String nombre, required bool activa}) async {
    await actualizar('$_ruta/$id', {'nombre': nombre.trim(), 'activa': activa});
    CatalogoCache.invalidar();
  }

  /// DELETE /api/especialidades/{id}
  Future<void> borrar(int id) async {
    await eliminar('$_ruta/$id');
    CatalogoCache.invalidar();
  }
}
