




abstract final class Json {
  
  static Map<String, dynamic> datos(dynamic respuesta) {
    if (respuesta is Map<String, dynamic>) {
      final data = respuesta['data'];
      if (data is Map<String, dynamic>) return data;
      return respuesta;
    }
    if (respuesta is List && respuesta.isNotEmpty && respuesta.first is Map<String, dynamic>) {
      return respuesta.first as Map<String, dynamic>;
    }
    return const <String, dynamic>{};
  }

  
  static List<Map<String, dynamic>> lista(dynamic respuesta) {
    dynamic fuente = respuesta;
    if (fuente is Map<String, dynamic>) {
      fuente = fuente['data'] ?? fuente['items'] ?? fuente;
    }
    if (fuente is Map<String, dynamic>) {
      fuente = fuente['items'] ?? fuente['registros'] ?? fuente['results'];
    }
    if (fuente is List) {
      return fuente.whereType<Map<String, dynamic>>().toList();
    }
    return const [];
  }

  
  static dynamic valor(Map<String, dynamic> json, Object claves) {
    final lista = claves is List<String> ? claves : [claves.toString()];
    for (final clave in lista) {
      final v = json[clave];
      if (v != null) return v;
    }
    
    for (final clave in lista) {
      for (final entrada in json.entries) {
        if (entrada.key.toLowerCase() == clave.toLowerCase() && entrada.value != null) {
          return entrada.value;
        }
      }
    }
    return null;
  }

  static String texto(Map<String, dynamic> json, Object claves) =>
      textoONulo(json, claves) ?? '';

  static String? textoONulo(Map<String, dynamic> json, Object claves) {
    final v = valor(json, claves);
    if (v == null || v is Map || v is List) return null;
    final texto = v.toString().trim();
    return texto.isEmpty ? null : texto;
  }

  static int entero(Map<String, dynamic> json, Object claves) =>
      enteroONulo(json, claves) ?? 0;

  static int? enteroONulo(Map<String, dynamic> json, Object claves) {
    final v = valor(json, claves);
    if (v == null) return null;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }

  static double decimal(Map<String, dynamic> json, Object claves) =>
      decimalONulo(json, claves) ?? 0;

  static double? decimalONulo(Map<String, dynamic> json, Object claves) {
    final v = valor(json, claves);
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString().replaceAll(',', '.'));
  }

  static bool booleano(Map<String, dynamic> json, Object claves, {bool porDefecto = false}) =>
      booleanoONulo(json, claves) ?? porDefecto;

  static bool? booleanoONulo(Map<String, dynamic> json, Object claves) {
    final v = valor(json, claves);
    if (v is bool) return v;
    if (v is num) return v != 0;
    final s = '${v ?? ''}'.toLowerCase();
    if (['true', 'activo', 'activa', 'si', 'sí', '1'].contains(s)) return true;
    if (['false', 'inactivo', 'inactiva', 'no', '0'].contains(s)) return false;
    return null;
  }

  /// Fechas: la app envía horas locales sin zona; si la API responde con
  /// "Z" se conserva la hora de pared para no desfasar la agenda.
  static DateTime? fecha(Map<String, dynamic> json, Object claves) {
    final v = valor(json, claves)?.toString();
    if (v == null || v.isEmpty) return null;
    final fecha = DateTime.tryParse(v.replaceFirst(' ', 'T'));
    if (fecha == null || !fecha.isUtc) return fecha;
    return DateTime(fecha.year, fecha.month, fecha.day, fecha.hour, fecha.minute, fecha.second);
  }

  static Map<String, dynamic> objeto(Map<String, dynamic> json, Object claves) {
    final v = valor(json, claves);
    return v is Map<String, dynamic> ? v : const <String, dynamic>{};
  }

  /// "nombres apellidos" de un objeto anidado (cliente, profesional).
  static String? nombreCompleto(Map<String, dynamic> json) {
    if (json.isEmpty) return null;
    final completo = textoONulo(json, 'nombreCompleto');
    if (completo != null) return completo;
    final n = '${texto(json, ['nombres', 'nombre'])} ${texto(json, ['apellidos', 'apellido'])}'.trim();
    return n.isEmpty ? null : n;
  }
}
