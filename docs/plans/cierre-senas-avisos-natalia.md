# Cierre verificable de A/B/C: señas y horarios liberados

> **Nota del 2 de noviembre de 2026:** las instrucciones de este documento de preservar el `HEAD` `80268e2` y el índice `55cd8f79…` quedaron superadas. Esa regla dejó divergir la copia local de GitHub y de producción. Ahora la rama de trabajo es `main`, que contiene la historia completa. El estado vigente está en [el registro único](../ESTADO-VIGENTE.md) y se comprueba con `node scripts/check-repo-sync.mjs`.

**Alcance histórico de este documento:** conserva la entrega A/B/C del 30 de octubre. La versión productiva y la recuperación actuales están en [el cierre de confirmación del 31 de octubre](traspaso-confirmacion-email-20261030.md). No instalar C9/B11 desde estos comandos: no conservan el flujo de correo publicado después. El criterio contextual de [AGENTS.md](../../AGENTS.md) sustituye las obligaciones históricas automáticas de staging, backup por horas, hashes de turnos ficticios y ensayos de reversión. La configuración de Natalia y D/E siguen en pausa.

30 de octubre de 2026. **A/B/C publicadas y verificadas; cierre operativo aprobado a17:04:43UTC.** La seña y la cancelación automática quedan apagadas, con la configuración de Natalia y D/E pendientes por separado. Este documento contrasta el [plan aprobado](propuesta-senas-avisos-natalia.md), incluidos sus ajustes 12.2–12.11. El [registro](registro-senas-avisos-natalia.md) conserva fallos, causas, correcciones y límites; el [traspaso](traspaso-senas-avisos-natalia.md) indica el siguiente paso. Los recibos están en `.verification/senas-avisos-20261029/` (en adelante, `EV`).

## Versiones y destinos

| Recurso | Revisión comprobada |
|---|---|
| Fuente final C9 | `deb74b023431e4f173eed85d6651c5073ad44557`, rama auxiliar `verify/senas-etapa-c-app-v9-20261030` |
| Paquete exacto | Actions 41081146798,222 archivos; `EV/release-c9`; copia privada `~/.local/share/cita-suite/releases/<SHA>` |
| Aplicación productiva | Worker `app`, versión `e5dddd3c-90e2-423c-8ce9-fc9ed4b9be15`,100% del tráfico,32 bindings conservados |
| Orígenes | `https://app.cita-suite.com.ar` y `https://app.cita-suite.workers.dev`, ambos con marcador C9 |
| Recuperación B11 | `bf0fd1892b1adc769d93c8ac369c533ee80a58b7`, paquete41049721655, versión productiva ensayada `0fbe672e-607c-4358-b335-3b047642ff09` |
| Esquema productivo |128 migraciones; proyecto `yjzferwuzbtgpmdnzlcb`; entrada de tareas heredada desactivada |
| Programador Cloudflare | `16c73f28-eb48-4651-ac71-f2fd9f4087f9`,APP→app,5 cron; staging0 cron |
| Estado final de señas | Interruptor general apagado;0 políticas/0 señas/0 horarios propios después de limpiar |
| Sitios externos |35 archivos de Natalia idénticos, sin nueva publicación; landing Vercel/DNS conservados |

El repositorio local conserva HEAD `80268e2a501198243996e1bdb0048ce066434727` e índice SHA256 `55cd8f7975542b806308d3e067f81660fe107ed1c5cdbed88962dbe614a1faba`. La rama principal anterior no se sobrescribió. La fuente completa verificada está en el auxiliar; los documentos locales de la clienta no se publican por incluirlos accidentalmente en una candidata.

## Contraste punto por punto

| Requisito aprobado | Evidencia y alcance |
|---|---|
| Promesa 1: datos de obra social y plan llegan a la ficha | Alta atómica cubierta por las suites y reserva nativa de CI/staging. Lectura productiva16:54 del destino enlazado por la web Natalia: integración activa, un profesional, ambos campos vinculados mediante `patientField`. Recibo `production-natalia-linked-configuration.json`, sin valores personales ni cambios. No se infiere identidad comercial del destino por el enlace. |
| A: avisar por WhatsApp al finalizar y desde la ficha | `practice-whatsapp.spec.ts`, full A 40966735724 y release C9; número habilitado, contenido/fecha/zona, variantes, apertura externa interceptada. No se envían mensajes reales. |
| A: todos los turnos de mañana en Recordatorios; el aviso de agenda conserva su significado | Unidad de recordatorios y full A; cubiertos plegados, contador de no cubiertos, texto de cancelación. Mutación combinada del contador detectada. |
| B: monto fijo de Natalia y opción porcentual para otros consultorios | `appointment_deposits.sql`,25 controles; fijo$40.000 entre prestaciones y porcentaje/arancel mensual/redondeo/respaldo. No se configuró Natalia. |
| B: alta atómica y ninguna seña retroactiva | SQL B; instalación productiva `production-features-installed.json`:0 políticas/0 señas antes del ensayo propio,128 migraciones. |
| B: fotografía de monto/plazos, reprogramación y política desactivada | SQL B; conserva recibidas/exceptuadas, recalcula pendientes desde el movimiento, apagar exceptúa pendientes sin confirmar turnos. |
| B: una regla de fechas y último momento | SQL B, incluidos cruce de medianoche en Córdoba y borde24 h/menos1 s; consulta por día usa la misma función privada. |
| B: condiciones antes de confirmar y cambio de política con formulario abierto | SQL 25, servidor y navegador B: rechaza términos viejos sin paciente/turno parcial, conserva datos, recarga resumen y exige segunda confirmación. Desconocido/relajado y reintento recuperado conservan sus contratos. |
| B: confirmar/exceptuar/deshacer junto con estado y auditoría | SQL B con fallas provocadas e idempotencia; navegador completo. HTTP real productivo con B11 y C9: registrar y deshacer, SQL posterior y auditorías1/1 y2/2. |
| B: impedir Confirmado pendiente por cualquier vía | SQL B: escritura directa, servidor público y recepción; interfaz pública omite el botón con seña pendiente o resuelta. |
| B: lista, alertas, pedido manual por WhatsApp y revisión concurrente | Navegador B y unidades;300+centinela/página estable, lotes de enlaces, desconocido explícito, segundo envío requiere confirmación atómica. No se afirma entrega de WhatsApp por abrir un enlace. |
| B: cancelación sólo cuando se cumplen todas las condiciones | SQL B con recibida/exceptuada/reprogramación/inactividad/suspensión/plazo/globaloff/políticaoff/autocanceloff; fallas provocadas deshacen todo y el turno de equipo se libera para todos. |
| B: tarea natural, registro, alerta y retención | Staging natural12:05:1 cancelación/1 auditoría/1 hueco por seña. Producción: ocho ejecuciones naturales16:25–17:00, todas exitosas,0procesadas/0canceladas con globaloff (`production-features-close.json`). Retención diaria: comando/permisos ensayados con rollback4929 filas, no ejecución natural diaria. |
| B: carreras y autoridad vigente | Diez carreras reales con dos conexiones en full/release, deadlocks 0; incluye pago/tarea en ambos órdenes, movimientos, filas hijas, apagado y revocación concurrente. |
| C: registro del horario anterior de cada profesional | `appointment_slot_releases.sql`,15 controles; equipo/OLD, cancelación, reprogramación y vencimiento, una misma transacción. Falla de registro revierte cancelación. |
| C: correcciones rápidas y hechos empatados | SQL C:30 min sobre intervalo exacto, movimiento pasado→futuro, ida/vuelta de turno viejo, identidad monotónica y reloj efectivo. Las dos implementaciones defectuosas tuvieron reproducciones rojas independientes. |
| C: sólo próximos horarios libres y rango acotado | SQL C y unidades:14 días por defecto/1–60,50+centinela, máximo 1001 páginas, retiro por ocupación parcial/bloqueo/inactividad y ocultación sin resucitar duplicados. |
| C: reasignar y ocultar desde agenda | Navegador C: teclado, filtros/rango, nueva navegación/intento de reserva, persistencia, retiro por ocupación y ocultación auditada; prestación retirada exige volver a elegir. HTTP real productivo adicional: aviso presente→ocultar→ausente, SQL/auditoría1. |
| Permisos y aislamiento en SQL, rutas y pantalla | Suites RLS/ACL y C 15/B 25; roles, consultorio ajeno, acceso comercial, escrituras directas y API anónima. Producción: 74 relaciones sin exposición anónima. No se sustituye esta prueba por ocultar botones. |
| Contratos, demo y presentación | Tipos0 errores/0 advertencias; fronteras; Node 168/scheduler 11/server 1579/client 246/Office 1 en release. Demo 3/3;9 superficies B/C×5 anchos sin `layoutIssues`, temas claros/oscuros públicos, capturas móviles inspeccionadas. |
| Verificación por etapa y release exacto | A 40966735724/B 41014366957/C 41047577448. Release 41082416537:20/20 fases,53 browser fuente/53 paquete C9/49 compatibilidad B11/demo 3,0 omitidos/inesperados/inestables/reintentos. |
| Recuperación conserva operar señas existentes | Staging B11 con esquema128 y tres estados:41051381337 y41051461112. Producción globaloff primero→B11→accionesHTTP/SQL→retorno nativo C9→mismas comprobaciones; sin exceptuar obligaciones en masa. Diagnóstico adicional B11 compilada41086383561:3 casos A/B/zona en su esquema127, separado de compatibilidad128. |
| Respaldo externo previo y recuperación |41081864440:105 tablas/4272 filas/126 migraciones/24 objetos, restauración aislada sin diferencias, descarga y descifrado independientes; `EV/respaldo-productivo-previo-fresco`. |
| Respaldo incluye las nuevas tablas y recupera trabajos | Staging 41050555719: nuevas tablas pobladas1 política/1 exclusión/3 señas/1 global/1 hueco, restauradas sin diferencias;2 jobs reconstruidos dos veces/globaloff/identidadCsegura. Copia productiva posterior **41092046966 aprobada**: 110 tablas/4295 filas/128 migraciones/24 objetos; restaurada sin diferencias, descargada y descifrada independientemente. `production-post-backup-feature-tables.json` comprueba las cinco tablas nuevas y snapshot posterior a la limpieza. |
| Preservación productiva y limpieza | `production-owned-cleanup.json`:0 consultorios/0dueñas propios y recorrido de todas las tablas con business_id. `production-core-after.json` y control final `production-core-close.json`: SHA completos de21 consultorios/122 pacientes/108 turnos idénticos al antes, sin exclusiones; Calendar 1/1. |
| Restablecer tareas sin otro despliegue durante observación | `production-state-close.json`: cinco cronCF/ninguno en staging,APP→app,C9/32bindings/128/legacyoff, Auth negativa/válida y agenda en ambos orígenes después de limpiar. Ocho eventos naturales16:51:46→17:03:31UTC, todosok/sinexcepciones, en calendario/push/reseñas/cargas. `production-scheduler-observed-summary.json`; tail terminado, sin procesos propios vivos. Mantenimiento cada3h configurado, no observado en esta ventana; veinte archivos de scheduler/despacho idénticos al baseline, con once pruebasCI aprobadas. |

## Respaldo y recuperación operativa

La copia previa permanece en `~/.local/share/cita-suite/backups/production-senas-20261030T154244Z`, manifiesto SHA256 `5e2d2acf53acf129ded955cf5f9500d7a26fca280bb63f812758a46d38a522d6`. La copia posterior **41092046966**, instantánea 16:44:47.284UTC, se conserva además en `~/.local/share/cita-suite/backups/production-senas-20261030T164850Z`, manifiesto SHA256 `ef847fb3378d952e3e4d0e853556227a94760dbef3ceac1ec9c117e6987716b5`. Recibos `EV/respaldo-productivo-posterior/{manual-backup,manual-backup-readback,local-recovery}.json`; 110 tablas/4295 filas/128 migraciones/24 referencias y 22 contenidos únicos, sin diferencias al restaurar. Todas las tablas nuevas están presentes: global 1/resto 0 después de limpiar. Esto complementa el ensayo no vacío de staging, no lo reemplaza.

Después de restaurar un respaldo128 en un **destino nuevo**, ejecutar `supabase/operations/recover-deposit-automation.sql` y verificar globaloff/dos trabajos exactos/identidad antes de servirlo. La recuperación privada genérica restaura tablas, datos, historial, objetos administrados y archivos; **no reconstruye automáticamente los trabajos cron**. El ensayo de staging sí probó la operación nueva. Los otros trabajos históricos requieren su propio procedimiento.

Para revertir código, seguir [la secuencia concreta](publicacion-senas-avisos-natalia.md): globaloff primero, detener scheduler y respetar margen, B11 compatible, comprobar bytes/permisos/Auth/agenda y señas existentes. No restaurar toda la base sobre datos posteriores para ensayar una reversión de aplicación. Los identificadores vigentes se leen nuevamente antes de mutar.

## Límites y decisiones pendientes

- La entrega técnica no activa señas en el consultorio de Natalia: faltan las decisiones y datos de su información registrada (documento privado `docs/clientes/natalia-frutos/informacion-20261029.md`, sólo en la computadora de trabajo). No se inventan ni se cargan sus opciones. El monto informado es$40.000, sin aumentos automáticos.
- Lectura del destino enlazado por su web16:54: WhatsApp de contacto desactivado y sin número, política de seña apagada. Por contrato, el botón público de WhatsApp permanece oculto hasta cargar y habilitar ese contacto. La función está probada con contacto habilitado en entornos de ensayo; esto no sustituye la configuración de la clienta.
- D (aviso al celular del consultorio) y E (correo) siguen en pausa. La alarma/calendario/push del paciente requiere activación del paciente; esta entrega no demuestra funcionamiento en su teléfono por abrir un enlace.
- CI usa servicios descartables; no acredita Realtime alojado. La excepción del observador conserva controles contra mensajes forjados y cierre nativo actual/futuro; no amplía errores tolerados.
- El release C8 fallido no conservó imágenes/reportes por un fallo del transporte. Los logs se conservan;821 archivos íntegros de C9 corresponden a C9, no reemplazan evidencia perdida de otra corrida.
- La igualdad de huellas abarca todas las filas de las tres tablas nombradas, no todas las tablas de la base. Los ensayos naturales, manuales, CI, staging y producción conservan evidencias separadas.
- No se contrató ni cambió ningún plan. La desviación de latencia aceptada para el primer consultorio y los pendientes anteriores de Google/correo no se declaran resueltos por esta campaña.

## Comprobante final

`EV/cierre-productivo.json`,17:04:43.972UTC, **ok=true**, reúne y compara los recibos de release, acciones B11/C9, ocultación, limpieza, ambas huellas, estado final/Auth/agenda, tareas naturales y las dos copias recuperadas. Incluye la huellaSHA256 de cada recibo leído; SHA256 del comprobante: `a46d1fa83f16ba0363bb4c5e9a44c569e0b702fda353b195e8acff807d73fe39`. El verificador local es `EV/close-campaign.py`, sin red ni mutaciones. Las limitaciones declaradas forman parte del cierre; no son pruebas supuestas ni activaciones pendientes que se hayan realizado.
