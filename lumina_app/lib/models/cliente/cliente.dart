import 'package:lumina_app/models/comun/json.dart';

class Cliente {
  const Cliente({
    required this.id,
    required this.documento,
    required this.nombres,
    required this.apellidos,
    this.fechaNacimiento,
    this.celular,
    this.correo,
  });

  final int id;
  final String documento;
  final String nombres;
  final String apellidos;
  final DateTime? fechaNacimiento;
  final String? celular;
  final String? correo;

  factory Cliente.fromJson(Map<String, dynamic> json) => Cliente(
    id: Json.entero(json, ['id', 'clienteId']),
    documento: Json.texto(json, ['documento', 'identificacion']),
    nombres: Json.textoONulo(json, ['nombres', 'nombre']) ?? 'Cliente',
    apellidos: Json.texto(json, ['apellidos', 'apellido']),
    fechaNacimiento: Json.fecha(json, 'fechaNacimiento'),
    celular: Json.textoONulo(json, ['celular', 'telefono']),
    correo: Json.textoONulo(json, ['correo', 'email']),
  );

  String get nombreCompleto => '$nombres $apellidos'.trim();

  /// Busca por documento, nombre o celular.
  bool coincide(String consulta) {
    final q = consulta.trim().toLowerCase();
    if (q.isEmpty) return true;
    final digitos = q.replaceAll(RegExp(r'\D'), '');
    return nombreCompleto.toLowerCase().contains(q) ||
        documento.contains(q) ||
        (digitos.isNotEmpty &&
            (celular ?? '').replaceAll(RegExp(r'\D'), '').contains(digitos));
  }
}
