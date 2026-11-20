import 'package:flutter_test/flutter_test.dart';
import 'package:lumina_app/domain/dias_semana.dart';
import 'package:lumina_app/domain/fechas.dart';
import 'package:lumina_app/domain/formatos.dart';
import 'package:lumina_app/domain/reglas_reserva.dart';
import 'package:lumina_app/models/agenda/horario_disponible.dart';
import 'package:lumina_app/models/comun/json.dart';
import 'package:lumina_app/widgets/campos_formulario.dart';

void main() {
  test('Validaciones de la hoja de requerimientos', () {
    expect(Validar.porcentaje('101'), isNotNull);
    expect(Validar.porcentaje('45'), isNull);
    expect(Validar.correoOpcional('maria@correo'), isNotNull);
    expect(Validar.correoOpcional(''), isNull);
    expect(Validar.entero('0', 'la duración'), isNotNull);
    expect(Validar.entero('0', 'el precio', permiteCero: true), isNull);
  });

  test('Formatos', () {
    expect(Formato.moneda(45000), '\$ 45.000');
    expect(Formato.duracion(90), '1 h 30 min');
    expect(Fechas.apiFechaHora(DateTime(2026, 10, 24, 8, 30)), '2026-10-24T08:30:00');
  });

  test('Estados de reserva y días de la API', () {
    expect(EstadoReserva.desde('Cancelada'), EstadoReserva.cancelada);
    expect(EstadoReserva.desde('Atendida'), EstadoReserva.atendida);
    expect(EstadoReserva.desde('Pendiente'), EstadoReserva.programada);
    expect(DiasSemana.desdeFecha(DateTime(2026, 11, 22)), 0); // domingo
    expect(DiasSemana.leer('Monday'), 1);
  });

  test('Json tolera claves alternativas', () {
    final json = {'Valor': 30000, 'activo': 'true'};
    expect(Json.decimal(json, ['precio', 'valor']), 30000);
    expect(Json.booleano(json, 'activo'), isTrue);
  });

  test('Agenda en distintos formatos', () {
    final fecha = DateTime(2026, 10, 20);
    expect(HorarioDisponible.leerLista(['08:00', '08:30:00'], fecha).length, 2);
    final agrupado = HorarioDisponible.leerLista([
      {'profesionalId': 17, 'nombres': 'Elena', 'horarios': ['09:00', '10:00']},
    ], fecha);
    expect(agrupado.first.profesionalId, 17);
    expect(agrupado.first.profesionalNombre, 'Elena');
  });
}
