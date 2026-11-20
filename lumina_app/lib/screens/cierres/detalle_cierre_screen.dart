import 'package:flutter/material.dart';
import 'package:lumina_app/domain/app_theme.dart';
import 'package:lumina_app/domain/fechas.dart';
import 'package:lumina_app/domain/formatos.dart';
import 'package:lumina_app/models/comision/comision.dart';
import 'package:lumina_app/models/liquidacion/liquidacion.dart';
import 'package:lumina_app/routes/app_routes.dart';
import 'package:lumina_app/screens/comisiones/detalle_comision_screen.dart';
import 'package:lumina_app/screens/comisiones/listado_comisiones_screen.dart';
import 'package:lumina_app/services/remote/api_service.dart';
import 'package:lumina_app/services/remote/comision_service.dart';
import 'package:lumina_app/theme/colores_app.dart';
import 'package:lumina_app/widgets/boton_principal.dart';
import 'package:lumina_app/widgets/chip_estado.dart';
import 'package:lumina_app/widgets/encabezado_modulo.dart';
import 'package:lumina_app/widgets/estados_vista.dart';
import 'package:lumina_app/widgets/marco_pantalla.dart';
import 'package:lumina_app/widgets/seccion_detalle.dart';
import 'package:lumina_app/widgets/tarjeta_base.dart';

/// Detalle de un cierre generado + consolidado (GET /api/comisiones?cierreId=…).
class DetalleCierreScreen extends StatefulWidget {
  const DetalleCierreScreen({super.key, required this.cierre});

  final Liquidacion cierre;

  @override
  State<DetalleCierreScreen> createState() => _DetalleCierreScreenState();
}

class _DetalleCierreScreenState extends State<DetalleCierreScreen> {
  List<Comision>? _comisiones;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _error = null);
    try {
      final lista = await ComisionService().listar(cierreId: widget.cierre.id);
      if (mounted) setState(() => _comisiones = lista);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    final l = widget.cierre;
    final cs = _comisiones ?? const <Comision>[];
    final total = l.total ?? cs.fold<double>(0, (a, x) => a + (x.base ?? 0));
    final comisiones = l.totalComisiones ?? cs.fold<double>(0, (a, x) => a + (x.valor ?? 0));
    final servicios = l.cantidadServicios ?? cs.fold<int>(0, (a, x) => a + (x.cantidadServicios ?? 0));

    return Scaffold(
      backgroundColor: c.fondo,
      appBar: EncabezadoModulo(titulo: 'Detalle del cierre', subtitulo: l.codigo),
      body: ContenidoCentrado(
        child: RefreshIndicator(
          onRefresh: _cargar,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              SeccionDetalle(
                titulo: 'Periodo',
                icono: Icons.date_range_outlined,
                etiqueta: const ChipEstado(texto: 'Cerrado', tono: TonoEstado.exito, icono: Icons.lock_outline),
                children: [
                  FilaDato(
                    icono: Icons.event_outlined,
                    etiqueta: 'Desde – hasta',
                    valor: '${Fechas.corta(l.fechaInicio)} – ${Fechas.corta(l.fechaFin)}',
                  ),
                  if (l.fechaCreacion != null)
                    FilaDato(icono: Icons.history, etiqueta: 'Generado', valor: Fechas.fechaHora(l.fechaCreacion)),
                  GrillaDatos(datos: [
                    FilaDato(etiqueta: 'Total', valor: Formato.moneda(total), destacado: true),
                    FilaDato(etiqueta: 'Servicios', valor: '$servicios', destacado: true),
                    FilaDato(etiqueta: 'Comisiones', valor: Formato.moneda(comisiones)),
                    FilaDato(etiqueta: 'Para el centro', valor: Formato.moneda(total - comisiones)),
                  ]),
                ],
              ),
              const SizedBox(height: 20),
              Text('Profesionales (${l.cantidadProfesionales ?? cs.length})',
                  style: AppTheme.cormorant(size: 17, color: c.primarioOscuro)),
              const SizedBox(height: 8),
              if (_error != null)
                EstadoError(mensaje: _error!, alReintentar: _cargar)
              else if (_comisiones == null)
                const SizedBox(height: 120, child: EstadoCarga(mensaje: 'Consultando comisiones...'))
              else if (cs.isEmpty)
                const EstadoVacio(
                  icono: Icons.percent,
                  titulo: 'Sin comisiones',
                  mensaje: 'Este cierre no tiene comisiones registradas.',
                )
              else
                for (final comision in cs)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: TarjetaComision(
                      comision: comision,
                      alTocar: () => abrir(context, DetalleComisionScreen(comision: comision, cierre: l)),
                    ),
                  ),
              const SizedBox(height: 8),
              BotonPrincipal(
                texto: 'Consultar comisiones',
                alPresionar: () => abrir(context, ListadoComisionesScreen(cierreInicial: l)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tarjeta reutilizada en el detalle del cierre y en Comisiones.
class TarjetaComision extends StatelessWidget {
  const TarjetaComision({super.key, required this.comision, required this.alTocar});

  final Comision comision;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    final nombre = comision.profesionalNombre ?? 'Profesional ${comision.profesionalId ?? ''}';
    return TarjetaBase(
      alTocar: alTocar,
      child: Row(
        children: [
          AvatarIniciales(texto: Formato.iniciales(nombre), tamano: 42),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(nombre, style: AppTheme.cormorant(size: 15.5, color: c.textoOscuro)),
                Text(
                  '${comision.cantidadServicios ?? '—'} servicio(s) · Base ${comision.base == null ? '—' : Formato.moneda(comision.base)}',
                  style: AppTheme.manrope(size: 12, color: c.textoSutil),
                ),
                const SizedBox(height: 4),
                ChipEstado(texto: '${Formato.porcentaje(comision.porcentaje)} comisión', tono: TonoEstado.info),
              ],
            ),
          ),
          Text(comision.valor == null ? '—' : Formato.moneda(comision.valor),
              style: AppTheme.cormorant(size: 17, color: c.primarioOscuro)),
        ],
      ),
    );
  }
}
