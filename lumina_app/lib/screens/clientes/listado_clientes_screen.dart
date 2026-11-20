import 'package:flutter/material.dart';
import 'package:lumina_app/domain/app_theme.dart';
import 'package:lumina_app/domain/formatos.dart';
import 'package:lumina_app/models/cliente/cliente.dart';
import 'package:lumina_app/models/comun/pagina.dart';
import 'package:lumina_app/routes/app_routes.dart';
import 'package:lumina_app/screens/clientes/detalle_cliente_screen.dart';
import 'package:lumina_app/screens/clientes/formulario_cliente_screen.dart';
import 'package:lumina_app/services/remote/cliente_service.dart';
import 'package:lumina_app/theme/colores_app.dart';
import 'package:lumina_app/widgets/encabezado_modulo.dart';
import 'package:lumina_app/widgets/estados_vista.dart';
import 'package:lumina_app/widgets/filtros.dart';
import 'package:lumina_app/widgets/tarjeta_base.dart';
import 'package:lumina_app/widgets/vista_paginada.dart';

class ListadoClientesScreen extends StatefulWidget {
  const ListadoClientesScreen({super.key});

  @override
  State<ListadoClientesScreen> createState() => _ListadoClientesScreenState();
}

class _ListadoClientesScreenState extends State<ListadoClientesScreen> {
  final ClienteService _servicio = ClienteService();
  late final ControladorPaginado<Cliente> _controlador = ControladorPaginado(_cargar);
  String _busqueda = '';

  @override
  void initState() {
    super.initState();
    _controlador.recargar();
  }

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  Future<Pagina<Cliente>> _cargar(int pagina) => _servicio.listar(busqueda: _busqueda);

  Future<void> _registrar() async {
    final creado = await abrir<Object>(context, const FormularioClienteScreen());
    if (creado != null && mounted) _controlador.recargar();
  }

  Future<void> _verDetalle(Cliente cliente) async {
    await abrir(context, DetalleClienteScreen(cliente: cliente));
    if (mounted) _controlador.recargar();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    return Scaffold(
      backgroundColor: c.fondo,
      appBar: EncabezadoModulo(
        titulo: 'Clientes',
        subtitulo: 'Directorio de clientes del centro',
        acciones: [
          AccionEncabezado(
            icono: Icons.person_add_alt_1_outlined,
            tooltip: 'Nuevo cliente',
            alPresionar: _registrar,
          ),
        ],
      ),
      body: PantallaLista(
        filtros: CampoBusqueda(
          hint: 'Documento, nombre o celular',
          alBuscar: (valor) {
            _busqueda = valor;
            _controlador.recargar();
          },
        ),
        lista: VistaPaginada<Cliente>(
          controlador: _controlador,
          cabecera: ListenableBuilder(
            listenable: _controlador,
            builder: (context, _) => ContadorResultados(
              mostrados: _controlador.items.length,
              total: _controlador.totalItems,
              sustantivo: 'clientes',
            ),
          ),
          constructor: (context, cliente) =>
              TarjetaCliente(cliente: cliente, alTocar: () => _verDetalle(cliente)),
          vacio: EstadoVacio(
            icono: Icons.person_search_outlined,
            titulo: 'No encontramos clientes',
            mensaje: _busqueda.isEmpty
                ? 'Registra el primer cliente del centro.'
                : 'Revisa el documento, nombre o celular.',
            textoAccion: 'Nuevo cliente',
            iconoAccion: Icons.person_add_alt_1_outlined,
            alAccion: _registrar,
          ),
        ),
      ),
    );
  }
}

class TarjetaCliente extends StatelessWidget {
  const TarjetaCliente({super.key, required this.cliente, required this.alTocar, this.seleccion = false});

  final Cliente cliente;
  final VoidCallback alTocar;
  final bool seleccion;

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    final contacto = [
      if ((cliente.celular ?? '').isNotEmpty) Formato.celular(cliente.celular),
      if ((cliente.correo ?? '').isNotEmpty) cliente.correo!,
    ].join('  ·  ');
    return TarjetaBase(
      alTocar: alTocar,
      child: Row(
        children: [
          AvatarIniciales(texto: Formato.iniciales(cliente.nombreCompleto)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(cliente.nombreCompleto, style: AppTheme.cormorant(size: 16, color: c.textoOscuro)),
                Text('CC ${cliente.documento}', style: AppTheme.manrope(size: 12, color: c.textoSutil)),
                Text(
                  contacto.isEmpty ? 'Sin datos de contacto' : contacto,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.manrope(size: 12, color: c.textoSutil),
                ),
              ],
            ),
          ),
          Icon(seleccion ? Icons.add_circle_outline : Icons.chevron_right, color: c.primario),
        ],
      ),
    );
  }
}
