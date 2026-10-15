# Arquitectura vigente de Cita Suite

Este es el punto de entrada vigente. La [auditoría estructural](../audits/2026-10-15-maintainability-and-growth.md) identifica deuda conocida; la [hoja de ruta revisada](../audits/2026-10-15-architecture-proposal-review.md) define la campaña de cierre. Esta página describe lo implementado, no da por ejecutados los pasos 2 a 7.

## Aplicaciones y límites

| Parte | Responsabilidad actual | Fuera de su responsabilidad |
|---|---|---|
| `apps/web` | Panel del consultorio en Cloudflare Workers, reservas públicas, gestión del turno, pacientes, integraciones y endpoints de tareas | Contenido editorial de Natalia |
| `apps/natalia` | Sitio Astro estático en Vercel, contenido público y enlaces nativos al turnero configurado | Crear una agenda propia, guardar reservas o registrar suscripciones push |
| `packages/shared` | Contrato declarativo de integración, helpers y tipos de base generados | Autorizar operaciones por su mera presencia en el navegador |
| `supabase/migrations` | Historia aplicada del esquema, funciones, RLS, restricciones y tareas SQL | Describir por sí sola el estado remoto actual |
| `supabase/tests` | Contratos SQL y pruebas especializadas de concurrencia | Certificar rendimiento de producción por correr en un contenedor local |

El módulo histórico `/administrativo` no es la aplicación operativa: la entrada actual dirige a `/odonto/agenda`. No eliminarlo ni considerarlo una capacidad nueva de esta campaña sin revisar sus contratos.

## Reserva pública e integración con Natalia

1. Natalia abre, en la misma pestaña, `/embed/v1/[integrationKey]` de Cita Suite. El nombre de esa ruta es histórico y permite también uso como página completa.
2. `booking-integration-request.ts` resuelve integración, negocio y alcance; valida el contexto de marco cuando efectivamente existe. No se toma del navegador un negocio arbitrario.
3. `public-booking-page.ts` y `PublicBookingFlow.svelte` sirven los recorridos públicos. Los lectores de disponibilidad alimentan el calculador TS compartido; no hay dos agendas ni dos generadores independientes por marca.
4. La creación llama a operaciones SQL transaccionales de identidad/reserva, con revisiones, idempotencia y protección de ocupación temporal.
5. El recorrido nativo confirma o recupera en `/turno/[token]`, que contiene gestión, información y las funciones de calendario/notificaciones existentes.
6. La apariencia se conserva mediante el contexto histórico de la reserva. Natalia transmite el modo claro/oscuro visible; Cita Suite guarda la preferencia visual propia. No decide el modo con la preferencia del sistema.

El SDK v1 continúa como compatibilidad para sitios que realmente usan un marco. `parent_origin` e `instance_id` identifican ese contexto; no se debe inferirlo sólo por el nombre `/embed` o por `entry_point=embedded`. El tema no debe convertirse en una regla de autorización o de negocio.

## Inventario funcional por responsabilidad

La existencia de código no prueba activación en un consultorio real. La columna de pruebas identifica dónde verificar comportamiento y límites; el recibo de cada ejecución determina qué se probó efectivamente.

| Responsabilidad | Entradas y núcleo actuales | Pruebas disponibles y límite de la baseline |
|---|---|---|
| Agenda y reserva manual | `/odonto/agenda`, `/odonto/turnos`, `ManualAppointmentWizard`, `appointments.ts`, `availability.ts` | Suites de servidor/componentes y contratos SQL de turnos; los E2E privados completos requieren sus propios fixtures/credenciales locales |
| Reserva pública | `/reservar`, `/embed/v1`, `public-booking-page.ts`, `PublicBookingFlow.svelte` | Suites públicas y SDK, contratos SQL y creación/recuperación real con fixtures sintéticos en navegador |
| Gestión del turno | `/turno`, rutas de confirmar/cancelar/reprogramar e información | Estados de componentes, handlers y recorrido nativo; entrega física de push no certificada |
| Identidad y ficha clínica | `/odonto/pacientes`, `patient-identity.ts`, `patient-permissions.ts`, `patient-list.ts` | Servidor, componentes, contratos de identidad, procedencia clínica, permisos y paginación |
| Documentos | `clinical-files.ts`, `clinical-documents.ts`, rutas privadas/públicas de archivos y `clinical_storage_budget` | Contratos de validación y SQL; el servidor real de Storage y transferencia HTTP tienen comprobación especializada separada |
| Exportaciones | `/odonto/exportar-datos`, `/api/odonto/exportaciones`, `patient-exports.ts`, `lib/patient-export` | Suites de exportación y contratos SQL; scripts de concurrencia específicos separados |
| Profesionales, prestaciones y horarios | `/odonto/profesionales`, `/odonto/servicios`, `professional-services.ts`, `availability-rules.ts`, `availability-exceptions.ts` | Validación de reglas y bloques, componentes y contratos de restricciones |
| Aranceles | `PricePolicyEditor.svelte`, `booking/pricing.ts`, RPC y funciones de políticas/cotización | Previsualización TS y cálculo SQL actuales; la unificación del calculador pertenece al paso 4 |
| Formularios | `/odonto/mis-preguntas`, `ProfessionalBookingFormEditor`, `booking-information.ts`, contrato compartido | Validación, componentes y SQL de respuestas, contexto y datos del paciente |
| Sitios e información pública | `/odonto/configuracion/reserva-online`, `booking-integrations.ts`, contacto público | Configuración, selección, privacidad, SDK y once escenarios interceptados de Natalia |
| Acceso y suscripción | Login/OAuth, `hooks.server.ts`, `business.ts`, `odonto-context.ts`, `commercial-access.ts`, Mercado Pago | Suites de acceso/comercial, webhook y contratos de roles; OAuth real y cobros externos no se ejecutan en la baseline |
| Tareas y proveedores | `/internal/jobs`, `push.ts`, `google-calendar.ts`, `google-reviews.ts` | Pruebas de handlers/estado y contratos SQL; no prueban recepción física ni capacidad de colas con 25 consultorios |
| Superficies heredadas | Administración y mensajería histórica | Inventariadas para evitar eliminaciones o activaciones accidentales; no se habilitan como parte de esta campaña |
| Contenido de Natalia | Portada y destinos públicos de Astro | Contrato de fidelidad y navegador; cursos y noticias permanecen fuera de implementación funcional actual |

## Propiedad de reglas y contratos

| Regla o dato | Autoridad actual | Consumidores que hay que revisar al modificarla |
|---|---|---|
| Consultorio activo, rol y acceso comercial | Sesión, resolución de negocio, políticas/RPC de base | Layout, rutas/acciones, descargas, exportación y operaciones privilegiadas |
| Identidad del paciente y resolución de coincidencias | Funciones SQL de creación/actualización y restricciones | Alta manual, reserva pública, ficha y reasignación |
| Ocupación temporal e idempotencia | Transacción SQL, exclusión por profesional y clave de solicitud | Manual/público, turnos conjuntos, reintentos, recuperación y reprogramación |
| Opciones de horario visibles | Calculador TS común sobre filas/snapshots autorizados | Manual, público, integrado, consulta de disponibilidad y cliente interno |
| Fotografía histórica de precio | Política/cotización y trigger/funciones SQL | Editor, preview TS existente, reserva, confirmación y gestión |
| Preguntas y respuestas históricas | Definiciones versionadas y funciones SQL de información | Configurador, formulario público, perfil e información posterior |
| Presupuesto de archivos | Contador global, reservas de carga y triggers SQL | URLs firmadas, almacenamiento, finalización, fallos, papelera y limpieza |
| Estado de trabajos externos | Colas/reclamaciones SQL y adaptadores del proveedor | Cancelación/reprogramación, reintentos, cron, callbacks y páginas de estado |
| Integración externa | `booking-integration.ts`, SDK y resolución por petición | Sitios, rutas públicas, validación de alcance, estados históricos y compatibilidad v1 |
| Presentación | Componentes, CSS y `BookingAppearance` | Modos visuales, menús flotantes, navegación nativa y marcos heredados |

Los tipos generados siguen la forma SQL, pero un resultado `Json` no especifica su documento interno. En el paso 2, los retornos tabulares se evaluarán para `RETURNS TABLE`; los documentos legítimamente anidados deben validarse en su adaptador y tener pruebas de contrato. No cambiar retornos, privilegios o firmas de RPC durante el inventario.

## Evidencia reproducible y límites

Ejecutar `pnpm inventory:architecture` para obtener rutas, grupos orientativos, referencias explícitas de contexto, pruebas, tamaños y huellas de fuente. Para guardar JSON sin el encabezado de pnpm: `pnpm --silent inventory:architecture > /tmp/cita-inventory.json`. La clasificación de rutas no demuestra autorización ni cobertura.

Ejecutar `pnpm verify:baseline` para la verificación secuencial documentada en [baseline local](baseline.md). Genera fuera del repositorio un inventario de fuentes, recibo por etapa y contrato efectivo de funciones/tablas de una base reconstruida. Esa base representa las migraciones locales, no una inspección de producción.

La baseline no ejecuta los 14 specs E2E privados de manera indiscriminada: algunos usan credenciales reales o fixtures destructivos. Tampoco ejecuta los scripts shell de intercalado concurrente, OAuth real, pagos reales ni entrega de notificaciones. Estas comprobaciones se deben incorporar al alcance correspondiente con fixtures aislados y un recibo propio; no se cuentan como aprobadas por omisión.

## Observación registrada para la separación de loaders

En el desarrollo local del recorrido nativo, SvelteKit emite una advertencia de `event.fetch` usado por un manejador de promesa después de terminar el `load` que lo creó, señalando el layout de integración. Las reservas y la recuperación completan el recorrido, pero se debe comprobar por separado el seguimiento de dependencias e invalidación. El recibo guarda la advertencia y su cantidad; no se suprime ni se presenta como un incidente confirmado en producción. El propietario de su investigación es el paso 4, junto a los límites de contexto por petición/loader.
