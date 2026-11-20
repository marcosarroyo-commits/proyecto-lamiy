import 'package:flutter/material.dart';
import 'package:lumina_app/domain/app_theme.dart';
import 'package:lumina_app/theme/colores_app.dart';
import 'package:lumina_app/widgets/filtros.dart';



Future<OpcionFiltro<T>?> elegirOpcion<T>(
  BuildContext context, {
  required String titulo,
  required List<OpcionFiltro<T>> opciones,
  T? seleccionado,
}) {
  return showModalBottomSheet<OpcionFiltro<T>>(
    context: context,
    isScrollControlled: true,
    builder: (context) {
      final c = context.colores;
      return SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Text(titulo, style: AppTheme.cormorant(size: 19, color: c.primarioOscuro)),
              ),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final opcion in opciones)
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                        title: Text(
                          opcion.texto,
                          style: AppTheme.manrope(size: 14.5, color: c.textoTitulo),
                        ),
                        trailing: opcion.valor == seleccionado
                            ? Icon(Icons.check, color: c.primario)
                            : null,
                        onTap: () => Navigator.pop(context, opcion),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
