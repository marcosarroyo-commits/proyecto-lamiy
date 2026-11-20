import 'package:flutter/material.dart';
import 'package:lumina_app/domain/app_theme.dart';
import 'package:lumina_app/domain/fechas.dart';
import 'package:lumina_app/domain/formatos.dart';
import 'package:lumina_app/models/inasistencia/inasistencia.dart';
import 'package:lumina_app/models/profesional/profesional.dart';
import 'package:lumina_app/routes/app_routes.dart';
import 'package:lumina_app/screens/comisiones/listado_comisiones_screen.dart';
import 'package:lumina_app/screens/horarios/horario_profesional_screen.dart';
import 'package:lumina_app/screens/inasistencias/formulario_inasistencia_screen.dart';
import 'package:lumina_app/screens/profesionales/formulario_profesional_screen.dart';
import 'package:lumina_app/services/local/catalogo_cache.dart';
import 'package:lumina_app/services/local/inasistencia_local_service.dart';
import 'package:lumina_app/services/remote/api_service.dart';
import 'package:lumina_app/services/remote/profesional_service.dart';
import 'package:lumina_app/theme/colores_app.dart';
import 'package:lumina_app/widgets/barra_acciones.dart';
import 'package:lumina_app/widgets/chip_estado.dart';
import 'package:lumina_app/widgets/dialogos.dart';
import 'package:lumina_app/widgets/encabezado_modulo.dart';
import 'package:lumina_app/widgets/marco_pantalla.dart';
import 'package:lumina_app/widgets/seccion_detalle.dart';
import 'package:lumina_app/widgets/tarjeta_base.dart';

class DetalleProfesionalScreen extends StatefulWidget {
  const DetalleProfesionalScreen({super.key, required this.profesional});

  final Profesional profesional;

  @override
  State<DetalleProfesionalScreen> createState() => _DetalleProfesionalScreenState();
}

class _DetalleProfesionalScreenState extends State<DetalleProfesionalScreen> {
  final ProfesionalService _servicio = ProfesionalService();
  late Profesional _p = widget.profesional;
  List<Inasistencia> _ausencias = const [];
  bool _procesando = false;

  @override
  void initState() {
    super.initState();
    _refrescar();
  }

  Future<void> _refrescar() async {
    try {
      final actual = await _servicio.obtenerPorId(_p.id);
      if (mounted) setState(() => _p = actual);
    } on ApiException catch (_) {}
    final hoy = Fechas.hoy;
    final ausencias = (await InasistenciaLocalService().todas(profesionalId: _p.id))
        .where((i) => !i.fechaFin.isBefore(hoy))
        .toList();
    if (mounted) setState(() => _ausencias = ausencias);
  }

  Future<void> _editar() async {
    final guardado = await abrir<bool>(context, FormularioProfesionalScreen(profesional: _p));
    if (guardado == true && mounted) _refrescar();
  }

  Future<void> _cambiarEstado() async {
    final activar = !_p.activo;
    final confirmado = await confirmarAccion(
      context,
      titulo: activar ? 'Activar profesional' : 'Inactivar profesional',
      mensaje: activar
          ? '${_p.nombreCompleto} volverá a recibir reservas.'
          : '${_p.nombreCompleto} dejará de aparecer al crear reservas.',
      textoConfirmar: activar ? 'Activar' : 'Inactivar',
      peligrosa: !activar,
      icono: activar ? Icons.play_circle_outline : Icons.pause_circle_outline,
    );
    if (!confirmado || !mounted) return;
    setState(() => _procesando = true);
    try {
      await _servicio.editar(
        _p.id,
        nombres: _p.nombres,
        apellidos: _p.apellidos ?? '',
        fechaNacimiento: _p.fechaNacimiento,
        porcentaje: _p.porcentaje,
        estado: activar,
      );
      if (!mounted) return;
      mostrarExito(context, activar ? 'Profesional activado.' : 'Profesional inactivado.');
      await _refrescar();
    } on ApiException catch (e) {
      if (mounted) mostrarError(context, e.message);
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }

  Future<void> _eliminar() async {
    final confirmado = await confirmarAccion(
      context,
      titulo: 'Eliminar profesional',
      mensaje: 'Si tiene reservas o comisiones, es mejor inactivarlo para conservar el historial.',
      textoConfirmar: 'Eliminar',
      peligrosa: true,
      icono: Icons.person_remove_outlined,
    );
    if (!confirmado || !mounted) return;
    setState(() => _procesando = true);
    try {
      await _servicio.borrar(_p.id);
      if (!mounted) return;
      mostrarExito(context, 'Profesional eliminado.');
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (mounted) mostrarError(context, e.message);
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    final especialidad = _p.especialidadNombre ??
        CatalogoCache.especialidad(_p.especialidadId)?.nombre ??
        'Sin especialidad';
    return Scaffold(
      backgroundColor: c.fondo,
      appBar: EncabezadoModulo(
        titulo: 'Profesional',
        subtitulo: _p.nombreCompleto,
        acciones: [AccionEncabezado(icono: Icons.edit_outlined, tooltip: 'Editar', alPresionar: _editar)],
      ),
      body: ContenidoCentrado(
        child: RefreshIndicator(
          onRefresh: _refrescar,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              TarjetaBase(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    AvatarIniciales(texto: Formato.iniciales(_p.nombreCompleto), tamano: 68),
                    const SizedBox(height: 10),
                    Text(_p.nombreCompleto, style: AppTheme.cormorant(size: 20, color: c.textoOscuro)),
                    Text(especialidad, style: AppTheme.manrope(size: 13, color: c.textoSutil)),
                    const SizedBox(height: 8),
                    ChipEstado.activo(_p.activo),
                  ],
                ),
              ),
              if (_ausencias.isNotEmpty) ...[
                const SizedBox(height: 12),
                Aviso(
                  titulo: _ausencias.first.cubre(DateTime.now())
                      ? 'Ausente hoy · ${_ausencias.first.motivo}'
                      : 'Inasistencia próxima · ${_ausencias.first.motivo}',
                  mensaje: _ausencias.first.unDia
                      ? Fechas.fechaLarga(_ausencias.first.fechaInicio)
                      : '${Fechas.corta(_ausencias.first.fechaInicio)} al ${Fechas.corta(_ausencias.first.fechaFin)}',
                  tono: TonoEstado.alerta,
                ),
              ],
              const SizedBox(height: 16),
              SeccionDetalle(
                titulo: 'Información',
                icono: Icons.badge_outlined,
                children: [
                  GrillaDatos(datos: [
                    FilaDato(etiqueta: 'ID', valor: '${_p.id}'),
                    FilaDato(etiqueta: 'Documento', valor: _p.documento),
                    FilaDato(etiqueta: 'Comisión', valor: Formato.porcentaje(_p.porcentaje), destacado: true),
                    FilaDato(etiqueta: 'Nacimiento', valor: Fechas.corta(_p.fechaNacimiento)),
                  ]),
                ],
              ),
              const SizedBox(height: 16),
              SeccionDetalle(
                titulo: 'Gestión',
                icono: Icons.tune,
                children: [
                  _Opcion(
                    icono: Icons.schedule,
                    texto: 'Horario semanal',
                    detalle: 'Consultar y editar jornadas',
                    alTocar: () => abrir(context, HorarioProfesionalScreen(profesional: _p)),
                  ),
                  _Opcion(
                    icono: Icons.event_busy_outlined,
                    texto: 'Registrar inasistencia',
                    detalle: 'Por un día o un rango de fechas',
                    alTocar: () async {
                      await abrir(context, FormularioInasistenciaScreen(profesional: _p));
                      if (mounted) _refrescar();
                    },
                  ),
                  _Opcion(
                    icono: Icons.percent,
                    texto: 'Comisiones',
                    detalle: 'Consolidado por cierre',
                    alTocar: () => abrir(context, ListadoComisionesScreen(profesionalInicial: _p)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: PieAcciones(
        children: [
          BotonSecundario(
            texto: _p.activo ? 'Inactivar' : 'Activar',
            icono: _p.activo ? Icons.pause_circle_outline : Icons.play_circle_outline,
            peligro: _p.activo,
            alPresionar: _procesando ? null : _cambiarEstado,
          ),
          BotonSecundario(
            texto: 'Eliminar',
            icono: Icons.delete_outline,
            peligro: true,
            alPresionar: _procesando ? null : _eliminar,
          ),
        ],
      ),
    );
  }
}

class _Opcion extends StatelessWidget {
  const _Opcion({required this.icono, required this.texto, required this.detalle, required this.alTocar});

  final IconData icono;
  final String texto;
  final String detalle;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    return InkWell(
      onTap: alTocar,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(color: c.fondo, borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            Icon(icono, color: c.primario, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(texto, style: AppTheme.manrope(size: 14, weight: FontWeight.w700, color: c.textoOscuro)),
                  Text(detalle, style: AppTheme.manrope(size: 12, color: c.textoSutil)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: c.textoSutil),
          ],
        ),
      ),
    );
  }
}
