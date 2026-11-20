import 'package:flutter/material.dart';
import 'package:lumina_app/domain/app_theme.dart';
import 'package:lumina_app/theme/colores_app.dart';
import 'package:lumina_app/widgets/decoracion_campo.dart';

Future<bool> confirmarAccion(
  BuildContext context, {
  required String titulo,
  required String mensaje,
  String textoConfirmar = 'Confirmar',
  bool peligrosa = false,
  IconData? icono,
}) async {
  final resultado = await showDialog<bool>(
    context: context,
    builder: (context) => _DialogoBase(
      titulo: titulo,
      mensaje: mensaje,
      icono: icono ?? (peligrosa ? Icons.warning_amber_rounded : Icons.help_outline),
      peligrosa: peligrosa,
      textoConfirmar: textoConfirmar,
      alConfirmar: () => Navigator.pop(context, true),
    ),
  );
  return resultado ?? false;
}

Future<String?> solicitarMotivo(
  BuildContext context, {
  required String titulo,
  required String mensaje,
  String etiqueta = 'Motivo',
  String textoConfirmar = 'Continuar',
  bool peligrosa = true,
}) {
  return showDialog<String>(
    context: context,
    builder: (context) => _DialogoMotivo(
      titulo: titulo,
      mensaje: mensaje,
      etiqueta: etiqueta,
      textoConfirmar: textoConfirmar,
      peligrosa: peligrosa,
    ),
  );
}

Future<void> mostrarInformacion(
  BuildContext context, {
  required String titulo,
  required Widget contenido,
  IconData icono = Icons.check_circle_outline,
}) {
  return showDialog<void>(
    context: context,
    builder: (context) {
      final c = context.colores;
      return AlertDialog(
        backgroundColor: c.superficie,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: Icon(icono, color: c.verde, size: 36),
        title: Text(
          titulo,
          textAlign: TextAlign.center,
          style: AppTheme.cormorant(
            size: 18,
            weight: FontWeight.w700,
            color: c.textoOscuro,
          ),
        ),
        content: contenido,
        actions: [
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.pop(context),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primario,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Entendido'),
            ),
          ),
        ],
      );
    },
  );
}

void mostrarExito(BuildContext context, String mensaje) {
  _mostrarAviso(context, mensaje, Icons.check_circle, const Color(0xFF006C49));
}

void mostrarError(BuildContext context, String mensaje) {
  _mostrarAviso(context, mensaje, Icons.error_outline, AppColors.rojoAlerta);
}

void _mostrarAviso(
  BuildContext context,
  String mensaje,
  IconData icono,
  Color color,
) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: color,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      content: Row(
        children: [
          Icon(icono, color: Colors.white, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              mensaje,
              style: AppTheme.manrope(
                size: 13,
                weight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _DialogoBase extends StatelessWidget {
  const _DialogoBase({
    required this.titulo,
    required this.mensaje,
    required this.icono,
    required this.peligrosa,
    required this.textoConfirmar,
    required this.alConfirmar,
    this.contenido,
  });

  final String titulo;
  final String mensaje;
  final IconData icono;
  final bool peligrosa;
  final String textoConfirmar;
  final VoidCallback alConfirmar;
  final Widget? contenido;

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    final color = peligrosa ? AppColors.rojoAlerta : AppColors.primario;

    return AlertDialog(
      backgroundColor: c.superficie,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      icon: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: Icon(icono, color: color, size: 28),
      ),
      title: Text(
        titulo,
        textAlign: TextAlign.center,
        style: AppTheme.cormorant(
          size: 18,
          weight: FontWeight.w700,
          color: c.textoOscuro,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            mensaje,
            textAlign: TextAlign.center,
            style: AppTheme.manrope(size: 14, color: c.textoSecundario),
          ),
          if (contenido != null) ...[const SizedBox(height: 16), contenido!],
        ],
      ),
      actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      actions: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: c.textoGris,
                  side: BorderSide(color: c.borde),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Cancelar'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: alConfirmar,
                style: FilledButton.styleFrom(
                  backgroundColor: color,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(textoConfirmar, textAlign: TextAlign.center),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DialogoMotivo extends StatefulWidget {
  const _DialogoMotivo({
    required this.titulo,
    required this.mensaje,
    required this.etiqueta,
    required this.textoConfirmar,
    required this.peligrosa,
  });

  final String titulo;
  final String mensaje;
  final String etiqueta;
  final String textoConfirmar;
  final bool peligrosa;

  @override
  State<_DialogoMotivo> createState() => _DialogoMotivoState();
}

class _DialogoMotivoState extends State<_DialogoMotivo> {
  final TextEditingController _motivo = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _motivo.dispose();
    super.dispose();
  }

  void _confirmar() {
    final texto = _motivo.text.trim();
    if (texto.length < 5) {
      setState(() => _error = 'Describe el motivo (mínimo 5 caracteres).');
      return;
    }
    Navigator.pop(context, texto);
  }

  @override
  Widget build(BuildContext context) {
    return _DialogoBase(
      titulo: widget.titulo,
      mensaje: widget.mensaje,
      icono: Icons.edit_note,
      peligrosa: widget.peligrosa,
      textoConfirmar: widget.textoConfirmar,
      alConfirmar: _confirmar,
      contenido: TextField(
        controller: _motivo,
        autofocus: true,
        maxLines: 3,
        minLines: 2,
        textCapitalization: TextCapitalization.sentences,
        decoration: decoracionCampo(
          context,
          hint: widget.etiqueta,
          icono: Icons.notes,
          error: _error,
        ),
      ),
    );
  }
}
