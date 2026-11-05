# Traspaso técnico de E — interrupción solicitada el 5 de noviembre de 2026

**Implementación detenida por pedido de Juan. E está incompleta y no está publicada.** Este documento preserva el contexto del agente saliente y su intención de continuación. No es otra especificación, una auditoría nueva ni una orden de ejecutar los pasos propuestos. El pedido posterior de detener y documentar prevalece sobre la continuación autónoma de 12.25; queda registrado en [plan 12.31](propuesta-senas-avisos-natalia.md#traspaso-e-documental-20261105).

El checkpoint de salida es **E3.50** del [registro activo](ejecucion-etapa-e-20261103.md#e350--interrupción-documental-y-resultado-final-del-browser-sn14). Las entradas E3.49 y anteriores son historia de lo observado en sus fechas; su «en curso» no describe una corrida todavía activa. La corrida 42080552190 terminó fallida y su evidencia ya está recuperada. No queda una corrección nueva sin guardar ni una verificación pesada iniciada por este traspaso.

## 1. Fuentes y encargo que estaba ejecutando

La reconstrucción del alcance se contrastó con el plan aprobado original, sus ajustes, la especificación y el registro; no procede sólo de los últimos mensajes ni del resumen de compactación.

| Fuente canónica | Función y precedencia |
|---|---|
| [AGENTS](../../AGENTS.md) | Restricciones de equipo, privacidad, sincronización, contexto productivo y continuidad. El encabezado actual detiene implementación por este pedido. |
| [Plan aprobado íntegro](propuesta-senas-avisos-natalia.md) | A/B/C y decisiones históricas conservadas. Secciones 0–11 no se reescriben; ajustes de sección 12 son acumulativos. 12.18 define E; 12.19 conserva conexión; 12.20 autoriza ejecución/publicación; 12.21–22 resuelven remitente/defaults/contexto; 12.24–25 fijan método; 12.26 pospone tareas posteriores; 12.27–30 registran decisiones de implementación; 12.31 registra esta interrupción. |
| [Especificación única de E](etapa-e-correo-autogestion.md) | Reglas C01–C13, 97 casos EM/AC/RP/SN/RM/ZH/UI/OP, E0–E6 y cierre. Describe lo exigido, no lo ya probado. |
| [Registro activo](ejecucion-etapa-e-20261103.md) | Matriz de aceptación parcial y cronología de decisiones, rojas, fallas, correcciones, evidencias y límites. Incluye la revisión de ingeniería aceptada; no hace falta producir otra para retomar. |
| [Estado vigente](../ESTADO-VIGENTE.md) | Única autoridad documental sobre producción, rama e inventario exacto del código diferente de producción. |
| [Índice documental](indice-etapa-e.md) | Acceso al detalle por componente, contratos, permisos, regresiones, diseño y operación. |
| [Pendientes generales, E](pendientes-vigentes.md#etapa-e-pendientes) | Lista única de pendientes, sin importar como trabajo de E otros encargos. |

El encargo original de esta continuación era **completar E1–E6**, corregir primero las causas estructurales de escritura del personal, continuar autogestión/contacto/correo, verificar la revisión integrada y publicar/probar producción. La autorización existe; no es una publicación ejecutada. El pedido actual es exclusivamente conservar ese trabajo y detener su implementación.

Los requisitos vigentes relevantes para entender lo construido son los siguientes; las excepciones y los 97 casos se consultan en la especificación, evitando duplicar sus tablas:

- Email requerido por defecto en reserva pública directa/integrada, desactivable por consultorio. Recepción puede continuar sin correo con advertencia y alternativa para agregarlo, leyendo la ficha realmente seleccionada. No confundirlo con confirmar el email de una cuenta Auth.
- Comprobantes de reserva/cambio/cancelación, pedidos de seña pertinentes y recordatorios **72/24 horas**. Push y calendario del paciente conservan sus reglas anteriores de 24/2 horas.
- Envíos y botones habilitados por defecto cuando corresponde, con controles independientes. Comprobante de un turno vigente puede ofrecer CANCELAR/REPROGRAMAR; el de cancelación no ofrece ninguno. Abrir enlaces o cambiar de alternativa no escribe. El enlace resuelve siempre el estado actual.
- Reprogramación autónoma con el mismo turno, prestación/equipo/modalidad y duración vigente. Conserva el horario anterior hasta completar el cambio. Confirmación y condiciones económicas visibles antes de escribir; no termina en coordinación manual con recepción.
- Para reservas informadas, nueva seña por defecto al reprogramar voluntariamente y pérdida de aplicación del importe anterior por defecto; ambas opciones configurables. No se borra el dinero recibido ni se crean cargos retroactivos, pagos automáticos o devoluciones. El sistema registra hechos, sin contabilidad bancaria completa.
- Zoho CPaaS sustituye Resend. Cada consultorio debe usar su subdominio verificado de cita-suite.com.ar, sin comprar otro dominio. Nombre/logo/contenido/Reply-To son del consultorio; el cuerpo no lleva promoción ni logo de Cita Suite. Preparación real del emisor y preferencia habilitada son datos distintos.
- Respeto de identidad/tenant, permisos al decidir, concurrencia, repetición, auditoría y dinero transaccionales; proveedores fuera de la transacción y entrega incierta recuperable. No prometer exactamente una entrega externa ni confundir aceptado/entregado/buzón/lectura humana.
- Rigor por garantías y evidencia, con pruebas adversarias y lecturas persistidas. Un test verde no autoriza extrapolar un cierre. No unificar responsabilidades distintas por estética, ni agregar revisiones, calculadores o infraestructuras duplicadas sin garantía concreta.

**Fuera de este encargo:** P1 cancelación desde recepción, P2 estilos globales y P3 avisos internos de horarios liberados están pospuestos por 12.26. Su [documento separado](tareas-posteriores-a-e-20261103.md) conserva los alcances; no se iniciaron como tareas posteriores. La antigua D de push al personal fue reemplazada por P3; no hay una D celular que retomar. A/B/C y otros encargos históricos no se reabren aquí. Los datos comerciales faltantes de Natalia no se inventan.

## 2. Foto exacta local, GitHub y producción

Esta foto identifica el producto que se preserva **antes del commit exclusivamente documental de este traspaso**. El SHA del commit que incorpora el documento se obtiene con `git log -1 --format=%H -- docs/plans/traspaso-etapa-e-20261105.md`; no se inventa un SHA autorreferencial dentro de su propio contenido. El recibo privado de salida conserva la revisión documental final.

| Ámbito | Estado comprobado al preparar el traspaso |
|---|---|
| Carpeta | `/home/usuario/CascadeProjects/CITA SUITE/Cita Suite App`; el padre CITA SUITE no es repositorio. No se trabaja en Landing ni Web Natalia. |
| Rama e historial de producto | `main`, **5ad5c843868fb2abb7f5f3fac610414094d82481**, limpio al iniciar documentación; `origin/main` igual. Origin: `github-secundaria:Juan4787/cita-suite.git`. |
| Último cambio de producto | **79ca40cc9e7ead5d57c08b77e8f66b80555fc391**: etiquetas explícitas for/id de los campos nuevos de dinero tardío. 5ad5c843 es checkpoint documental posterior. |
| Verificación auxiliar | `github-secundaria:Juan4787/cita-suite-verificacion.git`. Sus snapshots tienen otros SHA; no confundirlos con commits de main ni con despliegues. Es público: no incluir información privada. |
| Producción observada por la guardia | **V12b**, revisión **771fac5950c532b1123f11d4dde93eef9b42ceba**. `check-repo-sync.mjs` consultó y aprobó la revisión al preparar el traspaso. No se publica E. |
| Versión Cloudflare registrada | **277d332d-1794-4367-8ef0-567ced159f1b**, según el estado canónico. En este trabajo documental no se volvió a consultar la API de versiones Cloudflare. |
| Esquema de producto | **161 migraciones en el árbol / 30 de E**. SQL30 aprobado en base descartable. Ninguna migración E aplicada por esta ejecución en producción. El registro previo a E tenía 131; este traspaso no hizo otra lectura SQL productiva para certificar cantidad actual. |
| Trabajo sin commitear | Cero antes de documentar. Sólo los documentos propios de este traspaso se incluyen en su commit. La evidencia privada ignorada sigue fuera de Git. |
| Cambios externos | En este traspaso no se envía correo, cambia DNS/Zoho/SMTP/Auth/Google/push, compra crédito ni modifica Natalia. Sólo se recupera evidencia ya ejecutada y se sincroniza documentación. |

El inventario de código respecto de V12b está en el bloque `codigo-distinto-de-produccion` del estado vigente; no se copia aquí. No debe alterarse para ocultar una diferencia. La guardia se corre también después de subir el commit documental. La preservación en GitHub de este documento no convierte E en código publicado a usuarios.

## 3. Implementación que queda conservada

### 3.1 Fundamentos ya escritos, con evidencia parcial por capa

Las migraciones se localizan en [`supabase/migrations`](../../supabase/migrations). Su numeración de E y sus responsabilidades permiten recuperar el código sin tratar cada checkpoint histórico como una instrucción vigente:

| Migraciones E | Responsabilidad conservada y límite |
|---|---|
| 1–8, `20261103010000` a `20261103080000` | Revisión semántica, capacidades revocables, términos financieros, comandos/lectura públicos, repetición ligada a identidad/generación y autorización temporal. Hay suites/contraejemplos del núcleo; no prueban correo. |
| 9–11, `20261103090000` a `20261103110000` | Escrituras de agenda del personal con auditoría/recibo atómicos; cierre de UPDATE autenticado directo; alta/reparación de identidad y autoridad. No se sustituyeron RPC profesionales con otro contrato ni comandos de dinero por el comando de agenda. |
| 12–13, `20261103120000` a `20261103130000` | Revisión monotónica de contacto, revocación y editor autorizado. Hay eventos duraderos de contacto; **su consumidor para correo está pendiente**. |
| 14–17, `20261104010000` a `20261104040000` | Información, documentos, push y presentación auxiliar con permisos separados. Revocar gestión cubre las mutaciones de esas vías. La limpieza física de documentos y retención de capacidades aún no están cerradas. |
| 18–22, `20261104050000` a `20261104090000` | OAuth/Calendar con autoridad, orden de bloqueos, leases, observaciones/retiro/métricas y retención de nonce. Se conserva UID; no se hace revocación global automática de permisos Google al quitar un último evento (12.27). |
| 23–26, `20261104100000` a `20261104130000` | Seis preferencias de correo/CAS, email obligatorio en tres altas públicas, destino informado limitado al turno y orden de bloqueos de contacto. La resolución de destinatario existe; **no hay worker de correo que la consuma**. |
| 27–28, `20261104140000` y `20261105010000` | Términos económicos informados en alta pública y declaración expresa inicialmente desmarcada del personal. Adoptarlos no se infiere de configuración ni de un comprobante posterior. |
| 29, `20261105020000_staff_appointment_delivery.sql` | Preparación explícita de enlaces actuales por personal, pedido de seña y marcas manuales de recordatorio con autoridad/auditoría atómicas. Consumidores de Recordatorios, Señas y detalle conectados; caso browser de personal aprobado. No es entrega de WhatsApp/email. |
| 30, `20261105030000_late_deposit_records.sql` | Hechos monetarios posteriores a cancelación, correcciones, recibo, guardia de identidad y proyección común. SQL y fast aprobados; navegador sólo parcial, detalle a continuación. |

La revisión de ingeniería aceptada y el inventario original de escritores están en el registro activo, entre E2.13/E2.14 y desde E1.45. Importa distinguir aquel diagnóstico **en su fecha** de las correcciones posteriores E1.45–E1.101/E3. No se vuelve a afirmar que la agenda actual siga auditando en una segunda llamada sólo porque esa deuda aparezca en el texto histórico.

La interfaz pública comparte servidor/componentes entre `/gestion/<capacidad>` y `/turno/<legado>` con canales explícitos. Reutiliza disponibilidad y exclusión del turno validado; no emite capacidades nuevas desde GET. El lector entrega fotografía/revisión coherentes. Los POST conservan solicitud original ante resultado incierto y no sustituyen una revisión vieja por una fresca. Las superficies de gestión, información, clínica, PDF, push y calendario conservan sus límites específicos; no toda comprobación SQL equivale a recorrido browser actual.

El alta pública conserva borradores/entrada previa a hidratación y errores nativos: cambios en [PublicBookingFlow](../../apps/web/src/lib/booking/PublicBookingFlow.svelte), [PublicBookingConfirmation](../../apps/web/src/lib/booking/PublicBookingConfirmation.svelte), [PublicBookingIntakeField](../../apps/web/src/lib/booking/PublicBookingIntakeField.svelte) y [BookingBirthDateInput](../../apps/web/src/lib/booking/BookingBirthDateInput.svelte). El vaciado observado era real: efectos de montaje escribían valores iniciales; se usaron bindings/borrador contextual y captura puntual de select/fecha antes del control. El recorrido público posterior lo probó, sin otra biblioteca ni cambio de estilos globales.

### 3.2 Último trabajo: SN14, dinero llegado después de cancelar

Diseño previo escrito en **E3.35**; implementación y contraejemplos en **E3.36–E3.50**. Commits relevantes, en orden: `01208167` (SQL), `fd7c298d` (contratos), `25dc49bd` (consumidor), `1f3df869` (detalle), `509da314` (browser), `98bd6f9a` (identidad de carrera), `85ab1564` (tipos oficiales), `f4eff442` (separación de panel), `7f0a7e4e` (Recordatorios/diagnóstico), `79ca40cc` (etiquetas). No hay nuevo cambio funcional en este traspaso.

| Archivo | Implementación y responsabilidad |
|---|---|
| [SQL30](../../supabase/migrations/20261105030000_late_deposit_records.sql) | Añade `corrects_event_id` a eventos, FK y unicidad de corrección; helpers `appointment_late_deposit_balance` y `appointment_deposit_summary`; guardia de identidad; campo calculado `appointment_deposit_financials`; comando autenticado `record_late_appointment_deposit`; reemplazo sólo del resumen financiero del último snapshot público. |
| [Pruebas SQL](../../supabase/tests/late_appointment_deposits.sql) y [carreras](../../supabase/tests/run_late_deposit_concurrency.sh) | Veinte grupos de estado/roles/importe/replay/privacidad/rollback/identidad y nueve contenciones PostgreSQL reales. El arnés distingue nueva identidad de operación de acción record/correct. |
| [Consumidor](../../apps/web/src/lib/server/scheduling/public/late-deposits.ts) y [pruebas](../../apps/web/src/lib/server/scheduling/public/late-deposits.test.ts) | Parser curado del snapshot financiero y una RPC autenticada por escritura. Sesión fija tenant; no hay prelectura mutable que impida recuperar un resultado ya guardado. Validación previa y respuesta ilegible son categorías distintas. |
| [Servidor del detalle](../../apps/web/src/routes/odonto/turnos/[appointmentId]/+page.server.ts) | Financials y revisión en SELECT original, extracción/validación sin serializar el campo crudo, fallo explícito si contrato inválido; IDs de operación para registro/correcciones; acción `late_deposit` con formulario acotado y permisos actuales. |
| [Interfaz del detalle](../../apps/web/src/routes/odonto/turnos/[appointmentId]/+page.svelte) | Panel propio «Importes registrados», registro/corrección explícitos, confirmación sin marcar, textos humanos, borrador rechazado y retry exacto. La seña cerrada permanece descriptiva sin formularios para resolverla. |
| [Contrato de feedback](../../apps/web/src/lib/scheduling/staff-management.ts) | Acción de retry `late_deposit` distinta de cambio de estado y borrador `{amount,note}`. No reintenta dinero como cancelación. |
| [Términos](../../apps/web/src/lib/scheduling/reschedule-terms.ts) y [parser de pesos](../../apps/web/src/lib/server/scheduling/public/deposit-policy-form.ts) | Se exportaron los validadores existentes como `parseDepositMoney`/`parseWholePesoInput`; no se agregó otro cálculo financiero ni redondeo. |
| [Tipos generados](../../packages/shared/src/database.types.ts) | Importación exacta de tipos oficiales reproducibles después de SQL30 aprobado. Adaptación de nullabilidad SQL existente en [database.ts](../../apps/web/src/lib/types/database.ts); no editar el generado ni reemplazar null por omisión. |
| [Browser SN14](../../apps/web/e2e/late-deposits.spec.ts) | Nativo sin JS, respuesta de servidor realmente guardada pero ilegible, recuperación exacta de registro/corrección, lectura del paciente, temas/contraste/layout y limpieza. **No todo llegó a ejecutarse**, ver sección 5. |

Garantías concretas del comando: rol actual owner/admin/reception mediante autoridad existente y `auth.uid()` real; importe positivo entero de pesos como texto, acotado hasta 10^12; nota hasta 300; turno cancelado y obligación de su paciente actual; puede registrar un hecho después de la fecha del turno. Misma clave de operación comparte el namespace/recibo ya existentes. Fingerprint liga actor, turno, paciente, generación, acción, revisión esperada, importe, objetivo y nota. Recuperar el mismo recibo precede al CAS mutable; reutilizarlo con otra identidad/actor/payload se rechaza.

La transacción retiene la puerta del turno (`FOR NO KEY UPDATE`), registra hecho/corrección, auditoría y recibo juntos y revalida autoridad tras esperas pertinentes, incluidas las provocadas en auditoría/recibo. Corrección apunta a un hecho tardío concreto por su importe completo; una sola por original. Se conservan ambos eventos. **No cambia estado/horario/seña/exigencias/calendario/outbox**, no reactiva, no ejecuta devolución ni aplica otra penalidad. La guardia compartida de identidad rechaza reparación mientras el neto tardío sea positivo; si la reparación gana antes, la escritura con expectativa vieja no hereda la nueva persona. Al corregir a cero puede permitirse reparación normal sin trasladar historia al nuevo paciente.

La proyección financiera devuelve cadenas exactas y sólo datos curados. El campo calculado vuelve a leer el turno real para que un compuesto falsificado no elija otra persona. La lista de hechos tardíos está acotada a los últimos **50**, con indicador de truncamiento; el total considera todos. No muestra autores/notas/metadata. Esta UI no ofrece una navegación completa de historia contable ni corrección de un hecho fuera de esos 50; es un límite explícito, no una garantía de contabilidad general.

### 3.3 Distribución manual y composición de Recordatorios

La preparación común está en [staff-delivery.ts](../../apps/web/src/lib/server/scheduling/public/staff-delivery.ts) y SQL29. GET no acuña enlaces, ni serializa el token legado como alternativa. Los POST fijan teléfono/destino y capacidad vigentes bajo la autoridad SQL. Reabrir un pedido requiere revisión expresa; la marca manual conserva una auditoría al recuperar el mismo intento. Una preparación cuya respuesta se pierde puede dejar una capacidad no usada: sólo se guardan hashes, no se prometió recuperar su texto ni exactamente una emisión.

El aviso de cancelación automática de [Señas/avisar](../../apps/web/src/routes/odonto/senas/avisar/[appointmentId]/+server.ts) es lectura actual mínima autorizada, sin nueva capacidad. No ofrece reprogramar un cancelado. El constructor de pedido de seña recibe reloj explícito: después de vencer no promete un vencimiento futuro ni una baja automática por venir. Teléfono inválido/ausente no elimina las operaciones de dinero autorizadas.

En [Recordatorios](../../apps/web/src/routes/odonto/recordatorios/+page.svelte) sólo se corrigió composición puntual: separadores unidos al texto con espacios inseparables y grupos flexibles sin comprimir etiquetas. Las capturas habían mostrado cortes reales a 768 px; el caso posterior pasó con cinco anchos/dos temas. No se ejecutó P2 ni una revisión global de todos los estilos. La transparencia del encabezado general no se trató como nueva tarea aquí.

## 4. Decisiones significativas y fundamento recuperable

Esta tabla explica las decisiones conocidas del agente; no atribuye retrospectivamente una razón que no esté en el registro/código. Para las decisiones anteriores, el fundamento detallado y sus contraejemplos siguen en sus checkpoints originales.

| Decisión | Fundamento, alternativa y límite |
|---|---|
| Corregir los escritores afectados y conservar comandos distintos | La revisión aceptada halló lectura/autorización/atomicidad incompletas entre caminos. E1.45 inventarió agenda, alta/reparación, dinero/política/vencimiento, RPC profesional y telemetría. Se cerró UPDATE directo al integrar consumidores necesarios. No se unificaron contratos con distinta autoridad sólo para tener una RPC. Recuperación de una app vieja sigue siendo un riesgo de publicación. |
| Generación, revisión semántica y revisión de agenda tienen propósitos distintos | Generación revoca identidad/acceso; revisión semántica detecta modificaciones relevantes/ABA; schedule_revision delimita cambios de agenda sin rearmar avisos por telemetría. Se rechazó ampliar otras revisiones para esta garantía (regresiones documentadas). No se agregó una nueva revisión financiera/staff para SN14. |
| Recibo antes de precondiciones mutables, con autoridad e identidad actuales | Una respuesta perdida puede corresponder a un commit real. Rehacer disponibilidad/política primero impediría recuperar ese commit; recuperar sólo por fingerprint histórico podría revelar un resultado tras reparar identidad. Se exige recibo autorizado y vinculado a identidad/generación, sin otra operación por defecto. |
| Reloj real al decidir tras bloqueos | now()/transaction_timestamp quedan fijados al empezar. Se reprodujeron permiso/plazo válidos al inicio pero vencidos al escribir. Helpers comunes reciben reloj pertinente, sin alterar el contrato temporal de lectores anteriores. No garantiza que el permiso siga vivo cuando llega la respuesta; garantiza el punto de decisión de la operación. |
| Historia económica separada y proyección uno a uno | Varias obligaciones y destinos no caben sobrescribiendo el único paid/pending. La historia conserva hechos y la proyección mantiene lectores existentes. No se inventa saldo total ni se aplica pérdida a reservas no informadas. SN14 reutiliza eventos y recibos existentes; no crea otro ledger de reintentos. |
| Contacto público nuevo limitado a ese turno | Nombre/teléfono del contrato de reserva no autentican una edición global de email. 12.28 preserva la dirección informada por esa reserva sin modificar otras; una corrección autorizada con epoch monotónico la supersede, incluso ABA. La revalidación del worker futuro sigue pendiente; el helper no es autorización de envío. |
| Información económica pública y declaración del personal | 12.29/30: configuración activa no prueba que el paciente fue informado. Se conserva resumen aceptado/declarado, se rechaza endurecimiento concurrente y se permite relajación equivalente. Checkbox de personal empieza vacío. No se lo presenta como consentimiento independiente autenticado ni como pago. |
| SN14 separado de resolver una seña cerrada | El primer fast detectó una regresión válida de UX al poner el nuevo formulario dentro del panel cerrado. Se movió al panel de importes; se mantuvo la aserción correcta. Corregir un error de carga no es devolver dinero ni deshacer la cancelación. |
| Etiquetas explícitas para importe/nota | En Playwright instalado 1.60.0, getElementLabels/elementText incluye el texto SSR del textarea dentro de label implícito; una búsqueda exacta dejó de coincidir después del POST. For/id separa nombre y valor sin cambiar payload/aserción. La corrida siguiente sí superó nota/importe nativos; no se interpretó aquel fallo como pérdida de dinero. |
| No atribuir la espera nativa original al foco | Se agregó diagnóstico y bringToFront sin force ni subir timeout. La evidencia posterior mostró la página ya visible/enfocada antes. La mejoría no prueba causa: esa hipótesis no quedó demostrada. |
| No revocar OAuth global al quitar último evento | Una nueva autorización puede aparecer entre borrado local y revocación externa; Google revoca permisos del proyecto, no sólo del evento. 12.27 retiró ese efecto global, manteniendo borrado del evento/credencial local. No se creó otra cola ni una lectura adicional que pretenda cerrar una carrera externa. |
| Reutilizar capas aprobadas | SQL30 sin cambios no se repite por etiqueta/composición; público aprobado no se repite por UI exclusiva del personal; personal aprobado no se repite por SN14. Sí queda pendiente verificar la revisión integrada final. Una prueba pasada de otro SHA sólo sustenta la parte de código que permanece aplicable. |

Para detalles sobre el orden de bloqueos de contacto, leases externos, URLs clínicas firmadas y cuarentena, ver contratos/registro. No se presenta aquí una nueva solución decidida para los pendientes de worker/presupuesto/limpieza. Las alternativas de esa continuación permanecen abiertas, sección 7.

## 5. Evidencia obtenida y resultado exacto más reciente

### 5.1 Capas aprobadas que se conservan

Todas estas corridas son del repositorio **Juan4787/cita-suite-verificacion**. Un «caso aprobado» dentro de una corrida fallida no vuelve verde la corrida. Las rutas de colección se entienden bajo `.verification/etapa-e-20261103/` y son privadas/ignoradas; no se copian a Git. Su huella es la del bundle validado por el colector, no un hash de todos los archivos de la carpeta calculado con otro algoritmo.

| Capa / corrida | Fuente exacta y resultado verificable | Colección / SHA-256 del bundle |
|---|---|---|
| [SQL30 42073541134](https://github.com/Juan4787/cita-suite-verificacion/actions/runs/42073541134) | **SUCCESS**. Producto `98bd6f9a0706bc5963122dd899a5a46fbead04b6`; snapshot `5b0e6f8d2304f246f180b7ee545bb8298d9f158d`, rama `verify/e-late-deposit-distinct-20261105`. 161/30 migraciones; veinte grupos SN14/nueve carreras, regresiones anteriores (incluidas dieciocho esperas de autoridad, 48 carreras/dos contraejemplos FK, cinco de contacto y cuatro de política). Sin aumento de deadlocks; retiro de dos contenedores/una red. | `sql-late-deposit-distinct-evidence`, 4 archivos; `5994c277ffde5a9e1470606417c366b84f876f1efc3f00e31e91d197010d729d` |
| [Fast 42076262537](https://github.com/Juan4787/cita-suite-verificacion/actions/runs/42076262537) | **SUCCESS**. Producto `f4eff4429d3e779c0fc59f5751d86efb6f4b1901`; snapshot `321bf832d5d3ea7f66f0a388d200c3e6029d36a5`, rama `verify/e-closed-obligation-context-20261105`. 2038 servidor/300 cliente; cero errores/avisos Svelte, e2e/guardias/arquitectura, 962 módulos/2098 dependencias. Después cambiaron sólo composición Recordatorios, etiquetas de dinero y pruebas/documentación. No equivale a fast completo de un futuro release. | `fast-closed-obligation-context-evidence`, 7 archivos; `ff180dce99f4a8ddd8383c5966fcae5ebf306eb53e65deb785b89826d67b0a6e` |
| [Público en 42021721105](https://github.com/Juan4787/cita-suite-verificacion/actions/runs/42021721105) | **Caso público aprobado; corrida completa fallida por personal entonces**. Producto `66aa8fe`; snapshot `cd6ca8e90140ac331e7be6b934d151236769c65d`, rama `verify/e-public-and-staff-delivery-20261105`. POST real, endurecimiento atómico, misma clave, condiciones persistidas; datos/query/fecha/selección sin JS y antes de hidratación; pago SQL/movimiento real; anterior perdido y una pendiente de 40000; cancelado sin Cancelar/Reprogramar; cinco anchos/dos temas, layout/pageerrors cero y limpieza. No prueba proveedor/banco. | `browser-public-staff-delivery-evidence`, 25 archivos; `a21327fb6202d5a417f39df62ce7159b2217c2efeadc7c6bee263ad3ed3019c1` |
| [Personal en 42078792126](https://github.com/Juan4787/cita-suite-verificacion/actions/runs/42078792126) | **Caso personal aprobado; corrida completa fallida por SN14**. Producto `7f0a7e4e`; snapshot `ede092989cfe5a41b75546edf6cd98bc99665afd`, rama `verify/e-native-money-context-20261105`. GET sin emisión/legado, corrección contacto revoca, capacidad nueva válida, preparación seña/reapertura, marcas/replay con una auditoría, aviso de cancelación sin capacidad nueva. Tres superficies × cinco anchos × dos temas efectivos, 30 capturas, issues=[], limpieza. WhatsApp interceptado, externalSend=false. | `browser-native-money-context-evidence`, 48 archivos; `da53c4066344b3b8c7fb32b8db17dccab39b38d006fab9ed626862ded2be941d` |

Tipos oficiales SQL30: **202518 bytes**, SHA-256 **c001b6748a0c38fa65d77d1e7ee2eced7566d398bc0609cb9b2786a5739acc00**, digest de migraciones **cee6e187383ab68838d7f8e86621f3d0bb4e8d329126e4544798c021b9eaa758**. Se compararon nombres y bytes del snapshot/árbol antes de importar, no sólo cantidad de migraciones. No cambió SQL después de esa prueba.

Dirigidas locales de servidor/puras de SN14: `late-deposit-consumer-before.log` fue ausencia del módulo durante colección, no casos de dinero fallando; después `late-deposit-consumer-after.log`, **56/56 en tres archivos**. Detalle: `late-deposit-detail-before.log`, seis fallas/diecisiete aprobadas antes de acción/SELECT; después `late-deposit-detail-after.log`, **87/87 en cinco archivos**. Son una tarea/512 MB; no se ejecutó cliente/JSdom local. El fast hospedado posterior cubrió esos casos cliente. `delivery-current-context.log` conserva las 145 dirigidas previas aplicables.

### 5.2 Resultado recuperado al detener: 42080552190

[Corrida final de navegador](https://github.com/Juan4787/cita-suite-verificacion/actions/runs/42080552190): **COMPLETED / FAILURE**, creada **2026-11-05 18:03:22 UTC**, terminada **18:07:28 UTC**. Producto **79ca40cc9e7ead5d57c08b77e8f66b80555fc391**; snapshot **1e9cf67847d5c7635576f9ea9583680931eaef1e**; rama **verify/e-native-money-labels-20261105**; sólo filtro `late deposit:`. No repetía personal/público. Reporte Playwright 1.60.0: **0 expected / 1 unexpected / 0 skipped / 0 flaky**, un worker/sin retry; caso fallido en 20,572 s. El watch local ya terminó; no lanzar un reemplazo al leer el viejo E3.49.

Evidencia recuperada y validada, sin sobrescribir otra colección:

- ZIP de logs: `.verification/etapa-e-20261103/browser-native-money-labels-logs.zip`.
- Colección: `.verification/etapa-e-20261103/browser-native-money-labels-evidence`, **16 archivos**; bundle SHA-256 **099f5d52c9e90a38de8bc34409c81b0a64055f82d3a4bb2f75edfb37a1742358**.
- Reporte dentro de la colección: `.verification/runs/4cd76f1c-e4dd-499b-be43-ad84511e76be/diagnostic-4cd76f1c-e4dd-499b-be43-ad84511e76be/browser-diagnostic.json`.
- En ese directorio: `browser-artifacts/late-deposits--candidate-b-7f7bc-y-and-contextual-correction/error-context.md`, `test-failed-1.png`, `test-failed-2.png`; además logs de Vite/página y estado de plataforma. El reporte referencia un video, pero **no está en los 16 archivos recuperados**: no afirmar haberlo inspeccionado o preservado en esta colección.

**Lo que se alcanzó:** por el orden del spec y su punto de fallo, pasaron las aserciones nativas de POST 400 con aviso humano/importe 1,5 y nota conservados, cero recibos/estado cerrado intacto, luego ingreso 10.000 con éxito humano y `[1,0,1,1]` (hecho/corrección/recibo/auditoría) y estado cerrado intacto. También se completó carga de formulario JS, importe 25.000/nota/checkbox y detección del submit listener antes de intentar el clic siguiente. No se dispone de un recibo final `late-deposit-proof` porque no se alcanzó su generación.

**Fallo exacto:** `locator.click` agota 15000 ms esperando el botón «Registrar dinero recibido» dentro de `#late-deposit-record form`, **línea 64 de loseThenRecover**, llamado desde **línea 145** del spec. El snapshot del fallo muestra «Importes registrados», total por resolver 10.000 y el grupo «Registrar dinero después de cancelar» sin sus controles desplegados en el árbol accesible. Esto es observación, no causa demostrada. No hay prueba nueva de un commit del ingreso 25.000 ni de su respuesta destruida; la aserción `intercepted` posterior al clic no llegó a ejecutarse.

**No alcanzado en esa corrida:** recuperación de registro JS, corrección/recuperación, neto final público 10.000 tras corregir 25.000, matriz de cinco anchos/dos temas, contraste, health final y recibo final. Las comprobaciones de cierre del fixture no reportaron un segundo error distinto del timeout; esto no sustituye el recibo integral faltante. Tampoco es evidencia de pérdida de dinero, error de SQL, foco causante o entrega externa. No se diagnostica/corrige ahora por la orden de detener implementación.

### 5.3 Fallas anteriores importantes y su clasificación

El registro conserva cada fuente/bundle completo. Estos hitos evitan repetir investigación o clasificar todas las rojas como defectos de producto:

| Corrida | Hallazgo y resolución registrada |
|---|---|
| 42068364845 | Browser personal llegó a acciones, falló por h1 ambiguo banner/main al comenzar matriz. Se acotó el ancla del test, sin cambiar producto; E3.36. |
| 42070842232 | Dos escrituras dependientes en una sentencia de prueba compartían snapshot STABLE; correcto conflicto CAS. Se separaron sentencias, sin modificar SQL30 ni expectativas; E3.38. |
| 42071785428 | Veinte grupos SQL pasaron; sintaxis CASE en IF del arnés de carreras impidió ejecutarlas. Se parentizó, no cambió producto; E3.39. |
| 42072613604 | «Dos correcciones distintas» reutilizaba misma operación; el replay correcto contradecía la intención del fixture. Identidad nueva se separó de acción record/correct; E3.41. No se aceptó duplicar como solución. |
| 42074892469 | **Regresión de producto/UX**: nuevo formulario dentro del panel de obligación cerrada. 2038 servidor y 299 cliente pasaron/uno falló. Se separó el panel sin debilitar la aserción; E3.44 y fast posterior aprobado. |
| 42076886857 | **Defecto visual observado** en Recordatorios (etiquetas comprimidas/separadores); se corrigió composición. SN14 se detuvo antes del POST nativo por estabilidad; causa no establecida. Captura automática era la agenda principal, no la página nativa ya cerrada; E3.46. |
| 42078792126 | Personal pasó completo. SN14 llegó al POST 400, falló el locator exacto de la nota SSR; se separó label/valor con for/id. Diagnóstico mostró visible/foco=true antes de bringToFront; no confirma teoría de foco; E3.48. |

SQL30 no cambió para las tres fallas de arnés SQL anteriores a su aprobación. Las deficiencias estructurales históricas sí reproducidas —autorización al inicio en vez de al decidir, recibos no ligados a identidad vigente, herencia de condiciones/dinero al reparar, composición insegura con triggers— se explican en la revisión aceptada del registro y sus correcciones posteriores. No son «simples problemas de tests» por la existencia de estos ejemplos distintos.

## 6. Conexiones, investigaciones y límites externos

### Zoho

[Guía canónica de terminal](../architecture/zoho-cpaas-terminal.md), herramienta [`scripts/zoho-cpaas.py`](../../scripts/zoho-cpaas.py). OAuth persistente en región com con refresh token: `~/.config/cita-suite/private/zoho-cpaas.json`, archivo 600/directorio 700; no requiere daemon. **No imprimir, copiar a Git/chat/argumentos ni volver a pedir credenciales si funcionan.** `status` comprueba presencia; `agents` realiza consulta remota y renueva si corresponde. En la implementación anterior a este pedido ambos se ejecutaron y agents devolvió un agente tras renovación. Este traspaso no repitió esa consulta ni ejercitó envío.

Respuestas privadas: `~/.local/share/cita-suite/zoho/`, en particular `mailagents-latest.json`, `domains-latest.json`, `email-latest.json`, `apikeys-latest.json`. El wrapper de agentes es `{observed_at,resource,response}`; respuesta con data/status y agente con mailagent_key/name/status/created_time/description. Ese listado **no devuelve cuota/saldo/KYC**, y no se deducen por su éxito. Una clave existente de agente se leyó y guardó privadamente; no se generó otra ni se instaló en Worker. La API real usa campo **apikey**, aunque un ejemplo oficial usa token. Once comprobaciones sintéticas de la CLI sin red están en `zoho-existing-key-read-proof.json`. OAuth administrativo no sustituye la clave de envío.

Investigación preparatoria que quedaba para implementación, **sin prueba externa de esas garantías**. Notas originales privadas: `.verification/etapa-e-20261103/zoho-proveedor-preparacion-20261104.md` y `zoho-keys-contract.txt`; no contienen una integración ejecutada:

- Envío documentado por `/v1.1/email`, autenticación `Zoho-enczapikey`. Fuentes ya consultadas: [envío](https://www.zoho.com/cpaas/help/api/email-sending.html), [índice](https://www.zoho.com/cpaas/help/api/api-index.html), [autenticación](https://www.zoho.com/cpaas/help/api/api-authentication.html), [claves](https://www.zoho.com/cpaas/help/api/list-api-keys.html).
- `client_reference` no demuestra idempotencia del proveedor. Los registros se consultan por referencia del proveedor; no se probó conciliación por una referencia propia cuando se pierde toda respuesta. Ante incertidumbre el diseño requerido conserva «En comprobación», no reenvía a ciegas.
- [Webhooks](https://www.zoho.com/cpaas/help/webhooks.html#securing-webhooks): cabecera documentada `producer-signature`, con `ts=...;s=<Base64 codificada en URL>;s-algorithm=HmacSHA256`; preparar verificación sobre el valor de formulario decodificado una vez, no JSON reserializado. El MAC mostrado no permite suponer que el timestamp esté firmado. Aún hay que comprobar contrato con callback real, binding/dedupe duraderos, cuerpo acotado y orden de estados. **No se recibió un webhook firmado real ni hay receptor integrado**.
- Aperturas/clics pueden apagarse; siguen apagados inicialmente según requisito. No sirven como identidad, consentimiento ni prueba de pago.
- El índice consultado no mostraba API de saldo/cupo; eso no demuestra que el panel/soporte no puedan suministrarlo. Reinicio de cuota/consumo externo a la app/KYC/saldo/expiración actuales siguen desconocidos. Los 100/día y dos envíos son lo informado por Juan el 2, no saldo actual certificado.
- El dominio compartido `avisos.cita-suite.com.ar` ya figuraba verificado, pero no verifica automáticamente cada subdominio elegido después. No hay provisión por consultorio implementada ni decisión de sustituir esa exigencia por From compartido. Un subdominio no crea un buzón de Reply-To.

### Gmail y restricciones de pruebas

El conector Gmail quedó conectado y perfil/búsqueda/lectura se habían comprobado antes, según registro de inicio de E. **No se volvió a ejercitar Gmail en este traspaso ni se verificó recepción de E en esa cuenta**. Destino real autorizado para las pruebas de correo de esta campaña: **citasuite@gmail.com**. No usar por inferencia direcciones de pacientes/Natalia ni enviar correo a terceros. Los envíos manuales previos de Juan no son la integración E.

SMTP de Auth sigue separado (Gmail ya configurado); no cambiarlo por Zoho. KYC/pago los hace Juan, sin compras ni recargas por el agente. Sin cambios reales de DNS, Google, push o cuentas en esta preservación documental.

## 7. Cómo tenía pensado continuar

Esta es **la intención técnica del agente antes de la interrupción**, con su motivo. No es una obligación impuesta al siguiente agente ni autorización para ignorar el pedido actual de documentación. Las entradas del registro anteriores a esta interrupción ya enumeraban contacto/outbox/SN14/retención/Zoho/E5–E6; no se agrega un plan ajeno.

1. **Concluir la verificación browser de SN14 que estaba en curso.** Quería inspeccionar resultado, estado y capturas antes de decidir corrección. Ahora el resultado está recuperado: el primer trabajo de investigación que habría hecho es explicar por qué los controles del formulario JS dejan de estar disponibles entre llenado/listener y el clic en loseThenRecover. Habría contrastado snapshot y ciclo de hidratación/apertura de details, manteniendo expectativas/payload/estado; no tenía una causa demostrada ni una corrección decidida. El nativo ya pasó, por lo que no habría vuelto a tratar el locator SSR anterior como problema abierto. Evitaría force, subir tiempos o rellenar después para fabricar un verde. Sólo después habría repetido el caso necesario y completado recuperación real de registro/corrección y visuales. No habría repetido personal/público/SQL por una modificación aislada de ese test o marcado.
2. **Resolver contacto/eventos y entrega como una categoría coherente antes de activar correo.** Hay epoch, evento duradero y helper de destinatario, pero no consumidor. Pensaba seguir las transiciones paciente/email/identidad y su invalidación de enlaces/trabajos hasta el worker, definir precondiciones/lease/punto de decisión y crear o cerrar los trabajos pertinentes en transacción. No marcar un evento como consumido antes de persistir su consecuencia recuperable. La salida externa revalidaría destinatario/paciente/generación lo más tarde posible; un snapshot de email no autoriza enviar. Habría reutilizado los patrones de leases/recibos comprobados, sin llamar a Zoho reteniendo locks ni prometer retirar un email ya aceptado.
3. **Completar retención/cuarentena física y límites auxiliares pendientes.** Quería cerrar retención de capacidades expiradas y documentos revocados con los ledgers/cuotas existentes, distinguiendo metadata revocada de bytes borrados. El acceso a URL firmada ya emitida tiene intervalo residual (registrado como 2 h + margen de 15 min); no se puede afirmar revocación instantánea de una URL externa. No había una implementación nueva de limpieza lista ni una razón para reconstruir cuotas a partir de datos supuestos.
4. **Completar el recorrido de correo con Zoho y su preparación real.** Habría verificado datos de emisor/subdominio/Reply-To/pie y estado actual de la cuenta, implementado provisión repetible acotada, plantillas HTML/texto con acciones contextuales, outbox/leases/estado incierto/conciliación, bajas por consultorio-dirección y webhook autenticado con dedupe. Destinar comprobantes/pedidos/recordatorios a la revisión vigente y descartar versiones incompatibles/caducas con motivo. El orden fino entre esquema de outbox, worker y provisión todavía no estaba fijado; necesitaba sus contratos y límites externos reales, no otro diagnóstico general del núcleo ya aceptado.
5. **Resolver específicamente el presupuesto de tareas antes de enganchar email al push.** La lectura preparatoria encontró que `scheduled-jobs.ts` despacha push directamente a sendPushReminderBatch y el presupuesto compartido entra en finalización permanente; después `admits` es falso. Añadir simplemente email después del push podría dejarlo sin trabajo en todas las ejecuciones. Pensaba estudiar la mínima coordinación que reserve llamadas/tiempo y pruebe progreso justo de ambas colas. No había un diseño elegido ni consta una comparación completa de variantes: el punto pendiente era coordinar y reservar presupuesto con garantías de progreso. No atribuyo a esa lectura una selección o descarte de alternativas; no modifiqué ese código. Habría medido llamadas, CPU, consultas y cola, manteniendo límite de 40 llamadas/cadena, 20 s, reserva final y cinco crons; no contratar ni crear un sexto cron Free. No afirmaría suficiencia por haber un consultorio.
6. **Reconciliar la matriz de los 97 casos y completar contraejemplos funcionales pendientes.** Entre ellos las cuatro combinaciones de dinero, equipo/exclusión, duración/política concurrentes y fronteras de contacto/supresión/entrega. Aprovecharía pruebas ya válidas, pero sin convertir una tabla vieja o un test escrito en aprobación integral. Probaría estados persistidos, fallas parciales y recuperación por capa, distinguiendo fixtures inválidos/servicios descartables ausentes de fallos de producto.
7. **Verificar integración externa y revisión exacta antes de publicar E.** Recepción real sólo en el buzón acordado, lectura mediante Gmail, enlaces actuales y consecuencia SQL; contrato real del webhook/conciliación y consumo. Después artefacto/recovery compatible/esquema/flags, regresiones integradas y publicación/pruebas productivas autorizadas. V12b utiliza caminos que E cierra con nuevas restricciones; **volver sin más a V12b no es recuperación E demostrada**. Pensaba preparar un consumidor compatible que conserve operación/dinero/identidad y controlar productores/colas antes de cambiar destino. No había seleccionado ni empaquetado esa recuperación ni una candidata final de E.

Al completarse E habría avisado a Juan y entregado el índice/documentación; **no** habría seguido P1/P2/P3. Esa precedencia estaba resuelta, no una duda que requiriera pedir permiso otra vez.

### Hipótesis, alternativas y dependencias todavía abiertas

- No está determinada la causa de la espera original de estabilidad nativa ni la del fallo JS más reciente. El snapshot con details sin controles sugiere dónde observar el ciclo de render/apertura; no prueba por sí solo hidratación defectuosa, ni se eligió solución. No hay evidencia para atribuir pérdida del ingreso 25.000 o duplicación de dinero.
- No está probada entrega única de Zoho; no debe ofrecerse como garantía. Conciliación después de timeout sin referencia del proveedor puede requerir revisión explícita; su automatización exacta no se eligió. No asumir endpoint de búsqueda por client_reference no comprobado.
- Cuota diaria real, zona/reset, consumo manual externo, saldo/vencimiento y KYC actual desconocidos. No se decidió un contador ficticio ni utilizar como saldo el resultado de agents. No se puede cerrar ZH03/04 por haber dos mensajes conocidos.
- El reparto de presupuesto push/email y el progreso sin hambre de cola siguen sin diseñar/medir. La simple anexión después de finalización no sirve como diseño. No se añade complejidad hasta justificar el mecanismo.
- Retención de capacidades y cuarentena/borrado físico clínico pendientes; no hay prueba de bytes retirados ni de revocación retroactiva de URLs ya firmadas. Mantener contabilidad del almacenamiento realmente retenido.
- Política de devolución al cancelar y datos comerciales faltantes de Natalia siguen fuera de una inferencia técnica. El registro monetario tardío resuelve un hecho pendiente; no decide devolución ni activa su política real.
- No se comprobó el HTML final en clientes de email, imágenes bloqueadas/texto plano/modo oscuro, footer real ni dominios por consultorio. Las capturas de la app no cubren esas superficies.
- No hay prueba de publicación E, ensayo compatible de recuperación E ni cierre integral de regresiones de la revisión final. No declarar E terminada por sumar pruebas de distintos snapshots.

## 8. Recuperación práctica del contexto y evidencia

### Lecturas y comandos sin implementar nada

Desde la raíz de App:

```bash
node scripts/check-repo-sync.mjs
git status --short
git log -1 --format='%H%n%s'
git log -1 --format='%H%n%s' -- docs/plans/traspaso-etapa-e-20261105.md
gh run view 42080552190 --repo Juan4787/cita-suite-verificacion --json status,conclusion,headSha,url
```

Se usan para recuperar estado, no para iniciar una tarea pesada. Si aparece trabajo ajeno no se descarta ni se agrega al commit propio. No usar reset/clean/restores globales ni `git add -A`. La guardia exige `main`, igualdad con GitHub, producción en la historia y diferencias declaradas; no falsificarla para cerrar documentación.

El mecanismo existente de recuperación de evidencia es [`collect-verification-evidence.py`](../../scripts/collect-verification-evidence.py): descarga ZIP de logs de Actions, valida chunks/completitud/hash y extrae en **destino nuevo**. La colección de 42080552190 ya existe; no descargar ni sobrescribir por rutina. Los links de Actions y ramas de snapshot permiten localizar fuente aun si expiran artefactos. Las evidencias privadas locales no viajan con un clone de Git: si quien continúa cambia de computadora necesitará las carpetas privadas por un canal adecuado; **no publicarlas** para resolverlo.

Los reportes `browser-diagnostic.json` guardan adjuntos JSON como base64: decodificar sólo los nombres necesarios (proof/health/diagnóstico), sin imprimir el archivo completo. `generated-database-types.json` contiene todo el source generado y `.verification/ci-source.json` un manifiesto grande; consultar sólo campos seleccionados. Los ZIP contienen líneas CITA_EVIDENCE con archivo completo codificado: excluirlas antes de mostrar un extracto de error. No volcar respuestas de Zoho, notas, tokens o cuerpos de correo.

Herramientas de verificación que ya se usaban: `prepare-ci-snapshot.mjs` para snapshot aislado y workflow `refactoring-verification.yml` del auxiliar; evidencia SQL/tipos antes de fast/browser cuando cambia esquema. No se lanzó ningún workflow desde este traspaso. Los snapshots aprobados de SQL30/fast y el caso público/personal se reutilizan en sus límites. No ejecutar todo de nuevo sólo por leer un documento de continuidad.

### Recursos y fronteras operativas

- Equipo local de RAM muy limitada. SQL/containers/generación de tipos/build/cliente JSdom/browser sólo CI hospedado secuencial. Las dirigidas locales puras/servidor previamente usadas eran un worker y 512 MB; este traspaso no corrió esas pruebas.
- No había Browser del host aprobado expuesto; se usó Playwright hospedado del repo, fallback ya registrado. No se instaló navegador local ni TestKase. La existencia de herramientas de otro proyecto no amplía alcance.
- No quedan watches o procesos pesados iniciados por este traspaso. El watch previo de la corrida terminada se recogió con salida 1. No se afirma haber cerrado procesos de otras sesiones.
- Proteger cuenta/configuración/acceso de Natalia y las credenciales/cuentas/dominios reales. No importar datos de clientes a los snapshots públicos. Pruebas sintéticas autorizadas no convierten infraestructura o usuarios reales en fixtures.
- Dominio oficial de enlaces de app: `https://app.cita-suite.com.ar`. No usar workers.dev como dirección pública por conveniencia de pruebas.

## 9. Cierre de esta preservación, no de E

Este documento se guarda junto con plan 12.31, checkpoint E3.50, índice, traspaso general, pendientes, AGENTS y estado vigente, conservando el inventario de código. Los enlaces y el alcance exclusivamente documental se comprueban antes del commit; el commit propio se sube a origin/main y se vuelve a ejecutar la guardia. El recibo privado de salida registra el SHA documental final y resultado de sincronización en `.verification/etapa-e-20261103/traspaso-documental-20261105/`.

No se pudo verificar en este trabajo: causa del fallo JS, recuperación browser de los dos comandos monetarios, resto de visuales SN14, integración/entrega/recepción E, cuota/KYC/expiración, webhooks reales, limpieza física pendiente, recuperación compatible E ni publicación E. Producción conserva V12b. La documentación distingue esos límites; la implementación queda detenida para que otro pueda continuar sin perderlos.
