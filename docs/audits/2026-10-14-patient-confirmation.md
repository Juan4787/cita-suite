# Formulario final de reserva del paciente

## Alcance y resultado

Se aplica la referencia visual enviada al último paso compartido por `/reservar/[businessId]` y `/embed/v1/[publicKey]`: resumen destacado, arancel de la fecha elegida, datos obligatorios primero, separación de opcionales y confirmación amplia. Se elimina «Información para el consultorio». Las preguntas, profesionales, precios y ayudas siguen proviniendo de la configuración; los ejemplos de la imagen no se incorporan como datos reales.

Dentro de cada grupo se conserva el orden configurado, sin modificar el esquema ni su hash. Nombre y teléfono preceden a las preguntas obligatorias; después aparecen preguntas opcionales, comentario y correo. Sí/No requiere una elección explícita y conserva `false`; las preguntas opcionales permiten «Sin responder». El precio cotizado aparece una sola vez y conserva la advertencia de ajustes. Se mantienen revisión de enlace, modalidad, idempotencia, recuperación y validaciones del servidor.

La fecha de nacimiento permite escribir día, mes y año con JavaScript, valida fechas reales y conserva el ISO original. Sin JavaScript permanece un único `input type=date` con nombre, obligatoriedad y límites; la mejora se monta al hidratar y preserva lo escrito antes. Los controles y menús mantienen los temas de Cita Suite y Natalia. No hay migraciones ni cambios de configuración o datos de producción en esta entrega.

## Evidencia y límites

Todas las reservas de prueba se hicieron en PostgreSQL/PostgREST descartables y una clínica sintética, con Auth simulado. La evidencia no equivale a una reserva real en producción ni a pruebas en dispositivos físicos.

| Comprobación | Resultado |
| --- | --- |
| Clientes: orden estable, respuesta explícita, borrado opcional, precio único, fechas válidas/límites, controles compartidos | 17 pruebas aprobadas, secuenciales |
| Svelte y TypeScript, fuente final | 0 errores y 0 advertencias |
| Base local reconstruida | 97 migraciones existentes; contratos SQL aprobados |
| E2E de reserva compartida | 1 escenario aprobado; iframe, recuperación de respuesta perdida, página nativa y datos del paciente |
| Chromium local, fuente final con JavaScript | 7 comprobaciones; confirmación real local, `false`, fecha y arancel persistidos |
| Chromium local sin JavaScript | 2 comprobaciones; fecha obligatoria y opcional persistidas en el paciente |
| Pantallas | 1440, 390 y 320 px sin desborde horizontal; Natalia claro/oscuro y sus menús |

La revisión independiente inicial indicó `fix`: el primer diseño de la fecha dependía de JavaScript. Se corrigió y se probaron ambos modos. El dictamen final indicó `ship` sobre esa corrección y no observó regresiones visibles en las ocho recapturas. No constituye una auditoría de toda la aplicación.

Un intento intermedio de recaptura no conservó la selección de un radio al llegar a la lectura del formulario. La siguiente ejecución, sin cambios de fuente, pasó la misma comprobación y la persistencia real. No se atribuye una causa no demostrada. Para futuras reproducciones, esperar la mejora del selector antes de completar el formulario evita mezclar interacción con controles SSR e hidratados.

El detector se ejecutó una vez: 24 avisos de tamaños/radios y 4 avisos de fuentes ya existentes en Natalia. La revisión los evaluó dentro de la extensión del sistema existente. No se generaron imágenes para la interfaz.

Evidencia: [resultados JavaScript](evidence/2026-10-14-patient-confirmation/results.json), [resultados sin JavaScript](evidence/2026-10-14-patient-confirmation/nojs-results.json), [escritorio](evidence/2026-10-14-patient-confirmation/desktop.png), [celular](evidence/2026-10-14-patient-confirmation/mobile.png), [320 px](evidence/2026-10-14-patient-confirmation/user-320.png), [Natalia claro](evidence/2026-10-14-patient-confirmation/natalia-light.png) y [Natalia oscuro](evidence/2026-10-14-patient-confirmation/natalia-dark.png). Las capturas son del formulario completo o del menú indicado, no de toda la página.

## Reproducción local

Ejecutar todo secuencialmente, sin pruebas o compilaciones pesadas concurrentes. Desde la raíz:

```sh
NODE_OPTIONS=--max-old-space-size=1024 pnpm --filter web test:client src/lib/booking/PublicBookingFlow.client.test.ts src/lib/booking/BookingBirthDateInput.client.test.ts src/lib/ui/styled-controls.client.test.ts --maxWorkers=1 --no-file-parallelism
NODE_OPTIONS=--max-old-space-size=1024 pnpm --filter web check
node scripts/test-booking-foundation.mjs --keep
```

Con el nombre del contenedor descartable que imprime el último comando, iniciar `node scripts/serve-booking-fixture.mjs <contenedor>` en una terminal. El servidor genera `/tmp/cita-booking-runtime.json`; contiene credenciales sintéticas y no debe imprimirse ni versionarse. En otra terminal crear `.impeccable/review/patient-confirmation/` y ejecutar, en este orden y sobre un servidor nuevo:

```sh
node docs/audits/evidence/2026-10-14-patient-confirmation/qa.mjs
node docs/audits/evidence/2026-10-14-patient-confirmation/nojs.mjs
```

Los scripts sólo aceptan orígenes loopback y la clínica sintética. Configuran preguntas/aranceles mediante los RPC existentes y realizan tres reservas locales en total; no reutilizar el mismo servidor después de otros escenarios de reserva sin considerar el límite de intentos. No relajar límites de producción para ejecutar pruebas. Detener el supervisor al terminar para eliminar servidor, contenedores, redes y archivo de credenciales.

El E2E base se ejecuta en su propia instancia local con `--workers=1`. Primero verificarlo y después usar una instancia nueva para las comprobaciones específicas de esta carpeta; ambas pruebas modifican la configuración sintética.

## Publicación

Destino autorizado: Cita Suite, Worker `app`, mediante el build nativo conectado a GitHub `main`. Antes de subir se verifican los archivos incluidos, pruebas y dos compilaciones Cloudflare secuenciales con la misma versión. Después del despliegue se verifica `/_app/version.json` y se comparan los recursos publicados con la compilación local. El recibo de producción se guarda separado en `audit-evidence/cloudflare/`, asociado al commit publicado.

La web de Natalia consume el turnero compartido; esta entrega no introduce una clave pública ni habilita una configuración del consultorio que aún no haya sido confirmada. Cursos, noticias, adjuntos y notificaciones quedan fuera del alcance.
