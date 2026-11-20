import 'package:lumina_app/models/comun/json.dart';

class Servicio {
  const Servicio({
    required this.id,
    required this.nombre,
    required this.precio,
    required this.duracion,
    this.descripcion,
    this.especialidadId,
    this.especialidadNombre,
    this.activo = true,
  });

  final int id;
  final String nombre;
  final int precio;

  /// Minutos.
  final int duracion;
  final String? descripcion;
  final int? especialidadId;
  final String? especialidadNombre;
  final bool activo;

  factory Servicio.fromJson(Map<String, dynamic> json) {
    final especialidad = Json.objeto(json, 'especialidad');
    return Servicio(
      id: Json.entero(json, ['id', 'servicioId']),
      nombre: Json.textoONulo(json, ['nombre', 'nombreServicio']) ?? 'Servicio',
      precio: Json.decimal(json, ['precio', 'valor']).round(),
      duracion: Json.entero(json, ['duracion', 'duracionMinutos']),
      descripcion: Json.textoONulo(json, 'descripcion'),
      especialidadId: Json.enteroONulo(json, 'especialidadId') ??
          Json.enteroONulo(especialidad, 'id') ??
          (json['especialidad'] is num ? Json.enteroONulo(json, 'especialidad') : null),
      especialidadNombre: Json.textoONulo(json, ['especialidadNombre', 'nombreEspecialidad']) ??
          Json.textoONulo(especialidad, 'nombre') ??
          (json['especialidad'] is String ? Json.textoONulo(json, 'especialidad') : null),
      activo: Json.booleano(json, ['activo', 'activa', 'estado'], porDefecto: true),
    );
  }

  /// Código corto: SV-104
  String get codigo => 'SV-${id.toString().padLeft(3, '0')}';
}
