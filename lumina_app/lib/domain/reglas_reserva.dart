import 'package:flutter/material.dart';
import 'package:lumina_app/widgets/chip_estado.dart';

/// Regla de negocio: ciclo de vida de una reserva.
/// Programada → Atendida, o Programada → Cancelada. Los nombres se usan
/// igual en toda la app (agenda, detalle, inicio, cierres).
enum EstadoReserva {
  programada('Programada', TonoEstado.alerta, Icons.schedule),
  atendida('Atendida', TonoEstado.exito, Icons.verified_outlined),
  cancelada('Cancelada', TonoEstado.peligro, Icons.cancel_outlined);

  const EstadoReserva(this.texto, this.tono, this.icono);

  final String texto;
  final TonoEstado tono;
  final IconData icono;

  ChipEstado get chip => ChipEstado(texto: texto, tono: tono, icono: icono);

  static EstadoReserva desde(dynamic valor, {bool? activa}) {
    final s = '${valor ?? ''}'.toLowerCase();
    if (s.contains('cancel') || s.contains('anul')) return cancelada;
    if (s.contains('atend') ||
        s.contains('realiz') ||
        s.contains('complet') ||
        s.contains('finaliz') ||
        s.contains('asisti')) {
      return atendida;
    }
    if (activa == false) return cancelada;
    return programada;
  }
}

/// Medios de pago aceptados al confirmar una reserva.
abstract final class MedioPago {
  static const efectivo = 'Efectivo';
  static const transferencia = 'Transferencia';
  static const todos = [efectivo, transferencia];
}

/// Motivos sugeridos al cancelar una reserva.
abstract final class MotivoCancelacion {
  static const opciones = [
    'El cliente no puede asistir',
    'Reprogramará más adelante',
    'Enfermedad o calamidad',
  ];
}

/// Motivos de inasistencia de un profesional.
abstract final class MotivoInasistencia {
  static const opciones = [
    'Salud',
    'Situación familiar',
    'Vacaciones',
    'Otra causa justificada',
  ];
}
