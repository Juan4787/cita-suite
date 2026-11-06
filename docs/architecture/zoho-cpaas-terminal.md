# Zoho CPaaS desde la terminal

**3 de noviembre de 2026: conexión OAuth local comprobada.** Pedido de Juan: «conectemos zoho para que puedas controlarlo desde la terminal». Alcance en [plan 12.19](../plans/propuesta-senas-avisos-natalia.md#zoho-terminal-vigente). Las funciones de la etapa E siguen pendientes; esta conexión no las implementa ni despliega.

## Acceso preparado

Self Client en Zoho API Console, sobre la misma cuenta de CPaaS, región `.com`. Las credenciales se ingresaron mediante una ventana local con campos ocultos, sin pasar por el chat, los argumentos de procesos ni Git. El código de autorización se intercambió por access token y refresh token. Se comprobó además una renovación real y una consulta con el acceso renovado.

Permisos solicitados, con los nombres que conserva el índice oficial de CPaaS:

```text
Zeptomail.MailAgents.ALL,Zeptomail.Domains.ALL,Zeptomail.MailTemplates.ALL,Zeptomail.Suppressions.ALL,Zeptomail.email.READ
```

OAuth permite usar las APIs de administración de agentes, dominios, plantillas y supresiones, y consultar registros de correo. No habilita facturación, KYC ni otros productos de Zoho. La clave de envío de un agente es otra credencial: el 5 de noviembre se consultó y guardó privadamente una ya existente; no se generó ni desplegó una clave nueva. Los permisos no autorizan por sí mismos operaciones destructivas ni envíos a nuevos destinatarios.

## Custodia y comandos

Los secretos y respuestas quedan en esta computadora, fuera del repositorio:

- Herramienta sin secretos versionada: [`scripts/zoho-cpaas.py`](../../scripts/zoho-cpaas.py). La carpeta privada conserva una copia inicial y una guía local; la fuente para continuar es la del repositorio.
- Credenciales: `~/.config/cita-suite/private/zoho-cpaas.json`, archivo 600 dentro de directorio 700.
- Respuestas y recibos privados: `~/.local/share/cita-suite/zoho/`; incluyen `conexion-verificada.json`, `mailagents-latest.json`, `domains-latest.json` y `email-latest.json`.

La herramienta utiliza sólo la biblioteca estándar de Python, no instala un servicio persistente y renueva el acceso al vencer. Su código está guardado en Git; los tokens se guardan mediante archivo privado y reemplazo atómico, sincronizando archivo/directorio a disco. Se comprobó acceso desde un proceso nuevo, sin reiniciar la computadora. No hace falta mantener una terminal abierta para conservar la conexión tras un reinicio. No se copió ningún token a Workers, Supabase ni GitHub. Las respuestas completas contienen direcciones e identificadores: no publicarlas ni imprimir el archivo de credenciales.

```bash
python3 scripts/zoho-cpaas.py status
python3 scripts/zoho-cpaas.py agents
python3 scripts/zoho-cpaas.py domains
python3 scripts/zoho-cpaas.py logs
python3 scripts/zoho-cpaas.py keys
```

`status` sólo comprueba presencia local; las otras consultas comprueban acceso remoto. Los comandos de consulta hacen GET, guardan la respuesta privada y muestran únicamente cantidades. `keys` exige exactamente un agente activo y un identificador de ruta válido; consulta sus claves sin generarlas, modificarlas ni imprimirlas. Las conserva en `apikeys-latest.json` con permisos privados y procedencia. Si hubiera varios agentes, falla sin elegir uno por posición. Para otras operaciones de administración se usará la API correspondiente dentro del alcance solicitado, sin asumir que todas las opciones del panel tienen API pública.

Si se pierde o revoca el acceso, `connect --dc com` vuelve a abrir la captura local de un código nuevo de Self Client; no suministrar secretos por argumentos ni chat. Para una terminal operada directamente por Juan existe `--terminal`, con entrada oculta. Usar siempre la región real; no seguir redirecciones con credenciales.

## Evidencia y límites

- Consultas autenticadas reales: un agente (`agent_1`, activo), un dominio con salida verificada/habilitada y dos registros de email. El listado devuelve esos correos como `processed`; la captura aportada por Juan muestra dos entregados. Ninguna de esas evidencias prueba lectura o recepción en bandeja de entrada.
- Renovación OAuth real y consulta de agentes posterior: correctas.
- Verificación local: permisos de archivos/directorios, rechazo de credenciales no privadas, renovación conservando refresh token, destino fijo, bloqueo de redirecciones, salida sin secretos y lectura de listas válidas/vacías/inválidas. Estas comprobaciones locales no son pruebas de correo real.
- Ajuste por respuesta real: los registros vienen en `data.logs`, no en la lista directa usada por agentes/dominios. Se corrigió el lector y se repitió esa consulta real con éxito; un formato inesperado sigue fallando sin declarar un resultado verificado.
- En la conexión inicial del 3 no hubo nuevos envíos, cambios de dominio/DNS, claves de envío, webhooks, SMTP de Auth, configuración de Natalia, despliegues ni cambios de base. No se ejercitaron escrituras administrativas. KYC, compra/saldo/vencimiento y la integración completa de E conservan sus pendientes.
- **5 de noviembre:** GET real de claves existentes correcto, una credencial sin enmascarar guardada en archivo 600, fuera de Git/chat/argumentos. La API real usa el campo `apikey`, aunque el ejemplo oficial muestra `token`; conservar esa diferencia antes de implementar un lector de envío. Once comprobaciones aisladas de selección/rutas/guardado con credenciales sintéticas, sin red. Recibo sin secretos en `.verification/etapa-e-20261103/zoho-existing-key-read-proof.json`. No se probó esa clave contra la API de envío ni se publicó; esta lectura no prueba recepción, saldo, KYC o capacidad restante.

Para revocar, retirar el acceso del Self Client en Zoho Accounts/API Console. Borrar sólo el archivo local no revoca el refresh token en Zoho. No eliminar clientes ni regenerar claves ajenas por rutina.

## Fuentes oficiales consultadas

- [Grupos de API y autenticación](https://www.zoho.com/cpaas/help/api/api-home.html).
- [Endpoints y permisos OAuth de CPaaS](https://www.zoho.com/cpaas/help/api/api-index.html).
- [Lectura de claves de un agente](https://www.zoho.com/cpaas/help/api/list-api-keys.html).
- [Self Client: código, tokens y renovación](https://www.zoho.com/developer/oauth/self-client/authorization-code-flow.html).
- [Regiones de CPaaS](https://www.zoho.com/cpaas/help/api/multiple-data-centers.html).

Continuación funcional en la [especificación de E](../plans/etapa-e-correo-autogestion.md), su [registro](../plans/registro-senas-avisos-natalia.md#zoho-terminal-registro) y su [traspaso](../plans/traspaso-senas-avisos-natalia.md#etapa-e-punto).

## Integración del correo de turnos (6 de noviembre)

**Qué se comprobó con la API real** está en la [sección 4.3 del plan](../plans/plan-integral-avisos-20261105.md#43-comportamiento-real-de-zoho-medido-el-5-de-noviembre). Esta sección dice cómo se opera.

**Secretos del Worker `app`:**
- `ZOHO_CPAAS_API_KEY`: clave de envío del agente. Se toma de `~/.local/share/cita-suite/zoho/apikeys-latest.json` y se carga por la entrada estándar de `wrangler secret put`, sin imprimirla.
- `ZOHO_CPAAS_WEBHOOK_KEY`: se genera en `~/.config/cita-suite/private/zoho-webhook-key.txt`. El panel la pide escrita, así que la pega Juan desde ese archivo: el agente no escribe claves en formularios de terceros.

**Consultar un envío:** `python3 scripts/zoho-cpaas.py reference <referencia>` dice cuántos envíos tiene Zoho con esa referencia, sin mostrar direcciones. La referencia es el identificador de la entrega en la app. La lista de Zoho tarda en sincronizar, así que un cero reciente no prueba que no haya salido.

**Webhook:** configurado el 6 de noviembre. Agente → Webhooks → «Configurar webhook» → URL `https://app.cita-suite.com.ar/api/zoho/webhook` → Verificar → cuatro eventos de correo → Agregar; recién entonces aparece «Clave de autenticación». La clave debe tener hasta 50 caracteres; Zoho rechazó una con guiones y aceptó 32 letras y números. Formas reales: entregado llega con `object: email_delivery`, la queja como `fbl_compliant`, y ambos sólo con `processed_time`. «Send Test» sólo simula rebotes, aperturas y clics; «entregado» y las quejas se comprueban con un envío real. La firma cubre el contenido, y la marca de tiempo sólo se usa para rechazar notificaciones viejas.

**Preparar el remitente de un consultorio.** La API de dominios no funciona para esto (plan 4.3), así que se hace desde el panel:
1. Elegir con Juan un subdominio de `cita-suite.com.ar`. No se admiten nombres reservados como `app`, `avisos` o `admin`.
2. En Zoho, agregar el dominio al agente y copiar sus dos registros.
3. En Cloudflare, cargar el TXT DKIM y el CNAME `bounce-zem`, sin proxy.
4. Verificar en Zoho.
5. Registrar en la base con `operator_set_business_email_sender(consultorio, dominio, 'verified', clave_de_dominio, correo_de_respuesta)`.

El consultorio queda listo cuando tiene dominio verificado y correo de respuesta; hasta entonces no sale ningún correo suyo y la configuración lo dice.

**Crédito:** Zoho no informa saldo ni vencimiento por API. Cada compra se registra en `/odonto/maestro/correo`, y la app avisa desde 14 días antes del vencimiento o al quedar un décimo del crédito. El primer crédito vence el 3 de diciembre de 2026. La compra la hace Juan.
