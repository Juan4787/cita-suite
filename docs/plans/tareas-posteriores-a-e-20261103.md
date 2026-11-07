# Tareas posteriores a E

**Estado vigente desde el 7 de noviembre de 2026:** P1, P2 y P3 **publicadas**. Juan las había reanudado el 6 de noviembre, en ese orden y por separado ([plan 12.34](propuesta-senas-avisos-natalia.md#reanudacion-p1-p2-p3-20261106)). Sustituye la pausa de [12.26](propuesta-senas-avisos-natalia.md#posteriores-a-e-pospuestas). La autorización de publicar está registrada en el mismo 12.34. Estado de producción en el [registro único](../ESTADO-VIGENTE.md).

## Orden obligatorio y seguimiento

| Orden | Trabajo | Estado | Condición de avance |
|---|---|---|---|
| Previo | E completa: correo, autogestión, señas y sus 97 casos | Publicada el 6 de noviembre | [Registro de E](ejecucion-etapa-e-20261103.md) |
| P1 | Habilitar cancelar turnos desde recepción | Publicada el 7 de noviembre | Ver [punto de trabajo](#punto-de-trabajo) |
| P2 | Estilar todos los controles y superficies de la app, en claro y oscuro, y revisar el diseño y la experiencia de toda la app | Publicada el 7 de noviembre | Ver [punto de trabajo](#punto-de-trabajo) |
| P3 / nueva D | Avisos internos generales para horarios liberados, con patrón similar a Seguimientos | Publicada el 7 de noviembre | Ver [punto de trabajo](#punto-de-trabajo) |

Cada tarea conserva cambios, reproducción/contraste, pruebas, auditoría, publicación y documentación propios. Conservar sus límites e incidencias, y no atribuirles evidencia de otra revisión.

## P1: cancelación desde recepción

Revisar primero permisos y acciones reales después de E, porque parte de la autorización puede existir ya. Habilitar la opción visible y utilizable para recepción donde corresponda, con confirmación contextual, resultado persistente y mensajes humanos. Probar su rol real, tenant ajeno, permiso retirado, turno iniciado/cancelado y la coherencia con dinero, disponibilidad y notificaciones. No duplicar el comando transaccional de E ni ampliar otros permisos por inferencia.

**Decisión de Juan, 6 de noviembre ([12.34](propuesta-senas-avisos-natalia.md#reanudacion-p1-p2-p3-20261106)):** un turno que ya empezó o ya pasó no se cancela. La pantalla debe aclararlo en vez de esconder el botón sin explicación.

## P2: estilos completos en los dos modos

Inventariar las superficies reales de la aplicación y reserva pública: formularios, selectores, fechas/horas, botones, menús, diálogos, avisos, carga de archivos, estados vacíos/errores y controles del navegador que hoy queden sin estilo propio. Conservar semántica, teclado y accesibilidad al sustituir la presentación. Usar el sistema existente de tokens y componentes, sin colores sueltos ni un rediseño de marca no pedido.

Desde el 6 de noviembre P2 incluye la revisión de diseño y experiencia de toda la app: espacios vacíos, bloques que no encajan, jerarquía y coherencia entre pantallas, a partir de las capturas reales.

Verificar claro/oscuro, anchos 320/390/768/1280/1600, zoom, foco y contenido largo con evidencia de interfaz renderizada. Auditar controles nativos visibles y llamadas alert/confirm/prompt, sin asumir que un análisis de código o una captura del estado normal prueban todos los menús y estados. Documentar el alcance efectivo de los controles de la web; no presentar como personalizado un diálogo externo que el navegador/sistema siga dibujando.

## P3: reemplazo de D por notificación interna

**La D anterior de aviso al celular del consultorio queda reemplazada por este alcance.** El objetivo son avisos de horarios liberados dentro de una bandeja/notificación general de la app, con lógica similar al patrón real de Seguimientos, que se inspeccionará al iniciar esta tarea. No incorporar suscripciones push al personal, permisos del navegador, manifiesto instalable ni requisito de conocer Android/iPhone para esta D. Los push/calendarios existentes del paciente y el correo de E conservan su alcance propio.

Contrastar y reutilizar el registro/alerta C de horarios liberados para evitar dos fuentes, notificaciones duplicadas o avisos de un horario ya ocupado. Verificar visibilidad por consultorio/rol, acciones, pendientes/resueltos, recuentos, cambios concurrentes, caducidad y coherencia de navegación. Definir sus detalles a partir del código y del patrón de Seguimientos; no inventar otros tipos de aviso comercial no encargados.

## Continuidad

Después de una compactación: leer AGENTS, estado vigente, [12.34](propuesta-senas-avisos-natalia.md#reanudacion-p1-p2-p3-20261106) y el punto de trabajo de abajo. Se registra acá el inicio y cierre de cada tarea, la revisión, las corridas, la evidencia y el siguiente paso concreto. La lista general de pendientes enlaza este documento y no duplica su seguimiento.

<a id="punto-de-trabajo"></a>

## Punto de trabajo

**6 de noviembre, noche.** Relevamiento hecho sobre las 665 capturas de la corrida 42290663360 (`main` `f459b95c`). Hasta ese momento no se había publicado nada; la publicación fue el 7 de noviembre, al final de este punto.

**P1, lo implementado:**
- `supabase/migrations/20261106040000_staff_cancel_before_start.sql`: el comando rechaza cancelar un turno ya iniciado con `APPOINTMENT_ALREADY_STARTED`. Hasta acá sólo lo impedía la pantalla. Reprogramar un turno pasado sigue permitido.
- Detalle del turno: «Cancelar turno» sale del final de la página y queda arriba, en `StaffCancelPanel.svelte`, con lo que pasa con el horario, la seña y el aviso al paciente antes de confirmar. Sólo lo ven los roles que operan.
- Turno pasado o en curso: etiqueta «Turno pasado» o «En curso» y un aviso que explica por qué no se cancela. La agenda y «Mis turnos» usan la misma etiqueta, en reemplazo de «Expirado».
- Pruebas: `e2e/reception-cancel.spec.ts`, casos 11a a 11c de `supabase/tests/staff_appointment_management.sql`, y pruebas de cliente y servidor.
- Corridas: SQL 42307475373 aprobada. Navegador 42308051622: toda la conducta aprobada; falló sólo el control de diseño a 320 px por una palabra partida en el título anterior, reemplazado en P2.

**P2, lo implementado:**
- Detalle del turno rehecho: datos clave arriba, acciones visibles y grupos a todo el ancho. Se fue la grilla de cuatro columnas que dejaba el vacío.
- Desplegables con `ux-disclosure`: resuelve las dos flechas y los títulos corridos de Reprogramar, Historial y Horarios que se liberaron.
- Nada nativo: selectores, fechas, archivo, avisos de validación y ayudas emergentes son de la app. `native-controls.test.mjs` lo controla y `theme-modes.spec.ts` lo mide en pantalla.
- Diálogos de pacientes con los botones y campos del sistema: se va el azul de una paleta vieja. Configuración con encabezado y ancho únicos. Pestañas iguales en todo el editor del profesional.
- Defectos corregidos: «Último paso» oscuro e ilegible en modo claro, fechas como «6 De Noviembre De 2026», «Odontología» como título en celular, «Página no encontrada» con un mensaje de error de otra cosa, botón rojo de «Reportar problema», clases sin definir (`ux-success`, `ux-error`, `ux-link`, `ux-alert-danger`).

**P3, lo implementado:** `SlotReleasesNotice.svelte` en la parte superior de la app, con `loadSlotReleaseNotice`. Sin migraciones: reusa `get_appointment_slot_releases`. Sólo para dueño, administración y recepción, y no en la agenda. Detalle en el [contrato funcional](../architecture/functional-contracts.md).

**Prueba en teléfono real, 6 de noviembre.** Samsung A71 (Android 13, Chrome 156) contra un entorno local descartable: base local con las 165 migraciones, datos sintéticos y `adb reverse`, sin tocar producción. Con toques reales: cancelar con y sin confirmación, reprogramar, selectores y calendarios propios, alta de paciente, consulta en diálogo, reserva pública completa con validación propia, página del turno, aviso de horario liberado y modo oscuro. Sin desbordes ni controles nativos en 320, 360, 800 apaisado, 768 y 1280. El Xiaomi estaba bloqueado y no se usó.

**Hallado y corregido por esa prueba:** los avisos ocupaban casi toda la pantalla del celular, las fechas apilaban un campo por fila, «Ocultar búsqueda» se partía, el título de la pestaña quedaba desactualizado y el recuadro de «Reportar problema» parecía un error.

**Corrida 42310115660, servidor de desarrollo, 24 fallos:** no sirve como evidencia de conducta. El servidor de desarrollo hidrata tarde: las pruebas actuaron antes de que la página estuviera lista, y los reintentos de sesión dispararon el límite de ingresos. Dejó defectos reales ya corregidos: nombre accesible del campo de archivo, teléfono partido a 320 px y pruebas que medían los controles nativos ocultos. La evidencia válida usa el paquete real.

**Resoluciones, pedido de Juan del 6 de noviembre:** «acordate de probar en mas resoluciones, no solo las del samsung». `e2e/resolutions.spec.ts` recorre 45 pantallas y estados en 26 resoluciones reales, de 320×568 a 2560×1440, con celulares en las dos posiciones, tabletas, notebooks y monitores. Primero se corrió con Chromium local y halló lo que 390 y 1280 no mostraban:
- tabla de pacientes apretada en tableta y a 1024: ahora es tarjetas hasta 1023 px;
- botones partidos en Estudios, Turnos para recordar y Reseña de Google;
- filtros de la agenda partidos a 1024;
- tarjetas de prestación del asistente con palabras partidas en celulares chicos;
- separadores «·» colgando y cantidades separadas de su unidad;
- textos de ejemplo cortados a 320 px.

Después de corregir: cero problemas en todas las pantallas y estados.

**Información adicional del paciente, pedido de Juan del 6 de noviembre:** «cuando guardo la informacion adicional en el turno, deberia aparecer un cartel que indique que se guardo y volver al sitio anterior del resumen del turno». Al guardar, el paciente vuelve al resumen de su turno y arriba aparece «La información quedó guardada para la profesional.», con foco para los lectores de pantalla. Funciona también sin JavaScript, porque la vuelta la decide el servidor con un 303. La marca `?informacion=guardada` se borra de la dirección para que el cartel no reaparezca al recargar. Los errores siguen en el formulario, sin perder lo escrito. Probado con toques reales en el Samsung. Esa prueba mostró además que el formulario tenía otro color de fondo que el resto de las pantallas públicas del turno: quedó igualado.

**Firefox y WebKit, 6 de noviembre.** Juan instaló en la computadora de trabajo `libavif16` y `libwoff1`, y WebKit pasó a correr también acá. Cada fallo de las corridas 42315494990 (WebKit) y 42316788210 (Firefox) se midió antes de decidir:

| Lo que falló | Causa medida | Qué se hizo |
|---|---|---|
| WebKit no ingresa, 7 fallos | WebKit en Linux descarta las cookies `Secure` por http, también en `127.0.0.1` y `localhost`. Chromium y Firefox las conservan. El paquete real marca `Secure` las cookies de sesión. Safari real usa https y no tiene este problema | Con `E2E_ENGINE=webkit`, `serve-booking-fixture.mjs` pone un proxy que le quita ese atributo. El paquete no cambia |
| Teclado sin llegar al modo oscuro en Firefox | **Defecto real, en todos los navegadores:** el panel móvil declaraba `aria-modal` pero no tomaba el foco, Tab se iba a lo de atrás, y no cerraba con Escape | `dialogFocus`, compartida con `Modal`. Los menús del encabezado también cierran con Escape |
| Textos de ejemplo cortados en Firefox | `clientWidth` de un `<input>` en Firefox ya viene sin relleno y el control lo restaba dos veces. **El de la Papelera sí se cortaba a 320 px en todos los motores** | El control mide desde la caja. Papelera con `ux-input` y un ejemplo más corto |
| `network-failure` en Firefox | Cargas canceladas al salir de una pantalla: cada motor las nombra distinto (`net::ERR_ABORTED`, `NS_BINDING_ABORTED`, `Load request cancelled`) | El control reconoce los tres nombres |
| Errores de página en Firefox | Firefox y WebKit informan como error un `fetch` o `import` pendiente al abandonar la página. Chromium no | `pageErrorCollector`: esos errores sólo se aceptan si el motor informó la carga cancelada |
| `/realtime/v1/websocket` 404 en Firefox | Firefox informa el rechazo del WebSocket como una respuesta. El entorno de prueba no tiene Realtime | El control lo reconoce sólo contra ese origen, y clasifica el texto de cada motor |
| `isMobile` y captura mayor a 32767 px | No existe en Firefox. Firefox y WebKit rechazan esa captura, que Términos alcanza a 320 px | `mobileOptions` y captura de pantalla visible en ese caso |

**Barrido exhaustivo con esa base.** Las 53 pantallas con página del entorno local, medidas con Chromium en las 26 resoluciones como dueño, recepción y profesional (1.378 mediciones cada uno) y sin sesión, y con Firefox y WebKit en 8 resoluciones como dueño, profesional y sin sesión. Halló:
- en Ayuda a 320 px, «24 horas» partido y el botón en dos líneas;
- «Pacient…» cortado en la barra inferior;
- sólo con el perfil de profesional, la tarjeta de «Mis turnos» con el texto apretado a 108 px y un «·» colgando, «Mis pre…» y «Mis turn…» cortados, y «Mis preguntas» con el ícono de «Más»;
- «48 horas» partido en Términos.

Todo corregido, y el barrido final dio cero problemas en todos los perfiles y motores. `resolutions.spec.ts` mide ahora también las pantallas de un profesional real y las etiquetas de la barra inferior.

**Defecto real de Safari, hallado por WebKit.** Después de una acción, la app llevaba el foco al aviso y confiaba en que eso lo mostrara. Medido: Chromium y Firefox desplazan la página hacia el elemento enfocado; WebKit no. En un iPhone, un paciente que reprogramaba no veía «La reprogramación quedó registrada», ni el personal el aviso de que el turno había cambiado. `revealNotice` enfoca y desplaza por su cuenta, y lo usan el detalle del turno, la gestión del paciente, la información previa, la exportación y el cartel de información guardada.

**Corrida 42335965685, Firefox, 74 de 78, y 42337545565, WebKit, 45 de 78.** Primeras corridas con todas las pruebas en esos motores, sobre `c4c1ffd0`. Además de lo anterior:
- **El visor clínico no mostraba la imagen en Firefox:** el PNG de la prueba estaba corrupto, con CRC y zlib incorrectos. Chromium lo dibuja y Firefox y WebKit no. Se reemplazó por uno válido. Eso mostró una mejora real: Firefox dispara `load` para un archivo que no puede decodificar, y el visor quedaba mudo. Ahora ofrece «Reintentar».
- **Embebido en WebKit:** bloquea contenido http dentro de una página https, incluso en `127.0.0.1`. Es un límite del entorno de prueba, porque en producción las dos partes son https. El paquete real sólo acepta orígenes https, así que esa prueba se omite en WebKit. Chromium y Firefox la cubren.
- **`request-transport`:** caracteriza justamente el comportamiento de cookies `Secure` que WebKit no tiene; se omite en ese motor.
- **Cancelaciones:** Firefox informa `Unable to preload CSS` al salir de una pantalla; los `fetch` de la agenda sí estaban manejados. Entra en `pageErrorCollector`, siempre contra una carga cancelada. El caso de WebKit quedó explicado después, en la corrida de `246841d3`.

**Hora en «Mis turnos» y turnos en otras pantallas internas.** «Mis turnos» formateaba la hora sin la zona del consultorio y en 12 horas: el servidor corre en UTC, así que la primera pintura mostraba un horario corrido. Ahora usa `agendaTime`, igual que la agenda. También pasan la zona la ficha del paciente, el historial del profesional y el detalle del turno.

**Corridas 42340600343, Chromium, y 42342070553, Firefox.** El límite real de 40 ingresos por dirección cada 15 minutos se agotó: todas las pruebas ingresan desde la misma dirección, y ya eran más de 40. La app hizo bien en frenar. `signInWithPassword` limpia ese contador sólo en el entorno descartable.

**Corrida 42335055779, Chromium, 76 de 78.** Los dos fallos no venían del cambio de P1, P2 o P3:
- **`staff-delivery`, teléfono `--sanitized--`:** la app abre WhatsApp con un formulario en pestaña nueva y el servidor responde con una redirección. Playwright no intercepta redirecciones, así que esa prueba y la de señas siempre llegaron al sitio real, y WhatsApp ahora reescribe esa dirección. Con `whatsappDraft` la pestaña se frena en la respuesta del servidor: se lee el destino y WhatsApp no recibe ningún pedido, comprobado en los tres motores.
- **`patient-management-clinical`, 503 en vez de 404:** se repitió en varias corridas, siempre en esa línea. La causa quedó medida en la corrida de `246841d3`, abajo.

**Corridas 42344702853, Chromium, 78 de 79; 42345775618, WebKit, 57 de 79; y 42347334531, Firefox, 78 de 79, sobre `246841d3`.** Cada fallo se midió antes de decidir, con experimentos aislados en los tres motores:

| Lo que falló | Causa medida | Qué se hizo |
|---|---|---|
| Chromium y WebKit: 503 en `patient-management-clinical` | Lo responde `wrangler dev`, no la app: el cuerpo es «Your worker restarted mid-request». En `ProxyWorker.js` compara la dirección completa con una que sólo tiene la raíz, así que cualquier corte de un POST en otra ruta da ese texto aunque nada se reinicie. El pedido anterior dio 200, este murió en 2 ms y `workerd` registró `Broken pipe`. En producción ese proxy no existe | `pastDevProxy` repite sólo esa respuesta exacta: el primer intento no llegó a la app, así que nada corre dos veces |
| WebKit: 14 pruebas con `Refused to apply a stylesheet` | Lo causa la captura de Playwright, que inserta un estilo; sólo WebKit le aplica la política de la página. Medido: sin captura, cero; con captura, uno por marco. `caret: 'initial'` no lo evita. La ubicación no distingue una captura de un estilo insertado por la app | El colector lo ignora sólo mientras hay una captura en curso: 80 de 80 mensajes cayeron dentro y ninguno fuera. Un estilo real fuera de una captura sigue fallando, y `render-health.spec.ts` lo comprueba en los tres motores |
| WebKit: `Fetch API cannot load … due to access control checks` sin carga cancelada | WebKit rechaza un `fetch` que arranca mientras su documento se va, con ese texto, y no informa ningún pedido. Reproducido con un `fetch` en `pagehide`. Ocurre en la agenda justo al salir. No afecta a nadie: la pantalla ya se fue | El colector lo acepta sólo si es `fetch` del propio origen, que la política permite. Uno de otro origen sigue contando, y también lo comprueba `render-health.spec.ts` |
| WebKit: `booking-reschedule-policy`, campo sin `name` | La prueba quería actuar antes del arranque de la app, y WebKit sirve desde memoria los módulos ya cargados, por encima de cualquier `route`. Ni `no-store` lo evita. En Chromium y Firefox el freno sí funciona | La carga frenada pasa a ser la primera de esa página, y el freno funciona en los tres motores |
| WebKit: `account-assistance` | `isVisible()` no espera. Sin servicios el formulario se abre solo y el mismo botón cambia de nombre, así que la prueba buscaba para siempre un texto que ya no existía | Espera directamente el estado final |
| Firefox: `booking-embed`, clic sin efecto en «Fechas anteriores» | **Defecto real, en todos los navegadores:** al volver atrás la app animaba hasta 526 px, y un toque rápido se perdía: se aprieta sobre el enlace, la página se mueve y se suelta sobre otra cosa. Apretando 150 ms después se perdieron 5 de 5 | Al volver atrás la tarjeta del paso aparece en su lugar sin animación, en la misma posición final. Al avanzar sigue animada. Después: 0 de 5 en Firefox, 0 de 5 en Chromium, 0 de 4 en WebKit, y 3 de 3 toques reales bien en el Samsung |

**Corridas 42353204001, Chromium, 81 de 81; 42354228519, Firefox, 80 de 81; y 42351754547, WebKit, 75 de 81 con 2 omitidas, sobre `2c990dcc`.** Lo que quedaba:

| Lo que falló | Causa medida | Qué se hizo |
|---|---|---|
| WebKit: `appointment-deposits`, «Revisá los datos marcados» al guardar la seña, sólo a veces | Carrera de `fill` con el arranque de la app. Al arrancar, Svelte quita el atributo `value` y reasigna el valor (`remove_input_defaults`), y eso colapsa la selección. Medido en WebKit: con «50000» seleccionado y arranque en el medio, escribir dio `5000050.000`. La validación hizo bien en rechazarlo. WebKit tiene la ventana mayor porque no tiene `requestIdleCallback` | La prueba reescribe hasta que el campo tiene lo que corresponde. **Límite conocido, del framework:** una persona que selecciona un campo con valor antes de que arranque la app y escribe después agrega en vez de reemplazar |
| WebKit: `account-assistance`, `goto` interrumpido por una navegación a la misma página | Si falla un pedido de datos, `load_root_error_page` de SvelteKit recarga la página. WebKit le entrega la cancelación a la página antes de irse, y esa recarga interrumpe el `goto`. Sólo pasa con una navegación completa mientras cargan datos: los enlaces de la app no pasan por ahí | La prueba repite esa navegación |
| WebKit: `Error: Unable to preload CSS` | El mismo mensaje de salida que ya se reconocía en Firefox, con `Error: ` delante | Lo reconoce, siempre contra una carga cancelada |
| Firefox: `TypeError: error loading dynamically imported module` en la consola | Es una carga dinámica abandonada al salir, con otras palabras | Se clasifica como carga abandonada. Una que falle de verdad sigue en `networkFailures` |
| WebKit: la prueba nueva del colector | Error mío: usé el puerto 9, que los navegadores restringen | Otro puerto, el del experimento |
| WebKit: la corrida nunca dejaba evidencia | No era por los fallos: una corrida completa pesa 53 MB (51 MiB) porque sus capturas pesan 1,4 veces las de Chromium, y el tope era de 48 MiB. Eso habría hecho fallar incluso una corrida limpia | Tope de datos extraídos en 64 MiB. El del transporte sigue en 48 MiB comprimidos |

**Corridas sobre `8aa29267`, instantánea `32f7947478d06140535e903910842469442489cc`:** paquete 42356240861 y `fast` 42356252871 aprobados; Firefox 42357786559, 81 de 81; Chromium 42359023728, 81 de 81. WebKit 42356546061 dio 78 de 79, con las 2 omitidas de siempre, y su evidencia ya entró: 53,2 MB. El único fallo:

| Lo que falló | Causa | Qué se hizo |
|---|---|---|
| WebKit: `booking-embed`, un `goto` sin `load` en 30 s | El archivo estático `nodes/13.C4S1MaGl.js` tardó **36.274 ms** dentro de `wrangler dev`; los de alrededor, entre 4 y 15 ms. En producción esos archivos los sirve Cloudflare. **Causa probable, consistente pero sin demostrar:** el mismo defecto de comparación de `ProxyWorker.js` deja un GET que perdió su conexión en una cola de reintentos que sólo se procesa cuando llega otro pedido, y la página esperaba justo ese archivo. Los 36 s coinciden con los 30 del `goto` más el arranque de la prueba siguiente, cuyo primer pedido figura justo después. No quedó registrado ningún `Broken pipe` | Nada en la app. WebKit se repite sobre la misma revisión y el mismo paquete. **Pendiente del entorno de prueba:** procesar esa cola al instante, como admite el propio comentario de `wrangler`, o mandarle un pedido periódico |

**WebKit 42360160570, repetición sobre la misma instantánea: 78 de 79, con 2 omitidas. SQL 42360185338 aprobado**, con cero deadlocks en todas las carreras. El fallo fue otro:

| Lo que falló | Causa medida | Qué se hizo |
|---|---|---|
| WebKit: `appointment-slot-releases`, `goto` interrumpido por una navegación a la URL de la acción `…&/hide_slot_release` | «Ocultar» es un POST nativo, y su respuesta es una página nueva que todavía estaba cargando sus módulos: se cancelaron 25 en el instante del `goto`. WebKit le entregó esa falla a la página; el arranque de SvelteKit capturó «Importing a module script failed», pidió el `__data.json`, rechazado por la salida, y recargó la página de la acción. Mismo mecanismo que `account-assistance` | La prueba repite ese `goto`. **Límite conocido de SvelteKit en Safari:** quien toca un enlace mientras la página todavía carga su JavaScript puede ver recargarse la misma página en vez de navegar; vuelve a tocar y sigue. No pasa en Chromium ni en Firefox |

**Verificación de la revisión publicada**, `main` `2f81c7ef`, instantánea `cabd8ae4012749907d7bdb80b90f75bc0119f2a3`:
- paquete 42362009024, `fast` 42362019500 y SQL 42365877784;
- Chromium 42365013991 y Firefox 42363631730, con 81 de 81 cada uno;
- WebKit 42362424031, con 79 de 79 y las 2 omisiones declaradas. Ese trabajo figura fallido sólo porque `assertBrowserReport` exige cero omitidas; queda en [pendientes](pendientes-vigentes.md).

**Publicación, 7 de noviembre, de 11:04 a 11:06 UTC.** Antes del ensayo se migró staging a 165 (42366406312), porque le faltaba la correctiva `20261106030000`: así el ensayo vuelve a comparar contra un catálogo completo. Después: ensayo sin fallas, respaldo, programador sin cron, migración 165 en 756 ms, app `ecec47cb-93f2-49d6-be09-dfa94091810a`, `verify-production-release.mjs` aprobado y programador `0debec79-cadd-47e3-8bf6-47a46e6ba182` con sus cinco cron. Detalle y vuelta atrás en la [guía de publicación](../architecture/publicacion-y-reversion.md).
