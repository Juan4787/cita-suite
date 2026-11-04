# Propuesta: señas, avisos por WhatsApp y horarios liberados para el consultorio de Natalia Frutos

**Estado:** **aprobada íntegramente por Juan el 29 de octubre de 2026**, con la revisión 2. Es la fuente de verdad de la campaña. **Actualización vigente del 3 de noviembre:** E conserva su definición revisada en [12.18](#etapa-e-vigente) y su [especificación](etapa-e-correo-autogestion.md). Juan pidió conectar Zoho por terminal y conservar el acceso tras reinicios: [12.19](#zoho-terminal-vigente), conexión local comprobada. **E quedó autorizada íntegramente para implementación, auditoría, pruebas y publicación el 3 de noviembre, en [12.20](#ejecucion-e-autorizada).** Decisiones iniciales resueltas en 12.21/12.22 y E1 en implementación/verificación; [registro de ejecución](ejecucion-etapa-e-20261103.md). D celular fue reemplazada por la futura P3 interna (12.23); P1/P2/P3 quedan pospuestas por el pedido posterior 12.26 y no se iniciarán al cerrar E. Las pausas y Resend anteriores son historia en lo que estos ajustes reemplazan.
- La aprobación literal y los ajustes posteriores están en la sección 12, que sólo crece hacia el final.
- El texto aprobado está guardado tal cual en `.verification/senas-avisos-20261029/plan-aprobado-20261029.md`, con SHA-256 `24abe324…4d3c43`.
- Después de la aprobación cambiaron sólo esta línea de estado y la sección 12; el registro deja la comprobación.
- La ejecución se sigue en el [registro](registro-senas-avisos-natalia.md) y el [traspaso](traspaso-senas-avisos-natalia.md).

*Estado anterior a la aprobación: propuesta para revisar, 29 de octubre de 2026, sin cambios de código ni de base de datos.*

**Revisión 1 (29 de octubre):** incorpora una crítica externa y una aclaración tuya: hoy no hay pacientes reales; los habrá al lanzar. Cambiaron seis cosas:
- el monto de la seña, que pasa a ser un porcentaje del arancel;
- la relación con Confirmado, que ahora se unifica en la base;
- el modo prueba, que se elimina;
- el plan de entregas, que termina en una sola publicación antes del lanzamiento;
- los bloqueos de fila, que pasan a `FOR NO KEY UPDATE`;
- las alertas de horarios liberados, que ya no cuentan las correcciones rápidas.

El detalle y los motivos están en la sección 11.

**Revisión 2 (29 de octubre):** incorpora una segunda crítica sobre el orden de los bloqueos y de los disparadores. Cambiaron cuatro cosas, con el detalle en la sección 11:
- una regla de bloqueo única para la seña;
- qué lee cada disparador;
- cómo se apaga la política;
- una inconsistencia propia sobre «Confirmo que voy».

**Pedido:** proponer la mejor manera de implementar lo que aprobó la primera clienta de Cita Suite, la Dra. Natalia Frutos, sin regresiones silenciosas ni inconsistencias. También explicar el razonamiento completo para poder cuestionarlo.
- El texto aprobado está copiado literal en el anexo A.
- Las transcripciones de sus audios están resumidas en el anexo B.

## 0. Resumen

Esto es lo que propongo:

1. **La seña es un dato propio de cada turno, en una tabla aparte.** La tabla guarda, por turno, si la seña está pendiente, recibida, exceptuada o vencida, con el monto y las fechas fijadas al reservar. No se agrega ningún estado nuevo al turno.
2. **El «tocar confirmar» del texto aprobado es el botón «Confirmar seña».** Está en la agenda, en el detalle del turno y en la lista de señas.
   - Registra la seña y pasa el turno a Confirmado, en una sola operación de la base de datos que incluye su auditoría.
   - Para el consultorio de Natalia, confirmar es pagar la seña: la persona nunca tiene que tocar «Confirmo que voy».
3. **El monto es un porcentaje del arancel** que el sistema ya cotiza para la fecha del turno, con su ajuste mensual. Se redondea igual que el arancel y queda fijo en ese turno.
4. **Fechas de la seña:**
   - Se pide desde el día que cae 7 días antes del turno, en la hora del consultorio.
   - Vence 48 horas antes del turno.
   - Si al reservar quedan menos de 24 horas para pagar, ese turno no se cancela solo: queda marcado para que lo resuelva el consultorio.
5. **La baja automática corre dentro de la base de datos**, con pg_cron (el programador de tareas que ya trae Supabase) cada 5 minutos, y no en Cloudflare. Hay dos motivos: los cinco disparadores gratuitos de Cloudflare ya están en uso, y este trabajo no necesita nada fuera de la base.
   - Cancela el turno, marca la seña, deja la auditoría y anota el horario liberado, todo en una sola transacción.
   - Se apaga por consultorio, y también con un interruptor general.
   - Nunca actúa sobre una seña vencida hace más de 24 horas.
6. **Todo lo que sale por WhatsApp lo envía una persona con un toque**, como hoy en Recordatorios: un enlace `wa.me` con el mensaje ya redactado. El WhatsApp automático está descartado en el plan aprobado y además cobra por mensaje.
7. **Botón al terminar la reserva** para que la persona avise al consultorio por WhatsApp, con sus datos y su turno. En la misma pantalla ve los datos para transferir la seña.
8. **Horarios liberados:** la base anota cada horario que se libera, por cancelación o reprogramación. La agenda muestra los que siguen libres, con un botón para darlos. Las correcciones rápidas de recepción no generan alerta.
9. **El correo electrónico y el aviso al celular del consultorio van en etapas aparte**, porque cada uno necesita una decisión tuya:
   - el correo, una cuenta gratuita de un proveedor de correo;
   - el aviso al celular, si Natalia usa iPhone, que la aplicación se pueda instalar en la pantalla de inicio.

**Cómo se entrega:** las etapas A, B y C (botones, señas y horarios liberados) se verifican por separado y se publican juntas, antes del lanzamiento. Las etapas D y E (aviso al celular y correo) son opcionales y quedan en pausa (sección 6).

Lo que más conviene que revises, porque si cambia, cambia el resto:
- el principio de la sección 1.3: ante la duda, no cancelar;
- la unificación de la seña con Confirmado en la base (decisión 2, revisada);
- las reglas para reservas de último momento y para pedidos de reprogramación;
- la baja automática dentro de la base de datos.

## 1. Cómo razoné

### 1.1 Método

1. Separé el texto aprobado en 11 promesas que se pueden comprobar (sección 2).
2. Para cada promesa leí el código que la toca (rutas, módulos del servidor, migraciones y documentación) y anoté qué existe y qué falta. Cada afirmación lleva su archivo y su línea.
3. Fijé las restricciones que no se negocian (1.2) y el principio para los casos dudosos (1.3).
4. Para cada decisión listé alternativas y elegí con los criterios de 1.4. Al final de las decisiones importantes dejo «Dónde puedo estar equivocado», para que tengas por dónde atacarlas.
5. Verifiqué en la documentación oficial los datos externos: correo, conexiones salientes de Cloudflare, límites de Gmail y pg_cron (fuentes en la sección 10).

### 1.2 Restricciones que no se negocian

| Restricción | De dónde sale | Qué obliga |
|---|---|---|
| Sin gastos recurrentes para el primer consultorio y nada con cobro variable sin tope | `AGENTS.md` y `docs/architecture/control-de-consumo.md` | Descarta WhatsApp automático de Meta, Workers Paid y Cloudflare Email Service. |
| Cloudflare Workers Free: cinco disparadores programados por cuenta, ya usados; 10 milisegundos de procesador por ejecución; 40 llamadas por cadena de tarea | `docs/architecture/tareas-automaticas.md`, líneas 27, 65 y 114 | La baja automática no puede ser un sexto disparador, y conviene que no gaste presupuesto del Worker. |
| Las notificaciones por WhatsApp siguen descartadas | `docs/plans/refactorizacion-cita-suite.md`, línea 24 | Todo envío por WhatsApp lleva un toque humano. |
| Lo que debe cumplirse junto va en una transacción de la base; la pantalla nunca es la autoridad | `docs/architecture/guia-nuevas-funciones.md` | Cada acción sobre una seña es una función de la base con sus permisos y su auditoría adentro. |
| Migraciones aditivas, sin editar las aplicadas, y compatibles con la versión anterior para poder volver atrás | Guía de nuevas funciones y `docs/architecture/verificacion.md` | Tablas nuevas, interruptor general y un orden explícito para volver atrás (sección 5). |
| Un defecto se reproduce primero con una prueba que falla; una prueba vale sólo si detecta la pérdida de la garantía | `AGENTS.md` | Plan de pruebas por garantía (sección 5). |
| Producción, sólo con tu autorización expresa | Memoria del proyecto | Ninguna entrega se publica sin pedírtela. |

### 1.3 El principio que decide los casos dudosos

La baja automática puede equivocarse de dos maneras:

- **Cancelar de más:** se cancela el turno de alguien que pagó, o que no tuvo una oportunidad razonable de pagar.
  - La paciente pierde el turno.
  - El horario puede tomarlo otra persona antes de que alguien lo note.
  - Natalia pierde confianza en el sistema.
- **Cancelar de menos:** un turno sin seña sigue ocupando el horario. El consultorio lo ve en la lista y lo cancela a mano.

El primer error es mucho más grave y mucho más difícil de reparar. Por eso, **ante cualquier duda, la regla es no cancelar y mostrar el caso para que decida una persona.** Este principio explica varias decisiones de abajo:
- las reservas de último momento;
- los pedidos de reprogramación;
- la ventana de 24 horas;
- el consultorio suspendido;
- deshacer una seña cuando ya pasó el vencimiento;
- apagar la política.

Si no estás de acuerdo con este principio, esas decisiones cambian.

### 1.4 Criterios para elegir, en orden

1. No cancelar nunca por error (1.3).
2. Un solo lugar para cada dato y cada regla, sin dos copias que puedan diferir.
3. No cambiar el significado de algo que ya existe y funciona: es la fuente más común de regresiones silenciosas.
4. Reutilizar mecanismos ya verificados en producción.
5. Ningún costo recurrente.
6. Que Natalia y Aye lo entiendan sin explicación técnica.

### 1.5 Supuestos (si alguno es falso, cambia la propuesta)

- Las pacientes de Natalia reservan desde su web, que abre el turnero como página completa en `/embed/v1/<clave>` (`apps/natalia/src/lib/booking-config.ts`, línea 13). La pantalla final que ven es `/embed/v1/<clave>/turno/<token>`.
- La seña se paga por transferencia, fuera del sistema. El sistema sólo registra que llegó.
- La seña es un porcentaje del arancel que el sistema cotiza para la fecha del turno (revisión 1). El monto fijo queda sólo para prestaciones sin arancel configurado.
- Hoy no hay pacientes reales; los habrá cuando se lance (aclaración tuya del 29 de octubre). La web de Natalia ya está publicada y reserva contra producción (`docs/architecture/dominio.md`, líneas 14 y 114), así que esta entrega tiene que estar publicada antes de anunciarla.
- Las señas las registran Natalia o Aye, con rol de dueña, administración o recepción.
- El consultorio usa la hora de Argentina, que no tiene cambio de horario. El diseño igual funciona con cambio de horario, porque trabaja con instantes absolutos.

## 2. Qué se prometió y qué existe hoy

| # | Promesa del texto aprobado | Hoy | Evidencia | Qué falta |
|---|---|---|---|---|
| 1 | Al reservar por la web se crea la ficha con todos sus datos y el teléfono | **Existe** | La reserva crea paciente y turno en la misma transacción. `20261013010000_booking_patient_information.sql`, líneas 159 a 163, copia a la ficha obra social, plan, nacimiento, DNI y dirección cuando el formulario marca esos campos con `patientField`. | Comprobar que el formulario de Natalia marca obra social y plan. Es configuración, no código. |
| 2 | Al terminar la reserva, un botón para mandarle al consultorio un WhatsApp con nombre, fecha y hora | **No existe** | La pantalla final de Natalia sólo ofrece «Ver y gestionar mi turno» y «Reservar otra consulta» (`routes/embed/v1/[integrationKey]/turno/[token]/+page.svelte`, línea 28). El número de WhatsApp del consultorio ya existe: `businesses.whatsapp_phone` (`20261014030000_patient_instructions_public_contact.sql`, líneas 3 a 5), en Configuración, Negocio, Contacto. | El botón en las dos pantallas finales. |
| 3 | Escribirle a cada paciente por WhatsApp buscando su nombre en la app | **En parte** | El detalle del turno ya tiene botones de WhatsApp para enviar el enlace y avisar una reprogramación. La ficha muestra el teléfono con «Copiar teléfono», pero sin WhatsApp (`lib/components/patients/PatientProfilePanel.svelte`, líneas 254 a 264). | Un botón de WhatsApp en la ficha. |
| 4 | Transferir en el momento, mandar el comprobante por ese chat y tocar «confirmar» en el sistema | **No existe** | La seña no existe en la base de datos. | El núcleo de señas. |
| 5 | Pagar más adelante; 7 días antes, la lista de señas pendientes con un botón de WhatsApp de un clic y el mensaje redactado, que aclara que si ya transfirió lo desestime | **No existe** | Recordatorios ya resuelve lo mismo para otro mensaje: registra quién abrió el WhatsApp y redirige a `wa.me` (`routes/odonto/recordatorios/abrir/[appointmentId]/+server.ts`). | La lista, el mensaje y el registro de apertura. |
| 6 | Como complemento, un correo pidiendo la confirmación | **No existe** | La app no envía correos. Sólo Supabase Auth manda el de recuperación de contraseña. | Proveedor, cola y plantillas (etapa E). |
| 7 | Baja automática al vencer el plazo (por ejemplo, 48 horas antes), con el horario liberado en la web, aviso en la app y aviso opcional al celular | **No existe**, pero cancelar ya libera el horario en la web (hallazgo 3) | Las notificaciones push existentes son sólo para pacientes (`lib/server/integrations/public/push.ts`). | La tarea, los avisos en la app y, en la etapa D, el aviso al celular. |
| 8 | Alerta destacada en el turnero con los horarios que se liberaron | **No existe** | — | El registro de horarios liberados y la alerta. |
| 9 | El día anterior, el botón para mandar el recordatorio final de asistencia con un solo clic | **En parte** | Recordatorios lo tiene, pero **sólo para los turnos de mañana sin calendario ni notificación confirmada** (`lib/server/scheduling/public/reminders.ts`, líneas 203 y 392). A quien ya tiene aviso automático no se le ofrece el botón. | Mostrar todos los turnos de mañana (sección 4.11). |
| 10 | En iPhone se agenda una alarma; en Android llega una notificación automática | **Existe, con una condición** | Archivo de calendario con alarmas 24 y 2 horas antes, y notificaciones push 24 y 2 horas antes. **La persona tiene que activarlas una vez** en la página de su turno. Desde la web de Natalia eso es un toque más: «Ver y gestionar mi turno» abre otra pestaña. | Un llamado claro en la pantalla final. Ojo: el texto aprobado dice «automáticamente», y sin ese toque no ocurre. Conviene aclarárselo a Natalia. |
| 11 | Segunda etapa: recordatorios y pedidos de confirmación automáticos por correo | **No existe** | Depende de la promesa 6. | Etapa E. |

## 3. Hallazgos del código que condicionan el diseño

**Hallazgo 1. «Confirmado» ya significa otra cosa.**
- Hoy un turno pasa a Confirmado por dos vías:
  - la persona toca «Confirmo que voy» en su enlace (`lib/server/scheduling/public/public-appointments.ts`, líneas 276 a 279; botón en `routes/turno/[token]/+page.svelte`, línea 1603);
  - el consultorio lo confirma (`lib/server/scheduling/public/appointments.ts`, línea 455).
- Reprogramar lo vuelve a Reservado y borra la confirmación (`appointments.ts`, líneas 574 y 575).
- Consecuencia si «seña pagada» se guardara sólo como Confirmado, sin dato propio ni regla en la base (la sección 4.2 revisada resuelve estos dos riesgos):
  - una paciente quedaría confirmada sin pagar con sólo tocar su botón;
  - una reprogramación borraría la constancia de una seña ya cobrada.

**Hallazgo 2. La tabla de turnos tiene al menos once disparadores.**
- Son: límite de reservas públicas, copia de datos del paciente, horario permitido de la prestación, precio, indicaciones, guardia de roles, vínculo entre profesional y paciente, actividad del paciente, profesionales del turno, calendario de Google y reseñas de Google.
- Algunos corren ante cualquier cambio de la fila; por ejemplo, `zz_service_schedule` (`20261014010000_service_schedule_restrictions.sql`, línea 124).
- Consecuencia: si la seña se guardara en columnas del turno, cada registro de seña haría correr esa cadena. Una tabla aparte la evita.

**Hallazgo 3. Cancelar ya libera el horario en la web.**
- Las exclusiones que impiden superponer turnos sólo cuentan los estados activos (`20260724120000_joint_appointments_and_flexible_breaks.sql`, líneas 136 a 160).
- El disparador `sync_appointment_professionals` copia el estado del turno a cada profesional.
- La disponibilidad pública se lee en cada pedido, sin caché entre pedidos (`lib/server/scheduling/public/public-booking.ts`, líneas 308 a 319).
- Consecuencia: la baja automática sólo tiene que cancelar el turno. No hay que tocar el calculador de horarios.

**Hallazgo 4. Las cancelaciones actuales hacen el cambio y la auditoría en dos llamadas separadas.**
- Pasa tanto en el consultorio como en el enlace público (`appointments.ts`, líneas 455 a 526; `public-appointments.ts`, líneas 296 a 317).
- Si falla la segunda llamada, queda un turno cancelado sin registro.
- Consecuencia: la baja automática y las acciones sobre la seña se hacen como una sola función de la base, con la auditoría adentro.
- No propongo corregir las cancelaciones existentes en estas entregas, pero queda anotado como deuda.

**Hallazgo 5. pg_cron ya se usa en producción para trabajos que sólo tocan la base.**
- Ejemplos: el mantenimiento de exportaciones cada 15 minutos y las retenciones diarias.
- La documentación de Supabase indica que el historial de ejecuciones (`cron.job_run_details`) no se borra solo, y hoy ninguna migración lo poda.
- Consecuencia: la baja automática va en pg_cron, y la entrega agrega la poda de ese historial, que beneficia también a los trabajos existentes.

**Hallazgo 6. La guardia de roles de los turnos deja pasar los cambios hechos por la base sin un usuario conectado.**
- Es la condición `if auth.uid() is null then return new` de `20260831067000_restore_appointment_role_guard.sql`.
- Consecuencia: pg_cron puede cancelar sin desactivar ninguna protección.

**Hallazgo 7. La pantalla final de Natalia no es la del turno.**
- La pantalla final de la integración no es `/turno/<token>`, que es donde están el calendario y las notificaciones.
- Consecuencia: el botón de WhatsApp y los datos de la seña van en las dos pantallas.
- Además, el botón que lleva a `/turno/<token>` debería decir para qué sirve: «Activar el recordatorio en mi teléfono».

**Hallazgo 8. La aplicación no se puede instalar en la pantalla de inicio.**
- `apps/web/static` sólo tiene `booking/`, los logos, `push-sw.js` y `robots.txt`.
- iPhone sólo permite notificaciones web a aplicaciones agregadas a la pantalla de inicio (`docs/plan-calendario-direccion-recordatorios.md`, restricción 2).
- Consecuencia: para avisar al iPhone del consultorio, primero hay que hacer instalable la aplicación.

**Hallazgo 9. Correo electrónico (sección 10):**
- Cloudflare Email Service exige Workers Paid para escribirle a cualquier destinatario.
- Resend gratuito permite 100 correos por día y 3.000 por mes.
- Gmail personal se bloquea al pasar 500 mensajes o destinatarios en un día.
- Workers no puede abrir conexiones al puerto 25. Sobre el 587 la documentación no dice nada explícito.

**Hallazgo 10. La lista de estados activos aparece en 21 migraciones y en 24 archivos TypeScript o Svelte.**
- Consecuencia: agregar un estado nuevo al turno, como «esperando seña», obligaría a tocar unos 45 lugares. Es exactamente el tipo de cambio que produce regresiones silenciosas.

**Hallazgo 11. Los mensajes de recordatorio actuales no nombran la prestación.**
- Es la decisión 48 del plan de recordatorios: no exponer datos de salud en la vista previa del teléfono.
- Consecuencia: los mensajes nuevos siguen la misma regla.

## 4. Diseño propuesto

### 4.1 Decisión 1: la seña es un dato propio del turno

**Qué propongo.** Una tabla nueva, `appointment_deposits`, con una fila por cada turno que exige seña. La relación es uno a uno con el turno y lleva `business_id` con clave compuesta, como el resto de las relaciones entre consultorios. Tiene estas columnas:

- `status`, con cuatro valores:
  - `pending`: pendiente;
  - `paid`: recibida;
  - `waived`: exceptuada;
  - `expired`: vencida, es decir, el turno se canceló automáticamente.
- `amount`: entero en pesos, con el mismo formato y los mismos límites que los aranceles (`base_amount bigint`). Moneda `ARS`. Se calcula al reservar (sección 4.3) y queda fijo en ese turno.
- Fotografía de la política al momento de reservar:
  - `percentage`: el porcentaje aplicado, o nulo si se usó un monto fijo;
  - `reference_amount`: el arancel cotizado sobre el que se calculó;
  - `request_days`: 7 por defecto;
  - `deadline_hours`: 48 por defecto;
  - `min_payment_hours`: 24 por defecto;
  - `policy_revision`.
- Fechas calculadas:
  - `request_from`: desde cuándo se pide;
  - `due_at`: vencimiento;
  - `auto_cancel`: si la baja automática aplica a este turno.
- Registro:
  - `recorded_by` y `recorded_at`;
  - `note`, hasta 300 caracteres;
  - `reminder_opened_at` y `reminder_opened_by`;
  - `expired_at`.
- `revision`: un número que sube con cada cambio. Detecta que otra persona modificó la seña mientras alguien la miraba.

Un turno sin fila no exige seña. Es el caso de las prestaciones sin monto, de la política apagada y de todos los turnos anteriores a la función.

**Por qué:**
- No cambia el significado de Confirmado (hallazgo 1).
- Los datos de la seña (monto, fechas, quién abrió el WhatsApp, notas) se escriben sin activar la cadena de disparadores del turno (hallazgo 2). Sólo la activa el cambio de estado al confirmar o cancelar, igual que hoy.
- No toca la lista de estados activos (hallazgo 10).

**Alternativas descartadas:**

| Alternativa | Por qué no |
|---|---|
| Usar Confirmado como «seña pagada» | Hallazgo 1: confirmar sin pagar y perder la seña al reprogramar. |
| Columnas nuevas en la tabla de turnos | Hallazgo 2: cada registro dispara la cadena del turno. Además mezcla dos responsabilidades en una fila que ya tiene 56 columnas, según los tipos generados. |
| Un estado nuevo del turno, «esperando seña» | Hallazgo 10: unos 45 lugares que hoy deciden qué es un turno activo. |
| Guardarla en la ficha del paciente | La seña es de cada turno, no de la persona. |

**Dónde puedo estar equivocado.** En la primera versión, Natalia podía ver dos indicadores, el estado y la seña. La revisión de la sección 4.2 deja un solo estado visible, con la seña como detalle.

### 4.2 Decisión 2 (revisada): «Confirmar seña» confirma el turno

**Qué propongo.** Unificar la seña con Confirmado en la base de datos, no sólo en la pantalla:
1. **«Confirmar seña» y «Exceptuar» confirman el turno.** Registran la seña y pasan el turno a Confirmado, en la misma transacción y con su auditoría. «Deshacer» devuelve la seña a pendiente y el turno a Reservado.
2. **Una regla en la base impide confirmar con la seña pendiente**, venga el cambio de donde venga: el enlace de la persona, el botón genérico del consultorio o una escritura directa. Es un disparador nuevo en `appointments` que sólo corre cuando cambia el estado.
3. **Mientras la seña está pendiente no se ofrece «Confirmo que voy»**: pagar la seña es confirmar.
   - Cuando la seña se resuelve, el turno ya queda Confirmado. Ese botón sólo existe para turnos Reservados, así que tampoco aparece.
   - Cancelar y pedir reprogramación siguen disponibles.
   - La única excepción es apagar la política (sección 4.3): ahí el turno vuelve al funcionamiento habitual.
4. **Reprogramar un turno con la seña recibida o exceptuada lo mantiene Confirmado.** Es un cambio chico en `rescheduleAppointment` (`appointments.ts`, línea 574), protegido por la regla del punto 2: si alguien deshizo la seña en el medio, la reprogramación falla con un conflicto en vez de dejar un estado incoherente.
5. **Etiquetas:** «Reservado, seña pendiente» en amarillo y «Confirmado, seña recibida» en verde. La etiqueta, los filtros y los conteos dicen lo mismo, porque salen del mismo dato.

**Por qué cambié de opinión.** La crítica tiene razón en el problema:
- En los audios, Natalia dice que necesitan «que la persona confirme cien por ciento y valide su turno y que sea con la seña», y que el mensaje del día anterior es sólo un recordatorio.
- Pedirle «Confirmo que voy» a alguien que ya pagó no tiene sentido.
- Si Aye toca «Confirmar seña» y el turno sigue diciendo Reservado, va a pensar que el botón no anduvo.

**Por qué no la unificación sólo visual que propone la crítica**, que oculta «Reservado» en pantalla y deja el estado guardado como está:
- La agenda filtra y cuenta por el estado guardado (`routes/odonto/agenda/+page.server.ts`, líneas 154 a 165).
- La vista semanal cuenta por estado dentro de la base (`20261020050000_agenda_week_counts.sql`, líneas 12 y 22).
- Una tarjeta diría «Confirmado», pero el filtro «Confirmado» no la mostraría y la semana contaría ese turno como reservado.
- Para evitarlo habría que traducir el estado en cada filtro, conteo, historial y exportación: los mismos 45 lugares del hallazgo 10.

**Qué cuesta esta versión:**
- «Confirmar seña» ahora sí modifica la fila del turno, así que corre la cadena de disparadores del hallazgo 2. Es el mismo camino que hoy recorre el botón «Confirmar» del consultorio, ya verificado. Por ejemplo, vuelve a sincronizar el calendario de Google de la persona si lo conectó, como ya ocurre al confirmar.
- Confirmado pasa a significar «turno asegurado» por dos vías: la persona confirmó (consultorios sin seña) o la seña está resuelta (consultorios con seña). La auditoría registra cuál fue.
- En los turnos con seña se pierde el dato «además confirmó que viene». Para Natalia no tiene uso.

### 4.3 Decisión 3: política del consultorio y fotografía al reservar

**Configuración.** Hay una pantalla nueva, Configuración, Señas, para dueña y administración. Tiene:
- la seña: apagada o activa;
- la cancelación automática: apagada o encendida (sección 4.6);
- el porcentaje del arancel (ver «Monto», más abajo);
- días antes para pedir la seña (7);
- horas antes del turno para el vencimiento (48);
- plazo mínimo para pagar (24 horas);
- los datos para transferir (alias, CBU y titular), como texto;
- si la seña se exige también en los turnos que carga el consultorio.

**Monto.** Es un porcentaje del arancel cotizado para la fecha del turno:
- El arancel ya se cotiza al reservar, con el ajuste mensual del mes del turno, y queda fotografiado en el turno (`private.snapshot_appointment_price`, `20261014000000_booking_price_policies.sql`, línea 131).
- La seña se calcula sobre ese mismo valor y en la misma transacción. Así, el arancel y la seña que ve la persona son coherentes entre sí.
- Se redondea con la misma unidad de redondeo de la política del arancel, que se lee en esa misma transacción.
- Al reprogramar, la base conserva el arancel fotografiado, y con él la seña.
- Cada prestación puede exigir seña o no. Una prestación sin arancel configurado puede usar un monto fijo; si no tiene ninguno de los dos, la configuración no deja exigirle seña.
- Descarté un monto base con su propia regla de ajuste mensual: duplicaría la configuración de los ajustes. Sólo tendría sentido si la seña de Natalia no fuera proporcional al arancel.

**Cuándo se crea la fila.** Se crea en la misma transacción que el turno, mediante un disparador posterior a la inserción en `appointments`. Tiene que ser posterior porque la seña apunta al turno con una clave foránea. Esto tiene dos ventajas:
- Cubre las tres funciones de alta que existen sin modificarlas: `create_appointment_with_patient_identity`, `create_integrated_public_appointment` y `create_public_booking_with_information`.
- Un reintento de la misma reserva no crea otra seña, porque no inserta otro turno.

Cuando ese disparador corre, el arancel ya está en la fila:
- Lo calcula `zz_appointment_price`, que corre antes de la inserción (`20261014000000_booking_price_policies.sql`, línea 144).
- PostgreSQL ejecuta todos los disparadores anteriores a una escritura antes que los posteriores, sin importar el nombre.
- El orden alfabético sólo decide entre disparadores del mismo momento.

**Cambiar la política sólo afecta las reservas nuevas.** A la persona ya se le informó un monto y un vencimiento. Cambiarlos sin avisarle sería injusto, y su mensaje diría una cosa mientras el sistema hace otra.

**Apagar la política tiene efecto inmediato y seguro.** Las señas pendientes pasan a exceptuadas, con el motivo «política desactivada» y su auditoría, y ninguna se cancela después (principio 1.3).
- Para respetar la regla de bloqueo (sección 4.5), primero bloquea los turnos de esas señas, en orden de identificador, y recién después actualiza las señas.
- No pasa esos turnos a Confirmado. Sin política de seña, el consultorio vuelve al funcionamiento habitual y la persona puede confirmar con su enlace.

**No es retroactiva.** Al instalar la función no se crea ninguna fila para los turnos que ya existen.

### 4.4 Decisión 4: cuándo se pide y cuándo vence

**Reglas.** Son una sola función de la base, usada por el alta, la reprogramación, la baja automática y el paso de confirmación de la reserva:

- **Se pide desde** el comienzo del día que cae 7 días antes del turno, en la zona horaria del consultorio.
- **Vence** 48 horas exactas antes del comienzo del turno.
- **Se cancela sola** sólo si, entre el momento de reservar y el vencimiento, hubo al menos 24 horas para pagar. Si no, el turno queda como «Último momento: resolver a mano».

**Ejemplo con un turno del viernes 20 de noviembre a las 10:00:**

| Se reservó | Aparece para pedir la seña | Vence | ¿Se cancela solo? |
|---|---|---|---|
| Sábado 31 de octubre | Viernes 13 de noviembre, desde las 00:00 | Miércoles 18 de noviembre a las 10:00 | Sí |
| Domingo 15 de noviembre a las 18:00 | En el momento (el 13 ya pasó) | Miércoles 18 a las 10:00 | Sí: tuvo 64 horas para pagar |
| Martes 17 de noviembre a las 15:00 | En el momento | Miércoles 18 a las 10:00 | No: sólo tuvo 19 horas. Queda para resolver a mano. |
| Jueves 19 de noviembre a las 9:00 | En el momento | Ya vencido al reservar | No. Queda para resolver a mano. |

**Reprogramación.**
- Si la seña está pendiente, se recalculan las tres fechas con la fotografía guardada, no con la política actual. El plazo mínimo para pagar se mide desde el momento de reprogramar.
- Si estaba recibida o exceptuada, no cambia nada: la seña acompaña al turno.
- Lo hace un disparador, en la misma transacción que el cambio de horario, sea cual sea la pantalla que reprograme.

**Alternativa para el último momento:** no permitir reservas online con menos de 72 horas de anticipación, usando el ajuste que ya existe (`min_booking_notice_minutes`). No la pongo por defecto porque le quita turnos a Natalia. Es una pregunta para ella.

**Dónde puedo estar equivocado.** Las 24 horas de plazo mínimo son un criterio mío. Podrían ser 12 o 48. Por eso es un ajuste, y se fotografía en cada turno.

### 4.5 Estados de la seña y quién los cambia

| De | A | Quién | Condiciones | Además |
|---|---|---|---|---|
| (turno nuevo) | Pendiente | La base, al crear el turno | Seña activa en el consultorio y prestación que la exige. Si el consultorio carga el turno, según la política. | Calcula el monto y las fechas. |
| Pendiente | Recibida | Dueña, administración o recepción | Turno activo | Si el turno está Reservado, pasa a Confirmado en la misma transacción. Auditoría. |
| Pendiente | Exceptuada | Dueña, administración o recepción | Turno activo; motivo opcional | Igual que el anterior: el turno pasa a Confirmado. Auditoría. |
| Recibida o exceptuada | Pendiente («Deshacer») | Dueña, administración o recepción | Turno activo | Si el turno estaba Confirmado, vuelve a Reservado. Si el vencimiento ya pasó o faltan menos de 24 horas, ese turno deja de cancelarse solo: un deshacer nunca dispara una cancelación. |
| Pendiente | Vencida | Sólo la tarea automática | Las de la sección 4.6 | Turno Cancelado, auditoría y horario liberado. |
| Vencida | — | — | Es final | Para recuperar el horario se carga un turno nuevo (sección 4.8). |

**Si se cancela el turno.** Cuando la persona o el consultorio cancelan el turno, la seña queda como estaba, como constancia. Si se devuelve o no una seña cobrada se arregla por fuera: el sistema no mueve dinero, y la pantalla lo dice.

**Cómo funciona cada acción.** Cada acción es una función de la base que, en una sola transacción:
1. Comprueba el permiso con la membresía vigente (`user_can_operate_business`) y el estado comercial (`business_allows_operation`).
2. Bloquea primero la fila del turno y después la de la seña, siempre en ese orden y con `FOR NO KEY UPDATE`. Ese modo no choca con los bloqueos que toman las claves foráneas cuando otra transacción inserta filas que apuntan al turno: la seña, el horario liberado, los profesionales del turno. Con `FOR UPDATE` se repetiría el bloqueo mutuo `40P01` que la etapa 4 encontró y corrigió así (`docs/architecture/disponibilidad-y-aranceles.md`, línea 84; `20261018000000_availability_configuration_locking.sql`, líneas 19 a 22).
3. Compara la `revision` esperada. Si otra persona la cambió, responde «Otra persona actualizó esta seña. Revisala antes de seguir».
4. Aplica el cambio y escribe la auditoría.

Repetir «Confirmar seña» sobre una seña ya recibida devuelve éxito, sin duplicar la auditoría.

**Regla de bloqueo (revisión 2).** El bloqueo de la fila del turno es la única puerta de su seña: ninguna escritura sobre una seña ocurre sin tener bloqueado su turno. La cumplen todos los caminos:
- el alta, porque la seña se crea en la misma transacción que inserta el turno;
- la reprogramación, porque su disparador corre mientras actualiza el turno;
- las acciones de recepción, que bloquean el turno antes de tocar la seña;
- la tarea automática (sección 4.6);
- apagar la política (sección 4.3).

Nadie escribe directamente en la tabla de señas: sólo estas funciones tienen permiso. Con esta regla nadie puede tener una seña bloqueada sin tener también su turno, así que el bloqueo mutuo por orden inverso no puede ocurrir.

### 4.6 Decisión 5: la baja automática

**Dónde corre.** En la función `private.expire_unpaid_deposits()`, invocada por pg_cron cada 5 minutos con el trabajo `cita-suite-deposit-expiry`.

**Cancela un turno sólo si se cumplen todas estas condiciones**, evaluadas con la fila bloqueada:
1. La seña está pendiente y su `auto_cancel` es verdadero.
2. El vencimiento ya pasó, **y pasó hace menos de 24 horas**.
3. El turno está Reservado (con la seña pendiente no puede estar Confirmado), no está en «Quiere reprogramar» y todavía no empezó.
4. El consultorio está activo y su estado comercial le permite operar.
5. La cancelación automática del consultorio está encendida. Si está apagada con la seña activa, las señas vencidas aparecen en la lista para decidir a mano.
6. El interruptor general está encendido. Lo maneja el operador: sirve para apagar todo de inmediato y es el primer paso para volver atrás (sección 5).

**Qué hace, en una sola transacción:**
- El turno pasa a Cancelado con el motivo «Seña no registrada antes del {vencimiento}» y sin usuario.
- La seña pasa a vencida.
- Se escribe la auditoría `appointment.deposit_expired`.
- Se anota el horario liberado (sección 4.10).

Lo que ya ocurre con cualquier cancelación sigue igual, porque lo hacen disparadores existentes: liberar a cada profesional, actualizar el calendario de Google de la persona, anular la reseña pendiente y registrar la actividad del paciente.

**¿Por qué excluir «Quiere reprogramar»?** La persona hizo algo explícito para conservar un turno, y quien tiene que responder es el consultorio. Cancelarla mientras su pedido espera respuesta sería una falla del consultorio, no de ella. El turno aparece en la lista como «Pidió reprogramar: resolver a mano», y la agenda ya avisa esos pedidos.

**Carreras (dos cosas al mismo tiempo):**
- **Recepción toca «Confirmar seña» mientras corre la tarea.**
  - La tarea bloquea sólo los turnos candidatos, con `for no key update of` el turno y `skip locked`. Si alguien está usando un turno, lo saltea y lo vuelve a evaluar 5 minutos después.
  - Recién después escribe las señas de los turnos que bloqueó. Nunca espera, porque por la regla de bloqueo (sección 4.5) nadie puede tener esas señas sin tener sus turnos.
  - No bloqueo turno y seña en la misma consulta, como propuso la segunda crítica. PostgreSQL no documenta en qué orden bloquea las filas de varias tablas en una misma consulta, y un bloqueo de fila sólo se libera al terminar la transacción. Si llegara a bloquear la seña antes de descubrir que el turno está ocupado, esa seña quedaría bloqueada hasta el final de la tarea. No sería un bloqueo mutuo, pero haría esperar a recepción y dependería de un detalle interno.
  - La función de recepción espera a que la tarea termine.
  - Hay sólo dos resultados posibles: la seña quedó registrada y el turno sigue, o el turno ya estaba cancelado y recepción ve «Este turno se canceló automáticamente a las 10:05», con el botón para volver a darlo. Nunca las dos cosas a la vez.
  - No hay bloqueos mutuos, porque la tarea nunca espera.
- **Reprogramación al mismo tiempo.** El recálculo de fechas ocurre en la misma transacción que el cambio de horario, así que la tarea evalúa la fila ya actualizada.
- **Otra persona reserva el horario recién liberado.** Lo resuelve la exclusión existente (hallazgo 3).

**La ventana de 24 horas después del vencimiento.** Puede pasar que la tarea no haya corrido:
- pg_cron estuvo detenido;
- el proyecto se pausó;
- el consultorio estuvo suspendido y se reactivó;
- el interruptor se apagó y se volvió a encender.

En todos esos casos, al volver la tarea no cancela de golpe turnos vencidos hace días. Esos quedan en «Vencidas sin cancelar: decidir». Es la aplicación más directa del principio 1.3.

**Sin modo prueba (revisión 1).** La primera versión proponía un modo de prueba propio, que anotaba «se habría cancelado». Lo eliminé por dos motivos:
- Hoy no hay pacientes reales, así que antes del lanzamiento no habría nada real que observar, y ese código quedaría sin uso al lanzar.
- Si Natalia igual quiere observar unos días después del lanzamiento, alcanza con la seña activa y la cancelación automática apagada: las vencidas aparecen en «Vencidas sin cancelar: decidir». No hace falta código aparte, porque ese interruptor por consultorio se necesita igual. Al encenderlo, la ventana de 24 horas impide que cancele de golpe las que vencieron mientras estaba apagado.

**¿Por qué en la base y no en Cloudflare?**
1. Los cinco disparadores gratuitos están usados.
2. Un sexto obligaría a fusionar dos trabajos ya verificados.
3. Es una consulta indexada sin llamadas a proveedores: no gasta procesador del Worker (cuyo límite de 10 milisegundos ya se superó en mediciones anteriores) ni llamadas del presupuesto de 40.
4. Queda todo en una sola transacción.
5. Ya hay precedente: el mantenimiento de exportaciones corre así cada 15 minutos.

**¿Por qué no calcular el vencimiento al leer, sin tarea?** La exclusión de superposición de la base no puede evaluar «ahora»: seguiría rechazando reservas sobre un turno vencido pero todavía activo. Además, cada pantalla (agenda, turnero, semana, calendario) tendría que conocer la regla. Serían dos fuentes de verdad.

**Cómo se nota si falla:**
- La tarea guarda un registro de cada ejecución: cuándo empezó, cuándo terminó y cuántas procesó.
- La página de señas muestra «Última revisión automática: hace 3 minutos» y una alerta si pasaron más de 20 minutos.
- Si la tarea se detiene, no cancela nada: el error queda del lado seguro.
- Además se agrega la poda diaria de `cron.job_run_details` (hallazgo 5).

**Demora.** Hasta 5 minutos después del vencimiento. Para una regla de 48 horas es irrelevante. Se podría correr cada minuto sin costo apreciable, pero no aporta nada.

### 4.7 Aviso de reserva nueva por WhatsApp (promesa 2)

**Dónde aparece:**
- en la pantalla final de la integración, que es la que ven las pacientes de Natalia;
- en `/turno/<token>?creado=1`.

**A qué número.** Al número de WhatsApp del consultorio (`whatsapp_phone`, con `whatsapp_contact_enabled`), que se carga en Configuración, Negocio, Contacto. Si no está cargado, el botón no aparece y la configuración de señas lo advierte.

**Botones:**
- Con seña: «Ya transferí: enviar el comprobante» y «Voy a pagar la seña más adelante».
- Sin seña: «Avisar al consultorio por WhatsApp».

**Mensaje (ejemplo):**
> Hola, soy {nombre y apellido}. Reservé un turno para el viernes 20 de noviembre a las 10:00. Te envío el comprobante de la seña.

En la variante de pago posterior, la última oración es: «Voy a transferir la seña antes del miércoles 18 de noviembre a las 10:00».
- No nombra la prestación (hallazgo 11).
- La persona puede editarlo antes de enviarlo.

**Datos de transferencia.** Aparecen en la misma pantalla, con un botón para copiar el alias. Si el navegador no deja copiar, el texto queda seleccionable, como ya hace «Copiar detalles».

**Un límite que no se puede eliminar.** El aviso depende de que la persona toque el botón. Para que lo toque, el botón le resuelve algo a ella: mandar el comprobante o comprometerse a pagar. Igual va a haber reservas sin aviso. Para esas hay dos complementos:
1. Toda reserva nueva aparece en la lista de señas, en «Más adelante».
2. En la etapa D, un aviso al celular del consultorio que no depende de la persona.

**No registro si tocó el botón.** Tocarlo no prueba que haya enviado algo. Es el mismo criterio que ya usa el proyecto: que la persona haya visto la pantalla nunca cuenta como cobertura.

### 4.8 La lista de señas y el pedido por WhatsApp (promesa 5)

**La página.** Es una página nueva, «Señas», en el menú diario. Sólo aparece si la política no está apagada, y la ven dueña, administración y recepción. Tiene estas secciones:
1. **Para pedir:** pendientes cuya fecha de pedido ya llegó, ordenadas por vencimiento.
2. **Vencen en menos de 24 horas:** destacadas.
3. **Último momento: resolver a mano:** las que no se cancelan solas, incluidos los pedidos de reprogramación.
4. **Vencidas sin cancelar: decidir:** fuera de la ventana de 24 horas, o con la cancelación automática apagada.
5. **Más adelante:** plegada. Incluye las reservas recién hechas.
6. **Canceladas por falta de seña, últimos 7 días.** Cada una tiene dos botones:
   - «Avisar a la persona», que abre WhatsApp con el mensaje armado;
   - «Volver a dar este horario», que abre la agenda de ese día con el profesional, la persona y la prestación ya elegidos. La agenda hoy acepta esos datos en la dirección (`routes/odonto/agenda/+page.server.ts`, líneas 83 a 92), pero no la hora: precargarla en la carga manual es un agregado chico.

**Cada fila muestra:**
- nombre;
- día y hora, en la zona del consultorio;
- monto y vencimiento;
- qué pasó con el pedido, por ejemplo «WhatsApp abierto hace 2 horas por Aye».

Y tiene los botones «Pedir seña por WhatsApp», «Confirmar seña», «Exceptuar» y «Ver turno». Si la persona no tiene un teléfono válido, la fila lo dice y no muestra el botón de WhatsApp.

**«Pedir seña por WhatsApp».** Usa la misma redirección que Recordatorios: registra en la tabla de señas quién y cuándo lo abrió, y abre `wa.me`, o WhatsApp Web en una computadora, mediante `whatsappHrefFor`. Si ya se abrió, pide confirmación para no mandarlo dos veces.

**Mensaje (borrador para que Natalia lo apruebe):**
> Hola {nombre}. Te escribimos de {consultorio} por tu turno del viernes 20 de noviembre a las 10:00.
> Para confirmarlo necesitamos la seña de $ {monto} antes del miércoles 18 de noviembre a las 10:00.
> Datos para transferir: {datos}.
> Si no la recibimos para esa fecha, el turno se libera automáticamente.
> Si ya la transferiste, desestimá este mensaje (si podés, mandanos el comprobante por acá).
> Ver tu turno: {enlace}

La oración «se libera automáticamente» sólo aparece si ese turno se cancela solo y la cancelación automática del consultorio está encendida.

**En la agenda:**
- alertas como «3 señas para pedir hoy», «1 vence en menos de 24 horas» y «1 turno se canceló por falta de seña»;
- en cada tarjeta, el indicador de la seña.

**Lecturas acotadas.** Las consultas de la lista se paginan, con ventanas y con la regla de lectura evaluada una vez por consulta, como en `docs/architecture/control-de-consumo.md`.

### 4.9 Lo que ve la persona

**Antes de reservar.** El aviso aparece en el paso de confirmación, donde hoy se muestra la política de cancelación (`lib/booking/PublicBookingConfirmation.svelte`, línea 309):
> Este turno requiere una seña de $ {monto}. Tenés tiempo hasta el miércoles 18 de noviembre a las 10:00 para transferirla. Si no se registra, el turno se cancela automáticamente.

Hay otra versión para el último momento. Estas fechas las calcula la base con la misma función que usa el disparador, así que hay una sola regla. Es una consulta más, y sólo en ese paso.

**En la pantalla final y en `/turno/<token>`.** Un bloque de seña con el estado, el monto, el vencimiento, los datos para transferir y el botón de WhatsApp.
- Con la seña recibida: «Recibimos tu seña».
- Con la seña vencida: «Este turno se canceló porque no se registró la seña antes del {vencimiento}. Si ya transferiste, escribile al consultorio», con el botón de WhatsApp y «Reservar otro turno».

**«Confirmo que voy».** No aparece en los turnos con seña:
- mientras la seña está pendiente, en su lugar se muestra cómo pagar;
- cuando se resuelve, el turno ya queda Confirmado (sección 4.2).

Cancelar y pedir reprogramación siguen disponibles.

### 4.10 Horarios liberados (promesa 8)

**Cómo se registran.** Un disparador posterior en `appointments` actúa en dos casos:
- cuando un turno futuro y activo pasa a Cancelado;
- cuando un turno futuro cambia de horario.

En los dos casos anota en `appointment_slot_releases` el horario que quedó libre, con sus profesionales (también en los turnos de equipo). Lo hace en la misma transacción que el cambio, venga de la persona, del consultorio o de la baja automática.

**De dónde saca cada dato:**
- El horario anterior lo toma de la propia fila del turno antes del cambio (`OLD`), no de `appointment_professionals`. El disparador que sincroniza esa tabla, `appointments_sync_professionals`, también corre después de la actualización. Según el orden alfabético podría haberla dejado ya con el horario nuevo.
- De esa tabla sólo toma qué profesionales tenía el turno, que no cambian al cancelar ni al reprogramar.

**Qué muestra la agenda.** Un aviso «2 horarios se liberaron», con su lista:
- día, hora y profesional;
- el motivo: canceló la persona, canceló el consultorio, venció la seña o se reprogramó;
- el botón «Dar este horario», que abre la agenda en ese día y con ese profesional (la hora se precarga con el mismo agregado de la sección 4.8);
- el botón «Ocultar».

**Sólo se muestran los que siguen libres.** Una consulta de la base comprueba que ningún turno activo ni bloqueo ocupe el horario en ese momento:
- Si alguien lo reservó, desaparece solo.
- También desaparece cuando pasa la hora.

La ventana es de los próximos 14 días, configurable.

**Las correcciones rápidas no cuentan (revisión 1).** Si recepción carga un turno por error y lo mueve o lo cancela al minuto, ese horario no se «liberó»: nadie lo perdió. Para no generar una alerta falsa:
- El disparador guarda desde cuándo el turno ocupaba ese horario exacto. Es la creación del turno o, si ya se había movido, su último cambio de horario, que sale de la misma tabla de horarios liberados.
- La alerta sólo muestra los horarios que estuvieron ocupados al menos 30 minutos.
- Medirlo desde la creación del turno, como propone la crítica, deja un hueco. Un turno creado hace dos semanas que recepción mueve por error y devuelve a su lugar al minuto generaría una alerta falsa por el horario intermedio.
- El hecho queda registrado igual; sólo no se alerta. Tampoco alerta un turno que la persona reservó online y canceló a los pocos minutos; el horario igual vuelve a estar disponible en la web.

**No incluye lista de espera.** Natalia maneja los sobreturnos por fuera. Llevar la lista al sistema sería otra función.

**Dónde puedo estar equivocado.** Un horario ocupado en parte desaparece entero; por ejemplo, 60 minutos libres en los que alguien reservó 30. Lo hice simple a propósito; se puede refinar.

### 4.11 Recordatorio del día anterior (promesa 9)

**Qué cambia.** Recordatorios hoy sólo muestra los turnos de mañana sin aviso automático. Propongo mostrar todos los turnos de mañana, en dos grupos con el mismo botón:
- «Sin aviso automático», primero, igual que hoy;
- «Ya tienen aviso automático», plegado.

El aviso de la agenda sigue contando sólo los turnos sin aviso automático.

**Mensaje.** Se le agrega una oración:
> Si no podés venir, avisanos por acá o cancelalo desde el enlace, así le damos el horario a otra persona.

Eso alimenta los horarios liberados.

**Riesgo.** Una persona con aviso automático también puede recibir el WhatsApp. Es lo que pidió la clienta, y se decide fila por fila.

### 4.12 WhatsApp desde la ficha (promesa 3)

Un botón «WhatsApp» al lado de «Copiar teléfono» (`PatientProfilePanel.svelte`, líneas 254 a 264):
- Usa `normalizeArgentineWhatsAppPhone` y `whatsappHrefFor`.
- No lleva texto armado.
- Sólo lo ven los roles que ya ven el teléfono.

### 4.13 Aviso al celular del consultorio (etapa D, opcional y en pausa)

**Cómo funciona:**
- Notificaciones web al personal, con una tabla de suscripciones por usuario y consultorio.
- Una cola de avisos al personal. Es la misma que alimenta los avisos dentro de la app.
- El envío ocurre dentro de la tarea de notificaciones que ya corre cada 5 minutos, después de los recordatorios y dentro del mismo presupuesto. Con un consultorio sobra.

**Al enviar, se revalidan la membresía y el rol.** Quien dejó el consultorio no recibe nada.

**Qué avisa:**
- la baja automática, siempre;
- una reserva online nueva, opcional;
- un horario liberado, opcional.

**Texto neutral en la pantalla bloqueada.** Por ejemplo: «Turno del viernes 20 de noviembre a las 10:00 cancelado por seña». El detalle se ve al tocar el aviso.

**Según el teléfono:**
- En Android funciona en Chrome, sin instalar nada.
- En iPhone primero hay que hacer instalable la aplicación (manifiesto e ícono), y Natalia tiene que agregarla a la pantalla de inicio. Requiere iOS 16.4 o posterior.

Esto cambia la estructura general de la aplicación, por eso es una entrega aparte.

**Costo:** ninguno. **Procesador:** unos 2,7 milisegundos por envío según las mediciones existentes (`tareas-automaticas.md`), del mismo orden que lo que ya ocurre.

### 4.14 Correo electrónico (etapa E, promesas 6 y 11, en pausa)

| Opción | Costo | Límite | A favor | En contra |
|---|---|---|---|---|
| **Resend, plan gratuito** | Ninguno, sin tarjeta | 100 por día, 3.000 por mes, hasta 3 dominios | API por HTTPS (una llamada por correo); remitente `turnos@cita-suite.com.ar`; buena entrega con DKIM | Cuenta nueva a tu nombre; registros en el DNS; si cambian su plan gratuito, hay que mudarse |
| Gmail `citasuite@gmail.com` desde el Worker | Ninguno | 500 mensajes o destinatarios por día | Sin cuenta nueva | Cloudflare no documenta el puerto 587 (sólo bloquea el 25); hay que programar el protocolo de correo; si Google limita la cuenta por envíos automáticos, **también se cae la recuperación de contraseña**, que usa la misma cuenta |
| Cloudflare Email Service | Workers Paid, 5 dólares por mes | 3.000 incluidos | Integrado | Excluido por la restricción económica |

**Recomendación:** Resend gratuito, si autorizás crear la cuenta. La creás vos.

**Correos previstos:**
1. Confirmación de reserva con las condiciones de la seña, y el archivo de calendario con alarmas como adjunto, que refuerza la promesa 10.
2. Pedido de seña el día 7.
3. Aviso a la persona cuando su turno se cancela automáticamente.
4. En la segunda etapa, el recordatorio del día anterior con el enlace para confirmar asistencia.

**Envío:**
- Una cola que no repite un correo para el mismo turno, tipo y horario.
- Se envía dentro de la tarea de notificaciones existente, con un cupo propio.
- Cada correo lleva un enlace para dejar de recibirlos.

**DNS.** `docs/architecture/dominio.md` propone como pendiente opcional dos registros «mientras no envíe correo»: SPF `v=spf1 -all` y DMARC `p=reject`. Si se adopta Resend, hay que contemplar sus registros (DKIM y el SPF del subdominio de envío). No conviene aplicar el `-all` antes de decidir esto.

## 5. Cómo se evita que esto rompa otras cosas

**Área propietaria: agenda (`scheduling`).**
- Contratos puros, sin servidor, en `lib/scheduling/deposits.ts`: tipos, etiquetas y textos de los mensajes.
- Operaciones del servidor en `lib/server/scheduling/public/deposits.ts`.
- Los avisos al celular y el correo van en `integrations`.
- Las fronteras las comprueba `dependency-cruiser`, como hoy.

**La base de datos es la autoridad.** Permisos, transiciones, fechas, baja automática y horarios liberados se deciden en SQL. La pantalla sólo orienta.

**Una sola regla de fechas.** Es una función SQL que usan el disparador de alta, la reprogramación, la tarea y la consulta del paso de confirmación.

**Migración aditiva:**
- tablas y disparadores nuevos, entre ellos el de la regla «Confirmado exige seña resuelta», que sólo corre cuando cambia el estado;
- ninguna columna nueva en `appointments`, ningún estado nuevo y ninguna migración aplicada editada.

Permisos explícitos, como fija la guía:
- seguridad por fila (RLS) habilitada;
- todo revocado a `public`, `anon`, `authenticated` y `service_role`;
- se otorga exactamente lo que se usa.

Hay que actualizar `api_exposure_explicit.sql` y `write_expression_privileges.sql`. La lectura de la seña sigue la misma regla que la del turno, evaluada una vez por consulta, como en `appointment_read_set_based.sql`.

**Pruebas que se escriben primero y deben fallar sin la función:**

- **Base de datos descartable:**
  - Alta pública y manual: con monto, sin monto y con la política apagada.
  - Fechas con la zona de Córdoba, con un turno que cruza la medianoche de UTC.
  - Último momento.
  - Ninguna fila para los turnos anteriores a la migración.
  - La tarea cancela sólo lo que corresponde. Prueba un caso por cada condición de la sección 4.6: recibida, exceptuada, pidió reprogramar, ya empezó, consultorio suspendido, seña apagada, cancelación automática apagada, interruptor general apagado y vencida hace más de 24 horas.
  - Una falla provocada dentro de la tarea deshace todo: turno, seña, auditoría y horario liberado.
  - Después de la baja, otra persona puede reservar el mismo horario, también en turnos de equipo.
  - Permisos:
    - recepción puede;
    - profesional y sólo lectura no pueden;
    - otro consultorio no puede;
    - un consultorio suspendido no puede;
    - `anon` no ejecuta;
    - las escrituras directas a la tabla se rechazan.
  - Un deshacer después del vencimiento no cancela.
  - Un turno con seña pendiente no puede pasar a Confirmado por ninguna vía: el enlace de la persona, el botón genérico del consultorio o una escritura directa.
  - «Confirmar seña» deja seña recibida y turno Confirmado juntos, y «Deshacer» deja seña pendiente y turno Reservado juntos. Una falla provocada en el medio no deja un estado mezclado.
  - Monto: porcentaje del arancel del mes del turno, con ajuste mensual, redondeo y monto fijo cuando la prestación no tiene arancel. También la configuración que rechaza exigir seña sin arancel ni monto fijo.
  - Horarios liberados: una corrección rápida no alerta, incluido el caso de un turno viejo movido y devuelto al minuto. Un horario ocupado más de 30 minutos sí alerta.
  - La reprogramación recalcula con la fotografía, y una seña recibida se conserva.
  - Cambiar la política no toca las señas existentes; apagarla las exceptúa.
  - Repetir una acción no duplica nada.
  - Queda el registro de cada ejecución de la tarea.
- **Carreras con dos conexiones controladas en una misma prueba:**
  - «Confirmar seña» contra la tarea, en los dos órdenes: siempre un único resultado y ningún bloqueo mutuo.
  - Reprogramación contra la tarea, y reprogramación contra «Deshacer» (la regla de la sección 4.2 debe producir un conflicto, nunca Confirmado con la seña pendiente).
  - Inserciones de filas hijas con claves foráneas reales (seña, horario liberado) contra «Confirmar seña» y contra la tarea, con el contador de bloqueos mutuos de la base en cero, como ya se exige en las corridas completas desde la etapa 4.
  - La tarea contra un turno que recepción ya bloqueó, con su seña todavía libre: la tarea lo saltea, no toma la seña, y recepción termina sin esperar a la tarea.
  - Apagar la política mientras recepción confirma una seña, y mientras corre la tarea.
- **Disparadores:**
  - La seña de un turno nuevo usa el arancel recién calculado.
  - Reprogramar un turno de equipo anota, para cada profesional, el horario anterior y no el nuevo.
- **Unidad:**
  - Textos exactos de cada mensaje, con la zona horaria, el formato de pesos, nombres largos y datos faltantes.
  - Enlaces `wa.me`.
  - Identificadores inválidos que responden 404.
  - Modo demo.
  - El nuevo criterio de Recordatorios.
- **Navegador:**
  - Condiciones de la seña antes de reservar.
  - Botones de WhatsApp de la pantalla final, con el número y el texto codificado.
  - La lista de señas.
  - «Confirmar seña», que se refleja en la agenda y en la página de la persona.
  - Baja automática visible, con datos sintéticos vencidos y la tarea invocada en el entorno descartable.
  - Horarios liberados que aparecen y desaparecen.

  Las pruebas de comportamiento nuevo llevan la etiqueta `@candidate-behavior`, que la fase de compatibilidad con la versión anterior excluye, como ya fija `verificacion.md`.
- **Matriz visual:**
  - anchos de 320, 390, 768, 1280 y 1600 píxeles;
  - tema claro y oscuro de Natalia;
  - teclado y contenido largo, con `layoutIssues`.

**Verificación completa en CI:** fast, full y release (incluye el ensayo de vuelta atrás), y después staging con datos sintéticos. Todo en secuencia, como siempre.

**Volver atrás: el punto delicado.** La tarea vive en la base y no depende de la versión de la aplicación. Si se vuelve a la aplicación anterior con la política activa, pasarían dos cosas:
- la tarea seguiría cancelando turnos cuyas señas nadie puede registrar, porque la versión anterior no tiene los botones;
- las personas reservarían sin ver las condiciones.

Por eso:
1. La entrega se publica con el interruptor general y la política apagados.
2. El procedimiento para volver atrás empieza apagando el interruptor general, antes de volver la aplicación.
3. El ensayo en staging comprueba ese orden, y que la aplicación anterior funciona con filas de seña presentes.

**Copias de respaldo.** Hay que comprobar que la copia incluye las tablas nuevas y que la restauración de prueba las trae.

**Documentación.** Se actualizan la matriz de regresiones (puntos 2, 4 y 12), la matriz de permisos y los contratos funcionales, y la historia del turno muestra las acciones nuevas con su texto.

## 6. Plan de entregas (revisado)

Hoy no hay pacientes reales, así que no tiene sentido publicar por partes ni programar dos veces el mismo botón. Las tres primeras etapas se desarrollan de corrido y se publican juntas, antes del lanzamiento.

| Etapa | Qué incluye | Base de datos | Riesgo |
|---|---|---|---|
| **A. Botones y textos** | WhatsApp al terminar la reserva, programado una sola vez con sus dos variantes (con seña y sin seña); WhatsApp en la ficha; todos los turnos de mañana en Recordatorios, con la oración nueva; llamado claro para activar el recordatorio desde la pantalla final de Natalia | No | Bajo |
| **B. Señas** | Política, porcentaje del arancel, seña por turno, unificación con Confirmado, acciones, lista, mensajes, pantalla de la persona, condiciones antes de reservar, baja automática con interruptor por consultorio y general, registro de ejecuciones y poda del historial de pg_cron | Sí, aditiva | Medio |
| **C. Horarios liberados** | Registro, filtro de correcciones rápidas, alerta y «Dar este horario» | Sí, aditiva | Bajo a medio |
| **D. Aviso al celular (opcional, en pausa)** | Notificaciones web al personal; manifiesto instalable si Natalia usa iPhone | Sí, aditiva | Medio: toca la estructura de la aplicación y la tarea de notificaciones |
| **E. Correo (opcional, en pausa)** | Proveedor, cola, plantillas y registros DNS | Sí, aditiva | Medio |

**Cómo se verifica y se publica:**
1. Cada etapa (A, B y C) se verifica por separado en CI, en ese orden, con sus pruebas que fallan primero. Así, si algo falla, se sabe en qué etapa está.
2. Con las tres aprobadas, se hace una corrida completa de release sobre el conjunto y una pasada por staging con datos sintéticos.
3. Una sola publicación en producción, con copia de respaldo y tu autorización expresa. Cada publicación cuesta una copia, detener el programador con 15 minutos de margen y el ensayo de vuelta atrás; hacerla una vez en lugar de tres ahorra dos de esas ventanas.
4. Se publica con la seña y la cancelación automática apagadas. Natalia las configura y las enciende antes del lanzamiento.
5. Las etapas D y E quedan en pausa hasta cerrar A, B y C.

## 7. Riesgos que quedan y cómo se ven

| Riesgo | Mitigación | Cómo se detecta |
|---|---|---|
| La persona no toca el botón de WhatsApp al reservar | La reserva aparece igual en la lista de señas; aviso al celular en la etapa D | — |
| Recepción cobra una seña y olvida registrarla, y el turno se cancela | Sección «Vencen en menos de 24 horas», la opción de empezar con la cancelación automática apagada, mensaje que pide el comprobante; después de la baja, «Volver a dar este horario» si sigue libre | Auditoría y lista de canceladas |
| La tarea deja de correr | Registro de ejecuciones visible; si se detiene no cancela nada; la ventana de 24 horas evita cancelaciones masivas al volver | Alerta en la página de señas |
| El monto queda viejo por la inflación | Porcentaje del arancel, que ya se ajusta por mes; cada turno guarda el suyo | — |
| Una corrección rápida de recepción aparece como horario liberado | Sólo alertan los horarios ocupados al menos 30 minutos (4.10) | Pruebas de la sección 5 |
| Bloqueo mutuo entre «Confirmar seña», la tarea y las inserciones con claves foráneas | `FOR NO KEY UPDATE`, orden turno y después seña, y la tarea que nunca espera | Contador de bloqueos mutuos en cero en las corridas completas |
| Recepción edita el mensaje antes de enviarlo y pone un dato equivocado | El sistema no lo puede impedir: es texto libre dentro de WhatsApp | — |
| Volver atrás con la política activa | Orden de reversión de la sección 5 | Ensayo en staging |
| Confusión entre el estado del turno y la seña | Unificados en la base: «Confirmar seña» confirma el turno, y etiqueta, filtros y conteos coinciden (4.2) | Lo que cuente Natalia |
| Límite del correo gratuito (100 por día) | La cola respeta el cupo y sigue al día siguiente; un consultorio queda muy por debajo | Conteo diario |

## 8. Lo que descarté y por qué

- **WhatsApp automático con la API de Meta:**
  - el plan aprobado lo descarta;
  - Meta cobra cada mensaje de plantilla enviado fuera de la ventana de atención de 24 horas, y el precio para Argentina se publica en pesos y cambia: no lo pude verificar en su tabla oficial;
  - exige verificar la empresa y aprobar plantillas.

  Puede reconsiderarse cuando haya ingresos recurrentes.
- **Cobrar la seña con Mercado Pago:**
  - confirmaría la seña sola, sin que recepción toque nada;
  - pero suma comisiones por cobro para Natalia, credenciales de su cuenta, devoluciones y avisos de pago por consultorio;
  - no está en lo aprobado.

  Es una mejora futura natural.
- **Estado nuevo del turno, columnas en la tabla de turnos y cálculo al leer:** secciones 4.1 y 4.6.
- **Unificación sólo visual de Confirmado:** sección 4.2.
- **Modo prueba propio:** sección 4.6.
- **Monto fijo como regla general, y monto base con su propio ajuste mensual:** sección 4.3.
- **Sexto disparador de Cloudflare:** no hay cupo gratuito.
- **Cloudflare Email Service:** pago.
- **Gmail desde el Worker:** pone en riesgo la recuperación de contraseña (sección 4.14).
- **Push a pacientes de Android pidiendo la seña:**
  - sería automático y gratis, pero toca la cola de notificaciones ya verificada;
  - sólo alcanza a quien activó las notificaciones.

  Lo dejo como mejora posible.

## 9. Preguntas

### Para vos

1. ¿Estás de acuerdo con el principio de la sección 1.3: ante la duda, no cancelar?
2. ¿Aprobás la unificación de la seña con Confirmado en la base (sección 4.2, revisada)?
3. ¿Aprobás desarrollar las etapas A, B y C de corrido y publicarlas juntas antes del lanzamiento?
4. Correo: ¿autorizás crear una cuenta gratuita de Resend en la etapa E? La creás vos.
5. Aviso al celular: ¿lo hacemos? Depende en parte de la pregunta 8 para Natalia.
6. ¿Puedo leer, sin modificar nada, la configuración del consultorio de Natalia en producción? Sería el número de WhatsApp, el formulario de reserva y las prestaciones, para confirmar los supuestos de la sección 1.5.

### Para Natalia

1. ¿Qué porcentaje del arancel es la seña? ¿Es el mismo para todas las prestaciones?
2. ¿Confirma 7 días para pedirla y 48 horas para el vencimiento? ¿Le parecen bien 24 horas como plazo mínimo para pagar?
3. Reservas de último momento: ¿las resuelve a mano, como recomiendo, o prefiere no permitir reservas online con menos de 72 horas?
4. ¿Exige seña también en los turnos que carga el consultorio por teléfono?
5. Si alguien pidió reprogramar y no pagó, ¿espera a resolverlo ella, como recomiendo?
6. ¿Quiere unos días después del lanzamiento con la cancelación automática apagada, para observar antes de que cancele de verdad?
7. Datos para transferir: alias, CBU y titular.
8. ¿Su celular es Android o iPhone? ¿Quién registra las señas: ella, Aye o las dos?
9. ¿Aprueba los borradores de los mensajes?
10. Si la persona cancela, ¿la seña se devuelve, no se devuelve o se devuelve hasta cierta fecha? Es para el texto que se muestra antes de reservar.
11. ¿Sabe que las alarmas del iPhone y las notificaciones de Android requieren que la persona las active una vez en la página de su turno?

## 10. Fuentes externas

- [Cloudflare Email Service, precios](https://developers.cloudflare.com/email-service/platform/pricing/): «Sending to arbitrary recipients requires the Workers Paid plan».
- [Cloudflare Workers, conexiones TCP](https://developers.cloudflare.com/workers/runtime-apis/tcp-sockets/): puerto 25 bloqueado; `startTls()` requiere `secureTransport: "starttls"`.
- [Resend, cuota](https://resend.com/docs/knowledge-base/resend-email-quota): plan gratuito de 100 correos por día y 3.000 por mes, hasta 3 dominios verificados.
- [Gmail, límites de envío](https://support.google.com/mail/answer/22839?hl=es): más de 500 destinatarios o mensajes en un día.
- [Supabase Cron, guía rápida](https://supabase.com/docs/guides/cron/quickstart): el historial `cron.job_run_details` no se limpia solo.
- [Meta, precios de la plataforma de WhatsApp](https://developers.facebook.com/docs/whatsapp/pricing): cobro por mensaje de plantilla.
- Restricciones de calendario y notificaciones en iPhone y Android: `docs/plan-calendario-direccion-recordatorios.md`, secciones 1 y 12, ya verificadas en ese plan.

## 11. Revisión 1: qué cambió y por qué

El 29 de octubre se revisó la propuesta a partir de dos cosas: una crítica externa y tu aclaración de que hoy no hay pacientes reales.

| Punto de la crítica | Qué hice | Por qué |
|---|---|---|
| La seña ignora el ajuste por inflación | **Aceptado.** La seña es un porcentaje del arancel cotizado para la fecha del turno (4.3). | El motor de aranceles con ajuste mensual existe y fotografía el arancel en cada turno. No encontré escrita la promesa a Natalia de ajustar las señas, pero el motor alcanza para hacerlo sin programar un cálculo nuevo. |
| El modo prueba es innecesario | **Aceptado.** Eliminado (4.6). | Sin pacientes reales, antes del lanzamiento no hay nada que observar. Si se quiere observar después, alcanza con la cancelación automática apagada, que se necesita igual. |
| El botón de WhatsApp se programa dos veces y las entregas van separadas | **Aceptado.** Etapas A, B y C de corrido y una sola publicación (6). | Sin pacientes reales, publicar por partes no da nada a cambio, y cada publicación cuesta una ventana completa. Se mantiene la verificación por etapas para saber dónde está una falla. |
| La dualidad entre «Seña recibida» y Confirmado | **Aceptado el problema, con otra solución.** Unificación en la base, no en la pantalla (4.2). | La unificación sólo visual haría que la etiqueta, los filtros y los conteos digan cosas distintas. |
| Alertas falsas de horarios liberados | **Aceptado, con un ajuste.** Se mide cuánto tiempo el turno ocupó ese horario exacto, no su antigüedad (4.10). | Medir desde la creación deja pasar el caso de un turno viejo movido por error y devuelto al minuto. |
| Bloqueos `FOR NO KEY UPDATE` | **Aceptado.** Agregado a las funciones y a la tarea (4.5 y 4.6) y a las pruebas de carreras (5). | Es la lección concreta del bloqueo mutuo `40P01` de la etapa 4. |
| Correo y aviso al celular en pausa | **Aceptado** (6). | Dependen de decisiones que todavía no están tomadas. |
| Leer la configuración de Natalia en producción | **Pendiente de tu autorización expresa.** | La crítica la recomienda, pero la decisión es tuya. |

### Revisión 2 (29 de octubre): segunda crítica

| Punto | Qué hice | Por qué |
|---|---|---|
| Orden inverso de bloqueo entre recepción y la tarea | **Aceptado el riesgo, con otra corrección.** Regla de bloqueo única (4.5): ninguna escritura sobre una seña sin tener bloqueado su turno. La tarea bloquea sólo turnos y después escribe sus señas (4.6). | El documento no fijaba el orden de la tarea, y con el orden inverso el bloqueo mutuo era posible. La corrección propuesta, bloquear turno y seña en la misma consulta, depende de un orden que PostgreSQL no documenta. |
| Orden de los disparadores al crear la seña | **Correcto como principio; en este caso ya se cumplía.** Quedó explícito (4.3). | El arancel se calcula antes de la inserción, y PostgreSQL corre todos los disparadores anteriores antes que los posteriores. |
| Qué lee el disparador de horarios liberados (hallazgo propio) | **Corregido** (4.10). | Aplicando el mismo principio de orden: si leyera el horario de la tabla que sincroniza `appointments_sync_professionals`, podría obtener el horario nuevo en lugar del anterior. |
| Apagar la política (hallazgo propio) | **Corregido** (4.3). | Tenía que respetar la regla de bloqueo y no debía confirmar los turnos. |
| «Confirmo que voy» (hallazgo propio) | **Precisado** (4.2 y 4.9). | «Nunca en turnos con seña» contradecía el caso de la política apagada. |

## Anexo A: texto aprobado por la clienta (literal)

> Sobre el aviso de turnos nuevos: cuando la persona saca el turno por la web, el sistema le crea la ficha automáticamente con todos sus datos y el teléfono, sin que ustedes tengan que cargar nada a mano. Para que no tengan que estar revisando la pantalla a ver si alguien reservó, al terminar la reserva le salta un botón para mandarles un WhatsApp con su nombre, fecha y hora. Así ya les queda el aviso en el celular y el chat abierto. De todas formas, podes comunicarte con cada paciente por Whatsapp buscando su nombre en la app.
>
> Sobre el pago de la seña:
> Si la persona quiere transferir en el momento, puede mandar el comprobante por ese mismo chat. Ustedes van al turno en el sistema, tocan confirmar y listo.
> Si prefiere pagar más adelante, el turno queda reservado. A los 7 días antes de la fecha, en el sistema les aparece la lista de señas pendientes con un botón para mandarle un recordatorio por WhatsApp en un solo clic. El mensaje ya sale redactado pidiendo la seña y aclarando que si ya transfirió, desestime el aviso. Como complemento, tambien le podria llegar un email pidiendo la confirmación
>
> Sobre la baja automática: si se cumple la fecha límite que definamos (por ejemplo 48 horas antes) y no está confirmada la seña, el turno se cancela solo y el horario se libera de nuevo en la web automáticamente. Esto te lo avisa en la propia app, pero tambien esta la posibilidad de que te notifique al celular si queres.
>
> Sobre los huecos libres: para que no les queden baches vacíos si alguien cancela o reprograma, el turnero les muestra una alerta destacada con los horarios que se liberaron. Así pueden reasignarlos rápido a los pacientes que estén esperando un sobreturno.
>
> Y por último, el día anterior al turno les queda también el botón para mandar el recordatorio final de asistencia con un solo clic. Ademas, en el caso de Iphone se le agenda una alarma en su teléfono y en el caso de Android les llega automaticamente una notificacion a su celular.
> En una segunda etapa podrian enviarse recortatorios y pedidos de cofirmacion automaticos por email

## Anexo B: lo que pidió en los audios (resumen de las transcripciones)

1. Necesitan que la persona confirme y valide su turno con la seña antes de la fecha. Su ejemplo: un turno del 20 de noviembre, confirmado el 13. Preguntó si el sistema les avisa o si tienen que ir corroborando a mano.
2. Mencionó la posibilidad de pedir la seña 14 días antes, «si eso se puede configurar». Por eso los días son un ajuste. Si no se confirma, que se dé de baja. Preguntó si el consultorio se entera de un turno nuevo o si tiene que ir entrando al turnero.
3. Pidió que cancelaciones y reprogramaciones les avisen, para no quedar con «baches vacíos». También que, como pasa con la venta de suplementos, al reservar les lleguen por WhatsApp nombre, apellido y obra social, para agendar los teléfonos nuevos. La primera confirmación, 7 días antes, pide la seña y aclara que si ya la hizo la desestime. El mensaje del día anterior es sólo un recordatorio, del estilo «Te esperamos mañana a las 10».
4. Si alguien paga la seña mucho antes, el aviso igual tiene que pedirle el comprobante, para que el consultorio pueda corroborar que las señas están hechas.

## 12. Aprobación y ajustes posteriores

Esta sección sólo crece hacia el final. Cada ajuste dice qué cambia, por qué, qué secciones anteriores reemplaza en ese punto y cómo se verifica. Lo que no se nombra acá sigue valiendo tal cual se aprobó.

### 12.1 Aprobación (29 de octubre de 2026, literal)

> Apruebo integramente tu propuesta, necesito que acutes con el rigor mas extremo posible, no dejes pasar ninguna inconsistencia bug ni error silencioso. No te confies nunca, un test verde no demuestra ausencia de bugs silenciosos ni consistencia. Si en el camino consideras apropiado ajustar alguno de los puntos del plan hacelo, pero deja absolutamente todo documentado. Segui una forma de trabajo como la que se siguio en la refactorizacion de cita suite. Tambien, te voy a dejar todo lo que ella me paso, registralo

Junto con la aprobación llegó la información de Natalia, registrada en `docs/clientes/natalia-frutos/informacion-20261029.md`.

**Cómo se aplica:**
- **La forma de trabajo de la refactorización:**
  - este plan es la fuente de verdad;
  - el registro (`registro-senas-avisos-natalia.md`) anota cada cambio, prueba, corrida, falla, decisión y pendiente, con su identificador, su SHA y su evidencia;
  - el traspaso (`traspaso-senas-avisos-natalia.md`) fija el punto exacto donde quedó el trabajo;
  - las pruebas se escriben primero y tienen que fallar;
  - la verificación pesada corre sólo en CI y en secuencia;
  - las candidatas se arman con índices temporales, sin tocar el HEAD ni el índice del repositorio;
  - staging va antes que producción, y producción sólo con autorización expresa.
- **Criterio crítico:** un verde no prueba que no haya errores. Cada cierre se intenta refutar con pruebas adversarias y con una lectura posterior en la base de datos.

### 12.2 Ajuste 1 (29 de octubre): la seña puede ser un monto fijo, y la de Natalia lo es

**Qué cambia.** La política de seña tiene dos formas de calcular el monto, a elección del consultorio:
- **Monto fijo:** un importe en pesos, el mismo para todas las prestaciones que exigen seña. El de Natalia es $40.000.
- **Porcentaje del arancel:** lo que describe la sección 4.3, con su redondeo y su respaldo de monto fijo.

En los dos casos el monto queda guardado en el turno al reservar, y cambiar la política sólo afecta las reservas nuevas (4.3).

**Por qué.**
- Natalia informó que pide «una seña de 40000 pesos», un monto fijo.
- Sus honorarios dependen de la obra social: la orden más $87.000, o $115.000 particular. Un porcentaje daría señas distintas según la obra social, y ella no pidió eso.
- Además pidió no aplicar aumentos automáticos por ahora.

La revisión 1 había elegido el porcentaje como forma principal por el ajuste por inflación. Con estos datos, para Natalia el monto fijo es el correcto; el porcentaje queda como opción para otros consultorios.

**Qué reemplaza:**
- **Sección 0, punto 3, y sección 1.5:** el porcentaje del arancel deja de ser la regla; el monto es el que elija el consultorio.
- **Sección 4.1:** `percentage` y `reference_amount` quedan nulos cuando el monto es fijo.
- **Sección 4.3, «Monto»:** la forma fija pasa a ser una opción de primer nivel, no sólo de respaldo.

**Pruebas que agrega:**
- una seña fija queda igual en las dos prestaciones;
- cambiar el monto fijo no toca las señas existentes;
- un consultorio con porcentaje sigue calculando sobre el arancel;
- la configuración rechaza una forma de cálculo sin un monto válido.

### 12.3 Observación sin cambio de plan: «no es determinante para sacar el turno»

Natalia dijo que hoy la seña «no es determinante para sacar el turno». El plan ya no bloquea ninguna reserva por la seña, así que esto no cambia nada.

Queda abierto si quiere la cancelación automática que aprobó en su texto. El plan publica con la cancelación automática apagada (sección 6), y se enciende sólo cuando ella responda (pregunta 3 de la sección 5 del documento con su información).

### 12.4 Información de Natalia que no es de esta campaña

El documento con su información clasifica, en su sección 3, la configuración de su turnero (prestaciones, horarios, modalidades, obras sociales) y su web. Nada de eso entra en esta campaña, salvo tres datos que la campaña usa:
- el número de WhatsApp del consultorio;
- los datos de transferencia;
- el monto de la seña (ajuste 1).

Hay tres cosas que necesitan decisiones aparte (sección 4 de ese documento):
- cargar su configuración en producción;
- la función de notas por opción para el recordatorio del token;
- un arancel según la obra social.

### 12.5 Ajuste 2 (29 de octubre): el hallazgo 7 era falso; las pacientes de Natalia terminan en `/turno/<token>`

**Qué estaba mal.** El hallazgo 7 (sección 3) decía que las pacientes de Natalia terminan la reserva en la pantalla final de la integración, `/embed/v1/<clave>/turno/<token>`, y no en `/turno/<token>`. Las dos revisiones críticas lo dieron por bueno. Es falso, por tres hechos verificados en el código al empezar la etapa A:
1. **La web de Natalia no abre un marco.** Navega como página completa a `/embed/v1/<clave>?color_mode=light`, sin `parent_origin` ni `instance_id` (`apps/natalia/src/lib/booking-config.ts`, línea 13). Su propio código lo dice: «No iframe, booking SDK or separate confirmation flow lives on this website» (`apps/natalia/src/scripts/public.ts`, líneas 56 a 58).
2. **Sin esos parámetros, el servidor manda directo a `/turno/<token>?creado=1` al confirmar la reserva** (`apps/web/src/lib/server/scheduling/public/public-booking-page.ts`, líneas 346 a 355).
3. **La pantalla final de la integración sólo se ve dentro de un marco.** Fuera de un marco redirige a `/turno/<token>` (`apps/web/src/routes/embed/v1/[integrationKey]/turno/[token]/+page.server.ts`, líneas 16 a 20).

**Qué cambia:**
- **El aviso al consultorio por WhatsApp va en `/turno/<token>`.** Al terminar la reserva aparece arriba, como «Avisar al consultorio por WhatsApp». Si la persona vuelve después, aparece debajo de los datos del turno, como «Escribir al consultorio por WhatsApp», con un mensaje que no dice que recién reservó.
- **La pantalla final dentro del marco no cambia.** Hoy ninguna web la usa, y su botón «Ver y gestionar mi turno» lleva a `/turno/<token>`, donde está el aviso. Cambiarla sumaría riesgo, porque tiene sus propias pruebas de navegador, sin ningún beneficio actual.
- **Promesa 10 (sección 2): no hay «un toque más».** Las pacientes de Natalia aterrizan en la página que ya tiene el calendario y las notificaciones. El punto de la etapa A «llamado claro para activar el recordatorio desde la pantalla final de Natalia» se retira: no hay pantalla que mejorar.
- **Sigue en pie la advertencia de la promesa 10:** la alarma y la notificación necesitan que la persona las active una vez. Eso no cambia.

**Lección.** Un hallazgo que dos revisiones aceptaron también puede estar mal. Por eso cada etapa vuelve a leer el código que toca, antes de programar.

### 12.6 Ajuste 3 (29 de octubre): el consultorio no tiene un botón genérico para confirmar

**Qué estaba mal.** El hallazgo 1 (sección 3) y la sección 4.2 dicen que hoy el consultorio confirma turnos con un botón genérico (`appointments.ts`, línea 455), y que con la seña pendiente ese botón queda bloqueado por la regla de la base. La función `updateAppointmentStatus` acepta Confirmado, pero ninguna pantalla del consultorio la usa para eso:
- la agenda responde «La confirmación queda reservada al paciente desde su enlace» (`routes/odonto/agenda/+page.server.ts`, líneas 508 a 510);
- el detalle del turno responde lo mismo (`routes/odonto/turnos/[appointmentId]/+page.server.ts`, líneas 250 a 252).

Hoy un turno pasa a Confirmado sólo por el enlace de la persona o por una reprogramación que conserva ese estado.

**Qué cambia:**
- **No hay un botón genérico que reemplazar.** «Confirmar seña», «Exceptuar» y «Deshacer» se agregan en la agenda, en el detalle del turno y en la lista de señas, como dice la sección 4.2.
- **La regla de la base sigue cubriendo cualquier vía**, incluida una pantalla futura que deje confirmar al consultorio. La prueba SQL comprueba tres:
  - la escritura directa;
  - la actualización del servidor para el enlace de la persona, como `service_role` y con el estado observado;
  - una actualización de estado hecha por recepción, con la seguridad por fila.
- **Un turno sin seña sigue sin poder confirmarse desde el consultorio**, como hoy.

**Qué no cambia:** ninguna decisión aprobada. Es la corrección de un hecho.

**Lección.** Igual que en el ajuste 2: el hallazgo describía lo que acepta una función, no lo que hace la pantalla que la usa.

### 12.7 Ajuste 4 (30 de octubre): las condiciones de la seña se piden al elegir el día

**Qué estaba previsto.** La sección 4.9 dice que las condiciones de la seña se calculan en la base con la misma función que usa el disparador, como «una consulta más, y sólo en ese paso», el de confirmación.

**Por qué no se puede así.** La carga del turnero tiene prohibido leer el horario elegido (`lib/server/scheduling/public/public-booking-page.ts`, línea 59). Elegir un horario no recarga la página, y por eso es instantáneo. Una consulta que dependa del horario obligaría a romper esa regla o a agregar una llamada desde el navegador al llegar al paso de confirmación.

**Qué cambia:**
- Al elegir el día, la carga pide con **una sola consulta** las condiciones de todos los horarios de ese día: `public.get_deposit_terms_for_slots`, que reemplaza a `get_deposit_terms` antes de que se aplicara en ningún entorno.
- Usa la misma función privada del disparador (`private.deposit_terms`) y la misma cotización que fija la reserva, así que sigue habiendo una sola regla.
- Al elegir el horario, el resumen muestra el aviso al instante, **antes** del botón «Confirmar reserva». La sección 4.9 lo ubicaba donde está la política de cancelación, que queda debajo del botón.
- La consulta no devuelve los datos para transferir: la persona los ve en la página de su turno, una vez reservado.
- Si las condiciones no se pueden calcular, la reserva sigue (la seña «no es determinante», 12.3). El resumen dice «No pudimos calcular si este turno requiere una seña. Si corresponde, la vas a ver al terminar la reserva».

**Por qué es seguro mostrarlas antes de reservar.** Entre el aviso y la reserva, el tiempo sólo avanza. Por eso la cancelación automática sólo puede pasar de «sí» a «no» (se acorta el plazo para pagar), y nunca al revés: lo peor es avisar una cancelación que después no ocurre. El monto y el vencimiento no dependen del momento.

**Cómo se verifica:**
- la prueba SQL 16 compara cada horario con la regla, incluido uno de último momento;
- las pruebas del servidor exigen una respuesta por cada horario pedido, sin horarios ajenos;
- las pruebas del turnero comprueban el texto, su lugar antes del botón y los casos sin seña y sin condiciones.

### 12.8 Autorización anticipada de producción (30 de octubre de 2026, literal)

> Te concedo por adelantado la autorizacion para escribir en produccion y probar lo que sea necesario

**Cómo se aplica:** Juan autoriza por adelantado las escrituras y pruebas necesarias en producción para completar esta campaña. Sustituye la espera de autorización expresa para cada publicación o escritura que exigían las secciones 1.2, 5, 6 y 12.1 y las reglas anteriores de `AGENTS.md` y del traspaso. No hay que volver a pedir ese permiso.

**Controles que se conservan:** verificar A, B y C, release sobre la revisión exacta, staging primero, copia y recuperación verificadas, reversión compatible y comprobación del destino. Las pruebas usan datos sintéticos propios, acotados y con limpieza comprobada; el consultorio de Juan sigue sin usarse como fixture. No autoriza contrataciones, inventar decisiones de configuración de Natalia ni iniciar las etapas D y E. La entrega conserva la seña y la cancelación automática apagadas hasta contar con las decisiones de la clienta.

### 12.9 Ajuste 5 (30 de octubre): revalidar las condiciones mostradas antes de reservar

**Defecto reproducido.** El ajuste 4 (12.7) afirmaba que el monto y el vencimiento no dependen del momento. Eso supone una política sin cambios: el consultorio puede editar el monto o los plazos mientras una persona tiene abierto el resumen. La prueba SQL nueva reprodujo que un resumen de $40.000 no impedía guardar una seña de $50.000 después de editar la política (`41011128875`, `TEST_STALE_DEPOSIT_TERMS OK`).

**Qué cambia:** el formulario conserva las condiciones que mostró para el horario elegido, sin recalcularlas en JavaScript. El servidor valida esos tres datos y los envía en un encabezado propio de la petición de reserva. PostgREST expone ese encabezado dentro de la transacción; el mismo disparador que crea la seña lo compara con las condiciones vigentes, teniendo bloqueada la política. Cubre todas las vías de alta pública sin duplicar funciones ni cambiar firmas RPC.

- Si cambian monto o vencimiento, o la reserva pasa a cancelarse automáticamente cuando no se había avisado, no se crea el turno ni su ficha: se pide revisar el resumen actualizado y confirmar otra vez.
- Si se retira la seña o se apaga la cancelación automática, la reserva continúa con la condición menos exigente.
- «Desconocida» conserva el aviso y la reserva permitida del ajuste 4. La ausencia del encabezado conserva compatibilidad con la versión anterior; el retorno a esa versión sigue requiriendo apagar la función primero.
- Recuperar una reserva ya guardada sigue devolviendo esa reserva; no se vuelve a cotizar una operación que ya terminó.

**Qué reemplaza:** la justificación «Por qué es seguro» del ajuste 4. Su consulta por día, aviso previo y alternativa cuando no se pudieron calcular las condiciones siguen vigentes.

**Pruebas:** condiciones viejas, ninguna → requerida, activación de cancelación, cambio de vencimiento, condiciones válidas, desconocidas y relajadas; transporte de los datos del formulario hasta la transacción; nueva confirmación de navegador con lectura posterior. Fuente del alcance transaccional de encabezados: [PostgREST, transaction-scoped settings](https://docs.postgrest.org/en/stable/references/transactions.html#request-headers-cookies-and-jwt-claims); `setHeader` se verificó también en la versión instalada del SDK y clona los encabezados del constructor de cada petición.

### 12.10 Ajuste 6 (30 de octubre): conservar también el movimiento desde un horario pasado

**Hueco detectado al preparar las pruebas de C.** La sección 4.10 registra cambios de horarios futuros. Pero un turno viejo puede moverse desde una fecha pasada a una futura y cancelarse al minuto. Sin conservar ese movimiento, la antigüedad del horario nuevo se calcularía desde la creación del turno y daría una alerta falsa.

**Qué cambia:** el registro conserva cancelaciones y movimientos de turnos activos aunque el horario anterior ya haya pasado. La alerta sigue mostrando exclusivamente horarios futuros que estuvieron ocupados al menos 30 minutos y siguen libres. No se agregan alertas de turnos pasados. La prueba C8 reproduce el movimiento pasado → futuro → cancelación rápida.

**Qué reemplaza:** sólo la restricción de registrar hechos futuros en 4.10. El resto de sus condiciones y el filtro de correcciones rápidas se mantienen.

### 12.11 Ajuste 7 (30 de octubre): recuperación compatible con señas ya existentes

**Hueco detectado al preparar el release.** La sección5 pide apagar el interruptor general antes de volver la aplicación. Eso detiene altas de señas y la baja automática, pero no elimina la guardia que impide confirmar una seña pendiente. Una aplicación sin controles para resolverla dejaría ese turno sin una vía de confirmación.

**Qué cambia:** la recuperación de esta entrega se fija sobre el checkpoint **A/B ya verificado** (`bdd8eef`, etapa B v10), con una adaptación exclusiva del texto de historia para reconocer el aviso ocultado de C. Conserva los controles para resolver señas existentes, sin los avisos nuevos de horarios liberados. No se exceptúan ni se alteran obligaciones para hacer compatible una versión sin esa función.

Se empaqueta como revisión distinta, se verifica con el esquema completo y con filas de seña presentes, y se ensaya en staging antes de usarla en producción. El interruptor general se apaga primero igualmente. La versión que producción sirve al empezar (`aacba5b`) queda como antecedente comprobado; no se la llama compatible sin la prueba. El ensayo de recuperación puede servir brevemente el checkpoint, con automatización apagada, dentro de la misma ventana controlada; la entrega final continúa siendo A/B/C juntas.

**Qué reemplaza:** precisa cuál es la «aplicación anterior» de la sección5 y la recuperación de 6.2. Conserva respaldo, recuperación de datos, una sola entrega final y todos los controles de publicación.

### 12.12 Reanudación de configuración y D/E (30 de octubre)

**Pedido literal posterior al cierre A/B/C:** «avancemos en esto», sobre la frase seleccionada «Queda completar la configuración de Natalia; D/E continúan en pausa».

**Aplicación:** se reanuda el trabajo sobre esos tres pendientes. Sustituye la pausa de D/E en4.13,4.14,6 y12.8, sin alterar el cierre comprobado de A/B/C. El orden de implementación sigue siendo D y luego E, con candidatas aisladas sobre C9, pruebas que fallan primero, CI secuencial y staging/release/respaldo/reversión antes de otra publicación. La autorización productiva12.8 sigue vigente para las operaciones necesarias; no se vuelve a pedir.

**Datos y límites que siguen vigentes:** no se inventa el consultorio/cuenta de Natalia, su WhatsApp ni los datos de transferencia. La seña conocida es fija de$40.000 y no se activan aumentos ni cancelación automática sin resolver las decisiones registradas. Se solicitó identificar la cuenta/consultorio y esos datos, los teléfonos utilizados y si ya existe Resend. Mientras llegan, se avanza con implementación y pruebas independientes de esos datos. Una cuenta propia del proveedor, su verificación de dominio y recepción real no se sustituyen por mocks ni por un envío aceptado porAPI. No contratar ni cambiar planes; sólo opciones gratuitas. No usar el Gmail de recuperación para correo masivo. Ningún envío real al personal o a pacientes se inicia por tener código listo: requiere destinatarios y configuración reales y explícitos.

### 12.13 Datos recibidos y correo nuevamente pospuesto (30 de octubre)

Juan aportó el correo de la cuenta deNatalia y suWhatsApp; se conservan literalmente en la sección6 de su documento de información. No aportó alias/CBU/titular ni Android/iPhone. A la pregunta por el proveedor respondió «Dejemos el correo para después».

**Aplicación:** configuración de lo confirmado y etapaD siguen en curso. **E vuelve a quedar pospuesta**, sustituyendo ese punto de12.12; no se prepara una cuentaResend ni se implementa/envía correo automático en esta continuación. Los datos de negocio faltantes no se inventan. Si la cuenta todavía no existe, el flujo ya verificado `create_business_with_owner` permite preparar el consultorio y la dueña pendiente, sin crear contraseñas ni simular el ingreso deNatalia. La configuración pública no se conecta al consultorio de otro titular; las señas y la cancelación automática continúan apagadas hasta completar los datos y decisiones correspondientes.

### 12.14 Configuración/D en espera y nuevo frente de confirmación (30 de octubre)

**Pedido literal:** «Ya cree el consultorio y le di 12 meses de acceso, estoy esperando que se cree la cuenta, cuando lo haga seguimos con eso. por ahora queria que veamos otras cosas». A continuación pidió corregir a fondo la confirmación obligatoria deemail y suUX.

**Aplicación:** configuración deNatalia yD vuelven a quedar en espera, sustituyendo ese avance de12.13. E sigue pospuesta. El consultorio real fue preparado17:25UTC con dueña pendiente; la lectura posterior20:40UTC confirma el acceso activo/no permanente ajustado porJuan a12meses. No se vuelve a crear ni se altera su acceso. El nuevo frente se rige por `confirmacion-email-20261030.md`, con registro/traspaso/publicación propios y la autorización productiva ya concedida, manteniendo todos sus controles. La confirmaciónAuth permanece habilitada.

### 12.15 Cuenta real de Natalia, unificación de sus consultorios y autorización total (31 de octubre)

**Pedidos literales de Juan, en orden.** El correo de la cuenta se omite acá a propósito y consta en la sección 6 del documento privado de la clienta, para que este plan no contenga datos personales si alguna vez se incluye en una candidata del repositorio auxiliar, que es público.

> Te doy autorizacion total a a verificar todo lo que sea necesario y publicar. tambien aclaro, y repito algo muy importante para que tengas claro el enfoque, de modo que evites sobre ingenieria en un lado y sub verificacion en el otro, esta app aun no tiene clientes ni usuarios reales, todos los emails y turnos son ficticios, con una unica excepcion: Natalia, la primer usuaria real se registro con el email: [correo omitido] bajo el nombre del consultorio: "Consultorio" al cual le di 367 dias de acceso. Sin embargo yo le habia preparado el consultorio llamado  "Consultorio Natalia Frutos" el cual no puedo borrar desde el panel ya que por motivos de seguridad no cree esa opcion, pero ahora quiero resolver esa contradiccion, te autorizo tambien a resolverla de la manera que consideres mas adecuada.
> Antes de empezar redactame con precision y de forma clara todo lo que haras asi le doy una ultima revisada y te lo apruebo. Tambien aclarame si necesitas algun permiso adicional

Después de leer el plan de trabajo propuesto (cuatro fases: verificación de sólo lectura, unificación, versión V9 y documentación), respondió:

> Si, te autorizo a todo eso, necesito que avances con el rigor mas extremo posible, y vayas documentando todo de manera detallada y explicita. Y cuanto termines, dejame en claro que queda porque no quiero que se me pierda. nombraste las etapas D E y el resend, por eso te digo, que no se pierda todo lo que queda pendiente

**Qué cambia respecto de 12.13 y 12.14.**

- La cuenta real de Natalia existe y no usa el correo que Juan había aportado el 30 de octubre. Al ingresar por primera vez, el alta automática le creó un consultorio propio llamado «Consultorio», del que es dueña, y Juan le dio 367 días de acceso. El consultorio preparado el 30 de octubre, «Consultorio Natalia Frutos», quedó con una invitación de dueña pendiente que nadie va a reclamar.
- **Decisión:** se conserva el consultorio donde ya es dueña su cuenta real, y se elimina el preparado. Mudar su cuenta al preparado obligaría a trasladar o perder lo que ella ya cargó y a cambiar su consultorio activo, con más riesgo y ningún beneficio.
- En «Consultorio» se trasladan del preparado sólo los datos que expresan una decisión de Juan o un hecho, y sólo si el campo conserva todavía el valor del alta automática (nunca se pisa algo que ella haya cambiado): el nombre «Consultorio Natalia Frutos», el rubro «otro» en lugar de «odontología», la dirección pública `/reservar/natalia-frutos` (sólo si su reserva pública está apagada y no tiene integraciones, de modo que nadie pueda tener el enlace anterior) y el WhatsApp del consultorio aportado por Juan el 30 de octubre (sólo si ella no cargó otro). La respuesta «Si, te autorizo a todo eso» cubre las tres confirmaciones que pedía el plan de trabajo: ese número, ese nombre y esa dirección.
- No se trasladan: la zona horaria de Córdoba (hoy idéntica a la de Buenos Aires), el contacto público y los documentos del paciente apagados (fueron elecciones del agente el 30 de octubre, no decisiones de Juan ni de Natalia) ni los 12 meses del preparado (rige el acceso de 367 días que Juan le dio).
- La eliminación es una operación única y auditada, no una opción nueva del panel: Juan decidió por seguridad que el panel no borre consultorios, y esa decisión se mantiene.
- La autorización cubre además la verificación de sólo lectura de producción, la corrección de la falla que no se registraba en `/confirmar-correo` y su publicación como V9 en el Worker `app`, y la corrección de la documentación señalada en la revisión del 31 de octubre.
- **No cubre ni reanuda:** la configuración del turnero y de la seña de Natalia, las etapas D y E, Resend, cambios en su web o en Vercel, su acceso, su cuenta (contraseña, sesiones o correos) ni la configuración de Auth. Esos pendientes quedan enumerados en `docs/plans/pendientes-vigentes.md`.
- Quedan sin respuesta y se registran como pendientes: el valor del límite de envío de correos de Auth (se lee en el panel de Supabase, al que el agente no tiene acceso) y si la web de Natalia ya es pública para pacientes reales.

**Qué reemplaza:** la espera de 12.14 sobre la cuenta de Natalia («estoy esperando que se cree la cuenta»), porque la cuenta ya existe. El resto de 12.14 sigue vigente: la configuración de Natalia y D siguen en espera, y E sigue pospuesta.

**Registro y evidencia:** `docs/plans/registro-senas-avisos-natalia.md` (sección del 31 de octubre) y `.verification/natalia-unificacion-20261031/`.

### 12.16 Duplicado archivado, configuración de Natalia, conexión de su web y vista de archivados (31 de octubre y 1 de noviembre)

**Pedidos literales de Juan, en orden.** La dirección automática del consultorio real de Natalia se omite porque deja ver su correo.

Primer mensaje, después del informe final de 12.15 (31 de octubre). Adjuntó dos capturas: el panel maestro con el duplicado en «Pausado» y los límites de Auth de Supabase.

> "La base rechaza borrar el consultorio preparado (access_grants is append-only). Esa protección mantiene indeleble la historia de accesos. Lo comprobé con un intento de borrado que se deshizo solo.
> El plan aprobado decía que, en ese caso, no seguía sin tu aprobación. Por eso tampoco renombré tu consultorio de Natalia: habrían quedado dos con el mismo nombre.
> Preparé la alternativa y la ensayé en una transacción que se deshizo: pasó los 15 controles. Una lectura posterior confirmó que los dos consultorios quedaron exactamente como estaban." entonces renombrala para que no la confunda con el verdadero con consultorio de natalia y corregi un error porque al archivarla no me la quita de la vista, me pone "pausado". Necesito que se vayan a una ventana especial y no aparezcan al buscarlas en el buscador
>
> Sobre esto: "La web de Natalia reserva hoy en un consultorio de prueba, otro «Consultorio» con 80 turnos ficticios. Por ahí entraron 2 reservas en total, ninguna reciente. Si la web ya se difunde, una paciente real reservaría ahí y Natalia no la vería." decime que opinas de conectarla ya a su consultorio real y hacer las pruebas ahi. Antes de entregarle la app, la limpiaria, pero podria ser mas realista realizar las pruebas directamente ahi.
>
> Aca te paso una foto con todos los rate limit para que los registres y me digas si estas de acuerdo. Recorda que debe ser compatible con supabase free para al menos un consultorio, a partir del segundo o tercero probablemente me pase a pro.
>
> Sobre la web de natalia, aun no la esta usando, no se a que te referis con publica para clientes, hoy no la usa nadie hasta que le entregue la app.
> "Si querés la dirección de reservas natalia-frutos para su consultori" especificame mejor a que te referis.
>
> Sobre los datos de natalia, agrega todos los que se pueda, los que no tengamos quedaran pendientes pero adelanta eso e indicame que falta al terminar.
>
> Etapa D y E las dejamos para mas adelante, pero a no olvidarse que quedan pendientes.
>
> "Google: verificar cita-suite.com.ar en Search Console; recién después, la verificación de marca." y "Opcionales de dominio listados en dominio.md." Lo voy a hacer yo en paralelo, hasta que no te lo confirme como hecho, quedara pendiente.
> "Supabase: renombrar el proyecto «Staging 455»." descarta su renombre, quedara con ese nombre.
> "Avisos por correo: confirmar que llegan los de fallas de GitHub y los de las copias de respaldo." si llegan.
>
> Aun no empieces verificame que entendiste, si estas de acuerdo con todo o no, dame tu opinion y si tenes algo mas que decirme, cualquier cosa, puede ser inconsistencia, algo que se me esta pasando por alto adelante

Mientras el agente revisaba, sin cambiar nada, el código del panel, los recibos y la web pública:

> si, la idea es que la web publica de natalia sea indexada por navegadores

Después de la respuesta del agente (lo que entendió, su opinión, lo que encontró y nueve confirmaciones, cada una con su propuesta), el 1 de noviembre, poco antes de las 01:41 UTC. Adjuntó una captura de los límites de Auth con el envío de correos en 10 por hora. El texto entre comillas del tercer párrafo es la respuesta del agente, que Juan pegó:

> comparto todo lo que decis y te aclaro algunas cosas. natalia si comprara dominio propio e indexara en los buscadores cuando lo tenga. "le faltan robots.txt y un mapa del sitio. Eso va con el trabajo de la web, junto con las fotos y la presentación." si podes avanzar en eso hacelo.
> Otra aclaracion, de ahora en mas el dominio oficial es el que compre https://app.cita-suite.com.ar/ para la app y https://cita-suite.com.ar/ para la landing, workers.dev no.
>
> "La dirección de reservas: cada consultorio tiene un enlace para reservar sin pasar por la web, https://app.cita-suite.com.ar/reservar/<dirección>. Es el que se comparte por WhatsApp o Instagram, y el panel lo muestra debajo del correo.
> El consultorio real tiene la dirección automática [dirección omitida]: es fea y deja ver su correo.
> La linda, natalia-frutos, la tiene el duplicado.
> Recomiendo pasársela al real. Nadie usa todavía ninguno de los dos enlaces, y la web no depende de esa dirección." Si, pasala.
>
> "La alternativa: Natalia activa «Ayuda» y lo cargás vos desde la app, con una lista exacta que te preparo." esto por ahora no, cargalo directo en la base, porque la otra opcion tiene un limite de 1hs y es la madrugada de un sabado.
> El rubro de ella es medica no odontologa, agregalo y corregilo.
>
> "Para empezar, confirmame
> El nombre y la dirección del duplicado: «Duplicado archivado — no usar» y duplicado-archivado." SI, usa ese.
> "Pasar natalia-frutos al consultorio real." Si hacelo.
> "La vista de archivados tal como la describí." Si confirmo.
> "Cargar sus datos como operador en la base (lo recomiendo) " SI, hacelo.
> "Lo provisorio: lunes, martes y jueves presenciales, sin precios hasta noviembre y las opciones sin código de la sección " avanza todo lo que puedas, lo que falte registralo como pendiente y avisame.
> "Que la web lleve al dominio oficial." Si.
> "La especialidad de Natalia y si el WhatsApp del 30 es el correcto." Medica el whatsapp es correcto.
> "Si la web va a tener dominio propio, antes de que la indexen." Si
> "Si bajás el límite de correos a 10 por hora." Ya lo hice.
> Avanza con rigor extremo, documentando todo de forma precisa y clara, para que quien retome tu trabajo tenga perfectamente claro el estado actual y no encontre contradicciones o vacios. Ademas audita a fondo que funcione perfecto, Se extremadamente exigente e inconformista pero pone el esfuerzo en lo importante, por ejemplo, en lugar de repetir 25 veces un mismo test busca agujeros que los test aprobados podrian no estar detectando y que podria generarme un problema o al cliente.  Si tenes algo mas que decirme, decilo ahora, si no empeza. Una vez que empieces, toma decisiones propias y dejalas documentadas con sus fundamentos y aclaramelas, te doy autorizacion plena para ello, pero eso no significa que debas tomar cualquier decision con ligereza, necesito que esten muy bien fundamentadas.

**Lo que el agente encontró antes de empezar** (lectura de código, recibos y web pública, sin cambios):

- Archivar guarda `archived_at` y además apaga `commercial_access_enabled` (`grant_business_access`, migración `20260704130000_mp_billing_hardening.sql`). El panel maestro pregunta primero si el acceso está apagado: por eso un archivado aparece como «Pausado», con la indicación equivocada «Reanudalo desde las opciones avanzadas». Ni los filtros ni el buscador separan a los archivados.
- Archivar desde el panel sólo modifica `business_subscriptions` e inserta en `access_grants`. No cancela invitaciones ni cambia nombre, dirección o WhatsApp. Un archivado no acepta reservas públicas (`canUsePublicBooking` es falso).
- A las 21:37 UTC del 31 de octubre el duplicado estaba activo; Juan lo archivó desde el panel después. El ensayo de 12.15 ya no corresponde al estado actual y no se aplica.
- La web de Natalia no tiene `robots.txt`, `noindex` ni cabecera `X-Robots-Tag`: es indexable. Lleva a `app.cita-suite.workers.dev`. Su clave se graba en los archivos cuando CI arma la web, y Vercel sólo los sirve sin compilar: no hay una variable de Vercel que cambiar, contra lo que decía `pendientes-vigentes.md`.
- El ingreso y el alta los hace el servidor de la app en Cloudflare. Queda por verificar si Supabase aplica sus límites «por IP» a la dirección de Cloudflare en lugar de la de cada persona.

**Decisiones de Juan:**

1. **Duplicado:** se llama «Duplicado archivado — no usar», con la dirección `duplicado-archivado`, y sigue archivado. Reemplaza la eliminación decidida en 12.15. El agente además cancela su invitación de dueña pendiente, retira su correo habilitado y apaga su reserva pública y su WhatsApp.
2. **Panel maestro:** los archivados van a una vista aparte. Salen de Todos, En orden y Revisar, de sus contadores y del buscador; dentro de esa vista, el buscador busca sólo entre ellos. Cada uno dice «Archivado» con su fecha y conserva «Reactivar consultorio». Se publica como una versión nueva de la app (V10).
3. **Dirección:** `natalia-frutos` pasa al consultorio real de Natalia.
4. **Rubro:** Natalia es médica. Se agrega el rubro «medicina» al sistema y se le asigna. Reemplaza el rubro «otro» de 12.15.
5. **WhatsApp:** el aportado el 30 de octubre es correcto.
6. **Método de carga:** la configuración se carga directamente en la base, como operador, con esta autorización. No se usa «Ayuda» (dura una hora y era la madrugada de un sábado). Reemplaza la exclusión de 12.15 sobre la configuración del turnero.
7. **Provisorio:** lunes, martes y jueves sólo presenciales; sin precios hasta tener los de noviembre; las opciones sin código de la sección 4 del documento de la clienta. Lo que falte queda como pendiente y se le informa a Juan.
8. **Web de Natalia:** se conecta ya a su consultorio real y las pruebas se hacen ahí, marcadas, con limpieza antes de la entrega. Lleva al dominio oficial `app.cita-suite.com.ar`.
9. **Indexación:** Natalia comprará dominio propio e indexará su web cuando lo tenga. El agente avanza con `robots.txt` y el mapa del sitio.
10. **Dominios oficiales desde ahora:** `https://app.cita-suite.com.ar` para la app y `https://cita-suite.com.ar` para la landing. `workers.dev` no es oficial.
11. **Límites de Auth:** Juan bajó el envío de correos a 10 por hora el 31 de octubre. Los demás quedan como estaban; los valores están en el registro.
12. **Otros pendientes:**
    - Las etapas D y E, con Resend, quedan para más adelante y siguen pendientes.
    - Search Console, la verificación de marca y los opcionales de dominio los hace Juan en paralelo; quedan pendientes hasta que los confirme.
    - Se descarta renombrar «Staging 455».
    - Los avisos de fallas de GitHub y de las copias llegan, según confirmó Juan.
13. **Decisiones del agente:** autorización plena para tomar decisiones propias bien fundamentadas, documentadas con sus fundamentos y comunicadas a Juan. Están en el registro.

**Sigue sin cubrirse:**
- la seña: faltan los datos de transferencia y las respuestas de Natalia;
- las etapas D y E;
- el acceso y la cuenta de Natalia: contraseña, sesiones y correos;
- cualquier dato que Natalia no haya dado: no se inventa.

**Registro y evidencia:** `docs/plans/registro-senas-avisos-natalia.md` (sección del 1 de noviembre) y `.verification/natalia-configuracion-20261101/`.

### 12.17 Ayuda de Cita Suite con duraciones de 1 hora, 24 horas y 7 días (1 de noviembre)

**Pedidos literales de Juan, en orden.**

Primero, después del informe final de 12.16:

> hay un problema, implemente una funcion para configurarla, con la cual el dueño me da acceso temporal de 1hs, pero dado que ahora me pidio una web personal y conectarla al consultorio necesito mas que una hora para cargar sus datos y comprobar que todo funcione perfecto. La de 1hs tambien presupone que estemos conectados al mismo tiempo y que el problema pueda solucionarse en 1hs, que opinas de agregar 2 opciones, una de ayuda que sea de 24hs y otra de configuracion inicial de 7 dias

El agente explicó lo que da hoy la ayuda: el rol de administrador, que incluye leer las historias clínicas; las lecturas no se registran, sólo la dueña la corta y volver a activarla no la extiende. Propuso tres duraciones, con la de 7 días sólo sin pacientes. Juan respondió:

> SI no tiene pacientes no hay nada que ocultar. y es importante que el permiso no se reboque cuando yo cargue pacientes ficticios que para la app sin indistingibles de pacientes reales. Es importante que siga avisando a la dueña que estoy teniendo acceso a su cuenta y cuando se corta, con un boton para finalizarlo tanto ella como yo. Pero evitemos alarmismos irreales como poner "el desarrollador tendra acceso a todos tus pacientes e historiales clinicas" eso genera un miedo irreal porque en la configuracion inicial no existe nada de eso aun. antes de implementar terminemos de definir eso

El agente propuso reglas, textos y tres decisiones. Juan citó las tres decisiones y respondió:

> coincido con tus 3 propuestas e importante menus intermedios de confirmacion para acciones importantes como dar y cancelar la ayuda.
> En el punto 3, coincido en no mostrarla. Implementa eso con rigor extremo y despues audita

**Definición aprobada:**

1. **Duraciones:**
   - 1 hora y 24 horas, siempre disponibles;
   - configuración inicial de 7 días, sólo si el consultorio no tiene ningún paciente en el momento de activarla. Si tiene pacientes, la opción no se muestra.
2. **Una vez activa, dura lo elegido.** Cargar pacientes, de prueba o reales, no la corta ni la acorta.
3. **La activa sólo la dueña.** Las duraciones no cambian lo que se puede hacer durante la ayuda; la suscripción y el equipo siguen bajo su control.
4. **Terminarla:** la pueden terminar la dueña y el maestro, y queda registrado quién lo hizo.
5. **Extender sin cortar:** con una ayuda activa, la dueña puede pasar a una duración más larga, y el plazo se cuenta desde ese momento. Con la configuración inicial activa, puede sumar 7 días más aunque ya haya pacientes.
6. **Avisos:**
   - mientras está activa, la dueña ve un aviso con la fecha y la hora de fin. Puede cerrarlo, pero queda una marca chica y fija en el menú, «Ayuda activa hasta …»;
   - cuando termina, ve un aviso durante 24 horas que dice cómo terminó: por vencimiento, porque la terminó ella o porque la terminó Cita Suite.
7. **Fecha además de hora** en todos los textos.
8. **Confirmación intermedia** antes de dar, extender y terminar la ayuda, de los dos lados.
9. **Textos sin alarmismo.** No se dice que Cita Suite «tendrá acceso a todos tus pacientes e historiales clínicos». Las opciones se describen por su uso: algo en el momento, algo durante el día, o la configuración inicial con prestaciones, horarios, preguntas, la web y las pruebas.

**Registro y evidencia:** `docs/plans/registro-senas-avisos-natalia.md` (sección «Ayuda con duraciones, V11») y `.verification/ayuda-duraciones-20261101/`.

<a id="etapa-e-vigente"></a>

### 12.18 Etapa E: correo con Zoho, autogestión y nuevas señas (2 de noviembre)

**Estado y alcance del pedido actual:** revisar la propuesta contra el código, corregir sus resoluciones y actualizar documentación. Juan dará después la instrucción de empezar. No configurar secretos/DNS/proveedor, implementar, enviar mensajes ni publicar durante esta revisión. Esto no revoca autorizaciones productivas anteriores para el trabajo que corresponda al reanudarse; D no se reanuda.

**Fuente operativa de E:** [Etapa E: correo del consultorio, reprogramación autónoma y señas](etapa-e-correo-autogestion.md). Contiene las decisiones, contraste C01–C13, matriz identificada de casos, correcciones, orden de ejecución, fuentes de Zoho y condiciones de cierre. La matriz describe pruebas requeridas, no corridas aprobadas.

#### Decisiones conversadas y extractos literales de Juan, en orden

1. **Inicio de la definición:** «Vamos a ejecutar la fase E que son las notificaciones por email»; pidió email obligatorio por defecto, desactivable, botones opcionales CANCELAR/REPROGRAMAR y pantallas de confirmación con alternativas cruzadas. Cerró: «antes de empezar nada, lee el plan, evalua esta propuesta y decime si estas de acuerdo, si agregarias o quitarias algo o si hay algoq ue no estoy teniendo en cuenta».
2. **Recepción:** «para los pacientes registrados por recepcion podria salirles un aviso que diga algo asi "si no se registra el email no se le enviaran recordatorios por ese medio"». Se precisó «Continuar sin email» / «Agregar email», comprobando la ficha existente.
3. **Autogestión:** rechazó que reprogramar termine en coordinación con recepción: «si reprogramar implica coordinar con recepcion implica volver al mismo problema de coordinacion idas y vueltas que cita suite pretende resolver». Se acordó elegir otro horario y conservar el anterior hasta completar el cambio.
4. **Nueva seña:** «por defecto si la reserva exige seña para poder reprogramar, deberia pedir otra seña con opcion de quitarse». Se explicó guardar el nuevo horario como reservado con la nueva obligación pendiente; la transferencia sigue registrándose por el consultorio, sin cobro integrado.
5. **Mensajes y tiempos:** tras coincidir con el recorrido y la explicación de comprobantes/pedidos/recordatorios, precisó: «los recordatorios por email serian 72hs antes y 24hs antes. Ademas los comprobantes tambien tendrian los mismos botones que lleven a cita suite para cancelar o reprogramar».
6. **Identidad:** «es importante no hacer referencia al nombre cita suite ni poner el logo de cita suite en el email, la prioridad estetica es el consultorio».
7. **Destino del pago anterior:** «por defecto que se pierda pero que le de la opcion al consultorio de sumarla».
8. **Proveedor:** «hay un cambio pasamos de resend a https://cpaas.zoho.com/ decime que opinas». Tras la evaluación pidió: «excelente y dame una propuesta para todos los edge case porque hay bastantes».
9. **Economía:** «no iba a poder mantenerlo grauito indefinidament con un consultorio promedio con 500 pacientes por mes y 3 emails por paciente». El contexto es 1.500 mensajes mensuales de base más cambios/pedidos/cancelaciones. Se dimensiona por turnos y mensajes, sin exigir gratuidad indefinida ni usar ese cálculo como prueba de insuficiencia de otro proveedor.

Pedido final de esta revisión, literal:

> Bueno, verifica contra el codigo si la resolucion a todos esos edge case es la correcta y la mejor posible y si es asi modifica toda la documentacion del plan en esa seccion revisnaod que no quede documentacion contradictoria. tambien deja registrado, todos los cambios que hablamos y te aviso que ya me registre en ZOHO y probe el envio de 2 emails, la verificacion KYC esta pendiente pero ya tengo 100 emails gratis por dia, cuando tenga la verificacion pago. pero ya podemos empezar a configurarlo y probar. Cuando hagas todo eso avisame y te doy la instruccion para empezar

#### Aplicación y precedencia

1. **Proveedor y economía:** Zoho sustituye Resend. Cuenta creada y dos envíos probados por Juan; KYC pendiente y 100 emails gratis/día según su informe. Pagará después de la verificación. Se admite costo controlado de correo con un consultorio; exceptúa sólo ese gasto de la restricción económica histórica. No autoriza compras por el agente, recargas automáticas, otros canales, cambio de infraestructura ni tocar SMTP de Auth.
2. **Email del paciente:** obligatorio por defecto en alta pública directa e integrada, desactivable por consultorio. Recepción puede continuar sin email con aviso y alternativa para agregarlo, comprobando la ficha real en servidor. No imponerlo retroactivamente a operaciones ajenas ni confundirlo con la confirmación de la cuenta de acceso.
3. **Avisos:** comprobantes de reserva/cambio/cancelación, pedido de seña pertinente y recordatorios 72/24 h en esta entrega. Botones configurables donde tengan sentido; turno cancelado ofrece nueva reserva si está disponible, sin resucitarlo. Push 24/2 y alarmas existentes conservan sus reglas.
4. **Identidad y enlaces:** prioridad estética del consultorio, sin marca de Cita Suite en contenido; enlaces al dominio oficial. Dominio de envío y contacto reales verificados. Confirmación explícita; abrir enlaces o cambiar de alternativa no modifica nada.
5. **Reprogramación:** selección autónoma, manteniendo el turno anterior hasta éxito. Mismo turno, prestación/profesionales/modalidad; duración vigente y condiciones mostradas/revalidadas. Los pedidos manuales previos se conservan, pero no son el resultado del nuevo botón.
6. **Señas:** nueva obligación por cambio voluntario del paciente por defecto, desactivable; pago anterior perdido por defecto, con opción de sumarlo a cuenta. Dinero e historia separados de la exigencia actual; cuatro combinaciones explicadas en la especificación. Cambios del consultorio, fallos y operaciones sin cambio no penalizan por defecto. Una impaga no genera dos deudas. La reserva queda pendiente de la seña que corresponda.
7. **Transparencia:** reglas económicas informadas/fotografiadas; sin pérdidas retroactivas, pagos borrados, acreditaciones inventadas o supuestos de saldo completo. La devolución al cancelar sigue pendiente de la política del consultorio.
8. **Contraste y correcciones:** revisión semántica y transacción completa, historia compatible uno a uno, gestión revocable sin romper calendarios, disponibilidad compartida y presupuesto medido. Se retira supresión genérica por cercanía de 30 minutos; recuperación de recordatorios de 30 minutos queda como parámetro técnico inicial propuesto, no aprobación literal.
9. **Secuencia:** E puede avanzar antes de D. A/B/C conservan su cierre; no volver a publicar/reensayar por rutina. Verificar E por sus garantías y con controles proporcionados al criterio inicial de AGENTS.
10. **Pausa actual de ejecución:** terminar documentación, avisar y esperar la instrucción de Juan para comenzar integración/configuración/código. Su informe de Zoho no acredita aún conexión con Cita Suite ni sustituye una prueba integral de recepción y uso de enlaces.

**Qué reemplaza:** sección 0.9 y pausa D/E de 0/6; restricción económica de 1.2 sólo para correo; promesas 6/11 de 2; proveedores de 3/4.14/7/8/9/10; reprogramación voluntaria de 4.2–4.5 y recorrido de 4.9; pruebas, compatibilidad y automatización de 5/6, ampliadas por E. Sustituye el orden D→E de 12.12 y pausa de E de 12.13–12.16. No modifica 4.13/D, autorización productiva general, datos faltantes de Natalia, acceso/identidad de su cuenta, resultados históricos ni plazos generales de seña/baja automática.

**Continuidad:** [especificación](etapa-e-correo-autogestion.md), [registro de revisión](registro-senas-avisos-natalia.md#etapa-e-revision), [punto de continuación](traspaso-senas-avisos-natalia.md#etapa-e-punto) y [pendientes vigentes](pendientes-vigentes.md#etapa-e-pendientes).

<a id="zoho-terminal-vigente"></a>

### 12.19 Conectar Zoho por terminal y conservar el acceso (3 de noviembre)

Instrucciones literales de Juan, posteriores a la revisión:

> conectemos zoho para que puedas controlarlo desde la terminal

> Guarda todo, que no se pierda el acceso al reiniciar la pc

**Aplicación:** autoriza preparar/conectar el acceso administrativo local de Zoho CPaaS y guardarlo de forma persistente. Reemplaza la espera de 12.18.10 sólo en ese alcance. No se inicia por inferencia la implementación completa de E, D, envíos a nuevos destinatarios, compras ni cambios de DNS/SMTP de Auth/configuración de Natalia.

**Resultado:** Self Client OAuth, credenciales recibidas en ventana local sin pasar por chat/Git, refresh token guardado fuera del repositorio. Se comprobaron agentes, dominios, registros de email y renovación real con lectura posterior. La herramienta sin secretos queda versionada; los tokens y respuestas completas permanecen privados. No requiere un proceso permanente para sobrevivir a un reinicio. Guía de custodia, comandos, evidencia, límites y revocación en [Zoho por terminal](../architecture/zoho-cpaas-terminal.md).

Esto acredita acceso a las APIs consultadas y renovación OAuth, no entrega de nuevos mensajes, integración de Cita Suite, botones, webhooks, KYC o facturación. La definición y aceptación funcionales de 12.18 permanecen íntegras.

<a id="ejecucion-e-autorizada"></a>

### 12.20 Ejecución íntegra de E, autonomía y continuidad (3 de noviembre)

Pedido literal posterior de Juan:

> Bueno, ya esta todo, el plan, con los edge case y las conexiones listas. empeza con todo lo que acordamos, establece una regla para no perder informacion ante compataciones, actua con el rigor mas extremo posible, no dejes ni una sola inconsistancia, no tomes decisiones a la ligera sin verificar de forma exhaustiva y  no supongas que un test verde implicca necesariamente ausencia de errores, documenta todo lo que hagas, no dejes documentacion contradictoria, tenes autorizacion para subir y probar produccion pero respeta la regla de no dejar contradicciones (hay una regla documentada revisa todo). Avanza, audita y testea a fondo que todo haya quedado completado consistente y hecho de la mejor forma posible. Si tenes dudas, damelas ahora antes de empezar, una vez empieces avanza por tu cuenta, te doy autorizacion

**Aplicación y precedencia:** autoriza E1–E6 completas: código, migraciones/configuración pertinentes, pruebas, auditorías y publicación en producción. Sustituye la espera de 12.18.10, la limitación de 12.19 a conectar Zoho y las entradas activas que esperaban una instrucción de inicio. No se solicita otra autorización de producción. D permanece en pausa; no autoriza compras, auto-recargas, cambiar SMTP de Auth, inventar condiciones comerciales de Natalia ni mensajes a terceros ajenos a las pruebas acordadas.

**Antes de implementar:** se plantearon juntas Q01/Q02, sobre el remitente técnico compartido y los valores iniciales de botones/activación de correos. Se espera su respuesta, no otro permiso de implementación. Las definiciones no cuestionadas de 12.18 permanecen íntegras. Los datos comerciales faltantes siguen pendientes sin impedir desarrollar y verificar la función con fixtures propios.

**Continuidad y rigor:** [registro activo de E](ejecucion-etapa-e-20261103.md), con regla obligatoria tras compactaciones, checkpoint y los 97 casos por evidencia. La [especificación](etapa-e-correo-autogestion.md) sigue siendo la definición funcional única. El registro histórico, traspaso, estado vigente, contratos, permisos, regresiones y guías de operación se actualizan en cada cambio pertinente, con historia fechada y precedencia explícita. No confundir preparación, simulación, CI, proveedor, recepción real y publicación; una prueba verde no sustituye la búsqueda adversaria de inconsistencias ni el contraste posterior de datos.

**Autonomía posterior:** una vez resueltas las decisiones iniciales, continuar por cuenta propia hasta completar E y sus comprobaciones. Registrar decisiones técnicas justificadas, fallas, correcciones, evidencia y dependencias externas; no detener por una nueva pregunta de permiso ni declarar completado lo que siga sin demostrar.


<a id="etapa-e-decisiones-iniciales"></a>

### 12.21 Respuestas iniciales: subdominio por consultorio y envíos activos (3 de noviembre)

Respuesta literal de Juan sobre el remitente:

> Subdominio de Cita Suite
> odontologia-rojas.cita-suite.com.ar
> Sin comprar otro dominio
> Es la opción más económica y sencilla de implementar.

Sobre botones y envíos:

> Que esten activos por defecto cuando sea razonable que esten, si acabo de cancelar, que la confirmacion no diga de nuevo cancelar, siempre en contexto y que los envios de emails estan activos por defecto con opcion de desactivar. decime que opinas de ambas cosas, si estas de acuerdo continua

**Aplicación:** se acepta. Cada consultorio usará un subdominio de `cita-suite.com.ar`, sin comprar otro dominio, por ejemplo `turnos@odontologia-rojas.cita-suite.com.ar`. Ese ejemplo no es un consultorio real por crear. El nombre/logo/contenido son del consultorio y Reply-To dirige a su contacto real. Verificar cada subdominio en Zoho; el dominio `avisos.cita-suite.com.ar` ya comprobado no verifica automáticamente los demás. El alta DNS/proveedor debe ser repetible, acotada a sus registros y sin alterar app/landing/Auth.

Los envíos están **habilitados por defecto**, con opción de desactivarlos. Se distinguen preferencia habilitada y preparación real del emisor: si faltan verificación/contacto/datos exigidos, mostrar pendiente y no simular un envío ni usar datos inventados. No exigir una activación manual adicional como valor inicial una vez que estén dadas las condiciones. Email requerido por defecto conserva su regla independiente.

Los botones están habilitados por defecto **cuando el contexto permite la acción**, y son configurables por separado. Sustituye la propuesta inicial de apagar envíos hasta activación manual, que Juan no eligió. Q01/Q02 quedan resueltas; continuar por cuenta propia bajo 12.20, sin otra pregunta de inicio.

### 12.22 Coherencia contextual: comprobante de turno y de cancelación (3 de noviembre)

Correcciones literales posteriores de Juan:

> Especial atencion a eso, porque me planteaste esos 2 botones por defecto algo que ya definimos pero tambien definimos que todo deben adecuarse al contexto y ser coherente. No solo nos mostrar cancelar en el comprobate, tampoco mostrar reprogramar, entre tantos otros casos. Asegurate que todo quede coherente, consistente, sin error de logica de ni de UX

> Aclaro algo, en el comprobante del turno si puede aparecer cancelar o reprogramar, me referia  a que no deberia aparecer cancelar ni reprogramar en el comprobante de la cancelacion del turno, repito: CONTEXTO y COHERENCIA

**Aplicación inequívoca:** un comprobante de turno vigente puede mostrar CANCELAR y REPROGRAMAR, según las preferencias y permisos efectivos. **Un comprobante de cancelación no muestra ninguno de los dos.** Sólo puede ofrecer reservar un turno nuevo si hay reserva pública disponible, además de contacto pertinente. No reprograma ni resucita el cancelado. Turnos iniciados/pasados tampoco muestran esas acciones; los enlaces antiguos resuelven el estado actual. La preferencia de mostrar un botón no autoriza una acción que el contexto impide.

Esta es una reafirmación de AC05/AC06/OP03 y de la decisión contextual original, no un cambio para quitar botones de todos los comprobantes. Verificar correos, comprobantes, páginas de gestión, alternativas cruzadas, estado de pago y acciones finales en conjunto, incluidos cambios de estado concurrentes. Textos e información deben coincidir con el resultado persistente, sin anunciar pagos, confirmaciones, envíos o disponibilidad no demostrados.

<a id="tareas-posteriores-a-e"></a>

### 12.23 Tareas después de E y reemplazo de D (3 de noviembre)

Pedido literal de Juan durante la implementación de E:

> Segui y una vez que termines, hayas publicado auditado y asegurado que no haya quedado ningun error, inconsistencia, ni problema de UX ni contradicciones en la documentacion ni de ningun otro tipo, avanza con extremo rigor y verificacion con estas 3 tareas:
> 1. Habilitar opcion de cancelar turno desde recepcion
> 2. Estilar todo, que no quede nada nativo del navegador, asegurate de hacerlo en ambos modos, claro y oscuro.
> 3. Remplazar la fase D, de la notificacion al celular en caso de que se liberen turnos, y que sea simplemente una notificacion interna general dentro de la app, con una logica similar a la que tiene "seguimientos". Actualizarlo en la documentacion, que no quede nada contradictorio.
> Pero no mezcles las tareas porque son diferentes. Te las dejo para que las cumplas cuando termines la anterior

**Aplicación:** continuar E hasta terminar, publicar y auditar con sus criterios y evidencia. Después ejecutar por separado y en ese orden P1, P2 y P3; no cambiar ahora de tarea ni incorporar sus implementaciones a E. Se mantienen la autonomía y autorización de publicación/pruebas ya otorgadas, sin nuevas compras, mensajes a terceros por inferencia ni relajación de permisos. El seguimiento separado está en [tareas posteriores a E](tareas-posteriores-a-e-20261103.md).

**D reemplazada:** el aviso al celular del consultorio de 4.13 y su alcance D de la sección 6 quedan sustituidos por avisos internos generales de horarios liberados en la app, con lógica similar a Seguimientos. No se implementan push al personal ni requisitos de instalación/tipo de teléfono por esa D. Se iniciará como P3 después de E/P1/P2; no supone que la notificación interna nueva esté hecha. No cambia C ni los push/calendarios existentes del paciente, ni el correo de E. Las menciones anteriores a D en pausa conservan su sentido histórico; no son una tarea futura de push a retomar.

**Verificación y documentación:** cada tarea conserva alcance, evidencia y cierre propios; actualizar fuentes activas/pendientes y mantener fechado el texto histórico. Revisar el estado real tras E antes de añadir algo que ya pudiera existir, especialmente cancelación/roles y avisos de C.

<a id="calidad-ingenieria-e"></a>

### 12.24 Diseño e invariantes antes de ampliar E (3 de noviembre)

Juan indicó: «priorices la calidad de ingeniería por encima de la velocidad de implementación» y «El objetivo no es conseguir que todas las pruebas pasen a fuerza de iteraciones. Es construir una implementación cuya corrección pueda justificarse por su diseño, sus invariantes y su evidencia de verificación».

**Aplicación:** antes de ampliar funcionalidades, revisar arquitectura e invariantes en todas las transiciones, concurrencia, reintentos, cambios de identidad, permisos vencidos y fallos parciales. Clasificar causas aisladas/estructurales, preservar contratos, buscar contraejemplos entre componentes y justificar cada mecanismo por una garantía concreta. Separar defectos del producto, arnés/datos inválidos y contratos aún sin implementar. Corregir causas estructurales; no agregar abstracciones o defensas para obtener un verde. Dejar conclusiones breves en el registro activo, sin otra especificación ni documentación extensa. Esta prioridad gobierna la continuación de E1–E6 y no sustituye sus requisitos, autonomía ni autorización. E sólo cierra con verificación integral final y regresiones, distinguiendo lo probado de lo pendiente.

### 12.25 Revisión aceptada y continuación de implementación (3 de noviembre)

Juan aceptó la revisión como punto de partida y pidió «Ahora continuá la fase E aplicando esas conclusiones directamente sobre la implementación» y «Continuá autónomamente hasta completar la fase E». Primero corregir los escritores del personal que necesiten atomicidad/auditoría/concurrencia; conservar operaciones con responsabilidades/autorizaciones distintas, sin unificación obligatoria. Diseñar sus garantías, corregir categorías de problemas, verificar persistencia/carreras/recuperación y distinguir producto/arnés/infraestructura/contratos incompletos. No repetir diagnóstico general ni verificaciones costosas aún válidas. Después completar vías auxiliares, contacto, correo y E según el plan, con verificación integrada de la revisión exacta antes de publicar; autorización productiva ya concedida y tareas P1/P2/P3 separadas. No cambia ninguna regla funcional ni autoriza ampliar alcance o contratar.

<a id="posteriores-a-e-pospuestas"></a>

### 12.26 Completar E y posponer las tres tareas posteriores (3 de noviembre)

Pedido literal posterior de Juan:

> cuando termines la fase E con el rigor extremo y exigencia extrema que te pido, avisame y dejame la documentacion para ver todo a detalle. No avances en los siguientes 3 puntos, esos los vamos a posponer

**Aplicación y precedencia:** continuar autónomamente sólo E, con sus requisitos, verificación integral y autorización de publicación vigentes. Al completarla, avisar y entregar acceso a la documentación detallada de implementación, revisiones, pruebas, evidencia y límites. **P1, P2 y P3 quedan pospuestas y no deben iniciarse al cerrar E.** Sustituye la continuación automática de 12.23 y de los puntos de entrada que la indicaban; no elimina esos pendientes ni revierte el reemplazo de D celular por la futura notificación interna. El seguimiento separado conserva sus alcances para una reanudación posterior de Juan.


### 12.27 Alcance de quitar un turno del calendario (4 de noviembre)

Ajuste técnico bajo la autonomía de 12.20/12.25: quitar un evento borra ese evento y, si no quedan vínculos, elimina su credencial local. No revoca automáticamente todos los permisos de Google del usuario. Google documenta que revocar un token invalida permisos/tokens de todos los clientes del proyecto para esa persona; entre el borrado SQL y esa salida puede haber una nueva autorización legítima. Un modelo mutable reprodujo su invalidación por la revocación vieja. Una lectura adicional no cierra esa carrera externa.

Se retira ese efecto global del camino de borrado inmediato/programado, sin crear otra cola ni conservar credenciales innecesarias. El usuario puede retirar todos los permisos desde su cuenta Google; volver a conectar puede requerir consentimiento renovado por el flujo existente. Reemplaza sólo la revocación automática tras el último vínculo descrita en la guía de tareas; conserva UID, borrado del evento, autoridad de gestión y recuperación. Implementación/pruebas y sus límites en E1.90 del registro. No modifica permisos ni configuración reales durante el desarrollo. Fuente primaria: [revocación OAuth de Google](https://developers.google.com/identity/protocols/oauth2/web-server#tokenrevoke).


### 12.28 Email informado para una nueva reserva de una ficha existente (4 de noviembre)

Resolución técnica bajo 12.20/12.25 para C01/C02 y EM04/EM07/EM11: nombre/teléfono sirven al contrato existente de resolución de paciente, pero no autentican una edición global de su contacto. Si una reserva pública nueva informa otra dirección, esa dirección se vincula **sólo a ese turno**, sin modificar la ficha ni el destinatario de otros turnos. No se ignora el dato ni se fusiona por email. Una reserva con dirección opcional omitida conserva el contacto vigente de la ficha, si existe.

El vínculo se guarda junto con el alta, asociado al paciente y a su revisión monotónica de contacto. Una corrección autorizada posterior de la ficha reemplaza también ese destino para los avisos futuros; volver al mismo texto de email no resucita el vínculo anterior. Una reparación de identidad no hereda el destino de otra persona. El reintento de una reserva ya terminada no reescribe el vínculo ni renueva permisos. La preparación/entrega de correo debe leer y revalidar destinatario, paciente y revisión actuales juntos; un snapshot de destinatario no es una autorización de envío. Conserva los límites de mensajes ya aceptados por un proveedor y las bajas previas. Implementación/evidencia y límites en el registro activo; no describe una integración ya publicada.
