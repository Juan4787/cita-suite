# Contrato de implementación: turnero, documentos y contacto

Fecha: 14/10/2026. Plan: [propuesta actualizada](2026-10-14-natalia-cita-suite-propuesta.md).
Esta entrega amplía el sistema existente. Noticias y cursos quedan postergados. WhatsApp es
exclusivamente un enlace de contacto, sin mensajes automáticos. No se inventó ni activó la
configuración real del consultorio de Natalia.

## Decisiones confirmadas

- El consultorio ingresa porcentajes; no se consulta IPC ni otro índice.
- Precios nuevos en ARS y pesos enteros. La referencia monetaria se almacena como `bigint`.
- Se conserva precisión durante toda la serie; cada cotización se redondea al final, al entero
  más cercano (mitades hacia arriba) o al múltiplo elegido. Nunca se encadena una cotización
  redondeada para calcular la siguiente.
- 5 MB significa **5.000.000 bytes**, 10 MB significa **10.000.000 bytes** y 700 MB significa
  **700.000.000 bytes**. Se utilizan unidades decimales en límites y presentación.
- Paciente y profesional pueden cargar JPG, PNG y PDF. PDF no crea miniatura ni se abre
  automáticamente. No se incluye validación estructural completa ni cola asíncrona futura.
- No se elimina físicamente un estudio confirmado. La papelera conserva su almacenamiento.

## Aranceles y reservas

Modelo: `service_price_policies`, `service_price_monthly_adjustments` y versiones de
configuración. Una política pertenece a un consultorio y una prestación, opcionalmente a un
profesional de ese mismo consultorio. Las claves foráneas mantienen ese aislamiento.

`base_month` contiene el primer día de un mes actual o anterior. `first_adjustment_month`
es posterior al mes de referencia. El porcentaje habitual se aplica desde el primer ajuste.
Una fila `override` reemplaza el porcentaje **sólo en ese mes**; una fila `default` cambia el
porcentaje habitual desde ese mes en adelante. Un `override` tiene prioridad sobre un
`default` para el mismo mes. Un porcentaje cero congela el aumento de ese mes; no elimina
los aumentos anteriores. Configuraciones con meses duplicados del mismo tipo se rechazan.

Ejemplo sintético: referencia $20.000, dos meses al 2 %, tercer mes al 1 %, cuarto al 0 %:
$20.000 → $20.400 → $20.808 → $21.016 → $21.016. El tercer valor exacto es 21.016,08;
ese valor exacto, y no los $21.016 mostrados, sirve para el cálculo posterior. El redondeo
al múltiplo también se aplica sólo sobre el resultado final. El cliente usa racionales
`BigInt`; PostgreSQL usa `numeric` exacto. No interviene el redondeo de coma flotante.

Precedencia: un turno individual usa la tarifa de su profesional si existe; en su ausencia
usa la predeterminada de la prestación. Los turnos conjuntos requieren una tarifa
predeterminada explícita: **no se suman tarifas individuales**. El administrador elige esa
opción en el mismo editor. Sin política, se conserva el texto de arancel heredado; no se
interpreta ni transforma automáticamente en un importe monetario.

El listado inicial muestra el arancel vigente. Al elegir la fecha se obtiene una cotización
autoritativa para ese mes y aparece el aviso si difiere del importe actual. Se envía su hash
al reservar. El servidor vuelve a resolver política, versión, prestación, participantes,
fecha, moneda e importe dentro de la operación. Una cotización obsoleta impide confirmar;
no crea parcialmente paciente ni turno. La fecha se interpreta en la zona del consultorio.

`appointments.price_quote_snapshot` conserva la cotización aceptada. Cambiar porcentajes
no modifica reservas anteriores. No constituye cobro, comprobante de pago ni deuda. Un
cambio posterior de prestación o participantes de una reserva con cotización requiere
revisión explícita; no sustituye silenciosamente el importe. Un cambio de fecha conserva
el arancel aceptado, según la política de no modificar reservas existentes.

Administradores y dueños configuran todas las tarifas. Un profesional activo vinculado a
su usuario configura sólo su propia tarifa. Recepción, otros profesionales y otro
consultorio no pueden modificarla. Las versiones esperadas evitan sobrescribir cambios
de otra pestaña. La aplicación conserva el borrador si falla el guardado.

## Horarios, seguimiento y feriados

La pantalla conserva un único editor de bloques: días, intervalos y prestaciones permitidas.
Se admite, por ejemplo, martes 14–17 con todas las prestaciones y 17–19 sólo seguimiento.
Los intervalos del mismo día pueden ser adyacentes, pero no solaparse.

Modelo normalizado: `availability_rule_services` y `availability_exception_services` con
claves foráneas por consultorio. `service_scope = restricted` con cero prestaciones queda
**cerrado**. Borrar la última prestación permitida no transforma la franja en general.

Las excepciones admiten bloqueo, disponibilidad adicional y restricción. Se pueden agregar
varias fechas no consecutivas en un lote. Las fechas de día completo se convierten en
intervalos en la zona del consultorio; se mantiene la semántica de fin exclusivo. Se limita
el lote a 366 elementos. Un identificador del lote permite repetirlo sin duplicar excepciones;
cambiar el contenido con el mismo identificador se rechaza.

Se comprueba la prestación y el intervalo clínico completo, incluidos buffers. Disponibilidad
pública, individual, conjunta, creación manual y cambios posteriores comparten las reglas.
La validación SQL impide saltarlas mediante un payload distinto al de la interfaz. Una
excepción global se aplica a todos los profesionales; una individual sólo a su profesional.

Al bloquear un intervalo que contiene turnos, se exige reconocer el aviso. Se conservan
los turnos existentes. Confirmar uno de esos turnos no vuelve a validarlo como una reserva
nueva; reactivar uno cancelado sí vuelve a comprobar las restricciones.

`save_professional_editor` guarda perfil, asignaciones, horarios y excepciones en una
transacción. Un error revierte todo. El reemplazo de horarios y la creación de excepciones
usan la revisión esperada del consultorio; las rutas heredadas no pueden borrar restricciones
sin pasar por el contrato correspondiente. El cliente no elimina horarios como alternativa
si falla el guardado normalizado.

## Cuestionarios e historia médica

Se conserva `professional_booking_forms`: preguntas configurables por profesional, tipos,
obligatoriedad, límites y vinculación con datos del perfil. Se reutilizan los contratos ya
implementados de reserva e información posterior, en lugar de crear otro historial paralelo.

Los campos asociados actualizan obra social, plan, edad declarada, fecha de nacimiento,
medicación, antecedentes y alergias. La edad declarada conserva fecha de referencia; no se
inventa una fecha de nacimiento. Respuestas personalizadas permanecen identificadas y
fechadas. La reserva y los envíos posteriores conservan esquema, respuestas y cambios del
perfil en `appointment_intake_submissions`, con control de versión e idempotencia.

Las respuestas son **declaraciones del paciente**; no se presentan como evaluación validada
por un profesional. La ficha indica su procedencia. La historia clínica y los permisos
clínicos existentes se conservan. No se copian diagnósticos ni respuestas al aviso público.

El formulario posterior renderiza sus valores desde servidor y también puede guardarse sin
JavaScript. La sincronización del cliente ocurre al cambiar la versión real del envío, el
esquema o la reserva, para no reemplazar texto escrito durante la hidratación inicial.

## Documentos: almacenamiento, cuotas y validación

Los bytes se transfieren entre navegador y el bucket **privado** `patient-clinical-files`.
PostgreSQL guarda referencia, metadata y estados; no guarda el PDF ni una representación
base64 en filas. El servidor de Cita Suite prepara permisos y verifica el objeto almacenado;
no funciona como proxy de la descarga completa.

La URL firmada de carga tiene la vigencia nativa de Storage (dos horas). Cada ruta de objeto
reserva 5 MB durante dos horas y quince minutos. Se conserva ese margen incluso si falla la
petición o se elimina un objeto mientras su permiso de carga sigue vigente. Un reintento no
crea una segunda reserva de espacio para la misma ruta. JPG/PNG profesionales pueden tener
una reserva independiente para la miniatura; PDF y cargas del paciente no la tienen.

Hay **dos controles distintos**:

| Control | Importe contabilizado |
| --- | --- |
| Presupuesto global de 700 MB | Objetos de todos los buckets del proyecto + máximos pendientes de las autorizaciones vigentes |
| Tope del paciente de 10 MB / 3 documentos por turno | Bytes reales de sus objetos; para el chequeo anticipado se agregan tamaños declarados de pendientes sin objeto |

Dos documentos de 3,5 MB y uno de 200 KB se aceptan: 7,2 MB reales. La tercera carga puede
reservar globalmente 5 MB, sin convertir esos 5 MB en un supuesto documento de 5 MB del turno.
Si alguien declara 200 KB pero envía 5 MB y excede los 10 MB, el trigger de Storage rechaza
el crecimiento; completar también exige coincidencia del tamaño y MIME con lo declarado.

Un mutex transaccional global y el contador de `clinical_storage_budget` serializan los
cambios. `private.track_storage_budget` controla INSERT/UPDATE/DELETE en `storage.objects`:
crecimiento real, consumo de reservas, límite del archivo, quota por turno incluso sin lease
vigente y metadata nueva acotada a 4 KB por objeto JSON. Un archivo antiguo grande conserva
su acceso; no puede crecer como si estuviera exceptuado del límite nuevo.

Al iniciar se validan tipo, tamaño, nombre, nota, huella declarada e identificador del intento.
En `complete` se usa `storage.info` para comprobar tamaño y MIME. Para PDF se leen hasta
1.024 bytes del inicio y hasta 1.024 del final mediante `Range`; se valida `%PDF-1.0…1.7`
o `%PDF-2.0`, y `%%EOF` al cierre. Se exige una respuesta parcial coherente, incluidos
`Content-Range` y longitud. Si un proveedor ignora Range sobre un archivo grande, se
interrumpe la lectura y la finalización falla, sin descargar el documento entero al Worker.

Las lecturas se acotan y tienen timeout. También se acota el JSON de inicio de la carga.
JPG/PNG conservan validación de firma binaria. La huella SHA-256 la declara el cliente;
**no se verifica el hash completo en el Worker**. `integrity_status = ok` significa superar
estas comprobaciones básicas, no garantizar que todas las páginas abran ni ausencia de
contenido activo. Un PDF internamente dañado puede superar el chequeo básico: la profesional
puede pedir otra copia, tal como se decidió. No hay cola ni parser estructural pendiente.

El estado `ready` exige finalización validada. Si se pierde la respuesta, puede repetirse.
El paciente puede recuperar una carga cuyo objeto ya llegó a Storage sin sobrescribirlo.
Una selección nueva inicia un intento nuevo. La reserva clínica se conserva si falla el envío.

La limpieza manual reclama únicamente cargas abandonadas sin autorización vigente, después
de dos horas y quince minutos. Marca esas cargas como fallidas y elimina por Storage API,
nunca borrando sólo filas de `storage.objects`. También limpia miniaturas huérfanas no
confirmadas de documentos listos, sin tocar su original ni su miniatura confirmada. Conserva
la referencia de esas miniaturas cuando comienza otra carga. Si Storage falla, puede repetirse
la limpieza. No hay purga automática de estudios listos ni papelera.

## Permisos y descarga

| Actor | Capacidad |
| --- | --- |
| Paciente con enlace válido de su reserva | Iniciar/terminar su carga limitada; no listar ni descargar documentos históricos |
| Profesional participante y activo | Ver el documento aportado al turno, según permisos clínicos y pertenencia |
| Otro profesional vinculado al paciente, sin participar del turno | No obtiene acceso a los nuevos documentos de origen paciente sólo por ese vínculo |
| Dueño / administrador con permiso clínico | Ver documentos y administrar configuración y limpieza |
| Recepción / otra empresa / usuario anónimo sin capacidad válida | Sin acceso clínico al archivo |

La capacidad del enlace **no verifica identidad**: quien tenga ese enlace puede usar sus
funciones limitadas. No se agrega OTP ni se afirma que el titular fue autenticado por Auth.
Las rutas obtienen consultorio, paciente y turno del contexto almacenado, nunca de IDs
libres enviados por el navegador. Las consultas autenticadas también aplican RLS; los RPC
expuestos al público se ejecutan sólo desde el servidor, con permisos revocados a `anon`.

La descarga solicita autorización y genera una URL privada de 60 segundos. Para PDF se
responde con descarga y nombre saneado: `Nombre_Apellido_fecha_título.pdf`. El nombre se
obtiene de la ficha autorizada, no de lo que declare el enlace del paciente. El original se
conserva byte por byte. Las URLs firmadas son capacidades temporales y no deben registrarse
en logs, documentos, capturas de red publicadas ni repositorio.

## Indicaciones, recordatorios y contacto

Una prestación puede tener indicaciones de hasta 2.000 caracteres y una descripción pública
de hasta 180. Cada reserva conserva su copia. Cambiar la plantilla sólo afecta reservas nuevas;
un usuario clínico autorizado puede modificar las indicaciones de un turno específico con
control de versión. Los saltos de línea se conservan en la página del turno.

Sólo la descripción pública se agrega a recordatorios y avisos de reprogramación. El editor
explica que puede aparecer en la pantalla bloqueada. Medicación, diagnósticos, respuestas,
notas internas e indicaciones privadas no se agregan automáticamente a esa descripción.
La entrega real de push a un dispositivo no queda certificada por mocks de contenido.

El contacto público tiene una habilitación independiente de la reserva online. WhatsApp usa
`whatsapp_contact_enabled`, separado del antiguo `whatsapp_enabled` de mensajería. Exige un
número confirmado con código de país; el mensaje inicial es opcional y genérico. Natalia
consulta el contacto aprobado, conserva un contacto válido aunque falle el catálogo y crea
un enlace `wa.me` normal. No carga SDK de WhatsApp ni incluye datos del paciente.

La agenda embebida y su SDK se cargan al abrir la reserva. No se modifica la estructura pública
restaurada ni se habilitan cursos/noticias. Ante falta de configuración real, se mantiene un
estado explícito de disponibilidad pendiente.

## Presupuesto Free y límites de la garantía

El panel muestra espacio real, reservas pendientes, porcentaje, tamaño de PostgreSQL y una
**estimación de descargas autorizadas**; esa estimación no equivale a bytes facturados ni a
cuota mensual dura. No se descargan PDFs automáticamente al entrar a la ficha. Los límites
por paciente, archivo, JSON y frecuencia reducen abuso y crecimiento accidental.

Referencia oficial consultada el 14/10/2026: [cuotas Supabase](https://supabase.com/docs/guides/platform/billing-on-supabase)
(1 GB Storage, 500 MB de base por proyecto, 5 GB egress Free). Storage/transferencia se
contabilizan por organización. El presupuesto de 700 MB pertenece a este proyecto, no a
otros proyectos de la cuenta. Revisar consumo total y transferencia en el proveedor sigue
siendo necesario. La app no garantiza permanecer indefinidamente en Free ni conoce sus
métricas de facturación. Los objetos huérfanos físicos del proveedor pueden requerir revisión
adicional; no se inventa que el contador SQL mide toda su ocupación física.

La validación acotada responde a los [límites del Worker](https://developers.cloudflare.com/workers/platform/limits/),
sin afirmar que un PDF de 10 MB por sí solo agotaría la RAM. El procesamiento estructural
sería un gasto distinto; se descartó por alcance y necesidad práctica.

## Reproducción y publicación

Todo se ejecuta **secuencialmente**, sin builds o suites paralelas. No usar `supabase db reset`
en el proyecto vinculado. El runner desechable rechaza URLs y bases externas.

```sh
node scripts/test-booking-foundation.mjs --real-storage --keep
# Usar únicamente el nombre desechable impreso por ese runner:
node scripts/serve-booking-fixture.mjs cita-booking-test-<identificador>
# En otra terminal, con el fixture anterior abierto:
NODE_OPTIONS=--max-old-space-size=1024 node scripts/qa-booking-extensions.mjs
# Ejecutar después del anterior, con Natalia construida:
NODE_OPTIONS=--max-old-space-size=1024 node scripts/qa-natalia-booking-contact.mjs
```

El servidor valida las etiquetas Docker, usa loopback, desactiva cron y simula únicamente
Auth. PostgreSQL, PostgREST, RLS y Storage API son reales y aislados; Storage usa backend
local de archivos. El test de navegador adapta CSP/CORS exclusivamente para el origen
loopback, sin inventar resultados de negocio ni bytes. Esa prueba no certifica Kong, Auth,
Cloudflare, Vercel ni el Storage S3 de producción. El servidor limpia sólo sus contenedores
propios al cerrar; no detener contenedores de otros proyectos.

Las cuatro migraciones nuevas deben aplicarse en orden. Antes de publicar: confirmar destino,
backup/recuperación de schema, privilegio TRIGGER sobre `storage.objects`, tamaño/metadata de
objetos existentes, consumo global del proyecto y organización, permisos y origen exacto de
Natalia. La consulta de privilegios en producción del 14/10 fue sólo lectura y confirmó que
`postgres` puede crear ese trigger y actualizar el bucket. No se hicieron escrituras remotas.

Publicar un backend compatible y comprobar el artefacto servido antes de configurar tarifas,
restricciones o habilitar documentos del paciente. `BOOKING_INTEGRATIONS_ENABLED`,
`BOOKING_CONTEXTS_AVAILABLE` y `BOOKING_INFORMATION_ENABLED` deben seguir habilitados en la
integración nueva. Desactivar el último flag después de configurar políticas puede cerrar el
flujo antiguo porque ya no aporta la cotización requerida; no se permite confirmar con precio
sin aceptar. La habilitación de documentos del paciente es optativa y empieza apagada.

Una vuelta a código anterior después de activar tarifas/restricciones necesita revisión de
compatibilidad o cerrar temporalmente la entrada pública. No quitar triggers ni columnas de
snapshot para forzar una reversión. Conservar historial, reservas y objetos clínicos. El
rollback inicial recomendado, antes de configurar datos nuevos, es volver al artefacto
anterior manteniendo las migraciones aditivas; comprobar sus rutas contra el schema ampliado.

La matriz final de evidencia y hallazgos está en
[el registro de implementación](2026-10-14-implementation-ledger.md). Un pase local no significa
que las funciones nuevas estén publicadas ni que la web tenga datos reales de Natalia.
