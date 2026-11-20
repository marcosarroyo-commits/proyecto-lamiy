import 'package:flutter/material.dart';
import 'package:lumina_app/domain/app_theme.dart';
import 'package:lumina_app/domain/fechas.dart';
import 'package:lumina_app/domain/formatos.dart';
import 'package:lumina_app/models/reserva/reserva_borrador.dart';
import 'package:lumina_app/screens/inicio/inicio_screen.dart';
import 'package:lumina_app/screens/reservas/detalle_reserva_screen.dart';
import 'package:lumina_app/screens/reservas/formulario_reserva_screen.dart';
import 'package:lumina_app/theme/colores_app.dart';
import 'package:lumina_app/widgets/boton_principal.dart';
import 'package:lumina_app/widgets/barra_acciones.dart';
import 'package:lumina_app/widgets/marco_pantalla.dart';
import 'package:lumina_app/widgets/seccion_detalle.dart';


class ReservaCreadaScreen extends StatelessWidget {
  const ReservaCreadaScreen({
    super.key,
    required this.borrador,
    required this.reservaId,
    required this.medioPago,
  });

  final ReservaBorrador borrador;
  final int? reservaId;
  final String medioPago;

  void _irAgenda(BuildContext context) {
    Navigator.popUntil(context, (ruta) => ruta.isFirst);
    InicioScreen.pestanaSolicitada.value = InicioScreen.pestanaAgenda;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    final f = borrador.horario.inicio;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _irAgenda(context);
      },
      child: Scaffold(
        backgroundColor: c.superficie,
        body: SafeArea(
          child: ContenidoCentrado(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 40, 20, 24),
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.6, end: 1),
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.elasticOut,
                  builder: (_, escala, hijo) => Transform.scale(scale: escala, child: hijo),
                  child: Center(
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: c.verde.withValues(alpha: 0.12),
                        border: Border.all(color: c.verde.withValues(alpha: 0.3), width: 6),
                      ),
                      child: Icon(Icons.check_rounded, size: 54, color: c.verde),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text('¡Reserva creada!', textAlign: TextAlign.center,
                    style: AppTheme.cormorant(size: 28, color: c.primarioOscuro)),
                const SizedBox(height: 4),
                Text(
                  reservaId == null ? 'La reserva quedó programada.' : 'Reserva C-$reservaId programada.',
                  textAlign: TextAlign.center,
                  style: AppTheme.manrope(size: 14, color: c.textoSutil),
                ),
                const SizedBox(height: 24),
                SeccionDetalle(
                  titulo: 'Resumen',
                  icono: Icons.event_available_outlined,
                  children: [
                    FilaDato(icono: Icons.person_outline, etiqueta: 'Cliente', valor: borrador.clienteNombre),
                    FilaDato(icono: Icons.content_cut_outlined, etiqueta: 'Servicio', valor: borrador.servicio.nombre),
                    FilaDato(icono: Icons.event_outlined, etiqueta: 'Fecha y hora', valor: '${Fechas.fechaLarga(f)} · ${Fechas.hora12(f)}'),
                    FilaDato(icono: Icons.face_retouching_natural, etiqueta: 'Profesional', valor: borrador.profesionalNombre),
                    FilaDato(
                      icono: Icons.payments_outlined,
                      etiqueta: 'Valor · Medio de pago',
                      valor: '${Formato.moneda(borrador.servicio.precio)} · $medioPago',
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                if (reservaId != null) ...[
                  BotonPrincipal(
                    texto: 'Ver reserva',
                    alPresionar: () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => DetalleReservaScreen(reservaId: reservaId)),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                BotonSecundario(
                  texto: 'Ir a la agenda',
                  icono: Icons.calendar_month_outlined,
                  alPresionar: () => _irAgenda(context),
                ),
                const SizedBox(height: 6),
                TextButton(
                  onPressed: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const FormularioReservaScreen()),
                  ),
                  child: const Text('Crear otra reserva'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
