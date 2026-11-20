import 'package:lumina_app/domain/fechas.dart';
import 'package:lumina_app/models/agenda/horario_disponible.dart';
import 'package:lumina_app/services/local/catalogo_cache.dart';
import 'package:lumina_app/services/local/inasistencia_local_service.dart';
import 'package:lumina_app/services/remote/servicio_base.dart';

class AgendaService extends ServicioBase {
  static const _ruta = '/api/agenda';

  /// GET /api/agenda?fecha=…&servicioId=…[&profesionalId=…]
  ///
  /// Reglas: se descartan horas pasadas y profesionales con inasistencia.
  Future<List<HorarioDisponible>> disponibles({
    required DateTime fecha,
    required int servicioId,
    int? profesionalId,
  }) async {
    final respuesta = await api.get(
      _ruta,
      queryParameters: {
        'fecha': Fechas.api(fecha),
        'servicioId': '$servicioId',
        if (profesionalId != null) 'profesionalId': '$profesionalId',
      },
      headers: cabeceras,
    );
    final ausentes = await InasistenciaLocalService().ausentesEn(fecha);
    await CatalogoCache.precargar();
    final ahora = DateTime.now();
    return HorarioDisponible.leerLista(respuesta, fecha)
        .where((h) => h.inicio.isAfter(ahora))
        .map((h) {
          final id = h.profesionalId ?? profesionalId;
          return h.conProfesional(id, CatalogoCache.profesional(id)?.nombreCompleto);
        })
        .where((h) => h.profesionalId == null || !ausentes.contains(h.profesionalId))
        .toList();
  }

  /// GET /api/agenda/{yyyy-MM-dd} — horarios del día de todo el equipo.
  Future<List<HorarioDisponible>> delDia(DateTime fecha) async {
    final respuesta = await api.get('$_ruta/${Fechas.api(fecha)}', headers: cabeceras);
    await CatalogoCache.precargar();
    return HorarioDisponible.leerLista(respuesta, fecha)
        .map((h) => h.conProfesional(null, CatalogoCache.profesional(h.profesionalId)?.nombreCompleto))
        .toList();
  }
}
