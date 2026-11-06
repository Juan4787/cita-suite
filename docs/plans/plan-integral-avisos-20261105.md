# Plan integral de avisos, correo y calendarios

**Documento canónico del encargo del 5 de noviembre de 2026.** Fuente del pedido: [mandato literal](mandato-integral-avisos-20261105.md). Requisitos heredados: [especificación E](etapa-e-correo-autogestion.md) y [plan aprobado](propuesta-senas-avisos-natalia.md#12-aprobación-y-ajustes-posteriores). Cronología y evidencia: [registro activo](ejecucion-etapa-e-20261103.md). Este plan no repite esos requisitos: dice cómo se cumplen, qué falta y cómo se acredita.

**Después de una compactación:** releer el mandato, este plan completo, la especificación E, `AGENTS.md`, `docs/ESTADO-VIGENTE.md` y el checkpoint de abajo. Un resumen de conversación no reemplaza esas fuentes.

## 0. Checkpoint vigente

Se actualiza después de cada bloque con resultado. Es el único lugar con el «siguiente paso».

| Campo | Valor |
|---|---|
| Fecha | 6 de noviembre de 2026 (Argentina) |
| Revisión de partida | `main` `d3f7553c`, igual a GitHub; producción V12b `771fac59`, versión `277d332d`, comprobada con `/_app/version.json` y `wrangler deployments list` |
| Fase | **E publicada en producción el 6 de noviembre, 07:41 UTC.** Instantánea `dfec4774` de `main` `101c74dc`; detalle en `docs/ESTADO-VIGENTE.md`. El encargo sigue abierto: faltan las comprobaciones reales de abajo |
| Corridas de la revisión publicada | SQL 42147347019, paquete 42179941722, navegador 42179970561 (76/76), fast 42181404563 |
| Datos sintéticos abiertos en producción | Práctica de dispositivo `78f3c48dedc7`: limpiar con `node scripts/production-device-push.mjs cleanup 78f3c48dedc7` |
| Ajustes de teléfonos a restaurar | Xiaomi: `stay_on_while_plugged_in` estaba en 0 y hoy vale 7; permiso de notificaciones de Chrome estaba denegado por el usuario, y quedó igual después de las pruebas; origen `app.cita-suite.com.ar` quedó concedido. Samsung: origen de la sonda concedido. El evento sintético guardado por error en Hotmail ya se borró (el proveedor de calendario no lo devuelve) |
| Siguiente acción | Consultorio sintético con remitente y recepción real por propósito; webhook de Zoho (la clave la pega Juan); físicas de push y calendarios en los dos teléfonos; TestKase; medición de CPU y llamadas; turno del video de Google |

## 1. Resultado que hay que entregar

Un solo resultado: desde que se crea un turno hasta que deja de requerir acciones, paciente y personal reciben información correcta por los medios disponibles, y el estado comunicado coincide con el estado vigente del turno. La sección 16 del mandato fija las condiciones de cierre; la sección 8 de este plan las traduce a evidencia concreta.

Quedan fuera sólo: P1, P2, P3, la auditoría global de Cita Suite y las acciones de terceros (grabar y presentar el video, decisión de Google, KYC y compras de Zoho).

## 2. Cómo se relacionan los medios con el ciclo del turno

Cada medio tiene su propia infraestructura, pero todos leen el mismo estado vigente. Ninguno guarda una copia que autorice nada por sí sola.

| Evento del turno | Correo | Push | Google gestionado | ICS / enlace manual | Página del turno |
|---|---|---|---|---|---|
| Reserva | Comprobante; pedido de seña si corresponde | Se ofrece activar y probar | Se ofrece conectar | Se ofrece guardar | Estado actual, acciones permitidas |
| 72 h antes | Recordatorio | — | — | — | — |
| 24 h antes | Recordatorio | Recordatorio | Alarma del evento | Alarma del evento, si el calendario la respeta | — |
| 2 h antes | — | Recordatorio | Alarma del evento | Alarma del evento, si el calendario la respeta | — |
| Reprogramación | Comprobante de cambio; recordatorios recalculados | Aviso de cambio; recordatorios recalculados | Actualiza el mismo evento | **No se actualiza solo:** se pide volver a guardarlo | Nueva fecha, aviso de actualización |
| Cancelación | Comprobante sin Cancelar ni Reprogramar | Se detienen los avisos | Retira el evento | **No se retira solo:** se explica cómo quitarlo | Cancelado; reservar otro si hay reserva pública |
| Corrección de contacto | Revalida destinatario; nuevo enlace | Sin efecto | Sin efecto | Sin efecto | Enlace anterior revocado |
| Pago registrado | Se descarta el pedido de seña pendiente | Sin efecto | Sin efecto | Sin efecto | Refleja la seña |

Tres conceptos que no se mezclan en código ni en textos: **preferencia** (lo que eligió el consultorio o el paciente), **capacidad técnica** (lo que el dispositivo puede hacer) y **entrega efectiva** (lo que se observó). Aceptado por API, entregado al servidor receptor, en bandeja y leído son cuatro hechos distintos.

## 3. Estado real por frente, al empezar

| Frente | Existe y funciona | Incompleto | Falta investigar |
|---|---|---|---|
| Autogestión e identidad | 30 migraciones E, comandos, recibos, revocación, contacto. SQL30 y fast aprobados | SN14 navegador; casos RP04–07, RP10–11, RP13, SN08–10, SN12, SN15, AC04, AC08, EM05, EM08–10 sin prueba | Causa del fallo 42080552190 |
| Correo | Preferencias, pantalla de configuración, contexto de acciones, eventos en `private.appointment_email_events`, `private.patient_email_contact_events`, destinatario `private.appointment_email_contact`. Conexión Zoho, clave de agente guardada, dominio `avisos.cita-suite.com.ar` verificado | Todo el resto: cola, consumidor, plantillas, bajas, webhook, conciliación, emisores por consultorio, avisos de operación | Comportamiento real de Zoho: códigos, conciliación, cabeceras, cupo |
| Push | Suscripción, prueba, recibos, recordatorios 24/2 h | Recorrido de permisos del defecto original | Comportamiento real de Chrome 156 en los dos teléfonos |
| Calendarios | Enlace manual, ICS, servidor de Google gestionado con leases y observaciones | Sin entrada visible a Google gestionado; alternativas ligadas a la marca del teléfono | Samsung Calendar, Xiaomi, Apple Calendar reales |
| Tareas | Cinco cron, presupuesto por cadena | Sin categoría de correo | Medición de CPU y llamadas con correo |
| Limpieza | — | Retención de capacidades, cuarentena física de documentos | — |
| Publicación | Procedimiento general | Recuperación compatible con E, orden de migraciones, ensayo | Compatibilidad V12b frente a las restricciones nuevas |

## 4. Dependencias, riesgos y hechos externos comprobados

Hechos comprobados el 5 de noviembre, que condicionan el diseño:

- **Chrome 155 cambió el aviso de permiso en Android** a una interfaz no bloqueante que puede vencer: `requestPermission()` resuelve `default` sin decisión, y el permiso puede concederse después desde los controles del sitio ([fuente](https://developer.chrome.com/blog/notification-prompts-android)). Los dos teléfonos tienen Chrome 156. El diagnóstico histórico es anterior a esto. La duración del vencimiento y su relación con el bloqueo por descartes no están publicadas: se miden.
- **El Xiaomi tiene Chrome bloqueado a nivel Android** (`POST_NOTIFICATION: ignore`), que es el estado del defecto original. El Samsung no.
- **Zoho:** envío `POST https://cpaas.zoho.com/v1.1/email`, autenticación `Zoho-enczapikey`. Registros y administración usan OAuth, no la clave de envío. Los webhooks **sólo se configuran desde el panel**. La API no expone saldo ni cupo. `client_reference` llega en los webhooks y en el detalle del registro.
- **Token de `wrangler`:** sin permiso de DNS. Los registros de cada consultorio se cargan desde el panel de Cloudflare en el Chrome conectado, con la sesión de Juan, o los carga Juan.
- **Extensión de Chrome:** conectada desde el 5 de noviembre a la noche. Google Cloud tiene sesión y se puede leer: marca verificada, acceso a datos sin verificar. Cloudflare quedó con sesión de Juan esa misma noche. Zoho no tiene sesión en ese Chrome, y la extensión además negó capturar `accounts.zoho.com`/`cpaas.zoho.com`. El agente no ingresa contraseñas: iniciar sesión y permitir el dominio lo hace Juan.
- **SvelteKit:** `csrf.checkOrigin` está marcado como obsoleto en favor de `trustedOrigins`, que no admite excepciones por ruta. Se mantiene apagado porque el filtro propio replica la regla con dos excepciones exactas; al actualizar SvelteKit más allá de su retiro hay que revisarlo.
- **Google:** el video debe mostrar el flujo en inglés, el nombre de la app, el `client_id` en la barra de direcciones y el uso de cada permiso. No se modifica la marca durante la revisión.
- **TestKase:** hay iPhones reales disponibles. Falta comprobar si permite llegar a Apple Calendar antes de gastar minutos.

Riesgos principales:

| Riesgo | Tratamiento |
|---|---|
| Aceptación externa sin transacción común con la base | Estado «En comprobación», sin reenvío a ciegas; nunca prometer entrega exacta |
| Un duplicado legítimo suprimido por una protección contra duplicados | La identidad del envío incluye la revisión del horario y la del contacto |
| Cola de correo que demore push o calendario | Cadena propia para correo, ver D3 |
| V12b incompatible con el esquema nuevo | Recuperación compatible diseñada antes de publicar, sección 7 |
| Datos reales de Natalia | Sin cambios de configuración. Su emisor queda pendiente hasta una decisión de Juan |
| Teléfonos personales | Sólo Chrome, calendarios y ajustes necesarios, con valores previos registrados y restaurados |

## 4.1 Comportamiento real de Chrome Android (medido el 5 de noviembre)

Xiaomi 2312DRA50G, Android 16, Chrome 156, por depuración inalámbrica. Sonda propia en `localhost` y turno sintético real sobre V12b. Capturas privadas en `.verification/avisos-20261105/`.

| Hecho medido | Consecuencia |
|---|---|
| Con Chrome apagado en Android, un origen nuevo informa `default`/`prompt`, no `denied` | La página no puede saber que Android está apagado |
| El pedido muestra una tarjeta superior con «Permitir». Sin tocarla, vence a los 10,6 s y resuelve `default` | Hay unos 10 s para decidir. `default` no significa «la persona no quiso» |
| Con Android apagado, tocar «Permitir» resuelve `default` en unos 2 s, sin ningún mensaje de Chrome | **Causa raíz de «tocar Permitir no hace nada»** |
| 3.ª vez con «Permitir»: resuelve `default` pero `Notification.permission` ya es `denied`, con evento `onchange`. Dejando vencer la tarjeta fueron 4 | **Causa del salto «al tercer intento».** No es un número universal |
| Después, Chrome informa «Bloqueado de forma automática» y `requestPermission()` rechaza en 5–9 ms sin mostrar nada | Repetir el mismo botón empeora la situación |
| Activar Android **no** levanta ese bloqueo: la página sigue `denied` | **Por eso «Ya lo permití» no podía funcionar.** Hacen falta dos ajustes, no uno u otro |
| Tras varios pedidos sin aceptar, Chrome pasa a interfaz discreta: no muestra tarjeta, resuelve `default` en 1–2 s y deja una campana tachada unos segundos | Otro `default` sin decisión. También ocurre con Android bien configurado |
| En Chrome 156 **no hay ícono a la izquierda de la dirección** en un sitio HTTPS | La guía vigente pide un paso imposible |
| Ruta real: ⋮ → «Controles de sitios» → «Permisos» | Sirve para los dos estados: ofrece «Suscribirse» si está sin permiso, y «Restablecer permisos» si está bloqueado |
| «Permisos» sólo aparece si la página pidió el permiso **en esa visita** | La recuperación debe pedir antes de mandar a esa pantalla |
| «Suscribirse» concede el permiso y dispara `onchange` a `granted`; V12b continúa sola hasta la prueba y la notificación aparece en Android | La recuperación automática al volver funciona; lo que falla es llegar hasta ahí |
| «Restablecer permisos» devuelve `default` y dispara `onchange` | La página puede reaccionar sin recargar |
| En este Xiaomi el interruptor se llama «Mostrar notificaciones» con Android 16; la guía diría «Permitir notificaciones» | La regla de etiquetas era de Samsung y se aplicaba a todos. Hay que usar una descripción genérica |
| El valor predeterminado de Chrome 156 en «Cómo mostrar solicitudes» es «Contraer solicitudes no deseadas (recomendado)». En el Samsung, con Android permitido, el turno real no mostró ninguna pregunta y quedó el mismo botón | **El peor caso no necesita ningún ajuste mal puesto.** El diseño no puede depender de que la tarjeta aparezca |
| La campana tachada dura unos segundos; tocada a tiempo abre la misma pantalla de Controles de sitios | Confirma que esa ruta es común a ambos teléfonos. No se usa en las instrucciones porque desaparece |
| Con Android apagado y el sitio concedido: `Notification.permission` y `permissions.query` dicen `granted`, `showNotification()` resuelve y `getNotifications()` lista el aviso, pero Android no tiene ninguna notificación | **La web no puede detectar el bloqueo de Android.** Sólo la respuesta de la persona lo distingue |
| Producción registró `displayed_at` del recordatorio de 24 h a las 23:55:19 UTC con Android apagado | `displayed` sólo significa que el service worker terminó. **No es evidencia de visualización** y ninguna decisión puede apoyarse en él |

## 4.2 Comportamiento real de los calendarios (medido el 5 de noviembre)

Samsung SM-A715F, Android 13, Chrome 156, con Calendario Samsung, Proton Calendar y Outlook, sin la app Google Calendar. Xiaomi 2312DRA50G, Android 16, Chrome 156, con Google Calendar. Capturas en `.verification/avisos-20261105/`.

| Mecanismo | Samsung | Xiaomi | Consecuencia |
|---|---|---|---|
| Enlace `intent://`, variantes `data` y `type` | Cae siempre al enlace alternativo | Sin probar: mismo Chrome | No abre el calendario nativo. No se usa |
| `.ics`: apertura | Chrome descarga y ofrece «Abrir»; Android muestra sus apps reales (Proton, Outlook, Calendario) | Igual (Calendario de Google, otras apps que aceptan el archivo) | **Muestra lo que el teléfono tiene de verdad. No hace falta inferir nada por la marca** |
| `.ics`: alarmas | Calendario Samsung respeta las dos (`VALARM`) | Google Calendar las **ignora** y usa «30 minutos antes» | La página no puede prometer «24 y 2 horas antes» para el archivo |
| `.ics`: alarma real | Saltó a las 21:03:00 exactas con la pantalla apagada, como pantalla completa «Próximo evento» | Sin probar | Alternativa fuerte al push, sin cuenta ni sincronización |
| `.ics`: destino | Propone el calendario predeterminado de la persona | Propone su cuenta | Decide la persona |
| `.ics`: reprogramar con igual UID y `SEQUENCE` mayor | Abre el evento viejo, con la hora vieja, sin ofrecer guardar | Sin probar | **No actualiza ni duplica.** Hay que pedir borrar y guardar el nuevo |
| `.ics`: `METHOD:CANCEL` | Abre el evento viejo; no lo quita | Sin probar | Hay que pedir borrarlo a mano |

El enlace manual y Google gestionado se comprueban en los teléfonos con la versión nueva.

## 4.3 Comportamiento real de Zoho (medido el 5 de noviembre)

Un envío real a citasuite@gmail.com desde `avisos.cita-suite.com.ar`, más pedidos que debían fallar. Referencia `sonda-fd90dee6083e`.

| Hecho medido | Consecuencia |
|---|---|
| Éxito: HTTP **201** (la documentación dice 200), `data[0].code=EM_104`, `request_id` | El cliente acepta cualquier 2xx con ese código, y exige `request_id` |
| Errores: HTTP **401** `TM_4001` con subcódigo: `SM_111` remitente no verificado, `SERR_157` clave inválida, `SM_113` destinatario inválido | La clasificación usa el subcódigo, no el estado HTTP |
| Mensaje en la bandeja en segundos, con DKIM, SPF y DMARC aprobados | Dominio y cabeceras correctos |
| `Reply-To`, `List-Unsubscribe` y `List-Unsubscribe-Post` llegan intactos | Baja de un toque viable |
| El detalle por `request_id` (OAuth) responde enseguida con la entrega al servidor receptor | Sirve para conciliar **si se tiene** el `request_id` |
| La lista no mostró el envío recién hecho y filtrar por `client_reference` devolvió 0; una hora después ese filtro lo encuentra | El filtro funciona con demora de sincronización. Una respuesta perdida se puede conciliar por referencia, usando OAuth. La aplicación se apoya en el webhook; el filtro queda como herramienta de operador, para no poner credenciales de administración en el Worker |
| Crédito real, leído del panel: 1 crédito = 10.000 correos, 9.997 restantes, **vence el 3 de diciembre de 2026**, recarga automática desactivada | Hay margen sobrado para las pruebas. Juan debe comprar antes de esa fecha o los envíos se detienen: ZH04 |
| `POST /domains` exige `sub_domain_prefix`, aunque la documentación diga optativo, y con él responde `SERR_123`; `PUT .../verify` da 401. Lectura y envío funcionan | Crear y verificar dominios sólo se pudo desde el panel. La herramienta los lee y muestra los registros; el alta sigue siendo un paso de panel |
| Provisión real de `prueba-correo.cita-suite.com.ar`: alta en el panel, TXT DKIM y CNAME `bounce-zem` cargados a mano en Cloudflare, verificación del panel aprobada | Cada subdominio necesita esos dos registros. Ninguno toca app, landing ni Auth |

## 5. Evidencia heredada

Se reutiliza dentro de sus límites, sólo mientras el código correspondiente no cambie:

- SQL30 42073541134, fast 42076262537, caso público 42021721105, caso personal 42078792126.
- Pruebas físicas de push del 24 de octubre (Samsung A71, Android 13, Chrome 155): prueban recepción con pantalla apagada en esa fecha, no el recorrido de permisos.
- Calendario gestionado de punta a punta del 2 de noviembre, iniciado a mano.

Se verifica de nuevo: toda la revisión final integrada, correo real, recorrido de permisos, calendarios por dispositivo, publicación.

La corrida 42080552190 no certifica sus escenarios restantes. Las evidencias de otros SHA no se atribuyen a la revisión publicada.

## 6. Estrategia y decisiones

Orden por dependencias: primero lo que aporta hechos (dispositivos, Zoho real), después el núcleo de correo, luego la experiencia, y al final integración y publicación. Las decisiones son revisables si una prueba las refuta; cada cambio queda registrado acá con su motivo.

### D1. Consumidor de correo con revalidación en SQL

**Problema:** enviar sólo lo que sigue correspondiendo, sin retener bloqueos durante la llamada a Zoho.

**Decisión inicial:** una función de reclamo revalida turno, revisión, generación, destinatario, baja, preferencia y emisor en una transacción corta; marca el envío como iniciado antes de salir; el Worker llama a Zoho fuera de la transacción; otra función registra el resultado.

**Alternativas descartadas:** mandar desde la transacción del turno (retendría bloqueos y ataría el turno a Zoho); usar una cola externa (servicio nuevo, sin necesidad para un consultorio).

**Se invalida si:** el costo en llamadas o CPU no entra en el presupuesto Free.

### D2. Recordatorios por lectura del estado actual

**Problema:** una cola de recordatorios precalculados obliga a invalidarlos en cada cambio y puede suprimir uno legítimo.

**Decisión inicial:** los comprobantes nacen de eventos durables. Los recordatorios se derivan del turno vigente al llegar su ventana. Una clave única por turno, propósito, revisión del horario y revisión del contacto evita duplicados sin bloquear el aviso del horario nuevo.

**Alternativa descartada:** filas programadas al reservar: más estados, más carreras y peor recuperación al activar E con turnos ya existentes (RM14).

### D3. Cadena propia para correo, sin un sexto cron

**Problema:** agregar correo después de push lo dejaría sin presupuesto, porque push entra en finalización permanente.

**Decisión inicial:** cada disparo es una cadena con su propio presupuesto, así que el correo necesita su propio disparo, no una reserva dentro de push. Se mantienen cinco cron: `*/5` push, `1-59/5` calendario, `3-59/5` correo, `2-59/5` alternando reseñas y cargas, `17 */3` mantenimiento. Falta confirmar que la cuenta no use otros cron y medir.

**Alternativas descartadas:** segunda llamada de despacho después de push (no garantiza progreso); plan pago (no autorizado); `pg_cron` llamando al proveedor (saca secretos y presupuesto del Worker).

### D4. Entrega incierta sin reenvío automático

**Decisión inicial:** un envío iniciado sin resultado conocido queda «En comprobación» y sólo se resuelve con evidencia (respuesta, webhook con `client_reference`, registro del proveedor) o con decisión explícita del personal, que ve el riesgo de duplicado.

### D5. Recordatorio basado en hechos observables, no en la marca

**Problema:** el recorrido actual supone que después del botón hay una pregunta. Chrome puede contraerla, dejarla vencer o rechazarla sin avisar, y `default` no explica cuál. Repetir el botón lleva al bloqueo automático. La web no puede ver el ajuste de Android.

**Decisión, con evidencia de 4.1:**

- Después de cualquier resultado que no sea `granted`, la página deja de ofrecer el mismo botón como única salida. Explica qué pasó en lenguaje simple y da dos caminos: terminar el aviso del teléfono, o usar un calendario.
- Una sola receta para Chrome Android, comprobada en los dos teléfonos: interruptor principal de Chrome en Ajustes de Android, y **⋮ → Controles de sitios → Permisos → Suscribirse**, o «Restablecer permisos» si dice bloqueado. Sin ícono de la barra ni etiquetas por versión.
- Al volver, `permissions.onchange` continúa sola. El botón «Comprobar de nuevo» siempre responde con un resultado visible, aunque el estado no haya cambiado.
- La prueba sólo se da por buena con la respuesta de la persona. `displayed` no acredita nada.
- Se retiran la pregunta por la marca, «Ya estaba activado» y «Ya lo permití».

**Alternativa descartada:** pedir el permiso de nuevo automáticamente: suma descartes y acelera el bloqueo. Detectar Android apagado desde la web: comprobado imposible.

### D6. Alternativas de calendario sin suponer aplicaciones

**Decisión, con evidencia de 4.2:**

- En Android la alternativa principal es **«Guardar en mi calendario»** con `.ics`: el selector del sistema ofrece los calendarios reales del teléfono. Sirve sin Google y sin sincronización.
- La segunda es **«Conectar mi cuenta Google»** (gestionado): la única que actualiza y retira el evento sola. Se explica eso, y no se presenta como universal.
- Se quita el texto que promete avisos exactos para `.ics`: se dice que cada calendario usa sus propios avisos.
- Tras reprogramar o cancelar con `.ics`, la página y el correo piden borrar el evento anterior y, si corresponde, guardar el nuevo, porque el archivo no lo cambia.
- Calendario Samsung no tiene un botón propio: entra por `.ics` sin depender de una cuenta Google. Eso cierra la duda sobre `4d0905d`/`adf8ddc`: no se restaura aquella interfaz.
- El enlace `intent://` no funciona en Chrome: la página ya no lo ofrece. La ruta `calendario-intent` queda sin enlaces desde la interfaz; retirarla es limpieza menor que no cambia ningún recorrido, y se decide al cerrar la auditoría de rutas.

### D7. Recuperación compatible con E

**Problema:** después de aplicar E, V12b ya no puede servir la agenda: `20261103100000` cierra las actualizaciones directas de turnos que V12b hace como usuario autenticado, y su programador usa la asignación vieja de cron. Volver a V12b deja de ser una recuperación. El único procedimiento de restauración documentado ([respaldo y recuperación](../architecture/respaldo-y-recuperacion.md#restaurar-en-un-proyecto-nuevo)) restaura en un proyecto **nuevo**, y se ensayó en la pila local, no en un proyecto alojado.

**Decisión: recuperación por capas, cada una con su disparador.**

1. **Antes de tocar producción**, para no necesitar recuperación: CI sobre la revisión exacta (fast, SQL con carreras, paquete y navegador completo sobre el paquete); ensayo de la transacción de migraciones contra el esquema real de producción con `rehearse-production-migrations.mjs`, que siempre se revierte; respaldo `backup-production.mjs` comprobado.
2. **Durante la publicación:** las 32 migraciones van en **una sola transacción**. Si falla, producción queda en V12b sin cambios. El programador se detiene antes y vuelve con los cron nuevos sólo después de verificar la app. La app nueva se instala enseguida de confirmar las migraciones: esa ventana, de minutos, es la única en que V12b corre sobre el esquema nuevo.
3. **Defecto en un canal nuevo:** se apaga su interruptor, sin desplegar. Correo: `email_producer_enabled=false` (no registra eventos ni reclama) o `email_paused_until`. Reprogramación autónoma: `reschedule_enabled=false`. Google gestionado: secreto `GOOGLE_CALENDAR_MANAGED_ENABLED=false`. Todo lo programado: `deploy-production-workers.mjs scheduler-without-crons`.
4. **Defecto de la app fuera de esos interruptores:** corrección hacia adelante por el mismo circuito de CI. Desde la segunda versión de E, `wrangler rollback` a la versión E anterior verificada es válido, porque comparten el esquema.
5. **Datos:** el respaldo previo sirve para reparar filas puntuales con evidencia. Restaurarlo entero implica un proyecto nuevo, nuevas claves, sesiones invalidadas y perder lo escrito después; es un recurso de desastre, no una vuelta atrás, y antes de usarlo se cuenta qué datos reales se perderían.

**Alternativas descartadas:** volver a V12b (incompatible tras `.100`); reabrir las actualizaciones directas para que V12b funcione (rompe la auditoría y la identidad de E; la guía de publicación lo prohíbe); restaurar sobre el proyecto de producción (no ensayado, sin PITR en Free); publicar las migraciones semanas antes que la app (deja a V12b sobre un esquema que no entiende). El nivel `release` de CI exige un paquete de vuelta atrás compatible, que por esto no existe: se usa el criterio de V12b, navegador completo (`browser_grep=.`) sobre el paquete exacto.

**Riesgo residual aceptado:** un defecto grave de la app E en agenda o reserva que ningún interruptor apague se resuelve hacia adelante; mientras tanto podría verlo el consultorio real. Hoy no hay pacientes reales. **Se invalida si** aparecen pacientes reales antes de publicar o si alguna corrida sobre el paquete exacto no aprueba.

## 7. Integración y publicación

- Migraciones aditivas, con productores apagados al instalar y activación explícita por interruptor.
- Orden: CI completo, paquete, ensayo de migraciones, respaldo, detener el programador, aplicar migraciones, cargar secretos de Zoho, instalar la app, verificarla, instalar el programador con los cron nuevos, activar interruptores. Comandos exactos en la [guía de publicación](../architecture/publicacion-y-reversion.md#e--publicación-y-recuperación-compatible-5-de-noviembre).
- Secretos sólo en Workers: clave de envío del agente, desde el archivo privado, y clave de autenticación del webhook, generada en un archivo privado local. Esa clave la pega Juan en el panel de Zoho: el agente no escribe claves en formularios de terceros.
- Recuperación: D7. No se usa V12b ni `59f81e89` por inercia.
- Pruebas pesadas sólo en el repositorio auxiliar, secuenciales. Nada de datos privados en sus snapshots: es público.

## 8. Cómo se acredita el cierre

| Condición del mandato | Evidencia exigida |
|---|---|
| Push | Defecto reproducido antes y corregido después en teléfono físico; recepción observada en el dispositivo; cada estado sin salida tiene alternativa |
| Calendarios | Samsung Calendar, Xiaomi y Apple Calendar comprobados con sus condiciones y límites por escrito; lo no comprobable, declarado |
| Google OAuth | Entrada visible, consentimiento, crear, actualizar y retirar desde la interfaz publicada; guion y datos del video listos |
| Correo | Recepción real leída en el buzón acordado para cada propósito; enlaces abiertos y consecuencia en la base; baja, rebote y estado incierto comprobados |
| Integración y requisitos E | Matriz de 97 casos con evidencia por capa sobre la revisión final |
| Seguridad y fiabilidad | Carreras en ambos órdenes, fallas provocadas, aislamiento, reintentos y lecturas posteriores |
| Publicación | Revisión, versión, migraciones, cron, secretos e interruptores comprobados en el destino |
| Documentación | Índice con enlaces directos y sin instrucciones vigentes contradictorias |

## 9. Autorizaciones y decisiones de Juan en este encargo

Dadas en la conversación del 5 de noviembre, después de que el control de permisos rechazara una escritura productiva:

- **Autorizado expresamente:** leer y escribir datos sintéticos en la base de producción, aplicar las migraciones de E, detener y reactivar el programador, publicar la app y el programador, cargar sus secretos, ensayar la vuelta atrás, y enviar correos de prueba por Zoho a citasuite@gmail.com.
- **Autorizado después, las cuatro cosas:** en Zoho agregar dominios de envío, crear claves de envío y configurar el webhook; en Cloudflare crear sólo registros DNS de correo para subdominios de `cita-suite.com.ar`; en producción encender los interruptores de reprogramación autónoma, correo y Google Calendar gestionado; en los teléfonos aceptar el permiso de Google Calendar de Cita Suite y crear, mover y borrar eventos de prueba.
- **Cuenta Google de las pruebas en teléfonos:** Juan agrega `citasuite@gmail.com` en los dos. No se usan sus calendarios personales.
- **Natalia:** su remitente queda pendiente. No se toca su configuración, no salen correos de su consultorio hasta que Juan lo decida, y todo se prueba con un consultorio sintético.

## 10. Accesos que pueden necesitar a Juan

Se pide sólo cuando bloquee de verdad, y agrupado.

- Iniciar sesión en Zoho en el Chrome conectado y permitir `cpaas.zoho.com` en la extensión, o bien configurar el webhook desde el panel.
- Decisión sobre el emisor real de Natalia y su Reply-To.
- KYC y créditos de Zoho si el cupo gratuito no alcanza.
