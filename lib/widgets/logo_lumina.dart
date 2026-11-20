import 'package:flutter/material.dart';
import 'package:lumina_app/domain/app_theme.dart';
import 'package:lumina_app/theme/colores_app.dart';


class LogoLumina extends StatelessWidget {
  const LogoLumina({super.key, this.ancho = 220, this.alto = 120});

  final double ancho;
  final double alto;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: ancho,
      height: alto,
      child: Image.asset(
        'assets/images/logo.png',
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => Center(
          child: Text(
            'LUMINA',
            style: AppTheme.cormorant(
              size: 28,
              weight: FontWeight.w700,
              color: context.colores.acento,
            ),
          ),
        ),
      ),
    );
  }
}


class MonogramaLumina extends StatelessWidget {
  const MonogramaLumina({super.key, this.tamano = 44});

  final double tamano;

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    return Container(
      width: tamano,
      height: tamano,
      padding: EdgeInsets.all(tamano * 0.1),
      decoration: BoxDecoration(
        color: c.superficie,
        shape: BoxShape.circle,
        border: Border.all(color: c.acentoFondo, width: 1.5),
      ),
      child: Image.asset(
        'assets/images/logo_l.png',
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) =>
            Icon(Icons.spa_rounded, color: c.acento, size: tamano * 0.55),
      ),
    );
  }
}


class RamaDecorativa extends StatelessWidget {
  const RamaDecorativa({super.key, this.arriba = true, this.opacidad = 1});

  final bool arriba;
  final double opacidad;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacidad,
      child: Image.asset(
        arriba ? 'assets/images/rama_arriba.png' : 'assets/images/rama_abajo.png',
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
      ),
    );
  }
}
