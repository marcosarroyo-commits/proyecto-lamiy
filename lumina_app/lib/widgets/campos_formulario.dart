import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lumina_app/domain/app_theme.dart';
import 'package:lumina_app/domain/fechas.dart';
import 'package:lumina_app/theme/colores_app.dart';
import 'package:lumina_app/widgets/decoracion_campo.dart';

class EtiquetaCampo extends StatelessWidget {
  const EtiquetaCampo(this.texto, {super.key, this.obligatorio = false});

  final String texto;
  final bool obligatorio;

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    return Text.rich(
      TextSpan(
        text: texto.toUpperCase(),
        children: [
          if (obligatorio)
            const TextSpan(
              text: ' *',
              style: TextStyle(color: AppColors.rojoAlerta),
            ),
        ],
      ),
      style: AppTheme.manrope(
        size: 11.5,
        weight: FontWeight.w700,
        color: c.textoEtiqueta,
      ).copyWith(letterSpacing: 0.6),
    );
  }
}

class TituloSeccionFormulario extends StatelessWidget {
  const TituloSeccionFormulario({
    super.key,
    required this.titulo,
    required this.icono,
    this.descripcion,
  });

  final String titulo;
  final IconData icono;
  final String? descripcion;

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Row(
        children: [
          Icon(icono, size: 20, color: c.primario),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: AppTheme.cormorant(
                    size: 15,
                    weight: FontWeight.w600,
                    color: c.primarioOscuro,
                  ),
                ),
                if (descripcion != null)
                  Text(
                    descripcion!,
                    style: AppTheme.manrope(size: 12, color: c.textoSutil),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CampoTexto extends StatelessWidget {
  const CampoTexto({
    super.key,
    required this.etiqueta,
    required this.controlador,
    required this.icono,
    this.hint = '',
    this.validador,
    this.teclado,
    this.formateadores,
    this.lineas = 1,
    this.habilitado = true,
    this.obligatorio = false,
    this.mayusculas = TextCapitalization.none,
    this.alCambiar,
    this.accion = TextInputAction.next,
    this.longitudMaxima,
  });

  final String etiqueta;
  final TextEditingController controlador;
  final IconData icono;
  final String hint;
  final String? Function(String valor)? validador;
  final TextInputType? teclado;
  final List<TextInputFormatter>? formateadores;
  final int lineas;
  final bool habilitado;
  final bool obligatorio;
  final TextCapitalization mayusculas;
  final ValueChanged<String>? alCambiar;
  final TextInputAction accion;
  final int? longitudMaxima;

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EtiquetaCampo(etiqueta, obligatorio: obligatorio),
        const SizedBox(height: 6),
        TextFormField(
          controller: controlador,
          enabled: habilitado,
          keyboardType: teclado,
          inputFormatters: formateadores,
          maxLines: lineas,
          minLines: 1,
          maxLength: longitudMaxima,
          textCapitalization: mayusculas,
          textInputAction: lineas > 1 ? TextInputAction.newline : accion,
          onChanged: alCambiar,
          validator: validador == null ? null : (v) => validador!(v ?? ''),
          style: AppTheme.manrope(
            size: 14,
            color: habilitado ? c.textoTitulo : c.textoSecundario,
          ),
          decoration: decoracionCampo(
            context,
            hint: hint,
            icono: icono,
          ).copyWith(counterText: ''),
        ),
      ],
    );
  }
}

class CampoFecha extends StatelessWidget {
  const CampoFecha({
    super.key,
    required this.etiqueta,
    required this.valor,
    required this.alCambiar,
    this.primera,
    this.ultima,
    this.validador,
    this.obligatorio = false,
    this.habilitado = true,
    this.hint = 'Seleccionar fecha',
    this.icono = Icons.event_outlined,
  });

  final String etiqueta;
  final DateTime? valor;
  final ValueChanged<DateTime> alCambiar;
  final DateTime? primera;
  final DateTime? ultima;
  final String? Function(DateTime? valor)? validador;
  final bool obligatorio;
  final bool habilitado;
  final String hint;
  final IconData icono;

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EtiquetaCampo(etiqueta, obligatorio: obligatorio),
        const SizedBox(height: 6),
        FormField<DateTime>(
          initialValue: valor,
          validator: validador,
          builder: (estado) {
            final actual = estado.value;
            return InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: !habilitado
                  ? null
                  : () async {
                      final inicio = primera ?? DateTime(1920);
                      final fin = ultima ?? DateTime(DateTime.now().year + 15);
                      var inicial = actual ?? DateTime.now();
                      if (inicial.isBefore(inicio)) inicial = inicio;
                      if (inicial.isAfter(fin)) inicial = fin;
                      final elegida = await showDatePicker(
                        context: context,
                        initialDate: inicial,
                        firstDate: inicio,
                        lastDate: fin,
                        helpText: etiqueta,
                      );
                      if (elegida == null) return;
                      estado.didChange(elegida);
                      alCambiar(elegida);
                    },
              child: InputDecorator(
                isEmpty: actual == null,
                decoration: decoracionCampo(
                  context,
                  hint: hint,
                  icono: icono,
                ).copyWith(
                  errorText: estado.errorText,
                  enabled: habilitado,
                  suffixIcon: Icon(
                    Icons.expand_more,
                    color: c.textoSecundario,
                  ),
                ),
                child: Text(
                  actual == null ? '' : Fechas.corta(actual),
                  style: AppTheme.manrope(
                    size: 14,
                    color: habilitado ? c.textoTitulo : c.textoSecundario,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class CampoHora extends StatelessWidget {
  const CampoHora({
    super.key,
    required this.etiqueta,
    required this.valor,
    required this.alCambiar,
    this.obligatorio = false,
  });

  final String etiqueta;
  final TimeOfDay? valor;
  final ValueChanged<TimeOfDay> alCambiar;
  final bool obligatorio;

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EtiquetaCampo(etiqueta, obligatorio: obligatorio),
        const SizedBox(height: 6),
        FormField<TimeOfDay>(
          initialValue: valor,
          validator: obligatorio
              ? (v) => v == null ? 'Selecciona la hora.' : null
              : null,
          builder: (estado) {
            final actual = estado.value;
            return InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () async {
                final elegida = await showTimePicker(
                  context: context,
                  initialTime: actual ?? TimeOfDay.now(),
                  helpText: etiqueta,
                );
                if (elegida == null) return;
                estado.didChange(elegida);
                alCambiar(elegida);
              },
              child: InputDecorator(
                isEmpty: actual == null,
                decoration: decoracionCampo(
                  context,
                  hint: 'Seleccionar hora',
                  icono: Icons.schedule,
                ).copyWith(errorText: estado.errorText),
                child: Text(
                  actual == null ? '' : actual.format(context),
                  style: AppTheme.manrope(size: 14, color: c.textoTitulo),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class OpcionSelector<T> {
  const OpcionSelector({
    required this.valor,
    required this.texto,
    this.detalle,
    this.habilitada = true,
  });

  final T valor;
  final String texto;
  final String? detalle;
  final bool habilitada;
}

class CampoSelector<T> extends StatelessWidget {
  const CampoSelector({
    super.key,
    required this.etiqueta,
    required this.valor,
    required this.opciones,
    required this.alCambiar,
    required this.icono,
    this.hint = 'Seleccionar',
    this.validador,
    this.obligatorio = false,
    this.habilitado = true,
  });

  final String etiqueta;
  final T? valor;
  final List<OpcionSelector<T>> opciones;
  final ValueChanged<T?> alCambiar;
  final IconData icono;
  final String hint;
  final String? Function(T? valor)? validador;
  final bool obligatorio;
  final bool habilitado;

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    final existe = opciones.any((o) => o.valor == valor);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EtiquetaCampo(etiqueta, obligatorio: obligatorio),
        const SizedBox(height: 6),
        DropdownButtonFormField<T>(
          key: ValueKey<Object?>(existe ? valor : null),
          initialValue: existe ? valor : null,
          isExpanded: true,
          itemHeight: null,
          validator: validador,
          onChanged: habilitado ? alCambiar : null,
          borderRadius: BorderRadius.circular(12),
          dropdownColor: c.superficie,
          icon: Icon(Icons.expand_more, color: c.textoSecundario),
          style: AppTheme.manrope(size: 14, color: c.textoTitulo),
          decoration: decoracionCampo(context, hint: hint, icono: icono),
          selectedItemBuilder: (context) => [
            for (final opcion in opciones)
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  opcion.texto,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.manrope(size: 14, color: c.textoTitulo),
                ),
              ),
          ],
          items: [
            for (final opcion in opciones)
              DropdownMenuItem<T>(
                value: opcion.valor,
                enabled: opcion.habilitada,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        opcion.texto,
                        style: AppTheme.manrope(
                          size: 14,
                          weight: FontWeight.w500,
                          color: opcion.habilitada ? c.textoTitulo : c.hint,
                        ),
                      ),
                      if (opcion.detalle != null)
                        Text(
                          opcion.detalle!,
                          style: AppTheme.manrope(
                            size: 11.5,
                            weight: opcion.habilitada
                                ? FontWeight.w400
                                : FontWeight.w600,
                            color: opcion.habilitada
                                ? c.textoSutil
                                : AppColors.rojoAlerta,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class InterruptorCampo extends StatelessWidget {
  const InterruptorCampo({
    super.key,
    required this.titulo,
    required this.descripcion,
    required this.valor,
    required this.alCambiar,
  });

  final String titulo;
  final String descripcion;
  final bool valor;
  final ValueChanged<bool>? alCambiar;

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
      decoration: BoxDecoration(
        color: c.superficie,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.borde),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: AppTheme.manrope(
                    size: 14,
                    weight: FontWeight.w600,
                    color: c.textoTitulo,
                  ),
                ),
                Text(
                  descripcion,
                  style: AppTheme.manrope(size: 12, color: c.textoSutil),
                ),
              ],
            ),
          ),
          Switch(
            value: valor,
            onChanged: alCambiar,
            activeThumbColor: Colors.white,
            activeTrackColor: c.verde,
          ),
        ],
      ),
    );
  }
}

/// Validaciones de la hoja de requerimientos de Lumina.
abstract final class Validar {
  static String? requerido(String valor, [String campo = 'este campo']) =>
      valor.trim().isEmpty ? 'Completa $campo.' : null;

  static String? maximo(String valor, int max, [String campo = 'este campo']) {
    final error = requerido(valor, campo);
    if (error != null) return error;
    return valor.trim().length > max ? 'Máximo $max caracteres.' : null;
  }

  /// Correo opcional: solo se valida si se diligencia.
  static String? correoOpcional(String valor) {
    final v = valor.trim();
    if (v.isEmpty) return null;
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v)) {
      return 'Ingresa un correo válido, ej. nombre@correo.com';
    }
    return null;
  }

  static String? celular(String valor, {bool obligatorio = false}) {
    final v = valor.trim();
    if (v.isEmpty) return obligatorio ? 'Ingresa el celular.' : null;
    if (!RegExp(r'^3\d{9}$').hasMatch(v)) {
      return 'Debe tener 10 dígitos e iniciar por 3.';
    }
    return null;
  }

  static String? documento(String valor) {
    final v = valor.trim();
    if (v.isEmpty) return 'Ingresa el documento.';
    if (!RegExp(r'^\d{5,15}$').hasMatch(v)) {
      return 'Usa entre 5 y 15 dígitos, sin puntos.';
    }
    return null;
  }

  static String? entero(String valor, String campo, {bool permiteCero = false}) {
    final v = valor.replaceAll('.', '').trim();
    if (v.isEmpty) return 'Ingresa $campo.';
    final n = int.tryParse(v);
    if (n == null) return '$campo debe ser un número entero.';
    if (permiteCero ? n < 0 : n <= 0) {
      return permiteCero ? 'No puede ser negativo.' : 'Debe ser mayor que 0.';
    }
    return null;
  }

  static String? porcentaje(String valor) {
    final n = double.tryParse(valor.replaceAll(',', '.').trim());
    if (valor.trim().isEmpty) return 'Ingresa la comisión.';
    if (n == null || n < 0 || n > 100) return 'La comisión debe estar entre 0 y 100.';
    return null;
  }

  static String? fecha(DateTime? valor, [String campo = 'la fecha']) =>
      valor == null ? 'Selecciona $campo.' : null;

  static String? seleccion(Object? valor, [String campo = 'una opción']) =>
      valor == null ? 'Selecciona $campo.' : null;
}

abstract final class Formateadores {
  static final soloDigitos = FilteringTextInputFormatter.digitsOnly;

  static final mayusculas = TextInputFormatter.withFunction(
    (anterior, nuevo) => nuevo.copyWith(text: nuevo.text.toUpperCase()),
  );

  static final miles = TextInputFormatter.withFunction((anterior, nuevo) {
    final digitos = nuevo.text.replaceAll(RegExp(r'\D'), '');
    if (digitos.isEmpty) return nuevo.copyWith(text: '');
    final buffer = StringBuffer();
    for (var i = 0; i < digitos.length; i++) {
      if (i > 0 && (digitos.length - i) % 3 == 0) buffer.write('.');
      buffer.write(digitos[i]);
    }
    final texto = buffer.toString();
    return TextEditingValue(
      text: texto,
      selection: TextSelection.collapsed(offset: texto.length),
    );
  });

  static double valorMiles(String texto) =>
      double.tryParse(texto.replaceAll('.', '')) ?? 0;
}
