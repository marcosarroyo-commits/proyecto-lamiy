import 'package:flutter/material.dart';
import 'package:lumina_app/domain/app_theme.dart';
import 'package:lumina_app/theme/colores_app.dart';

class TarjetaMetrica extends StatelessWidget {
  const TarjetaMetrica({
    super.key,
    required this.icono,
    required this.valor,
    required this.titulo,
    this.alTocar,
  });

  final IconData icono;
  final String valor;
  final String titulo;
  final VoidCallback? alTocar;

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    final radio = BorderRadius.circular(16);

    return Material(
      type: MaterialType.transparency,
      child: Ink(
        decoration: BoxDecoration(
          color: c.superficie,
          borderRadius: radio,
          border: Border.all(color: c.bordeTarjeta),
          boxShadow: AppTheme.sombraSuave,
        ),
        child: InkWell(
          onTap: alTocar,
          borderRadius: radio,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: c.badgeFondo,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icono, size: 20, color: c.primario),
                ),
                const SizedBox(height: 12),
                Text(
                  valor,
                  style: AppTheme.cormorant(
                    size: 22,
                    weight: FontWeight.w700,
                    color: c.textoOscuro,
                  ),
                ),
                Text(
                  titulo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.manrope(size: 12, color: c.textoSutil),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}