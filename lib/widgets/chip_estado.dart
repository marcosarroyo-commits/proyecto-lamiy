import 'package:flutter/material.dart';
import 'package:lumina_app/domain/app_theme.dart';

enum TonoEstado { exito, alerta, peligro, info, neutro }

class ChipEstado extends StatelessWidget {
  const ChipEstado({
    super.key,
    required this.texto,
    required this.tono,
    this.icono,
  });

  factory ChipEstado.activo(
    bool activo, {
    String textoActivo = 'Activo',
    String textoInactivo = 'Inactivo',
  }) {
    return ChipEstado(
      texto: activo ? textoActivo : textoInactivo,
      tono: activo ? TonoEstado.exito : TonoEstado.neutro,
    );
  }

  final String texto;
  final TonoEstado tono;
  final IconData? icono;

  static (Color fondo, Color texto) colores(TonoEstado tono, bool oscuro) {
    final base = switch (tono) {
      TonoEstado.exito => (const Color(0xFFD1FAE5), const Color(0xFF006C49)),
      TonoEstado.alerta => (const Color(0xFFFFEDD5), const Color(0xFF9A4A00)),
      TonoEstado.peligro => (const Color(0xFFFFDAD6), const Color(0xFFBA1A1A)),
      TonoEstado.info => (const Color(0xFFDCE1FF), const Color(0xFF264191)),
      TonoEstado.neutro => (const Color(0xFFEEF0F4), const Color(0xFF444651)),
    };
    if (!oscuro) return base;
    final claro = switch (tono) {
      TonoEstado.exito => const Color(0xFF6EE7B7),
      TonoEstado.alerta => const Color(0xFFFDBA74),
      TonoEstado.peligro => const Color(0xFFFCA5A5),
      TonoEstado.info => const Color(0xFFA5B4FC),
      TonoEstado.neutro => const Color(0xFFCBD5E1),
    };
    return (claro.withValues(alpha: 0.16), claro);
  }

  @override
  Widget build(BuildContext context) {
    final oscuro = Theme.of(context).brightness == Brightness.dark;
    final (fondo, color) = colores(tono, oscuro);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(9999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icono != null) ...[
            Icon(icono, size: 13, color: color),
            const SizedBox(width: 4),
          ] else ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
          ],
          Text(
            texto,
            style: AppTheme.manrope(
              size: 11,
              weight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
