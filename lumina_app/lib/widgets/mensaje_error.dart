import 'package:flutter/material.dart';
import 'package:lumina_app/domain/app_theme.dart';
import 'package:lumina_app/theme/colores_app.dart';

class MensajeError extends StatelessWidget {
  const MensajeError(this.texto, {super.key});

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.rojoAlerta.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.rojoAlerta.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, size: 18, color: AppColors.rojoAlerta),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              texto,
              style: AppTheme.manrope(
                size: 13,
                weight: FontWeight.w500,
                color: context.colores.textoTitulo,
              ),
            ),
          ),
        ],
      ),
    );
  }
}