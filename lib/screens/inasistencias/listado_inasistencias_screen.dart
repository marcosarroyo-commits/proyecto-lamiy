import 'package:flutter/material.dart';
import 'package:lumina_app/domain/app_theme.dart';
import 'package:lumina_app/domain/fechas.dart';
import 'package:lumina_app/models/comun/pagina.dart';
import 'package:lumina_app/models/inasistencia/inasistencia.dart';
import 'package:lumina_app/routes/app_routes.dart';
import 'package:lumina_app/screens/inasistencias/formulario_inasistencia_screen.dart';
import 'package:lumina_app/services/local/inasistencia_local_service.dart';
import 'package:lumina_app/theme/colores_app.dart';
import 'package:lumina_app/widgets/chip_estado.dart';
import 'package:lumina_app/widgets/dialogos.dart';
import 'package:lumina_app/widgets/encabezado_modulo.dart';
import 'package:lumina_app/widgets/estados_vista.dart';
import 'package:lumina_app/widgets/filtros.dart';
import 'package:lumina_app/widgets/tarjeta_base.dart';
import 'package:lumina_app/widgets/vista_paginada.dart';

class ListadoInasistenciasScreen extends StatefulWidget {
  const ListadoInasistenciasScreen({super.key});

  @override
  State<ListadoInasistenciasScreen> createState() => _ListadoInasistenciasScreenState();
}

class _ListadoInasistenciasScreenState extends State<ListadoInasistenciasScreen> {
  final InasistenciaLocalService _servicio = InasistenciaLocalService();
  late final ControladorPaginado<Inasistencia> _controlador = ControladorPaginado(_cargar);
  bool _proximas = true;

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

  Future<Pagina<Inasistencia>> _cargar(int pagina) => _servicio.listar(proximas: _proximas);

  Future<void> _abrirFormulario([Inasistencia? inasistencia]) async {
    final guardado = await abrir<bool>(context, FormularioInasistenciaScreen(inasistencia: inasistencia));
    if (guardado == true && mounted) _controlador.recargar();
  }

  Future<void> _eliminar(Inasistencia i) async {
    final confirmado = await confirmarAccion(
      context,
      titulo: 'Eliminar inasistencia',
      mensaje: '${i.profesionalNombre} volverá a estar disponible en esas fechas.',
      textoConfirmar: 'Eliminar',
      peligrosa: true,
      icono: Icons.delete_outline,
    );
    if (!confirmado || !mounted) return;
    await _servicio.eliminar(i.id);
    if (!mounted) return;
    mostrarExito(context, 'Inasistencia eliminada.');
    _controlador.recargar();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    return Scaffold(
      backgroundColor: c.fondo,
      appBar: EncabezadoModulo(
        titulo: 'Inasistencias',
        subtitulo: 'Ausencias del equipo por día o rango',
        acciones: [
          AccionEncabezado(icono: Icons.add, tooltip: 'Nueva inasistencia', alPresionar: _abrirFormulario),
        ],
      ),
      body: PantallaLista(
        filtros: Align(
          alignment: Alignment.centerLeft,
          child: BarraFiltros<bool>(
            seleccionado: _proximas,
            alCambiar: (valor) {
              setState(() => _proximas = valor);
              _controlador.recargar();
            },
            opciones: const [OpcionFiltro(true, 'Próximas'), OpcionFiltro(false, 'Historial')],
          ),
        ),
        lista: VistaPaginada<Inasistencia>(
          controlador: _controlador,
          constructor: (context, i) {
            final hoy = i.cubre(DateTime.now());
            return Opacity(
              opacity: _proximas ? 1 : 0.75,
              child: TarjetaBase(
                alTocar: () => _abrirFormulario(i),
                child: Row(
                  children: [
                    IconoCaja(
                      icono: Icons.event_busy_outlined,
                      color: hoy ? AppColors.rojoAlerta : AppColors.ambar,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(i.profesionalNombre, style: AppTheme.cormorant(size: 16, color: c.textoOscuro)),
                          Text(
                            i.unDia
                                ? Fechas.fechaLarga(i.fechaInicio)
                                : '${Fechas.corta(i.fechaInicio)} al ${Fechas.corta(i.fechaFin)} · ${i.dias} días',
                            style: AppTheme.manrope(size: 12.5, color: c.textoGris),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              ChipEstado(texto: i.motivo, tono: TonoEstado.alerta),
                              if (hoy) ...[
                                const SizedBox(width: 6),
                                const ChipEstado(texto: 'Hoy', tono: TonoEstado.peligro, icono: Icons.today),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Eliminar',
                      onPressed: () => _eliminar(i),
                      icon: const Icon(Icons.delete_outline, color: AppColors.rojoAlerta),
                    ),
                  ],
                ),
              ),
            );
          },
          vacio: EstadoVacio(
            icono: Icons.event_available_outlined,
            titulo: _proximas ? 'Sin inasistencias próximas' : 'Sin historial',
            mensaje: 'Registra ausencias por un día o por un rango de fechas '
                '(salud, situación familiar u otra causa).',
            textoAccion: 'Registrar inasistencia',
            alAccion: _abrirFormulario,
          ),
        ),
      ),
    );
  }
}
