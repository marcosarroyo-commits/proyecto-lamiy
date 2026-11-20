import 'package:lumina_app/models/comun/json.dart';


class Liquidacion {
  const Liquidacion({
    required this.id,
    this.fechaInicio,
    this.fechaFin,
    this.fechaCreacion,
    this.total,
    this.totalComisiones,
    this.cantidadServicios,
    this.cantidadProfesionales,
  });

  final int id;
  final DateTime? fechaInicio;
  final DateTime? fechaFin;
  final DateTime? fechaCreacion;
  final double? total;
  final double? totalComisiones;
  final int? cantidadServicios;
  final int? cantidadProfesionales;

  factory Liquidacion.fromJson(Map<String, dynamic> json) {
    final profesionales = Json.valor(json, 'profesionales');
    final servicios = Json.valor(json, ['servicios', 'detalle']);
    return Liquidacion(
      id: Json.entero(json, ['id', 'cierreId', 'liquidacionId']),
      fechaInicio: Json.fecha(json, ['fechaInicio', 'desde']),
      fechaFin: Json.fecha(json, ['fechaFin', 'hasta']),
      fechaCreacion: Json.fecha(json, ['fechaCreacion', 'fechaRegistro', 'fecha']),
      total: Json.decimalONulo(json, ['total', 'totalVentas', 'valorTotal', 'totalServicios']),
      totalComisiones: Json.decimalONulo(json, ['totalComisiones', 'valorComisiones']),
      cantidadServicios: Json.enteroONulo(json, ['cantidadServicios', 'numeroServicios']) ??
          (servicios is List ? servicios.length : (servicios is num ? servicios.toInt() : null)),
      cantidadProfesionales: Json.enteroONulo(json, ['cantidadProfesionales', 'numeroProfesionales']) ??
          (profesionales is List
              ? profesionales.length
              : (profesionales is num ? profesionales.toInt() : null)),
    );
  }

  
  String get codigo {
    final f = fechaInicio ?? fechaCreacion;
    if (f == null) return 'CR-$id';
    return 'CR-${f.year}-${f.month.toString().padLeft(2, '0')} · #$id';
  }

  double? get valorCentro =>
      total != null && totalComisiones != null ? total! - totalComisiones! : null;
}
