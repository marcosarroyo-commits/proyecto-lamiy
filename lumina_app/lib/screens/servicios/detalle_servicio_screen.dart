import 'package:flutter/material.dart';
import 'package:lumina_app/domain/app_theme.dart';
import 'package:lumina_app/domain/formatos.dart';
import 'package:lumina_app/models/servicio/servicio.dart';
import 'package:lumina_app/routes/app_routes.dart';
import 'package:lumina_app/screens/servicios/formulario_servicio_screen.dart';
import 'package:lumina_app/services/local/catalogo_cache.dart';
import 'package:lumina_app/services/remote/api_service.dart';
import 'package:lumina_app/services/remote/servicio_service.dart';
import 'package:lumina_app/theme/colores_app.dart';
import 'package:lumina_app/widgets/barra_acciones.dart';
import 'package:lumina_app/widgets/chip_estado.dart';
import 'package:lumina_app/widgets/dialogos.dart';
import 'package:lumina_app/widgets/encabezado_modulo.dart';
import 'package:lumina_app/widgets/marco_pantalla.dart';
import 'package:lumina_app/widgets/seccion_detalle.dart';
import 'package:lumina_app/widgets/tarjeta_base.dart';

class DetalleServicioScreen extends StatefulWidget {
  const DetalleServicioScreen({super.key, required this.servicio});

  final Servicio servicio;

  @override
  State<DetalleServicioScreen> createState() => _DetalleServicioScreenState();
}

class _DetalleServicioScreenState extends State<DetalleServicioScreen> {
  final ServicioService _servicio = ServicioService();
  late Servicio _s = widget.servicio;
  bool _procesando = false;

  @override
  void initState() {
    super.initState();
    _refrescar();
  }

  Future<void> _refrescar() async {
    try {
      final actual = await _servicio.obtenerPorId(_s.id);
      if (mounted) setState(() => _s = actual);
    } on ApiException catch (_) {}
  }

  Future<void> _editar() async {
    final guardado = await abrir<bool>(context, FormularioServicioScreen(servicio: _s));
    if (guardado == true && mounted) _refrescar();
  }

  Future<void> _cambiarEstado() async {
    final activar = !_s.activo;
    final confirmado = await confirmarAccion(
      context,
      titulo: activar ? 'Activar servicio' : 'Inactivar servicio',
      mensaje: activar
          ? '"${_s.nombre}" volverá a estar disponible para nuevas reservas.'
          : '"${_s.nombre}" dejará de aparecer al crear reservas. Las reservas existentes no cambian.',
      textoConfirmar: activar ? 'Activar' : 'Inactivar',
      peligrosa: !activar,
      icono: activar ? Icons.play_circle_outline : Icons.block,
    );
    if (!confirmado || !mounted) return;
    setState(() => _procesando = true);
    try {
      await _servicio.editar(_s.id,
          nombre: _s.nombre, precio: _s.precio, duracion: _s.duracion, activo: activar);
      if (!mounted) return;
      mostrarExito(context, activar ? 'Servicio activado.' : 'Servicio inactivado.');
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
      titulo: 'Eliminar servicio',
      mensaje: 'Si el servicio ya tiene reservas, es mejor inactivarlo para conservar el historial.',
      textoConfirmar: 'Eliminar',
      peligrosa: true,
      icono: Icons.delete_outline,
    );
    if (!confirmado || !mounted) return;
    setState(() => _procesando = true);
    try {
      await _servicio.borrar(_s.id);
      if (!mounted) return;
      mostrarExito(context, 'Servicio eliminado.');
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
    final especialidad = _s.especialidadNombre ??
        CatalogoCache.especialidad(_s.especialidadId)?.nombre ??
        'No disponible';
    return Scaffold(
      backgroundColor: c.fondo,
      appBar: EncabezadoModulo(
        titulo: 'Detalle del servicio',
        subtitulo: _s.codigo,
        acciones: [AccionEncabezado(icono: Icons.edit_outlined, tooltip: 'Editar', alPresionar: _editar)],
      ),
      body: ContenidoCentrado(
        child: RefreshIndicator(
          onRefresh: _refrescar,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              TarjetaBase(
                padding: const EdgeInsets.all(22),
                child: Column(
                  children: [
                    ChipEstado.activo(_s.activo, textoActivo: 'Servicio activo', textoInactivo: 'Servicio inactivo'),
                    const SizedBox(height: 12),
                    Text(_s.nombre,
                        textAlign: TextAlign.center,
                        style: AppTheme.cormorant(size: 22, color: c.textoOscuro)),
                    const SizedBox(height: 6),
                    Text(Formato.moneda(_s.precio),
                        style: AppTheme.cormorant(size: 30, weight: FontWeight.w800, color: c.primarioOscuro)),
                    Text(Formato.duracion(_s.duracion),
                        style: AppTheme.manrope(size: 13, color: c.textoSutil)),
                  ],
                ),
              ),
              if (!_s.activo) ...[
                const SizedBox(height: 12),
                const Aviso(
                  titulo: 'No disponible para reservas',
                  mensaje: 'Este servicio está inactivo y no aparece al crear reservas.',
                  tono: TonoEstado.neutro,
                ),
              ],
              const SizedBox(height: 16),
              SeccionDetalle(
                titulo: 'Información del servicio',
                icono: Icons.info_outline,
                children: [
                  FilaDato(icono: Icons.tag, etiqueta: 'Identificador', valor: '${_s.id} · ${_s.codigo}'),
                  FilaDato(icono: Icons.category_outlined, etiqueta: 'Especialidad', valor: especialidad),
                  FilaDato(
                    icono: Icons.notes,
                    etiqueta: 'Descripción',
                    valor: Formato.valorO(_s.descripcion, 'Sin descripción'),
                  ),
                  GrillaDatos(datos: [
                    FilaDato(etiqueta: 'Precio', valor: Formato.moneda(_s.precio), destacado: true),
                    FilaDato(etiqueta: 'Duración', valor: Formato.duracion(_s.duracion), destacado: true),
                  ]),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'La especialidad y la descripción se definen al crear el servicio y no se modifican.',
                style: AppTheme.manrope(size: 11.5, color: c.textoSutil),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: PieAcciones(
        children: [
          BotonSecundario(
            texto: _s.activo ? 'Inactivar' : 'Activar',
            icono: _s.activo ? Icons.block : Icons.play_circle_outline,
            peligro: _s.activo,
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
