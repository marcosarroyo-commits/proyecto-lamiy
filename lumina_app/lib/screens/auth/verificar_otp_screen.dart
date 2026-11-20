import 'package:flutter/material.dart';
import 'package:lumina_app/domain/app_theme.dart';
import 'package:lumina_app/domain/auth.dart';
import 'package:lumina_app/routes/app_routes.dart';
import 'package:lumina_app/services/remote/recuperacion_service.dart';
import 'package:lumina_app/theme/colores_app.dart';
import 'package:lumina_app/widgets/boton_principal.dart';
import 'package:lumina_app/widgets/campos_formulario.dart';
import 'package:lumina_app/widgets/dialogos.dart';
import 'package:lumina_app/widgets/encabezado_seguridad.dart';
import 'package:lumina_app/widgets/mensaje_error.dart';

/// Paso 2: verificar el código OTP (modo demostración: 123456).
class VerificarOtpScreen extends StatefulWidget {
  const VerificarOtpScreen({super.key, required this.usuario});

  final String usuario;

  @override
  State<VerificarOtpScreen> createState() => _VerificarOtpScreenState();
}

class _VerificarOtpScreenState extends State<VerificarOtpScreen> {
  final RecuperacionService _servicio = RecuperacionService();
  final TextEditingController _codigo = TextEditingController();
  bool _verificando = false;
  String? _error;

  @override
  void dispose() {
    _codigo.dispose();
    super.dispose();
  }

  Future<void> _verificar() async {
    final error = Auth.validarOtp(_codigo.text);
    setState(() => _error = error);
    if (error != null) return;
    setState(() => _verificando = true);
    final valido = await _servicio.verificarCodigo(widget.usuario, _codigo.text);
    if (!mounted) return;
    setState(() => _verificando = false);
    if (!valido) {
      setState(() => _error = 'El código no es correcto. Revisa tu correo e intenta de nuevo.');
      return;
    }
    await mostrarInformacion(
      context,
      titulo: 'Solicitud enviada',
      icono: Icons.mark_email_read_outlined,
      contenido: Text(
        'Verificamos tu código. El administrador del centro completará el cambio '
        'de tu clave y te la enviará al correo registrado.',
        textAlign: TextAlign.center,
        style: AppTheme.manrope(size: 13, color: context.colores.textoSecundario),
      ),
    );
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (ruta) => false);
  }

  Future<void> _reenviar() async {
    await _servicio.solicitarCodigo(widget.usuario);
    if (mounted) mostrarExito(context, 'Te enviamos un nuevo código.');
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    return Scaffold(
      backgroundColor: c.superficie,
      appBar: const EncabezadoSeguridad(titulo: 'Verificar código'),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Icon(Icons.mark_email_unread_outlined, size: 64, color: c.acento),
                const SizedBox(height: 16),
                Text(
                  'Revisa tu correo',
                  textAlign: TextAlign.center,
                  style: AppTheme.cormorant(size: 26, color: c.primarioOscuro),
                ),
                const SizedBox(height: 6),
                Text(
                  'Escribe el código de 6 dígitos enviado al correo del usuario '
                  '${Auth.enmascararUsuario(widget.usuario)}.',
                  textAlign: TextAlign.center,
                  style: AppTheme.manrope(size: 14, color: c.textoSutil),
                ),
                const SizedBox(height: 24),
                if (_error != null) ...[MensajeError(_error!), const SizedBox(height: 16)],
                TextField(
                  controller: _codigo,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  inputFormatters: [Formateadores.soloDigitos],
                  onSubmitted: (_) => _verificar(),
                  style: AppTheme.cormorant(size: 30, color: c.primarioOscuro)
                      .copyWith(letterSpacing: 14),
                  decoration: InputDecoration(
                    counterText: '',
                    hintText: '······',
                    filled: true,
                    fillColor: c.fondo,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: c.borde),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('¿No recibiste el código?',
                        style: AppTheme.manrope(size: 13, color: c.textoSutil)),
                    TextButton(onPressed: _reenviar, child: const Text('Reenviar')),
                  ],
                ),
                const SizedBox(height: 12),
                BotonPrincipal(
                  texto: 'Verificar código',
                  alPresionar: _verificar,
                  cargando: _verificando,
                ),
                const SizedBox(height: 16),
                Text(
                  'Modo demostración: usa el código ${RecuperacionService.codigoDemo}.',
                  textAlign: TextAlign.center,
                  style: AppTheme.manrope(size: 11.5, color: c.hint),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
