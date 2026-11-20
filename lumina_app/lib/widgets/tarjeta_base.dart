import 'package:flutter/material.dart';
import 'package:lumina_app/domain/app_theme.dart';
import 'package:lumina_app/theme/colores_app.dart';

class TarjetaBase extends StatelessWidget {
  const TarjetaBase({
    super.key,
    required this.child,
    this.alTocar,
    this.padding = const EdgeInsets.all(16),
    this.colorBorde,
    this.colorFondo,
  });

  final Widget child;
  final VoidCallback? alTocar;
  final EdgeInsetsGeometry padding;
  final Color? colorBorde;
  final Color? colorFondo;

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    final radio = BorderRadius.circular(16);

    return Material(
      type: MaterialType.transparency,
      child: Ink(
        decoration: BoxDecoration(
          color: colorFondo ?? c.superficie,
          borderRadius: radio,
          border: Border.all(color: colorBorde ?? c.bordeTarjeta),
          boxShadow: AppTheme.sombraSuave,
        ),
        child: InkWell(
          onTap: alTocar,
          borderRadius: radio,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

class AvatarIniciales extends StatelessWidget {
  const AvatarIniciales({super.key, required this.texto, this.tamano = 44});

  final String texto;
  final double tamano;

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    return Container(
      width: tamano,
      height: tamano,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: c.badgeFondo, shape: BoxShape.circle),
      child: Text(
        texto,
        style: AppTheme.cormorant(
          size: tamano * 0.34,
          weight: FontWeight.w700,
          color: c.primarioOscuro,
        ),
      ),
    );
  }
}

class PlacaVehiculo extends StatelessWidget {
  const PlacaVehiculo({super.key, required this.placa, this.grande = false});

  final String placa;
  final bool grande;

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: grande ? 14 : 10,
        vertical: grande ? 6 : 4,
      ),
      decoration: BoxDecoration(
        color: c.badgeFondo,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: c.primario.withValues(alpha: 0.25)),
      ),
      child: Text(
        placa.toUpperCase(),
        style: AppTheme.cormorant(
          size: grande ? 20 : 14,
          weight: FontWeight.w700,
          color: c.primarioOscuro,
        ).copyWith(letterSpacing: 1),
      ),
    );
  }
}

class IconoCaja extends StatelessWidget {
  const IconoCaja({
    super.key,
    required this.icono,
    this.tamano = 40,
    this.color,
    this.fondo,
  });

  final IconData icono;
  final double tamano;
  final Color? color;
  final Color? fondo;

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    return Container(
      width: tamano,
      height: tamano,
      decoration: BoxDecoration(
        color: fondo ?? c.badgeFondo,
        borderRadius: BorderRadius.circular(tamano * 0.3),
      ),
      child: Icon(icono, size: tamano * 0.52, color: color ?? c.primario),
    );
  }
}
