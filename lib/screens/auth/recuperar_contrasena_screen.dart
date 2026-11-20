import 'package:flutter/material.dart';
import 'package:lumina_app/domain/app_theme.dart';
import 'package:lumina_app/domain/auth.dart';
import 'package:lumina_app/routes/app_routes.dart';
import 'package:lumina_app/services/remote/recuperacion_service.dart';
import 'package:lumina_app/theme/colores_app.dart';
import 'package:lumina_app/widgets/boton_principal.dart';
import 'package:lumina_app/widgets/campos_formulario.dart';
import 'package:lumina_app/widgets/decoracion_campo.dart';
import 'package:lumina_app/widgets/encabezado_seguridad.dart';
import 'package:lumina_app/widgets/logo_lumina.dart';


class RecuperarContrasenaScreen extends StatefulWidget {
  const RecuperarContrasenaScreen({super.key});

  @override
  State<RecuperarContrasenaScreen> createState() => _RecuperarContrasenaScreenState();
}

class _RecuperarContrasenaScreenState extends State<RecuperarContrasenaScreen> {
  final TextEditingController _usuario = TextEditingController();
  bool _enviando = false;
  String? _error;

  @override
  void dispose() {
    _usuario.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    final error = Auth.validarUsuario(_usuario.text);
    setState(() => _error = error);
    if (error != null) return;
    setState(() => _enviando = true);
    await RecuperacionService().solicitarCodigo(_usuario.text.trim());
    if (!mounted) return;
    setState(() => _enviando = false);
    Navigator.pushNamed(context, AppRoutes.verificarOtp, arguments: _usuario.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    return Scaffold(
      backgroundColor: c.superficie,
      appBar: const EncabezadoSeguridad(titulo: 'Recuperar contraseña'),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                const Center(child: MonogramaLumina(tamano: 96)),
                const SizedBox(height: 20),
                Text(
                  '¿Olvidaste tu clave?',
                  textAlign: TextAlign.center,
                  style: AppTheme.cormorant(size: 26, color: c.primarioOscuro),
                ),
                const SizedBox(height: 6),
                Text(
                  'Ingresa tu usuario y enviaremos un código de verificación al correo registrado.',
                  textAlign: TextAlign.center,
                  style: AppTheme.manrope(size: 14, color: c.textoSutil),
                ),
                const SizedBox(height: 28),
                const EtiquetaCampo('Usuario', obligatorio: true),
                const SizedBox(height: 6),
                TextField(
                  controller: _usuario,
                  onSubmitted: (_) => _enviar(),
                  style: AppTheme.manrope(size: 14, color: c.textoTitulo),
                  decoration: decoracionCampo(
                    context,
                    hint: 'Tu número de documento',
                    icono: Icons.person_outline,
                    error: _error,
                  ),
                ),
                const SizedBox(height: 24),
                BotonPrincipal(texto: 'Enviar código', alPresionar: _enviar, cargando: _enviando),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Volver a iniciar sesión'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
