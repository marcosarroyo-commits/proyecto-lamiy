import 'package:flutter/material.dart';
import 'package:lumina_app/domain/fechas.dart';
import 'package:lumina_app/models/liquidacion/liquidacion.dart';
import 'package:lumina_app/routes/app_routes.dart';
import 'package:lumina_app/screens/cierres/resumen_cierre_screen.dart';
import 'package:lumina_app/theme/colores_app.dart';
import 'package:lumina_app/widgets/barra_acciones.dart';
import 'package:lumina_app/widgets/campos_formulario.dart';
import 'package:lumina_app/widgets/chip_estado.dart';
import 'package:lumina_app/widgets/encabezado_modulo.dart';
import 'package:lumina_app/widgets/filtros.dart';
import 'package:lumina_app/widgets/marco_pantalla.dart';
import 'package:lumina_app/widgets/mensaje_error.dart';
import 'package:lumina_app/widgets/seccion_detalle.dart';


class FormularioCierreScreen extends StatefulWidget {
  const FormularioCierreScreen({super.key, this.ultimo});

  final Liquidacion? ultimo;

  @override
  State<FormularioCierreScreen> createState() => _FormularioCierreScreenState();
}

class _FormularioCierreScreenState extends State<FormularioCierreScreen> {
  late DateTime? _inicio = widget.ultimo?.fechaFin?.add(const Duration(days: 1));
  DateTime? _fin;
  String? _error;

  
  String? _validar() {
    if (_inicio == null || _fin == null) return 'Selecciona la fecha inicial y la final.';
    if (_fin!.isBefore(_inicio!)) return 'La fecha final debe ser igual o posterior a la inicial.';
    final ultimoFin = widget.ultimo?.fechaFin;
    if (ultimoFin != null && !_inicio!.isAfter(Fechas.soloFecha(ultimoFin))) {
      return 'El periodo se cruza con el último cierre (terminó el ${Fechas.corta(ultimoFin)}).';
    }
    return null;
  }

  Future<void> _continuar() async {
    final error = _validar();
    setState(() => _error = error);
    if (error != null) return;
    final creado = await abrir<bool>(context, ResumenCierreScreen(inicio: _inicio!, fin: _fin!));
    if (creado == true && mounted) Navigator.pop(context, true);
  }

  void _atajo(DateTime inicio, DateTime fin) {
    final hoy = Fechas.hoy;
    setState(() {
      _inicio = inicio;
      _fin = fin.isAfter(hoy) ? hoy : fin;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    final hoy = Fechas.hoy;
    return Scaffold(
      backgroundColor: c.fondo,
      appBar: const EncabezadoModulo(titulo: 'Nuevo cierre', subtitulo: 'Define el periodo a consolidar'),
      body: ContenidoCentrado(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            if (_error != null) ...[MensajeError(_error!), const SizedBox(height: 16)],
            if (widget.ultimo != null) ...[
              Aviso(
                titulo: 'Último cierre',
                mensaje: 'Cubrió del ${Fechas.corta(widget.ultimo!.fechaInicio)} al '
                    '${Fechas.corta(widget.ultimo!.fechaFin)}. Sugerimos iniciar el día siguiente.',
                tono: TonoEstado.info,
              ),
              const SizedBox(height: 16),
            ],
            CampoFecha(
              etiqueta: 'Fecha inicial',
              valor: _inicio,
              primera: DateTime(hoy.year - 2),
              ultima: hoy,
              obligatorio: true,
              alCambiar: (f) => setState(() => _inicio = f),
            ),
            const SizedBox(height: 16),
            CampoFecha(
              etiqueta: 'Fecha final',
              valor: _fin,
              primera: _inicio ?? DateTime(hoy.year - 2),
              ultima: hoy,
              obligatorio: true,
              alCambiar: (f) => setState(() => _fin = f),
            ),
            const SizedBox(height: 16),
            const EtiquetaCampo('Atajos'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                PildoraFiltro(
                  texto: '1.ª quincena',
                  activa: false,
                  icono: Icons.looks_one_outlined,
                  alTocar: () => _atajo(DateTime(hoy.year, hoy.month, 1), DateTime(hoy.year, hoy.month, 15)),
                ),
                PildoraFiltro(
                  texto: '2.ª quincena',
                  activa: false,
                  icono: Icons.looks_two_outlined,
                  alTocar: () => _atajo(DateTime(hoy.year, hoy.month, 16), DateTime(hoy.year, hoy.month + 1, 0)),
                ),
                PildoraFiltro(
                  texto: 'Mes anterior',
                  activa: false,
                  icono: Icons.history,
                  alTocar: () => _atajo(DateTime(hoy.year, hoy.month - 1, 1), DateTime(hoy.year, hoy.month, 0)),
                ),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: BarraAcciones(textoPrincipal: 'Ver resumen del periodo', alPrincipal: _continuar),
    );
  }
}
