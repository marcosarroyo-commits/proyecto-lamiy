import 'package:lumina_app/models/comun/json.dart';

class Especialidad {
  const Especialidad({required this.id, required this.nombre, this.activa = true});

  final int id;
  final String nombre;
  final bool activa;

  factory Especialidad.fromJson(Map<String, dynamic> json) => Especialidad(
    id: Json.entero(json, ['id', 'especialidadId']),
    nombre: Json.textoONulo(json, ['nombre', 'descripcion']) ?? 'Sin nombre',
    activa: Json.booleano(json, ['activa', 'activo', 'estado'], porDefecto: true),
  );
}
