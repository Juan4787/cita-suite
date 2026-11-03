# Ejecución de E: continuidad, decisiones y evidencia

**Punto vigente — 3 de noviembre de 2026:** ejecución completa autorizada por Juan, incluida publicación y pruebas productivas; decisiones iniciales Q01/Q02 resueltas y ejecución E1 en preparación de contratos/pruebas. No hay implementación funcional publicada. Producción sigue en V12b; revisión exacta en el [estado vigente](../ESTADO-VIGENTE.md).

Fuentes: [plan íntegro y ajustes](propuesta-senas-avisos-natalia.md#ejecucion-e-autorizada), [especificación única y 97 casos](etapa-e-correo-autogestion.md), [registro histórico](registro-senas-avisos-natalia.md), [traspaso](traspaso-senas-avisos-natalia.md#etapa-e-punto) y [pendientes generales](pendientes-vigentes.md#etapa-e-pendientes). Este archivo concentra el seguimiento de E; no copia sus reglas funcionales para evitar dos especificaciones divergentes.

## Regla obligatoria de continuidad

1. Después de cada compactación, antes de cambiar código/datos/configuración, leer AGENTS, el estado vigente, el plan aprobado completo con sus ajustes, la especificación E y el punto actual de este registro/traspaso. Un resumen de conversación ayuda a localizar información; no reemplaza esas fuentes ni elimina requisitos ausentes del resumen.
2. Recuperar el último punto comprobado: revisión de main/GitHub, revisión/versión efectivas de producción, diferencias declaradas de código, migraciones, interruptores, conexiones, corridas y evidencia. Confirmar resultados de procesos/CI en curso antes de lanzar reemplazos. No repetir por rutina una prueba válida ni ejecutar instrucciones fechadas ya sustituidas.
3. Actualizar este punto y el traspaso tras cada cambio significativo, decisión, falla, corrección, corrida y publicación, y antes de una interrupción o compactación anunciada. Registrar también trabajo sin cerrar, archivos cambiados, operación pendiente y el siguiente comando concreto. Guardar checkpoints coherentes en main y GitHub; no perder cambios ni descartarlos para hacer pasar el chequeo de sincronización.
4. Cada caso conserva estado por evidencia: pendiente, en implementación, probado local/simulado, probado en CI, probado en producción/proveedor/buzón, o bloqueado por una dependencia identificada. Una prueba existente o verde aislada no aprueba un caso. Registrar hipótesis, roja o mutación que demuestra sensibilidad, negativa/adversaria y lectura posterior de los datos relevantes.
5. El cierre exige contrastar cada criterio con su evidencia y límites, incluidos carreras en ambos órdenes, efectos parciales provocados, aislamiento, dinero, revocación, cola, proveedor y buzón. No llamar prueba de recepción a una aceptación API ni a un estado del proveedor. No atribuir una verificación a una revisión distinta.
6. Todo ajuste funcional va al final de la sección 12 del plan, con motivo y precedencia. Actualizar en el mismo paso los puntos de entrada, contratos, permisos, regresiones, operación y pendientes que cambien. Preservar historia literal, fechada y señalada; no dejar un resumen vigente incompatible con el estado real.
7. Antes de cualquier publicación, conservar recuperación compatible con el esquema/dinero/colas nuevos, comprobar el artefacto exacto y registrar versión y estado de interruptores. Actualizar el estado vigente y sincronizar main/GitHub en ese trabajo. Aplicar controles por el riesgo concreto, sin restablecer circuitos históricos por inercia.
8. No volver a pedir la autorización de implementación/publicación/pruebas ya otorgada. Decisiones técnicas autónomas requieren fundamento y comprobación. No inventar datos o decisiones comerciales de Natalia, comprar créditos, activar recargas ni enviar a otros destinatarios por inferencia. Pruebas pesadas sólo en CI, secuenciales; preservar cuentas, secretos y configuración reales.

## Decisiones iniciales resueltas

- **Q01 resuelta:** subdominio de Cita Suite por consultorio, sin compra de otro dominio; From de su subdominio verificado, nombre/logo/contenido y Reply-To del consultorio. `odontologia-rojas.cita-suite.com.ar` fue un ejemplo, no el alta de una entidad real. Provisión repetible y registros acotados; no se supone verificación heredada del dominio compartido.
- **Q02 resuelta:** envíos habilitados por defecto, desactivables; preparación del emisor visible y separada de esa preferencia. Botones habilitados por defecto cuando correspondan al contexto, con controles independientes. No se exige una segunda activación manual al completar los datos.
- **Aclaración contextual expresa:** comprobante de turno vigente puede mostrar CANCELAR/REPROGRAMAR; comprobante de cancelación no muestra ninguno de los dos. Los controles, alternativas cruzadas y textos dependen de estado, tiempo, capacidades vigentes, configuración y dinero. AC05/AC06/OP03 no se reducen a ocultar un botón en una plantilla.
- Literales y precedencia en [12.21 y 12.22](propuesta-senas-avisos-natalia.md#etapa-e-decisiones-iniciales). No quedan preguntas iniciales ni permisos por pedir; continuar E1–E6 por cuenta propia.

## Punto técnico de partida y conexiones

- Main y GitHub: `90991e1`; sincronización inicial aprobada, sin trabajo sin commitear. Producción: V12b `771fac5950c532b1123f11d4dde93eef9b42ceba`, versión `277d332d-1794-4367-8ef0-567ced159f1b`.
- Plan completo y especificación revisados antes de escribir cambios funcionales. Se consultan registro/traspaso históricos como evidencia y fuente de riesgos; sus versiones y pausas anteriores no gobiernan este encargo posterior.
- Zoho OAuth local persistente operativo; lectura autenticada del agente nuevamente correcta. Clave de envío/webhook/integración de la app todavía pendientes. [Operación y custodia](../architecture/zoho-cpaas-terminal.md).
- Gmail conectado y consulta del perfil comprobada; búsqueda y lectura de un mensaje ya verificadas en la conversación. Buzón propio para las pruebas acordadas: cuenta dedicada de Cita Suite. No es un envío de prueba nuevo ni una integración terminal de Gmail; se utiliza su conector autorizado.
- A/B/C conservan su cierre. D y los datos comerciales faltantes de Natalia conservan sus pendientes. No activar seña/cancelación automática de Natalia ni alterar su acceso por esta etapa.
- Skills leídas: Supabase Postgres para SQL/transacciones/RLS/colas; Impeccable para las superficies nuevas conservando el diseño existente. Antes de editar UI se leerá su referencia de calidad y la superficie aplicable. No se iniciaron compilaciones, contenedores ni navegador locales.

## Checkpoint y siguiente acción

**Fase:** E0 completo; E1 en implementación, con alcance de ejecución autorizado. **Implementación iniciada:** contrato puro y primera migración E1 escrita; todavía sin rutas ni envíos integrados, sin migración aplicada en producción. **Publicación de E:** no. **Pruebas integrales E:** no ejecutadas.

**Siguiente acción:** verificar por CI nivel sql ambas migraciones `20261103010000`/`20261103020000`, sus 22+20 comprobaciones y los ocho casos de actualización. Ya se constataron las rojas estructurales; fundamentos v1–v3 detectaron errores del fixture, corregidos en E1.5/E1.6/E1.8. Recuperar resultado/tipos de una nueva snapshot combinada; no atribuir un verde previo a ese código. Después seguir con comandos atómicos de agenda/dinero, cola y E2–E6 según dependencias. Q01/Q02 están resueltas; no esperar otra instrucción de inicio.

**Evidencia privada de esta ejecución:** `.verification/etapa-e-20261103/`. Ningún secreto, dirección de paciente, cuerpo de correo recibido o dato personal se incluye en Git ni en documentos públicos. Las rutas de evidencia no equivalen a resultados aprobados.

## Matriz de seguimiento

La regla de cada caso se lee en la especificación; esta tabla registra su aceptación. Inicialmente ninguno tiene cierre funcional de E.

| Caso | Estado de aceptación | Evidencia y límites |
|---|---|---|
| EM01 | Pendiente | Sin prueba funcional de E. |
| EM02 | Pendiente | Sin prueba funcional de E. |
| EM03 | Pendiente | Sin prueba funcional de E. |
| EM04 | Pendiente | Sin prueba funcional de E. |
| EM05 | Pendiente | Sin prueba funcional de E. |
| EM06 | Pendiente | Sin prueba funcional de E. |
| EM07 | Pendiente | Sin prueba funcional de E. |
| EM08 | Pendiente | Sin prueba funcional de E. |
| EM09 | Pendiente | Sin prueba funcional de E. |
| EM10 | Pendiente | Sin prueba funcional de E. |
| EM11 | Pendiente | Sin prueba funcional de E. |
| EM12 | Pendiente | Sin prueba funcional de E. |
| AC01 | Parcial local | Contrato de contexto: 44 casos y cuatro mutaciones; faltan integración, SQL y recorridos reales. Ver E1.1. |
| AC02 | Pendiente | Sin prueba funcional de E. |
| AC03 | Pendiente | Sin prueba funcional de E. |
| AC04 | Pendiente | Sin prueba funcional de E. |
| AC05 | Parcial local | Contrato de contexto: 44 casos y cuatro mutaciones; faltan integración, SQL y recorridos reales. Ver E1.1. |
| AC06 | Parcial local | Contrato de contexto: 44 casos y cuatro mutaciones; faltan integración, SQL y recorridos reales. Ver E1.1. |
| AC07 | Pendiente | Sin prueba funcional de E. |
| AC08 | Pendiente | Sin prueba funcional de E. |
| AC09 | Parcial local | Contrato de contexto: 44 casos y cuatro mutaciones; faltan integración, SQL y recorridos reales. Ver E1.1. |
| AC10 | Pendiente | Sin prueba funcional de E. |
| RP01 | Pendiente | Sin prueba funcional de E. |
| RP02 | Pendiente | Sin prueba funcional de E. |
| RP03 | Pendiente | Sin prueba funcional de E. |
| RP04 | Pendiente | Sin prueba funcional de E. |
| RP05 | Pendiente | Sin prueba funcional de E. |
| RP06 | Pendiente | Sin prueba funcional de E. |
| RP07 | Pendiente | Sin prueba funcional de E. |
| RP08 | Pendiente | Sin prueba funcional de E. |
| RP09 | Pendiente | Sin prueba funcional de E. |
| RP10 | Pendiente | Sin prueba funcional de E. |
| RP11 | Pendiente | Sin prueba funcional de E. |
| RP12 | Pendiente | Sin prueba funcional de E. |
| RP13 | Pendiente | Sin prueba funcional de E. |
| SN01 | Pendiente | Sin prueba funcional de E. |
| SN02 | Pendiente | Sin prueba funcional de E. |
| SN03 | Pendiente | Sin prueba funcional de E. |
| SN04 | Pendiente | Sin prueba funcional de E. |
| SN05 | Pendiente | Sin prueba funcional de E. |
| SN06 | Pendiente | Sin prueba funcional de E. |
| SN07 | Pendiente | Sin prueba funcional de E. |
| SN08 | Pendiente | Sin prueba funcional de E. |
| SN09 | Pendiente | Sin prueba funcional de E. |
| SN10 | Pendiente | Sin prueba funcional de E. |
| SN11 | Pendiente | Sin prueba funcional de E. |
| SN12 | Pendiente | Sin prueba funcional de E. |
| SN13 | Pendiente | Sin prueba funcional de E. |
| SN14 | Pendiente | Sin prueba funcional de E. |
| SN15 | Pendiente | Sin prueba funcional de E. |
| SN16 | Pendiente | Sin prueba funcional de E. |
| SN17 | Pendiente | Sin prueba funcional de E. |
| SN18 | Pendiente | Sin prueba funcional de E. |
| SN19 | Pendiente | Sin prueba funcional de E. |
| RM01 | Pendiente | Sin prueba funcional de E. |
| RM02 | Pendiente | Sin prueba funcional de E. |
| RM03 | Pendiente | Sin prueba funcional de E. |
| RM04 | Pendiente | Sin prueba funcional de E. |
| RM05 | Pendiente | Sin prueba funcional de E. |
| RM06 | Parcial local | Contrato de contexto: 44 casos y cuatro mutaciones; faltan integración, SQL y recorridos reales. Ver E1.1. |
| RM07 | Parcial local | Contrato de contexto: 44 casos y cuatro mutaciones; faltan integración, SQL y recorridos reales. Ver E1.1. |
| RM08 | Pendiente | Sin prueba funcional de E. |
| RM09 | Parcial local | Contrato de contexto: 44 casos y cuatro mutaciones; faltan integración, SQL y recorridos reales. Ver E1.1. |
| RM10 | Pendiente | Sin prueba funcional de E. |
| RM11 | Parcial local | Contrato de contexto: 44 casos y cuatro mutaciones; faltan integración, SQL y recorridos reales. Ver E1.1. |
| RM12 | Pendiente | Sin prueba funcional de E. |
| RM13 | Pendiente | Sin prueba funcional de E. |
| RM14 | Pendiente | Sin prueba funcional de E. |
| RM15 | Pendiente | Sin prueba funcional de E. |
| ZH01 | Pendiente | Sin prueba funcional de E. |
| ZH02 | Pendiente | Sin prueba funcional de E. |
| ZH03 | Pendiente | Sin prueba funcional de E. |
| ZH04 | Pendiente | Sin prueba funcional de E. |
| ZH05 | Pendiente | Sin prueba funcional de E. |
| ZH06 | Pendiente | Sin prueba funcional de E. |
| ZH07 | Pendiente | Sin prueba funcional de E. |
| ZH08 | Pendiente | Sin prueba funcional de E. |
| ZH09 | Pendiente | Sin prueba funcional de E. |
| ZH10 | Pendiente | Sin prueba funcional de E. |
| ZH11 | Pendiente | Sin prueba funcional de E. |
| ZH12 | Pendiente | Sin prueba funcional de E. |
| ZH13 | Pendiente | Sin prueba funcional de E. |
| UI01 | Pendiente | Sin prueba funcional de E. |
| UI02 | Pendiente | Sin prueba funcional de E. |
| UI03 | Pendiente | Sin prueba funcional de E. |
| UI04 | Pendiente | Sin prueba funcional de E. |
| UI05 | Pendiente | Sin prueba funcional de E. |
| UI06 | Pendiente | Sin prueba funcional de E. |
| UI07 | Pendiente | Sin prueba funcional de E. |
| UI08 | Pendiente | Sin prueba funcional de E. |
| OP01 | Pendiente | Sin prueba funcional de E. |
| OP02 | Pendiente | Sin prueba funcional de E. |
| OP03 | Parcial local | Contrato de contexto: 44 casos y cuatro mutaciones; faltan integración, SQL y recorridos reales. Ver E1.1. |
| OP04 | Pendiente | Sin prueba funcional de E. |
| OP05 | Pendiente | Sin prueba funcional de E. |
| OP06 | Pendiente | Sin prueba funcional de E. |
| OP07 | Pendiente | Sin prueba funcional de E. |

## Registro cronológico

### E0.1 — autorización y preparación del 3 de noviembre

- Pedido de Juan preservado literal en plan 12.20. Publicación/pruebas productivas autorizadas, autonomía posterior y exigencia de continuidad/consistencia documental.
- Check-repo-sync inicial aprobado. Lectura del plan íntegro, especificación, reglas vigentes y estado de las conexiones. No se ejecutaron escrituras remotas ni envíos.
- Se identificaron Q01/Q02 antes de implementar y se enviaron juntas. Sólo falta su respuesta; no se interpreta como falta de permiso.
- Se crea este registro con los 97 casos únicos, todos pendientes de aceptación funcional, y la regla de continuidad. La documentación activa remite aquí y sustituye la espera de una nueva autorización de inicio.

### E0.2 — respuestas y correcciones contextuales incorporadas

- Juan eligió subdominio por consultorio y envíos habilitados por defecto, con opción de desactivarlos; botones pertinentes al contexto, configurables. Se aceptaron sus decisiones, con verificación real de cada subdominio antes de emitir. Plan 12.21.
- Reafirmó que el comprobante de turno vigente sí puede ofrecer Cancelar/Reprogramar; el comprobante de cancelación no puede ofrecer ninguno. Se registra literal en 12.22 y como criterio común de UX/negocio para correo y gestión.
- Las propuestas de remitente compartido y de activación manual inicial no fueron elegidas. Se retiran de los resúmenes activos; se conserva su historial de pregunta/respuesta sin presentarlas como implementación.

### E1.1 — contrato contextual común, sin integración todavía

- Se agregaron `apps/web/src/lib/scheduling/patient-action-context.ts` y su prueba, reutilizando la lista pura de estados activos existente. El servidor/SQL sigue siendo la autoridad: la presentación sólo filtra permisos efectivos, no los concede.
- Distingue comprobante de turno vigente y comprobante de cancelación; acciones para futuro/actual/pasado, enlace inválido/revocado, reserva pública retirada, preferencias independientes, seña pendiente/resuelta y evento incompatible con el estado actual. Una seña pendiente no implica pago ni confirmación.
- Roja inicial: módulo inexistente, por lo que no se ejecutaron casos; `.verification/etapa-e-20261103/contexto-roja.log`. Verde posterior local **44/44**, `contexto-verde-inicial.log`.
- **Cuatro mutaciones verificadas:** cancelado con acciones, ignorar una preferencia, comprobante de cancelación de un turno activo y pedir una seña ya resuelta. Las cuatro fallaron por aserciones, no por compilación; `mutaciones-contexto.json` y los cuatro logs identificados allí. Fuente restaurada byte por byte.
- Límite: es contrato local y todavía no tiene consumidores. No acredita HTML de correos, páginas, cambios en base, proveedor, buzón ni publicación. Ningún caso completo de E se cierra por este verde. No hay procesos de esas pruebas pendientes.
- Decisión técnica: a la hora exacta del comienzo ya no se ofrecen mutaciones; para turnos pasados sólo consulta/contacto, siguiendo AC06. Preferencias de botones del email no retiran la capacidad del enlace de gestión.

### E1.2 — contrato SQL inicial escrito, todavía sin ejecutar

- Se agregó `supabase/tests/appointment_management_foundation.sql`: 16 comprobaciones sobre preferencias predeterminadas, revisión semántica, dos movimientos con mismo estado, exclusión de telemetría/presentación, protección ante condiciones no informadas, historial de pagos/correcciones/excepciones, idempotencia del registro existente, fallo provocado y ACL/RLS.
- **Todavía no ejecutado:** la migración nueva no existe. La suite debe fallar primero en CI por el contrato ausente; no se considera roja demostrada por inspección. No se levantó base local ni se aplicó SQL remoto de producción.
- Diseño técnico por verificar: revisión semántica calculada en SQL sobre campos relevantes, en vez de usar updated_at; excluir telemetría y preferencias de presentación. Preservar la proyección de seña uno a uno y añadir obligaciones históricas/eventos; deshacer agrega una corrección, no una devolución bancaria. Una obligación nueva se instala antes de actualizar la proyección, para no interpretar el cambio de ciclo como deshacer un pago anterior.
- No introducir un disparador de asignaciones que tome el turno después de bloquear una fila hija sin auditar su orden: podría invertir el bloqueo contra la sincronización del turno. Revalidar composición/permisos en la operación atómica. Los bloqueos de política deben preceder al turno cuando también los necesita el guardado de política existente.
- Credenciales de gestión separadas por generación: revocar debe bloquear también mutaciones por el token legado, manteniendo su uso limitado para calendario/push. Todos los caminos de escritura deben acabar en el comando validado; no hay revocación aprobada todavía.
- Fuente del contrato contextual: main `67306c1`; snapshot CI `4cfdee41adfb4cf5b03e93aa8c7990e57ea3cdca`, rama auxiliar `verify/etapa-e-contexto-20261103`, nivel fast solicitado. Recuperar su resultado antes de repetirlo. Ningún CI nuevo se atribuye aprobado por el verde local.

### E1.3 — resultado fast y reproducción SQL solicitada

- **Fast aprobado:** corrida `41578321181`, fuente exacta `4cfdee41adfb4cf5b03e93aa8c7990e57ea3cdca`. Se leyeron los recibos, no sólo la conclusión del workflow: servidor 1711/1711, cliente 265/265, cero fallos/pendientes; el archivo contextual figura con sus 44 aserciones aprobadas. No se atribuye esta prueba a código posterior ni a SQL/UI/proveedor.
- Evidencia privada `fast-contexto-41578321181.zip`, extraída con `collect-verification-evidence.py` en `fast-contexto-evidence`; siete archivos, SHA-256 de la colección `e4957c112a0258e4d66daf0b8a43eaee134170b92b7b5717dd15c4172ebd7462`.
- Contrato SQL en main/GitHub `462c9d0`. Corrida roja solicitada `41579375029`, fuente `c44a7dd131fae96ab5430f6b5fd5ca91a80e4757`; al registrar este punto sigue ejecutándose. No hay migración nueva todavía ni resultado rojo atribuido antes de recibirlo. La sincronización de main/GitHub/producción/documento volvió a aprobarse.
- Se contrastaron bloqueos y digest con la documentación oficial de PostgreSQL: [bloqueos explícitos](https://www.postgresql.org/docs/current/explicit-locking.html) y [pgcrypto](https://www.postgresql.org/docs/current/pgcrypto.html). La revisión debe serializar instantes absolutos, sin depender de la zona horaria de la sesión; se agregará su prueba. Estas fuentes no acreditan el comportamiento de la implementación propia.

### E1.4 — roja SQL demostrada y primera migración de fundamentos

- **Roja demostrada:** `41579375029`, fuente `c44a7dd131fae96ab5430f6b5fd5ca91a80e4757`, falló en la creación del helper de prueba porque `private.appointment_semantic_revision(uuid,uuid)` no existe. No alcanzó los 16 casos; se corrige la expectativa inicial de que llegaría primero al tipo de política ausente. Log privado `sql-roja-41579375029.log`, línea 848. No es un fallo de infraestructura.
- Se escribe `20261103010000_appointment_management_foundation.sql`: preferencias iniciales habilitadas con emisor no verificado, estado de gestión sin condiciones económicas retroactivas, obligaciones históricas y eventos, sin tocar la relación uno a uno vigente. Sin productores ni envío, sin nuevo cron ni cambios en Natalia.
- Revisión: hash SQL con fechas absolutas y contador monotónico de cambios relevantes del turno. Se añade el contador porque sólo comparar valores no detectaría A→B→A; no sube por updated_at/calendario/WhatsApp. La historia se sincroniza desde las escrituras existentes que ya bloquean primero el turno. No se incorporan bloqueos inversos en hijos.
- Registrar/deshacer agrega eventos en la misma transacción; exceptuar no registra dinero. Cancelar mantiene el pago y lo deja por resolver, sin pérdida ni devolución automática. Reasignar con pagos registrados se rechaza en la transacción; completar la integración y mensaje humano de esa guardia en E1/E2 sigue pendiente.
- Contrato ampliado a 22 verificaciones: ida/vuelta al mismo horario, zona de sesión distinta, tenant ajeno, cancelación con pago, identidad y eventos no reescribibles. Fixtures `.before.sql`/`.after.sql`: cinco estados reales del esquema anterior, fotografía exacta de las proyecciones y ocho verificaciones de actualización sin pagos inventados ni hora histórica supuesta. Nuevas verificaciones todavía no ejecutadas; no se cuentan como aprobadas.
- Falta CI SQL/tipos, pruebas de carreras y mutaciones SQL, comandos idempotentes/capacidades/cola. La migración escrita es sólo un fundamento, no la implementación completa de E1 ni aceptación funcional de los 97 casos. Mantener esas filas pendientes/parciales.

### E1.5 — primera comprobación SQL y corrección de la limpieza del fixture

- Corrida `41580229239`, fuente `4f2c1b6ce3f23cfa3d75be67fd6798858506c4e4` (main `69c0033`), fallida durante reconstrucción/tipos. Log privado `sql-fundamentos-41580229239.log`: al limpiar el fixture previo/posterior a E1, borrar directamente el consultorio intenta borrar un paciente aún referenciado por la nueva obligación.
- Contraste causal: el contrato anterior de `appointments→patients` ya usa RESTRICT, y el fixture de actualización de trabajos elimina explícitamente los turnos antes del consultorio. El fixture E1 había omitido ese orden. Se corrige su limpieza, eliminando primero exclusivamente sus turnos sintéticos; no se rebaja la clave foránea de historia económica para obtener un verde.
- La salida no acredita el resto de la suite ni los ocho checks de actualización, porque el proceso terminó fallido. Continuar con una snapshot corregida; no repetir la fuente fallida sin cambios. No hubo cambios de producción.

### E1.6 — segunda corrida SQL: etiquetas de fixture y sensibilidad ante filas ausentes

- Corrida `41580661787`, fuente `a30522cf7aaf0fabb49c2e8c29e4ea200f83a612` (main `c2b9340`), fallida por la aserción 3 del fixture de actualización. La limpieza corregida ya termina. Log privado `sql-fundamentos-v2-41580661787.log`.
- El disparador previo de snapshots sustituye `service_name_snapshot` por el nombre real del servicio. El fixture lo usaba erróneamente como etiqueta propia; la salida muestra todos los nombres como `E1 upgrade service`. Se conserva el comportamiento de producción y se identifican los cinco casos por un mapa privado label→UUID registrado antes de migrar.
- Se detecta además que la aserción de fecha desconocida podía dar NULL por no encontrar una fila. Se cambia por un conteo exacto de una obligación pagada identificada; un faltante falla. La prueba de términos antiguos también exige cinco filas seguras, en vez de cero filas malas. No se considera verde anterior esa sensibilidad insuficiente.
- No cambió el SQL de la migración por esta falla; sí el fixture de prueba. Sigue pendiente la suite E1 completa. Continuar con snapshot corregida, nivel sql, y recuperar los tipos sólo si su recibo/digest corresponden a las migraciones actuales.

### E1.7 — contrato de capacidades de gestión, previo a implementación

- Escritas veinte comprobaciones SQL en `appointment_management_capabilities.sql`: acceso opaco almacenado como hash, alcance turno/consultorio, enlace legado antes/después de revocación, conservación del token de calendario, generación esperada, operación repetida/cambiada, actor revocado/ajeno, caducidad, falla de auditoría y ACL. Todavía sin corrida roja ni migración de capacidades; no anticipar un resultado.
- Decisión técnica a verificar: credenciales opacas aleatorias de 256 bits, sólo digest en tabla privada y resolución/alta exclusivamente desde backend, con generación bloqueada por turno. Evita guardar otra clave global de firma en el Worker. La capacidad de gestión no reemplaza el UID de calendario. Su emisión no tendrá un endpoint público que pueda renovar enlaces revocados.
- Recibo de operación privado y compartido por comandos, identidad de operación por consultorio, huella canónica de entrada y actor; revalidar autorización antes de recuperar un resultado anterior. El ensayo de revocación debe demostrar también que una falla de auditoría deshace todo. TTL técnico y retención se fijarán con la implementación, no como una nueva regla comercial.
- Primero recuperar la corrida de fundamentos v3, fuente `c16611a8eba7ccc8dd452d83eb090c57e2d0be4a`, ya solicitada en rama `verify/etapa-e-fundamentos-v3-20261103`. Esa fuente NO contiene este contrato nuevo. Después ejecutar una snapshot con el contrato de capacidades para demostrar su roja antes de implementarlo.

### E1.8 — identidad de prueba restaurada y evidencia de SQL fallida

- Fundamentos v3: corrida `41581186112`, fuente `c16611a8eba7ccc8dd452d83eb090c57e2d0be4a`, fallida en el movimiento A→B→A de la comprobación 17 por `APPOINTMENT_ACCESS_DENIED`. Log privado `sql-fundamentos-v3-41581186112.log`. La prueba negativa 16 había dejado el JWT del dueño ajeno; RESET ROLE no restablece esa identidad. Se repone explícitamente el JWT del dueño correcto antes de probar movimientos. Se mantiene intacta la guardia real que detectó el error.
- El arnés descartaba stdout si aparecía un error SQL posterior, ocultando las aserciones previas de ese mismo archivo. Se agrega salida de diagnóstico acotada a 32 KiB para psql fallida dentro del contenedor propio. No se llama aprobado al prefijo no recuperado ni se habilitan destinos remotos/locales pesados.
- Roja de capacidades solicitada: corrida `41581532197`, fuente `f64c2d8d22a46c93ae91c7176b368f9276b963ea` (main `8c676fe`), rama `verify/etapa-e-capacidades-roja-20261103`. Al registrar este punto sigue ejecutándose; esa fuente precede a la corrección de identidad/diagnóstico. La migración de capacidades todavía no existe; esperar la roja concreta antes de escribirla. Después comprobar ambos contratos juntos, sin otra repetición aislada de fundamentos.

### E1.9 — roja de capacidades comprobada e implementación inicial

- **Roja comprobada:** `41581532197`, fuente exacta `f64c2d8d22a46c93ae91c7176b368f9276b963ea`, falló al crear el helper por falta de `public.resolve_appointment_management_access(text,boolean)`. Log privado `sql-capacidades-roja-41581532197.log`, línea 897. No alcanzó sus veinte comprobaciones ni es verde de fundamentos.
- Se escribe `20261103020000_appointment_management_capabilities.sql`: tablas privadas de hashes y recibos, emisión/resolución sólo backend, revocación para dueño/admin/recepción con autorización vigente, generación/revisión esperadas, bloqueo por operación y turno, auditoría y recibo en una transacción. Repetir no concede autoridad a un actor que ya perdió el permiso.
- Se verificó el formato real anterior en la migración inicial: `confirmation_token` también es 64-hex aleatorio, no UUID. El backend distingue explícitamente el canal legado de la capacidad nueva. Revocar no rota ese token de calendario y bloquea la vía legada de gestión.
- La resolución usa búsquedas indexadas por token/hash antes de unir el turno; evita examinar todos los turnos por una condición OR correlacionada. Una consulta obtiene capacidad/generación/revisión con la misma fotografía. La acción futura debe revalidar otra vez después de bloquear, sin tratar esta lectura como autorización permanente.
- Caducidad técnica: hasta 30 días después del turno, con mínimo un día desde emisión y máximo 365 días desde emisión; usa el reloj SQL después del bloqueo. No cambia plazos de cancelación/seña ni agrega un límite comercial a reprogramaciones. Falta integrar limpieza/retención acotada y sus pruebas en la operación E1/E4.
- **Todavía no verificado:** correr ambos contratos y actualización juntos en CI, recuperar tipos oficiales con digest y después integrar comandos/rutas. Faltan también carreras, ayuda que venza mientras espera un bloqueo, corrección de email/reasignación con dinero, cola y todos los recorridos de E. No se publicó ni aplicó SQL de E en producción.
