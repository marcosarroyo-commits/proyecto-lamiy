import 'package:lumina_app/models/comun/json.dart';

class Profesional {
  const Profesional({
    required this.id,
    required this.documento,
    required this.nombres,
    this.apellidos,
    this.fechaNacimiento,
    this.porcentaje = 0,
    this.activo = true,
    this.especialidadId,
    this.especialidadNombre,
  });

  final int id;
  final String documento;
  final String nombres;
  final String? apellidos;
  final DateTime? fechaNacimiento;

  /// Porcentaje de comisión (0–100).
  final double porcentaje;
  final bool activo;
  final int? especialidadId;
  final String? especialidadNombre;

  factory Profesional.fromJson(Map<String, dynamic> json) {
    final especialidad = Json.objeto(json, 'especialidad');
    return Profesional(
      id: Json.entero(json, ['id', 'profesionalId']),
      documento: Json.texto(json, ['documento', 'identificacion']),
      nombres: Json.textoONulo(json, ['nombres', 'nombre']) ?? 'Profesional',
      apellidos: Json.textoONulo(json, ['apellidos', 'apellido']),
      fechaNacimiento: Json.fecha(json, 'fechaNacimiento'),
      porcentaje: Json.decimal(json, ['porcentaje', 'porcentajeComision', 'comision']),
      activo: Json.booleano(json, ['estado', 'activo', 'activa'], porDefecto: true),
      especialidadId: Json.enteroONulo(json, 'especialidadId') ??
          Json.enteroONulo(especialidad, 'id') ??
          (json['especialidad'] is num ? Json.enteroONulo(json, 'especialidad') : null),
      especialidadNombre: Json.textoONulo(json, ['especialidadNombre', 'nombreEspecialidad']) ??
          Json.textoONulo(especialidad, 'nombre') ??
          (json['especialidad'] is String ? Json.textoONulo(json, 'especialidad') : null),
    );
  }

  String get nombreCompleto => '$nombres ${apellidos ?? ''}'.trim();

  /// "Elena M."
  String get nombreCorto {
    final primero = nombres.split(' ').first;
    final a = (apellidos ?? '').trim();
    return a.isEmpty ? primero : '$primero ${a[0]}.';
  }
}
