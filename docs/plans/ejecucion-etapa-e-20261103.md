# Ejecución de E: continuidad, decisiones y evidencia

**Punto vigente — 3 de noviembre de 2026:** ejecución completa autorizada por Juan, incluida publicación y pruebas productivas; decisiones iniciales Q01/Q02 resueltas y ejecución E1 en preparación de contratos/pruebas. No hay implementación funcional publicada. Producción sigue en V12b; revisión exacta en el [estado vigente](../ESTADO-VIGENTE.md).

**Cola posterior, sin cambiar de tarea:** Juan encargó P1 cancelación desde recepción, P2 estilos completos claro/oscuro y P3 reemplazo de D por avisos internos similares a Seguimientos, sólo después de terminar/publicar/auditar E y en ese orden. [Seguimiento separado](tareas-posteriores-a-e-20261103.md), plan 12.23. La antigua D del celular queda sustituida; no es un push pendiente de retomar. E sigue activa.

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
- A/B/C conservan su cierre. Los datos comerciales faltantes de Natalia conservan sus pendientes. La antigua D celular quedó reemplazada por la futura P3 interna, posterior a E/P1/P2. No activar seña/cancelación automática de Natalia ni alterar su acceso por esta etapa.
- Skills leídas: Supabase Postgres para SQL/transacciones/RLS/colas; Impeccable para las superficies nuevas conservando el diseño existente. Antes de editar UI se leerá su referencia de calidad y la superficie aplicable. No se iniciaron compilaciones, contenedores ni navegador locales.

## Checkpoint y siguiente acción

**Fase:** E0 completo; E1 y primera integración E2 en implementación. Siete migraciones comprobadas en SQL descartable; adaptadores y pantalla compartida escritos, sin publicar ni aplicar SQL en producción. Personal/roles/contacto/cola pendientes. **Publicación de E:** no. **Pruebas integrales E:** no ejecutadas.

**Siguiente acción:** recuperar fast de integración inicial de autogestión, corregir por evidencia y completar pruebas de ruta/revocación/navegador. Hay una nueva prueba de reserva tras cancelación voluntaria sin seña, todavía sin ejecutar (posible botón limitado por UI vieja a seña vencida). Último SQL íntegro `41653421061`, siete migraciones. Continuar personal/identidad/roles/cola y E3–E6; después P1/P2/P3.

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
| EM11 | Parcial CI | Reparación controlada no hereda aceptación/deuda y eventos conservan generación en 41616550006; faltan destinatarios/rutas/alta idempotente y prueba integral. |
| EM12 | Pendiente | Sin prueba funcional de E. |
| AC01 | Parcial CI | Contrato puro: 44 casos en fast 41578321181 y cuatro mutaciones locales; faltan integración y recorridos reales. Ver E1.1/E1.15. |
| AC02 | Pendiente | Sin prueba funcional de E. |
| AC03 | Pendiente | Sin prueba funcional de E. |
| AC04 | Pendiente | Sin prueba funcional de E. |
| AC05 | Parcial CI | Contrato puro: 44 casos en fast 41578321181 y cuatro mutaciones locales; faltan integración y recorridos reales. Ver E1.1/E1.15. |
| AC06 | Parcial CI | Contrato puro: 44 casos en fast 41578321181 y cuatro mutaciones locales; faltan integración y recorridos reales. Ver E1.1/E1.15. |
| AC07 | Parcial CI | Comando SQL 29/29 en 41609778146; alcance específico E1.22. Faltan carreras completas, consumidores y prueba integral. |
| AC08 | Pendiente | Sin prueba funcional de E. |
| AC09 | Parcial CI | Contrato puro y capacidades SQL 20/20, 41600939474; rutas legadas y corrección de email todavía sin integrar/verificar. E1.15. |
| AC10 | Pendiente | Sin prueba funcional de E. |
| RP01 | Parcial CI | SQL del comando y carreras en 41614887283 (E1.28); faltan integración, UX y restantes condiciones del caso. |
| RP02 | Parcial CI | SQL del comando y carreras en 41614887283 (E1.28); faltan integración, UX y restantes condiciones del caso. |
| RP03 | Parcial CI | Comando SQL 29/29 en 41609778146; alcance específico E1.22. Faltan carreras completas, consumidores y prueba integral. |
| RP04 | Pendiente | Sin prueba funcional de E. |
| RP05 | Pendiente | Sin prueba funcional de E. |
| RP06 | Pendiente | Sin prueba funcional de E. |
| RP07 | Pendiente | Sin prueba funcional de E. |
| RP08 | Pendiente | Sin prueba funcional de E. |
| RP09 | Parcial CI | SQL del comando y carreras en 41614887283 (E1.28); faltan integración, UX y restantes condiciones del caso. |
| RP10 | Pendiente | Sin prueba funcional de E. |
| RP11 | Pendiente | Sin prueba funcional de E. |
| RP12 | Parcial CI | Comando SQL 29/29 en 41609778146; alcance específico E1.22. Faltan carreras completas, consumidores y prueba integral. |
| RP13 | Pendiente | Sin prueba funcional de E. |
| SN01 | Parcial CI | Comando SQL 29/29 en 41609778146; alcance específico E1.22. Faltan carreras completas, consumidores y prueba integral. |
| SN02 | Parcial CI | Comando SQL 29/29 en 41609778146; alcance específico E1.22. Faltan carreras completas, consumidores y prueba integral. |
| SN03 | Parcial CI | Comando SQL 29/29 en 41609778146; alcance específico E1.22. Faltan carreras completas, consumidores y prueba integral. |
| SN04 | Parcial CI | Comando SQL 29/29 en 41609778146; alcance específico E1.22. Faltan carreras completas, consumidores y prueba integral. |
| SN05 | Parcial CI | Comando SQL 29/29 en 41609778146; alcance específico E1.22. Faltan carreras completas, consumidores y prueba integral. |
| SN06 | Parcial CI | Comando SQL 29/29 en 41609778146; alcance específico E1.22. Faltan carreras completas, consumidores y prueba integral. |
| SN07 | Parcial CI | Comando SQL 29/29 en 41609778146; alcance específico E1.22. Faltan carreras completas, consumidores y prueba integral. |
| SN08 | Pendiente | Sin prueba funcional de E. |
| SN09 | Pendiente | Sin prueba funcional de E. |
| SN10 | Pendiente | Sin prueba funcional de E. |
| SN11 | Parcial CI | Comando SQL 29/29 en 41609778146; alcance específico E1.22. Faltan carreras completas, consumidores y prueba integral. |
| SN12 | Pendiente | Sin prueba funcional de E. |
| SN13 | Parcial CI | SQL del comando y carreras en 41614887283 (E1.28); faltan integración, UX y restantes condiciones del caso. |
| SN14 | Pendiente | Sin prueba funcional de E. |
| SN15 | Pendiente | Sin prueba funcional de E. |
| SN16 | Parcial CI | Comando SQL 29/29 en 41609778146; alcance específico E1.22. Faltan carreras completas, consumidores y prueba integral. |
| SN17 | Parcial CI | Cancelación conserva pago como unresolved en SQL 41600939474; falta comando público/UX/correo y comprobaciones integrales. |
| SN18 | Pendiente | Falta comprobar el comando y recorrido real del personal en E. La cancelación del paciente no acredita ese origen. |
| SN19 | Parcial CI | Actualización real desde cinco estados anteriores, 8/8 en 41600939474; sin aplicación productiva ni UI de historia. |
| RM01 | Pendiente | Sin prueba funcional de E. |
| RM02 | Pendiente | Sin prueba funcional de E. |
| RM03 | Pendiente | Sin prueba funcional de E. |
| RM04 | Pendiente | Sin prueba funcional de E. |
| RM05 | Pendiente | Sin prueba funcional de E. |
| RM06 | Parcial CI | Contrato puro: 44 casos en fast 41578321181 y cuatro mutaciones locales; faltan integración y recorridos reales. Ver E1.1/E1.15. |
| RM07 | Parcial CI | Contrato puro: 44 casos en fast 41578321181 y cuatro mutaciones locales; faltan integración y recorridos reales. Ver E1.1/E1.15. |
| RM08 | Pendiente | Sin prueba funcional de E. |
| RM09 | Parcial CI | Contrato puro: 44 casos en fast 41578321181 y cuatro mutaciones locales; faltan integración y recorridos reales. Ver E1.1/E1.15. |
| RM10 | Pendiente | Sin prueba funcional de E. |
| RM11 | Parcial CI | Contrato puro: 44 casos en fast 41578321181 y cuatro mutaciones locales; faltan integración y recorridos reales. Ver E1.1/E1.15. |
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
| OP01 | Parcial CI | Fallas provocadas de auditoría/evento revierten SQL en 41614887283; falta recuperación de cola/proveedor y UX. |
| OP02 | Pendiente | Sin prueba funcional de E. |
| OP03 | Parcial CI | Contrato puro: 44 casos en fast 41578321181 y cuatro mutaciones locales; faltan integración y recorridos reales. Ver E1.1/E1.15. |
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

### E1.10 — capacidades 20/20 y aislamiento de la falla provocada de historia

- Corrida combinada `41582418674`, fuente `de06da3b28119e46d0242fbac48867b1eb1a9fcf` (main `c31f713`), fallida globalmente. **Sí terminó el archivo de capacidades, 20/20**, incluidas revocación legada, recibo repetido, actor revocado y falla de auditoría. No acredita integración de rutas, email ni cierre de AC09; el código anterior todavía no consume estos RPC.
- El diagnóstico acotado agregado en E1.8 dejó visibles las primeras 19 comprobaciones de fundamentos, todas aprobadas. Después el fixture volvió a registrar un pago, pero el disparador de falla provocado por la prueba 14 seguía instalado. Se elimina ese disparador después de comprobar su reversión, para que no contamine la posterior cancelación con pago. No se elimina la prueba adversaria ni se modifica la lógica productiva por ese error de alcance del fixture.
- Evidencia privada `sql-base-gestion-41582418674.log`: capacidades empieza en línea 897, resultado 20 en 1030; diagnóstico de fundamentos desde 1036 y falla provocada nuevamente desde 1188. Los tres casos finales de fundamentos, la suite posterior y los tipos aún no tienen cierre. Ejecutar la fuente corregida, sin repetir la fallida idéntica.

### E1.11 — diseño de los próximos comandos, todavía por implementar/verificar

- El motor compartido de disponibilidad seguirá en TypeScript. La ruta de cambio debe validar el horario con ese motor y transportar su revisión real de configuración; el RPC mantiene bloqueado el negocio, compara esa revisión, revalida identidad/equipo/duración/anticipación/modalidad y aplica las exclusiones SQL. No duplicar el calculador ni aceptar desde el navegador un turno ajeno que excluir. Exponer una variante del helper que devuelva también la revisión, conservando el contrato actual que devuelve sólo slots.
- Orden a contrastar con carreras: actor/suscripción cuando corresponda, negocio/políticas, identidad de operación, profesionales en orden determinista y turno, después proyección/obligaciones. Los escritores actuales de configuración bloquean primero su fila hija y luego el negocio: no agregar un FOR SHARE de servicio/profesional después de bloquear el negocio, porque podría invertir ese orden. Con el negocio bloqueado, una configuración pendiente no puede confirmar su nueva revisión; leer su versión comprometida y compararla con la que calculó el horario. Verificar ambos órdenes con conexiones controladas.
- La resolución del enlace es sólo lectura. Volver a validar generación/caducidad/revisión después de bloquear el turno y comprobar el reloj SQL al ejecutar; no confiar en el instante de apertura de la pantalla ni en now() de una transacción que haya esperado. La ayuda que caduque durante una espera sigue siendo un caso abierto.
- Para la seña impaga, mover conserva una obligación y su protección previa frente a baja automática. Para una resuelta, cerrar la obligación actual e identificar por separado la disposición del pago y la nueva exigencia. Una acreditación histórica ya conservada no se vuelve a perder por consumir el mismo registro en otra operación.
- **Proyección cuando no hay nueva obligación:** evaluar cerrar la obligación resuelta y retirar sólo la fila de proyección vigente, manteniendo íntegros requisito pagado/eventos/destino en la historia. Así los lectores anteriores siguen viendo «sin seña exigida», en vez de inventar una excepción o mantener un pago perdido como si fuera un anticipo vigente. Probar las cuatro combinaciones y la recuperación antes de adoptar/publicar. La historia no depende por FK de esa proyección, deliberadamente; ningún pago se elimina por retirarla.
- Base de la nueva seña: conservar el importe original fotografiado (base_amount), con tope de cotización válida menos créditos registrados aplicables. Cero significa sin anticipo adicional; un importe desconocido no se trata como cero. Comprobar moneda, números enteros/límites y contrato de cotización existente (`price-contracts.ts` / `resolve_service_price`), sin llamar saldo contable al resultado. Evitar que un tope reducido se convierta en la base de todos los cambios siguientes.
- Condiciones económicas anteriores no informadas siguen sin pérdida/nuevo cargo. Contrastar relajaciones actuales frente a la foto aceptada y política global apagada, sin imponer una condición más onerosa retroactivamente. No resolver la ausencia de configuración comercial de Natalia inventando datos. Estos puntos son diseño pendiente de prueba, no resultados ni nuevas autorizaciones por pedir.

### E1.12 — continuidad tras el nuevo encargo y reasignación por su ruta real

- Juan pidió las tres tareas posteriores, sin mezclar: registradas literal en 12.23 y en su cola propia. La documentación activa ya sustituye D celular por P3 interna y retira los teléfonos como dependencia de D; no se implementó ninguna de P1/P2/P3. E continúa activa. Cambios documentales separados en main `d8cc687`; enlaces locales comprobados y los 97 IDs de E siguen coincidiendo.
- Corrida `41598621193`, fuente `2e9bac7f3b6b54675bd3c169987d5fca58d1b2cb` (código main `80890b9`), globalmente fallida. Capacidades **20/20**, actualización de esquema **8/8** y prefijo de fundamentos **20/22** aprobados; tipos y comprobaciones posteriores aún sin cierre. Evidencia privada `sql-base-gestion-v2-41598621193.log`.
- Falló la prueba 21 al intentar cambiar patient_id directamente: la guardia previa `protect_appointment_identity_fields` lo impide antes de la defensa nueva de pagos. Se corrige el fixture para usar `reassign_appointment_patient_safely`, la operación real ya auditada, y verificar que su rechazo por dinero conserva también la revisión anterior. No se deshabilita la guardia de identidad ni se usa un bypass manual del disparador.
- Próximo paso: snapshot SQL conjunta con ese fixture corregido, recuperar resultado y tipos reproducibles. Después implementar los comandos/cola y continuar E2–E6, no iniciar la cola posterior. Ninguna migración, envío nuevo ni publicación de E en producción todavía.

### E1.13 — fundamentos 22/22 y limpieza del ensayo de carreras

- Corrida `41599560764`, fuente `8bd89b92d46a89023915f23aed5476f9c2693f9f` (main `b9bfe22`): **fundamentos 22/22, capacidades 20/20 y actualización 8/8**. La suite posterior avanzó a carreras. Resultado global fallido: `run_deposit_expiry_concurrency.sh` llegó al escenario 10 y su limpieza falló al borrar directamente el consultorio, porque la historia nueva conserva una referencia al paciente.
- Log privado `sql-base-gestion-v3-41599560764.log`, líneas 4966–4967. No se atribuye cierre a todas las carreras por haber llegado al escenario 10; el stdout positivo del script fallido no estaba recuperado íntegro. La suite global/tipos no tienen cierre todavía.
- Se aplica el mismo orden de limpieza que en el fixture de actualización: eliminar primero los turnos de ese namespace sintético, con guardia por UUID y slug del consultorio propio, y después su consultorio/usuarios. Se conserva la FK que protege la identidad del historial económico; no se cambia a cascada desde paciente para hacer pasar el ensayo. Su destino sigue limitado a la base descartable de loopback.
- Continuar con una snapshot que incluya esa limpieza y verificar suite/carreras/tipos completos. Ningún cambio de producción, proveedor o buzón. Mantener E activa y la cola posterior sin iniciar.

### E1.14 — contrato del resumen económico antes de implementarlo

- Escritas 18 comprobaciones en `appointment_reschedule_financial_terms.sql`, todavía sin corrida roja ni implementación del helper nuevo. Cubre las cuatro combinaciones, impaga única, excepción sin dinero, reserva no informada, tope/cero/quote desconocida, base original, crédito histórico no consumido dos veces, último momento/protección anterior, operación sin cambio/lectura sin escrituras, pausa operativa, condiciones relajadas, cotización malformada y ACL.
- Se usan snapshots de precio producidos por el disparador existente; una escritura UPDATE de price_quote_snapshot sería sobrescrita por esa guardia y daría un fixture falso. El crédito anterior extra es un dato sintético separado, no una operación real ni una prueba de que el comando ya existe.
- **Pausa general no es condonación:** para turnos con consecuencias económicas, un interruptor técnico apagado debe devolver reprogramación no disponible y conservar el original; no aprovechar la pausa para regalar una nueva seña, forzar un crédito ni aplicar una pérdida. Una política relajada por el consultorio es otro caso, explícito. El comando y UX deberán probarlo; todavía es contrato pendiente.
- Primero recuperar fundamentos v4, fuente `a06715572239118146e4e95bc5a416b7a5ebcb9b`, rama `verify/etapa-e-base-gestion-v4-20261103`; esa fuente no incluye este contrato financiero. Después demostrar roja del helper económico ausente y seguir su implementación/los comandos. No cerrar E1 con el resumen readonly ni iniciar P1/P2/P3.

### E1.15 — fundamentos SQL completos aprobados y tipos oficiales recuperados

- **SQL aprobado:** corrida `41600939474`, fuente exacta `a06715572239118146e4e95bc5a416b7a5ebcb9b` (main de código `d64e5fb`). Se leyó recibo `type-generation.json`: `ok=true`, `sqlVerified=true`, tipo `sql-and-types-generation-only`. Archivo de fundamentos 22/22, capacidades 20/20 y actualización 8/8; archivo de log completo con **684 aserciones pgTAP y 15 scripts de carreras**, sin not ok/Bail out/ERROR. Esto comprueba esos fundamentos y regresiones, no los comandos de reprogramación nuevos ni E completa.
- Archivo privado `sql-base-gestion-v4-41600939474.zip`; colección `sql-base-gestion-v4-evidence`, cuatro recibos, SHA-256 `055175c45737633fc4aac8df4f048f3be08c578ce3f05fa7a33ec985a36dc546`. Se conservan las corridas fallidas anteriores con sus causas; no se transforman en éxitos.
- Tipos públicos importados desde la doble generación oficial de CI, sin escribirlos a mano. SHA-256 `068fa889132f0a3830842d6bc9e592049dab038fa055e6c56b97540bafd673bf`; digest de migraciones `70524866fe0ff56c5dcd8990f56ec37b97db6c3e9e4f79f2759bb80b4ead4547`, comparado con todas las migraciones locales antes de escribir `database.types.ts`. Diff: 243 líneas añadidas, sin borrados. Una migración posterior requiere su propio recibo, aunque el esquema público no cambie.
- Roja económica solicitada `41601472826`, fuente `785961791a4dcd1b44cb932103387291c2cdc83b` (main `81a901b`), rama `verify/etapa-e-economia-roja-20261103`. Recuperar su conclusión/error antes de implementar el helper. Fuente anterior a la importación de tipos, con las mismas dos migraciones E1; su SQL no exige comparar el archivo TS antiguo.
- **Riesgos a comprobar al integrar (sin tratarlos como defectos reproducidos):** emisión de capacidades no puede renovarse desde un token legado revocado; revisión del alta pública idempotente después de una reasignación (EM11/EM12), para que el cliente anterior no recupere una identidad o token nuevos; nuevas altas de push/Calendar desde enlaces legados revocados frente a vínculos legítimos existentes (AC09/UI08). Leer los retornos y endpoints reales antes de decidir sus cambios; no copiar una suposición de formato o permisos.
- Sin rutas/plantillas/colas nuevas conectadas, sin SQL de E aplicado, sin correo nuevo/proveedor/buzón ni publicación. Las filas de la matriz siguen parciales/pendientes; continuar E1–E6 y luego la cola posterior separada.

### E1.16 — roja económica e implementación readonly inicial

- **Roja comprobada:** `41601472826`, fuente `785961791a4dcd1b44cb932103387291c2cdc83b`, falta `private.appointment_reschedule_financial_terms(uuid,uuid,timestamptz,timestamptz)` al crear el helper. Log privado `sql-economia-roja-41601472826.log`, línea 1270. Las 18 comprobaciones económicas no se ejecutaron; no confundir el fallo estructural con una roja de cálculo ya observada.
- Se escribe `20261103030000_appointment_reschedule_financial_terms.sql`: validación del arancel fotografiado sin recotizarlo, resumen con las cuatro combinaciones, protección de reservas no informadas/obligación impaga, conservación de crédito histórico, base original, tope explícito, cambio nulo y pausa operativa. Las funciones son privadas y readonly; el movimiento real/dinero/eventos todavía no existen como comando nuevo.
- Decisión de contrato: los importes del resumen se serializan como enteros decimales en texto, para conservar precisión incluso en créditos acumulados superiores al entero seguro de JavaScript. Consumidores usarán BigInt para validar/formatear, sin calcular la política en el navegador. Fechas UTC canónicas conservan microsegundos al reenviar las condiciones vistas. Se ajustan las expectativas del contrato antes de su primer verde; no cambia una regla comercial ni el tipo actual de la proyección de seña.
- El resumen separa estado/importe/asignación actuales de importe previamente aplicable, destino propuesto y crédito total. Una pausa técnica produce `unavailable` sin mover ni condonar; la política relajada por el consultorio sí se respeta. No usar ese diagnóstico técnico como texto para pacientes. Falta probar el comando/UX que consume esos resultados.
- Siguiente paso: CI SQL de la fuente nueva con las tres migraciones y contrato económico; conservar resultado, revisar negativas, obtener recibo de tipos con nuevo digest y después seguir operaciones idempotentes/cola/E2–E6. No aplicar en producción ni afirmar integración por este helper.
- Se amplía a **19 comprobaciones** antes del primer verde: la consulta inicial del turno y el resumen de un horario elegido comparten disponibilidad económica. Al leer el horario actual, el helper conserva `kind=unchanged` y a la vez informa una pausa/impedimento; así la pantalla puede omitir REPROGRAMAR sin simular otra fecha ni duplicar esa política. Nueva verificación `E1_INITIAL_FINANCIAL_READINESS_INCOHERENT`; no es integración de UI todavía.


### E1.17 — resumen económico verificado, sin integración todavía

- **SQL aprobado:** `41605022654`, fuente `4a528506b83ebed5a61192ac8d3821896a7785c2`, código main `f722076`. Contrato económico 19/19 y suite completa con 703 aserciones pgTAP. Recibo `type-generation.json`: `ok=true`, `sqlVerified=true`, `kind=sql-and-types-generation-only`. La fuente anterior `e8dcc159…` se preparó pero no se ejecutó; no atribuirle esta evidencia.
- Archivo privado `sql-economia-v2-41605022654.zip`, colección `sql-economia-v2-evidence`, SHA-256 `ce43934347d923fc4c2dce92d3be26588c0243a13c7364032a7a52b962fedbfd`. Tipos oficiales reproducibles y byte por byte iguales al archivo local, SHA-256 `068fa889132f0a3830842d6bc9e592049dab038fa055e6c56b97540bafd673bf`; digest de las tres migraciones E junto con todas las anteriores `9d1bc44d077eb6f996feb61cab06e601606232cb716e887682430c2411e86289`, cotejado antes de afirmar correspondencia. No hizo falta reescribir tipos sin cambios.
- Los cuatro resultados económicos, crédito anterior, tope/importe desconocido y diagnóstico inicial están comprobados sólo como lectura SQL. Faltan operación atómica, carreras nuevas y consumidores/UX. No se marca cerrado ningún caso por este verde. Producción, proveedor y buzón permanecen sin cambios de E.


### E1.18 — contrato de comandos reales, previo a implementación

- `patient_appointment_management_commands.sql`: 24 grupos de comprobación para cambio/cancelación/confirmación del paciente. Exige las cuatro combinaciones económicas, obligación impaga única, operación nula, recuperación idempotente y conflicto de identidad de operación, revisión vieja, condiciones manipuladas, configuración vieja, cancelación con dinero por resolver y evento único, rechazo de resurrección, permiso mínimo con reserva pública apagada/archivo, falla de auditoría con reversión completa, revocación previa a replay, pago pendiente, turno iniciado, pausas y dos movimientos pagados con versiones de horario separadas de los pagos.
- El contrato aún no fue ejecutado. La primera función de prueba referencia el comando ausente para que la roja demuestre ese contrato faltante antes de sus fixtures. Todavía no hay implementación de comando/eventos ni se atribuyen estas pruebas a la suite económica anterior. Solicitar una snapshot SQL roja; después escribir la migración y carreras controladas.


### E1.19 — roja del comando y primera implementación transaccional

- **Roja comprobada** `41607071313`, fuente `66ac2186a9f1f62dca5b22341fd311b9c993a069`, main `7a2ae9d`: falta `public.apply_patient_appointment_management(text,boolean,uuid,text,text,timestamptz,bigint,jsonb)`. Log privado `sql-comandos-roja-41607071313.log`, línea 3207. No se ejecutaron los 24 grupos del contrato. Tras esta roja, el wrapper de prueba restablece el JWT interno durante cada llamada para simular la identidad nula del backend/paciente, con restitución incluso al fallar; no desactiva guardias de negocio.
- Migración `20261103040000`: comandos de paciente, recibos idempotentes, revisión/credencial revalidadas tras bloquear, resumen financiero contrastado, proyección compatible e historia por operación, auditoría/transacción, eventos mínimos de correo y revisión de horario separada de pagos. Interruptores nuevos de reprogramación/productor apagados al instalar; todavía sin consumidores/rutas ni aplicación productiva. No modifica por adelantado P1/P2/P3.
- La baja con enlace válido conserva el permiso mínimo aun con reserva pública apagada o archivo; no abre búsqueda/reserva/reprogramación. Un replay exige autorización vigente antes de devolver recibo, pero no repite efectos ni vuelve a exigir que la cita siga en su estado previo.
- Se conservan bloqueos profesionales ordenados antes del turno y el orden política→turno→proyección. Los registros de configuración no se bloquean después del negocio; se comprueba su revisión comprometida. Se amplía esa revisión a excepciones, sus prestaciones restringidas e integraciones para no aceptar una selección anterior a cambios de modalidad/horarios. Esta defensa nueva aún requiere suite y carreras.
- Cuando no hay nueva obligación, se retira sólo la proyección actual, preservando historia/destino del dinero. Si se vuelve a crear una obligación, su revisión empieza después del máximo histórico: impide que un formulario viejo coincida con el 1 de otro ciclo. Falta prueba adversaria específica de este último caso.
- Helper TypeScript `getAvailabilitySelection`: transporta revisión/duración del catálogo que calculó slots; la API anterior conserva su array y consultas. Roja local: 2 fallos por helper ausente y 13 casos anteriores aprobados (`disponibilidad-revision-roja.log`). Verde dirigido: 19/19 con ventanas (`disponibilidad-revision-verde.log`), un trabajador y 512 MiB; no es prueba del consumidor público ni de SQL.
- Siguiente: comprobar SQL conjunto y tipos de cuatro migraciones E; corregir por evidencia. Añadir carreras controladas y casos de configuración/equipo, proyección recreada y fallas de eventos. No cerrar E1 ni saltar a las tareas posteriores.


### E1.20 — preservar el contrato existente de ventanas y separar la revisión de guardado

- Corrida `41608026890`, fuente `25556a6f9be89703c73e61ae41b31e525b7fe185`, main `d4ed909`, **fallida** antes del comando nuevo. Log `sql-comandos-41608026890.log`, línea 1618: `AVAILABILITY_CONFIGURATION_CHANGED` en `availability_windows.sql`. La prueba existente exige expresamente que ocupaciones/excepciones fechadas no invaliden la revisión de configuración; la ampliación inicial de E1.19 la cambió por error. No se cambia esa aserción para obtener verde.
- Corrección: conservar íntegra esa revisión y transportar además `businesses.booking_availability_revision`, que ya cubre excepciones y prestaciones restringidas, desde la misma fotografía del catálogo. Sólo se agrega a esa revisión amplia la edición de integraciones/modalidad. El comando compara esa revisión de guardado bajo bloqueo del negocio. No buscar una versión nueva después de calcular slots con otra anterior. No se atribuye verde del comando a esta corrección todavía.
- El parser acepta la ausencia del campo adicional de la versión anterior para los lectores existentes; un consumidor nuevo debe exigir una revisión de guardado real. Si aparece, se valida como entero seguro positivo. Selección transporta las dos revisiones con nombres distintos; no sustituye una por otra ni inventa una cuando no leyó el catálogo.
- Contrato del comando ampliado antes de su primer verde a 29 grupos: incluye formulario de pago viejo después de quitar/recrear proyección, reserva no informada, origen de personal falsificado, revisiones separadas y falla provocada del evento de correo. La corrida fallida anterior tenía 24, no estas ampliaciones. Corregida además la expresión de horizonte con minutos absolutos y zona explícita, sin depender de la zona de sesión SQL.
- Próximo: SQL conjunto de la corrección, tipos públicos oficiales y carreras. Producción continúa en V12b, sin migraciones E aplicadas ni correos nuevos.


### E1.21 — revisión propia de integración y carreras del comando

- Corrida `41608751121`, fuente `d85ab3f14044d0091405e0f9417737aa8fe57989`, main `e345411`, **fallida**. La suite de ventanas vuelve a aprobar 30/30, pero `booking_integration_foundation.sql` falla por `BOOKING_AVAILABILITY_CHANGED` tras activar una integración; log `sql-comandos-v2-41608751121.log`, línea 1811. El contrato de alta ya valida separadamente integración y disponibilidad. La ampliación de la revisión amplia a integraciones alteraba ese contrato; se retira, sin cambiar el fixture existente para ocultar la regresión.
- Corrección: conservar las revisiones originales de catálogo, reserva e integración. El comando nuevo recibe como condición adicional la revisión de integración de la que obtuvo modalidad/ventanas, derivada por servidor; la compara y bloquea la integración sin espera bajo el negocio. NOWAIT evita introducir una espera inversa frente a caminos legados integración→negocio; un conflicto pide volver a leer, no mueve ni penaliza. La revisión de reserva adicional en el catálogo conserva su función para horarios/excepciones. Todavía pendiente de comprobar en SQL.
- Diez carreras nuevas escritas en `run_patient_management_concurrency.sh`: comando repetido, cambio/cancelación en ambos órdenes, pago/cambio en ambos órdenes, vencimiento/cambio en ambos órdenes, configuración/cambio en ambos órdenes y dos turnos por un horario. Cada espera se demuestra con pg_blocking_pids; el caso SKIP LOCKED exige que el worker termine mientras el movimiento sigue abierto. Estado posterior y contador de deadlocks son condiciones, no sólo éxito de psql. Destino exclusivamente loopback, namespace propio, restauración de interruptores y limpieza turno antes de paciente/consultorio.
- **Hipótesis pendiente de reproducir:** FOR SHARE sobre la fila de `deposit_automation` en el comando puede detener el heartbeat del worker antes de su SKIP LOCKED, porque ese heartbeat actualiza la misma fila. La nueva carrera inversa está escrita para detectarlo. No se declara probado ni se corrige antes de recibir su resultado; si se confirma, separar sincronización de la configuración respecto de la escritura de heartbeat.
- Local dirigido de revisiones/parser **27/27** ejecutado en secuencia con un trabajador/512 MiB; conservar resultado en `disponibilidad-dos-revisiones-verde.log`. No sustituye SQL, carreras ni integración del sitio. Próximo: snapshot SQL v3 con corrección y diez carreras.


### E1.22 — comando 29/29 y corrección de identidad en el escenario de carrera

- Corrida `41609778146`, fuente `db832ad5210e5a64c986a7b6eef69c37f7063870`, main `16b52c9`, globalmente **fallida**. El archivo `patient_appointment_management_commands.sql` sí terminó: **29/29**, secuencia exacta cotejada en el log, incluidas reversión por auditoría/evento, proyección recreada, dinero de las cuatro combinaciones, credenciales y cancelación mínima. No se atribuye a esta fuente entrega de correo, rutas ni tipos completos.
- Log `sql-comandos-v3-41609778146.log`, desde 3200 el contrato, desde 5424 las carreras nuevas. Falló `cancel_before_move`: la segunda llamada reutilizaba la misma identidad de operación para otra acción, por lo que respondió correctamente `APPOINTMENT_OPERATION_CONFLICT`; el escenario esperaba conflicto por revisión. Se le asigna una operación distinta, como exige ese escenario. No se afloja el recibo ni la comparación del comando.
- La corrida no llegó a las otras carreras nuevas ni a la hipótesis de heartbeat de E1.21; sigue pendiente su reproducción. Próximo: SQL v4 con sólo ese escenario corregido y recuperar el resultado completo. Mantener la prueba del worker que debe poder saltear un turno ocupado.
- Contrato puro `reschedule-terms.ts` para consumidores futuros: preserva importes decimales exactos y microsegundos, valida el DTO completo sin recotizar, distingue arancel desconocido y evita números JS al formatear créditos grandes. Roja estructural por módulo ausente (`contrato-economico-ui-roja.log`), **20/20 locales** después (`contrato-economico-ui-verde.log`), un trabajador/512 MiB. No es prueba de una pantalla ni de que el servidor ya lo transporte.


### E1.23 — entrada documental del contrato parcial y corrida en curso

- SQL v4 solicitado `41610641502`, fuente `d767f2154a45c56710eb8d6ca957068813180137`, código main `7e26e34`. Recuperar esa corrida antes de reemplazarla. Es posterior a la corrección del fixture; todavía no se atribuye éxito global ni prueba de la hipótesis de heartbeat.
- Contratos funcionales/permisos generales distinguen el código E1 local de A/B/C en producción, y remiten a la evidencia parcial. Se corrige SN18 en la matriz: cancelar como paciente no prueba cancelar como personal; ese recorrido sigue pendiente. No se cambia el texto histórico aprobado ni se cierra una tarea de la cola posterior.


### E1.24 — corrida de carreras detenida por falta de terminación; diagnóstico acotado

- `41610641502`, fuente `d767f2154a45c56710eb8d6ca957068813180137`: **cancelada por el agente**, no aprobada ni falla global concluida por sí sola. Verify empezó 09:25:03 UTC; tras más de ocho minutos se pidió detenerla y terminó 09:35:07 UTC. Log recuperado de job `125831370641`: `sql-comandos-v4-job.log`. SQL llegó otra vez al comando 29/29 y los scripts anteriores a `run_patient_management_concurrency.sh` terminaron; último encabezado previo, `run_patient_identity_idempotency_concurrency.sh`, a las 09:25:48. La salida del script nuevo estaba retenida por spawnSync y no se recuperó su escenario exacto. No inventar la causa ni declarar demostrada la hipótesis de heartbeat por esta demora.
- Se agregan límites de 7 s de espera de bloqueo y 12 s por sentencia a **todas** las conexiones del script nuevo, incluidas preparación y limpieza; algunas ya tenían límites locales pero esas otras no. El arnés limita cada script de carreras a 120 s y conserva stdout/diagnóstico acotados también si falla o vence. Sólo base propia descartable. Así un ensayo bloqueado no consume indefinidamente la corrida ni oculta el punto de fallo.
- `bash -n` del script y `node --check` del arnés pasan; no son prueba de concurrencia. Próximo: SQL v5 del mismo comando con límites/diagnóstico, recuperar su error o evidencia completa antes de cambiar lógica. La cancelación no acredita ni refuta el supuesto concreto de la fila de heartbeat. Producción intacta.


### E1.25 — nueve carreras demostradas; atasco pendiente de localizar

- SQL v5 `41612394332`, fuente `30872c37223673af18fd810592e02f21ba943c9b`, main `cfa23b2`, **fallido** por el límite externo de 120 s. Log `sql-comandos-v5-41612394332.log`, diagnóstico desde línea 5425. Nueve escenarios tienen PASS con espera real comprobada y estado posterior: repetido, cambio/cancelación ambos órdenes, pago/cambio ambos órdenes, vencimiento primero, configuración/cambio ambos órdenes y destino ocupado. El script no terminó ni llegó a acreditar su contador final de deadlocks. No es aprobación global ni tipos verificados.
- El atasco ocurre después del escenario de destino ocupado y antes de terminar vencimiento posterior al cambio. Las conexiones ya tenían límites; no aparece todavía un error de heartbeat ni el paso exacto. Se instrumentan preparación, marcador del holder, inicio/retorno del worker, señal, retorno del holder y limpieza. No se modifica el comando suponiendo una causa no demostrada.
- **Continuidad de auditoría para después de resolver las carreras, sin implementación ni prueba todavía:** (a) evento de email debe capturar también generación de gestión/contacto para que una reasignación/corrección no herede un evento anterior; revisar clave de unicidad para comprobante vigente solicitado al nuevo contacto; (b) comprobar SEQUENCE de ICS al cancelar, no sólo al mover; (c) probar recuperación de alta idempotente pública después de reasignación para que no devuelva identidad/token actuales a quien creó otra identidad; (d) ayuda/suscripción que vencen mientras una operación espera y lectura mínima de gestión de una sola fotografía. Estos puntos son requisitos/hipótesis de integración, no errores productivos reproducidos ni nueva política comercial.


### E1.26 — reproducción local de diagnóstico recursivo y localización del atasco

- SQL v6 `41613292672`, fuente `7496ed91b36886f293853d328c105e4de5e89102`, main `e41052f`, **fallido** por 120 s. Log `sql-comandos-v6-41613292672.log`, desde 5466: preparación y marcador del holder terminaron, llegó a «worker begins while holder is open» y no informó retorno ni limpieza. Nueve escenarios previos siguen comprobados en esa fuente; no se demuestra aún un error concreto del heartbeat ni cierre global.
- **Defecto del arnés reproducido localmente sin PostgreSQL:** función shell con un proceso fallido y ERR heredado dentro de descriptores redirigidos envía el diagnóstico al propio log; cat intenta leer/escribir ese mismo archivo y Bash informa `pop_var_context`. Control con proceso directo conserva stderr del llamador y el log redirigido vacío. Recibo con las dos fuentes y resultados: `diagnostico-err-trap-shell.json`. No se atribuye esta simulación a una prueba de base.
- Corrección del script: array de comando psql y límites exportados, sin envoltorio funcional intermedio. El PID guardado del holder corresponde al cliente real; terminarlo cierra su conexión. No se cambian el comando SQL ni las expectativas de la carrera para obtener verde. Solicitar SQL v7 de este arnés y conservar el error original/resultados antes de corregir una hipótesis de lógica SQL.


### E1.27 — defecto de heartbeat reproducido y sincronización separada

- SQL v7 `41614171946`, fuente `1d83a404146de6e7be7101594d7eb817f07c4b73`, main `1a4637a`, **fallido** con diagnóstico original y limpieza completa. Log `sql-comandos-v7-41614171946.log`, líneas 5465–5484: worker iniciado con movimiento abierto, `canceling statement due to statement timeout`, al actualizar la fila de `deposit_automation`. Las nueve carreras anteriores tienen PASS y el escenario termina con estado 3 y limpieza comprobada. Esto confirma ahora la hipótesis de E1.21; las demoras anteriores, por sí solas, no la habían probado.
- Causa: el comando tomaba FOR SHARE sobre la fila que contiene tanto enabled como timestamps del worker. El UPDATE de heartbeat quedaba bloqueado antes de llegar al SELECT de candidatos con SKIP LOCKED. Corrección: bloqueo asesor transaccional compartido para el comando y exclusivo **sólo** al cambiar enabled mediante disparador. Los cambios de heartbeat no participan de esa llave. No se deja sin sincronizar la pausa operativa ni se cambia la regla de vencimiento. Función privada sin permisos API.
- Se añaden dos carreras para comprobar pausa→cambio y cambio→pausa, además de repetir la inversa que detectó el defecto. El script tendrá **doce** escenarios y exige no incrementar deadlocks. Son pruebas nuevas pendientes, no resultados de v7.
- Se contrastaron semántica/alcance transaccional y modos compartido/exclusivo con [bloqueos de PostgreSQL 17](https://www.postgresql.org/docs/17/explicit-locking.html#ADVISORY-LOCKS) y [funciones oficiales](https://www.postgresql.org/docs/17/functions-admin.html#FUNCTIONS-ADVISORY-LOCKS). La documentación no prueba nuestra implementación: recuperar SQL v8 conjunto, tipo generado con nuevo digest y doce carreras reales antes de cerrar esta corrección.


### E1.28 — suite completa del comando y corrección de heartbeat aprobadas

- **SQL aprobado** `41614887283`, fuente `894a674fff4b01e10c95650b09f5c65de4b55540`, código main `863e759`. Se cotejaron recibo `type-generation.json` (`ok=true`, `sqlVerified=true`, `kind=sql-and-types-generation-only`), 732 aserciones pgTAP, los 16 encabezados de scripts de concurrencia, 29/29 del comando y las **doce** carreras nuevas con contador de deadlocks sin aumento. La carrera de heartbeat que fallaba ahora termina, y las dos carreras de pausa confirman que no se eliminó su sincronización para obtener verde. No acredita la app/proveedor/buzón ni el contrato posterior de 33 grupos.
- Archivo privado `sql-comandos-v8-41614887283.zip`, colección `sql-comandos-v8-evidence`, SHA-256 `c81fa900c2dd15477830ef09d6f44edb00b3635667071a03986786cb1b4db037`. Tipos oficiales, dos generaciones iguales, SHA-256 `53fe51b08b18bc5b4c801277ef155671fff692b85f568d513afce35382d10ab0`, digest de todas las migraciones `d0ce8de7a2fb227f50e579f6837cf929ab00478badd618bff3dcabfd7a0a7aae` cotejado antes de importarlos. Diff de tipos: 17 líneas añadidas, sin borrados (schedule_revision y comando de nueve parámetros).
- Contrato posterior ampliado **a 33 grupos**, antes de implementar esos hallazgos de auditoría: SEQUENCE al cancelar conservando token, generación original del evento al reasignar, no heredar aceptación económica y no trasladar la obligación impaga a otra persona. Se usa la reasignación controlada real y aserciones que fallan también ante un campo ausente, sin cortar por falta de columna antes de comprobar los otros casos. Falta roja concreta; no atribuirlos al verde de 29.
- Próximo: corrida roja de esos cuatro casos, corregir por evidencia y verificar de nuevo. Luego lectura mínima/operación del personal/incidentes/cola y E2–E6; no cerrar E1 ni iniciar P1/P2/P3 con este fundamento aprobado. Sin migraciones E en producción y sin correo nuevo.


### E1.29 — cuatro fallas de identidad/calendario reproducidas y corrección inicial

- **Roja de comportamiento comprobada** `41615584129`, fuente `4a2f6291633aca8144d656a2c619b8ef6d06ea2f`, main `01a04dd`: primeros 29 grupos aprobados, **30–33 fallidos por aserción**, no por compilación/infraestructura. Log `sql-identidad-calendario-roja-41615584129.log`, líneas 3498–3533: SEQUENCE sin avanzar al cancelar, evento sin generación del destinatario, aceptación económica heredada y obligación impaga heredada al reasignar.
- Corrección inicial: cancelar aumenta SEQUENCE sin rotar token/UID. Cada evento captura la generación vigente y su unicidad la incluye; la identidad original de un evento no se cambia al corregir destinatario. Los futuros consumidores deben contrastarla, no sólo el horario.
- La reasignación real sigue rechazando cualquier dinero registrado. Sin pagos, cierra la obligación actual anterior, retira su proyección y deja la historia de la persona original con un evento de cierre, sin inventar excepción/cobro. Borra la aceptación económica de esa identidad en el estado actual. Las búsquedas de base/crédito/impedimentos del resumen y del comando se limitan al paciente actual, para que esa historia anterior no condicione ni informe a la persona nueva.
- Se modifican únicamente migraciones E **nunca aplicadas en producción** (.010/.030/.040); cambia su digest y se exige nueva suite/tipos. Las migraciones anteriores aplicadas siguen intactas. La evidencia v8 describe su fuente anterior, no estas correcciones. No se rompe una FK ni se borra historia para evitar una falla de fixture.
- Contrato ampliado a **35** antes del primer verde: lectura económica de persona nueva con historia anterior y evento de cancelación nueva generación sin retaggear el comprobante anterior. El usuario final no ve estos identificadores técnicos. Falta comprobar la implementación y la integración de destinatarios/enlaces; no cerrar EM11 por estas pruebas SQL.
- Próximo: SQL conjunto, doce carreras, digest/tipos. Después comprobar recuperación pública idempotente tras reasignar, lectura mínima de una fotografía, comandos de personal/ayuda que vence, incidentes y cola; continuar E2–E6. La baja por corrección de email es distinta de reasignar paciente: preservar calendarios legítimos y no extender por inferencia la rotación de token que ya hace la reasignación controlada.


### E1.30 — identidad/calendario 35/35 y suite completa aprobados

- **SQL aprobado** `41616550006`, fuente `0ed587dfa772a46d1abf85c6e22f4eb9042424f6`, main de código `1c6666a`. Recibo ok/sqlVerified, **738 aserciones pgTAP**, 16 scripts de concurrencia y doce carreras del comando con contador de deadlocks sin aumento. Se cotejó la secuencia exacta 1–35 del archivo; los cuatro fallos de la roja y las dos ampliaciones ahora pasan. No es cierre de destinatarios/ICS en UI ni de EM11 integral.
- Archivo `sql-identidad-calendario-41616550006.zip`, colección `sql-identidad-calendario-evidence`, SHA-256 `5d9422e35861badaa36c487034928f7dfcc55b7546ffe23646a5be110f3c3c42`. Tipos públicos reproducibles e idénticos byte por byte al archivo local, SHA-256 `53fe51b08b18bc5b4c801277ef155671fff692b85f568d513afce35382d10ab0`; nuevo digest de migraciones `be4ef82c4404e6b1da3b7c03ffe802f3f806f13747aa21e19ce78787875f9163`, cotejado. No se reescriben tipos idénticos ni se atribuye el recibo a otra migración futura.
- Continúa E1. Falta consumidor que descarte eventos de otra generación, gestión/revocación en todas las rutas, corrección de email, recuperación de alta después de reasignar, lectura mínima, personal/incidentes y cola. Ninguna migración E en producción y ningún envío nuevo.

### E1.31 — contrato de lectura del paciente antes de implementarlo

- `patient_appointment_management_view.sql`: 16 grupos escritos, **sin ejecutar todavía**. Exigen identidad/revisión/opciones/condiciones coherentes en una lectura, no notas/contacto privado/intake, abrir/previsualizar sin nueva capacidad o escritura, preferencias email independientes, excepciones mínimas con reserva apagada/archivo, pausas, servicio retirado/duración vigente, seña pendiente, cancelado/dinero a resolver, turno iniciado, revocación y ACL backend.
- La primera función de prueba referencia la API ausente para demostrar su roja antes de escribirla. El DTO es explícito; no serializar la fila completa de appointments/patients. Capacidad/generación/datos deben usar una misma fotografía SQL. Revisar la estabilidad de `resolve_appointment_management_access`, que sólo lee, para reutilizar su autoridad sin copiarla ni emitir una nueva credencial en GET. La mutación conserva revalidación después de bloquear.
- Al integrar, distinguir canal legado de capacidad nueva: ambos tokens son 64-hex y no se infiere autoridad de su apariencia. Calendario conserva su identificador limitado; un enlace legado revocado no obtiene otra capacidad ni vuelve a mutar por una ruta secundaria. Componentes/plantillas consumirán el contexto común, sin duplicar la página ni la regla económica. No hay UI nueva todavía.


### E1.32 — roja de lectura e implementación de fotografía única

- **Roja comprobada** `41617669734`, fuente `47c2c4f9798bc3f9c6d39071902cd43fd5f20f31`, main `c396f5c`: falta `public.get_patient_appointment_management_view(text,boolean,timestamptz)` al compilar la primera función de prueba. Log `sql-lectura-roja-41617669734.log`, línea 3551; no alcanzó sus 16 grupos. El comando anterior de 35 sí avanzó; no atribuir ejecución al contrato de lectura ausente.
- Migración `20261103050000`: resolución pura privada con reloj explícito y fotografía mínima privada STABLE, unidas en una sola consulta del getter backend. La resolución pública del comando sigue VOLATILE y toma clock_timestamp en cada llamada después de esperar; no se la etiqueta STABLE con un reloj que cambia. Se conserva su firma/grant restringido y se reutiliza la autoridad, sin otra copia ni emisión de credenciales en GET.
- Proyección explícita, sin notas internas, contacto privado del paciente, intake ni actores. Estado/opciones/condiciones/dinero comparten fotografía; seña por resolver al cancelar, sin nuevo pedido para turnos iniciados, sin el domicilio presencial en modalidad video. La lista pública de acciones no se confunde con flags de email. El parser/UI que consuma este DTO todavía falta.
- Se extrae en la migración .040 no aplicada la preparación general de reprogramación a `private.appointment_reschedule_scope`, consumida por lectura y comando: negocio, servicio, equipo, paciente, modalidad y pausa. Condiciones específicas del horario/versiones/bloqueos siguen en el comando; el motor de slots TypeScript no se duplica. Este refactor posterior necesita su nueva suite; el verde anterior acredita su fuente anterior.
- Carrera nueva `run_patient_management_view_concurrency.sh`: puerta de prueba después de resolver autorización, movimiento real mientras la lectura espera y comprobación de una vista vieja coherente, seguida de otra completamente nueva. Modifica/restaura sólo la función privada del fixture descartable, con reloj explícito, tiempos acotados, cliente psql directo y restauración del mismo objeto/grants originales. Todavía sin ejecutar.
- Fundamento contrastado en [volatilidad y MVCC de PostgreSQL 17](https://www.postgresql.org/docs/17/xfunc-volatility.html): los helpers STABLE heredan la fotografía de su consulta y una función VOLATILE puede iniciar nuevas fotografías. No es por sí mismo prueba de nuestro getter; recuperar 16 grupos, carrera real, resto de SQL y tipos de cinco migraciones antes de cerrar esta pieza.


### E1.33 — lectura coherente y regla compartida aprobadas

- Suite SQL completa **41650084150**, fuente exacta `64cb1c378511001cdeea3a47e628c398eb8055d0`, main de código `2184ed7`. **754 aserciones pgTAP y 17 scripts de carreras**, sin errores: lectura 16 grupos, comandos 35 y doce carreras conservados. La carrera nueva demuestra lectura previa coherente de autorización/horario/dinero durante un movimiento real, seguida de lectura completamente nueva. No equivale a prueba de la app ni del proveedor.
- Recibo `type-generation.json`: ok/sqlVerified verdaderos, `sql-and-types-generation-only`. Evidencia privada `sql-lectura-41650084150.zip`, colección `sql-lectura-evidence`, SHA-256 `e7f5708c138196faf0b4f52da66bfc2887b298af9f9b5b5e3866401fe07fceca`; log extraído `sql-lectura-41650084150.log`.
- Dos generaciones oficiales iguales, SHA-256 `5e48632df86fc9342ba03361f58921d1f6ec23a22fb26959115b229778513dbb`, digest de todas las migraciones `c8c0d41c0945df10b9346ddf08605381e7859f4f2ce3fed88c54d3e1d9e93bd5` cotejado antes de importar tipos. Se añade la firma del getter; no se escriben tipos a mano.
- Próximo: adaptador mínimo validado, autogestión y cierre de brechas E1 (personal/identidad/roles/cola). Ninguna migración E aplicada en producción ni correo nuevo enviado. La producción V12b sigue intacta.


### E1.34 — prueba adversaria de recuperación tras reasignar, previa a corrección

- Lectura estática del creador: la rama de repetición compara la huella original y devuelve la ficha/token **actuales**. La reparación cambia ficha/token y conserva huella/key; hipótesis de exposición del reemplazo a quien conserva la solicitud original. No se declara reproducida hasta obtener la roja.
- Se amplía el fixture real `appointment_patient_reassignment.sql`: tras reparar por RPC, repetir la solicitud pública y manual en modo normal y sólo-recuperación debe dar conflicto sin otra reserva ni revelar la nueva identidad. Mantener procedencia y clave reservada; no borrar la huella ni crear otra reserva como corrección.
- Próximo: CI roja y revisión del adaptador de presentación mientras se recupera. Sin cambio de la función de producción ni migración nueva todavía.


### E1.35 — reasignación reproducida, corrección inicial y adaptador

- Roja de comportamiento `41651423223`, fuente `7d93f77dc20a89186e69fca8a45ae61eb2312b6a`, main `16c9ffe`: `TEST_REASSIGNED_PUBLIC_REPLAY_DISCLOSED_REPLACEMENT`, log privado `sql-identidad-replay-roja-41651423223.log:1455`. No fue un error de compilación. La rama original devolvía la identidad actual después de reparar el turno.
- Migración .060 nueva: mismo contrato del creador y revalidación del actor; antes de devolver, bloquear padre y verificar que no se reasignó ni cambió la identidad/token leídos. Mantener key/huella originales reservadas e inmutables; rechazo controlado, sin exposición ni otra reserva. Pendiente suite, incluida compatibilidad de repeticiones normales.
- Adaptador `patient-management.ts`, sin integrar a rutas: DTO explícito validado, reloj SQL, importes exactos, sin datos privados inesperados, URLs sanitizadas y contexto video; disponibilidad fija exclusión/equipo/prestación/modalidad desde el enlace autorizado, rango máximo 14 días y versiones de la misma lectura. Roja local por módulo ausente, verde **24/24** (`adaptador-lectura-roja.log`, `adaptador-lectura-inicial.log`). No prueba el navegador ni el API real.
- Nueva prueba de recuperación de comandos antes del preflight de disponibilidad: una respuesta perdida debe poder recuperarse aunque cambien estado/política. Se propone una consulta backend de recibo ya autorizado; no puede ejecutar un comando nuevo ni permitir recuperar con enlace revocado. Contrato de siete grupos escrito, función todavía ausente; ejecutar roja antes de implementar. Evita que el servidor rechace el reintento de una escritura ya terminada al volver a calcular horarios.


### E1.36 — recuperación previa al preflight implementada después de roja

- CI `41652233660`, fuente `761904b002d041bd87a5c5f8d6b0e672382d0514`, main `32a8de1`: prueba ampliada de reasignación aprobada (log `sql-recuperacion-roja-41652233660.log:1463`); después roja estructural del nuevo lookup ausente (:3796), antes de ejecutar sus siete grupos. No se atribuye aprobación completa a esta corrida.
- .070 implementa recuperación sólo de recibo existente, previa a recalcular disponibilidad; autorización/identidad/recibo en una fotografía, sin efectos ni emisión de credencial. Revalidar enlace vigente incluso para repetir. Huella extraída a helper privado único en .040, misma forma de JSON/época/generación; otro payload no toma prestado el resultado. Pendiente CI de siete migraciones y digest/tipos nuevos.
- Adaptador de comando: roja local seis funciones/casos faltantes y 24 previos verdes; implementación inicial **30/30** dirigida. Preserva input/revisión/condiciones de la pantalla, comprueba slot con calculador compartido, ninguna identidad/exclusión del navegador. El lookup permite recuperar antes de las guardias mutables. Un fallo de transporte dice resultado sin comprobar y revisión/reintento; no afirma que la escritura se revirtió. Primera corrida de implementación tuvo un mock sin exportar zonedDate, corregido usando el helper puro real (no se cambia la regla para aprobar). Evidencia privada `adaptador-comando-roja.log`, `adaptador-comando-inicial.log`, `adaptador-comando-verde.log`.
- Estos adaptadores aún no están en las rutas. Pendiente tipado remoto con tipos generados actuales, UX, personal/roles, cola y E3–E6.


### E1.37 — siete migraciones y recuperación aprobadas

- **Suite completa 41653421061**, fuente exacta `a0a47b251129250f55fcd47f32a08a014ce1bc97`, main de código `4bd0210`: **761 pgTAP y 17 scripts de carreras** aprobados, incluido contrato de recuperación 7/7, protección de recuperación pública/manual después de reasignación y las doce carreras anteriores. Sin nuevos envíos ni producción.
- Recibo ok/sqlVerified y generación doble reproducible. Evidencia privada `sql-recuperacion-41653421061.zip`, colección `sql-recuperacion-evidence`, SHA-256 `bc85e6c6e05ceaf8c13e910952c8d867aa5fb55e7f6b1614f35cec5cd56ccdb2`. Tipos SHA-256 `c85bc7e3a826d0499c6c883c4505f4c3a6bd5a122154322998f14cfebcf2b1df`; digest de todas las migraciones `ac0abf5dc344c52b966303d92b801e157ded4ac362e44e8e2c185b814b1bb24f`, cotejado antes de importar. Este recibo no prueba UI/proveedor ni personal/cola pendientes.

### E2.1 — primera integración del recorrido, pendiente de CI general

- Nuevo panel contextual y flujo de GET/POST; rutas separadas explícitas `/gestion/<capacidad>` y `/turno/<legado>` usan un único servidor y componente completo. No inferir canal por formato, ni emitir enlaces nuevos en GET. Retirado el mutador TypeScript anterior que hacía update/auditoría en llamadas distintas y el formulario de pedido manual; formularios viejos de ese pedido reciben revisión, no una mutación. Pedidos históricos se conservan. Un test del mutador retirado se sustituye por garantías del comando SQL y adaptador; pruebas de lectura/calendario legadas permanecen.
- GET resuelve presentación y condiciones de horario elegido en un único getter. Slots se calculan por la vía compartida con el propio turno excluido y contexto fijo. Cancelar/reprogramar requieren resumen y POST explícito; alternativas y salida sin cambios. Duración vigente e importes registrados/condiciones visibles; sin saldo completo supuesto ni devolución automática. Campos/operación originales conservados para reintento incierto; una revisión vieja nunca se sustituye silenciosamente por otra fresca.
- Rojas locales de panel/flujo por módulos ausentes. Panel 6/6 y flujo 8/8 dirigidos; primera corrida del panel falló por `context` reservado en opciones de testing-library, resuelto pasando props explícitas. Logs `panel-contextual-{roja,inicial,verde}.log`, `flujo-autogestion-{roja,inicial}.log`. La apariencia/contrato de extensión están en `apps/web/.impeccable/surfaces/gestion-del-turno.md`; revisión visual/navegador pendiente.
- **Defecto propio reproducido:** comparar horarios con Date.parse truncaba microsegundos y admitía un horario fuera de la lista. Roja `precision-horario-roja.log`: 1 falla/30 pasan. Comparación de instantes a microsegundos, conservando offsets/precisión; verde 31/31 en `precision-horario-verde.log`. Sin mover ni recortar fechas SQL aceptadas.
- **Defecto propio reproducido:** ruta nueva no figuraba entre autorizaciones independientes y una cookie vencida llevaba al login. Roja `cookies-gestion-roja.log`: 1 falla/25 pasan; se incorpora sólo `/gestion/`. Lecturas sin caché/referrer/indexación y cupo de lecturas existente. Adaptadores/flujo/hooks y lectores legados juntos **84/84 locales**, `adaptadores-integrados-local.log`. No acredita la integración real.
- Calendario/push/estado de comprobante continúan en el componente completo compartido. SQL mantiene el token/UID de calendario; las mutaciones de agenda pasan por resolución revocable y comando único. Falta prueba integral adversaria de todas las rutas/redirecciones y corrección de email, así como contacto/baja y productor/consumidor de correo.
- Nueva prueba de UI para «Reservar otro turno» tras cancelación voluntaria sin seña: escrita para comprobar la hipótesis de que el botón viejo sólo se muestra con seña vencida; sin ejecutar ni corregir todavía. Próximo fast de integración, no confundir la pasada de unidades con tipado/paquete/navegador/producción.
