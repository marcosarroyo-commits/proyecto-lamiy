import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lumina_app/domain/app_theme.dart';
import 'package:lumina_app/domain/fechas.dart';
import 'package:lumina_app/theme/colores_app.dart';
import 'package:lumina_app/widgets/decoracion_campo.dart';

class CampoBusqueda extends StatefulWidget {
  const CampoBusqueda({
    super.key,
    required this.hint,
    required this.alBuscar,
    this.teclado,
    this.mayusculas = false,
  });

  final String hint;
  final ValueChanged<String> alBuscar;
  final TextInputType? teclado;
  final bool mayusculas;

  @override
  State<CampoBusqueda> createState() => _CampoBusquedaState();
}

class _CampoBusquedaState extends State<CampoBusqueda> {
  final TextEditingController _controlador = TextEditingController();
  Timer? _espera;

  @override
  void dispose() {
    _espera?.cancel();
    _controlador.dispose();
    super.dispose();
  }

  void _alCambiar(String valor) {
    setState(() {});
    _espera?.cancel();
    _espera = Timer(
      const Duration(milliseconds: 450),
      () => widget.alBuscar(valor.trim()),
    );
  }

  void _limpiar() {
    _espera?.cancel();
    _controlador.clear();
    setState(() {});
    widget.alBuscar('');
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    return TextField(
      controller: _controlador,
      onChanged: _alCambiar,
      onSubmitted: (valor) {
        _espera?.cancel();
        widget.alBuscar(valor.trim());
      },
      keyboardType: widget.teclado,
      textCapitalization: widget.mayusculas
          ? TextCapitalization.characters
          : TextCapitalization.none,
      textInputAction: TextInputAction.search,
      style: AppTheme.manrope(size: 14, color: c.textoTitulo),
      decoration: decoracionCampo(
        context,
        hint: widget.hint,
        icono: Icons.search,
        sufijo: _controlador.text.isEmpty
            ? null
            : IconButton(
                tooltip: 'Limpiar',
                onPressed: _limpiar,
                icon: Icon(Icons.close, size: 18, color: c.textoSecundario),
              ),
      ),
    );
  }
}

class OpcionFiltro<T> {
  const OpcionFiltro(this.valor, this.texto);

  final T valor;
  final String texto;
}

class BarraFiltros<T> extends StatelessWidget {
  const BarraFiltros({
    super.key,
    required this.opciones,
    required this.seleccionado,
    required this.alCambiar,
    this.extra = const [],
  });

  final List<OpcionFiltro<T>> opciones;
  final T seleccionado;
  final ValueChanged<T> alCambiar;
  final List<Widget> extra;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final widgetExtra in extra) ...[
            widgetExtra,
            const SizedBox(width: 8),
          ],
          for (final opcion in opciones) ...[
            PildoraFiltro(
              texto: opcion.texto,
              activa: opcion.valor == seleccionado,
              alTocar: () => alCambiar(opcion.valor),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class PildoraFiltro extends StatelessWidget {
  const PildoraFiltro({
    super.key,
    required this.texto,
    required this.activa,
    required this.alTocar,
    this.icono,
    this.alQuitar,
  });

  final String texto;
  final bool activa;
  final VoidCallback alTocar;
  final IconData? icono;
  final VoidCallback? alQuitar;

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    final colorTexto = activa ? Colors.white : c.textoGris;

    return Material(
      color: activa ? AppColors.primario : c.superficie,
      shape: StadiumBorder(
        side: BorderSide(color: activa ? AppColors.primario : c.borde),
      ),
      child: InkWell(
        onTap: alTocar,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: EdgeInsets.fromLTRB(14, 7, alQuitar == null ? 14 : 6, 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icono != null) ...[
                Icon(icono, size: 15, color: colorTexto),
                const SizedBox(width: 6),
              ],
              Text(
                texto,
                style: AppTheme.manrope(
                  size: 12.5,
                  weight: FontWeight.w600,
                  color: colorTexto,
                ),
              ),
              if (alQuitar != null) ...[
                const SizedBox(width: 2),
                InkWell(
                  onTap: alQuitar,
                  customBorder: const CircleBorder(),
                  child: Padding(
                    padding: const EdgeInsets.all(2),
                    child: Icon(Icons.close, size: 15, color: colorTexto),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class FiltroFecha extends StatelessWidget {
  const FiltroFecha({
    super.key,
    required this.etiqueta,
    required this.valor,
    required this.alCambiar,
  });

  final String etiqueta;
  final DateTime? valor;
  final ValueChanged<DateTime?> alCambiar;

  @override
  Widget build(BuildContext context) {
    return PildoraFiltro(
      texto: valor == null ? etiqueta : '$etiqueta: ${Fechas.corta(valor)}',
      activa: valor != null,
      icono: Icons.calendar_today_outlined,
      alQuitar: valor == null ? null : () => alCambiar(null),
      alTocar: () async {
        final elegida = await showDatePicker(
          context: context,
          initialDate: valor ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime(DateTime.now().year + 2),
          helpText: etiqueta,
        );
        if (elegida != null) alCambiar(elegida);
      },
    );
  }
}

class ContadorResultados extends StatelessWidget {
  const ContadorResultados({
    super.key,
    required this.mostrados,
    required this.total,
    required this.sustantivo,
  });

  final int mostrados;
  final int total;
  final String sustantivo;

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    return Text(
      'Mostrando $mostrados de $total $sustantivo',
      style: AppTheme.manrope(size: 12, color: c.textoSutil),
    );
  }
}
