# Natalia abre el turnero completo de Cita Suite

## Contrato

Reservar desde Natalia debe abrir la misma aplicación de Cita Suite que abre el enlace compartido del consultorio. La identidad visual puede ser Natalia; las funciones, validaciones, persistencia y gestión del turno pertenecen a Cita Suite.

## Implementación

- Los enlaces existentes de `BookingLink.astro` ya apuntaban al enlace público configurado; se eliminó la interceptación que los convertía en un modal del SDK. Ahora navegan en la misma pestaña y funcionan sin JavaScript. Las tarjetas del catálogo mantienen `service_id`.
- `/turnos` sólo redirige al mismo destino, con `meta refresh` de cero segundos y una salida visible en español con el estilo público. No solicita una reserva ni recoge datos.
- La ruta pública por clave conserva `PublicBookingFlow`, `loadPublicBookingPage` y `submitPublicBookingPage`. Sin contexto de marco, usa los pasos completos; el tema Natalia deja de activar el salto de profesional y el contador compacto en ese acceso.
- Confirmar o recuperar una reserva sin marco conduce directamente a `/turno/[token]`, que ya implementa información, calendario, recordatorios, cancelación y solicitud de reprogramación. Se conserva el tema histórico de la reserva.
- Los enlaces antiguos de confirmación integrada también conducen a esa gestión cuando se abren fuera de un marco, después de validar la integración y el token. El SDK v1 y su confirmación dentro de un marco mantienen su contrato para otras webs.

La clave configurada, filtros de profesionales y prestaciones, modalidad, revisión, cuestionario, cotización e idempotencia se conservan. No se cambia la configuración real del consultorio ni se agregan esquemas, migraciones, service workers o sistemas de notificaciones a Natalia. El valor histórico `entry_point=embedded` identifica el canal de integración v1 y continúa sin cambios de base; el contexto de marco validado distingue cómo se presenta y dónde termina la navegación.

## Verificación

- 72 pruebas focalizadas: configuración y privacidad, SDK, creación, recuperación, destino de confirmación y compatibilidad de enlaces anteriores. Incluyen siete regresiones nuevas de navegación con servicios simulados.
- 32 pruebas del componente de gestión del turno y sus estados de notificaciones, ejecutadas secuencialmente. No prueban entrega física de notificaciones.
- Base local descartable reconstruida con las 97 migraciones existentes y contratos SQL aprobados.
- `scripts/qa-natalia-direct-booking.mjs`: web estática real servida por HTTP, Cita Suite real local y PostgreSQL/PostgREST locales. En escritorio 1440×960 y móvil 390×844 se crearon dos reservas sintéticas, se comprobó el diseño histórico Natalia y el destino completo, y se recuperaron ambas sin duplicación. Auth es simulado; VAPID no está configurado en ese entorno. No se contacta producción.
- Ocho escenarios de Natalia con Cita Suite interceptado: apertura directa, selección del catálogo, contacto, datos ausentes o inválidos, navegación sin JavaScript y redirección de `/turnos` con y sin JavaScript. Ninguno puede cargar el SDK.

La evidencia local del flujo completo está en `/tmp/cita-direct-booking-qa/`. No contiene información real de pacientes. Browser gestionado no disponible en las herramientas activas; se usó Playwright instalado, Chromium y viewports emulados. Las capturas de escritorio y móvil se revisaron juntas. No constituye prueba sobre teléfono físico.

## Reproducción y publicación

Ejecutar las suites focalizadas de la auditoría anterior agregando `src/lib/server/public-booking-navigation.test.ts`. Para gestión: `pnpm --filter web test:client 'src/routes/turno/[token]/page.client.test.ts' --maxWorkers=1 --no-file-parallelism`. Ejecutar `pnpm --filter web check`, compilar Natalia con su origen y clave públicos y ejecutar `pnpm --filter natalia test:browser`.

Para el flujo real local: `node scripts/test-booking-foundation.mjs --keep`, iniciar `node scripts/serve-booking-fixture.mjs <contenedor_descartable>` y ejecutar `node scripts/qa-natalia-direct-booking.mjs`. El script exige loopback y clínica sintética; nunca imprimir el archivo de credenciales temporales. Detener el supervisor para limpiar procesos, base y credenciales.

Publicar primero Cita Suite por Git/Cloudflare, verificar su versión y después Natalia en el mismo proyecto Vercel. Comprobar en producción portada → enlace real → prestación → profesional → día → horario → formulario, sin enviar una reserva. Verificar origen de Cita Suite, ausencia de marcos y SDK, destino idéntico al enlace configurado y conservación de la prestación seleccionada. Guardar recibos por commit en `audit-evidence/`.

La entrega de push conserva las condiciones del turnero de Cita Suite: permiso del navegador, soporte del dispositivo y configuración del servicio. No se afirma que este cambio habilite iOS ni que una prueba local simule recepción física. El rollback no requiere operaciones de base; restaurar las versiones previas de ambas aplicaciones mantiene las reservas y los enlaces ya emitidos.
