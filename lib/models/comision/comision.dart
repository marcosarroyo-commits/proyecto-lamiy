import 'package:lumina_app/models/comun/json.dart';


class Comision {
  const Comision({
    required this.id,
    this.profesionalId,
    this.profesionalNombre,
    this.cierreId,
    this.cantidadServicios,
    this.base,
    this.porcentaje,
    this.valor,
    this.fechaInicio,
    this.fechaFin,
  });

  final int id;
  final int? profesionalId;
  final String? profesionalNombre;
  final int? cierreId;
  final int? cantidadServicios;
  final double? base;
  final double? porcentaje;
  final double? valor;
  final DateTime? fechaInicio;
  final DateTime? fechaFin;

  factory Comision.fromJson(Map<String, dynamic> json) {
    final profesional = Json.objeto(json, 'profesional');
    final cierre = Json.objeto(json, ['cierre', 'liquidacion']);
    final servicios = Json.valor(json, 'servicios');
    final base = Json.decimalONulo(json, ['base', 'valorBase', 'totalServicios', 'total', 'subtotal']);
    final porcentaje = Json.decimalONulo(json, ['porcentaje', 'porcentajeComision']) ??
        Json.decimalONulo(profesional, 'porcentaje');
    return Comision(
      id: Json.entero(json, ['id', 'comisionId']),
      profesionalId: Json.enteroONulo(json, 'profesionalId') ?? Json.enteroONulo(profesional, 'id'),
      profesionalNombre: Json.nombreCompleto(profesional) ??
          Json.textoONulo(json, ['profesionalNombre', 'nombreProfesional']) ??
          (json['profesional'] is String ? Json.textoONulo(json, 'profesional') : null),
      cierreId: Json.enteroONulo(json, ['cierreId', 'liquidacionId', 'liquidacionComisionId']) ??
          Json.enteroONulo(cierre, 'id'),
      cantidadServicios: Json.enteroONulo(json, ['cantidadServicios', 'serviciosRealizados']) ??
          (servicios is List ? servicios.length : (servicios is num ? servicios.toInt() : null)),
      base: base,
      porcentaje: porcentaje,
      valor: Json.decimalONulo(json, ['valor', 'valorComision', 'comision', 'totalComision']) ??
          (base != null && porcentaje != null ? base * porcentaje / 100 : null),
      fechaInicio: Json.fecha(json, 'fechaInicio') ?? Json.fecha(cierre, 'fechaInicio'),
      fechaFin: Json.fecha(json, 'fechaFin') ?? Json.fecha(cierre, 'fechaFin'),
    );
  }

  Comision completar({String? nombre, double? porcentajeProfesional}) {
    final pct = porcentaje ?? porcentajeProfesional;
    return Comision(
      id: id,
      profesionalId: profesionalId,
      profesionalNombre: profesionalNombre ?? nombre,
      cierreId: cierreId,
      cantidadServicios: cantidadServicios,
      base: base,
      porcentaje: pct,
      valor: valor ?? (base != null && pct != null ? base! * pct / 100 : null),
      fechaInicio: fechaInicio,
      fechaFin: fechaFin,
    );
  }
}


class ServicioComisionado {
  const ServicioComisionado({
    required this.servicio,
    this.id,
    this.fecha,
    this.cliente,
    this.valor,
    this.comision,
  });

  final int? id;
  final String servicio;
  final DateTime? fecha;
  final String? cliente;
  final double? valor;
  final double? comision;

  factory ServicioComisionado.fromJson(Map<String, dynamic> json) {
    final servicio = Json.objeto(json, 'servicio');
    final reserva = Json.objeto(json, 'reserva');
    final cliente = Json.objeto(json, 'cliente').isNotEmpty
        ? Json.objeto(json, 'cliente')
        : Json.objeto(reserva, 'cliente');
    return ServicioComisionado(
      id: Json.enteroONulo(json, ['id', 'reservaId']),
      servicio: Json.textoONulo(servicio, 'nombre') ??
          Json.textoONulo(json, ['servicioNombre', 'nombreServicio', 'nombre']) ??
          (json['servicio'] is String ? Json.texto(json, 'servicio') : 'Servicio'),
      fecha: Json.fecha(json, ['fecha', 'fechaReserva', 'fechaServicio']) ?? Json.fecha(reserva, 'fecha'),
      cliente: Json.nombreCompleto(cliente) ??
          Json.textoONulo(json, ['clienteNombre', 'nombreCliente']) ??
          (json['cliente'] is String ? Json.textoONulo(json, 'cliente') : null),
      valor: Json.decimalONulo(json, ['valor', 'precio', 'valorServicio']) ??
          Json.decimalONulo(servicio, 'precio'),
      comision: Json.decimalONulo(json, ['comision', 'valorComision']),
    );
  }
}
