import 'package:flutter/material.dart';
import 'package:lumina_app/domain/app_theme.dart';
import 'package:lumina_app/domain/filtros_agenda.dart';
import 'package:lumina_app/models/profesional/profesional.dart';
import 'package:lumina_app/models/servicio/servicio.dart';
import 'package:lumina_app/theme/colores_app.dart';
import 'package:lumina_app/widgets/boton_principal.dart';
import 'package:lumina_app/widgets/campos_formulario.dart';
import 'package:lumina_app/widgets/filtros.dart';

Future<FiltrosAgenda?> mostrarFiltrosAgenda(
  BuildContext context, {
  required FiltrosAgenda actuales,
  required List<Servicio> servicios,
  required List<Profesional> profesionales,
  bool mostrarProfesional = true,
}) {
  return showModalBottomSheet<FiltrosAgenda>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _FiltrosAgendaSheet(
      actuales: actuales,
      servicios: servicios,
      profesionales: profesionales,
      mostrarProfesional: mostrarProfesional,
    ),
  );
}

class _FiltrosAgendaSheet extends StatefulWidget {
  const _FiltrosAgendaSheet({
    required this.actuales,
    required this.servicios,
    required this.profesionales,
    required this.mostrarProfesional,
  });

  final FiltrosAgenda actuales;
  final List<Servicio> servicios;
  final List<Profesional> profesionales;
  final bool mostrarProfesional;

  @override
  State<_FiltrosAgendaSheet> createState() => _FiltrosAgendaSheetState();
}

class _FiltrosAgendaSheetState extends State<_FiltrosAgendaSheet> {
  late final TextEditingController _cliente = TextEditingController(text: widget.actuales.cliente);
  late int? _servicioId = widget.actuales.servicioId;
  late int? _profesionalId = widget.actuales.profesionalId;
  late FiltroEstado _estado = widget.actuales.estado;

  @override
  void dispose() {
    _cliente.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(child: Text('Filtrar agenda', style: AppTheme.cormorant(size: 20, color: c.primarioOscuro))),
                  TextButton(
                    onPressed: () => setState(() {
                      _cliente.clear();
                      _servicioId = null;
                      _profesionalId = null;
                      _estado = FiltroEstado.activas;
                    }),
                    child: const Text('Limpiar'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              CampoTexto(
                etiqueta: 'Cliente',
                controlador: _cliente,
                icono: Icons.person_search_outlined,
                hint: 'Nombre o documento',
              ),
              const SizedBox(height: 16),
              CampoSelector<int?>(
                etiqueta: 'Servicio',
                valor: _servicioId,
                icono: Icons.content_cut_outlined,
                alCambiar: (v) => setState(() => _servicioId = v),
                opciones: [
                  const OpcionSelector(valor: null, texto: 'Todos'),
                  for (final s in widget.servicios) OpcionSelector(valor: s.id, texto: s.nombre),
                ],
              ),
              if (widget.mostrarProfesional) ...[
                const SizedBox(height: 16),
                CampoSelector<int?>(
                  etiqueta: 'Profesional',
                  valor: _profesionalId,
                  icono: Icons.face_retouching_natural,
                  alCambiar: (v) => setState(() => _profesionalId = v),
                  opciones: [
                    const OpcionSelector(valor: null, texto: 'Todos'),
                    for (final p in widget.profesionales) OpcionSelector(valor: p.id, texto: p.nombreCompleto),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              const EtiquetaCampo('Estado'),
              const SizedBox(height: 6),
              BarraFiltros<FiltroEstado>(
                seleccionado: _estado,
                alCambiar: (e) => setState(() => _estado = e),
                opciones: [for (final e in FiltroEstado.values) OpcionFiltro(e, e.texto)],
              ),
              const SizedBox(height: 22),
              BotonPrincipal(
                texto: 'Aplicar filtros',
                alPresionar: () => Navigator.pop(
                  context,
                  FiltrosAgenda(
                    cliente: _cliente.text,
                    servicioId: _servicioId,
                    profesionalId: _profesionalId,
                    estado: _estado,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
