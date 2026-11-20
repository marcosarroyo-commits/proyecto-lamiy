import 'package:lumina_app/domain/fechas.dart';
import 'package:lumina_app/models/comun/json.dart';
import 'package:lumina_app/models/comun/pagina.dart';
import 'package:lumina_app/models/liquidacion/liquidacion.dart';
import 'package:lumina_app/services/remote/api_service.dart';
import 'package:lumina_app/services/remote/servicio_base.dart';


class LiquidacionService extends ServicioBase {
  static const _ruta = '/api/liquidaciones-comisiones';

  
  Future<List<Liquidacion>> todas() async {
    final lista = await listarTodo(_ruta, Liquidacion.fromJson);
    lista.sort((a, b) => (b.fechaFin ?? DateTime(1900)).compareTo(a.fechaFin ?? DateTime(1900)));
    return lista;
  }

  
  Future<Pagina<Liquidacion>> listar({int anio = 0, int mes = 0}) {
    bool enPeriodo(DateTime? d) =>
        d != null && (anio == 0 || d.year == anio) && (mes == 0 || d.month == mes);
    return paginaLocal(
      todas,
      donde: (l) => (anio == 0 && mes == 0) || enPeriodo(l.fechaInicio) || enPeriodo(l.fechaFin),
    );
  }

  
  Future<Liquidacion?> ultima() async {
    try {
      final respuesta = await api.get(_ruta, queryParameters: {'ultimo': 'true'}, headers: cabeceras);
      final datos = Json.datos(respuesta);
      if (datos.isNotEmpty && Json.enteroONulo(datos, 'id') != null) {
        return Liquidacion.fromJson(datos);
      }
      final lista = Json.lista(respuesta);
      return lista.isEmpty ? null : Liquidacion.fromJson(lista.first);
    } on ApiException catch (e) {
      if (e.noEncontrado) return null;
      rethrow;
    }
  }

  
  Future<Liquidacion?> generar(DateTime inicio, DateTime fin) async {
    final respuesta = await crear(_ruta, {
      'fechaInicio': Fechas.api(inicio),
      'fechaFin': Fechas.api(fin),
    });
    final datos = Json.datos(respuesta);
    return Json.enteroONulo(datos, 'id') == null ? null : Liquidacion.fromJson(datos);
  }
}
