import 'package:lumina_app/domain/fechas.dart';
import 'package:lumina_app/models/comun/json.dart';

/// Un horario libre devuelto por GET /api/agenda.
class HorarioDisponible {
  const HorarioDisponible({
    required this.inicio,
    this.profesionalId,
    this.profesionalNombre,
  });

  final DateTime inicio;
  final int? profesionalId;
  final String? profesionalNombre;

  String get hora => Fechas.hora12(inicio);

  HorarioDisponible conProfesional(int? id, String? nombre) => HorarioDisponible(
    inicio: inicio,
    profesionalId: profesionalId ?? id,
    profesionalNombre: profesionalNombre ?? nombre,
  );

  /// Interpreta la respuesta de la agenda en cualquiera de sus formas:
  ///  * ["08:00", "08:30"] o ["2026-10-20T08:00:00", ...]
  ///  * [{hora / horaInicio / inicio / fecha, profesionalId, profesional}, ...]
  ///  * [{profesionalId, nombre, horarios: [...]}, ...]   (agrupado)
  ///  * {horarios: [...]} / {data: [...]}
  static List<HorarioDisponible> leerLista(dynamic respuesta, DateTime fecha) {
    final salida = <HorarioDisponible>[];

    DateTime? aFecha(dynamic v) {
      if (v == null) return null;
      final s = '$v';
      if (s.length >= 10 && s.contains('-')) {
        final d = Json.fecha({'f': s}, 'f');
        if (d != null) return d;
      }
      final h = Fechas.leerHora(s);
      if (h == null) return null;
      return DateTime(fecha.year, fecha.month, fecha.day, h.hour, h.minute);
    }

    void recorrer(dynamic nodo, int? proId, String? proNombre) {
      if (nodo is List) {
        for (final e in nodo) {
          recorrer(e, proId, proNombre);
        }
        return;
      }
      if (nodo is Map<String, dynamic>) {
        final pro = Json.objeto(nodo, 'profesional');
        final anidado = Json.valor(nodo, ['horarios', 'horariosDisponibles', 'disponibles', 'slots', 'horas']);
        final id = Json.enteroONulo(nodo, 'profesionalId') ?? Json.enteroONulo(pro, 'id') ?? proId;
        final nombre = Json.nombreCompleto(pro) ??
            Json.textoONulo(nodo, ['profesionalNombre', 'nombreProfesional']) ??
            (anidado is List ? Json.nombreCompleto(nodo) : null) ??
            proNombre;
        if (anidado is List) {
          recorrer(anidado, id, nombre);
          return;
        }
        final inicio = aFecha(Json.valor(nodo, ['fechaHora', 'inicio', 'horaInicio', 'hora', 'fecha', 'desde']));
        final libre = Json.booleanoONulo(nodo, ['disponible', 'libre']) ?? true;
        if (inicio != null && libre) {
          salida.add(HorarioDisponible(inicio: inicio, profesionalId: id, profesionalNombre: nombre));
        }
        return;
      }
      final inicio = aFecha(nodo);
      if (inicio != null) {
        salida.add(HorarioDisponible(inicio: inicio, profesionalId: proId, profesionalNombre: proNombre));
      }
    }

    dynamic raiz = respuesta;
    if (raiz is Map<String, dynamic>) {
      raiz = Json.valor(raiz, ['data', 'horarios', 'disponibles', 'horariosDisponibles']) ?? raiz;
    }
    recorrer(raiz, null, null);
    salida.sort((a, b) => a.inicio.compareTo(b.inicio));
    return salida;
  }
}
