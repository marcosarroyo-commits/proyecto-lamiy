import 'package:lumina_app/domain/reglas_reserva.dart';
import 'package:lumina_app/models/comun/json.dart';

class Reserva {
  const Reserva({
    required this.id,
    required this.fecha,
    this.estado = EstadoReserva.programada,
    this.fechaCreacion,
    this.motivoCancelacion,
    this.clienteId,
    this.clienteNombre,
    this.clienteDocumento,
    this.clienteCelular,
    this.clienteCorreo,
    this.servicioId,
    this.servicioNombre,
    this.precio,
    this.duracion,
    this.profesionalId,
    this.profesionalNombre,
    this.medioPago,
  });

  final int id;
  final DateTime fecha;
  final EstadoReserva estado;
  final DateTime? fechaCreacion;
  final String? motivoCancelacion;

  final int? clienteId;
  final String? clienteNombre;
  final String? clienteDocumento;
  final String? clienteCelular;
  final String? clienteCorreo;

  final int? servicioId;
  final String? servicioNombre;
  final int? precio;
  final int? duracion;

  final int? profesionalId;
  final String? profesionalNombre;

  
  final String? medioPago;

  factory Reserva.fromJson(Map<String, dynamic> json) {
    final cliente = Json.objeto(json, 'cliente');
    final servicio = Json.objeto(json, 'servicio');
    final profesional = Json.objeto(json, 'profesional');
    final estado = Json.valor(json, ['estado', 'estadoReserva', 'status']);
    return Reserva(
      id: Json.entero(json, ['id', 'reservaId']),
      fecha: Json.fecha(json, ['fecha', 'fechaHora', 'fechaReserva']) ?? DateTime.now(),
      estado: EstadoReserva.desde(
        estado is Map<String, dynamic> ? Json.texto(estado, 'nombre') : estado,
        activa: Json.booleanoONulo(json, ['activa', 'activo']),
      ),
      fechaCreacion: Json.fecha(json, ['fechaCreacion', 'fechaRegistro', 'createdAt']),
      motivoCancelacion: Json.textoONulo(json, ['motivo', 'motivoCancelacion']),
      clienteId: Json.enteroONulo(json, 'clienteId') ?? Json.enteroONulo(cliente, 'id'),
      clienteNombre: Json.nombreCompleto(cliente) ??
          Json.textoONulo(json, ['clienteNombre', 'nombreCliente']) ??
          (json['cliente'] is String ? Json.textoONulo(json, 'cliente') : null),
      clienteDocumento: Json.textoONulo(cliente, 'documento') ??
          Json.textoONulo(json, ['clienteDocumento', 'documento']),
      clienteCelular: Json.textoONulo(cliente, ['celular', 'telefono']) ??
          Json.textoONulo(json, ['clienteCelular', 'celular']),
      clienteCorreo: Json.textoONulo(cliente, ['correo', 'email']) ??
          Json.textoONulo(json, ['clienteCorreo', 'correo']),
      servicioId: Json.enteroONulo(json, 'servicioId') ?? Json.enteroONulo(servicio, 'id'),
      servicioNombre: Json.textoONulo(servicio, 'nombre') ??
          Json.textoONulo(json, ['servicioNombre', 'nombreServicio']) ??
          (json['servicio'] is String ? Json.textoONulo(json, 'servicio') : null),
      precio: (Json.decimalONulo(servicio, ['precio', 'valor']) ??
              Json.decimalONulo(json, ['precio', 'valor']))
          ?.round(),
      duracion: Json.enteroONulo(servicio, 'duracion') ?? Json.enteroONulo(json, 'duracion'),
      profesionalId:
          Json.enteroONulo(json, 'profesionalId') ?? Json.enteroONulo(profesional, 'id'),
      profesionalNombre: Json.nombreCompleto(profesional) ??
          Json.textoONulo(json, ['profesionalNombre', 'nombreProfesional']) ??
          (json['profesional'] is String ? Json.textoONulo(json, 'profesional') : null),
      medioPago: Json.textoONulo(json, ['medioPago', 'metodoPago']),
    );
  }

  
  String get codigo => 'C-$id';

  DateTime get fin => fecha.add(Duration(minutes: duracion ?? 0));

  bool get programada => estado == EstadoReserva.programada;
  bool get atendida => estado == EstadoReserva.atendida;
  bool get cancelada => estado == EstadoReserva.cancelada;

  Reserva copyWith({
    EstadoReserva? estado,
    String? motivoCancelacion,
    String? clienteNombre,
    String? clienteDocumento,
    String? clienteCelular,
    String? clienteCorreo,
    String? servicioNombre,
    int? precio,
    int? duracion,
    String? profesionalNombre,
    String? medioPago,
  }) => Reserva(
    id: id,
    fecha: fecha,
    estado: estado ?? this.estado,
    fechaCreacion: fechaCreacion,
    motivoCancelacion: motivoCancelacion ?? this.motivoCancelacion,
    clienteId: clienteId,
    clienteNombre: clienteNombre ?? this.clienteNombre,
    clienteDocumento: clienteDocumento ?? this.clienteDocumento,
    clienteCelular: clienteCelular ?? this.clienteCelular,
    clienteCorreo: clienteCorreo ?? this.clienteCorreo,
    servicioId: servicioId,
    servicioNombre: servicioNombre ?? this.servicioNombre,
    precio: precio ?? this.precio,
    duracion: duracion ?? this.duracion,
    profesionalId: profesionalId,
    profesionalNombre: profesionalNombre ?? this.profesionalNombre,
    medioPago: medioPago ?? this.medioPago,
  );
}
