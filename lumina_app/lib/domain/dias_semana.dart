/// Días de la semana según la API (System.DayOfWeek de .NET):
/// 0 = Domingo, 1 = Lunes … 6 = Sábado.
/// El ejemplo de "Crear masivo" de Bruno usa [1..6] = lunes a sábado.
abstract final class DiasSemana {
  static const nombres = {
    1: 'Lunes',
    2: 'Martes',
    3: 'Miércoles',
    4: 'Jueves',
    5: 'Viernes',
    6: 'Sábado',
    0: 'Domingo',
  };

  /// Orden de presentación: lunes → domingo.
  static const orden = [1, 2, 3, 4, 5, 6, 0];

  static String nombre(int dia) => nombres[dia] ?? 'Día $dia';

  static String corto(int dia) => nombre(dia).substring(0, 3);

  static String inicial(int dia) => nombre(dia).substring(0, 1);

  /// DateTime.weekday (1 = lunes … 7 = domingo) → valor de la API.
  static int desdeFecha(DateTime fecha) => fecha.weekday % 7;

  /// Acepta número o texto ("Monday", "Lunes", "1").
  static int leer(dynamic valor) {
    if (valor is num) return valor.toInt();
    final s = '${valor ?? ''}'.toLowerCase().trim();
    final n = int.tryParse(s);
    if (n != null) return n;
    const prefijos = {
      'sun': 0, 'dom': 0, 'mon': 1, 'lun': 1, 'tue': 2, 'mar': 2,
      'wed': 3, 'mié': 3, 'mie': 3, 'thu': 4, 'jue': 4, 'fri': 5,
      'vie': 5, 'sat': 6, 'sáb': 6, 'sab': 6,
    };
    for (final p in prefijos.entries) {
      if (s.startsWith(p.key)) return p.value;
    }
    return 1;
  }
}
