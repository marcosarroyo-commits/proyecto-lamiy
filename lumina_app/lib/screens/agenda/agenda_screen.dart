import 'package:flutter/material.dart';
import 'package:lumina_app/domain/app_theme.dart';
import 'package:lumina_app/domain/fechas.dart';
import 'package:lumina_app/domain/filtros_agenda.dart';
import 'package:lumina_app/models/agenda/horario_disponible.dart';
import 'package:lumina_app/models/profesional/profesional.dart';
import 'package:lumina_app/models/reserva/reserva.dart';
import 'package:lumina_app/models/servicio/servicio.dart';
import 'package:lumina_app/routes/app_routes.dart';
import 'package:lumina_app/screens/agenda/filtros_agenda_sheet.dart';
import 'package:lumina_app/screens/reservas/detalle_reserva_screen.dart';
import 'package:lumina_app/screens/reservas/formulario_reserva_screen.dart';
import 'package:lumina_app/services/local/catalogo_cache.dart';
import 'package:lumina_app/services/local/gestor_sesion.dart';
import 'package:lumina_app/services/remote/agenda_service.dart';
import 'package:lumina_app/services/remote/api_service.dart';
import 'package:lumina_app/services/remote/profesional_service.dart';
import 'package:lumina_app/services/remote/reserva_service.dart';
import 'package:lumina_app/theme/colores_app.dart';
import 'package:lumina_app/widgets/chip_estado.dart';
import 'package:lumina_app/widgets/encabezado_modulo.dart';
import 'package:lumina_app/widgets/estados_vista.dart';
import 'package:lumina_app/widgets/filtros.dart';
import 'package:lumina_app/widgets/marco_pantalla.dart';
import 'package:lumina_app/widgets/tarjeta_base.dart';
import 'package:lumina_app/widgets/tarjeta_reserva.dart';

enum _Vista { lista, calendario }

/// Agenda: vista lista por rango de fechas y calendario mensual compacto.
/// Con [soloLectura] (rol profesional) muestra solo sus propias reservas.
class AgendaScreen extends StatefulWidget {
  const AgendaScreen({super.key, this.soloLectura = false});

  final bool soloLectura;

  @override
  State<AgendaScreen> createState() => _AgendaScreenState();
}

class _AgendaScreenState extends State<AgendaScreen> {
  final ReservaService _servicio = ReservaService();

  _Vista _vista = _Vista.lista;
  DateTime _desde = Fechas.hoy;
  DateTime _hasta = Fechas.hoy.add(const Duration(days: 6));
  DateTime _mes = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime _dia = Fechas.hoy;
  FiltrosAgenda _filtros = const FiltrosAgenda();

  List<Reserva> _reservas = const [];
  List<Servicio> _servicios = const [];
  List<Profesional> _profesionales = const [];
  int? _miProfesionalId;
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _iniciar();
  }

  Future<void> _iniciar() async {
    if (widget.soloLectura) {
      try {
        _miProfesionalId =
            (await ProfesionalService().porDocumento(GestorSesion.actual?.username ?? ''))?.id;
      } catch (_) {}
    }
    try {
      _servicios = await CatalogoCache.servicios();
      _profesionales = await CatalogoCache.profesionales();
    } catch (_) {}
    await _cargar();
  }

  (DateTime, DateTime) get _rango => _vista == _Vista.lista
      ? (_desde, _hasta)
      : (DateTime(_mes.year, _mes.month, 1), DateTime(_mes.year, _mes.month + 1, 0));

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final (inicio, fin) = _rango;
      final reservas = await _servicio.entre(inicio, fin);
      if (mounted) setState(() => _reservas = reservas);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  List<Reserva> get _visibles =>
      _reservas.where((r) => _filtros.acepta(r, profesionalFijo: _miProfesionalId)).toList();

  Future<void> _abrirFiltros() async {
    final nuevos = await mostrarFiltrosAgenda(
      context,
      actuales: _filtros,
      servicios: _servicios,
      profesionales: _profesionales,
      mostrarProfesional: !widget.soloLectura,
    );
    if (nuevos != null) setState(() => _filtros = nuevos);
  }

  Future<void> _verReserva(Reserva r) async {
    await abrir(context, DetalleReservaScreen(reserva: r));
    if (mounted) _cargar();
  }

  Future<void> _nuevaReserva() async {
    await abrir(context, FormularioReservaScreen(fechaInicial: _vista == _Vista.calendario ? _dia : null));
    if (mounted) _cargar();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    return Scaffold(
      backgroundColor: c.fondo,
      appBar: EncabezadoModulo(
        titulo: widget.soloLectura ? 'Mi agenda' : 'Agenda',
        subtitulo: Fechas.fechaLarga(DateTime.now()),
        acciones: [
          AccionEncabezado(
            icono: Icons.tune,
            tooltip: _filtros.activos > 0 ? 'Filtros (${_filtros.activos})' : 'Filtros',
            alPresionar: _abrirFiltros,
          ),
          if (!widget.soloLectura)
            AccionEncabezado(icono: Icons.add, tooltip: 'Crear reserva', alPresionar: _nuevaReserva),
        ],
      ),
      body: ContenidoCentrado(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: BarraFiltros<_Vista>(
                seleccionado: _vista,
                alCambiar: (v) {
                  setState(() => _vista = v);
                  _cargar();
                },
                opciones: const [
                  OpcionFiltro(_Vista.lista, 'Lista'),
                  OpcionFiltro(_Vista.calendario, 'Calendario'),
                ],
                extra: [
                  if (_filtros.activos > 0)
                    PildoraFiltro(
                      texto: '${_filtros.activos} filtro(s)',
                      activa: true,
                      icono: Icons.filter_alt_outlined,
                      alTocar: _abrirFiltros,
                      alQuitar: () => setState(() => _filtros = const FiltrosAgenda()),
                    ),
                ],
              ),
            ),
            if (_vista == _Vista.lista)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Row(
                  children: [
                    FiltroFecha(
                      etiqueta: 'Desde',
                      valor: _desde,
                      alCambiar: (f) {
                        if (f == null) return;
                        setState(() {
                          _desde = Fechas.soloFecha(f);
                          if (_hasta.isBefore(_desde)) _hasta = _desde;
                        });
                        _cargar();
                      },
                    ),
                    const SizedBox(width: 8),
                    FiltroFecha(
                      etiqueta: 'Hasta',
                      valor: _hasta,
                      alCambiar: (f) {
                        if (f == null) return;
                        setState(() {
                          _hasta = Fechas.soloFecha(f);
                          if (_hasta.isBefore(_desde)) _desde = _hasta;
                        });
                        _cargar();
                      },
                    ),
                  ],
                ),
              ),
            Expanded(child: _cuerpo(c)),
          ],
        ),
      ),
    );
  }

  Widget _cuerpo(ColoresApp c) {
    if (_cargando && _reservas.isEmpty) return const EstadoCarga(mensaje: 'Consultando la agenda...');
    if (_error != null) return EstadoError(mensaje: _error!, alReintentar: _cargar);
    return _vista == _Vista.lista ? _lista(c) : _calendario(c);
  }

  Widget _lista(ColoresApp c) {
    final visibles = _visibles;
    final porDia = <DateTime, List<Reserva>>{};
    for (final r in visibles) {
      porDia.putIfAbsent(Fechas.soloFecha(r.fecha), () => []).add(r);
    }
    final dias = porDia.keys.toList()..sort();
    return RefreshIndicator(
      onRefresh: _cargar,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          Text('${visibles.length} cita(s) · ${_filtros.estado.texto}',
              style: AppTheme.manrope(size: 12, color: c.textoSutil)),
          if (visibles.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 32),
              child: EstadoVacio(
                icono: Icons.event_available_outlined,
                titulo: 'Sin reservas',
                mensaje: _filtros.activos > 0
                    ? 'Ninguna reserva coincide con los filtros aplicados.'
                    : 'No hay reservas en el rango seleccionado.',
                textoAccion: _filtros.activos > 0 ? 'Limpiar filtros' : (widget.soloLectura ? null : 'Crear reserva'),
                iconoAccion: _filtros.activos > 0 ? Icons.filter_alt_off_outlined : Icons.add,
                alAccion: _filtros.activos > 0
                    ? () => setState(() => _filtros = const FiltrosAgenda())
                    : (widget.soloLectura ? null : _nuevaReserva),
              ),
            ),
          for (final d in dias) ...[
            const SizedBox(height: 16),
            Text(
              Fechas.mismoDia(d, DateTime.now()) ? 'Hoy · ${Fechas.diaMes(d)}' : Fechas.fechaLarga(d),
              style: AppTheme.cormorant(size: 15, color: c.primarioOscuro),
            ),
            for (final r in porDia[d]!)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: TarjetaReserva(reserva: r, alTocar: () => _verReserva(r)),
              ),
          ],
        ],
      ),
    );
  }

  Widget _calendario(ColoresApp c) {
    final visibles = _visibles;
    final conteo = <int, int>{};
    for (final r in visibles) {
      if (r.fecha.year == _mes.year && r.fecha.month == _mes.month) {
        conteo[r.fecha.day] = (conteo[r.fecha.day] ?? 0) + 1;
      }
    }
    final delDia = visibles.where((r) => Fechas.mismoDia(r.fecha, _dia)).toList();
    return RefreshIndicator(
      onRefresh: _cargar,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          TarjetaBase(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
            child: _CalendarioMes(
              mes: _mes,
              seleccionado: _dia,
              conteo: conteo,
              alCambiarMes: (m) {
                setState(() {
                  _mes = m;
                  _dia = DateTime(m.year, m.month, 1);
                });
                _cargar();
              },
              alElegirDia: (d) => setState(() => _dia = d),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: Text('Reservas del ${Fechas.diaMes(_dia)}',
                    style: AppTheme.cormorant(size: 16, color: c.primarioOscuro)),
              ),
              Text('${delDia.length} cita(s)', style: AppTheme.manrope(size: 12, color: c.textoSutil)),
            ],
          ),
          if (delDia.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text('No hay reservas este día.', style: AppTheme.manrope(size: 13, color: c.textoSutil)),
            ),
          for (final r in delDia)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: TarjetaReserva(reserva: r, alTocar: () => _verReserva(r)),
            ),
          if (!widget.soloLectura) ...[
            const SizedBox(height: 16),
            _DisponibilidadDia(key: ValueKey(_dia), fecha: _dia),
          ],
        ],
      ),
    );
  }
}

class _CalendarioMes extends StatelessWidget {
  const _CalendarioMes({
    required this.mes,
    required this.seleccionado,
    required this.conteo,
    required this.alCambiarMes,
    required this.alElegirDia,
  });

  final DateTime mes;
  final DateTime seleccionado;
  final Map<int, int> conteo;
  final ValueChanged<DateTime> alCambiarMes;
  final ValueChanged<DateTime> alElegirDia;

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    final diasMes = DateTime(mes.year, mes.month + 1, 0).day;
    final desplazamiento = DateTime(mes.year, mes.month, 1).weekday - 1; // lunes primero
    final filas = ((desplazamiento + diasMes) / 7).ceil();
    const cabecera = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];

    Widget celda(int dia) {
      if (dia < 1 || dia > diasMes) return const SizedBox(height: 44);
      final fecha = DateTime(mes.year, mes.month, dia);
      final activo = Fechas.mismoDia(fecha, seleccionado);
      final hoy = Fechas.mismoDia(fecha, DateTime.now());
      final n = conteo[dia] ?? 0;
      return InkWell(
        onTap: () => alElegirDia(fecha),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 44,
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: activo ? AppColors.primario : (hoy ? c.badgeFondo : null),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('$dia',
                  style: AppTheme.manrope(
                      size: 14, weight: FontWeight.w700, color: activo ? Colors.white : c.textoOscuro)),
              const SizedBox(height: 2),
              Container(
                width: n == 0 ? 0 : (n > 3 ? 18 : 6.0 * n),
                height: 4,
                decoration: BoxDecoration(
                  color: activo ? Colors.white : AppColors.malva,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        Row(
          children: [
            IconButton(
              onPressed: () => alCambiarMes(DateTime(mes.year, mes.month - 1)),
              icon: Icon(Icons.chevron_left, color: c.primario),
            ),
            Expanded(
              child: Text(Fechas.mesAnio(mes),
                  textAlign: TextAlign.center, style: AppTheme.cormorant(size: 17, color: c.primarioOscuro)),
            ),
            IconButton(
              onPressed: () => alCambiarMes(DateTime(mes.year, mes.month + 1)),
              icon: Icon(Icons.chevron_right, color: c.primario),
            ),
          ],
        ),
        Row(
          children: [
            for (final d in cabecera)
              Expanded(
                child: Center(
                  child: Text(d, style: AppTheme.manrope(size: 11, weight: FontWeight.w700, color: c.textoSutil)),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        for (var f = 0; f < filas; f++)
          Row(
            children: [
              for (var col = 0; col < 7; col++) Expanded(child: celda(f * 7 + col - desplazamiento + 1)),
            ],
          ),
      ],
    );
  }
}

/// Disponibilidad del equipo en el día (GET /api/agenda/{fecha}).
class _DisponibilidadDia extends StatefulWidget {
  const _DisponibilidadDia({super.key, required this.fecha});

  final DateTime fecha;

  @override
  State<_DisponibilidadDia> createState() => _DisponibilidadDiaState();
}

class _DisponibilidadDiaState extends State<_DisponibilidadDia> {
  List<HorarioDisponible>? _horarios;
  String? _error;
  bool _abierto = false;

  Future<void> _cargar() async {
    setState(() {
      _error = null;
      _horarios = null;
    });
    try {
      final horarios = await AgendaService().delDia(widget.fecha);
      if (mounted) setState(() => _horarios = horarios);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    final porProfesional = <String, List<HorarioDisponible>>{};
    for (final h in _horarios ?? const <HorarioDisponible>[]) {
      porProfesional.putIfAbsent(h.profesionalNombre ?? 'Disponibles', () => []).add(h);
    }
    return TarjetaBase(
      padding: EdgeInsets.zero,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Icon(Icons.event_available_outlined, color: c.verde),
          title: Text('Horarios libres del día',
              style: AppTheme.manrope(size: 14, weight: FontWeight.w700, color: c.textoOscuro)),
          subtitle: Text('Disponibilidad del equipo', style: AppTheme.manrope(size: 12, color: c.textoSutil)),
          onExpansionChanged: (abierto) {
            _abierto = abierto;
            if (abierto && _horarios == null) _cargar();
          },
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            if (_abierto && _horarios == null && _error == null)
              const Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator()),
            if (_error != null) Text(_error!, style: AppTheme.manrope(size: 13, color: c.textoSutil)),
            if (_horarios != null && _horarios!.isEmpty)
              Text('Sin horarios libres para esta fecha.', style: AppTheme.manrope(size: 13, color: c.textoSutil)),
            for (final e in porProfesional.entries) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 6),
                  child: Text(e.key, style: AppTheme.manrope(size: 13, weight: FontWeight.w700, color: c.textoGris)),
                ),
              ),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [for (final h in e.value) ChipEstado(texto: h.hora, tono: TonoEstado.exito)],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
