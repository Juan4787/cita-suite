# Plan integral de avisos, correo y calendarios

**Documento canónico del encargo del 5 de noviembre de 2026.** Fuente del pedido: [mandato literal](mandato-integral-avisos-20261105.md). Requisitos heredados: [especificación E](etapa-e-correo-autogestion.md) y [plan aprobado](propuesta-senas-avisos-natalia.md#12-aprobación-y-ajustes-posteriores). Cronología y evidencia: [registro activo](ejecucion-etapa-e-20261103.md). Este plan no repite esos requisitos: dice cómo se cumplen, qué falta y cómo se acredita.

**Después de una compactación:** releer el mandato, este plan completo, la especificación E, `AGENTS.md`, `docs/ESTADO-VIGENTE.md` y el checkpoint de abajo. Un resumen de conversación no reemplaza esas fuentes.

## 0. Checkpoint vigente

Se actualiza después de cada bloque con resultado. Es el único lugar con el «siguiente paso».

| Campo | Valor |
|---|---|
| Fecha | 5 de noviembre de 2026, noche (Argentina) |
| Revisión de partida | `main` `d3f7553c`, igual a GitHub; producción V12b `771fac59`, versión `277d332d`, comprobada con `/_app/version.json` y `wrangler deployments list` |
| Fase | Reconstrucción terminada. Investigación física en curso |
| Siguiente acción | Reproducir el defecto de Chrome Android en los dos teléfonos sobre V12b |

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

### D5. Experiencia de recordatorio por capacidades

**Decisión inicial:** se reemplaza la pregunta por la marca por un recorrido basado en estados observables del permiso y en una salida de calendario siempre disponible. El detalle se fija después de las pruebas físicas.

## 7. Integración y publicación

- Migraciones aditivas, con productores apagados al instalar y activación explícita por interruptor.
- Orden previsto: detener el programador, aplicar migraciones, instalar la app, instalar el programador con los cron nuevos, comprobar, activar productores.
- Secretos sólo en Workers: clave de agente y clave de autenticación del webhook.
- Antes de publicar se escribe y se ensaya una recuperación compatible. No se usa V12b ni `59f81e89` por inercia.
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

## 9. Accesos que pueden necesitar a Juan

Se pide sólo cuando bloquee de verdad, y agrupado.

- Iniciar sesión en Zoho en el Chrome conectado y permitir `cpaas.zoho.com` en la extensión, o bien configurar el webhook desde el panel.
- Decisión sobre el emisor real de Natalia y su Reply-To.
- KYC y créditos de Zoho si el cupo gratuito no alcanza.
