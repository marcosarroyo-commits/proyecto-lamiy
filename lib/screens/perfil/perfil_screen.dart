import 'package:flutter/material.dart';
import 'package:lumina_app/domain/app_theme.dart';
import 'package:lumina_app/domain/fechas.dart';
import 'package:lumina_app/domain/formatos.dart';
import 'package:lumina_app/config/app_config.dart';
import 'package:lumina_app/services/local/catalogo_cache.dart';
import 'package:lumina_app/routes/app_routes.dart';
import 'package:lumina_app/services/local/gestor_sesion.dart';
import 'package:lumina_app/theme/colores_app.dart';
import 'package:lumina_app/theme/preferencia_tema.dart';
import 'package:lumina_app/widgets/chip_estado.dart';
import 'package:lumina_app/widgets/dialogos.dart';
import 'package:lumina_app/widgets/encabezado_modulo.dart';
import 'package:lumina_app/widgets/marco_pantalla.dart';
import 'package:lumina_app/widgets/tarjeta_base.dart';

class PerfilScreen extends StatelessWidget {
  const PerfilScreen({super.key});

  Future<void> _cerrarSesion(BuildContext context) async {
    final confirmado = await confirmarAccion(
      context,
      titulo: 'Cerrar sesión',
      mensaje: 'Se eliminarán los datos de acceso guardados en este dispositivo.',
      textoConfirmar: 'Cerrar sesión',
      peligrosa: true,
      icono: Icons.logout,
    );
    if (!confirmado || !context.mounted) return;
    await GestorSesion.cerrar();
    CatalogoCache.invalidar();
    if (!context.mounted) return;
    Navigator.of(
      context,
      rootNavigator: true,
    ).pushNamedAndRemoveUntil(AppRoutes.login, (ruta) => false);
  }

  void _acercaDe(BuildContext context) {
    mostrarInformacion(
      context,
      titulo: AppConfig.nombreApp,
      icono: Icons.spa_outlined,
      contenido: Text(
        'Versión ${AppConfig.version}\n\n'
        'Aplicación administrativa para gestionar servicios, profesionales, '
        'clientes, reservas, agenda, cierres y comisiones del centro de belleza.\n\n'
        'API: ${AppConfig.apiBaseUrl}',
        textAlign: TextAlign.center,
        style: AppTheme.manrope(size: 13, color: context.colores.textoSecundario),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    final sesion = GestorSesion.actual;

    return Scaffold(
      backgroundColor: c.fondo,
      appBar: const EncabezadoModulo(
        titulo: 'Mi perfil',
        subtitulo: 'Cuenta y preferencias',
      ),
      body: ContenidoCentrado(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            TarjetaBase(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  AvatarIniciales(
                    texto: Formato.iniciales(sesion?.username ?? 'Usuario'),
                    tamano: 72,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    sesion?.nombreVisible ?? 'Usuario',
                    style: AppTheme.cormorant(
                      size: 18,
                      weight: FontWeight.w700,
                      color: c.textoOscuro,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ChipEstado(
                    texto: sesion?.rolLegible ?? 'Usuario',
                    tono: TonoEstado.info,
                    icono: Icons.verified_user_outlined,
                  ),
                  const SizedBox(height: 16),
                  Divider(height: 1, color: c.bordeTarjeta),
                  const SizedBox(height: 12),
                  _dato(
                    c,
                    Icons.storefront_outlined,
                    'Centro',
                    AppConfig.nombreApp,
                  ),
                  _dato(
                    c,
                    Icons.badge_outlined,
                    'Usuario',
                    sesion?.username ?? '—',
                  ),
                  if (sesion?.empresaId != null)
                    _dato(
                      c,
                      Icons.apartment_outlined,
                      'Empresa',
                      'N.° ${sesion!.empresaId}',
                    ),
                  if (sesion?.expira != null)
                    _dato(
                      c,
                      Icons.timer_outlined,
                      'Sesión válida hasta',
                      Fechas.fechaHora(sesion!.expira),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _tituloGrupo(c, 'Preferencias'),
            TarjetaBase(
              padding: EdgeInsets.zero,
              child: ValueListenableBuilder<ThemeMode>(
                valueListenable: PreferenciaTema.modo,
                builder: (context, modo, _) => SwitchListTile(
                  value: modo == ThemeMode.dark,
                  onChanged: PreferenciaTema.cambiar,
                  secondary: Icon(Icons.dark_mode_outlined, color: c.primario),
                  title: Text('Modo oscuro', style: _estiloOpcion(c)),
                  subtitle: Text(
                    'Reduce el brillo de la pantalla',
                    style: AppTheme.manrope(size: 12, color: c.textoSutil),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            _tituloGrupo(c, 'Información'),
            TarjetaBase(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _opcion(
                    c,
                    icono: Icons.info_outline,
                    texto: 'Acerca de la aplicación',
                    alTocar: () => _acercaDe(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 52,
              child: OutlinedButton.icon(
                onPressed: () => _cerrarSesion(context),
                icon: const Icon(Icons.logout),
                label: const Text('Cerrar sesión'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.rojoAlerta,
                  side: BorderSide(
                    color: AppColors.rojoAlerta.withValues(alpha: 0.4),
                  ),
                  backgroundColor: AppColors.rojoAlerta.withValues(alpha: 0.05),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: AppTheme.manrope(size: 15, weight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  TextStyle _estiloOpcion(ColoresApp c) =>
      AppTheme.manrope(size: 14, weight: FontWeight.w600, color: c.textoTitulo);

  Widget _tituloGrupo(ColoresApp c, String texto) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        texto.toUpperCase(),
        style: AppTheme.manrope(
          size: 11.5,
          weight: FontWeight.w700,
          color: c.textoSutil,
        ).copyWith(letterSpacing: 0.8),
      ),
    );
  }

  Widget _opcion(
    ColoresApp c, {
    required IconData icono,
    required String texto,
    required VoidCallback alTocar,
  }) {
    return ListTile(
      onTap: alTocar,
      leading: Icon(icono, color: c.primario),
      title: Text(texto, style: _estiloOpcion(c)),
      trailing: Icon(Icons.chevron_right, color: c.textoSutil),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }

  Widget _dato(ColoresApp c, IconData icono, String etiqueta, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icono, size: 18, color: c.textoSutil),
          const SizedBox(width: 10),
          Text(etiqueta, style: AppTheme.manrope(size: 13, color: c.textoSutil)),
          const Spacer(),
          Flexible(
            child: Text(
              valor,
              textAlign: TextAlign.end,
              style: AppTheme.manrope(
                size: 13,
                weight: FontWeight.w600,
                color: c.textoOscuro,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
