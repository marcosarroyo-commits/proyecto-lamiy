import 'package:lumina_app/models/comision/comision.dart';
import 'package:lumina_app/services/local/catalogo_cache.dart';
import 'package:lumina_app/services/remote/servicio_base.dart';

class ComisionService extends ServicioBase {
  static const _ruta = '/api/comisiones';

  /// GET /api/comisiones  ·  ?cierreId=…  ·  ?profesionalId=…
  /// La API filtra por uno de los dos; si se envían ambos, el segundo se
  /// aplica en la app.
  Future<List<Comision>> listar({int? cierreId, int? profesionalId}) async {
    final lista = await listarTodo(_ruta, Comision.fromJson, filtros: {
      if (cierreId != null) 'cierreId': '$cierreId',
      if (cierreId == null && profesionalId != null) 'profesionalId': '$profesionalId',
    });
    await CatalogoCache.precargar();
    final salida = lista
        .map((c) {
          final p = CatalogoCache.profesional(c.profesionalId);
          return c.completar(nombre: p?.nombreCompleto, porcentajeProfesional: p?.porcentaje);
        })
        .where((c) => profesionalId == null || c.profesionalId == null || c.profesionalId == profesionalId)
        .where((c) => cierreId == null || c.cierreId == null || c.cierreId == cierreId)
        .toList();
    salida.sort((a, b) => (b.valor ?? 0).compareTo(a.valor ?? 0));
    return salida;
  }

  /// GET /api/comisiones/{id}/servicios
  Future<List<ServicioComisionado>> servicios(int comisionId) async {
    final lista = await listarTodo('$_ruta/$comisionId/servicios', ServicioComisionado.fromJson);
    lista.sort((a, b) => (a.fecha ?? DateTime(1900)).compareTo(b.fecha ?? DateTime(1900)));
    return lista;
  }
}
