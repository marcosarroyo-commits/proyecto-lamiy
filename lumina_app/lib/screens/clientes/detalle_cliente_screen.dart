import 'package:flutter/material.dart';
import 'package:lumina_app/domain/app_theme.dart';
import 'package:lumina_app/domain/fechas.dart';
import 'package:lumina_app/domain/formatos.dart';
import 'package:lumina_app/models/cliente/cliente.dart';
import 'package:lumina_app/models/reserva/reserva.dart';
import 'package:lumina_app/routes/app_routes.dart';
import 'package:lumina_app/screens/clientes/formulario_cliente_screen.dart';
import 'package:lumina_app/screens/reservas/detalle_reserva_screen.dart';
import 'package:lumina_app/screens/reservas/formulario_reserva_screen.dart';
import 'package:lumina_app/services/remote/api_service.dart';
import 'package:lumina_app/services/remote/cliente_service.dart';
import 'package:lumina_app/services/remote/reserva_service.dart';
import 'package:lumina_app/theme/colores_app.dart';
import 'package:lumina_app/widgets/barra_acciones.dart';
import 'package:lumina_app/widgets/dialogos.dart';
import 'package:lumina_app/widgets/encabezado_modulo.dart';
import 'package:lumina_app/widgets/estados_vista.dart';
import 'package:lumina_app/widgets/marco_pantalla.dart';
import 'package:lumina_app/widgets/seccion_detalle.dart';
import 'package:lumina_app/widgets/tarjeta_base.dart';
import 'package:lumina_app/widgets/tarjeta_reserva.dart';

/// Ficha del cliente con su historial de reservas.
class DetalleClienteScreen extends StatefulWidget {
  const DetalleClienteScreen({super.key, required this.cliente});

  final Cliente cliente;

  @override
  State<DetalleClienteScreen> createState() => _DetalleClienteScreenState();
}

class _DetalleClienteScreenState extends State<DetalleClienteScreen> {
  final ClienteService _servicio = ClienteService();
  late Cliente _cliente = widget.cliente;
  List<Reserva>? _reservas;
  String? _errorReservas;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    try {
      // GET /api/clientes/{documento}
      final actual = await _servicio.buscarPorDocumento(_cliente.documento);
      if (actual != null && mounted) setState(() => _cliente = actual);
    } on ApiException catch (_) {}
    try {
      final todas = await ReservaService().todas();
      if (!mounted) return;
      setState(() {
        _errorReservas = null;
        _reservas = todas
            .where((r) => r.clienteId == _cliente.id || r.clienteDocumento == _cliente.documento)
            .toList()
            .reversed
            .toList();
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _errorReservas = e.message);
    }
  }

  Future<void> _editar() async {
    final guardado = await abrir<Object>(context, FormularioClienteScreen(cliente: _cliente));
    if (guardado != null && mounted) _cargar();
  }

  Future<void> _eliminar() async {
    final confirmado = await confirmarAccion(
      context,
      titulo: 'Eliminar cliente',
      mensaje: 'Se eliminará a ${_cliente.nombreCompleto}. Esta acción no se puede deshacer.',
      textoConfirmar: 'Eliminar',
      peligrosa: true,
      icono: Icons.person_remove_outlined,
    );
    if (!confirmado || !mounted) return;
    try {
      await _servicio.borrar(_cliente.id);
      if (!mounted) return;
      mostrarExito(context, 'Cliente eliminado.');
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (mounted) mostrarError(context, e.message);
    }
  }

  Future<void> _nuevaReserva() async {
    await abrir(context, FormularioReservaScreen(clienteInicial: _cliente));
    if (mounted) _cargar();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    final atendidas = _reservas?.where((r) => r.atendida).length ?? 0;
    return Scaffold(
      backgroundColor: c.fondo,
      appBar: EncabezadoModulo(
        titulo: 'Cliente',
        subtitulo: 'Ficha y reservas',
        acciones: [AccionEncabezado(icono: Icons.edit_outlined, tooltip: 'Editar', alPresionar: _editar)],
      ),
      body: ContenidoCentrado(
        child: RefreshIndicator(
          onRefresh: _cargar,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              TarjetaBase(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    AvatarIniciales(texto: Formato.iniciales(_cliente.nombreCompleto), tamano: 68),
                    const SizedBox(height: 10),
                    Text(_cliente.nombreCompleto,
                        textAlign: TextAlign.center,
                        style: AppTheme.cormorant(size: 20, color: c.textoOscuro)),
                    Text('CC ${_cliente.documento}', style: AppTheme.manrope(size: 13, color: c.textoSutil)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SeccionDetalle(
                titulo: 'Datos de contacto',
                icono: Icons.contact_phone_outlined,
                children: [
                  FilaDato(icono: Icons.phone_iphone_outlined, etiqueta: 'Celular', valor: Formato.celular(_cliente.celular)),
                  FilaDato(icono: Icons.alternate_email, etiqueta: 'Correo', valor: Formato.valorO(_cliente.correo)),
                  FilaDato(icono: Icons.cake_outlined, etiqueta: 'Nacimiento', valor: Fechas.corta(_cliente.fechaNacimiento)),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Text('Historial de reservas',
                        style: AppTheme.cormorant(size: 17, color: c.primarioOscuro)),
                  ),
                  Text('$atendidas atendida(s)', style: AppTheme.manrope(size: 12, color: c.textoSutil)),
                ],
              ),
              const SizedBox(height: 8),
              if (_errorReservas != null)
                EstadoError(mensaje: _errorReservas!, alReintentar: _cargar)
              else if (_reservas == null)
                const SizedBox(height: 120, child: EstadoCarga(mensaje: 'Consultando reservas...'))
              else if (_reservas!.isEmpty)
                EstadoVacio(
                  icono: Icons.event_note_outlined,
                  titulo: 'Sin reservas',
                  mensaje: 'Este cliente aún no tiene reservas.',
                  textoAccion: 'Crear reserva',
                  alAccion: _nuevaReserva,
                )
              else
                for (final r in _reservas!)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: TarjetaReserva(
                      reserva: r,
                      alTocar: () => abrir(context, DetalleReservaScreen(reserva: r)),
                    ),
                  ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: PieAcciones(
        children: [
          BotonSecundario(texto: 'Eliminar', icono: Icons.delete_outline, peligro: true, alPresionar: _eliminar),
          BotonSecundario(texto: 'Reservar', icono: Icons.event_available_outlined, alPresionar: _nuevaReserva),
        ],
      ),
    );
  }
}
