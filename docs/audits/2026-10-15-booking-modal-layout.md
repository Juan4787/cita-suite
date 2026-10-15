# Modal de reservas: centrado, ancho y desplazamiento

## Fallo y causa reproducida

La comprobación anterior recorrió `/turnos`, que usa la agenda integrada, y no detectó el fallo del diálogo que se abre al reservar desde la portada de Natalia.

El reset público `* { margin: 0; padding: 0 }` eliminaba el margen automático del diálogo. El SDK no declaraba posición ni margen propios: a 1440px el modal comenzaba en x=0, con su centro desplazado 340px. En un móvil de 390px comenzaba también en x=0 y medía 352px: seguía activo el `max-width` predeterminado del navegador. El contenido interior no tenía desbordamiento horizontal en esa reproducción; medir sólo `scrollWidth` no detectaba el diálogo mal ubicado.

## Corrección

- El SDK declara posición fija, inset, margen automático y máximo de ancho propios. El modal conserva 760px de ancho máximo y separaciones simétricas de 16px, o 8px hasta 480px.
- El cálculo de altura usa el mismo espacio exterior definido en CSS y descuenta el encabezado y ambos bordes. La altura del iframe se vuelve a calcular al mostrarlo y al cambiar el viewport.
- El cierre permanece fuera del área que se desplaza. El iframe ocupa el ancho interior disponible y mantiene accesibles todos los campos y el botón final.
- La agenda integrada conserva el ancho del contenedor y la altura de su contenido; el contrato v1, origen, instancia, reintentos y recuperación permanecen vigentes.

No hay migraciones ni modificaciones de pacientes, reservas, prestaciones o configuración de producción. Tampoco cambia el sitio estático de Natalia: recibe los archivos compartidos del SDK desde Cita Suite.

## Evidencia y regresión

`apps/natalia/scripts/test-public-browser.mjs` ahora comprueba geométricamente el modal sobre el CSS real de Natalia: centrado, límites del viewport, ausencia de desplazamiento horizontal, iframe sin recortes y acceso al final de un formulario sintético largo. Usa un único navegador y ejecuciones secuenciales. Intercepta todas las solicitudes a Cita Suite; no usa una base real.

La reproducción adicional de lectura sobre la web publicada, con los dos archivos del SDK corregidos sustituidos sólo en el navegador local, recorrió prestación → día → horario → formulario en 1440×900, 2557×1079, 390×844, 320×568, 768×1024 y 844×390. En los seis tamaños el desvío horizontal del centro fue 0px; el modal y su iframe quedaron dentro del área disponible. Se comprobó llegar al botón final, cerrar, recuperar el foco y reabrir conservando el paso, sin ingresar datos ni enviar reservas. Esta evidencia con archivos sustituidos es previa al despliegue: no prueba por sí sola la corrección publicada.

Pasaron las 65 pruebas focalizadas, los ocho escenarios públicos de Natalia con la nueva regresión en seis tamaños y Svelte/TypeScript sin errores ni advertencias. Se ejecutaron secuencialmente.

La comprobación final de producción confirmó los seis tamaños y la agenda integrada de `/turnos`. La revisión de consola detectó además una polilínea del icono de reloj con cinco coordenadas numéricas en `ServiceCards.astro`; se completó el par faltante, sin cambiar contenido ni diseño de las tarjetas. Esa corrección de la portada requiere una publicación estática de Natalia independiente del SDK. La advertencia genérica del navegador sobre `allow-scripts` y `allow-same-origin` se conserva en el recibo; no es un error de JavaScript ni un bloqueo de carga. El motor y la web de Natalia se sirven desde orígenes distintos.

Las capturas y mediciones antes/después están en `/tmp/cita-modal-layout-before/` y `/tmp/cita-modal-layout-after/`. No incluyen datos de pacientes. La revisión de capturas se hizo en una ronda conjunta de escritorio y móvil; no se cambió la identidad visual.

## Reproducir y publicar

1. Con Natalia compilada y configurada, ejecutar `pnpm --filter natalia test:browser`. El caso `configured` contiene las seis medidas de regresión.
2. Ejecutar las cuatro suites focalizadas del SDK, instalación y origen: `pnpm --filter web test src/lib/booking/embed-sdk.test.ts src/lib/booking/booking-installation.test.ts src/lib/server/booking-integrations.test.ts src/lib/server/booking-integration-request.test.ts --maxWorkers=1 --no-file-parallelism`.
3. Ejecutar `pnpm --filter web check` y compilar Cloudflare secuencialmente. Conservar el hash de compilaciones reproducibles antes de publicar por el flujo Git conectado.
4. Verificar la versión servida y comparar **ambos** archivos `/booking/embed-v1.js` y `/booking/embed-v1.css` con los compilados. No omitir la hoja de estilos en la comprobación de publicación.
5. Abrir la portada canónica, pulsar Reservar consulta y recorrer los pasos hasta el formulario sin enviarlo. Comprobar posición, ancho y desplazamiento del modal, no sólo el ancho de la página. Repetir una comprobación de `/turnos` para proteger el modo integrado.

El SDK se sirve con revalidación de caché; verificar también las direcciones sin parámetros de caché. No hace falta volver a publicar Vercel para este cambio. El rollback consiste en restaurar los dos archivos del SDK de la versión anterior y publicar Cita Suite, sin operaciones de base de datos.

Alcance de navegador: Chromium en escritorio y emulación móvil/táctil. No constituye una prueba en un teléfono físico ni con un teclado virtual real. Los recibos de despliegue y la comprobación final de producción se guardan separados, asociados al commit, en `audit-evidence/cloudflare/`.
