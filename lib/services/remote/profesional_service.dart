import 'package:lumina_app/domain/fechas.dart';
import 'package:lumina_app/models/comun/pagina.dart';
import 'package:lumina_app/models/profesional/profesional.dart';
import 'package:lumina_app/services/local/catalogo_cache.dart';
import 'package:lumina_app/services/remote/servicio_base.dart';

class ProfesionalService extends ServicioBase {
  static const _ruta = '/api/profesionales';

  
  Future<List<Profesional>> todos() async {
    final lista = await listarTodo(_ruta, Profesional.fromJson);
    lista.sort((a, b) =>
        a.nombreCompleto.toLowerCase().compareTo(b.nombreCompleto.toLowerCase()));
    return lista;
  }

  
  Future<Pagina<Profesional>> listar({
    String busqueda = '',
    int? especialidadId,
    bool? activo,
  }) {
    final q = busqueda.toLowerCase();
    return paginaLocal(
      todos,
      donde: (p) =>
          (q.isEmpty || p.nombreCompleto.toLowerCase().contains(q) || p.documento.contains(q)) &&
          (especialidadId == null || p.especialidadId == especialidadId) &&
          (activo == null || p.activo == activo),
    );
  }

  
  Future<Profesional> obtenerPorId(int id) => obtener('$_ruta/$id', Profesional.fromJson);

  
  
  
  Future<List<Profesional>> porEspecialidad(int especialidadId) async {
    try {
      final lista = await listarTodo(
        '$_ruta/$especialidadId/especialiades',
        Profesional.fromJson,
        headers: cabecerasEmpresa,
      );
      if (lista.isNotEmpty) return lista.where((p) => p.activo).toList();
    } catch (_) {}
    final todosLosProfesionales = await CatalogoCache.profesionales();
    return todosLosProfesionales
        .where((p) => p.activo && p.especialidadId == especialidadId)
        .toList();
  }

  
  Future<Profesional?> porDocumento(String documento) async {
    final lista = await CatalogoCache.profesionales();
    for (final p in lista) {
      if (p.documento == documento.trim()) return p;
    }
    return null;
  }

  
  Future<void> registrar({
    required String documento,
    required String nombres,
    String apellidos = '',
    DateTime? fechaNacimiento,
    required double porcentaje,
    required bool estado,
    required int especialidadId,
  }) async {
    await crear(_ruta, {
      'documento': documento.trim(),
      'nombres': nombres.trim(),
      'apellidos': apellidos.trim(),
      if (fechaNacimiento != null) 'fechaNacimiento': Fechas.api(fechaNacimiento),
      'porcentaje': porcentaje,
      'estado': estado,
      'especialidad': especialidadId,
    });
    CatalogoCache.invalidar();
  }

  
  
  Future<void> editar(
    int id, {
    required String nombres,
    String apellidos = '',
    DateTime? fechaNacimiento,
    required double porcentaje,
    required bool estado,
  }) async {
    await actualizar('$_ruta/$id', {
      'nombres': nombres.trim(),
      'apellidos': apellidos.trim(),
      if (fechaNacimiento != null) 'fechaNacimiento': Fechas.api(fechaNacimiento),
      'porcentaje': porcentaje,
      'estado': estado,
    });
    CatalogoCache.invalidar();
  }

  
  Future<void> borrar(int id) async {
    await eliminar('$_ruta/$id');
    CatalogoCache.invalidar();
  }
}
