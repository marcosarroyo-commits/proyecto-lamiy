import 'package:flutter/material.dart';
import 'package:lumina_app/domain/dias_semana.dart';
import 'package:lumina_app/domain/fechas.dart';
import 'package:lumina_app/models/comun/json.dart';

class HorarioLaboral {
  const HorarioLaboral({
    required this.id,
    required this.profesionalId,
    required this.diaSemana,
    required this.horaInicio,
    required this.horaFin,
    this.tieneAlmuerzo = false,
    this.inicioAlmuerzo,
    this.finAlmuerzo,
  });

  final int id;
  final int profesionalId;

  
  final int diaSemana;
  final TimeOfDay horaInicio;
  final TimeOfDay horaFin;
  final bool tieneAlmuerzo;
  final TimeOfDay? inicioAlmuerzo;
  final TimeOfDay? finAlmuerzo;

  factory HorarioLaboral.fromJson(Map<String, dynamic> json) => HorarioLaboral(
    id: Json.entero(json, ['id', 'horarioLaboralId']),
    profesionalId: Json.enteroONulo(json, 'profesionalId') ??
        Json.entero(Json.objeto(json, 'profesional'), 'id'),
    diaSemana: DiasSemana.leer(Json.valor(json, ['diaSemana', 'dia'])),
    horaInicio: Fechas.leerHora(Json.valor(json, 'horaInicio')) ??
        const TimeOfDay(hour: 8, minute: 0),
    horaFin: Fechas.leerHora(Json.valor(json, 'horaFin')) ??
        const TimeOfDay(hour: 18, minute: 0),
    tieneAlmuerzo: Json.booleano(json, 'tieneAlmuerzo'),
    inicioAlmuerzo: Fechas.leerHora(Json.valor(json, 'horaInicioAlmuerzo')),
    finAlmuerzo: Fechas.leerHora(Json.valor(json, 'horaFinAlmuerzo')),
  );

  String get dia => DiasSemana.nombre(diaSemana);

  String get rango => '${Fechas.horaDelDia(horaInicio)} – ${Fechas.horaDelDia(horaFin)}';

  String? get almuerzo => tieneAlmuerzo && inicioAlmuerzo != null && finAlmuerzo != null
      ? '${Fechas.horaDelDia(inicioAlmuerzo)} – ${Fechas.horaDelDia(finAlmuerzo)}'
      : null;

  /// Minutos efectivos de trabajo (descontando almuerzo).
  int get minutosLaborales {
    var total = Fechas.minutos(horaFin) - Fechas.minutos(horaInicio);
    if (tieneAlmuerzo && inicioAlmuerzo != null && finAlmuerzo != null) {
      total -= Fechas.minutos(finAlmuerzo!) - Fechas.minutos(inicioAlmuerzo!);
    }
    return total < 0 ? 0 : total;
  }
}
