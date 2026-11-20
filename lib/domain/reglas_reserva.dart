import 'package:flutter/material.dart';
import 'package:lumina_app/widgets/chip_estado.dart';




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

    // Palabras relacionadas con una cancelación o anulación.
    if (s.contains('cancel') || s.contains('anul')) return cancelada;

    // Palabras relacionadas con una reserva ya atendida o finalizada.
    if (s.contains('atend') ||
        s.contains('realiz') ||
        s.contains('complet') ||
        s.contains('finaliz') ||
        s.contains('asisti')) {
      return atendida;
    }

    // Si la API marca explícitamente que no está activa, se considera cancelada.
    if (activa == false) return cancelada;

    // Cualquier estado desconocido conserva la reserva como programada.
    return programada;
  }
}

/// Medios de pago aceptados al confirmar una reserva.
abstract final class MedioPago {
  /// Pago realizado directamente en el centro.
  static const efectivo = 'Efectivo';

  /// Pago realizado mediante una transferencia bancaria.
  static const transferencia = 'Transferencia';

  /// Opciones disponibles para mostrar en el selector de pago.
  static const todos = [efectivo, transferencia];
}

/// Motivos sugeridos al cancelar una reserva.
abstract final class MotivoCancelacion {
  /// Opciones predefinidas presentadas en el formulario de cancelación.
  static const opciones = [
    'El cliente no puede asistir',
    'Reprogramará más adelante',
    'Enfermedad o calamidad',
  ];
}

/// Motivos de inasistencia de un profesional.
abstract final class MotivoInasistencia {
  /// Opciones predefinidas presentadas al registrar una inasistencia.
  static const opciones = [
    'Salud',
    'Situación familiar',
    'Vacaciones',
    'Otra causa justificada',
  ];
}
