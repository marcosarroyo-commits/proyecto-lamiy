import 'package:flutter/material.dart';
import 'package:lumina_app/domain/app_theme.dart';
import 'package:lumina_app/theme/colores_app.dart';

InputDecoration decoracionCampo(
  BuildContext context, {
  required String hint,
  required IconData icono,
  String? error,
  Widget? sufijo,
}) {
  final c = context.colores;

  OutlineInputBorder borde(Color color) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(color: color),
  );

  return InputDecoration(
    hintText: hint,
    hintStyle: AppTheme.manrope(size: 14, color: c.hint),
    errorText: error,
    filled: true,
    fillColor: c.superficie,
    prefixIcon: Icon(icono, size: 20, color: c.textoSecundario),
    suffixIcon: sufijo,
    contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
    enabledBorder: borde(c.borde),
    disabledBorder: borde(c.borde),
    focusedBorder: borde(c.primario),
    errorBorder: borde(Colors.redAccent),
    focusedErrorBorder: borde(Colors.redAccent),
  );
}