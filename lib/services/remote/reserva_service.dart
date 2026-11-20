import 'package:lumina_app/domain/fechas.dart';
import 'package:lumina_app/domain/reglas_reserva.dart';
import 'package:lumina_app/models/comun/json.dart';
import 'package:lumina_app/models/reserva/reserva.dart';
import 'package:lumina_app/models/reserva/reserva_borrador.dart';
import 'package:lumina_app/services/local/catalogo_cache.dart';
import 'package:lumina_app/services/local/reserva_local_service.dart';
import 'package:lumina_app/services/remote/api_service.dart';
import 'package:lumina_app/services/remote/servicio_base.dart';

class ReservaService extends ServicioBase {
  static const _ruta = '/api/reservas';

  
  Future<List<Reserva>> todas() async =>
      _completar(await listarTodo(_ruta, Reserva.fromJson));

  
  Future<List<Reserva>> entre(DateTime inicio, DateTime fin) async {
    final lista = await listarTodo(_ruta, Reserva.fromJson, filtros: {
      'fechaInicio': Fechas.api(inicio),
      'fechaFin': Fechas.api(fin),
    });
    final desde = Fechas.soloFecha(inicio);
    final hasta = Fechas.soloFecha(fin).add(const Duration(days: 1));
    return _completar(
      lista.where((r) => !r.fecha.isBefore(desde) && r.fecha.isBefore(hasta)).toList(),
    );
  }

  
  Future<Reserva> obtenerPorId(int id) async =>
      (await _completar([await obtener('$_ruta/$id', Reserva.fromJson)])).first;

  
  
  Future<int?> registrar(ReservaBorrador borrador, {required String medioPago}) async {
    final base = {
      'fecha': Fechas.apiFechaHora(borrador.horario.inicio),
      'servicioId': borrador.servicio.id,
      if (borrador.profesionalId != null) 'profesionalId': borrador.profesionalId,
      'medioPago': medioPago,
    };
    final dynamic respuesta;
    if (borrador.cliente != null) {
      respuesta = await crear(_ruta, {...base, 'clienteId': borrador.cliente!.id});
    } else {
      final nuevo = borrador.clienteNuevo!;
      respuesta = await crear(_ruta, {
        ...base,
        'documento': nuevo.documento,
        'nombres': nuevo.nombres,
        'apellidos': nuevo.apellidos,
        'celular': nuevo.celular,
      }, publico: true);
      CatalogoCache.invalidar();
    }
    final id = respuesta is num ? respuesta.toInt() : Json.enteroONulo(Json.datos(respuesta), ['id', 'reservaId']);
    if (id != null && id > 0) {
      await ReservaLocalService.guardar(id, 'medioPago', medioPago);
    }
    return id;
  }

  
  Future<void> reagendar(Reserva reserva, {required DateTime fecha, int? profesionalId}) async {
    await actualizar('$_ruta/${reserva.id}', {
      'fecha': Fechas.apiFechaHora(fecha),
      'servicioId': reserva.servicioId,
      if (profesionalId != null) 'profesionalId': profesionalId,
    });
  }

  /// DELETE /api/reservas/{id} — el motivo se envía y además se guarda local.
  Future<void> cancelar(int id, String motivo) async {
    await eliminar('$_ruta/$id', cuerpo: {'motivo': motivo});
    await ReservaLocalService.guardar(id, 'motivo', motivo);
  }

  /// Confirmar asistencia / servicio realizado.
  ///
  /// La colección de Bruno no trae un endpoint para esto: se intenta con
  /// PUT enviando el estado y, si la API no lo admite, el estado "Atendida"
  /// se conserva en el dispositivo para que agenda y detalle lo reflejen.
  Future<void> marcarAtendida(Reserva reserva) async {
    try {
      await actualizar('$_ruta/${reserva.id}', {
        'fecha': Fechas.apiFechaHora(reserva.fecha),
        'servicioId': reserva.servicioId,
        if (reserva.profesionalId != null) 'profesionalId': reserva.profesionalId,
        'estado': EstadoReserva.atendida.texto,
      });
    } on ApiException catch (e) {
      final code = e.statusCode;
      if (code == null || code >= 500 || code == 401 || code == 403) rethrow;
    }
    await ReservaLocalService.guardar(reserva.id, 'atendida', true);
  }

  /// Completa nombres/precios con la caché y aplica los datos locales.
  Future<List<Reserva>> _completar(List<Reserva> lista) async {
    if (lista.isEmpty) return lista;
    await CatalogoCache.precargar();
    final extras = await ReservaLocalService.todos();
    final salida = lista.map((r) {
      final s = CatalogoCache.servicio(r.servicioId);
      final p = CatalogoCache.profesional(r.profesionalId);
      final c = CatalogoCache.cliente(r.clienteId);
      final x = extras['${r.id}'] ?? const <String, dynamic>{};
      return r.copyWith(
        estado: r.programada && x['atendida'] == true ? EstadoReserva.atendida : null,
        servicioNombre: r.servicioNombre ?? s?.nombre,
        precio: r.precio ?? s?.precio,
        duracion: (r.duracion ?? 0) > 0 ? null : s?.duracion,
        profesionalNombre: r.profesionalNombre ?? p?.nombreCompleto,
        clienteNombre: r.clienteNombre ?? c?.nombreCompleto,
        clienteDocumento: r.clienteDocumento ?? c?.documento,
        clienteCelular: r.clienteCelular ?? c?.celular,
        clienteCorreo: r.clienteCorreo ?? c?.correo,
        medioPago: r.medioPago ?? x['medioPago']?.toString(),
        motivoCancelacion: r.motivoCancelacion ?? x['motivo']?.toString(),
      );
    }).toList();
    salida.sort((a, b) => a.fecha.compareTo(b.fecha));
    return salida;
  }
}
