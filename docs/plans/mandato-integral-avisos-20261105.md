<!-- Texto literal del encargo de Juan del 5 de noviembre de 2026, extraído de la transcripción de la sesión sin retipear.
No se edita: las decisiones y ajustes posteriores van en plan-integral-avisos-20261105.md. -->

# CITA SUITE — ENCARGO INTEGRAL DE INGENIERÍA PARA OPUS 5.5

## 1. Objetivo y responsabilidad

Quiero que asumas autónomamente la ingeniería necesaria para dejar **completo, funcional, integrado, publicado y profundamente auditado todo el sistema de notificaciones, comunicaciones, recordatorios y calendarios de Cita Suite**, junto con los procesos del producto necesarios para que ese sistema funcione correctamente de principio a fin.

El resultado no se limita a corregir el problema original de Android, incorporar botones de calendario o conseguir que se envíen correos. Debe existir una experiencia integral y coherente para los pacientes y el personal, desde que se crea un turno hasta que se confirma, modifica, cancela, vence o deja de requerir acciones.

**Correo electrónico, notificaciones push y calendarios forman parte del mismo encargo.** Ninguno puede considerarse un complemento pendiente o una responsabilidad de otro agente.

Además, el desarrollo previo denominado **fase E** debe quedar completamente cerrado como consecuencia de este trabajo: todos sus requisitos vigentes, funcionalidades, procesos, integraciones y verificaciones deben estar resueltos. **No debe quedar trabajo de E pendiente cuando termines.**

Esto **no significa que debas continuar mecánicamente el plan de ejecución descrito en el traspaso**, ni respetar sus etapas, secuencia, arquitectura propuesta o intención de continuación. La implementación previa debe estudiarse, aprovecharse y cuestionarse técnicamente, pero el resultado exigido es más importante que la estrategia histórica.

Tenés libertad para reorganizar la implementación, conservar lo que funciona, corregir lo defectuoso, reemplazar decisiones técnicamente inferiores y proponer soluciones mejores. Lo que no podés hacer es perder, postergar o reinterpretar unilateralmente requisitos funcionales aprobados.

No quiero que conviertas este encargo en una sucesión de parches independientes. **Quiero la mejor solución integral que puedas justificar con ingeniería y evidencia.**

La aplicación tiene actualmente un consultorio en funcionamiento y todavía no tiene pacientes reales. Eso permite realizar determinadas comprobaciones controladas, pero no autoriza a utilizar datos personales, alterar configuraciones comerciales, enviar comunicaciones a destinatarios no acordados ni comprometer infraestructura real.

La implementación y publicación ya habían sido autorizadas en el proyecto. No interrumpas el trabajo para volver a solicitar una autorización general existente. Sí distinguí las acciones que requieran una decisión nueva, un gasto, acceso ausente o una intervención personal que no puedas realizar por tus medios.

## 2. Reconstruí la realidad actual antes de decidir cómo avanzar

El proyecto es **Cita Suite**, basado en SvelteKit, Supabase y Cloudflare Workers.

Repositorio:

`Juan4787/cita-suite`

Aplicación pública:

`https://app.cita-suite.com.ar`

La raíz del repositorio local es:

`/home/usuario/CascadeProjects/CITA SUITE/Cita Suite App`

No confundas esa carpeta con otros proyectos cercanos.

Antes de modificar el sistema, recuperá el contexto completo desde el repositorio, las decisiones originales y sus ajustes posteriores, las implementaciones, los tests y los registros de ejecución.

Empezá por `AGENTS.md`, `docs/ESTADO-VIGENTE.md`, `docs/plans/pendientes-vigentes.md` y la documentación específica accesible mediante `docs/plans/indice-etapa-e.md`.

El índice conduce al plan aprobado `propuesta-senas-avisos-natalia.md`, la especificación `etapa-e-correo-autogestion.md`, el registro `ejecucion-etapa-e-20261103.md`, el traspaso `traspaso-etapa-e-20261105.md` y los contratos de arquitectura correspondientes.

La especificación contiene **97 casos de aceptación**, además de reglas y decisiones que no pueden reducirse a contar tests. Debés satisfacer íntegramente los requisitos aplicables, pero no estás obligado a conservar una organización artificial alrededor de las etapas históricas E0–E6.

**Diferenciá siempre tres cosas:**

1. Los **requisitos aprobados**, que deben cumplirse.
2. La **evidencia histórica**, que indica qué se comprobó y bajo qué condiciones.
3. Las **decisiones e intenciones de implementación registradas en el historial y el traspaso**, que podés revisar y sustituir.

No trates una propuesta técnica como un requisito de producto. Tampoco descartes una garantía ya demostrada únicamente porque preferís otra arquitectura.

### Estado histórico relevante

El 5 de noviembre de 2026, se detuvo la implementación por pedido del usuario y se documentó el traspaso técnico. El checkpoint era **E3.50**, con treinta migraciones propias del trabajo y 161 migraciones totales en el árbol.

Había implementaciones y pruebas parciales sobre autogestión, identidad, agenda, concurrencia, dinero, capacidades, OAuth, calendarios y otros componentes. Seguían sin completarse, entre otras cosas, los consumidores de cambios de contacto, el sistema operativo de correo, Zoho, la entrega externa, distintos recorridos integrados, tareas de limpieza y la publicación.

Las corridas SQL y rápidas contenían resultados útiles. La corrida de navegador `42080552190` terminó fallida después de superar una parte del caso SN14, por lo que no certifica sus escenarios restantes.

La producción documentada seguía siendo **V12b**, revisión `771fac5950c532b1123f11d4dde93eef9b42ceba`, sin las migraciones nuevas publicadas.

**Son datos históricos de partida, no afirmaciones sobre el estado actual.** Comprobá los SHA, archivos, migraciones, versiones, configuración, conexiones y pruebas vigentes antes de actuar.

No repitas automáticamente todas las investigaciones o pruebas anteriores. Reutilizá evidencia válida para el código y las condiciones que efectivamente permanecen iguales.

Tampoco continúes mecánicamente desde la siguiente acción anotada en el traspaso. Primero evaluá el sistema completo y decidí tu propia estrategia.

## 3. Plan integral, persistente y revisable

Antes de empezar a cambiar funcionalidades, elaborá un **plan técnico integral y canónico dentro del repositorio**.

Debe explicar:

- Qué resultado completo hay que entregar y cómo se acredita.
- Qué funcionalidades y contratos existen, cuáles están incompletos y cuáles requieren investigación.
- Cómo se relacionan los distintos medios de notificación con el ciclo de vida de un turno.
- Qué dependencias, riesgos y decisiones transversales condicionan la solución.
- Qué evidencia histórica se puede aprovechar y qué necesita verificarse nuevamente.
- Qué estrategia proponés, por qué y qué alternativas relevantes descartaste.
- Cómo se integrarán cambios, migraciones, trabajos programados y proveedores externos.
- Cómo se comprobará el resultado en navegadores, dispositivos físicos y producción.
- Qué condiciones exactas determinarán que el encargo está terminado.

No quiero una lista de tareas superficial ni una nueva especificación que duplique y contradiga los documentos existentes.

Elegí una ubicación canónica y mantenela actualizada. Las fuentes históricas deben seguir disponibles; las instrucciones vigentes deben reflejar la situación real.

**El plan no debe imponerte una arquitectura prematura.** Primero investigá lo que falta saber; después elegí y justificá la solución. Si una prueba demuestra que tu estrategia inicial era incorrecta, revisala.

La planificación debe ayudarte a evitar omisiones y contradicciones, no convertirse en burocracia.

### Continuidad entre sesiones

Asumí que el trabajo puede atravesar varias sesiones y compactaciones de contexto.

Dejá checkpoints persistentes con la revisión exacta, estado funcional, decisiones, evidencia, riesgos, problemas abiertos y siguiente acción. Antes de continuar después de una compactación, recuperá el mandato original y los documentos canónicos, no sólo el resumen conversacional.

No pierdas decisiones por depender de tu memoria temporal. Tampoco llenes el repositorio de registros redundantes que luego puedan divergir.

## 4. Experiencia completa de notificaciones y avisos

Diseñá y verificá la experiencia desde la perspectiva de alguien que reserva un turno y necesita recibir información correcta y oportuna, sin tener que comprender cómo funcionan los navegadores, los permisos o las sincronizaciones.

El sistema debe manejar adecuadamente:

- Creación, confirmación, reprogramación y cancelación de turnos.
- Recordatorios previos y eventos que modifican su vigencia.
- Solicitudes de seña, condiciones económicas y comunicaciones relacionadas.
- Acciones autónomas del paciente y operaciones autorizadas del personal.
- Cambios de email, teléfono, identidad, destinatario o preferencias.
- Múltiples medios disponibles, bloqueados, deshabilitados o fallidos.
- Enlaces y eventos de calendario que pueden quedar desactualizados.
- Reintentos, entregas inciertas, fallos parciales y situaciones concurrentes.

Los distintos medios no tienen que compartir necesariamente la misma infraestructura. Sí deben representar de manera consistente el **estado vigente del turno**, sus acciones permitidas y los datos legítimos del destinatario.

No crees un sistema que funcione solamente durante la reserva inicial y se vuelva incoherente al cambiar o cancelar el turno.

Tampoco confundas tres conceptos diferentes: **preferencia del usuario, capacidad técnica del dispositivo y entrega efectiva de una notificación**.

La experiencia debe ofrecer alternativas útiles cuando un medio no está disponible, sin afirmar que una opción funciona cuando no existe evidencia suficiente.

No presupongas que todos los pacientes necesitan activar todos los canales. Evaluá una experiencia clara, proporcional y que evite configuraciones obligatorias innecesarias.

## 5. Defecto original de Chrome Android: reconstruí el recorrido y resolvé la causa raíz

Este defecto fue el punto de partida del encargo, pero no agota su alcance. Para entenderlo correctamente, distinguí la **motivación original del producto**, el **recorrido que se intentó implementar**, el **fallo observado** y la **experiencia final que debe conseguirse**. No confundas el diseño histórico con una obligación de conservarlo.

### Motivación y recorrido histórico

Inicialmente Cita Suite sólo ofrecía un enlace manual que abría la creación de un evento en Google Calendar; el paciente tenía que guardarlo. La preocupación era que, en un Samsung que usa Samsung Calendar sin Google Calendar instalado o sin una sincronización apropiada, ese enlace podía no servir para recibir recordatorios. Esa limitación es **condicional**, no una regla que se aplique a todos los Samsung: hay que comprobarla en los dispositivos y con las cuentas disponibles. La evaluación técnica de los diferentes mecanismos de calendario corresponde a la sección 7.

Para afrontar ese problema se diseñó una experiencia que daba prioridad a comprobar el push y, si no era útil, ofrecía orientación y calendarios alternativos. El recorrido pretendido era:

1. El paciente tocaba «Activar notificaciones» y autorizaba los permisos necesarios.
2. Si la habilitación y la suscripción se completaban, Cita Suite enviaba una **notificación de prueba** y preguntaba «La recibí» o «No la recibí».
3. «La recibí» terminaba satisfactoriamente el recorrido.
4. «No la recibí» abría una pregunta sobre el fabricante: Samsung u otra marca Android.
5. En Samsung se mostraban instrucciones para activar o revisar las notificaciones de Chrome en los ajustes del teléfono.
6. En otras marcas se proponía guardar el turno en Google Calendar, apoyándose en la hipótesis de que era frecuente encontrarlo en Motorola y Xiaomi.

**Este recorrido describe la intención histórica, no el comportamiento que quedó demostrado ni la UX que necesariamente debés preservar.** La pregunta por fabricante era una heurística, no una manera fiable de conocer las aplicaciones instaladas, el calendario usado o la sincronización configurada. Investigá una experiencia superior si los hechos lo justifican.

### Fallo observado

La dificultad aparece **antes de enviar la prueba**. En el caso informado, al utilizar Chrome en Android con las notificaciones de Chrome deshabilitadas a nivel del teléfono, tocar «Permitir» en la interfaz interna de Cita Suite no habilitaba las notificaciones ni ofrecía una recuperación útil.

Después de varios intentos —aproximadamente al tercero en aquella experiencia—, en vez de aparecer la pregunta «La recibí / No la recibí» y sus alternativas, se presentaban directamente instrucciones asociadas al recorrido Samsung, incluso cuando esa opción no había sido elegida y podía no corresponder al dispositivo. El botón «Ya estaba activado» era falso en ese contexto. Al tocarlo aparecía «Ya lo permití»; tocar este último podía no producir ningún avance ni mensaje útil. La notificación de prueba nunca había llegado a enviarse, de modo que el paciente quedaba sin confirmación de entrega y sin una alternativa de calendario accesible.

Un diagnóstico anterior señaló posibles fallos en el tratamiento de `Notification.permission`, los permisos de Chrome como aplicación, los permisos del sitio y las condiciones que muestran las guías y alternativas. También atribuyó el cambio tras varios intentos a un bloqueo automático de Chrome. **No des por probado un número universal de intentos ni una duración fija del bloqueo.** Contrastá las hipótesis con el comportamiento actual y las pruebas físicas de la sección 6.

Referencias históricas de código, cuya vigencia debés verificar:

`apps/web/src/lib/components/appointments/PublicAppointmentPage.svelte`

`apps/web/src/routes/turno/[token]/+page.svelte`

`apps/web/src/lib/device.ts`

La condición histórica `samsungExclusive` identificaba Samsung Internet, **no cualquier teléfono Samsung usando Chrome**. Evitá confundir navegador, fabricante, permisos del sitio y ajustes del sistema operativo.

### Resultado funcional exigido

Investigá la causa raíz y resolvé el recorrido completo. Cuando sea posible autorizar y entregar una notificación de prueba, el paciente debe poder comprobar si la recibió y terminar de manera clara. Cuando el permiso no pueda solicitarse, permanezca bloqueado, la suscripción falle, el envío sea imposible o la prueba no llegue, **también debe existir una salida comprensible, accionable y útil**, sin esperar a que se produzca un evento que justamente no puede ocurrir.

Ningún botón debe quedar inerte. No afirmes que se concedió un permiso, que se creó una suscripción o que se recibió un aviso sin distinguir las pruebas respectivas. Después de cambiar ajustes fuera del navegador, recargar, regresar a la página o modificar permisos, el sistema debe recuperar correctamente su situación, sin bucles ni instrucciones contradictorias.

**No te impongo restaurar los botones ni la bifurcación Samsung/otra marca originales.** Diseñá la mejor recuperación y las mejores alternativas a partir de la investigación. La selección de calendarios y sus límites se aborda en la sección 7; la reproducción y evidencia de dispositivos reales, en la sección 6. Comprobá además que los resultados siguen siendo coherentes cuando el turno se modifica o cancela, de acuerdo con el alcance transversal de las secciones 4 y 11.

## 6. Dos teléfonos reales disponibles: Samsung y Xiaomi

**El Samsung y el Xiaomi ya están conectados por depuración inalámbrica.**

No hace falta volver a explicarme cómo emparejarlos. Comprobá su disponibilidad con ADB y aprovechá las herramientas instaladas, incluido scrcpy cuando resulte conveniente.

Ambos teléfonos pueden estar con la pantalla apagada; se pueden despertar mediante doble toque.

**Actualmente ninguno está en silencio.**

Realizá pruebas físicas suficientemente profundas para comprobar las diferencias entre comportamiento simulado y real.

Investigá, según corresponda:

- Permisos de Chrome a nivel Android y a nivel sitio.
- Estados permitido, denegado e indeterminado.
- Primera autorización, bloqueos, reintentos y recuperación.
- Suscripción, envío, recepción y presentación efectiva del push.
- Chrome abierto, en segundo plano y cerrado.
- Pantalla apagada, reposo y restricciones del fabricante.
- Sonido, vibración y presentación de avisos.
- Cambios de configuración durante el recorrido.
- Creación, movimiento y cancelación de turnos de prueba.
- Comportamiento de las aplicaciones de calendario instaladas.

La evidencia debe distinguir una solicitud aceptada por el servidor de una **notificación realmente observada en el dispositivo**.

No pruebes sólo el recorrido feliz. Reproducí especialmente el problema original y los estados que antes dejaban al usuario sin salida.

Podés modificar temporalmente los ajustes necesarios de los dispositivos para las pruebas, pero registrá los valores relevantes, preservá información personal y restaurá lo que corresponda.

Son teléfonos personales: no inspecciones contenido ajeno al producto ni modifiques aplicaciones sin necesidad.

## 7. Estrategia integral de calendarios

Necesitamos ofrecer alternativas realmente útiles a los avisos push, especialmente cuando no pueden habilitarse o no llegan.

Hoy existen mecanismos con propiedades diferentes:

**Enlace manual de Google Calendar:** prepara la información del evento para que el paciente lo guarde. Cita Suite no controla las modificaciones posteriores de ese evento.

**Google Calendar administrado mediante OAuth:** con autorización del usuario, Cita Suite puede crear y gestionar eventos dentro del alcance permitido.

**Archivo `.ics`:** ofrece interoperabilidad con calendarios compatibles, pero no garantiza por sí solo actualizaciones o eliminaciones posteriores.

Investigá qué conviene ofrecer, a quién, en qué momento y con qué explicación.

El objetivo no es simplemente conseguir que un evento aparezca. Debe resultar útil como recordatorio, reflejar adecuadamente el turno y comunicar honestamente sus limitaciones.

### Samsung Calendar

En agosto existió una interfaz que ofrecía agregar eventos a Samsung Calendar a través de una cuenta Google administrada por OAuth. Se incorporó en el commit `4d0905d` y se retiró en `adf8ddc`.

No existe una razón histórica suficientemente acreditada para esa retirada. Investigá el código y los tests correspondientes, pero **no restaures la función por inercia**.

La sincronización entre una cuenta Google y Samsung Calendar puede funcionar bajo ciertas condiciones, pero no debés presentarla como universal.

Comprobá en el Samsung físico:

- Si el evento se crea y aparece en Samsung Calendar.
- Si se produce el aviso esperado y bajo qué condiciones.
- Qué ocurre al reprogramarlo.
- Qué ocurre al cancelarlo.
- Si depende de una configuración de sincronización previamente habilitada.
- Qué experiencia alternativa existe cuando esa condición no se cumple.

**No quiero que la solución obligue al paciente a configurar manualmente una sincronización de calendarios para poder utilizarla.**

Si un mecanismo funciona sólo bajo ciertas condiciones, detectá o explicá esas condiciones en la medida técnicamente posible y ofrecé alternativas apropiadas.

### Xiaomi y otros Android

Comprobá qué aplicaciones reales están disponibles en el Xiaomi, cómo se comportan el enlace manual, OAuth y las alertas, y qué ocurre ante cambios de turno.

No asumas que todos los Android no Samsung usan Google Calendar ni que la aplicación preinstalada es necesariamente la preferida.

### iPhone y Apple Calendar

Para iPhone, el mecanismo previsto utiliza Safari y `.ics` con el calendario nativo.

**No incluyas la implementación de push para iOS como un objetivo de este encargo.**

Debés comprobar hasta donde sea posible el recorrido real: apertura, importación, evento, alertas y limitaciones ante reprogramaciones y cancelaciones.

Hay acceso a **TestKase Device Farm MCP** en Claude Code.

Skill:

`~/.claude/skills/testkase/SKILL.md`

Leé sus instrucciones, verificá las capacidades disponibles y utilizalo cuando pueda aportar evidencia real.

Antes de consumir minutos de prueba, comprobá si permite interactuar con Apple Calendar nativo. Si sólo permite Safari o ciertas operaciones limitadas, no desperdicies recursos repitiendo intentos imposibles.

No compres minutos ni servicios.

No declares que probaste una alerta de Apple Calendar por el solo hecho de haber descargado un archivo `.ics`.

### Diseño final de alternativas

La pregunta histórica «Samsung u otra marca», explicada en la sección 5, no es una decisión arquitectónica inamovible. La experiencia definitiva debe utilizar señales y capacidades verificables hasta donde la plataforma lo permita, admitir incertidumbre y ofrecer alternativas claras sin inferir aplicaciones instaladas únicamente a partir del fabricante.

La prioridad es evitar que el paciente se quede sin ningún mecanismo viable por un fallo de permisos o por una suposición equivocada sobre su teléfono.

## 8. Google Calendar OAuth y verificación oficial de Google

Existe una integración administrada de Google Calendar que quedó técnicamente desarrollada en parte, pero cuyo acceso visible desde la experiencia real del paciente fue retirado.

No basta con que funcione una ruta técnica conocida por el desarrollador.

Debés completar, integrar y comprobar su recorrido legítimo desde la interfaz pública.

Datos históricos:

**Proyecto Google Cloud:** `cita-suite-calendar-513502`

**Scope:** `https://www.googleapis.com/auth/calendar.events.owned`

**Callback:** `https://app.cita-suite.com.ar/oauth/google-calendar/callback`

Ruta histórica de conexión:

`/turno/[token]/google-calendar/connect`

La verificación de marca estaba aprobada; el scope se había declarado y la verificación de acceso a datos seguía pendiente.

**Consultá el estado real actual y los requisitos oficiales de Google antes de modificar configuración o preparar la presentación.**

No confundas la integración administrada con el enlace manual:

`/turno/[token]/ir/google`

Comprobá el recorrido completo, incluidos:

- Entrada visible y comprensible desde el producto.
- Inicio voluntario de la autorización.
- Consentimiento y permisos solicitados.
- Protección de estado, callback, identidad y vinculación al turno correcto.
- Persistencia y protección de credenciales.
- Creación efectiva del evento.
- Reprogramación y actualización del evento correcto.
- Cancelación y retirada del evento correspondiente.
- Reintentos, permisos revocados, tokens vencidos y fallos de Google.
- Aislamiento entre pacientes y consultorios.

No introduzcas cambios globales peligrosos en las autorizaciones del usuario por confundir la eliminación de un evento con la revocación del acceso a todo el proyecto Google.

### Video de verificación

Prepará **una experiencia real, completamente funcional y comprobada** que permita grabar el video requerido por Google.

El recorrido debe poder mostrar, de acuerdo con los requisitos oficiales vigentes:

- La aplicación Cita Suite y la función accesible desde su interfaz.
- El inicio de OAuth.
- La pantalla de consentimiento de Google en inglés.
- La identidad de la aplicación y los permisos solicitados.
- La identificación del cliente OAuth cuando Google la requiera, incluida su visualización en la barra de direcciones si corresponde.
- El uso efectivo del permiso para gestionar eventos.
- Creación, actualización y cancelación, conforme a lo que la verificación de Google deba demostrar.

Prepará un **guion exacto, en orden de ejecución**, con la cuenta y los datos sintéticos necesarios, los pasos que debe mostrar el usuario y las comprobaciones previas.

El usuario realizará la grabación y su presentación administrativa. Dejá las instrucciones necesarias para el formato, la carga del video como **No listado** en YouTube y el envío a Google.

No inventes requisitos oficiales: contrastalos con la documentación actual.

No expongas secretos, tokens, datos privados ni credenciales en el video.

**La función debe quedar realmente lista para demostrar, no simplemente documentada como pendiente de grabar.**

La aprobación final de Google es una decisión externa que no controlás. Distinguí claramente esa dependencia administrativa de la obligación de terminar toda la implementación y preparación bajo nuestro control.

## 9. Correo electrónico: integración real y completa

**El email es un canal central de notificaciones de Cita Suite.** No puede quedar fuera de la implementación ni resolverse con plantillas que nunca llegan a una bandeja.

La solución aprobada utiliza **Zoho CPaaS**, en sustitución de Resend.

Debés completar toda la cadena operativa: preparación del emisor, configuración, generación del mensaje, elección autorizada del destinatario, persistencia, despacho, reintentos, recepción de resultados, conciliación y comprobación real.

Los requisitos incluyen, según contexto:

- Comprobantes de reserva.
- Avisos de reprogramación y cancelación.
- Solicitudes pertinentes de seña.
- Recordatorios por email a **72 y 24 horas**.
- Acciones y enlaces coherentes con el estado actual.
- Preferencias configurables por consultorio.
- Correcciones y cambios de contacto.
- Supresión de envíos que ya no correspondan.
- Registro de estados y recuperación ante errores.

Los tiempos de email **no sustituyen** las reglas históricas de push y calendario, que incluyen avisos a 24 y 2 horas. Investigá y respetá los contratos vigentes de cada canal.

### Identidad del consultorio y configuración

Cada consultorio debe utilizar un subdominio verificado de `cita-suite.com.ar` como identidad de envío, conforme a las decisiones aprobadas.

No compres otro dominio ni sustituyas arbitrariamente el modelo por un único remitente compartido.

Nombre, logo, contenido y Reply-To deben corresponder al consultorio. No incluyas promoción ni branding de Cita Suite en el cuerpo cuando el contrato exige identidad del consultorio.

El sistema debe distinguir **preferencia de envío habilitada** de **remitente efectivamente preparado para enviar**.

Los envíos están habilitados por defecto cuando corresponde, con la posibilidad de desactivarlos conforme a la configuración y las reglas aprobadas.

Los botones pertinentes también deben respetar sus controles independientes.

El comprobante de un turno vigente puede ofrecer CANCELAR y REPROGRAMAR si esas acciones están autorizadas. **El comprobante de cancelación no puede ofrecer ninguna de las dos.**

Un enlace debe resolver el estado actual y su autoridad, sin asumir que el turno continúa igual que cuando se generó el mensaje.

### Entrega, cola y fallos

Implementá y verificá lo que falte del sistema de salida: eventos o trabajos duraderos, consumidores, coordinación, leases o equivalentes justificados, protección contra duplicaciones, estados inciertos, reintentos y conciliación.

No llames a Zoho mientras retenés bloqueos transaccionales si eso compromete los contratos de concurrencia y recuperación.

Investigá el comportamiento real de Zoho, sus límites, autenticación, webhooks y posibilidades de conciliación.

No prometas **exactamente una entrega externa** si el proveedor y el protocolo no permiten garantizarla.

Diferenciá aceptación por API, recepción por el servidor de destino, llegada a la bandeja y lectura humana.

No marques un trabajo como resuelto antes de persistir una consecuencia recuperable. Tampoco reenvíes ciegamente un mensaje cuando se desconoce si el proveedor ya lo aceptó.

Los destinatarios y las capacidades deben revalidarse tan cerca del envío como corresponda. Una dirección que figuraba al crear el turno no autoriza indefinidamente futuros envíos después de una corrección de contacto.

Verificá mensajes HTML y texto plano, clientes relevantes, enlaces, imágenes bloqueadas, visualización móvil y fallos de formato.

La conexión administrativa previa con Zoho **no es evidencia de integración transaccional terminada**.

### Comprobación externa

Usá el buzón de prueba acordado y las conexiones disponibles, verificando primero su estado.

Realizá envíos reales controlados y comprobá la recepción, el contenido y el comportamiento de los enlaces.

No infieras recepción porque una API respondió satisfactoriamente.

No utilices pacientes reales ni destinatarios no aprobados. No publiques cuerpos privados de correos, secretos, tokens o respuestas sensibles del proveedor en GitHub o en documentación pública.

## 10. Coordinación de recordatorios y presupuesto operativo

Inspeccioná el mecanismo de tareas programadas, especialmente el histórico `scheduled-jobs.ts`, y cómo se coordinan actualmente los recordatorios push y los demás trabajos.

El registro técnico identifica un riesgo relevante: el envío push podía consumir el presupuesto de ejecución compartido antes de que otros trabajos tuvieran oportunidad de progresar.

No tenés que implementar su solución prevista. **Tenés que investigar y eliminar el riesgo real de inanición, pérdida de progreso o interferencia entre canales.**

Analizá las restricciones efectivas de Cloudflare Workers, la disponibilidad de cron, límites de llamadas externas, tiempo, CPU, reintentos, volumen y concurrencia.

No presupongas que agregar una segunda llamada de despacho después de push alcanzará para que el correo funcione.

Diseñá una coordinación donde cada canal progrese de forma verificable y donde un fallo o una cola atrasada no produzcan silenciosamente la pérdida de otros avisos.

Prestá atención a los cambios de horario, cancelaciones y correcciones durante la espera de un trabajo.

No sobredimensiones infraestructura para una escala que todavía no existe. Tampoco aceptes una solución frágil sólo porque actualmente hay un consultorio.

No contrates servicios, créditos ni capacidades pagas sin autorización.

## 11. Integridad transversal: turnos, identidad, autogestión y dinero

Una notificación correcta depende de que los procesos que la originan también sean correctos.

Por eso debés completar y verificar los contratos relacionados con:

**Reservas:** captura y validación de email, requisitos por canal público, excepción de recepción autorizada, persistencia correcta del paciente y del turno, e información económica presentada antes de confirmar.

**Autogestión:** consulta del turno mediante capacidad válida, cancelación, reprogramación autónoma, disponibilidad actual, duración, profesional, modalidad y condiciones aplicables.

**Operaciones del personal:** acciones permitidas por rol, preparación de enlaces, cambios de turno, marcas manuales, contacto, información económica y trazabilidad.

**Identidad y destinatarios:** vinculación correcta del paciente, revisiones de contacto, revocación de enlaces, reparación de identidad, permisos efectivos y aislamiento entre consultorios.

**Señas y dinero:** obligaciones, importes recibidos, pérdida o conservación de aplicación, créditos, correcciones, hechos posteriores a cancelación e información económica previa.

Respetá las reglas comerciales existentes. La aplicación registra hechos económicos; **no se está encargando un procesador bancario ni una contabilidad general**.

No inventes pagos, devoluciones, penalidades retroactivas, aceptación de condiciones ni decisiones comerciales ausentes.

Una condición económica configurada no demuestra por sí sola que el paciente fue informado antes de reservar.

Los cambios autónomos deben conservar la identidad y continuidad contractual del turno según la especificación. No conviertas una reprogramación en una nueva reserva desligada de su historia, salvo que exista un requisito explícito que lo justifique.

Evitá acciones ofrecidas fuera de contexto: no se puede cancelar un turno cancelado, reprogramar mediante un enlace revocado ni aceptar una seña como si un cambio de pantalla fuera una transacción.

Las operaciones deben conservar las garantías relevantes de autorización, atomicidad, idempotencia, persistencia, concurrencia y recuperación.

### Investigá las consecuencias de tus propias correcciones

No quiero soluciones que arreglen un fallo introduciendo otro más difícil de detectar.

Por ejemplo:

- Un bloqueo contra duplicados puede suprimir un recordatorio legítimo tras reprogramar.
- Un reintento puede generar una operación monetaria duplicada.
- Un cambio de contacto puede dejar un mensaje pendiente dirigido al destinatario anterior.
- Una cancelación puede retirar el evento de un calendario pero dejar otro canal comunicando una fecha equivocada.
- Una validación antes de obtener un bloqueo puede dejar de ser válida cuando finalmente se escribe.
- Una respuesta HTTP perdida puede corresponder a una operación realmente confirmada.
- Una revisión antigua puede describir el mismo valor aparente después de cambios intermedios, aunque ya no represente la misma autoridad.
- Una optimización del presupuesto de correo puede demorar indebidamente el push.

**No basta con demostrar que la corrección evita el síntoma original. Debés demostrar que preserva los invariantes de negocio y no genera consecuencias negativas relevantes en otros recorridos.**

## 12. Nivel de verificación exigido

Quiero una **auditoría técnica y funcional extraordinariamente rigurosa del alcance completo de este encargo**.

No te conformes con revisar archivos, ejecutar tests verdes o inspeccionar interfaces aisladas.

Elegí pruebas que realmente permitan sostener las garantías:

- Contratos funcionales y casos adversarios.
- SQL real, permisos, RLS y transacciones.
- Carreras relevantes en ambos órdenes.
- Reintentos, respuestas perdidas y efectos parciales.
- HTTP, SSR, formularios nativos y JavaScript.
- Navegación completa del paciente y del personal.
- Integración de calendarios y OAuth.
- Envío y recepción real de correo.
- Push observado en teléfonos físicos.
- Producción con la revisión exacta publicada.

Investigá las causas de los fallos. No aumentes timeouts, fuerces clics, ocultes aserciones o cambies expectativas simplemente para conseguir una corrida verde.

Cuando uses un doble de prueba, indicá qué contrato demuestra y qué no puede demostrar.

Una prueba SQL no demuestra recepción de email. Un evento creado mediante API no demuestra que Samsung Calendar lo mostrará. Un archivo descargado no demuestra que Apple Calendar haya emitido una alerta.

Reutilizá resultados históricos válidos cuando la implementación correspondiente no haya cambiado. Realizá nuevas pruebas cuando cambien los contratos, la integración o la revisión que efectivamente se publicará.

No impongas números arbitrarios de casos ni una metodología rígida de TDD. Usá el rigor necesario para demostrar cada propiedad importante.

### Calidad de interfaz

Las pantallas que se modifiquen deben ser claras, consistentes, accesibles y apropiadas para móviles.

Comprobá estados vacíos, bloqueados, exitosos y fallidos; textos; foco; navegación; errores recuperables; carga; tamaños de pantalla; temas y contraste.

Respetá el diseño vigente y las reglas de `apps/web/DESIGN.md` y las superficies correspondientes.

No emprendas una renovación estética global porque estés tocando una pantalla. La tarea futura P2 continúa pospuesta.

### Frontera de la auditoría

**Sí debés auditar profundamente todo lo que entregues y todas sus interacciones relevantes con el resto del producto.**

**No debés iniciar todavía la auditoría global definitiva de toda Cita Suite.**

Esa auditoría general está prevista para después de otros cambios que el usuario quiere realizar.

Si encontrás problemas independientes, documentalos y evaluá su gravedad. Corregí los que afecten las garantías de este encargo. No conviertas automáticamente cualquier hallazgo ajeno en una ampliación ilimitada del trabajo.

La auditoría futura no puede utilizarse como excusa para entregar incompleto o sin verificar lo que estás implementando ahora.

## 13. Restricciones operativas y protección del proyecto

Respetá `AGENTS.md` y las reglas vigentes de sincronización, privacidad, seguridad y consumo de recursos.

La computadora local tiene **RAM limitada**. No inicies múltiples compilaciones pesadas, contenedores o suites de navegador simultáneamente.

Usá el repositorio auxiliar de verificación y CI hospedado para las pruebas pesadas cuando corresponda, en ejecuciones secuenciales y con snapshots reproducibles.

Comprobá el estado de procesos existentes antes de duplicarlos.

No alteres ni elimines trabajo de otras sesiones para hacer pasar la guardia de sincronización.

No utilices `git reset`, `clean`, restauraciones globales ni `git add -A` indiscriminadamente.

Controlá y documentá la relación entre:

- Archivos locales.
- Rama y revisión de GitHub.
- Código y migraciones pendientes.
- Artefacto construido.
- Versión realmente publicada.
- Configuración de proveedores y trabajos programados.

`node scripts/check-repo-sync.mjs` es una referencia operativa importante. Investigá sus resultados reales; no los maquilles.

No confundas un commit subido a GitHub con una publicación en producción.

### Recuperación compatible

Antes de desplegar cambios de esquema, permisos, dinero, identidades, colas o capacidades, prepará un procedimiento de recuperación **compatible con esos cambios**.

En el pasado apareció una recomendación de volver a `59f81e89` para recuperar un cliente anterior de Calendar. Esa acción también habría deshecho el modo claro.

**No uses ese rollback histórico por inercia.**

Del mismo modo, volver sin análisis a V12b después de introducir nuevas restricciones, migraciones o contratos puede ser incompatible.

Diseñá una recuperación proporcionada al riesgo real, sin recurrir a maniobras destructivas ni a garantías ficticias.

### Credenciales y pruebas reales

Respetá las ubicaciones privadas y las reglas de custodia existentes.

La documentación de TestKase y Zoho puede indicar dónde están las credenciales. No copies claves al chat, al código, a evidencias públicas ni a commits.

No compres servicios, créditos o cuotas.

No alteres la configuración real de Natalia ni inventes datos comerciales para cerrar casos de aceptación.

Usá identidades y turnos sintéticos. Antes de enviar comunicaciones externas, confirmá que los destinatarios son los ya acordados para pruebas.

Preservá la privacidad de los teléfonos personales.

## 14. Cómo quiero que trabajes

No quiero que te limites a cumplir una secuencia impuesta por este prompt. Quiero un proceso de ingeniería autónomo y crítico.

**Primero:** recuperá los requisitos, la implementación y la evidencia real. Identificá qué sabés y qué no.

**Después:** elaborá el plan integral, decidí las prioridades según dependencias y riesgo, y empezá a investigar y resolver los problemas.

**Durante el trabajo:** integrá los cambios de forma coherente, contrastá tus decisiones con pruebas relevantes, corregí las causas raíz y verificá sus consecuencias.

**Antes de publicar:** comprobá la revisión integrada final, su compatibilidad con los datos y proveedores reales y el procedimiento de recuperación.

**Después de publicar:** verificá producción, dispositivos y entregas externas según corresponda. Contrastá los resultados con todos los requisitos.

Estas son etapas lógicas, **no una obligación de reproducir el orden o la arquitectura sugeridos en los registros históricos**.

Tenés permiso para cambiar la estrategia cuando la evidencia lo justifique.

No me consultes por cada decisión técnica que puedas resolver profesionalmente. Sí pedí una decisión cuando exista una alternativa comercial real que no esté previamente resuelta o una acción fuera de las autorizaciones vigentes.

No confundas una limitación de acceso con un defecto del producto. Si una herramienta o servicio no permite una verificación determinada, investigá alternativas apropiadas y documentá exactamente la limitación.

No inventes resultados, no presentes hipótesis como hechos y no atribuyas una prueba a una versión diferente de la efectivamente evaluada.

## 15. Documentación y trazabilidad de decisiones

Quiero poder entender en el futuro **qué se construyó, por qué se construyó así y qué evidencia sostiene que funciona**.

Registrá las decisiones significativas con su problema, alternativas relevantes, fundamento técnico, restricciones, riesgos y condiciones que podrían volverlas inválidas.

Preservá las decisiones históricas, pero diferenciá claramente cuáles siguen vigentes y cuáles fueron sustituidas.

No produzcas documentos repetidos para aparentar exhaustividad.

Las especificaciones, contratos, tests, instrucciones operativas y documentación pública deben ser coherentes.

La historia de Git debe permitir reconstruir el desarrollo, sin convertirse en el único lugar donde exista la explicación de una decisión crítica.

El índice documental debe conducir a la información vigente y detallada. Al terminar, entregame **las ubicaciones exactas y enlaces directos** a esa documentación, además de un resumen claro de las modificaciones y comprobaciones realizadas.

No introduzcas enlaces de documentación de ingeniería en la aplicación para pacientes o profesionales salvo que sean parte de un requisito real.

## 16. Condiciones de cierre — no negociables

Tu encargo termina cuando puedas demostrar, mediante evidencia suficiente y verificable, que se alcanzó **un único resultado integral**.

Debe quedar resuelto lo siguiente:

**Notificaciones push:** el problema original de Chrome Android está corregido; los permisos y bloqueos se manejan correctamente; existe recuperación cuando una prueba no puede enviarse o no llega; los recorridos funcionan en los dispositivos disponibles y la entrega real fue comprobada donde técnicamente corresponde.

**Calendarios:** se investigaron y resolvieron las mejores alternativas para Samsung, otros Android y Apple; el producto no depende de supuestos falsos sobre aplicaciones instaladas; los eventos y sus avisos funcionan bajo condiciones conocidas; se gestionan adecuadamente las reprogramaciones, cancelaciones y limitaciones de cada mecanismo.

**Google OAuth:** existe una entrada real desde la interfaz, el consentimiento funciona, los eventos pueden crearse, actualizarse y eliminarse correctamente, y el recorrido está comprobado y preparado para grabar el video oficial de Google.

**Correo electrónico:** la solución con Zoho está operativa de extremo a extremo, con emisores, plantillas, destinatarios, configuración, colas, consumidores, reintentos, observaciones, recordatorios, comprobantes y pruebas de recepción real.

**Integración con el producto:** las reservas, la autogestión, los cambios de turno, las cancelaciones, las señas, los contactos, las identidades, los permisos y las operaciones pertinentes funcionan con los avisos de manera consistente.

**Requisitos heredados:** todos los requisitos y casos de aceptación de la fase E están satisfechos y verificados. **No queda ningún proceso o trabajo de E pendiente para una continuación posterior**, aunque hayas utilizado una estrategia completamente distinta de la sugerida en la documentación de continuación.

**Seguridad y fiabilidad:** las garantías relevantes de concurrencia, aislamiento, autorización, revocación, idempotencia, recuperación y consistencia económica se sostienen frente a fallos y escenarios adversarios.

**Publicación:** los cambios y las migraciones correspondientes están efectivamente publicados; los trabajos externos están operativos; la revisión y la configuración de producción son conocidas; se realizaron las comprobaciones necesarias sobre ese destino.

**Documentación:** las decisiones, contratos, evidencias, instrucciones operativas, historial y estado vigente son coherentes, trazables y están accesibles mediante enlaces directos.

No declarés terminado el encargo por acumular tests verdes, cerrar tickets o haber completado una lista de implementación.

**El criterio de cierre es que el producto efectivamente cumpla todos los requisitos, sin trabajo funcional pendiente dentro de este alcance.**

Las únicas actividades expresamente reservadas para después son las tareas posteriores P1, P2 y P3 ya pospuestas, la auditoría global definitiva de Cita Suite y las acciones administrativas externas que dependan del usuario o de terceros, como grabar/presentar el video y obtener la decisión de Google. Estas excepciones no autorizan a dejar sin terminar la preparación técnica bajo tu responsabilidad.

Si aparece una limitación real que impida acreditar algún requisito, no la ocultes ni declares un cierre ficticio. Identificá la causa concreta, explorá las alternativas y agotálas dentro de las autorizaciones y recursos disponibles.

## 17. Tu primera acción

Empezá recuperando la realidad actual del proyecto y toda la documentación necesaria.

Contrastá las fuentes, revisá las implementaciones existentes y construí tu propia comprensión de los problemas y dependencias.

Después, dejá persistido el plan integral y **avanzá autónomamente hacia la implementación, las pruebas, la integración y la publicación**.

No me devuelvas únicamente un diagnóstico ni una propuesta teórica. El encargo es ejecutar el trabajo completo.

No priorices arbitrariamente la última corrección de esta conversación sobre los objetivos anteriores. **Todas las condiciones aquí expuestas forman parte del mismo mandato y deben permanecer presentes durante toda la ejecución.**

Quiero una solución integral, técnicamente excelente, comprobada en condiciones reales y mantenible; no un conjunto de parches que parezcan resolver los problemas por separado.
