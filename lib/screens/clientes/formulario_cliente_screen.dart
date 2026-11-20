import 'package:flutter/material.dart';
import 'package:lumina_app/domain/fechas.dart';
import 'package:lumina_app/models/cliente/cliente.dart';
import 'package:lumina_app/services/remote/api_service.dart';
import 'package:lumina_app/services/remote/cliente_service.dart';
import 'package:lumina_app/theme/colores_app.dart';
import 'package:lumina_app/widgets/barra_acciones.dart';
import 'package:lumina_app/widgets/campos_formulario.dart';
import 'package:lumina_app/widgets/dialogos.dart';
import 'package:lumina_app/widgets/encabezado_modulo.dart';
import 'package:lumina_app/widgets/marco_pantalla.dart';
import 'package:lumina_app/widgets/mensaje_error.dart';



class FormularioClienteScreen extends StatefulWidget {
  const FormularioClienteScreen({super.key, this.cliente, this.documentoInicial});

  final Cliente? cliente;
  final String? documentoInicial;

  @override
  State<FormularioClienteScreen> createState() => _FormularioClienteScreenState();
}

class _FormularioClienteScreenState extends State<FormularioClienteScreen> {
  final ClienteService _servicio = ClienteService();
  final GlobalKey<FormState> _formulario = GlobalKey<FormState>();
  late final TextEditingController _documento =
      TextEditingController(text: widget.cliente?.documento ?? widget.documentoInicial ?? '');
  late final TextEditingController _nombres = TextEditingController(text: widget.cliente?.nombres ?? '');
  late final TextEditingController _apellidos =
      TextEditingController(text: widget.cliente?.apellidos ?? '');
  late final TextEditingController _celular = TextEditingController(text: widget.cliente?.celular ?? '');
  late final TextEditingController _correo = TextEditingController(text: widget.cliente?.correo ?? '');
  late DateTime? _nacimiento = widget.cliente?.fechaNacimiento;

  bool _guardando = false;
  String? _errorServidor;

  bool get _editando => widget.cliente != null;

  @override
  void dispose() {
    for (final c in [_documento, _nombres, _apellidos, _celular, _correo]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _guardar() async {
    FocusScope.of(context).unfocus();
    setState(() => _errorServidor = null);
    if (!(_formulario.currentState?.validate() ?? false)) return;
    setState(() => _guardando = true);
    try {
      if (_editando) {
        await _servicio.editar(
          widget.cliente!.id,
          documento: _documento.text,
          nombres: _nombres.text,
          apellidos: _apellidos.text,
          fechaNacimiento: _nacimiento,
          celular: _celular.text,
          correo: _correo.text,
        );
        if (!mounted) return;
        mostrarExito(context, 'Cliente actualizado.');
        Navigator.pop(context, true);
        return;
      }
      
      final existente = await _servicio.buscarPorDocumento(_documento.text);
      if (existente != null) {
        setState(() => _errorServidor =
            'Ya existe un cliente con el documento ${_documento.text.trim()} (${existente.nombreCompleto}).');
        return;
      }
      final creado = await _servicio.registrar(
        documento: _documento.text,
        nombres: _nombres.text,
        apellidos: _apellidos.text,
        fechaNacimiento: _nacimiento,
        celular: _celular.text,
        correo: _correo.text,
      );
      if (!mounted) return;
      mostrarExito(context, 'Cliente creado.');
      Navigator.pop<Object>(context, creado ?? true);
    } on ApiException catch (e) {
      if (mounted) setState(() => _errorServidor = e.message);
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    return Scaffold(
      backgroundColor: c.fondo,
      appBar: EncabezadoModulo(
        titulo: _editando ? 'Editar cliente' : 'Nuevo cliente',
        subtitulo: _editando ? widget.cliente!.nombreCompleto : 'Completa los datos de contacto',
      ),
      body: Form(
        key: _formulario,
        child: ContenidoCentrado(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              if (_errorServidor != null) ...[MensajeError(_errorServidor!), const SizedBox(height: 16)],
              const TituloSeccionFormulario(titulo: 'Identificación', icono: Icons.badge_outlined),
              const SizedBox(height: 10),
              CampoTexto(
                etiqueta: 'Documento',
                controlador: _documento,
                icono: Icons.badge_outlined,
                hint: 'Número de identificación',
                obligatorio: true,
                teclado: TextInputType.number,
                formateadores: [Formateadores.soloDigitos],
                validador: Validar.documento,
              ),
              const SizedBox(height: 16),
              CampoTexto(
                etiqueta: 'Nombres',
                controlador: _nombres,
                icono: Icons.person_outline,
                obligatorio: true,
                mayusculas: TextCapitalization.words,
                validador: (v) => Validar.requerido(v, 'los nombres'),
              ),
              const SizedBox(height: 16),
              CampoTexto(
                etiqueta: 'Apellidos',
                controlador: _apellidos,
                icono: Icons.person_outline,
                obligatorio: true,
                mayusculas: TextCapitalization.words,
                validador: (v) => Validar.requerido(v, 'los apellidos'),
              ),
              const SizedBox(height: 16),
              CampoFecha(
                etiqueta: 'Fecha de nacimiento',
                valor: _nacimiento,
                primera: DateTime(1920),
                ultima: Fechas.hoy, // no se permiten fechas futuras
                icono: Icons.cake_outlined,
                alCambiar: (f) => setState(() => _nacimiento = f),
              ),
              const SizedBox(height: 20),
              const TituloSeccionFormulario(titulo: 'Contacto', icono: Icons.contact_phone_outlined),
              const SizedBox(height: 10),
              CampoTexto(
                etiqueta: 'Celular',
                controlador: _celular,
                icono: Icons.phone_iphone_outlined,
                hint: '3004567821',
                teclado: TextInputType.phone,
                longitudMaxima: 10,
                formateadores: [Formateadores.soloDigitos],
                validador: (v) => Validar.celular(v),
              ),
              const SizedBox(height: 16),
              CampoTexto(
                etiqueta: 'Correo',
                controlador: _correo,
                icono: Icons.alternate_email,
                hint: 'nombre@correo.com',
                teclado: TextInputType.emailAddress,
                accion: TextInputAction.done,
                validador: Validar.correoOpcional,
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BarraAcciones(
        textoPrincipal: _editando ? 'Guardar cambios' : 'Crear cliente',
        alPrincipal: _guardar,
        cargando: _guardando,
      ),
    );
  }
}
