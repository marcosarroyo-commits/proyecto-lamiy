import 'package:flutter/material.dart';
import 'package:lumina_app/domain/dias_semana.dart';
import 'package:lumina_app/domain/fechas.dart';
import 'package:lumina_app/models/horario/horario_laboral.dart';
import 'package:lumina_app/services/remote/api_service.dart';
import 'package:lumina_app/services/remote/servicio_base.dart';


class Jornada {
  const Jornada({
    required this.inicio,
    required this.fin,
    required this.almuerzo,
    this.inicioAlmuerzo,
    this.finAlmuerzo,
  });

  final TimeOfDay inicio;
  final TimeOfDay fin;
  final bool almuerzo;
  final TimeOfDay? inicioAlmuerzo;
  final TimeOfDay? finAlmuerzo;

  Map<String, dynamic> toJson() => {
    'horaInicio': Fechas.horaApi(inicio),
    'horaFin': Fechas.horaApi(fin),
    'tieneAlmuerzo': almuerzo,
    'horaInicioAlmuerzo':
        almuerzo && inicioAlmuerzo != null ? Fechas.horaApi(inicioAlmuerzo!) : null,
    'horaFinAlmuerzo': almuerzo && finAlmuerzo != null ? Fechas.horaApi(finAlmuerzo!) : null,
  };
}

class HorarioService extends ServicioBase {
  static const _ruta = '/api/horarios-laboral';

  
  Future<List<HorarioLaboral>> todos() => listarTodo(_ruta, HorarioLaboral.fromJson);

  
  Future<HorarioLaboral> obtenerPorId(int id) => obtener('$_ruta/$id', HorarioLaboral.fromJson);

  
  Future<List<HorarioLaboral>> deProfesional(int profesionalId) async {
    try {
      final lista = await listarTodo('$_ruta/profesional/$profesionalId', HorarioLaboral.fromJson);
      lista.sort((a, b) => DiasSemana.orden
          .indexOf(a.diaSemana)
          .compareTo(DiasSemana.orden.indexOf(b.diaSemana)));
      return lista;
    } on ApiException catch (e) {
      if (e.noEncontrado) return []; 
      rethrow;
    }
  }

  
  Future<void> registrar({
    required int profesionalId,
    required List<int> dias,
    required Jornada jornada,
  }) async {
    if (dias.length == 1) {
      await crear(_ruta, {
        'profesionalId': profesionalId,
        'diaSemana': dias.first,
        ...jornada.toJson(),
      });
    } else {
      await crear('$_ruta/masivo', {
        'profesionalId': profesionalId,
        'dias': dias,
        ...jornada.toJson(),
      });
    }
  }

  
  Future<void> editar(int id, Jornada jornada) => actualizar('$_ruta/$id', jornada.toJson());

  
  Future<void> borrar(int id) => eliminar('$_ruta/$id');
}
