import 'package:lumina_app/models/comun/json.dart';

/// Inasistencia de un profesional por un día o un rango de fechas.
/// La API no tiene este recurso: se guarda en el dispositivo.
class Inasistencia {
  const Inasistencia({
    required this.id,
    required this.profesionalId,
    required this.profesionalNombre,
    required this.fechaInicio,
    required this.fechaFin,
    required this.motivo,
    this.observacion,
  });

  final String id;
  final int profesionalId;
  final String profesionalNombre;
  final DateTime fechaInicio;
  final DateTime fechaFin;
  final String motivo;
  final String? observacion;

  factory Inasistencia.fromJson(Map<String, dynamic> json) => Inasistencia(
    id: Json.texto(json, 'id'),
    profesionalId: Json.entero(json, 'profesionalId'),
    profesionalNombre: Json.texto(json, 'profesionalNombre'),
    fechaInicio: Json.fecha(json, 'fechaInicio') ?? DateTime.now(),
    fechaFin: Json.fecha(json, 'fechaFin') ?? DateTime.now(),
    motivo: Json.textoONulo(json, 'motivo') ?? 'Otra causa justificada',
    observacion: Json.textoONulo(json, 'observacion'),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'profesionalId': profesionalId,
    'profesionalNombre': profesionalNombre,
    'fechaInicio': fechaInicio.toIso8601String(),
    'fechaFin': fechaFin.toIso8601String(),
    'motivo': motivo,
    'observacion': observacion,
  };

  int get dias => fechaFin.difference(fechaInicio).inDays + 1;

  bool get unDia => dias == 1;

  bool cubre(DateTime fecha) {
    final d = DateTime(fecha.year, fecha.month, fecha.day);
    return !d.isBefore(fechaInicio) && !d.isAfter(fechaFin);
  }

  bool seCruzaCon(DateTime inicio, DateTime fin) =>
      !fin.isBefore(fechaInicio) && !inicio.isAfter(fechaFin);
}
