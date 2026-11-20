import 'package:flutter/material.dart';
import 'package:lumina_app/domain/app_theme.dart';
import 'package:lumina_app/theme/colores_app.dart';

class EstadoCarga extends StatelessWidget {
  const EstadoCarga({super.key, this.mensaje = 'Cargando información...'});

  final String mensaje;

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: c.primario,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              mensaje,
              textAlign: TextAlign.center,
              style: AppTheme.manrope(size: 13, color: c.textoSecundario),
            ),
          ],
        ),
      ),
    );
  }
}

class EstadoVacio extends StatelessWidget {
  const EstadoVacio({
    super.key,
    required this.icono,
    required this.titulo,
    required this.mensaje,
    this.textoAccion,
    this.iconoAccion,
    this.alAccion,
  });

  final IconData icono;
  final String titulo;
  final String mensaje;
  final String? textoAccion;
  final IconData? iconoAccion;
  final VoidCallback? alAccion;

  @override
  Widget build(BuildContext context) {
    return _EstadoBase(
      icono: icono,
      titulo: titulo,
      mensaje: mensaje,
      textoAccion: textoAccion,
      iconoAccion: iconoAccion,
      alAccion: alAccion,
    );
  }
}

class EstadoError extends StatelessWidget {
  const EstadoError({super.key, required this.mensaje, this.alReintentar});

  final String mensaje;
  final VoidCallback? alReintentar;

  @override
  Widget build(BuildContext context) {
    return _EstadoBase(
      icono: Icons.cloud_off_outlined,
      titulo: 'No pudimos cargar la información',
      mensaje: mensaje,
      textoAccion: alReintentar == null ? null : 'Reintentar',
      iconoAccion: Icons.refresh,
      alAccion: alReintentar,
      error: true,
    );
  }
}

class _EstadoBase extends StatelessWidget {
  const _EstadoBase({
    required this.icono,
    required this.titulo,
    required this.mensaje,
    this.textoAccion,
    this.iconoAccion,
    this.alAccion,
    this.error = false,
  });

  final IconData icono;
  final String titulo;
  final String mensaje;
  final String? textoAccion;
  final IconData? iconoAccion;
  final VoidCallback? alAccion;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    final colorIcono = error ? AppColors.rojoAlerta : c.primario;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: colorIcono.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icono, size: 34, color: colorIcono),
            ),
            const SizedBox(height: 18),
            Text(
              titulo,
              textAlign: TextAlign.center,
              style: AppTheme.cormorant(
                size: 16,
                weight: FontWeight.w600,
                color: c.textoOscuro,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              mensaje,
              textAlign: TextAlign.center,
              style: AppTheme.manrope(size: 13, color: c.textoSecundario),
            ),
            if (textoAccion != null && alAccion != null) ...[
              const SizedBox(height: 18),
              OutlinedButton.icon(
                onPressed: alAccion,
                icon: Icon(iconoAccion ?? Icons.add, size: 18),
                label: Text(textoAccion!),
                style: OutlinedButton.styleFrom(
                  foregroundColor: c.primario,
                  side: BorderSide(color: c.primario.withValues(alpha: 0.4)),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: AppTheme.manrope(size: 14, weight: FontWeight.w600),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
