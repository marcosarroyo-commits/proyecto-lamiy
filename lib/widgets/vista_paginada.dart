import 'package:flutter/material.dart';
import 'package:lumina_app/domain/app_theme.dart';
import 'package:lumina_app/models/comun/pagina.dart';
import 'package:lumina_app/services/remote/api_service.dart';
import 'package:lumina_app/theme/colores_app.dart';
import 'package:lumina_app/widgets/estados_vista.dart';
import 'package:lumina_app/widgets/marco_pantalla.dart';

typedef CargadorPagina<T> = Future<Pagina<T>> Function(int pagina);

class ControladorPaginado<T> extends ChangeNotifier {
  ControladorPaginado(this._cargador);

  final CargadorPagina<T> _cargador;
  final List<T> items = [];

  int _pagina = 0;
  int _version = 0;
  int totalItems = 0;
  bool _hayMas = true;
  bool cargando = false;
  bool iniciado = false;
  bool _descartado = false;
  String? error;

  bool get hayMas => _hayMas;

  bool get vacio => items.isEmpty;

  Future<void> recargar() {
    _version++;
    items.clear();
    _pagina = 0;
    totalItems = 0;
    _hayMas = true;
    error = null;
    cargando = false;
    _notificar();
    return cargarMas();
  }

  Future<void> cargarMas() async {
    if (cargando || !_hayMas) return;
    final version = _version;
    cargando = true;
    error = null;
    _notificar();

    try {
      final pagina = await _cargador(_pagina + 1);
      if (version != _version) return;
      items.addAll(pagina.items);
      _pagina++;
      totalItems = pagina.totalItems;
      _hayMas = pagina.hayMas && pagina.items.isNotEmpty;
    } on ApiException catch (e) {
      if (version != _version) return;
      error = e.message;
    } catch (_) {
      if (version != _version) return;
      error = 'Ocurrió un error inesperado. Intenta de nuevo.';
    } finally {
      if (version == _version) {
        cargando = false;
        iniciado = true;
        _notificar();
      }
    }
  }

  void _notificar() {
    if (!_descartado) notifyListeners();
  }

  @override
  void dispose() {
    _descartado = true;
    super.dispose();
  }
}

class VistaPaginada<T> extends StatefulWidget {
  const VistaPaginada({
    super.key,
    required this.controlador,
    required this.constructor,
    required this.vacio,
    this.cabecera,
    this.separacion = 12,
    this.padding = const EdgeInsets.fromLTRB(16, 4, 16, 24),
  });

  final ControladorPaginado<T> controlador;
  final Widget Function(BuildContext context, T item) constructor;
  final Widget vacio;
  final Widget? cabecera;
  final double separacion;
  final EdgeInsets padding;

  @override
  State<VistaPaginada<T>> createState() => _VistaPaginadaState<T>();
}

class _VistaPaginadaState<T> extends State<VistaPaginada<T>> {
  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_alDesplazar);
  }

  @override
  void dispose() {
    _scroll.removeListener(_alDesplazar);
    _scroll.dispose();
    super.dispose();
  }

  void _alDesplazar() {
    final controlador = widget.controlador;
    if (!_scroll.hasClients || controlador.error != null) return;
    if (_scroll.position.extentAfter < 300) controlador.cargarMas();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controlador,
      builder: (context, _) {
        final controlador = widget.controlador;

        if (controlador.vacio && (controlador.cargando || !controlador.iniciado)) {
          return const EstadoCarga();
        }

        if (controlador.vacio) {
          return RefreshIndicator(
            onRefresh: controlador.recargar,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: widget.padding,
              children: [
                ?widget.cabecera,
                const SizedBox(height: 32),
                if (controlador.error != null)
                  EstadoError(
                    mensaje: controlador.error!,
                    alReintentar: controlador.recargar,
                  )
                else
                  widget.vacio,
              ],
            ),
          );
        }

        final desplazamiento = widget.cabecera == null ? 0 : 1;
        final total = controlador.items.length + desplazamiento + 1;

        return RefreshIndicator(
          onRefresh: controlador.recargar,
          child: ListView.separated(
            controller: _scroll,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: widget.padding,
            itemCount: total,
            separatorBuilder: (context, indice) =>
                SizedBox(height: widget.separacion),
            itemBuilder: (context, indice) {
              if (widget.cabecera != null && indice == 0) {
                return widget.cabecera!;
              }
              final posicion = indice - desplazamiento;
              if (posicion < controlador.items.length) {
                return widget.constructor(
                  context,
                  controlador.items[posicion],
                );
              }
              return _PiePagina(controlador: controlador);
            },
          ),
        );
      },
    );
  }
}

class _PiePagina<T> extends StatelessWidget {
  const _PiePagina({required this.controlador});

  final ControladorPaginado<T> controlador;

  @override
  Widget build(BuildContext context) {
    final c = context.colores;

    if (controlador.cargando) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
        ),
      );
    }

    if (controlador.error != null) {
      return Center(
        child: TextButton.icon(
          onPressed: controlador.cargarMas,
          icon: const Icon(Icons.refresh, size: 18),
          label: const Text('No se pudo cargar más. Reintentar'),
        ),
      );
    }

    if (controlador.hayMas) {
      return Center(
        child: TextButton(
          onPressed: controlador.cargarMas,
          child: const Text('Cargar más'),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        'No hay más resultados',
        textAlign: TextAlign.center,
        style: AppTheme.manrope(size: 12, color: c.textoSutil),
      ),
    );
  }
}

class PantallaLista extends StatelessWidget {
  const PantallaLista({super.key, required this.filtros, required this.lista});

  final Widget filtros;
  final Widget lista;

  @override
  Widget build(BuildContext context) {
    return ContenidoCentrado(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: filtros,
          ),
          Expanded(child: lista),
        ],
      ),
    );
  }
}
