import 'package:lumina_app/models/agenda/horario_disponible.dart';
import 'package:lumina_app/models/cliente/cliente.dart';
import 'package:lumina_app/models/profesional/profesional.dart';
import 'package:lumina_app/models/servicio/servicio.dart';


class ClienteNuevo {
  const ClienteNuevo({
    required this.documento,
    required this.nombres,
    required this.apellidos,
    required this.celular,
  });

  final String documento;
  final String nombres;
  final String apellidos;
  final String celular;

  String get nombreCompleto => '$nombres $apellidos'.trim();
}


class ReservaBorrador {
  const ReservaBorrador({
    required this.servicio,
    required this.horario,
    this.cliente,
    this.clienteNuevo,
    this.profesional,
  }) : assert(cliente != null || clienteNuevo != null);

  final Cliente? cliente;
  final ClienteNuevo? clienteNuevo;
  final Servicio servicio;

  
  final Profesional? profesional;
  final HorarioDisponible horario;

  bool get primeraVez => cliente == null;

  String get clienteNombre => cliente?.nombreCompleto ?? clienteNuevo!.nombreCompleto;

  String get clienteDocumento => cliente?.documento ?? clienteNuevo!.documento;

  int? get profesionalId => profesional?.id ?? horario.profesionalId;

  String get profesionalNombre =>
      profesional?.nombreCompleto ?? horario.profesionalNombre ?? 'Cualquiera (asigna el centro)';
}
