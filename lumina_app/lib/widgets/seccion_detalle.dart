import 'package:flutter/material.dart';
import 'package:lumina_app/domain/app_theme.dart';
import 'package:lumina_app/theme/colores_app.dart';
import 'package:lumina_app/widgets/chip_estado.dart';
import 'package:lumina_app/widgets/tarjeta_base.dart';

class SeccionDetalle extends StatelessWidget {
  const SeccionDetalle({
    super.key,
    required this.titulo,
    required this.icono,
    required this.children,
    this.etiqueta,
  });

  final String titulo;
  final IconData icono;
  final List<Widget> children;
  final Widget? etiqueta;

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    return TarjetaBase(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconoCaja(icono: icono, tamano: 34),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  titulo,
                  style: AppTheme.cormorant(
                    size: 15,
                    weight: FontWeight.w600,
                    color: c.textoOscuro,
                  ),
                ),
              ),
              ?etiqueta,
            ],
          ),
          const SizedBox(height: 14),
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            children[i],
          ],
        ],
      ),
    );
  }
}

class FilaDato extends StatelessWidget {
  const FilaDato({
    super.key,
    required this.etiqueta,
    required this.valor,
    this.icono,
    this.destacado = false,
    this.complemento,
  });

  final String etiqueta;
  final String valor;
  final IconData? icono;
  final bool destacado;
  final Widget? complemento;

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: c.fondo,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          if (icono != null) ...[
            Icon(icono, size: 18, color: c.textoSutil),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  etiqueta,
                  style: AppTheme.manrope(size: 11, color: c.textoSutil),
                ),
                const SizedBox(height: 2),
                Text(
                  valor,
                  style: AppTheme.manrope(
                    size: destacado ? 16 : 14,
                    weight: destacado ? FontWeight.w700 : FontWeight.w500,
                    color: c.textoOscuro,
                  ),
                ),
              ],
            ),
          ),
          ?complemento,
        ],
      ),
    );
  }
}

class GrillaDatos extends StatelessWidget {
  const GrillaDatos({super.key, required this.datos});

  final List<FilaDato> datos;

  @override
  Widget build(BuildContext context) {
    final filas = <Widget>[];
    for (var i = 0; i < datos.length; i += 2) {
      filas.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: datos[i]),
            const SizedBox(width: 10),
            Expanded(
              child: i + 1 < datos.length ? datos[i + 1] : const SizedBox(),
            ),
          ],
        ),
      );
    }
    return Column(
      children: [
        for (var i = 0; i < filas.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          filas[i],
        ],
      ],
    );
  }
}

class Aviso extends StatelessWidget {
  const Aviso({
    super.key,
    required this.titulo,
    required this.mensaje,
    required this.tono,
    this.icono,
  });

  final String titulo;
  final String mensaje;
  final TonoEstado tono;
  final IconData? icono;

  static IconData _iconoPorTono(TonoEstado tono) => switch (tono) {
    TonoEstado.peligro => Icons.gpp_bad_outlined,
    TonoEstado.alerta => Icons.warning_amber_rounded,
    TonoEstado.exito => Icons.check_circle_outline,
    _ => Icons.info_outline,
  };

  @override
  Widget build(BuildContext context) {
    final oscuro = Theme.of(context).brightness == Brightness.dark;
    final (fondo, color) = ChipEstado.colores(tono, oscuro);
    final iconoFinal = icono ?? _iconoPorTono(tono);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(iconoFinal, color: color, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: AppTheme.cormorant(
                    size: 14,
                    weight: FontWeight.w700,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  mensaje,
                  style: AppTheme.manrope(
                    size: 12.5,
                    weight: FontWeight.w500,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class PieTrazabilidad extends StatelessWidget {
  const PieTrazabilidad({
    super.key,
    required this.registro,
    required this.actualizacion,
  });

  final String registro;
  final String actualizacion;

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    final estilo = AppTheme.manrope(size: 11, color: c.textoSutil);
    return Row(
      children: [
        Icon(Icons.event_note_outlined, size: 14, color: c.textoSutil),
        const SizedBox(width: 4),
        Expanded(child: Text('Registro: $registro', style: estilo)),
        Icon(Icons.update, size: 14, color: c.textoSutil),
        const SizedBox(width: 4),
        Expanded(child: Text('Actualizado: $actualizacion', style: estilo)),
      ],
    );
  }
}
