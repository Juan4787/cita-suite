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

**Fase:** E0 completo; E1 en preparación de contratos y pruebas, con alcance de ejecución autorizado. **Implementación iniciada:** contrato puro E1; todavía sin rutas, migraciones ni envíos integrados. **Publicación de E:** no. **Pruebas funcionales E:** no ejecutadas.

**Siguiente acción:** comprobar el contrato contextual en CI y escribir pruebas SQL E1 para revisión semántica, historial de señas, operaciones atómicas e idempotencia; ejecutar la reproducción en CI antes de migraciones nuevas. Continuar E2–E6 según dependencias. Q01/Q02 están resueltas; no esperar otra instrucción de inicio. La matriz contextual debe cubrir correo de turno vigente frente a correo de cancelación, sin extrapolar la ausencia de botones a todos los comprobantes.

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
