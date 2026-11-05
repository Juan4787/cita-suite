# Pendientes vigentes de Cita Suite

**Para qué existe:** Juan pidió el 31 de octubre de 2026 que no se pierda nada de lo que queda pendiente (plan de señas y avisos, sección 12.15). Esta es la lista única. Cada punto remite a su documento de origen, que conserva el detalle. Al cerrar un punto, se lo marca como hecho acá con la fecha y la evidencia, y se actualiza su documento de origen.

**Última revisión:** 4 de noviembre de 2026, autorización íntegra de E (plan 12.20), preparación y regla de continuidad. Las otras entradas conservan sus fechas y evidencias. E1 tiene fundamentos en implementación/verificación, sin aceptación integral ni publicación; P1/P2/P3 pospuestas por el pedido posterior de plan 12.26, sin iniciarlas al cerrar E.

## 1. Lo que sigue para la entrega a Natalia

1. **Cargar los datos que faltan** (punto 2), empezando por la dirección del consultorio. Cada uno se carga con el mismo cuidado: ensayo, aplicación y comprobación como paciente.
2. **Revisar con Natalia** las observaciones de las pruebas del 1 de noviembre:
   - las indicaciones de documentación también se muestran en la consulta online y hablan de «traer» la orden;
   - el paso «¿Con quién?» ofrece «Equipo de profesionales» aunque haya una sola profesional; es un comportamiento general de la app, y puede mejorarse si molesta.
3. **Pruebas finales antes de la entrega,** con los datos completos. Se hacen como el 1 de noviembre: reservas marcadas «PRUEBA Cita Suite…» con `reservar-prueba.mjs`, y limpieza comprobada contra una foto previa con `limpiar-pruebas.mjs`, adaptando sus identificadores.
4. **Contarle a Natalia** que su cuenta ya tiene la agenda cargada. Si edita los datos del consultorio antes de cargar la dirección, la app se la va a pedir.

## 2. Datos que faltan de Natalia (se cargan cuando lleguen; no se inventan)

Fuente: `docs/clientes/natalia-frutos/informacion-20261029.md`, secciones 4 y 5, y plan 12.16.

1. **Dirección del consultorio.** Es lo más importante antes de la entrega: el comprobante de un turno presencial la muestra, y la app la exige para guardar los datos del consultorio mientras la reserva pública está encendida. Si Natalia edita sus datos antes de cargarla, la app se la va a pedir.
2. **Cómo es la consulta online del miércoles a las 16:30** (plataforma o enlace). Hoy el texto es provisorio: «Antes del turno, el consultorio te va a indicar cómo conectarte a la consulta online.» Hay que confirmarlo o reemplazarlo.
3. **Modalidad de lunes, martes y jueves.** Hoy esos días se ofrecen sólo presenciales (provisorio aprobado por Juan).
4. **Honorarios vigentes** (proyección de noviembre a marzo) y cómo informarlos (sección 4, puntos 1 y 3). Hoy no se publica ningún precio: los de octubre ya no rigen.
5. **Seña:**
   - alias, CBU y titular;
   - si es la misma para las dos prestaciones y si se actualiza (pregunta 2);
   - si quiere la cancelación automática (pregunta 3);
   - las condiciones de cancelación y reprogramación (pregunta 8).

   La seña sigue apagada: interruptor general apagado y ninguna política cargada.
6. **Token:** confirmar que IAPOS y las de orden impresa, salvo OSPAC, no lo requieren (pregunta 4). Hoy hay una ayuda fija bajo la pregunta de obra social; mostrarla sólo al elegir esas obras sociales necesita una función nueva (sección 4, punto 2).
7. **Equipo:** el correo y el rol de Aye. Los tipos de teléfono ya no son requisito de D: el aviso al celular fue reemplazado por avisos internos (plan 12.23). Si Aye se agrega como profesional, la app crea las prestaciones genéricas «Consulta» y «Otro servicio» de 30 minutos: hay que ocultarlas o borrarlas para no romper la grilla de 60.
8. **Web:**
   - fotos, presentación y datos de contacto (pregunta 7);
   - revisar con Natalia que la web presenta cuatro tipos de consulta (entre ellas fitoterapia y medicina del estrés), mientras el turnero ofrece las dos que ella pidió;
   - blog y talleres siguen fuera del alcance.
9. **Anticipación de las reservas:** hoy rigen los valores por omisión (hasta 60 días, sin reservas para el mismo día y sin anticipación mínima). Hay que confirmarlos con ella.
10. **Su dominio propio:** cuando lo compre, se carga en `PRODUCTION_NATALIA_SITE_URL` (`scripts/lib/production-deploy.mjs`), se agrega como origen de su integración y como dominio en Vercel, se redirige la dirección provisoria y se publica. Desde ahí la web se indexa, con dirección canónica en cada página y mapa del sitio. Hasta entonces, cada página pide no ser indexada (decisión propia 12 del registro).

## 3. Etapas D y E: alcance actual

1. **D celular reemplazada, sin implementar:** avisos internos generales de horarios liberados, con patrón similar a Seguimientos. Es P3 de las [tareas posteriores a E](tareas-posteriores-a-e-20261103.md), después de cerrar E, P1 cancelación desde recepción y P2 estilos completos claro/oscuro. No retomar push al personal ni pedir tipos de teléfono para esta D. Las tres tareas están pospuestas y no iniciadas por pedido posterior de Juan (plan 12.26); no avanzar al cerrar E.

<a id="etapa-e-pendientes"></a>

2. **E, correo y autogestión: ejecución completa autorizada, E1 en implementación/verificación; Zoho y Gmail conectados.** [Registro activo y continuidad](ejecucion-etapa-e-20261103.md). Q01/Q02 resueltas; E1 en implementación/verificación; ningún comportamiento nuevo de E publicado.
   - Fuente: [plan 12.18](propuesta-senas-avisos-natalia.md#etapa-e-vigente) y [especificación completa](etapa-e-correo-autogestion.md). La revisión de código/documentación está hecha; ningún comportamiento nuevo de E está publicado.
   - **Ya hecho por Juan:** registro en Zoho y prueba de dos envíos. Informó KYC pendiente y 100 correos gratuitos diarios; pagará al completarlo. No falta crear cuenta Resend ni volver a crear Zoho.
   - **Al iniciar:** comprobar dominio/remitente/región, credenciales fuera de chat/git, cuota/saldo/vencimiento reales, configuración del emisor, webhooks y buzones autorizados. Sus dos mensajes no prueban integración ni recepción/acciones desde Cita Suite.
   - **Trabajo técnico en implementación/verificación parcial:** email requerido configurable y aviso de recepción; reprogramación autónoma transaccional con revisión; historia y nueva exigencia de seña; gestión revocable; cola, plantillas del consultorio, avisos 72/24 y los casos de aceptación.
   - **Prueba de cierre pendiente:** integración real con Zoho, recepción en los buzones acordados, botones desde el correo, consistencia de agenda/dinero/calendario y controles de consumo/recuperación. La aceptación de cada caso se registra por capa; ninguno tiene cierre integral todavía.
   - **Economía:** aceptado gasto controlado de correo con un consultorio. KYC/compras de créditos a cargo de Juan, sin recarga automática ni cambios de infraestructura/Auth.
   - **Continúa pendiente de la clienta:** condiciones de devolución al cancelar y datos de la seña del punto 2.5. La pérdida acordada al reprogramar no define esas devoluciones.
   - **Conexión local terminada el 3 de noviembre:** Juan pidió acceso por terminal y conservarlo al reiniciar ([12.19](propuesta-senas-avisos-natalia.md#zoho-terminal-vigente)). OAuth, consultas y renovación comprobados; herramienta versionada y credenciales privadas persistentes. [Guía y comandos](../architecture/zoho-cpaas-terminal.md). No necesita una terminal abierta.
   - **Ahora:** E1/E2/E3 sin publicar ni SQL E productivo. SQL26 (41929889370) y browser de recepción/integración (41931144923, c85bce8) conservan su aprobación. Borrador27: veinte grupos SQL de alta pública informada aprobados en 41960959120, pero corrida rechazada por limpieza del nuevo arnés; se corrige el orden turno→consultorio y el diagnóstico, sin cambios del producto. Aún faltan las carreras posteriores/tipos oficiales y fast/browser de este borrador; 64 dirigidas locales aprobadas. Nuevo browser de resumen/cambio de política preparado. Siguiente: repetir SQL27 antes de fast/browser; luego altas manuales informadas/contacto/outbox/distribución/SN14/Zoho/correo/E5–E6. Checkpoint E3.12. Producción V12b, ningún envío nuevo ni cierre E; P1/P2/P3 pospuestas.

## 4. Lanzamiento y operación general

1. **Google: Calendar con proyecto propio** (estado al 2 de noviembre de 2026, 03:20 UTC).

   **Hecho:**
   - **Search Console:** Juan lo confirmó el 2 de noviembre, literal: «la web ya esta verificada por google».
   - **Decisión:** proyecto aparte y gratis para Calendar, en lugar del dominio propio de Supabase, que es pago. El proyecto anterior, «Dashboard Odontologia», no puede verificarse para Calendar porque comparte la pantalla de permiso con el ingreso con Google, y el ingreso exige el dominio de Supabase.
   - **Proyecto «Cita Suite Calendar»** (`cita-suite-calendar-513502`), creado y configurado por Juan:
     - cliente web «Cita Suite», `702611060405-mkcoqcsgsod4s3cjb1cliqmjn9th33vs.apps.googleusercontent.com`;
     - retorno único oficial y permiso único `calendar.events.owned`;
     - privacidad y términos directos de la app, logo y API habilitada;
     - **publicado («En producción») y con la información de marca verificada por Google.**
   - **En producción desde las 03:03 UTC:** el Worker `app` usa ese cliente (versión `986cf666-ae09-423b-ae05-1928007dccde`, código V11f).
   - **Comprobado de punta a punta:**
     - un turno sintético «PRUEBA Calendar Cita Suite» del consultorio ficticio Ramirez;
     - Juan aceptó el permiso desde la computadora y vio el evento en el Google Calendar de su celular;
     - la base guardó la conexión del cliente nuevo y el evento activo;
     - la cancelación pública del turno borró el vínculo y retiró la autorización sobrante.

     Recibos en `.verification/calendar-proyecto-propio-20261102/`.
   - **Credenciales:** en `ACCESOS-GOOGLE-CITA-SUITE/GOOGLE-CALENDAR-PROYECTO-CITA-SUITE/`. `GOOGLE-CALENDAR/` es el cliente anterior.
   - **Vuelta atrás al cliente anterior (corregido el 3 de noviembre):** Desde el modo claro, volver al cliente anterior **no** se hace con una vuelta atrás de versión: `59f81e89…` desharía también V11f y V12b. Si hiciera falta, se cargan con `wrangler secret bulk` el ID y el secreto del JSON de `ACCESOS-GOOGLE-CITA-SUITE/GOOGLE-CALENDAR/`, como hizo `instalar-cliente-calendar.mjs` con el cliente nuevo. Nunca volver a `59f81e89…`.

   **Falta:**
   1. ~~**Juan: confirmar que el evento de prueba desapareció** de su Google Calendar.~~ **Hecho:** Juan confirmó el 2 de noviembre, literal, «si, desaparecio de mi google calendar».
   2. ~~**Juan: declarar el permiso en «Acceso a los datos»**~~ **Hecho el 3 de noviembre** (aparece en «Tus permisos sensibles»). Falta la justificación, de 751 caracteres, en la sección de la guía de verificación. Antecedente: La tabla «Tus permisos sensibles» está vacía en la captura de Juan. Pasos en `docs/architecture/verificacion-google-calendar.md`, sección «Declarar el permiso». Hasta hacerlo, la verificación no puede pedirse completa.
   3. **Juan: pedir la verificación del permiso delicado** desde el «Centro de verificación» del proyecto nuevo. El agente preparó el texto y el guion del video (registro, 2 de noviembre). **Bloqueado el 3 de noviembre:** la función gestionada no tiene botón para que un paciente la inicie, así que no se puede grabar el recorrido (punto 7). Hasta que Google la apruebe:
      - los pacientes ven el aviso de «app no verificada» y deben tocar «Avanzada → Ir a Cita Suite»;
      - Google admite hasta 100 usuarios.
   4. **El ingreso con Google sigue en «Dashboard Odontologia»,** con su aviso. Es aparte y no bloquea a Natalia.
   5. **«Dashboard Odontologia», por ahora sin tocar** (recomendación del 2 de noviembre):
      - su cliente de ingreso lo usa Supabase y no se modifica;
      - su cliente de Calendar anterior se conserva como vuelta atrás.

      Cuando el cliente nuevo lleve unos días estable, o con la verificación aprobada, el agente avisa para que Juan borre ese cliente anterior y quite el permiso de Calendar de la pantalla de permiso de ese proyecto. Así ese proyecto queda sólo para el ingreso.

2. **Opcionales de `docs/architecture/dominio.md`, a cargo de Juan en paralelo.** Quedan pendientes hasta que Juan los confirme:
   - redirección de `www`;
   - TLS mínimo 1.2;
   - registros SPF y DMARC;
   - borrar las tres direcciones viejas `https://cita-suite.com.ar/…` de Supabase;
   - borrar el proyecto de Vercel `presentacion-cita-suite`;
   - borrar el Worker `cita-suite-landing`, pidiéndoselo al agente.
3. **Segundo consultorio:** antes de incorporarlo, Juan contrata Supabase Pro con tope de gasto y se demuestran dos consultorios en ese destino (`docs/architecture/capacidad.md`). La espera ocasional de 2 a 3 segundos es una desviación aceptada sólo para el primer consultorio.
4. **Límites «por IP» de Auth:**
   - el ingreso y el alta los hace el servidor de la app en Cloudflare;
   - la base no guarda la auditoría de Auth (0 eventos en 30 días), así que desde ahí no se puede saber qué dirección ve Supabase;
   - hay que mirarlo en Supabase → Logs → Auth: si es una dirección de Cloudflare, esos límites se comparten entre todos los usuarios de la app;
   - para un consultorio sobra; revisarlo antes del segundo.
5. **Dominios oficiales** (Juan, 12.16): `https://app.cita-suite.com.ar` para la app y `https://cita-suite.com.ar` para la landing.
   - `app.cita-suite.workers.dev` sigue siendo el mismo Worker, pero queda sólo como origen técnico: enlaces enviados antes del dominio, verificaciones y la vuelta atrás de Calendar registrada en Google.
   - Nada que vea un paciente o un consultorio debe usarlo.
   - Pendiente menor para la próxima versión: la constante `PUBLIC_SITE_URL_FALLBACK` (`apps/web/src/lib/constants.ts`) todavía es workers.dev. Sólo la usa el restablecimiento de contraseña si falta `PUBLIC_SITE_URL`, que en producción está configurada con el dominio oficial.

6. **Para la próxima versión de la app** (no cambian nada de lo publicado):
   - los dos programas de armado de CI con el mes de Buenos Aires (`scripts/serve-booking-fixture.mjs` y `scripts/staging-release-fixture.mjs`). Ya están corregidos en el árbol de trabajo y listados en `.verification/natalia-configuracion-20261101/archivos-proxima-version.txt`;
   - la constante `PUBLIC_SITE_URL_FALLBACK` (punto 4.5).

   Hasta entonces, las pruebas de navegador de reservas fallan en CI entre las 21:00 y las 23:59 del último día de cada mes en Argentina: la prueba arma el precio con el mes en UTC (registro, 1 de noviembre). La app no tiene ese defecto.

- **Insignia del botón de cuenta cortada a 1280 px** (hallazgo del 2 de noviembre, anterior a la campaña de modo claro).
  - Cuándo pasa: con un nombre de consultorio largo y seis secciones en la barra, la insignia del plan («Permanente») se corta en el botón de cuenta.
  - Evidencia: `.verification/modo-claro-20261102/barras/barras-dark-1280.jpg` (consultorio de demostración).
  - Por qué no se arregló ahora: el diseño principal no cambió fuera de los colores, así que no lo causa el modo claro.
  - Pendiente: decidir si la insignia se oculta o se acorta cuando falta lugar.

- **Divergencia del repositorio: resuelta el 2 de noviembre.** `origin/main`, la rama local y la línea de producción (V12b) quedaron unidas en `main`, sin perder commits. El estado vigente está en `docs/ESTADO-VIGENTE.md` y lo comprueba `node scripts/check-repo-sync.mjs`.
- **Plantilla del correo de recuperación** (`supabase/templates/recovery.html`): modificada en otro trabajo. No está verificado si la versión cargada en Supabase coincide con el archivo.

7. **Recordatorio del paciente en Android: defectos del flujo de avisos y del calendario** (Juan, 3 de noviembre).

   El diagnóstico del agente se hizo sobre el código de producción V12b (`routes/turno/[token]/+page.svelte`). La lógica es idéntica en `main` (`lib/components/appointments/PublicAppointmentPage.svelte`), archivo en curso en la etapa E: hay que coordinar antes de editarlo.

   **Lo que vio Juan en su teléfono,** con las notificaciones de Chrome apagadas en el teléfono:
   - tocar «Permitir» en la pregunta del navegador no cambia nada ni ofrece otra salida;
   - al tercer intento aparecen los pasos de los ajustes del teléfono, con el botón «Ya estaba activado»;
   - ese botón lleva a los pasos del sitio, con «Ya lo permití», que no hace nada.

   **Causas en el código:**
   1. **Pregunta sin respuesta:** si después de la pregunta el permiso sigue «sin decidir» (`default`), sólo Samsung Browser pasa a la recuperación del teléfono. Chrome vuelve al mismo botón (`awaiting_permission`), sin guía ni alternativa.
   2. **Bloqueo automático:** Chrome bloquea solo el permiso de un sitio después de tres preguntas sin aceptar, durante siete días ([diseño de Chromium](https://groups.google.com/a/chromium.org/g/blink-dev/c/fHl9GNxPPpA)). El permiso pasa a «bloqueado» (`denied`) y recién ahí aparece una guía. Eso explicaría el «tercer intento»: falta confirmarlo en el teléfono.
   3. **Guías como alternativas:** con el permiso bloqueado, la página trata los ajustes del teléfono y los del sitio como alternativas («Ya estaba activado» pasa de una guía a la otra). En el caso de Juan hacían falta las dos cosas.
   4. **Botón sin respuesta:** «Ya lo permití» vuelve a leer el permiso y, si sigue bloqueado, no muestra nada.
   5. **Sin alternativa:** con el permiso bloqueado en Chrome no se ofrece ningún calendario. La alternativa sólo aparece cuando una prueba no llegó.
   6. **Pregunta por la marca:** «¿Tu teléfono es Samsung? / ¿de otra marca?» sólo aparece cuando se envió la prueba y no llegó. En el caso de Juan nunca se envió.
   7. **Función gestionada sin botón:** no tiene botón desde el 5 de agosto (`adf8ddc`). «¿Tu teléfono es de otra marca? Agregar a Google Calendar» abre el enlace manual.

   **Diseño del 4 de agosto** (`4d0905d`): ofrecía «Agregar a Calendario Samsung», un evento con avisos en la cuenta de Google que sincroniza Calendario Samsung, y Google Calendar para otros Android, los dos con la función gestionada. Se quitó al día siguiente sin motivo documentado.

   **Pedido de Juan:** probar si Cita Suite puede crear y controlar recordatorios en Calendario Samsung a través de la cuenta de Google del paciente, porque eso podría cambiar el flujo.

   **Siguiente paso:** probar en los teléfonos de Juan, un Samsung y un Xiaomi, por depuración inalámbrica. `adb` y `scrcpy` ya están instalados en esta computadora. La matriz y los pasos están en el registro, 3 de noviembre. Después vienen las pruebas que fallan primero, la corrección y la publicación con la autorización de Juan. El video de verificación de Google se graba después.

## 5. Límites conocidos (no son tareas, pero no se deben olvidar)

- La llegada real de los correos de confirmación a un buzón externo no se observó. La prueba en producción usó un enlace generado por Auth.
- La sesión que trae el enlace de confirmación queda viva en Supabase aunque la aplicación no la use. Es un riesgo bajo, aceptado para no agregar puntos de falla.
- La seguridad de las invitaciones pendientes depende de que la confirmación obligatoria del correo siga activa: quien se registra con un correo invitado toma esa invitación en su primer ingreso (`docs/architecture/confirmacion-de-correo.md`).
- **Archivar desde el panel sólo cambia el acceso.** No cancela invitaciones pendientes ni cambia nombre, dirección o WhatsApp; para el duplicado de Natalia se hizo aparte (registro, 1 de noviembre).
- **Volver de V10 a V9 exige un paso previo:** V9 no lee el rubro «medicina» ni preguntas de más de 20 opciones. Antes de la reversión, correr `node .verification/natalia-configuracion-20261101/revertir-para-v9.mjs ensayo` y después `aplicar` (detalle en `docs/architecture/publicacion-y-reversion.md`).
- **Límites de Auth registrados el 1 de noviembre** (`docs/architecture/correo-de-recuperacion.md`):
  - envío de correos: 10 por hora, bajado por Juan el 31 de octubre;
  - renovación de sesión: 150 cada 5 minutos;
  - verificación de enlaces: 30 cada 5 minutos;
  - altas e ingresos: 30 cada 5 minutos;
  - intervalo mínimo por usuario: 60 segundos.
- CI usa servicios descartables y no acredita Realtime alojado.
- Los registros históricos conservan palabras pegadas: se corrigieron los documentos de uso diario, no la historia.

## 6. Hecho (para no repetirlo)

### 2 de noviembre: modo claro (plan `modo-claro-20261102.md`; detalle en su registro)

- **V12 publicada y comprobada** (14:46 UTC): `c21a19839c814a8a5f476cb522a13273a10f89c4`, versión de Cloudflare `f18a80f2-fd65-4ffc-b92f-fc0101d4f85f`.
  - **Qué trae:** modo claro predeterminado, el oscuro conservado y el selector Claro, Oscuro y Automático, con la preferencia por dispositivo.
  - **CI:** `fast` 41460642336, paquete 41462444575 y navegador 41462806211, con 64 de 64. El recorrido abarcó 242 pantallas y estados en los dos modos, sin problemas de contraste ni de diseño.
  - **Después de publicar:**
    - `verify-production-release.mjs` aprobado;
    - el primer pintado del servidor es correcto con cada valor de la cookie, en los dos orígenes;
    - la reserva de Natalia es idéntica, píxel a píxel.
  - **Puntero de la fuente** en V12.
- **V12b publicada y comprobada** (15:33 UTC): `771fac5950c532b1123f11d4dde93eef9b42ceba`, versión de Cloudflare `277d332d-1794-4367-8ef0-567ced159f1b`.
  - Es el fondo general del modo claro apenas más cálido (`#f6f5f3`), a pedido de Juan.
  - CI: `fast` 41469851263, paquete 41470383141 y navegador 41470743564, con 64 de 64.
  - Producción verificada. Natalia y el oscuro quedaron idénticos.
- **Vuelta atrás:** a V12 (`f18a80f2…`) o a antes del modo claro (`986cf666-ae09-423b-ae05-1928007dccde`). Nunca a `59f81e89…`.


### 1 de noviembre (plan 12.16; detalle en el registro de señas y avisos)

- **V10b publicada y comprobada** (10:15 UTC): `68f31741f6ff7f2253c036800b1369f1eda16510`, versión de Cloudflare `1d2b4acd-7dd8-4cb7-81e3-a205bafe9f8d`. Trae la vista aparte de consultorios archivados en el panel maestro (y «Archivado» en lugar de «Pausado»), el rubro «medicina» y preguntas de hasta 40 opciones.
  - Verificación: pruebas rojas y verdes, 12 de 12 mutaciones detectadas, `sql` 41265804819, `fast` 41265937843 (1864 pruebas unitarias), paquete 41266013495, navegador sobre el paquete exacto 41267444767 (7 de 7) y comprobaciones posteriores.
  - Migraciones de 128 a 130 a las 02:40 UTC, con copia previa.
  - Puntero de la fuente en V10b.
- **Rubro «medicina» y pregunta de obra social de 24 opciones** cargados en el consultorio de Natalia (10:16 UTC).
- **Web de Natalia publicada** (10:18 UTC):
  - reserva en su consultorio real por `app.cita-suite.com.ar`;
  - tiene `robots.txt` y pide no ser indexada hasta su dominio propio;
  - sus 36 archivos servidos son idénticos al paquete (commit `8ac6dfee` y Vercel `dpl_2Xtgk4uEqhRumxb4t3Fc4dqdR6sU`).
- **Pruebas marcadas en su consultorio real** (presencial y online), con un navegador real desde su web, y **limpieza comprobada** (10:31 UTC): conteos idénticos a la foto previa y el turnero otra vez en 24 de 24.
- **Dominios oficiales** registrados en `docs/architecture/dominio.md` y `AGENTS.md`.

- **Duplicado de Natalia** (`1a00afa2-92ad-46cf-bc4a-cd6b58e4e4b0`):
  - Juan lo archivó desde el panel;
  - se llama «Duplicado archivado — no usar», con la dirección `duplicado-archivado`;
  - reserva pública y WhatsApp apagados, sin el correo ni el teléfono de Natalia;
  - invitación de dueña cancelada y correo habilitado deshabilitado (`unificacion-aplicar.json`, 01:56 UTC).
- **Consultorio real de Natalia** (`c488f625-cb9a-41ec-8526-b7ec03c4646b`):
  - nombre «Consultorio Natalia Frutos», dirección `natalia-frutos` y WhatsApp del consultorio;
  - perfil profesional «Dra. Natalia Frutos» vinculado a su cuenta;
  - dos prestaciones de 60 minutos con descripción e indicaciones por tipo de orden;
  - horarios exactos con paso de 60 minutos y descanso 0;
  - integración predeterminada con presencial y online (`configuracion-aplicar.json`, 02:00 UTC). Comprobado como paciente, 24 de 24 (`turnero-despues-de-cargar.json`).
- **Decisión anterior reemplazada:** el punto «unificar los consultorios» de la versión del 31 de octubre de esta lista.
- **Límite de envío de correos de Auth:** 10 por hora (Juan, 31 de octubre). Los demás límites quedaron registrados.
- **Web de Natalia:** no la usa nadie hasta la entrega (Juan). Se conecta a su consultorio real y las pruebas se hacen ahí.
- **«Staging 455»:** Juan decidió no renombrarlo; queda con ese nombre.
- **Avisos por correo:** los de fallas de GitHub y los del monitor de copias llegan, según confirmó Juan el 1 de noviembre.
- **Etapas D y E:** siguen pendientes, por decisión de Juan (punto 3).

### 31 de octubre

- Revisión completa del estado publicado y de la evidencia: registro de señas y avisos, sección del 31 de octubre.
- Verificación de sólo lectura de producción. Nadie reclamó la invitación del consultorio preparado. Las siete tareas programadas corrieron sin fallas desde el cierre del 30 de octubre, incluida la retención diaria (`.verification/natalia-unificacion-20261031/inspeccion-inicial.json`).
- Datos personales de Natalia retirados del registro de señas y avisos; quedan sólo en su documento privado, con permiso 600.
- **V9 publicada y comprobada a las 21:58 UTC:** `a3c707f368736da90d2adf5850d291460f657af0`, versión de Cloudflare `2ef53723-0a46-4879-bf6e-4af5ed5320c9`. Registra las fallas de Auth al comprobar el enlace de confirmación. Prueba roja y verde, tres mutaciones detectadas, `fast` 41244933261, paquete 41244945074, navegador sobre el programa exacto 41245436407 (12 de 12) y comprobaciones posteriores aprobadas. Recuperación inmediata a V8 documentada en `docs/architecture/publicacion-y-reversion.md`.
- Documentación corregida: rótulos de recuperación obsoletos, comandos exactos de recuperación, dependencia de seguridad de las invitaciones, palabras pegadas de `AGENTS.md`, apartados viejos del traspaso rotulados como históricos y esta lista enlazada desde `AGENTS.md` y `docs/README.md`.
- Hallazgo de la revisión cerrado sin cambios: la retención diaria del historial de tareas corrió de forma natural el 31 de octubre a las 05:37 UTC (`DELETE 4986`).

## 7. Trabajo en curso

La revisión documental de E y la conexión administrativa local de Zoho quedaron terminadas; credenciales/renovación persistentes guardadas. Juan autorizó después la ejecución completa, pruebas y publicación de E; preparación y Q01/Q02 en el [registro activo](ejecucion-etapa-e-20261103.md), sin volver a pedir inicio (sección 3). El modo claro sigue publicado; la insignia del botón de cuenta conserva su pendiente de la sección 4.
