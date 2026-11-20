import 'package:flutter/material.dart';
import 'package:lumina_app/domain/app_theme.dart';
import 'package:lumina_app/theme/colores_app.dart';
import 'package:lumina_app/widgets/marco_pantalla.dart';

class SeccionPanel {
  const SeccionPanel(this.titulo, this.icono, this.pantalla);

  final String titulo;
  final IconData icono;
  final Widget pantalla;
}

/// Pestaña agrupadora (Catálogo, Equipo, Finanzas): un selector segmentado
/// arriba y el listado de la sección elegida debajo. Cada sección se construye
/// la primera vez que se abre y conserva su estado al cambiar.
class PanelSecciones extends StatefulWidget {
  const PanelSecciones({super.key, required this.secciones});

  final List<SeccionPanel> secciones;

  @override
  State<PanelSecciones> createState() => _PanelSeccionesState();
}

class _PanelSeccionesState extends State<PanelSecciones> {
  int _indice = 0;
  final Set<int> _visitadas = {0};

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    return ColoredBox(
      color: c.fondo,
      child: Column(
        children: [
          SafeArea(
            bottom: false,
            child: ContenidoCentrado(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 2),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: c.badgeFondo,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      for (var i = 0; i < widget.secciones.length; i++)
                        Expanded(child: _segmento(c, i)),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            // El SafeArea de arriba ya cubrió la barra de estado; se quita ese
            // margen para que el encabezado de cada sección no lo repita.
            child: MediaQuery.removePadding(
              context: context,
              removeTop: true,
              child: IndexedStack(
                index: _indice,
                children: [
                  for (var i = 0; i < widget.secciones.length; i++)
                    _visitadas.contains(i) ? widget.secciones[i].pantalla : const SizedBox.shrink(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _segmento(ColoresApp c, int i) {
    final s = widget.secciones[i];
    final activo = i == _indice;
    return GestureDetector(
      onTap: () => setState(() {
        _indice = i;
        _visitadas.add(i);
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: activo ? c.superficie : Colors.transparent,
          borderRadius: BorderRadius.circular(11),
          boxShadow: activo ? AppTheme.sombraSuave : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(s.icono, size: 16, color: activo ? c.primario : c.textoGris),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                s.titulo,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.manrope(
                  size: 12.5,
                  weight: activo ? FontWeight.w700 : FontWeight.w500,
                  color: activo ? c.primario : c.textoGris,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
