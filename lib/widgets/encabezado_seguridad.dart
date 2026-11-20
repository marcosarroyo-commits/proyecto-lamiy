import 'package:flutter/material.dart';
import 'package:lumina_app/domain/app_theme.dart';
import 'package:lumina_app/theme/colores_app.dart';

class EncabezadoSeguridad extends StatelessWidget
    implements PreferredSizeWidget {
  const EncabezadoSeguridad({super.key, required this.titulo});

  final String titulo;

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    return AppBar(
      backgroundColor: c.fondo,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        tooltip: 'Volver',
        onPressed: () => Navigator.pop(context),
        icon: Icon(Icons.arrow_back, color: c.primarioOscuro),
      ),
      title: Text(
        titulo,
        style: AppTheme.cormorant(
          size: 18,
          weight: FontWeight.w600,
          color: c.textoOscuro,
        ),
      ),
    );
  }
}