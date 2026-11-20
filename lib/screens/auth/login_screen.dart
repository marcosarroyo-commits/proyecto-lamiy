import 'package:flutter/material.dart';
import 'package:lumina_app/domain/app_theme.dart';
import 'package:lumina_app/domain/auth.dart';
import 'package:lumina_app/models/login/login_request.dart';
import 'package:lumina_app/routes/app_routes.dart';
import 'package:lumina_app/services/local/catalogo_cache.dart';
import 'package:lumina_app/services/local/gestor_sesion.dart';
import 'package:lumina_app/services/remote/api_service.dart';
import 'package:lumina_app/services/remote/login_service.dart';
import 'package:lumina_app/services/remote/profesional_service.dart';
import 'package:lumina_app/theme/colores_app.dart';
import 'package:lumina_app/widgets/boton_principal.dart';
import 'package:lumina_app/widgets/campos_formulario.dart';
import 'package:lumina_app/widgets/decoracion_campo.dart';
import 'package:lumina_app/widgets/logo_lumina.dart';
import 'package:lumina_app/widgets/mensaje_error.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.mensaje});

  
  final String? mensaje;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final LoginService _loginService = LoginService();
  final TextEditingController _usuario = TextEditingController();
  final TextEditingController _clave = TextEditingController();

  bool _ocultarClave = true;
  bool _recordarSesion = true;
  bool _cargando = false;
  String? _errorUsuario;
  String? _errorClave;
  String? _errorServidor;

  @override
  void initState() {
    super.initState();
    _errorServidor = widget.mensaje;
  }

  @override
  void dispose() {
    _usuario.dispose();
    _clave.dispose();
    super.dispose();
  }

  Future<void> _iniciarSesion() async {
    FocusScope.of(context).unfocus();
    final errorUsuario = Auth.validarUsuario(_usuario.text);
    final errorClave = Auth.validarContrasena(_clave.text);
    setState(() {
      _errorUsuario = errorUsuario;
      _errorClave = errorClave;
      _errorServidor = null;
    });
    if (errorUsuario != null || errorClave != null) return;

    setState(() => _cargando = true);
    try {
      final sesion = await _loginService.login(
        LoginRequest(usuario: _usuario.text.trim(), clave: _clave.text),
      );
      CatalogoCache.invalidar();
      await GestorSesion.iniciar(sesion, recordar: _recordarSesion);
      await _resolverNombre();
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.inicio, (ruta) => false);
    } on ApiException catch (e) {
      if (mounted) setState(() => _errorServidor = e.message);
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  
  Future<void> _resolverNombre() async {
    final sesion = GestorSesion.actual;
    if (sesion == null || sesion.esGestor) return;
    try {
      final profesional = await ProfesionalService().porDocumento(sesion.username);
      if (profesional != null) {
        await GestorSesion.actualizarNombre(profesional.nombres.split(' ').first);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    return Scaffold(
      backgroundColor: c.superficie,
      body: Stack(
        children: [
          const Positioned(
            top: -20,
            right: -90,
            width: 280,
            child: RamaDecorativa(opacidad: 0.5),
          ),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Center(child: MonogramaLumina(tamano: 120)),
                      const SizedBox(height: 18),
                      Text(
                        'Iniciar sesión',
                        textAlign: TextAlign.center,
                        style: AppTheme.cormorant(size: 30, color: c.primarioOscuro),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Accede a tu panel administrativo',
                        textAlign: TextAlign.center,
                        style: AppTheme.manrope(size: 14, color: c.textoSutil),
                      ),
                      const SizedBox(height: 28),
                      if (_errorServidor != null) ...[
                        MensajeError(_errorServidor!),
                        const SizedBox(height: 16),
                      ],
                      const EtiquetaCampo('Usuario', obligatorio: true),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _usuario,
                        keyboardType: TextInputType.text,
                        textInputAction: TextInputAction.next,
                        style: AppTheme.manrope(size: 14, color: c.textoTitulo),
                        decoration: decoracionCampo(
                          context,
                          hint: 'Tu número de documento',
                          icono: Icons.person_outline,
                          error: _errorUsuario,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const EtiquetaCampo('Clave', obligatorio: true),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _clave,
                        obscureText: _ocultarClave,
                        onSubmitted: (_) => _iniciarSesion(),
                        style: AppTheme.manrope(size: 14, color: c.textoTitulo),
                        decoration: decoracionCampo(
                          context,
                          hint: '••••••••',
                          icono: Icons.lock_outline,
                          error: _errorClave,
                          sufijo: IconButton(
                            tooltip: _ocultarClave ? 'Mostrar clave' : 'Ocultar clave',
                            onPressed: () => setState(() => _ocultarClave = !_ocultarClave),
                            icon: Icon(
                              _ocultarClave
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: c.textoSecundario,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Checkbox(
                            value: _recordarSesion,
                            activeColor: AppColors.primario,
                            onChanged: (v) => setState(() => _recordarSesion = v ?? false),
                          ),
                          Expanded(
                            child: Text(
                              'Recordar sesión',
                              style: AppTheme.manrope(size: 13, color: c.textoGris),
                            ),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pushNamed(context, AppRoutes.recuperar),
                            child: Text(
                              '¿Olvidaste tu clave?',
                              style: AppTheme.manrope(
                                size: 13,
                                weight: FontWeight.w700,
                                color: c.primario,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      BotonPrincipal(
                        texto: 'Iniciar sesión',
                        alPresionar: _iniciarSesion,
                        cargando: _cargando,
                      ),
                      const SizedBox(height: 28),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.spa_outlined, size: 15, color: c.acento),
                          const SizedBox(width: 6),
                          Text(
                            'Lumina Beauty Center',
                            style: AppTheme.manrope(size: 12, color: c.textoSutil),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
