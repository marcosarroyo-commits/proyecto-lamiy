import 'package:lumina_app/domain/fechas.dart';
import 'package:lumina_app/models/cliente/cliente.dart';
import 'package:lumina_app/models/comun/json.dart';
import 'package:lumina_app/models/comun/pagina.dart';
import 'package:lumina_app/services/local/catalogo_cache.dart';
import 'package:lumina_app/services/remote/api_service.dart';
import 'package:lumina_app/services/remote/servicio_base.dart';

class ClienteService extends ServicioBase {
  static const _ruta = '/api/clientes';

  /// GET /api/clientes
  Future<List<Cliente>> todos() async {
    final lista = await listarTodo(_ruta, Cliente.fromJson);
    lista.sort((a, b) =>
        a.nombreCompleto.toLowerCase().compareTo(b.nombreCompleto.toLowerCase()));
    return lista;
  }

  /// Búsqueda por documento, nombre o celular.
  Future<Pagina<Cliente>> listar({String busqueda = ''}) =>
      paginaLocal(todos, donde: (c) => c.coincide(busqueda));

  /// GET /api/clientes/{documento}  → null si no existe.
  Future<Cliente?> buscarPorDocumento(String documento) async {
    final doc = documento.trim();
    if (doc.isEmpty) return null;
    try {
      return await obtener('$_ruta/$doc', Cliente.fromJson);
    } on ApiException catch (e) {
      if (e.noEncontrado || e.statusCode == 400) return null;
      rethrow;
    }
  }

  Map<String, dynamic> _cuerpo({
    required String documento,
    required String nombres,
    required String apellidos,
    DateTime? fechaNacimiento,
    String celular = '',
    String correo = '',
  }) => {
    'documento': documento.trim(),
    'nombres': nombres.trim(),
    'apellidos': apellidos.trim(),
    if (fechaNacimiento != null) 'fechaNacimiento': Fechas.api(fechaNacimiento),
    if (celular.trim().isNotEmpty) 'celular': celular.trim(),
    if (correo.trim().isNotEmpty) 'correo': correo.trim(),
  };

  /// POST /api/clientes → devuelve el cliente creado.
  Future<Cliente?> registrar({
    required String documento,
    required String nombres,
    required String apellidos,
    DateTime? fechaNacimiento,
    String celular = '',
    String correo = '',
  }) async {
    final respuesta = await crear(
      _ruta,
      _cuerpo(
        documento: documento,
        nombres: nombres,
        apellidos: apellidos,
        fechaNacimiento: fechaNacimiento,
        celular: celular,
        correo: correo,
      ),
    );
    CatalogoCache.invalidar();
    final datos = Json.datos(respuesta);
    if (Json.enteroONulo(datos, 'id') != null) return Cliente.fromJson(datos);
    // Si la API no devuelve el cliente, se consulta por documento.
    return buscarPorDocumento(documento);
  }

  /// PUT /api/clientes/{id}
  Future<void> editar(
    int id, {
    required String documento,
    required String nombres,
    required String apellidos,
    DateTime? fechaNacimiento,
    String celular = '',
    String correo = '',
  }) async {
    await actualizar(
      '$_ruta/$id',
      _cuerpo(
        documento: documento,
        nombres: nombres,
        apellidos: apellidos,
        fechaNacimiento: fechaNacimiento,
        celular: celular,
        correo: correo,
      ),
    );
    CatalogoCache.invalidar();
  }

  /// DELETE /api/clientes/{id}
  Future<void> borrar(int id) async {
    await eliminar('$_ruta/$id');
    CatalogoCache.invalidar();
  }
}
