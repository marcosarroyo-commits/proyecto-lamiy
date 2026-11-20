import 'package:lumina_app/models/reserva/reserva.dart';

enum FiltroEstado {
  activas('Activas'),
  programadas('Programadas'),
  atendidas('Atendidas'),
  canceladas('Canceladas'),
  todas('Todas');

  const FiltroEstado(this.texto);

  final String texto;

  bool acepta(Reserva r) => switch (this) {
    FiltroEstado.activas => !r.cancelada,
    FiltroEstado.programadas => r.programada,
    FiltroEstado.atendidas => r.atendida,
    FiltroEstado.canceladas => r.cancelada,
    FiltroEstado.todas => true,
  };
}


class FiltrosAgenda {
  const FiltrosAgenda({
    this.cliente = '',
    this.servicioId,
    this.profesionalId,
    this.estado = FiltroEstado.activas,
  });

  final String cliente;
  final int? servicioId;
  final int? profesionalId;
  final FiltroEstado estado;

  int get activos =>
      (cliente.trim().isNotEmpty ? 1 : 0) +
      (servicioId != null ? 1 : 0) +
      (profesionalId != null ? 1 : 0) +
      (estado != FiltroEstado.activas ? 1 : 0);

  bool acepta(Reserva r, {int? profesionalFijo}) {
    final q = cliente.trim().toLowerCase();
    final profesional = profesionalFijo ?? profesionalId;
    return estado.acepta(r) &&
        (servicioId == null || r.servicioId == servicioId) &&
        (profesional == null || r.profesionalId == profesional) &&
        (q.isEmpty ||
            (r.clienteNombre ?? '').toLowerCase().contains(q) ||
            (r.clienteDocumento ?? '').contains(q));
  }
}
