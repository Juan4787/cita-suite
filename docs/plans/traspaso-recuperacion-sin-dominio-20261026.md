# Traspaso exacto: recuperación sin dominio — 26 de octubre de 2026

> **Superado a las 21:50 UTC** por [el traspaso del panel y la recuperación](traspaso-apertura-panel-20261026.md): `40373057375` terminó fallida y la entrega pasó a la candidata `1fa2f2f` y a la base `dbd69d2`. Este documento se conserva como antecedente; no ejecutar sus pasos con `ad5ac57`/`375e16a`.

## Punto de interrupción pedido por el usuario

Última observación: **17:59:29 UTC / 14:59:29 Argentina**. El usuario pidió dejar documentado el punto exacto para que otro modelo continúe. Se detiene el trabajo de implementación/publicación en este punto; la auditoría remota ya solicitada continúa. No se creó otro temporizador ni proceso local de reanudación.

**Siguiente operación: consultar la corrida existente `40373057375`, recuperar sus evidencias cuando termine y resolver el preflight productivo fallido antes de publicar. No despachar otra corrida ni volver a compilar mientras ésta siga activa.**

Leer primero `AGENTS.md` y el plan original **completo**, `docs/plans/refactorizacion-cita-suite.md` (697 líneas), luego el registro y este traspaso. El plan original no se modificó para esta continuación. Las decisiones posteriores aceptan la desviación de latencia sólo para un consultorio, mantienen las demás garantías y prohíben más cargas de dos consultorios en Free. No contratar servicios; el dominio lo comprará el usuario. Autonomía y publicación autorizadas, sin preguntas intermedias. Ninguna autorización convierte un control pendiente en aprobado.

## Estado de código, artefactos y entornos

| Elemento | Estado comprobado |
|---|---|
| Revisión candidata | `ad5ac57435b41eef452be3c7449bb2fe3aacf682` |
| Rama remota auxiliar | `verify/password-recovery-router-ready-20261026`, repo `Juan4787/cita-suite-verificacion` |
| Navegador dirigido | `40368550984`, aprobado: dos casos con Auth real descartable y cinco anchos |
| Artefacto candidato | `40369186753`, descargado y verificado en `.verification/releases/ad5ac57/`, 216 archivos |
| Recuperación compatible | `375e16a5f97e3e9069853c22e7dd251ffe193dbe`, rama `verify/password-recovery-compatible-20261026` |
| Artefacto compatible | `40369909691`, descargado y verificado en `.verification/releases/375e16a/`, 216 archivos |
| Staging | `cita-suite-staging.cita-suite.workers.dev`, marcador candidata confirmado HTTP200 a17:54UTC |
| Versión candidata de staging | `528f4d69-f1ae-421d-b79b-8e37090cffd8` |
| Versión compatible de staging | `d8ecc08a-4a7f-44cd-908b-663868279144` |
| Reversión desplegada de staging | `40371503253`, aprobada; después se volvió nativamente a la candidata |
| Auditoría completa | **`40373057375`, `in_progress`, sin conclusión**; job `121748644577`, paso `Verify sequentially` |
| Entradas del release | `level=release`, `artifact_run=40369186753`, `rollback_run=40369909691`; fuente exacta `ad5ac57` |
| Producción | **Sigue en `0851de59ed7971debe2514e6d6851d142bbc5766`; la corrección no se publicó** |
| Worker productivo | `app`, cuenta `52b358653379c162b5a07b10ae5e84b3`, versión `70f0cdc0-c2fd-4b7d-93e6-d6a68e2529be`, deployment `0515d135-8044-47fe-964d-6476a6be260d` |
| Programador productivo | Versión `94bed118-58f7-4608-b543-202812184fda`, deployment `952422d5-5c61-46b9-9faa-21fe59496966`, cinco cron activos |
| Programador de staging | Cero cron; no se activó ni se duplicó un programador |
| SMTP | **No configurado; no existe contraseña dedicada disponible; no se envió ni recibió correo real** |

La metadata productiva se releyó a partir de17:57:52UTC:33 bindings conservados por nombre/tipo, sin extraer valores. El preflight falló después, en la primera lectura del estado de base, antes de guardar conteos o comprobar autenticación/agenda. Recibo `production-before.json`, `ok=false`, `failure=READONLY_PREFLIGHT_FAILED`; salida1. **No se estableció la causa**: el auxiliar sanea el error y no conservó el detalle. No afirmar caída, contraseña incorrecta, timeout o problema de pooler sin nueva evidencia. No usar este recibo como preflight aprobado. No se detuvo el programador, no se desplegó producción y no se cambió la base ni SMTP.

El compatible375 deriva de la producción0851 e incorpora **únicamente los tres archivos de recuperación corregidos**. El baseline0851 sin corrección tiene el falso éxito ante contraseña repetida y no puede aprobar la nueva regresión. No omitir esa regresión ni presentar375 como el binario productivo antiguo intacto. SQL, tareas y otros módulos no cambiaron. Los35 archivos de Natalia son idénticos a los publicados: no corresponde redesplegar el sitio por este arreglo.

## Qué cambió y qué demuestran las pruebas

- `/reset/+page.server.ts`: valida y normaliza correo, traduce configuración/red/límites a mensajes utilizables, y lee `PUBLIC_SITE_URL` desde `$env/dynamic/public`. Antes lo buscaba en el espacio privado, que excluye las variables `PUBLIC_`.
- `/reset/+page.svelte`: respuesta condicional sobre la existencia de la cuenta; no afirma una entrega real.
- `/reset/callback/+page.svelte`: rechaza contraseña repetida con un mensaje correcto, una sola actualización pendiente, retira el fragmento antes de errores, desactiva la detección duplicada de sesión del SDK y distingue actualización exitosa de fallo posterior al cerrar sesión. `afterNavigate` difiere una microtarea porque SvelteKit2.70.3 marca `started=true` después de ejecutar el callback inicial. El código exacto y su huella están en `router-initialization-source.json`.
- Nuevas unidades:10 del servidor y8 del cliente. El mock inicial del router era demasiado permisivo: se corrigió para reproducir el orden real, se obtuvieron8 fallos y luego8 verdes. Los primeros verdes no se usaron como prueba del navegador.
- `e2e/password-recovery.spec.ts`: preflight propio permitido/origen ajeno rechazado; identidad y membresía sintéticas propias, token de recuperación verificado por Auth real, contraseña repetida rechazada, contraseña distinta guardada, ingreso real por UI, contraseña anterior y token consumido rechazados; limpieza de recursos propios. Cinco anchos320/390/768/1280/1600, controles reales y `layoutIssues`/`alignTaskForCapture`. Sin trazas que retengan credenciales.
- `serve-booking-fixture.mjs`: permite el encabezado que añade el SDK (`x-supabase-api-version`) sólo en el CORS del origen descartable propio. Control negativo desde origen ajeno. No cambia CORS productivo.
- Plantilla española `supabase/templates/recovery.html` y guía `docs/architecture/correo-de-recuperacion.md`; el empaquetador incluye esa documentación. No se cargó la plantilla en Supabase.

El ensayo de navegador dirigido está aprobado **sólo en el entorno descartable**. `realEmailDelivered=false` y `emailUrlFollowed=false`. Generó/verificó un token con la API de Auth: no acredita un correo SMTP ni el recorrido desde la URL recibida. No confundir Supabase Auth con Google OAuth. Google en la alternativa propuesta aporta SMTP.

## Evidencia que debe conservarse

Directorio principal: **`.verification/recovery-20261026/`**. Todo lo siguiente es local y queda disponible al siguiente modelo; los secretos no están en este documento ni deben copiarse al repo público.

| Recibo o ruta | Uso |
|---|---|
| `prestate.json`, `before/`, `git-status-before.bin` | Preservación del árbol original y preimágenes |
| `browser-approved-receipts.json`, `browser-approved-evidence/`, `browser-approved-job.log` | Dos casos y prueba de Auth real; paquete SHA256 `ba162f31a2d2a92bde0df05998f5d5d29f8d546438419eaad2dc2cd3482363ad` |
| `compatible-baseline.json` | Construcción acotada del compatible y sus tres archivos |
| `staging-candidate-deploy.*` | Instalación candidata |
| `staging-compatible-deploy.*`, `staging-compatible-deploy-retry.*` | Fallo Cloudflare10013 del primer upload; readback sin cambio y un reintento controlado exitoso |
| `staging-rollback-run.json`, `staging-rollback-evidence/` | Rollback alojado aprobado:130 archivos cliente,35 Natalia,61 relaciones sin exposición, reserva/gestión/cancelación nativas en escritorio/móvil. Paquete `fbac447d319043c09b8044ed7577ab68c4973a37a45fab1243a7873679f9ee36` |
| `staging-return-candidate.*` | Retorno nativo exitoso; primer readback no confirmado dentro de su ventana. Ese `verified=false` histórico no se sobrescribió |
| `release-dispatch.json` | Nueva lectura HTTP200 de candidata y único dispatch de la auditoría completa |
| `release-at-handoff.json` | Estado remoto de la corrida completa a17:59:29UTC |
| `production-before.json`, `production-state.mjs` | Metadata productiva actual y primer preflight fallido; **no aprobado** |
| `handoff-state.json` | Los nueve archivos de código/tests/plantilla/arnés coinciden byte por byte conad5; HEAD/índice/lock/plan preservados |

Los fallos anteriores, sus fuentes y causas están en el registro general. Corridas40361642149,40362677680,40364107430,40364976351,40365935003 y40367214719 no son verdes;40366395474 se canceló al descubrir que su código ya era obsoleto. Los fast40365119806 y40367435519 aprobaron revisiones anteriores, **no sustituyen el release de la fuente final**. No borrar ni reinterpretar estas pruebas. El error de contraseña repetida HTTP422 es el control negativo esperado; no hay permiso para suprimir errores generales.

## Continuación reproducible

1. Consultar **la corrida existente**, sin un nuevo dispatch:

   ```bash
   gh run view 40373057375 --repo Juan4787/cita-suite-verificacion --json status,conclusion,headSha,url,jobs
   ```

   Si sigue activa, esperar sin duplicar trabajo ni cargar esta computadora. Si termina fallida, conservar y diagnosticar el primer fallo real; no repetir ciegamente ni llamar aprobado a un paso omitido. Si termina aprobada, verificar fuentead5 y recuperar los resultados: el verde deGitHub solo no acredita todas las garantías.

2. Recuperar el log del job identificado. `gh run view --log` devolvió anteriormente vacío con salida0; usar la API del job si vuelve a ocurrir. Estos comandos no imprimen el log completo:

   ```bash
   gh api repos/Juan4787/cita-suite-verificacion/actions/jobs/121748644577/logs > .verification/recovery-20261026/release-job.log
   python3 - <<'PY'
   from pathlib import Path
   from zipfile import ZipFile, ZIP_DEFLATED
   root = Path('.verification/recovery-20261026')
   with ZipFile(root / 'release-logs.zip', 'w', ZIP_DEFLATED) as z:
       z.write(root / 'release-job.log', 'verify.txt')
   PY
   python3 scripts/collect-verification-evidence.py .verification/recovery-20261026/release-logs.zip .verification/recovery-20261026/release-evidence
   ```

   El destino debe ser nuevo: si ya existe, inspeccionarlo, no sobrescribir. Guardar la huella verificada por el colector. Leer `.verification/release.json`, los20 pasos reales, los tres reportes `integration`, `integration-artifact`, `integration-rollback`, y staging. Exigir cero fallos, omisiones, reintentos o intermitencias en los perfiles obligatorios, e inclusión real de los dos nuevos casos de recuperación en cada perfil. No reconstruir un resultado por un conteo antiguo44/44. La suite completa ahora incluye casos nuevos. La prueba dirigida2/2 no sustituye esos perfiles.

3. Resolver el primer preflight de base fallido **antes de cualquier publicación**. El auxiliar `production-state.mjs` ya limita salidas a metadata, conteos y resultados; inspeccionar/añadir fases y conservar sólo diagnósticos saneados, nunca stderr con secretos. `productionPsql` usa la conexión configurada y validada del proyecto productivo, sólo lectura. No cambiar proyecto, credenciales ni puerto a modo de ensayo arbitrario. El fallo se produjo antes de contar la base; no se comprobó Auth/agenda en ese intento.

4. Con release y preflight aprobados, preparar la entrega concreta según `docs/architecture/publicacion-y-reversion.md` y los helpers existentes, adaptando **explícitamente** revisiones y recibos a esta entrega. No ejecutar el script histórico `deploy-and-rehearse-inactive-push-20261024.mjs`: lleva SHA/versiones fijos de otra entrega. El nuevo auxiliar `production-state.mjs` es sólo preflight/readback, no orquestador de publicación.

   - Respaldar/verificar una copia actual antes de publicar. La natural10:04 es evidencia real, pero no se la certificó fresca para una publicación posterior. El ejecutor privado existente puede hacer una copia normal; no repetir consentimiento, custodia, generación de claves ni restauración completa ya comprobada si formato/esquema no cambian. Una copia manual nueva no sustituye el evento natural.
   - Confirmar destinos/cuenta/versión/33 bindings,126 migraciones y entrada heredada apagada, artefactos íntegros y fuente exacta. Leer estado vigente: las muestras de este documento son un punto temporal.
   - Respetar la secuencia del plan de detener el programador y drenar antes de publicar, registrar confirmación y margen de propagación15min+20s. No se realizó todavía. No activar staging. Preparar reversión del despliegue y restauración de los cinco cron ante fallos.
   - Desplegar bytes del artefacto aprobado, sin build local ni nuevas migraciones; ensayar el compatible375 y retorno nativo a la nueva versión candidata efectivamente instalada. No usar la versión candidata de staging como si fuera una versión de producción.
   - Verificar marcador, archivos exactos, CSP, ausencia de exposición anónima, autenticación negativa/válida, agenda de la cuenta sintética existente y preservación de datos. `verify-production-release.mjs` y los módulos de `production-state.mjs` son auxiliares; ninguno sustituye la evidencia de correo recibido. Restaurar/confirmar cron y eventos según el plan. No repetir carga de capacidad.
   - Natalia no requiere redeploy si sus35 archivos siguen idénticos. No rotar secretos, reinstalar proveedores ni activar WhatsApp/cursos/noticias.

5. SMTP sigue dependiendo de una acción humana precisa, para dejar al final sin detener trabajos independientes: crear contraseña de aplicación dedicada deGoogle para `juampiluduena@gmail.com` y pegarla **directamente** en el campo protegido deSMTP deSupabase, siguiendo [la guía](../architecture/correo-de-recuperacion.md). No pedir el secreto por chat ni reutilizar OAuth deDrive/Auth/Calendar. No cambiar la contraseña de una cuenta real para probar. Falta la recepción y el recorrido real desde el correo en un buzón sintético controlado por el usuario. Sólo entonces marcar `realEmailDelivered`/`productionRecoveryVerified` verdaderos.

## Respaldos y límites que ya están acreditados

Ejecutor privado `Juan4787/cita-suite-respaldos`, fuente `742e5ded813a57ec769a4d846d43c984fcde2a46`; cuenta deDrive **juanmarquez56783@gmail.com**, distinta del remitente SMTP principal. Carpeta privada `122AAiXE1qX2FED6IFUkF33ZCswLQoVYK`. No leer JSON deAuth/Calendar para este trabajo.

- Copia natural40303961884, evento `schedule`,10:00:17–10:04:41UTC frente a04:07 previsto:5h53min17s de demora. Instantánea10:04:16.270Z,105 tablas/3930 filas/126 migraciones/24 objetos reutilizados/0 descargas deStorage; archivoDrive `1q9TSieH3rAMZKu1i05jy3kXasy5T1Rua`,415906B, cipherSHA`e55b1f0ad95cb3b78e569b60fa70e7ba042a8778e6b120613c0a8809c9973bcb`, manifiesto`5cae77c996c9a633e70050dc334b1834f670e95125e610c79d7ef4a1109deca1`. Descarga propia desdeDrive comprobada.
- Monitor natural40364212526, evento `schedule`,16:58:23UTC frente a10:43 previsto:6h15min23s de demora. Misma copia, edad6,9h, descarga/huella aprobadas y sin acceder a la base.
- Restauración completa previa40265535110 aprobada con105 tablas/3930 filas/126 migraciones/24 referencias,0 diferencias; corresponde a otra instantánea identificada en la guía. No afirmar que se restauró la copia natural nueva.
- Evidencias `.verification/backup-private-capacity-20261026/scheduled-first*` y `scheduled-monitor-first*`. `fullyCertifiedUnattendedBackups=false`: falta recepción de alertas y monitor independiente deGitHub; el cron puede retrasarse u omitirse. No prometer puntualidad ni aumentar presupuesto. US$0 bloqueado confirmado por el usuario; no contratar ni cambiar plan.
- Temporizador local anterior sí se disparó, pero Codex rechazó abrir la conversación por escritor activo; no hubo trabajo. Usuario descartó ese incidente; no reprogramarlo.

## Preservación y pendientes finales

Árbol muy modificado desde antes: **no reset, checkout, stash, add global ni commit indiscriminado**. Las fuentes se generaron con índice temporal y se empujaron sólo al auxiliar; no se cambió HEAD del usuario. Las evidencias `.verification/` y los accesos privados son locales/ignorados: no incorporarlos al repo público para transferir contexto.

- Rama local: `refactor/maintainability-20261015`.
- HEAD: `80268e2a501198243996e1bdb0048ce066434727`.
- SHA256 índice: `55cd8f7975542b806308d3e067f81660fe107ed1c5cdbed88962dbe614a1faba`.
- SHA256 lock: `98ce4b17589b2967edeadeda93566a8e79bf58f62316ca0033be506bdc9d1a65`.
- SHA256 plan: `5fef6e285db4984b226da976317ae9478991f55e922c8c786b6276c0464eaccc`.
- A17:59UTC, los nueve archivos de runtime/tests/arnés/plantilla listados en `handoff-state.json` coinciden exactamente conad5. La documentación se actualizó después de ese snapshot; no es otro binario ensayado.

La campaña **no está terminada**. Además del release/publicación/SMTP pendientes de esta entrega, permanecen dominio y verificación deGoogle, etiquetas deSupabase y limitaciones de alertas/capacidad documentadas. Mantener distinción entre unidades simuladas, Auth real descartable, staging desplegado y producción. Trabajos pesados siempre alojados y secuenciales; no subagentes ni navegadores/bases/builds pesados locales. El siguiente modelo debe registrar cada nueva decisión, fallo, corrección, SHA, corrida y ruta de evidencia, conservando los originales.
