import 'package:flutter/material.dart';
import 'package:lumina_app/domain/app_theme.dart';
import 'package:lumina_app/domain/fechas.dart';
import 'package:lumina_app/domain/formatos.dart';
import 'package:lumina_app/models/comun/pagina.dart';
import 'package:lumina_app/models/liquidacion/liquidacion.dart';
import 'package:lumina_app/routes/app_routes.dart';
import 'package:lumina_app/screens/cierres/detalle_cierre_screen.dart';
import 'package:lumina_app/screens/cierres/formulario_cierre_screen.dart';
import 'package:lumina_app/services/remote/liquidacion_service.dart';
import 'package:lumina_app/theme/colores_app.dart';
import 'package:lumina_app/widgets/chip_estado.dart';
import 'package:lumina_app/widgets/encabezado_modulo.dart';
import 'package:lumina_app/widgets/estados_vista.dart';
import 'package:lumina_app/widgets/filtros.dart';
import 'package:lumina_app/widgets/selector_opciones.dart';
import 'package:lumina_app/widgets/tarjeta_base.dart';
import 'package:lumina_app/widgets/vista_paginada.dart';


class ListadoCierresScreen extends StatefulWidget {
  const ListadoCierresScreen({super.key});

  @override
  State<ListadoCierresScreen> createState() => _ListadoCierresScreenState();
}

class _ListadoCierresScreenState extends State<ListadoCierresScreen> {
  final LiquidacionService _servicio = LiquidacionService();
  late final ControladorPaginado<Liquidacion> _controlador = ControladorPaginado(_cargar);
  int _anio = 0;
  int _mes = 0;
  Liquidacion? _ultimo;

  @override
  void initState() {
    super.initState();
    _controlador.recargar();
    _cargarUltimo();
  }

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  Future<Pagina<Liquidacion>> _cargar(int pagina) => _servicio.listar(anio: _anio, mes: _mes);

  Future<void> _cargarUltimo() async {
    try {
      final ultimo = await _servicio.ultima();
      if (mounted) setState(() => _ultimo = ultimo);
    } catch (_) {}
  }

  Future<void> _nuevo() async {
    final creado = await abrir<bool>(context, FormularioCierreScreen(ultimo: _ultimo));
    if (creado == true && mounted) {
      _controlador.recargar();
      _cargarUltimo();
    }
  }

  Future<void> _elegirAnio() async {
    final actual = DateTime.now().year;
    final opcion = await elegirOpcion<int>(
      context,
      titulo: 'Filtrar por año',
      seleccionado: _anio,
      opciones: [
        const OpcionFiltro(0, 'Todos los años'),
        for (var a = actual; a >= actual - 3; a--) OpcionFiltro(a, '$a'),
      ],
    );
    if (opcion == null) return;
    setState(() => _anio = opcion.valor);
    _controlador.recargar();
  }

  Future<void> _elegirMes() async {
    final opcion = await elegirOpcion<int>(
      context,
      titulo: 'Filtrar por mes',
      seleccionado: _mes,
      opciones: [
        const OpcionFiltro(0, 'Todos los meses'),
        for (var m = 1; m <= 12; m++) OpcionFiltro(m, Fechas.meses[m - 1]),
      ],
    );
    if (opcion == null) return;
    setState(() => _mes = opcion.valor);
    _controlador.recargar();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    return Scaffold(
      backgroundColor: c.fondo,
      appBar: EncabezadoModulo(
        titulo: 'Cierres',
        subtitulo: 'Periodos consolidados para comisiones',
        acciones: [AccionEncabezado(icono: Icons.add_chart, tooltip: 'Nuevo cierre', alPresionar: _nuevo)],
      ),
      body: PantallaLista(
        filtros: Row(
          children: [
            PildoraFiltro(
              texto: _anio == 0 ? 'Año' : '$_anio',
              activa: _anio != 0,
              icono: Icons.calendar_today_outlined,
              alTocar: _elegirAnio,
              alQuitar: _anio == 0
                  ? null
                  : () {
                      setState(() => _anio = 0);
                      _controlador.recargar();
                    },
            ),
            const SizedBox(width: 8),
            PildoraFiltro(
              texto: _mes == 0 ? 'Mes' : Fechas.meses[_mes - 1],
              activa: _mes != 0,
              icono: Icons.date_range_outlined,
              alTocar: _elegirMes,
              alQuitar: _mes == 0
                  ? null
                  : () {
                      setState(() => _mes = 0);
                      _controlador.recargar();
                    },
            ),
          ],
        ),
        lista: VistaPaginada<Liquidacion>(
          controlador: _controlador,
          cabecera: _ultimo == null ? null : _TarjetaUltimo(cierre: _ultimo!),
          constructor: (context, l) => _TarjetaCierre(
            cierre: l,
            alTocar: () => abrir(context, DetalleCierreScreen(cierre: l)),
          ),
          vacio: EstadoVacio(
            icono: Icons.receipt_long_outlined,
            titulo: _anio == 0 && _mes == 0 ? 'Aún no hay cierres' : 'Sin cierres en ese periodo',
            mensaje: _anio == 0 && _mes == 0
                ? 'Crea el primer cierre para consolidar servicios y calcular comisiones.'
                : 'Cambia el año o el mes del filtro.',
            textoAccion: 'Nuevo cierre',
            alAccion: _nuevo,
          ),
        ),
      ),
    );
  }
}

class _TarjetaUltimo extends StatelessWidget {
  const _TarjetaUltimo({required this.cierre});

  final Liquidacion cierre;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primario, AppColors.primarioOscuro],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.auto_awesome, color: AppColors.doradoSuave, size: 18),
            const SizedBox(width: 6),
            Text('ÚLTIMO CIERRE',
                style: AppTheme.manrope(size: 11, weight: FontWeight.w700, color: Colors.white70)
                    .copyWith(letterSpacing: 1.4)),
          ]),
          const SizedBox(height: 6),
          Text('${Fechas.corta(cierre.fechaInicio)} – ${Fechas.corta(cierre.fechaFin)}',
              style: AppTheme.cormorant(size: 20, color: Colors.white)),
          if (cierre.total != null)
            Text(Formato.moneda(cierre.total), style: AppTheme.cormorant(size: 24, color: Colors.white)),
        ],
      ),
    );
  }
}

class _TarjetaCierre extends StatelessWidget {
  const _TarjetaCierre({required this.cierre, required this.alTocar});

  final Liquidacion cierre;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    Widget dato(String etiqueta, String valor) => Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(etiqueta, style: AppTheme.manrope(size: 11, color: c.textoSutil)),
          Text(valor, style: AppTheme.manrope(size: 13.5, weight: FontWeight.w800, color: c.textoOscuro)),
        ],
      ),
    );
    return TarjetaBase(
      alTocar: alTocar,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const IconoCaja(icono: Icons.receipt_long_outlined),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(cierre.codigo, style: AppTheme.cormorant(size: 15.5, color: c.textoOscuro)),
                    Text('Desde ${Fechas.corta(cierre.fechaInicio)} hasta ${Fechas.corta(cierre.fechaFin)}',
                        style: AppTheme.manrope(size: 12, color: c.textoSutil)),
                  ],
                ),
              ),
              const ChipEstado(texto: 'Cerrado', tono: TonoEstado.exito, icono: Icons.lock_outline),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              dato('Total', cierre.total == null ? '—' : Formato.moneda(cierre.total)),
              dato('Servicios', '${cierre.cantidadServicios ?? '—'}'),
              dato('Profesionales', '${cierre.cantidadProfesionales ?? '—'}'),
            ],
          ),
        ],
      ),
    );
  }
}
