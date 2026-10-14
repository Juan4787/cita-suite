# Rediseño de configuración de reservas — 14 de octubre de 2026

El problema era la mezcla de tareas en Reserva online: integración con webs, cuestionarios,
aranceles, servicios y horarios de profesionales aparecían juntos. La corrección cambia la
arquitectura y los flujos, conservando las configuraciones y contratos existentes.

| Tarea | Lugar principal |
| --- | --- |
| Compartir agenda, activar/pausar reservas, plazo, anticipación y cancelación | Configuración → Reserva online |
| Perfil, servicios/aranceles y horarios | Equipo → profesional |
| Datos que el paciente debe responder | Equipo → profesional → Preguntas al paciente |
| Ajustes mensuales de aranceles | Profesional → Servicios y aranceles → Configurar aranceles |
| Integrar una web | Reserva online → Administrar sitios |
| Permisos de carga y consumo de archivos | Configuración → Archivos de pacientes |
| Contacto público | Datos del consultorio → Contacto en tu web |

## Cambios

- Un enlace general listo para compartir reemplaza la hilera de accesos a profesionales.
  Las conexiones externas son opcionales, con direcciones web individuales y opciones plegadas.
- Los cuestionarios se editan para el profesional abierto. Datos habituales conservan su
  correspondencia automática con la ficha; las preguntas adicionales admiten tipos y opciones.
  No se pide elegir un destino de almacenamiento ni un «profesional del formulario».
- Indicaciones de consulta y texto del aviso se editan junto al servicio. «Arancel a mostrar»
  reemplaza lenguaje sobre políticas internas. La dirección personalizada del consultorio
  queda en una opción secundaria: `/reservar/<slug>` redirige a la dirección canónica con ID.
- Selectores, calendarios de fechas/meses, casillas, radios, diálogos de descarte, foco,
  selección de texto, barras de desplazamiento y estados comparten el sistema visual.
  Los originales nativos se conservan ocultos para valores y validación del formulario;
  los menús visibles usan la capa superior y no se recortan dentro de un modal.
- Sin JavaScript se mantiene el formulario básico progresivo con controles del navegador
  estilizados. El aviso al recargar/cerrar la pestaña permanece bajo control del navegador.
  La entrega no reemplaza todos los selectores de rutas ajenas al ámbito de reservas.
- Los sitios activos conservan listas explícitas de profesionales/servicios según el contrato
  actual. «Todo el equipo actual» refiere al catálogo actual: incorporar otro profesional
  requiere revisar esa conexión. El enlace general del consultorio utiliza el equipo vigente.

## Auditoría y defectos corregidos

La revisión independiente de Impeccable aprobó la arquitectura y pidió cuatro correcciones:
restaurar el borrador antes de navegar a otra configuración, plegar la dirección personalizada,
simplificar el arancel y anunciar la fecha seleccionada a lectores de pantalla. Todas quedaron
resueltas. La última también se verificó tras mutar `min` y `disabled`: la sincronización común
conserva etiqueta y valor. El veredicto final fue `ship` sobre las cuatro correcciones.

Además, se corrigieron el rechazo incorrecto de campos repetidos `service_ids`, el cierre del
calendario por desplazamiento, la pérdida del editor al escribir una pregunta nueva y un
selector que mostraba un valor inicial distinto del dato guardado. El modal compartido recibió
semántica de diálogo, contención de foco y restauración del foco al cerrar.

Las pruebas de guardado esperan la respuesta antes de consultar la base; un mensaje de éxito
anterior no se usa como comprobante de otro guardado. Se conserva el aviso de ayuda durante
asistencia activa; su invitación ordinaria no desplaza estas tareas de configuración.

## Verificación

- 66 pruebas de servidor focalizadas: validación, límites de formularios, duplicados,
  tenant/permisos, revisión y separación de cambios en contacto/documentos.
- 18 pruebas de cliente: formularios, controles, teclado, valores tras hidratación,
  descarte/cancelación de borradores, calendario y accesibilidad ante mutaciones.
- Comprobación Svelte/TypeScript y compilación Cloudflare, secuenciales.
- Base local desechable con las 97 migraciones existentes y 10 contratos SQL aprobados.
  La reserva pública E2E pasó contra PostgreSQL/PostgREST local, con Auth simulado.
- Auditoría Chromium secuencial con 16 comprobaciones, capturas de escritorio 1440 y celulares
  390/320, calendarios/menús abiertos y diálogo de cambios sin guardar. Comprueba copia real,
  guardados persistidos, claves/scopes, redirecciones, formularios sin JS, rol profesional y
  ausencia de desborde horizontal. Comprobación adicional del nombre accesible del mes.

Los [comprobantes](evidence/2026-10-14-reservation-ux/browser.json) y
[capturas](evidence/2026-10-14-reservation-ux/reservation-desktop.png) son **locales y sintéticos**.
La fixture carece de Realtime: se distinguen sus advertencias esperadas del resto de la consola.
No acreditan Auth real, Safari, lector de pantalla físico, producción clínica ni cargas de PDF.
El detector sólo advirtió Inter, fuente existente que se preservó deliberadamente.

## Repetición y mantenimiento

1. Ejecutar `node scripts/test-booking-foundation.mjs --keep`; usar sólo el contenedor
   desechable que imprime. No apuntar estos scripts a una base real.
2. Levantar `node scripts/serve-booking-fixture.mjs <contenedor>`; ese proceso crea el runtime
   protegido `/tmp/cita-booking-runtime.json` y limpia los recursos al detenerse.
3. Ejecutar `E2E_LOCAL_BOOKING_FIXTURE_PATH=/tmp/cita-booking-runtime.json node scripts/audit-reservation-settings.mjs`.
   Es Chromium local de un solo proceso; modifica únicamente datos sintéticos. Las capturas
   se generan en `.impeccable/review/reservation-settings`, fuera del historial clínico real.
4. Pruebas de cliente: `pnpm --filter web test:client src/lib/ui/confirm-action.client.test.ts
   src/lib/ui/styled-controls.client.test.ts src/lib/booking/ProfessionalBookingFormEditor.client.test.ts
   src/lib/booking/PublicBookingFlow.client.test.ts --maxWorkers=1 --no-file-parallelism`.
   Ejecutar cada comando por separado y secuencialmente; no sumar compilaciones concurrentes.
5. Usar roles visibles de los controles personalizados en E2E. Interactuar con la fuente
   oculta no acredita la interacción que realiza la persona. Verificar ID/revisión/borrador
   al cambiar de entidad, también al aceptar descartar y al cancelar.

[PRODUCT](../../apps/web/PRODUCT.md), [DESIGN](../../apps/web/DESIGN.md) y el brief de superficie
registran los límites. Esta entrega no modifica el esquema ni configura negocios reales.
Una reversión de código conserva los datos y las migraciones existentes; requiere recargar las
pestañas anteriores. Cursos, noticias y la configuración real pendiente de Natalia mantienen
su alcance anterior. La publicación se identifica por el commit y la versión servida; los
comprobantes posteriores se guardan localmente sin provocar otro despliegue documental.
