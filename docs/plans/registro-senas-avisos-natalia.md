# Registro de la campaña de señas y avisos (consultorio de Natalia Frutos)

**Estado de E, 2 de noviembre:** revisión documental contra código terminada; [especificación vigente](etapa-e-correo-autogestion.md) y [registro de esta revisión](#etapa-e-revision). Configuración/implementación esperan la próxima instrucción de Juan. Las pausas D/E, Resend y tareas antiguas que siguen abajo son historia fechada; D sí permanece en pausa.

**Fuente de verdad:** el [plan aprobado](propuesta-senas-avisos-natalia.md), incluida su sección 12, que contiene la aprobación literal y los ajustes posteriores.

**Qué registra este documento:**
- cada cambio, prueba, corrida, falla, causa, corrección, decisión, bloqueo y pendiente;
- de cada corrida: su identificador, el SHA de la fuente y la ruta de su evidencia.

Las evidencias locales están en `.verification/senas-avisos-20261029/`; esa carpeta no se sube a Git. El punto exacto donde quedó el trabajo está en el [traspaso](traspaso-senas-avisos-natalia.md).

Criterio, por pedido literal de Juan: «No te confíes nunca, un test verde no demuestra ausencia de bugs silenciosos ni consistencia».
- Cada cierre se intenta refutar.
- Una prueba vale sólo si se la vio fallar sin la corrección.

## 29 de octubre de 2026

### Aprobación y punto de partida

- **Aprobación.** Juan aprobó íntegramente el plan, con su revisión 2 (texto literal en la sección 12.1 del plan).
  - Huella SHA-256 del texto aprobado: `24abe324c148cfcedde2df2e0e5c6c58f2535675b363ba2f9f3f76924f4d3c43`.
  - Copia exacta: `.verification/senas-avisos-20261029/plan-aprobado-20261029.md`.
  - Después de la aprobación se cambiaron la línea de estado y se agregó la sección 12. Comprobación con `diff` entre la copia y el plan: sólo dos bloques, `3c3,9` (estado) y `843a850,914` (sección 12 agregada al final).
- **Información de Natalia** registrada en informacion-20261029.md (documento privado `docs/clientes/natalia-frutos/informacion-20261029.md`, sólo en la computadora de trabajo):
  - el texto literal;
  - la versión ordenada;
  - la clasificación de cada punto;
  - las decisiones y preguntas pendientes.
- **Hallazgos verificados en el código al registrarla:**
  - **Inicios exactos de Natalia sin código nuevo.** Cada regla horaria tiene su propio paso (`slot_interval_minutes`) y la grilla arranca en el comienzo de cada franja (`apps/web/src/lib/availability/calculate.ts`, líneas 323 a 331 y 364 a 371). Dos franjas por día con paso de 60 minutos dan esos inicios.
  - **Viernes habilitable.** Se hace con una excepción de tipo `extra_available` (líneas 373 a 381).
  - **El recordatorio del token no se puede mostrar sólo al elegir esas obras sociales.** El formulario admite una ayuda fija por pregunta (`help`), pero no texto según la opción elegida (`packages/shared/src/booking-integration.ts`, líneas 18 a 27).
  - **Blog y talleres de la web están excluidos por el plan de la refactorización:** «Cursos y noticias quedan fuera» (línea 24).
- **Ajuste 1** (plan, sección 12.2): la seña puede ser un monto fijo, y la de Natalia es de $40.000.
- **Base de la campaña:** `aacba5b10ff6030ac061e20ce0cccdf28126c180`, la versión que sirve producción (app `4e29aba6`, programador `ba7b746d`).
- **Directorio de trabajo comparado por contenido contra la base.** Usé `git ls-tree` de la base y `git hash-object` de cada archivo, porque el índice local no sigue estos archivos y `git diff` daría un resultado falso. Resultado:
  - 1.151 archivos en la base; ninguno falta en el directorio;
  - 11 con contenido distinto: 10 documentos actualizados después de la publicación, y `supabase/templates/recovery.html`;
  - la plantilla de recuperación sólo agrega una línea vacía al final (modificada el 27 de octubre a las 20:23, hora argentina). No se compila ni se publica con la app, y no entra en las candidatas.
- **Preservación del repositorio local:**
  - HEAD `80268e2`;
  - índice con SHA-256 `55cd8f79…`.

  Las candidatas se arman con `.verification/senas-avisos-20261029/build.sh`, sobre la base, con un índice temporal y `GIT_OPTIONAL_LOCKS=0`.

### Etapa A: botones y textos

#### Lectura del código y hallazgos

- **El hallazgo 7 del plan era falso.** Las pacientes de Natalia terminan en `/turno/<token>?creado=1`, no en la pantalla final del marco. Corregido como ajuste 2 (plan, sección 12.5), con las tres pruebas en el código.
  - El aviso al consultorio va en `/turno/<token>`.
  - La pantalla final del marco no cambia.
  - Se retira el punto «llamado claro para activar el recordatorio», que no tenía pantalla que mejorar.
- **Error silencioso en código existente: «Marcar como enviado» de Recordatorios** (`apps/web/src/routes/odonto/recordatorios/+page.server.ts`).
  - No validaba el identificador. Uno mal formado llegaba a PostgreSQL, fallaba con 22P02 y respondía 500, cuando la guía pide 404.
  - Actualizaba sin comprobar las filas afectadas. Con el identificador de un turno inexistente o de otro consultorio, no actualizaba nada, respondía éxito y escribía igual una auditoría `reminder.whatsapp_marked_sent` sobre ese identificador.
  - Se reprodujo con pruebas que fallaron y se corrigió: valida el identificador, exige la fila actualizada (`select('id').maybeSingle()`) y audita sólo si hubo cambio.
- **El número de WhatsApp del consultorio no se suma a `PUBLIC_BUSINESS_SELECT`.** Esa consulta también alimenta el turnero, cuyos datos llegan al navegador. El número viajaría aunque el consultorio no hubiera habilitado su WhatsApp. Se lee sólo en la consulta del turno, y la vista expone `whatsapp_contact_phone` ya normalizado, y sólo si está habilitado.
- **Consumo:** la lista completa de Recordatorios arma mensajes también para los turnos cubiertos. El aviso de la agenda corre en cada carga, así que la función interna descarta los cubiertos antes de armar mensajes cuando no se van a mostrar. El costo del aviso de la agenda queda igual que antes.
- **Arquitectura:** las funciones que arman enlaces `wa.me` vivían en un módulo del servidor (`reminders.ts`), y la ficha, que corre en el navegador, no podía usarlas. Se movieron a `apps/web/src/lib/utils/whatsapp.ts`, que es puro, y `reminders.ts` las reexporta. Una prueba exige que sean la misma función, sin copia.

#### Cambios

- **Página del turno** (`routes/turno/[token]/+page.server.ts` y `+page.svelte`):
  - aviso al consultorio con dos variantes;
  - el mensaje se arma en `lib/server/scheduling/public/practice-whatsapp.ts`: nombre, día y hora en la zona del consultorio, sin la prestación;
  - la tarjeta aparece sólo con turno activo y futuro y el WhatsApp del consultorio habilitado;
  - en una computadora abre WhatsApp Web.
- **Vista pública** (`public-appointments.ts`): `whatsapp_contact_phone`, obligatorio en el tipo, para que cada dato de ejemplo lo declare. Se actualizaron los de tres pruebas: `google-calendar-sync`, `calendar-content` y `google-calendar`.
- **Ficha:** botón «Abrir WhatsApp» junto a «Copiar teléfono» (`PatientProfilePanel.svelte`).
  - Usa el teléfono normalizado o, si falta, el escrito.
  - Sin JavaScript abre `wa.me`; ya cargada la página, en una computadora abre WhatsApp Web.
- **Recordatorios:**
  - `loadReminderList` trae todos los turnos del día con su cobertura (`aviso_automatico` para los cubiertos);
  - `loadReminderCandidates` y el contador de la agenda conservan su significado;
  - la pantalla muestra tres grupos, con los cubiertos plegados al final;
  - el mensaje suma una oración que invita a avisar o cancelar para liberar el horario.
- **Contratos** (`lib/scheduling/contracts.ts`): `ReminderListCoverage`, `ReminderListItem` y `PracticeWhatsAppNotice`.

#### Pruebas

- **Rojas antes de implementar:**
  - `.verification/senas-avisos-20261029/etapa-a-roja-servidor.txt`: 7 fallidas y 3 archivos sin el módulo nuevo;
  - `etapa-a-roja-cliente.txt`: 6 fallidas.

  Las dos pruebas que exigen que el botón no aparezca ya pasaban antes, porque el botón no existía; recién protegen algo después de implementar.
- **Verdes después** (locales, en secuencia):
  - `etapa-a-verde-servidor.txt`: 11 archivos, 127 pruebas, incluidas las vecinas de calendario, teléfono y agenda;
  - `etapa-a-verde-cliente-2.txt`: 3 archivos, 52 pruebas.

  La primera corrida de componentes (`etapa-a-verde-cliente.txt`) falló por la prueba, no por el código: el bloque nuevo no limpiaba lo montado y el botón aparecía dos veces. Se agregó la limpieza.
- **Tipos de las pruebas de navegador:** `tsc -p e2e/tsconfig.json`, sin errores (`etapa-a-tipos-e2e.txt`).
- **Mutaciones a propósito** (`mutaciones-etapa-a.py`; resultados en `mutaciones-etapa-a.txt` y `mutacion-m3b.txt`):
  - detectadas cinco de seis: exponer el WhatsApp sin habilitar, usar la zona de Argentina, marcar sin fila, mostrar la tarjeta arriba al volver e ignorar el teléfono escrito;
  - la sexta, «el contador cuenta los cubiertos», resultó un mutante equivalente: hay dos protecciones independientes (el descarte temprano y el filtro final) y romper una sola no cambia el resultado;
  - rompiendo las dos (`M3b`), nueve pruebas lo detectan;
  - cada archivo se restauró y se comprobó por SHA-256.
- **Prueba de navegador nueva:** `apps/web/e2e/practice-whatsapp.spec.ts`, etiquetada `@candidate-behavior`.
  - Usa datos sintéticos propios, con el WhatsApp del consultorio habilitado sólo durante la prueba y restaurado y comprobado al final.
  - Cubre las dos variantes del aviso, que desaparezca al deshabilitarlo y el botón de la ficha.
  - Incluye la matriz de 320, 390, 768, 1280 y 1600 píxeles con `layoutIssues`, y capturas.
  - Corre en CI.

#### Candidata y verificación en CI

- **Archivos de la candidata:** se eligieron con la misma política que `scripts/prepare-ci-snapshot.mjs`. Entran el código de `apps`, `packages`, `supabase` y `scripts`, los archivos de raíz y la lista cerrada de documentos de esa herramienta. La lista exacta está en `.verification/senas-avisos-20261029/candidata-a-archivos.txt`.
  - **Comparación por contenido contra la base:** 26 archivos cambiados y 6 archivos de código nuevos.
  - **Entran:** los 22 de código y pruebas, `AGENTS.md` y 9 documentos de la lista que se actualizaron después de `aacba5b`.
  - **No entran:**
    - los documentos de esta campaña (plan, registro, traspaso e información de Natalia), porque la herramienta no los incluye y CI no los usa;
    - `docs/architecture/dominio.md`, por el mismo motivo, como en las candidatas anteriores;
    - `supabase/templates/recovery.html`, que sólo agrega una línea vacía;
    - los 888 archivos que no están ignorados por Git pero nunca formaron parte de la base: copias de auditoría, volcados, capturas y salidas locales.
- **Candidata de la etapa A:** `b0970e65466444bc119869113fca1197723212f4`.
  - Armada con `build.sh` sobre `aacba5b`: 31 archivos, 1.460 líneas agregadas y 89 quitadas.
  - HEAD local `80268e2` e índice `55cd8f79…` comprobados sin cambios después de armarla.
  - Subida a `Juan4787/cita-suite-verificacion` en la rama `verify/senas-etapa-a-20261029`.
- **Verificación rápida:** corrida `40944009246`, **aprobada** (terminó el 29 de octubre a las 19:56 UTC). Cubre los tipos de las dos aplicaciones y de las pruebas de navegador, las fronteras entre áreas, las guardas y las pruebas unitarias de servidor y de cliente.
- **Verificación completa:** corrida `40944689839`, **fallida** (20:07 UTC).
  - **Qué falló:** sólo la prueba nueva `practice-whatsapp.spec.ts`, en la matriz de diseño. El resto de la etapa de navegador no llegó a correr, porque la verificación se detiene en la primera falla.
  - **Registros:** `.verification/senas-avisos-20261029/etapa-a-full-job.log` (líneas 6487 a 6640).
  - **Primera causa, la prueba:** el selector `main a, main button` incluía controles ocultos de ancho cero, como menús de escritorio ocultos en el celular y contenido plegado. Dio decenas de falsos positivos. La guía pide nombrar sólo los controles operables, así que se usa `main a:visible, main button:visible`.
  - **Segunda causa, un defecto previo en la página del turno:** a 320 píxeles, «Guardar comprobante» se partía en dos líneas. Con el relleno de la tarjeta y del botón, al texto le quedan unos 180 píxeles, y la fuente de CI lo necesita un poco más ancho. En teléfonos reales probablemente entraba justo, pero sin margen. Se redujo el relleno horizontal del botón sólo en pantallas chicas (`px-3 sm:px-5`).
  - **Tercera causa, un defecto previo en la ficha:** a 320 píxeles quedaba un «·» colgado al final de una línea («…l de prueba · Reservado»), en «Próximos turnos». Se aplicó la regla de la guía, `·&nbsp;`, en sus dos líneas y en la línea equivalente del historial del panel de datos.
  - **Los dos defectos previos son reales y ninguna prueba los había detectado:** las matrices anteriores no cubrían la página del turno, y la ficha no tenía datos con nombres que cortaran justo ahí. La corrida fallida queda como su reproducción.
- **Candidata v2:** `75d6f33c5d9593418296a1bd92fe1dca6bba694b`, en la rama `verify/senas-etapa-a-v2-20261029`.
  - Difiere de la v1 sólo en esos cuatro archivos (`git diff --stat`).
  - Locales: las pruebas de componentes de la página del turno y del panel (51) y los tipos de navegador, verdes.
  - **Verificación completa: corrida `40966735724`, aprobada** (22:42 UTC). Comprobado en el registro del trabajo (`.verification/senas-avisos-20261029/etapa-a-v2-full-job.log`), no sólo en la conclusión:
    - 1.438 pruebas de servidor y 195 de cliente;
    - las suites SQL y todas las carreras con dos conexiones (`PASS:`);
    - navegador 49 de 49, incluida `practice-whatsapp.spec.ts` con su matriz de cinco anchos;
    - sin pruebas salteadas ni fallidas.
  - **La etapa A queda verificada en CI** sobre `75d6f33`. Falta la parte de publicación (release, staging y producción), que se hace junto con las etapas B y C.

### Etapa B: diseño detallado antes de programar

Concreta las secciones 4.1 a 4.9 del plan con sus ajustes. Si al programar algo cambia, se anota acá con su motivo.

**Tablas** (una migración aditiva):
- **`public.deposit_policies`:** una fila por consultorio.
  - Interruptores: `enabled` y `auto_cancel_enabled`, los dos apagados por defecto.
  - Monto: `amount_mode` (`fixed` o `percentage`), `fixed_amount` (entero en pesos, con los límites de los aranceles) y `percentage` (de 0 a 100, sin incluir el 0).
  - Plazos: `request_days` (7), `deadline_hours` (48) y `min_payment_hours` (24), con límites razonables.
  - `transfer_details`: hasta 500 caracteres.
  - `applies_to_manual`: si la seña se exige también en los turnos que carga el consultorio. Verdadero por defecto.
  - `revision`, `updated_at` y `updated_by`.
  - Una restricción exige el monto que corresponde a la forma de cálculo cuando la seña está activa.
- **`public.deposit_service_exclusions`:** prestaciones que no exigen seña. Si no hay ninguna, todas la exigen, que es el caso de Natalia.
- **`public.appointment_deposits`:** los campos de la sección 4.1 más `waived_reason` (`staff` o `policy_disabled`). Clave foránea compuesta `(appointment_id, business_id)` hacia `appointments`, con borrado en cascada.
- **`private.deposit_automation`:** una sola fila.
  - El interruptor general, apagado por defecto.
  - El registro de la última ejecución: inicio, fin, cuántas procesó y el último error.

**Funciones y disparadores:**
- **Cálculo de fechas:** `private.deposit_schedule(...)`. Es la única regla de fechas y la usan el alta, la reprogramación y la consulta del paso de confirmación.
- **Cálculo del monto:** `private.deposit_amount(...)`. Toma el monto fijo, o el porcentaje sobre `price_quote_snapshot.amount` redondeado con la unidad del arancel.
- **Alta de la seña:** disparador posterior a la inserción en `appointments`. Crea la seña sólo si se cumplen todas estas condiciones:
  - la política está activa;
  - la prestación no está excluida;
  - el interruptor general está encendido;
  - si el turno lo cargó el consultorio, `applies_to_manual` es verdadero;
  - hay un monto válido.
- **Reprogramación:** disparador posterior a la actualización de `starts_at`. Si la seña está pendiente, recalcula las fechas con la fotografía guardada.
- **Regla «Confirmado exige seña resuelta»:** disparador previo a la actualización de `status`.
- **Funciones para el consultorio:**
  - `public.set_appointment_deposit`, para recibida, exceptuada o deshacer;
  - `public.open_appointment_deposit_reminder`, que registra la apertura del WhatsApp;
  - `public.save_deposit_policy`, que si apaga la política exceptúa las pendientes, bloqueando primero sus turnos;
  - la lectura para la página de señas.
- **Para el turnero:** `public.get_deposit_terms`, con las condiciones antes de reservar, sólo para la clave de servicio.
- **Tarea automática:** `private.expire_unpaid_deposits(p_now, p_limit)`.
- **Programación:** pg_cron `cita-suite-deposit-expiry` cada 5 minutos, y una poda diaria de `cron.job_run_details` que conserva 14 días.

**Bloqueos:**
- Regla de la sección 4.5: toda escritura sobre una seña ocurre teniendo bloqueado su turno, con `for no key update`.
- La tarea bloquea sólo turnos, con `for no key update of` el turno `skip locked`.
- Apagar la política bloquea los turnos en orden de identificador.
- **Relectura obligatoria dentro de la tarea.** Con READ COMMITTED, cuando `for no key update` encuentra un turno modificado, PostgreSQL vuelve a evaluar las condiciones con la versión nueva de ese turno, pero no relee las filas de las otras tablas de la consulta: la seña queda como estaba al empezar.
  - Si recepción registró la seña sin cambiar el turno (por ejemplo, en «Quiere reprogramar») y terminó antes de que la tarea bloqueara ese turno, la tarea podría tenerlo en su lista con la seña vieja.
  - Por eso, con cada turno ya bloqueado, la tarea vuelve a leer la seña, el turno, la política y el consultorio en una consulta nueva, y recién ahí decide.
  - Una prueba simula exactamente ese orden.

**Permisos:**
- La tabla de señas se lee con seguridad por fila, la misma que permite leer el turno.
- No se otorga escritura directa a ningún rol de la API: sólo las funciones escriben.
- `anon` no recibe nada.
- Las funciones validan el actor como `private.follow_up_actor`: bloquean la membresía en modo compartido para que una revocación espere, y verifican `business_allows_operation`.

**Código de la app:**
- **Reprogramación** (`rescheduleAppointment`): conserva Confirmado si la seña está resuelta.
- **Confirmación pública:** se rechaza con la seña pendiente.
- **Botón genérico «Confirmar» de la agenda:** con la seña pendiente se reemplaza por «Confirmar seña».

**Pruebas SQL:**
- `supabase/tests/appointment_deposits.sql`, con todos los casos de la sección 5 del plan y del ajuste 1.
- `supabase/tests/run_deposit_expiry_concurrency.sh`, con las carreras contra la tarea, la reprogramación y el apagado de la política.

### Etapa B: base de datos y su verificación en CI

**Corrida roja.** Candidata `c7c3a3b6d9e48b639406262d11372c4f966b2dde`: la v2 de la etapa A más la suite SQL y el guion de carreras, sin la migración. Rama `verify/senas-etapa-b-roja-20261029`.
- Corrida `40966898142`, nivel `sql`: **fallida como correspondía**, con «relation "private.deposit_automation" does not exist» al preparar la suite nueva (`.verification/senas-avisos-20261029/etapa-b-roja-job.log`, línea 604).

**Primera corrida con la migración.** Candidata `9747bab3343480cc59c828418410cfa96a7f8528` (la roja más la migración), rama `verify/senas-etapa-b-sql-20261029`.
- Corrida `40968289018`: **fallida**, con `TEST_GLOBAL_SWITCH` en la prueba 14 (`etapa-b-sql-job.log`, línea 603). Las pruebas anteriores de la suite no lanzaron excepciones, pero su salida no se imprime cuando el archivo falla.
- **Causa: un error de la prueba.** Llamaba a la tarea y leía su registro de ejecución en la misma sentencia. Una sentencia no ve lo que escribe una función volátil que ella misma llama, así que leía el valor anterior.
  - Reproducido en un contenedor descartable `postgres:17`, que se borró al terminar (`reproduccion-misma-sentencia.txt`): en la misma sentencia el control ve el valor viejo; en sentencias separadas, el nuevo.
  - Corrección: la llamada y la lectura van en sentencias separadas.

**Revisión completa después de esa falla.** Antes de volver a correr, revisé la suite, la migración y el guion buscando el mismo tipo de error. Encontré defectos en los tres.
- **En la suite, controles que un nulo dejaba pasar en silencio.** `if <condición> then raise` no lanza nada si la condición es nula. Por ejemplo, `(seña).amount<>45000` con la seña ausente da nulo, y el control pasaba. Además, `fila is not null` en un tipo compuesto es verdadero sólo si todos los campos son no nulos, así que `TEST_DISABLE_NEW` no podía detectar una seña creada.
  - Corrección: todas las comparaciones usan `is distinct from`; los booleanos, `is not true` o `is not false`; la existencia se pregunta con `exists`.
  - Los valores esperados que eran copia de la implementación se reemplazaron por literales: la fotografía de 72 horas y 14 días, y el motivo exacto de la cancelación con la fecha en la zona del consultorio.
- **En la migración, dos defectos reales del mismo tipo:**
  1. `set_appointment_deposit` y `save_deposit_policy` comparaban la revisión esperada con `<>`. Con una revisión nula, el control de concurrencia no saltaba y el cambio pisaba una versión ajena. Ahora la revisión es obligatoria (`DEPOSIT_ACTION_INVALID` o `DEPOSIT_POLICY_INVALID`) y se compara con `is distinct from`.
  2. `save_deposit_policy` completaba con valores por defecto las claves ausentes. Por ejemplo, una casilla de «aplica a turnos cargados por el consultorio» que no llegara se guardaba como «sí». Ahora exige las 11 claves con su tipo JSON, no acepta ninguna otra y no completa nada.
  - Además, los resultados de `business_allows_operation` se evalúan con `is not true`. Hoy esa función nunca devuelve nulo (sus dos ramas usan `coalesce(…, false)`), pero así un cambio futuro no abre el permiso.
- **En el guion de carreras, que nunca había llegado a correr:**
  1. La limpieza restauraba el interruptor con `set enabled=t`. `psql -At` imprime los booleanos como `t` o `f`, y sin comillas PostgreSQL lo lee como una columna, así que la limpieza fallaba siempre. Ahora se valida el valor leído y se restaura como literal entre comillas.
  2. El escenario de la política mandaba el JSON sin la clave `percentage`, que el control estricto nuevo rechaza.

**Incidente: una subida con el origen vacío.** Al armar la candidata siguiente, el armador no tenía permiso de ejecución y falló, pero la cadena de comandos siguió. `git push <vacío>:refs/heads/verify/senas-etapa-b-sql-v2-20261029` es la forma de borrar una rama remota, y git informó «[deleted]».
- **Qué se comprobó:**
  - git 2.43, con el nombre completo `refs/heads/…`, informa «[deleted]» aunque la rama no exista: un ensayo en seco (`--dry-run`) sobre un nombre inventado dio la misma salida.
  - Ese nombre lo acababa de elegir.
  - No había ninguna corrida asociada (`gh run list --branch`).
  - Las cuatro ramas de la campaña seguían en su commit (`git ls-remote`).
  - **Conclusión: con toda probabilidad no se borró nada.** No es seguro al cien por ciento, porque la salida completa del servidor se perdió (sólo se mostraron las dos últimas líneas).
- **Qué cambió en la forma de trabajo:**
  - el armador se invoca con `bash`;
  - antes de subir, se valida que la candidata sea un SHA de 40 caracteres;
  - en esta herramienta `set -e` no corta una cadena, así que los controles son explícitos.

**Segunda corrida.** Candidata `9c668cc1fbb2d3ff4886153d777b264c125da153` (correcciones anteriores), rama `verify/senas-etapa-b-sql-v2-20261029`.
- Corrida `40970391559`: **fallida**, con `TEST_POLICY_TEXT_AMOUNT 1` (`etapa-b-sql-v2-job.log`, línea 613). La prueba detectó un defecto real **en el control estricto recién agregado**: una política con el monto escrito como texto (`"40000"`) se guardaba.
- **Causa:** los tipos permitidos estaban escritos como literal de arreglo, `'{number,null}'::text[]`. Ahí, `null` sin comillas es el nulo de SQL, no la palabra. `= any` sobre un elemento nulo da nulo, y `where not (nulo)` descarta la fila, así que cualquier tipo pasaba en las claves que admiten nulo.
  - Reproducido en un contenedor descartable (`reproduccion-literal-null.txt`): la forma vieja aceptaba texto, un booleano y la clave ausente; la nueva rechaza los tres y acepta los valores válidos.
  - Corrección: constructores `array['number','null']` y la condición escrita como `(…) is not true`.

**Relectura completa del plan.** `AGENTS.md` exige releer el plan entero después de cada compactación. No lo había hecho al retomar, y lo hice después de la primera falla. Comparándolo con lo implementado aparecieron faltantes. Todos quedaron resueltos en la candidata siguiente.
- **Sección 4.5, «turno activo»:** las acciones sobre la seña ahora nombran los estados activos (Reservado, Confirmado y «Quiere reprogramar») en vez de rechazar sólo Cancelado (`DEPOSIT_APPOINTMENT_CLOSED`).
  - **No corrige ningún defecto.** Desde `20260824030000_appointment_status_contract.sql` no existen los estados «atendido» ni «ausente». Al escribir esta línea por primera vez lo había dado por cierto leyendo migraciones viejas, y la corrida `40973277418` lo desmintió: `attended_at` ya no existe. Con los cuatro estados vigentes, las dos formas son equivalentes; la lista explícita deja cerrado por defecto un estado que se agregue en el futuro.
  - La app tampoco aplica una regla de tiempo a los cambios de estado (`assertCanTransitionAppointment` recibe las fechas pero no las usa), así que las acciones sobre la seña tampoco la aplican.
- **Sección 5, «lectura evaluada una vez por consulta, como en `appointment_read_set_based.sql`»:** la política de lectura de señas usaba una subconsulta correlacionada sobre `appointments`, que reevalúa la regla de turnos por cada seña. Ahora usa la misma forma que las asignaciones y los contextos de reserva: `user_appointment_reader_business_ids()` una vez por sentencia y `user_allocated_appointment_ids()` como conjunto.
- **Sección 5, «actualizar `api_exposure_explicit.sql` y `write_expression_privileges.sql`»:** no hace falta editarlas. Las dos recorren todo el catálogo, así que cubren solas las tablas y funciones nuevas. `api_exposure_explicit.sql` ya pasó con la migración aplicada (corrida `40970391559`, líneas 440 a 468). `write_expression_privileges.sql` corre después de la suite de señas y queda cubierta en la corrida siguiente.
- **Pruebas que pedía la sección 5 y no estaban** (agregadas a `appointment_deposits.sql`, que pasa de 20 a 24 comprobaciones):
  - un turno a las 22:30 de Córdoba, que en UTC ya es el día siguiente, con la fecha esperada calculada desde el día local (3b);
  - el límite exacto de 24 horas para pagar, con 24 horas justas que alcanzan y un segundo menos que no (4);
  - la seña fija igual en una prestación con arancel (5, ajuste 1);
  - las tres vías hacia Confirmado con la seña pendiente: la escritura directa, la del enlace de la persona como `service_role` y la de recepción con seguridad por fila (6);
  - una falla provocada a mitad de «Confirmar seña» y de «Deshacer», sin estado mezclado ni auditoría (7b);
  - un miembro de otro consultorio, un consultorio restringido y un turno atendido (8);
  - repetir «Exceptuar» y deshacer una seña ya pendiente, sin auditoría duplicada (10);
  - la seña exceptuada en la matriz de la tarea, y el registro de ejecución con procesadas y canceladas (12);
  - una falla provocada dentro de la tarea, que deshace turno, seña, auditoría y registro de la ejecución, y deja el horario ocupado; sin la falla, la misma tarea cancela ese turno (12c);
  - el horario de un turno de equipo, que también se libera para la segunda profesional (13);
  - la política apagada sin la exención que haría su guardado, y un consultorio inactivo (14);
  - el porcentaje sin arancel ni monto fijo (no pide seña), con el monto fijo de respaldo y con el ajuste mensual del mes del turno (15);
  - la apertura del pedido por WhatsApp: quién y cuándo, sin nueva revisión, sólo sobre una seña pendiente (16b);
  - la lectura de cada rol igual a la de sus turnos, sin evaluar la regla por cada seña, y los permisos de ejecución de cada función para `anon`, `authenticated` y `service_role` (18).
- **Carreras que pedía la sección 5 y no estaban** (agregadas al guion, que pasa de 4 a 8 escenarios):
  - la tarea contra un turno que recepción ya bloqueó, con la seña todavía libre;
  - filas hijas con clave foránea real contra «Confirmar seña» y contra la tarea, en los dos órdenes. La fila hija es una tabla sintética con una clave foránea compuesta real hacia `appointments`: toma el mismo bloqueo que la seña o el horario liberado, sin las validaciones de negocio de otras tablas;
  - la reprogramación contra «Deshacer», con el turno Confirmado (la condición de estado de la reprogramación ya no coincide y no mueve nada) y con el turno en «Quiere reprogramar» (la regla de la base rechaza la confirmación);
  - apagar la política mientras corre la tarea, en los dos órdenes.

**Correcciones al diseño registrado más arriba:**
- **«El último error» en `private.deposit_automation`:** no se implementó, y el plan no lo pedía (sección 4.6: inicio, fin y cuántas procesó). Una falla deshace toda la transacción de la tarea, incluido lo que se escriba ahí. La falla se nota porque el registro de ejecución deja de avanzar, y la página de señas avisa a los 20 minutos. pg_cron guarda el mensaje en `cron.job_run_details`, que se poda a los 14 días.
  - **Límite aceptado y documentado:** si un turno hace fallar la tarea, ninguna otra cancelación avanza hasta que alguien lo resuelva. Es el lado seguro del principio 1.3. Mientras tanto, esas señas siguen visibles como vencidas en la lista.
- **«Botón genérico Confirmar de la agenda»:** no existe. La agenda y el detalle del turno rechazan `confirmed` con «La confirmación queda reservada al paciente desde su enlace». El plan registra la corrección como ajuste 3 (sección 12.6).

**Corridas siguientes, todas del nivel `sql` y armadas sobre `9747bab` con los tres archivos al día.** Cada falla se analizó en el registro del trabajo antes de corregir.

| Corrida | Candidata y rama (`verify/senas-etapa-b-sql-vN-20261029`) | Resultado | Causa y corrección |
|---|---|---|---|
| `40972861223` | `6a2613d…`, v3 | Fallida en la preparación de la prueba 5: `PRICE_QUOTE_CHANGED` | **Error de la prueba.** Una reserva pública sobre una prestación con arancel exige en la sesión el hash de la cotización que vio la persona (`cita.booking_price_quote_hash`, `20261014000000_booking_price_policies.sql`, línea 141). La función real de reserva lo fija y la inserción directa de la prueba no. El ayudante de la prueba ahora lo fija igual. Al leer esa función se confirmó además que reprogramar conserva el arancel fotografiado (sección 4.3). |
| `40973277418` | `cd6f124…`, v4 | Fallida en la prueba 8: no existe la columna `attended_at` | **Supuesto falso mío.** `20260824030000_appointment_status_contract.sql` retiró los estados «atendido» y «ausente» y esas columnas. La prueba usa ahora un turno cancelado: la seña queda como constancia y nadie la cambia. Ver la corrección de la «sección 4.5» más arriba. |
| `40973745022` | `5113c19…`, v5 | **Suite SQL de señas: 24 de 24.** Fallido el guion de carreras, sin ningún mensaje propio | El guion terminaba con error sin imprimir nada: el error de la conexión retenedora quedaba en su archivo de registro y `wait` cortaba en silencio. La evidencia empaquetada tampoco guarda esa salida. Se agregó una trampa de errores que imprime la línea, el comando y todos los registros, y un aviso por escenario. Los dos van a la salida de errores, que el ejecutor muestra sólo cuando algo falla. Los dos fallos esperados (escenarios 2 y 6) se capturan con `\|\|`, para que la trampa no los informe. |
| `40974607535` | `5283173…`, v6 | Suite SQL de señas 24 de 24. Escenarios 1 a 5 de carreras aprobados; el 6 falló con `DEPOSIT_RACE_OTHER_SIDE_DID_NOT_WAIT` | **Error del guion, latente desde el diseño original.** Cuando la conexión que retiene es recepción, ya corrió `set role authenticated`, y con un rol común `pg_stat_activity` oculta las esperas de las sesiones de otros roles. La reprogramación estaba bloqueada, pero recepción no podía verlo. El mismo error tenía el escenario de la política contra recepción, que nunca había llegado a correr. Corrección: volver al rol propio de la sesión antes de esperar; los bloqueos son de la transacción, no del rol. |
| `41001712350` | `9e23f54c42b7e567342274cdca4565ce5bd6215e`, v7 | **Aprobada** (30 de octubre, 04:16 UTC) | Comprobado en el registro del trabajo (`etapa-b-sql-v7-job.log`): todas las suites SQL; la de señas, 24 de 24 (líneas 600 a 728); `write_expression_privileges.sql`, aprobada con las tablas nuevas (línea 4292); los ocho escenarios de carreras con `PASS` y el contador de bloqueos mutuos sin cambios, en 0 (líneas 4311 a 4320). |
| `41002261680` | `1fa1f0fad65ab4c1795118de9a8398658ec0d6ef`, v8 | **Aprobada** | Reemplaza `get_deposit_terms` por `get_deposit_terms_for_slots` (ajuste 4 del plan). Suite 24 de 24, con la prueba 16 sobre la consulta nueva (línea 711). De su evidencia salieron los primeros tipos, que mostraron un defecto: `isOneToOne: false` en la relación entre turno y seña. |
| `41002862880` | `827589802fb4225329ccd24e880bc525cd7a869a`, v9 | **Aprobada** | **Causa del uno a uno perdido:** el generador de tipos (postgres-meta) compara las columnas de la clave foránea en el orden declarado con las de la restricción única en el orden de la tabla. PostgREST ordena las dos, así que en ejecución devolvía un objeto mientras los tipos decían lista. La tabla declara ahora `business_id` antes que `appointment_id`, como `clinical_entry_costs`. Los tipos de esta corrida ya dicen `isOneToOne: true`. Además, una asignación tipada en `public-appointments.ts` deja de compilar si los tipos vuelven a decir lista. |
| `41003356303` | `a50fc5e37ffb7a71208f894897c6f41d4e8dd7e6`, v10 | **Aprobada** (04:34 UTC) | La segunda apertura del pedido por WhatsApp exige `p_reopen`, decidido con el turno bloqueado: dos personas que tocan a la vez ya no mandan dos mensajes sin saberlo. La redirección de Recordatorios tiene esa carrera; la de señas no. La seña ya resuelta tiene su propio código, `DEPOSIT_NOT_PENDING`: antes respondía `DEPOSIT_APPOINTMENT_CLOSED`, cuyo mensaje dice «El turno ya está cancelado». Suite 24 de 24 (prueba 21, línea 715) y carreras sin bloqueos mutuos. **Tipos vigentes:** `packages/shared/src/database.types.ts`, SHA `cf70ada1de3fd4edca64eb0a851d95088e69a03c9592c3506c620d0e16a9be09`, con el resumen de migraciones comprobado contra las locales (evidencia en `tipos-generados-v10.json`). |

Todos los registros de trabajo y los envíos están en `.verification/senas-avisos-20261029/` (`etapa-b-sql-vN-dispatch.json`).

**Código TypeScript de la etapa B ya escrito** (pruebas locales verdes; todavía sin CI):
- `lib/scheduling/deposits.ts`: contratos puros, etiquetas, clasificación de la lista y mensajes. 9 pruebas, después 12 (`etapa-b-contrato.txt`, `etapa-b-contrato-2.txt`).
- `lib/server/scheduling/public/deposits.ts`: llamadas a las funciones de la base, lectura de la política y de la lista. 11 pruebas (`etapa-b-servidor.txt`).
- `appointments.ts`: la reprogramación conserva Confirmado con la seña resuelta. 24 pruebas (`etapa-b-reprogramacion.txt`).
- `practice-whatsapp.ts`: los dos avisos al consultorio con la seña pendiente. 10 pruebas (`etapa-b-aviso-sena.txt`).
- `public-appointments.ts`: la vista pública con la seña y sin «Confirmo que voy» mientras está pendiente. 13 pruebas (`etapa-b-vista-publica.txt`).
- Página `/turno/[token]`: el bloque de la seña está escrito y todavía no tiene pruebas.

### Etapa B: código del consultorio (pruebas locales, todavía sin CI)

- **Página «Señas»** (`routes/odonto/senas`), **redirección «Pedir seña por WhatsApp»** (`senas/abrir/[appointmentId]`), **Configuración, Señas** (`configuracion/senas`) y **«Señas» en el menú** (layout). Cantidades de pruebas y archivos en el traspaso.
- **Defecto encontrado por una prueba:** en la acción de guardado de la configuración, `Number('')` da 0. Una revisión vacía pasaba como «la política nunca se guardó» y se intentaba guardar.
  - Con una política existente, la base lo habría rechazado por conflicto, pero no correspondía mandarlo.
  - Ahora la revisión tiene que ser sólo dígitos.
  - La acción de la página «Señas» tenía el mismo patrón: ahí la base igual rechaza la revisión 0, pero con un mensaje engañoso («Otra persona actualizó…»). Ahora responde «No pudimos leer la versión de la seña. Recargá la página antes de seguir».
- **Defecto de diseño corregido antes de escribir la página:** la lista de señas traía también los turnos que ya pasaron, ordenados por vencimiento de la más vieja a la más nueva y con un tope de 300. A los meses, las señas viejas sin registrar llenaban el tope y escondían las vigentes. La consulta trae ahora sólo turnos que todavía no empezaron, y la clasificación descarta además cualquier turno ya empezado.
- **Decisión:** «abierto por» nombra al usuario por su correo, como la historia del detalle del turno (`list_business_users`). Si no se puede leer el equipo, la fila dice «alguien del equipo», pero la apertura igual se muestra.
- **Decisión:** «Exceptuar» pide una confirmación en la misma fila, porque confirma el turno sin pago.
- **Agenda:** el parámetro `hora` y la propiedad `initialValues` del asistente de carga sirven a «Volver a dar este horario» y, en la etapa C, a «Dar este horario».
  - Si la hora ya no está libre, el asistente vuelve a los horarios del mismo día con un aviso.
  - Antes quedaba en el último paso sin horario y con el botón deshabilitado. También pasaba al restaurar un envío fallido.

## 30 de octubre de 2026: reanudación desde la candidata de aplicación v1

- **Contexto recuperado:** lectura íntegra del plan de esta campaña y sus ajustes, `AGENTS.md`, registro y traspaso. La memoria histórica del 26 de octubre estaba desactualizada: el trabajo vigente es la etapa B de señas, no el release antiguo de recuperación. No se ejecutaron comandos históricos de producción.
- **Preservación comprobada al retomar:** HEAD `80268e2a501198243996e1bdb0048ce066434727`; SHA-256 del índice `55cd8f7975542b806308d3e067f81660fe107ed1c5cdbed88962dbe614a1faba`.
- **Corrida pendiente recuperada:** `41006783127`, trabajo `123903378814`, fuente `4fe48da308730d6b50f127b657226e0881caa752`, terminó **fallida** en `web-types`: 57 errores en ocho archivos, cero advertencias; las etapas posteriores no se ejecutaron. Diagnóstico sin bloques binarios: `.verification/senas-avisos-20261029/fast-app-v1-diagnostics.log`.
  - `practice-whatsapp.test.ts` usaba `Record<string, unknown>` en el constructor: el tipo perdía la seña aunque estuviera en el objeto. Los fixtures ahora declaran el contrato de entrada real y los estados admitidos.
  - La agenda omitía `selectedTime` en su contrato de datos; `loadServices` infería la sobrecarga de cliente sólo Auth; la lectura del equipo llamaba `.catch` sobre un `PromiseLike`. Esas tres correcciones ya estaban en el árbol local, posteriores al snapshot; se conservaron y se incorporan a v2.
  - Los constructores de componentes perdían los tipos de la seña y fijaban fechas a `null`; ahora usan los contratos de la página y de `AppointmentDepositView`.
  - El ayudante de redirecciones esperaba un `Promise` aunque SvelteKit permite respuesta directa o `PromiseLike`.
  - Sin `any`, sin doble aserción ni relajación del contrato de producción para hacer pasar las pruebas.
- **Candidata de aplicación v2:** `f581152b93ead70115506058786e178e8fdc0b8a`, hija de `4fe48da`, siete archivos corregidos; rama `verify/senas-etapa-b-app-v2-20261030`. Verificación `fast` solicitada; recuperar su identificador antes de otro envío. Prueba local dirigida de WhatsApp: 17/17, `.verification/senas-avisos-20261029/reanudacion-whatsapp-unit.txt`.
- **Navegador:** no hay una capacidad de navegador administrado expuesta en esta sesión. Las pruebas Playwright del repositorio se escriben y ejecutan en el CI aislado autorizado; no se inició navegador, compilación ni base local.

### Autorización de producción recibida durante la reanudación

> Te concedo por adelantado la autorizacion para escribir en produccion y probar lo que sea necesario

Registrada literalmente en la sección 12.8 del plan y en `AGENTS.md`: sustituye la espera de otro permiso. No elimina CI, staging, respaldo/recuperación, reversión ni la comprobación del destino. Las decisiones de Natalia que faltan no se inventan; la publicación conserva los interruptores apagados. D y E siguen en pausa.

### Verificación y revisión adversaria de la aplicación, continuación

- **Aplicación v2, `fast` `41007843404`, aprobada** sobre `f581152b93ead70115506058786e178e8fdc0b8a`: tipos 0 errores/0 advertencias, 162 guardas Node en 49 archivos, 11 del programador, 1.554 de servidor en 200 archivos y 235 de cliente en 31 archivos, sin omitidas. Registro recuperado: `fast-app-v2-diagnostics.log`. No acredita SQL, navegador, demo, staging ni producción.
- **Tres defectos adicionales reproducidos antes de corregir:**
  1. Las condiciones por horario aceptaban dos respuestas para el mismo horario y omitían otro: la cantidad era correcta pero no la correspondencia. Ahora se exige unicidad además de pertenencia y cantidad.
  2. Un vencimiento con texto inválido se aceptaba y podía romper el resumen al formatearlo. Ahora se exige un instante válido.
  3. El modo demo de «Señas» conservaba enlaces de apertura y enlaces externos reales. Ahora usa botones deshabilitados para los dos avisos de WhatsApp.
  - Reproducciones: `reanudacion-condiciones-rojas.txt` (2 fallos/18 éxitos) y `reanudacion-demo-roja.txt` (1 fallo/10 éxitos). Correcciones: `reanudacion-condiciones-verdes.txt` (20/20) y `reanudacion-demo-verde.txt` (11/11).
- **Mutaciones controladas B1 a B6:** seis de seis rechazadas por aserciones de las suites, no por errores de compilación o ausencia de pruebas. Se rompieron aviso exclusivo de seña, filtro de turnos iniciados, aviso antes de reservar, revisión de la seña en el formulario, bloqueo de confirmación pública y precarga de la hora manual. Todos los archivos se restauraron y sus SHA-256 coincidieron. Guion y recibos: `mutaciones-etapa-b-reanudacion.py`, `mutaciones-etapa-b-reanudacion.json`, `mutacion-BN.txt`.
- **Aplicación v3:** `192b98a575030fc472ec175676f27a0a1bc98e02`, rama `verify/senas-etapa-b-app-v3-20261030`; incluye las correcciones anteriores y el nuevo spec `appointment-deposits.spec.ts`, más demo en `odonto.smoke.spec.ts`.
  - **Navegador dirigido `41008433387`, fallido.** Reconstruyó 127 migraciones y comprobó tipos reproducibles. El test llegó a configurar la política por la UI y recorrer las condiciones en los dos temas y cinco anchos; no llegó a reservar porque el selector `getByLabel('Teléfono', { exact: true })` no coincide con el nombre real «Teléfono de contacto». Era un error de la prueba, no de la reserva. Se retiró la coincidencia exacta también de los dos campos de obra social, conforme al spec existente.
  - Evidencia íntegra recuperada con el colector: `browser-app-v3-evidence`, 30 archivos, SHA-256 `f68d310d32855d852aca44cde12dcac4ed35016fd1a49d4750abe922a2e8ada8`. Incluye capturas y contexto; inspeccionadas configuración a 320 y condiciones claras a 390. Las matrices acumuladas todavía no llegaron a su aserción final: no se consideran aprobadas.
- **Faltantes del plan detectados en la relectura del código:**
  - La agenda mostraba la etiqueta, pero no las acciones de seña. Prueba roja `reanudacion-agenda-acciones-roja.txt`; ahora ofrece Confirmar/Exceptuar/Deshacer con la revisión observada. Los formularios reutilizan la acción autorizada del detalle del turno y muestran allí su resultado, sin otra implementación de la escritura. Sólo para actores autorizados y turnos activos futuros; sin acciones para la exención por política apagada.
  - La búsqueda y su precarga usan dos RPC JSON anteriores a la seña: al buscar se perdía el dato. `agenda-deposits.ts` los completa con **una** lectura RLS por lote, limitada a los IDs autorizados (60 en búsqueda, 400 en precarga), sin escanear pacientes/turnos ni modificar las firmas SQL. Error, duplicación, dato ajeno o revisión inválida fallan explícitamente; no se convierten en «sin seña». Tres pruebas propias; verificación de navegador añadida para exigir la respuesta real de búsqueda, además del resultado optimista.
  - La lista tenía límite con aviso pero no paginación. Ahora permite páginas acotadas de 300 más un centinela, con orden estable por vencimiento/ID; páginas inválidas vuelven a la primera. La agenda no presenta un conteo parcial como total: si se supera la ventana informa que no pudo comprobar el total y enlaza la lista. Pruebas rojas: `reanudacion-paginacion-roja.txt`, 2 fallos/31 éxitos. Pruebas de servidor posteriores: `reanudacion-paginacion-busqueda-verde.txt`, 58/58 (antes del último caso de normalización de página).
- Se actualizaron contratos funcionales, permisos y puntos 2/4/12 de la matriz de regresiones, con las capas y su estado explícitos. No se cambió el plan aprobado para ocultar un faltante.

### Nuevas carreras y correcciones de SQL (30 de octubre, continuación)

- **Navegador v4 `41009237757`, fallido**, fuente `b736556bde481ddfdcdf2c5a7eda510446ac754d`. El formulario no se envió: el nombre sintético llevaba dígitos de un UUID, que la validación nativa rechaza. El contexto del navegador conserva todos los campos y ningún POST completado; no es una falla del servidor de reserva. Corregido en v5 `da0bffb3a249502d3e86a706437942b26f95e2d7`: sufijo único sólo de letras y `checkValidity()` exigido antes del clic. V5, diagnóstico `41009753863`, en curso. Evidencia v4: `browser-app-v4-evidence`, 30 archivos, SHA-256 `c5193066a574d83c6c321eb3db0eb869d094a58dabc535ddbf77e057a472dd93`.
- **Hipótesis de dos carreras nuevas, reproducidas antes de corregir.** Se agregaron los escenarios 9 y 10 al guion. El retenedor espera una señal de `pg_stat_activity`, ya sea la espera real por su bloqueo o la sentencia completada en una transacción aún abierta, de modo que la implementación rota llega a la comparación de estados en vez de fallar sólo un ayudante de solapamiento.
  - Roja `41009558869` (`sql`), fuente `9d8ca1b2ceea8fc5a8c6191ecef02e1cb58ccf03`. La suite pgTAP y los escenarios anteriores avanzaron; los dos nuevos fallaron explícitamente (`sql-roja-v11-diagnostics.log`, 05:40:59 UTC).
  - **Defecto 1 confirmado:** al reservar durante el apagado no se bloqueaba la política. La reserva veía la política vieja, y el apagado no podía ver el turno todavía sin confirmar: quedaba una seña pendiente con la política ya apagada.
  - **Defecto 2 confirmado:** `deposit_actor` leía `user_business_role` antes de esperar el bloqueo de la membresía y devolvía ese rol viejo. Pasar recepción a readonly antes de que tome el bloqueo no impedía el cobro.
- **Corrección en la migración todavía no aplicada:** el alta toma SHARE sobre la política y recién en la sentencia siguiente calcula las condiciones; si el alta ganó, el apagado ve y exceptúa su seña después de esperar. Si el apagado ganó, el alta no crea seña. El turno nuevo sigue invisible a otras transacciones durante ese bloqueo, por lo que no invierte el orden de los turnos existentes.
- **Autoridad corregida:** membresía y rol se leen bajo SHARE, con estado, aceptación y `disabled_at`; la ayuda de cuenta y el usuario de soporte también se bloquean para conservar su capacidad admin con autoridad vigente; la suscripción se bloquea antes de comprobar operación comercial, como las operaciones transaccionales de Equipo/registro de pacientes. No se cambió ninguna migración histórica aplicada ni firma pública.
- **SQL v11 corregido:** `1a502c2652994601472238518ae4ebe9b2d9d28c`; corrida `41009942644`, pendiente detrás del navegador v5. No se considera aprobado antes de recuperar sus diez carreras y el contador de deadlocks.
- **Otros dos defectos reproducidos en configuración:** si fallaba la lectura del estado global mostraba `automationStopped=false`, y un teléfono no vacío pero inválido contaba como WhatsApp configurado. `reanudacion-configuracion-roja.txt`: 2 fallos/9 éxitos. Ahora la lectura desconocida es `null` con aviso humano, y se usa el normalizador compartido de teléfonos. Servidor 11/11 (`reanudacion-configuracion-verde.txt`) y componente 9/9 (`reanudacion-configuracion-ui-verde.txt`). Todavía fuera de las candidatas v5/SQL v11.

### Etapa B: resultados recuperados y condiciones concurrentes (30 de octubre, 06:08 UTC)

- **SQL v11 `41009942644`, aprobado**, fuente `1a502c2652994601472238518ae4ebe9b2d9d28c`: suite de señas 24/24, diez carreras y deadlocks 0; restantes suites SQL aprobadas. `sql-v11-diagnostics.log`, evidencia `sql-v11-evidence` (4 archivos, SHA-256 del paquete `01108226575fd3e9d6f02d5e45b8e0644d6ee56004439a7c792ea9aecc3badf5`). Recibo `tipos-verificados-v11.json`: fuente de tipos idéntica y resumen de todas las migraciones comprobado.
- **Navegador v5 `41009753863`, fallido por un defecto real de la interfaz**, fuente `da0bffb3a249502d3e86a706437942b26f95e2d7`: después de registrar la seña, el botón «Confirmo que voy» seguía apareciendo deshabilitado. La reserva real, los datos de la seña, WhatsApp interceptado, búsqueda y registro con auditoría ya habían avanzado. El plan exige que el botón no aparezca. Se corrigió la rama de Svelte para omitirlo también con seña resuelta; conserva el caso de política apagada. Reproducción local 2 fallos/48 éxitos y corrección 50/50. Evidencia `browser-app-v5-evidence` (50 archivos, SHA-256 `378c49654176f629a36b4250352554bdbe2b9790e9338f2ea4c5ad8897b73a59`).
- **Inspección visual de las capturas v5:** nombre/estado de agenda demasiado comprimidos a 320 px y botón de WhatsApp partido por doble relleno en la lista. La agenda usa filas completas para nombre e indicadores en móvil; se quitó el envoltorio acolchado de la lista, conservando sus tarjetas. Componentes afectados: 68/68. La matriz ahora adjunta sus hallazgos por superficie aunque un paso posterior falle; todavía falta alcanzar la aserción conjunta final.
- **Aplicación v6 `41010664957` (`full`), fallida en tipos**, fuente `aacd0c1a028c98f35feff7e038be13d6ff8c922f`: siete usos nuevos de `exact: true`, admitido por Playwright pero no por Testing Library. Error mío en las pruebas; se retiró esa opción de las siete consultas de componentes. Las etapas posteriores no corrieron. `full-app-v6-diagnostics.log`.
- **Defecto nuevo reproducido antes de corregir:** la política podía cambiar mientras estaba abierto el resumen público. SQL roja `41011128875`, fuente `fc0eb20b42f546eda2a1df9150cdc82024d7a5e3`, falló con `TEST_STALE_DEPOSIT_TERMS OK`: se mostraban $40.000 y se guardaban $50.000. El ajuste 5, sección 12.9 del plan, reemplaza la justificación incompleta del ajuste 4.
  - El formulario conserva las condiciones mostradas; el servidor las valida y las lleva en un encabezado exclusivo de esa petición. El disparador compara monto, vencimiento y activación de cancelación bajo el bloqueo de la política. Un cambio exige revisar y confirmar otra vez, sin paciente ni turno parcial. Ausencia/desconocimiento explícito conserva la alternativa aprobada; relajar las condiciones no impide reservar. Se preserva el reintento idempotente de operaciones ya guardadas.
  - Se comprobó el alcance transaccional en documentación oficial de PostgREST y el clonado de encabezados en `setHeader` de la versión instalada. No se cambió ninguna firma RPC ni migración histórica aplicada.
  - Rojas locales `reanudacion-condiciones-enviadas-roja.txt` (3 fallos/45 éxitos) y `reanudacion-condiciones-formulario-roja.txt` (1 fallo/9 éxitos). Verdes: contrato/transporte 48/48, formulario 10/10 y cadena del servidor 102/102 (`reanudacion-condiciones-cadena-verde.txt`). Tipos e2e sin errores (`reanudacion-e2e-types-v7.txt`).
- **SQL v12 `41011505260`, aprobado**, fuente `283d01070e49453130100f6ce9a38bdda8f8e1bc`: comprobación nueva 25 aprobada (condiciones viejas, requisito nuevo, cancelación nueva, vencimiento nuevo, válidas, desconocidas y relajadas), diez carreras y deadlocks 0; demás suites aprobadas. `sql-v12-diagnostics.log`, evidencia `sql-v12-evidence` (4 archivos, SHA-256 del paquete `f6c8184e62b7fa7ba35a9867a697649c828624da4ed667623e4529fa999414f5`). Recibo `tipos-verificados-v12.json`: tipos `cf70ada1…`, idénticos al archivo local, migraciones `aea85255d4d56f023e92f7460493dcf159fd3646d787c39e3c814c493c7c8015` idénticas a las locales.
- **Candidata conjunta v7:** `adb50c9e86abb0e4397c665c239b971dc74b1630`, rama `verify/senas-etapa-b-app-v7-20261030`; `fast` **`41012287892`, en curso**. Lista explícita `candidata-b-v7-archivos.txt`: suma `public-booking.ts` y la suite SQL 25 a v6 para no perder la cadena ni la prueba. El spec de navegador añade cambio real de política por otra pestaña, rechazo sin ficha parcial, formulario preservado y segunda confirmación con importe actualizado; aún pendiente de ejecutar. Limpieza incluye intentos propios de reserva para no afectar los límites globales de otros specs.
- **Detector estático Impeccable** sobre los componentes Svelte de la lista v7: terminó sin hallazgos primarios (`impeccable-etapa-b-v7.json`). No sustituye la matriz ni la inspección visual.
- **Preservación comprobada de nuevo:** HEAD `80268e2a501198243996e1bdb0048ce066434727`, índice `55cd8f7975542b806308d3e067f81660fe107ed1c5cdbed88962dbe614a1faba`. Sin publicación ni escrituras en producción en esta reanudación. B sigue abierta; C aún no empezó.

### Etapa B: lecturas de la lista por lote y fast v7 (06:16 UTC)

- **Fast v7 `41012287892`, aprobado**, fuente `adb50c9e86abb0e4397c665c239b971dc74b1630`: tipos 0 errores/0 advertencias, Node 162/49 archivos, programador 11/2, servidor 1.568/201 y cliente 241/31, sin omitidas. `fast-app-v7-diagnostics.log`. **Navegador de esa revisión:** `41012669551`, en curso, trabajo `123921839834`; recuperar resultado y evidencia.
- **Nuevo defecto real de consumo, reproducido:** al preparar el aviso de una cancelada, la lista llamaba `loadRebookUrl` por fila, con hasta tres lecturas cada vez. Una página de 300 podía hacer cientos de lecturas. `reanudacion-lista-lote-roja.txt`: una aserción fallida por **300 llamadas** individuales, 14 pruebas aprobadas.
  - `loadRebookUrls` resuelve todos los destinos de la página en como máximo tres lecturas: contextos acotados a los IDs y consultorio autorizados, integraciones únicas del mismo consultorio y, sólo si hace falta, la reserva pública habitual. El lector individual delega al mismo código; no quedan dos reglas.
  - La lista arma el lote una vez y no consulta al transformar cada fila. Sin destino opcional, el aviso de cancelación sigue disponible, como antes. Sin canceladas, no se hacen estas lecturas.
  - Dos archivos, **35/35** (`reanudacion-lista-lote-verde-final.txt`). La prueba de 300 destinos mixtos comprueba que cada turno conserve su enlace y exactamente tres lecturas. La mutación que vuelve a resolverlos uno por uno fue rechazada por aserción (`mutacion-lote-rebook.txt`); fuente restaurada con SHA-256 idéntico.
- **Candidata v8:** `72f17f696df3912e6d0eb3828208386c2d083a30`, rama `verify/senas-etapa-b-app-v8-20261030`; cuatro archivos de diferencia frente a v7. Fast `41012906624`, pendiente detrás del navegador v7; no encolar otro trabajo mientras siga pendiente. Lista de archivos de v7 sigue vigente.
- **Baseline público revalidado en ambas direcciones:** `aacba5b10ff6030ac061e20ce0cccdf28126c180`, HTTP 200 con agente explícito de verificación. `baseline-publico-20261030.json`. La primera lectura urllib sin ese agente recibió 403; se conserva esa limitación en el recibo. Sólo lectura del marcador público: no acredita Auth/base ni es publicación.

### Etapa B: recarga después de condiciones rechazadas (06:19 UTC)

- **Navegador v7 `41012669551`, fallido por un defecto real**, fuente `adb50c9e86abb0e4397c665c239b971dc74b1630`: la reserva recibió el rechazo esperado de las condiciones viejas, mostró el mensaje y no creó paciente, pero el resumen conservó $40.000 después de editar la política a $50.000. No se alcanzó la segunda confirmación ni las matrices posteriores.
  - **Causa comprobada:** `enhance.update({ reset: false })` actualiza el formulario tras un `failure`, pero no vuelve a ejecutar las cargas. La interfaz no pedía la oferta nueva.
  - **Corrección:** el rechazo de condiciones marca que deben recargarse; después de conservar la respuesta y los datos, el navegador ejecuta `invalidateAll` y mantiene el botón ocupado hasta terminar. Las condiciones provienen otra vez del servidor; no se calculan en JavaScript. El recorrido sin JavaScript ya recarga al responder el POST.
  - **Reproducción de servidor** `reanudacion-refrescar-condiciones-roja.txt`: falta la indicación de recarga, 1 fallo/4 éxitos. Corrección 5/5 (`reanudacion-refrescar-condiciones-verde.txt`) y formulario 10/10 (`reanudacion-refrescar-formulario-verde.txt`). El navegador fallido es la reproducción de la falta de actualización real; sigue pendiente demostrar el recorrido corregido.
  - **Evidencia recuperada:** `browser-app-v7-evidence`, 30 archivos, SHA-256 `53ff77fb25ae55a8c09031fc64eb591626b1e5c8cf0179aa9e3c2a7ebc0a515b`; registro `browser-app-v7-diagnostics.log`.
- **Candidata v9:** `62db9245e1ae7fb03fd17fb5f4aa2ac65205eb67`, rama `verify/senas-etapa-b-app-v9-20261030`: v8 más siete archivos (recarga y contrato, sus pruebas, formato legible del validador y contratos funcionales). Lista explícita de v7 sigue cubriendo todas las fuentes. Pendiente corrida completa, sin suponer que el SQL o el fast anteriores la sustituyan.

### Etapa B verificada en CI; comienzo de C (30 de octubre)

- **Fast v8 `41012906624`, aprobado**: fuente `72f17f696df3912e6d0eb3828208386c2d083a30`, tipos 0/0, servidor 1571, cliente 241, Node 162 y programador 11; sin omitidas. `fast-app-v8-diagnostics.log`.
- **Full v9 `41013409668`, fallido sólo al final de la matriz nueva**: tipos, unidades, LibreOffice, SQL 25 y carreras 10/0 aprobados. El recorrido B completó cambio de política, rechazo sin ficha, resumen nuevo, confirmación con $50.000, búsqueda/agenda, apertura de WhatsApp interceptada, cobro/auditoría, deshacer, cron real, cancelación y disponibilidad de nuevo. La aserción conjunta detectó dos hallazgos a 320 px: `24 horas` separado y «Pedir seña por WhatsApp» en dos líneas. Las otras pruebas de navegador y demo no se completaron; no se lo llama full aprobado.
  - Evidencia `full-app-v9-evidence`, 80 archivos, SHA-256 `0d81ba22c3fea7ef953d1f004f85c1316f584991ace9d92fd9e253c6888af9bf`; registro `full-app-v9-diagnostics.log`. Inspeccionadas lista, configuración y agenda móviles.
  - Corrección: espacio inseparable en cantidad/unidad y menor relleno horizontal del botón sólo en móvil. Sin cambiar texto ni aserciones. Dos archivos respecto a v9.
- **Full v10 `41014366957`, aprobado** (06:41 UTC), fuente `bdd8eef1a825935d0db841cd715486cc1b7d9acc`, rama `verify/senas-etapa-b-app-v10-20261030`, trabajo `123927534055`:
  - tipos 0 errores/0 advertencias; Node 162, programador 11, servidor 1571, cliente 241, LibreOffice 1;
  - SQL señas 25/25 y todas las otras suites; diez carreras de señas y deadlocks 0;
  - navegador **50/50**, demo **3/3**, sin omitidas, inesperadas ni inestables; reserva nativa y desempeño de Natalia aprobados;
  - las ocho superficies nuevas × cinco anchos (40 combinaciones) llegaron a la aserción conjunta sin hallazgos. Tema claro/oscuro en condiciones y turno pendiente. Capturas móviles de lista, seña pendiente y cancelación inspeccionadas;
  - evidencia íntegra `full-app-v10-evidence`, **298 archivos**, SHA-256 `c0a7a7d806d0d4a4f0c41514eeb98008e1f36931c566cc0ab1a3462075ed59d6`; registro `full-app-v10-diagnostics.log`, recibo `cierre-etapa-b-ci.json`;
  - el observador mantiene la excepción ya auditada del Realtime ausente del stack descartable (sockets cerrados); no acredita Realtime alojado. Sin respuestas HTTP fallidas ni fallas de red en el recorrido B;
  - todos los archivos de la lista explícita B v7 coinciden byte por byte con v10. HEAD e índice preservados. **B queda verificada en CI**, con release/staging/producción pendientes junto con C. No hay publicación ni escritura productiva de esta campaña.
- **Pruebas C antes de implementar:** `supabase/tests/appointment_slot_releases.sql`. Roja `41014279398`, fuente `9ade692f925cbf2e32e0ac1b26904fe727d1a34d` (v9 más la prueba), trabajo `123926948971`, falló por la tabla nueva inexistente, como correspondía. `etapa-c-sql-roja-diagnostics.log`. La diferencia v9/v10 es sólo visual; el SQL de B es idéntico.
- **Diseño C concretado tras leer el plan íntegro:**
  - una tabla aditiva, una fila por profesional del horario anterior, en la misma transacción que la cancelación/movimiento; tiempos desde `OLD`, no desde asignaciones sincronizadas;
  - fotografía del instante desde el que ocupaba ese intervalo exacto, a partir del último movimiento registrado; correcciones de menos de 30 minutos permanecen en el registro, sin alerta;
  - ajuste 6, sección 12.10: también se registra el movimiento desde un horario pasado para no atribuir a un intervalo nuevo la antigüedad del turno;
  - lectura SQL con RLS y ventana configurable de vista (URL), 14 días por defecto, 1 a 60 como límite, páginas de 50+centinela. Sólo intervalos futuros todavía libres; cualquier ocupación parcial o bloqueo los oculta enteros. Sin otro calculador de disponibilidad;
  - ocultar sólo para dueño/admin/recepción, con actor vigente bloqueado, escritura y auditoría juntas; idempotencia. El lector individual de disponibilidad existente conserva la exclusión final al reasignar;
  - lectura de permisos por conjuntos como turnos/señas, sin regla por fila. Sin configuración nueva de negocio ni cambios en columnas/estados del turno.
- **C SQL v1:** dos archivos nuevos sobre B v10, rama `verify/senas-etapa-c-sql-v1-20261030`; SHA en `candidata-c-sql-v1.sha`. La suite crece a 13: añade un caso adversario de marcas de tiempo iguales con UUIDs de orden invertido. Falta recuperar la corrida; ese caso intenta refutar el orden temporal de esta primera implementación.

### C: dos defectos propios reproducidos y corregidos en SQL; interfaz local (10:41 UTC)

- **C SQL v1 `41040986902`, fallido**, fuente `af2ee37cf9d4eadd27004f68883f3598540614f7`, trabajo `124013441794`: `SLOT_SAME_TIMESTAMP_ORDER`. Los doce controles anteriores avanzaron; el 13 usa dos marcas iguales y UUIDs de orden invertido para demostrar un aviso viejo que reaparece. El UUID no establece antigüedad. `etapa-c-sql-v1-diagnostics.log`.
- **Otra roja antes de corregir:** `41041757879`, fuente `681b0b4939ec46615d6304a8cb611516dcdc5e78`, trabajo `124016009668`: `SLOT_EFFECTIVE_MOVE_TIME`. El inicio de la sentencia precede el movimiento efectivo y puede incluir una espera por bloqueo, atribuyendo esa espera a la ocupación del intervalo nuevo. La prueba compara el registro con el instante inmediatamente anterior al UPDATE dentro de la sentencia. Se ejecuta antes del caso13, que ya tenía su reproducción propia. `etapa-c-sql-roja-v2-diagnostics.log`.
- **Corrección:** identidad monotónica para ordenar hechos (incluida la deduplicación), `clock_timestamp()` al ejecutar el disparador para el instante efectivo y lectura del último movimiento por orden de registro. No se usa el orden de UUID ni el comienzo de la sentencia.
- **C SQL v2 `41042159376`, aprobado**, fuente `4000899969551abad28b08fd344708c77bfdd682`, rama `verify/senas-etapa-c-sql-v2-20261030`, trabajo `124017333951`: suite C14/14, restantes suites y diez carreras de B con deadlocks0. `etapa-c-sql-v2-diagnostics.log`. Incluye cancelación por consultorio y tarea real de señas, equipo con OLD, corrección rápida de turno nuevo y viejo, vuelta rápida desde fecha pasada, ocupación parcial, bloqueo general, ventana acotada, ocultar autorizado/idempotente/auditado, RLS/ACL y reversión completa al provocar falla de registro. No acredita navegador ni publicación.
- **Contratos y servidor C locales:** módulos `slot-releases.ts` puro y del servidor, rojas por inexistencia (`etapa-c-contratos-roja.txt`) y 6/6 después (`etapa-c-contratos-verde.txt`). Valida filas/instantes/UUID/motivos, duplicados, límites51 y página, día local al cruzar UTC; una lectura fallida/nula nunca se presenta vacía.
- **Agenda:** carga una sola RPC y muestra estado desconocido si falla. Ventana configurable en URL, paginación50+centinela, preservación de filtros. Ocultar valida UUID/rol antes del RPC y devuelve un mensaje propio (`slotReleaseMessage`), sin activar la lógica anterior que abre crear turno ante `message`. Roja2/12 (`etapa-c-agenda-roja.txt`), conjunta servidor **20/20** (`etapa-c-agenda-verde.txt`).
- **Componentes:** `SlotReleaseAlerts.svelte`, agenda y leyenda humana en historia. Demo con controles deshabilitados y sólo lectura sin acciones. Una prueba detectó selección vacía por mezclar valores numéricos/texto en opciones; corregido como texto consistente (`etapa-c-interfaz-verde.txt` conserva el fallo, no se renombró).
- **Defecto adicional reproducido en reasignación:** si la prestación del turno original fue retirada, el asistente quedaba sin selección válida. Vuelve a la elección de una prestación vigente y limpia la selección de horario no certificada. La primera guardia no bastó: otro efecto forzaba paso2. La prueba incluía además un espacio normal donde el texto real usa inseparable; se corrigió el selector y **se revalidó la roja contra el componente exacto de Bv10**, restaurando después los bytes y su SHA. `etapa-c-reasignar-roja-validada.txt`.
- **Historia:** ocultar muestra «ocultó un aviso de horario liberado», sin el código de auditoría. Roja1/20 (`etapa-c-historia-roja.txt`). Última conjunta de cuatro archivos de componentes **39/39**, `etapa-c-componentes-verde-validado.txt`; conserva las fallas intermedias separadas. Todavía no hay prueba de navegador C.
- El ayudante de fixture B se extrajo a `e2e/helpers/owned-appointment-fixture.ts` con el mismo cuerpo/guardias, para que el próximo spec C no duplique controles de destino. Ambos deben entrar a la candidata conjunta y verificarse otra vez con B. Falta escribir ese spec y ampliar demo.

### C: tipos recuperados y candidata de aplicación (10:49 UTC)

- **Evidencia SQL C v2 recuperada:** `etapa-c-sql-v2-evidence`, 4 archivos, SHA-256 `b204979c49e625e191f7eb9200e9313415ff98f8346791749b0978593dfbac3e`. Se verificó fuente reproducible y resumen de **todas** las migraciones contra los archivos locales antes de actualizar `database.types.ts`. Tipos `1569609cee6a57fae3a31d49f4d92c3a4de372a0f7d082b7200befa62f5db1af`, migraciones `946f2c1072dc0600ff8f039f6860247ebcd3bef503e39ffdb8987a9bcbcef788`. Recibo `tipos-verificados-c-v2.json`.
- **C app v1:** `a7c8e121926df95592c064e5fea58f58d031e19a`, `fast` `41042827806`, trabajo `124019556557`, **fallido en tipos por un único error mío**: faltaba importar `page` en la agenda para conservar filtros del panel. Sin advertencias; otras etapas no ejecutadas. Corregido y pruebas anteriores de agenda6/6 (`etapa-c-agenda-integrada-verde.txt`). `etapa-c-fast-v1-diagnostics.log`. Lista `candidata-c-v1-archivos.txt`.
- **Límite extremo de paginación reproducido:** en página1001 ofrecía1002, que se normalizaría a1. `etapa-c-limite-pagina-roja.txt`, 1 fallo/3 éxitos. Ahora informa que debe acortarse el rango y no ofrece una página fuera del límite. 4/4 (`etapa-c-limite-pagina-verde.txt`).
- **Navegador C escrito, aún pendiente:** `appointment-slot-releases.spec.ts`, `@candidate-behavior`. Fixture propio/disposable, cancelación por la UI, alerta con nombre largo y cinco anchos, filtros/rango preservados, activación por teclado, reasignación por la UI con lectura de persistencia, retiro por ocupación, segunda liberación y ocultar con auditoría, disponibilidad pública en ambos temas. Limpieza acotada comprobada y nombre original restaurado. La antigüedad se prepara sólo en filas sintéticas propias, sin esperar media hora. No usar el consultorio de Juan ni producción como fixture.
  - El primer tipado e2e detectó que faltaba `patient_name_at_booking` en la inserción sintética; se agregó el dato real de la fixture, sin debilitar el tipo. `etapa-c-tipos-e2e-v1.txt`; corregido sin errores en `etapa-c-tipos-e2e-v2.txt`.
  - Se amplió el caso demo existente para verificar el aviso de horario y ambos controles deshabilitados, sin enlaces de reasignación reales.
- **C app v2:** `11516b3bf719200d0b460f78eb1d7cae5a1f003a`, rama `verify/senas-etapa-c-app-v2-20261030`, lista `candidata-c-v2-archivos.txt` (agrega el spec). Fast solicitado; recuperar su ID y primer resultado. Contratos, permisos y matriz2/4/12 actualizados con sus límites de evidencia. Detector estático `impeccable-etapa-c-v2.json`, sin hallazgos; no sustituye la matriz de navegador pendiente.

### C: fast aprobado y primer diagnóstico de navegador (10:58 UTC)

- **Fast C v2 `41043510072`, aprobado**, trabajo `124021809940`, fuente `11516b3bf719200d0b460f78eb1d7cae5a1f003a`: tipos0/0, Node162/49 archivos, programador11/2, servidor1579, cliente246; sin omitidas. `etapa-c-fast-v2-diagnostics.log`.
- **Navegador C v2 `41043624047`, fallido por el selector de la prueba**, trabajo `124022827221`. Se creó y canceló el turno por la UI, se leyó el registro correcto y la agenda mostró el aviso con nombre largo. Se capturaron cinco anchos. El selector `getByLabel` exacto del rango no encontró el control: el contexto confirma **combobox «Ver próximos días»**. Se cambió únicamente a `getByRole('combobox', { name: 'Ver próximos días', exact: true })`, sin cambiar UI ni tiempos ni aflojar aserciones.
  - Evidencia recuperada `etapa-c-browser-v2-evidence`,20 archivos, SHA-256 `7dc252fcbc2df87ae16e359b0ee3090c93761df21bcbe90d0b6b6e28a7ab835c`; registro `etapa-c-browser-v2-diagnostics.log`. Captura320 inspeccionada. No se alcanzaron reasignación/ocultar ni la aserción conjunta de matriz, por lo que no se consideran aprobadas.
- **C app v3:** cambio de un selector sobre v2, SHA en `candidata-c-app-v3.sha`, rama `verify/senas-etapa-c-app-v3-20261030`. Navegador dirigido solicitado; recuperar ID/resultado antes de otra pendiente. El SQL y código funcional siguen idénticos a la v2 aprobada por fast.

### C: reasignación desde la misma página y preparación del full

- **Navegador v3 `41044762306`, fallido por un defecto real**, fuente `a319aaa84fa506ce3a80c9627a4f6dacedfd9346`, trabajo `124026047988`. El rango se cambió y se conservaron filtros; al activar «Dar este horario» con teclado, cambió la selección de la URL, pero no apareció el asistente.
  - Causa: la navegación dentro de `/agenda` conserva el componente. Su apertura inicial está protegida por `initialized`, y un asistente ya abierto también puede conservar un borrador y la clave del intento anterior.
  - Corrección acotada al nuevo CTA: inicia una navegación nativa con `data-sveltekit-reload`, porque es una **reserva nueva**. Reinicia el componente, selección e intento, en vez de reutilizar un borrador de otra operación. No se cambió la inicialización de búsquedas ni filtros generales de agenda.
  - Evidencia `etapa-c-browser-v3-evidence`,20 archivos, SHA-256 `f7a9e9b51f44c4fac852853295199f767ccb0c704a01f0d0d57a907f7532ae31`; registro `etapa-c-browser-v3-diagnostics.log`. El recorrido corregido todavía debe ejecutarse.
- **Suite SQL ampliada a15 antes del full:** lectura de profesional sólo de sus turnos (incluido equipo), lectura completa para readonly y retiro de lectura/ocultar por restricción comercial. Control positivo: se amplía deliberadamente una política, se exige observar la fuga con el mismo actor/lectura, se retira la política de prueba y se exige aislamiento otra vez. Todo queda dentro de la transacción descartable. El SQL funcional no cambió; el digest de migraciones/tipos sigue siendo el aprobado en C SQL v2. Caso nuevo pendiente de ejecutar en full.
- **C v4 preparada, sin corrida propia:** `df7a4d269f2f94fd57ab78243f8cc2455941a182`, sólo la suite15 sobre v3. **C v5:** v4 más la navegación nueva del CTA, SHA en `candidata-c-app-v5.sha`, rama `verify/senas-etapa-c-app-v5-20261030`; full solicitado. Lista de fuentes `candidata-c-v2-archivos.txt` sigue cubriendo todos los cambios. Recuperar resultado y primer fallo real.
- **Pendiente de la revisión de release:** no asumir que apagar sólo el interruptor global hace compatible cualquier versión antigua. La guardia de Confirmado sigue protegiendo las señas pendientes. La recuperación debe conservar una interfaz capaz de resolverlas o desactivar las políticas por su operación autorizada y comprobar el estado; se comprobará con filas presentes. `aacba5b` es el baseline productivo leído, no una compatibilidad ya demostrada con esta entrega.

### C verificada en CI y preparación de recuperación (30 de octubre, 11:45 UTC)

- **Full C v5 `41046014190`, fallido**, fuente `477e6e7fb474be3af5618192e56a4f2e50998851`, trabajo `124030175799`: tipos, Node162, programador11, servidor1579, cliente246, Office1, SQL C15/B25 y diez carreras/deadlocks0 aprobaron. La reasignación creó realmente el turno nuevo. Falló una expectativa del arnés: carga manual devuelve `created=1` y `from_date`, no el `creado=1` público. Se corrigió sólo la comprobación de URL. Evidencia87archivos `etapa-c-full-v5-evidence`, paqueteSHA `3ec1499f3b43ac9eea6c6e7c8402d9b3feb221db8662cf50cb1b4933de5bf812`; registro `etapa-c-full-v5-diagnostics.log`. No se atribuyeron las fases posteriores a esa corrida.
- **Full C v6 `41047577448`, aprobado**, fuente **`1da731a28d98a9d01b5e79b4f89497068e7564b2`**, trabajo `124035373467`, final11:33:40UTC. Tipos0/0, Node162, programador11, servidor1579, cliente246, Office1; SQL C15/B25 y todas las demás suites; diez carreras B/deadlocks0. Navegador **51/51**, demo **3/3**, sin omitidas, inesperadas ni inestables. Recorrido completo C: cancelar → registro → alerta → reasignar por teclado/UI → persistencia → retiro por ocupación → nueva cancelación → ocultar/auditoría → disponibilidad pública en ambos temas.
  - Nueve matrices × cinco anchos (incluidas las ocho de B), todas sin hallazgos. Observador C sin HTTP fallidos/fallas de red/overflow; conserva exclusivamente la excepción auditada de Realtime ausente del stack descartable. No acredita Realtime alojado.
  - Evidencia **304 archivos**, `etapa-c-full-v6-evidence`, paqueteSHA **`6a2a75456a106048ed149e63152ce5f72fc70bca23f034f03bb5b5eb3feeadf6`**; `etapa-c-full-v6-diagnostics.log`, recibo `cierre-etapa-c-ci.json`. **C queda verificada en CI**; no equivale a release/staging/producción.
- **Recuperación elegida, ajuste7/12.11:** checkpoint Bv10 con sólo la leyenda humana del aviso ocultado de C. Fuente **`bf0fd1892b1adc769d93c8ac369c533ee80a58b7`**, rama `verify/senas-recuperacion-b11-20261030`. Tres líneas cambiadas en dos archivos frente a Bv10. Fast **`41047841872` aprobado**, trabajo `124039923994`. Artefacto solicitado **`41049721655`**. Falta demostrar compatibilidad con filas presentes y esquema C, además del ensayo alojado; no llamarla cerrada por el fast.
- **Staging:** migraciones de la fuente C6 verificada, corrida **`41049660527` aprobada**. Falta recuperar el recibo y verificar directamente el estado128/global apagado. Primera escritura remota de esta campaña, sólo staging. Producción sigue sin cambios.
- **Hueco de recuperación del respaldo detectado por lectura del mecanismo:** el dump/historial no repite las llamadas `cron.schedule` de las migraciones; el manifiesto local histórico del24-oct no incluye tablas cron (no es una lectura actual). Se agregó operación versionada para recuperar exactamente los dos trabajos de señas en el destino restaurado, con interruptor apagado, sin tocar obligaciones. El ensayo la ejecuta dos veces sólo en su contenedor y verifica comandos/horarios/estado y siguiente identidad de C. No se afirma recuperar otros trabajos históricos con este paso.
  - Roja Node por módulo inexistente `recuperacion-automatismo-roja.txt`; verdes inicial4/4 y final6/6 (`recuperacion-automatismo-verde-final.txt`), incluyendo nulos, familias incompletas, jobs faltantes/duplicados/alterados y distinción B sin C. **Pendiente SQL real de restauración**; mocks no prueban pg_cron ni la secuencia. Archivos nuevos aún posteriores a C6; deben integrar la siguiente candidata exacta antes de release.

### Staging ampliado, respaldo restaurado y revisión exacta de release (11:54 UTC)

- Recibo de migraciones41049660527:126→**128**, B SHA256 `d93d72912509067c0ea46e324f614f0d39b7ea7205864500204bb1ce896d82a1`, C `18c33636b58eb641e44b12ae3563f2552636a3ff0c2eec2d7042893562a0446b`. Lectura independiente11:49 `staging-after-migrations.json`:128, globaloff, dos trabajos nuevos activos, una única política activa que pertenece al ensayo sintético propio.
- **C7 `843f163f697dfd90af005ae2a1f8068b9c2781fd`**, ocho archivos de operaciones/ensayo/documentación sobre C6, sin cambios funcionales de aplicación. Lista explícita `candidata-c-v7-archivos.txt`. Artefacto **41050317496 aprobado**,222archivos íntegros. Desplegado sólo en staging, app versión `496f3953-38ea-46b8-87cd-810815b4e377`; Natalia staging versión `d9d2a36a-280e-4620-95e4-85b90e89ee84`,35archivos, ninguno nuevo/subido respecto al sitio que servía. Paquetes C7 y recuperaciónB11 comprobados con `loadBuildArtifact`.
- **Fixture alojada nueva, propia y acotada:** `scripts/staging-deposit-recovery.mjs`, sólo acepta el destino staging fijo. Semilla local remota11:44–11:45, `staging-deposit-recovery-seed.json`: consultorio/dueña/paciente/profesional propios, política sintética40mil/autocanceloff, una exclusión, tres señas (pendiente/reservado; recibida/confirmado; exceptuada/confirmado), un horario liberado. Global se enciende sólo dentro de la transacción de semilla, invisible a otros; se confirma apagado. Guardias de identidad/documentos/membresías antes de comprobar o limpiar. Nunca usa Juan/Natalia como fixture.
- **Prueba alojada41050345377 falló antes del ingreso por el arnés**, no demuestra todavía incompatibilidad visual de `aacba5b`: había dos botones Ingresar y el selector era ambiguo. Recibo `staging-anterior-roja/…json`. Se restringió al primer formulario, como el helper existente. **C8 `9d6a0784b3af78781375b04d4cb7be43a2823e93`**, sólo esa línea sobre C7; rama `verify/senas-etapa-c-app-v8-20261030`. Artefacto **41050801627 en curso**. No debilita aserciones ni cambia aplicación.
- **Restauración staging41050555719 aprobada** sobre C7, 11:48–11:51: 101tablas/520filas,128migraciones idénticas, sin diferencias de filas/objetos administrados/archivo. Nuevas tablas recuperadas con filas **1política/1exclusión/3señas/1interruptor/1horario**; repetición de operación recupera exactamente2jobs, globaloff y próxima identidadCsegura. Archivo sintético2368B con misma huella; limpieza confirmada. Evidencia `staging-backup-rehearsal-c7/backup-rehearsal.json` y registro `.log`. Advertencias de grants a funciones de extensiones se resumen en el recibo; no se presentaron como inexistentes.
- **Producción, sólo lectura:** `production-auth-before.json`, revisiónaac/126/legacyoff/32bindings; autenticación negativa y válida sobre entrada heredada, agenda de la cuenta de lectura en ambos orígenes, sin nodos de error. No se usó Juan para escrituras. Fuente de verificadores adaptada con fecha actual y migraciones explícitas, no se ejecutó el capturador antiguo con SHAs fijos.
- **Copia productiva externa fresca41050465153**, ejecutor privado742e5de, `mode=rehearsal`, **aprobada**. Pendiente conservar recibo completo/descarga independiente y descifrar esa instantánea a carpeta privada nueva antes de usarla para autorizar migraciones. Aún no hay escrituras ni publicación productiva de la campaña.

### Recuperación alojada aprobada y regreso a candidata (11:58 UTC)

- **Artefacto C8 `41050801627` aprobado**,222archivos verificados. Los35archivos de Natalia staging son byte por byte iguales a C7: no se repite su publicación. C8 instalada en staging como `ad726457-69f7-4b82-b9df-95fd04a468a4` después de los dos ensayos B11. Registros `staging-deploy-c8-app.log` y `artefacto-c8.json`.
- **Orden de recuperación real de staging:** `staging-global-off-before-b11.json`,11:53:30UTC, apagado confirmado **antes** del despliegue B11. B11 instalada `e3d31c10-df31-4b91-a60d-d8e2b9293a42`. **Prueba alojada41051381337 aprobada**, C8 como fuente del arnés/B11 como revisión servida: estados pendiente/recibida/exceptuada presentes; Confirmar y Deshacer reales por UI, lectura SQL posterior en los dos estados, auditorías1/1; mismos estados finales/montos; sin pageerrors ni respuestas500. Recibo `staging-deposit-b11/…json`.
- **Perfil rollback alojado41051461112 aprobado**, trabajo124048505628: B11 exacta,136archivos cliente/35Natalia, CSP sólo staging,65relaciones sin exposición anónima, HTTP→HTTPS308, reserva nativa y recuperación sin duplicación desde Natalia en escritorio/móvil; ambas canceladas. Evidencia7archivos `staging-rollback-b11-evidence`, paqueteSHA `eb88fc7a892d46a6e7509e21f7ffaf723c7384c7fe3d2d9c4ffc5211549f11b3`.
- **Copia previa productiva descargada y descifrada independientemente:** instantánea11:49:48.807UTC de41050465153,105tablas/4246filas/126migraciones/24referencias de objetos,22contenidos únicos. Restauración SQL/Storage del propio ejecutor aprobada,0diferencias y servicios aislados retirados. ManifiestoSHA `a75720d8594f18b744d2276216529b888490592a2d914143bb95da5f7f8b8bd5`, cifradoSHA `d1bde51245146fa842a6b683f453bd625e2b3a551848044b156fbd21dbebb815`.
  - `respaldo-productivo-previo/manual-backup.json`, `manual-backup-readback.json` y `local-recovery.json`. Carpeta privada nueva fuera del repositorio, ruta sólo en el recibo local. Huellas/bytes/llave/destino privado comprobados. La descarga local no se presenta como otra restauración SQL.
  - Primer intento de invocación de `recover.py` con Python `-I` falló antes de importar su módulo vecino `backup_drive` (reproducido con `--help`, sin red/datos). Se corrigió únicamente el lanzador: mantiene `-I` e incorpora explícitamente la ruta del ejecutor revisado. Segundo intento completó la recuperación; no se certificó el primero ni se reutilizó una salida parcial.
- **Producción sigue en aac/126, sin escrituras de campaña.** Ensayo productivo propio y lectores adaptados preparados bajo `.verification`, todavía sin ejecutar. Falta check alojado C8, release exacto completo, ensayo DDL con rollback y publicación/drenaje/reversión/limpieza autorizadas.

### C8 alojada y ejecución natural de pg_cron (12:06 UTC)

- **Check C8 alojado41051835546 aprobado**: misma prueba de tres estados/Confirmar/Deshacer, con C8 exacta servida. Estados/montos conservados, auditorías acumuladas2/2 tras B11 y C8, sin pageerrors ni500. Recibo `staging-deposit-c8/…json`. No se llama prueba productiva.
- **Release exacto41051917975 en curso**, trabajo124050042438, fuente C8 `9d6a0784b3af78781375b04d4cb7be43a2823e93`, artefacto41050801627 y recuperación41049721655. No se publicará hasta aprobarlo y conservar evidencia.
- **Ejecución natural real en Supabase staging, sin invocar a mano la función:** tras los checks B11/C8 se preparó exclusivamente la seña pendiente de la fixture propia para vencer. Guardias exigieron globaloff previo, identidad propia y ninguna otra política activa; se activaron sólo su autocancelación y el interruptor general de staging a12:01:47UTC.
  - Trabajo `cita-suite-deposit-expiry` (job6), ejecución natural **12:05:00.16088→12:05:00.60828UTC, succeeded**. Procesadas1/canceladas1, turno Cancelado, seña Vencida, auditoría1 y horario liberado1 con motivo `deposit_expired`. No hubo llamada manual ni simulación de scheduler.
  - Recibos `staging-natural-expiry-start.json`, `staging-natural-expiry-passed.json`; script operativo `staging-natural-expiry.mjs`. Se apagó global/autocancelación del ensayo inmediatamente después; conservar `staging-natural-expiry-stopped.json`. La fixture queda con esa seña vencida hasta su limpieza; los checks anteriores se conservan y no se ejecutan de nuevo esperando los estados viejos.
- **Certificado de fuente local** `ci-source-c8.json`:1194archivos/10.116.731B, tree `1001540ebeba18ca0788a646e472fe82382c6664`, digest `98d6af6b81e5b15b5a3befde71edb69fdb447224b3bb4f66b996aa8a5f56241c`. Todo código de apps/packages/scripts/migraciones, lockfile y AGENTS coincide byte por byte con C8. HEAD/índice preservados. Aún no reemplaza el puntero operativo `.verification/ci-source.json` (95b histórico); antes de usar el deploy del scheduler, conservar ese puntero y seleccionar explícitamente el manifiesto C8 verificado.
- Main principal leído por ID/permisos/remoto: `4352f8abd00dd9d5899349959185b530eca187b0`,25-oct, tiene diferencias anteriores a esta campaña frente al baseline servidoaac. No se sobrescribió ni se promovió a ciegas; la fuente completa probada y el artefacto permanecen identificados en el auxiliar.

### Ensayo de migraciones productivas revertido y límite de evidencia (12:08 UTC)

- `rehearse-production-migrations.mjs` ejecutó las dos migraciones pendientes y su historial **dentro de una transacción que terminó con rollback**, contra el esquema productivo real. Backup fresco ya comprobado; fuente SQL idéntica a C8. No se comprometieron ni se publicaron cambios.
- Resultado12:06:48.903UTC:126aplicadas/2pendientes, **0fallas** y **0diferencias** frente al catálogo de staging en RLS/tablas/funciones/políticas/columnas/restricciones/índices/disparadores/cuerpos. `production-migration-rehearsal.json` y `.log`.
- **Lectura independiente posterior12:07:03UTC:**126migraciones, tablasB/Causentes y0trabajosnuevos (`production-after-rehearsal-readonly.json`). Prueba el rollback efectivo, no sólo que el programa lo intentó. La producción sigue sirviendoaac; falta release completo antes de publicar/confirmar migraciones.
- `staging-natural-expiry-stopped.json` confirma12:06:05.55062UTC:globaloff y0políticas con autocancelación. El ensayo natural terminó; no dejarlo encendido esperando el cierre.
- **Limpieza del ensayo alojado comprobada12:09:11UTC:** eliminados sus cuatro turnos, el consultorio y todas sus filas por consultorio (recorrido dinámico de cada tabla public/private con `business_id`); luego dueña de Auth retirada por API. Lectura final0consultorios/0dueñas. `staging-deposit-cleanup.json`. Sin documentos ni miembros ajenos, validados antes de borrar. Se preserva la fixture permanente separada de release que usa el recorrido público de Natalia.
- **Paquetes conservados fuera de la retención de Actions:** `release-packages-preserved.json`, copias privadas locales íntegras de222archivos cada una bajo `~/.local/share/cita-suite/releases/<SHA>`. Manifiesto C8 SHA256 `2c37737f67e7ebc02e183419164b8358fd6e5e94838a29ed74bba883fba5a90d`; B11 `229a5b98d239672492f2117d9a25874542f64b40645561b0ebf8b4de270b0a7d`. No son respaldos externos ni otro despliegue; permiten volver a los mismos bytes sin reconstruir ni depender de que siga disponible el artefacto temporal.

### Release C8 fallido: observación tardía y evidencia no transportada (12:18 UTC)

- **41051917975 fallido**, trabajo124050042438, fuente C8. Tipos/Node168/scheduler11/servidor1579/cliente246/Office1/SQL C15/B25/diez carreras0deadlocks, navegador de desarrollo51/51/demo3 y fidelidad/desempeñoNatalia aprobaron en registros. **El perfil del paquete compilado falló** tras39casos aprobados, en `roles-agenda-regression.spec.ts:490`: un aviso `fixture-realtime-cancelled` y0cierres CONNECTING observados. No se ejecutaron los perfiles de rollback descartable ni staging final; no se llama release aprobado.
- Hipótesis causal localizada: `observeRenderHealth` agrega el observador de WebSocket sólo a futuras navegaciones. Ese caso lo llama **después de ingresar**, con un documento ya abierto; el cierre de ese documento al navegar podría quedar sin observar. No se amplió la excepción ni se descartó el mensaje: se agregó primero una prueba nativa sobre documento ya cargado, sin código de app. Fuente roja `9de47e1e32ab3bbe17cd7527d9c23dd8981b8e28`, rama `verify/senas-sonda-roja-20261030`, navegador dirigido **41054527935 en curso**.
- **Segundo fallo del arnés:** el empaquetador calculó634archivos/37.139.979B originales/28.658.235B gzip, dentro del límite original48MiB de datos pero fuera del límite24MiB comprimido. Rechazó antes de emitir un archivo completo. No hay artifact alternativo en Actions. **No se recuperaron imágenes/reportes de esa corrida**; sí ZIP de registros y diagnóstico sin bloques (`release-c8-logs.zip`, `release-c8-diagnostics.log`). No atribuirle imágenes de otra corrida ni ocultar esa pérdida.
- Roja portátil determinista de transporte,25MiB de bytes incompresibles: `evidencia-incompresible-roja-validada.txt`, falla explícita `Compressed evidence exceeded the workflow log budget`. Corrección local: transporte gzip48MiB, ZIP128MiB/miembro96MiB por las dos copias del mismo bloque que guarda Actions; **se mantienen48MiB extraídos/2000archivos**, rutas autorizadas, SHA, redacción y prohibición de sobrescritura. No se omite evidencia para entrar en el presupuesto. Pruebas4/4 en `evidencia-transporte-verde.txt`: ese roundtrip íntegro, redacción/conservación de fallo, corrupción/no sobrescribir, traversal y rechazo del payload49MiB (los últimos controles agrupados en sus casos). Falta verificación CI de estos cambios y cerrar la roja de la sonda antes de corregirla.
- Producción conserva aac/126. Staging está en C8/globaloff y fixture propia eliminada. Antes de otra publicación se necesita una nueva candidata y paquete exactos con el arnés corregido, y release completo aprobado.

### Omisión de sonda reproducida sin app y candidata C9 (30 de octubre; horas exactas en recibos de CI)

- **Roja41054527935 confirmada**, fuente `9de47e1e32ab3bbe17cd7527d9c23dd8981b8e28`, trabajo124058604261: nuevo caso sobre documento ya abierto falla exactamente con1aviso/0cierres; los dos controles anteriores aprueban. Documento sintético propio, sin app/SDK/ingreso: el mecanismo queda localizado en el observador, no inferido de un mensaje conocido.
  - Evidencia14archivos `sonda-documento-roja-evidence`, paqueteSHA `9383f812df49c70f1ab010093dfb9d899e2fa617e2bce6512712b7bde45d208d`; `sonda-documento-roja-diagnostics.log`.
- **Corrección del observador:** registra la misma función tanto con `addInitScript` para documentos futuros como con `evaluate` en el actual, con marca por documento para no envolver dos veces. No cambia el socket ni su transporte. El observador del wizard pasa además al comienzo del caso, antes de ingresar. No se amplía ninguna categoría permitida.
- Suite de sonda ahora4: cierre nativo actual y futuro contados exactamente1; mensaje forjado actual y futuro rechazados sin cierre. `assertAndAttach` devuelve el mismo informe de metadatos que adjunta, después de todas las aserciones. Tipos e2e verdes locales (`sonda-tipos-verde.txt`); las cuatro conductas quedan pendientes de navegador en CI.
- **C9 preparada**, fuente en `candidata-c-app-v9.sha`, rama `verify/senas-etapa-c-app-v9-20261030`,7archivos sobre C8: helpers/spec de sonda/caso de roles,3guiones Python y guía de verificación. Lista `candidata-c-v9-archivos.txt`. **Sin cambios en código funcional de apps, tipos ni migraciones** respecto a C8. Artefacto solicitado; recuperar su ID antes del diagnóstico del paquete y del release completo.
- Fuentes y copias C8 no se llaman finales mientras C9 esté pendiente. Se conservan como antecedentes con sus recibos. El respaldo productivo de11:49 cubre126migraciones; verificar su antigüedad menor a6h antes de publicar. El ensayo staging de128 tiene su recibo propio.

### C9 compilada verificada y nuevo release (15:38 UTC)

- **C9 `deb74b023431e4f173eed85d6651c5073ad44557`**, tree `ab0d664a0eac402ef5b00753aa5e4480e3f7fac6`, certificado `ci-source-c9.json` (1194archivos/10.120.972B/digest `f788a13368b2a4fa835edfb9baac85cc6ecf0677eb19002c72513d1f858e75ff`). Runtime/scripts/migraciones locales idénticos; sin cambios de producto sobre C8.
- **Artefacto41081146798 aprobado**, creado15:29:14UTC,222archivos recuperados/verificados en `release-c9` y copia privada externa alworkspace (`release-c9-preserved.json`). Los35archivos Natalia staging siguen idénticos a C8: no se repite esa publicación. C9 instalada sólo en staging como `1334e55b-682d-45d7-b214-19530ce2a08b`, globaloff/fixturepropiaeliminada.
- **Diagnóstico dirigido del binario41081605917 aprobado**, trabajo124151903948: **5/5**,0omitidos/inesperados/inestables, sin reintentos. Los cuatro controles de sonda nativa/forjada actual/futura y el caso real de roles que había frenado C8. Evidencia25archivos `sonda-compilada-c9-evidence`, SHA `787b15790fbff5ee1b24c8d55e5454e5dfae0e51b07cd5b6ab704649d87847dc`.
- **Release completo C9 `41082416537` en curso**, artefacto41081146798/rollback41049721655. No se publica hasta aprobar todas sus fases.
- **Nueva copia productiva12641081864440 en curso**, ejecutor privado742e5de, `mode=rehearsal`, para renovar la instantánea antes de la ventana. La anterior no se borra ni se da por nueva. `check-backup-previo-fresco.py` escribe recibos en carpeta nueva. Preflight fresco15:33:56 (`production-prewindow-readonly.json`) no detectó deriva de app/scheduler/bindings/crons/DB126/legacyoff. No nuevos ingresos Auth ni escrituras de esa lectura.

### Respaldo fresco previo a ventana comprobado (15:44 UTC)

- **41081864440 aprobado** sobre742e5de. Snapshot **15:37:23.655UTC**,105tablas/4272filas/126migraciones/24referencias(22contenidos). Restauración SQL/Storage del mismo snapshot:0diferencias/objetosadministradospresentes/serviciosaisladosretirados. Rol dedicado readOnlyon/BYPASSRLS; no se modificó su acceso ni se llevó clave elevada al repositorio auxiliar.
- Descarga independiente desdeDrive comprobada y luego descifrada con llave privada sólo en llavero temporal; huellas de SQL/objetos/manifest validadas. ManifiestoSHA **`5e2d2acf53acf129ded955cf5f9500d7a26fca280bb63f812758a46d38a522d6`**, cifradoSHA `b5196dcf8b5be64ae7fedf4f2e17bb05d7ba06a3646aeffd57954ea3f5aeb8c7`.
- Recibos `respaldo-productivo-previo-fresco/{manual-backup,manual-backup-readback,local-recovery}.json`; carpeta privada **`/home/usuario/.local/share/cita-suite/backups/production-senas-20261030T154244Z`**. La anterior11:49 permanece. Usar esta copia15:37 como parámetro de las migraciones, comprobando nuevamente su edad y estado antes de aplicarlas.
- **Permiso de retención comprobado con rollback15:53:26UTC:** rol productivo `postgres`, misma condición de14días de la tarea nueva;4929filas eliminadas dentro de la transacción y4929presentes otra vez después del rollback. `production-retention-rollback-rehearsal.json`. Es un ensayo manual de comando/permisos/restauración, no ejecución natural del trabajo diario. No quedaron eliminaciones persistidas.
- Procedimiento concreto preparado en `publicacion-senas-avisos-natalia.md`: gate de release, respaldo seleccionado, drenaje15min20s, migraciones128/defaultoff, C9/B11/retorno nativo, prueba propiaHTTP, comparación de huellas completas sin exclusiones después de limpiar, y reactivación/observación del scheduler. Su existencia no acredita ejecución.

### Release C9 aprobado y comienzo de ventana productiva (16:07 UTC)

- **Release41082416537 aprobado**, fuente **`deb74b023431e4f173eed85d6651c5073ad44557`**, trabajo124154701490, run `b0b8458d-5e0b-402f-8144-bfddbab692cd`, final15:56:54.581UTC: **20/20fases**,0errores/advertenciastipos,Node168/scheduler11/server1579/client246/Office1,SQL C15/B25+10carreras/deadlocks0. Browser **53desarrollo/53paqueteC9/49compatibilidadB11**, demo3, sin omitidas/inesperadas/inestables ni reintentos. StagingC9:136cliente/35Natalia/CSPpropia/65relaciones sinexposición; reserva nativa escritorio/móvil recuperada sin duplicar y cancelada.
- Evidencia completa **821archivos**, `release-c9-evidence`, paqueteSHA **`9c4b10613f754aa1f45416126ca13c1687054d8da58ff2b7fd5774ae9ccc28e1`**; `release-c9-diagnostics.log`, `release-c9-run.json`, recibo `cierre-release-c9.json`. El transporte ampliado conservó íntegra esta corrida. La pérdida de imágenes de C8 permanece documentada.
- **Límite explícito del perfil B11:** el arnés excluye4casos marcados `@candidate-behavior`; B11 ya contiene A/B. Para no inferir su comportamiento compilado de la exclusión, se lanzó diagnóstico adicional **41086383561**, fuente/paquete B11/artefacto41049721655, grep de esas conductas ya presentes: **aprobado**. Su base descartable es la127 que declara B11, separada del esquemaC128; la compatibilidad128 se conserva con49casos y con la UI alojada de tres estados/registrar/deshacer. Recuperar evidencia y cantidad exacta del diagnóstico antes de citarla. No sumar esos casos como si fueran un único perfil128.
- **Manifiesto operativo seleccionado:** se preservó el puntero95b en `ci-source-pointer-before.json` y se seleccionó `ci-source-c9.json`. Índice y HEAD originales conservados.
- **Primera mutación productiva persistida de esta campaña:** scheduler instalado sincrons, versión **`7af0c71c-7681-457e-99e2-9762f53e5a26`**, bindingAPP→app, mismo secreto existente; `production-stop-scheduler.log`. No cambió aún la app ni el esquema productivo.
- **Confirmación API16:05:47.679UTC:**0crons en ambos schedulers, app original4e29aba6/aac intacta. `production-drain.json`. Margen conservador15min20s: **no antes de16:21:07.679UTC**. No se afirma observar directamente ejecuciones en vuelo. El respaldo elegido es el fresco15:37; todavía no se aplicaron las migraciones.


- Diagnóstico adicional B11 **41086383561:3/3**,0omitidos/inesperados/inestables: hora del consultorio frente a otra zona de navegador, flujo completo de señas y WhatsApp público/ficha. Evidencia66archivos `b11-funciones-previas-evidence`,SHA `1d867d21f6070090cdaf612eaaed3b04c028127ddafed94632c9b6d2ab92a1b7`. Es B11compilada con su esquema127; no se lo atribuye al esquemaC128. Los49casos de compatibilidad y la UI alojada con128 conservan su prueba independiente.

### Migraciones productivas128 aplicadas después del drenaje (16:23 UTC)

- Gate16:21:33.909UTC **posterior** al límite16:21:07.679: `production-preapply-gate.json`. Revalidó release20/20, ambos paquetes,0crons/destinoAPP→app/versiones esperadas, DB126/legacyoff/tablasnuevasausentes y preservación de HEAD/índice. Recalculó hashes/bytes de los cinco SQL y24referencias de objetos de la copia15:37; sin cambios/copia vigente.
- **Huella previa de datos completos**,16:21:40UTC, `production-core-before.json`:21consultorios/122pacientes/108turnos, SHA por todas sus filas sin exclusiones. Ningún valor salió de PostgreSQL y la fixture propia estaba ausente. Conservar para la comparación después de limpiar.
- **Transacción productiva16:22:13.766→16:22:17.810UTC, comprometida**,126→**128**, ambas migraciones con sus hashes ya verificados y sin reconciliación pendiente. Recibo y `production-migrations.log`; copia usada `production-senas-20261030T154244Z`. No se editaron migraciones aplicadas.
- **Lectura16:23:22UTC**, `production-features-installed.json`:globaloff,0políticas/0señas/0huecos, ambosjobs activos con horarios/comandos exactos. No hay filas retroactivas en los turnos anteriores. Heartbeat aún nulo antes del primer tick natural, no se inventó una ejecución.
- Despliegue C9 iniciado desde su paquete precompilado; aún pendiente comprobar versión/bytes y ensayar recuperación B11/retorno. SchedulerCF continúa sincrons. No se configuró Natalia.

### C9 instalada y lectura productiva de bytes/destinos (16:26 UTC)

- **Aplicación C9 productiva instalada**, versión **`e5dddd3c-90e2-423c-8ce9-fc9ed4b9be15`**, fuente `deb74b023431e4f173eed85d6651c5073ad44557`, desde el paquete41081146798 sin reconstrucción local. `production-deploy-c9.log` y `production-c9-installed.json`.
- Marcador C9 comprobado en `app.cita-suite.com.ar` y workers.dev; deployment100%/32bindings preservados. `production-verify-c9-first.log`:136archivos cliente exactos, CSP sólo de Supabase productivo, **74relaciones sin exposición anónima**; HTTP→HTTPS301dominio/308workersdev. Natalia35archivos exactos, sin otra publicaciónVercel. No tocar landing/DNS.
- Conteos originales todavía21consultorios/122pacientes/108turnos,1conexiónCalendar/1evento; DB128/legacyoff. Falta ensayo B11/retorno y comparar huellas después de limpiar, antes de declarar cierre. El schedulerCF conserva0crons durante la prueba.
- Comenzó la semilla exclusivamente propia para comprobar estados existentes y reversión; no se usan Juan/Natalia ni mensajes, archivos o proveedores externos. Conservar su recibo y limpieza verificable.

### Recuperación B11 productiva con señas presentes aprobada (16:30 UTC)

- Semilla propia16:26:32→16:26:36UTC, `production-owned-seed.json`: política40mil/autocanceloff,1exclusión,3señas(paid/pending/waived),1hueco. Globaltrue sólo dentro de la transacción de semilla y commitfalse. ComprobadoOFF antes de revertir (`production-features-before-recovery.json`,16:27:58). PGexpiry natural16:25succeeded/0procesadas/0canceladas enOFF.
- Estado capturado antes de recuperar, `production-before-recovery.json`:22consultorios/123pacientes/112turnos(incluyepropiob1/p1/a4),Calendar1/1;32bindings;C9e5dddd3c;0crons ambos.
- **B11 instalada** versión **`0fbe672e-607c-4358-b335-3b047642ff09`**; `production-deploy-b11.log`. Bytes136/CSPpropia/74relacionesnoexpuestas/HTTPS verificados en `production-verify-b11.log`.
- **Prueba real productiva16:29:12→16:29:22 aprobada** (`production-owned-check-bf0fd1892b1adc769d93c8ac369c533ee80a58b7.json`): autenticación propiaHTTP,3estados legibles, registrar y deshacer víaacciónreal, lecturaSQL posterior confirmaConfirmado/Pagada y luegoReservado/Pendiente, auditorías1/1. Montos/estadosrestantes/globaloff conservados. No es navegador local ni simulación.
- **Readback productivoB11 aprobado** (`production-b11-readback.json`):32bindings/ambosmarcadores/DB128/legacyoff/conteos sin cambios/Authnegativayválida/agenda de la cuenta configurada en ambos orígenes. Esta cuenta sólo lee; las escrituras corresponden a la fixture propia.
- Retorno nativo hacia **C9e5dddd3c** iniciado; no asumirlo completado hasta volver a comprobar versión/bytes,accionespropias,Auth/agenda y limpieza. SchedulerCF permanece0crons.

### Retorno nativo C9 y comprobación propia de horarios (16:40 UTC)

- **Retorno nativo C9 completado** hacia `e5dddd3c-90e2-423c-8ce9-fc9ed4b9be15`, fuente `deb74b023431e4f173eed85d6651c5073ad44557`; `production-native-return.log`. Bytes/destinos otra vez aprobados en `production-verify-c9-return.log`; `production-c9-readback.json` confirma ambos orígenes, 32 bindings, DB128/legacyoff, conteos preservados, Auth negativa/válida y agenda en ambos orígenes. La cuenta configurada sólo leyó.
- **Señas con C9 productiva aprobadas16:33:28→16:33:38UTC**, `production-owned-check-deb74b023431e4f173eed85d6651c5073ad44557.json`: tres estados propios, registrar y deshacer por HTTP autenticado real, lectura SQL y auditorías acumuladas2/2, globaloff.
- **Fallo de arnés adicional conservado**, `production-owned-slot.json`,16:35:07UTC: `RELEASE_NOT_SHOWN`, antes de cualquier mutación. La comprobación buscaba `appointment_id` en el DTO, cuyo contrato usa `appointmentId`. No se cambió la aplicación. `production-owned-slot-v2.json`,16:39:39UTC: la misma respuesta da falso para el predicado anterior y verdadero para el contrato correcto; luego ocultar por HTTP autenticado real pasa, desaparece de la agenda y SQL confirma oculto por la dueña propia, una auditoría y el turno aún cancelado. No es navegador ni simulación.
- **Siguiente:** limpiar exclusivamente la fixture, comparar huellas completas y globaloff, respaldo posterior128; luego restaurar y observar el scheduler. Sigue sin darse por cerrado hasta completar estos pasos.

### Limpieza, huellas intactas y programador restaurado (16:47 UTC)

- **Limpieza propia16:40:05→16:40:08 aprobada**, `production-owned-cleanup.json`: guardias de identidad/documentos/membresías, retiro de cuatro turnos/consultorio y todas sus filas porbusiness_id, dueña Auth eliminada,0consultorios/0dueñas finales. No se repiten checks contra filas borradas.
- **Integridad16:40:24 aprobada**, `production-core-after.json`: todas las filas de21consultorios/122pacientes/108turnos, sin exclusiones, producen exactamente los mismos SHA256 que antes de migraciones. No es sólo igualdad de conteos ni una huella de toda la base. Calendar1/1 conservado en lecturas de estado.
- **Funciones16:40:33**, `production-features-final.json`:128/globaloff/0políticas/0señas/0horarios; dos trabajos activos con nombres/horarios/comandos exactos. Cuatro ejecuciones pg_cron naturales16:25/30/35/40succeeded,0procesadas/0canceladas. Retención diaria sigue siendo ensayo manual con rollback, no ejecución natural observada.
- **Restauración del programador aprobada**, `production-restore-scheduler.log`, versión **`16c73f28-eb48-4651-ac71-f2fd9f4087f9`**, fuenteC9. `production-scheduler-restored.json` confirma5cronCF/0staging/APP→app, C9e5dd/32bindings/128/legacyoff/conteos originales. El aviso de Wrangler por entornos se conserva: el destino efectivo top-level productivo se comprobó por API; no se confundió con staging. Un tail saneado activo después de completar el despliegue; observación natural pendiente.
- **Copia posterior solicitada41092046966**, fuente privada742e5de,16:40:38UTC,mode=rehearsal, después de limpiar. A16:47 en curso. No llamarla restaurada/descargada hasta terminar y leer recibos. Incluye el esquema128 limpio; la prueba poblada de recuperación de nuevas tablas/trabajos sigue siendo staging41050555719.
- [Cierre por requisito](cierre-senas-avisos-natalia.md) preparado y arquitectura actualizada; pendientes operativos explícitos. El `git diff` entreaac yC9 para scheduler, contrato compartido y endpoints internos es vacío: no se cambió su lógica ni frecuencia. Esto no convierte un cron configurado en evento natural observado.

### Copia posterior128 recuperada y configuración enlazada leída (16:54 UTC)

- **Copia productiva posterior41092046966 aprobada**, fuente742e5de/mode=rehearsal, snapshot **16:44:47.284UTC**, después de limpiar: **110tablas/4295filas/128migraciones/24referencias(22contenidos)**. Restauración aislada de esa instantánea sin diferencias de filas/historial/objetos administrados/archivos y servicios retirados. Rol dedicado de sólo lectura/BYPASSRLS. No se cambiaron permisos de exportación ni secretos para hacerla pasar.
- **Descarga y descifrado independientes aprobados**: `respaldo-productivo-posterior/{manual-backup,manual-backup-readback,local-recovery}.json`; carpeta privada `~/.local/share/cita-suite/backups/production-senas-20261030T164850Z`. ManifiestoSHA256 **`ef847fb3378d952e3e4d0e853556227a94760dbef3ceac1ec9c117e6987716b5`**, cifradoSHA256 `e8cd1e4baddd56d6b4577aa7b520d842118d160317a29b760730fd47c5a1c06c`. Se conserva además la copia previa126, sin sobrescribirla.
- `production-post-backup-feature-tables.json` comprueba presencia exacta de las cinco tablas nuevas:0políticas/0exclusiones/0señas/1global/0huecos,128migraciones y snapshot posterior a limpieza. La restauración genérica privada **no reconstruye cron**; la operación versionada es obligatoria en un destino restaurado antes de servirlo. Tablas nuevas no vacías/dosjobs idempotentes/identidadCsegura tienen su prueba separada en staging41050555719.
- **Supuesto pendiente de la promesa1 comprobado**, lectura productiva16:54:07 (`production-natalia-linked-configuration.json`): clave extraída del HTML productivo cuyos35archivos ya coincidieron, destino único/activo/unprofesional, tanto obra social como plan vinculados a la ficha mediantepatientField. Sólo booleanos/conteos; no valores personales ni escrituras.
- **Configuración actual de ese destino enlazado:** WhatsApp de contacto apagado/sin número; política de señas apagada. El botón público se oculta por contrato hasta cargar contacto, no por una falla de A. No se deduce que un destino enlazado sea por ello el consultorio real de Natalia, ni se inventan sus decisiones. Configuración y D/E siguen aparte.
- **Fuente del programador comparada por blobs**, `production-scheduler-source-comparison.json`:20archivos idénticos entreaac yC9 (scheduler/contrato/despacho/endpoints internos). La equivalencia no sustituye observar eventos; ya entraron calendario y reseñas naturales, ambosok/sinexcepciones, versión16c73f28. Faltan las otras dos categorías frecuentes.

### Cierre operativo A/B/C aprobado (30 de octubre, 17:04 UTC)

- **Observación natural final:** ocho eventosCF16:51:46.529→17:03:31.177UTC, calendario3/push2/reseñas2/cargas1, todosok/sinexcepciones en scheduler16c73f28. `production-scheduler-observed.jsonl` y `production-scheduler-observed-summary.json`; sólo metadatos autorizados. El programador espera y valida el recibo de la aplicación; no se lo llama aprobado por tener sólo la expresióncron. Tail terminado conSIGINT y procesos propios ausentes. No se desplegó durante la captura.
- **Límite explícito:** mantenimiento cada3h tiene su expresión activa, misma lógica fuente(20blobs iguales) y11pruebasCI, pero no tick dentro de esta ventana. Retención diariaPG: ensayo manual y rollback ya documentado, sin ejecución natural diaria atribuida. Las cuatro categorías frecuentes y la nueva expiraciónPG sí conservan evidencia natural propia.
- **Último readback productivo**, `production-state-close.json`: C9e5dd en ambosorígenes,32bindings,128/legacyoff,5cronproductivos/0staging/APP→app; conteos originales y Calendar1/1; autenticación negativa/válida y agenda en ambosorígenes después de limpieza. Cuenta configurada sólolectura; últimos ingresos anteriores16:34, por lo que la nueva lectura respetó el límite5/15min.
- **Integridad final17:04:26**, `production-core-close.json`: todas las filas de21consultorios/122pacientes/108turnos producen exactamente los tresSHA anteriores, sin exclusiones. No hubo restauración sobre producción ni se ocultó una diferencia restando la fixture.
- **Estado seguro17:04:40**, `production-features-close.json`:128/globaloff,0políticas/0señas/0horarios, dos trabajos exactosactivos; ocho ticks naturales16:25→17:00todosucceeded/0procesadas/0canceladas. Fixture productiva y dueña eliminadas, con guardias y comprobación de todas sus tablas.
- **Comprobante consolidado17:04:43.972UTC aprobado:** `cierre-productivo.json`, verificador `close-campaign.py`, sin red ni mutaciones; contrasta release20/20, estados/accionesB11/C9, ocultación, limpieza/huellas/readbackfinal, fuentes/tareas naturales y respaldo previo/posterior restaurados y recuperados independientemente. Incluye SHA256 de cada recibo; su SHA256 es **`a46d1fa83f16ba0363bb4c5e9a44c569e0b702fda353b195e8acff807d73fe39`**.
- **A/B/C quedan publicadas y verificadas en este alcance.** [Cierre por requisito](cierre-senas-avisos-natalia.md), [procedimiento](publicacion-senas-avisos-natalia.md), traspaso y arquitectura actualizados; se conserva toda la historia y no se edita el texto aprobado. Configuración deNatalia/global/señas/autocancelación apagados; D/E aparte. No se contrató, cambióDNS/landing/secretos ni usóJuan/Natalia comofixture. No se publican documentos de la clienta en el auxiliar público ni se sobreescribe main antiguo. HEAD e índice originales conservados.

### Reanudación pedida: configuración de Natalia y D/E (30 de octubre, después del cierre)

- Pedido literal «avancemos en esto» sobre la frase del pendiente de configuración yD/E. Registrado en12.12 yAGENTS; no se repite una pregunta de autorización. A/B/C mantienen su cierreC9/128 y todos sus recibos.
- Preguntas de información enviadas: cuenta/consultorio correcto, WhatsApp, datos de transferencia, Android/iPhone deNatalia/Aye y si existeResend. La información original no los contiene; no se adoptan datos de la demo ni del consultorio deJuan. Mientras llegan, se trabaja en las partes independientes.
- Fuente técnica para iniciarD: C9 `deb74b023431e4f173eed85d6651c5073ad44557`; conservar HEAD/índice originales y producción en esa revisión hasta nueva verificación completa. No hay otra publicación ni escritura de datos de negocio por esta reanudación.
- Revisión de mecanismos iniciada: D debe separar suscripciones autenticadas del personal y del paciente, comprobar membresía/rol al enviar, usar texto neutral, no introducir un sexto cron ni otra regla de disponibilidad. La instalación no debe cachear historia clínica ni respuestas autenticadas. E mantiene proveedor separado deSMTP de recuperación, cuota persistente y garantía de no duplicar correos incluso ante respuesta perdida. Son diseño/revisión en curso, no implementación ni entrega acreditadas.
- Navegador administrado sin capacidad expuesta en las herramientas actuales; navegador y compilaciones seguirán en el Playwright deCI autorizado, sin procesos pesados locales. Se aplican Supabase/Postgres, frontend-testing-debugging eImpeccable para las superficies afectadas.

### Respuesta de Juan y destino real de la configuración (30 de octubre, 17:20 UTC)

- Datos nuevos aportados: el correo que Juan indicó para la cuenta de Natalia y el WhatsApp del consultorio. Constan literalmente en la sección 6 del documento privado de la clienta (`docs/clientes/natalia-frutos/informacion-20261029.md`); se retiraron de este registro el 31 de octubre para que no contenga datos personales (ver la sección del 31 de octubre). Transferencia y teléfonos Android/iPhone no recibidos.
- **Cambio de alcance literal:** «Dejemos el correo para después». Plan12.13/AGENTS: E vuelve a posponerse; no se programó integraciónResend ni se creó cuenta ni enviócorreo. Continúan configuración confirmada yD.
- Lectura exacta `natalia-account-readonly.json`:0cuentasAuth/0membresías. Lectura complementaria `natalia-pending-readonly.json`:0accesos/0invitaciones/0consultoriosconeseemail/0profesionalesconeseemail. No se concluyó que no había consultorio sólo por el primer resultado; se contrastaron asociaciones pendientes.
- Se revisó el flujo ya publicado `create_business_with_owner`: crea acceso/manual, consultorio, invitaciónownercuandoAuthausente y acceso inicial en una sola transacción; no envía emails ni crea contraseñas. Su guardia de asociación deemail impide dos consultorios para un mismo correo. Se prepara operación acotada con ensayo revertido, lectura posterior y huellas del resto de datos. El acceso permanente se funda en la modalidad de pago único ya fijada enAGENTS; no registra un cobro ni inventa un monto abonado. La especialidad se ajusta aother, no se deja laodontología por defecto a una médica general.

### Cambio de tarea pedido por Juan (30 de octubre, 20:40 UTC)

- Juan indicó que el consultorio ya tiene12meses y que esperará el alta deNatalia; pide ver otra cuestión: confirmación obligatoria deemail yUX. Configuración deNatalia yD quedan en espera; E ya se había pospuesto.
- La operación propia anterior `natalia-setup-apply.json` terminó confirmada17:25:47: consultorio nuevo/dueña pendiente/WhatsApp, sin cambiar otras filas deconsultorios/pacientes/turnos en su transacción, sin crear cuenta ni enviar mensajes. El usuario luego dejó acceso12meses: lectura `natalia-access-at-switch.json` confirma activo/no permanente/paid_until2027-10-25. Se conserva tal cual, sin nuevas escrituras.
- No se implementó ni publicóD niE. Continuación vigente: plan/registro de confirmación deemail; no repetir el alta ni la operación de prueba revertida.

## 31 de octubre: revisión, cuenta real de Natalia, unificación de consultorios y V9

Pedidos literales y alcance en la sección 12.15 del plan. Evidencia de esta sección: `.verification/natalia-unificacion-20261031/` (carpeta privada, permiso 700; los recibos se escriben con permiso 600 y sin sobrescribir).

### Revisión previa (31 de octubre, 20:40 a 21:00 UTC, sólo lectura)

- Producción sirve V8 `408ca04d9e6750e4657dc087264644665a63fb37` en `app.cita-suite.com.ar` y en `app.cita-suite.workers.dev` (`/_app/version.json`).
- El árbol local coincide archivo por archivo con el manifiesto de V8 (`.verification/ci-source.json`, 1203 archivos): no hay diferencias de código; sólo difieren 12 documentos actualizados después y la plantilla de correo del proveedor, como declara el certificado.
- Las 13 corridas de verificación citadas en los cierres existen, terminaron bien y corresponden al SHA declarado. Las copias 41081864440, 41092046966 y 41131024848 corrieron en el repositorio privado `Juan4787/cita-suite-respaldos` y terminaron bien, igual que la copia programada del 31 de octubre a las 10:18 UTC y el control de frescura de las 15:51 UTC.
- Coinciden las huellas del comprobante de cierre (`a46d1fa8…`), de los manifiestos de las copias privadas (`5e2d2acf…`, `ef847fb3…`) y de los paquetes V8 (`91eaa5a4…`) y de recuperación `c195b1e` (`961ffbdb…`).
- El repositorio auxiliar es público. Sus 88 ramas se revisaron con árboles completos: ninguna contiene documentos de la clienta ni de estas campañas, y el correo y el teléfono privados de Natalia no aparecen en ninguno de los 193 documentos publicados ni en los 1203 archivos de V8. En el auxiliar sólo quedan los tres secretos de staging.
- Hallazgos: (1) la invitación de dueña del consultorio preparado sólo estaba protegida por la confirmación obligatoria del correo, y hubo una ventana el 30 de octubre (17:25:47 a, como máximo, 21:18 UTC) sin prueba de que estuviera activa; (2) el correo y el WhatsApp de Natalia figuraban escritos tal cual en este registro; (3) dos rótulos «Recuperación vigente» obsoletos en `docs/architecture/publicacion-y-reversion.md` y sin comando exacto para la recuperación actual; (4) la acción `confirm` de `/confirmar-correo` no registraba las fallas de Auth; (5) cientos de palabras pegadas en traspasos, registros, la sección 12 del plan y `AGENTS.md`; (6) sin observación natural de la retención diaria ni recibo del límite de envío de correos de Auth.
- Una lectura de producción de sólo lectura fue rechazada por el control de permisos («Production Reads») antes de la autorización total; no se intentó otra vía.

### Fase 1: verificación de sólo lectura (31 de octubre, 21:37 UTC)

Guion `inspeccionar.mjs` (sólo transacciones `read only`; el correo real se lee de la sección 7 del documento privado). Recibo `inspeccion-inicial.json` (permiso 600). La lectura respondió por el puerto 5432.

- **Cuenta real de Natalia:** una sola cuenta, creada el 31 de octubre a las 00:28:49 UTC y confirmada por enlace a las 00:29:03; ingreso con contraseña (proveedor `email`); último ingreso 00:31:27. Una sola membresía: dueña activa del consultorio `c488f625-cb9a-41ec-8526-b7ec03c4646b`.
- **Su consultorio «Consultorio»:** dirección automática derivada de su correo (no se escribe acá porque permite deducirlo; consta en el recibo privado `inspeccion-inicial.json`), rubro `odontology`, zona `America/Argentina/Cordoba`, reserva pública **encendida** (valor por defecto de todo consultorio nuevo), contacto público y documentos del paciente apagados, sin WhatsApp. Creación y última modificación iguales (00:31:28): ella todavía no cambió su configuración. Acceso activo hasta el 2 de noviembre de 2027 (concesiones de Juan: 12 meses a las 00:33:49 y 7 días a las 00:36:15, total 367 días). Filas propias: 1 membresía, 1 suscripción, 2 concesiones, 1 revisión de datos, 1 presupuesto de archivos clínicos y 1 versión de disponibilidad. **Sin** profesionales, prestaciones, horarios, pacientes, turnos, integraciones, historia ni archivos.
- **Consultorio preparado «Consultorio Natalia Frutos»** (`1a00afa2-92ad-46cf-bc4a-cd6b58e4e4b0`): dirección `natalia-frutos`, rubro `other`, WhatsApp de contacto encendido con el número aportado por Juan, sin miembros, una invitación de dueña pendiente (sin aceptar ni cancelar), una entrada de historia (`business.operator_contact_configured`), 5 concesiones (permanente a las 17:25:47, archivado a las 17:49:36, quitar permanente a las 17:50:26, habilitar a las 17:51:11 y extender 12 meses a las 17:51:20), sin archivos ni datos clínicos.
- **Correo aportado el 30 de octubre:** 0 cuentas (nadie reclamó la invitación durante la ventana sin confirmación obligatoria: se cierra el hallazgo 1 de la revisión), 1 invitación (la del preparado), 1 fila de correo habilitado (modo `manual`, creada a las 17:25:47 por la preparación y nunca modificada), ningún otro consultorio ni profesional con ese correo.
- **Correo real:** ninguna invitación, ninguna fila de correo habilitado, un consultorio (el suyo) y ningún profesional.
- **Web de Natalia:** la página publicada enlaza una integración activa de un **tercer** consultorio de prueba, también llamado «Consultorio» (`cdef6981-9dfb-4ae8-b862-4a61c07b299d`), con 80 turnos ficticios y ninguno futuro. Por esa integración entraron 2 reservas en total, ninguna en los últimos 14 días y ninguna futura. No es el consultorio de Natalia: conectar la web al suyo queda como pendiente (requiere configurar su turnero).
- **Tareas programadas desde el cierre del 30 de octubre (17:04:43 UTC):** 7 tareas activas y ninguna ejecución fallida. Revisión de señas 343 de 343, retención diaria del historial 1 de 1 (31 de octubre, 05:37 UTC, `DELETE 4986`: se cierra la observación pendiente del cierre), mantenimiento de exportaciones 114 de 114, integridad de archivos clínicos 5 de 5 y las tres retenciones de las 04:41 a 04:53 UTC 1 de 1 cada una. Seña global apagada, 0 políticas, 0 señas y 0 horarios liberados; 24 consultorios y 128 migraciones.
- **Dirección pública:** como la reserva pública de «Consultorio» está encendida, no se cumple la condición aprobada (reserva apagada y ninguna integración) para mudarla a `natalia-frutos`. No se cambia.

### Fase 2: el borrado del consultorio preparado está bloqueado por diseño (31 de octubre, 21:40 UTC)

- Lectura del catálogo: todas las tablas hijas del preparado se borran en cascada, pero `public.access_grants` tiene el disparador `trg_access_grants_no_delete`, que llama a `prevent_access_grants_mutation()` y rechaza **todo** borrado sin condiciones («access_grants is append-only», migración `20260528052136_business_subscriptions_access.sql`). Es la protección que mantiene una historia indeleble de los cambios de acceso.
- Ensayo deshecho `ensayar-borrado.mjs`, recibo `ensayo-borrado.json`: `delete from public.businesses` del preparado falla con `ERROR: access_grants is append-only`. No cambió nada.
- **Decisión aplicada según el plan aprobado:** la fase 2 se detiene completa. No se renombra «Consultorio» ni se le copian datos, para no dejar dos consultorios con el mismo nombre ni un estado a medias. Se propone a Juan archivar el preparado (mecanismo del sistema, reversible y con historia) en lugar de forzar el borrado desactivando la protección; ninguna de las dos se ejecuta sin su aprobación.
- **Alternativa preparada y ensayada, sin aplicar:** guion `unificar-archivando.mjs` (modos `ensayo` y `aplicar`; `aplicar` exige el ensayo aprobado y que la transacción reproduzca exactamente sus efectos). En una sola transacción, bajo bloqueo de los dos consultorios y con las precondiciones de la fase 1 repetidas:
  - consultorio preparado: archivado con `grant_business_access(..., 'archive_business', ..., 'internal', ...)`, que agrega una concesión a la historia en lugar de borrarla; invitación de dueña cancelada (`status = 'cancelled'`, no borrada); reserva pública y WhatsApp de contacto apagados; nombre «Consultorio Natalia Frutos (duplicado archivado)»;
  - fila de correo habilitado del correo anterior: borrada (la creó la preparación del 30 de octubre y nunca se modificó);
  - «Consultorio» de Natalia: nombre «Consultorio Natalia Frutos», rubro `other`, WhatsApp del preparado copiado y contacto encendido; la dirección pública no se toca porque su reserva pública está encendida;
  - historia: `business.operator_reconciled` en el de Natalia y `business.operator_archived_duplicate` en el preparado, con la sección 12.15 como fuente.
- Ensayo `unificacion-ensayo.json` (31 de octubre, 21:47:16 UTC), deshecho: 15 de 15 controles verdaderos. Efectos exactos: en el de Natalia, +1 historia y cambian `industry`, `name`, `updated_at`, `whatsapp_contact_enabled` y `whatsapp_phone`; en el preparado, +1 historia y +1 concesión, y cambian `booking_availability_revision` (por apagar la reserva pública), `name`, `public_booking_enabled`, `updated_at` y `whatsapp_contact_enabled`. Otros consultorios, pacientes y turnos: huellas idénticas antes y después dentro de la transacción. Acceso de Natalia intacto (2 de noviembre de 2027).
- Relectura independiente `despues-de-ensayos.json`: el estado de ambos consultorios, de los dos correos y de las membresías es idéntico al de `inspeccion-inicial.json`. Ningún ensayo dejó cambios.
- **Pendiente de Juan:** aprobar la alternativa de archivado (recomendada) o pedir el borrado forzado, que exigiría desactivar dentro de la transacción la protección de sólo agregado de `access_grants` y destruiría las cinco concesiones de la historia del preparado.

### Fase 4: documentación corregida hasta las 21:55 UTC

- `docs/plans/pendientes-vigentes.md` (nuevo): lista única de pendientes pedida por Juan, por responsable. Incluye la decisión sobre el consultorio preparado, el límite de envío de correos de Auth, si la web de Natalia ya es pública, la configuración de su turnero y de su seña, la conexión de su web a su consultorio real, las decisiones de la sección 4 y las preguntas de la sección 5 de su documento, D, E y Resend, Google, el nombre del proyecto de staging, los avisos por correo, los opcionales de dominio, el segundo consultorio y los límites conocidos. Enlazado desde `AGENTS.md` y `docs/README.md`.
- `AGENTS.md`: corregidas las 17 palabras pegadas que quedaban en sus apartados del 30 y 31 de octubre y dos fechas abreviadas («31-oct»); recuento hecho comparando la copia previa con la final, con 0 restantes. El título «Tarea vigente posterior» pasó a «Tarea posterior, ya cerrada». Nuevo apartado «Estado al 31 de octubre» con la usuaria real, el duplicado pendiente de decisión, dónde viven sus datos personales y la dependencia de seguridad de las invitaciones.
- `docs/architecture/publicacion-y-reversion.md`: los dos rótulos «Recuperación vigente» de las entregas del 27 y 28 de octubre ahora dicen que ya no son vigentes y remiten al primer apartado.
- `docs/architecture/confirmacion-de-correo.md`: por qué no se puede desactivar la confirmación obligatoria mientras haya invitaciones pendientes.
- `docs/plans/traspaso-senas-avisos-natalia.md`: los apartados del 30 de octubre a las 06:00 UTC («Verificado en CI», «Hecho sólo localmente», «A medio hacer» y «Siguiente») quedaron rotulados como históricos.
- Documento privado de la clienta: nueva sección 7 (cuenta real y unificación) y permiso 600.
- No se corrigieron en masa las palabras pegadas de los registros históricos ni de la sección 12 del plan: son historia, y una edición masiva puede alterar identificadores. Decisión registrada también en la lista de pendientes, en «Límites conocidos».

### Estado al cerrar la sesión del 31 de octubre (22:01 UTC)

- **Hecho:** revisión completa; verificación de sólo lectura de producción; datos personales retirados del registro; V9 publicada y comprobada (detalle en `registro-confirmacion-email-20261030.md`); documentación corregida; lista única de pendientes en `docs/plans/pendientes-vigentes.md`.
- **No hecho, por la regla aprobada:** la unificación de los consultorios. La base prohíbe borrar el preparado. El archivado está ensayado y espera la decisión de Juan. Los dos consultorios siguen exactamente como estaban a las 21:37 UTC (relectura `despues-de-ensayos.json`).
- **Para continuar con la aprobación:** desde la raíz, `node .verification/natalia-unificacion-20261031/unificar-archivando.mjs aplicar`. El guion exige el ensayo aprobado y que los efectos sean idénticos a los ensayados; si no, deshace todo. Después, `node .verification/natalia-unificacion-20261031/inspeccionar.mjs inspeccion-final` y registrar el resultado acá, en el traspaso, en la sección 7 del documento privado y en la lista de pendientes. Si pasa mucho tiempo y Natalia cambia su consultorio (por ejemplo su nombre), la precondición `NATALIA_BUSINESS_CHANGED` lo detiene sin cambios: en ese caso hay que repetir la fase 1 y ajustar el guion a lo que ella ya decidió.

## 1 de noviembre: duplicado archivado, configuración de Natalia, su web y vista de archivados

Autorización y decisiones literales de Juan: plan, sección 12.16. Evidencia: `.verification/natalia-configuracion-20261101/` (carpeta 700, recibos 600, ninguno se sobrescribe). Las horas son UTC; en Argentina son tres horas menos.

### Fase 0: decisiones registradas (01:41 a 01:45)

Plan 12.16 agregado al final del plan, sin datos personales (la dirección automática del consultorio real se omite porque deja ver el correo). El traspaso tiene un bloque «Trabajo en curso — 1 de noviembre» con las fases y el punto exacto. El ensayo del 31 de octubre (`natalia-unificacion-20261031/unificar-archivando.mjs`) no se aplica: corresponde a un estado anterior y a una decisión reemplazada.

### Fase 1: lectura de producción, sólo lectura (01:44 a 01:50)

- `leer-esquema.mjs` → `esquema.json` (01:44:38): columnas, restricciones, índices, disparadores y funciones de las tablas involucradas. 128 migraciones, la última `20261030010000`.
- `inspeccionar.mjs inicial` → `inicial.json` (01:49:55), copia de la inspección del 31 de octubre con rutas y nombres nuevos:
  - **Duplicado:** Juan lo archivó desde el panel el 1 de noviembre a las 00:49:27 (sexta concesión, `archive_business`). Conservaba nombre, dirección `natalia-frutos`, reserva pública y WhatsApp encendidos, el teléfono, la invitación de dueña pendiente y el correo habilitado.
  - **Consultorio real:** sin cambios desde su alta (31 de octubre, 00:31:28): «Consultorio», «odontología», nada cargado. Natalia entró una sola vez, al registrarse.
  - La web sigue en el consultorio de prueba. Las siete tareas programadas no tienen fallas. Señas apagadas: interruptor general, 0 políticas, 0 señas, 0 huecos.
- `inspeccionar-modelo.mjs inicial` → `modelo-inicial.json` (01:50:10): la configuración que usa hoy la web en el consultorio de prueba, que sirve como modelo ya probado. Tiene tema `natalia`, sólo presencial, sin franjas, sin preguntas de integración y la obra social como texto libre en el formulario del profesional. El consultorio real no tiene integraciones.
- **Direcciones IP de Auth:** `auth.audit_log_entries` no tiene ningún evento en 30 días; este proyecto no guarda la auditoría de Auth en la base. No se puede saber desde ahí si Supabase aplica sus límites «por IP» a la dirección de Cloudflare. Queda como pendiente: mirarlo en Supabase → Logs → Auth.

### Hallazgos de la fase 1 que el análisis del 29 de octubre no había visto

1. **Una pregunta de opciones admite como máximo 20.** Lo exigen `parseBookingIntakeFields` (`packages/shared/src/booking-integration.ts`) y `private.booking_intake_schema_valid` en la base, y de esta última dependen las restricciones de `booking_integrations.intake_schema` y `professional_booking_forms.fields`. La obra social de Natalia necesita 24 opciones: sus 22 obras sociales, «Particular» y «Otra obra social». Aun uniendo las dos últimas serían 23. La paciente las ve en una lista desplegable (`PublicBookingIntakeField.svelte`), que funciona bien con 24 en el celular.
2. **El rubro está restringido en la base** (`businesses_industry_check`). Además, V9 rechaza un rubro que no conoce: `parseBusiness` lanza `InvalidDataContractError('business.industry')` (`apps/web/src/lib/server/access/public/business.ts`, línea 91). Con «medicina» cargado, volver a V9 rompería la app de Natalia.
3. **Las modalidades y sus franjas viven en la integración de reservas.** Una modalidad con alguna franja queda limitada a sus franjas todos los días, y un día sin franjas de esa modalidad no ofrece horarios en ella. Así lo hacen el calculador (`calculate.ts`, líneas 383 a 392) y la validación de la base al reservar (`BOOKING_MODALITY_UNAVAILABLE`).
4. **Habilitar la consulta online exige un texto de instrucciones** (`booking_integrations_check1`). Natalia no lo mandó.
5. **El enlace directo `/reservar/<dirección>` usa la integración predeterminada del consultorio** (`loadDefaultBookingIntegration`). Sin ella, ese enlace ofrecería el miércoles a las 16:30 sin modalidad, es decir, presencial, aunque Natalia lo reserva exclusivamente para online.
6. **El descanso de una regla se suma al final de cada turno.** El valor por omisión de la tabla es 15 minutos, y con él una consulta de 08:00 a 09:00 bloquearía el inicio de las 09:00.
7. **La app exige la dirección del consultorio para guardar sus datos con la reserva pública encendida** (`configuracion/negocio/+page.server.ts`). Natalia no la mandó. Su reserva pública quedó encendida por el alta y no se apaga, porque la integración la necesita; pero si ella edita los datos del consultorio, la app le va a pedir la dirección. Además, los comprobantes de los turnos presenciales no la tendrán hasta cargarla.

### Decisiones propias del agente y sus fundamentos

1. **Carga escribiendo directamente en las tablas, replicando cada función de guardado de la app**, con historia de operador atribuida al maestro.
   - Las funciones de guardado autorizan por `user_can_manage_business` (dueña, administradora o ayuda vigente) y anotan `auth.uid()` en la historia.
   - Usar la identidad de Natalia dejaría escrito que ella hizo la carga. Crear una ayuda en su nombre fabricaría un consentimiento que ella no dio.
   - Sumar temporalmente al maestro como administrador lo impide `assert_email_available_for_business` (un correo no puede quedar asociado a dos consultorios), y no corresponde saltear esa protección.
   - Las restricciones y disparadores de la base siguen aplicándose a cada escritura, y el resultado se comprueba con las lecturas públicas de la app.
2. **Correo habilitado deshabilitado, no borrado** (reemplaza lo previsto en 12.15). Es lo que hace `cancel_business_role_invite` cuando se cancela la última invitación de un correo sin cuenta: `enabled = false` con el motivo «Sin roles activos o pendientes.». El alta abierta vigente (`ensure_user_default_business`, migración `20260707165923`) ya no consulta esa tabla, así que no le impide a nadie registrarse.
3. **El duplicado queda sin el correo y sin el teléfono de Natalia.** Un consultorio archivado no los necesita, y así no quedan copias de sus datos personales en una fila sin uso. La historia registra que se borraron, no sus valores.
4. **Sin las prestaciones genéricas «Consulta» y «Otro servicio» de 30 minutos.** La app las crea al dar de alta un perfil profesional (`assign_team_default_services`), pero funciona sin ellas: `defaultServiceIds` sale de las que existen (`professional-editor.ts`, línea 511). En el consultorio de Natalia ofrecerían turnos de 30 minutos que rompen su grilla de 60. Si más adelante se agrega otra profesional, la app las va a crear; conviene saberlo.
5. **Reglas con paso de 60 minutos y descanso 0**, por el hallazgo 6. Dos franjas por día dan exactamente los inicios que pidió Natalia.
6. **La integración de su web es la predeterminada del consultorio,** por el hallazgo 5. Así el enlace directo y la web aplican las mismas modalidades y la misma pregunta.
7. **Franjas de modalidad:** presencial todos los días de 00:00 a 23:59, salvo el miércoles, que queda de 00:00 a 16:30 y de 17:30 a 23:59; online sólo el miércoles de 16:30 a 17:30. Por el hallazgo 3, limitar la presencialidad a los horarios exactos dejaría sin reservar la disponibilidad extra que Natalia habilite un viernes. Así, el único cambio respecto de «todo presencial» es que el miércoles 16:30 sea sólo online. Lunes, martes y jueves quedan sólo presenciales, que es lo provisorio que aprobó Juan.
8. **Instrucciones provisorias de la consulta online**, por el hallazgo 4: «Antes del turno, el consultorio te va a indicar cómo conectarte a la consulta online.» No promete una plataforma ni un canal. Sin texto no se puede ofrecer el miércoles 16:30. Natalia tiene que confirmarlo o reemplazarlo antes de la entrega.
9. **Límite de opciones de 20 a 40**, en el código compartido y en la base, por el hallazgo 1. Cuarenta cubre a un consultorio que trabaje con muchas obras sociales. El tamaño sigue acotado por los 16.384 bytes del formulario y los 120 caracteres por opción, y la lista desplegable no cambia.
10. **El rubro «medicina» se asigna recién con V10 publicada,** por el hallazgo 2. Antes de volver a V9 hay que devolverle a Natalia el rubro «otro» y dejar su pregunta de obra social en 20 opciones o menos, porque V9 tampoco lee una pregunta con más. La recuperación queda escrita con ese paso previo.
11. **No se toca la función de alta (`ensure_user_default_business`) para agregar el rubro.** La app siempre la llama con «odontología» (`business.ts`, línea 341). Agregar un valor que nadie usa a una función crítica de alta e invitaciones agrega riesgo sin beneficio. La dueña cambia el rubro en Configuración → Negocio, que usa la lista de la app y la restricción de la base.

### Fase 2: unificación aplicada (01:55 a 01:56)

- `unificar.mjs ensayo` → `unificacion-ensayo.json` (01:55:52): 16 de 16 controles, deshecho.
- `unificar.mjs aplicar` → `unificacion-aplicar.json` (01:56:09 a 01:56:10): mismos efectos, confirmado.
- **Duplicado (`1a00afa2-92ad-46cf-bc4a-cd6b58e4e4b0`):**
  - se llama «Duplicado archivado — no usar» y su dirección es `duplicado-archivado`;
  - quedan apagados la reserva pública y el WhatsApp, y vacíos el correo y el teléfono;
  - la invitación de dueña quedó cancelada por el maestro y el correo habilitado, deshabilitado;
  - sigue archivado con la fecha y la hora en que lo archivó Juan;
  - suma una entrada de historia, `business.operator_archived_duplicate`.
- **Consultorio real (`c488f625-cb9a-41ec-8526-b7ec03c4646b`):**
  - se llama «Consultorio Natalia Frutos», su dirección es `natalia-frutos` y tiene el WhatsApp del consultorio con el contacto encendido;
  - el rubro todavía es «odontología»;
  - suma una entrada de historia, `business.operator_reconciled`.
- **Sin cambios:** los otros 22 consultorios, las otras invitaciones, los otros correos habilitados, las 38 membresías, las 24 suscripciones, los 122 pacientes y los 108 turnos (huellas idénticas antes y después). La membresía y el acceso de Natalia, hasta el 2 de noviembre de 2027, también siguen iguales.
- **Relectura independiente:** `inspeccionar.mjs despues-de-unificar` (01:56) confirma lo anterior. Su bloque «correo anterior» ya no aplica, porque se calcula desde el correo del duplicado, que ahora está vacío. Los controles de la transacción (`invitesPending`, `allowedEmailDisabled`) son la evidencia de ese punto.
- **Direcciones públicas:** `comprobar-direcciones.mjs despues-de-unificar` (01:56:30) y una lectura posterior siguiendo la redirección:
  - `/reservar/natalia-frutos` redirige al identificador del consultorio de Natalia y muestra «Consultorio Natalia Frutos» con «No hay servicios disponibles para reservar online en este momento»;
  - `/reservar/duplicado-archivado` muestra «La reserva online no está disponible en este momento»;
  - la dirección automática anterior responde «El enlace de reserva no está disponible».

### Fase 3a: configuración de Natalia cargada (02:00)

- `cargar-configuracion.mjs ensayo` → `configuracion-ensayo.json` (02:00:34): 12 de 12 controles, deshecho.
- `cargar-configuracion.mjs aplicar` → `configuracion-aplicar.json` (02:00:49 a 02:00:50): mismos efectos, confirmado.
- **Creado en el consultorio real:**
  - perfil profesional `b84d9890-44ab-4bbf-a8f2-607704999bc8`, «Dra. Natalia Frutos», «Médica general y de familia», público y vinculado a la cuenta de Natalia;
  - prestaciones de 60 minutos sin márgenes ni precio: «Primera consulta» (`6e7e1265-c301-4716-a4fa-131e9965c2ad`) y «Consulta de seguimiento» (`f315cfee-3f3a-408d-ac92-382f7f5daf44`). Las descripciones son las de Natalia, y las indicaciones de documentación por tipo de orden tienen 749 caracteres (texto en el programa);
  - ocho reglas de horario con paso de 60 minutos y descanso 0;
  - integración `a527e8c4-63b9-4d56-9567-7eec7f58448c`, predeterminada y activa, con la clave pública `aa46a991730483b855ae11445c95b9bf`. Tiene tema `natalia`, el origen `https://natalia-frutos.vercel.app`, presencial y online, las nueve franjas de la decisión 7 y las instrucciones provisorias de la decisión 8;
  - una entrada de historia, `business.operator_configuration_loaded`, con lo creado, lo diferido (pregunta de obra social y rubro, después de V10) y lo que no se cargó por falta de datos (dirección, precios, seña y política de cancelación).
- **Sin cambios:** todos los demás consultorios, profesionales, prestaciones, reglas e integraciones, las membresías, las suscripciones, los pacientes y los turnos (huellas idénticas). Del consultorio sólo cambió su número de revisión de agenda.
- **Comprobación como paciente:** `comprobar-turnero.mjs despues-de-cargar 2026-11-09` → `turnero-despues-de-cargar.json`, 24 de 24. Recorre el enlace directo del dominio oficial, sin sesión, durante la semana del 9 al 15 de noviembre, con la prestación «Primera consulta» todos los días y también con «Consulta de seguimiento» el lunes y el miércoles:
  - **presencial:** lunes y martes 08:00, 09:00, 10:30 y 11:30; miércoles 13:00, 14:00 y 15:00; jueves 14:00, 15:00, 16:30 y 17:30; viernes, sábado y domingo, nada;
  - **online:** sólo el miércoles a las 16:30;
  - la página ofrece las dos modalidades. La lista de días que devuelve es su primera tanda (8 días en presencial y 2 en online) y en las dos sólo aparecen días permitidos.

### Fase 4: candidata V10 (02:30 a ...)

**Código** (23 archivos, lista en `archivos-v10.txt`; todos eran idénticos a V9 antes de editarse, comprobado por hash con `git hash-object` contra el árbol de V9; `git diff <revisión>` no sirve para eso porque el índice local es anterior y no registra muchos archivos):

1. **Vista de archivados del panel maestro.**
   - La lógica del directorio pasó de la página a `apps/web/src/lib/access/master-directory.ts`, una función pura con pruebas propias.
   - «Archivado» se pregunta antes que «pausado» en la etiqueta, el tono, el resumen y el detalle. El tono es neutral, el color de acento, porque no es una alarma.
   - Los archivados salen de Todos, En orden y Revisar, de sus contadores, del resumen de arriba y del buscador. Tienen su propia vista, que se abre con «Ver consultorios archivados» y se cierra con «Volver a consultorios», con buscador propio. Cada uno conserva «Gestionar» para reactivarlo.
   - Se corrigió de paso un texto que ya estaba mal: con un solo resultado decía «1 resultados».
2. **Rubro «medicina»:** en `BUSINESS_INDUSTRIES`, la etiqueta «Medicina» en Configuración → Negocio y la migración `20261101010000_business_industry_medicine.sql`, que reemplaza la restricción de la base. No cambia el rubro de ningún consultorio.
3. **Preguntas de hasta 40 opciones:** la constante `BOOKING_CHOICE_OPTIONS_MAX` en el código compartido y la migración `20261101020000_booking_choice_options_limit.sql`. Esta última reemplaza `private.booking_intake_schema_valid` con su texto idéntico salvo el límite; la comparación con `diff` muestra una sola línea distinta.
4. **Web de Natalia:**
   - lleva a `https://app.cita-suite.com.ar` con la clave de su consultorio real (`scripts/lib/production-deploy.mjs`);
   - `src/lib/site-config.ts` y el diseño común ponen, según `PUBLIC_NATALIA_SITE_URL`, «noindex» o la dirección canónica en cada página;
   - `scripts/write-discovery.mjs` escribe `robots.txt` siempre, y el mapa del sitio sólo cuando hay dominio;
   - `check-public.mjs` prueba que todo sea coherente;
   - `nataliaSite` (`scripts/lib/staging-deploy.mjs`) exige la misma regla al armar, publicar y verificar.

   **Decisión propia 12, la dirección provisoria no se indexa:** Natalia indexará su web cuando tenga dominio propio (Juan, 12.16). Indexar ahora `natalia-frutos.vercel.app` dejaría en Google una dirección que después habría que redirigir. Hasta la entrega, además, una reserva real no la vería nadie. Cuando exista el dominio, se carga en `PRODUCTION_NATALIA_SITE_URL` y la misma compilación produce las direcciones canónicas, el mapa y la línea `Sitemap:`.

**Pruebas que fallan primero y después pasan** (recibos `roja-*` y `verde-*`):
- 24 opciones: falla con `BOOKING_INTAKE_SCHEMA_INVALID` y después pasa (37 de 37 en su archivo).
- «medicina»: una primera versión de la prueba del rubro desconocido falló por estar mal escrita (comparaba el mensaje, que es genérico, en lugar de `contract`). Se corrigió la prueba, no el código, y después falló sólo la de «medicina» (26 de 26 con el arreglo).
- Directorio: con la lógica vieja copiada tal cual fallaron exactamente las dos pruebas de archivados («Pausado» en lugar de «Archivado», y los archivados listados entre todos), y pasaron las de los demás estados y la búsqueda. Con el arreglo, 4 de 4.
- SQL: la candidata roja `3b499f50e6e61858e380c3a3ecf9a9d6501c3fc4` (V9 más sólo `supabase/tests/natalia_configuration_support.sql`) falló en CI, corrida [41265242090](https://github.com/Juan4787/cita-suite-verificacion/actions/runs/41265242090), con `businesses_industry_check` al crear un consultorio de rubro «medicine». La falla corta ahí, así que la parte de las 40 opciones en la base no llegó a ejecutarse en rojo; la protege la prueba unitaria roja equivalente y la comparación línea a línea de la función. Registro en `sql-roja-41265242090.log`.
- Sitio: armado local en los dos modos. Sin dominio: 14 páginas con «noindex», `robots.txt` sin mapa y sin `sitemap.xml`. Con un dominio de ejemplo: dirección canónica en las 14 páginas, mapa con 13 (todas menos la redirección `/turnos/`) y la línea `Sitemap:`. En los dos, `check-build` confirma que el botón y la redirección de turnos llevan a `https://app.cita-suite.com.ar/embed/v1/aa46a991730483b855ae11445c95b9bf`.

**Mutaciones** (`mutaciones.py`; cada una rompe una línea, corre su prueba y restaura el archivo byte a byte, con sumas SHA-256 comprobadas al final):
- primera serie, `mutaciones-1-con-sobreviviente.json`: 11 de 12 detectadas. Sobrevivió «dirección canónica exacta»: si el validador aceptara cualquier dirección canónica, la prueba no lo notaba, porque el caso que la cubría fallaba antes por `robots.txt`;
- se agregaron dos casos que aíslan la dirección canónica: dominio equivocado con `robots.txt` correcto, y todas las páginas apuntando a la portada;
- segunda serie, `mutaciones-2-completa.json`: 12 de 12 detectadas.

**Candidatas,** armadas con índice temporal, sin tocar el HEAD (`80268e2`) ni el índice local (comprobado antes y después):
- roja `3b499f50e6e61858e380c3a3ecf9a9d6501c3fc4`, rama `verify/natalia-v10-roja-20261101`;
- V10 `4f1769e9cbdd257315b8bcbc809180b4a2beba21`, rama `verify/natalia-v10-20261101`, 23 archivos (778 líneas agregadas y 114 quitadas).

**Cola de CI:** el grupo `cita-refactoring-verification` conserva una sola corrida pendiente y cancela la anterior. Por eso `fast` 41265251097 y el paquete 41265260137, lanzados seguidos, quedaron cancelados sin correr. `cola-ci.sh` lanza cada corrida recién cuando empezó la anterior, y la de navegador cuando termina el paquete; registro en `cola-ci.log`.

**Primeras corridas de V10 y dos fallas que no eran del producto:**
- `sql` de V10 `4f1769e` (corrida 41265268422, 02:29 a 02:31): la prueba nueva pasó («ok 1 - The medicine industry and insurance lists of up to 40 options…»). Falló `price_confirmation_lifecycle.sql`, una prueba anterior a V10, con `PRICE_CONFIGURATION_INVALID`.
  - **Causa:** la prueba toma el mes base en UTC (`date_trunc('month', now())`) para un consultorio de Buenos Aires. `save_service_price_policy` rechaza, con razón, un mes base posterior al mes local del consultorio.
  - Desde las 00:00 UTC del 1 de noviembre (21:00 del 31 de octubre en Argentina) la prueba pedía noviembre cuando allá todavía era octubre. Es un defecto de la prueba, no de la función, y hacía fallar CI las tres últimas horas de cada mes.
  - **Corrección:** el mes del consultorio, `date_trunc('month', now() at time zone 'America/Argentina/Buenos_Aires')`, con un comentario que explica por qué.
- `fast` de V10 `4f1769e` (corrida 41265400087, 02:29 a 02:32): falló `scripts/lib/staging-environment.test.mjs`. Su paquete de ejemplo tenía un sitio de Natalia sin `robots.txt` ni «noindex», y el validador nuevo lo rechaza, como corresponde.
  - **Corrección:** el ejemplo ahora es un sitio como el que arma la compilación.
  - **Falla de método:** antes de subir sólo había corrido la prueba del archivo que modifiqué, y no toda la serie de pruebas de los programas. Ahora corrí la serie completa localmente: 171 de 171. También pasaron `svelte-check` (1431 archivos, 0 errores), los tipos de las pruebas de navegador y `astro check` del sitio.
- **V10b** `68f31741f6ff7f2253c036800b1369f1eda16510`, rama `verify/natalia-v10b-20261101`: V10 más esas dos correcciones (25 archivos, `archivos-v10b.txt`). Reemplaza a V10 como candidata. Su `sql` se lanzó a las 02:35 UTC, dentro de la misma ventana en que la prueba vieja fallaba, así que su resultado prueba la corrección. La cola sigue en `cola-ci-candidata.sh` (registro `cola-ci-natalia-v10b-20261101.log`).

**`sql` de V10b aprobada** (corrida [41265804819](https://github.com/Juan4787/cita-suite-verificacion/actions/runs/41265804819), 02:35 a 02:37 UTC):
- todas las pruebas SQL pasan (583 resultados «ok», ninguno «not ok»), incluidas `natalia_configuration_support.sql` y `price_confirmation_lifecycle.sql` corregida;
- la corrección de esta última queda probada dentro de la misma ventana del cambio de mes en que la versión vieja había fallado seis minutos antes (corrida 41265268422).

Registro en `sql-v10b-41265804819.log`.

### Migraciones de V10 en staging y en producción (02:38 a 02:41 UTC)

1. **Staging:** `apply-staging-migrations.mjs`, de 128 a 130, a las 02:38:45.
2. **Ensayo en producción:** `rehearse-production-migrations.mjs` (`ensayo-migraciones-produccion.json`). Dos pendientes, cero fallas y cero diferencias de catálogo con staging en tablas, columnas, restricciones, índices, disparadores, políticas, RLS y cuerpos de funciones. La transacción se deshizo.
3. **Copia privada de producción:** `backup-production.mjs` en `~/.local/share/cita-suite/backups/production-2026-11-01T02-39-07-585Z`, creada a las 02:40:32. Tiene 110 tablas, 4.391 filas, 128 migraciones y 24 archivos guardados, sin fallas (`copia-produccion.log`).
4. **Aplicación:** `apply-production-migrations.mjs` con esa copia (`aplicar-migraciones-produccion.log`). De 128 a 130 a las 02:40:51, en 0,9 segundos y en una sola transacción.
5. **Lectura posterior** (`migraciones-leidas.json`):
   - `businesses_industry_check` incluye «medicine»;
   - `booking_intake_schema_valid` tiene el límite de 40 y ya no el de 20;
   - ningún consultorio usa todavía «medicina», así que V9, que sigue publicada, no se ve afectada.

**`fast` de V10b aprobada** (corrida [41265937843](https://github.com/Juan4787/cita-suite-verificacion/actions/runs/41265937843), `fast-v10b-41265937843.log`):
- tipos de la app: `svelte-check`, 0 errores y 0 advertencias;
- tipos del sitio de Natalia;
- pruebas de los programas: 171 de 171;
- programador: 11 de 11;
- servidor: 1611 de 1611, en 206 archivos;
- cliente: 253 de 253, en 33 archivos.

Son 7 pruebas unitarias más que V9 (1864 contra 1857): las 7 nuevas de V10.

**Paquete de V10b aprobado:** corrida [41266013495](https://github.com/Juan4787/cita-suite-verificacion/actions/runs/41266013495), bajado sin cambios a `release-candidate-v10b/` (228 archivos, manifiesto SHA-256 `e3c6e647f33fd8bd19a78964444a1e10fabea365a3c433b1a2c893b140a1f574`). Verificado con `loadBuildArtifact` y `nataliaSite`:
- revisión `68f31741f6ff7f2253c036800b1369f1eda16510`;
- sitio de Natalia de 36 archivos (los 35 de antes más `robots.txt`), sin mapa del sitio y con «noindex»;
- lleva a `https://app.cita-suite.com.ar` con la clave `aa46a991730483b855ae11445c95b9bf`.

**Datos del proyecto de Vercel releídos** (`vercel-natalia-proyecto.json`, 02:42 UTC, con la herramienta oficial 50.13.2 y su sesión interna, filtrados a identidad, configuración, Git y despliegue):
- proyecto `prj_ddhAhez9VNro373XWSykLkhU5vBS`, vinculado a `juan-altamira/web-natalia`, rama `main`;
- sin compilación ni marco;
- producción en `dpl_6zBnr7E2FVg11SQ5mHiHv8rdPPKk`, el despliegue del 24 de octubre;
- la rama `main` del repositorio sigue en `e3530eda43fd6ddc82b093a166eb49f83bf7815a`.

**Navegador sobre el paquete de V10b, primera corrida** ([41266282159](https://github.com/Juan4787/cita-suite-verificacion/actions/runs/41266282159), 02:42 a 02:46 UTC): 3 de 7.
- **Pasaron:** la prueba nueva del panel maestro («a practice archived from the panel leaves the directory and its search and lives in its own view»), la de ayuda (que recorre el panel maestro y los datos del consultorio) y una de reservas.
- **Fallaron:** cuatro de `booking-embed.spec.ts`. Evidencia reconstruida con `collect-verification-evidence.py` en `navegador-v10b-41266282159-evidence/` (73 archivos, SHA-256 `9d79d167fc230b9f839359af25fd929cd059bc4520306366a1c9e05f12cfd4fc`). La página de reserva del consultorio de prueba decía «La reserva online no está disponible en este momento».
- **Causa demostrada, y es otra vez la ventana del cambio de mes:** el armado de CI (`scripts/serve-booking-fixture.mjs`, y lo mismo `scripts/staging-release-fixture.mjs`) carga el precio con mes base en UTC. A las 02:44 UTC ya era noviembre en UTC, pero en Buenos Aires, la zona de ese consultorio, todavía era 31 de octubre. `private.resolve_service_price` calcula el precio de hoy con la fecha local y `private.calculate_policy_monthly_amount` rechaza una fecha anterior al mes base (`PRICE_DATE_INVALID`). La cotización falla y la página se cierra.
- **La app no tiene ese defecto:** el editor de precios propone el mes con la zona del consultorio (`monthForTimezone`, `professional-editor.ts`, línea 480) y la base rechaza un mes base futuro.
- **Corrección:** los dos programas de armado usan ahora el mes de Buenos Aires. Quedan en el árbol de trabajo para la próxima candidata (`archivos-proxima-version.txt`); no cambian nada de lo que se publica. V10b no se rearma por esto.
- **Comprobación:** pasadas las 03:00 UTC, fuera de la ventana, se repite la misma prueba de navegador sobre el mismo paquete de V10b.

**Navegador sobre el paquete de V10b, repetición fuera de la ventana:** corrida [41267444767](https://github.com/Juan4787/cita-suite-verificacion/actions/runs/41267444767), lanzada a las 03:00:58 UTC sobre el mismo paquete 41266013495: **7 de 7** en 41,4 segundos.
- Pasaron las cuatro pruebas de reservas que habían fallado a las 02:44, la del panel maestro y la de ayuda.
- Queda demostrado que la falla anterior era de la ventana del cambio de mes en el armado de CI, no de V10b.
- Evidencia: `navegador-v10b-41267444767-evidence/`, 103 archivos, SHA-256 `4e279c2c98ddb3cebf6caa9f6c9a5d66a4ca2fdf3aa0f32e54028f7231a038ca`. El registro sin colores está en `navegador-v10b-41267444767-limpio.log`.

### Fase 5: V10b publicada (10:15 UTC) y fase 3b aplicada (10:16 UTC)

- **Relectura antes de publicar** (`antes-de-publicar-v10b.json`, 10:14):
  - producción servía V9 en los dos orígenes;
  - el consultorio de Natalia estaba idéntico al de las 02:00, sin pacientes ni turnos, y ella no había vuelto a entrar;
  - el duplicado no había cambiado;
  - ninguna tarea programada había fallado, había 130 migraciones y la seña seguía apagada.
- **Publicación:** `deploy-production-workers.mjs app release-candidate-v10b` (`despliegue-v10b.log`). Revisión `68f31741f6ff7f2253c036800b1369f1eda16510`, versión de Cloudflare **`1d2b4acd-7dd8-4cb7-81e3-a205bafe9f8d`**, sin compilar nada localmente. Los despliegues anteriores quedaron registrados en `despliegues-antes-v10b.txt`.
- **Comprobaciones posteriores, todas aprobadas:**
  - los dos orígenes sirven V10b;
  - `verify-production-release.mjs`: 139 archivos del cliente idénticos al paquete, política de seguridad del contenido y HTTPS correctos, y 0 de 74 relaciones expuestas sin sesión (recibo `.verification/production-release-2026-11-01T10-15-34-831Z.json`);
  - `comprobar-publicacion.mjs` (copia de la de V9, `comprobacion-publicacion-68f31741.json`): `/confirmar-correo` y `/login` responden 200 en los dos orígenes, un enlace inválido recibe la respuesta neutra 410 y uno mal formado, 400;
  - `comprobar-turnero.mjs despues-de-v10b 2026-11-09`: 24 de 24.
- **Fase 3b:** `completar-configuracion.mjs` (ensayo y aplicación, recibos `completar-*.json`):
  - el consultorio de Natalia pasó a rubro «medicina»;
  - su perfil profesional tiene el formulario con la pregunta obligatoria «Obra social» (`q_0b93475301594789187de33ba8b08c77`), destinada a la obra social de la ficha. Tiene 24 opciones: «Particular», las 22 en orden alfabético y «Otra obra social»;
  - la pregunta lleva la ayuda fija del token: «Si tu obra social es AMUR, Avalian, OSPAC, Sancor o Swiss Medical, requiere token: deberás enviarlo al momento de la consulta.»;
  - la lectura pública (`patient_booking_schema`) devuelve la pregunta como `profile_insurance` con sus 24 opciones;
  - historia: `business.operator_configuration_completed`.
- **Ensayo de la vuelta a V9** (`revertir-para-v9.mjs ensayo`, deshecho): alcanza sólo al consultorio de Natalia y a su formulario, y deja los cuatro controles en verdadero (sin «medicina», sin preguntas anchas y formularios válidos). Si hiciera falta volver a V9, es el primer paso.
- **Fuente publicada certificada** (`certify-source-v10b.mjs` y `ci-source-v10b.json`): árbol `01f68d8c51ae3c6f0d9e9948a825102a6b00d576`, 1211 archivos, 1148 del código idénticos byte a byte a los locales.
  - Excepción explícita: los dos programas de armado corregidos para la próxima candidata, con su hash en la candidata y en local.
  - El puntero `.verification/ci-source.json` pasó a V10b, y el de V9 quedó en `ci-source-before-production-v10b-20261101.json` (`puntero-fuente-v10b.json`).

### Fase 5, segunda parte: web de Natalia publicada (10:18 UTC)

- **Preparación:** `prepare-natalia-publication.mjs` con el paquete de V10b, los datos de Vercel releídos y la rama `main` en `e3530eda43fd6ddc82b093a166eb49f83bf7815a`. Resultado en `.verification/natalia-publication-68f3174/`: 36 archivos del sitio y `vercel.json` idéntico al vigente (sin compilación y con salida `site`).
- **Publicación:** `publicar-web.mjs` (recibo `publicacion-web.json`) con la cuenta dueña del repositorio, `juan-altamira`, activada sólo durante la operación; la cuenta activa volvió a `Juan4787` al terminar.
  - Commit `8ac6dfee28121e6f5abc7bf4e9d5608e68ab0d0a`, de avance simple desde `e3530ed`, sin forzar y sólo si `main` seguía en el commit esperado.
  - `site/` es un árbol nuevo (`03fa9fdfeb06457d9ef48297f8052bc1dff3efe4`) con exactamente los 36 archivos.
  - `rollback/` pasó a ser el sitio que se servía hasta ese momento (árbol `7c6a0874eb950ed8eefc000485af53738542ef83`).
  - El resto del repositorio, sin cambios.
- **Vercel:** desplegó solo y sirvió `robots.txt` a las 10:18:40. Despliegue de producción **`dpl_2Xtgk4uEqhRumxb4t3Fc4dqdR6sU`**, listo y desde ese commit; el anterior, `dpl_6zBnr7E2FVg11SQ5mHiHv8rdPPKk`, es la vuelta atrás inmediata (`vercel-natalia-despues.json`).
- **Comprobación:** `verify-production-release.mjs release-candidate-v10b --natalia` (`verificacion-web-natalia.log`). Los 36 archivos servidos en `natalia-frutos.vercel.app` son idénticos al paquete; además, 139 archivos del cliente de la app y nada expuesto.

### Fase 6: pruebas marcadas en el consultorio real y limpieza (10:21 a 10:31 UTC)

- **Foto previa,** sólo lectura: `antes-de-pruebas.json` (10:21), con el conteo de filas de cada tabla del consultorio.
- **Método:** `reservar-prueba.mjs`, con un navegador real (Chromium sin ventana de Playwright 1.60, local, de a una página) en tamaño de celular (390 × 844) y la zona horaria de Córdoba. Recorre como paciente desde `https://natalia-frutos.vercel.app/` hasta la página del turno, con una captura por paso en `prueba-<etiqueta>/`.
  - Hubo cinco intentos fallidos por errores de la prueba, no de la app, conservados con su nombre:
    - el primer botón de reserva está en el encabezado, oculto en el celular;
    - existe el paso «¿Con quién?»;
    - entrar con la fecha en la dirección pierde a la profesional elegida;
    - las etiquetas de los días usan espacios no separables, así que el día se elige por su fecha exacta;
    - la obra social es un desplegable propio de la app.
  - Ninguno de esos intentos llegó a reservar, salvo el último presencial, que reservó y del que sólo faltó reconocer la página final.
- **Presencial** (`prueba-presencial-reservada/`): «Primera consulta», lunes 9 de noviembre a las 08:00, obra social OSPAC.
  - La web mostraba «noindex».
  - Su botón llevó a `app.cita-suite.com.ar/embed/v1/aa46a991730483b855ae11445c95b9bf`, con el título «Reservar turno · Consultorio Natalia Frutos», las modalidades «Presencial» y «Virtual» y el diseño de la web de Natalia.
  - «¿Con quién?» mostró «Dra. Natalia Frutos — Médica general y de familia».
  - Horarios del lunes 9: 08:00, 09:00, 10:30 y 11:30.
  - La pregunta «Obra social» mostró «Elegí una opción» y las 24 opciones en el orden previsto, con la ayuda del token.
  - Página del turno: «Tu turno quedó reservado. Te esperamos el lunes, 09 de noviembre a las 08:00.», las indicaciones de documentación completas, el botón «Avisar al consultorio por WhatsApp», el resumen (presencial, prestación, profesional, fecha y hora) y las acciones para confirmar, reprogramar o cancelar.
- **Online** (`prueba-online/`, sin errores de página ni de consola): «Consulta de seguimiento», «Virtual», «Particular».
  - En virtual sólo se ofrecen los miércoles 4 y 11 de noviembre, y en cada uno sólo las 16:30.
  - Página del turno: «Tu consulta virtual — Modalidad: Virtual — Antes del turno, el consultorio te va a indicar cómo conectarte a la consulta online.», con el miércoles 11 de noviembre a las 16:30.
- **Lo que quedó en la base** (`verificar-reservas-prueba.mjs` → `reservas-prueba-despues-de-reservar.json`):
  - dos pacientes, con la obra social guardada en su ficha (OSPAC y «Particular»), y dos turnos `reserved` de origen `public_booking`, por la integración nueva;
  - 08:00 y 16:30 hora local; contexto `in_person` y `video`, este último con las instrucciones guardadas en el turno; indicaciones de 749 caracteres guardadas en los dos;
  - ninguna otra paciente ni otro turno en el consultorio;
  - filas nuevas: 2 en cada una de estas tablas: pacientes, turnos, profesionales del turno, vínculos profesional-paciente, contextos de reserva, respuestas, envíos, contextos de información, intentos de reserva e historia `appointment.public_created`.
- **WhatsApp:** el botón de la página del turno lleva al número configurado del consultorio (comparado sin mostrarlo) con un mensaje precargado que nombra el turno.
- **Limpieza** (`limpiar-pruebas.mjs`; ensayo, aplicación a las 10:31:03 y recibos `limpieza-*.json`): borra sólo los cuatro identificadores registrados y lo que crearon.
  - Un primer ensayo frenó solo (`limpieza-ensayo-intento-1.json`): el registro de intentos no guarda el turno, así que sus dos filas no se encontraban por esa vía. Se borran ahora por consultorio y franja horaria, exigiendo que sean exactamente dos (la foto previa tenía cero).
  - Controles: cada tabla volvió al conteo exacto de la foto previa, los identificadores desaparecieron y los demás consultorios quedaron con huellas idénticas en pacientes, turnos e historia.
- **Comprobación independiente:** `despues-de-limpiar.json` tiene conteos idénticos a `antes-de-pruebas.json`, y `comprobar-turnero.mjs despues-de-limpiar 2026-11-09` da 24 de 24 (los dos horarios usados volvieron a estar libres).
- **No salió nada del sistema:** el consultorio no tiene WhatsApp automático, Calendar ni reseñas de Google conectados; la profesional no tiene avisos al celular registrados, y no hay correo a pacientes.

### Hallazgos de las pruebas en el consultorio real (para Juan y Natalia)

1. **Falta la dirección del consultorio.** El turno presencial dice «Te esperamos el lunes…» sin decir dónde. Es lo más importante antes de la entrega.
2. **«Equipo de profesionales» con una sola profesional:** el paso «¿Con quién?» ofrece «Un profesional / Equipo de profesionales» aunque el consultorio tenga una sola. Es un comportamiento general de la app, no de esta configuración; queda como mejora posible.
3. **Indicaciones iguales para presencial y online:** el texto de documentación, que habla de «traer» la orden, se muestra también en la consulta online. Natalia tiene que decir qué hacen sus pacientes con la orden en una consulta online.
4. **Instrucciones de la consulta online:** son las provisorias (decisión 8) hasta que Natalia las confirme.

### Fase 7: documentación (10:32 a 10:40 UTC)

- **Pasan a V10b como versión vigente,** dejando V9 como antecedente: `README.md`, `docs/README.md`, `AGENTS.md` (con un apartado nuevo, «Estado al 1 de noviembre»), `docs/architecture/publicacion-y-reversion.md` (estado, recuperación con el paso de datos previo y recuperación de la web), `docs/architecture/confirmacion-de-correo.md`, `docs/architecture/auditoria-final.md` y los traspasos de confirmación de correo, refactorización y señas y avisos.
- **Dominios oficiales:** `docs/architecture/dominio.md` (decisión literal y fila de workers.dev corregida), `docs/architecture/identidad-cita-suite.md` (estado de la web de Natalia) y la memoria del agente.
- **Límites de Auth:** `docs/architecture/correo-de-recuperacion.md`.
- **Lista única de pendientes:** reescrita (`docs/plans/pendientes-vigentes.md`). Se corrigió además un error propio de la primera versión del día, que decía que el retorno de Google Calendar seguía en workers.dev: vuelve al dominio oficial desde el 28 de octubre.
- **Documento privado de Natalia:** sección 7, «Resultado», con los valores reales (permiso 600).
- **Datos personales:** ninguno en los documentos públicos (búsqueda del correo, de la dirección automática y del teléfono, sin resultados).
- **Repositorio:** HEAD `80268e2a501198243996e1bdb0048ce066434727` e índice `55cd8f79…` sin cambios. La cuenta activa de `gh` volvió a ser Juan4787.

## Ayuda con duraciones, V11 (1 de noviembre, desde las 21:20 UTC)

Pedido y definición aprobada, literales: plan, sección 12.17. Traspaso: «Trabajo en curso — 1 de noviembre, desde las 21:20 UTC». Evidencia: `.verification/ayuda-duraciones-20261101/` (carpeta 700, recibos 600).

### Lo que había (V10b)

- `activate_account_assistance(uuid, uuid)` daba siempre 60 minutos; con una ayuda activa devolvía la misma, sin extenderla.
- `revoke_account_assistance(uuid)` sólo la podía usar la dueña.
- Los textos decían sólo la hora («hasta las 10:15»): alcanzaba para una hora, no para 24 horas ni 7 días.
- Durante la ayuda, el usuario de soporte actúa como administrador del consultorio; eso no cambia con V11.

### Diseño de V11 y sus fundamentos

- **Tabla `account_assistance_grants`:**
  - `kind`: `hour`, `day` o `initial_setup`. Su valor por omisión es `hour`, la hora que da V10b. Así las ayudas ya existentes quedan como de una hora y la función de V10b sigue funcionando durante la publicación y en una recuperación.
  - `extended_at`: la última extensión.
  - `revoked_by_role`: `owner` o `support`. Queda nulo cuando la ayuda vence y en las que terminó V10b, porque entonces sólo podía terminarla la dueña; la app lo lee como «la terminaste».
  - Restricción `account_assistance_grants_seven_day_cap_check`: ninguna ayuda termina más de 7 días después de su última activación o extensión, la escriba quien la escriba. Es una defensa además de las funciones: si una función tuviera un error, la base igual rechazaría un plazo mayor.
- **Funciones nuevas.** Todas son privilegiadas, con la ruta de búsqueda `pg_catalog, pg_temp` y nombres completos; las ejecutan los usuarios con sesión y nunca la clave pública:
  - `start_account_assistance(consultorio, soporte, duración)`: sólo la dueña, con el consultorio habilitado y el soporte activo. La configuración inicial exige que no haya ningún paciente, archivados incluidos, en ese momento. Pedir de nuevo la misma duración devuelve la ayuda activa, para que un doble clic no cree dos. Pedir otra duración con una activa se rechaza (`ACCOUNT_ASSISTANCE_ALREADY_ACTIVE`): cambiar de duración es extender, nunca un reemplazo silencioso.
  - `extend_account_assistance(consultorio, ayuda, duración)`: sólo la dueña y sólo sobre la ayuda que está viendo. Pasa a una duración más larga, contada desde ese momento, sobre la misma ayuda, así el maestro no pierde la sesión. La configuración inicial se renueva por 7 días más aunque haya pacientes; pasar a ella desde 1 hora o 24 horas exige que no los haya. Nunca acorta: además de la regla de duraciones, rechaza un fin que no sea posterior al actual.
  - `end_account_assistance(consultorio, ayuda)`: la dueña o el usuario de soporte de esa ayuda. A cualquier otro le responde lo mismo, `ACCOUNT_ASSISTANCE_OWNER_REQUIRED`, esté como esté la ayuda, para no revelar si existe. Registra quién la terminó en la fila y en la historia de auditoría.
  - `account_assistance_has_patients(consultorio)`: sólo la dueña. Es la misma condición que usan las funciones, para que la pantalla nunca ofrezca una opción que la base rechazaría.
- **Pacientes cargados durante la ayuda:** ningún disparador ni función mira los pacientes después de dar la ayuda. La condición «sin pacientes» se evalúa una sola vez, al darla. Si alguien crea un paciente en el mismo instante en que la dueña da la configuración inicial, es equivalente a crearlo justo después, que la definición permite.
- **Confirmación de dar, extender y terminar, de los dos lados:** componente nuevo `ConfirmForm`. Su formulario no tiene botón de envío: sólo lo envía el diálogo, con `confirmed=1`, y el servidor rechaza cada acción sin ese campo. El botón queda inactivo hasta que la página carga, y el diálogo se monta sobre el cuerpo de la página, fuera de las tarjetas.
- **El diálogo de dar o extender dice la fecha y la hora estimadas de fin** («hasta el domingo 8 de noviembre, alrededor de las 10:15»). La calcula con el reloj del servidor de la página, así no depende del reloj del teléfono, y la escribe al abrirse. Dice «alrededor» porque el plazo empieza cuando la dueña confirma.
- **Avisos:**
  - mientras está activa, la dueña ve el aviso con la fecha y la hora de fin. Si lo cierra, vuelve a aparecer sólo si cambia el fin, por ejemplo al extenderla;
  - la marca fija «Ayuda activa hasta dom 8/11 10:15» aparece debajo del nombre del consultorio en la computadora y en el menú del celular, donde además un punto verde en el botón del menú avisa que está activa;
  - cuando termina, la dueña ve durante 24 horas «La ayuda de Cita Suite terminó», con la causa, la fecha y la hora. Puede cerrarlo en ese dispositivo o, desde Ayuda, en todos.
- **Lo que no muestra la app:** la duración ya no se ofrece en el aviso general. El aviso lleva a Ayuda, donde la dueña elige y confirma.

### Pruebas que fallaron primero

- **Unitarias del servidor:** 32 de 38 fallaron antes de implementar (`unitarias-antes.txt`), y el diálogo no compilaba porque no existía (`cliente-antes.txt`).
- **Prueba SQL nueva** `supabase/tests/account_assistance_durations.sql`, con 47 comprobaciones, y par de actualización `supabase/tests/migrations/20261101030000_account_assistance_durations.sql.{before,after}.sql`. Sobre V10b fallan porque las funciones no existen.

### Comprobación local de la base y mutaciones

- **Base descartable local:** `test-booking-foundation.mjs --keep --prepare-only`, de 384 MB, con 131 migraciones. Su armado sobrescribe `.verification/database-catalog.json`; la copia del 15 de octubre se preservó y se restauró con la misma huella y el mismo permiso.
- **Errores propios encontrados en la prueba antes de CI:**
  - una misma dueña en dos consultorios: la base lo prohíbe (`EMAIL_ALREADY_ASSOCIATED_WITH_OTHER_BUSINESS`);
  - `format('%s', booleano)` escribe `t` y no `true`;
  - una sentencia no ve la fila que inserta la función que llama.

  Corregidos, la prueba da 47 de 47 y la actualización 4 de 4, sin dejar filas.
- **Hueco que la prueba no veía:** con el reloj congelado de la transacción, el intento de «1 hora → 1 hora» lo frenaba el control de «más largo» y no la regla de duraciones, así que una mutación de esa regla habría pasado. La ayuda ahora se envejece 40 minutos antes de los intentos inválidos.
- **Mutaciones** (`mutaciones-sql.py`, recibo `mutaciones-sql-primera.json`): 18 de 18 detectadas, con la base en 47 de 47 antes y después de restaurar. Entre ellas:
  - configuración inicial con pacientes, al darla o al extender;
  - extensión que acorta o renueva 1 hora;
  - fin por un administrador o por otro soporte;
  - archivados que no cuentan;
  - auditoría sin duración;
  - quién terminó equivocado o sin usuario;
  - sin tope de 7 días;
  - reemplazo silencioso;
  - extensión de otra ayuda;
  - ejecución con la clave pública;
  - 24 horas que son 23;
  - soporte deshabilitado;
  - consultorio sin acceso;
  - un disparador que termina la ayuda al cargar un paciente.

### Candidatas y CI

| Candidata | Revisión | Resultado |
|---|---|---|
| V11a | `4665475e0e65479bd3a9496927ceb0b89f5b54bc` | Tipos [41355440901](https://github.com/Juan4787/cita-suite-verificacion/actions/runs/41355440901): idénticos byte a byte a los escritos a mano, con las migraciones de huella `4e4bf282…`. SQL [41355454597](https://github.com/Juan4787/cita-suite-verificacion/actions/runs/41355454597): falló en la prueba de actualización por los booleanos `t`, ya encontrados en local. `fast` cancelada. |
| V11b | `8908c706be21bbbe5e3bfe4b954c8622803db2d8` | Tipos, SQL [41355931355](https://github.com/Juan4787/cita-suite-verificacion/actions/runs/41355931355) y `fast` [41356120948](https://github.com/Juan4787/cita-suite-verificacion/actions/runs/41356120948) aprobadas. |
| V11c | `a8a04a8108200f6fe351d67ddc68730eea41c486` | Auditoría: con V11b, pasadas las 24 horas del aviso de fin la app ya no volvía a ofrecer la ayuda, como sí hacía V10b. Se restituyó y la decisión del aviso pasó a `assistance-notice.ts`, con 5 pruebas. Tipos [41362807984](https://github.com/Juan4787/cita-suite-verificacion/actions/runs/41362807984), SQL [41362823023](https://github.com/Juan4787/cita-suite-verificacion/actions/runs/41362823023), `fast` [41363001658](https://github.com/Juan4787/cita-suite-verificacion/actions/runs/41363001658) y paquete aprobados. El navegador corrió primero sólo la selección por omisión del flujo (8 pruebas, sin la de ayuda: la cola no pasaba patrón). Con el patrón `.` ([41364181270](https://github.com/Juan4787/cita-suite-verificacion/actions/runs/41364181270)) dio 58 de 59. |
| V11d | `69a0493266ee77a9eb2e48aa0250fdb4e482c583` | La falla de V11c era de la prueba: el envío sin confirmar salía sin la sesión de la dueña y SvelteKit respondía con su JSON de redirección a `/login`, sin llegar al control. Navegador [41365401446](https://github.com/Juan4787/cita-suite-verificacion/actions/runs/41365401446) lo demostró, y la prueba pasó a enviar un formulario real desde la página. |
| V11e | `4a2ecd241697eeaf5598bdb3bd0e84116ba89d30` | El envío sin confirmar queda rechazado («Confirmá la acción para continuar.» y ninguna ayuda creada). Navegador [41366749036](https://github.com/Juan4787/cita-suite-verificacion/actions/runs/41366749036): el nombre accesible de la marca tenía un espacio antes de los dos puntos, porque el texto y el detalle eran dos elementos del contenedor flexible. Se agruparon. |
| **V11f** | **`72d59ab00db67a8502ca560c762c61e6cfac1923`** | **`fast` [41367629390](https://github.com/Juan4787/cita-suite-verificacion/actions/runs/41367629390), paquete [41367663218](https://github.com/Juan4787/cita-suite-verificacion/actions/runs/41367663218) y navegador completo sobre ese paquete [41368132842](https://github.com/Juan4787/cita-suite-verificacion/actions/runs/41368132842): 59 de 59.** La migración y las pruebas SQL son idénticas a las de V11c, que las aprobó. |

En V11c, `fast` dio:
- servidor: 1648 de 1648, 37 más que V10b;
- cliente: 258 de 258, 5 más;
- programas: 171;
- programador: 11;
- `svelte-check`: 0 errores y 0 advertencias.

Las capturas de la prueba de navegador (`ci-41368132842/evidencia/…`) muestran:
- en la computadora, la marca «Ayuda activa hasta lun 2/11 21:40» debajo del nombre del consultorio y el aviso «Cita Suite puede entrar a tu cuenta hasta el lunes 2 de noviembre a las 21:40.»;
- en el celular, el punto verde en el botón del menú y en «Más».

### Publicación (2 de noviembre)

- **Staging:** pasó de 130 a 131 migraciones a las 00:01 UTC (`migracion-staging.log`).
- **Ensayo en producción:** una migración pendiente, 0 fallas y 0 diferencias de catálogo con staging (`ensayo-migraciones-produccion.log`).
- **Copia privada:** `~/.local/share/cita-suite/backups/production-2026-11-02T00-02-46-283Z`. Tiene 110 tablas, 4419 filas, 130 migraciones y 24 archivos, sin fallas (`copia-produccion.log`).
- **Paquete de V11f bajado** a `.verification/ayuda-duraciones-20261101/release-candidate-v11f/`: 229 archivos, revisión `72d59ab0…`.
- **Bloqueada a las 00:47 UTC:** el control de permisos rechazó `apply-production-migrations.mjs` («Production Deploy»). Producción sigue en V10b, con 130 migraciones. Hace falta que Juan autorice expresamente la migración y la publicación.
- **Publicada (2 de noviembre):**
  - Juan respondió «subi»;
  - migración aplicada en producción a las 02:10:26 UTC: de 130 a 131 migraciones, en 3 segundos;
  - el Worker `app` sirve la versión `59f81e89-412f-49be-b65b-3a2378ddf71e`, revisión `72d59ab0…`;
  - `verify-production-release.mjs` aprobado (140 archivos del cliente) y los dos orígenes sirven 72d59ab;
  - el primer intento de publicar falló antes de publicar nada, por recibir la carpeta superior del paquete en lugar de su subcarpeta.
- **Google:** Juan confirmó el 2 de noviembre que la web ya está verificada por Google. Ese punto se marcó hecho en `pendientes-vigentes.md`; la decisión de Calendar y la verificación de marca siguen pendientes.

## Google: proyecto propio para Calendar (2 de noviembre)

- **Decisión de Juan:** «hagamozlo», por la recomendación del agente de un proyecto aparte y gratis en lugar del dominio propio de Supabase, que es pago.
- **Lo que creó Juan:** «Cita Suite Calendar» (`cita-suite-calendar-513502`), con el cliente web `702611060405-…`, el retorno oficial, el permiso `calendar.events.owned` y el estado «Prueba».
- **Retornos:** la sonda `.verification/calendar-proyecto-propio-20261102/` confirma que Google acepta el retorno oficial y rechaza el control, la doble barra y workers.dev.
- **Hallazgo:**
  - Calendar lo vinculan los pacientes desde la página del turno (`authorize_google_calendar_event`), no el consultorio.
  - Con la app en «Prueba», el cambio bloquearía a todo paciente que no sea usuario de prueba. Por eso publicarla va antes del cambio.
  - Las autorizaciones del cliente anterior no sirven con el nuevo: `oauth_client_key` es la huella del ID de cliente.
- **Credenciales:**
  - el JSON quedó en `ACCESOS-GOOGLE-CITA-SUITE/GOOGLE-CALENDAR-PROYECTO-CITA-SUITE/` (huella `574eaaea…`, 600), trasladado sin abrirlo;
  - el agente lo había puesto primero en `~/.config/cita-suite/private/`. Juan señaló que ya existía la carpeta de accesos, y se corrigió para no mezclarlo con `GOOGLE-CALENDAR/`, que sigue siendo el cliente de producción;
  - `indice-clientes.json` no se actualizó, porque el control de permisos no dejó abrir los JSON de esa carpeta.
- **Documentación:** quedó coherente en:
  - `ACCESOS-GOOGLE-CITA-SUITE/LEEME.md` y las guías de `GOOGLE-CALENDAR/` y de la subcarpeta nueva;
  - `docs/architecture/accesos-google.md`, `acceso-google-calendar.md`, `dominio.md` (punto 4) y `auditoria-final.md`;
  - `pendientes-vigentes.md`, sección 4, punto 1, que es la fuente única del estado.
- **Bloqueado por el control de permisos:** la lectura de producción de las conexiones de Calendar.
- **Logo para Google:** `CITA SUITE/logo-cita-suite-google-120.png`, de 120 × 120.
- **2 de noviembre, de 03:00 a 03:07 UTC: cambio de cliente de Calendar.** Juan publicó la app nueva («En producción»), y Google mostró verificada la información de la marca. Juan cargó estas reglas de permiso de Claude Code: `node scripts/*`, `NODE_OPTIONS=* node scripts/*`, `node .verification/*` y `npx wrangler *`.
  - **Lectura previa** (`calendar-antes-del-cambio.json`): una sola conexión, la histórica de agosto, con un evento pasado de Ramirez. Nadie real pierde su vínculo.
  - **Credenciales:** `instalar-cliente-calendar.mjs` cargó las dos juntas con `wrangler secret bulk`, sin mostrarlas. Versión `986cf666-ae09-423b-ae05-1928007dccde`; vuelta atrás a `59f81e89-412f-49be-b65b-3a2378ddf71e`. Los dos orígenes siguen sirviendo la revisión 72d59ab.
  - **Turno sintético:** `reservar-turno-calendar.mjs` reservó «PRUEBA Calendar Cita Suite» en Ramirez para el 2 de noviembre a las 09:00. El primer intento no reservó nada, porque el formulario rechaza nombres con números.
  - **Inicio de la conexión:** responde 303 a `accounts.google.com`, con el cliente nuevo, el retorno oficial y `openid calendar.events.owned`.
  - **Pendiente:** el permiso real de Juan, y después la creación, cancelación y borrado del evento.
- **2 de noviembre, de 03:13 a 03:17 UTC: ciclo de Calendar con el cliente nuevo.**
  - **Permiso:** Juan lo aceptó desde la computadora («aceptado») y vio en su celular el evento del Consultorio Ramirez, con el aviso de verificación pendiente.
  - **Lectura** `calendar-despues-del-permiso.json`: conexión del cliente nuevo con autorización guardada y evento `active`.
  - **Cancelación:** `cancelar-turno-calendar.mjs`. El intento 1 no canceló nada: esperaba el título «Resumen de la reserva», que sólo aparece en la primera visita. El intento 2 canceló el turno.
  - **Lectura** `calendar-despues-de-cancelar.json`: no quedan el vínculo ni la conexión nueva; sólo la histórica de agosto. La cancelación borró el evento y retiró la autorización sobrante, como en el ciclo del 24 de octubre.
  - **Datos:** el turno ficticio queda cancelado en Ramirez.
- **Reglas de permiso de Claude Code revisadas:** las cuatro de Juan funcionan.
  - Un comando compuesto, como `cd … && node …`, no coincide con ellas: el agente escribe los archivos aparte y ejecuta `node .verification/…` solo.
  - `node .verification/*` permite que cualquier programa de esa carpeta escriba en producción: es amplio a propósito para esta fase. Se recomienda quitarlo al entregar.
- **Documentación pasada al cliente nuevo como vigente:**
  - `ACCESOS-GOOGLE-CITA-SUITE/` (raíz, las dos subcarpetas de Calendar y `datos-de-acceso.json`);
  - `docs/architecture/accesos-google.md`, `acceso-google-calendar.md`, `dominio.md` y `auditoria-final.md`;
  - pendientes.

<a id="etapa-e-revision"></a>

## Revisión documental de E — 2 de noviembre de 2026

**Cierre de esta revisión: 3 de noviembre de 2026 (hora argentina).** La conversación y el inicio del contraste fueron el 2; se conserva esa fecha en el ajuste 12.18. La validación final y los documentos de continuación distinguen ambas fechas.

### Pedido, alcance y estado informado

El pedido literal y las decisiones de la conversación se incorporaron a [plan 12.18](propuesta-senas-avisos-natalia.md#etapa-e-vigente). Juan pidió primero contrastar todos los casos con el código y dejar la documentación coherente; después dará la instrucción de empezar. Este paso no configura proveedor/secretos/DNS, no cambia la app/base ni envía o publica nada.

**Zoho, fuente Juan:** cuenta creada, dos envíos probados por él, KYC pendiente y 100 correos gratuitos diarios; pagará al verificarse. No falta crear cuenta. No se conocen por ese informe el dominio, región, credenciales, saldo/vencimiento exactos ni recepción/recorridos de los mensajes. No se atribuyen al agente ni a la integración todavía inexistente.

**Economía:** se acepta correo de costo controlado también con un consultorio. Base aportada 500 pacientes por mes × 3 mensajes = 1.500 mensajes mensuales, más eventos adicionales. No exigir gratuidad indefinida, no afirmar que la cuenta de prueba sirve para siempre ni que ese cálculo demuestra insuficiencia de otro proveedor. Juan compra después del KYC; sin auto-recarga o contrataciones del agente. Supabase/Workers conservan sus decisiones separadas.

### Contraste, correcciones y resultado documental

- Fuente leída: main **45ad4dad3259386b445d3306ca66bb16bf51f285**, sincronizada con origin/main; producción V12b **771fac5950c532b1123f11d4dde93eef9b42ceba**, versión **277d332d-1794-4367-8ef0-567ced159f1b**. Comprobación inicial con check-repo-sync aprobada.
- Se aplicó la skill supabase-postgres-best-practices para revisar orden de bloqueos, transacciones breves y colas. Sólo lectura de SQL; no se escribió ni ejecutó migración.
- Se creó [especificación única de E](etapa-e-correo-autogestion.md), con decisiones, evidencia C01–C13, matriz de aceptación y secuencia E0–E6. D no se reanuda. Los casos se marcan pendientes de ejecutar, no aprobados.
- **Reutilización confirmada por lectura:** disponibilidad excluye el propio turno y contempla equipo/modalidad; calendario tiene UID estable y secuencia; la relación de seña vigente es uno a uno.
- **Trabajo necesario:** movimiento público autónomo en vez de pedido; revisión semántica, porque status no detecta dos cambios de hora; transacción de horario/dinero/auditoría/eventos, frente a la auditoría actual separada; historia de obligaciones/pagos sin romper la proyección actual.
- **Correcciones a la propuesta:** no rotar indiscriminadamente el token compartido con push/Calendar; revisar rutas legadas/ICS al revocar gestión. No prometer duración congelada: hoy se usa la vigente. No llamar saldo financiero total a la diferencia entre cotización y señas registradas. No activar auto_cancel de una obligación ya protegida sólo por moverla.
- Se retiró la deduplicación por cercanía genérica de 30 minutos y se exigió equivalencia de contenido/propósito/revisión/destinatario y resultado conocido. La recuperación tardía de recordatorios de 30 minutos permanece como parámetro técnico inicial propuesto, sujeto a verificación; no es aprobación literal ni hecho del código.
- La nueva política de pérdidas no define devoluciones al cancelar. No se inventan condiciones de Natalia ni historia de pagos en migración.
- Los permisos de consulta/cancelación con reserva apagada o suspensión deben ser mínimos y específicos; no se retiran globalmente guardias comerciales. Zoho no aporta una transacción común con la base ni prueba de entrega única por usar una referencia propia.
- Se revisaron las fuentes oficiales de Zoho enlazadas en la especificación: cuota/revisión, vigencia, API, webhooks y condiciones. Es contraste documental del proveedor; no se ingresó a la cuenta ni se enviaron pruebas.
- El plan anterior se conserva: sólo se amplió su línea de estado y se agregó 12.18, con precedencia explícita sobre los apartados superados. No se reescribieron resultados ni decisiones antiguas como si hubieran sido los actuales.

### Consistencia de documentos

Se alinearon AGENTS, README, índice documental, pendientes, traspasos, estado vigente, contratos funcionales, permisos, matriz de regresiones, tareas automáticas, consumo, dominio, publicación/reversión y notas de los cierres históricos A/B/C. Las guías históricas de Auth no se usan para volver a pausar E; su alcance queda fechado. Se corrigió además la descripción vieja del README que aún decía mantener HEAD histórico: main y GitHub siguen siendo la referencia actual.

La fuente normativa nueva es una sola, enlazada desde los otros documentos. «Definición lista» no significa «implementado», «cuenta Zoho probada» no significa «integración comprobada», y «D en pausa» no significa «E descartada».

### Verificación de esta entrega documental

Recibo local de lectura/validación: .verification/etapa-e-plan-20261102/revision-documental.json. Conserva base, archivos documentales, casos y resultados de enlaces/fragmentos, integridad del plan anterior y ausencia de cambios de código. El SHA del commit documental se obtiene de Git; la versión de producción no se actualiza por editar estos archivos.

**Validación documental:** 97 casos identificados, enlaces y fragmentos locales comprobados, plan anterior preservado salvo su línea de estado y nuevo ajuste; sin cambios de código/migraciones/configuración. Comprobador privado reproducible: .verification/etapa-e-plan-20261102/validar-documentacion.py; recibo final en la ruta anterior. El control de integridad del plan de refactorización también pasó. Cierre en Git y sincronización se comprueban con check-repo-sync antes del informe. No se ejecutaron suites de aplicación ni se presentó su ausencia como aprobación de E.

### Punto exacto para continuar

Tras informar la revisión, esperar instrucción de inicio. Al reanudar: sincronización, plan 12.18, especificación, este registro, traspaso y lista única de pendientes. Comenzar E1–E4 en su orden de dependencias y preparar Zoho existente dentro de la cuota permitida, sin esperar KYC por rutina y sin comprar por Juan. Mantener las autorizaciones productivas anteriores y todos los límites de contexto, datos reales y RAM.
