import 'package:flutter/material.dart';
import 'package:lumina_app/domain/app_theme.dart';
import 'package:lumina_app/domain/fechas.dart';
import 'package:lumina_app/domain/formatos.dart';
import 'package:lumina_app/domain/reglas_reserva.dart';
import 'package:lumina_app/models/reserva/reserva_borrador.dart';
import 'package:lumina_app/screens/reservas/reserva_creada_screen.dart';
import 'package:lumina_app/services/remote/api_service.dart';
import 'package:lumina_app/services/remote/reserva_service.dart';
import 'package:lumina_app/theme/colores_app.dart';
import 'package:lumina_app/widgets/barra_acciones.dart';
import 'package:lumina_app/widgets/campos_formulario.dart';
import 'package:lumina_app/widgets/encabezado_modulo.dart';
import 'package:lumina_app/widgets/marco_pantalla.dart';
import 'package:lumina_app/widgets/mensaje_error.dart';
import 'package:lumina_app/widgets/seccion_detalle.dart';

/// Resumen de solo lectura + medio de pago antes de crear la reserva.
class ConfirmarReservaScreen extends StatefulWidget {
  const ConfirmarReservaScreen({super.key, required this.borrador});

  final ReservaBorrador borrador;

  @override
  State<ConfirmarReservaScreen> createState() => _ConfirmarReservaScreenState();
}

class _ConfirmarReservaScreenState extends State<ConfirmarReservaScreen> {
  String _medioPago = MedioPago.efectivo;
  bool _guardando = false;
  String? _error;

  Future<void> _confirmar() async {
    setState(() {
      _guardando = true;
      _error = null;
    });
    try {
      final id = await ReservaService().registrar(widget.borrador, medioPago: _medioPago);
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => ReservaCreadaScreen(
            borrador: widget.borrador,
            reservaId: id,
            medioPago: _medioPago,
          ),
        ),
        (ruta) => ruta.isFirst,
      );
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    final b = widget.borrador;
    final f = b.horario.inicio;
    return Scaffold(
      backgroundColor: c.fondo,
      appBar: const EncabezadoModulo(titulo: 'Confirmar reserva', subtitulo: 'Revisa la información antes de confirmar'),
      body: ContenidoCentrado(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            if (_error != null) ...[MensajeError(_error!), const SizedBox(height: 16)],
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.malva, AppColors.primario],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('RESUMEN DE LA RESERVA',
                      style: AppTheme.manrope(size: 11, weight: FontWeight.w700, color: Colors.white70)
                          .copyWith(letterSpacing: 1.4)),
                  const SizedBox(height: 8),
                  Text(b.servicio.nombre, style: AppTheme.cormorant(size: 24, color: Colors.white)),
                  Text('${Fechas.fechaLarga(f)} · ${Fechas.hora12(f)}',
                      style: AppTheme.manrope(size: 13, weight: FontWeight.w700, color: Colors.white)),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Text(Formato.moneda(b.servicio.precio),
                          style: AppTheme.cormorant(size: 26, color: Colors.white)),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(20)),
                        child: Text(Formato.duracion(b.servicio.duracion),
                            style: AppTheme.manrope(size: 12, weight: FontWeight.w700, color: Colors.white)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SeccionDetalle(
              titulo: 'Datos de la cita',
              icono: Icons.event_note_outlined,
              children: [
                FilaDato(
                  icono: Icons.person_outline,
                  etiqueta: b.primeraVez ? 'Cliente (primera vez)' : 'Cliente',
                  valor: '${b.clienteNombre} · CC ${b.clienteDocumento}',
                ),
                FilaDato(icono: Icons.content_cut_outlined, etiqueta: 'Servicio', valor: b.servicio.nombre),
                GrillaDatos(datos: [
                  FilaDato(etiqueta: 'Precio', valor: Formato.moneda(b.servicio.precio)),
                  FilaDato(etiqueta: 'Duración', valor: Formato.duracion(b.servicio.duracion)),
                  FilaDato(etiqueta: 'Fecha', valor: Fechas.corta(f)),
                  FilaDato(etiqueta: 'Hora', valor: Fechas.hora12(f)),
                ]),
                FilaDato(icono: Icons.face_retouching_natural, etiqueta: 'Profesional', valor: b.profesionalNombre),
              ],
            ),
            const SizedBox(height: 20),
            const EtiquetaCampo('Medio de pago', obligatorio: true),
            const SizedBox(height: 8),
            Row(
              children: [
                for (final medio in MedioPago.todos) ...[
                  Expanded(
                    child: _OpcionPago(
                      texto: medio,
                      icono: medio == MedioPago.efectivo ? Icons.payments_outlined : Icons.account_balance_outlined,
                      seleccionada: _medioPago == medio,
                      alTocar: () => setState(() => _medioPago = medio),
                    ),
                  ),
                  if (medio != MedioPago.todos.last) const SizedBox(width: 10),
                ],
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: BarraAcciones(
        textoPrincipal: 'Confirmar reserva',
        textoSecundario: 'Volver a editar',
        alPrincipal: _confirmar,
        cargando: _guardando,
      ),
    );
  }
}

class _OpcionPago extends StatelessWidget {
  const _OpcionPago({required this.texto, required this.icono, required this.seleccionada, required this.alTocar});

  final String texto;
  final IconData icono;
  final bool seleccionada;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    return InkWell(
      onTap: alTocar,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: seleccionada ? c.badgeFondo : c.superficie,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: seleccionada ? c.primario : c.borde, width: seleccionada ? 1.6 : 1),
        ),
        child: Row(
          children: [
            Icon(seleccionada ? Icons.radio_button_checked : Icons.radio_button_off,
                color: seleccionada ? c.primario : c.hint, size: 20),
            const SizedBox(width: 8),
            Icon(icono, size: 18, color: c.primario),
            const SizedBox(width: 6),
            Flexible(
              child: Text(texto, style: AppTheme.manrope(size: 13.5, weight: FontWeight.w700, color: c.textoOscuro)),
            ),
          ],
        ),
      ),
    );
  }
}
