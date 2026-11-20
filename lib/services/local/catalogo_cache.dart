import 'package:lumina_app/models/cliente/cliente.dart';
import 'package:lumina_app/models/especialidad/especialidad.dart';
import 'package:lumina_app/models/profesional/profesional.dart';
import 'package:lumina_app/models/servicio/servicio.dart';
import 'package:lumina_app/services/remote/cliente_service.dart';
import 'package:lumina_app/services/remote/especialidad_service.dart';
import 'package:lumina_app/services/remote/profesional_service.dart';
import 'package:lumina_app/services/remote/servicio_service.dart';






abstract final class CatalogoCache {
  static List<Especialidad>? _especialidades;
  static List<Servicio>? _servicios;
  static List<Profesional>? _profesionales;
  static List<Cliente>? _clientes;

  static void invalidar() {
    _especialidades = null;
    _servicios = null;
    _profesionales = null;
    _clientes = null;
  }

  static Future<List<Especialidad>> especialidades() async =>
      _especialidades ??= await EspecialidadService().todas();

  static Future<List<Servicio>> servicios() async =>
      _servicios ??= await ServicioService().todos();

  static Future<List<Profesional>> profesionales() async =>
      _profesionales ??= await ProfesionalService().todos();

  static Future<List<Cliente>> clientes() async =>
      _clientes ??= await ClienteService().todos();

  
  static Future<void> precargar() async {
    Future<void> seguro(Future<Object?> Function() f) async {
      try {
        await f();
      } catch (_) {}
    }

    await Future.wait([
      seguro(servicios),
      seguro(profesionales),
      seguro(clientes),
      seguro(especialidades),
    ]);
  }

  static Servicio? servicio(int? id) => _buscar(_servicios, id, (s) => s.id);
  static Profesional? profesional(int? id) => _buscar(_profesionales, id, (p) => p.id);
  static Cliente? cliente(int? id) => _buscar(_clientes, id, (c) => c.id);
  static Especialidad? especialidad(int? id) => _buscar(_especialidades, id, (e) => e.id);

  static T? _buscar<T>(List<T>? lista, int? id, int Function(T) clave) {
    if (lista == null || id == null) return null;
    for (final e in lista) {
      if (clave(e) == id) return e;
    }
    return null;
  }
}
