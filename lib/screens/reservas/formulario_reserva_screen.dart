import 'package:flutter/material.dart';
import 'package:lumina_app/domain/app_theme.dart';
import 'package:lumina_app/domain/formatos.dart';
import 'package:lumina_app/models/cliente/cliente.dart';
import 'package:lumina_app/models/especialidad/especialidad.dart';
import 'package:lumina_app/models/reserva/reserva_borrador.dart';
import 'package:lumina_app/models/servicio/servicio.dart';
import 'package:lumina_app/routes/app_routes.dart';
import 'package:lumina_app/screens/clientes/selector_cliente_sheet.dart';
import 'package:lumina_app/screens/reservas/confirmar_reserva_screen.dart';
import 'package:lumina_app/screens/reservas/selector_horario.dart';
import 'package:lumina_app/services/local/catalogo_cache.dart';
import 'package:lumina_app/services/remote/cliente_service.dart';
import 'package:lumina_app/theme/colores_app.dart';
import 'package:lumina_app/widgets/barra_acciones.dart';
import 'package:lumina_app/widgets/campos_formulario.dart';
import 'package:lumina_app/widgets/dialogos.dart';
import 'package:lumina_app/widgets/encabezado_modulo.dart';
import 'package:lumina_app/widgets/estados_vista.dart';
import 'package:lumina_app/widgets/filtros.dart';
import 'package:lumina_app/widgets/marco_pantalla.dart';
import 'package:lumina_app/widgets/selector_opciones.dart';
import 'package:lumina_app/widgets/tarjeta_base.dart';



class FormularioReservaScreen extends StatefulWidget {
  const FormularioReservaScreen({super.key, this.clienteInicial, this.fechaInicial});

  final Cliente? clienteInicial;
  final DateTime? fechaInicial;

  @override
  State<FormularioReservaScreen> createState() => _FormularioReservaScreenState();
}

class _FormularioReservaScreenState extends State<FormularioReservaScreen> {
  final GlobalKey<FormState> _formularioNuevo = GlobalKey<FormState>();
  final TextEditingController _documento = TextEditingController();
  final TextEditingController _nombres = TextEditingController();
  final TextEditingController _apellidos = TextEditingController();
  final TextEditingController _celular = TextEditingController();

  bool _primeraVez = false;
  late Cliente? _cliente = widget.clienteInicial;
  List<Servicio> _servicios = const [];
  List<Especialidad> _especialidades = const [];
  Especialidad? _especialidad;
  Servicio? _servicio;
  SeleccionHorario? _seleccion;
  bool _cargando = true;
  bool _validando = false;
  bool _intentado = false;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    try {
      final servicios = await CatalogoCache.servicios();
      var especialidades = <Especialidad>[];
      try {
        especialidades = await CatalogoCache.especialidades();
      } catch (_) {}
      if (!mounted) return;
      setState(() {
        _servicios = servicios.where((s) => s.activo).toList();
        _especialidades = especialidades.where((e) => e.activa).toList();
      });
    } catch (e) {
      if (mounted) mostrarError(context, e.toString());
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  void dispose() {
    for (final c in [_documento, _nombres, _apellidos, _celular]) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _clienteListo => _primeraVez
      ? [_documento, _nombres, _apellidos, _celular].every((c) => c.text.trim().isNotEmpty)
      : _cliente != null;

  List<String> get _faltantes => [
    if (!_clienteListo) 'cliente',
    if (_servicio == null) 'servicio',
    if (_seleccion == null) 'fecha y hora',
  ];

  int get _paso => !_clienteListo || _servicio == null ? 0 : (_seleccion == null ? 1 : 2);

  Future<void> _elegirCliente() async {
    final cliente = await seleccionarCliente(context);
    if (cliente != null) setState(() => _cliente = cliente);
  }

  Future<void> _elegirServicio() async {
    final lista = _servicios.where((s) => _especialidad == null || s.especialidadId == _especialidad!.id);
    final opcion = await elegirOpcion<Servicio>(
      context,
      titulo: 'Selecciona el servicio',
      seleccionado: _servicio,
      opciones: [
        for (final s in lista)
          OpcionFiltro(s, '${s.nombre}  ·  ${Formato.moneda(s.precio)}  ·  ${Formato.duracion(s.duracion)}'),
      ],
    );
    if (opcion == null || opcion.valor.id == _servicio?.id) return;
    setState(() {
      _servicio = opcion.valor;
      _seleccion = null;
    });
  }

  Future<void> _continuar() async {
    setState(() => _intentado = true);
    if (_primeraVez && !(_formularioNuevo.currentState?.validate() ?? false)) return;
    if (_faltantes.isNotEmpty) {
      mostrarError(context, 'Falta seleccionar: ${_faltantes.join(', ')}.');
      return;
    }
    var cliente = _primeraVez ? null : _cliente;
    if (_primeraVez) {
      // Si el documento ya existe, se ofrece usar el cliente registrado.
      setState(() => _validando = true);
      try {
        final existente = await ClienteService().buscarPorDocumento(_documento.text);
        if (existente != null && mounted) {
          final usar = await confirmarAccion(
            context,
            titulo: 'Cliente ya registrado',
            mensaje: 'El documento ${_documento.text.trim()} pertenece a ${existente.nombreCompleto}. '
                '¿Crear la reserva con este cliente?',
            textoConfirmar: 'Usar cliente',
            icono: Icons.person_search_outlined,
          );
          if (!usar) return;
          cliente = existente;
          setState(() {
            _primeraVez = false;
            _cliente = existente;
          });
        }
      } catch (_) {
        // Si la verificación falla se continúa como primera vez.
      } finally {
        if (mounted) setState(() => _validando = false);
      }
    }
    if (!mounted) return;
    final borrador = ReservaBorrador(
      cliente: cliente,
      clienteNuevo: cliente == null
          ? ClienteNuevo(
              documento: _documento.text.trim(),
              nombres: _nombres.text.trim(),
              apellidos: _apellidos.text.trim(),
              celular: _celular.text.trim(),
            )
          : null,
      servicio: _servicio!,
      profesional: _seleccion!.profesional,
      horario: _seleccion!.horario,
    );
    await abrir(context, ConfirmarReservaScreen(borrador: borrador));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    return Scaffold(
      backgroundColor: c.fondo,
      appBar: const EncabezadoModulo(titulo: 'Reserva tu momento', subtitulo: 'Programa una cita para un cliente'),
      body: _cargando
          ? const EstadoCarga(mensaje: 'Cargando servicios...')
          : ContenidoCentrado(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  _Pasos(paso: _paso),
                  const SizedBox(height: 20),
                  const EtiquetaCampo('1. Cliente', obligatorio: true),
                  const SizedBox(height: 8),
                  BarraFiltros<bool>(
                    seleccionado: _primeraVez,
                    alCambiar: (v) => setState(() => _primeraVez = v),
                    opciones: const [OpcionFiltro(false, 'Cliente registrado'), OpcionFiltro(true, 'Primera vez')],
                  ),
                  const SizedBox(height: 10),
                  if (!_primeraVez)
                    _Selector(
                      icono: Icons.person_search_outlined,
                      texto: 'Buscar o seleccionar cliente',
                      valor: _cliente == null ? null : '${_cliente!.nombreCompleto} · CC ${_cliente!.documento}',
                      error: _intentado && _cliente == null,
                      alTocar: _elegirCliente,
                    )
                  else
                    Form(
                      key: _formularioNuevo,
                      child: TarjetaBase(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text('El cliente quedará registrado junto con la reserva.',
                                style: AppTheme.manrope(size: 12.5, color: c.textoSutil)),
                            const SizedBox(height: 12),
                            CampoTexto(
                              etiqueta: 'Documento',
                              controlador: _documento,
                              icono: Icons.badge_outlined,
                              obligatorio: true,
                              teclado: TextInputType.number,
                              formateadores: [Formateadores.soloDigitos],
                              validador: Validar.documento,
                              alCambiar: (_) => setState(() {}),
                            ),
                            const SizedBox(height: 12),
                            CampoTexto(
                              etiqueta: 'Nombres',
                              controlador: _nombres,
                              icono: Icons.person_outline,
                              obligatorio: true,
                              mayusculas: TextCapitalization.words,
                              validador: (v) => Validar.requerido(v, 'los nombres'),
                              alCambiar: (_) => setState(() {}),
                            ),
                            const SizedBox(height: 12),
                            CampoTexto(
                              etiqueta: 'Apellidos',
                              controlador: _apellidos,
                              icono: Icons.person_outline,
                              obligatorio: true,
                              mayusculas: TextCapitalization.words,
                              validador: (v) => Validar.requerido(v, 'los apellidos'),
                              alCambiar: (_) => setState(() {}),
                            ),
                            const SizedBox(height: 12),
                            CampoTexto(
                              etiqueta: 'Celular',
                              controlador: _celular,
                              icono: Icons.phone_iphone_outlined,
                              obligatorio: true,
                              teclado: TextInputType.phone,
                              longitudMaxima: 10,
                              formateadores: [Formateadores.soloDigitos],
                              validador: (v) => Validar.celular(v, obligatorio: true),
                              alCambiar: (_) => setState(() {}),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 22),
                  const EtiquetaCampo('2. Servicio', obligatorio: true),
                  const SizedBox(height: 8),
                  if (_especialidades.isNotEmpty) ...[
                    BarraFiltros<Especialidad?>(
                      seleccionado: _especialidad,
                      alCambiar: (e) => setState(() => _especialidad = e),
                      opciones: [
                        const OpcionFiltro(null, 'Todas'),
                        for (final e in _especialidades) OpcionFiltro(e, e.nombre),
                      ],
                    ),
                    const SizedBox(height: 10),
                  ],
                  _Selector(
                    icono: Icons.content_cut_outlined,
                    texto: 'Seleccionar servicio',
                    valor: _servicio == null ? null : '${_servicio!.nombre} (${Formato.moneda(_servicio!.precio)})',
                    detalle: _servicio == null ? null : Formato.duracion(_servicio!.duracion),
                    error: _intentado && _servicio == null,
                    alTocar: _elegirServicio,
                  ),
                  const SizedBox(height: 22),
                  if (_servicio == null)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: c.bordeTarjeta, borderRadius: BorderRadius.circular(14)),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: c.textoSecundario),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text('Elige un servicio para ver profesionales y horarios disponibles.',
                                style: AppTheme.manrope(size: 13, color: c.textoSecundario)),
                          ),
                        ],
                      ),
                    )
                  else
                    SelectorHorario(
                      key: ValueKey(_servicio!.id),
                      servicio: _servicio!,
                      fechaInicial: widget.fechaInicial,
                      alCambiar: (s) => setState(() => _seleccion = s),
                    ),
                  if (_intentado && _faltantes.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Text('Falta: ${_faltantes.join(', ')}',
                        style: AppTheme.manrope(size: 12.5, weight: FontWeight.w600, color: AppColors.rojoAlerta)),
                  ],
                ],
              ),
            ),
      bottomNavigationBar: BarraAcciones(
        textoPrincipal: 'Continuar',
        alPrincipal: _continuar,
        cargando: _validando,
      ),
    );
  }
}

class _Pasos extends StatelessWidget {
  const _Pasos({required this.paso});

  final int paso;

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    const textos = ['Cliente y servicio', 'Profesional', 'Fecha y hora'];
    return Row(
      children: [
        for (var i = 0; i < 3; i++)
          Expanded(
            child: Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: i <= paso ? AppColors.primario : c.borde,
                  child: i < paso
                      ? const Icon(Icons.check, size: 14, color: Colors.white)
                      : Text('${i + 1}',
                          style: AppTheme.manrope(
                              size: 11.5, weight: FontWeight.w800, color: i <= paso ? Colors.white : c.textoSutil)),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(textos[i],
                      maxLines: 2,
                      style: AppTheme.manrope(
                          size: 11, weight: FontWeight.w700, color: i <= paso ? c.textoOscuro : c.textoSutil)),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Selector extends StatelessWidget {
  const _Selector({
    required this.icono,
    required this.texto,
    required this.valor,
    required this.alTocar,
    this.detalle,
    this.error = false,
  });

  final IconData icono;
  final String texto;
  final String? valor;
  final String? detalle;
  final bool error;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    final elegido = valor != null;
    return InkWell(
      onTap: alTocar,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: elegido ? c.badgeFondo : c.superficie,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: error ? AppColors.rojoAlerta : (elegido ? c.primario : c.borde),
            width: error || elegido ? 1.4 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icono, color: elegido ? c.primario : c.textoSecundario),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(valor ?? texto,
                      style: AppTheme.manrope(
                          size: 14,
                          weight: elegido ? FontWeight.w700 : FontWeight.w500,
                          color: elegido ? c.textoOscuro : c.hint)),
                  if (detalle != null) Text(detalle!, style: AppTheme.manrope(size: 12, color: c.textoSutil)),
                ],
              ),
            ),
            Icon(Icons.expand_more, color: c.textoSecundario),
          ],
        ),
      ),
    );
  }
}
