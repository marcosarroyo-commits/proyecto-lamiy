import 'package:flutter/material.dart';
import 'package:lumina_app/theme/colores_app.dart';
import 'package:lumina_app/widgets/boton_principal.dart';
import 'package:lumina_app/widgets/marco_pantalla.dart';

class BarraAcciones extends StatelessWidget {
  const BarraAcciones({
    super.key,
    required this.textoPrincipal,
    required this.alPrincipal,
    this.cargando = false,
    this.textoSecundario = 'Cancelar',
    this.alSecundario,
  });

  final String textoPrincipal;
  final VoidCallback alPrincipal;
  final bool cargando;
  final String textoSecundario;
  final VoidCallback? alSecundario;

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    return Container(
      decoration: BoxDecoration(
        color: c.superficie,
        border: Border(top: BorderSide(color: c.bordeTarjeta)),
      ),
      child: SafeArea(
        top: false,
        child: ContenidoCentrado(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: OutlinedButton(
                      onPressed: cargando
                          ? null
                          : (alSecundario ?? () => Navigator.maybePop(context)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: c.textoGris,
                        side: BorderSide(color: c.borde),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(textoSecundario),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: BotonPrincipal(
                    texto: textoPrincipal,
                    alPresionar: alPrincipal,
                    cargando: cargando,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class BotonSecundario extends StatelessWidget {
  const BotonSecundario({
    super.key,
    required this.texto,
    required this.icono,
    required this.alPresionar,
    this.peligro = false,
  });

  final String texto;
  final IconData icono;
  final VoidCallback? alPresionar;
  final bool peligro;

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    final color = peligro ? const Color(0xFFBA1A1A) : c.primario;
    return SizedBox(
      height: 52,
      child: OutlinedButton.icon(
        onPressed: alPresionar,
        icon: Icon(icono, size: 20),
        label: Text(texto),
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          backgroundColor: color.withValues(alpha: 0.06),
          side: BorderSide(color: color.withValues(alpha: 0.35)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

class PieAcciones extends StatelessWidget {
  const PieAcciones({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    return Container(
      decoration: BoxDecoration(
        color: c.superficie,
        border: Border(top: BorderSide(color: c.bordeTarjeta)),
      ),
      child: SafeArea(
        top: false,
        child: ContenidoCentrado(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(
              children: [
                for (var i = 0; i < children.length; i++) ...[
                  if (i > 0) const SizedBox(width: 12),
                  Expanded(child: children[i]),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
