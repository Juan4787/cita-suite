# Traspaso de la campaña de señas y avisos (consultorio de Natalia Frutos)

> **Nota del 2 de noviembre de 2026:** las instrucciones de este documento de preservar el `HEAD` `80268e2` y el índice `55cd8f79…` quedaron superadas. Esa regla dejó divergir la copia local de GitHub y de producción. Ahora la rama de trabajo es `main`, que contiene la historia completa. El estado vigente está en [el registro único](../ESTADO-VIGENTE.md) y se comprueba con `node scripts/check-repo-sync.mjs`.

<a id="etapa-e-punto"></a>

## Etapa E — ejecución íntegra autorizada, preparación del 3 de noviembre de 2026

**Revisión cerrada el 3 de noviembre (hora argentina); definición conversada el 2.** Después Juan pidió conectar Zoho por terminal y guardar todo para no perder acceso al reiniciar: [12.19](propuesta-senas-avisos-natalia.md#zoho-terminal-vigente). Conexión OAuth local, consultas y renovación reales comprobadas. Herramienta versionada y credenciales persistentes privadas; [guía de operación](../architecture/zoho-cpaas-terminal.md).

**Al retomar:** `python3 scripts/zoho-cpaas.py status` y `python3 scripts/zoho-cpaas.py agents`. No necesita terminal abierta; renueva al vencer usando el refresh token guardado. No imprimir el archivo de credenciales ni volver a pedirlas si funcionan. **Instrucción posterior:** Juan autorizó E completa, pruebas y publicación en [12.20](propuesta-senas-avisos-natalia.md#ejecucion-e-autorizada). Q01/Q02 resueltas: subdominio por consultorio, envíos activos por defecto y botones contextuales; continuar E1–E6 autónomamente. Punto al 4 de noviembre, E1.93: diecinueve migraciones aprobadas en SQL 41829516097 (43 carreras/dos contraejemplos FK, doce esperas y regresiones/limpieza), tipos oficiales/digest cotejados. Corrige la carrera 42 con deadlock real de 41828016563 y comprueba lotes de orden opuesto. Consumidores OAuth/auxiliares conservan fast 41827070902 (1852/281, cero errores/avisos) y browser ampliado 41827075064 sobre 7b2fd22; personal 41757455635 conserva su alcance. Recuperación TS posterior b269876 con 37/37 modeladas, fast posterior pendiente. Veinte aprobada en SQL 41842452349 (18 grupos de lease, 45 carreras/dos contraejemplos FK, doce esperas y regresiones/limpieza). Tipos oficiales/digest cotejados e importados. Consumidor común y retiro de revoke global con 65 dirigidas aprobadas; fast 41873691746 falló por un tipo de callback del arnés, corregido. Veintiuna escrita con 15 grupos/48 carreras sin ejecutar, consumidores/tipos pendientes (E1.93). Continuar SQL/tipos y consumidor inmediato/lote común, tracking/borrado/métricas/PDF por responsabilidad y retención OAuth SQL, luego distribución/contacto/cola/altas informadas y E3–E6. Fuente, evidencia e historia en el [registro activo](ejecucion-etapa-e-20261103.md). Ninguna migración E aplicada en producción, correo nuevo ni publicación; V12b sigue vigente.

- Leer el [plan 12.18](propuesta-senas-avisos-natalia.md#etapa-e-vigente), la [especificación de E](etapa-e-correo-autogestion.md), el [registro de revisión](registro-senas-avisos-natalia.md#etapa-e-revision) y los [pendientes](pendientes-vigentes.md#etapa-e-pendientes).
- **Cuenta Zoho ya existe:** Juan probó dos envíos, informó KYC pendiente y 100 emails gratuitos por día. Pagará al verificarse. No volver a preguntar por Resend ni exigir KYC para preparar las pruebas permitidas al iniciar; no asumir dominio, credenciales o recepción integral por ese informe.
- **Definición:** email requerido/desactivable, excepción con aviso para recepción, comprobantes y avisos 72/24 con botones opcionales y marca del consultorio, reprogramación autónoma, nueva seña y destino anterior configurables. Casos y correcciones sólo en la especificación, para evitar copias divergentes.
- **Cuidado al implementar:** conservar disponibilidad compartida y exclusión del propio turno; revisión semántica y transacción para horario/dinero/eventos; historia separada con proyección uno a uno; credencial revocable sin fugas de token legado; saldo limitado a información real y presupuesto de cron medido. La lectura no acredita pruebas de E.
- **P1/P2/P3 pospuestas por pedido posterior de Juan (12.26):** no iniciarlas al cerrar E; avisar y entregar su documentación detallada. D celular sigue reemplazada por la futura P3 interna. [Seguimiento separado](tareas-posteriores-a-e-20261103.md). Los datos comerciales faltantes de Natalia y su configuración real no se inventan ni se activan por esta tarea.
- **Producción:** V12b, sin cambios. Historial y recuperación actuales en [estado vigente](../ESTADO-VIGENTE.md) y [publicación/reversión](../architecture/publicacion-y-reversion.md), no en las versiones históricas de abajo.
- La autorización de ejecución y producción de E es expresa y vigente; no solicitar otra. Q01/Q02 ya están resueltas en 12.21/12.22; no hay otra espera de inicio. Los cierres se sostienen por evidencia por caso y revisión, no por un verde aislado.

## Historia — ayuda con duraciones desde el 1 de noviembre (V11, plan 12.17)

Pedido y definición aprobada, literales: sección 12.17 del plan. Registro: sección «Ayuda con duraciones, V11» de `registro-senas-avisos-natalia.md`. Evidencia: `.verification/ayuda-duraciones-20261101/` (carpeta 700, recibos 600, nunca se sobrescriben).

Fases, en este orden:
0. Registrar el pedido (plan 12.17, este traspaso, registro).
1. Pruebas que fallan primero: SQL `supabase/tests/account_assistance_durations.sql`, unitarias de la vista y de los textos, acciones del servidor (página de Ayuda y panel maestro), diálogo de confirmación y la prueba de navegador `apps/web/e2e/account-assistance.spec.ts`.
2. Migración `supabase/migrations/20261101030000_account_assistance_durations.sql` y código. Las funciones anteriores `activate_account_assistance(uuid, uuid)` y `revoke_account_assistance(uuid)` quedan intactas, para que V10b siga funcionando durante la publicación y en una recuperación.
3. Comprobaciones locales, siempre secuenciales.
4. Candidata V11 sobre V10b `68f31741f6ff7f2253c036800b1369f1eda16510`, con los dos programas de armado de CI ya corregidos (`archivos-proxima-version.txt` de 12.16). CI: `types` (tipos generados), `sql`, `fast`, `artifact` y `browser`.
5. Producción: ensayo de migraciones, copia, migración, publicación del Worker `app`, comprobaciones, certificado y puntero de la fuente.
6. Auditoría, documentación e informe final.

**Punto exacto (2 de noviembre, 02:15 UTC): V11f publicada y comprobada.**
- **Autorización y migración:** Juan respondió «subi». La migración `20261101030000` se aplicó en producción a las 02:10:26 UTC, en una transacción de 3 segundos; producción pasó de 130 a 131 migraciones (`aplicar-migraciones-produccion.log`).
- **Publicación:** el Worker `app` sirve la versión **`59f81e89-412f-49be-b65b-3a2378ddf71e`**, revisión `72d59ab00db67a8502ca560c762c61e6cfac1923` (`despliegue-v11f.log`). El paquete está en `release-candidate-v11f/cloudflare-staging-72d59ab…`: el programa recibe esa subcarpeta, no la superior.
- **Comprobaciones:** `verify-production-release.mjs` aprobado, con 140 archivos del cliente (`verificacion-produccion.log`). Los dos orígenes responden con la revisión 72d59ab.
- **Recuperación:** `wrangler rollback 1d2b4acd-7dd8-4cb7-81e3-a205bafe9f8d` vuelve a V10b sin tocar la base, porque las funciones de V10b siguen intactas.
- **Queda:**
  - certificar la fuente y mover `.verification/ci-source.json` a V11f;
  - pasar V11 como vigente en `publicacion-y-reversion.md`, `AGENTS.md` y el README.
- **Google:** Juan confirmó que la web ya está verificada por Google (`pendientes-vigentes.md`).

## Trabajo del 1 de noviembre — terminado a las 10:40 UTC

Autorización y alcance: sección 12.16 del plan (decisiones de Juan, literales). Registro: sección «1 de noviembre» al final de `registro-senas-avisos-natalia.md`, con las decisiones propias del agente y sus fundamentos. Evidencia: `.verification/natalia-configuracion-20261101/` (carpeta 700, recibos 600, nunca se sobrescriben).

Fases, en este orden:
0. Registrar las decisiones: plan 12.16, este traspaso, registro y `pendientes-vigentes.md`.
1. Lectura de producción, sólo lectura: estado actual del duplicado `1a00afa2-92ad-46cf-bc4a-cd6b58e4e4b0` (Juan lo archivó desde el panel después de las 21:37 UTC del 31 de octubre) y del consultorio real `c488f625-cb9a-41ec-8526-b7ec03c4646b`, integraciones de la web y direcciones IP que registra Auth.
2. Operación sobre los dos consultorios, como operador y en una transacción: duplicado «Duplicado archivado — no usar», dirección `duplicado-archivado`, invitación cancelada, correo habilitado retirado, reserva pública y WhatsApp apagados; consultorio real «Consultorio Natalia Frutos», dirección `natalia-frutos` y WhatsApp del 30 de octubre. Ensayo deshecho, aplicación y relectura.
3. Carga de la configuración de Natalia, como operador: profesional, prestaciones, horarios y modalidades provisorias, pregunta de obra social, textos e integración de su web. Ensayo deshecho, aplicación y comprobación en el turnero público.
4. Candidata V10 sobre V9: vista de archivados del panel maestro, rubro «medicina» y web de Natalia con dominio oficial, clave de su consultorio real, `robots.txt` y mapa del sitio. Pruebas que fallan primero, CI, paquete y navegador sobre el paquete exacto.
5. Publicación: V10 en el Worker `app`, rubro «medicina» del consultorio real y web de Natalia, con sus comprobaciones.
6. Pruebas marcadas en el consultorio real, búsqueda de agujeros y limpieza comprobada.
7. Documentación final y lista de pendientes.

**Estado final (10:40 UTC): las fases 0 a 7 están terminadas y comprobadas.** Detalle, con todos los recibos, en el registro, sección «1 de noviembre».
- **Producción** sirve V10b `68f31741f6ff7f2253c036800b1369f1eda16510`, versión de Cloudflare `1d2b4acd-7dd8-4cb7-81e3-a205bafe9f8d`, con 130 migraciones. El puntero de la fuente está en V10b.
- **Volver a V9** exige antes `revertir-para-v9.mjs` (`docs/architecture/publicacion-y-reversion.md`).
- **Consultorio real de Natalia:** configurado como describe el documento privado, sección 7, «Resultado». No tiene pacientes ni turnos: las pruebas se borraron y los conteos volvieron a la foto previa.
- **Duplicado:** archivado y renombrado.
- **Web de Natalia:** publicada; reserva en su consultorio real por el dominio oficial y pide no ser indexada.
- **Lo que queda:** `docs/plans/pendientes-vigentes.md`. Lo primero son los datos que faltan de Natalia, empezando por la dirección del consultorio.
- **Para la próxima candidata:** los dos programas de armado de CI corregidos (`archivos-proxima-version.txt`) ya están en el árbol de trabajo; el certificado de V10b los lista como excepción explícita.
- **Recuperación de la web:** volver a promover en Vercel `dpl_6zBnr7E2FVg11SQ5mHiHv8rdPPKk`, o un commit nuevo que sirva `rollback/`.
- **Repositorio:** HEAD `80268e2a501198243996e1bdb0048ce066434727` e índice `55cd8f79…` sin cambios. La cuenta activa de `gh` es Juan4787.

**El ensayo del 31 de octubre no se aplica:** `.verification/natalia-unificacion-20261031/unificar-archivando.mjs` corresponde a un estado anterior y a una decisión reemplazada (12.15 por 12.16).

## Trabajo anterior — 31 de octubre, desde las 21:30 UTC (cerrado; la fase 2 fue reemplazada por 12.16)

Autorización y alcance: sección 12.15 del plan. Registro: sección «31 de octubre» al final de `registro-senas-avisos-natalia.md`. Evidencia: `.verification/natalia-unificacion-20261031/`.

Fases aprobadas, en este orden:
1. Verificación de sólo lectura en producción: cuenta real de Natalia y su consultorio «Consultorio», consultorio preparado «Consultorio Natalia Frutos», destino de la web de Natalia y tareas programadas desde el cierre.
2. Unificación: conservar «Consultorio», trasladar sólo nombre, rubro, dirección pública y WhatsApp si conservan el valor del alta automática, y eliminar el preparado con su invitación y su correo habilitado. Ensayo deshecho primero, aplicación después, relectura independiente.
3. V9: registrar las fallas de Auth en la acción `confirm` de `/confirmar-correo`, con prueba que falla primero, candidata sobre V8, nivel `fast`, paquete `artifact` y publicación en el Worker `app`.
4. Documentación y lista única de pendientes en `docs/plans/pendientes-vigentes.md`.

**Punto exacto (22:01 UTC):** fases 1, 3 y 4 terminadas. **Fase 2 sin cambios en producción y a la espera de Juan:** la base prohíbe borrar el consultorio preparado (`access_grants is append-only`, `ensayo-borrado.json`); el archivado está preparado y ensayado (`unificar-archivando.mjs ensayo`, 15 de 15 controles, deshecho; relectura `despues-de-ensayos.json` idéntica a la inicial). Con la aprobación: desde la raíz, `node .verification/natalia-unificacion-20261031/unificar-archivando.mjs aplicar` y después `node .verification/natalia-unificacion-20261031/inspeccionar.mjs inspeccion-final`. V9 `a3c707f368736da90d2adf5850d291460f657af0` publicada (versión `2ef53723-0a46-4879-bf6e-4af5ed5320c9`), puntero de fuente en V9 y recuperación inmediata a V8 documentada. Todo lo pendiente: `docs/plans/pendientes-vigentes.md`.

## Continuidad vigente — 31 de octubre

**Checkpoint histórico:** las pausas y tareas de este apartado no son la continuación actual. Para E rigen 12.18 y el punto del 2 de noviembre al comienzo; producción y recuperación se consultan en el estado vigente.

Desde el 1 de noviembre a las 10:15 UTC producción sirve V10b `68f31741f6ff7f2253c036800b1369f1eda16510`, versión `1d2b4acd-7dd8-4cb7-81e3-a205bafe9f8d` (12.16; ver «Trabajo en curso — 1 de noviembre»). Del 31 de octubre a esa hora sirvió V9 `a3c707f368736da90d2adf5850d291460f657af0`, versión `2ef53723-0a46-4879-bf6e-4af5ed5320c9`. Antes, la entrega de confirmación de correo quedó **publicada y comprobada**, V8 `408ca04d9e6750e4657dc087264644665a63fb37`, versión productiva `a1844665-447e-40bb-b9e5-ce7c03ed29d7`. Consultar [el traspaso de cierre](traspaso-confirmacion-email-20261030.md): es la referencia de versión, recuperación compatible, evidencia y límites. No volver a publicar esta corrección ni usar como actuales las revisiones y próximos pasos de los apartados fechados inferiores.

Natalia/D/E siguen en pausa por el cambio de alcance del usuario; no modificar sus 12 meses de acceso. Rige el criterio contextual inicial de [AGENTS.md](../../AGENTS.md): auditoría rigurosa y producción autorizada, sin circuitos de staging, backups por antigüedad o reversión obligatorios para toda modificación. Se protegen cuentas, secretos, permisos, configuración comercial e infraestructura; los turnos/pacientes ficticios pueden alterarse para probar.

Los puntos siguientes conservan la historia y los pendientes de sus fechas. No permiten concluir que todas las dependencias generales de la campaña estén resueltas ni que sigan abiertas por no figurar su cierre aquí: consultar la guía específica y sus recibos antes de actuar.

**Fuente de verdad:** el [plan aprobado](propuesta-senas-avisos-natalia.md) completo, incluida su sección 12. El historial está en el [registro](registro-senas-avisos-natalia.md).

Después de cada compactación y antes de cada etapa:
1. Leer el plan completo.
2. Contrastarlo con este traspaso y con el registro.
3. No reconstruir el plan de memoria.

## Cambio posterior de alcance (30 de octubre)

El usuario dejó configuraciónNatalia/D en espera hasta que exista su cuenta; E ya estaba pospuesta. El acceso12meses lo asignóJuan y se conserva. No retomarD/E en la tarea actual: confirmación obligatoria deemail yUX, en `confirmacion-email-20261030.md` y su registro/traspaso específicos. Aplicación literal en12.14 del plan. A/B/C sigue cerrada; lo siguiente es histórico.

## Estado final del 30 de octubre (17:04 UTC)

**Campaña A/B/C publicada y verificada en producción. Cierre operativo aprobado; no queda trabajo técnico autorizado de esta entrega por ejecutar.** La configuración de Natalia y las etapas D/E siguen separadas. Leer el [cierre por requisito](cierre-senas-avisos-natalia.md) y el plan completo antes de abrir otro frente; no repetir migraciones, ensayos ni limpiezas históricas.

- **Comprobante final:** `.verification/senas-avisos-20261029/cierre-productivo.json`,17:04:43.972UTC,ok=true, SHA256 `a46d1fa83f16ba0363bb4c5e9a44c569e0b702fda353b195e8acff807d73fe39`. Su mapa incluye SHA de cada recibo leído. Verificador `close-campaign.py`: sin red ni escrituras productivas. Evidencia final preservada además en carpeta privada `~/.local/share/cita-suite/campaigns/senas-avisos-20261030T170443Z` y recibo `final-evidence-preserved.json`; no es otro respaldo de la base.
- **App:** `deb74b023431e4f173eed85d6651c5073ad44557` (C9), artefacto41081146798, versión `e5dddd3c-90e2-423c-8ce9-fc9ed4b9be15`,100%/32bindings/ambosorígenes. DB128/legacyoff. Bytes136/CSPpropia/74relacionesnoexpuestas/HTTPS/35Natalia exactos; no se tocaron Vercel/landing/DNS. Fuente durable: auxiliar `verify/senas-etapa-c-app-v9-20261030`; paquete privado `~/.local/share/cita-suite/releases/<SHA>`.
- **Recuperación B11:** `bf0fd1892b1adc769d93c8ac369c533ee80a58b7`, paquete41049721655, versión productiva ensayada `0fbe672e-607c-4358-b335-3b047642ff09`. Globaloff antes, tres estados propios y confirmar/deshacer reales por HTTP/SQL/auditoría; retorno nativo C9 y mismos controles. No volver a aac/95b sin controles de seña. Secuencia vigente en [publicación](publicacion-senas-avisos-natalia.md).
- **Limpieza e integridad final:** `production-owned-cleanup.json`0consultorios/0dueñas propios y todas sus filas porbusiness_id eliminadas. `production-core-close.json`,17:04:26: las mismas huellas completas sinexclusiones de21consultorios/122pacientes/108turnos que antes de migraciones. `production-state-close.json`: Auth negativa/válida y agenda de la cuenta configurada en ambosorígenes después de limpiar,32bindings/128/Calendar1/1 conservados.
- **Interruptores:** `production-features-close.json`,17:04:40: globaloff,0políticas/0señas/0huecos; dos trabajospg_cron exactos activos. Ocho ticks naturales16:25→17:00succeeded/0procesadas/0canceladas. Retención diaria sólo ensayada conrollback4929filas, sin afirmar tick natural. No se configuró Natalia.
- **Programador:** versión `16c73f28-eb48-4651-ac71-f2fd9f4087f9`,5cronproductivos/0staging/APP→app. `production-scheduler-observed-summary.json`: ocho eventos naturales16:51:46→17:03:31 de calendario/push/reseñas/cargas, todosok/sinexcepciones/versiónexacta. Mantenimiento cada3h configurado, no observado en esta ventana;20archivos scheduler/contrato/despacho/endpoints idénticos al baseline y11pruebasCI. Tail terminado y procesos propios ausentes; no queda un Wrangler/tarea de esta sesión pendiente.
- **Copia previa12641081864440:** snapshot15:37,105tablas/4272filas/24referencias, restaurada/descargada/descifrada, manifiesto `5e2d2acf53acf129ded955cf5f9500d7a26fca280bb63f812758a46d38a522d6`, privada `~/.local/share/cita-suite/backups/production-senas-20261030T154244Z`.
- **Copia posterior12841092046966:** snapshot16:44:47.284,110tablas/4295filas/24referencias(22contenidos), restaurada enCI sin diferencias/serviciosretirados, descarga y descifrado independientes, manifiesto `ef847fb3378d952e3e4d0e853556227a94760dbef3ceac1ec9c117e6987716b5`, privada `~/.local/share/cita-suite/backups/production-senas-20261030T164850Z`. Cinco tablas nuevas presentes/global1/resto0. Recibos `respaldo-productivo-posterior` y `production-post-backup-feature-tables.json`. No sobrescribir ni repetir los checkers.
- **Restaurar un destino nuevo128:** la copia privada genérica no reconstruyecron. Ejecutar `supabase/operations/recover-deposit-automation.sql`, globaloff primero, y comprobar dos trabajos/identidad antes de servirlo. Prueba no vacía staging41050555719:1política/1exclusión/3señas/1global/1hueco, dos ejecuciones idempotentes/identidadsegura/0diferencias. Los trabajos históricos restantes necesitan su propio procedimiento.
- **CI final:** release41082416537, fuenteC9,20/20fases;53browserfuente/53paqueteC9/49compatB11/demo3, sinomitidas/flaky/inesperados/reintentos; SQLB25/C15/diezcarreras/deadlocks0. Evidencia821, SHA `9c4b10613f754aa1f45416126ca13c1687054d8da58ff2b7fd5774ae9ccc28e1`. DiagnósticoextraB11compilada41086383561:3/3A/B/zona en esquema127, separado de compat128. Ver registro para cada roja/falla/corrección y límites de Realtime/transporteC8.
- **Configuración enlazada leída:** `production-natalia-linked-configuration.json`,16:54, integraciónúnicaactiva/unprofesional, obraSocial/plan mapeados. WhatsAppcontactoapagado/sinnúmero y políticaoff. No inferir propiedad del consultorio por el enlace. Faltan datos y decisiones de la clienta; no activar ni inventar. D/E siguen en pausa y no se contrató nada.
- **Repositorio:** HEAD `80268e2a501198243996e1bdb0048ce066434727` e índiceSHA256 `55cd8f7975542b806308d3e067f81660fe107ed1c5cdbed88962dbe614a1faba` conservados. El índice/árbol sucios son previos; no usar add-A/reset/clean. Main principal4352f8 antiguo no fue sobrescrito. `.verification/ci-source.json` apunta a C9 y el puntero anterior95b está conservado. Los documentos de cierre locales son posteriores al paquete; no fingir que integran el commit compilado ni publicar la información privada de la clienta en el auxiliar público.

**Continuación futura:** obtener/resolver únicamente la configuración que corresponde a la clienta o una nueva etapa expresamente encargada. La autorización12.8 sigue cubriendo las operaciones necesarias de esta campaña, sin otra pregunta de permiso; no habilita inventar esas decisiones ni iniciarD/E. Este cierre no declara resueltos otros pendientes anteriores de lanzamiento/Google/correo ni acredita Realtime alojado o entrega deWhatsApp.

## Antecedente del 30 de octubre (16:56 UTC)

**A/B/C están en producción C9 y DB128. Recuperación B11→retorno nativo C9, acciones propias, limpieza e integridad aprobadas. Cinco crons restaurados. La copia posterior ya está recuperada; falta la última categoría frecuente del programador y completar el cierre documental.** El [cierre por requisito](cierre-senas-avisos-natalia.md) ya tiene el contraste del plan, con los pendientes operativos explícitos. No ejecutar otra vez migraciones, semilla, pruebas de las filas ya borradas ni despliegues por leer instrucciones históricas.

- App C9 `deb74b023431e4f173eed85d6651c5073ad44557`, versión `e5dddd3c-90e2-423c-8ce9-fc9ed4b9be15`, paquete41081146798. Retorno nativo y136archivos/CSP/74noexpuestas/35Natalia/HTTPS aprobados; `production-c9-readback.json` confirma32bindings/ambosorígenes/128/legacyoff/Auth/agenda/conteos. Recuperación B11 `bf0fd1892b1adc769d93c8ac369c533ee80a58b7`, paquete41049721655, versión ensayada0fbe672e.
- Acciones de seña propias por HTTP y SQL aprobadas con B11 y C9, auditorías1/1→2/2; tres estados preservados. C propio adicional: `production-owned-slot.json` falló por predicado de arnés snake_case, sin mutación; `production-owned-slot-v2.json` confirma sobre el mismo DTO falso anterior/verdadero camelCase, luego ocultación real, retiro y auditoría1. No se cambió producto.
- **Limpieza16:40:08 aprobada** `production-owned-cleanup.json`,0consultorios/0dueñas y todas las tablas public/private conbusiness_id recorridas. `production-core-after.json`: SHA completos de21consultorios/122pacientes/108turnos idénticos al antes, sin exclusiones. `production-features-final.json`:128/globaloff/0políticas/0señas/0huecos, dos trabajos exactos activos; cuatro ticks naturales16:25–16:40succeeded/0procesadas/0canceladas. No usar otra vez el correo propio eliminado.
- **Scheduler restaurado** versión `16c73f28-eb48-4651-ac71-f2fd9f4087f9`,5cronproductivos/0staging/APP→app; recibo `production-scheduler-restored.json`, log `production-restore-scheduler.log`. C9/32bindings/128/conteos y Calendar1/1 conservados. **Tail saneado activo** sesión88715, proceso padre1461775, hijoWrangler; `observe-scheduler.mjs`, salida `production-scheduler-observed.jsonl`. Un Wrangler; no desplegar ni ejecutar lectores que invocan Wrangler mientras siga activo. Al terminar Ctrl-C a esa sesión y conservar resumen; no iniciar un segundo tail. A16:55 ya entraron calendario/reseñas/push, todosok/sinexcepciones/versión16c73f28; falta uploads natural17:03UTC. Cuatro categorías frecuentes deben tener eventos reales ok/sin excepciones; mantenimiento17cada3h no se llama observado por estar configurado. Código scheduler/contrato/endpoints internos sin diferencias contraaac (git diff vacío), pruebas11verdes.
- **Copia posterior12841092046966 aprobada/restaurada/descargada/descifrada**, trabajo124188164340, ejecutor privado742e5de/mode=rehearsal, snapshot16:44:47.284UTC posterior a limpieza:110tablas/4295filas/128migraciones/24referencias(22contenidos),0diferencias/serviciosretirados. Recibos `respaldo-productivo-posterior`; `production-post-backup-feature-tables.json` verifica cinco tablas nuevas/global1/resto0. Privada `~/.local/share/cita-suite/backups/production-senas-20261030T164850Z`, manifiesto `ef847fb3378d952e3e4d0e853556227a94760dbef3ceac1ec9c117e6987716b5`. No repetir checkers ni sobrescribir recibos. Restauración privada genérica no reconstruye cron: operación versionada obligatoria al recuperar destino nuevo, probada en staging41050555719 con filas no vacías.
- Copia previa elegida41081864440/instantánea15:37, restaurada+descargada+descifrada: `~/.local/share/cita-suite/backups/production-senas-20261030T154244Z`, manifiesto5e2d2acf…a522d6. Paquetes C9/B11 fuera de retención en `~/.local/share/cita-suite/releases/<SHA>`. Release41082416537 aprobado20/20; evidencia821/SHA9c4b1061…c28e1. Todos los detalles exactos en registro/cierre.
- Autoridad12.8 vigente, sin otra pregunta de permiso. Global/señas/autocancelación quedan apagados; no configurar Natalia ni iniciar D/E/contratar. HEAD80268e2/índice55cd8f79 intactos. CI pesado solamente. Auxiliar público: no publicar por accidente la información literal de la clienta ni volcados/recibos privados. Main antiguo no se sobrescribe.

**Siguiente:** esperar uploads natural17:03UTC, detener tail, capturar `production-readback.mjs production-state-close <C9SHA> 128 production-scheduler-restored` (nueva lectura Auth/agenda después de limpiar; cuenta configurada disponible, última lectura anterior16:34), `core-integrity.mjs production-core-close production-core-before` y `feature-state.mjs production-features-close`; ejecutar `python3 -I .verification/senas-avisos-20261029/close-campaign.py`. Revisa exactamente todos los recibos y cuatro categorías naturales, no altera datos. Actualizar cierre/registro/traspaso/publicación/respaldo con los resultados. Lectura productiva16:54 de destino enlazadoNatalia confirmaobraSocial/plan mapeados, WhatsApp desactivado/sinnúmero/políticaoff; sólo configuración, sin escrituras ni inferir propiedad del consultorio. No cerrar por una preparación ni ampliar a otras campañas o decisiones comerciales.

## Antecedente del 30 de octubre (16:28 UTC)

**ProducciónDB128 y C9 instaladas/verificadas. Ensayo B11 productivo iniciado, con3señas propias/globaloff; schedulerCF sigue0cron. Falta retorno C9, comprobaciones/limpieza y reactivar/observar.** Leer plan íntegro y registro después de compactar; esta sección prevalece.

- **Punto inmediato:** C9 productiva **`e5dddd3c-90e2-423c-8ce9-fc9ed4b9be15`**, fuente `deb74b023431e4f173eed85d6651c5073ad44557`,136clientefiles/35Natalia exactos/CSPpropia/74relacionesnoexpuestas/32bindings/ambosorígenes/HTTPS verificados. `production-c9-installed.json`, `production-verify-c9-first.log`. DB128aplicada16:22despuésdeldrenaje; globaloff/0filasretroactivas en `production-features-installed.json`.
- **Fixture productiva propia sembrada** (`production-owned-seed.json`),3señas(paid/pending/waived),1hueco,política40mil/autocanceloff/globaloff. **NuncaJuan/Natalia**, sin mensajes/documentos/proveedores. Recibo antes de reversión `production-before-recovery.json`:22consultorios/123pacientes/112turnos (incluyepropiob1/p1/a4),Calendar1/1. **B11deployen curso** `production-deploy-b11.log` (consultarlog/estado, no repetir). Al completar: verificarbytesB11, ejecutar `production-owned-deposit.mjs check bf0fd1892b1adc769d93c8ac369c533ee80a58b7` (HTTPauthreal), y `production-readback.mjs production-b11-readback <B11SHA> 128 production-before-recovery`. Después volver **nativamente** a e5dddd3c C9, no a un IDantiguo.
- **OFF comprobado antes de B11** `production-features-before-recovery.json`,16:27:58UTC. PGexpiry natural16:25succeeded/0procesadas/0canceladas; ambosjobs exactosactivos. No confundir cronsPG conCF: CF0 duranteensayo.
- **Integridad completa antes de migraciones** `production-core-before.json`:21consultorios/122pacientes/108turnos y SHA de todas sus filas sinexclusiones, capturada16:21:40confixtureausente. Después de limpieza debeigualarSHAyconteos con `core-integrity.mjs production-core-after production-core-before`. No limitarse a conteos.
- **Gate/preapply** `production-preapply-gate.json`,16:21:33posterioral margen16:21:07: copia15:37 rehasheada5SQL/24objetos/0derivaCF/DB126antes. Migraciones16:22:13→16:22:17,126→128; hashesB/C coinciden. Scheduler detenido versión7af0c71c-7681-457e-99e2-9762f53e5a26,APP→app,0ambosschedulers. `.verification/ci-source.json` yaC9, puntero95b preservado.
- **Release41082416537 aprobado**, trabajo124154701490,runb0b8458d-5e0b-402f-8144-bfddbab692cd,20/20;53browserdev/53paqueteC9/49compatB11/demo3,sinomisiones/flaky/inesperados. Evidencia821 `release-c9-evidence`,SHA `9c4b10613f754aa1f45416126ca13c1687054d8da58ff2b7fd5774ae9ccc28e1`. **DiagnósticoB11extra41086383561:3/3**(timezone/señas/WhatsApp) sobreSQL127, noatribuir128; evidencia66 `b11-funciones-previas-evidence`,SHA `1d867d21f6070090cdaf612eaaed3b04c028127ddafed94632c9b6d2ab92a1b7`. Compat128por49casos+UIalojadaB11.



- Autorización anticipada12.8 vigente: publicar/escribir/probar lo necesario sin otra consulta. Conservar CI/release/staging/copia/recuperación/reversión/destino. No contratar ni inventar configuración de Natalia. Final global/señas/autocancelación apagados; D/E en pausa.
- Preservar HEAD `80268e2a501198243996e1bdb0048ce066434727` e índiceSHA `55cd8f7975542b806308d3e067f81660fe107ed1c5cdbed88962dbe614a1faba`. No compilar app, navegador o base local; sólo unitarias puntuales secuenciales y operaciones remotas ligeras. Un Wrangler activo; no desplegar mientras un tail esté activo. CI auxiliar una activa y máximo una pendiente.
- A full40966735724; B full41014366957 (`bdd8eef1a825935d0db841cd715486cc1b7d9acc`); C full6 **41047577448** (`1da731a28d98a9d01b5e79b4f89497068e7564b2`): tipos0/0,Node162,scheduler11,server1579,client246,Office1,SQL C15/B25+10carreras/deadlocks0,browser51/demo3,9matrices×5anchos/layoutIssues0. Evidencia304 `etapa-c-full-v6-evidence`, paquete `6a2a75456a106048ed149e63152ce5f72fc70bca23f034f03bb5b5eb3feeadf6`; `cierre-etapa-c-ci.json`. No confundir con publicación.
- Staging128 por41049660527. **Restauración12841050555719 aprobada**:101tablas/520filas, nuevas filas1política/1exclusión/3señas/1global/1hueco,2jobs reconstruidos idempotentemente/globaloff/identidadsegura,0diferencias/archivo2368Brestauradoyretirado. `staging-backup-rehearsal-c7/backup-rehearsal.json`. Operación versionada `supabase/operations/recover-deposit-automation.sql` recupera sólo esos2jobs en destino restaurado; no afirmar recuperación automática de otros históricos.
- **B11 recuperación compatible12.11:** `bf0fd1892b1adc769d93c8ac369c533ee80a58b7`, artefacto41049721655 en `release-recuperacion-b11` y copia privada `~/.local/share/cita-suite/releases/<SHA>`. Mantiene resolver señas. Globaloff **antes** de instalar. UI alojada41051381337 aprobó tres estados, confirmar/deshacer reales y SQL/auditoría; rollback alojado41051461112 aprobó136cliente/35Natalia/CSPstaging/65noexpuestas/HTTPS/reservas desktopmobile recuperadas y canceladas. Evidencia7/paquete `eb88fc7a892d46a6e7509e21f7ffaf723c7384c7fe3d2d9c4ffc5211549f11b3`.
- C8 UI alojada41051835546 aprobó mismo recorrido. **pg_cron natural staging12:05UTC**:1seña/1turno cancelados,1auditoría/1hueco `deposit_expired`,sin invocaciónmanual (`staging-natural-expiry-passed.json`). Globaloff confirmado12:06 y **fixturepropia limpiada12:09**,0consultorios/0dueñas (`staging-deposit-cleanup.json`). No volver a correr check esperando esos datos eliminados. Fixture permanente separada de release sigue intacta.
- **C8 release41051917975 falló**, trabajo124050042438: sourcebrowser51/demo3/SQL/unidades aprobados; paquete compilado falló después39casos en control de consola de roles:1aviso cancelado/0cierresobservados. Luego transporte de evidencia falló37.139.979Braw/28.658.235Bgzip >24MiB. Sólo logs recuperados, **no imágenes/reportes de esa corrida**; `release-c8-diagnostics.log`/ZIP. No declarar release ni rollback posterior ejecutados.
- **Roja causal sin app41054527935** (`9de47e1e32ab3bbe17cd7527d9c23dd8981b8e28`), trabajo124058604261: cerrar socket nativo en documento ya cargado no se observa porque sólo había `addInitScript`;1falla/2controlespreviosverdes. Evidencia14 `sonda-documento-roja-evidence`,SHA `9383f812df49c70f1ab010093dfb9d899e2fa617e2bce6512712b7bde45d208d`.
- **C9 candidata actual `deb74b023431e4f173eed85d6651c5073ad44557`**, rama `verify/senas-etapa-c-app-v9-20261030`, **artefacto41081146798 aprobado** (created15:29UTC),222archivos en `release-c9` y copia privada `~/.local/share/cita-suite/releases/<SHA>`. 7archivos de arnés/docs sobre C8, **ningún cambio funcional de apps/tipos/migraciones**. Lista `candidata-c-v9-archivos.txt`. Sonda actual+futura idempotente; wizardobservadodesdeantesdelingreso;4controles nativos/forjados y conteoexacto1. Transporte48MiBcomprimido/128ZIP/96miembro, mantiene48raw/2000/rutas/SHA/redacción/nooverwrite. Roja25MiBincompresible y4pruebas Python verdes (`evidencia-transporte-verde.txt`), tipose2everdes.
- **Diagnóstico del binario C9 `41081605917` aprobado**, trabajo124151903948: `browser_grep=render health socket evidence|crea rol profesional pendiente`, artifact_run41081146798. Recuperar evidencia; exige5casos. **Release completo C9 `41082416537` aprobado**, trabajo124154701490, artifact41081146798/rollback41049721655; evidencia y cierre arriba.
- **Staging sirve C9** versión `1334e55b-682d-45d7-b214-19530ce2a08b`, globalsapagados/fixturepropiaeliminada. Natalia35archivos idénticos C7/C8/C9, ya instalada d9d2a36a: no volver a desplegarla. Certificado `ci-source-c9.json`:1194archivos/10.120.972B/tree `ab0d664a0eac402ef5b00753aa5e4480e3f7fac6`/digest `f788a13368b2a4fa835edfb9baac85cc6ecf0677eb19002c72513d1f858e75ff`; runtime/scripts/migraciones locales idénticos a C9. Antes del deploy scheduler copiar el puntero actual95b a archivo propio y seleccionar este manifiesto en `.verification/ci-source.json`.
- **Producción preflight fresco15:33:56** `production-prewindow-readonly.json`: app4e29aba6/aac/32bindings, schedulerba7b746d,5cronCF/staging0,DB126/legacyoff; sin deriva respecto a metadatos anteriores. Auth/agenda de cuenta configurada ambosorígenes aprobada11:51 (`production-auth-before.json`). Máximo2readbacks/15min (2loginscadauno); propiafixtureusaotromail.
- **DDLproductivo ensayado y revertido**12:06:48,0fallas/0diferenciascatálogo versusstaging; lectura independiente12:07 confirma126/sinB/C/0jobsnuevos (`production-migration-rehearsal.json`, `production-after-rehearsal-readonly.json`). No hay cambios productivos persistidos.
- Copia productiva126 **41050465153 aprobada/restaurada/descargadaydescifrada** snapshot11:49,105tablas/4246filas/24objetos,manifiesto `a75720d8594f18b744d2276216529b888490592a2d914143bb95da5f7f8b8bd5`. Privada `/home/usuario/.local/share/cita-suite/backups/production-senas-pre-20261030T115438Z`; recibos `respaldo-productivo-previo`. **Renovación comprobada41081864440 aprobada**, fuente742e5de/snapshot15:37:23.655UTC/105tablas/4272filas/126migraciones/24objetos. SQL/Storage restaurados/0diferencias/serviciosretirados; descargada y descifrada independientemente en **`/home/usuario/.local/share/cita-suite/backups/production-senas-20261030T154244Z`**. ManifiestoSHA `5e2d2acf53acf129ded955cf5f9500d7a26fca280bb63f812758a46d38a522d6`. Recibos `respaldo-productivo-previo-fresco`. Usar esta copia15:37 al aplicar migraciones; no volver a ejecutar el checker sobre nombres existentes ni dar por nueva la de11:49.
- Herramientas operativas preparadas en `.verification/senas-avisos-20261029/`: `production-state.mjs`, `production-readback.mjs` (nombre/SHA/migraciones/beforeopcional), **`production-owned-deposit.mjs` todavía sin ejecutar** (semilla/checkHTTP/cleanup únicamente propia,privado/UUIDsdistintos), `feature-state.mjs` (128/globaloff/jobs exactos/montosconteos), `observe-scheduler.mjs` (tail saneado,sinlogscrudos). Revisar antes de usar. No hay navegador local en estos scripts; HTTP real/SQLremoto. No tocar main4352f8 (25oct) a ciegas ni sobrescribir cambios: fuenteprobada está en auxiliar.

**Continuar:** diagnósticoC9→releaseexacto; conservar evidenciacompleta. Con respaldo fresco recuperado, seleccionar manifiestoC9, detener schedulerCF, comprobar0cron enambos y esperar15min20s desdeconfirmaciónconservadora. Aplicar2migraciones como una transacción con backupseleccionado, verificar128/globaloff y0filasretroactivas. Publicar C9precompilado; ensayar B11 con señaspresentes enfixtureproductivapropia y globaloffprimero, retorno nativoC9, bytes/CSP/permisos/ambosorígenes/Auth/agenda/conteos, limpiezapropiacomprobada. Restablecer5cron y observar eventos reales; PGexpirydebeejecutarseconglobaloffsin cancelar. MantenerseparadosCI/staging/producción/manual/natural. Documentarversiónexactayreversión. No cerrar por parciales ni pedirpermisoyaotorgado.

### Verificado en CI (histórico, 30 de octubre a las 06:00 UTC)
- **Etapa A:** candidata v2 `75d6f33c5d9593418296a1bd92fe1dca6bba694b`, completa `40966735724` aprobada.
- **Etapa B, base de datos:** última corrida `41003356303` (nivel `sql`), aprobada, candidata `a50fc5e37ffb7a71208f894897c6f41d4e8dd7e6` sobre `9747bab`.
  - La candidata lleva tres archivos: la migración `supabase/migrations/20261029010000_appointment_deposits.sql`, la suite `supabase/tests/appointment_deposits.sql` (24 comprobaciones) y el guion `supabase/tests/run_deposit_expiry_concurrency.sh` (8 escenarios).
  - Resultado: suite 24 de 24, carreras 8 de 8, bloqueos mutuos 0 y todas las demás suites aprobadas.
  - Las corridas anteriores, con sus fallas y causas, están en la tabla del registro.
- **Tipos de la base:** `packages/shared/src/database.types.ts` regenerado desde la evidencia de `41003356303`, SHA `cf70ada1de3fd4edca64eb0a851d95088e69a03c9592c3506c620d0e16a9be09`. Quedaron comprobados el resumen de migraciones, la relación uno a uno entre turno y seña y el parámetro `p_reopen`. Copia de la evidencia: `.verification/senas-avisos-20261029/tipos-generados-v10.json`.

### Hecho sólo localmente al 30 de octubre a las 06:00 UTC (histórico: todo quedó en C9 y en V8)
Las pruebas se corrieron de a un archivo, en secuencia; la cantidad es la del último resultado.

| Archivo (bajo `apps/web/src/`) | Qué hace | Pruebas locales |
|---|---|---|
| `lib/scheduling/deposits.ts` | contratos, clasificación (excluye turnos ya empezados), mensajes, aviso previo a reservar, secciones, tiempo transcurrido, aviso del registro de ejecución | `deposits.test.ts`: 21 |
| `lib/server/scheduling/public/deposits.ts` | operaciones: registro, apertura con `reopen`, política, condiciones por horario, lista (filtra turnos ya empezados), `loadDepositPolicyEnabled` | `deposits.test.ts`: 18 |
| `lib/server/scheduling/public/practice-whatsapp.ts` | avisos de la página del turno; regla única `buildTurnWhatsAppNotices` | 17 |
| `lib/server/scheduling/public/public-appointments.ts` | seña en la vista pública, protección uno a uno en compilación, `loadRebookUrl` | `public-appointments.test.ts`: 18 |
| `lib/server/scheduling/public/appointments.ts` | la reprogramación conserva Confirmado con la seña resuelta | 24 (`etapa-b-reprogramacion.txt`) |
| `routes/turno/[token]/+page.server.ts` y `+page.svelte` | bloque de la seña, seña recibida, turno cancelado por la seña con WhatsApp y «Reservar otro turno» | `page.client.test.ts`: 49 |
| `lib/server/scheduling/public/public-booking-page.ts`, `lib/booking/PublicBookingFlow.svelte`, `lib/booking/PublicBookingConfirmation.svelte`, `lib/scheduling/booking-view.ts` | condiciones de la seña por horario y aviso en el resumen antes de «Confirmar reserva» (ajuste 4) | `PublicBookingFlow.client.test.ts`: 10. **Falta** una prueba del servidor de la carga (`public-booking-page.ts`). |
| `routes/odonto/+layout.server.ts` y `+layout.svelte` | «Señas» en el menú diario y en Configuración, con aviso si no se pudo comprobar | `layout-notices.server.test.ts`: 7 |
| `routes/odonto/agenda/+page.server.ts` y `+page.svelte`, `lib/components/agenda/ManualAppointmentWizard.svelte` | parámetro `hora` y propiedad `initialValues` para «Volver a dar este horario»; si la hora ya no está libre, vuelve a los horarios con aviso | `agenda-day.server.test.ts`: 9; `page.client.test.ts` de la agenda: 1; `ManualAppointmentWizard.client.test.ts`: 8 |

### A medio hacer el 30 de octubre a las 06:00 UTC (histórico: terminado y publicado en C9)
- Página «Señas» **terminada localmente**, todavía sin CI:
  - `routes/odonto/senas/+page.server.ts` (`senas.server.test.ts`: 13);
  - `routes/odonto/senas/abrir/[appointmentId]/+server.ts` (`abrir.server.test.ts`: 9);
  - `routes/odonto/senas/+page.svelte` (`page.client.test.ts`: 10).
- Configuración, Señas **terminada localmente**, todavía sin CI:
  - `routes/odonto/configuracion/senas/+page.server.ts` (`senas-config.server.test.ts`: 9);
  - `lib/server/scheduling/public/deposit-policy-form.ts` (`deposit-policy-form.test.ts`: 8);
  - `routes/odonto/configuracion/senas/+page.svelte` (`page.client.test.ts`: 8).
- Detalle del turno **terminado localmente**, todavía sin CI:
  - `routes/odonto/turnos/[appointmentId]/+page.server.ts`: la seña, si se cancela sola (desconocido se informa como desconocido), quién la registra y la acción `deposit`. `appointment-detail.server.test.ts`: 12.
  - `+page.svelte`: el panel con «Confirmar seña», «Exceptuar» y «Deshacer», la etiqueta «Reservado, seña pendiente» o «Confirmado, seña recibida» y los textos de la historia. `page.client.test.ts`: 21. `reschedule.server.test.ts`: 3, sin cambios.
- Agenda **terminada localmente**, todavía sin CI:
  - `routes/odonto/agenda/+page.server.ts`: estado de la seña de cada turno y alertas en paralelo (`summarizeDepositAlerts` en `lib/server/scheduling/public/deposits.ts`). `agenda-day.server.test.ts`: 11.
  - `+page.svelte`: «Reservado, seña pendiente» en amarillo, «Confirmado, seña recibida» y la línea de alertas con enlace. `page.client.test.ts` de la agenda: 4.
- `lib/server/scheduling/public/public-booking-page.test.ts`: 4 (condiciones por horario con la cotización cruda, falla que no corta la reserva, sin día, sin cotización).
- **Candidata de la aplicación v1:** `4fe48da308730d6b50f127b657226e0881caa752`, sobre `a50fc5e`, rama `verify/senas-etapa-b-app-v1-20261030`. Lleva los 49 archivos de `.verification/senas-avisos-20261029/candidata-b-archivos.txt`, todo lo local menos `supabase/templates/recovery.html`.
  - **En curso:** nivel `fast`, corrida `41006783127` (tipos de las dos aplicaciones y de las pruebas de navegador, fronteras, guardas y pruebas unitarias).
- **Lo próximo a escribir, mientras corre:** las pruebas de navegador `@candidate-behavior` (punto 6 de la lista de abajo).

### Siguiente, en este orden, al 30 de octubre a las 06:00 UTC (histórico)
1. ~~Página Svelte de «Señas» y sus pruebas~~ (hecho, ver arriba).
2. ~~Configuración, Señas~~ (hecho, ver arriba).
3. ~~Detalle del turno~~ (hecho, ver arriba). `business.deposit_policy_saved` no aparece en la historia del turno porque es del consultorio.
4. ~~Agenda~~ (hecho, ver arriba).
5. ~~Prueba del servidor de `public-booking-page.ts`~~ (hecho).
6. Modo demo de las páginas nuevas, pruebas de navegador `@candidate-behavior` con su matriz de diseño, y mutaciones de las pruebas escritas después del código.
7. Candidata con todo lo local más los tres archivos SQL, en nivel `fast` y después `full`; registrar cada corrida.
8. Documentación: matriz de regresiones, matriz de permisos, contratos funcionales y textos de la historia.
- **Después:** la etapa C (horarios liberados, que reutiliza `initialValues` y `hora` de la agenda). Las tres etapas se publican juntas, con la seña y la cancelación automática apagadas.

### Cómo retomar (comandos exactos)
- **Pruebas locales**, una por vez, desde `apps/web`:
  - servidor: `NODE_OPTIONS=--max-old-space-size=640 pnpm exec vitest run <archivo>`;
  - componentes: `NODE_OPTIONS=--max-old-space-size=768 pnpm exec vitest run --config vitest.client.config.ts <archivo>`.
- **Armar una candidata** desde la raíz del repositorio: `c=$(bash .verification/senas-avisos-20261029/build.sh <base> "<mensaje>" <archivos...>)`, y comprobar `[[ "$c" =~ ^[0-9a-f]{40}$ ]]` antes de subirla.
- **Subir y lanzar:** `git push github-secundaria:Juan4787/cita-suite-verificacion.git "$c:refs/heads/verify/<rama>"` y después `gh workflow run refactoring-verification.yml -R Juan4787/cita-suite-verificacion --ref verify/<rama> -f level=<nivel>`.
- **Leer una corrida:** `gh api repos/Juan4787/cita-suite-verificacion/actions/jobs/<trabajo>/logs`. Si falla el guion de carreras, la trampa de errores imprime la línea y los registros de cada conexión.
- **Regenerar tipos después de cambiar la migración:**
  1. descargar el ZIP con `gh api repos/Juan4787/cita-suite-verificacion/actions/runs/<corrida>/logs`;
  2. recuperar la evidencia con `python3 -I scripts/collect-verification-evidence.py <zip> <carpeta nueva>`;
  3. verificar el SHA y el resumen de migraciones, y recién entonces escribir `source` en `packages/shared/src/database.types.ts` (procedimiento completo en el registro, corridas v8 a v10).

<a id="reglas-vigentes"></a>

## Reglas históricas del 30 de octubre

Las reglas de HEAD/índice y las pausas siguientes no se aplican como instrucciones actuales: prevalecen AGENTS, el estado vigente y el punto de continuación del 2 de noviembre.

- **Repositorio local:**
  - no tocar el HEAD (`80268e2`) ni el índice (`55cd8f79…`);
  - armar las candidatas con `bash .verification/senas-avisos-20261029/build.sh <base> <mensaje> <archivos>` y validar que el resultado sea un SHA de 40 caracteres antes de subirlo (incidente del registro: una subida con origen vacío borra una rama remota);
  - subirlas sólo al repositorio auxiliar `Juan4787/cita-suite-verificacion`.
- **Verificación:**
  - nada pesado en la máquina local: sólo pruebas unitarias puntuales, en secuencia;
  - suites, compilaciones, SQL y navegador corren en CI.
- **Producción:**
  - la autorización anticipada posterior está en la sección vigente y en 12.8 del plan; sustituye la espera de otro permiso;
  - el consultorio real de Juan nunca se usa para pruebas.
- **Ajustes al plan:** cada ajuste va como subsección nueva de la sección 12, con su motivo y las secciones que reemplaza.

<a id="pendientes-de-otros"></a>

## Pendientes históricos de otros al 30 de octubre

No usar esta lista histórica para volver a pedir cuenta/proveedor. La lista actual es pendientes vigentes, sección 3; Zoho ya tiene conexión administrativa local y E tiene ejecución autorizada; seguir el registro activo del 3 de noviembre, no estas pausas históricas.

- **De Natalia:** las preguntas de la sección 5 de su información (documento privado `docs/clientes/natalia-frutos/informacion-20261029.md`, sólo en la computadora de trabajo).
- **De Juan:**
  - las decisiones de la sección 4 de esa información;
  - lectura y escrituras necesarias en producción autorizadas por 12.8; las decisiones de configuración que faltan no se inventan;
  - las etapas D y E, que siguen en pausa.
