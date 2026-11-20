import 'package:flutter/material.dart';

abstract final class Fechas {
  static const List<String> _dias = [
    'Lunes',
    'Martes',
    'Miércoles',
    'Jueves',
    'Viernes',
    'Sábado',
    'Domingo',
  ];

  static const List<String> _meses = [
    'Enero',
    'Febrero',
    'Marzo',
    'Abril',
    'Mayo',
    'Junio',
    'Julio',
    'Agosto',
    'Septiembre',
    'Octubre',
    'Noviembre',
    'Diciembre',
  ];

  static List<String> get meses => _meses;

  static DateTime get hoy => soloFecha(DateTime.now());

  static DateTime soloFecha(DateTime fecha) =>
      DateTime(fecha.year, fecha.month, fecha.day);

  static bool mismoDia(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  
  static String fechaLarga(DateTime fecha) {
    return '${_dias[fecha.weekday - 1]}, ${fecha.day} ${_meses[fecha.month - 1]} ${fecha.year}';
  }

  static String fechaLargaSegura(DateTime? fecha) =>
      fecha == null ? '—' : fechaLarga(fecha);

  /// 16/09/2026
  static String corta(DateTime? fecha) {
    if (fecha == null) return '—';
    final dia = fecha.day.toString().padLeft(2, '0');
    final mes = fecha.month.toString().padLeft(2, '0');
    return '$dia/$mes/${fecha.year}';
  }

  /// 16 Sep 2026
  static String media(DateTime? fecha) {
    if (fecha == null) return '—';
    return '${fecha.day} ${_meses[fecha.month - 1].substring(0, 3)} ${fecha.year}';
  }

  /// 16 Sep
  static String diaMes(DateTime fecha) =>
      '${fecha.day} ${_meses[fecha.month - 1].substring(0, 3)}';

  /// Septiembre 2026
  static String mesAnio(DateTime fecha) => '${_meses[fecha.month - 1]} ${fecha.year}';

  /// Mié
  static String diaCorto(DateTime fecha) => _dias[fecha.weekday - 1].substring(0, 3);

  static String fechaHora(DateTime? fecha) {
    if (fecha == null) return '—';
    return '${corta(fecha)} · ${hora12(fecha)}';
  }

  /// 2026-10-20 (formato de la API)
  static String api(DateTime fecha) {
    final mes = fecha.month.toString().padLeft(2, '0');
    final dia = fecha.day.toString().padLeft(2, '0');
    return '${fecha.year}-$mes-$dia';
  }

  /// 2026-10-24T08:30:00 (hora local, sin zona: así la espera la API)
  static String apiFechaHora(DateTime fecha) {
    final hora = fecha.hour.toString().padLeft(2, '0');
    final minuto = fecha.minute.toString().padLeft(2, '0');
    return '${api(fecha)}T$hora:$minuto:00';
  }

  /// 08:00:00
  static String horaApi(TimeOfDay hora) {
    final h = hora.hour.toString().padLeft(2, '0');
    final m = hora.minute.toString().padLeft(2, '0');
    return '$h:$m:00';
  }

  /// 10:00 AM
  static String hora12(DateTime fecha) {
    final hora = fecha.hour % 12 == 0 ? 12 : fecha.hour % 12;
    final minutos = fecha.minute.toString().padLeft(2, '0');
    final sufijo = fecha.hour < 12 ? 'AM' : 'PM';
    return '${hora.toString().padLeft(2, '0')}:$minutos $sufijo';
  }

  static String horaDelDia(TimeOfDay? hora) =>
      hora == null ? '—' : hora12(DateTime(2000, 1, 1, hora.hour, hora.minute));

  /// "08:00:00" / "08:00" → TimeOfDay
  static TimeOfDay? leerHora(dynamic valor) {
    final m = RegExp(r'(\d{1,2}):(\d{2})').firstMatch('${valor ?? ''}');
    if (m == null) return null;
    return TimeOfDay(hour: int.parse(m.group(1)!), minute: int.parse(m.group(2)!));
  }

  static int minutos(TimeOfDay hora) => hora.hour * 60 + hora.minute;

  static String saludo(DateTime fecha) {
    if (fecha.hour < 12) return 'Buenos días';
    if (fecha.hour < 19) return 'Buenas tardes';
    return 'Buenas noches';
  }

  static bool vencida(DateTime? fecha) =>
      fecha != null && soloFecha(fecha).isBefore(hoy);
}
