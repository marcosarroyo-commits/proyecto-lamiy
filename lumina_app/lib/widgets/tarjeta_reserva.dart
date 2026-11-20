import 'package:flutter/material.dart';
import 'package:lumina_app/domain/app_theme.dart';
import 'package:lumina_app/domain/fechas.dart';
import 'package:lumina_app/domain/formatos.dart';
import 'package:lumina_app/models/reserva/reserva.dart';
import 'package:lumina_app/theme/colores_app.dart';
import 'package:lumina_app/widgets/chip_estado.dart';
import 'package:lumina_app/widgets/tarjeta_base.dart';

class TarjetaReserva extends StatelessWidget {
  const TarjetaReserva({super.key, required this.reserva, required this.alTocar});

  final Reserva reserva;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    final r = reserva;
    final oscuro = Theme.of(context).brightness == Brightness.dark;
    final (_, colorEstado) = ChipEstado.colores(r.estado.tono, oscuro);
    final hora = Fechas.hora12(r.fecha).split(' ');

    return Opacity(
      opacity: r.cancelada ? 0.7 : 1,
      child: TarjetaBase(
        alTocar: alTocar,
        padding: EdgeInsets.zero,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 4,
                decoration: BoxDecoration(
                  color: colorEstado,
                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 14, 14, 14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 58,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(hora.first,
                                style: AppTheme.cormorant(size: 18, color: c.primarioOscuro)),
                            Text(hora.length > 1 ? hora[1] : '',
                                style: AppTheme.manrope(size: 11, color: c.textoSutil)),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              r.clienteNombre ?? 'Cliente',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTheme.cormorant(size: 15.5, color: c.textoOscuro).copyWith(
                                decoration: r.cancelada ? TextDecoration.lineThrough : null,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${r.servicioNombre ?? 'Servicio'} · ${r.profesionalNombre ?? 'Sin asignar'}',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppTheme.manrope(size: 12.5, color: c.textoSutil),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                r.estado.chip,
                                const SizedBox(width: 8),
                                if ((r.duracion ?? 0) > 0)
                                  Text(Formato.duracion(r.duracion),
                                      style: AppTheme.manrope(size: 11.5, color: c.textoSutil)),
                                const Spacer(),
                                Text(r.codigo,
                                    style: AppTheme.manrope(size: 11.5, color: c.hint)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
