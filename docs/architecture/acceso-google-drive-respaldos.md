# Google Drive para respaldos externos de Cita Suite

## Estado vigente — respaldo diario configurado y recuperación comprobada, 26 de octubre

Cuenta elegida **juanmarquez56783@gmail.com**, carpeta privada [Copias automáticas cifradas](https://drive.google.com/drive/folders/122AAiXE1qX2FED6IFUkF33ZCswLQoVYK). Ejecutor independiente y privado [Juan4787/cita-suite-respaldos](https://github.com/Juan4787/cita-suite-respaldos), revisión **742e5ded813a57ec769a4d846d43c984fcde2a46**. Copia diaria **04:07UTC / 01:07Argentina** y monitor **10:43UTC / 07:43Argentina**. **Primera ejecución natural comprobada:** [40303961884](https://github.com/Juan4787/cita-suite-respaldos/actions/runs/40303961884), evento `schedule` sobre esta revisión, iniciada a10:00:17UTC y terminada a10:04:41UTC. Estaba prevista a04:07UTC: demora de5h53min17s, sin garantía de puntualidad. Instantánea10:04:16.270UTC,105tablas/3930filas/126migraciones/24objetos, todos reutilizados y0bytes de Storage. Descarga independiente desdeDrive y huella comprobadas; no se repitió restauraciónSQL. Las pruebas anteriores siguientes fueron manuales. No hace falta tener esta computadora encendida.

**Pruebas reales:** copia actual40264983219; restauración completa40265535110 con105 tablas/3930 filas/126 migraciones/24 referencias, sin diferencias; luego descarga y descifrado de ESA misma instantánea externa, manifiesto `4e8ab983b65133e12ff538421e0aab3cb5749267cb178b2242106769f86c8c3d`. Incremental40266203512 reutilizó24 objetos con0 descargas/0 bytes de Storage. Monitor40266261547 aprobó frescura y huella sin acceder a la base. Retención 30d/37d probada con fixtures propios enDrive, todos retirados; verify final40266759429 aprobado sobre742e5de. Evidencias `.verification/backup-private-capacity-20261026/`. Esto no equivale a una transacción global entre SQL y Storage ni recuperación a un segundo exacto. **Primer monitor natural comprobado40364212526**, fuente742e5de, creado16:58:23UTC: revisó la copia de10:04 con6,9h de antigüedad, descargó/comprobó el cifrado y no accedió a la base. Estaba previsto10:43UTC: demora6h15min23s. No acredita recepción de alertas por correo ni puntualidad.

Sólo clave pública de recuperación en CI; kit privado y contraseña externos confirmados por el usuario, sin inspeccionar ese soporte. Rol DB dedicado de lectura/BYPASSRLS, sin membresía postgres ni escrituras, límite de dos conexiones. La clave de Storage tiene privilegios **service_role más amplios que GET**: el código sólo lee, pero la credencial conserva ese alcance. Dos secretos protegidos en el ejecutor, separados de Auth/Calendar; no se leyó ni reutilizó ninguno de esos dos JSON. La copia histórica del 24-oct se conserva.

Sin nuevas contrataciones ni aumento del presupuesto: captura Actions US$0 bloqueado y facturado visible US$0; saldo exacto de minutos no acreditado. Límites preventivos y contabilidad aproximada en el README. El monitor falla ante copia ausente/vencida/corrupta o Drive inaccesible; **no se certificó recepción de correo** y si Actions completo no ejecuta por cuota/caída, tampoco ejecutará el monitor. El propietario debe conservar ese control periódico. No repetir consentimiento, custodia o presupuesto ya aportados ni regenerar claves. Dominio y SMTP siguen como dependencias externas de la campaña; no se declara terminada la campaña por cerrar respaldos.


## Operación del ejecutor privado — procedimiento vigente

La fuente del ejecutor y su procedimiento reproducible están en el [README privado](https://github.com/Juan4787/cita-suite-respaldos#readme). Incluye acceso dedicado, adaptación de las plantillas fijadas de Supabase, secretos por entrada estándar, comprobaciones, descifrado local, recuperación aislada y reversión. El estado fechado del inicio de esta guía prevalece sobre las preparaciones históricas inferiores.

- `verify.yml`: pruebas secuenciales de exportación, versiones, retención y monitoreo, más PostgreSQL real con el rol lector y los tres tipos de exportación. Cambiar el marcador esperado de la plantilla debe hacer fallar la verificación.
- `backup.yml`, entrada `mode=backup`: lectura del origen fijo, objetos incrementales, cifrado, carga/descarga verificada y limpieza posterior. `mode=rehearsal` fuerza descarga completa y ensaya SQL y Storage en el runner externo antes de publicar. Nunca ejecutar ese ensayo en la computadora del usuario.
- `monitor.yml`: comprueba una instantánea reciente y su cifrado sin acceder a la base. La entrega de correo de GitHub no está certificada. Una caída o falta de cuota de Actions impide también este monitor: revisar fecha en Drive y Actions sigue siendo un control del propietario.
- `recover.py`: recupera SQL y todos los objetos desde Drive, valida huellas y usa la clave privada sólo en un llavero temporal local. No escribe automáticamente en ninguna base. La salida parcial de un fallo no es una copia recuperable.

Las instantáneas se conservan30d y los objetos37d desde su última referencia. Se actualizan referencias antes de publicar, se limpian sólo marcas propias y se conserva la copia histórica del24-oct. No mover o eliminar objetos cifrados individuales: pueden estar compartidos por varias instantáneas.

El objetivo es una copia diaria, no un respaldo de cada escritura. Ante una pérdida, se recupera el estado de la última copia completa y validada; lo ingresado después puede quedar fuera. Un evento retrasado, omitido o fallido amplía ese intervalo. El control de frescura a30h detecta parte de ese riesgo, con la dependencia deActions y de las notificaciones ya documentada.

La retención no equivale a una transacción global entre cinco SQL y Storage ni a recuperación a un segundo exacto. El catálogo se contrasta antes y después; un cambio detectado rechaza la copia. El SQL de datos tiene su propia instantánea de pg_dump. Para cambios de estructura críticos, coordinar una ventana sin migraciones.

Límites preventivos:20MB por objeto,100MB por SQL,128MB por cifrado,2GB de datos propios en Drive y contabilidad mensual de1,4GB para respaldos. Esta última es aproximada, omite fallos y tráfico de la app y no sustituye las cuotas/tope del proveedor. No hay contratación ni saldo exacto de minutos acreditado.

Para detener futuras ejecuciones sin borrar copias:

```sh
gh variable set LIVE_BACKUP_ENABLED --body false --repo Juan4787/cita-suite-respaldos
gh workflow disable backup.yml --repo Juan4787/cita-suite-respaldos
gh workflow disable monitor.yml --repo Juan4787/cita-suite-respaldos
gh run list --repo Juan4787/cita-suite-respaldos --limit 10
```

Una puerta apagada no cancela una corrida activa: identificarla y cancelar sólo esa si corresponde. Para revocar el acceso de base, comprobar primero el proyecto y el rol y ejecutar `ALTER ROLE cita_suite_backup NOLOGIN;` por el canal administrativo autorizado. No borrar tablas, clientes, claves o carpetas; no modificar postgres, Auth o Calendar. Reactivar exige una revisión/verify aprobada y conservar el presupuesto bloqueado.


## Antecedente — acceso renovable y primera copia cifrada verificados el 25 de octubre

Cuenta **juanmarquez56783@gmail.com**, proyecto **Cita Suite Respaldos** (`project-ae0f9447-d7a0-49d1-b0b`), cliente de escritorio propio y alcance exclusivo `drive.file`. Capturas del usuario: marca guardada, OAuth externo **En producción** y permiso guardado. Autorización real recibida por retorno local con PKCE S256/state y renovación comprobada contra Google; identidad leída por Drive API, no deducida del login_hint. Token 600 ignorado por Git, sólo local; receptor terminado. No volver a pedir consentimiento ni recrear cliente mientras funcione la renovación.

Destino operativo: [Copias automáticas cifradas](https://drive.google.com/drive/folders/122AAiXE1qX2FED6IFUkF33ZCswLQoVYK), dentro de [Cita Suite — Respaldos](https://drive.google.com/drive/folders/1mdnNa0fde28beeoOIurojp5pTZfbfQkK). Creado con el cliente propio porque el contenedor del conector devuelve 404 con ese alcance; movido con el conector tras leer padres. Acceso propio conservado después del movimiento, privado y único propietario comprobados por ambas vías. Prueba inocua de crear/leer/modificar/borrar y404 final correcta. Cuota leída por API: límite 5.497.558.138.880 bytes y uso 7.060.446 bytes **antes** de esta carga; no acredita precio o facturación futuros.

**Primera copia externa preservada, histórica:** [archivo cifrado del 24 de octubre](https://drive.google.com/file/d/1YgGdOtBYk0qWEJjuF99jsi6Ax8t-siNI/view?usp=drivesdk),9.796.494 bytes, instantánea `2026-10-24T12:58:38.208Z`,126 migraciones,24 referencias de objetos / 22 contenidos únicos, cinco SQL y manifiesto:28 archivos únicos comprobados. No es una copia actual del 25. Manifiesto SHA256 `e042313d02e9c02599f55962a96e7d5a582436f0f55a2ea7fab0c7ef50ebabdf`; cifrado SHA256 `adfbb62bd14c72f3e3816022c01b92ab230f89c513a853c6a6e74615c55a2267`. Empaquetado sólo de archivos autorizados por manifiesto, sin seguir symlinks ni incluir credenciales. Cifrado OpenPGP con clave de recuperación propia, subclave cv25519 y AES256, mediante un llavero que sólo tenía la clave pública. Carga reanudable de Drive, descarga y huella idénticas; importación de clave exportada en un llavero nuevo, descifrado y28 archivos comparados byte por byte/hash con el origen. Prueba sintética previa rechaza un cifrado manipulado y no se descifra con la clave pública; ambas pruebas temporales remotas fueron eliminadas y devuelven 404. Esto prueba transporte, descifrado y contenido de archivos: **no restaura ni valida ahora una base PostgreSQL**, ni certifica atomicidad global del exportador.

**Fallo abierto de copia actual:** `backup-production.mjs` salió 1 en roles, archivo vacío; diagnóstico acotado con el mismoCLI repitió cierre inesperado al conectar al pooler en 5432. Una consulta sólo lectura desde el host tampoco conectó dentro del límite. Causa no establecida: no afirmar caída de Supabase, credencial inválida o falla de Docker como diagnóstico. Sin cambios de base, configuración, aplicación o datos; no subió una copia parcial. No repetir indiscriminadamente las exportaciones. Revalidar conectividad e identidad del destino antes de intentar una copia nueva; no cambiar a otro proyecto/puerto ni modificar secretos como atajo. CLI2.115.0; no se actualizó. No se tocaron los contenedores del otro proyecto que ya estaban ejecutándose.

**Pendientes, sin aprobación implícita:** custodia externa confirmada después por el usuario; resolver conexión y generar copia actual, restauración aislada de SQL y objetos, ejecutor independiente privado, credenciales de mínimo acceso, objetos incrementales, retención, límites gratuitos/facturación y alertas de fallo/ausencia. No hay tareas diarias, repositorio ejecutor ni secretos productivos copiados a CI. Ninguna contratación. Auth y Calendar no modificados; dominio y SMTP siguen pospuestos.

## Identificación y enlaces para encontrarlo

| Dato | Valor y procedencia |
|---|---|
| Finalidad exclusiva | Custodia de respaldos cifrados y su futura automatización. |
| Cuenta de Drive elegida | `juanmarquez56783@gmail.com`, perfil del conector comprobado antes de crear la carpeta. |
| Correo de contacto del proyecto | El usuario indicó su correo principal; su dirección exacta no se ve en la captura recibida. Este campo no cambia el destino de las copias. |
| Proyecto | **Cita Suite Respaldos**. |
| ID estable | `project-ae0f9447-d7a0-49d1-b0b`, comprobado también dentro del JSON descargado. |
| Número de proyecto | `320579536277`, mostrado en las capturas y prefijo del ID del cliente. |
| Organización visible | `juanmarquez56783-org`, según captura; no es una auditoría de IAM. |
| Cliente | **Cita Suite Respaldos - Automatico**, según captura de creación. |
| Tipo | **Aplicación de escritorio**; raíz `installed` en el JSON. |
| ID del cliente | `320579536277-3rvibd44oktsjauql3ff8ldm3ssf898p.apps.googleusercontent.com`. |
| Agente de IA | Casilla desmarcada en la captura del cliente. |
| Retorno del JSON | `http://localhost`, propio de la autorización inicial de escritorio. |
| Creación mostrada por Google | 25-oct-2026, 20:56:33 GMT-3, según captura; no se obtiene del JSON. |

- [Clientes OAuth de este proyecto](https://console.cloud.google.com/auth/clients?project=project-ae0f9447-d7a0-49d1-b0b).
- [Configuración del proyecto](https://console.cloud.google.com/iam-admin/settings?project=project-ae0f9447-d7a0-49d1-b0b).
- [Google Drive API para este proyecto](https://console.cloud.google.com/apis/library/drive.googleapis.com?project=project-ae0f9447-d7a0-49d1-b0b).
- [Carpeta remota privada «Cita Suite — Respaldos»](https://drive.google.com/drive/folders/1mdnNa0fde28beeoOIurojp5pTZfbfQkK).

El proyecto tenía el nombre visible «My First Project» en una captura anterior con el mismo ID. Se conserva su identidad estable: no se certifica que sea un proyecto nuevo o vacío. No eliminar servicios previos para uniformar su nombre.

## Enlaces públicos para completar la marca de respaldos

El usuario confirmó que Información de contacto del desarrollador ya está completada; no volver a pedir su captura. Se publicaron páginas informativas en GitHub Pages para completar los campos vacíos de este proyecto. No son la web de pacientes ni contienen copias o credenciales.

| Campo en Información de la marca de Cita Suite Respaldos | Valor preparado |
|---|---|
| Dominio autorizado | `juan4787.github.io` |
| Página principal | https://juan4787.github.io/cita-suite-respaldos-info/ |
| Política de privacidad | https://juan4787.github.io/cita-suite-respaldos-info/privacidad/ |
| Condiciones del servicio | https://juan4787.github.io/cita-suite-respaldos-info/terminos/ |

Repositorio público exclusivo: https://github.com/Juan4787/cita-suite-respaldos-info, revisión `e0aa4aaaf9ac76b1479ef28a1e2ca380a899a0c2`. Fuente local: `docs/public/google-drive-backups/`. Sólo seis archivos estáticos: tres HTML, CSS, README y `.nojekyll`; sin formularios ni JavaScript. El repositorio de páginas no contiene ni ejecuta los respaldos. GitHub Pages es una opción disponible en repositorios públicos con GitHub Free; no se contrataron servicios ni se activó facturación. [Disponibilidad oficial](https://docs.github.com/en/pages/getting-started-with-github-pages/what-is-github-pages).

Verificación HTTP anónima del checkpoint: inicio, privacidad, términos y CSS devuelven200 porHTTPS, sin redirección y con bytes/huella idénticos al artefacto. API de Pages: construido sobre el mismoSHA, HTTPS obligatorio y sin dominio personalizado. Preflight estático15/15; no es certificación visual de navegador. La herramientaweb no pudo abrir los enlaces recién creados; esto no se presenta como caída ni se usa como prueba de aprobación. Se conserva la evidencia independiente de HTTP y API.

**Marca ya completada por el usuario:** capturas posteriores muestran los enlaces guardados y OAuth En producción; Acceso a los datos contiene sólo drive.file. No repetir el formulario. Esto no acredita aprobación pública de marca o propiedadDNS; el dominio de la aplicación principal continúa pospuesto. Los valores de la tabla permanecen como inventario vigente. [Requisitos de marca de Google](https://support.google.com/cloud/answer/15549049?hl=en).

Evidencia `.verification/backup-drive-branding-pages-20261025/`: `static-preflight.json`, `publication-manifest.json`, `pages-created.json`, `http-first-check.json` y `verification.json`. El HEAD/índice del repositorio principal se conservan; la revisión publicada pertenece sólo al repositorio informativo.

### Reversión de estas páginas

Antes de retirar páginas ya configuradas en Google, preparar URLs sustitutas o detener la dependencia correspondiente. Comprobar identidad antes de ejecutar:

```sh
gh api repos/Juan4787/cita-suite-respaldos-info/pages --jq '{html_url, source, https_enforced}'
```

Para deshabilitar exclusivamente este sitio, conservando repositorio y contenido:

```sh
gh api --method DELETE repos/Juan4787/cita-suite-respaldos-info/pages
```

No borrar el repositorio ni modificar OAuth/Auth/Calendar como reversión del sitio. Si sólo cambia un texto, actualizar únicamente los archivos públicos revisados, publicar un nuevo commit en ese repositorio y repetir los controles HTTP/huella.

## Carpeta local y separación de finalidades

La carpeta general es `ACCESOS-GOOGLE-CITA-SUITE/`. Su `LEEME.md` identifica los dos proyectos y remite a cada finalidad. El inventario sin secretos se encuentra en [accesos Google](accesos-google.md).

| Finalidad | Cuenta y proyecto | Subcarpeta privada |
|---|---|---|
| Autenticación | Administradora indicada `juampiluduena@gmail.com`; `dashboard-odontologia`. | `AUTENTICACION-GOOGLE/` |
| Google Calendar | Administradora indicada `juampiluduena@gmail.com`; `dashboard-odontologia`. | `GOOGLE-CALENDAR/` |
| Respaldos externos en Drive | Destino elegido `juanmarquez56783@gmail.com`; `project-ae0f9447-d7a0-49d1-b0b`. | `RESPALDOS-GOOGLE-DRIVE/` |

La integración de Drive retirada de la aplicación continúa retirada. Este cliente es independiente y no sirve para iniciar sesión en Cita Suite ni para los eventos de Calendar. Los JSON de esas dos integraciones no se leyeron, cambiaron ni reutilizaron para preparar este acceso.

Dentro de `RESPALDOS-GOOGLE-DRIVE/`:

- `CREDENCIALES-RESPALDOS-GOOGLE-DRIVE-CITA-SUITE.json`: el archivo secreto descargado; exclusivamente para el cliente de respaldos.
- `LEEME.md`: cuenta, propósito, proyecto, enlaces, archivo y estado comprobado.
- `metadatos.json`: inventario del cliente y procedencia de las verificaciones, sin el secreto.

El JSON llegó como `Cita Suite Respaldo.json` en la raíz, sin seguimiento ni incorporación al índice de Git en el checkpoint. Se restringieron sus permisos y se trasladaron sus **mismos 419 bytes**, sin reserializarlo. Se comprobó la misma huella SHA-256 antes y después; el archivo de la raíz ya no existe. Su nombre anterior también quedó excluido en `.gitignore` para evitar una incorporación accidental si vuelve a descargarse allí.

Directorios privados: `700`. JSON, LEEME y metadatos privados: `600`. Toda la carpeta general está excluida de Git. No copiar el secreto a documentación, chats, evidencias, comandos visibles o memoria.

### Comprobaciones locales reproducibles

Desde la raíz del repositorio, sin imprimir el contenido del JSON:

```sh
git check-ignore -- ACCESOS-GOOGLE-CITA-SUITE/RESPALDOS-GOOGLE-DRIVE/CREDENCIALES-RESPALDOS-GOOGLE-DRIVE-CITA-SUITE.json
stat -c '%a %n' ACCESOS-GOOGLE-CITA-SUITE/RESPALDOS-GOOGLE-DRIVE ACCESOS-GOOGLE-CITA-SUITE/RESPALDOS-GOOGLE-DRIVE/CREDENCIALES-RESPALDOS-GOOGLE-DRIVE-CITA-SUITE.json
```

Se esperan la ruta ignorada, `700` para la carpeta y `600` para el JSON. La validación privada comprobó raíz `installed` sin `web`, proyecto e ID correctos, endpoints de autorización/token de Google, retorno local y secreto presente sin mostrarlo. El checkpoint de archivo sólo acreditaba configuración local. La autorización y renovación reales se comprobaron después, en los recibos vigentes de autorización y destino.

## Evidencia y límites del estado actual

| Comprobación | Evidencia | Límite |
|---|---|---|
| Identidad del Drive y carpeta privada | Perfil y lectura de permisos por conector; `backup-drive-destination-20261025`. | No autoriza por sí sola al cliente de escritorio. |
| Proyecto y Drive API habilitada | Capturas del usuario; `backup-drive-project-20261025` y `backup-drive-api-enabled-20261025`. | Sin consulta administrativa independiente de IAM o facturación. |
| OAuth publicado y permiso guardado | Capturas posteriores del usuario, preflight de autorización. | En producción y drive.file; no es aprobación pública de marca ni auditoría de facturación. |
| Cliente de escritorio autorizado | Autorización local PKCE y renovación real; `backup-drive-authorization-20261025/result.json` y `backup-drive-destination-proof-20261025/renewal.json`. | Comprobación puntual; una autorización puede revocarse y debe vigilarse. |
| JSON recibido y archivado | Huella/bytes conservados,600 e ignoradoGit; autorización posterior real con ese cliente. | El JSON contiene el secreto del cliente; el token renovable se guarda por separado. |

Los recibos están bajo `.verification/<identificador>/`, ignorados por Git. El checkpoint de archivo contiene `before.json`, preimágenes documentales, `credential-metadata.json`, `archival.json` y `verification.json`; **no contiene una copia del JSON secreto**. SHA de trabajo: `80268e2a501198243996e1bdb0048ce066434727`. Los documentos locales pueden tener cambios sin commit; ese SHA no afirma que ya estén publicados.

## Clave de recuperación y operación reproducible

Huella pública: `99938EAA9E89ECD58BEE950E7686669ABE7C160A`. El llavero operativo local de recuperación está fuera del repositorio, `~/.local/share/cita-suite/backup-keys/gnupg`, privado. No se usa el llavero GPG personal. Su agente se detuvo al terminar. No regenerar ni sustituir esta clave: las copias ya cifradas dependen de ella.

Archivos locales privados dentro de `ACCESOS-GOOGLE-CITA-SUITE/RESPALDOS-GOOGLE-DRIVE/`:

- `AUTORIZACION-RESPALDOS-GOOGLE-DRIVE.json`: token renovable y cuenta comprobada; no copiar a evidencias.
- `DESTINO-RESPALDOS-GOOGLE-DRIVE.json`: IDs y alcance, sin tokens.
- `RECUPERACION-DE-RESPALDOS/CLAVE-PUBLICA-RESPALDOS.asc`: única clave que necesitará el futuro ejecutor.
- `RECUPERACION-DE-RESPALDOS/CLAVE-PRIVADA-RECUPERACION.asc`: clave privada protegida por contraseña, exclusivamente para recuperación.
- `CONTRASENA-CLAVE-RECUPERACION.txt`: contraseña aleatoria; custodiar fuera de la computadora, preferentemente separada de la clave privada. No enviar al chat ni guardar junto a las copias de Drive.
- `RECUPERACION-DE-RESPALDOS/LEEME-RECUPERACION.md`: importación ydescifrado en otro equipo. Archivos600, directorios 700, todo fuera deGit.

El archivo `RECUPERACION-DE-RESPALDOS/KIT-RECUPERACION-CITA-SUITE.zip` reúne clave pública, clave privada protegida, huella e instrucciones. Se comprobó su contenido exacto; **no contiene la contraseña**, token OAuth ni credenciales de producción. La contraseña permanece en el archivo separado.

**Custodia posteriormente confirmada por el usuario:** respondió listo tras guardar el kit y la contraseña fuera de la computadora; no se inspeccionó el soporte externo. No repetir esta solicitud. No subir la clave privada o contraseña alDrive de respaldos ni a CI. Puede seguirse preparando el ejecutor mientras se espera, pero no declarar operación completa.

Comprobaciones seguras desde la raíz, sin imprimir secretos:

```sh
cat .verification/backup-drive-authorization-20261025/result.json
cat .verification/backup-drive-destination-proof-20261025/lifecycle.json
cat .verification/backup-drive-encryption-20261025/encryption-proof.json
cat .verification/backup-drive-encryption-20261025/production-snapshot-recovery.json
```

El procedimiento efectivamente ejecutado de empaquetado/cifrado/carga/recuperación está en `.verification/backup-drive-encryption-20261025/archive_existing_backup.py`: contiene sólo lógica y rutas, no credenciales. Se niega a sobrescribir el archivo cifrado o duplicar un marcador remoto. No volver a ejecutarlo contra esa instantánea. Si la carga fuera ambigua, consultar el marcador `citaSuiteSnapshot=production-snapshot-20261024T125838Z-v1` antes de repetir; la URI de sesión de carga no se registra. El recibo local `production-upload-created.json` identifica el archivo confirmado. Los metadatos y sufijo GPG no se toman como prueba de cifrado: lo prueba el descifrado verificado.

Las copias locales permanecen bajo `~/.local/share/cita-suite/backups/` y la envoltura cifrada en `~/.local/share/cita-suite/encrypted-backups/`, ambas privadas. El empaquetado y descifrado de prueba sólo usaron directorios temporales 700; los llaveros temporales y los duplicados en claro se retiraron al terminar. No se promete borrado físico deSSD.

Evidencias de esta continuación: `backup-drive-authorization-20261025`, `backup-drive-destination-proof-20261025` y `backup-drive-encryption-20261025`. El último contiene diagnóstico de exportación, prueba del host, recibos, scripts y preimágenes documentales sin secretos. El ensayo anterior de PostgreSQL en CI39859035283 sigue siendo evidencia histórica independiente; no se extrapola como restauración del archivo recién subido.

Referencias: [alcances de Drive](https://developers.google.com/workspace/drive/api/guides/api-specific-auth), [carga reanudable](https://developers.google.com/workspace/drive/api/guides/manage-uploads) y [gestión de clavesGnuPG](https://gnupg.org/documentation/manuals/gnupg/OpenPGP-Key-Management.html).

## Conservación y reversión

Una corrección documental se limita a los fragmentos de este checkpoint y conserva los cambios posteriores, contrastando las preimágenes. No devolver el JSON a una ubicación expuesta ni restaurar sus permisos anteriores. Si se cambia la ruta privada, verificar primero destino ignorado y directorio `700`, mover sin sobrescribir otra credencial, conservar la huella y fijar archivo `600`; actualizar ambos índices y esta guía. La validación y la documentación no exigen rotar, borrar ni inhabilitar clientes. No alterar Auth o Calendar para revertir este registro.
