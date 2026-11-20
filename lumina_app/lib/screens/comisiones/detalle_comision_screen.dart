import 'package:flutter/material.dart';
import 'package:lumina_app/domain/app_theme.dart';
import 'package:lumina_app/domain/fechas.dart';
import 'package:lumina_app/domain/formatos.dart';
import 'package:lumina_app/models/comision/comision.dart';
import 'package:lumina_app/models/liquidacion/liquidacion.dart';
import 'package:lumina_app/services/remote/api_service.dart';
import 'package:lumina_app/services/remote/comision_service.dart';
import 'package:lumina_app/theme/colores_app.dart';
import 'package:lumina_app/widgets/encabezado_modulo.dart';
import 'package:lumina_app/widgets/estados_vista.dart';
import 'package:lumina_app/widgets/marco_pantalla.dart';
import 'package:lumina_app/widgets/seccion_detalle.dart';
import 'package:lumina_app/widgets/tarjeta_base.dart';

/// Servicios que componen una comisión (GET /api/comisiones/{id}/servicios).
class DetalleComisionScreen extends StatefulWidget {
  const DetalleComisionScreen({super.key, required this.comision, this.cierre});

  final Comision comision;
  final Liquidacion? cierre;

  @override
  State<DetalleComisionScreen> createState() => _DetalleComisionScreenState();
}

class _DetalleComisionScreenState extends State<DetalleComisionScreen> {
  List<ServicioComisionado>? _servicios;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _error = null);
    try {
      final lista = await ComisionService().servicios(widget.comision.id);
      if (mounted) setState(() => _servicios = lista);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    final x = widget.comision;
    final nombre = x.profesionalNombre ?? 'Profesional';
    final periodo = widget.cierre != null
        ? '${Fechas.corta(widget.cierre!.fechaInicio)} – ${Fechas.corta(widget.cierre!.fechaFin)}'
        : (x.fechaInicio != null
            ? '${Fechas.corta(x.fechaInicio)} – ${Fechas.corta(x.fechaFin)}'
            : 'Cierre N.° ${x.cierreId ?? '—'}');
    final servicios = _servicios ?? const <ServicioComisionado>[];

    return Scaffold(
      backgroundColor: c.fondo,
      appBar: EncabezadoModulo(titulo: 'Detalle de comisión', subtitulo: '$nombre · $periodo'),
      body: ContenidoCentrado(
        child: RefreshIndicator(
          onRefresh: _cargar,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              SeccionDetalle(
                titulo: nombre,
                icono: Icons.face_retouching_natural,
                children: [
                  GrillaDatos(datos: [
                    FilaDato(etiqueta: 'Servicios', valor: '${x.cantidadServicios ?? servicios.length}'),
                    FilaDato(etiqueta: '% comisión', valor: Formato.porcentaje(x.porcentaje)),
                    FilaDato(etiqueta: 'Base', valor: x.base == null ? '—' : Formato.moneda(x.base)),
                    FilaDato(
                      etiqueta: 'Comisionado',
                      valor: x.valor == null ? '—' : Formato.moneda(x.valor),
                      destacado: true,
                    ),
                  ]),
                ],
              ),
              const SizedBox(height: 18),
              Text('Servicios realizados', style: AppTheme.cormorant(size: 17, color: c.primarioOscuro)),
              const SizedBox(height: 8),
              if (_error != null)
                EstadoError(mensaje: _error!, alReintentar: _cargar)
              else if (_servicios == null)
                const SizedBox(height: 120, child: EstadoCarga(mensaje: 'Consultando servicios...'))
              else if (servicios.isEmpty)
                const EstadoVacio(
                  icono: Icons.content_cut_outlined,
                  titulo: 'Sin servicios',
                  mensaje: 'No hay servicios asociados a esta comisión.',
                )
              else
                for (final s in servicios)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: TarjetaBase(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          const IconoCaja(icono: Icons.content_cut_outlined, tamano: 38),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(s.servicio,
                                    style: AppTheme.manrope(size: 14, weight: FontWeight.w700, color: c.textoOscuro)),
                                Text(
                                  [if (s.fecha != null) Fechas.corta(s.fecha), if (s.cliente != null) s.cliente!]
                                      .join(' · '),
                                  style: AppTheme.manrope(size: 12, color: c.textoSutil),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(s.valor == null ? '—' : Formato.moneda(s.valor),
                                  style: AppTheme.manrope(size: 13, weight: FontWeight.w700, color: c.textoOscuro)),
                              if (s.comision != null || (s.valor != null && x.porcentaje != null))
                                Text(
                                  '+ ${Formato.moneda(s.comision ?? s.valor! * x.porcentaje! / 100)}',
                                  style: AppTheme.manrope(size: 12, weight: FontWeight.w700, color: c.verdeOscuro),
                                ),
                            ],
                          ),
                        ],
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
