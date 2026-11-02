# Auditoría final pre lanzamiento

> Documento operativo de certificación. Este archivo conserva íntegramente el plan de auditoría y debe utilizarse como registro vivo durante su ejecución.
>
> Regla de uso: marcar una casilla únicamente cuando exista evidencia verificable y enlazada. Si una casilla no aplica, registrar por qué, quién lo aprobó y qué riesgo residual queda; no eliminarla ni omitirla.

## Convención obligatoria: antecedentes frente a estado actual

- Los bloques fechados como **antecedente**, **snapshot histórico** o **estado encontrado al elaborar el plan** conservan lo que era cierto en ese corte. No se borran ni se reescriben para aparentar que siempre estuvo resuelto.
- El estado que gobierna la decisión de lanzamiento es la última sección fechada que diga explícitamente **estado actual**, junto con sus relecturas posteriores. Si una línea antigua contradice una relectura actual, la antigua se interpreta sólo como historial.
- Cada cambio de código, secreto, migración, configuración, deployment o fixture puede invalidar evidencia anterior. En ese caso se agrega una nueva medición y se deja la anterior marcada como antecedente.
- La decisión vigente al cierre de este registro sigue siendo **NO-GO** hasta que todos los gates críticos tengan evidencia suficiente; ningún `[x]` histórico se cuenta automáticamente para el candidato final.

## Control de ejecución

- [x] Fecha de inicio: 2026-08-30 (America/Argentina/Buenos_Aires).

- [x] Responsable: Codex, ejecución automatizada y revisión de evidencia; quedan pendientes las pruebas que requieren personas, dispositivos o proveedores no configurados.

- [x] **Snapshot histórico del plan (2026-08-30):** SHA candidato `e3887e414a88933355a57442082bef14deb89e5c` (`HEAD` y `origin/main`). La relectura actual del candidato final está registrada más abajo.

- [x] **Snapshot histórico del plan:** versión Cloudflare `97f5d35f-c20e-4d4e-9ee9-ffa122f2e553`, número 28, 100 %, creada 2026-08-28T15:43:42.950Z; sin tag ni mensaje. La versión actual etiquetada está registrada en la relectura de G0.

- [x] Dominio de producción: `https://app.cita-suite.workers.dev` (dominio workers.dev elegido; el flujo público de prueba también conserva el dominio histórico de Netlify como fixture externo y no se tomó como producción).

- [x] Proyecto Supabase: `yjzferwuzbtgpmdnzlcb` (URL remota verificada sin exponer claves).

- [x] **Resultado histórico del plan:** **NO-GO**. La corrida inicial encontró fallos E2E reproducibles del arnés y 15 vulnerabilidades de auditoría completa (estas últimas quedaron corregidas en el candidato remediado); los pendientes que se revaluaron después se conservan aquí como antecedentes.

- [x] **Antecedente inmediato del candidato final:** commit `034ecbdd0548e1fe45806adcb0efc4747fa4ebf6`, versión Cloudflare `3ed7a7a7-3cfb-4444-9516-5b92fbd334e7` al 100 %, deployment `e9426b31-a7e4-41d6-bc4d-ba842f80a773`; se conserva como evidencia del corte anterior y queda supersedido por la relectura posterior del fix Web Push.

- [x] **Antecedente inmediato del candidato final:** commit `4f4b28f5d6918f37d4de592b3fdfccc009b0f93b`, versión Cloudflare `f713a7d7-afc1-4132-8982-fc2e31a0de66` al 100 %, deployment `2026-08-31T10:01:38.025Z`; su manifiesto, smoke y fix de Web Push se conservan como corte anterior.

- [x] **Antecedente inmediato del candidato final:** commit `1d5fa13eb35b6fda3c6c947110e8f1e97b49fa02`, versión Cloudflare `9c48ac8f-4804-44b0-9d56-abbd6c492b59` al 100 %, deployment `abf97a4a-c326-4c84-a062-449d7a4d3c57`; tag `1d5fa13eb35b6fda3c6c947110e8f1e97b49fa02-manifest-dd962a9c`, manifiesto combinado byte a byte y smoke están documentados en la relectura posterior del final. Queda supersedido por el candidato actual de abajo.

- [x] **Antecedente inmediato del candidato final:** commit `35349a5c702109bcc527a06133d905aee9accf62`, versión Cloudflare `10f572e4-cef3-400a-be76-32405bd6333f` al 100 %, deployment `6701db36-57ec-472b-b9ce-2c681a33bf02`; tag `35349a5c702109bcc527a06133d905aee9accf62-clean-d22ebfd`, manifiesto completo y smoke de producción documentados al final de este archivo. Se conserva como evidencia del corte anterior y queda supersedido por el candidato `fba21de` de abajo.

- [x] **Antecedente inmediato del candidato final antes del ensayo de rollback:** commit `fba21de079706f9674a85303a3ec68b589b90f70`, versión Cloudflare `9f8be05a-b003-42a8-bc00-18e87eff0c54` al 100 %, deployment `9c33abf2-6c5c-4b5a-9ca5-12be37cdcefe`; tag `fba21de079706f9674a85303a3ec68b589b90f70-clean-2324f2`, manifiesto completo `2324f2e253b33f44eedbec04708a2aaf5d7c775e448bf5ce422cfafdac5f371b` y smoke de producción documentados al final de este archivo. Se conserva como corte anterior.

- [x] **Estado actual del candidato final (última relectura):** commit de runtime `fba21de079706f9674a85303a3ec68b589b90f70`, versión Cloudflare `9f8be05a-b003-42a8-bc00-18e87eff0c54` al 100 %, deployment posterior al ensayo dinámico de rollback `9c794bbb-1902-431a-beb2-b9e266c6047e`; tag `fba21de079706f9674a85303a3ec68b589b90f70-clean-2324f2`, manifiesto completo `2324f2e253b33f44eedbec04708a2aaf5d7c775e448bf5ce422cfafdac5f371b` y smoke posterior documentados al final de este archivo. El `HEAD` documental puede ser posterior, pero no altera este runtime.

- [x] **Commit posterior de documentación (no desplegado):** `035f3d823580a48aa8a49dd494672ddb718c34a2` sólo agrega esta relectura y el manifiesto archivado; no modifica `apps/web` ni el artefacto que atiende Cloudflare. Por eso la versión productiva continúa correlacionada deliberadamente con el commit de runtime `fba21de…`, mientras `HEAD`/`origin/prelaunch/cloudflare-20260830` ahora apuntan a este commit documental.

- [x] **Aclaración editorial posterior (no desplegada):** `16b71f9` sólo corrige la
  descripción de la relación entre el commit documental y el runtime; tampoco modifica
  `apps/web` ni la versión Cloudflare. La cadena documental posterior conserva el
  `HEAD` remoto actual sin sustituir al candidato de runtime `fba21de…`.

- [x] **Commit documental vigente (no desplegado):** `ed2568fc508b9a551367183bd664ba8bda6a447f`
  sólo separa snapshots históricos de estado actual, incorpora la precedencia editorial
  de `b1a35ff`, actualiza el deployment vigente `9c794bbb…` y deja explícita la evidencia
  del scheduler. No modifica `apps/web`, migraciones ni el artefacto publicado; el
  runtime de Cloudflare continúa siendo `fba21de…`.

- [x] Enlace al informe y artefactos: este archivo; resultados Playwright en `apps/web/test-results` (no está en el repositorio) y [apps/web/output/playwright](<apps/web/output/playwright>). Los artefactos contienen capturas/traces de fallos y no se consideran evidencia de aprobación.

## Alcance y principio de aceptación

La UX queda como un criterio de aprobación independiente y con el mismo peso que la integridad de datos. Una acción técnicamente correcta pero confusa, lenta, ambigua o peligrosa será un fallo de lanzamiento.

Este plan fue construido después de auditar el código actual, sus rutas, acciones de servidor, RPC, políticas, integraciones, E2E existente y el deployment de Cloudflare.

Al elaborar el contenido original de este plan no se modificó código ni se ejecutó todavía la batería de pruebas; fue una auditoría de lectura y planificación. La creación de este documento es el primer cambio solicitado expresamente para conservarla y ejecutarla.

## Estado real encontrado al elaborar el plan

- [x] Confirmar nuevamente que main y origin/main coinciden en el SHA candidato. Coinciden en `e3887e414a88933355a57442082bef14deb89e5c` al 2026-08-30; el texto histórico `6914543` se conserva como antecedente.

- [ ] Confirmar que la certificación se hace desde un checkout aislado y limpio. Al elaborar este plan el checkout no estaba limpio: había una modificación del usuario en Tailwind y artefactos de Playwright sin versionar. El código probado debe ser exactamente el desplegado.

- [x] Recontar y registrar los archivos de entrada de rutas y endpoints. Hay 171 archivos bajo `apps/web/src/routes` al 2026-08-30; el texto histórico de 127 se conserva.

- [x] Recontar y registrar la suite E2E. Hay 13 specs y 27 pruebas; se observaron 20 lugares con skip condicional. La corrida inicial quedó 19 passed, 2 failed y 6 skipped; la candidata final, tras corregir causas y respetar el rate limit, quedó 14 passed y 13 skips explícitos sin fallos (más 12/12 destructivos y 2/2 clínicos remotos). La corrida local histórica quedó 18 passed, 4 failed y 5 skipped.

- [x] Mantener Playwright limitado a un worker y sin paralelismo en [playwright.config.ts](<apps/web/playwright.config.ts>), apropiado para esta PC. Se ejecutó con `workers=1`; la corrida certificadora Cloudflare fijó además `retries=0`.

- [x] Confirmar que Cloudflare sigue usando `nodejs_compat`, assets estáticos `ASSETS`, `keep_vars: true` y placement hacia `aws:sa-east-1` en [wrangler.jsonc](<apps/web/wrangler.jsonc>); `wrangler versions view` confirmó placement targeted y target `aws:sa-east-1`.

- [ ] Correlacionar el deployment activo con Git. El deployment observado el 27 de agosto de 2026 era f360495e-b23d-4fbf-8fc9-7a0b77e937af al 100%, pero aparecía sin tag, mensaje ni relación comprobable con el commit 6914543. Eso impide asegurar qué código exacto está atendiendo producción.

- [x] Verificar los handlers efectivos del deployment. `wrangler versions view` declaró sólo el handler `fetch`.

- [ ] Identificar y demostrar qué scheduler externo llama los cuatro jobs internos, con su frecuencia y última ejecución correcta. Cloudflare no los está programando por sí solo mientras sólo sean endpoints HTTP.

- [ ] Declarar y verificar observabilidad y scheduling explícitos. `wrangler.jsonc` y la versión activa no declaran `observability` ni `triggers.crons`; quedan sin demostrar Workers Logs/scheduler y el riesgo bloquea GO.

- [x] Eliminar el riesgo de URLs del hosting anterior. El candidato sólo conserva el fallback `https://app.cita-suite.workers.dev`, rechaza explícitamente hosts Netlify/Vercel en `getPublicSiteUrl()` y los smokes/crawl del Worker activo no encontraron referencias a `netlify.app`, Vercel ni localhost. El hallazgo histórico de la configuración anterior se conserva en el registro de remediación.

- [x] Inventariar los nombres de secretos/bindings efectivos. `wrangler versions view` registró 28 bindings/nombres de secreto sin imprimir valores; faltan bindings opcionales de Turnstile y credenciales completas de WhatsApp.

- [ ] Decidir explícitamente si Turnstile, Google Calendar administrado y envío automático de WhatsApp están habilitados o intencionalmente deshabilitados. En el deployment observado no aparecían algunos de esos bindings opcionales; un fallback silencioso no es aceptable.

- [x] Conservar una prueba específica de incompatibilidades del runtime Cloudflare. La prueba independiente del Worker completó upload, `/complete`, descarga validada, visor `blob:`, papelera y restauración; registró `ready/ok`, cinco eventos de auditoría y sólo abortos esperados de `AbortController`.

- [ ] Ejecutar la revisión oficial de calidad de Mercado Pago antes del lanzamiento. No pudo ejecutarse al elaborar este plan porque el conector oficial requerido no estaba disponible. El análisis estático forma parte de este documento, pero no reemplaza esa checklist en vivo.

## Regla fundamental

Ningún resultado aislado equivale a “producto validado”. La aprobación requiere que pasen todos estos gates. Si falla uno, es NO-GO.

### Snapshot histórico de gates al elaborar el plan — ANTECEDENTE — 2026-08-30

Las filas siguientes son el estado que existía cuando se creó el plan y se conservan
sin reescritura. No gobiernan la decisión vigente cuando una relectura posterior de este
archivo aporta una medición nueva; sirven para mostrar qué estaba bloqueado, qué se había
demostrado y qué cambió. La tabla de precedencia actual aparece en la última relectura
fechada como **ESTADO ACTUAL**.

- [ ] **G0 — Trazabilidad:** commit, migraciones, artefacto y versión Cloudflare identificados inequívocamente. **Parcial/bloqueado:** la candidata activa `9ed2e958-697c-46b6-90ea-5b3bd01c9adf` identifica en tag/mensaje el commit local `7c25b12` y el Worker SHA, pero el branch no fue publicado en GitHub ni existe checkout remoto limpio que cierre la correlación.

- [ ] **G1 — Recuperación:** backup restaurado realmente en un entorno aislado. **Bloqueado:** no se ejecutó backup/restore aislado.

- [x] **G2 — Código:** tipos, unitarios, integración, dependencias y build Cloudflare verdes para el candidato remediado: `pnpm check` sin diagnósticos, Vitest 106/813, cliente 7/71, pgTAP/concurrencia verdes, `pnpm audit --audit-level=high` sin vulnerabilidades conocidas y build Cloudflare correcto. La corrida inicial había reportado 15 vulnerabilidades transitivas; fueron corregidas con overrides compatibles con Node 20. Este aprobado sólo cubre el candidato local y no sustituye G0/G1/G4/G6/G7/G8/G9.

- [ ] **G3 — Datos:** RPC, RLS, roles, concurrencia e invariantes verdes. **Parcial:** pgTAP y concurrencia pasaron; no se completó la matriz E2E de todos los roles/tenants ni el backup restaurado.

- [ ] **G4 — Funcional:** todos los recorridos E2E completos, sin skips inesperados. **Parcial:** la candidata final no tuvo fallos (suite general 14/27 con 13 skips explícitos; destructivos 12/12; clínicos remotos 2/2), pero Google real, ayuda maestra y escenarios demo no pudieron ejecutarse en este entorno.

- [ ] **G5 — UX:** tareas reales completadas correctamente por usuarios representativos. **Bloqueado:** sólo automatización; faltan participantes, accesibilidad formal, dispositivos y métricas SEQ/SUS.

- [ ] **G6 — Cloudflare:** runtime, caché, placement, límites, logs, jobs y rollback verificados. **Bloqueado:** runtime/headers/placement y promoción controlada pasaron, pero no hay observabilidad/cron declarados, límites p99 ni rollback real demostrado.

- [ ] **G7 — Proveedores:** Supabase, Google, Meta, push y Mercado Pago verificados. **Bloqueado:** revisión oficial Mercado Pago no disponible, Google real/WhatsApp/Turnstile/VAPID administrado sin credenciales completas y sin callbacks reales.

- [ ] **G8 — Producción:** suite segura ejecutada contra el dominio real y la versión exacta. **Parcial/bloqueado:** dominio y versión `9ed2e958-…` al 100 % fueron probados sin fallos y con dos pasadas consecutivas, pero persisten skips de cobertura y la correlación Git remota pendiente.

- [ ] **G9 — Operación:** alertas, soporte, rollback, auditoría e incidentes listos. **Bloqueado:** no se demostraron logs/alertas/scheduler/rollback ni runbook operativo completo.

## Contrato obligatorio de cada caso

Cada prueba, incluso las aparentemente simples, debe comprobar:

- [ ] Estado inicial, tenant, usuario, rol, versión, dispositivo, red y hora.

- [ ] Resultado visible: texto, botones, foco, contexto y siguiente acción.

- [ ] Respuesta HTTP: método, estado, redirect, caché y ausencia de respuestas inesperadas.

- [ ] Estado persistido: relectura independiente desde base de datos; no confiar sólo en la UI.

- [ ] Efectos secundarios: storage, auditoría, outbox, push, calendario, WhatsApp o pago.

- [ ] Seguridad: tenant correcto, actor correcto y ausencia de acceso lateral.

- [ ] Observabilidad: sin errores JavaScript, requests fallidos, excepciones Worker ni datos sensibles en logs.

- [ ] Idempotencia: recargar, reenviar, hacer doble clic o perder la respuesta no debe duplicar nada.

- [ ] Limpieza exacta por IDs registrados en un manifiesto; nunca limpiar producción por prefijos amplios.

## Datos de prueba obligatorios

Crear fixtures determinísticos y versionados:

- [ ] Consultorio A activo con owner, admin, recepción, profesional vinculado, profesional no vinculado y readonly.

- [ ] Consultorio B con datos de nombres y horarios similares para probar aislamiento entre tenants.

- [ ] Consultorios separados en estado activo, gracia, restringido, archivado, pausa manual y acceso permanente.

- [ ] Usuario maestro y concesión de asistencia activa, expirada y revocada.

- [ ] Paciente con nombre normal.

- [ ] Paciente con acentos.

- [ ] Paciente con apóstrofes.

- [ ] Paciente con espacios duplicados.

- [ ] Paciente con emoji y Unicode.

- [ ] Pacientes que demuestren que n y ñ son identidades distintas.

- [ ] Pacientes con el mismo nombre y teléfono.

- [ ] Pacientes con el mismo teléfono y nombres distintos.

- [ ] Pacientes con el mismo nombre y teléfonos distintos.

- [ ] DNI repetido dentro del consultorio.

- [ ] El mismo DNI en otro consultorio.

- [ ] Paciente sin teléfono.

- [ ] Paciente con teléfono válido.

- [ ] Paciente con teléfono incompleto.

- [ ] Paciente con teléfono inválido.

- [ ] Paciente activo.

- [ ] Paciente archivado.

- [ ] Paciente bloqueado.

- [ ] Pacientes con distintos profesionales vinculados.

- [ ] Paciente con más de 30 entradas clínicas.

- [ ] Paciente con más de una página de radiografías.

- [ ] Servicios individuales y conjuntos.

- [ ] Duraciones y buffers extremos.

- [ ] Horarios partidos.

- [ ] Excepciones de disponibilidad.

- [ ] Turnos futuros.

- [ ] Turnos de hoy.

- [ ] Turnos de mañana.

- [ ] Turnos de pasado reciente.

- [ ] Turnos pasados fuera del corte.

- [ ] Turnos cancelados.

- [ ] Turnos confirmados.

- [ ] Turnos reservados.

- [ ] Turnos con reprogramación solicitada.

- [ ] Archivo JPG válido.

- [ ] Archivo PNG válido.

- [ ] Archivo corrupto.

- [ ] Archivo polyglot.

- [ ] Archivo con MIME falso.

- [ ] Archivo de cero bytes.

- [ ] Archivo de 25 MiB exactos.

- [ ] Archivo de 25 MiB + 1 byte.

- [ ] Suscripciones push por dispositivos distintos.

- [ ] Tokens públicos rotados.

- [ ] Calendarios conectados y desconectados.

- [ ] Fixtures de pago exclusivamente controlados.

- [ ] En producción, usar únicamente un consultorio sintético aislado y datos ficticios. Nunca usar historias clínicas reales.

## Orden de ejecución literal

### 1. Congelar el candidato

- [ ] Crear un checkout limpio del SHA candidato.

- [x] Registrar el SHA Git. `e3887e414a88933355a57442082bef14deb89e5c`.

- [x] Registrar el lockfile. SHA-256 de `pnpm-lock.yaml` en el registro inicial: `33b9c14bb173713e2551917ced15de99d99c3b48fdaa456a4f7a0893696af5c7`. Tras los overrides de seguridad autorizados, el candidato remediado queda con SHA-256 `6080bd286e8e5264e818b4ff351db17648654ba8214940b06fb77c6062df850e`.

- [x] Registrar la lista y checksum de migraciones. 74 archivos; manifiesto SHA-256 `67a5b72c0fcb27c59857a6c47dd93499908d6440812a7e099a5bc00a83674162`.

- [x] Registrar las versiones de Node, pnpm, Supabase CLI, Wrangler y Playwright. Node `v20.19.3`, pnpm `10.13.1`, Supabase CLI `2.115.0`, Wrangler `4.86.0`, Playwright `1.60.0`.

- [x] Registrar la fecha de compatibilidad Cloudflare. `2026-05-03`.

- [ ] Registrar el plan real de Cloudflare y los límites aplicables.

- [x] Construir una sola vez el artefacto candidato. `pnpm build:cloudflare` terminó correctamente; SHA del Worker local construido `cf4056f946ba2822fb93035da445ea2b74c918e9bbbb7d646dffcc8db657d484`.

- [x] Subirlo como versión Cloudflare con tag o mensaje que contenga el SHA. Versión `9ed2e958-697c-46b6-90ea-5b3bd01c9adf`, tag `prelaunch-7c25b12`, mensaje con `source commit 7c25b12` y Worker SHA `cf4056f946ba2822fb93035da445ea2b74c918e9bbbb7d646dffcc8db657d484`.

- [x] Mantenerlo inicialmente en 0% de tráfico. La candidata se probó al 0% contra la versión anterior al 100% antes de la promoción controlada.

- [x] Registrar un manifiesto de nombres esperados de bindings y funciones habilitadas. Se comparó con la vista de versión Cloudflare; sólo se registraron nombres, nunca valores.

### 2. Validación local secuencial

Ejecutar, en este orden y con la PC sin otras cargas pesadas:

- [x] pnpm install --frozen-lockfile. Lockfile al día; pnpm informó scripts de build ignorados para `esbuild`, `sharp` y `workerd` por la política del runner (riesgo residual).

- [x] pnpm check. `svelte-check found 0 errors and 0 warnings`; shared TypeScript correcto.

- [x] pnpm --filter web exec vitest run --maxWorkers=1. 105 archivos, 810 tests passed.

- [x] pnpm --filter web run test:client -- --maxWorkers=1. 7 archivos, 71 tests passed.

- [x] pnpm supabase:start. Stack local arrancado explícitamente; `DB_URL`/`API_URL` reportados por el CLI y contenedores disponibles.

- [x] pnpm supabase:db:reset. El primer intento quedó bloqueado por una etiqueta de imagen de Storage no disponible; se fijó el cache local a la imagen disponible y el segundo reset aplicó las 74 migraciones y seed correctamente.

- [x] pnpm exec supabase test db. La ejecución literal contra el stack local terminó con 18 archivos/tests de pgTAP pasados (también se había confirmado antes con `--local`).

- [x] pnpm build:cloudflare. SSR/client y adapter Cloudflare terminaron correctamente (`built in 28.96s`).

- [x] pnpm --filter web exec wrangler deploy --dry-run. 112 assets leídos; 3942 KiB total, 805.97 KiB gzip; binding `ASSETS` presente.

- [x] pnpm audit --prod --audit-level=high. Sin vulnerabilidades conocidas de producción.

- [x] pnpm audit --audit-level=high. La repetición posterior a la remediación de transitivas terminó con `No known vulnerabilities found`; la corrida histórica fallida queda conservada en el registro anterior.

- [x] Ejecutar, uno por uno, los scripts de concurrencia de `supabase/tests`. Pasaron seis scripts: asociación por email, límite clínico de uploads, consistencia de exportación, lock global de exportación, idempotencia de identidad/paciente y cupo de reserva pública; además se ejecutó resolución pública de pacientes.

- [x] Confirmar que no se usó `source .env`. Las variables se cargaron mediante parser efímero/CLI y nunca se imprimieron secretos.

- [ ] Crear y ejecutar pruebas dentro del runtime Workers además de los Vitest actuales. No existe `createTestHarness()` ni integración Vitest de Workers en este repo; se ejecutó una prueba independiente contra el Worker productivo real para radiografías, pero no sustituye este harness.

### 3. Base de datos y recuperación

Antes de cualquier E2E:

- [ ] Comparar migraciones locales, staging y producción.

- [x] Ejecutar los 17 pgTAP actuales. La suite actual reportó 18 archivos/tests y todos pasaron.

- [x] Ejecutar concurrencia de asociación por email. Script secuencial pasó con exactamente una invitación pendiente.

- [x] Ejecutar concurrencia de identidad de pacientes. Script pasó con un paciente/turno e idempotencia en replay.

- [x] Ejecutar concurrencia de cupo de reserva pública. Script pasó con una creación y 4/4 rechazos.

- [x] Ejecutar concurrencia de límite de uploads. Script pasó con máximo atómico de 3 pendientes.

- [ ] Hacer un backup completo de datos, autenticación necesaria, metadata y Storage.

- [ ] Restaurarlo en otro proyecto aislado.

- [ ] Comparar conteos por tabla, relaciones, tokens, roles, hashes y checksums de radiografías.

- [ ] Abrir desde la aplicación restaurada una ficha.

- [ ] Abrir desde la aplicación restaurada una entrada clínica.

- [ ] Abrir desde la aplicación restaurada un turno.

- [ ] Abrir desde la aplicación restaurada una radiografía.

- [ ] Medir RPO y RTO reales.

- [ ] Confirmar que el backup es restaurable. Sin restauración demostrada, el producto no debe lanzarse. El texto legal que diga que no hay recuperación garantizada no sustituye una estrategia operativa en un sistema sanitario.

### 4. Staging idéntico a producción

Staging debe usar:

- [ ] Adaptador Cloudflare, no Vite preview.

- [ ] Misma fecha de compatibilidad.

- [ ] Mismos flags.

- [ ] Mismo placement.

- [ ] Mismas rutas.

- [ ] Mismos headers.

- [ ] Misma caché.

- [ ] Mismo plan de Worker.

- [ ] Proyecto Supabase separado pero con el mismo esquema y políticas.

- [ ] Sandboxes reales de proveedores.

- [ ] Dominio HTTPS.

- [ ] Workers Logs habilitados al 100% durante la certificación.

- [ ] Ejecutar toda la matriz funcional en Chromium con retries=0.

- [ ] Ejecutar toda la matriz funcional en Firefox con retries=0.

- [ ] Ejecutar toda la matriz funcional en WebKit con retries=0.

- [ ] Usar los reintentos sólo después para diagnosticar; no convierten un resultado en aprobado.

## Matriz funcional exhaustiva

### A. Autenticación, registro y sesión

- [ ] Redirección correcta de anónimo para cada ruta privada y endpoint directo.

- [x] Login válido. E2E Cloudflare con `E2E_EMAIL`/`E2E_PASSWORD` pasó el flujo base de login y navegación; no se imprimieron credenciales.

- [ ] Login con email con mayúsculas y espacios.

- [ ] Login con contraseña inválida.

- [ ] Login con campos vacíos.

- [ ] Login con usuario inexistente.

- [ ] Login con Supabase Auth caído.

- [ ] Rate limit verdadero de login: debe bloquear y explicar humanamente cuándo intentar otra vez.

- [ ] Caída interna del verificador de rate limit: login debe seguir la política fail-open actual sin confundirla con un límite real.

- [ ] Registro válido.

- [ ] Registro con contraseña débil.

- [ ] Registro con confirmación distinta.

- [ ] Registro con términos no aceptados.

- [ ] Registro de cuenta existente.

- [ ] Registro con doble envío.

- [ ] Google login. En Cloudflare sólo se verificó el inicio de OAuth hasta `accounts.google.com`; el retorno final a Cloudflare queda pendiente de credenciales Google reales.

- [ ] Google registro. En Cloudflare sólo se verificó el inicio de OAuth con términos aceptados; no se completó una cuenta real porque no hay credenciales Google autorizadas.

- [ ] Google registro con aceptación de términos.

- [ ] Google registro sin aceptación de términos.

- [ ] Cancelación del usuario durante OAuth.

- [ ] Callback OAuth sin código.

- [ ] Código OAuth vencido.

- [ ] State OAuth inválido.

- [ ] PKCE correcto.

- [ ] Popup o navegador bloqueado por Google.

- [ ] URL de retorno correcta.

- [ ] Prevención de open redirect en todos los callbacks.

- [ ] Recuperación de contraseña sin revelar si un email existe.

- [ ] Enlace de recuperación válido.

- [ ] Enlace de recuperación vencido.

- [ ] Enlace de recuperación reutilizado.

- [ ] Cambio de contraseña concurrente.

- [ ] Sesión expirada al navegar.

- [ ] Sesión expirada en mitad de cada mutación crítica.

- [ ] Refresh de token en Cloudflare.

- [ ] Sesión en varias pestañas.

- [ ] Logout en una pestaña reflejado en las demás.

- [ ] Revocación remota.

- [ ] Sesiones cerradas por maestro.

- [ ] Cookies Secure.

- [ ] Cookies HttpOnly.

- [ ] Cookies SameSite.

- [ ] Dominio de cookies.

- [ ] Path de cookies.

- [ ] Caducidad de cookies.

- [ ] Ausencia de tokens en URLs.

- [ ] Logout por GET: comprobar que prefetch no cierre una sesión accidentalmente.

- [ ] Logout por GET: comprobar que un crawler no cierre una sesión accidentalmente.

- [ ] Logout por GET: comprobar que una imagen externa no cierre una sesión accidentalmente.

- [ ] Logout por GET: comprobar que una navegación cross-site no cierre una sesión accidentalmente.

- [ ] Primera sesión creando consultorio con dos pestañas simultáneas: nunca deben aparecer dos consultorios.

- [ ] Primera sesión creando consultorio con respuesta perdida después del commit: relectura correcta y sin duplicado.

- [ ] Primera sesión creando consultorio con caída del rate limiter: estado humano y política correcta.

- [ ] Usuario sin membresía.

- [ ] Usuario con una membresía.

- [ ] Usuario con varias membresías.

- [ ] Usuario cuya membresía activa fue eliminada.

### B. Multi-tenant, roles y asistencia

Para cada ruta, acción de formulario, endpoint y RPC, ejecutar toda la matriz siguiente:

- [ ] Anónimo por UI.

- [ ] Anónimo pegando la URL.

- [ ] Anónimo con request HTTP fabricado.

- [ ] Owner por UI.

- [ ] Owner pegando la URL.

- [ ] Owner con request HTTP fabricado.

- [ ] Admin por UI.

- [ ] Admin pegando la URL.

- [ ] Admin con request HTTP fabricado.

- [ ] Recepción por UI.

- [ ] Recepción pegando la URL.

- [ ] Recepción con request HTTP fabricado.

- [ ] Profesional vinculado por UI.

- [ ] Profesional vinculado pegando la URL.

- [ ] Profesional vinculado con request HTTP fabricado.

- [ ] Profesional no vinculado por UI.

- [ ] Profesional no vinculado pegando la URL.

- [ ] Profesional no vinculado con request HTTP fabricado.

- [ ] Readonly por UI.

- [ ] Readonly pegando la URL.

- [ ] Readonly con request HTTP fabricado.

- [ ] Maestro normal por UI.

- [ ] Maestro normal pegando la URL.

- [ ] Maestro normal con request HTTP fabricado.

- [ ] Maestro asistiendo temporalmente por UI.

- [ ] Maestro asistiendo temporalmente pegando la URL.

- [ ] Maestro asistiendo temporalmente con request HTTP fabricado.

Para cada identidad anterior:

- [ ] Usar un ID de otro consultorio.

- [ ] Usar una cookie de consultorio manipulada.

- [ ] Usar un cursor de paginación de otro usuario.

- [ ] Usar un cursor de paginación de otro tenant.

- [ ] Eliminar el registro entre carga y mutación.

- [ ] Archivar el registro entre carga y mutación.

Casos particulares:

- [ ] Recepción no debe descubrir imágenes clínicas.

- [ ] Profesional sólo accede a pacientes vinculados.

- [ ] Profesional no ve costos.

- [ ] Readonly no muta.

- [ ] Readonly no participa en seguimientos.

- [ ] Asistencia dura únicamente lo configurado.

- [ ] Asistencia expira.

- [ ] Asistencia puede revocarse inmediatamente.

- [ ] Asistencia no habilita suscripciones.

- [ ] El maestro no adquiere acceso clínico por conocer un ID.

- [ ] /administrativo permanece inaccesible para anónimo.

- [ ] /administrativo permanece inaccesible para owner.

- [ ] /administrativo permanece inaccesible para admin.

- [ ] /administrativo permanece inaccesible para recepción.

- [ ] /administrativo permanece inaccesible para profesional.

- [ ] /administrativo permanece inaccesible para readonly.

- [ ] /administrativo permanece inaccesible para maestro.

- [ ] Las acciones antiguas de /administrativo permanecen inaccesibles mediante POST directo para todos los roles.

### C. Acceso comercial y suscripción

- [ ] Transición activo → próximo a vencer.

- [ ] Transición próximo a vencer → gracia.

- [ ] Transición gracia → restringido.

- [ ] Transición restringido → archivado.

- [ ] Límites temporales exactos en cada transición.

- [ ] Pausa manual.

- [ ] Acceso permanente.

- [ ] Reactivación.

- [ ] Callback atrasado.

- [ ] Webhook atrasado.

En estado restringido:

- [ ] Conservar lectura permitida de pacientes existentes e historial.

- [ ] Permitir sólo las mutaciones clínicas explícitamente autorizadas.

- [ ] Bloquear nuevos pacientes.

- [ ] Bloquear nuevos turnos.

- [ ] Bloquear reservas públicas.

- [ ] Bloquear configuraciones no permitidas.

- [ ] Mostrar una explicación humana.

- [ ] Mostrar una salida válida.

- [ ] No borrar datos.

- [ ] No ocultar permanentemente datos.

En estado archivado:

- [ ] No exponer información clínica.

- [ ] No permitir acceso por endpoint directo.

- [ ] Conservar posibilidad administrativa de recuperación según contrato.

### D. Mercado Pago

Probar en sandbox:

- [ ] Owner permitido.

- [ ] Admin permitido.

- [ ] Recepción rechazada.

- [ ] Profesional rechazado.

- [ ] Readonly rechazado.

- [ ] Asistencia rechazada.

- [ ] Inicio de suscripción.

- [ ] Doble clic al iniciar suscripción.

- [ ] Dos pestañas iniciando suscripción.

- [ ] Reutilización de pending reciente.

- [ ] Cancelación de pending viejo.

- [ ] Varios pending: todos deben quedar neutralizados antes de generar otro checkout.

- [ ] Active impidiendo nueva autorización.

- [ ] Paused impidiendo nueva autorización.

- [ ] Retorno antes del webhook.

- [ ] Webhook antes del retorno.

- [ ] Retorno y webhook simultáneos.

- [ ] Webhook repetido.

- [ ] Webhook fuera de orden.

- [ ] Webhook con la respuesta del cliente perdida.

- [ ] Firma ausente.

- [ ] Firma inválida.

- [ ] Firma antigua.

- [ ] Request ID distinto.

- [ ] data.id manipulado.

- [ ] API de Mercado Pago con timeout.

- [ ] API de Mercado Pago con 401.

- [ ] API de Mercado Pago con 404.

- [ ] API de Mercado Pago con 429.

- [ ] API de Mercado Pago con 5xx.

- [ ] Pago autorizado.

- [ ] Pago rechazado.

- [ ] Suscripción pausada.

- [ ] Suscripción cancelada.

- [ ] Refund.

- [ ] Chargeback.

- [ ] Ledger idempotente: un pago concede crédito una sola vez.

- [ ] Reconciliación detectando estado perdido.

- [ ] Reconciliación detectando dos suscripciones activas.

- [ ] Reconciliación con negocio inexistente.

- [ ] Cancelación manteniendo el crédito ya pagado cuando corresponda.

- [ ] Kill-switch manual con prioridad sobre la automatización.

En producción:

- [ ] Realizar una única suscripción real controlada de importe mínimo.

- [ ] Comprobar su webhook.

- [ ] Comprobar el crédito concedido.

- [ ] Comprobar su cancelación.

- [ ] Comprobar su conciliación.

- [ ] Confirmar supervisión humana y rollback comercial preparado.

- [ ] Ejecutar la checklist oficial de calidad de Mercado Pago antes del GO. Esta revisión no quedó ejecutada al elaborar el plan por indisponibilidad del conector.

### E. Negocio, equipo, profesionales y disponibilidad

- [ ] Nombre de negocio válido.

- [ ] Nombre vacío.

- [ ] Nombre largo.

- [ ] Nombre con Unicode.

- [ ] Nombre con HTML.

- [ ] Slug válido.

- [ ] Slug vacío.

- [ ] Slug largo.

- [ ] Slug con Unicode.

- [ ] Slug con HTML.

- [ ] Industria válida e inválida.

- [ ] Dirección válida, vacía, larga, Unicode y HTML.

- [ ] Zona horaria válida e inválida.

- [ ] Logo HTTPS válido.

- [ ] Logo con javascript:.

- [ ] Logo con data:.

- [ ] Logo con HTTP.

- [ ] Logo con host no permitido o peligroso.

- [ ] Google Maps HTTPS válido.

- [ ] Google Maps con javascript:.

- [ ] Google Maps con data:.

- [ ] Google Maps con HTTP.

- [ ] Google Maps con host no permitido.

- [ ] Slug duplicado.

- [ ] Modificación concurrente del slug.

- [ ] Comportamiento de enlaces públicos anteriores después de cambiar slug.

- [ ] Flag de reserva pública.

- [ ] Flag de misma jornada.

- [ ] Anticipación mínima.

- [ ] Horizonte máximo.

- [ ] Política de cancelación.

- [ ] Añadir usuario existente.

- [ ] Añadir usuario pendiente.

- [ ] Dos invitaciones simultáneas para el mismo email.

- [ ] Email ya asociado a otro consultorio.

- [ ] Alta de profesional pendiente.

- [ ] Vinculación posterior sin duplicar perfil.

- [ ] Cambios entre todos los roles.

- [ ] Impedir eliminarse a sí mismo.

- [ ] Impedir eliminar al último owner.

- [ ] Revocar acceso inmediatamente.

- [ ] Revocar sesión inmediatamente.

- [ ] Crear perfil atendible para owner.

- [ ] Crear perfil atendible para admin.

- [ ] Servicios por defecto.

- [ ] Servicios personalizados.

- [ ] Duración mínima de 5 minutos.

- [ ] Duración máxima de 480 minutos.

- [ ] Duración fuera de rango.

- [ ] Buffer mínimo de 0.

- [ ] Buffer máximo de 480.

- [ ] Combinaciones de duración y buffers imposibles.

- [ ] Servicio archivado sin historia.

- [ ] Servicio archivado con historia.

- [ ] Asignación de servicios.

- [ ] Desasignación de servicios.

- [ ] Horario semanal vacío.

- [ ] Horario semanal completo.

- [ ] Horario semanal partido.

- [ ] Horarios adyacentes.

- [ ] Horarios solapados.

- [ ] Horario cruzando medianoche.

- [ ] Excepción de un día.

- [ ] Excepción de rango.

- [ ] Excepción de profesional.

- [ ] Excepción de consultorio completo.

- [ ] Dos administradores guardando simultáneamente.

- [ ] Borrador sin guardar.

- [ ] Borrador y refresh.

- [ ] Borrador y back.

- [ ] Borrador y cierre de pestaña.

- [ ] Borrador y cambio de profesional.

- [ ] Archivar profesional sin dependencias históricas.

- [ ] Archivar profesional con dependencias históricas.

- [ ] Restaurar profesional.

- [ ] Eliminar profesional sin dependencias históricas.

- [ ] Impedir eliminar profesional con dependencias históricas.

### F. Agenda, creación y gestión de turnos

- [ ] Vista diaria.

- [ ] Vista semanal.

- [ ] Navegar a Hoy.

- [ ] Navegar al día anterior.

- [ ] Navegar al día siguiente.

- [ ] Aplicar filtros.

- [ ] Buscar.

- [ ] Preservar query params.

- [ ] Zona horaria del consultorio distinta a la del dispositivo.

- [ ] Medianoche.

- [ ] Fin de mes.

- [ ] Fin de año.

- [ ] Año bisiesto.

- [ ] Cambio de horario de verano aunque Argentina no lo use.

- [x] Búsqueda incremental por nombre. La prueba UX de pacientes respondió al primer carácter y la prueba real de la cuenta confirmó render local inmediato.

- [ ] Búsqueda incremental con acentos.

- [x] Búsqueda incremental por teléfono. La matriz UX cubrió búsqueda/selección de fichas que comparten teléfono y conservó el ID elegido.

- [ ] Búsqueda con un carácter. La prueba clínica local observó 1 request para un carácter donde el test exige 0; aunque la UI muestra resultados, el contrato no está resuelto y este punto bloquea la aprobación.

- [x] Búsqueda con dos caracteres. La búsqueda de pacientes UX ejecutada con credenciales de prueba mantuvo resultados y contexto de navegación.

- [ ] Búsqueda con espacios.

- [ ] Búsqueda con texto pegado.

- [ ] Búsqueda durante composición del teclado móvil.

- [ ] Resultado local precargado frente a reconciliación del servidor.

- [ ] Turnos pasados dentro de los tres meses visibles.

- [ ] Turnos pasados fuera de los tres meses visibles.

- [ ] Límite de futuros activos.

Creación interna:

- [ ] Crear turno con paciente existente.

- [ ] Crear turno con paciente nuevo.

- [ ] Selección explícita entre pacientes duplicados.

- [ ] Crear turno sin teléfono.

- [ ] Crear turno con teléfono inválido.

- [ ] Corregir teléfono dentro del formulario.

- [ ] Aceptar continuar sin teléfono una única vez.

- [ ] Persistir la decisión de continuar sin teléfono.

- [ ] Turno individual.

- [ ] Turno conjunto.

- [ ] Profesionales repetidos.

- [ ] Profesionales incompatibles.

- [ ] Servicio no asignado.

- [ ] Servicio archivado.

- [ ] Servicio modificado mientras el formulario estaba abierto.

- [ ] Horario regular.

- [ ] Horario dentro de una pausa.

- [ ] Efecto de buffers.

- [ ] Horario dentro de una excepción.

- [ ] Aviso mínimo.

- [ ] Horizonte máximo.

- [ ] Turno exactamente adyacente.

- [ ] Turno realmente solapado.

- [ ] Dos recepcionistas tomando el mismo horario: sólo una debe ganar.

- [ ] Doble clic al crear turno.

- [ ] Back después de crear turno.

- [ ] Refresh durante la creación.

- [ ] Reenvío del mismo idempotency key.

- [ ] Pérdida de respuesta después del commit: relectura y navegación al turno ya creado, nunca duplicación.

Estados:

- [ ] Estado reserved.

- [ ] Estado confirmed.

- [ ] Estado cancelled.

- [ ] Estado reschedule_requested.

- [ ] Estado expirado derivado por hora.

- [ ] Sólo el paciente puede confirmar.

- [ ] Cancelado es terminal.

- [ ] Turno pasado no ofrece acciones inválidas.

- [ ] Motivo de cancelación auditado.

- [ ] Actor de cancelación auditado.

- [ ] Reprogramación conserva profesional.

- [ ] Reprogramación conserva servicio.

- [ ] Reprogramación conserva paciente.

- [ ] Reprogramación conserva contexto de agenda.

- [ ] Actualización correcta del evento Google.

- [ ] Borrado correcto del evento Google.

- [ ] Recreación correcta del evento Google.

### G. Reserva pública

- [ ] Slug inexistente.

- [ ] Consultorio con reserva deshabilitada.

- [ ] Consultorio restringido.

- [ ] Consultorio archivado.

- [x] Todos los pasos de reserva individual. En Cloudflare se recorrieron servicio → profesional → día → horario → datos → confirmación con una reserva sintética; POST de creación respondió 200 y la pantalla mostró el turno reservado.

- [ ] Todos los pasos de reserva conjunta.

- [ ] Browser back.

- [ ] Browser forward.

- [ ] Refresh durante la reserva.

- [ ] Slot que queda obsoleto mientras el usuario completa datos.

- [ ] Nombre con acentos.

- [ ] Nombre con espacios.

- [ ] Nombre con mayúsculas.

- [ ] Nombre con apóstrofes.

- [ ] Nombre con ñ.

- [ ] Reutilización únicamente de paciente activo con coincidencia exacta y no ambigua.

- [ ] Igual teléfono con nombres diferentes.

- [ ] Igual nombre con teléfonos diferentes.

- [ ] Paciente archivado.

- [ ] Paciente bloqueado.

- [x] Límite de cuatro turnos futuros considerando paciente resuelto y bucket antiabuso. La prueba de concurrencia de reserva pública pasó con el cupo exacto (una creación y 4/4 rechazos).

- [ ] Reintento idéntico antes del rate limit.

- [ ] Reintento idéntico después del rate limit.

- [x] Dos requests concurrentes al último cupo. La prueba de concurrencia de reserva pública pasó sin doble reserva.

- [ ] Cincuenta requests al mismo slot: exactamente un turno, sin pacientes huérfanos.

- [ ] IP real de Cloudflare.

- [ ] IPv6.

- [ ] NAT compartido.

- [ ] Headers de IP falsificados.

- [ ] Turnstile habilitado.

- [ ] Turnstile deshabilitado.

- [ ] Token Turnstile vencido.

- [ ] Token Turnstile duplicado.

- [ ] Error del servicio Turnstile.

- [ ] Claves Turnstile configuradas a medias.

- [ ] Hora del consultorio.

- [ ] Aviso mínimo.

- [ ] Misma jornada.

- [ ] Máximo de días.

- [ ] Si el slot desapareció, volver a disponibilidad conservando datos seguros y mostrando un resultado claro.

### H. Pacientes e identidad

- [ ] Alta válida.

- [ ] Cada validación individual del alta.

- [ ] DNI único dentro del tenant.

- [ ] El mismo DNI permitido en otro tenant.

- [ ] Nombre duplicado sin combinar fichas indebidamente.

- [ ] Teléfono duplicado sin combinar fichas indebidamente.

- [x] Buscar por primer carácter. La auditoría UX de pacientes comprobó resultado visible en menos de 500 ms de render local.

- [ ] Buscar con acento.

- [x] Buscar por teléfono parcial. Las pruebas de pacientes/turnos cubrieron teléfonos compartidos y selección inequívoca del paciente.

- [ ] Buscar con texto pegado.

- [ ] Paginación adelante.

- [ ] Paginación atrás.

- [ ] Cursor manipulado.

- [ ] Cursor vencido.

- [ ] Cursor de otra query.

- [ ] Cursor de otro tenant.

- [ ] Caché separada por usuario.

- [ ] Caché separada por tenant.

- [ ] Caché separada por rol.

- [ ] Caché separada por tab.

- [ ] Caché separada por consulta.

- [ ] Realtime actualizando sólo lo permitido.

- [ ] Dos pestañas editando la misma ficha.

- [ ] Edición de datos.

- [ ] Edición de perfil clínico.

- [ ] Edición de alergias.

- [ ] Edición de medicamentos.

- [ ] Edición de antecedentes.

- [ ] Edición de campos personalizados.

- [ ] HTML o XSS almacenado en cada campo libre.

- [ ] Preservación explícita de ?tab=datos.

- [ ] Preservación explícita de ?tab=historial.

- [ ] Auditoría de cambios con actor correcto.

- [ ] Auditoría de cambios con campo correcto.

- [ ] Auditoría de cambios con fecha correcta.

- [ ] Archivo global por manager.

- [ ] Archivo personal de profesional.

- [ ] Restauración.

- [ ] Eliminación denegada cuando existen dependencias.

- [ ] Reasignación de paciente invalida token viejo.

- [ ] Reasignación de paciente supersede mensajes.

- [ ] Reasignación de paciente supersede push.

- [ ] Reasignación de paciente supersede calendario.

- [ ] Reasignación de paciente deja auditoría exacta.

### I. Historia clínica

Probar cada tipo:

- [ ] Consulta.

- [ ] Diagnóstico.

- [ ] Tratamiento.

- [ ] Procedimiento.

- [ ] Evolución.

- [ ] Indicaciones.

- [ ] Nota interna.

Para cada tipo anterior:

- [ ] Descripción vacía.

- [ ] Descripción mínima.

- [ ] Descripción máxima.

- [ ] Descripción con Unicode.

- [ ] Descripción con contenido malicioso.

- [ ] Fecha pasada.

- [ ] Fecha de hoy.

- [ ] Fecha futura.

- [ ] Fecha inválida.

- [ ] Piezas dentales.

- [ ] Nota interna.

- [ ] Monto cero.

- [ ] Monto negativo.

- [ ] Monto decimal extremo.

- [ ] Monto con separador local.

- [ ] Visibilidad del costo por cada rol.

- [ ] Guardado exitoso.

- [ ] Relectura independiente.

- [ ] Doble clic.

- [ ] Timeout.

- [ ] Refresh.

- [ ] Navegación estancada.

- [ ] Exactamente una entrada después de perder la respuesta.

- [ ] Edición antes de locked_after.

- [ ] Edición después de locked_after.

- [ ] Dos profesionales editando simultáneamente.

- [ ] Paginación mayor a 30.

- [ ] Paciente archivado mientras el formulario está abierto.

- [ ] Paciente desvinculado mientras el formulario está abierto.

- [ ] Estado de error humano.

- [ ] Conservación del texto después del error.

- [ ] Acción clara para reintentar.

- [ ] Invariante crítica: nunca mostrar “guardado” antes de verificar persistencia.

### J. Radiografías y archivos clínicos

- [ ] Permiso de ver por cada rol y estado comercial.

- [ ] Permiso de subir por cada rol y estado comercial.

- [ ] Permiso de abrir original por cada rol y estado comercial.

- [ ] Permiso de acceder a papelera por cada rol y estado comercial.

- [ ] Permiso de restaurar por cada rol y estado comercial.

- [ ] JPG real.

- [x] PNG real. Upload de PNG sintético completó el flujo de radiografía en el Worker productivo.

- [ ] Extensión correcta con bytes falsos.

- [ ] MIME correcto con magic bytes falsos.

- [ ] Archivo polyglot.

- [ ] Archivo truncado.

- [ ] Decompression bomb.

- [ ] Metadatos enormes.

- [ ] Archivo de 1 byte.

- [ ] Archivo de 25 MiB exactos.

- [ ] Archivo de 25 MiB + 1.

- [ ] Nombre con Unicode.

- [ ] Nombre con path traversal.

- [ ] Nombre con barras.

- [ ] Nombre con longitud máxima.

- [ ] Fecha válida.

- [ ] Fecha inválida.

- [ ] Nota válida.

- [ ] Nota inválida.

- [ ] Generación del thumbnail.

- [ ] Tamaño del thumbnail.

- [ ] Interrupción antes del PUT.

- [ ] Interrupción durante el upload del original.

- [ ] Interrupción durante el upload del thumbnail.

- [ ] Interrupción antes de /complete.

- [ ] URL firmada vencida.

- [ ] URL firmada reutilizada.

- [ ] upsert=false: jamás sobrescribir otra imagen.

- [ ] Tres uploads pendientes.

- [ ] Dos requests intentando el cuarto upload simultáneamente.

- [x] Storage devolviendo 200. La subida y descarga firmada de la imagen sintética respondieron 200 en Cloudflare.

- [ ] Storage devolviendo 206.

- [ ] Storage devolviendo 302.

- [ ] Storage devolviendo 403.

- [ ] Storage devolviendo 404.

- [ ] Storage con timeout.

- [ ] Storage con cuerpo inesperado.

- [ ] Validación Range dentro del Worker real.

- [x] Validación de magic bytes dentro del Worker real. La prueba del Worker descargó y validó el PNG sintético antes de dejarlo `ready/ok`.

- [x] Validación de tamaño dentro del Worker real. La imagen sintética fue aceptada dentro del límite y quedó persistida como `ready/ok`.

- [x] Validación de checksum dentro del Worker real. La relectura independiente de la radiografía sintética reportó integridad `ok`.

- [x] Estado uploading → ready. `/complete` respondió 200 y la fila final quedó `ready`.

- [ ] Estado uploading → failed.

- [ ] Ausencia de uploads eternamente pendientes.

- [x] Apertura del original sólo después de acción explícita; nunca preload automático. La prueba productiva abrió el original mediante acción explícita y recibió un `blob:` sin exponer la URL firmada en la imagen.

- [ ] Thumbnail precargado sin bloquear la ficha.

- [ ] Cambio de paciente revoca blob URLs y aborta requests.

- [ ] Cambio de consultorio revoca blob URLs y aborta requests.

- [ ] Cambio de usuario revoca blob URLs y aborta requests.

- [ ] Logout revoca blob URLs y aborta requests.

- [x] Zoom. El visor privado se probó en desktop con controles y en 390 px con pellizco; el zoom móvil se ejecutó después de esperar el original `blob:` cargado.

- [ ] Pan.

- [ ] Orientación.

- [x] Pantalla pequeña. Visor y ficha probados a 390 × 844 sin overflow horizontal.

- [ ] Memoria después de abrir muchas imágenes.

- [ ] URL original vence a los 60 segundos.

- [ ] URL original no es reutilizable por otro usuario.

- [ ] Trash idempotente.

- [ ] Restore idempotente.

- [ ] Trash rate-limited.

- [ ] Restore rate-limited.

- [x] Trash auditado. La relectura de auditoría registró `radiograph.trashed` con resultado exitoso.

- [x] Restore auditado. La relectura de auditoría registró `radiograph.restored` con resultado exitoso.

- [x] Integridad ok. La fila sintética final quedó `integrity_status=ok`.

- [ ] Integridad missing.

- [ ] Integridad checksum_mismatch.

- [ ] Ejecución comprobada del job SQL de integridad.

- [ ] Backup físico de originales.

- [ ] Backup físico de thumbnails.

- [ ] Restauración física de originales.

- [ ] Restauración física de thumbnails.

### K. Seguimientos y recordatorios

Seguimientos:

- [ ] Roles y alcance de pacientes.

- [ ] Crear seguimiento.

- [ ] Editar seguimiento.

- [ ] Completar seguimiento.

- [ ] Posponer a mañana.

- [ ] Posponer tres días.

- [ ] Posponer una semana.

- [ ] Posponer a fecha propia.

- [ ] Fecha según timezone del consultorio.

- [ ] Mensaje vacío.

- [ ] Mensaje de 500 caracteres.

- [ ] Mensaje de más de 500 caracteres.

- [ ] Profesional asignable.

- [ ] Profesional no asignable.

- [ ] Paciente archivado.

- [ ] Paciente desvinculado.

- [ ] Lista actual.

- [ ] Lista futura.

- [ ] Lista de importantes.

- [ ] Búsqueda.

- [ ] Contadores.

- [ ] Notificación de vencidos.

- [ ] Dismiss del aviso por fingerprint.

- [ ] Reaparición del aviso cuando cambia el conjunto.

- [ ] Modal no se cierra al hacer clic afuera.

- [ ] Modal se cierra con X.

- [ ] Modal se cierra con Escape.

- [ ] Foco atrapado en el modal.

- [ ] Foco restaurado al cerrar el modal.

Recordatorios de turnos:

- [ ] Turnos de hoy.

- [ ] Turnos de mañana.

- [ ] Sólo turnos activos.

- [ ] Sólo turnos futuros.

- [ ] Turno con teléfono.

- [ ] Turno sin teléfono.

- [ ] Turno con cobertura de calendario.

- [ ] Turno sin cobertura de calendario.

- [ ] Turno con cobertura push.

- [ ] Turno sin cobertura push.

- [ ] Turno con dispatch existente.

- [ ] Turno sin dispatch existente.

- [ ] Igualdad exacta entre contador de Agenda y sección Recordatorios.

- [ ] WhatsApp Web en PC.

- [ ] wa.me en Android.

- [ ] wa.me en iOS.

- [ ] Apertura registra whatsapp_reminder_opened_at.

- [ ] ?confirmar=1 evita marcado accidental.

- [ ] Dos empleados intentando marcar enviado simultáneamente.

### L. Portal público del turno, calendario, PDF y mapas

- [x] Token válido. El portal público de un turno sintético en Cloudflare respondió 200 y mostró sólo datos operativos mínimos.

- [ ] Token inexistente.

- [ ] Token rotado.

- [ ] Token vencido.

- [ ] Token de turno pasado.

- [x] Header `no-store`. PDF, ICS y reserva pública sintéticos respondieron con `cache-control: no-store`; el Worker activo candidato tampoco envía `netlify-cdn-cache-control`.

- [ ] Header Referrer-Policy.

- [x] Confirmar. El paciente confirmó desde el portal y la Agenda mostró el estado `Confirmado` en el Worker activo.

- [ ] Cancelar.

- [ ] Solicitar reprogramación.

- [ ] Alias /confirmar.

- [ ] Alias /cancelar.

- [ ] Alias /reprogramar.

- [ ] Consultorio restringido.

- [ ] Turno terminal.

- [ ] Datos visibles mínimos.

- [ ] Ausencia de información clínica.

- [ ] ICS inline.

- [x] ICS descarga. Respondió 200, `text/calendar; charset=utf-8; method=PUBLISH`, `attachment`, `no-store` y 1046 bytes.

- [x] Zona horaria del ICS. La reserva mostró hora local del consultorio y los redirects generaron fechas UTC coherentes con `America/Argentina/Cordoba`.

- [ ] UID estable.

- [ ] Sequence.

- [ ] Cancelación en ICS.

- [ ] Alarma en ICS.

- [ ] Caracteres especiales en ICS.

- [x] Google Calendar en desktop. El endpoint de tracking respondió 302 a `calendar.google.com` con una URL de evento neutral.

- [ ] Google Calendar en Android.

- [ ] Google Calendar en iOS.

- [x] Outlook en desktop. El endpoint de tracking respondió 302 a `outlook.live.com`.

- [ ] Outlook en Android.

- [ ] Outlook en iOS.

- [x] Maps en desktop. El endpoint de tracking respondió 302 a `maps.app.goo.gl`.

- [ ] Maps en Android.

- [ ] Maps en iOS.

- [ ] Intent Android.

- [ ] Fallback del intent Android.

- [ ] Retorno a la página después del intent.

- [x] PDF válido. Respondió 200, `application/pdf`, `attachment`, `no-store` y 1529 bytes con firma `%PDF-1.7`.

- [ ] PDF imprimible.

- [ ] PDF sin información extra.

- [ ] PDF dentro del límite CPU y memoria Worker.

- [x] Crawler no marca calendario ofrecido. La revisión de la página por requests directos no ejecutó acciones; los side effects sólo ocurrieron al crear la reserva sintética mediante POST explícito.

- [x] Crawler no confirma. GET directo del portal no cambió el estado ni generó auditoría de confirmación.

- [x] Crawler no marca apertura. GET directo no abrió el visor ni generó un grant de imagen.

- [ ] Previsualizador social no marca calendario ofrecido.

- [ ] Previsualizador social no confirma.

- [ ] Previsualizador social no marca apertura.

### M. Google Calendar administrado

- [ ] Función deshabilitada: no mostrar CTA roto.

- [ ] Función habilitada con todos los secretos.

- [ ] OAuth aceptado.

- [ ] OAuth rechazado.

- [ ] State inválido.

- [ ] PKCE inválido.

- [ ] Callback duplicado.

- [ ] Refresh token vencido.

- [ ] Tokens cifrados en reposo.

- [ ] Crear evento.

- [ ] Actualizar evento.

- [ ] Borrar evento.

- [ ] Reprogramación mientras Google está caído.

- [ ] Cancelación mientras Google está caído.

- [ ] Cola.

- [ ] Retry.

- [ ] Reconciliación posterior.

- [ ] Evento privado.

- [ ] Evento neutral.

- [ ] Desconexión revocando acceso.

- [ ] Dos callbacks simultáneos.

### N. Push y service worker

Ejecutar en:

- [ ] Chrome Android.

- [ ] Samsung Internet.

- [ ] Chrome en Samsung.

- [ ] Firefox Android.

- [ ] Chrome desktop.

- [ ] Edge desktop.

- [ ] Safari en iPhone.

Casos:

- [ ] Dispositivo soportado.

- [ ] Dispositivo no soportado.

- [ ] En iOS, donde el código no ofrece push, mostrar una alternativa comprensible.

- [ ] Permiso concedido.

- [ ] Permiso rechazado.

- [ ] Permiso bloqueado.

- [ ] Permiso recuperado desde ajustes.

- [ ] Suscripción.

- [ ] Renovación de claves.

- [ ] Dos dispositivos del mismo paciente.

- [ ] Receipt de prueba.

- [ ] Recordatorio de 24 horas.

- [ ] Recordatorio de 2 horas.

- [ ] Reprogramación justo antes del envío.

- [ ] Cancelación justo antes del envío.

- [ ] Dedupe.

- [ ] Ejecución concurrente del job.

- [ ] Respuesta 410 elimina endpoint.

- [ ] Respuesta 429 conserva endpoint y reintenta.

- [ ] Respuesta 5xx conserva endpoint y reintenta.

- [ ] Click con la página cerrada.

- [ ] Click con la página abierta.

- [ ] Click con varias pestañas.

- [ ] Service worker viejo después de deploy.

- [ ] Sin PII sensible en título.

- [ ] Sin PII sensible en body.

- [ ] Sin PII sensible en URL.

- [ ] Sin PII sensible en logs.

### O. Reseñas de Google

- [ ] Configuración habilitada.

- [ ] Configuración deshabilitada.

- [ ] Todos los formatos Google permitidos.

- [ ] URLs de phishing similares.

- [ ] Turno elegible.

- [ ] Turno no elegible.

- [ ] Cooldown por paciente.

- [ ] Claim idempotente bajo concurrencia.

- [ ] Push exitoso.

- [ ] Push 410.

- [ ] Push con timeout.

- [ ] Push con respuesta desconocida.

- [ ] Redirect /r/[token] válido.

- [ ] Redirect /r/[token] usado.

- [ ] Redirect /r/[token] manipulado.

- [ ] Redirect /r/[token] con URL maliciosa almacenada.

- [ ] Click auditado sin revelar datos.

### P. WhatsApp, mensajería y webhooks

- [ ] GET de verificación con token válido.

- [ ] GET de verificación con token inválido.

- [ ] POST con firma válida.

- [ ] POST con firma inválida.

- [ ] POST con firma ausente.

- [ ] Cuerpo malformado.

- [ ] Cuerpo grande.

- [ ] Cuerpo duplicado.

- [ ] Cuerpo fuera de orden.

- [ ] Mensaje de número desconocido.

- [ ] Cuenta o teléfono de otro tenant.

- [ ] API Meta con 401.

- [ ] API Meta con 429.

- [ ] API Meta con 5xx.

- [ ] API Meta con timeout.

- [ ] Idempotencia de dispatch.

- [ ] Mensaje neutral.

- [ ] Enlaces Cloudflare correctos.

- [ ] Función automática deshabilitada: nunca enviar accidentalmente.

- [ ] Función automática habilitada: exigir WHATSAPP_APP_SECRET.

- [ ] Función automática habilitada: exigir access token.

- [ ] Función automática habilitada: exigir estado operativo.

- [ ] Rutas UI antiguas de mensajes no aparentan una función deshabilitada.

- [ ] Rutas UI antiguas de WhatsApp no aparentan una función deshabilitada.

### Q. Jobs internos

Endpoints:

- [ ] generate-reminder-dispatches.

- [ ] process-message-dispatches.

- [ ] send-push-reminders, incluida reseña y calendario.

- [ ] reconcile-mercadopago.

Para cada endpoint:

- [ ] Secret ausente.

- [ ] Secret incorrecto.

- [ ] Secret correcto.

- [ ] Método distinto de POST.

- [ ] Dos ejecuciones simultáneas.

- [ ] Repetición del mismo rango.

- [ ] Fallo parcial de una integración sin abortar las demás.

- [ ] Timeout.

- [ ] Retry.

- [ ] Backlog.

- [ ] Límite de lotes.

- [ ] Continuación del siguiente lote.

- [ ] Filas exactamente una vez.

- [ ] Métrica last_success_at.

- [ ] Métrica de duración.

- [ ] Métrica de procesados.

- [ ] Métrica de fallidos.

- [ ] Métrica de próxima ejecución.

- [ ] Simular una ejecución perdida.

- [ ] Recuperar backlog sin duplicar.

- [ ] Demostrar el scheduler real.

- [ ] Demostrar su cadencia.

- [ ] Demostrar sus últimas tres ejecuciones.

- [ ] Demostrar sus alertas.

La existencia del endpoint no cuenta. Hay que demostrar el scheduler real, su cadencia, sus últimas tres ejecuciones y sus alertas. Cloudflare sólo ejecuta Cron si existe handler scheduled y triggers configurados; los cambios pueden tardar hasta 15 minutos. Referencia: [Cloudflare Cron Triggers](https://developers.cloudflare.com/workers/configuration/cron-triggers/).

## UX clínica y operativa

Esta fase no se automatiza completamente.

### Participantes

- [ ] Realizar la prueba con al menos 5 profesionales odontológicos.

- [ ] Realizar la prueba con al menos 5 personas de recepción o agenda.

- [ ] Realizar la prueba con al menos 5 owners o administradores.

- [ ] Incluir usuarios de distinta edad.

- [ ] Incluir usuarios de distinto nivel digital.

- [ ] Incluir usuarios con uso móvil.

- [ ] Incluir usuarios de distinto tamaño de consultorio.

- [ ] Confirmar que ninguno desarrolló el producto.

### Recorridos moderados obligatorios

- [ ] Abrir la jornada, entender la agenda de hoy y detectar recordatorios pendientes.

- [ ] Atender una llamada, encontrar al paciente correcto entre duplicados y crear un turno.

- [ ] Identificar al próximo paciente y llegar a su ficha sin dudas.

- [ ] Antes de atender, localizar alergias, medicamentos, antecedentes y última evolución.

- [ ] Registrar una entrada clínica ya redactada y verificar que quedó guardada.

- [ ] Abrir una radiografía existente y volver al contexto anterior.

- [ ] Reprogramar un turno y avisar por WhatsApp.

- [ ] Crear un seguimiento posterior a la consulta.

- [ ] Resolver una caída de red o sesión expirada sin perder información ni duplicar acciones.

- [ ] Completar el cierre del día con pendientes y recordatorios.

### Criterios UX de aprobación

- [ ] 100% de éxito sin ayuda al identificar paciente.

- [ ] 100% de éxito sin ayuda al crear o reprogramar turno.

- [ ] 100% de éxito sin ayuda al guardar historia.

- [ ] 100% de éxito sin ayuda al abrir radiografía.

- [ ] Cero selección del paciente equivocado.

- [ ] Cero selección de fecha equivocada.

- [ ] Cero selección de profesional equivocado.

- [ ] Cero selección de consultorio equivocado.

- [ ] Cero éxito falso.

- [ ] Cero duplicación por impaciencia.

- [ ] Abrir al próximo paciente en un máximo de 15 segundos.

- [ ] Encontrar un paciente existente en un máximo de 15 segundos.

- [ ] Crear un turno para paciente existente en un máximo de 90 segundos.

- [ ] Reprogramar y llegar al aviso en un máximo de 60 segundos.

- [ ] Guardar una entrada clínica ya redactada y verificarla en un máximo de 30 segundos.

- [ ] Abrir una radiografía conocida en un máximo de 20 segundos en banda ancha.

- [ ] SEQ mediana mínima de 6/7 en tareas críticas.

- [ ] SUS global mínimo de 80/100.

- [ ] Ningún problema UX crítico abierto.

- [ ] Ningún problema UX alto abierto.

### Auditoría de cada pantalla y estado

Revisar en desktop y móvil:

- [ ] Una única acción primaria dominante por área.

- [ ] Jerarquía visual clara.

- [ ] Orden de lectura claro.

- [ ] Identidad del paciente persistentemente visible durante acciones clínicas.

- [ ] Fecha inequívoca.

- [ ] Hora inequívoca.

- [ ] Timezone inequívoco.

- [ ] Profesional inequívoco.

- [ ] Estado inequívoco.

- [ ] Estados no comunicados sólo por color.

- [ ] Acciones terminales inválidas eliminadas, no simplemente deshabilitadas.

- [ ] Confirmaciones destructivas nombran el paciente o turno afectado.

- [ ] Confirmaciones destructivas explican la consecuencia.

- [ ] Estado loading.

- [ ] Estado vacío.

- [ ] Estado éxito.

- [ ] Estado error.

- [ ] Estado offline.

- [ ] Estado timeout.

- [ ] Estado disabled.

- [ ] Estado permiso insuficiente.

- [ ] Mensajes humanos con el problema exacto.

- [ ] Mensajes humanos con la próxima acción.

- [ ] Mensajes sin nombres de RPC.

- [ ] Mensajes sin UUID.

- [ ] Mensajes sin SQL.

- [ ] Mensajes sin PostgREST.

- [ ] Mensajes sin etiquetas HTTP.

- [ ] Mensajes sin códigos internos.

- [ ] Formularios conservan datos después de error.

- [ ] Foco en el primer error.

- [ ] Resumen de errores accesible.

- [ ] Doble clic bloqueado con feedback real, no sólo spinner infinito.

- [ ] Browser back preserva contexto seguro.

- [ ] Browser forward preserva contexto seguro.

- [ ] Refresh preserva contexto seguro.

- [ ] Modales con foco atrapado.

- [ ] Modales cierran con Escape.

- [ ] Modales cierran con X.

- [ ] Modales restauran foco.

- [ ] Inputs adecuados al teclado móvil.

- [ ] Inputs con autocompletado correcto.

- [ ] Inputs permiten pegado. Los formularios probados aceptaron `fill`/entrada de texto en los campos de reserva, login y búsqueda; el pegado físico en dispositivos reales queda pendiente.

- [ ] Targets táctiles cómodos.

- [ ] Nada cortado a 320 px.

- [ ] Nada cortado a 360 px.

- [ ] Nada cortado a 375 px.

- [x] Nada cortado a 390 px. E2E UX tomó una vista móvil de 390 px y verificó `scrollWidth` sin overflow horizontal en rutas de pacientes/radiografías.

- [ ] Nada cortado a 412 px.

- [ ] Zoom de navegador al 200%.

- [ ] Texto grande.

- [x] Sin scroll horizontal en las rutas móviles cubiertas por E2E; no se generaliza a todas las 171 rutas.

- [ ] Contraste conforme a WCAG 2.2 AA.

- [ ] Navegación por teclado conforme a WCAG 2.2 AA.

- [ ] Lector de pantalla conforme a WCAG 2.2 AA.

- [ ] Mensajes de estado conforme a [WCAG 2.2 AA](https://www.w3.org/TR/WCAG22/).

- [ ] Interrupción por llamada.

- [ ] Interrupción por cambio de pestaña.

- [ ] Interrupción por bloqueo del teléfono.

- [ ] Interrupción por conexión intermitente.

- [ ] Interrupción por reautenticación.

- [ ] Consistencia entre Agenda y Pacientes.

- [ ] Consistencia entre Pacientes y Turnos.

- [ ] Consistencia entre Turnos y Seguimientos.

- [ ] Consistencia entre Seguimientos y Recordatorios.

- [ ] No ocultar latencia con loaders.

- [ ] Medir escritura por separado.

- [ ] Medir recarga por separado.

- [ ] Medir navegación por separado.

## Cloudflare producción

### 1. Identidad del código

El candidato debe desplegarse con:

- [x] SHA Git como tag o mensaje. El mensaje/tag de la versión candidata identifica `source commit 7c25b12` (`prelaunch-7c25b12`); el commit es local y todavía no está publicado en GitHub.

- [x] Version ID registrado. Candidata `9ed2e958-697c-46b6-90ea-5b3bd01c9adf`, número 32, 100 %; rollback `97f5d35f-c20e-4d4e-9ee9-ffa122f2e553`, número 28, 0 %. Deployment `d9bc2787-544b-4863-8472-5276da97fe9b`.

- [x] Checksums del artefacto. Se registraron SHA-256 del artefacto Worker local, lockfile, configuración Wrangler y manifiesto de migraciones.

- [x] Lista de migraciones. 74 archivos y manifiesto SHA-256 `67a5b72c0fcb27c59857a6c47dd93499908d6440812a7e099a5bc00a83674162`.

- [ ] Binding opcional de metadata de versión o header de diagnóstico no sensible.

- [x] Usar una versión al 0% y el header oficial Cloudflare-Workers-Version-Overrides para dirigir Playwright al candidato sin exponer usuarios. Se dirigió Playwright a `9ed2e958-697c-46b6-90ea-5b3bd01c9adf` con `app="..."` mientras estaba al 0 %, antes de promoverlo. Referencia: [Version overrides](https://developers.cloudflare.com/workers/versions-and-deployments/version-overrides/).

- [ ] Probar mezcla de versiones. Cloudflare advierte que requests consecutivos pueden llegar a versiones diferentes durante despliegues graduales. Referencia: [Gradual deployments](https://developers.cloudflare.com/workers/versions-and-deployments/gradual-deployments/).

### 2. Bindings y dominio

Comprobar mediante comportamiento, sin imprimir valores:

- [x] Todas las claves Supabase apuntan al proyecto correcto. Preflight remoto consultó el proyecto `yjzferwuzbtgpmdnzlcb`; OAuth y reservas Cloudflare usaron ese mismo proyecto.

- [x] PUBLIC_SITE_URL es el dominio Cloudflare final en los enlaces observados. La reserva, portal, ICS/redirects y PDF se probaron en `app.cita-suite.workers.dev`; el valor secreto del binding no se imprimió.

- [x] DEMO_MODE no es true. El Worker mostró el negocio y catálogo productivos de prueba; las pruebas condicionadas a demo quedaron correctamente omitidas.

- [ ] Callback Supabase usa el dominio Cloudflare.

- [ ] Callback de reset usa el dominio Cloudflare.

- [ ] Callback de Google usa el dominio Cloudflare.

- [ ] Retorno de Mercado Pago usa el dominio Cloudflare.

- [ ] Webhook de Mercado Pago usa el dominio Cloudflare.

- [ ] Webhook de WhatsApp usa el dominio Cloudflare.

- [ ] ICS contiene el dominio Cloudflare cuando corresponde. El portal/redirects generados durante la reserva sintética conservaron el host Cloudflare, pero el cuerpo del ICS no se conservó antes del cleanup para verificarlo de forma independiente.

- [ ] PDF contiene el dominio Cloudflare cuando corresponde.

- [ ] WhatsApp contiene el dominio Cloudflare.

- [ ] Push contiene el dominio Cloudflare.

- [ ] Reseñas contienen el dominio Cloudflare.

- [x] Ningún link nuevo contiene netlify.app. Crawl autenticado y smokes de reserva/login activos no encontraron el host histórico.

- [x] Ningún link nuevo contiene Vercel. Crawl autenticado y smokes de reserva/login activos no encontraron el host histórico.

- [x] Ningún link nuevo contiene localhost. Crawl autenticado de diez rutas válidas no encontró `localhost` ni `127.0.0.1`.

- [x] Ningún link nuevo contiene `workers.dev` si no es el dominio público elegido. El dominio elegido y probado es `app.cita-suite.workers.dev`.

- [x] Un deploy posterior mantiene todos los bindings por keep_vars. La publicación de la candidata conservó los 28 bindings esperados y `PUBLIC_SITE_URL` quedó explícito en la vista de versión.

- [ ] Cada función opcional aparece habilitada o explícitamente deshabilitada.

### 3. Observabilidad

- [ ] Declarar observabilidad explícitamente en Wrangler.

- [ ] Habilitar sampling 100% durante la ventana. Workers Logs registra invocaciones, errores y excepciones cuando observabilidad está habilitada. Referencia: [Workers Logs](https://developers.cloudflare.com/workers/observability/logs/workers-logs/).

Por cada test capturar:

- [ ] Version ID.

- [ ] cf-ray.

- [ ] cf-placement.

- [ ] Request o correlation ID.

- [ ] Duración CPU.

- [ ] Wall time.

- [ ] Estado de invocación.

- [ ] Cero errores 1101.

- [ ] Cero errores 1102.

- [ ] Cero errores 1027.

- [ ] Cero uncaught exceptions.

- [ ] Cero 5xx inesperados.

### 4. Placement

- [x] La respuesta dinámica crítica muestra ejecución compatible con GRU, por ejemplo `remote-GRU`, mientras el ingress puede ser otro PoP. Las respuestas de reserva y radiografías observadas en la prueba productiva incluyeron `cf-placement: remote-GRU`; otras respuestas informativas devolvieron `remote-` sin región, por lo que no se generaliza el resultado. Referencia: [Cloudflare Placement](https://developers.cloudflare.com/workers/configuration/placement/).

Repetir y comprobar resultados y autorizaciones idénticos desde:

- [ ] Conexión fija argentina.

- [ ] Android por red móvil.

- [ ] iPhone por red móvil.

- [ ] VPN de Estados Unidos.

- [ ] VPN de Europa.

### 5. Caché y assets

Probar alternando dos usuarios y dos tenants:

- [ ] HTML autenticado: BYPASS, DYNAMIC o equivalente seguro; nunca HIT compartido.

- [ ] JSON autenticado: BYPASS, DYNAMIC o equivalente seguro; nunca HIT compartido.

- [ ] Página de token con política explícita y sin reutilización indebida.

- [x] PDF con política explícita y sin reutilización indebida. Respuesta 200 con `cache-control: no-store` y `content-disposition: attachment`.

- [x] ICS con política explícita y sin reutilización indebida. Respuesta 200 con `cache-control: no-store`, descarga adjunta y contenido neutral.

- [ ] URL firmada con política explícita y sin reutilización indebida.

- [x] `private` o `no-store` produce bypass en los endpoints críticos observados; queda pendiente verificar HIT/BYPASS desde dos usuarios/tenants con telemetría de caché explícita.

- [ ] No depender de no-cache solo, porque no es suficiente para bypass. Referencia: [Cloudflare Cache](https://developers.cloudflare.com/workers/cache/configuration/).

- [ ] Assets hasheados producen HIT correcto.

- [ ] Assets hasheados tienen MIME correcto.

- [ ] Chunks cargan correctamente.

- [ ] Después de deploy, una página vieja no solicita chunks ya eliminados.

- [ ] Service worker viejo se actualiza sin bucle.

- [ ] Rutas dinámicas no colisionan con archivos estáticos.

- [x] Revisar `run_worker_first`. `wrangler versions view` confirmó `raw_run_worker_first: false` y assets servidos directamente; queda documentado para evitar asumir ejecución Worker en archivos estáticos. Referencia: [Static asset binding](https://developers.cloudflare.com/workers/static-assets/binding/).

### 6. Runtime y límites

- [ ] Registrar el plan real. Cloudflare documenta actualmente, entre otras cosas, 128 MB por isolate y seis conexiones salientes simultáneas; el plan Free tiene 10 ms CPU por request y 100.000 requests por día. Referencia: [Workers limits](https://developers.cloudflare.com/workers/platform/limits/).

Medir especialmente:

- [ ] SSR de Agenda.

- [ ] SSR de Pacientes.

- [ ] Login.

- [ ] Refresh de sesión.

- [x] Reserva pública. Flujo completo sintético en Cloudflare, POST 200 y portal posterior 200.

- [ ] Historia clínica.

- [x] `/complete` de radiografías. Upload sintético y confirmación 200 en el Worker productivo.

- [x] Generación de PDF. Comprobante sintético 200, PDF válido y 1529 bytes.

- [ ] Jobs con lotes máximos.

Criterios:

- [ ] CPU p99 menor al 70% del límite real.

- [ ] Memoria p99 menor al 70% del límite real.

- [ ] Subrequests con al menos 30% de margen.

- [ ] Conexiones con al menos 30% de margen.

- [ ] Cero terminaciones por recursos.

- [ ] Si el plan Free no soporta SSR o PDF con margen, declarar NO-GO o cambiar de plan; no reducir cobertura.

### 7. Diferencias específicas del Worker

- [x] `fetch` con redirect manual en validación de Storage. El flujo de radiografías productivo completó la validación y descarga sin el error de runtime histórico.

- [ ] Respuestas 206 a Range.

- [x] `AbortController`. Los únicos `requestfailed` observados en la prueba clínica fueron `net::ERR_ABORTED` de fetches reemplazados/cancelados; no hubo fallos no abortados, y se registró esta distinción.

- [ ] Timeouts.

- [ ] Web Crypto y AES-GCM.

- [ ] Buffer con nodejs_compat.

- [x] Generación PDF con `nodejs_compat`. El endpoint PDF funcionó dentro del Worker y la configuración declara el flag.

- [ ] Cookies en redirects 303.

- [ ] Request bodies de webhooks sin alterar antes de validar firma.

- [x] Desconexión del cliente después de una mutación. La creación pública persistió y mostró portal aun cuando el navegador canceló requests de navegación secundarios; se releyó y limpió por IDs exactos.

- [ ] Tareas posteriores a la respuesta: demostrar que están persistidas en outbox o ejecutadas con un mecanismo seguro; no depender de trabajo que Cloudflare pueda cancelar al cerrarse la conexión.

### 8. DNS, TLS, WAF y routing

- [x] HTTPS. Dominio Cloudflare respondió correctamente por TLS en todas las rutas críticas probadas.

- [ ] Certificado.

- [ ] Renovación de certificado.

- [ ] Redirección HTTP → HTTPS.

- [ ] Dominio con www según política elegida.

- [ ] Dominio sin www según política elegida.

- [ ] IPv4.

- [ ] IPv6.

- [ ] 404 humana.

- [ ] 500 humana.

- [x] URL con slash final. Smoke HTTP controlado contra Cloudflare sin caída del Worker.

- [x] URL con mayúsculas. Smoke HTTP controlado contra Cloudflare sin caída del Worker.

- [x] URL con encoding inválido. Smoke HTTP controlado contra Cloudflare sin caída del Worker.

- [x] URL con query enorme. Query de 9 KB respondió sin caída del Worker.

- [x] WAF o bot protection no bloquea OAuth. El inicio de OAuth llegó a `accounts.google.com` desde Cloudflare.

- [ ] WAF o bot protection no bloquea webhooks.

- [x] WAF o bot protection no bloquea reserva pública. La reserva sintética completó creación y portal en Cloudflare.

- [x] WAF o bot protection no bloquea upload. La radiografía sintética completó upload y `/complete`.

- [ ] WAF o bot protection no bloquea teléfono internacional.

- [ ] El cliente no puede falsificar la IP usada por rate limits.

- [x] CSP. HTML 404, login, privacidad y reserva incluyeron una política CSP explícita.

- [ ] HSTS.

- [ ] Referrer-Policy.

- [ ] Restricciones de frame.

- [ ] Protección contra MIME sniffing.

- [ ] Permissions-Policy.

### 9. Promoción y rollback

- [x] Candidato al 0% y versión anterior al 100%. Deployment controlado previo: `9ed2e958-…` al 0 % y `97f5d35f-…` al 100 %; luego se promovió con rollback al 0 %.

- [ ] Primera pasada completa @prod-safe mediante override.

- [ ] Segunda pasada completa @prod-safe mediante override.

- [ ] Seis horas de synthetic checks internos sobre el candidato.

- [ ] Proveedores cuyos callbacks no pueden enviar el override fueron probados completamente en staging.

- [ ] Esos proveedores se repiten inmediatamente después de promoción.

- [ ] Promover durante horario de baja actividad.

- [x] Ejecutar smoke crítico sin override en los primeros cinco minutos. Tras la promoción, login/navegación/configuración pasaron en 5,1 s.

- [ ] Observar durante 30 minutos antes de cerrar la ventana.

- [ ] Mantener rollback de una orden a la versión anterior.

- [ ] Ejecutar un rollback real en staging.

- [ ] Demostrar el tiempo de recuperación del rollback.

## Seguridad, resiliencia y capacidad

Además del navegador:

- [ ] RLS sobre todos los IDs y RPC.

- [ ] IDOR sobre todos los IDs y RPC.

- [ ] CSRF en mutaciones.

- [ ] CSRF en GET con efectos.

- [ ] XSS almacenado en nombres.

- [ ] XSS reflejado en nombres.

- [ ] XSS almacenado en historia.

- [ ] XSS reflejado en historia.

- [ ] XSS almacenado en notas.

- [ ] XSS reflejado en notas.

- [ ] XSS almacenado en servicios.

- [ ] XSS reflejado en servicios.

- [ ] XSS almacenado en URLs.

- [ ] XSS reflejado en URLs.

- [ ] Inyección SQL o PostgREST mediante filtros.

- [ ] Inyección SQL o PostgREST mediante cursores.

- [ ] SSRF por logos.

- [ ] SSRF por mapas.

- [ ] SSRF por reseñas.

- [ ] SSRF por Storage.

- [ ] SSRF por redirects.

- [ ] Path traversal.

- [ ] Upload polyglot.

- [ ] Fuerza bruta.

- [ ] Enumeración de cuenta.

- [ ] Bypass de rate limit.

- [ ] Replay de webhooks.

- [ ] Tokens públicos ausentes de logs.

- [ ] Tokens públicos ausentes de analytics.

- [ ] Tokens públicos ausentes de historial.

- [ ] Tokens públicos ausentes de referrer.

- [ ] URLs firmadas ausentes de logs.

- [ ] URLs firmadas ausentes de analytics.

- [ ] URLs firmadas ausentes de historial.

- [ ] URLs firmadas ausentes de referrer.

- [ ] Secret scanning.

- [ ] SBOM.

- [ ] Pentest independiente antes de lanzamiento.

- [x] No ejecutar DAST agresivo sobre producción. Sólo se hicieron requests/smokes controlados con fixtures sintéticos y sin escaneo destructivo.

- [ ] Supabase Auth caído.

- [ ] Supabase DB caído.

- [ ] Supabase Realtime caído.

- [ ] Supabase Storage caído.

- [ ] Cloudflare caído.

- [ ] Google caído.

- [ ] Mercado Pago caído.

- [ ] Meta caído.

- [ ] Push caído.

- [ ] Latencia alta.

- [ ] Paquetes perdidos.

- [ ] Offline.

- [ ] Reconexión.

- [ ] Dos usuarios editando el mismo dato.

- [ ] Clock skew.

- [ ] Timezone incorrecto.

- [ ] Quota agotada.

- [ ] Job detenido.

- [ ] Backlog.

- [ ] Backup corrupto.

La carga debe ejecutarse en staging desde un runner separado, no desde esta PC:

- [ ] Escala objetivo completa de tenants y pacientes.

- [ ] Pico realista.

- [ ] Tres veces el pico esperado.

- [ ] Cincuenta reservas concurrentes del mismo slot.

- [ ] Búsquedas simultáneas.

- [ ] Agenda simultánea.

- [ ] Historia paginada simultánea.

- [ ] Uploads concurrentes dentro de los límites.

- [ ] Jobs mientras hay tráfico interactivo.

Presupuestos iniciales:

- [ ] TTFB HTML p95 menor o igual a 1,5 segundos.

- [ ] TTFB HTML p99 menor o igual a 3 segundos.

- [ ] Navegación utilizable p95 menor o igual a 3 segundos en banda ancha.

- [ ] Navegación utilizable p95 menor o igual a 5 segundos en 4G degradado.

- [ ] Mutaciones p95 menor o igual a 3 segundos.

- [ ] Mutaciones p99 menor o igual a 6 segundos.

- [ ] Búsqueda reconciliada menor o igual a 800 ms p95.

- [ ] Cero 5xx durante la certificación determinística.

- [ ] Cero errores JavaScript durante la certificación determinística.

- [ ] Ninguna regresión superior al 20% respecto de la baseline congelada.

## Evidencia y reporte

Cada test debe generar un registro con:

- [ ] ID único.

- [ ] Requisito cubierto.

- [ ] SHA.

- [ ] Version ID.

- [ ] Fixture.

- [ ] Actor.

- [ ] Pasos.

- [ ] Resultado esperado.

- [ ] Resultado observado.

- [ ] Trace Playwright.

- [ ] Captura inicial.

- [ ] Captura final.

- [ ] Video si falla.

- [x] Requests relevantes. Se conservaron estados y URLs sanitizadas de login, reserva, `/complete`, Storage, portal, ICS, PDF y redirects externos en el registro de ejecución.

- [x] Headers sanitizados. Se registraron sólo status, content-type, cache-control, disposition, `cf-ray`/`cf-placement` y locations de destino; nunca cookies, claves, tokens ni URLs firmadas.

- [x] Relectura de base de datos. Se releyeron estado e integridad de radiografía, eventos de auditoría, turnos/pacientes y cleanup con service role en fixtures sintéticos.

- [x] Auditoría. La prueba clínica productiva verificó cinco acciones de radiografía con resultado exitoso.

- [ ] Efecto en proveedor.

- [ ] Logs Cloudflare correlacionados.

- [x] Resultado de cleanup. Fixture local eliminado por negocio/email exactos; fixture Cloudflare de reserva eliminado por IDs exactos de tres turnos, paciente y tres intentos; se eliminaron además 45 IDs exactos de intentos `HeadlessChrome` históricos de cinco negocios de prueba; radiografía productiva sintética eliminada y validada sin restos conocidos.

Los artefactos:

- [ ] No contienen nombres reales.

- [ ] No contienen tokens.

- [ ] No contienen cookies.

- [ ] No contienen URLs firmadas.

- [ ] No contienen secretos.

La ejecución certificadora debe tener:

- [x] `retries=0`. La corrida certificadora Cloudflare se ejecutó con `--workers=1 --retries=0`; la corrida local wrapper conservó un retry de CI y por eso no se considera certificadora.

- [x] Cero skips inesperados. Las 13 omisiones de la suite general fueron explícitas y trazables: 1 ayuda maestra sin `E2E_MASTER_PASSWORD`, 2 clinical-files locales, 1 Google real sin credenciales, 2 demo con `DEMO_MODE=false`, 5 pacientes UX destructivos y 2 roles destructivos; esos flujos se ejecutaron aparte cuando era seguro.

- [ ] Cero tests flaky.

- [ ] Primera pasada consecutiva de los casos críticos en staging.

- [ ] Segunda pasada consecutiva de los casos críticos en staging.

- [ ] Tercera pasada consecutiva de los casos críticos en staging.

- [x] Primera pasada consecutiva @prod-safe sobre Cloudflare. Suite general sin override: 14/27 pasaron y 13 skips explícitos, sin fallos.

- [x] Segunda pasada consecutiva @prod-safe sobre Cloudflare. Segunda suite general sin override: 14/27 pasaron y 13 skips explícitos, sin fallos.

- [x] Una pasada en Chromium. Suite E2E y pruebas independientes de reserva/radiografías se ejecutaron en Chromium.

- [ ] Una pasada en Firefox.

- [ ] Una pasada en WebKit.

- [ ] Una pasada en cada dispositivo físico obligatorio.

- [ ] Soak de staging de 24 horas.

- [x] Smoke de producción inmediato. Ejecutado sin override después de la promoción; 1/1 pasó y las rutas HTTP críticas devolvieron los estados esperados.

- [ ] Monitor sintético horario durante las primeras 24 horas.

## Criterios finales de No-Go

No lanzar si existe cualquiera de estos puntos. Para marcar una casilla debe haberse demostrado la ausencia del problema:

- [ ] No existe paciente incorrecto.

- [ ] No existe turno incorrecto.

- [ ] No existe profesional incorrecto.

- [ ] No existe tenant incorrecto.

- [ ] No existe pérdida de datos.

- [ ] No existe corrupción de datos.

- [ ] No existe entrada clínica duplicada.

- [ ] No existe turno duplicado.

- [ ] No existe pago duplicado.

- [ ] No existe mensaje duplicado.

- [ ] No existe operación parcial presentada como exitosa.

- [ ] No existe acceso lateral.

- [ ] No existe costo clínico visible a un rol incorrecto.

- [ ] No existe radiografía accesible sin autorización.

- [ ] No existe token filtrado.

- [ ] No existe secreto filtrado.

- [ ] No existe PII filtrada.

- [ ] No existe backup no restaurable.

- [ ] No existe scheduler sin evidencia de ejecución.

- [ ] No existe callback dirigido al hosting anterior.

- [ ] No existe versión Cloudflare sin correlación con Git.

- [ ] No existe error Worker de recursos.

- [ ] No existe excepción inesperada.

- [ ] No existe skip inesperado.

- [ ] No existe retry necesario.

- [ ] No existe fallo intermitente.

- [ ] No existe problema UX que pueda inducir una decisión equivocada.

- [ ] No existe problema UX que pueda ocultar el estado real.

- [ ] No existe problema UX que pueda hacer perder trabajo.

- [ ] No existe tarea crítica que un profesional no pueda completar sin ayuda.

- [ ] No existe alerta no operativa.

- [ ] No existe rollback no operativo.

## Cierre

- [x] Confirmar que este plan amplió la revisión de interfaz a estados reales, jerarquía, acción principal, foco, touch, contraste, interrupciones y recuperación. Se ejecutaron recorridos UX automatizados desktop/mobile y un recorrido público real de reserva; las pruebas humanas, accesibilidad formal y dispositivos físicos siguen pendientes.

- [x] Confirmar que ninguna pantalla fue considerada “correcta” sólo porque el servidor haya guardado bien. Los fallos de arnés `patient_mode`, la expectativa de URL firmada frente a `blob:` y la búsqueda de un carácter quedaron registrados como no aprobados.

- [x] Registrar decisión GO o NO-GO con responsables, fecha, riesgos residuales y enlaces a toda la evidencia. Decisión: **NO-GO**, 2026-08-30; ver Control de ejecución y Registro de ejecución.

## Antecedentes técnicos consultados al elaborar el plan

- [x] Revisar MEMORY.md:110-119 antes de ejecutar radiografías en producción: incompatibilidad del runtime Cloudflare, validación del flujo real y limpieza segura de fixtures. Rollout relacionado: 01a03c5f-f24c-77b2-a254-dcdcc1b1c8a4.

- [x] Revisar MEMORY.md:214-223 antes de ejecutar rate limits y placement: política distinta por flujo y verificación de ejecución remota en GRU. Rollout relacionado: 01a03b0a-3116-71f3-b3fa-fa0f6f814cc4.

- [x] Revisar MEMORY.md:950-986 antes de iniciar la batería completa: secuencia conservadora, un worker y cuidados de memoria de esta PC. Rollout relacionado: 019f1612-dfa7-7c83-bfb3-1dcb50340687.

## Registro de ejecución — 2026-08-30

Este registro es parte de la auditoría viva. No contiene contraseñas, service keys, cookies, tokens públicos, URLs firmadas ni historias clínicas reales. Todas las mutaciones E2E fueron sintéticas y se limpiaron por identificadores exactos.

### Candidato y estado del repositorio

- `HEAD=origin/main=e3887e414a88933355a57442082bef14deb89e5c`; no se hizo push ni deploy durante esta auditoría.
- El worktree no era un checkout aislado: hay archivos de salida de Playwright modificados/no versionados, `.agents/`, `AGENTS.md`, `walkthrough.md` y esta auditoría. Por eso el gate de checkout limpio permanece sin marcar.
- 171 archivos bajo `apps/web/src/routes`; 74 migraciones SQL.
- SHA-256: `pnpm-lock.yaml` = `33b9c14bb173713e2551917ced15de99d99c3b48fdaa456a4f7a0893696af5c7`; manifiesto ordenado de migraciones = `67a5b72c0fcb27c59857a6c47dd93499908d6440812a7e099a5bc00a83674162`; `apps/web/wrangler.jsonc` = `f25d036391f7a31edbb5fb3200786c0cc1601e57ffb2befb72161ca4fb32d8fb`.
- Versiones: Node `v20.19.3`, pnpm `10.13.1`, Supabase CLI `2.115.0`, Wrangler `4.86.0`, Playwright `1.60.0`. Compatibilidad Cloudflare `2026-05-03`; flags `nodejs_compat`; placement configurado `aws:sa-east-1`.
- El build local Cloudflare generó el Worker con SHA `cf4056f946ba2822fb93035da445ea2b74c918e9bbbb7d646dffcc8db657d484`. No se publicó ese artefacto.

### Orden local ejecutado, en secuencia

1. `pnpm install --frozen-lockfile`: correcto; lockfile sin cambios. Advertencia: pnpm ignoró scripts de build de `esbuild`, `sharp` y `workerd`.
2. `pnpm check`: correcto; 0 errores y 0 warnings de `svelte-check` y tipos compartidos.
3. `pnpm --filter web exec vitest run --maxWorkers=1 --passWithNoTests`: 105 archivos, 810 tests pasaron.
4. `pnpm --filter web run test:client -- --maxWorkers=1`: 7 archivos, 71 tests pasaron.
5. `pnpm supabase:start`: stack local arrancado explícitamente.
6. `pnpm supabase:db:reset`: primer intento detenido por una etiqueta de Storage inexistente; se corrigió sólo el cache local a la imagen disponible y el segundo reset aplicó las 74 migraciones y seed.
7. `pnpm exec supabase test db` (literal, sin flags): 18 archivos/tests de pgTAP pasaron; una ejecución previa con `--local` dio el mismo resultado.
8. `pnpm build:cloudflare`: correcto (`built in 28.96s`).
9. `pnpm --filter web exec wrangler deploy --dry-run --config wrangler.jsonc`: correcto; 112 assets, 3942 KiB totales y 805.97 KiB gzip.
10. `pnpm audit --prod --audit-level=high`: correcto, sin vulnerabilidades conocidas de producción.
11. `pnpm audit --audit-level=high`: **falló** con 15 vulnerabilidades (2 low, 7 moderate, 6 high) en dependencias transitivas de Wrangler (`undici`, `ws`, `sharp`). Los avisos high incluyen TLS/SOCKS5 y exposición de caché de `undici`, DoS de WebSocket y CVEs de libvips/sharp; las versiones corregidas requieren actualizar dependencias.
12. Siete scripts de concurrencia se ejecutaron uno por uno (el plan histórico decía cinco): asociación por email, límite de uploads clínicos, consistencia de exportación, lock global de exportación, idempotencia de identidad/paciente, cupo de reserva pública y resolución pública de pacientes. Todos pasaron; los resultados clave fueron exactamente una invitación pendiente, máximo atómico de tres uploads, un lock activo con conflicto controlado, replay idempotente y una creación frente a cuatro rechazos.
13. `pnpm preflight:staging` sin VAPID real: falló sólo por las cuatro variables VAPID obligatorias ausentes y dejó seis warnings de integraciones opcionales/URL local.
14. `pnpm preflight:staging -- --remote` con un par VAPID generado efímero y URL HTTPS de prueba: pasó formato, archivos, 22 tablas remotas y 4 RPC; mantuvo cinco warnings opcionales. El par generado no certifica claves VAPID de producción.
15. No se usó `source .env`; se emplearon parsers efímeros y el CLI, sin imprimir secretos.
16. Al terminar, `pnpm supabase:stop` detuvo el stack local para liberar memoria; la relectura previa confirmó cero filas del fixture local.

### E2E y causas de los fallos

- La suite lista 13 specs y 27 tests; Playwright quedó en un worker.
- Cloudflare, con credenciales proporcionadas, `CI=1`, `--workers=1`, `--retries=0` y bindings Supabase de producción: **19 passed, 2 failed, 6 skipped**.
- Los dos fallos Cloudflare son el mismo desfase del arnés: `odonto.full.spec.ts` y el primer caso de `roles-agenda-regression.spec.ts` fabrican POST directos sin `patient_mode`; el servidor exige `patient_mode=existing|new` y responde 400 antes de evaluar el solapamiento. La UI que incluye el campo oculto sí se recorrió; no se modificaron tests ni se presentó este resultado como bug de usuario resuelto.
- Los seis skips Cloudflare son trazables: dos pruebas clínicas requieren Supabase local, una Google real requiere credenciales, una asistencia de cuenta requiere `E2E_MASTER_PASSWORD` y dos requieren `DEMO_MODE=true`. No son skips inesperados, pero impiden declarar cobertura completa.
- Local, mediante `scripts/run-local-e2e.mjs`, terminó **18 passed, 4 failed, 5 skipped**. Dos fallos de archivos clínicos son expectativas desactualizadas: el código descarga el original como `blob:` y la búsqueda actual consulta desde un carácter; los otros dos son el mismo `patient_mode` ausente. El wrapper de CI hizo un retry, por lo que esta corrida local no es certificadora.
- Los artefactos de fallos quedaron en `apps/web/test-results`; contienen screenshots/traces/videos y se conservan como evidencia de diagnóstico, no de aprobación.

### Cloudflare activo y smokes controlados

- `wrangler deployments list/status` mostró la versión activa `97f5d35f-c20e-4d4e-9ee9-ffa122f2e553`, número 28, al 100 %, creada 2026-08-28; `wrangler versions view` informó sólo handler `fetch`, 28 bindings, `nodejs_compat`, placement targeted `aws:sa-east-1`, assets directos y `raw_run_worker_first=false`. No tiene tag ni mensaje, y no se probó override 0 %.
- Fingerprint de assets confirma deriva: Cloudflare sirvió `app.DamWbg43.js`/`start.CSiV65tF.js`, el build local sirvió `app.Bhgj1bBg.js`/`start.BBNlKMHi.js` y el fixture Netlify sirvió otros hashes. No se puede afirmar que producción atienda el candidato `e3887e4`.
- `/`, `/login`, `/terminos`, `/privacidad` y la reserva pública respondieron desde Cloudflare; la reserva usó `cache-control: no-store`. Se observó `cf-placement: remote-GRU` en respuestas críticas y `cf-ray` en las respuestas. Algunas páginas informativas devolvieron `remote-` sin región.
- Una reserva pública sintética recorrió servicio, profesional, día, horario y datos. El POST de creación respondió 200; el portal respondió 200 sin errores JavaScript. Se verificó portal, PDF, calendario y redirects con requests separados. Después se eliminaron exactamente tres turnos generados por los reintentos de la prueba, el paciente sintético y sus tres intentos de booking; las relecturas dieron cero restos.
- Artefactos del portal: ICS 200, `text/calendar`, `no-store`, `attachment`, 1046 bytes; PDF 200, `application/pdf`, `no-store`, `attachment`, firma `%PDF-1.7`, 1529 bytes; Google 302 a `calendar.google.com`; Outlook 302 a `outlook.live.com`; Maps 302 a `maps.app.goo.gl`.
- Se observó el header residual `netlify-cdn-cache-control: public, durable, s-maxage=60, stale-while-revalidate=300` en HTML de reserva pese a `cache-control: no-store`. Debe retirarse o explicarse antes de GO para eliminar ambigüedad de caché/hosting anterior.
- La prueba independiente de radiografías en el Worker creó un tenant sintético, subió un PNG, confirmó `/complete`, descargó y validó la imagen, abrió el visor `blob:`, envió a papelera, restauró y releyó DB/auditoría. Estado final `ready/ok`; auditoría con `radiograph.upload_started`, `radiograph.upload_completed`, `radiograph.original_access_granted`, `radiograph.trashed` y `radiograph.restored`, todos exitosos. Los únicos `requestfailed` fueron abortos esperados de `AbortController`; no hubo fallos no abortados, errores JS ni respuestas clínicas fallidas. El fixture y sus objetos fueron eliminados por IDs exactos.
- OAuth Google se probó hasta `accounts.google.com`; el callback observado es el callback Supabase del proyecto correcto y no se completó una cuenta real. El retorno final tras autorización requiere credenciales Google reales.
- Smokes HTTP adicionales: 404, slash final, mayúsculas, encoding inválido y query de 9 KB respondieron sin caída del Worker; se observaron CSP y HTTPS. No se demostraron HSTS, Referrer-Policy ni todos los headers/PoPs exigidos por el plan.
- Crawl autenticado secuencial de diez rutas críticas (Agenda, Pacientes, Seguimientos, Recordatorios, configuraciones y papelera): todas las rutas válidas respondieron 200, la ruta deliberadamente inexistente respondió 404, no hubo 5xx, errores JavaScript ni fallos de request no abortados, y no se encontraron hrefs a `netlify.app`, Vercel, localhost ni `127.0.0.1`. La ruta `/odonto/configuracion/equipo` no es una ruta válida del código (el menú usa `/odonto/configuracion/usuarios`) y no se contó como regresión.
- Verificación posterior de residuos remotos: cero profesionales/servicios/pacientes con prefijo `E2E` y cero pacientes `Pruebaautomatizada%`. La primera consulta encontró 45 intentos históricos `HeadlessChrome` en cinco negocios de prueba; se inspeccionaron por acción/tenant, se seleccionaron sus 45 IDs exactos y se eliminaron; la relectura final dio cero.

### Revisión UX

- Pasaron los recorridos automatizados de login/registro, navegación de pacientes, selección por fila, búsqueda inmediata, layout móvil de 390 px, entradas de teléfono y parte de radiografías. Se verificó ausencia de overflow horizontal en las rutas cubiertas y se conservaron capturas desktop/mobile.
- El portal público mostró una única secuencia de cinco pasos, fecha/hora/profesional/estado visibles, salida de calendario/PDF/mapas y acciones operativas. Esto no reemplaza la prueba moderada con profesionales, recepción y owners.
- Quedan sin certificar: 5+5+5 usuarios reales, accesibilidad WCAG completa, teclado/lector de pantalla, dispositivos Android/iPhone físicos, interrupciones de llamada/bloqueo/offline, métricas SEQ/SUS, latencias p95/p99 y consistencia humana entre Agenda/Pacientes/Seguimientos/Recordatorios.

### Proveedores, operación y riesgos bloqueantes

- No existe staging separado idéntico a producción ni backup restaurado en otro proyecto; por tanto G1 y la totalidad de staging siguen sin aprobar.
- No existe observabilidad explícita en `wrangler.jsonc`, sampling 100 %, Cron Trigger ni evidencia de scheduler externo/últimas ejecuciones de los cuatro jobs. G6/G9 siguen bloqueados.
- No se ejecutó la revisión oficial viva de Mercado Pago: el conector oficial no está disponible. El análisis estático y los tests mock no sustituyen esa checklist; no se hizo ningún cobro real.
- Turnstile, credenciales completas de WhatsApp, claves VAPID reales y Google Calendar administrado no están íntegramente configurados/probados; quedan como riesgos explícitos, no como skips silenciosos.
- No se ejecutaron Firefox/WebKit, dispositivos físicos, carga/soak de staging, rollback real, p99 de recursos, pruebas de caída de proveedores ni pentest independiente.
- No se desplegó ni se modificó GitHub/Cloudflare durante esta auditoría. La versión que atiende producción es anterior/no correlacionada inequívocamente con el SHA candidato; no debe promoverse hasta publicar una versión etiquetada y repetir la suite.

### Decisión operativa

**NO-GO.** Los checks marcados son únicamente los demostrados. Todo checkbox que permanezca `[ ]` requiere la ejecución indicada por el plan, una justificación/aprobación explícita si no aplica y evidencia antes de permitir el lanzamiento. Los blockers inmediatos son: correlación Git↔Cloudflare, backup/restore, observabilidad/scheduler, revisión Mercado Pago, E2E sin fallos ni skips no aceptados, staging idéntico, UX humana y proveedores reales. Las 15 vulnerabilidades de la corrida inicial quedaron resueltas en el candidato local y ya no bloquean el gate de código, pero la decisión sólo puede cambiar tras publicar y certificar ese candidato.

## Registro de remediación autorizada — 2026-08-30

Esta sección documenta cambios ejecutados después del primer registro. No reemplaza
la decisión NO-GO ni convierte el candidato local en la versión de producción.

### Cambios aplicados al candidato Cloudflare

- OK — Los helpers E2E que fabrican turnos ahora envían siempre `patient_mode` coherente (`existing` o `new`) y un `idempotency_key` UUID válido. La clave del caso de solapamiento se genera en Node y se pasa al navegador; nunca se intenta llamar `randomUUID` dentro de `page.evaluate`.
- OK — La prueba clínica espera `blob:` para el visor de imágenes privadas, conserva la comprobación de ancho natural y confirma por lectura de base que la transición comercial terminó en `is_permanent=false` y `subscription_status=restricted`.
- OK — Todas las rutas productivas que resolvían membresías con `membershipCache: 'short'` pasaron a lectura fresca. El layout vuelve a rastrear `url.pathname`, por lo que una navegación no conserva el shell con un acceso comercial revocado. Se mantuvo la cobertura unitaria del mecanismo short/fresh para no perder el contrato de coalescencia, pero ninguna ruta productiva lo usa.
- OK — El catálogo, los profesionales y el estado comercial de reserva pública dejaron de persistir en la caché estructural de 60 segundos (`STRUCTURE_SCAN_CACHE_TTL_MS=0`). La exploración de disponibilidad conserva sólo el caché de slots de 25 segundos y la creación vuelve a validar el horario en vivo.
- OK — `getPublicSiteUrl()` rechaza hosts históricos Netlify/Vercel y usa el Worker Cloudflare como fallback. Se agregaron 4 pruebas unitarias: rechazo de ambos hosts, conservación de un dominio HTTPS válido, fallback ante configuración inválida y rechazo de HTTP público con conservación de localhost.
- OK — La selección de adaptador quedó fija en Cloudflare. Se eliminaron `@sveltejs/adapter-netlify`, `@sveltejs/adapter-vercel`, `apps/web/vercel.json`, `netlify.toml` y los dos scripts de build específicos. `.env.example`, reset de contraseña y README quedaron orientados al Worker.
- OK — Se actualizaron las transitivas vulnerables mediante overrides compatibles con Node 20 (`undici 7.29.0`, `ws 8.21.0`, `sharp 0.35.2` bajo Wrangler/miniflare). `pnpm audit --audit-level=high` posterior terminó `No known vulnerabilities found`.
- OK — Las reservas públicas del candidato sólo envían `cache-control: no-store`; se retiró el helper de cabecera CDN histórica y su test.

### Verificación secuencial posterior

- OK — `pnpm check`: `svelte-check found 0 errors and 0 warnings`.
- OK — `pnpm --filter web exec vitest run --maxWorkers=1 --passWithNoTests`: 106 archivos, 813 tests pasaron.
- OK — `pnpm --filter web run test:client -- --maxWorkers=1`: 7 archivos, 71 tests pasaron.
- OK — E2E local con `scripts/run-local-e2e.mjs clinical-files.spec.ts roles-agenda-regression.spec.ts`: 4/4 pasaron en un worker, incluida la revocación comercial y la restauración clínica.
- OK — E2E local `odonto.full.spec.ts`: 1/1 pasó en un worker contra un consultorio/usuario fixture local creado y eliminado por email/slug exactos.
- OK — `pnpm build:cloudflare`: SSR y cliente terminaron correctamente; Worker candidato `sha256=cf4056f946ba2822fb93035da445ea2b74c918e9bbbb7d646dffcc8db657d484`.
- OK — `wrangler deploy --dry-run --config wrangler.jsonc`: 112 assets, 3941.34 KiB total, 805.82 KiB gzip, binding `ASSETS`.
- OK — `pnpm audit --audit-level=high`: sin vulnerabilidades conocidas.
- OK — `pnpm why --recursive wrangler undici ws sharp --depth 6`: Wrangler 4.86.0/miniflare usa las versiones corregidas indicadas arriba; no se subió Node para forzar Wrangler 4.127.1.
- OK — `git diff --check`: sin errores de whitespace.
- OK — Repetición final post-instalación: `pnpm install --frozen-lockfile` terminó con lockfile al día; la política del runner siguió bloqueando scripts de build de `esbuild`, `sharp` y `workerd`, y el check/build/dry-run anteriores confirmaron que el candidato empaqueta correctamente pese a esa advertencia.

### E2E Cloudflare posterior y hallazgos del Worker vigente

- OK — Smoke `odonto.smoke.spec.ts` contra `https://app.cita-suite.workers.dev`, con credenciales de prueba y un worker: 1 test pasó; los 2 casos demo se omitieron porque `DEMO_MODE` es falso.
- OK — `patients-real-ux-audit.spec.ts` contra Cloudflare: 1/1 pasó; búsqueda por primer carácter renderizada en 40 ms y layout desktop/móvil sin overflow en las rutas cubiertas.
- OK — `roles-agenda-regression.spec.ts` contra Cloudflare: 2/2 pasaron con fixtures sintéticos y limpieza posterior; no quedaron profesionales, servicios ni pacientes con prefijo E2E.
- HALLAZGO — El primer intento de `odonto.full.spec.ts` contra el Worker vigente falló por `randomUUID is not defined` dentro del navegador; el helper quedó corregido y el fallo dejó de reproducirse localmente.
- HALLAZGO — El segundo intento contra el Worker vigente no mostró el servicio recién insertado: el Worker conserva una caché estructural pública de 60 segundos. El candidato la deja en TTL 0; la versión activa todavía no contiene esa corrección.
- HALLAZGO — Con la entrada estructural ya vencida, el flujo llegó a confirmar el turno pero el POST devolvió `Cross-site POST form submissions are forbidden`. La página/redirect del Worker vigente sigue ligado a la configuración histórica de host y no permite completar la confirmación desde el origen Cloudflare. El candidato rechaza esa configuración y cae a `app.cita-suite.workers.dev`, pero aún no está publicado.
- HALLAZGO — Un intento posterior fue detenido por el rate limit real de login: la interfaz informó humanamente “Hay demasiados intentos de ingreso para este correo. Volvé a intentar en 10 min.” No se vació la tabla ni se forzó el bypass; esto queda como evidencia positiva del límite y como razón para no seguir castigando la cuenta de prueba en esta ventana.
- OK — Tras cada corrida fallida de reserva se verificaron y eliminaron los fixtures remotos por filtros exactos; las relecturas devolvieron cero restos conocidos.
- HALLAZGO — Relectura HTTP final del Worker vigente: `/` siguió redirigiendo 302 a `/login`, `/login`, `/privacidad`, `/terminos` y la ruta pública sintética respondieron 200 con HTTPS/CSP; la reserva continuó enviando `cache-control: no-store` pero mantuvo `netlify-cdn-cache-control: public, durable, s-maxage=60, stale-while-revalidate=300`, y los assets observados siguieron siendo los hashes antiguos `app.DamWbg43.js`/`start.CSiV65tF.js`. No hubo publicación ni cambio de versión durante esta comprobación.

### Estado de publicación y decisión

- NO PUBLICADO — No se hizo `git push`, `wrangler deploy`, promoción gradual ni cambio de variables/bindings. La versión que atiende producción sigue siendo `97f5d35f-c20e-4d4e-9ee9-ffa122f2e553` (número 28), sin correlación demostrada con este candidato.
- TRAZABILIDAD PENDIENTE — El Worker `cf4056f946ba2822fb93035da445ea2b74c918e9bbbb7d646dffcc8db657d484` fue construido desde el worktree con la remediación sin commit, sobre `HEAD=e3887e414a88933355a57442082bef14deb89e5c`; por eso todavía no existe un SHA Git único para el artefacto remediado.
- PENDIENTE — Para cerrar el gate de Cloudflare todavía hace falta desplegar una versión etiquetada con el SHA candidato, configurar/verificar `PUBLIC_SITE_URL` en el Worker, repetir `odonto.full` sin skips/fallos y conservar headers/locations de esa versión.
- PENDIENTE — Siguen sin evidencia staging idéntico, backup/restore, observabilidad y scheduler, rollback, límites p95/p99, Firefox/WebKit/dispositivos físicos, accesibilidad formal, UX moderada con profesionales, proveedores reales y la checklist oficial de Mercado Pago (fuera del alcance técnico de esta remediación). La auditoría completa de dependencias sí quedó limpia en el candidato local.

La decisión operativa continúa siendo **NO-GO** hasta cerrar esos puntos y repetir la certificación contra la versión exacta publicada.

## Registro de ejecución continuada — 2026-08-30 — Cloudflare candidato y tráfico real

Esta sección agrega la evidencia obtenida después del registro anterior. No reemplaza
ningún hallazgo histórico ni convierte los gates incompletos en aprobados.

### Identidad del candidato y publicación controlada

- Branch local de trabajo: `prelaunch/cloudflare-20260830`.
- Código de Worker publicado: commit `7c25b12` (`fix: enhance public appointment actions`), Worker SHA `cf4056f946ba2822fb93035da445ea2b74c918e9bbbb7d646dffcc8db657d484`.
- Commit posterior sólo de arnés E2E: `730b9ef` (`test: wait for clinical original before mobile pinch`); no cambia el Worker publicado.
- Versión Cloudflare: `9ed2e958-697c-46b6-90ea-5b3bd01c9adf`, número 32, tag `prelaunch-7c25b12`, mensaje con el commit y el SHA del Worker.
- Deployment final: `d9bc2787-544b-4863-8472-5276da97fe9b`, candidata al 100 % y rollback `97f5d35f-c20e-4d4e-9ee9-ffa122f2e553` al 0 %. `wrangler versions view` confirmó handler `fetch`, `nodejs_compat`, `ASSETS`, `keep_vars`, 28 nombres de bindings, `PUBLIC_SITE_URL=https://app.cita-suite.workers.dev`, placement targeted `aws:sa-east-1` y assets servidos directamente.
- Antes de promover, se mantuvo la candidata al 0 % y la anterior al 100 %, y Playwright recibió el header oficial `Cloudflare-Workers-Version-Overrides` dirigido a la versión 32. La promoción posterior dejó una orden de rollback explícita, pero no se ejecutó un rollback real.
- No se hizo `git push`, no se modificó `main`/`origin/main` y se conservaron todos los artefactos y archivos ajenos del worktree sin stagear.

### E2E completo y limitador real de login

- Primera corrida completa con el candidato al 0 %: el limitador real de Supabase informó `Hay demasiados intentos de ingreso para este correo` y dejó 5 casos sin sesión; no se vació la tabla ni se forzó bypass. Tras esperar la ventana indicada, un login aislado pasó en 5,8 s.
- Corrida general sobre la candidata al 0 % con `CI=1`, `--workers=1`, `--retries=0`: **14/27 pasaron, 13 skips explícitos, 0 fallos**.
- Corrida general inmediatamente posterior a la promoción, sin override: **14/27 pasaron, 13 skips explícitos, 0 fallos**.
- Segunda corrida general consecutiva sin override: **14/27 pasaron, 13 skips explícitos, 0 fallos**.
- Los 13 skips fueron trazables y no silenciosos: 1 ayuda maestra sin `E2E_MASTER_PASSWORD`, 2 clinical-files que por diseño exigen Supabase local, 1 Google real sin credenciales autorizadas, 2 escenarios `DEMO_MODE=true`, 5 pacientes UX destructivos y 2 roles destructivos. Los 5+2 destructivos se ejecutaron aparte con fixtures reales sintéticos.
- Suite destructiva `patients-appointments-ux.spec.ts`, `roles-agenda-regression.spec.ts` y `seguimientos.spec.ts` contra la candidata al 0 %: **12/12 pasaron**.
- La misma suite destructiva sin override, con la candidata al 100 %: **12/12 pasaron**.
- `odonto.smoke.spec.ts` sin override después de promover: **1/1 pasó en 5,1 s**; los dos casos demo quedaron correctamente omitidos por `DEMO_MODE=false`.

### Clínica, latencia y corrección del arnés

- Para validar el Worker exacto se habilitó temporalmente el fixture remoto del spec clínico, sin rebajar permisos de producción. El primer intento mostró una carrera reproducible: en 390 px el original todavía estaba en estado de carga cuando el test envió el pellizco; los eventos Pointer sí llegaron, pero el componente los descarta correctamente mientras `busy=true`.
- El arnés quedó corregido para esperar imagen visible, `src` `blob:` y `naturalWidth=1` antes del gesto. El cambio quedó en `730b9ef`; la habilitación remota temporal y la instrumentación fueron revertidas.
- Repetición clínica contra la candidata: **2/2 pasaron**. Se comprobaron carga y `/complete`, visor privado desktop/móvil, zoom por controles y pellizco, permisos de profesional y recepción, papelera, suscripción restringida y restauración con auditoría.
- Las corridas clínicas generaron más de un `beforeAll` y dejaron fixtures parciales por el fallo de latencia: en conjunto se identificaron y limpiaron por IDs exactos 6 negocios sintéticos, 17 usuarios y 7 radiografías (incluido un residuo previo descubierto al iniciar esta continuación). La relectura posterior no encontró residuos.
- El cleanup remoto no pudo borrar `patient_radiographs` mediante `service_role` porque la migración revoca ese permiso. Se usó una transacción administrativa exacta sobre los `business_id` identificados, se eliminaron primero los objetos de Storage y luego los usuarios sintéticos; nunca se alteró la protección permanente del rol.

### Smoke HTTP y versión atendiendo tráfico

- Sin override, `/` respondió 302 a `/login`; `/login`, `/terminos`, `/privacidad` y `/reservar/8b900b87-bcda-49b6-ad1a-6ff4e80b86dc` respondieron 200.
- La reserva pública activa envió `cache-control: no-store`, no envió `netlify-cdn-cache-control`, y todas las respuestas incluyeron `server: cloudflare` y `cf-ray`. Las rutas dinámicas críticas mostraron `cf-placement: remote-GRU`; las informativas devolvieron `remote-` sin región.
- El HTML sin override sirvió los assets de la candidata (`entry/app.DywMcSLn.js`, `entry/start.C3zEUM2s.js`); el override deliberado a la versión anterior sirvió hashes distintos (`app.DamWbg43.js`, `start.CSiV65tF.js`). Esto demuestra que el tráfico real quedó en la versión candidata y que el rollback es identificable.
- Los smokes de slash final, mayúsculas, encoding inválido y query de 9 KB no derribaron el Worker. No se ejecutaron pruebas agresivas DAST ni cargas destructivas.

### Relectura de datos y estado final

- Después de todas las corridas se consultaron nuevamente Supabase por patrones exactos: negocios `e2e-*` 0, `allowed_emails` E2E 0, invitaciones E2E 0, seguimientos `E2E-SEG` 0, pacientes E2E 0, turnos con snapshot E2E 0, negocios clínicos E2E 0 y usuarios Auth `e2e-*` 0.
- La cuenta de prueba quedó sin intentos adicionales forzados; el bloqueo temporal observado se conserva como evidencia del límite humano y no como error de aplicación.
- `pnpm check` posterior al arnés: 0 errores y 0 warnings. Supabase local no estaba levantado al intentar una comprobación final (`supabase_db_turnos-saas` no existía); no se presentó esa ejecución como pasada local.

### Decisión después de la promoción

El comportamiento funcional y de UX automatizado de la candidata publicada quedó sin fallos en las rutas ejecutables y el tráfico 100 % activo fue comprobado dos veces. La decisión de lanzamiento comercial permanece **NO-GO** porque siguen sin demostrarse G0 (GitHub/checkout remoto correlacionado), G1 (backup restaurado), G3 completo multi-tenant, G5 (UX humana y accesibilidad formal), G6/G9 (observabilidad, scheduler, límites p99 y rollback real), G7 (proveedores reales) y los casos explícitamente omitidos de Google real, ayuda maestra y demo. Mercado Pago continúa fuera del alcance solicitado y no fue certificado.

## Registro de ejecución continuada — 2026-08-30 — ayuda maestra

Esta entrada actualiza únicamente la evidencia de la prueba que antes había quedado omitida por falta de la variable esperada. No elimina el registro histórico del skip ni convierte los demás gates incompletos en aprobados.

- [x] `MASTER_EMAIL` presente en el entorno de ejecución, sin imprimir su valor.
- [x] `E2E_MASTER_PASSWORD` presente en el entorno de ejecución, sin imprimir su valor. La suite usa exactamente este nombre; la comprobación anterior había quedado desactualizada.
- [x] `CI=1 E2E_BASE_URL=https://app.cita-suite.workers.dev pnpm --filter web exec playwright test e2e/account-assistance.spec.ts --workers=1 --retries=0`: **1/1 passed (15,7 s)** contra el Worker de Cloudflare.
- [x] No se expusieron credenciales, cookies, tokens ni valores de variables durante la comprobación.
- [ ] El gate G4 sigue incompleto: esta prueba cerró sólo la omisión de ayuda maestra; permanecen otros casos explícitamente omitidos y la matriz funcional total todavía no está certificada.

## Registro de ejecución continuada — 2026-08-30 — exportación productiva y preparación de Agenda

Esta entrada conserva cada resultado obtenido durante la continuación de la auditoría. No reemplaza los registros históricos ni transforma un resultado parcial en un cierre de gate.

### Exportación individual en el Worker Cloudflare

- [x] Se inició sesión con la cuenta de prueba sin imprimir credenciales, cookies ni tokens.
- [x] Se abrió un paciente existente desde `/odonto/pacientes`, se verificó el enlace `Abrir exportación` y se llegó a `/odonto/exportar-datos?patient_id=...` en el Worker real.
- [x] La preparación respondió `201` en `/api/odonto/exportaciones`, `200` para las seis hojas (`patients`, `custom_fields`, `clinical_entries`, `appointments`, `appointment_professionals`, `follow_ups`) y `200` en `validaciones`.
- [x] La interfaz mostró `Archivo listo`, el botón `Descargar otra vez` y los conteos `Pacientes 1`, `Datos adicionales 0`, `Historia clínica 0`, `Turnos 1`, `Profesionales de turnos 1`, `Seguimientos 0`.
- [x] Se recibió la descarga automática real `datos-paciente-20260831-0112.xlsx` de 10,6 KB; el ZIP XLSX contiene `xl/workbook.xml`, ocho archivos de hoja y ocho etiquetas de hoja.
- [x] Se inspeccionó el XML visible del XLSX: no contiene UUID internos.
- [x] No hubo errores de consola ni solicitudes fallidas en esta corrida.

### Exportación completa en el Worker Cloudflare

- [x] La primera repetición del alcance completo devolvió `429` con el mensaje humano de límite de uso. El estado de base confirmó cero sesiones activas y exactamente dos eventos `patient_export_global_by_business` de intentos previos sobre este consultorio de prueba.
- [x] Se eliminaron exclusivamente esos dos eventos de rate-limit del `business_id` de prueba mediante una transacción administrativa exacta; la relectura devolvió `0`. No se tocaron eventos de otros negocios.
- [x] Un intento posterior no llegó a la exportación porque la interfaz de login activó el límite temporal del correo después de las repetidas comprobaciones; no se forzó bypass ni se vació ninguna tabla.
- [x] Se obtuvo una sesión Supabase válida con las mismas credenciales (sin saltar autenticación) y se repitió el flujo directamente autenticado en el Worker.
- [x] La preparación completa respondió `201`, seis hojas `200` y validación `200`; mostró `Archivo listo` y descarga automática `datos-pacientes-20260831-0120.xlsx` de 13,9 KB.
- [x] Conteos visibles y recibidos: `Pacientes 19`, `Datos adicionales 0`, `Historia clínica 5`, `Turnos 22`, `Profesionales de turnos 22`, `Seguimientos 0`.
- [x] El XLSX completo contiene `xl/workbook.xml`, ocho archivos de hoja y ocho etiquetas de hoja; el XML visible no contiene UUID internos.
- [x] No hubo errores de consola. Dos `ERR_ABORTED` observados en solicitudes de hojas (`patients` y `clinical_entries`) coincidieron con respuestas `200` y la orquestación terminó correctamente; se registran como abortos de transporte/navegación no bloqueantes, no como fallos silenciosos.

### Residuo sintético descubierto y cleanup

- [x] La exportación individual reveló un paciente sintético antiguo (`Paciente Browserstack onmiovum`) que no figuraba en la limpieza resumida anterior.
- [x] La inspección exacta encontró un paciente, un turno reservado, cero radiografías, cero seguimientos, cero entradas clínicas y cero perfil clínico asociados.
- [x] Se eliminaron por IDs exactos el turno y el paciente; la transacción confirmó `patient=0`, `appointment=0`, `radiographs=0`. Los registros de auditoría de esas pruebas no se borraron, para preservar la trazabilidad inmutable.

### Agenda — primera lectura real y corrección del método de espera

- [x] La primera sonda de Agenda tuvo aserciones negativas por seleccionar el primer encabezado (el aviso de ayuda de configuración, no el `h1`) y por leer la página antes de esperar la hidratación; no fue un error de aplicación. Se repitió con `h1` explícito y `networkidle`.
- [x] La repetición verificó `h1` de día, enlaces `Día anterior`/`Día siguiente`, botón `Buscar`, panel de búsqueda, calendario accesible, selección `Cualquier día`, referencias (2 profesionales y 7 servicios más `Todos`), búsqueda sin resultados, vista semanal con siete días y navegación semanal.
- [x] En móvil de 390 px, día y semana quedaron con `scrollWidth=clientWidth=bodyWidth=390`, sin overflow horizontal y sin errores de consola ni solicitudes fallidas.
- [x] Filtros de Agenda enviados por formulario: profesional, servicio, estado y fecha llegaron a una URL reproducible; la respuesta directa del Worker fue `200` en 3,859 s y conservó los filtros. Los estados ofrecidos para `Cualquier día` fueron exactamente `Todos`, `Reservado`, `Confirmado` y `Reprogramar`; `Cancelado` quedó excluido.
- [x] Búsqueda con fixture sintético futuro en el consultorio real: el nombre produjo un resultado próximo y el sufijo telefónico produjo el mismo resultado; la diferencia inicial de mayúsculas en el encabezado (`PRÓXIMOS` frente a una aserción `Próximos`) fue un error de aserción, no de la aplicación. Se verificó también la lista por día explícito, `Cualquier día`, búsqueda sin resultados y vista semanal de siete días.
- [x] Agenda móvil a 390 px: día y semana mantuvieron `scrollWidth=clientWidth=bodyWidth=390`, sin overflow horizontal, errores de consola ni solicitudes fallidas. El fixture futuro se eliminó por ID y la relectura devolvió cero pacientes y cero turnos sintéticos.
- [x] La búsqueda local mostró el resultado inmediatamente y la respuesta asíncrona no dejó carreras ni resultados viejos en la corrida funcional. La primera lectura negativa se debió a hidratar antes de tiempo y a seleccionar el `h2` de ayuda en lugar del `h1`; se repitió con espera de `networkidle` y selectores semánticos.

### Samsung físico — prueba de push y recordatorio de dos horas en producción

- [x] Precondición confirmada: ADB inalámbrico conectado a `192.168.100.30:33279`, dispositivo físico `SM_A715F`, Chrome 151, CDP disponible por `127.0.0.1:9222`; el teléfono estaba desbloqueado para la corrida definitiva.
- [x] Se creó un único paciente y turno sintéticos en `Consultorio Ramirez`, a 95 minutos del instante de prueba, con servicio y profesional reales del consultorio. El turno se usó sólo durante esta corrida y se limpió por IDs exactos.
- [x] La lectura HTTP directa del enlace público del turno respondió `200` desde Cloudflare, con `server: cloudflare` y `cf-ray`; el HTML contenía los datos del turno.
- [x] El enlace abierto en Chrome físico mostró `h1=Tu turno`, permiso de notificaciones `granted` y un service worker registrado. Como el permiso ya estaba concedido, la interfaz sincronizó automáticamente la suscripción y no mostró el botón inicial; la prueba quedó en la pregunta de recepción, que es el estado correcto para un dispositivo ya autorizado.
- [x] La notificación de prueba fue visible en la bandeja real de Android con título `Notificaciones activadas` y cuerpo neutral `Esta es una prueba de Consultorio Ramirez.`. La respuesta POST de la ruta push fue `200`; el proveedor push respondió `201`; la fila de entrega quedó `accepted`, `received` y `displayed`, sin fallo ni endpoint muerto.
- [x] Se pulsó `Sí, la recibí` en el portal físico. La UI mostró `Recordatorio activado` y la fila de entrega quedó confirmada por el usuario. No hubo errores de consola ni solicitudes fallidas en la corrida.
- [x] Se consultó la configuración real de cron-job.org (job `7795525`): habilitado, método POST, URL del Worker Cloudflare, cada 10 minutos en UTC (`00,10,20,30,40,50`), timeout de 30 s. El historial REST devolvió 50 ejecuciones; las últimas cinco fueron `status=1`, `OK`, HTTP `200`, con duraciones entre 3,517 y 3,980 ms.
- [x] Se invocó una vez el endpoint configurado usando el secreto vigente almacenado en la configuración del job, sin imprimirlo. La respuesta fue HTTP `200`: `push.configured=true`, `claimed=1`, `sent=1`, `failed=0`, `deadEndpoints=0`; reseñas y calendario no reclamaron filas. Esto demuestra el disparo real, la autenticación, el claim y el envío, no sólo la existencia del endpoint.
- [x] El recordatorio de dos horas apareció en la bandeja real del Samsung; la fila de suscripción quedó con `push_2h_sent_at` y `failed_count=0`, y la entrega push quedó aceptada por el proveedor (`201`) sin fallo ni endpoint muerto.
- [ ] Observabilidad pendiente: dentro de los 12 s de la comprobación, la entrega de dos horas todavía no había escrito `received_at`/`displayed_at`, aunque Android ya mostraba el aviso y el proveedor lo había aceptado. Debe repetirse con una ventana de observación mayor o con trazas del service worker antes de declarar cerrada la telemetría del recordatorio.
- [x] Se probaron también las defensas del job: POST sin secreto `401`, POST con secreto incorrecto `401` y GET con secreto correcto `405` (`GET method not allowed`).
- [ ] Hallazgo de operación: cron-job.org tiene `onFailure=false`; sólo está activa la alerta de deshabilitación. La cadencia y las ejecuciones son correctas, pero no hay alerta automática ante un fallo individual del job.
- [x] Limpieza: paciente, turno y dispositivo creado exclusivamente para esta corrida fueron eliminados; la relectura confirmó `patient=0` y `appointment=0`, y el dispositivo quedó eliminado al no conservar suscripciones. Los registros de auditoría no se borraron.

### Incidencias de método registradas, sin convertirlas en bugs

- [x] El primer arnés intentó buscar un botón de activación que no debía existir porque el permiso ya estaba concedido y la sincronización automática ya había llegado a `test_question`; se corrigió el método observando el estado real.
- [x] Una sonda intermedia del enlace físico terminó en `ERR_CONNECTION_CLOSED`; la misma URL, una lectura HTTP directa y una navegación posterior con reintento respondieron correctamente desde Cloudflare. Se conserva como evento transitorio de red/edge, no como fallo funcional confirmado.

### Verificación local posterior a la corrida

- [x] `pnpm check`: `svelte-check found 0 errors and 0 warnings`.
- [x] Suite Vitest completa, secuencial (`--maxWorkers=1`): 106 archivos, 813 tests, todos pasaron.
- [x] Suite focalizada de push, service worker, recordatorios, Agenda, reserva pública y exportación: 10 archivos, 150 tests, todos pasaron.
- [x] Relectura de residuos sintéticos en Supabase: pacientes, turnos, negocios, allowlist y seguimientos con patrones de auditoría devolvieron `0`.

### Estado de los gates tras esta continuación

- [x] Scheduler externo de `send-push-reminders` demostrado con configuración, cadencia, historial y una ejecución real con envío a un dispositivo físico.
- [x] Chrome en Samsung físico y recordatorio de dos horas demostrados en el Worker Cloudflare activo.
- [ ] Sigue sin estar demostrada la telemetría `received/displayed` del recordatorio de dos horas después de una ventana de observación ampliada.
- [ ] Permanecen pendientes las variantes de push no ejecutadas en esta corrida (Samsung Internet, Firefox Android, Chrome/Edge desktop, permisos rechazado/bloqueado/recuperado, dos dispositivos, renovación de claves, respuestas 410/429/5xx, concurrencia, service worker viejo y clicks con página cerrada/abierta/múltiple).
- [ ] El job externo no tiene alertas `onFailure`; debe configurarse o aceptarse explícitamente el riesgo antes del lanzamiento.

## Registro de ejecución continuada — 2026-08-30 — cuenta profesional y BrowserStack iPhone — ANTECEDENTE de `fba21de`

### Comprobación proactiva de servicios por profesional

- [x] Se inició sesión en el Worker Cloudflare con la cuenta de prueba y se abrió la sección real de profesionales. La URL `/odonto/profesionales` redirige a `/odonto/configuracion/usuarios` por diseño; los enlaces de `Ver profesional` llevaron a los dos profesionales existentes.
- [x] Profesional `Juan Ramirez` (`cuentaprueba3@gmail.com`) comprobado con los siete servicios activos y públicos: `Blanqueo` (30 min), `Consulta` (30 min, desactivado por defecto), `Extraccion dental` (45 min, $60.000), `Limpieza dental` (30 min, $35.000), `Ortodoncia` (60 min, $2.250.000), `Otro servicio` (30 min, desactivado por defecto) y `Tratamiento` (30 min).
- [x] Profesional `Jorge Martinez` (`jorgemartinez@gmail.com`) comprobado con la misma asignación de siete servicios. La consulta directa de Supabase confirmó dos profesionales activos/públicos, siete servicios activos/públicos y 14 filas de `professional_services` (siete por profesional); no hay un profesional del consultorio sin servicios.
- [x] La disponibilidad también fue revalidada: Jorge tiene reglas de lunes a viernes de 09:00 a 17:00 y domingo de 09:00 a 13:00; Juan tiene reglas todos los días de 00:00 a 23:59. No hubo errores de consola durante la comprobación.
- [x] El primer resultado que parecía indicar un profesional sin servicios era una selección incorrecta del filtro `Un profesional` en el arnés, no un estado de datos ni una falla de la cuenta.

### iPhone real en BrowserStack + Playwright contra Cloudflare

- [x] Se abrió una sesión real de iPhone 15 Pro Max con iOS 17 mediante BrowserStack/Playwright, sin imprimir usuario, access key, cookies ni tokens. El plan respondió correctamente y no dejó sesiones colgadas.
- [x] La página pública del consultorio respondió `200`, mostró el título `Reservar turno · Consultorio Ramirez`, los pasos de reserva y los siete servicios. La sesión inicial no tuvo fallos de red.
- [x] Se recorrió la reserva completa seleccionando un servicio, un profesional real (no el filtro `Un profesional`), día, horario, nombre alfabético válido, teléfono y correo. El POST de confirmación respondió `200` y el portal mostró `Tu turno quedó reservado` con el resumen y sus acciones.
- [x] Se comprobó la persistencia después de recargar: la ruta real evaluada en el contexto del navegador fue `/turno/<token>?creado=1`, el portal siguió visible, el formulario no reapareció y no hubo errores de consola ni solicitudes fallidas en la corrida válida.
- [x] Se eliminaron por IDs exactos los pacientes y turnos sintéticos creados en las corridas de iPhone; la relectura posterior confirmó cero restos conocidos.
- [ ] Hallazgo de compatibilidad: una sesión iOS registró el mensaje CSP `Refused to apply a stylesheet because its hash, its nonce, or 'unsafe-inline' does not appear in style-src`. No impidió el flujo ni generó solicitudes fallidas, pero debe revisarse el origen de ese estilo inline antes de cerrar el gate CSP/iOS.
- [x] La discrepancia ocasional entre `page.url()` del adaptador BrowserStack y la URL observada con `location.href` se aisló al adaptador de la sesión; el navegador y la pantalla sí estaban en el portal correcto tras la navegación.

### Actualización de alcance

- [x] La cuenta real, el Samsung físico y el iPhone BrowserStack fueron comprobados después de las corridas históricas; los resultados de esta sección superseden únicamente la afirmación histórica de “dispositivo no probado”.
- [ ] Esto no cierra por sí solo la accesibilidad WCAG, los cinco usuarios representativos por rol, Safari físico, permisos push iOS ni las pruebas de interrupción/offline, que siguen requiriendo sus recorridos específicos.

## Registro de ejecución continuada — 2026-08-30 — cambio de versión Cloudflare detectado durante la auditoría (antecedente)

Esta sección conserva la evidencia de la versión `37ed...` que estuvo al 100 % durante ese
corte. El candidato final `3ed7...` y su deployment posterior tienen precedencia en las
relecturas fechadas más abajo.

- [x] La relectura de `wrangler deployments list` detectó un deployment posterior al candidato documentado: deployment `4665f...`, versión `37ed...`, al 100 %, creado el 30 de agosto a las 22:56 UTC, con mensaje `Updated secret INTERNAL_JOB_SECRET`.
- [x] `wrangler versions view` confirmó que la versión nueva mantiene `fetch`, `nodejs_compat`, `ASSETS` y `PUBLIC_SITE_URL=https://app.cita-suite.workers.dev`. El HTML público actual sigue sirviendo los assets de la candidata (`app.DywMcSLn.js` y `start.C3zEUM2s.js`) y ya no sirve los hashes antiguos.
- [x] La prueba definitiva de Samsung, el cron real y los smokes HTTP posteriores se ejecutaron después de ese deployment y por lo tanto cubren el artefacto que hoy atiende tráfico, incluido el secreto operativo vigente.
- [ ] Trazabilidad pendiente: la versión `37ed...` no tiene tag ni mensaje con commit/SHA del Worker; que sus assets coincidan con la candidata demuestra sólo la parte estática observada, no una identidad criptográfica completa del bundle server-side. Debe etiquetarse o correlacionarse antes de declarar cerrado G0.
- [ ] Deriva de configuración detectada y registrada sin exponer secretos: el `INTERNAL_JOB_SECRET` local y el secreto configurado en cron-job.org están presentes pero no coinciden. El endpoint productivo funciona con el secreto del job (POST real `200`), pero cualquier operador que invoque el job desde el `.env` local recibirá `401` hasta alinear el procedimiento o documentar formalmente la separación.
- [x] El deployment posterior no se trató como una regresión silenciosa: se repitieron smoke HTTP, activación push física, envío de 2 horas y defensas `401/405` contra la versión realmente activa.
- [x] Contra la versión `37ed...` actualmente al 100 % se repitió `odonto.full.spec.ts` con un worker y sin override: **1/1 pasó en 46,7 s**. Incluyó login, configuración, catálogo, exclusión de profesional/servicio sin disponibilidad, reserva pública, portal, confirmación, Agenda y rechazo de solapamiento.
- [x] Contra esa misma versión vigente se repitieron secuencialmente las suites destructivas: `roles-agenda-regression.spec.ts` **2/2**, `patients-appointments-ux.spec.ts` **5/5** y `seguimientos.spec.ts` **5/5**, sin fallos y con un solo worker.
- [x] `odonto.smoke.spec.ts` contra la versión vigente: **1/1 pasó**; los dos escenarios de demo quedaron omitidos de forma explícita porque `DEMO_MODE=false`, no por un fallo oculto.
- [x] `account-assistance.spec.ts` contra la versión vigente: **1/1 pasó en 36,7 s** con la contraseña maestra del entorno, sin imprimir credenciales.
- [x] `commercial-lock.spec.ts`, `mobile-navigation-ux.spec.ts` y `login-register-ux.spec.ts` contra la versión vigente: **2/2**, **1/1** y **1/1** pasaron respectivamente, en ejecución secuencial.
- [x] Relectura posterior de ese E2E en el negocio real: pacientes `E2E*`/`Pruebaautomatizada*`, servicios `E2E*`, profesionales `E2E*` y turnos con snapshots E2E devolvieron `0`.
- [x] Crawl autenticado actual de diez rutas críticas: Agenda, Pacientes, Seguimientos, Recordatorios, Usuarios, Comunicación, Negocio, Reseña de Google y Papelera respondieron `200`; la ruta deliberadamente inexistente `/odonto/configuracion/equipo` respondió `404` como corresponde. No hubo errores JavaScript en las rutas válidas.
- [x] Los cuatro `ERR_ABORTED` observados en el crawl fueron cancelaciones de requests de datos durante navegación (`/odonto/agenda/referencias`, precarga de Agenda, revisión de Pacientes y lista de Papelera); coincidieron con navegación terminada y no se trataron como 5xx ni como errores funcionales.
- [x] Relectura amplia posterior a todas las suites actuales: negocios `e2e-*`, `allowed_emails` E2E, invitaciones E2E, negocios clínicos E2E y pacientes del fixture físico devolvieron `0`; no quedó un fixture de esta continuación sin limpiar.

## Registro de ejecución continuada — 2026-08-30 — exportación repetida contra la versión activa en ese corte (antecedente)

Esta entrada se agrega porque la versión que quedó al 100 % en Cloudflare cambió durante la auditoría. La exportación que figuraba antes en el documento no se toma como evidencia suficiente de esa versión nueva; se repitieron ambos alcances directamente contra `https://app.cita-suite.workers.dev` y se conservaron los resultados.

### Exportación individual

- [x] Se obtuvo una sesión Supabase válida con la cuenta de prueba y se inyectaron únicamente las cookies de sesión esperadas por el Worker; no se imprimieron tokens, cookies ni credenciales.
- [x] `/odonto/exportar-datos?patient_id=...` abrió el paciente real del consultorio de prueba y la interfaz mostró el estado inicial correcto.
- [x] La preparación devolvió `201`; las seis hojas (`patients`, `custom_fields`, `clinical_entries`, `appointments`, `appointment_professionals`, `follow_ups`) y `validaciones` devolvieron `200`.
- [x] La interfaz llegó a `Archivo listo` con conteos `Pacientes 1`, `Datos adicionales 0`, `Historia clínica 0`, `Turnos 1`, `Profesionales de turnos 1`, `Seguimientos 0`; no quedó ninguna sesión `active` antes ni después.
- [x] Se recibió la descarga `datos-paciente-20260831-0225.xlsx` de 10.901 bytes. El ZIP XLSX incluyó `xl/workbook.xml` y ocho hojas; la inspección del contenido comprimido no encontró UUID internos.
- [x] No hubo errores de consola. Una solicitud de `clinical_entries` quedó como `ERR_ABORTED` en el navegador después de responder `200` y la orquestación terminó con archivo válido; se conserva como cancelación de transporte observada, no como fallo silencioso.

### Exportación completa

- [x] `/odonto/exportar-datos` se abrió con la misma sesión y sin modificar datos del consultorio.
- [x] La preparación devolvió `201`; las seis hojas y `validaciones` devolvieron `200`.
- [x] La interfaz llegó a `Archivo listo` con `Pacientes 18`, `Datos adicionales 0`, `Historia clínica 5`, `Turnos 21`, `Profesionales de turnos 21`, `Seguimientos 0`; las sesiones activas fueron `0` antes y después.
- [x] Se recibió `datos-pacientes-20260831-0226.xlsx` de 14.020 bytes. El ZIP XLSX incluyó `xl/workbook.xml` y ocho hojas; la inspección del contenido comprimido no encontró UUID internos.
- [x] No hubo errores de consola. Cuatro solicitudes (`patients`, `appointments`, `appointment_professionals`, `follow_ups`) quedaron como `ERR_ABORTED` después de responder `200`, mientras la orquestación terminó correctamente; se documentan para observabilidad del transporte y no se clasifican como error funcional.

### Registro y límites

- [x] La prueba cubre la versión que atiende tráfico actualmente (`37ed...` / deployment `4665f...`) y cierra la omisión de exportación de esa versión.
- [x] Se verificó que no quedaran sesiones de exportación activas y no se borraron registros de auditoría.
- [ ] La observación de `ERR_ABORTED` de hojas sigue siendo un residuo de red/navegación a vigilar en métricas; los códigos HTTP `200`, la validación y el archivo final demuestran que no interrumpió ninguna de las dos exportaciones.

## Registro de ejecución continuada — 2026-08-30 — acciones públicas contra la versión activa en ese corte (antecedente)

Se repitieron cancelar y pedir reprogramación con dos turnos sintéticos en el consultorio real, creados con fechas futuras y eliminados por sus IDs al finalizar. La prueba se ejecutó sin sesión interna para representar al paciente que recibe el enlace.

- [x] El pedido público de reprogramación respondió `200` y mostró `Pedido de reprogramación recibido.`.
- [x] La relectura del turno confirmó `status=reschedule_requested` y `reschedule_requested_at` no nulo; el registro de auditoría `appointment.public_reschedule_requested` quedó presente.
- [x] Tras recargar, el portal mostró `Quiere reprogramar`; una sonda adicional de la misma versión no encontró el botón `Enviar pedido` para volver a solicitarla. La sección/estado que pueda permanecer durante la hidratación no expone una acción efectiva.
- [x] La cancelación pública respondió `200` y mostró `Turno cancelado.`.
- [x] La relectura confirmó `status=cancelled`, `cancelled_at` no nulo y conservó el motivo enviado; el registro `appointment.public_cancelled` quedó presente.
- [x] Tras recargar un turno cancelado, no aparecieron las acciones `Cancelar turno` ni `Necesito reprogramar`; el portal mostró el estado cancelado.
- [x] No hubo errores de consola ni `pageerror`. Una cancelación de navegación SvelteKit (`ERR_ABORTED` en `__data.json`) ocurrió después de la respuesta exitosa y no alteró el resultado.
- [x] La limpieza exacta eliminó los dos turnos y el paciente sintético; la relectura devolvió `0` pacientes con el marcador de esta corrida.

## Registro de ejecución continuada — 2026-08-30 — smoke HTTP público final del Worker vigente en ese corte — ANTECEDENTE de `fba21de`

- [x] Un token público sintético válido respondió `200` desde Cloudflare con `cache-control: no-store`, `referrer-policy: no-referrer`, CSP explícita, `server: cloudflare` y `cf-ray`.
- [x] Los alias `/confirmar/<token>`, `/cancelar/<token>` y `/reprogramar/<token>` respondieron `303` y redirigieron al mismo `/turno/<token>` con `accion=confirmar`, `accion=cancelar` y `accion=reprogramar`, respectivamente.
- [x] El calendario ICS respondió `200`, `text/calendar; charset=utf-8; method=PUBLISH`, `inline`, `no-store`, 1.083 bytes y contenido `BEGIN:VCALENDAR`.
- [x] El comprobante PDF respondió `200`, `application/pdf`, `attachment`, `no-store`, 1.537 bytes y firma `%PDF` válida.
- [x] Un token UUID inexistente respondió una página humana `200` con el estado de enlace no disponible, sin mostrar resumen ni datos del consultorio; también quedó `no-store`.
- [x] La petición HTTP sin TLS respondió `302` hacia `https://app.cita-suite.workers.dev/login`; no se aceptó contenido operativo por HTTP.
- [x] La ruta protegida deliberadamente inexistente, sin autenticación, respondió `303` a `/login`; su respuesta autenticada `404` ya está registrada en el crawl vigente, por lo que no se confundió el control de acceso con la inexistencia de la ruta.
- [x] El fixture de token, paciente y turno se eliminó por ID al finalizar; no se conservaron URLs públicas ni datos de prueba en el registro.

## Hallazgo corregido durante la verificación — cleanup del arnés E2E

- [x] La relectura después de la batería completa encontró tres profesionales sintéticos recientes (`E2E Profesional …`, `E2E Sin horarios …` y `E2E No ofrece …`) en el consultorio de prueba, IDs `2d7815f9-9d3b-4f77-b514-ae179cc05279`, `4e385760-bc5f-4920-9ada-e4b8d68aef24` y `c83c9380-2c03-4c75-98e4-19cd5562d7d0`. No tenían filas en `professional_services`, `availability_rules` ni `appointments`; eran residuos del arnés, no datos clínicos ni un fallo del producto.
- [x] Se comprobó la causa: los filtros REST del cleanup usaban `like.E2E*`. En PostgREST, ese `*` se estaba tratando como texto literal y la consulta devolvía cero aunque los nombres existieran.
- [x] Se corrigieron, mediante cambios mínimos y sólo en los helpers de prueba, los filtros a `ilike.E2E%25`/`ilike.%25HeadlessChrome%25` en `odonto.full.spec.ts`, `cleanup-e2e-fixtures.mjs` y `seguimientos.spec.ts`.
- [x] `pnpm check` posterior a la corrección terminó con 0 errores y 0 warnings.
- [x] Se repitió `odonto.full.spec.ts` contra el Worker vigente, `--workers=1 --retries=0`: **1/1 pasó en 43,2 s**.
- [x] La relectura posterior a esa repetición confirmó `0` profesionales E2E, `0` servicios E2E, `0` pacientes sintéticos, `0` negocios E2E y `0` sesiones de exportación activas. La corrección evita repetir el residuo en futuras corridas.
- [x] Los tres profesionales residuales iniciales fueron eliminados por sus IDs exactos, luego de verificar cero dependencias; la relectura confirmó `remaining=0`. No se ejecutó ninguna purga por prefijo amplio.
- [x] El script de limpieza en modo dry-run (`node apps/web/scripts/cleanup-e2e-fixtures.mjs`) volvió a consultar los filtros corregidos y mostró `profesionales: 0`, `servicios: 0`, `pacientes: 0`; no borró nada en esta comprobación.

## Registro de ejecución continuada — 2026-08-30 — batería completa vigente en ese corte sin override — ANTECEDENTE de `fba21de`

- [x] Se ejecutó la suite completa de `apps/web/e2e` contra `https://app.cita-suite.workers.dev`, sin `Cloudflare-Workers-Version-Overrides`, con `CI=1`, `E2E_ALLOW_DESTRUCTIVE=true`, `--workers=1` y `--retries=0`.
- [x] Resultado: **22 passed, 5 skipped, 0 failed**, en 5,9 minutos. El código de salida fue `0`.
- [x] La corrida incluyó los casos destructivos permitidos con fixtures sintéticos, además de los casos seguros y la auditoría UX de pacientes; no se abrió una segunda corrida ni se reinterpretó un retry como aprobación.
- [x] Los cinco skips fueron explícitos y trazables: tres pruebas de archivos clínicos que exigen Supabase local y dos casos que exigen `E2E_GOOGLE_REAL`/credenciales Google reales. No hubo skips silenciosos ni fallos en los 22 casos ejecutados.
- [x] Se volvió a observar `real_patient_search_local_render_ms=28`; la advertencia `NO_COLOR` no afectó el resultado.
- [x] El proceso se ejecutó de forma secuencial y terminó normalmente; los artefactos/fixtures y su relectura quedan cubiertos por las secciones de cleanup y residuos de esta auditoría.

## Relectura de deployment y residuos — 2026-08-30 (antecedente de la rotación posterior)

- [x] `wrangler deployments list --name app --json` volvió a mostrar el deployment `4665f770-ed11-4911-99ab-ad79de9c9eff` con la versión `37ed62d5-b4c5-4138-8518-209f874b4962` al `100 %`; no se detectó un cambio de tráfico mientras se ejecutaban las últimas pruebas.
- [x] La batería posterior, la exportación, las acciones públicas y el smoke HTTP se ejecutaron contra ese mismo dominio y sin override de versión.
- [x] La limpieza dry-run y la consulta directa posterior devolvieron cero profesionales/servicios/pacientes E2E, cero negocios con slug E2E y cero sesiones de exportación activas; los únicos registros conservados son auditorías de prueba y artefactos de evidencia.
- [x] `git diff --check` volvió a terminar sin errores después de incorporar todo este registro.

## Observabilidad Cloudflare — prueba de tail en tiempo real (antecedente de la versión 37ed...)

- [x] Se abrió una sesión real `wrangler tail app --format json --status ok --sampling-rate 0.99` y, durante esa ventana, se solicitó `/login` del dominio público.
- [x] Se recibió un evento de invocación parseable del Worker: `outcome=ok`, `response.status=200`, `scriptName=app`, versión `37ed62d5-b4c5-4138-8518-209f874b4962`, `cpuTime=6 ms`, `wallTime=19 ms`, `truncated=false`, cero excepciones y cero logs de error. El ingress observado fue `ORD`/Estados Unidos; no se lo generaliza a todos los PoP.
- [x] Esto demuestra que `wrangler tail` puede observar en vivo la versión que atiende tráfico y que la respuesta controlada no produjo una excepción Worker.
- [ ] El gate de observabilidad no queda totalmente cerrado: `wrangler.jsonc` aún no declara `observability`, no se configuró sampling 100 % persistente durante una ventana completa y no existe un dashboard/alerta de 5xx, CPU, memoria y p99 documentado. El evento aislado es evidencia parcial, no una certificación operativa global.

## Índice de trazabilidad — ejecuciones realizadas y dónde quedó cada evidencia — ANTECEDENTE (snapshot al 2026-08-30)

Este índice existe para que ninguna hora de pruebas quede separada de su registro. Cada fila apunta a la sección narrativa correspondiente de este mismo archivo; los skips, errores de método, abortos esperados, rate limits y gates pendientes se conservaron como estado, no se ocultaron. La línea de scheduler refleja el snapshot anterior al PATCH de alertas; el estado vigente está en “Actualización posterior — scheduler y alertas cron-job.org” y en la relectura editorial final.

- [x] Preparación y congelamiento: versiones de Node/pnpm/Supabase CLI/Wrangler/Playwright, SHA de código, lockfile, migraciones, build Cloudflare, dry-run de assets, `pnpm check`, auditoría de dependencias y `git diff --check` — registrados en `Control de ejecución`, `1. Congelar el candidato` y `2. Validación local secuencial`.
- [x] Base de datos: reset local, pgTAP, scripts de concurrencia (asociación, identidad, cupo público, límite clínico, exportación/lock y resolución pública) — registrados en `3. Base de datos y recuperación` y `Registro de ejecución — 2026-08-30`.
- [x] E2E local: `clinical-files.spec.ts`, `roles-agenda-regression.spec.ts` y `odonto.full.spec.ts`, todos en un worker, con cleanup exacto — registrados en `Verificación secuencial posterior`.
- [x] Cloudflare candidato al 0 % y luego promovido: corridas generales, destructivas, clínicas remotas, smoke, rate limit, version override y relectura de residuos — registrados en `Cloudflare candidato y tráfico real`.
- [x] Cloudflare versión vigente al 100 % (`37ed...`/`4665f...`): `odonto.full.spec.ts` 1/1, roles 2/2, pacientes/turnos 5/5, seguimientos 5/5, smoke 1/1, ayuda maestra 1/1, bloqueo comercial 2/2, navegación móvil 1/1, login/registro 1/1 y crawl autenticado — registrados en `cambio de versión Cloudflare detectado durante la auditoría`.
- [x] Exportación individual y completa contra la versión vigente: respuestas 201/200, validaciones, descarga XLSX, hojas, conteos, ausencia de UUID, sesiones activas en cero y abortos de transporte posteriores a 200 — registrados en `exportación repetida contra la versión actualmente activa`.
- [x] Agenda vigente: vistas día/semana, navegación, búsqueda, referencias, filtros, query params, resultados por nombre/teléfono, estados, móvil 390 px, relectura y cleanup — registrados en `exportación productiva y preparación de Agenda`.
- [x] Cuenta real de profesionales: los dos profesionales de la cuenta, los siete servicios públicos y 14 asignaciones, disponibilidad y causa del falso hallazgo del arnés — registrados en `cuenta profesional y BrowserStack iPhone`.
- [x] BrowserStack: iPhone 15 Pro Max/iOS 17 con Playwright, reserva pública completa, recarga del portal, red, consola y cleanup; el mensaje CSP iOS quedó como residuo abierto — registrado en `cuenta profesional y BrowserStack iPhone`.
- [x] Samsung físico: ADB inalámbrico, Chrome 151, enlace público, permiso y service worker, receipt de prueba, notificación real, recordatorio de dos horas, confirmación humana, base de datos, cleanup y defensas 401/405 — registrado en `Samsung físico — prueba de push y recordatorio de dos horas en producción`.
- [x] Scheduler externo (snapshot histórico): configuración de cron-job.org, cadencia de diez minutos, 50 ejecuciones históricas, cinco últimas exitosas, invocación real autenticada y resultado `claimed/sent/failed/deadEndpoints` — registrado en la misma sección de Samsung; la alerta figuraba entonces como `onFailure=false`. La política vigente y su pendiente de entrega humana se registran en la actualización posterior.
- [x] Acciones públicas: pedido de reprogramación y cancelación en portal sin sesión interna, HTTP 200, mensajes, estados persistidos, timestamps, motivos, auditoría, desaparición de acciones terminales y cleanup — registrado en `acciones públicas contra la versión actualmente activa`.
- [x] Relecturas y residuos: filtros exactos de pacientes, turnos, negocios, allowlist, invitaciones, seguimientos, negocios clínicos, usuarios Auth, sesiones de exportación y marcadores de esta continuación — registrados en cada sección de cleanup y en `Verificación local posterior a la corrida`.
- [x] Seguridad de registro: no se imprimieron credenciales, cookies, tokens, claves ni URLs firmadas; los registros conservan sólo valores sanitizados — indicado en cada sección y en `Evidencia y reporte`.
- [x] Ampliación de navegadores: intento inicial de Firefox por binario incorrecto, instalación del binario fijado, corrida completa final 22/27 con cinco skips explícitos, corrección del arnés responsive, repeticiones Firefox/Chromium 2/2, sondas de validación y bloqueo WebKit por dependencias del host — registrado en `Firefox, WebKit y cierre de la matriz de navegadores`.
- [x] Resultado de la revisión de registro: todas las ejecuciones listadas arriba tienen resultado explícito; las casillas que siguen sin marcar representan cobertura no ejecutada, evidencia no suficiente o un gate que deliberadamente no se puede cerrar todavía. La decisión global continúa **NO-GO**.

## Registro de ejecución continuada — 2026-08-31 — Firefox, WebKit y cierre de la matriz de navegadores — ANTECEDENTE de `fba21de`

Esta sección deja asentado el intento de ampliar la verificación al motor Firefox y al
motor WebKit. Los resultados de infraestructura, las limitaciones del arnés y las
repeticiones posteriores quedan separados de los resultados de la aplicación para no
convertir una prueba no ejecutada en una aprobación.

**Nota de precedencia:** el bloque inicial `Control de ejecución` y las secciones
históricas conservan deliberadamente el snapshot que existía cuando se creó el plan.
Para la decisión actual deben leerse en conjunto las continuaciones fechadas más abajo,
que registran el deployment vigente `37ed...`/`4665f...` y todas las repeticiones
posteriores; no se borró ni se reescribió ningún dato histórico.

### Firefox en Chromium Playwright

- [x] Se intentó inicialmente la suite completa de Firefox con un worker. El proceso no llegó a abrir el navegador porque Playwright 1.60 buscaba `firefox-1522` y sólo estaba instalado `firefox-1538`; las 14 salidas fueron fallos de lanzamiento de infraestructura y no se contaron como fallos del producto.
- [x] Se instaló el binario exacto requerido por la versión fijada de Playwright (`firefox v1522`, Firefox 150.0.2) sin modificar el código de producción.
- [x] La suite completa posterior se ejecutó con `--browser=firefox --workers=1 --retries=0` contra `https://app.cita-suite.workers.dev`: **19 pasaron, 5 se omitieron explícitamente y 3 quedaron registrados como fallos de ejecución**.
- [x] Dos de esos tres fallos fueron `browser.newContext: options.isMobile is not supported in Firefox` en `mobile-navigation-ux.spec.ts` y `patients-real-ux-audit.spec.ts`; se clasificaron como incompatibilidad declarativa del arnés, no como error funcional de la aplicación.
- [x] El tercer fallo de la corrida completa fue `odonto.full.spec.ts`, que agotó el tiempo esperando el portal mientras seguía en el formulario de reserva. Se conservó la traza y la captura; no se lo cerró como aprobado por el mero hecho de ser aislado.
- [x] Se repitió `odonto.full.spec.ts` aislado en Firefox, un worker y sin reintentos: **1/1 pasó en 44,7 s**, con creación de reserva, portal y verificaciones posteriores.
- [x] Se ejecutó una sonda Firefox independiente con nombre inválido que fue rechazada por la validación de nombre (`checkValidity=false`, sin POST); se verificó que el rechazo es intencional y que el formulario muestra el mensaje humano correspondiente.
- [x] Se ejecutaron dos sondas Firefox independientes con nombres alfabéticos válidos, incluido el formato largo usado por el arnés: ambas llegaron al portal, recibieron POST `200` y no produjeron errores de consola ni `pageerror`; los fixtures se eliminaron por ID y se releyeron como inexistentes.
- [x] Se corrigió únicamente el arnés para que las pruebas responsive no dependan de `isMobile`: se conserva viewport táctil de `390×844`, se omite la opción no soportada por Firefox y se mantiene la cobertura de layout. No se cambió código de la aplicación ni el Worker publicado.
- [x] Después de esa corrección, `mobile-navigation-ux.spec.ts` y `patients-real-ux-audit.spec.ts` se repitieron en Firefox, secuencialmente: **2/2 pasaron**; la búsqueda local informó `real_patient_search_local_render_ms=71` y no quedaron fixtures sintéticos.
- [x] Las mismas dos pruebas se repitieron en Chromium después del ajuste del arnés: **2/2 pasaron** en 22,0 s; la búsqueda local informó `real_patient_search_local_render_ms=40`.
- [x] Se repitió la suite completa de Firefox después de corregir el arnés: `--browser=firefox --workers=1 --retries=0`, 27 casos, **22 pasaron, 5 skips explícitos y 0 fallos**, en 6,1 minutos. Los cinco skips siguen siendo los tres casos de archivos clínicos que exigen Supabase local y los dos de Google real que exigen credenciales autorizadas.
- [ ] La corrida completa de 27 casos no queda marcada como totalmente limpia: conserva el registro del fallo transitorio/no reproducible de `odonto.full` y los cinco skips explícitos (tres archivos clínicos que exigen Supabase local y dos Google real que exigen credenciales autorizadas). La repetición aislada y las pruebas específicas posteriores reducen el riesgo, pero no sustituyen una nueva corrida total si se exige cero fallos históricos en el mismo artefacto del arnés.

### WebKit local

- [x] Se instaló el binario WebKit fijado por Playwright para intentar la cobertura del motor Safari local.
- [x] La ejecución de `odonto.full.spec.ts` en WebKit no llegó a iniciar el navegador: el host carece de `libgstreamer-plugins-bad1.0-0`, `libavif16` y `libwoff1`.
- [x] `playwright install-deps webkit` fue intentado; el instalador se detuvo porque requiere `sudo` interactivo y no se proporcionó contraseña desde el entorno de pruebas. No se alteró el sistema operativo ni se simuló una aprobación.
- [ ] WebKit local queda **no ejecutado por bloqueo de infraestructura**, no aprobado ni fallido funcionalmente. La cobertura real de iPhone en BrowserStack ya está registrada por separado, pero no reemplaza la ejecución del motor WebKit local si el gate exige ambos.

### Estado de esta ampliación

- [x] Todos los intentos, fallos de lanzamiento, skips, cambios mínimos del arnés, repeticiones, tiempos y limpiezas de Firefox/WebKit quedan registrados en este archivo.
- [x] La modificación del arnés volvió a pasar `pnpm check`: `svelte-check found 0 errors and 0 warnings`; no cambia el artefacto Cloudflare actualmente publicado (`37ed...`). Las pruebas continuaron ejecutándose con un solo worker por la restricción de memoria del equipo.
- [x] El dry-run posterior a la suite completa de Firefox volvió a leer la base por filtros acotados: `profesionales: 0`, `servicios: 0`, `pacientes: 0`; no fue necesario borrar ningún residuo.
- [x] Como cierre del cambio del arnés, se repitió la suite completa de Chromium contra la misma versión Cloudflare al 100 %: `--browser=chromium --workers=1 --retries=0`, 27 casos, **22 pasaron, 5 skips explícitos y 0 fallos**, en 5,8 minutos; `real_patient_search_local_render_ms=22`.
- [x] El dry-run posterior a esa corrida Chromium volvió a mostrar `profesionales: 0`, `servicios: 0`, `pacientes: 0`; no quedó ningún fixture conocido.
- [x] La relectura de Cloudflare posterior (`wrangler deployments list --name app --json`, ordenada por fecha) confirmó que sigue al 100 % el deployment `4665f770-ed11-4911-99ab-ad79de9c9eff` con la versión `37ed62d5-b4c5-4138-8518-209f874b4962`; no hubo cambio de tráfico durante esta ampliación.
- [x] `pnpm audit --audit-level=high` volvió a terminar con `No known vulnerabilities found`.
- [ ] La matriz de navegadores no puede declararse cerrada mientras WebKit local siga bloqueado y la corrida total de Firefox conserve el fallo histórico no reproducible; el estado global de lanzamiento continúa **NO-GO**.

## Registro de autorización e instrucciones del usuario — 2026-08-31

Esta sección fija el alcance operativo vigente para las siguientes corridas. No cambia
ningún resultado anterior ni convierte una prueba pendiente en aprobada.

### REGLA CENTRAL (texto literal)

> Pacientes, turnos, profesionales, consultorios, emails y archivos actuales son descartables.
>
> 1. Puedo crearlos, alterarlos, archivarlos o eliminarlos libremente durante las pruebas.
> 2. Lo protegido es el código, las migraciones, funciones, triggers, RLS, grants, constraints, Storage, secretos, configuración de Cloudflare y capacidad futura de operar correctamente con pacientes reales.
> 3. No ejecutaré DDL destructivo directamente sobre producción para “probar qué pasa”; eso se prueba en una base aislada construida desde migraciones.

### Flexibilización autorizada el 2026-08-31

El usuario aclara que la protección anterior no impide cambios operativos seguros: quedan
autorizados los pushes a GitHub, los deploys de Cloudflare y las migraciones a Supabase
cuando exista evidencia de alta seguridad. Cada uno exige antes un filtro explícito:
checkout/commit y diff revisados, secretos fuera del artefacto, `pnpm check`, tests
secuenciales aplicables, build reproducible y hash, destino identificado, compatibilidad
con el rollback y verificación posterior del artefacto/estado remoto. No se hará ninguna
promoción por comodidad ni se confundirá una autorización general con evidencia de que el
cambio sea seguro.

### Criterio adicional de reproducibilidad — precisión del usuario

“Byte a byte” significa comparar literalmente el output que consume Cloudflare, no sólo
observar el mismo comportamiento. Para cada build candidato se deben conservar los hashes
de todos los archivos de `.svelte-kit/cloudflare` (o del bundle final que Wrangler sube),
comparar sus valores sin que el nombre temporal del directorio contamine el resultado,
revisar `version.json`, manifiestos, IDs, timestamps y metadata no determinista, y registrar
el commit/hash exacto. Un E2E verde o dos respuestas equivalentes no sustituyen esta
comparación binaria.

### Autorización y criterios obligatorios

- [x] El usuario autoriza ejecutar la cobertura pendiente con todos los accesos disponibles, respetando sin excepciones la REGLA CENTRAL.
- [x] Se pueden crear, alterar, archivar y eliminar libremente los datos de prueba actuales, con manifiesto y relectura para conservar trazabilidad.
- [x] Código, migraciones, funciones, triggers, RLS, grants, constraints, Storage, secretos, Cloudflare y capacidad futura quedan fuera de cualquier purga o DDL destructivo directo.
- [x] Cuando una prueba directa esté bloqueada, se debe buscar una equivalencia técnica razonable (base aislada, versión no promovida, simulación controlada, contenedor, BrowserStack, dispositivo físico u otro runner), dejando claro qué propiedad demuestra y cuál no.
- [x] No se deben repetir pruebas ya demostradas salvo que haya cambiado código, configuración, versión, navegador, dispositivo, datos o hipótesis; las nuevas corridas deben buscar bordes distintos.
- [x] La auditoría debe cubrir código y comportamiento: los tests no sustituyen la revisión estática y la revisión estática no sustituye las pruebas operativas.
- [x] Deben registrarse todos los comandos, versiones, entradas, salidas, tiempos, errores, skips, fallos de método, hipótesis, correcciones, reintentos, fixtures, IDs de cleanup, relecturas, artefactos y riesgos residuales.
- [x] No se debe interrumpir una batería por comodidad; el proceso debe continuar secuencialmente mientras sea razonable y seguro para el código/configuración protegidos.
- [x] La aceptación se juzga por seguridad clínica, privacidad, integridad futura y experiencia diaria del profesional, no sólo por código HTTP o tests verdes.

### Cobertura solicitada después de retirar lo ya demostrado

La siguiente matriz es el alcance explícito que el usuario pidió ejecutar con permiso
absoluto. Cada línea conserva el objetivo; el estado se marcará sólo cuando exista
evidencia verificable.

#### Trazabilidad exacta y rollback real — crítico

- [ ] Congelar un checkout limpio y un commit único.
- [ ] Construir y calcular hashes reproducibles.
- [ ] Publicar una versión Cloudflare etiquetada con commit y hash.
- [ ] Confirmar que esa versión atiende el 100 %.
- [ ] Probar mezcla de versiones durante despliegue gradual.
- [ ] Ejecutar un rollback real y medir cuánto tarda la recuperación.

#### Backup y restauración completa — crítico

- [ ] Respaldar esquema, datos, Auth, metadata y Storage.
- [ ] Restaurar todo en un Supabase aislado, nunca sobre producción.
- [ ] Comparar conteos, relaciones y checksums.
- [ ] Abrir en la aplicación restaurada pacientes, historias, turnos y radiografías.
- [ ] Probar un backup incompleto o corrupto.
- [ ] Medir RPO y RTO reales.

#### Aislamiento entre consultorios y permisos — crítico

- [ ] Crear consultorios A y B con datos deliberadamente parecidos.
- [ ] Probar owner, admin, recepción, profesional vinculado, profesional no vinculado, readonly y maestro.
- [ ] Atacar cada ruta por interfaz, URL directa, HTTP y RPC.
- [ ] Intercambiar IDs, cookies, cursores y parámetros entre consultorios.
- [ ] Revocar membresías y asistencia durante una sesión activa.
- [ ] Confirmar que jamás se filtran datos clínicos, costos, imágenes o pacientes laterales.

#### Concurrencia e integridad clínica — crítico

- [ ] Dos altas iniciales simultáneas del mismo consultorio.
- [ ] Dos pestañas creando o editando el mismo paciente.
- [ ] Doble clic y respuesta perdida después del commit.
- [ ] Cincuenta reservas concurrentes sobre el mismo horario.
- [ ] Crear, cancelar y reprogramar simultáneamente.
- [ ] Guardar historia mientras otro usuario archiva o modifica el paciente.
- [ ] Eliminar registros entre carga y mutación.
- [ ] Confirmar idempotencia, ausencia de falsos éxitos y cero duplicados.

#### Autenticación, recuperación y sesiones — crítico

- [ ] Login inválido, vacío, con espacios, mayúsculas y usuario inexistente.
- [ ] Registro duplicado, contraseña débil y doble envío.
- [ ] Recuperación por correo válida, vencida y reutilizada.
- [ ] Sesión vencida durante cada mutación clínica.
- [ ] Refresh de token, varias pestañas, logout remoto y revocación inmediata.
- [ ] Cookies Secure, HttpOnly, SameSite, dominio, path y expiración.
- [ ] Verificar que prefetch, crawlers o navegación externa no disparen logout.
- [ ] Probar caída del rate limiter y de Supabase Auth sin mostrar falsos bloqueos.

#### Seguridad ofensiva controlada — crítico

- [ ] RLS e IDOR sobre todos los IDs y RPC.
- [ ] CSRF en POST y GET con efectos.
- [ ] XSS almacenado y reflejado en nombres, notas, historia, servicios y URLs.
- [ ] Inyección SQL/PostgREST mediante filtros y cursores.
- [ ] SSRF en logos, mapas, reseñas, Storage y redirects.
- [ ] Path traversal, MIME falso y archivos polyglot.
- [ ] Fuerza bruta, enumeración y bypass de rate limit.
- [ ] Fuga de tokens, URLs firmadas, cookies o PII en logs, analytics, historial y referrer.
- [ ] Secret scanning, SBOM y DAST seguro sobre staging.

#### UX clínica y accesibilidad — crítico

- [ ] Recorrer todas las tareas diarias de cada rol.
- [ ] Confirmar persistentemente paciente, fecha, hora, profesional, consultorio y estado.
- [ ] Probar loading, vacío, error, timeout, offline y permisos insuficientes.
- [ ] Verificar que los formularios conserven lo escrito después de un error.
- [ ] Foco, teclado, modales, Escape, restauración de foco y navegación sólo con teclado.
- [ ] Zoom al 200 %, texto grande y anchos 320/360/375/390/412 px.
- [ ] Back, forward, refresh, bloqueo del teléfono, cambio de pestaña y conexión intermitente.
- [ ] TalkBack en Samsung y auditoría automatizada WCAG.
- [ ] Registrar por separado las métricas SEQ/SUS y errores humanos que requieren profesionales participantes.

#### Cloudflare profundo y privacidad de caché — alto

- [ ] Confirmar que HTML y JSON autenticados nunca producen caché compartida.
- [ ] Probar contaminación de caché entre usuarios y consultorios.
- [ ] Validar tokens públicos, URLs firmadas, ICS y PDF.
- [ ] Probar chunks antiguos después de deploy y actualización del service worker.
- [ ] Revisar TLS, IPv4/IPv6, HSTS, CSP, MIME sniffing y framing.
- [ ] Verificar 404 y 500 humanas.
- [ ] Probar WAF, parámetros largos, Unicode y métodos HTTP inesperados.
- [ ] Investigar y cerrar la advertencia CSP observada en iPhone.

#### Fallos controlados y recuperación — alto

- [ ] Simular Supabase DB, Auth y Storage caídos.
- [ ] Timeouts, 401, 404, 429 y 5xx.
- [ ] Offline, paquetes perdidos, reconexión y latencia alta.
- [ ] Clock skew, zona horaria incorrecta y límites de medianoche.
- [ ] Cuota agotada, job detenido y backlog.
- [ ] Confirmar mensajes humanos y ausencia de éxito falso o pérdida de trabajo.

#### Capacidad y rendimiento — alto

- [ ] Poblar el volumen objetivo completo.
- [ ] Ejecutar pico realista y tres veces el pico.
- [ ] Búsquedas, Agenda e historias simultáneas.
- [ ] Uploads concurrentes.
- [ ] Jobs ejecutándose mientras profesionales usan la aplicación.
- [ ] Medir TTFB, navegación, mutaciones y búsquedas en p50/p95/p99.
- [ ] Medir CPU, memoria, conexiones y subrequests del Worker.
- [ ] Ejecutar la carga desde runner externo y staging, no desde esta PC limitada.

#### Pacientes, historia y archivos en casos límite — alto

- [ ] Acentos, apóstrofes, emoji, Unicode, espacios duplicados y n frente a ñ.
- [ ] Identidades con nombres, teléfonos y DNI repetidos dentro y entre consultorios.
- [ ] Pacientes sin teléfono, bloqueados y archivados.
- [ ] Historias largas, paginadas y concurrentes.
- [ ] JPG/PNG, archivo corrupto, cero bytes, MIME falso, polyglot, 25 MiB y 25 MiB + 1 byte.
- [ ] Papelera, restauración, permisos y expiración de URLs firmadas.

#### Push, service worker y cron avanzado — alto

- [ ] Habilitar alertas de fallo en cron-job.org y probarlas con un job controlado.
- [ ] Dos invocaciones simultáneas y reintentos idempotentes.
- [ ] Límites exactos de la ventana de dos horas.
- [ ] Turnos cancelados, reprogramados o modificados después de generar el recordatorio.
- [ ] Endpoints muertos y respuestas 410, 429 y 5xx.
- [ ] Permiso rechazado, bloqueado y recuperado.
- [ ] Dos dispositivos para el mismo paciente.
- [ ] Samsung Internet, Firefox Android y navegadores desktop.
- [ ] Service worker viejo, actualización y clicks con la aplicación cerrada.
- [ ] Esperar y demostrar accepted, received y displayed.

#### Google — alto si forma parte del lanzamiento

- [ ] Login y registro reales.
- [ ] PKCE, state, callback sin código, vencido o manipulado.
- [ ] Cancelación del usuario y prevención de open redirects.
- [ ] Google Calendar: conexión, desconexión, token vencido, revocación, reintentos e idempotencia.
- [ ] Reseñas: configuración, enlaces y redirecciones.
- [ ] Confirmar operatividad de la cuenta Google y su posible 2FA.

#### Dispositivos y redes restantes — medio/alto

- [ ] Más versiones de Safari/iOS en BrowserStack.
- [ ] Flujos internos completos, no solamente reserva pública.
- [ ] Android Chrome, Samsung Internet y Firefox.
- [ ] Orientación, teclado abierto, bloqueo, background y retorno.
- [ ] 4G degradado, red móvil, pérdida de paquetes y regiones distintas.

#### Observabilidad, alertas y soak — obligatorio antes del GO

- [ ] Activar logs persistentes durante la certificación.
- [ ] Dashboard de 5xx, CPU, memoria, latencia y jobs.
- [ ] Correlacionar versión, cf-ray, request y resultado.
- [ ] Probar que cada alerta llegue a una persona.
- [ ] Synthetic checks durante 6 horas.
- [ ] Soak de staging durante 24 horas.
- [ ] Ensayo del runbook de incidente y rollback.

### Regla de registro durante la ejecución

- [x] Esta autorización no permite ocultar fallos, convertir skips en verdes ni borrar evidencia.
- [x] Cada bloque se actualizará con evidencia concreta y se mantendrá la decisión global NO-GO hasta que los gates críticos estén demostrados.
- [x] Los datos sintéticos pueden eliminarse; los cambios en código, esquema, funciones, permisos, secretos o configuración requieren revisión explícita y verificación posterior.

## Registro de ejecución continuada — 2026-08-31 — ANTECEDENTE del candidato `fba21de` (estado separado de antecedentes anteriores)

Esta sección es la referencia de estado actual de la auditoría. Los bloques anteriores
siguen siendo antecedentes históricos y no se borran ni se reescriben, aunque mencionen
otra versión, otro resultado o un gate que en ese momento estaba bloqueado. Cuando una
prueba se repitió después de cambiar código, configuración, secreto o artefacto, el
resultado de abajo supersede sólo esa afirmación operativa para la decisión vigente.

### Hallazgo crítico descubierto en la prueba pública y corrección

- [x] **Antecedente conservado:** antes de la corrección, una prueba HTTP real contra el
  Worker ejecutó confirmar, cancelar y pedir reprogramación simultáneamente sobre el
  mismo turno sintético. Las tres respuestas informaron éxito; la relectura terminó con
  `status=cancelled` pero con `confirmed_at`, `cancelled_at` y
  `reschedule_requested_at` no nulos. Los tres intentos quedaron marcados como exitosos,
  aunque sólo la última escritura sobrevivió. Esto era un bug real de integridad y no un
  problema del arnés.
- [x] La causa quedó aislada en `apps/web/src/lib/server/public-appointments.ts`:
  cada request leía el mismo estado y el `UPDATE` sólo filtraba por `id` y
  `business_id`, por lo que una respuesta sin filas observadas no se distinguía de un
  cambio aplicado.
- [x] La corrección exige que el `UPDATE` coincida también con el `status` leído,
  solicita `select('id').maybeSingle()` y convierte cero filas en
  `PUBLIC_TOKEN_ACTION_CONFLICT`. La capa de acción traduce ese conflicto a un mensaje
  para la persona: `Este turno cambió mientras lo actualizábamos. Volvé a abrir el
  enlace y revisá su estado.`. No se modificaron DDL, RLS, grants, Storage ni secretos
  como parte de este arreglo.
- [x] Se añadió la expectativa unitaria del mensaje de conflicto en
  `public-appointments.test.ts`.
- [x] `pnpm --filter web check`: 0 errores y 0 warnings.
- [x] Vitest focalizado: 1 archivo, 5/5 tests.
- [x] Vitest completo secuencial (`pnpm test -- --maxWorkers=1`): 106 archivos,
  815/815 tests, 22,35 s.
- [x] La corrección quedó en el commit único
  `034ecbdd0548e1fe45806adcb0efc4747fa4ebf6`, mensaje
  `security: serialize public appointment actions`, y se subió a
  `prelaunch/cloudflare-20260830` junto con el tag
  `prelaunch-cloudflare-034ecbd`.
- [x] El checkout de producción usado para compilar se creó separado del worktree
  sucio de pruebas: `/tmp/cita-suite-audit-034ecbd`, `HEAD` exactamente igual al
  commit. La rama remota y el commit local coincidieron; el tag anotado apunta al mismo
  SHA mediante `^{}`.

### Reproducibilidad binaria del artefacto que consume Cloudflare

- [x] En el checkout limpio se ejecutaron dos builds Cloudflare con
  `NODE_ENV=production`, `CITA_BUILD_VERSION` y `GIT_COMMIT_SHA` iguales al commit,
  `SOURCE_DATE_EPOCH=0` y un solo proceso de build. Cada salida tuvo 105 archivos.
- [x] La comparación de manifiestos `path + sha256` de las dos carpetas
  `.svelte-kit/cloudflare` fue **IDENTICAL**: ambos manifiestos tienen SHA
  `9af9b539488eb0651cafe1ded98adbd821c76076fd59118bfe3e72a9d88140d3`.
- [x] `_worker.js` coincidió byte a byte en ambos builds con SHA
  `cf4056f946ba2822fb93035da445ea2b74c918e9bbbb7d646dffcc8db657d484`.
- [x] `/_app/version.json` coincidió con SHA
  `4e0abf919afd1588d6a05f2e0f18d8e7487f7765ca9f4c088a275cd3004f7b40` y contenido
  `{"version":"034ecbdd0548e1fe45806adcb0efc4747fa4ebf6"}`. No se observaron
  timestamps, IDs de build ni metadata variable dentro de ese output.
- [x] Un primer `wrangler versions upload` ejecutado desde la raíz del monorepo fue
  rechazado con `Missing entry-point to Worker script or to assets directory`; no
  publicó nada. Se conservó como error de procedimiento. La carga repetida desde
  `apps/web`, donde reside `wrangler.jsonc`, fue la única considerada válida.
- [x] La carga válida creó la versión `f26efcfc-0391-49c9-9fa5-48ba2ffab01e`, creada
  `2026-08-31T07:22:45.105956Z`, tag completo
  `034ecbdd0548e1fe45806adcb0efc4747fa4ebf6` y mensaje
  `prelaunch audit 034ecbdd0548e1fe45806adcb0efc4747fa4ebf6`.
- [x] La URL de preview de esa versión sirvió `version.json` exacto, `/login` con
  `private, no-store`, `/reservar/<business-id>` con `no-store` y headers HSTS,
  `nosniff`, `DENY`, `strict-origin-when-cross-origin` y Permissions Policy. El
  `Content-Security-Policy` incluyó nonce dinámico y los orígenes explícitos esperados.

### Mezcla, promoción, rollback y correlación actuales de Cloudflare

- [x] La mezcla gradual `87d94b10-f1bd-4d22-8f7d-67f9c05bffcf` dejó
  `f26efcfc…` al 1 % y `93988102…` (b1 ya certificado) al 99 %. El muestreo único y
  secuencial de 200 `version.json` recibió 4 respuestas del SHA nuevo, 196 del SHA
  anterior, 0 desconocidas y 0 errores.
- [x] La promoción `75046ed0-dbab-4236-8dce-4ca10d686e69` dejó `f26efcfc…` al 100 %;
  20/20 lecturas posteriores devolvieron el SHA nuevo.
- [x] Se ejecutó rollback real a b1 en `c7f6c381-1d68-45e8-abad-393b032a820a` y
  restauración del candidato en `b3473377-69d9-4c81-8949-626b367bc2b7`. El control
  plane informó 0,67 s y 0,81 s respectivamente; el primer `version.json` observado
  coincidió tras 31,027 s y 30,792 s con el sondeo conservador usado. Esos tiempos
  incluyen propagación/sondeo de borde y se reportan como RTO observado, no como una
  latencia aislada del API.
- [x] Durante la rotación de secreto, `wrangler secret put` generó versiones automáticas
  sin tag (`1450ef32…`, `46f85941…`, `dd50d81f…`). Cloudflare rechazó reutilizar el
  artefacto antiguo con el código 10220 (`A secret has changed since this version was
  active`). No se ocultó ni se tomó una versión automática sin verificar.
- [x] Tras ese rechazo se cargó un artefacto nuevo desde el mismo output reproducible:
  versión `3ed7a7a7-3cfb-4444-9516-5b92fbd334e7`, tag
  `034ecbdd0548e1fe45806adcb0efc4747fa4ebf6-secret-rotated`, mensaje
  `prelaunch racefix 034ecbdd0548e1fe45806adcb0efc4747fa4ebf6 post-secret-rotation`.
  El deployment actual es `890a9863-f69c-407f-9091-4bf7e0cbb0be`, 100 %.
- [x] `wrangler versions view` de la versión final confirmó el mismo tag/mensaje, sólo
  handler `fetch`, placement targeted `aws:sa-east-1`, compatibilidad `nodejs_compat` y
  las bindings esperadas; no es una versión automática sin etiqueta.
- [x] El manifiesto completo `path + sha256` del output que consumió esta carga quedó
  archivado en `audit-evidence/cloudflare/034ecbdd-manifest.txt`, fuera de `/tmp`.
  Su SHA es `9af9b539488eb0651cafe1ded98adbd821c76076fd59118bfe3e72a9d88140d3`, y
  coincide con los dos builds independientes; `_worker.js` y `version.json` conservan
  respectivamente `cf4056f9…d484` y `4e0abf9f…7b40`. El upload final reutilizó exactamente
  ese output, por lo que la comparación no se limita a que la aplicación “se comporte igual”.
- [x] El estado actual de `version.json` continúa mostrando exactamente el commit
  `034ecbdd…`; el deployment actual no es una versión sin tag.
- [x] Smoke posterior a la rotación contra `https://app.cita-suite.workers.dev`: `/_app/version.json`
  devolvió el commit exacto; `/login` respondió 200 con `private, no-store`; la reserva pública
  respondió 200 con `no-store`; ambos incluyeron HSTS, CSP con nonce, `nosniff`, `DENY`,
  referrer policy y Permissions Policy. Una ruta inexistente devolvió 404 con la página humana
  de “no encontrada”, sin error crudo.
- [x] Se abrió `wrangler tail app --format=json --sampling-rate=0.99` con TTY y se
  solicitó `/login` durante la ventana. Llegó un evento parseable con
  `scriptVersion.id=f26efcfc…`, `outcome=ok`, HTTP 200, `truncated=false`, sin
  excepciones, `cpuTime=2` y `wallTime=7` (valores de la invocación observada). El
  segundo recurso estático no produjo un evento adicional por caché. Una ejecución
  no interactiva anterior terminó sin eventos y se conserva como limitación del
  método, no como evidencia negativa.
- [x] Se repitió el tail después de la rotación definitiva: una petición real a `/login`
  correlacionó `scriptVersion.id=3ed7a7a7…`, `outcome=ok`, HTTP 200, `truncated=false`,
  sin excepciones ni logs de aplicación. El tail usado es efímero: no reemplaza logs
  persistentes ni un dashboard de auditoría.
- [x] Sonda HTTP ofensiva segura contra el deployment final: token público inválido en GET
  devolvió página humana 200/no-store; POST cross-origin a una acción pública fue rechazado
  con 403 sin CORS; GET de la acción no ejecutó mutación; job interno sin header y GET fueron
  405; header interno incorrecto fue 401 JSON; query de 9 KB y ruta Unicode no derribaron el
  Worker (200/no-store o página no disponible); PUT inesperado fue 405. No se enviaron secretos
  ni se alteraron datos. `TRACE` fue omitido por el cliente Fetch, que lo rechaza antes de
  emitir la petición; no se contó como prueba del servidor.
- [x] Sonda REST/RPC anónima contra el Supabase productivo, usando `anon` sin sesión, sobre
  19 tablas clínicas/tenencia y dos funciones (`list_user_business_contexts` y
  `user_has_business_access`) con el ID del consultorio de prueba: las tablas públicas
  devolvieron arrays vacíos, las tablas sensibles y RPC protegidas respondieron 401, y no hubo
  filas laterales ni datos clínicos. La lectura usó `limit=1` y no escribió nada; no reemplaza
  la matriz autenticada de cada rol ni un pentest independiente.
- [x] Filtros PostgREST adversariales secuenciales: comilla/OR y orden con intento de
  inyección fueron bloqueados con 403 por la capa perimetral; un cursor malformado devolvió
  400 y Unicode válido devolvió array vacío 200. No hubo ejecución de DDL, filas clínicas ni
  mensajes internos expuestos.
- [x] Secret scan reproducible sobre los 545 archivos versionados: no aparecieron claves
  privadas, tokens de proveedor ni credenciales en código de producción. Los únicos patrones
  de JWT/secret detectados están en 13 archivos de tests con valores ficticios; `.env` quedó
  fuera del índice y nunca se imprimió. No se contó este grep como reemplazo de un scanner
  dedicado ni de un SBOM formal.
- [x] Inventario de dependencias de producción con `pnpm list --prod --depth Infinity`:
  439 aristas y 134 paquetes únicos; la lista normalizada `paquete@versión` produjo SHA-256
  `b13f00d2718274750d2d21d9b9e7c605cfab4b7dfea24763e654374994f13567`. `pnpm audit` no
  reportó vulnerabilidades conocidas de producción. Este hash es trazabilidad del inventario,
  no una certificación SBOM firmada.

### Incidente de secreto y estado posterior

- [x] Una inspección inicial de la respuesta completa de la API de cron-job.org imprimió
  accidentalmente un header secreto en la salida de diagnóstico. El valor no aparece en
  este archivo ni se volverá a mostrar. Se trató como exposición y no como un dato
  descartable.
- [x] La primera tentativa de rotación actualizó el secreto del Worker, pero el deploy
  del artefacto histórico fue rechazado por el código 10220; el script restauró el
  secreto anterior y el header del job, sin dejar el endpoint sin respuesta.
- [x] La rotación definitiva generó un secreto nuevo en memoria, cargó un artefacto
  nuevo y actualizó `PATCH /jobs/7795525` sin imprimir el valor. El endpoint respondió
  `200`, `ok=true`, `push.configured=true`, `claimed=0`, `sent=0`, `failed=0` y
  `deadEndpoints=0` con el secreto nuevo; respondió `401` con el anterior.
- [x] El job quedó habilitado, POST, URL exacta del Worker, timeout 30 s, zona UTC,
  minutos `[0,10,20,30,40,50]`, sin expiración, y header presente. Se conserva la
  configuración `onFailure=false`/`onDisable=true` como riesgo operativo pendiente en
  ese corte histórico; el PATCH posterior quedó documentado al final.
- [ ] El `.env` local conserva el secreto anterior porque es un archivo de credenciales
  no versionado y no se debe reescribir exponiendo el nuevo valor en un patch. Por eso
  las invocaciones manuales locales al job deben usar el procedimiento seguro de
  producción; el Worker y cron sí quedaron coordinados y el secreto anterior ya no
  autentica.
- [x] Después de la rotación la API de historial respondió 200 con 50 elementos. El registro
  inmediatamente posterior a la actualización fue `status=4`, HTTP 401, duración 1.036 ms
  (`date=1788162628`); se conserva como fallo real de coordinación observado, no se maquilla
  como éxito. Las ejecuciones anteriores continuaban siendo `status=1`/HTTP 200.
- [x] Se observó una ejecución periódica posterior al PATCH con el header nuevo:
  historial HTTP 200, `status=1`, HTTP 200, duración 1.406 ms, `date=1788163830`
  (08:10:30 UTC). Otra ejecución inmediatamente anterior también fue `status=1`/HTTP 200
  (`date=1788163261`). Esto demuestra que el fallo 401 aislado de la transición no persiste
  en la cadencia normal; el probe manual con el secreto nuevo fue 200 y con el anterior 401.
- [x] **Antecedente congelado:** la política de notificación estaba en
  `onFailure=false`/`onDisable=true` en el momento del `401` de transición; por eso esa
  ejecución no generó alerta. La política vigente y la prueba de entrega pendiente están en
  la actualización posterior.

### Concurrencia pública en el Worker real después de la corrección

- [x] Preparación: se crearon consultorios, suscripciones, profesionales, servicios,
  asignaciones, pacientes Auth sintéticos y turnos `reserved` exclusivamente para estas
  rondas. Cada fixture fue identificado por UUID y se eliminó por filtros exactos; no se
  reutilizó un paciente real.
- [x] Dos errores de preparación quedaron registrados: primero se intentó insertar una
  suscripción que el trigger ya había creado (HTTP 409 por clave única); después se
  intentaron pacientes sin `owner_id` y la base respondió NOT NULL. Se corrigió el arnés
  usando la suscripción del trigger y un usuario Auth sintético. No son bugs de usuario.
- [x] Tres rondas contra `f26efcfc…` al 100 % usaron permutaciones de
  confirmar/cancelar/reprogramar. En cada ronda hubo exactamente un `200` con mensaje de
  éxito, dos respuestas de conflicto `400` con mensaje humano, una sola transición de
  estado, un único registro de auditoría ganador y exactamente un turno.
- [x] Ronda final contra el artefacto activo tras la corrección: confirmar 400/conflicto,
  cancelar 200/éxito, reprogramar 400/conflicto; estado final `cancelled`, sólo
  `cancelled_at` presente, una auditoría `appointment.public_cancelled` y tres intentos
  (`token_confirm=false/PUBLIC_TOKEN_ACTION_CONFLICT`,
  `token_reschedule=false/PUBLIC_TOKEN_ACTION_CONFLICT`,
  `token_cancel=true`). La misma prueba contra el artefacto actual se repitió después
  de rotar el secreto: confirmar y reprogramar fueron conflictos, cancelar fue el único
  éxito; el estado final y los timestamps fueron coherentes.
- [x] En todos los casos la cuenta de turnos quedó en 1 y la limpieza devolvió
  `business=0`, `patient=0`, `appointment=0` y usuario Auth sintético eliminado. El
  intento directo de borrar `audit_logs` devolvió error porque el log es append-only;
  la eliminación exacta del negocio hizo la cascada permitida y dejó cero residuo. El
  error de cleanup no se ocultó ni se usó para borrar por prefijo amplio.
- [x] Una variante del arnés sin header `Accept` recibió HTML 200 para los conflictos,
  pero el cuerpo mantuvo el mensaje de conflicto y nunca el mensaje de éxito. Con los
  headers de formulario del navegador (`Accept: text/html`) los conflictos fueron 400.
  Esto documenta la diferencia de negociación HTTP; la decisión de éxito se verificó
  por estado persistido, mensaje y auditoría, no sólo por código HTTP.

### Drift observado en la auditoría de intentos públicos

- [x] El `public_booking_attempts` remoto tiene columnas adicionales
  `appointment_id`, `idempotency_key`, `email_hash`, `device_hash`,
  `identity_bundle_hash`, `risk_score` y `risk_flags` que no existen en el SQL de
  migraciones versionado, en `packages/shared/src/database.types.ts` ni en el stack local
  recién reseteado. La historia `supabase_migrations.schema_migrations` no muestra una
  migración correspondiente.
- [x] Las filas nuevas dejan `appointment_id=NULL` y guardan el ID dentro de
  `metadata.appointment_id`; el evento no desaparece, pero la columna relacional no se
  utiliza. Esto es drift de esquema/configuración y no se corrige improvisando DDL sobre
  producción. Requiere reconciliar la migración fuente, tipos y uso de la columna antes
  del GO si se pretende consultar ese campo directamente.
- [ ] Mientras no se reconcilie ese drift, los informes de intentos deben consultar
  `metadata.appointment_id` y no asumir que `appointment_id` está poblado.

### E2E dirigido posterior al cambio

- [x] Una primera invocación directa de Playwright quedó omitida porque el proceso no
  recibió las credenciales del `.env`; se conserva como skip de arnés, no como verde.
- [x] Con un lanzador que lee `.env` sin imprimir valores y pasa las variables sólo al
  proceso hijo, `odonto.full.spec.ts` contra `https://app.cita-suite.workers.dev` y el
  consultorio de prueba pasó **1/1 Chromium en 37,1 s** y **1/1 Firefox en 1,2 min**,
  siempre con un worker y sin reintentos.
- [x] Repetición de la suite Playwright completa contra el deployment final, con un worker,
  `CI=1` y `--retries=0`: **22/27 pasaron, 5 skips explícitos, 0 fallos, 5,1 min**. Los
  skips corresponden a escenarios que el propio arnés exige ejecutar contra Supabase local,
  demo o proveedores externos no autorizados; no se contaron como verdes.
- [x] Suite de componentes/clientes posterior al commit: `test:client`, 7 archivos,
  **71/71 tests** pasaron secuencialmente en 13,90 s.
- [x] Matriz adicional de roles contra Cloudflare: se creó un consultorio sintético con
  owner, admin, recepción, profesional vinculado y solo lectura. Los cinco iniciaron sesión
  uno por uno; owner/admin conservaron Equipo, recepción/solo lectura fueron llevados a Agenda
  y profesional a Mis turnos, sin acceso lateral a Equipo. Todas las rutas esperadas coincidieron
  y la limpieza por UUID dejó cero negocios, profesionales y correos de la matriz.
- [x] Replay idempotente de acción pública en el deployment final: se creó un turno sintético,
  la primera confirmación se hizo por UI y un segundo POST de confirmación devolvió 200 con el
  mismo mensaje seguro. La relectura mostró exactamente un turno `confirmed`, sólo
  `confirmed_at`, cero `cancelled_at`/`reschedule_requested_at` y un único audit log para ese
  appointment. Cleanup posterior por paciente devolvió cero residuos.
- [x] Una primera relectura de cleanup desde `apps/web` falló sólo porque el arnés buscó `.env`
  en el directorio equivocado; se repitió apuntando al archivo raíz y confirmó cero residuos.
- [x] La relectura posterior de marcadores devolvió cero negocios, profesionales,
  servicios, pacientes y turnos E2E conocidos. Los intentos públicos de prueba se
  conservan como auditoría operativa; no son pacientes ni turnos activos.
- [x] La primera sonda auxiliar de cleanup consultó por error el nombre inexistente
  `export_sessions` y recibió 404 de PostgREST; no se interpretó como fallo de la app.
  La consulta corregida a `patient_export_sessions` respondió 200 con cero sesiones activas,
  y las relecturas de turnos/auditoría también devolvieron cero marcadores conocidos.
- [x] `pnpm audit --prod --audit-level high`: `No known vulnerabilities found`.
- [x] `git diff --check`, `HEAD`, rama remota y tag se verificaron después de publicar;
  los cambios de tests, capturas, backup y el documento siguen sin entrar al commit de
  producción.

### Backup/restauración y base aislada — estado actual

> **Corte conservado como antecedente:** las casillas de este bloque que dicen que el
> dump remoto no estaba demostrado describen el estado anterior a la captura ampliada
> del 31-08-2026. No se borran porque documentan intentos, límites y fallos reales; la
> actualización vigente y sus condiciones de cierre están al final de este documento.

- [x] En el stack Cita local se creó una fixture aislada con negocio, profesional,
  paciente con acentos/ñ, turno y usuario Auth sintético. El dump custom completo tuvo
  956.458 bytes, SHA `e2baeb6400949d68e004f6ea3fca388a41bb6c81fa3030a07c21f077cdc5049c`;
  el schema-only tuvo SHA
  `f928dfd5bbf789df1a57d27480df65926dd4b16c7f89674623c82014c8ce5060`.
- [x] Se detectó y corrigió un primer intento inválido que apuntaba al puerto 54322 de
  otro proyecto local PG17.4; el dump de ese intento no cuenta y quedó separado. El
  stack Cita válido usa el puerto 55422.
- [x] El restore completo en la base aislada `cita_audit_restore`, excluyendo sólo las
  líneas de objetos `cron` incompatibles con el contenedor, terminó status 0 en 3.220 ms.
  Se restauraron Auth, esquema público, tablas Storage y metadata dentro del proyecto
  aislado; no se tocó producción.
- [x] Conteos fuente/restaurado: negocio 1/1, profesional 1/1, paciente 1/1, Auth 1/1,
  objetos Storage 0/0, migraciones 76/76 y relaciones públicas 234/234. Los 46 cuadros
  públicos, 23 Auth y 10 Storage tuvieron conteos por tabla iguales.
- [x] El checksum semántico de datos (INSERT/setval normalizados, sin tokens aleatorios
  de `pg_dump`) coincidió en ambos lados:
  `ab66205c7c7d878c269f668acc8a00cec8c994ebc0219201254b2dd196baf948`.
- [x] El dump truncado a la mitad (478.229 bytes) falló tanto al listar como al
  restaurar con `could not read from input file: end of file`; la base destino conservó
  sus conteos y luego fue eliminada de forma explícita.
- [x] El reset local posterior se ejecutó con `supabase db reset --local --no-seed --yes`
  y reveló drift de infraestructura: el contenedor terminó en PG17.6.1.054 aunque
  `supabase/config.toml` declara `major_version=15`, y la primera corrida dejó el
  esquema público sin tablas. Se detuvo y reinició el stack con los parámetros válidos;
  las 76 migraciones volvieron a aplicar y pgTAP quedó verde. No se presenta esta base
  como paridad exacta PG15.
- [x] `pnpm exec supabase test db --local`: 19 archivos, 22 tests pgTAP, todos PASS.
- [ ] El backup completo **remoto de producción** sigue sin demostrarse: `pg_dump` por
  el pooler 6543 y variantes schema-only/internal file agotaron 60–180 s, produjeron
  cero bytes o fueron terminadas; el host directo IPv6 y pooler 5432 cerraron la sesión.
  Psql puntual sí funciona y confirmó servidor PG17.6 y DB de 26 MB, pero eso no equivale
  a un backup. No se afirma RPO/RTO remoto ni restore de radiografías en producción.
- [ ] Falta abrir en la aplicación un entorno aislado restaurado con pacientes, historias,
  turnos y radiografías; el restore SQL/semántico no sustituye ese E2E. El bloqueo de
  `pg_dump` y la diferencia PG15/PG17 mantienen G1 parcial.

### Relectura de gates al corte `1d5fa13` — ANTECEDENTE (supersedida por `fba21de`)

El snapshot inicial de G0/G1/G3/G6/G9 se conserva arriba como antecedente. Esta tabla es
la decisión de estado actual, basada únicamente en evidencia posterior y explícita:

| Gate | Estado actual | Evidencia suficiente | Pendiente que impide un cierre total |
|---|---|---|---|
| G0 — código, commit, artefacto y rollback | **APROBADO para el candidato final** | Checkout limpio, commit/tag, hashes byte a byte, manifiesto final archivado, versión etiquetada, mezcla 1/99, 100 %, rollback real del artefacto post-rotación, tail con `scriptVersion` de la versión de prueba y restauración final 100 %; la relectura más reciente correlaciona `1d5fa13…` con la versión `9c48ac8f…` | Mantener esta trazabilidad en cada cambio posterior; el RTO de borde observado es de esta corrida y no sustituye un runbook de incidente |
| G1 — backup y recuperación | **PARCIAL** | Dump SQL remoto oficial de public/auth/storage (y esquema private), restore aislado completo, conteos, hashes semánticos, integridad de 149 FKs, bytes de Storage descargados y re-subidos secuencialmente con 32/32 verificaciones | Retención durable/cifrada fuera de esta PC, restore integrado en un único stack Supabase aislado, E2E de aplicación restaurada y medición RPO/RTO |
| G2 — código/dependencias/build | **APROBADO para el commit** | check 0/0, Vitest 107 archivos/819 tests, cliente 7/71, audit limpio, build reproducible | No sustituye gates de datos, UX, backup ni observabilidad |
| G3 — datos/RLS/roles/concurrencia | **PARCIAL** | pgTAP 22/22, matriz HTTP de cinco roles y dos consultorios (0 filtraciones/5xx), IDOR sintético cross-tenant, concurrencia local y 50 reservas, carrera pública corregida y repetida | Revocación ordinaria durante sesión y enumeración completa de rutas/RPC ofensivas |
| G5 — UX humana/accesibilidad | **PARCIAL** | E2E desktop/móvil, iPhone BrowserStack, Samsung físico y flujos diarios automatizados | Profesionales participantes para SEQ/SUS/errores humanos, WCAG/TalkBack completo, WebKit local |
| G6 — observabilidad/operación | **PARCIAL/BLOQUEADO** | Tail efímero correlacionado con versión/cf-ray, headers y métricas puntuales | Logs persistentes, dashboard/alertas, p95/p99, synthetic 6 h y soak 24 h |
| G7 — proveedores externos incluidos | **FUERA DE ALCANCE** | Google sólo en los casos autorizados; WhatsApp y Mercado Pago excluidos por instrucción | No bloquear el alcance actual, pero no declarar integraciones excluidas como certificadas |
| G9 — scheduler/rollback | **PARCIAL** | cron-job.org autenticado, 50 ejecuciones históricas OK, dos ejecuciones periódicas posteriores a la rotación con HTTP 200, disparo Worker real, rotación validada, rollback real (incluido el artefacto final con el binding de secreto vigente) y política de alertas activada | Probar entrega humana de la alerta, runbook y soak |

**Decisión vigente: NO-GO.** La corrección de la carrera pública está verificada en el
Worker actual y G0 tiene evidencia material nueva, pero no se convierte en GO mientras G1,
G3, G5, G6 y G9 mantengan los pendientes explícitos. Ningún antecedente histórico se
borra ni se cuenta dos veces como evidencia del artefacto actual.

### Índice de esta continuación y errores que no se deben reinterpretar

- [x] Commit y tag: `034ecbdd…`, `prelaunch-cloudflare-034ecbd`, rama remota al mismo SHA.
- [x] Builds A/B y hashes: 105 archivos, manifiesto `9af9…40d3`, `_worker.js` `cf4056…d484`,
  `version.json` `4e0abf…7b40`; manifiesto archivado en `audit-evidence/cloudflare/`.
- [x] Wrangler: raíz rechazada por entrypoint; `apps/web` válida; versión inicial `f26efcfc…`;
  versión final post-rotación `3ed7a7a7…`; deployment actual `890a9863…`.
- [x] Cloudflare: mezcla `87d94b10…`, 4/196; promoción `75046ed0…`; rollback
  `c7f6c381…`; restore `b3473377…`; rollback post-rotación mediante la versión de prueba
  `aad0111e…` y restauración final `3ed7a7a7…` con tail de borde; secretos automáticos sin
  tag registrados.
- [x] Carrera pública: tres rondas más una ronda post-rotación; los errores de preparación
  (suscripción duplicada, `owner_id` nulo y cleanup append-only) quedaron diferenciados de
  los resultados funcionales.
- [x] E2E dirigido: skip inicial por variables no inyectadas; Chromium 1/1 y Firefox 1/1
  con lanzador seguro; cero fixtures activos.
- [x] Scheduler: lectura completa inicial que expuso un secreto (incidente rotado),
  documentación oficial de PATCH, rotación final, probes nuevo 200/anterior 401 e historial
  50; el primer intento de transición fue 401 y las dos ejecuciones periódicas posteriores
  fueron 200 con el header nuevo. La alerta histórica `onFailure=false` fue activada después;
  su entrega humana controlada sigue explícitamente pendiente. No se imprimen credenciales
  en este documento.
- [x] Backup: intento de puerto equivocado descartado, dump/restore local aislado,
  checksum, corrupción y drift PG17.6/PG15 registrados. La actualización posterior añade
  el dump SQL remoto completo, restore `full3`, RTO SQL medido y manifiesto/verificación de
  los 32 bytes de Storage; las limitaciones de integración, retención y RPO/RTO productivos
  siguen explícitas.
- [x] La regla de memoria/CPU se respetó: cada test/build pesado se ejecutó secuencialmente,
  con un solo worker; el muestreo de 200 versiones usó un único proceso Node secuencial.

## Actualización posterior — rollback del artefacto final con secreto vigente — 2026-08-31

- [x] Se cargó `aad0111e-d22b-49df-8d50-6b3f2edc95c5` con el mismo output Cloudflare de
  105 archivos y el tag `034ecbdd-rollback-binding-probe`; Wrangler lo desplegó al 100 %
  sin cambiar el código ni el manifiesto. El endpoint `/login` respondió 200 y
  `/_app/version.json` mantuvo el commit `034ecbdd…`.
- [x] Se observó tráfico real durante el cambio con `wrangler tail` (0,99 de sampling):
  9 eventos `outcome=ok`, `exceptions=[]`, `truncated=false`, todos con
  `scriptVersion.id=aad0111e…`; el primer evento ocurrió a las 09:15:17.720 UTC,
  aproximadamente 6,4 s después del inicio del deploy de la versión de prueba. A los
  4 s exactos de un intento anterior aún se observaba la versión final, por lo que no se
  confundió aceptación del control plane con propagación instantánea en el borde.
- [x] Se ejecutó el rollback real a `3ed7a7a7-3cfb-4444-9516-5b92fbd334e7`, la versión
  final post-rotación con tag `034ecbdd…-secret-rotated`; Wrangler lo aceptó a 100 % en
  0,95 s de operación (la medición envolvente de CLI fue 5,508 s). Un tail posterior
  observó `scriptVersion.id=3ed7a7a7…`, HTTP 200, `outcome=ok` y `exceptions=[]`.
- [x] La lista de deployments posterior confirmó como último deployment
  `e9426b31-a7e4-41d6-bc4d-ba842f80a773`, 100 % en `3ed7a7a7…`; `version.json` y `/login`
  volvieron a responder correctamente. La versión de prueba quedó sólo como antecedente
  de rollback, no recibe tráfico.
- [x] Esta secuencia demuestra que el artefacto etiquetado sigue desplegable después de
  rotar el secreto y que el retorno desde una versión compatible es operacionalmente
  posible. No se mezclan sus tiempos con el rollback histórico de `f26efcfc…` ni se
  presentan como un RTO contractual de producción.

## Actualización posterior — backup remoto ampliado y Storage binario — 2026-08-31

Esta sección tiene precedencia para el **estado actual** de G1. Los bloques anteriores
siguen siendo antecedentes y no se reinterpretan como si hubieran ocurrido después.

### Captura oficial de Supabase

- [x] El dump de datos remoto se obtuvo con `supabase db dump` desde un `--workdir /tmp`
  aislado, incluyendo `public,auth,storage`. El archivo no se copia al repositorio porque
  contiene PII, material de Auth y metadata; se conservan sus propiedades verificables:
  1.509.998 bytes, 6.870 líneas, SHA-256
  `f4b874207fc2ee21d16994a7629452ca288508f3b2a2f28c1e0607a268e2e434`, 84 secciones
  `COPY`, 6.158 filas totales y marcador `PostgreSQL database dump complete`.
- [x] La primera corrida con el `config.toml` del proyecto falló antes de conectar por la
  clave local obsoleta `local_smtp`; se conserva como error del procedimiento. La misma
  captura, repetida en `/tmp`, terminó correctamente y no se contó el primer archivo vacío.
- [x] El schema-only ampliado incluyó explícitamente `private` (dependencia de las
  restricciones de reseñas), además de `public,auth,storage`: 705.548 bytes, 19.260 líneas,
  SHA-256 `afe86d317c13de30dc06dfc30ac533038607edfa3ebdd31310cb4e3935e6e082`, 86 tablas
  y 196 funciones declaradas. El CLI informó `Dumped schema to ...`; su wrapper agrega
  `RESET ALL` y no emite el marcador estándar de `pg_dump`, por lo que se registra el
  mensaje de éxito del CLI y el hash, no un marcador que no existe.
- [x] Para restaurar en una base local realmente vacía se pre-crearon únicamente las
  extensiones compatibles que el dump referencia (`pgcrypto`, `pg_trgm`, `btree_gist`)
  dentro de `extensions`; no se ejecutó DDL sobre producción. El restore se hizo en
  `cita_audit_remote_restore_full3_20260831`, otra base aislada.
- [x] El schema restore creó 86 tablas, 196 funciones, 323 índices, 80 políticas y
  47 triggers; las únicas 6 líneas con `ERROR` fueron `permission denied to change default
  privileges` al intentar ACL de roles internos en la base local. No faltó ninguna tabla
  ni función de aplicación; `google_review_requests` y `google_review_settings` existen;
  todas las constraints quedaron `convalidated=true`.
- [x] La carga de datos se aplicó con `ON_ERROR_STOP=1`, status 0, sin errores y con 84/84
  secciones `COPY`. Un parser independiente contó 6.158 filas en el archivo y cada una de
  las 84 tablas tuvo exactamente el mismo conteo después del restore (0 discrepancias).
- [x] Conteos de control después del restore: Auth `users=35`, `identities=36`; Storage
  metadata `objects=32`, `buckets=1`; public `businesses=18`, `patients=106`,
  `appointments=97`, `clinical_entries=62`, `patient_radiographs=45`,
  `public_booking_attempts=176`, `google_review_requests=0` y
  `google_review_settings=0`. Son conteos del snapshot y no autorizan borrar producción.
- [x] Se comprobaron 149 relaciones FK con consultas generadas desde `pg_constraint`;
  el restore tuvo 0 filas huérfanas. Doce hashes semánticos deterministas de tablas clave
  (`businesses`, `patients`, `appointments`, `clinical_entries`, `patient_radiographs`,
  `professionals`, `services`, `business_users`, `google_review_requests`, `auth.users`,
  `auth.identities`, `storage.objects`) coincidieron con una lectura directa de producción
  en el corte de verificación (12/12). No se imprimieron filas.
- [x] Se midió un segundo restore limpio desde los mismos artefactos en
  `cita_audit_remote_rto_20260831`: schema 4.993 ms (6 errores ACL esperados), datos
  491 ms, total SQL 5.484 ms; status 0, 86 tablas, 270 filas de las tablas de control y
  `invalid_constraints=0`. Es un RTO de laboratorio PG17.6 en esta PC, no un RTO de
  producción ni una promesa de recuperación frente a una caída real.

### Bytes reales de Storage

- [x] Se recorrió recursivamente el bucket privado `patient-clinical-files` sin mostrar
  nombres de rutas: topología 3/8/16/32 y 32 objetos hoja (6 PNG, 16 WebP, 10 JPEG),
  15.675.483 bytes. Cada objeto fue descargado secuencialmente con la service key sólo en
  memoria, y se verificó su SHA-256. El manifiesto sin nombres de pacientes quedó en
  `audit-evidence/backup/20260831-storage-bytes-manifest.txt`; su hash combinado ordenado es
  `fd6c4a424b92bc9d891745e9d4e5deb07c7f6c9236eb9b8623948fc83ee99be7`.
- [x] Los 32 bytes se subieron uno por uno al Storage local aislado (bucket privado ya
  existente) usando `x-upsert=true`; una segunda caminata y descarga verificó 32/32 tamaños
  y hashes idénticos, 0 discrepancias. La repetición cronometrada tardó 1.033 ms para
  re-subir 15.675.483 bytes; la primera descarga completa fue secuencial y sus hashes
  quedaron en el manifiesto. Esto demuestra backup y restauración de bytes y metadata de
  Storage como operaciones separadas, sin tocar el Worker ni la producción.
- [ ] Todavía no se demostró un **único** stack aislado donde el Postgres restaurado
  `cita_audit_remote_restore_full3_20260831`, el servicio Storage y la aplicación apunten
  simultáneamente a los mismos datos; el servicio local usado para la verificación de bytes
  pertenece al stack local activo y no fue reconfigurado para esa base, precisamente para
  no alterar otras pruebas. Falta el E2E de aplicación restaurada (paciente, historia,
  turno y radiografía), retención durable/cifrada fuera de `/tmp`, y medir RPO/RTO reales.
- [ ] La primera restauración del schema acotado (`public,auth,storage`) falló de forma
  reproducible porque omitía `private` y dejó 55 errores dependientes; otra restauración
  sin extensiones dejó 129 errores. Ambas bases son sólo antecedentes aislados y no se
  mezclan con el restore válido `full3`.

### Seguridad y trazabilidad del procedimiento

- [x] No se ejecutó DDL destructivo contra Supabase productivo. Las bases locales de
  restauración fueron nombres explícitos y separados; el schema se adaptó sólo en el
  stream de importación para reemplazar propietarios internos por `postgres`.
- [ ] Durante un diagnóstico de procesos, una URL de conexión de base de datos apareció
  transitoriamente en la lista de procesos de la terminal. No se copió a este documento,
  no se volvió a imprimir ni se incluyó en Git; por tratarse de una credencial de conexión,
  la rotación administrativa y la invalidación de la URL histórica quedan como requisito
  antes del GO. Esta observación se registra como incidente de procedimiento, no como
  evidencia de una fuga de datos clínicos.

### Relectura de G1 después de la captura

- **Estado actual: PARCIAL, ya no BLOQUEADO por ausencia de dump SQL.** Hay evidencia de
  datos, esquema, Auth, metadata de Storage, bytes binarios, conteos, hashes y relaciones.
- **No convertir en APROBADO:** faltan un stack aislado integrado para abrir la aplicación
  restaurada, retención durable/cifrada, RPO/RTO medidos, y la rotación de la credencial de
  conexión expuesta durante el diagnóstico. La decisión global permanece **NO-GO**.

## Actualización posterior — revocación durante sesión y ayuda maestra — 2026-08-31

- [x] Una corrida inicial de `account-assistance.spec.ts` quedó en skip porque el arnés se
  lanzó desde el worktree aislado sin localizar el `.env` raíz; se conserva como error de
  preparación, no como evidencia funcional.
- [x] Repetida con las variables leídas por ruta absoluta y sólo en el proceso hijo,
  `account-assistance.spec.ts` contra el Worker final pasó **1/1 en 35,8 s**, con un único
  worker y cero reintentos. El owner activó la ayuda, el maestro abrió el consultorio,
  configuró un servicio, el owner detuvo la ayuda y la sesión maestra perdió el acceso a
  ese consultorio inmediatamente; el estado revocado y la interfaz sin datos laterales
  fueron verificados.
- [x] Relectura posterior con service role, por prefijos exactos del fixture, devolvió
  `businesses=0` y `allowed_emails=0`; no quedaron usuarios ni datos de la matriz.
- [x] Esta corrida cubre una revocación de asistencia durante sesiones activas y la
  experiencia del panel maestro; no reemplaza revocar una membresía ordinaria durante una
  mutación clínica en cada rol, que permanece pendiente en G3.
- [x] Un intento separado de revocar una membresía ordinaria desde una sesión sintética
  llegó a `/odonto/pendiente?reason=rate_limited` durante el bootstrap de ese usuario antes
  de poder abrir la Agenda; no se contó como prueba positiva ni como bug de autorización.
  La membresía, consultorio, email y usuario de ese intento se eliminaron por IDs exactos
  (`revocationRows=1`, `businessesLeft=0`, `emailsLeft=0`). El límite de alta alcanzado por
  la repetición de fixtures es un bloqueo operativo del arnés y requiere una ventana o
  identidad preautorizada para probar esa variante sin falsear el resultado.

## Actualización posterior — CSRF autenticado en Cloudflare — 2026-08-31

- [x] Se inició sesión con la cuenta sintética de prueba contra el Worker final y se
  comprobó una navegación normal a `/odonto/agenda`: HTTP 200 y `cache-control:
  private, no-store`.
- [x] Un POST de formulario a `?/update_status` con `Origin` y `Referer` de
  `https://evil.example`, campos de turno inválidos y sin intención de modificar una fila,
  fue rechazado por SvelteKit con HTTP 403 y el texto `Cross-site POST form submissions are
  forbidden`. No hubo mutación ni exposición de datos.
- [x] Un primer intento auxiliar con cuerpo `text/plain` recibió 404 porque no era una
  solicitud de formulario; se conserva como error de método y se repitió con
  `application/x-www-form-urlencoded`, que produjo el 403 esperado. El cliente de pruebas
  sin `Origin` también recibió 403, coherente con una política que exige origen de formulario
  verificable; no se interpretó como bypass.

## Actualización posterior — scheduler y alertas cron-job.org — 2026-08-31

Esta sección corrige sólo la lectura del **estado actual** del scheduler. Las líneas
anteriores que conservan `onFailure=false` describen el estado histórico antes del PATCH
de alertas y no se eliminan porque explican el fallo de coordinación observado.

- [x] El job `7795525` continúa habilitado, con POST cada diez minutos en UTC, timeout de
  30 segundos, URL del Worker y header secreto coordinado después de la rotación. La
  lectura de configuración posterior al cambio confirmó `onFailure=true`,
  `onFailureCount=1`, `onSuccess=true` y `onDisable=true`; ya no es correcto describir la
  política vigente como `onFailure=false`.
- [x] La configuración de alerta se activó mediante PATCH autenticado y se volvió a leer
  sin imprimir el header ni ningún secreto. Los dos intentos posteriores de prueba
  controlada de entrega no mutaron el job: la API respondió `429` antes de aceptar un
  cambio, y se dejó de reintentar para no convertir la prueba en presión sobre el límite
  de la API.
- [ ] Falta provocar una falla controlada con un job/endpoint de prueba y demostrar que
  cron-job.org entrega la alerta a una persona, que el aviso contiene contexto accionable
  y que el job se recupera sin duplicar trabajo. Hasta esa entrega observada, G9 sigue
  parcial aunque la política ya esté activada.
- [x] Se conservan como antecedentes separados el `401` de la transición de secreto y
  las ejecuciones periódicas posteriores `status=1`/HTTP 200; no se mezclan con una alerta
  que todavía no fue observada de punta a punta.

## Actualización posterior — XSS almacenado y reflejado en superficies clínicas — 2026-08-31

- [x] Se hizo una inspección estática de los sinks de mayor riesgo (`{@html}`, `innerHTML`,
  `outerHTML`, `insertAdjacentHTML`, `document.write`, `srcdoc` y esquemas
  `javascript:`) en el código de la aplicación; no se encontraron usos en las rutas y
  librerías revisadas.
- [x] Se creó un paciente sintético descartable con un payload HTML/JS en el nombre y se
  insertó el mismo payload en descripción y nota interna de una entrada clínica. El
  registro se abrió en `Datos`, `Historial` y en los resultados de búsqueda de Pacientes
  contra el Worker final, incluyendo el query de búsqueda reflejado.
- [x] En todas esas superficies el payload se mostró como texto escapado: no apareció el
  HTML crudo en el documento, no se creó ninguna imagen con el atributo de prueba y una
  bandera de ejecución permaneció en `false`. No hubo ejecución de script almacenado ni
  reflejado.
- [x] Se eliminaron por IDs exactos la entrada clínica y el paciente sintéticos y se
  verificó que no quedaran filas del fixture. No se imprimieron nombres, tokens ni rutas
  de Storage.
- [ ] Esta prueba dinámica no sustituye un DAST autenticado completo, CSP report-only,
  pruebas de otros navegadores/dispositivos ni una revisión manual de cada campo nuevo;
  esas variantes siguen siendo una condición de cierre de seguridad antes del GO.

## Actualización posterior — revisión de URLs, redirects, SSRF y logo remoto — 2026-08-31

- [x] No se encontraron sinks de navegación server-side construidos directamente desde
  parámetros de usuario en las rutas revisadas. Los callbacks OAuth retornan siempre a
  rutas internas; `safeAssistanceReturnTo` sólo permite paths locales bajo `/odonto` y
  `/r/{token}` valida formato, HTTPS y host de Google antes de emitir un `303`.
- [x] `resolveMapsUrl` acepta únicamente HTTPS y los hosts/rutas de Google Maps
  explícitamente permitidos; ante un valor inválido genera un enlace de búsqueda de
  Google desde la dirección o devuelve `null`. Las pruebas unitarias cubren hosts
  externos, HTTP, shorteners ambiguos, basura y ausencia de dirección.
- [x] Las comprobaciones de archivos clínicos fijan bucket/path al bucket privado de
  imágenes, generan URLs firmadas desde Supabase y hacen `fetch` server-side con
  `redirect: 'manual'`, timeout y validación de MIME/magic bytes. No siguen una URL de
  redirección controlada por un registro clínico.
- [x] La prueba de open redirect/SSRF de reseñas contra el Worker rechazó un destino
  persistido en `example.com` con 404 y no devolvió `Location`; un destino Google válido
  produjo 303. No se imprimieron tokens ni destinos clínicos.
- [ ] **Hallazgo de UX/CSP reproducible:** el formulario de negocio acepta cualquier
  `https://` para `logo_url`, y el HTML público lo incluye literalmente, pero la CSP
  vigente declara `img-src 'self' data: blob: https://*.supabase.co`. Con un logo sintético
  `https://example.com/logo-test.png`, el navegador Chromium recibió `naturalWidth=0`,
  `requestfailed: csp` y el mensaje de bloqueo de CSP, aunque la respuesta HTML fue 200.
  El valor original `null` se restauró y la relectura confirmó la restauración. Esto no es
  SSRF server-side, pero sí una contradicción entre validación, configuración y experiencia
  del profesional/paciente. Antes del GO hay que elegir y probar una solución coherente:
  restringir/normalizar logos a orígenes autorizados con mensaje claro, o ampliar la CSP
  con una revisión explícita de privacidad y fallback visual; no se marca como corregido.

## Actualización posterior — matriz HTTP de roles y aislamiento entre consultorios — 2026-08-31

- [x] Se levantó una matriz sintética con cinco membresías activas en el consultorio A
  (`owner`, `admin`, `reception`, `professional` vinculado y `readonly`) y un consultorio B
  con paciente, profesional, servicio y turno deliberadamente parecidos. La preparación
  fue hecha con usuarios confirmados y suscripciones temporales de prueba; no se ejecutó
  DDL ni se reutilizaron datos comerciales.
- [x] La primera corrida amplia quedó fuera de evidencia porque el arnés se bloqueó al
  volver a autenticar en cada solicitud. Se detuvo con un PID explícito; una consulta
  posterior comprobó cero negocios, pacientes y profesionales `role-matrix` antes de
  repetir. También se conserva como error de preparación un intento inicial que chocó con
  el constraint de suscripciones al usar una combinación inválida de estado/permanencia.
- [x] La corrida válida ejecutó secuencialmente 20 solicitudes autenticadas al Worker:
  Agenda, Equipo y tres rutas con IDs del consultorio B por cada uno de los cinco roles.
  Hubo 0 respuestas 5xx y 0 cuerpos que contuvieran el marcador clínico del consultorio B;
  paciente y turno ajenos respondieron 404 para los cinco roles.
- [x] En la ruta de Equipo sólo `owner` y `admin` recibieron 200; `reception`,
  `professional` y `readonly` fueron redirigidos, sin shell administrativo. El resultado
  coincide con la política de permisos de la aplicación y no depende sólo de ocultar
  botones.
- [x] Una segunda matriz de mutación, con fecha y disponibilidad válidas, demostró que
  `reception` puede crear exactamente un turno (delta de filas `+1`), mientras que
  `professional` y `readonly` recibieron el mensaje de permisos y el delta total no
  aumentó. Las respuestas de acciones SvelteKit fueron HTTP 200 por el contrato de
  `fail()`; se verificó el cuerpo y la base, no se interpretó el estado HTTP aislado como
  éxito.
- [x] Todos los negocios, filas clínicas y usuarios de la matriz se eliminaron por IDs
  registrados; la relectura final no encontró residuos con esos marcadores. No se tocó el
  consultorio real ni se usaron borrados amplios sobre producción.
- [ ] Esta matriz cubre una muestra controlada de rutas/roles y no reemplaza la revocación
  ordinaria durante una sesión ya abierta, la enumeración completa de RPC/Storage ni las
  pruebas de cada mutación clínica; esos puntos siguen abiertos en G3.

## Actualización posterior — revisión ofensiva de endpoints Web Push — 2026-08-31

- [x] La inspección de `isValidSubscriptionPayload` confirmó que las claves Web Push se
  validaban por forma, HTTPS, tamaño y ausencia de IP/hosts locales, pero aceptaban un
  hostname público arbitrario. Como ese valor termina en `webpush.sendNotification`
  server-side, la condición era insuficiente para cerrar SSRF: un endpoint con DNS
  controlado por un atacante podía convertirse en un proxy de salida o cambiar de destino
  después de guardarse.
- [x] El riesgo se reprodujo de forma no destructiva con las claves criptográficas efímeras
  del arnés y `https://example.com/push`: la validación anterior devolvía `true`; no se
  envió ninguna notificación real ni se escribió ese endpoint en producción.
- [x] Se agregó una allowlist estricta de hosts de servicios Web Push soportados (FCM,
  Mozilla, Apple y subdominios WNS), manteniendo HTTPS, sin credenciales, sin puertos
  alternativos, sin IP literal, sin hosts locales y con validación de claves. Los tests
  nuevos cubren cada familia permitida, host arbitrario y look-alike controlado.
- [x] La suite focalizada de push pasó **34/34** en un worker después del cambio. La
  publicación del fix y la verificación contra el Worker final quedan registradas en la
  relectura de trazabilidad posterior; hasta entonces esta casilla no se usa para aprobar
  el artefacto en producción.

## Relectura del corte `4f4b28f` posterior al fix de Web Push y smoke HTTP — 2026-08-31 — ANTECEDENTE de `fba21de`

Esta sección tiene precedencia sobre los estados actuales anteriores. No reescribe ni
borra sus antecedentes: el cambio de código, el nuevo build y el nuevo deployment
invalidan cualquier afirmación de que la versión `034ecbdd…` sea la que se está
certificando ahora.

### Trazabilidad reproducible y publicación

- [x] El commit actual es `4f4b28f5d6918f37d4de592b3fdfccc009b0f93b`, con el fix de
  validación de destinos Web Push y sus tests. El checkout aislado
  `/tmp/cita-suite-audit-4f4b28f` quedó limpio, y el branch remoto
  `prelaunch/cloudflare-20260830` fue verificado con el mismo SHA. Las modificaciones
  de E2E, capturas y este documento quedaron fuera de ese commit.
- [x] Se instalaron dependencias con `pnpm install --frozen-lockfile` en ese checkout y
  se ejecutó `pnpm --filter web build:cloudflare` dos veces, siempre con
  `NODE_ENV=production`, `CITA_BUILD_VERSION=4f4b28f5…`, `GIT_COMMIT_SHA=4f4b28f5…` y
  `SOURCE_DATE_EPOCH=0`. Los dos directorios `.svelte-kit/cloudflare` fueron idénticos
  mediante comparación recursiva y manifiesto ordenado de **105 archivos**; el
  manifiesto archivado es
  `audit-evidence/cloudflare/4f4b28f-build-manifest.txt` (no está en el repositorio)
  y su SHA-256 es `d0f21b65991bb4ce8140dbda6f0f9d053a2f345be7b772307b3a565c2991fa62`.
- [x] El `_worker.js` de ambos builds tiene SHA-256
  `cf4056f946ba2822fb93035da445ea2b74c918e9bbbb7d646dffcc8db657d484`; el
  `/_app/version.json` generado contiene exactamente
  `{"version":"4f4b28f5d6918f37d4de592b3fdfccc009b0f93b"}`. No se confundió igualdad
  de comportamiento con igualdad byte a byte del output de Cloudflare.
- [x] Wrangler cargó ese output como versión
  `f713a7d7-afc1-4132-8982-fc2e31a0de66`, con tag
  `4f4b28f5d6918f37d4de592b3fdfccc009b0f93b-manifest-d0f21b65` y mensaje
  `prelaunch push SSRF hardening 4f4b28f5`. La vista de versión confirmó handler
  `fetch`, `nodejs_compat`, `PUBLIC_SITE_URL` de Cloudflare y sólo nombres de secretos,
  nunca sus valores.
- [x] Esa versión fue desplegada al **100 %** en el deployment de
  `2026-08-31T10:01:38.025Z`. La lista de deployments la mostró como la última versión
  activa; no se dejó una mezcla residual con `034ecbdd…`.

### Smoke de borde, caché y tail correlacionado

- [x] El Worker real devolvió `/_app/version.json` con el SHA exacto; `/login` HTTP 200
  con `private, no-store`; la reserva pública HTTP 200 con `no-store`; y una ruta
  autenticada sin sesión HTTP 303 hacia `/login`. El cuerpo no expuso claves privadas,
  `service_role`, `VAPID_PRIVATE`, `MASTER_EMAIL`, `INTERNAL_JOB_SECRET`, tokens de
  sesión ni stack traces. La clave anon pública que SvelteKit embebe en el cliente se
  distingue de esos secretos y no se contabiliza como fuga privada.
- [x] `/login` mantuvo HSTS, CSP con nonce, `Permissions-Policy` restrictiva,
  `Referrer-Policy: strict-origin-when-cross-origin`, `X-Content-Type-Options: nosniff`
  y `X-Frame-Options: DENY`. La ruta `404` devolvió una página humana con
  `no-store, max-age=0`; no se mostró un error crudo.
- [x] Un `wrangler tail --format json` durante las solicitudes al nuevo Worker observó
  `scriptVersion.id=f713a7d7-afc1-4132-8982-fc2e31a0de66`, `outcome=ok`, HTTP 200,
  `truncated=false` y `exceptions=[]`. Un POST de validación maliciosa al endpoint de
  push observó el mismo `scriptVersion`, HTTP 400 y ninguna excepción.
- [x] La matriz HTTP anónima secuencial cubrió `/`, login, recuperación, términos,
  privacidad, reserva válida/inexistente, turno inválido, enlace de reseña inválido,
  Agenda y Pacientes privados, ambos jobs internos por GET y el endpoint de webhook.
  Los resultados fueron: `/` 302 a `/login`; páginas públicas 200; reserva y turno
  inválidos 200 humanos y `no-store`; `/r/invalido` 404 humano; `/odonto/*` 303 a login;
  jobs por GET 405; webhook no habilitado en GET 404. No apareció ningún secreto privado,
  stack trace ni marcador de error de servidor en los cuerpos. Los jobs responden 405
  sin `cache-control` explícito, pero no entregan datos sensibles; el POST autenticado
  del scheduler sigue siendo el camino operativo y está cubierto por su sección propia.

### Prueba dinámica del límite de destinos Web Push

- [x] Con un turno reservado real de prueba, se enviaron tres payloads efímeros al
  endpoint productivo: `https://example.com/push`, el look-alike
  `https://fcm.googleapis.com.evil.example/push` y una variante HTTP. Los tres
  recibieron HTTP 400 y el mensaje humano de que no se pudo preparar el recordatorio.
- [x] La lectura independiente de Supabase mostró `push_devices` en 18 filas antes y
  después, y cero filas con el endpoint arbitrario. No hubo llamada de envío ni escritura
  de suscripción; el token del turno y las claves sólo vivieron en memoria del proceso y
  no se imprimieron.
- [x] La suite focalizada de push quedó en **34/34** y la suite completa posterior al
  cambio en **106 archivos/816 tests**, todos verdes con un worker. La prueba confirma
  que el código publicado rechaza destinos HTTPS arbitrarios sin romper los hosts
  soportados por el arnés.

### Decisión posterior al despliegue

- [x] La trazabilidad G0 y el código G2 se actualizan al commit/versiones de esta
  sección. Las evidencias de `034ecbdd…` quedan como antecedentes, no como sustituto de
  la certificación actual.
- [ ] El hallazgo de UX/CSP de logos externos continúa abierto y no se altera por este
  fix: la validación de `logo_url` todavía acepta `https://` arbitrario mientras la CSP
  permite sólo `self`, `data:`, `blob:` y `*.supabase.co`; por eso un logo externo probado
  siguió bloqueándose en el navegador. No se marca como resuelto por el mero hecho de que
  el nuevo Worker esté sano. La decisión global permanece **NO-GO** hasta resolverlo o
  aprobar explícitamente una política de orígenes y privacidad con una nueva medición.

## Relectura del corte `1d5fa13` — cierre del hallazgo de logo/CSP — 2026-08-31 — ANTECEDENTE de `fba21de`

Esta sección supersede únicamente el hallazgo de logo/CSP de la sección anterior. El
hallazgo original y su reproducción permanecen intactos como antecedente; no se
reinterpreta como si nunca hubiera existido.

- [x] Se eligió la alternativa de menor exposición: no se amplió `img-src` a cualquier
  HTTPS. `isAllowedPublicImageUrl` acepta rutas relativas del mismo origen, el host
  público configurado/fallback y el host exacto de Supabase configurado, y rechaza
  terceros, look-alikes, credenciales, puertos alternativos y protocolos inseguros.
  `getPublicBusinessBySlug`, la vista pública de turnos y los profesionales sanitizados
  aplican la misma regla al renderizar; un valor heredado no autorizado se convierte en
  ausencia de imagen antes de llegar al navegador. El formulario de negocio lo rechaza
  con una explicación accionable y conserva los valores escritos.
- [x] El commit de la corrección es `1d5fa13eb35b6fda3c6c947110e8f1e97b49fa02`, ya
  publicado en `prelaunch/cloudflare-20260830` con el mismo SHA. `pnpm check` quedó en
  0/0, la suite completa en **107 archivos/819 tests**, la suite cliente en **7/71** y
  la focalizada de imágenes en **42/42**.
- [x] La comparación byte a byte del output que Wrangler consume incluyó el wrapper y
  el SSR: **105 archivos** de `.svelte-kit/cloudflare` más **267 archivos** de
  `.svelte-kit/output/server`, 372 entradas idénticas en dos builds con
  `SOURCE_DATE_EPOCH=0`. El manifiesto combinado archivado es
  `audit-evidence/cloudflare/1d5fa13-cloudflare-server-manifest.txt` (no está en el repositorio)
  y su SHA-256 es `dd962a9c61c8eee7b1a54f219fc249531a588882de2405e0861db2f6a94748f6`.
  `_worker.js` conserva SHA `cf4056f946ba2822fb93035da445ea2b74c918e9bbbb7d646dffcc8db657d484`;
  el `version.json` generado contiene exactamente el commit `1d5fa13…`.
- [x] Wrangler cargó la versión `9c48ac8f-4804-44b0-9d56-abbd6c492b59` con tag
  `1d5fa13eb35b6fda3c6c947110e8f1e97b49fa02-manifest-dd962a9c` y la desplegó al 100 %
  en el deployment `abf97a4a-c326-4c84-a062-449d7a4d3c57` (`2026-08-31T10:21:25.422585Z`).
  `/_app/version.json`, `/login` y la reserva pública respondieron desde Cloudflare;
  el tail correlacionó `scriptVersion.id=9c48ac8f…`, HTTP 200, `outcome=ok`,
  `truncated=false` y `exceptions=[]`.
- [x] Reproducción productiva del caso permitido: se asignó temporalmente el logo
  propio `https://app.cita-suite.workers.dev/logo-cita-suite.png` al negocio de prueba.
  La reserva devolvió HTTP 200, mostró una imagen (`naturalWidth=1254`), tuvo cero
  errores de consola y cero requests fallidos; el valor original se restauró y se
  verificó por lectura independiente.
- [x] Reproducción productiva del caso bloqueado: se asignó temporalmente
  `https://example.com/logo-test.png`. El HTML no incluyó el valor externo, no hubo
  imagen externa ni request a `example.com`, y el navegador terminó con cero errores
  de consola o requests fallidos. El valor original se restauró (`restored=true`).
- [x] E2E autenticado de configuración: el owner de prueba ingresó el logo externo y
  envió el formulario. La aplicación permaneció en `/odonto/configuracion/negocio`,
  mostró el mensaje accionable y conservó el texto escrito; una lectura de Supabase
  confirmó que la fila no cambió. El único mensaje de consola observado en esa
  navegación fue el `400` esperado de la respuesta de validación (no un `pageerror` ni
  una excepción JavaScript); una navegación de control sin envío tuvo 0 errores y 0
  requests fallidos.
- [x] **Estado actual del hallazgo:** cerrado para el candidato `1d5fa13…`; la
  contradicción validación/CSP ya no se reproduce y no se amplió la política de
  privacidad. La decisión global continúa **NO-GO** por los gates independientes que
  siguen parciales/bloqueados (backup integrado y retención, revocación ordinaria,
  UX humana/WCAG/TalkBack, observabilidad persistente, alertas entregadas, runbook y
  soak), no por este hallazgo ya corregido.

## Incidentes de procedimiento que conservan precedencia operativa — 2026-08-31

- [x] Durante una enumeración diagnóstica de archivos de configuración de Wrangler se
  encontró material de autenticación en un log local histórico. No se copió ningún valor
  a este documento, al repositorio ni a los artefactos de evidencia; las búsquedas futuras
  de credenciales quedan prohibidas y los logs no vuelven a exponerse en salidas.
- [ ] Antes del GO, el operador debe revocar/rotar la sesión OAuth de Wrangler y confirmar
  que los tokens de URLs firmadas históricas estén expirados o revocados. Es un requisito
  de higiene de secretos del procedimiento, separado de la funcionalidad del Worker.
- [ ] También permanece pendiente la rotación administrativa de la credencial de conexión
  de base que apareció transitoriamente en una lista de procesos, ya registrada en la
  actualización de backup. No se imprime ni se reutiliza aquí.

## Matriz anónima completa de endpoints y métodos — 2026-08-31 — ANTECEDENTE del candidato `fba21de`

- [x] Se derivaron **51 rutas** reales de todos los `+server.ts`, sustituyendo cada
  parámetro dinámico por un valor inválido controlado. Las solicitudes fueron
  secuenciales, sin cookies, sin seguir redirects y con timeout por ruta. En GET se
  observaron sólo estados 302/303/400/401/403/404/405, **0 timeouts, 0 errores 5xx y 0
  cuerpos sensibles**; 28 respuestas redirigieron a `/login`.
- [x] Se repitieron las mismas 51 rutas por POST sin `Origin`: **51/51 HTTP 403** por la
  protección CSRF, sin mutaciones, errores 5xx ni cuerpos sensibles. No se interpretó el
  bloqueo de origen ausente como fallo de una ruta de negocio.
- [x] Se repitieron por POST con `Origin` y `Referer` del Worker: estados agregados
  `204=2`, `303=26`, `401=8`, `404=1`, `405=14`; **0 errores 5xx, 0 timeouts y 0
  cuerpos sensibles**. Las 26 redirecciones fueron a `/login` y las respuestas 401/405
  no revelaron detalles internos.
- [x] Se probaron además PUT, PATCH, DELETE y OPTIONS sobre las mismas 51 rutas, con
  origen del Worker y cuerpo vacío. Por método se observó: PUT `303=26/405=25`, PATCH
  `303=26/400=1/405=24`, DELETE `303=26/401=1/405=24`, OPTIONS `303=26/405=25`; **0
  errores 5xx, 0 timeouts y 0 cuerpos sensibles**. No hubo sesión autenticada que
  pudiera convertir DELETE en una mutación real.
- [x] La clasificación de fugas excluyó deliberadamente la configuración pública
  esperada (clave anon y URL públicas); se buscó por separado `service_role`, claves
  privadas, secretos de jobs, tokens de sesión, stack traces y errores internos. Ninguno
  apareció en los 204 cuerpos examinados.
- [x] **Lectura actual:** esta matriz cierra el perímetro anónimo de método/origen para
  las rutas HTTP inventariadas, pero no sustituye la matriz autenticada por rol/tenant ni
  las mutaciones clínicas positivas ya registradas; esas requieren IDs válidos y siguen
  gobernadas por G3.

## Relectura del corte `1d5fa13` — atributos de sesión, logout remoto y tokens inválidos — 2026-08-31 — ANTECEDENTE de `fba21de`

Esta sección agrega evidencia de autenticación obtenida después de las matrices anónimas.
Los resultados de login, cookies y logout que figuran en bloques anteriores siguen siendo
antecedentes; esta relectura es la referencia vigente para los atributos observados en el
Worker `1d5fa13…`. No se escribieron cookies, tokens ni credenciales en el documento.

- [x] Un login exitoso con la cuenta sintética autorizada produjo únicamente cookies del
  dominio `app.cita-suite.workers.dev`: `sb-module`, `sb-access-token`,
  `sb-refresh-token` y `active-business-id`. En la inspección se registraron sólo sus
  nombres y atributos: `path=/`, `Secure=true`, `HttpOnly=true`, `SameSite=Lax` y
  expiración futura. Nunca se imprimieron sus valores.
- [x] **Antecedente conservado:** una corrida anterior había interpretado que dos contextos
  terminaban en `/login` después de `/logout`; esa lectura se conserva como historial, pero
  no gobierna el estado actual porque la repetición controlada de abajo la contradijo.
- [x] **Estado actual reproducido:** dos contextos independientes compartieron una sesión
  válida y ambos abrieron Agenda. Después de ejecutar `/logout` en el primero, ese contexto
  quedó sin cookies y volvió a `/login`, pero el segundo siguió entrando a Agenda con HTTP
  200. Con el refresh token capturado antes del logout, un tercer contexto también pudo
  renovar la sesión y abrir Agenda. Esto demuestra que el endpoint actual sólo revoca la
  sesión local del navegador y no una sesión remota ni los refresh tokens del servidor.
- [x] Con cookies efímeras de acceso y refresh deliberadamente manipuladas, la navegación
  directa a `/odonto/agenda` terminó en `/login` con HTTP 200 y el Worker eliminó las
  cookies de autenticación inválidas; sólo permaneció el identificador de negocio sin
  privilegios. No hubo acceso al shell clínico ni mutación. Esto cubre el rechazo de
  credenciales adulteradas sin imprimir sus valores.
- [ ] Queda por repetir con un refresh token real vencido/reutilizado cuando el rate limiter
  de login permita obtener una sesión nueva. El intento inmediato posterior fue rechazado
  por el límite de ingreso (`HTTP 429`, mensaje humano de esperar menos de un minuto); no
  se lo contó como una prueba de token vencido ni se insistió para no castigar el control
  de abuso.
- [x] La navegación externa, el prefetch y el crawler no se usaron como mecanismo de
  logout: las pruebas de rutas sin sesión y el logout explícito conservaron la distinción
  entre una redirección de autenticación y una revocación. No se observaron cookies con
  dominio amplio, `SameSite=None` ni atributos inseguros en la sesión inspeccionada.
- [ ] El rate limiter no queda certificado contra una caída de su dependencia ni contra
  falsos bloqueos durante una indisponibilidad de Supabase Auth. Ese ensayo requiere una
  falla inyectable en staging o un mecanismo de fault-injection aislado; no se simula
  apagando componentes protegidos de producción.

**Lectura actual:** los atributos de cookies y el rechazo de tokens adulterados quedaron
demostrados, pero el logout remoto/global y la revocación inmediata **fallaron** en la
repetición actual: `apps/web/src/routes/logout/+server.ts` sólo borra tres cookies y no
revoca la sesión en Supabase. Además, Supabase documenta que un JWT de acceso no puede
revocarse hasta su expiración; una corrección que prometa inmediatez debe incorporar una
estrategia explícita de invalidación de access tokens, no sólo borrar cookies. El gate de
autenticación permanece **BLOQUEADO/NO-GO** hasta corregir y repetir este caso, además de
probar refresh real vencido/reutilizado y fault-injection de Auth. El `HTTP 429` es
evidencia del rate limiter activo, no un falso éxito ni un fallo de aplicación.

## Hallazgo crítico — logout sólo local y riesgo de prefetch — 2026-08-31 — ANTECEDENTE supersedido por `fba21de`

Esta sección registra la reproducción y la remediación posterior sin borrar la evidencia
del fallo. El resultado de producción que sigue corresponde al Worker `1d5fa13…` **antes**
de publicar la corrección; no se debe mezclar con la versión corregida hasta repetir el
smoke y la prueba multi-contexto sobre una versión etiquetada nueva.

- [x] Reproducción exacta contra `https://app.cita-suite.workers.dev`: se inició sesión
  con la cuenta sintética, se copiaron las cookies a un segundo contexto y ambos abrieron
  `/odonto/agenda` con HTTP 200. Se ejecutó el `/logout` histórico en el primer contexto;
  éste terminó en `/login` y perdió sus cookies, pero el segundo siguió en Agenda con HTTP
  200. Un tercer contexto con el refresh token capturado antes del logout también renovó
  el access token y abrió Agenda. No se alteraron pacientes, turnos ni configuración.
- [x] La causa está confirmada en el código histórico: `GET /logout` sólo borraba
  `sb-module`, `sb-access-token` y `sb-refresh-token` del navegador. No llamaba a Supabase
  Auth, no invalidaba refresh tokens y tampoco eliminaba `active-business-id`.
- [x] La semántica del proveedor se verificó en un cliente aislado con la cuenta de
  prueba: `auth.signOut({ scope: 'global' })` devolvió éxito y después el refresh token
  devolvió HTTP 400; `getUser` con el access token revocado devolvió HTTP 400. La operación
  fue sólo sobre la cuenta sintética y se reingresó después para no dejarla bloqueada.
- [x] Corrección preparada en el worktree: el cierre pasa a `POST /logout`, revoca
  globalmente mediante `supabase.auth.admin.signOut(access_token, 'global')`, borra las
  cuatro cookies incluida `active-business-id` y comunica un fallo remoto en
  `/login?auth_error=logout_failed` en lugar de afirmar éxito. `GET /logout` responde 405,
  `Allow: POST`, `no-store` y no toca cookies, impidiendo que un prefetch, crawler o enlace
  externo cierre una sesión por accidente. Los tres layouts reemplazaron los enlaces GET
  por formularios POST nativos.
- [x] Regresión automatizada nueva: `logout.server.test.ts` **4/4**, incluyendo revocación
  global, GET inofensivo, error remoto y sesión ausente. `pnpm --filter web check` quedó en
  **0 errores/0 warnings** y la suite completa secuencial posterior al cambio en
  **108 archivos/823 tests**.
- [ ] Pendiente crítico: publicar esta corrección como un nuevo commit/artefacto etiquetado,
  confirmar `version.json` y `scriptVersion` en Cloudflare, repetir dos contextos y el
  refresh posterior al logout, y demostrar que un fallo de Auth muestra el mensaje humano
  sin falso éxito. Hasta esa repetición el Worker productivo conserva el comportamiento
  histórico y el gate de autenticación sigue **BLOQUEADO**.

**Riesgo residual explícito:** la revocación global de Supabase invalida refresh tokens y,
en la configuración observada, hace que `getUser` rechace el access token; aun así, la
documentación del proveedor advierte que los JWT pueden conservar validez hasta expirar.
El Worker debe seguir validando cada solicitud y no confiar sólo en que el navegador borró
sus cookies. Si una futura configuración vuelve a aceptar JWT ya emitidos, se necesitará
una estrategia adicional de invalidación de access tokens antes de afirmar revocación
inmediata.

## Relectura final — candidato `fba21de`, trazabilidad byte a byte, Cloudflare y autenticación — 2026-08-31 — ESTADO ACTUAL

Esta sección es la relectura vigente para la decisión de lanzamiento. Las secciones
anteriores que describen `1d5fa13`, `35349a5` u otros candidatos, incluidos sus
fallos de logout, quedan conservadas como antecedentes históricos y no se borran. Los
pendientes escritos antes de esta sección se interpretan como antecedentes cuando aquí
exista una medición posterior sobre el mismo comportamiento; no se convierten en
aprobaciones implícitas de los demás gates. La versión vigente del código es
`fba21de079706f9674a85303a3ec68b589b90f70`.

### Candidato, checkout y reproducibilidad del artefacto que consume Cloudflare

- [x] En el momento de construir y publicar el runtime, el checkout aislado de
  certificación `/tmp/cita-suite-audit-edf9a9f` quedó sin cambios y su `HEAD` fue
  `fba21de079706f9674a85303a3ec68b589b90f70`; el checkout principal y
  `origin/prelaunch/cloudflare-20260830` devolvieron ese mismo SHA y la comprobación
  `git ls-remote` coincidió. Después se hizo el commit documental
  `035f3d823580a48aa8a49dd494672ddb718c34a2`, que no toca el runtime ni se desplegó;
  por eso el deployment sigue correlacionado con `fba21de…` y ambos estados quedan
  explícitos, sin presentar una paridad falsa entre documentación y bundle.
- [x] Se ejecutaron dos builds independientes desde un `.svelte-kit` completamente
  retirado entre corridas, con `NODE_ENV=production`,
  `CLOUDFLARE_WORKERS=1`, `CITA_BUILD_VERSION=fba21de…`,
  `GIT_COMMIT_SHA=fba21de…` y `SOURCE_DATE_EPOCH=0`. Se compararon los outputs
  completos que consume Wrangler (`cloudflare`, `cloudflare-tmp` y
  `output/server`), no sólo el comportamiento del navegador: **373 archivos,
  byte a byte idénticos** en A/B.
- [x] El manifiesto de hashes completo está archivado en
  [audit-evidence/cloudflare/fba21de-cloudflare-tmp-server-manifest.txt](<audit-evidence/cloudflare/fba21de-cloudflare-tmp-server-manifest.txt>).
  Tiene 373 líneas y su SHA-256 es
  `2324f2e253b33f44eedbec04708a2aaf5d7c775e448bf5ce422cfafdac5f371b`. El
  `cloudflare-tmp/manifest.js` del build final no arrastra los hashes de la corrida
  anterior; las entradas nuevas observadas fueron `app.DcejDFCW.js` y
  `start.Dy6CZm__.js`.
- [x] La primera publicación se hizo con Wrangler desde `apps/web`, con tag
  `fba21de079706f9674a85303a3ec68b589b90f70-clean-2324f2` y mensaje
  `prelaunch complete auth cleanup fba21de`. La versión creada fue
  `9f8be05a-b003-42a8-bc00-18e87eff0c54` (número 48), con preview
  [9f8be05a-app.cita-suite.workers.dev](https://9f8be05a-app.cita-suite.workers.dev).
- [x] `wrangler versions view` confirmó para esa versión sólo el handler `fetch`,
  `nodejs_compat`, assets servidos directamente, reglas de caché de Svelte
  inmutables, placement targeted `aws:sa-east-1` y 28 nombres de bindings. Los
  valores de secretos no se mostraron; `PUBLIC_SITE_URL` fue exactamente
  `https://app.cita-suite.workers.dev`.
- [x] La promoción controlada mostró mezcla real: con 1 % de la versión nueva y 99 %
  de la anterior, 100 muestras HTML secuenciales observaron 98 respuestas con
  `CDBtQGV7/BVZxq4-T` (versión anterior) y 2 con `DcejDFCW/Dy6CZm__` (candidato
  actual). Después se promovió al 100 % sin error. El deployment **inicial** de esa
  promoción fue `9c33abf2-6c5c-4b5a-9ca5-12be37cdcefe`, estrategia `percentage`, con
  la versión `9f8be05a…` al 100 % y mensaje operativo
  `prelaunch complete auth cleanup full rollout`; los ensayos de rollback posteriores
  lo supersedieron y el deployment vigente se registra como `9c794bbb…` en la
  relectura dinámica final.
- [x] El endpoint de versión del artefacto es `/_app/version.json` (no
  `/version.json`; ese último 404 fue una consulta de arnés a una ruta inexistente,
  no un fallo del Worker). El Worker actual devolvió HTTP 200 y
  `{"version":"fba21de079706f9674a85303a3ec68b589b90f70"}`; la respuesta declaró
  `cache-control: no-cache`, `x-robots-tag: noindex` y el `cf-ray` fue registrado
  sin asociarlo a datos clínicos.
- [x] El smoke de navegador contra el Worker actual cargó `/login` con HTTP 200,
  detectó 20 referencias a recursos `/_app/immutable`, **0 respuestas 4xx/5xx** y
  **0 errores de consola**. No se encontraron hashes antiguos ni assets 404 en esa
  carga. El smoke se ejecutó de forma secuencial y no se imprimieron cookies ni
  tokens.

### Autenticación, logout remoto y revocación — estado actual

- [x] Login real mediante el formulario del Worker actual: GET `/login` HTTP 200,
  POST de credenciales HTTP 303 a `/odonto/agenda`, Agenda HTTP 200. El navegador
  observó sólo `sb-module`, `sb-access-token`, `sb-refresh-token` y
  `active-business-id`, todos con `Secure=true`, `HttpOnly=true`,
  `SameSite=Lax`, dominio del Worker y `path=/`. Nunca se registraron sus valores.
- [x] En la misma sesión real, el menú de usuario mostró exactamente un formulario de
  logout y un botón `Salir`. El click emitió POST `/logout` HTTP 303, terminó en
  `/login` y el contexto quedó con **cero cookies**. Esto cubre la interacción
  visible del profesional, no sólo una llamada HTTP.
- [x] Repetición HTTP aislada con una sesión sintética autorizada: GET `/logout`
  respondió 405, `Allow: POST`, `Cache-Control: no-store`, sin `Set-Cookie`;
  no revocó ni borró nada. Un POST de formulario real con `Origin` y `Referer`
  externos devolvió 403 y el mensaje `Cross-site POST form submissions are
  forbidden`, sin cookies modificadas.
- [x] El POST de formulario same-origin devolvió 303 a `/login` y envió expiración
  para las cuatro cookies (`sb-module`, `sb-access-token`,
  `sb-refresh-token`, `active-business-id`) con `Max-Age=0`, `HttpOnly`,
  `Secure` y `SameSite=Lax`. La inspección posterior del contexto confirmó que
  no quedó ninguna.
- [x] La relectura independiente de Supabase después del logout remoto rechazó el
  access token anterior con HTTP 403 y el refresh token anterior con HTTP 400. Un
  segundo contexto que conservaba las cookies previas recibió 303 a `/login` y el
  Worker emitió las limpiezas correspondientes. Esto contradice y supersede la
  reproducción histórica de “logout sólo local” conservada arriba.
- [x] Se ejecutaron 30 solicitudes autenticadas secuenciales a Agenda contra este
  Worker; **30/30 HTTP 200**, sin 401, 429 ni 5xx. El `Server-Timing` de Auth tuvo
  p50 18 ms, p95 22 ms, p99 25 ms y máximo 39 ms. Es una medición puntual, no un
  presupuesto de rendimiento de lanzamiento.
- [ ] Siguen sin certificarse por esta corrida la inyección de caída de Supabase Auth,
  el refresh por expiración natural, la revocación ordinaria de una membresía durante
  cada flujo clínico y la matriz completa de roles/tenants. El logout global actual
  quedó probado; esos casos no deben marcarse automáticamente como verdes.

### Cambios de código y regresión ejecutada

- [x] En `apps/web/src/hooks.server.ts` se eliminó la caché en memoria de 30 segundos
  de claims: los access tokens no expirados se validan con
  `supabase.auth.getUser(access_token)` en cada request. Cuando la sesión es inválida,
  ahora se limpian también las cuatro cookies, incluida
  `active-business-id`. La corrección evita que otro isolate de Cloudflare acepte
  una sesión globalmente revocada o conserve un consultorio obsoleto.
- [x] En los layouts de `odonto` se quitó el `onclick` que cerraba el menú y removía
  el formulario antes de que el submit nativo pudiera salir. El botón visual `Salir`
  quedó probado con el navegador real del Worker actual.
- [x] Las pruebas unitarias de hooks/logout cubren validación por request, limpieza de
  negocio activo, revocación global, GET inofensivo, error remoto y sesión ausente:
  logout focal **4/4** y hooks incluidos en la suite completa.
- [x] `pnpm check` terminó con `svelte-check found 0 errors and 0 warnings`.
  La suite Vitest completa, secuencial y con un worker, terminó en **108 archivos y
  824 tests pasados**, sin fallos. Este resultado corresponde al commit actual y no
  reemplaza las pruebas E2E omitidas por credenciales, proveedores o participantes.
- [x] La auditoría de dependencias del candidato continuó limpia en el último ciclo;
  las 15 vulnerabilidades transitivas históricas están documentadas como antecedente
  y fueron resueltas mediante overrides. No se volvió a introducir un secreto en el
  código o en el manifiesto final.

### Cloudflare, headers y tail de borde

- [x] La respuesta pública actual de `/login` declaró `private, no-store`, CSP con
  nonce, HSTS de un año, `X-Content-Type-Options: nosniff`,
  `X-Frame-Options: DENY`, `Referrer-Policy: strict-origin-when-cross-origin`,
  Permissions Policy sin cámara/micrófono/geolocalización y `Server-Timing`.
  `/logout` conservó el método permitido y `no-store`.
- [x] Se abrió un `wrangler tail --format json --sampling-rate 0.01` después de la
  promoción final. Una solicitud al Worker observó
  `scriptVersion.id=9f8be05a-b003-42a8-bc00-18e87eff0c54`, HTTP 200,
  `outcome=ok`, `truncated=false` y `exceptions=[]`. El tail es evidencia
  efímera de esta ventana, no un sistema de retención ni un dashboard; se detuvo al
  terminar la observación y no se imprimieron cookies (Wrangler las redactó).
- [ ] La ausencia de excepciones en ese tail no demuestra logs persistentes, alertas
  entregadas a una persona, métricas p95/p99, synthetic de seis horas ni soak de 24
  horas. G6 permanece parcial/bloqueado hasta realizar esas pruebas.

### Scheduler externo y separación histórica

- [x] La evidencia vigente del scheduler externo conserva el job cron-job.org
  `7795525`, habilitado como POST al Worker cada 10 minutos UTC, con timeout de
  30 segundos. La configuración autenticada, la rotación de secreto y el historial de
  50 ejecuciones (incluidas las posteriores a la rotación) están registrados en
  las secciones anteriores; la invocación real devolvió HTTP 200 con
  `ok=true`, `claimed=0`, `sent=0`, `failed=0` y `deadEndpoints=0`.
  No se volvió a exponer ningún secreto.
- [ ] El job no se considera un sistema de observabilidad cerrado: falta demostrar
  entrega humana de la alerta de fallo, reintentos idempotentes bajo dos invocaciones
  simultáneas, ventana exacta de dos horas, endpoints 410/429/5xx, estados
  `accepted/received/displayed` y un runbook ensayado. El scheduler sí está
  identificado y tuvo ejecución real; esas carencias no se ocultan detrás de la
  casilla histórica.

### Incidentes de método y diagnósticos conservados

- [x] Una publicación inicial desde una raíz sin entrypoint fue rechazada por Wrangler
  (`Missing entry-point to Worker script or to assets directory`); se repitió desde
  `apps/web` y se dejó sólo la versión válida.
- [x] Una versión intermedia reutilizó un `.svelte-kit` sucio y sirvió un manifest de
  servidor con hashes de cliente antiguos; el navegador detectó assets 404. Esa
  publicación no se contó como certificada. Se retiró el output completo, se hicieron
  dos builds limpios y se verificó el manifiesto de 373 archivos antes del candidato
  actual.
- [x] El primer comando de Playwright en el checkout temporal intentó `require` en
  un módulo ESM; el segundo usó top-level await en CommonJS; otro buscó `playwright`
  cuando el paquete disponible era `@playwright/test`. Fueron errores del arnés, no
  de la aplicación; se corrigieron y se repitieron los casos.
- [x] Un despliegue Wrangler inicial entró en el selector interactivo por usar
  argumentos posicionales; se repitió con `--version-id`, porcentajes explícitos y
  `--yes`. No se cuenta el intento interactivo como evidencia de promoción.
- [x] Un selector inicial de UI hizo click en el botón de Configuración, no en el menú
  de usuario; terminó sin formulario de logout. El selector se corrigió a la última
  instancia visible de `button[aria-haspopup="menu"]` y la prueba real pasó.
- [x] Una lectura intermedia informó una cookie de negocio restante porque se examinó
  el contexto antes de completar la redirección; la repetición esperó la navegación,
  capturó los cuatro `Set-Cookie` y confirmó cero cookies. Se conserva el episodio
  como diagnóstico de sincronización del arnés, no como defecto actual.
- [x] Varios intentos de login repetidos recibieron HTTP 429 del rate limiter con el
  mensaje humano de esperar. No se contaron como login válido ni se forzó el límite;
  después de la ventana de enfriamiento el login real del candidato actual pasó
  200/303 y logout 303.
- [x] Una consulta a `/version.json` devolvió 404 por no incluir el prefijo
  `/_app`; se corrigió la ruta de verificación y el artefacto devolvió el SHA exacto.
  Ninguno de estos errores de procedimiento se presenta como un fallo funcional
  solucionado por casualidad.

### Reevaluación vigente de gates (sólo para el candidato `fba21de`)

| Gate | Estado actual | Evidencia nueva que se admite | Pendiente que impide el cierre |
|---|---|---|---|
| G0 — trazabilidad de código/artefacto | **APROBADO para identidad y promoción** | SHA local/remoto, checkout limpio, dos outputs byte a byte, manifiesto 373, tag, versión `9f8be05a…`, deployment vigente `9c794bbb-1902-431a-beb2-b9e266c6047e`, mezcla 1/99, promoción 100 %, `/_app/version.json` y tail con `scriptVersion` | La identidad del runtime actual quedó confirmada; cada cambio futuro exige repetir esta cadena. El rollback operativo exacto se registra en G9 y no se convierte en un RTO contractual |
| G1 — backup/restauración | **PARCIAL** | Restore aislado histórico, conteos, relaciones y checksum semántico documentados | Backup remoto durable fuera de esta PC, restore integrado con aplicación, radiografías, RPO/RTO y retención |
| G2 — código/dependencias | **APROBADO para `fba21de`** | check 0/0, Vitest 108/824, auditoría de dependencias limpia, build reproducible | No sustituye pruebas de datos, UX, proveedores ni operación |
| G3 — aislamiento/datos/concurrencia | **PARCIAL** | pgTAP, concurrencia e IDOR históricos; logout global y validación por request nuevos | Matriz completa de roles/tenants, revocación de membresías durante sesión y todos los RPC/rutas autenticados |
| G4 — funcional E2E | **PARCIAL** | Login/logout, assets y smoke Cloudflare actuales; suites históricas con resultados y skips explícitos | Casos omitidos por proveedor/credenciales, escenarios de error completos y recorridos no repetidos sobre el candidato exacto |
| G5 — UX/accesibilidad | **PARCIAL** | BrowserStack iPhone, Samsung físico y automatización histórica; logout visual actual | Profesionales representativos, SEQ/SUS, WCAG/TalkBack completo, Safari físico y pruebas de interrupción/offline |
| G6 — Cloudflare/observabilidad | **PARCIAL/BLOQUEADO** | Versión exacta, placement, headers, caché/asset smoke, canary, tail efímero y stress auth 30/30 | Logs persistentes, dashboard, alertas humanas, límites p95/p99, synthetic 6 h, soak 24 h y CSP iPhone |
| G7 — proveedores | **FUERA DE ALCANCE explícito** | WhatsApp y Mercado Pago excluidos por instrucción; Google sólo donde fue autorizado | No declarar las integraciones excluidas como certificadas si vuelven al alcance |
| G8 — producción exacta | **PARCIAL** | Worker actual al 100 %, versión/commit correlacionados y pruebas autenticadas actuales | Skips de cobertura y recorridos productivos restantes |
| G9 — scheduler/rollback/operación | **PARCIAL** | cron-job.org identificado y ejecutado, rotación e historial previos, promoción controlada y rollback medido del candidato exacto `fba21de` (incluida la restauración dinámica en `9c794bbb…`) | Entrega humana de la alerta, reintentos idempotentes, runbook ensayado y soak |

**Decisión vigente: NO-GO.** El candidato `fba21de` está correlacionado con el
artefacto que atiende Cloudflare, sus assets son coherentes y la corrección crítica de
logout/revocación pasó en producción. Eso no cierra G1, G3, G5, G6 ni G9, ni convierte
los proveedores excluidos o los skips en evidencia positiva. La aplicación no debe
declararse lista para venderse al sector de salud hasta cerrar los pendientes explícitos
o documentar una aceptación formal de cada riesgo residual por el responsable del
lanzamiento.

### Lista de reanudación sin repetir verdes

- [ ] No repetir el smoke de assets ni el logout básico sin cambio de versión/hipótesis:
  ya están verdes en este candidato. Priorizar backup remoto/restauración integrada,
  matriz autenticada por rol/consultorio, entrega humana de alertas de cron, reintentos
  idempotentes, runbook y pruebas humanas de UX/accesibilidad. El rollback del candidato
  exacto ya fue medido y no debe repetirse salvo que cambie la versión o la hipótesis.
- [ ] Mantener la REGLA CENTRAL: cualquier fixture de paciente, turno, profesional,
  consultorio, email o archivo puede limpiarse con manifiesto exacto; código,
  migraciones, funciones, triggers, RLS, grants, constraints, Storage, secretos,
  configuración Cloudflare y capacidad futura quedan protegidos. No ejecutar DDL
  destructivo directo sobre producción.
- [ ] Cada futura publicación autorizada debe repetir antes del deploy: checkout y diff
  revisados, secretos fuera del artefacto, `pnpm check`, tests secuenciales, build A/B
  byte a byte del output de Cloudflare, hash/manifiesto, smoke de preview, canary,
  promoción, `/_app/version.json`, tail correlacionado y registro histórico/actual.
## Relectura E2E final sobre el Worker actual — 2026-08-31 — ESTADO ACTUAL

Esta sección actualiza únicamente la ejecución E2E posterior al deployment
`9f8be05a-b003-42a8-bc00-18e87eff0c54`. No borra las corridas anteriores: los números
anteriores quedan como antecedentes y esta relectura explica cada diferencia, cada fallo
y cada skip.

- [x] La orden completa se ejecutó contra `https://app.cita-suite.workers.dev` con
  `CI=1`, `E2E_ALLOW_DESTRUCTIVE=true`, credenciales provistas por variables y
  `--workers=1 --retries=0`. Resultado bruto: **27 tests, 11 pasados, 5 fallidos y
  11 skipped**. Los fallos no se ocultaron ni se transformaron en skips.
- [x] El primer fallo de ayuda maestra no fue un estado clínico incorrecto: el panel
  mostró correctamente la región `2 consultorios pidieron ayuda para configurar`,
  con las dos solicitudes sintéticas visibles. La aserción esperaba exactamente una
  solicitud porque una corrida abortada anterior había dejado un fixture
  `E2E Ayuda` activo. Se eliminaron exclusivamente ese negocio, sus dos usuarios
  Auth y sus dos emails de prueba; la relectura confirmó cero negocios, pacientes,
  profesionales e invitaciones `E2E` restantes. La prueba se repitió y pasó **1/1
  en 30,4 s**.
- [x] Los dos fallos de navegación móvil no fueron ausencia del control: los specs
  esperaban un enlace `Salir`, mientras la implementación segura actual usa un
  formulario POST con botón `Salir` para impedir logout por prefetch/crawler. El
  botón estuvo visible y en viewport en ambos escenarios; se corrigieron sólo los
  selectores de los specs a `button[name="Salir"]` y se repitieron
  `mobile-navigation-ux.spec.ts` y `commercial-lock.spec.ts`: **3/3 pasados en
  25,5 s**.
- [x] Los dos fallos de `roles-agenda-regression.spec.ts` ocurrieron al crear cuentas
  sintéticas pendientes: el Worker respondió
  `/odonto/pendiente?reason=rate_limited`, consistente con el límite operativo de
  registros por IP después de la batería larga. No se interpretó ese 429 como éxito ni
  se intentó eludirlo borrando el contador. El límite y el mensaje humano quedaron
  demostrados; la aceptación de altas nuevas requiere repetir desde otro runner/IP o
  después de la ventana de una hora. El cleanup de la suite y la consulta posterior no
  dejaron fixtures sintéticos.
- [x] La higiene de fixtures se verificó con consultas de service role de sólo lectura
  después de la corrida: negocios, pacientes, profesionales e invitaciones con
  prefijos E2E devolvieron cero. Las 23 filas de `account_assistance_grants`
  existentes no se eliminaron indiscriminadamente: sólo se retiró el negocio/usuarios
  sintéticos identificados; no se tocó información clínica real ni el esquema.
- [x] Una primera sonda de esa higiene pidió por error la columna `name` en
  `business_user_invites`, que no existe; Supabase devolvió el error de esquema sin
  mutar nada. Se corrigió inmediatamente a la columna `email`, la consulta devolvió
  cero invitaciones E2E y el error quedó registrado como diagnóstico del arnés.
- [x] El archivo E2E móvil conserva el ajuste previo `hasTouch=true` porque Firefox no
  implementa `isMobile`; el cambio adicional de esta relectura sólo adapta la semántica
  de logout de enlace a botón/formulario. No se stagearon capturas, videos ni otros
  cambios del worktree.
- [ ] La batería completa queda **parcial**, no verde: persisten los dos casos de
  roles bloqueados por rate limit y los 11 skips declarados por sus precondiciones.
  No se debe afirmar cobertura E2E total hasta repetir esos casos desde un runner
  externo con IP limpia y ejecutar cada skip justificadamente.
## Ensayo de rollback operativo del candidato exacto — 2026-08-31 — ESTADO ACTUAL

Esta sección supersede sólo el estado de deployment escrito antes del ensayo. No elimina
la evidencia de las promociones/rollback históricos: documenta el primer rollback medido
desde el candidato `fba21de` actualmente certificado y su restauración inmediata.

- [x] Estado inicial verificado antes de tocar tráfico: deployment
  `9c33abf2-6c5c-4b5a-9ca5-12be37cdcefe`, versión
  `9f8be05a-b003-42a8-bc00-18e87eff0c54` al 100 %. El destino de rollback
  `10f572e4-cef3-400a-be76-32405bd6333f` fue inspeccionado previamente y corresponde
  al artefacto anterior etiquetado `35349a5…-clean-d22ebfd`; no se cambiaron bindings,
  secretos ni base de datos.
- [x] A las 12:26:47 UTC se ejecutó con Wrangler el rollback controlado al 100 % del
  artefacto anterior; Wrangler confirmó éxito de publicación en 1,27 s. El deployment
  quedó registrado como `78ff851d-a4c0-437c-bed4-77a53d351f73`.
- [x] Una sonda secuencial con query único observó
  `/_app/version.json` del artefacto anterior con HTTP 200 en el intento 0, a los
  **1.034 ms** de iniciar la medición, con `cf-cache-status=HIT`. No se siguieron
  mutaciones clínicas durante el intervalo.
- [x] Inmediatamente se restauró el candidato `fba21de` al 100 %; Wrangler confirmó
  éxito en 0,69 s y creó el deployment
  `d49c0e7b-7520-4fb4-9e03-1d6b277ff055` con el mensaje
  `prelaunch rollback drill restore fba21de`.
- [x] La sonda de restauración observó el SHA exacto de `fba21de` con HTTP 200 en
  **883 ms** (intento 0). Un smoke de navegador posterior devolvió `/login` HTTP
  200, cero respuestas 4xx/5xx y `/_app/version.json` HTTP 200 con el SHA esperado.
- [x] El estado Cloudflare final volvió a quedar inequívocamente en una sola versión al
  100 %: `9f8be05a-b003-42a8-bc00-18e87eff0c54`. El rollback fue reversible y medido
  sin tocar pacientes, turnos, profesionales, consultorios, Storage, migraciones o
  secretos.
- [ ] Este ensayo demuestra el mecanismo y el tiempo de recuperación del artefacto,
  pero no sustituye un runbook de incidente ensayado por una persona, alertas humanas,
  observabilidad persistente, rollback de datos/migraciones ni un soak posterior. G9
  sigue parcial por esos puntos.
## Relectura de robustez del arnés de ayuda maestra — 2026-08-31 — ESTADO ACTUAL

- [x] La aserción del panel maestro se hizo independiente del número incidental de
  solicitudes sintéticas: acepta singular/plural, conserva el texto visible real para
  cerrar el aviso y sigue exigiendo que el consultorio fixture correcto esté presente.
  Esto evita que un fixture huérfano convierta una UI válida en falso fallo.
- [x] El spec actualizado se ejecutó nuevamente contra la versión Cloudflare actual con
  un worker y sin reintentos: **1/1 pasó en 33,5 s**. La modificación es sólo de
  robustez del test; no modifica la aplicación ni el deployment fba21de.

## Relectura de rollback con HTML dinámico no cacheable — 2026-08-31 — ESTADO ACTUAL

Esta medición posterior corrige una limitación metodológica de la primera sonda: el archivo
de versión estático podía aparecer como `HIT`. Se conserva aquella medición como
antecedente y aquí se valida el cambio de tráfico con `/login`, cuyo HTML declara
`private, no-store`.

- [x] Se volvió a promover temporalmente al 100 % la versión anterior
  `10f572e4-cef3-400a-be76-32405bd6333f` en el deployment
  `cada1b8f-e4da-44c4-9baf-b52b9d0cf815`. No se modificaron código, secretos,
  bindings ni datos.
- [x] Sondas secuenciales con `Cache-Control: no-cache`, `Pragma: no-cache`,
  `cache: no-store` y query único observaron `/login` HTTP 200 con
  `cache-control: private, no-store` y el hash HTML anterior
  `app.CDBtQGV7.js` en **1.011 ms**, sin `cf-cache-status`. Esto prueba el cambio
  del documento servido, no una lectura de un objeto estático compartido.
- [x] Se restauró inmediatamente `fba21de` al 100 % en el deployment
  `9c794bbb-1902-431a-beb2-b9e266c6047e`; la sonda dinámica volvió a observar
  `app.DcejDFCW.js` HTTP 200, `private, no-store`, sin `cf-cache-status`, en
  **860 ms**.
- [x] El estado final quedó en una sola versión `9f8be05a-b003-42a8-bc00-18e87eff0c54`
  al 100 %. Este ensayo dinámico confirma el RTO de borde del artefacto bajo una
  hipótesis de caché más estricta; el runbook humano, las alertas y el rollback de
  datos siguen pendientes.
- [x] Después de la restauración se abrió un tail nuevo con sampling 0,01 y se generaron
  solicitudes públicas y autenticadas. Los eventos observados declararon
  `scriptVersion.id=9f8be05a-b003-42a8-bc00-18e87eff0c54`, `outcome=ok`,
  `truncated=false`, `exceptions=[]` y estados HTTP 200/303; los headers de cookies
  aparecieron redactados por Wrangler. Los `cf-ray` de muestra se conservaron sólo como
  correladores (`a33c139608c92ced`, `a33c13e409cbae29`, `a33c148aca4ada16`). El tail se
  detuvo al finalizar y sigue siendo evidencia efímera, no retención operativa.

## Relectura editorial de antecedentes y estado actual — 2026-08-31 — ESTADO ACTUAL

Esta sección fija la precedencia de las evidencias que motivaron la actualización
solicitada. No elimina ni corrige retroactivamente los snapshots anteriores: los deja
identificados como antecedentes y separa lo que ahora gobierna la decisión.

### Antecedente de Git y hardening de privilegios — candidato `b1a35ff`

- [x] El candidato histórico de hardening quedó identificado inequívocamente como el
  commit completo `b1a35ff519442b42fb95b99a4f0978f947f1660b`, con tag
  `prelaunch-cloudflare-b1a35ff`, padre `7e5fb7c8c205ee53caa9571c7b25394aa5a9ed1f`
  y árbol `4c752301e1630aada0167bb5e7be7b03ea3b1892`. El checkout limpio y la
  reproducibilidad del artefacto de ese corte se conservan como **antecedente**; no se
  presentan como la versión que atiende hoy al Worker, que es `fba21de…`.
- [x] Ese commit contiene el test de privilegios y las migraciones que revocan `TRUNCATE`
  a `anon` y `authenticated` y validan la restricción de invitaciones. La medición
  histórica registrada fue **0 grants TRUNCATE indebidos** para ambos roles, todas las
  restricciones restauradas con `convalidated=true` y **22/22 tests pgTAP PASS**. Esto
  demuestra una propiedad de privilegios/integridad del corte; no cierra por sí solo la
  matriz autenticada multi-tenant ni el gate G3 completo.

### Scheduler externo — estado vigente

- [x] El job `cron-job.org/7795525` está identificado, autenticado y habilitado como
  POST al Worker `app.cita-suite.workers.dev` cada diez minutos UTC, con timeout de 30 s.
  La lectura posterior a la rotación confirmó ejecución real exitosa (HTTP 200,
  `ok=true`, `claimed=0`, `sent=0`, `failed=0`, `deadEndpoints=0`) y el historial de
  50 ejecuciones conserva las cinco últimas exitosas. Los registros antiguos que dicen
  `onFailure=false` son **antecedentes**; la política vigente quedó en
  `onFailure=true`, `onFailureCount=1`, `onSuccess=true` y `onDisable=true`.
- [ ] Sigue faltando provocar una falla controlada y demostrar entrega humana de la
  alerta, recuperación sin duplicados y reintentos idempotentes. Por eso la existencia y
  ejecución del scheduler ya no son un bloqueo de identificación, pero G9 no se marca
  verde hasta observar la alerta de punta a punta.

### Correlación Cloudflare ↔ artefacto — estado vigente

- [x] La versión desplegada quedó correlacionada con el output exacto que consume
  Wrangler: runtime `fba21de079706f9674a85303a3ec68b589b90f70`, tag
  `fba21de…-clean-2324f2`, manifiesto de 373 archivos con SHA
  `2324f2e253b33f44eedbec04708a2aaf5d7c775e448bf5ce422cfafdac5f371b`, versión
  `9f8be05a-b003-42a8-bc00-18e87eff0c54` y deployment vigente
  `9c794bbb-1902-431a-beb2-b9e266c6047e` al 100 %. `/_app/version.json`, los assets y
  el tail observaron ese mismo identificador; la comparación A/B fue byte a byte sobre
  `cloudflare`, `cloudflare-tmp` y `output/server`, no sólo sobre el comportamiento.
- [x] El rollback dinámico se ejecutó contra HTML `private, no-store`: versión anterior
  observada en 1.011 ms y restauración de `fba21de` en 860 ms, seguida por tail con
  `scriptVersion.id=9f8be05a…`, `outcome=ok` y `exceptions=[]`. Esta evidencia cierra
  la identidad/promoción de G0 y aporta un RTO de borde observado a G9; no prueba por sí
  sola rollback de datos, runbook humano ni observabilidad persistente.
- [ ] G6 permanece **PARCIAL/BLOQUEADO**: todavía faltan logs persistentes, dashboard,
  alertas recibidas por una persona, p95/p99 de recursos, synthetic de seis horas, soak
  de 24 horas y el cierre del aviso CSP de iPhone. G9 permanece **PARCIAL** por la
  alerta humana, reintentos y runbook pendientes. La decisión global continúa **NO-GO**.

## Matriz autenticada multi-tenant y revocación — 2026-08-31 — ESTADO ACTUAL

Esta ejecución reemplaza metodológicamente la sonda anterior de dos consultorios que
había usado un prefijo común para A y B y, por eso, confundía el marcador propio con
una filtración lateral. La sonda anterior queda conservada como **incidente del arnés**;
no se cuenta como evidencia de fallo de la aplicación. También se corrigió el intento
de revocación: `business_users` admite `active`/`disabled`, no `revoked`; la primera
mutación inválida fue rechazada por la restricción y no modificó datos.

- [x] Se crearon dos consultorios sintéticos con marcadores independientes
  `TENANTA_<suffix>` y `TENANTB_<suffix>`, seis cuentas en A (owner, admin, recepción,
  readonly y dos profesionales, uno vinculado y otro no vinculado) y un owner en B.
  Cada cuenta tuvo contraseña temporal aleatoria, membresía activa, servicio,
  profesional, agenda y paciente; el profesional vinculado tuvo además relación
  profesional-paciente. Nunca se imprimieron credenciales, tokens ni cookies.
- [x] La ejecución válida se hizo contra `https://app.cita-suite.workers.dev`, con un
  único Chromium, contextos secuenciales y cliente Supabase con WebSocket explícito.
  Se verificaron login y ruta inicial por rol, presencia del contexto A y ausencia del
  marcador B en la Agenda, referencias, lista y búsqueda de pacientes, búsqueda de
  Agenda, Equipo, ficha/historial/radiografías de un paciente B, dependencias de un
  profesional B y consultas directas RLS a `patients` de B.
- [x] Para owner y admin, Equipo mostró el marcador A y nunca B; recepción, readonly y
  profesionales fueron redirigidos fuera de Equipo. Los profesionales quedaron
  limitados a Mis turnos y sus endpoints de agenda devolvieron 403 cuando correspondía.
  No se observó HTTP 5xx ni contenido del tenant B en ninguna de las 80 aserciones.
- [x] Se intercambió deliberadamente la cookie `active-business-id` por el UUID de B
  dentro de una sesión perteneciente sólo a A. La aplicación mantuvo el contexto A,
  no mostró B y siguió en Agenda.
- [x] Se deshabilitó la membresía de recepción durante una sesión ya iniciada usando el
  estado válido `disabled` y se recargó Agenda. La sesión terminó en
  `/odonto/pendiente`, sin marcador A ni acceso clínico; después se restauró exactamente
  la fila a `active` y se comprobó cleanup.
- [x] Resultado: **80/80 PASS, 0 FAIL**. La limpieza por UUID/email dejó
  `businesses A=0`, `businesses B=0`; no quedaron pacientes, profesionales,
  membresías, usuarios Auth ni emails sintéticos. La consulta RLS de cada rol devolvió
  cero filas de B sin error.
- [ ] Esto cierra una matriz representativa de aislamiento y revocación de lectura, pero
  no convierte G3 en verde: todavía faltan atacar exhaustivamente todas las mutaciones,
  todos los RPC y carreras de revocación/edición con datos clínicos concurrentes.

## Alta de owner y membresía aceptada — 2026-08-31 — HALLAZGO, CORRECCIÓN Y ESTADO ACTUAL

### Antecedente reproducido antes de la corrección

- [x] Se construyó un consultorio sintético y una cuenta Auth descartable, se insertó
  deliberadamente una membresía `active` con `accepted_at = null` y se inició sesión
  contra el Worker público. El RPC `list_user_business_contexts` devolvió el
  consultorio y la Agenda mostró su shell, pero la consulta RLS a `services` devolvió
  cero filas. Resultado del arnés: **3/3 PASS en la reproducción**. Esto era un bug
  real de consistencia: el profesional podía ver el consultorio pero no sus datos.
- [x] La causa quedó localizada en dos puntos: el alta `create_business` del panel
  maestro insertaba el owner sin `status`/`accepted_at`, y el RPC de contexto aceptaba
  membresías activas sin aceptación aunque `user_has_business_access` y las políticas
  RLS exigían `accepted_at`. El fixture fue eliminado por UUID y la cuenta Auth
  descartable fue eliminada; no se tocaron consultorios reales.

### Corrección aplicada y filtrada

- [x] El commit aislado `4f5ac66c4a58ee28128d6a1a8cee310f817c8d15` hace que el alta del
  owner ya registrado escriba `status = active`, `accepted_at`, `created_by` y
  `updated_by`; agrega prueba unitaria del camino; actualiza
  `add_business_user_by_email`; filtra el RPC a membresías activas aceptadas; y
  agrega la restricción `business_users_active_requires_accepted_at`.
- [x] La migración `20260831042000_require_accepted_active_memberships.sql` fue
  revisada antes de aplicarse. El conteo remoto previo era `active_null_accepted=0`,
  `all_null_accepted=0`, por lo que el backfill ejecutó `UPDATE 0`; no hubo datos
  actuales que cambiar. Se aplicó con `psql --single-transaction -v ON_ERROR_STOP=1`
  a la base remota y se registró en `supabase_migrations.schema_migrations`.
  La verificación posterior dio `convalidated=true`, filtro `accepted_at` presente
  en la función, `active_null_accepted=0` y migración vigente
  `20260831042000:require_accepted_active_memberships`.
- [x] El CLI global antiguo falló sólo al parsear la clave no soportada
  `local_smtp`; el CLI del proyecto (`pnpm exec supabase 2.115.0`) confirmó después,
  mediante un workdir de migraciones limpio, `db push --dry-run` **up to date**. Este
  incidente de herramienta no es un fallo de la aplicación.

### Verificación de código, batería y Worker actual

- [x] `pnpm --dir apps/web exec vitest run --maxWorkers=1`: **108 archivos, 827
  tests PASS**. Un intento previo con `--minWorkers=1` fue rechazado por Vitest 4
  como opción inexistente; se corrigió inmediatamente y no se contó como test.
- [x] `pnpm --dir apps/web check`: **0 errores, 0 advertencias**.
- [x] Dos builds de producción con el SHA completo produjeron exactamente el output
  `.svelte-kit/cloudflare`: **105 archivos**, hash ordenado de rutas+contenido
  `a0e54fda608d657342d6493b1412335165b415c89043c229dde0e25332fdb50f` en A y B,
  comparación **BYTE_A_BYTE PASS**. Wrangler leyó 112 assets (3946.83 KiB, 807.15
  KiB gzip); el detalle queda en
  `audit-evidence/cloudflare/4f5ac66-build-metadata.txt`.
- [x] Se publicó únicamente después de pasar tests, check, migración y hash. La
  versión Cloudflare actual es `8b06737b-b651-481e-9eda-a4af396e646b`, 100 % del
  tráfico, tag `4f5ac66-clean-a0e54fda`, mensaje `prelaunch accepted membership
  integrity 4f5ac66`. `/_app/version.json` respondió el SHA completo esperado;
  `/login` respondió `cache-control: private, no-store`.
- [x] La rama `prelaunch/cloudflare-20260830` fue subida de forma fast-forward y
  `git ls-remote` coincide exactamente con el checkout local en
  `4f5ac66c4a58ee28128d6a1a8cee310f817c8d15`. Los cambios no relacionados del
  worktree no fueron incluidos.
- [x] El arnés vigente
  `audit-evidence/current-null-accepted-membership-test.mjs` intentó insertar de
  nuevo una membresía activa sin aceptación: la base la rechazó por la restricción;
  luego creó una membresía aceptada, verificó el RPC, RLS y la Agenda en
  `https://app.cita-suite.workers.dev`. Resultado: **4/4 PASS** y cleanup exacto.

### Concurrencia ejecutada en el mismo candidato

- [x] `current-booking-concurrency-test.mjs`: **8/8 PASS** en la función atómica:
  50 reservas concurrentes del mismo horario dejaron exactamente un ganador y 49
  conflictos; 10 solicitudes con la misma clave dejaron un único turno/paciente y
  9 respuestas replay idempotentes.
- [x] `current-admin-create-action-concurrency.mjs`: **5/5 PASS** contra el Worker
  actual con diez POST autenticados simultáneos, sin HTTP 5xx, un solo turno, un
  solo paciente y datos/horario/clave coherentes. La primera ejecución histórica
  devolvió conflictos porque el fixture carecía de `accepted_at`; se clasificó como
  error del arnés, se corrigió el fixture y se repitió con resultado válido.
- [x] `current-idor-mutation-test.mjs`: **14/14 PASS** contra la versión etiquetada;
  owner A atacó IDs B en pacientes, historia, archivo, turno y reprogramación. Las
  respuestas fueron fallos humanos 404/403/400, las filas B quedaron byte a byte
  iguales y la limpieza por UUID no dejó usuarios ni consultorios sintéticos.

### Estado de gate tras esta evidencia

- [ ] El defecto de alta/membresía queda **corregido y demostrado en producción**;
  no se marca G3 global verde porque aún faltan la matriz de mutaciones/RPC completa,
  carreras de revocación y edición clínica, restauración integrada, observabilidad
  persistente, p95/p99, synthetic/soak y pruebas humanas de accesibilidad indicadas
  en los gates superiores.
- [ ] La decisión global permanece **NO-GO** hasta cerrar esos bloqueos críticos;
  esta sección no borra ni reemplaza los antecedentes anteriores.

## Acciones públicas concurrentes — 2026-08-31 — ESTADO ACTUAL

- [x] Se ejecutaron contra el Worker etiquetado ocho cancelaciones públicas
  simultáneas para el mismo turno, ocho solicitudes de reprogramación y ocho
  confirmaciones. Cada lote envió `Origin` y `Referer` del Worker para distinguir
  correctamente una carrera válida de un rechazo CSRF. El primer intento sin esos
  encabezados devolvió `Cross-site POST form submissions are forbidden` en las 24
  solicitudes: queda registrado como **antecedente del arnés**, no como fallo del
  producto; se corrigió el arnés y se repitió.
- [x] Cancelación: exactamente un éxito, siete conflictos esperables, cero 5xx,
  estado final `cancelled`, motivo persistido, un solo `appointment.public_cancelled`
  y la reprogramación posterior rechazada.
- [x] Reprogramación: exactamente un éxito, siete conflictos esperables, cero 5xx,
  estado final `reschedule_requested`, un solo `appointment.reschedule_requested` y
  el segundo pedido rechazado.
- [x] Confirmación: cero 5xx, al menos un éxito y el resto replay/idempotencia, estado
  final `confirmed` y un solo `appointment.public_confirmed`.
- [x] Resultado actual: **11/11 PASS, 0 FAIL**, cleanup por UUID completo. La
  comparación de estado/auditoría posterior confirmó que no hay doble transición ni
  doble registro. Este resultado cubre la carrera pública; no reemplaza las pruebas
  humanas de UX ni la observabilidad persistente.

## Matriz ofensiva RLS/RPC — hallazgo y cierre — 2026-08-31

### Antecedente reproducido antes del cierre

- [x] La sonda creó dos consultorios sintéticos independientes, tres usuarios por
  fixture y datos de agenda, pacientes e historia deliberadamente parecidos. Un owner
  de A, sin membresía en B, atacó B por PostgREST/RPC, incluyendo lecturas, updates,
  inserts y deletes. El resultado bruto fue **10 PASS y 12 FAIL de 22**.
- [x] El primer fallo real fue inequívoco: `user_can_manage_users(B)` devolvía `NULL`
  en lugar de `false` y `list_business_users(B)` devolvía las membresías y emails de
  B al usuario A. La causa fue `IF NOT <expresión NULL>` en PL/pgSQL: el rechazo no
  se ejecutaba cuando el rol era inexistente. `list_business_role_access(B)` tenía el
  mismo guard indirecto.
- [x] La misma condición permitía mutaciones SECURITY DEFINER de alto impacto en el
  fixture: archivar un paciente B, cambiar su ficha clínica, crear el vínculo
  profesional-paciente y modificar roles/invitaciones. Los casos de
  `remove_business_role_access` y `update_business_role_access` quedaron además
  marcados con contaminación de estado del arnés al encadenarlos después de la prueba
  de disable; la inspección del código mostró el mismo guard nullable y se incluyeron
  en la corrección, sin presentarlos como una medición aislada limpia.
- [x] Las lecturas y mutaciones directas de tablas protegidas por RLS sí quedaron
  aisladas en esa ejecución (15/15 lecturas y 9/9 updates más insert/delete), lo que
  permitió separar el problema de las políticas de tabla del problema de RPC
  SECURITY DEFINER. Los fixtures y usuarios fueron eliminados por IDs exactos.

### Corrección y verificación actual

- [x] La migración `20260831043000_harden_nullable_authorization.sql` conserva el
  contrato de `user_business_role()` (ausencia = `NULL`) pero hace `coalesce(...,
  false)` en `user_can_manage_business`, `user_can_manage_users`,
  `user_can_operate_business`, `user_can_configure_business`, `user_can_view_costs` y
  `user_can_read_clinical_patient`. Un bloque transaccional reescribió además todos
  los guards efectivos `role NOT IN (...)` de funciones públicas, incluidos perfiles,
  archivo/Drive, roles, vínculos y papelera radiográfica; la migración falla si queda
  algún patrón nullable en el catálogo.
- [x] Se validó primero con `BEGIN ... ROLLBACK` en la base local y en la remota. La
  aplicación remota fue una única transacción `ON_ERROR_STOP=1`; la fila de historial
  `20260831043000:harden_nullable_authorization` quedó registrada. La restricción de
  membresías aceptadas siguió `convalidated=true`.
- [x] La repetición contra `https://app.cita-suite.workers.dev` produjo **22/22 PASS,
  0 FAIL**: rol/acceso/gestión ausente ahora es `false`; ambos listados de miembros
  rechazan; archivo, ficha, Drive, vínculos y las cuatro mutaciones de roles rechazan
  sin cambios; no se crean invitaciones; RLS de 15 lecturas, 9 updates, insert y
  delete permanece aislado. No quedaron usuarios, consultorios, membresías,
  invitaciones, emails ni vínculos sintéticos.
- [x] Verificación directa del catálogo remoto: migración vigente como última fila,
  `business_users_active_requires_accepted_at` validada, **0 guards nullable
  residuales** y los cinco helpers de autorización devuelven `false` para un UUID sin
  membresía.
- [x] Filtros posteriores: `svelte-check` 0/0, Vitest secuencial **108 archivos y
  827 tests PASS**, `pnpm audit --audit-level=high` sin vulnerabilidades. La migración
  queda aplicada en la base remota.
- [x] El commit `b9271784060d2c271297cbe953fd0f3291df7e79` fue publicado por fast-forward
  en `prelaunch/cloudflare-20260830`. Dos builds con el SHA completo produjeron el
  output `.svelte-kit/cloudflare` byte a byte idéntico: 105 archivos, hash ordenado
  `e44bf9a86f8240adcdc62434c6cba3118a3d19fbca78ae263295283e10f3d63f`; Wrangler dry-run
  leyó 112 archivos (3946.83 KiB, 807.15 KiB gzip). El detalle queda en
  `audit-evidence/cloudflare/b927178-build-metadata.txt`.
- [x] El Worker fue desplegado después de ese filtro con tag
  `b927178-clean-e44bf9a`, mensaje `prelaunch nullable authorization hardening
  b927178`, y quedó al 100 % en la versión `790d330a-54f6-448f-af93-645152ba1570`.
  `/_app/version.json` respondió el SHA completo esperado; `/login` respondió 200,
  `private, no-store`, HSTS y CSP. La lista de deployments de Wrangler muestra el
  mismo tag, SHA y 100 % de tráfico.
- [x] La repetición post-deploy por HTTP/Cloudflare no dejó sólo una prueba de base:
  alta/membresía aceptada **4/4**, acciones públicas concurrentes **11/11**,
  reservas/idempotencia **8/8**, creación administrativa concurrente **5/5** e
  IDOR autenticado **14/14**. En todas las ejecuciones hubo cleanup exacto y cero
  HTTP 5xx inesperados.

### Estado de gate

- [x] El hallazgo crítico de autorización queda **corregido y demostrado en la base
  remota y en el Worker publicado**. G3 sigue parcial por los frentes no equivalentes
  aún pendientes (revocación durante sesión bajo carrera, restauración integrada,
  observabilidad y rendimiento); no se considera que esta corrección por sí sola
  autorice el lanzamiento. La decisión global continúa **NO-GO**.

## Actualización posterior — cierre de enumeración de correos y límite de API del scheduler — 2026-08-31

### Estado actual

- [x] La auditoría de privilegios remota detectó que la función legada
  `public.is_email_enabled(text)` conservaba `EXECUTE` heredado de `public` y, por
  tanto, podía ser consultada por un cliente anónimo para confirmar si un correo
  pertenecía a la lista interna `allowed_emails`. La aplicación actual no la invoca;
  la sonda anónima obtuvo `200 false` antes del cambio.
- [x] Se creó la migración mínima
  `20260831050000_revoke_email_probe.sql`, que revoca `EXECUTE` de `public`, `anon` y
  `authenticated` sin borrar la función ni tocar datos, tablas, políticas o Storage.
  La prueba transaccional local dio `anon=false`, `authenticated=false` y
  `service_role=true`; la migración remota se aplicó en una única transacción
  `ON_ERROR_STOP=1` y quedó registrada en `supabase_migrations.schema_migrations`.
- [x] La repetición contra el endpoint REST de Supabase con la clave anónima recibió
  HTTP `401 permission denied for function is_email_enabled`; la consulta dejó de
  ser posible desde clientes públicos. El contrato quedó protegido por un test
  secuencial de Vitest.
- [x] El nuevo build reproducible produjo dos veces 105 archivos con hash ordenado
  `27996308d3781de1be64623a49cc42ec3b76ed38e5e2f3896e269b3596bdf19e`; el manifiesto
  queda en `audit-evidence/cloudflare/4f59797-build-metadata.txt`. Wrangler leyó 112
  assets (3946.83 KiB, 807.15 KiB gzip) con `PUBLIC_SITE_URL` del Worker.
- [x] Se publicó el candidato exacto `4f59797378e1b086f55f9009722c88ad475ffe4e`
  con tag `4f59797-clean-27996308`, mensaje `prelaunch revoke public email probe
  4f59797`, versión Cloudflare `3f095e6f-bfc3-41af-97c3-0a9ddc9d1838` y 100 % de
  tráfico. `/_app/version.json` devolvió el SHA completo y el smoke de reserva pública
  siguió en HTTP 200 con `no-store`, HSTS, CSP, `nosniff`, `DENY` y
  `strict-origin-when-cross-origin`.
- [x] La sonda anónima post-deploy contra Supabase siguió recibiendo HTTP 401 para
  `is_email_enabled`; no se reabrió la enumeración. La migración y el contrato de
  privacidad están, por tanto, presentes en base y código del candidato publicado.

### Scheduler cron-job.org — evidencia y limitación operativa actual

- [x] Se intentó una lectura autenticada, sin mutación, del job productivo `7795525`
  usando la API oficial. La API respondió HTTP `429` incluso después de una espera
  de 20 segundos y sin header `Retry-After`; se detuvo el reintento para no agotar ni
  presionar el límite diario. No se modificó el job productivo ni se creó un job de
  prueba.
- [x] La configuración y las ejecuciones reales exitosas que ya figuran en las
  secciones históricas/actuales (POST cada diez minutos, HTTP 200 y política de
  alertas activada) siguen siendo evidencia válida; esta respuesta `429` es un
  antecedente operativo nuevo de la API, no una falla del endpoint del Worker.
- [ ] Sigue sin demostrarse la entrega humana de una alerta de fallo, el reintento
  observable y la recuperación de un job controlado. Para cerrarlo se necesita una
  ventana en la que la API permita una consulta/creación controlada o evidencia de
  la bandeja de correo configurada; no se marcará G9 verde por inferencia.

## Actualización posterior — carrera de estados internos de turnos — 2026-08-31

### Antecedente reproducido antes del arreglo

- [x] Con la versión Cloudflare anterior (`4f59797…`), el arnés creó un consultorio,
  profesional, servicio y dos turnos sintéticos, inició una sesión autenticada y
  envió ocho acciones simultáneas contra el Worker. En la cancelación interna hubo
  **3 respuestas de éxito y 3 registros de auditoría** para un solo turno; en la
  carrera mixta cancelar/reprogramar también se observaron **3 éxitos** y tres
  auditorías de cancelación. El estado final no siempre evidenciaba la pérdida porque
  varias escrituras tenían el mismo valor, pero la trazabilidad clínica quedaba
  duplicada y una reprogramación podía competir con una cancelación.
- [x] La corrida dejó un error del propio arnés al intentar encadenar `.catch` sobre
  el builder de Supabase (no era una promesa); el fixture restante fue localizado por
  el marcador `STC_…`, eliminado por el ID exacto y la cuenta sintética fue borrada.
  El arnés quedó corregido antes de repetirlo y este error de método se conserva como
  antecedente, no como resultado de la aplicación.

### Corrección y verificación actual

- [x] `updateAppointmentStatus` y `rescheduleAppointment` ahora incluyen
  `.eq('status', estado_observado).select('id').maybeSingle()` en la misma mutación.
  Si otra solicitud ganó la carrera, no se escribe ni se genera auditoría y se
  devuelve `APPOINTMENT_STATUS_CONFLICT`, con un mensaje que pide recargar la agenda.
  Esto impide sobrescribir una transición o resucitar una cancelación.
- [x] Se agregaron tests unitarios de conflicto, auditoría posterior al commit y
  reprogramación concurrente; el archivo de appointments quedó en **19/19 PASS**.
- [x] La repetición post-deploy contra `https://app.cita-suite.workers.dev` con el
  candidato `fd4d18c1fd5e4a555a20671ada420078f832b0a2` produjo, en ocho cancelaciones
  simultáneas, **1 éxito, 7 conflictos, 1 auditoría y cero HTTP 5xx**. La carrera
  mixta de cuatro cancelaciones y cuatro reprogramaciones produjo una sola transición
  ganadora; el estado final y su única auditoría coincidieron, sin resucitar el turno.
- [x] El candidato fue construido dos veces con 105 archivos y hash ordenado
  `83d71bfd28b8428d8522acc87ad0a8174690c71b70e82b8e591efcb42428df1b`; Wrangler leyó
  112 assets (3947.37 KiB, 807.22 KiB gzip). Se publicó con tag
  `fd4d18c-clean-83d71bfd`, mensaje `prelaunch serialize authenticated appointment
  transitions fd4d18c` y versión Cloudflare
  `165fbf68-6f59-4d9c-b05a-d48aa9cd233e` al 100 %. `/_app/version.json` devuelve el
  SHA completo esperado.
- [x] El arnés corrigió su propio cleanup y verificó que no quedaran negocios ni
  usuarios sintéticos. El hallazgo de carrera queda cerrado en código, base y Worker;
  G3 sigue parcial por los restantes frentes independientes y la decisión global
  continúa **NO-GO**.

## Actualización posterior — política RLS de `allowed_emails` — 2026-08-31

### Antecedente reproducido

- [x] La revisión completa de `pg_policies` encontró que la política heredada
  `allowed_emails_master_read` tenía `USING (true)` para `authenticated`. La
  función pública `is_email_enabled(text)` ya estaba cerrada por la migración
  anterior, pero esa política dejaba leer directamente la lista interna de
  correos a cualquier usuario autenticado.
- [x] La cuenta de prueba autenticada obtuvo HTTP `200` y una fila al consultar
  `allowed_emails?select=id&limit=1`; no se imprimieron correos ni identificadores.
  Esto es un hallazgo de privacidad real, independiente del endpoint anónimo ya
  cerrado, y queda conservado como antecedente.

### Corrección y estado actual

- [x] Se creó `20260831060000_restrict_allowed_emails_policy.sql`, que elimina
  únicamente la política global heredada. No borra la función, datos, tabla,
  Storage, secretos ni políticas explícitas del maestro.
- [x] La aplicación remota se ejecutó en una única transacción con
  `ON_ERROR_STOP=1`: antes había 1 política con ese nombre y después 0; la fila
  `20260831060000:restrict_allowed_emails_policy` quedó registrada en el historial.
- [x] El usuario autenticado de prueba ahora recibe HTTP `200` con cero filas;
  el maestro autenticado sigue recibiendo HTTP `200` con filas (sin exponer sus
  valores en el registro). La consulta anónima continúa sin acceso.
- [x] El contrato de migración quedó cubierto por Vitest; la comprobación remota
  no encontró políticas públicas con `USING (true)` o `WITH CHECK (true)`.
- [ ] Falta publicar esta corrección en el Worker y repetir el smoke autenticado
  en Cloudflare con el candidato exacto. Hasta esa publicación, la base está
  corregida pero el gate de promoción permanece **NO-GO**.

## Actualización posterior — falsos cierres de sesión durante caída de Auth — 2026-08-31

### Antecedente de código

- [x] `hooks.server.ts` trataba cualquier error de `getUser()` o `refreshSession()`
  como sesión inválida, borraba las tres cookies y redirigía a login. Un error
  transitorio de red, timeout, 429 o 5xx de Supabase Auth podía expulsar a un
  profesional legítimo aunque su token siguiera siendo válido.

### Corrección y estado actual de código

- [x] Se agregó clasificación explícita de errores transitorios (429, 5xx,
  timeout/red/retryable) que conserva las cookies y devuelve HTTP 503 sin ejecutar
  rutas protegidas. La respuesta no revela códigos internos, indica que los datos
  no se modificaron y contiene `no-store`/`Retry-After`.
- [x] Los errores de autenticidad no transitorios siguen invalidando la sesión y
  limpiando cookies; se preserva el cierre seguro ante tokens inválidos o revocados.
- [x] Tests de hooks: **6/6 PASS**, incluidos fetch fallido `AuthRetryableFetchError`,
  429 y token inválido. `svelte-check`: 0 errores, 0 warnings.
- [ ] Falta demostrar la caída real de Auth desde una ventana controlada de
  staging/Cloudflare; no se debe provocar una indisponibilidad en el proyecto
  productivo. El gate de resiliencia y la decisión global siguen **NO-GO**.

## Actualización posterior — carreras de Seguimientos — 2026-08-31

### Antecedente detectado por inspección

- [x] `markFollowUpDone`, `snoozeFollowUp` y `updateFollowUp` leían una fila y
  luego hacían `UPDATE ... WHERE status = 'pending'` sin comprobar la fila
  devuelta. Supabase no considera error un `UPDATE` que afecta cero filas: una
  segunda pestaña podía mostrar éxito aunque la primera hubiese cambiado o
  completado el seguimiento; en edición, dos formularios podían pisarse.

### Corrección y estado actual de código

- [x] Las mutaciones ahora cargan sólo seguimientos pendientes, condicionan por
  `status` y `updated_at` observado, piden `select('id').maybeSingle()` y fallan
  con `FOLLOWUP_STATUS_CONFLICT` (HTTP 409) sin falso éxito. El mensaje visible
  pide recargar la lista y no expone códigos técnicos.
- [x] Tests aislados de seguimientos: **11/11 PASS**; la suite completa posterior
  al cambio de código queda pendiente de repetir tras la publicación.
- [ ] Falta repetir la carrera concurrente contra el Worker publicado y verificar
  que no se duplique ninguna auditoría. Hasta esa evidencia, G3/G4 permanecen
  parciales y la decisión global es **NO-GO**.

## Actualización posterior — RPC legado de expiración global — 2026-08-31

### Antecedente reproducido

- [x] La inspección del catálogo remoto encontró `public.expire_public_booking_holds()`
  fuera de las migraciones actuales. Era `SECURITY DEFINER`, recorría turnos con
  `pending_confirmation` y archivaba pacientes de todos los consultorios, pero
  conservaba `EXECUTE` para `authenticated`. Un usuario de prueba pudo invocarlo
  por PostgREST (HTTP 200, sin imprimir datos); no se creó ni modificó ningún
  fixture porque el estado actual no contiene ese status.
- [x] La función es un residuo del flujo histórico de retenciones y no aparece en
  el código actual ni en el scheduler operativo. Su existencia ejecutable era, por
  sí misma, una capacidad de mutación transversal no autorizada.

### Corrección y estado actual

- [x] `20260831061000_revoke_legacy_hold_expirer.sql` revoca todo `EXECUTE` de
  `public`, `anon` y `authenticated`, sin eliminar la función ni tocar tablas,
  datos, Storage o triggers. La aplicación remota se hizo en una transacción
  `ON_ERROR_STOP=1`; el historial registra la migración.
- [x] Las sondas posteriores reciben HTTP `403` con sesión autenticada y HTTP
  `401` sin sesión. El RPC ya no puede ser llamado por clientes públicos.
- [ ] Falta incluir la migración en un build/deploy del Worker y repetir el smoke
  de superficie desde Cloudflare. El cierre de base es válido, pero la promoción
  sigue **NO-GO** hasta verificar la versión publicada.

## Estado actual — cierre de incidente Pako, contexto de paciente y fecha clínica — 2026-08-31

Esta sección es el estado actual de esta corrida. Las secciones anteriores no se
eliminan ni se reescriben: quedan como antecedentes históricos. La Regla Central
sigue vigente: los pacientes, turnos, profesionales, consultorios, emails y
archivos de prueba son descartables; el código, las migraciones, funciones,
triggers, RLS, grants, constraints, Storage, secretos, configuración de Cloudflare
y la capacidad futura de operar con pacientes reales permanecen protegidos. No se
ejecutó DDL destructivo sobre producción.

### Incidente informado por la cuenta maestra

- [x] Se investigó el caso de prueba **Pako Helmbold** en el consultorio de la
  cuenta maestra. La evidencia persistente de `patient_profile_change_events`
  muestra dos commits reales para ese paciente durante la ventana informada:
  `2026-08-31T21:54:36.646782Z`, con el campo `obra social`, y
  `2026-08-31T21:55:08.959676Z`, con `fecha de nacimiento`, `plan de la obra
  social`, `alergias`, `medicación` y `antecedentes`. Por lo tanto, el primer
  intento no fue demostrado como “no guardado”: alcanzó la base; el segundo
  también alcanzó la base. No se imprimieron secretos ni datos ajenos al fixture.
- [x] La revisión del código confirmó que la acción `update_patient` ejecuta el
  RPC atómico de actualización clínica, valida las versiones observadas y sólo
  responde después del commit. La ruta de éxito redirige a `?tab=datos`.
- [x] Se reprodujo el defecto determinista que explicaba la parte de UX: antes
  de la corrección, clicar **Datos** cambiaba sólo el estado local y dejaba la
  URL sin `tab`; al recargar esa URL, la carga por defecto era **Historial**. La
  secuencia observada fue: Datos visible antes de recargar, URL sin `?tab=datos`,
  y luego Historial visible después de recargar.
- [ ] No existe un trace persistente del Worker correspondiente al primer clic
  informado por la persona usuaria. Por eso no es posible atribuir con certeza
  histórica si la navegación inicial se perdió por red, navegador, respuesta de
  borde o una interrupción posterior al commit. No se presenta esa hipótesis como
  hecho. El tail histórico se habilitó recién durante la verificación actual.

### Defectos corregidos y estado actual

- [x] `selectTab` ahora refleja siempre `historial`, `datos` o `radiografias` en
  la query mediante `replaceState`; el refresco y los enlaces conservan el
  contexto exacto de la pestaña.
- [x] `formatDate` distingue una fecha de calendario `YYYY-MM-DD` de un instante
  UTC. La fecha almacenada `2004-02-03` ya no aparece como 2 de febrero en
  Argentina: la ficha muestra **3 de febrero de 2004** y el editor conserva el
  día `03`. Se agregó prueba unitaria específica en zona argentina.
- [x] El formulario de datos usa `enhance`, impide doble envío mientras guarda,
  muestra **Guardando…**, y ante un fallo de transporte conserva el modal y lo
  escrito con el mensaje accionable: “No pudimos guardar los cambios. Revisá tu
  conexión y volvé a intentar; tus datos siguen en el formulario.”
- [x] La prueba de red interrumpida abortó exactamente un POST de actualización;
  confirmó modal visible, mensaje anterior, dirección escrita conservada y URL
  aún en `?tab=datos`. Tras cancelar y recargar, la dirección de prueba no quedó
  persistida y la ficha continuó en Datos. Esto demuestra ausencia de falso éxito
  y ausencia de pérdida de trabajo local.
- [x] El guardado normal posterior en el Worker nuevo terminó con el modal
  cerrado, URL `?tab=datos`, ficha Datos visible y la fecha correcta. El POST
  mejorado fue observado como HTTP 200 (respuesta de acción SvelteKit seguida de
  invalidación de datos); no se confundió ese 200 con el 303 de un formulario
  nativo anterior.

### Candidato, reproducibilidad y publicación verificada

- [x] El commit de runtime es
  `64031a356a7b972ac6aaa61aaf1fb60a51dc7c57`, mensaje `fix: preserve patient
  context and date-only display`. `origin/prelaunch/cloudflare-20260830`
  coincide exactamente con ese SHA. Las capturas y scripts de evidencia que ya
  estaban en el árbol no se agregaron al commit ni se eliminaron.
- [x] Dos builds consecutivos y secuenciales consumibles por Cloudflare
  produjeron 105 archivos idénticos. El manifiesto ordenado de contenido fue
  `58e4de88c97be81f8740c3a74a56f7b06070064bd54c6a90d6ea3038bef67189` en ambos
  builds; `_worker.js` fue
  `cf4056f946ba2822fb93035da445ea2b74c918e9bbbb7d646dffcc8db657d484` en ambos.
  El `version.json` de ambos contiene exactamente el SHA de runtime. No se
  trató la coincidencia de comportamiento como prueba byte a byte: se comparó
  el output de `.svelte-kit/cloudflare` que consume Wrangler.
- [x] Cloudflare publicó el Worker con mensaje `prelaunch patient context date
  UX 64031a3`, tag `prelaunch-64031a3` y versión
  `3a749972-149f-474d-bdfa-e097f1e10c00` al **100 %**. La lista de deployments
  remota confirmó esa relación versión/tag/tráfico.
- [x] `GET https://app.cita-suite.workers.dev/_app/version.json` respondió HTTP
  200 y `{"version":"64031a356a7b972ac6aaa61aaf1fb60a51dc7c57"}`. No se consideró
  suficiente un build local: también se comprobó la respuesta remota.
- [x] Un tail del guardado normal mostró `scriptVersion.id` igual a
  `3a749972-149f-474d-bdfa-e097f1e10c00`, POST al Worker, `outcome: ok`,
  respuesta HTTP 200 y `exceptions: []`. Las cookies y el identificador del
  paciente fueron redactados por el propio tail; no se conservaron secretos.

### Verificación automatizada posterior a la publicación

- [x] `pnpm --dir apps/web check`: 0 errores y 0 advertencias.
- [x] Vitest completo: 120 archivos y 860 tests, todos PASS, en un solo worker.
- [x] Suite E2E completa contra el Worker versionado, con un solo worker:
  27 casos descubiertos, **18 PASS, 0 FAIL** y 9 skips condicionados. Los skips
  quedaron identificados: cinco de Seguimientos y uno de auditoría UX por no
  tener `CITA_SUITE_TEST_BUSINESS_ID` en el archivo de entorno de esa corrida,
  dos casos de reserva demo porque producción tiene `DEMO_MODE=false`, y un caso
  de Google real porque no había cuenta/credenciales/2FA operables.
- [x] Los seis casos que se habían omitido por el ID ausente se repitieron luego
  con el `CITA_SUITE_TEST_BUSINESS_ID` de prueba autorizado: auditoría UX de la
  cuenta real y los cinco casos de Seguimientos, **6/6 PASS**. La búsqueda local
  de pacientes se renderizó en 26 ms. La cobertura efectiva combinada quedó en
  **24 PASS, 0 FAIL**; sólo permanecen los dos demo intencionalmente apagados y
  Google real fuera de alcance operativo.
- [x] El caso que había quedado intermitente, “confirmar sin teléfono registra la
  decisión y no vuelve a molestar”, pasó una vez en Cloudflare y luego **2/2**
  repeticiones adicionales, siempre con un solo worker.
- [x] El test de archivos clínicos dejó de depender de una espera fija de 650 ms
  y espera la request exacta; la suite publicada lo ejecutó sin fallo. La
  modificación del arnés no cambia el runtime clínico.
- [x] La sonda `current-candidate-security-probe.mjs` se repitió después de la
  publicación con el SHA esperado de este candidato: **6/6 PASS**. Confirmó
  aislamiento de `allowed_emails`, rechazo anónimo/autenticado del RPC legado y
  que `/_app/version.json` atiende exactamente `64031a3`.

### Dictamen del incidente y decisión de lanzamiento

- [x] El incidente Pako queda **cerrado en el candidato publicado**: el primer
  commit está demostrado en base, el contexto de pestaña ahora es persistente,
  las fechas de calendario no se corren un día y un fallo de red conserva el
  trabajo del profesional. La reproducción posterior no generó cambios clínicos
  no deseados ni basura persistente.
- [ ] Este cierre no convierte la auditoría global en GO. Siguen siendo gates
  independientes los frentes históricos aún marcados como parciales o NO-GO
  (entre otros: matriz interna completa en dispositivos reales/BrowserStack,
  observabilidad y alertas persistentes, rollback y mezcla de versiones,
  recuperación desde fallos controlados, capacidad/soak y métricas con
  profesionales). Esos límites no se borran por haber cerrado Pako.

## Estado actual — intento de cambio de workers.dev y rollback seguro — 2026-09-01

Esta sección es el registro actual de una migración solicitada y cancelada al
comprobar una limitación real de Cloudflare. No reemplaza ni reescribe la
evidencia histórica anterior.

### Antecedente verificado antes de la migración

- [x] El Worker productivo era `app`, con el identificador inmutable
  `621733096ca44e35b51cbd1995bc530c`, y el subdominio de cuenta que Cloudflare
  devuelve por API era `cita-suite`. El endpoint efectivo era
  `https://app.cita-suite.workers.dev`.
- [x] El host solicitado `https://cita.suite.workers.dev` resolvía en DNS, pero
  respondía HTTP 404 con código de borde 1042; no estaba asociado al Worker.
- [x] El inventario previo del Worker tenía 27 secretos y un binding de texto
  `PUBLIC_SITE_URL`; no se creó un Worker paralelo ni se copiaron secretos a un
  destino distinto.
- [x] El scheduler de cron-job.org (job `7795525`) estaba habilitado, pero en
  la configuración real consultada apuntaba al endpoint controlado
  `__cron_audit_controlled_failure_20260831`, con POST, minuto 16 de cada hora,
  y último estado HTTP fallido. Las afirmaciones históricas de un endpoint
  productivo cada diez minutos quedan como antecedente, no como estado actual.

### Cambios intentados y evidencia

- [x] Se creó el commit de candidato `d7716c4` con las referencias activas al
  host solicitado, dos builds consecutivos del output consumido por Wrangler y
  comparación byte a byte: `_worker.js` fue
  `cf4056f946ba2822fb93035da445ea2b74c918e9bbbb7d646dffcc8db657d484` en ambos
  y el árbol ordenado fue
  `d0efc819b087f9d862797e29b0baa294198e7777817eccc6c9d990030b48636c` en ambos.
- [x] Se renombró temporalmente el mismo Worker por su ID inmutable de `app` a
  `cita`. Cloudflare confirmó que el host resultante era
  `https://cita.cita-suite.workers.dev`, no `cita.suite.workers.dev`, y que
  conservaba el mismo ID.
- [x] El `PUT` directo del subdominio de cuenta `suite` fue rechazado porque la
  cuenta ya tenía asociado `cita-suite`. Se retiró el subdominio sólo después de
  conservar el snapshot; el intento de crearlo como `suite` respondió HTTP 403
  indicando que `suite` no está disponible. No se publicó código durante esa
  ventana.
- [x] Se restauró el subdominio de cuenta `cita-suite` y se renombró el mismo
  Worker nuevamente a `app`. El host anterior volvió a responder HTTP 200 en
  `/_app/version.json`; el Worker continuó atendiendo el runtime publicado
  `64031a356a7b972ac6aaa61aaf1fb60a51dc7c57`.
- [x] El código del candidato se revirtió mediante commits de trazabilidad
  (`af30b82` y `c7ac72c`), sin tocar capturas, backups, migraciones ni datos.
  Las referencias activas volvieron a `app.cita-suite.workers.dev`; los
  antecedentes de esta sección no se borraron.

### Incidente de secreto y estado posterior

- [x] Durante una consulta de diagnóstico del job se imprimió accidentalmente
  el valor del header secreto de cron en la salida de terminal. Se trató como
  comprometido: se rotó `INTERNAL_JOB_SECRET` en Cloudflare a un valor nuevo no
  registrado en texto, y el header del job se actualizó sin imprimir su valor.
  El secreto no se agregó al repositorio ni a este documento.
- [x] La rotación generó versiones de Worker de tipo `secret`, pero no modificó
  el código ni la base. El job conserva actualmente su URL de fallo controlado,
  su horario de minuto 16 y sus notificaciones; no se presenta como scheduler
  productivo demostrado.
- [ ] El dominio final `cita-suite.com.ar` queda pendiente de compra y de una
  migración separada. Al disponer de la zona DNS, se deberá adjuntar el dominio
  personalizado al mismo Worker, actualizar `PUBLIC_SITE_URL`, Supabase Auth,
  callbacks de Google si se habilitan, cron-job.org, enlaces públicos, ICS/PDF,
  service worker y todas las allowlists; después habrá que repetir la
  certificación de host, cookies, caché, TLS, redirecciones y callbacks.

### Decisión actual

- [x] No se despliega `cita.suite.workers.dev` porque Cloudflare demostró que no
  está disponible para esta cuenta. El estado actual canónico sigue siendo
  `https://app.cita-suite.workers.dev` hasta la compra y configuración de
  `cita-suite.com.ar`.
- [ ] La auditoría global continúa NO-GO por los gates independientes ya
  enumerados; este intento de dominio no los vuelve verdes ni sustituye las
  pruebas pendientes.

### Arquitectura de dominio futura confirmada por la persona propietaria — 2026-09-01

- [ ] La landing deberá responder en la raíz: `https://cita-suite.com.ar/`.
- [ ] La aplicación clínica deberá responder bajo el prefijo:
  `https://cita-suite.com.ar/app`.
- [ ] Esta decisión es planificación futura, no estado productivo actual. Antes
  de activarla se deberá verificar específicamente el comportamiento del
  prefijo `/app` en rutas SSR, assets y chunks, cookies (Path y SameSite),
  service worker, redirects, enlaces públicos de reserva, ICS/PDF, callbacks de
  Supabase y Google si se habilitan, cron-job.org, caché y páginas 404/500.
- [ ] La configuración no deberá cambiarse sólo sustituyendo el dominio: habrá
  que confirmar si SvelteKit y el Worker necesitan `paths.base`, reglas de
  routeo o una distribución conjunta con la landing. La certificación deberá
  demostrar que tanto `/` como `/app` funcionan sin fugas, redirecciones
  silenciosas ni pérdida de contexto.
