abstract final class Formato {
  
  static String moneda(num? valor) {
    final v = valor ?? 0;
    final entero = v.round().abs().toString();
    final grupos = StringBuffer();
    for (var i = 0; i < entero.length; i++) {
      if (i > 0 && (entero.length - i) % 3 == 0) grupos.write('.');
      grupos.write(entero[i]);
    }
    return '${v < 0 ? '-' : ''}\$ $grupos';
  }

  static String iniciales(String nombre) {
    final palabras = nombre
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (palabras.isEmpty) return '?';
    final primera = palabras.first[0];
    final segunda = palabras.length > 1 ? palabras[1][0] : '';
    return (primera + segunda).toUpperCase();
  }

  static String capitalizar(String texto) {
    final limpio = texto.trim().toLowerCase().replaceAll('_', ' ');
    if (limpio.isEmpty) return limpio;
    return limpio[0].toUpperCase() + limpio.substring(1);
  }

  static String valorO(String? valor, [String alternativo = 'No registrado']) {
    if (valor == null || valor.trim().isEmpty) return alternativo;
    return valor;
  }

  /// 45 min · 1 h 30 min
  static String duracion(int? minutos) {
    if (minutos == null || minutos <= 0) return '—';
    if (minutos < 60) return '$minutos min';
    final h = minutos ~/ 60, m = minutos % 60;
    return m == 0 ? '$h h' : '$h h $m min';
  }

  static String porcentaje(num? valor) {
    if (valor == null) return '—';
    return valor % 1 == 0 ? '${valor.toInt()}%' : '${valor.toStringAsFixed(1)}%';
  }

  /// 300 456 7821
  static String celular(String? valor) {
    final d = (valor ?? '').replaceAll(RegExp(r'\D'), '');
    if (d.length == 10) return '${d.substring(0, 3)} ${d.substring(3, 6)} ${d.substring(6)}';
    return valorO(valor);
  }

  static String horas(double horas) =>
      horas % 1 == 0 ? '${horas.toInt()} h' : '${horas.toStringAsFixed(1)} h';
}
