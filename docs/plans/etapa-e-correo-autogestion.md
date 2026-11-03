# Etapa E: correo del consultorio, reprogramación autónoma y señas

**Definición conversada el 2 de noviembre de 2026; revisión documental cerrada el 3:** el 3 Juan pidió conectar Zoho por terminal y guardar el acceso tras reinicios ([12.19](propuesta-senas-avisos-natalia.md#zoho-terminal-vigente)). Conexión administrativa OAuth local y renovación comprobadas; [guía de operación](../architecture/zoho-cpaas-terminal.md). **Juan autorizó después la ejecución íntegra, pruebas y publicación de E ([12.20](propuesta-senas-avisos-natalia.md#ejecucion-e-autorizada)); Q01/Q02 resueltas y E1 en implementación/verificación.** [Registro y continuidad](ejecucion-etapa-e-20261103.md). Los recorridos integrales de la app/correo todavía no se verificaron; los fundamentos SQL parciales y sus límites están en el registro. La antigua D celular quedó reemplazada por P3 interna, que se implementará después de E/P1/P2; [cola separada](tareas-posteriores-a-e-20261103.md). Producción sigue en V12b; consultar siempre el [estado vigente](../ESTADO-VIGENTE.md).

Esta es la especificación vigente de E, incorporada por la sección 12.18 del [plan aprobado](propuesta-senas-avisos-natalia.md#etapa-e-vigente). Sustituye en este alcance la antigua sección 4.14, su proveedor Resend, la pausa conjunta D/E y las reglas anteriores sobre reprogramación iniciada por el paciente. El texto aprobado anterior se conserva como historia. [Registro](registro-senas-avisos-natalia.md#etapa-e-revision) y [traspaso](traspaso-senas-avisos-natalia.md#etapa-e-punto).

## 1. Alcance y decisiones del usuario

| Tema | Definición vigente |
|---|---|
| Email del paciente | Obligatorio por defecto en reservas públicas, incluidas las integradas. Dueña/administración pueden desactivar la obligación. Es diferente de la confirmación de email de la cuenta de acceso, que permanece habilitada. |
| Turnos de recepción | Permitir continuar sin email después de «Sin un correo electrónico, este paciente no recibirá recordatorios por email», con «Continuar sin email» y «Agregar email». Revisar la ficha seleccionada, no sólo el campo del formulario. |
| Mensajes | Comprobante de reserva, comprobante de cambio, comprobante de cancelación, pedido de seña cuando corresponda y recordatorios a las **72 y 24 horas** del turno. No cambia el push existente de 24 h/2 h ni las alarmas de calendario. |
| Botones | Habilitados por defecto cuando el contexto permite actuar, con controles independientes para mostrar CANCELAR y REPROGRAMAR. Comprobante de turno vigente puede ofrecerlos; comprobante de cancelación no muestra ninguno. Se puede configurar ninguno, uno o ambos. Son presentación, no nuevos permisos de agenda. |
| Recorrido de cancelación | «¿Querés cancelar este turno?», fecha/hora, «Sí, cancelar turno» y alternativa discreta «Prefiero reprogramar». Abrir o cambiar de recorrido no modifica nada. |
| Recorrido de reprogramación | «¿Querés reprogramar este turno?», selección autónoma de otro horario, resumen y «Confirmar reprogramación». Alternativa «Prefiero cancelar sin reprogramar». Ya no termina en un pedido a recepción. |
| Identidad | Prioridad visual del consultorio: su nombre, logo si existe, colores, asunto, remitente visible y contacto. Sin nombre, logo ni promoción de Cita Suite en el contenido del email. Los enlaces de gestión sí van al dominio oficial de la app. |
| Nueva seña | Si el turno exige seña, exigir una nueva al reprogramar por iniciativa del paciente, por defecto; opción de desactivar esta exigencia. Cambios del consultorio no la generan por defecto. |
| Destino del pago anterior | Por defecto deja de aplicarse al precio de la consulta al concretarse la reprogramación del paciente; el consultorio puede elegir sumarlo a cuenta. No se borra el pago recibido. |
| Momento del cambio | Guardar el nuevo horario como reservado con la nueva seña pendiente, cuando corresponda. La transferencia sigue registrándose por el consultorio; no se integra un cobro automático en E. |
| Proveedor | **Zoho CPaaS**, elegido por Juan, sustituye Resend. Cada consultorio usa su subdominio de cita-suite.com.ar verificado para enviar, sin compra de otro dominio. Gmail sigue como SMTP de Auth y su conector se usa para leer el buzón de pruebas; no se cambia SMTP por esta etapa. |
| Activación | Envíos habilitados por defecto y desactivables por el consultorio. La preferencia no simula preparación del emisor: falta de dominio/contacto/datos exigidos se muestra pendiente, sin emitir ni marcar enviado. No exigir otra activación manual al quedar listo. |
| Economía | Juan acepta el gasto controlado de correo también con un consultorio. No exigir gratuidad indefinida ni interpretar esto como permiso para contratar otra infraestructura. Las compras las hace Juan, sin recargas automáticas del agente. |

Si no hay nueva obligación pendiente, conservar una confirmación previa válida cuando corresponda; un turno sin seña que estaba reservado no se confirma artificialmente por abrir el correo. No crear estados nuevos de turno para representar pagos.

### 1.1 Estado de Zoho informado por Juan

El 2 de noviembre Juan confirmó: cuenta creada, **dos envíos de email probados por él**, KYC pendiente, disponibilidad de **100 correos gratuitos diarios** y decisión de pagar cuando se complete la verificación. No volver a pedir que cree una cuenta.

Es evidencia aportada por el usuario, no una prueba ejecutada por el agente ni una prueba integral Cita Suite → Zoho → buzón → botón → base. No se conocen por esa declaración el dominio/remitente utilizado, la región, el saldo y vencimiento exactos, las credenciales API ni la recepción y recorridos de esos dos mensajes. Se comprueban al configurar, sin pedir secretos por chat.

Comprobación posterior del 3 de noviembre: [conexión administrativa local real](../architecture/zoho-cpaas-terminal.md), con credenciales privadas persistentes, un agente activo, un dominio habilitado/verificado para salida y dos registros consultados. Se verificó renovación OAuth; la recepción en buzón, KYC, saldo y vencimiento siguen sin comprobarse. No se desplegó la integración de la app.

Dimensionamiento aportado: 500 pacientes por mes y tres emails por paciente, **1.500 mensajes mensuales de base**; para capacidad de la aplicación se cuenta cada turno/mensaje, porque un paciente puede tener varios turnos. Cambios, cancelaciones y pedidos de seña se agregan. No se afirma que ese cálculo, por sí solo, pruebe insuficiencia de otro proveedor. La decisión vigente es Zoho y costo previsible.

## 2. Contraste con el código: qué se reutiliza y qué debe cambiar

Revisión estática sobre main **45ad4dad3259386b445d3306ca66bb16bf51f285**, sin modificar aplicación, SQL ni configuración remota. Las referencias describen el código leído, no un resultado de pruebas nuevas.

| Ref. | Evidencia local | Conclusión para E |
|---|---|---|
| C01 | [Formulario público](../../apps/web/src/lib/booking/PublicBookingConfirmation.svelte#L282), [alta pública](../../apps/web/src/lib/server/scheduling/public/public-booking.ts#L731) y [alta integrada](../../supabase/migrations/20261013010000_booking_patient_information.sql#L203) | El email es opcional. La nueva obligación requiere contrato/configuración, formulario y validación de todas las vías de alta; agregar sólo un atributo visual no basta. Recuperar un alta idempotente ya terminada no debe exigir de nuevo una política cambiada. |
| C02 | [Asistente manual](../../apps/web/src/lib/components/agenda/ManualAppointmentWizard.svelte#L1142) y [acción de agenda](../../apps/web/src/routes/odonto/agenda/+page.server.ts#L446) | Al elegir paciente existente el formulario manda email vacío; no significa que la ficha carezca de correo. Resolverlo en servidor y ofrecer completar el dato con el mismo alcance de identidad. |
| C03 | [Acción pública](../../apps/web/src/lib/server/scheduling/public/public-appointments.ts#L368) | Hoy cambia a «Quiere reprogramar». E necesita un comando distinto que mueva el turno. Mantener pedidos anteriores consultables y resolubles; no transformarlos en cambios de horario por migración. |
| C04 | [Disponibilidad](../../apps/web/src/lib/server/scheduling/public/availability.ts#L25) | Ya existe excludeAppointmentId, además de equipo y modalidad. Reutilizar el calculador; fijar el turno a excluir desde la identidad validada en servidor, nunca aceptar uno ajeno del navegador. |
| C05 | [Reprogramación interna](../../apps/web/src/lib/server/scheduling/public/appointments.ts#L585), [acción pública](../../apps/web/src/lib/server/scheduling/public/public-appointments.ts#L380) | Comparar sólo status detecta varias transiciones, pero dos cambios de hora pueden conservar el mismo estado. E exige revisión semántica del turno y condiciones, más operación transaccional. La auditoría actual posterior en otra llamada no satisface la nueva garantía de atomicidad. |
| C06 | [Seña uno a uno](../../supabase/migrations/20261029010000_appointment_deposits.sql#L44), [vista pública tipada](../../apps/web/src/lib/server/scheduling/public/public-appointments.ts#L173) | No convertir la relación actual en una lista ni sobrescribir un pago para guardar el siguiente. Mantener una proyección actual compatible y agregar historia de exigencias/pagos/destinos vinculada a cada operación. Las escrituras nuevas pasan por comandos controlados. |
| C07 | [Movimiento de la seña](../../supabase/migrations/20261029010000_appointment_deposits.sql#L236), [confirmación](../../apps/web/src/lib/server/scheduling/public/appointments.ts#L580) | Hoy una seña pagada/exceptuada acompaña el cambio. La nueva regla necesita distinguir origen del cambio y política aceptada, actualizar la exigencia vigente y respetar la guardia de Confirmado. |
| C08 | [Fechas y baja](../../supabase/migrations/20261029010000_appointment_deposits.sql#L117) | Reusar la regla de zona/plazo mínimo, la ventana de 24 h de vencimiento y la exclusión de turnos iniciados. El recálculo actual conserva un auto_cancel previamente falso: no prometer reactivación automática al mover más lejos. Una nueva exigencia debe decidir su elegibilidad con las condiciones informadas. |
| C09 | [Token compartido y permisos](../../apps/web/src/lib/server/scheduling/public/public-appointments.ts#L169), [push](../../apps/web/src/lib/server/integrations/public/push.ts#L737), [Google](../../apps/web/src/lib/server/integrations/public/google-calendar.ts#L676) | Rotar indiscriminadamente confirmation_token para corregir un email puede romper otros recorridos. Separar/revisionar la capacidad de gestión enviada por email y revisar cualquier fuga del token legado en HTML, ICS y redirecciones. No afirmar revocación si otra vía permite seguir mutando. |
| C10 | [Permisos del enlace](../../apps/web/src/lib/server/scheduling/public/public-appointments.ts#L169), [disponibilidad pública](../../apps/web/src/lib/server/scheduling/public/availability.ts#L36) | Apagar la reserva online y una suspensión/archivo son situaciones distintas. E no debe eliminar globalmente las guardias comerciales: el permiso excepcional de consultar/cancelar con un enlace válido debe ser específico, mínimo y probado. No concede reservar, reprogramar, acceso interno ni datos clínicos. |
| C11 | [Tareas](../../apps/web/src/lib/server/integrations/public/scheduled-jobs.ts#L31), [presupuesto](../../apps/web/src/lib/server/integrations/internal/job-budget.ts#L14) | No hay trabajo de correo en ese ejecutor. No afirmar que «con un consultorio sobra»: extender la ejecución existente con cupo reservado y medir llamadas/CPU, sin un sexto cron gratuito ni perjudicar push/calendario. |
| C12 | [Calendario](../../apps/web/src/lib/server/integrations/public/calendar-content.ts#L66) | Ya hay UID estable y secuencia; conservarlos. El estado CONFIRMED del archivo ICS no debe usarse como prueba de seña pagada o de asistencia confirmada en la aplicación. |
| C13 | [Cotización y duración](../../apps/web/src/lib/server/scheduling/public/appointments.ts#L570), [tipos de seña](../../supabase/migrations/20261029010000_appointment_deposits.sql#L44) | Hoy se usa duración vigente del servicio al mover, y la cotización se conserva. No prometer duración congelada ni un saldo financiero completo que el producto no lleva. Mostrar duración/condiciones vigentes antes del cambio; usar importes de señas registrados y cotización válida con límites explícitos. |

Las pruebas existentes de disponibilidad, señas, calendario, identidad y permisos son precedentes y regresiones a conservar. **No acreditan E**, que todavía no está implementada. No se clasifican riesgos leídos como defectos reproducidos mediante una corrida que no se ejecutó.

## 3. Reglas transaccionales y de compatibilidad

1. Un cambio conserva la identidad del turno. La disponibilidad se revalida al confirmar para la prestación, todos los profesionales, modalidad, horarios, anticipación, bloqueos, descansos y duración efectivos. No copiar el calculador a la web de Natalia.
2. Validar el enlace, consultorio, turno, revisión observada, política y resumen económico en la misma operación que cambia el horario. Si cambió un dato relevante, devolver conflicto humano antes de afectar turno/dinero. Un cambio de telemetría irrelevante no debe producir conflictos artificiales.
3. El cambio de horario, revisión del turno, destino de pagos anteriores, nueva exigencia, auditoría, horario liberado y eventos pendientes de correo/calendario se guardan juntos. Un error deshace todo. Zoho y Google se llaman después de confirmar la transacción, nunca reteniendo bloqueos de la base.
4. Mantener una puerta única por turno para modificar su seña, con bloqueos breves y orden consistente con alta, política, vencimiento, recepción y reprogramación. Revalidar roles. No agregar una escritura directa alternativa que eluda las funciones actuales.
5. Cada comando lleva identidad de operación y revisión esperada. Repetirlo recupera su resultado autorizado, sin repetir pagos, pérdidas, auditorías o avisos. Esto es distinto de comparar solamente el estado del turno.
6. Conservar la seña vigente uno a uno para lectores anteriores; la historia separada registra obligación, dinero efectivamente registrado, importes a cuenta, importes perdidos y correcciones. «Pagó» no pasa a significar «no pagó» cuando ese pago pierde aplicación. Sin transferencias o devoluciones bancarias automáticas.
7. Fotografiar las condiciones aceptadas. Las nuevas obligaciones por reprogramar y su pérdida no se imponen retroactivamente a reservas que no fueron informadas. Cambios de política más exigentes con un resumen abierto requieren nueva revisión. Apagar una política debe seguir resolviendo pendientes de forma segura.
8. La revocación de gestión por email debe cubrir las mutaciones de todas sus rutas. Mantener identificadores de calendario y vínculos legítimos; un token estable expuesto no puede servir para obtener otra credencial de gestión después de revocado. Probar explícitamente rutas legadas y los enlaces contenidos en ICS.
9. Una migración no envía mensajes ni activa reglas económicas sobre filas antiguas. Conservar pedidos de reprogramación ya existentes. Una recuperación anterior debe entender la proyección actual y detener productores/consumidores de E antes de volver, cuando el cambio lo requiera.

## 4. Matriz completa de casos y aceptación

Cada identificador exige una prueba o comprobación registrada durante la implementación. **Todos están pendientes de ejecución para E**. C01–C13 son el contraste de código aplicable; las decisiones del usuario están en la sección 1.

### 4.1 Email, recepción e identidad — C01, C02

| Caso | Regla y resultado exigido |
|---|---|
| EM01 | Público/directo/integrado sin email requerido: conservar formulario y pedir el dato; no dejar paciente ni turno parcial. Validar también llamadas al servidor y a funciones de alta. |
| EM02 | Obligación desactivada: aceptar ausencia; si se escribe algo, validar formato. Un espacio no es una dirección. |
| EM03 | Recepción sin email: confirmación explícita con los dos botones acordados. No se agrega otro turno al reintentar después de la advertencia. |
| EM04 | Ficha existente: leer su dirección y pertenencia real; el campo vacío oculto no borra un correo ni produce un aviso falso. «Agregar email» guarda el dato en la ficha correcta. |
| EM05 | Formato inválido o posible error de dominio: mensaje específico, datos conservados, sugerencia sin autocorrección silenciosa. Conservar alias con signo + y no asumir equivalencia de buzones distintos. |
| EM06 | Correo familiar compartido: permitido; no usarlo como identidad única, no fusionar personas ni enviar varios turnos en un mensaje común. |
| EM07 | Dirección corregida por un actor autorizado: revisar a qué turnos futuros se aplica, renovar capacidad de gestión y revalidar destinatario al enviar. No retirar ni repetir automáticamente mensajes ya entregados. |
| EM08 | Email añadido después: comprobante vigente solicitado/aceptado y próximos recordatorios útiles; sin recuperación masiva de historia ni reactivación de una baja previa. |
| EM09 | Paciente antiguo sin correo: se puede editar su historia/ficha y gestionar turnos. La exigencia de una nueva reserva pública no bloquea operaciones ajenas. |
| EM10 | Baja de correos: registrar el alcance de ese consultorio/dirección, detener su cola y mantener la reserva. Restablecer envíos requiere acción expresa; un contacto compartido puede dejar de recibir todos los avisos de esa dirección en ese consultorio. |
| EM11 | Corregir la identidad o reasignar un turno: no heredar destinatario, enlaces ni dinero de otra persona. Cerrar envíos viejos y exigir resolución de pagos antes de trasladarlos. |
| EM12 | Retorno idempotente después de cambiar la política de email: recuperar la reserva ya creada y autorizada; no exigir rehacer una operación terminada ni exponer una ajena. |

### 4.2 Botones y credenciales — C03, C05, C09, C10

| Caso | Regla y resultado exigido |
|---|---|
| AC01 | Ninguno/uno/ambos botones: verificar las cuatro combinaciones en cada plantilla activa; los controles sólo afectan el correo. El enlace secundario sigue permitiendo la alternativa disponible. |
| AC02 | Abrir, previsualizar, analizar o rastrear un enlace no cambia turno, seña, asistencia ni preferencias. La acción requiere confirmación de escritura. |
| AC03 | Pasar de cancelar a reprogramar, volver o abandonar no modifica nada. Mostrar siempre salida sin cambios. |
| AC04 | Email viejo: resolver fecha/estado actuales y avisar el cambio. No aceptar una cancelación con la revisión antigua del resumen. |
| AC05 | Turno cancelado: comprobante con «Reservar otro turno» sólo si existe reserva pública disponible; no ofrecer cancelar o resucitar esa reserva. |
| AC06 | Turno iniciado/pasado: consulta mínima y contacto; sin nuevas acciones de agenda. Enlace inválido/revocado: explicación sin revelar otra identidad. |
| AC07 | Dos pestañas o doble clic: un único resultado; la segunda operación distinta debe revisar el turno vigente. Un reintento de la misma recupera su resultado. |
| AC08 | Enlace reenviado: es una capacidad personal; limitarla a un turno/consultorio y permitir revocación. No afirmar que un clic prueba la identidad del paciente. |
| AC09 | Corregir email: probar que enlaces de gestión anteriores, variantes legadas, calendarios y redirecciones no permitan una mutación después de revocados; preservar los eventos legítimos sin cambiar su UID. |
| AC10 | Página sin JavaScript, conexión lenta, error o teclado/lector de pantalla: acciones comprensibles, confirmación utilizable y datos conservados; nunca éxito antes de guardar. |

### 4.3 Cambio de horario — C03–C05, C07, C10, C13

| Caso | Regla y resultado exigido |
|---|---|
| RP01 | Sin horarios, abandono o fallo previo a confirmar: conservar exactamente turno, pagos y exigencia original. |
| RP02 | Otro toma el horario: conflicto y nuevas opciones; el original sigue reservado. Elegir una opción no bloquea indefinidamente otro horario. |
| RP03 | Mismo inicio/equipo/prestación: operación sin cambio; sin nueva seña, pérdida, auditoría de movimiento, aviso ni reinicio de plazos. |
| RP04 | Equipo: todos los profesionales deben poder ocupar el nuevo intervalo y sus descansos. Rechazo completo si falla uno. |
| RP05 | Superposición consigo mismo: excluir únicamente el turno validado. Nunca excluir otro a partir de un identificador enviado por el paciente. |
| RP06 | Mantener prestación, profesional/equipo y modalidad; sin autorizar que el navegador cambie esos datos ni use excepciones de recepción. |
| RP07 | Horarios, anticipación, servicio/profesional desactivado o modalidad incompatible: no ofrecer ni aceptar opciones inválidas; conservar el original y ofrecer contacto. |
| RP08 | Duración vigente distinta: mostrarla y revalidarla, como hace el motor actual; no prometer duración fija ni usar una lista de horarios calculada con otra duración. Conservar cotización aceptada salvo otro cambio comercial explícitamente aprobado. |
| RP09 | Personal cambia hora/política/seña durante la selección: conflicto por revisión semántica aunque status siga igual. No sobrescribir el cambio de otra persona. |
| RP10 | Cambio del consultorio: conserva pago aplicable, no penaliza al paciente por defecto y registra actor/origen desde servidor. No aceptar que el paciente se declare personal. |
| RP11 | Varios cambios: secuencia íntegra, regla económica por operación exitosa y límite técnico de abuso sin bloquear una cancelación legítima. No introducir un máximo comercial de cambios no acordado. |
| RP12 | Respuesta perdida después de guardar: recuperar la operación real y su comprobante; sin otra reserva ni otra consecuencia económica. |
| RP13 | Pedido «Quiere reprogramar» previo a E: conservarlo y permitir resolverlo; no liberar horarios ni generar señas por migrar o abrirlo. |

### 4.4 Señas y dinero — C06–C08, C13

| Caso | Regla y resultado exigido |
|---|---|
| SN01 | Nueva seña sí / anterior perdida: al cambio exitoso registrar el destino del pago anterior y una obligación pendiente nueva. Es el valor predeterminado para reservas informadas. |
| SN02 | Nueva seña sí / anterior a cuenta: mantener importe anterior aplicable y nueva obligación identificada; mostrar ambos por separado. |
| SN03 | Nueva seña no / anterior a cuenta: conservar el crédito, sin inventar un pago nuevo. |
| SN04 | Nueva seña no / anterior perdida: informar la pérdida y la ausencia de otro anticipo. No equivale a cobrar dos veces ni a haber saldado el precio final. |
| SN05 | Seña todavía impaga: conservar una sola obligación pendiente vinculada al nuevo horario; no crear deuda histórica acumulada ni declarar dinero perdido que nunca llegó. |
| SN06 | Fallo, abandono o movimiento nulo: ninguna pérdida ni nueva exigencia. Repetir el mismo cambio no vuelve a aplicar el destino. |
| SN07 | Más de una reprogramación pagada: distinguir cada cobro, el crédito acumulado aplicable y cada pérdida, sin volver a consumir importes ya perdidos o ya aplicados. |
| SN08 | Señas acumuladas y arancel conocido: limitar el nuevo anticipo al importe positivo de cotización menos señas registradas todavía aplicables; cero implica no pedir más anticipo. Ese cálculo **no es saldo contable total** ni supone pagos externos registrados. |
| SN09 | Precio ausente, ambiguo o prestaciones con precio sujeto a obra social no resuelto: mostrar que no se conoce el saldo; no inventarlo ni aplicar una reducción sobre cero. La seña fija puede seguir su política; el consultorio ve el total registrado y puede exceptuar. |
| SN10 | Excepción puntual: sólo esa obligación, con actor/motivo y sin dinero ficticio. Una obligación nueva sigue su política y se muestra antes de confirmar. Desactivar toda la política conserva la regla segura anterior y no confirma artificialmente turnos sin seña. |
| SN11 | Nueva obligación pendiente: Reservado, sin «Confirmo que voy» que eluda el pago. Registrar o exceptuar la exigencia confirma de forma transaccional cuando corresponda. |
| SN12 | Último momento/plazo habitual ya pasado: informar antes del cambio, mostrar tratamiento de último momento y excluir una baja automática retroactiva; conservar el plazo mínimo aprobado para toda baja que sí se habilite. No activar auto_cancel por reflejo al mover más lejos una obligación ya protegida. |
| SN13 | Registro de pago contra baja automática, en ambos órdenes: resultado único, sin estado mezclado, doble auditoría o horario liberado ocupado dos veces. |
| SN14 | Transferencia tardía con turno cancelado: no reactivar ni prometer devolución. Una acción autorizada registra el dinero/incidente por resolver sin falsear la seña vigente cerrada. |
| SN15 | «Ya transferí»/archivo de comprobante: no acredita automáticamente. El dinero lo registra personal autorizado; E no introduce pasarela ni lectura bancaria. |
| SN16 | Política cambia con pantalla abierta: las condiciones más exigentes requieren revisión y aceptación; reservas anteriores no reciben pérdidas/cargos retroactivos. Deshacer un pago respeta la protección frente a cancelación inmediata. |
| SN17 | Cancelación voluntaria: cerrar turno y conservar pagos; la pérdida aprobada al reprogramar no define por sí sola devolución al cancelar. No ejecutar devoluciones ni marcar automáticamente el pago como perdido. |
| SN18 | Cancelación del consultorio: no imputar al paciente una pérdida por reprogramación; conservar dinero a resolver y auditoría. Restaurar un turno o corregir dinero requiere una acción propia, no deshacer a ciegas toda la historia. |
| SN19 | Migración con señas existentes: registrar sólo el hecho y saldo aplicable que se pueda demostrar a partir del estado real; no reconstruir pagos históricos supuestos, duplicar el importe al crear la historia ni convertir una excepción en dinero recibido. |

### 4.5 Comprobantes y tiempos de aviso — C08, C11, C12

| Caso | Regla y resultado exigido |
|---|---|
| RM01 | Reserva a más de 72 h: comprobante y dos avisos futuros, uno por cada plazo y revisión de horario. |
| RM02 | Entre 72 y 24 h: comprobante y aviso futuro de 24 h. Menos de 24 h: comprobante sin recuperar avisos pasados. Probar igualdad exacta de cada frontera. |
| RM03 | Comprobante justo al vencer un recordatorio: un envío puede satisfacer ambos sólo si contiene toda la información requerida, misma revisión/destinatario y resultado conocido. No suprimir un aviso sólo por proximidad de 30 minutos. |
| RM04 | Mover antes/después: invalidar avisos del horario anterior y calcular sólo los futuros del nuevo; no conservar marcas de cobertura incompatibles. |
| RM05 | Señal de entrega de un mensaje anterior: actualiza ese envío, no la cobertura del nuevo horario ni el estado de pago. |
| RM06 | Seña pendiente: decir Reservado y explicar condición vigente; un comprobante de reserva no es comprobante de pago ni confirmación de asistencia. |
| RM07 | Registro de pago mientras se prepara pedido: revalidar y descartar el pedido de seña innecesario. Mantener el recordatorio ordinario que sí corresponda. |
| RM08 | Pedido de seña y recordatorio coincidentes: combinar sólo con contenido completo y trazabilidad de ambos propósitos. Sin duplicar destinatarios ni afirmar entrega por estar en cola. |
| RM09 | Plazo de seña 48 h y avisos 72/24: el primero puede recordar el plazo; el segundo sólo sale si el turno sigue activo. Auto-cancelado no recibe «Te esperamos». |
| RM10 | Tarea atrasada: ventana técnica inicial propuesta de 30 minutos para recuperar recordatorios aún útiles; después se descartan con motivo visible. Nunca enviar recordatorios de un turno empezado. No es una regla de plazos de pago ni un número aprobado por el usuario. |
| RM11 | Comprobantes atrasados o varios movimientos antes del envío: conservar eventos, enviar el estado pertinente más reciente con su fecha real y descartar versiones incompatibles pendientes. Un mensaje ya entregado no se retracta. |
| RM12 | Cambios al mismo tiempo que se envía: revalidar lo más tarde posible; documentar que una aceptación externa ya ocurrida no puede deshacerse atómicamente con la base. El enlace siempre consulta el estado actual. |
| RM13 | Zona horaria, medianoche, fin de mes y horario de otro país: instantes absolutos para 72/24 y fechas en la zona del consultorio. No usar el reloj del dispositivo como autoridad. |
| RM14 | Activar E con citas antiguas: sólo avisos futuros útiles, sin correo masivo de historial ni cargo económico retroactivo. Respetar bajas previas. |
| RM15 | Push/ICS existentes: mantener sus plazos y reglas propios. No considerar a alguien «avisado» por programar email ni retirar botones de seguimiento sólo por ese supuesto. |

### 4.6 Zoho y entrega incierta — C11

| Caso | Regla y resultado exigido |
|---|---|
| ZH01 | Cuenta creada y dos envíos de Juan: registrar lo informado, no repetir alta ni atribuir integración a esos mensajes. Configuración se puede preparar durante KYC, una vez iniciada E. |
| ZH02 | Dominio/remitente/región/API no comprobados: estado pendiente en configuración, no secretos en chat/git ni activación con una identidad falsa. |
| ZH03 | Cupo inicial 100/día: cupo compartido con cualquier otro envío de la cuenta, contador duradero y margen para pruebas. Obtener reinicio/cupo real del proveedor; no asumir zona ni cuota restante por haber enviado sólo dos mensajes conocidos. |
| ZH04 | Saldo bajo o vencimiento: aviso en app/operación que no dependa sólo de Zoho. Sin auto-recarga. KYC y compras de créditos quedan a cargo de Juan. |
| ZH05 | Límite/saldo agotado: mantener tareas, priorizar comprobantes útiles, descartar recordatorios caducos y no alterar reservas ni plazos de pago silenciosamente. |
| ZH06 | Error temporal conocido: reintentos persistentes acotados por presupuesto y utilidad, sin sostener bloqueos SQL ni bucles de peticiones. |
| ZH07 | Timeout/respuesta ambigua tras envío posible: estado En comprobación y conciliación por referencia/evidencia. No reenviar a ciegas; si el proveedor no permite resolverlo, revisión explícita con riesgo de duplicado comunicado al operador. No prometer exactamente una entrega. |
| ZH08 | Rechazo permanente: detener reintentos y revisar contacto. Rechazo temporal: reintentar sólo mientras el aviso sea pertinente; no borrar un correo escrito por el paciente por una falla temporal. |
| ZH09 | Baja/queja de spam/supresión del proveedor: respetarla también en reprogramaciones, reenvíos manuales y recuperación de cola. No evadir una supresión cambiando el remitente. |
| ZH10 | Notificación falsa, repetida, atrasada o desordenada: autenticar firma, limitar cuerpo, controlar repetición y asociar al envío/consultorio correcto. Guardar recibo antes de responder éxito y procesar sin duplicar. |
| ZH11 | Aceptado/entregado/abierto: son hechos distintos. «Entregado» del proveedor es aceptación por servidor de correo, no prueba de buzón ni de lectura humana. Ninguno confirma asistencia ni pago. |
| ZH12 | Clave revocada, dominio desverificado o servicio caído: fallos visibles y reanudación controlada; no cambiar SMTP de Auth ni improvisar otro proveedor/remitente. |
| ZH13 | Varios consultorios: aislar configuración, destinatarios, referencias, bajas y lectura de estados. Cupos por consultorio no reemplazan el límite global real del proveedor. |

### 4.7 Presentación, privacidad, calendario y operación — C09–C13

| Caso | Regla y resultado exigido |
|---|---|
| UI01 | Sin logo: nombre del consultorio en texto; nunca suplirlo con Cita Suite. Asunto, preencabezado, nombre visible y pie siguen su identidad. |
| UI02 | Imagen bloqueada, texto simple, modo oscuro, pantallas pequeñas, zoom/teclado: contenido y acciones legibles. Validar HTML de email, no sólo la página web. |
| UI03 | Nombres largos o texto con marcas/caracteres especiales: escapar contenido y limitarlo sin ejecutar HTML ni romper enlaces o cabeceras. |
| UI04 | Privacidad: un destinatario por aviso, sin CC de pacientes; no incluir historia clínica, estudios o detalles de salud en asunto, vista previa, cuerpo o adjuntos de calendario. |
| UI05 | Dirección/contacto del emisor incompletos: no inventar datos ni copiar otro consultorio. Completar lo exigido antes de habilitar envíos reales; responder dirige al consultorio configurado. |
| UI06 | Dominio propio del consultorio no disponible: nombre visible no equivale a dirección propia. Verificar el dominio técnico elegido con Juan; la estética no autoriza suplantar un From. Los enlaces de gestión llevan al dominio oficial de la app. |
| UI07 | Seguimiento de aperturas/clics: desactivado inicialmente salvo necesidad justificada; su ausencia no impide usar notificaciones de entrega/rebote. No usarlos como prueba de consentimiento o identidad. |
| UI08 | ICS tras cambiar/cancelar: conservar UID/SEQUENCE y no usar CONFIRMED del ICS para marcar seña pagada. Google se sincroniza por su mecanismo; otros calendarios pueden necesitar importar actualización. |
| OP01 | Escritura guardada y correo/Google fallan: conservar turno correcto y tareas de recuperación visibles. Un fallo de la transacción local sí revierte turno, dinero y eventos juntos. |
| OP02 | Revocación de roles/ayuda: revalidar al ejecutar; configurar correo/política sólo con capacidades apropiadas, registrar/eximir seña con los roles ya autorizados, lectura sola nunca escribe. |
| OP03 | Reserva online apagada: no ofrecer nuevos horarios; conservar consulta y cancelación de turnos vigentes válidos. Suspensión/archivo requieren un permiso mínimo específico de enlace, no bypass global de seguridad/comercial. |
| OP04 | Datos técnicos y errores: mensajes humanos con siguiente acción; secretos, tokens completos y diagnósticos del proveedor sólo en operación protegida, sin exponerlos en UI/email. |
| OP05 | Instalación o recuperación: migración aditiva, proyección compatible, productores y colas controlables; comprobar recuperación con historia y obligaciones nuevas presentes. No reutilizar a ciegas una reversión anterior a E. |
| OP06 | Pruebas y destinatarios: fixtures reconocibles, buzones expresamente acordados, separación de simulación/proveedor real/recepción real. No escribir a pacientes reales por inferencia ni usar sus datos como prueba. |
| OP07 | Consumo: respetar las 40 llamadas y el plazo de la cadena Free, presupuesto separado dentro del existente y progreso de push/calendario. Medir CPU, cola y consultas; no afirmar suficiencia por cantidad de consultorios. |

### 4.8 Provisión por consultorio — ZH02, ZH13, UI05, UI06, OP05

Decisión posterior [12.21/12.22](propuesta-senas-avisos-natalia.md#etapa-e-decisiones-iniciales): un subdominio de Cita Suite por consultorio, envíos activos por defecto y acciones contextuales. Estos detalles amplían las comprobaciones de esos casos existentes, sin convertir el registro administrativo de Zoho en una integración funcional aprobada.

- El subdominio debe ser válido, único y vinculado al consultorio correcto; reservar app/landing/avisos y otros nombres de infraestructura. No derivarlo de un dato personal ni permitir suplantar el de otro consultorio.
- Verificar dominio/From realmente en Zoho y asociarlo al agente correcto. El dominio compartido existente no implica que otro subdominio esté verificado; el nombre visible no sustituye la verificación.
- Provisión repetible ante fallas parciales, consultando antes de crear/alterar. Escribir sólo los registros DNS exactos del emisor, sin sobrescribir app/landing/Auth o eliminar registros ajenos. Un cambio de nombre/slug del consultorio no destruye por reflejo su dominio de envío.
- Preferencia de envíos habilitada por defecto separada de preparación efectiva. Configuración incompleta/pendiente/fallida visible, sin remitentes/contactos inventados, sin envíos falsamente exitosos ni compras/recargas automáticas.
- Reply-To y pie corresponden al contacto real del consultorio; un subdominio de emisión no crea una casilla que reciba respuestas. No compartir destinatarios, bajas, claves de gestión ni estados entre consultorios.
- La selección de acciones usa el estado actual y propósito del mensaje, además de preferencias/permisos/tiempo. Comprobante de turno vigente: acciones pertinentes; comprobante de cancelación: ninguna de Cancelar/Reprogramar. No ofrecer acciones por conservar botones configurados cuando el estado ya no las admite. El enlace antiguo consulta el estado actual.

## 5. Correcciones a la propuesta conversada y límites de prueba

- **Se conserva el enfoque**, pero no basta con conectar dos botones al cambio de estado anterior. C03–C08 exigen nuevas operaciones e historia.
- **Revocar sólo un enlace nuevo no basta** si HTML/ICS o una ruta legada siguen exponiendo otra credencial de escritura. C09/AC09 son requisito de cierre, no una promesa ya demostrada.
- **No congelar duración sin soporte:** el código usa duración actual. RP08 exige mostrar/revalidar; no cambiar ese contrato accidentalmente.
- **No afirmar saldo total:** SN08 se limita a arancel válido menos anticipos registrados aplicables; SN09 conserva explícitamente lo desconocido. No se implementa una contabilidad general.
- **Se retira la supresión genérica de 30 minutos por proximidad:** podría omitir un pedido de seña o un aviso diferente. RM03/RM08 exigen equivalencia de contenido, propósito, revisión, destinatario y resultado.
- **Los 30 minutos de recuperación de recordatorios son un parámetro técnico propuesto**, no un hallazgo del código ni una aprobación literal. Se valida con el intervalo real de ejecución y se documenta cualquier ajuste. No modifica 72/24 ni los plazos de seña.
- **No eliminar guardias comerciales globales:** OP03 es una excepción acotada de gestión de una cita existente. Debe incluir pruebas adversarias antes de publicarse.
- **Reintentos de Zoho:** una referencia propia no documenta garantía de deduplicación del proveedor. ZH07 conserva el estado incierto si no se puede demostrar el resultado.
- **Correos ya aceptados y calendarios externos** tienen límites reales de recuperación. La base puede ser atómica; no hay una transacción común con Zoho, Gmail y Google. No prometer retractación ni recepción exacta a una hora.
- **Cancelación y devolución:** la política del consultorio sobre devolución sigue pendiente. E registra hechos y no mueve dinero. La nueva regla de pérdida sólo cubre la reprogramación voluntaria informada.

## 6. Orden de ejecución de E (autorizado en 12.20; decisiones iniciales resueltas)

1. **E0 — definición y preparación terminadas:** revisión documental, conexiones locales verificadas, autorización 12.20, decisiones iniciales Q01/Q02 y registro de continuidad. Las conexiones administrativas no acreditan integración de la app ni pruebas funcionales.
2. **E1 — contratos y transacciones:** pruebas que fallen primero para revisión semántica, identidad de operación, historial de señas, destino de importes y cola de eventos; migraciones aditivas, permisos, exposición API y tipos. Conservar la proyección uno a uno y las garantías de A/B/C.
3. **E2 — autogestión:** disponibilidad compartida, pantallas de confirmación, movimiento autónomo, tratamiento de pedidos antiguos, revocación de gestión y actualización de calendario. Probar cada carrera en ambos órdenes.
4. **E3 — configuración y email obligatorio:** política por consultorio, aviso de recepción para ficha nueva/existente, preferencias/destinatarios y condiciones antes de reservar/cambiar. Plantillas con identidad del consultorio y las cuatro combinaciones de botones.
5. **E4 — Zoho:** comprobar cuenta existente, dominio/remitente/región, límites y vencimiento reales; custodiar credenciales fuera del chat/repositorio; preparar agente/clave/webhook firmados y envío HTTPS con conciliación. El KYC pendiente no obliga a esperar para preparar y probar lo permitido por la cuenta inicial; no comprar créditos por Juan.
6. **E5 — comprobación:** unidades/SQL/carreras/paquete/navegador en secuencia y con recursos apropiados; adversarias de cada fila, presupuesto de tareas, recibos de Zoho y recepción/uso de enlaces desde los buzones acordados. Anchos 320/390/768/1280/1600, claro/oscuro, accesibilidad y clientes de email. No atribuir al sandbox entrega real.
7. **E6 — publicación:** autorizada por 12.20, con los controles pertinentes al cambio; registrar versión exacta, migraciones, estado de interruptores/colas, recuperación compatible y pruebas del destino. La revisión documental previa terminó; no pedir otra instrucción de inicio ni confundir esta autorización con publicación ya realizada.

Las pruebas pesadas son secuenciales y se reutiliza evidencia aplicable. No renovar copias ni repetir entornos por rutina; sí comprobar específicamente recuperación, integridad de dinero, permisos y ejecución de colas nuevas. No modificar la configuración real de Natalia ni activar señas/cancelación automática con datos comerciales faltantes.

## 7. Criterio de cierre de E

- Cada caso EM/AC/RP/SN/RM/ZH/UI/OP tiene resultado y evidencia por capa; ninguno se marca aprobado sólo por existir un test.
- Hay pruebas negativas contra manipulación de tenant, turno excluido, actor, revisión, monto, política, destinatario, token y notificaciones falsas/repetidas.
- Las carreras cubren cambio/cambio, cambio/cancelación, cambio/pago, cambio/vencimiento, cambio/política, pago/vencimiento, roles revocados y reclamaciones duplicadas de cola.
- Comparación posterior de turno, seña actual, historia de importes, auditoría, hueco, destinatario y avisos pendientes. Sin registros parciales ante fallos provocados.
- Estado incierto de envío y reintento recuperable demostrado sin fingir entrega única; presupuesto y progreso de tareas existentes medidos.
- Prueba integral con recepción real y botones. Los dos envíos previos de Juan no sustituyen esta comprobación.
- Recuperación compatible, documentación general y lista única de pendientes actualizadas con revisión exacta. D y los datos de Natalia faltantes conservan su estado separado.

## 8. Fuentes oficiales del proveedor consultadas el 2 de noviembre

- [Cuenta inicial y revisión](https://help.zoho.com/portal/en/kb/zoho-cpaas/faqs/getting-started/articles/can-i-immediately-start-sending-out-emails-once-i-create-my-account): crédito inicial temporal y límite diario; continuar/comprar requiere revisión. No presentar la cuota de prueba como plan gratuito permanente.
- [Vigencia de créditos](https://help.zoho.com/portal/en/kb/zoho-cpaas/faqs/subscription/articles/what-is-the-duration-for-my-credits): inicial un mes; comprados seis meses.
- [Precios](https://www.zoho.com/cpaas/pricing.html): 10.000 mensajes por crédito; verificar importe/moneda/impuestos al comprar. No se contrató nada en esta revisión.
- [API](https://www.zoho.com/cpaas/help/api/email-sending.html): contenido, remitente/respuesta y referencia propia; no inferir de esa referencia idempotencia garantizada.
- [Webhooks](https://www.zoho.com/cpaas/help/webhooks.html): entrega al servidor receptor, rebotes, quejas y autenticación por firma. El estado entregado no prueba lectura humana.
- [Condiciones](https://www.zoho.com/cpaas/terms.html): correo transaccional, identificación/contacto del emisor y respeto de bajas. Resolver el pie con datos reales; no inventar información de Natalia.

## 9. Punto de continuación

Conexión administrativa local de Zoho completada por instrucción posterior de Juan, con persistencia y renovación comprobadas: [guía](../architecture/zoho-cpaas-terminal.md). La instrucción posterior [12.20](propuesta-senas-avisos-natalia.md#ejecucion-e-autorizada) autoriza E1–E6 completas, incluida producción. Q01/Q02 están resueltas; continuar autónomamente según el [registro activo y su regla de continuidad](ejecucion-etapa-e-20261103.md), sin otra espera de autorización. KYC y pago posteriores son de Juan. Al retomar: comprobar sincronización, leer plan 12.18, este documento, registro, traspaso y pendientes. La configuración de la integración y los nuevos comportamientos **no están desplegados ni comprobados de punta a punta**.
