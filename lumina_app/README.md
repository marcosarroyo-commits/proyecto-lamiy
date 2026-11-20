# LUMINA · Beauty Center

Aplicación móvil en Flutter para la administración de un centro de belleza. Consume la API Ehily (`https://api.ehily.cecar.cloud`).

## Requisitos

- Flutter estable con Dart `^3.13.4`
- Android Studio o VS Code con un emulador o un dispositivo físico

## Ejecución

```bash
flutter pub get
flutter run
```

Para apuntar a otra instancia de la API:

```bash
flutter run --dart-define=API_BASE_URL=https://mi-servidor.com
```

Generar el instalador de Android:

```bash
flutter build apk --release
```

## Roles

| Rol | Acceso |
|---|---|
| Gestor | Panel administrativo completo: catálogo, equipo, agenda, reservas, cierres y comisiones. |
| Profesional | Inicio con sus citas del día, "Mis servicios" (servicios del periodo y comisiones liquidadas) y "Mi agenda" en solo lectura. |

El rol se lee del JWT que devuelve `POST /api/sesion`.

## Módulos

- **Acceso:** splash con validación de sesión, inicio de sesión con "Recordar sesión", recuperación de contraseña con OTP y cierre de sesión.
- **Dashboard:** saludo, métricas del día, accesos a todos los módulos y próximas citas.
- **Especialidades:** listado con búsqueda y filtro de estado, registro, edición, activación/inactivación y eliminación con confirmación.
- **Servicios:** listado por especialidad y estado, registro, detalle y edición (descripción y especialidad solo al crear).
- **Clientes:** listado con búsqueda, registro con documento único, detalle con historial de reservas y edición.
- **Profesionales:** listado, registro, detalle con horario, inasistencias y comisiones, edición e inactivación.
- **Horarios:** jornada por día con almuerzo, registro de varios días a la vez (masivo), edición y eliminación.
- **Inasistencias:** registro por rango de fechas sin cruces; bloquean la agenda del profesional.
- **Agenda:** vista de lista y de calendario, rango de fechas, filtros por cliente, servicio, profesional y estado, y disponibilidad del día.
- **Reservas:** flujo en pasos (cliente → servicio → profesional y horario → confirmación con medio de pago), cliente de primera vez, detalle, reagendar, marcar atendida y cancelar con motivo.
- **Cierres:** listado por año y mes, nuevo cierre con validación del periodo, resumen previo y detalle.
- **Comisiones:** consolidado por cierre y profesional, y detalle de los servicios que componen cada comisión.
- **Mi cuenta (profesional):** citas de hoy, servicios del periodo y comisión estimada.

## Cobertura de la API

| Recurso | Endpoints | Dónde se usa |
|---|---|---|
| sesion | `POST` | Inicio de sesión |
| especialidades | `GET`, `GET/{id}`, `POST`, `PUT/{id}`, `DELETE/{id}` | Especialidades |
| servicios | `GET`, `GET/{id}`, `POST`, `PUT/{id}`, `DELETE/{id}` | Servicios, flujo de reserva |
| clientes | `GET`, `GET/{documento}`, `POST`, `PUT/{id}`, `DELETE/{id}` | Clientes, selector de cliente |
| profesionales | `GET`, `GET/{id}`, `GET/{documento}`, `GET/{especialidad}/especialiades`, `POST`, `PUT/{id}`, `DELETE/{id}` | Profesionales, selector de profesional, rol profesional |
| horarios-laboral | `GET`, `GET/{id}`, `GET/profesional/{id}`, `POST`, `POST/masivo`, `PUT/{id}`, `DELETE/{id}` | Horarios |
| agenda | `GET ?fecha&servicioId[&profesionalId]`, `GET/{fecha}` | Crear y reagendar reservas, disponibilidad del día |
| reservas | `GET`, `GET ?fechaInicio&fechaFin`, `GET/{id}`, `POST` (cliente registrado y primera vez con `X-Empresa-Id`), `PUT/{id}`, `DELETE/{id}` | Agenda, reservas, dashboard, cierres |
| liquidaciones-comisiones | `GET`, `GET ?ultimo`, `POST` | Cierres |
| comisiones | `GET ?cierreId`, `GET ?profesionalId`, `GET/{id}/servicios` | Comisiones, Mis servicios |

## Estados de interfaz

Cada módulo maneja carga, sin resultados (con acción para limpiar filtros o registrar), error con reintento, éxito, confirmación antes de las acciones sensibles y sesión no válida (un 401 limpia las credenciales y regresa al login).

## Estructura

```
lib/
├── config/        Configuración de la API
├── domain/        Tema, fechas, formatos, validaciones y reglas de negocio
├── models/        Modelos por recurso de la API
├── routes/        Rutas con nombre y navegación
├── screens/       Pantallas organizadas por módulo
├── services/
│   ├── local/       Sesión, preferencias, caché de catálogos y datos locales
│   └── remote/      Clientes HTTP por recurso
├── theme/         Paleta clara y oscura
└── widgets/       Componentes reutilizables
```

## Notas

- La recuperación de contraseña funciona en modo demostración, porque la API no expone ese servicio. El código de prueba es `123456`.
- Las inasistencias, el medio de pago y el motivo de cancelación se guardan también en el dispositivo, porque la API no tiene campos para ellos.
- "Marcar atendida" envía `PUT /api/reservas/{id}` con el estado; si la API lo ignora, queda marcado localmente.
- La API devuelve listas completas (sin paginación), así que la búsqueda y los filtros se aplican en la app.
- Los modelos aceptan varios nombres por campo (`Json.valor`). Si un dato no aparece, revisa la respuesta en Bruno y agrega el nombre en el `fromJson` del modelo.
