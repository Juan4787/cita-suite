# Cita Suite: archivos clínicos en Supabase Storage — fase 1

## Actualización de alcance — 14 de octubre de 2026

La ampliación a PDF y carga por el paciente está implementada localmente y se audita en
[el contrato de extensiones](audits/2026-10-14-booking-extensions-contract.md). Ese contrato
prevalece para los archivos nuevos: 5 MB por archivo, PDF sin miniatura, presupuesto global
700 MB y capacidad limitada por reserva. La fase original siguiente queda como antecedente;
no describe por sí sola los límites ni los permisos de la ampliación. Las migraciones de la
ampliación todavía no se aplicaron a producción.

## Estado y propósito

Este documento es la referencia funcional, técnica y operativa de la fase 1 aprobada el
20 de agosto de 2026, implementada y auditada localmente hasta el 21 de agosto de 2026. Se
mantiene dentro del repositorio para que las decisiones no dependan del historial de una
conversación ni se pierdan por compactación de contexto.

La fase 1 reemplaza Google Drive por almacenamiento clínico privado en Supabase y adopta la
regla central:

> Si una persona está autorizada a acceder clínicamente al paciente, puede ver sus archivos y
> radiografías activas. La autoría de la carga se registra, pero no crea propiedad exclusiva.

La implementación también corrige la escalabilidad de la pantalla Pacientes: carga inicial de
30 registros por actividad relevante, búsqueda global autorizada en servidor y paginación por
cursor.

## Alcance aprobado

Incluido en fase 1:

- eliminación de Google Drive de la experiencia y del flujo operativo;
- un bucket privado de Supabase Storage;
- originales inalterados y miniaturas independientes;
- subida directa del navegador a Storage, sin transportar los bytes por Netlify;
- acceso compartido por permisos clínicos del paciente;
- permisos diferenciados por rol;
- URL firmada breve para abrir un original;
- validación de archivo, tamaño, tipo, firma binaria, ruta y objeto almacenado;
- estados de carga `uploading`, `ready`, `failed` y `trashed`;
- estado de integridad independiente;
- Papelera de radiografías para Dueño y Administrador;
- restauración sin volver a subir el archivo;
- auditoría de alta, acceso concedido al original, envío a Papelera, restauración y anomalías;
- rate limits específicos, máximo de cargas pendientes y medición estimada de transferencia;
- detección periódica de originales faltantes;
- evaluación y tratamiento explícito de referencias heredadas de Google Drive;
- actualización de Términos y Privacidad;
- carga, búsqueda y paginación server-side de pacientes en bloques de 30;
- conservación del contexto del listado al volver desde una ficha;
- pruebas unitarias, de contrato SQL, integración local, compilación y navegador.

Expresamente fuera de fase 1:

- backup externo en Backblaze B2 u otro proveedor;
- recuperación desde backup;
- exportación masiva o descarga integral de datos, incluidos sus manifiestos;
- purga física controlada, incluido “Vaciar Papelera”, el borrado automático por antigüedad y la
  eliminación definitiva desde la cuenta master.

Abrir una radiografía individual dentro de Cita Suite sí pertenece a fase 1. “Exportación” se
refiere a obtener en bloque el historial o todos los archivos de un consultorio.

## Riesgo residual aceptado temporalmente

En fase 1 Supabase Storage es la única copia física operativa. La Papelera protege contra
borrados lógicos accidentales, pero no protege frente a pérdida o corrupción completa del
proyecto o del Storage. Por eso la interfaz y los documentos legales no deben afirmar que existe
un respaldo externo ni prometer recuperación ante una pérdida física.

Hasta que exista fase 2, es un invariante de seguridad:

> Ningún archivo clínico que haya llegado a `ready` puede eliminarse físicamente desde Cita Suite.

No se concede `DELETE` sobre objetos clínicos al cliente. Tampoco hay endpoint de purga para el
master. Sólo pueden limpiarse posteriormente cargas incompletas que nunca llegaron a `ready`;
esa limpieza no forma parte del flujo de usuario de esta entrega.

## Arquitectura

```text
navegador autenticado
    │
    ├─ solicita inicio de carga a Cita Suite
    │      └─ autorización + rate limit + fila uploading + URL firmada de carga
    │
    ├─ sube original y miniatura directamente a Supabase Storage
    │
    ├─ solicita completar a Cita Suite
    │      └─ verifica metadata, tamaño, MIME, firma binaria y rutas; marca ready
    │
    └─ para abrir original solicita un access grant
           └─ autorización + rate limit + auditoría + URL firmada de 60 segundos
                  └─ descarga directa navegador ↔ Supabase Storage
```

Netlify procesa control y metadata liviana. No funciona como proxy de originales ni miniaturas.
La auditoría de apertura registra que Cita Suite concedió acceso; no prueba que el navegador haya
terminado de transferir todos los bytes.

## Bucket y rutas

Bucket único privado:

```text
patient-clinical-files
```

Rutas:

```text
{business_id}/{patient_id}/{radiograph_id}/original.jpg
{business_id}/{patient_id}/{radiograph_id}/original.png
{business_id}/{patient_id}/{radiograph_id}/thumbnail.webp
```

Las rutas sólo contienen UUID. Nunca contienen nombre, DNI, teléfono, correo, diagnóstico ni
otro dato humano. Conocer una ruta o UUID no concede acceso.

Las cargas usan `cacheControl = 0`. Las respuestas de control llevan `private, no-store` y las
URLs firmadas no se almacenan en la base ni en el caché de la lista.

El tamaño máximo inicial es 25 MiB por original. Fase 1 admite únicamente JPEG y PNG. HEIC,
HEIF, SVG, PDF, DICOM y tipos genéricos se rechazan con mensajes humanos que explican el paso
siguiente. La miniatura WebP se genera en el navegador con un lado máximo de 480 px. Si la
miniatura falla, el original puede quedar disponible y la UI usa un reemplazo visual.

## Modelo de metadata

La tabla heredada `patient_radiographs` se evoluciona; no se crea una segunda fuente de verdad.
Los campos conceptuales de fase 1 son:

```text
id
business_id
patient_id
uploaded_by
client_request_id
original_filename
mime_type
bytes
sha256
storage_bucket
storage_path
thumbnail_path
status
integrity_status
taken_at
note
created_at
ready_at
deleted_at
deleted_by
restored_at
restored_by
failure_code
```

Los campos heredados de Drive se conservan temporalmente sólo para inventario o migración. La
aplicación nueva no los usa como origen de archivos y no crea nuevas referencias de Drive.

`owner_id` deja de representar propiedad y no puede provocar borrado en cascada al eliminar al
usuario que cargó. `created_by`/`uploaded_by` son auditoría y admiten `NULL` si la cuenta deja de
existir.

### Ciclo de vida

```text
uploading ──complete──> ready ──trash──> trashed ──restore──> ready
    │
    └────fail────────> failed
```

Las transiciones se realizan mediante funciones específicas, autorizadas e idempotentes. El
cliente no puede actualizar libremente el estado.

### Integridad

Dimensión separada:

```text
unchecked | ok | missing | checksum_mismatch
```

En fase 1 se valida presencia, tamaño, MIME y firma binaria antes de `ready`. El SHA-256 del
original se calcula en el cliente y queda guardado para reconciliación y fase 2. Una comprobación
periódica contrasta metadata activa/Papelera con `storage.objects`; si falta un original, marca
`missing` y deja auditoría sin destruir metadata. Si un objeto reaparece, permanece bloqueado: la
sola presencia no demuestra que conserve los bytes esperados y la recuperación verificada queda
para fase 2.

No existe `backup_status` en fase 1 para evitar representar una protección inexistente.

## Matriz de permisos

| Acción | Dueño | Administrador | Profesional vinculado | Recepción | Sólo lectura |
| --- | ---: | ---: | ---: | ---: | ---: |
| Ver radiografía `ready` | Sí | Sí | Sí | No | No |
| Subir | Sí | Sí | Sí | No | No |
| Abrir original | Sí | Sí | Sí | No | No |
| Enviar a Papelera | Sí | Sí | No | No | No |
| Ver Papelera | Sí | Sí | No | No | No |
| Restaurar | Sí | Sí | No | No | No |

“Profesional vinculado” significa que `user_can_read_clinical_patient` es verdadero para ese
consultorio y paciente en el momento de cada operación. No basta con pertenecer al consultorio.

Para metadata activa se exige acceso clínico y `status = ready`. Para Papelera se exige rol
Dueño/Administrador y `status = trashed`. Recepción y Sólo lectura no pueden usar una
consulta básica del paciente para descubrir metadata clínica.

El estado comercial también se verifica en cada solicitud. Con cuenta activa o en gracia, los
roles habilitados pueden realizar las acciones de la matriz. En modo restringido, Dueño y
Administrador conservan lectura de imágenes existentes y de Papelera, pero no pueden subir,
enviar a Papelera ni restaurar. El Profesional no conserva acceso clínico en modo restringido. Una
cuenta archivada no puede entrar a estas superficies. Así, la lectura de continuidad comercial no
se confunde con permiso de mutación.

## Contratos HTTP

Los recursos se exponen bajo la ficha del paciente:

```text
GET  /odonto/pacientes/{patientId}/radiografias
POST /odonto/pacientes/{patientId}/radiografias/uploads
POST /odonto/pacientes/{patientId}/radiografias/{radiographId}/complete
POST /odonto/pacientes/{patientId}/radiografias/{radiographId}/failed
POST /odonto/pacientes/{patientId}/radiografias/{radiographId}/access-grants
POST /odonto/pacientes/{patientId}/radiografias/{radiographId}/trash

GET  /odonto/pacientes/papelera/lista
POST /odonto/pacientes/papelera/{radiographId}/restore
```

`complete`, `failed`, `trash` y `restore` son idempotentes para su estado final. Repetir una
solicitud tras un corte de red no duplica registros ni rompe transiciones.

Respuesta de error estable:

```json
{
  "code": "UPLOAD_LIMIT_REACHED",
  "message": "Hay varias cargas en curso. Esperá a que terminen y probá nuevamente.",
  "retryAfterSeconds": 120
}
```

Los códigos permiten pruebas y manejo interno. La interfaz muestra sólo el mensaje humano y la
acción siguiente. Los errores de Postgres, Storage, rutas, IDs, SQL, HTTP o RLS nunca se muestran
al usuario.

## Subida y validación

1. El cliente valida extensión, MIME declarado, tamaño y bytes iniciales.
2. Calcula SHA-256 del original y prepara una miniatura independiente.
3. `uploads` vuelve a validar datos, autorización, límites y cantidad de cargas pendientes.
4. La base crea una fila `uploading` con UUID y rutas decididas por el servidor.
5. El servidor genera tokens temporarios de carga para las dos rutas exactas. Se usan de inmediato,
   no se guardan y llevan `upsert = false`; una carga no puede sobrescribir otra.
6. El navegador sube directamente a Storage y muestra progreso; sólo una carga se inicia desde la
   interfaz a la vez.
7. `complete` obtiene la información real del objeto con credenciales de servidor, exige ruta,
   tamaño y MIME esperados y comprueba firma JPEG/PNG mediante una lectura corta.
8. La función de finalización vuelve a comprobar actor, paciente, negocio y estado; pasa a
   `ready`, registra auditoría y actualiza la actividad clínica del paciente.
9. Si una etapa falla, se marca `failed` de forma idempotente y se ofrece reintentar creando una
   carga nueva. Nunca se reutiliza una ruta que pueda sobrescribir contenido.

## Acceso a originales y miniaturas

- Las listas devuelven miniaturas mediante URLs firmadas breves generadas sólo después de validar
  acceso. No se audita cada render.
- Abrir un original requiere un access grant separado.
- El grant valida el estado `ready`, la integridad y el acceso clínico actual.
- El límite inicial es 300 grants por hora por usuario.
- Se inserta `radiograph.original_access_granted` con tamaño estimado y consultorio.
- La URL del original vence a los 60 segundos y no se guarda en base de datos, logs ni caché.
- Las URLs de miniatura vencen a los 5 minutos y sólo se generan para filas autorizadas.
- El visor vive dentro de Cita Suite; al cerrarlo se descarta la URL.
- Las verificaciones posteriores a la firma encapsulan cualquier falla antes de registrarla, para
  que una excepción de red tampoco pueda imprimir accidentalmente la URL firmada.

## Papelera de radiografías

La entrada está dentro de Pacientes. En escritorio, debajo del listado y alineada con el ancho del
bloque:

```text
Papelera de radiografías        Ver más        Reportar problema
```

En móvil se apilan controles táctiles con la misma jerarquía. La entrada sólo se muestra a Dueño y
Administrador.

Enviar a Papelera hace `ready → trashed`, registra `deleted_at`/`deleted_by`, la retira de la ficha
activa y no toca objetos. Restaurar hace `trashed → ready`, registra restaurador y fecha, y no
vuelve a subir nada. No existen controles de eliminar definitivamente, vaciar ni vencimiento.

La Papelera usa paginación por cursor en bloques de 30 y búsqueda server-side por paciente o
archivo. Nunca expone archivos de otro consultorio.

## Límites y protección de costo

No se agrega un rate limit global a toda la API. Se amplía el limitador server-side existente con
acciones específicas:

- inicio de carga: 6 por minuto y 60 por hora por usuario;
- máximo de 3 filas `uploading` recientes por usuario;
- acceso al original: 300 por hora por usuario;
- envío a Papelera: 30 por minuto por usuario;
- restauración: 30 por minuto por usuario.

Además, 25 MiB es un límite duro de objeto y la UI no inicia cargas concurrentes. La auditoría
registra bytes de uploads completados y access grants, lo que permite estimar transferencia por
consultorio. Los umbrales 2/5/10 GB diarios son observabilidad inicial, no bloqueos automáticos:
un falso positivo no debe impedir acceso a información clínica.

La función `get_clinical_file_daily_transfer_estimates(fecha)` es exclusiva de `service_role`,
calcula cada día en la zona horaria del consultorio y clasifica `normal`, `watch_2gb`, `high_5gb`
o `critical_10gb`. Es una estimación operativa: no representa la métrica de facturación de
Supabase porque no puede observar reintentos de red, caché ni todas las transferencias internas.

## Pacientes: actividad, búsqueda y paginación

La pantalla no descarga 200 ni todos los pacientes. Carga 30 y solicita otros 30 con “Ver más”.

`activity_at` representa actividad clínica o asistencial, no cualquier edición administrativa:

- alta del paciente;
- creación o cambio relevante de un turno asociado;
- entrada clínica creada o modificada;
- radiografía que llega a `ready` o se restaura.

Una modificación de teléfono, dirección u otro dato administrativo no hace subir por sí sola a la
persona. Un turno futuro cuenta cuando se crea o modifica el turno, usando el momento de la
interacción, no la fecha futura del turno.

La búsqueda consulta todos los pacientes que el usuario actual está autorizado a ver. Para un
profesional, sólo sus vínculos activos; jamás permite descubrir nombres, DNI o teléfonos fuera de
su alcance. Campos mínimos: nombre, DNI y teléfono. Se normalizan mayúsculas, acentos y dígitos.

Orden de búsqueda:

1. DNI o teléfono exacto;
2. nombre que comienza con el texto;
3. coincidencia dentro del nombre;
4. coincidencia parcial de DNI/teléfono;
5. actividad reciente e ID como desempate estable.

Se consulta con 250–300 ms de debounce a partir de dos caracteres, se cancelan o ignoran
respuestas antiguas y los resultados también se paginan de a 30.

El cursor es opaco, firmado con HMAC-SHA256 y ligado a consultorio, estado activo/archivado y
consulta normalizada; contiene snapshot, orden e ID, no datos personales. Un cursor modificado,
reutilizado en otro consultorio o aplicado a otra búsqueda se rechaza. La paginación es keyset,
nunca offset. Las filas ya visibles no cambian de posición solas. Los cambios de actividad se
reflejan al actualizar o iniciar una nueva visita.
Durante una sesión se deduplican IDs y se acota la consulta al snapshot; si un registro todavía no
visible recibe actividad concurrente posterior al snapshot, puede aparecer recién en la próxima
visita. Esta es la garantía de UX aprobada, no una promesa de snapshot histórico matemático.

El caché continúa siendo privado, sólo en memoria y ligado a usuario/rol/consultorio/revisión. Se
extiende por estado + consulta. Se guarda aparte un contexto sin datos clínicos (consulta, cantidad
cargada y scroll) para intentar restaurar la posición al volver; si cambian permisos o revisión,
los datos se vuelven a pedir antes de mostrarse.

## Legado Google Drive y corte

El inventario remoto repetido antes de publicar confirmó que la migración experimental
`20260820010000_individual_google_drive_folders.sql` nunca fue aplicada: producción llega a
`20260805163000` y tampoco existe la tabla `patient_drive_folders`. Por decisión explícita de
producto, ese borrador se eliminó del lote y no se incorporará al historial ni a producción. La
migración de esta fase funciona sin esa tabla opcional, revoca las superficies Drive heredadas que
sí existen desde el esquema original y deja sus filas/columnas sólo como inventario no utilizable.

El inventario read-only previo al corte encontró 29 filas heredadas de radiografías: 27 en estado
`ready` con `drive_file_id`, 2 en `uploading` y 3 conexiones personales. El responsable del producto
confirmó que esas imágenes son pruebas y no deben migrarse ni condicionar esta entrega.

La decisión de fase 1 es, por lo tanto:

- no copiar contenido desde Drive;
- no mostrar referencias heredadas en la aplicación nueva;
- no permitir nuevas conexiones, carpetas, cargas, lecturas ni escrituras de Drive;
- no borrar destructivamente las filas heredadas durante este cambio;
- excluirlas de los contadores, la Papelera y la reconciliación de Supabase Storage.

Esas filas permanecen inertes únicamente por trazabilidad histórica. No existe una migración de
contenido pendiente ni un bloqueo de salida asociado a ellas.

## Legal y comunicación

Privacidad y Términos deben decir que Cita Suite aloja imágenes clínicas en infraestructura privada
de Supabase, controla el acceso según roles/vínculos y conserva en Papelera sin borrado definitivo
en fase 1. Deben eliminar afirmaciones como “Cita Suite no almacena los archivos” y toda explicación
operativa de Drive.

También deben decir con precisión que todavía no existe backup externo ni recuperación garantizada
de objetos. No se prometen exportación ni purga hasta fase 2 y revisión jurídica.

## Invariantes verificables

1. Un `ready` nuevo posee original en la ruta exacta de su metadata.
2. Un `trashed` conserva original y miniatura y puede restaurarse.
3. Nadie recibe `DELETE` de objetos clínicos ni endpoint de purga.
4. Conocer IDs o paths no concede acceso.
5. Eliminar al uploader no elimina ni vuelve inaccesible el archivo al consultorio.
6. Un profesional sólo ve/sube si tiene vínculo clínico activo con ese paciente.
7. Recepción y Sólo lectura no ven metadata, miniaturas ni originales.
8. Sólo Dueño/Administrador ven Papelera, envían a ella o restauran.
9. Repetir `complete`, `trash` o `restore` conserva el mismo resultado.
10. URLs firmadas no aparecen en logs, base de datos ni mensajes de error.
11. La pantalla Pacientes abre con un máximo de 30 filas.
12. La búsqueda encuentra coincidencias autorizadas fuera de esas 30.
13. “Ver más” no duplica filas y desaparece cuando no hay más.
14. La lista visible no se reordena sola por eventos paralelos.
15. Errores de producto son humanos y ofrecen un siguiente paso sin detalles técnicos.

## Decisiones técnicas de cierre

- El plano de control de archivos es server-only. El navegador autenticado no puede insertar,
  actualizar ni borrar `patient_radiographs`, ni ejecutar las RPC de ciclo de vida.
- Cada RPC recibe el actor ya autenticado, vuelve a resolver rol, consultorio, paciente, vínculo y
  estado comercial, y no confía en que la ruta HTTP haya autorizado correctamente.
- Los límites de tres cargas pendientes se serializan con advisory lock por consultorio + actor;
  el caso concurrente queda atómico incluso entre pestañas o dispositivos.
- `ready` y `trashed` restringen físicamente el borrado del paciente y del consultorio. Eliminar
  una cuenta de usuario pone las referencias de autoría en `NULL`, pero conserva archivo y auditoría.
- El backend conserva `SELECT` y `INSERT` sobre auditoría, pero no puede actualizar ni borrar
  historial; tampoco puede mutar directamente radiografías ni rate limits.
- Las fechas clínicas se comparan con el día local del consultorio, no con la zona horaria del
  servidor de Netlify.
- Las búsquedas escapan `%`, `_` y `\\` como literales. Una búsqueda de un carácter no consulta al
  servidor y las respuestas tardías no pueden reemplazar una búsqueda más nueva.
- El contexto comercial usado por archivos es siempre fresco. Una lectura corta del layout puede
  compartirse por 12 segundos para superficies no sensibles, pero una carga hija `fresh` la
  omite incluso dentro del mismo request. Así una restricción recién aplicada se refleja sin
  recargar manualmente ni esperar el TTL.
- La reconciliación de integridad se programa cada seis horas, al minuto 17. La migración falla con
  `CLINICAL_INTEGRITY_CRON_UNAVAILABLE` si `pg_cron` no está realmente disponible; no existe un
  despliegue silencioso sin control periódico.
- Supabase CLI queda fijado exactamente en `2.115.0` como dependencia de desarrollo. Esto evita
  que una CLI global antigua interprete de forma distinta `config.toml` o la generación de tipos.
- SvelteKit se actualizó a la línea corregida 2.70 y `nanoid` se fijó en 3.3.18 para cerrar los
  avisos de seguridad detectados sin cambiar el stack de la aplicación.

## Ejecutor E2E local

`pnpm test:e2e:local` obtiene las credenciales del Supabase local ya iniciado, rechaza cualquier
host que no sea localhost, habilita las regresiones destructivas locales y usa un solo worker.

La aplicación no posee purga en fase 1. Por eso el fixture que prueba una carga real no podría
eliminar su propia metadata al terminar. El ejecutor concede temporalmente `DELETE` sobre
`patient_radiographs` a `service_role` sólo en esa base local y lo revoca en un bloque `finally`,
aun si Playwright falla. No concede acceso a `server_rate_limit_events`, no modifica la migración
de producción y no puede ejecutarse contra un host remoto.

Los fixtures usan identidades únicas y respetan el rate limit real. Las pruebas dejaron de vaciar
la tabla privada de rate limits, de modo que ya no dependen de un permiso que el producto prohíbe.

## Estrategia de pruebas y salida

El cierre exige, en orden y con baja concurrencia por memoria disponible:

1. prueba desde cero de todas las migraciones en Supabase local;
2. pruebas SQL de RLS por rol, vínculo, consultorio, estado y Storage;
3. pruebas unitarias de validación, cursores, errores y rate limits;
4. pruebas de servidor para cada endpoint e idempotencia;
5. pruebas del listado/cache/contexto;
6. `pnpm check`;
7. Vitest con un solo worker;
8. build de producción;
9. build Netlify;
10. Playwright secuencial en escritorio y móvil para subir, abrir, papelera, restaurar, búsqueda,
    Ver más y regresiones de recepción/profesional;
11. auditoría de dependencias;
12. inspección final del diff y estado Git.

El despliegue de esquema, publicación a GitHub y verificación de hosting son estados separados. No
se declara fase 1 completa en producción sólo porque compile localmente.

## Resultado final de auditoría — 21 de agosto de 2026

### Base de datos y seguridad

- reconstrucción final de Supabase local desde cero: correcta, con todas las migraciones aplicadas;
- generación de tipos TypeScript con la CLI fijada: correcta;
- pgTAP: 13 archivos, 13 contratos, todos aprobados;
- concurrencia real: dos invitaciones simultáneas produjeron una sola asociación de correo; dos
  reservas produjeron un éxito y un rechazo exacto por límite 4/4; dos inicios clínicos produjeron
  un inicio y un rechazo por máximo pendiente; los tres scripts aprobaron;
- `supabase db diff --local --schema public,storage`: sin deriva de esquema;
- bucket confirmado privado, límite 26.214.400 bytes y MIME JPEG/PNG/WebP;
- un único cron activo `17 */6 * * *` para reconciliación;
- observabilidad ejecutable por `service_role` y no por `authenticated`;
- `service_role` sin `DELETE` final sobre radiografías y sin acceso directo a rate limits;
- ningún negocio, usuario, correo permitido, fila clínica, objeto Storage ni archivo físico de los
  E2E quedó como residuo.

### Aplicación

- `pnpm check`: 0 errores y 0 advertencias;
- Vitest servidor: 76 archivos y 614 pruebas aprobadas;
- Vitest cliente: 2 archivos y 29 pruebas aprobadas;
- Playwright local final: 21 casos descubiertos, 8 aplicables aprobados y 13 omisiones
  condicionales declaradas; cero reintentos y un worker;
- dentro de esos E2E, los 2 casos clínicos completos aprobaron: carga de Dueño y Profesional,
  lectura compartida, visor, Papelera/restauración, paginación global, búsqueda, contexto móvil y
  no descubrimiento por Recepción;
- también aprobaron asistencia de cuenta, bloqueo comercial desktop/mobile, registro y las dos
  regresiones destructivas de roles/agenda;
- build SvelteKit de producción: aprobado;
- build mediante `scripts/netlify-build.mjs`: aprobado;
- CSP de producción admite imágenes y conexiones Supabase, y ya no admite frames de Drive;
- `pnpm install --frozen-lockfile`: aprobado;
- `pnpm audit`: sin vulnerabilidades conocidas;
- `git diff --check`, conflictos, marcadores de merge, depuración accidental y marcas de trabajo
  pendiente en archivos tocados: sin hallazgos pendientes.

### Verificación del sitio publicada antes del lanzamiento

Con las credenciales E2E provistas se verificó de forma no destructiva la versión que hoy está
publicada: login/navegación/smoke, tres casos de Seguimientos de sólo lectura/UI y la reserva
pública en desktop y móvil. La URL pública respondió 200, mostró el consultorio esperado, no tuvo
overflow horizontal ni errores de página.

Esto fue evidencia de que el baseline publicado seguía sano antes del lanzamiento. No se
ejecutaron operaciones que crearan o alteraran información clínica de la cuenta proporcionada.

### Hallazgos encontrados y cerrados

- una lectura comercial corta podía sobrevivir dentro del mismo request y mostrar controles
  clínicos antiguos; se separó la procedencia del caché y se agregó la regresión exacta;
- el cron podía omitir silenciosamente la programación si faltaba su esquema; ahora la migración
  falla de forma explícita;
- `fail_patient_radiograph_upload` no repetía la frontera comercial; ahora bloquea mutaciones en
  modo restringido y tiene pruebas de idempotencia y auditoría única;
- el permiso visual de una ficha no distinguía al Profesional restringido; ahora coincide con la
  autorización de servidor, mientras Dueño/Administrador conservan sólo lectura;
- el fixture E2E intentaba borrar tablas protegidas; se eliminó ese atajo y se creó el ejecutor
  local acotado descrito arriba;
- la selección de equipo en el asistente manual podía vaciar los slots ya cargados; se conservan
  los resultados válidos y pasaron las regresiones completas de Agenda;
- la configuración local dependía de una CLI global incompatible; quedó fijada en el repositorio;
- las dependencias reportadas por auditoría se actualizaron y la auditoría final quedó limpia.
- el postflight remoto detectó tres políticas RLS antiguas de mutación que eran inertes por falta
  de privilegios de tabla, pero constituían un riesgo futuro; la migración
  `20260822010000_remove_legacy_radiograph_mutation_policies.sql` las eliminó y agregó una
  aserción que impide cerrar el despliegue si queda cualquier política distinta de lectura.

## Cierre en producción — 22 de agosto de 2026

- Supabase remoto recibió `20260805223000_record_push_notification_click.sql`, que ya estaba en
  `main` pero seguía pendiente, y las cuatro migraciones del cierre clínico:
  `20260820020000_supabase_clinical_files_phase1.sql`,
  `20260820030000_patient_activity_search_pagination.sql`,
  `20260821010000_service_role_backend_privileges.sql` y
  `20260822010000_remove_legacy_radiograph_mutation_policies.sql`.
- La migración experimental `20260820010000_individual_google_drive_folders.sql` no se aplicó y
  fue eliminada del repositorio. Google Drive no forma parte del producto operativo resultante.
- El commit principal `bd64a6b` y el endurecimiento `4248eb4` se publicaron directamente en
  `origin/main`. El SHA funcional publicado fue
  `4248eb46827ab3142bed1b53a4713df3c826a926`.
- Netlify publicó la versión nueva en `https://cita-suite.netlify.app`.
- La salida no agregó backup externo, recuperación, exportación ni purga controlada. Esas cuatro
  familias continúan reservadas íntegramente para fase 2.

## Estado de entrega

La fase 1 está implementada y publicada en producción. El código está en `main`, el esquema está
aplicado en el Supabase remoto y la aplicación está desplegada en Netlify. El worktree aislado
`Base-de-Datos-Sabrina-storage-phase1`, rama `codex/supabase-storage-phase1`, se conserva como
referencia de trabajo; el checkout original con cambios ajenos no fue modificado.

## Fase 2 reservada

La fase 2 queda reservada exclusivamente para las cuatro familias excluidas: backup externo,
recuperación, exportación y purga controlada. Su diseño deberá contemplar, dentro de esas familias:

- worker de backup externo idempotente;
- cifrado y custodia/rotación de claves;
- checksum verificado en copia;
- reconciliación y alertas;
- pruebas periódicas reales de restauración;
- exportación cifrada con manifiesto;
- política de conservación y solicitudes;
- purga física en Supabase y backup, con autorización fuerte y auditoría.

Hasta que todo eso exista y se pruebe, no debe agregarse ninguna forma de eliminación definitiva.

## Evolución posterior: visor clínico de detalle — 22 de agosto de 2026

Esta evolución está implementada y validada en el worktree aislado, pero no fue publicada como
parte de este pedido. No modifica el bucket, las rutas de Storage, la metadata, las políticas RLS
ni los contratos de autorización. El original continúa obteniéndose mediante una URL firmada de
corta duración y sólo después de que Cita Suite vuelve a autorizar al usuario y al paciente.

### Decisiones de experiencia clínica

- El modal genérico fue reemplazado únicamente para la observación de imágenes por un visor
  dedicado. Los diálogos de carga y Papelera siguen usando el componente común.
- En escritorio el visor ocupa más del 90 % del ancho y alto disponibles. Mantiene título, fecha,
  formato y peso en una cabecera compacta, y reserva el resto para la imagen sobre un fondo oscuro.
- Los controles de escritorio incluyen lupa para acercar y alejar, porcentaje visible, `Ajustar`,
  rueda del mouse con anclaje bajo el cursor y arrastre de la imagen ampliada. El rango está
  limitado entre 100 % y 800 %.
- El teclado admite `+`, `-`, `0`, flechas, `Shift` + flechas y `Escape`. El foco queda atrapado
  dentro del diálogo y vuelve al botón `Ver imagen` que lo abrió al cerrar.
- En mobile el visor ocupa exactamente el viewport. Dos punteros controlan el pellizco alrededor
  de su punto medio y un puntero recorre la imagen ampliada. El porcentaje y `Restablecer`
  permanecen siempre visibles; el lienzo usa `touch-action: none` para que el navegador no capture
  el gesto destinado al análisis clínico.
- El límite de arrastre se calcula con las dimensiones reales de la imagen ajustada, no con las
  bandas vacías del viewport. Una panorámica horizontal o una placa vertical no puede perderse
  fuera del área observable al ampliar.
- Cambios de orientación o tamaño recalculan el ajuste y acotan nuevamente la posición sin bajar
  el zoom elegido. Cerrar o cargar otra imagen siempre restablece la vista a 100 %.
- Si falla la descarga o la decodificación, el visor muestra una explicación humana y `Reintentar`;
  el reintento solicita otra URL firmada en vez de reutilizar una vencida.
- No se agregaron edición, recorte, rotación, filtros, anotaciones ni descarga. El alcance es
  deliberadamente observacional.

### Continuidad de lectura comercial

La auditoría E2E reveló que la autorización clínica ya permitía a Dueño y Administrador consultar
archivos durante el período restringido, pero el bloqueo visual global ocultaba esas superficies.
Se cerró la divergencia con una excepción estrecha y verificable:

- sólo Dueño y Administrador;
- sólo una cuenta `restricted` que aún puede entrar, nunca una cuenta archivada o deshabilitada;
- sólo lista de pacientes, una ficha cuyo identificador tenga forma UUID y Papelera;
- navegación visible únicamente hacia `Pacientes`;
- sin alta, edición, carga, envío a Papelera ni restauración.

La ficha del paciente dejó además de usar el caché compartido de 12 segundos para resolver sus
permisos. Su lectura comercial ahora es fresca, evitando que un botón de carga permanezca visible
brevemente después de que la cuenta pasa a modo restringido. Los endpoints y RLS ya bloqueaban la
operación; este cambio alinea inmediatamente la interfaz con esa seguridad.

### Validación de esta evolución

Se ejecutó todo en secuencia y con un solo worker cuando correspondía:

- `pnpm check`: 0 errores y 0 advertencias;
- Vitest de servidor: 77 archivos y 626 pruebas aprobadas;
- Vitest de cliente: 3 archivos y 36 pruebas aprobadas, incluidas geometría, límites, anclaje y
  punto medio móvil;
- Playwright de archivos clínicos: 2 de 2 casos aprobados, con visor mayor al 90 % en escritorio,
  viewport exacto de 390 × 844, pellizco real mediante eventos táctiles, zoom superior al 150 %,
  restablecimiento, ausencia de overflow, controles dentro del viewport, lectura compartida del
  profesional y continuidad restringida de Dueño;
- Playwright de bloqueo comercial: 2 de 2 casos aprobados en escritorio y mobile;
- `pnpm build` y `node scripts/netlify-build.mjs`: aprobados;
- `pnpm audit --audit-level high`: sin vulnerabilidades conocidas;
- inspección visual manual en 1280 × 720 y 390 × 844: cabecera, lienzo, lupa, cierre, ayuda táctil,
  porcentaje y restablecimiento quedaron legibles y dentro de pantalla.

No se agregó ninguna dependencia ni migración. Backup externo, recuperación, exportación y purga
controlada continúan íntegramente en fase 2.
