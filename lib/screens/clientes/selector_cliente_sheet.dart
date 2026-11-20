import 'package:flutter/material.dart';
import 'package:lumina_app/domain/app_theme.dart';
import 'package:lumina_app/models/cliente/cliente.dart';
import 'package:lumina_app/routes/app_routes.dart';
import 'package:lumina_app/screens/clientes/formulario_cliente_screen.dart';
import 'package:lumina_app/screens/clientes/listado_clientes_screen.dart';
import 'package:lumina_app/services/local/catalogo_cache.dart';
import 'package:lumina_app/services/remote/cliente_service.dart';
import 'package:lumina_app/theme/colores_app.dart';
import 'package:lumina_app/widgets/estados_vista.dart';
import 'package:lumina_app/widgets/filtros.dart';




Future<Cliente?> seleccionarCliente(BuildContext context) {
  return showModalBottomSheet<Cliente>(
    context: context,
    isScrollControlled: true,
    builder: (_) => const _SelectorCliente(),
  );
}

class _SelectorCliente extends StatefulWidget {
  const _SelectorCliente();

  @override
  State<_SelectorCliente> createState() => _SelectorClienteState();
}

class _SelectorClienteState extends State<_SelectorCliente> {
  List<Cliente> _todos = const [];
  Cliente? _porDocumento;
  String _busqueda = '';
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    try {
      final lista = await CatalogoCache.clientes();
      if (mounted) setState(() => _todos = lista);
    } catch (_) {
      
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _buscar(String valor) async {
    setState(() {
      _busqueda = valor;
      _porDocumento = null;
    });
    if (RegExp(r'^\d{6,15}$').hasMatch(valor) && !_todos.any((c) => c.documento == valor)) {
      try {
        final cliente = await ClienteService().buscarPorDocumento(valor);
        if (mounted && _busqueda == valor) setState(() => _porDocumento = cliente);
      } catch (_) {}
    }
  }

  Future<void> _nuevo() async {
    final creado = await abrir<Object>(
      context,
      FormularioClienteScreen(
        documentoInicial: RegExp(r'^\d+$').hasMatch(_busqueda) ? _busqueda : null,
      ),
    );
    if (!mounted) return;
    if (creado is Cliente) Navigator.pop(context, creado);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    final lista = [
      if (_porDocumento != null) _porDocumento!,
      ..._todos.where((cl) => cl.coincide(_busqueda)),
    ];
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.82,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 8, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text('Selecciona el cliente',
                          style: AppTheme.cormorant(size: 20, color: c.primarioOscuro)),
                    ),
                    TextButton.icon(
                      onPressed: _nuevo,
                      icon: const Icon(Icons.person_add_alt_1_outlined, size: 18),
                      label: const Text('Nuevo'),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: CampoBusqueda(
                  hint: 'Documento, nombre o celular',
                  alBuscar: _buscar,
                  teclado: TextInputType.text,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: _cargando
                    ? const EstadoCarga(mensaje: 'Cargando clientes...')
                    : lista.isEmpty
                        ? EstadoVacio(
                            icono: Icons.person_search_outlined,
                            titulo: 'Sin coincidencias',
                            mensaje: 'Registra al cliente para continuar con la reserva.',
                            textoAccion: 'Registrar cliente',
                            iconoAccion: Icons.person_add_alt_1_outlined,
                            alAccion: _nuevo,
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                            itemCount: lista.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 10),
                            itemBuilder: (context, i) => TarjetaCliente(
                              cliente: lista[i],
                              seleccion: true,
                              alTocar: () => Navigator.pop(context, lista[i]),
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
