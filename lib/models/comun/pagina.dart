import 'package:lumina_app/models/comun/json.dart';

class Pagina<T> {
  const Pagina({
    required this.items,
    required this.pagina,
    required this.totalPaginas,
    required this.totalItems,
  });

  final List<T> items;
  final int pagina;
  final int totalPaginas;
  final int totalItems;

  bool get hayMas => pagina < totalPaginas;

  
  
  factory Pagina.completa(List<T> items) => Pagina(
    items: items,
    pagina: 1,
    totalPaginas: 1,
    totalItems: items.length,
  );

  factory Pagina.desdeRespuesta(
    dynamic respuesta,
    T Function(Map<String, dynamic> json) convertir,
  ) {
    final items = Json.lista(respuesta).map(convertir).toList();
    final datos = Json.datos(respuesta);
    final paginacion = Json.objeto(datos, 'pagination');

    if (paginacion.isEmpty) {
      return Pagina(
        items: items,
        pagina: 1,
        totalPaginas: 1,
        totalItems: items.length,
      );
    }

    return Pagina(
      items: items,
      pagina: Json.entero(paginacion, 'page'),
      totalPaginas: Json.entero(paginacion, 'totalPages'),
      totalItems: Json.entero(paginacion, 'totalItems'),
    );
  }
}
