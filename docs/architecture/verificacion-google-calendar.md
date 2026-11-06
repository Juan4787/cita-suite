# Verificación en Google del permiso de Calendar (proyecto «Cita Suite Calendar»)

**Estado al 5 de noviembre de 2026:** permiso declarado el 3 de noviembre; verificación del acceso a datos todavía no enviada. Lo que falta de parte de Juan es grabar el video con el guion de abajo, subirlo y enviarlo. **Estado anterior, 2 de noviembre:**
- **Proyecto:** `cita-suite-calendar-513502`, publicado («En producción»).
- **Cliente:** en uso por la app desde las 03:03 UTC.
- **Marca:** Google ya la verificó.
- **Falta:** verificar el permiso delicado `https://www.googleapis.com/auth/calendar.events.owned`. Hasta entonces los pacientes ven «Google no verificó esta app» y el límite es de 100 usuarios.

La lista de pendientes vigente está en `docs/plans/pendientes-vigentes.md`, sección 4, punto 1.

## Las dos verificaciones de Google (comprobado en la documentación oficial el 2 de noviembre)

1. **Verificación de marca:** Google revisa el nombre, el logo, el dominio y las páginas. **Ya está aprobada** («Se verificó la información de tu marca y se muestra a los usuarios», captura de Juan del 2-nov). Es el requisito previo de la segunda: «you must have a published branding status before you can request verification for data access».
2. **Verificación del acceso a datos:** se pide sólo para los permisos que Google clasifica como sensibles o restringidos. **Estado comprobado el 3 de noviembre con captura de Juan:** en «Acceso a los datos» la tabla «Tus permisos sensibles» está vacía, «No hay filas para mostrar». Es decir, `calendar.events.owned` **todavía no está declarado** en el proyecto. Las versiones anteriores de esta guía decían lo contrario y eran incorrectas. Google exige declarar todos los permisos en la consola antes de pedir la verificación. Para declararlo: ver la sección «Declarar el permiso» más abajo. Pide:
   - una justificación por permiso, que explique también por qué no alcanza uno más acotado;
   - un video en YouTube «No listado», en inglés, que muestre la pantalla de permiso con el nombre de la app, la barra de direcciones con el ID de cliente y la función que usa el permiso;
   - una política de privacidad en el mismo dominio que la página principal, que diga cómo se usan los datos de Google.

   Google indica que puede tardar **hasta 10 días**.

Hasta aprobarse la segunda, Google muestra la pantalla de «app no verificada» y limita la app a **100 usuarios nuevos en total**.

**Por qué antes no se pidió esto:** con «Dashboard Odontologia» nunca se llegó a la segunda. El intento anterior se frenó en la de marca (`acceso-google-calendar.md`: rechazos por el sitio de Netlify, la privacidad y el inicio detrás de acceso), y después quedó bloqueado por el dominio de Supabase.

Fuentes:
- [verificación de permisos sensibles](https://developers.google.com/identity/protocols/oauth2/production-readiness/sensitive-scope-verification);
- [pantalla de app no verificada y tope de 100 usuarios](https://support.google.com/cloud/answer/7454865?hl=es).

## Enlaces directos

- **Centro de verificación:** https://console.cloud.google.com/auth/verification?project=cita-suite-calendar-513502
- **Acceso a los datos (permisos):** en el menú izquierdo de Google Auth Platform, opción «Acceso a los datos». No tomar una dirección directa de esta sección: no fue verificada.
- **Subir el video:** https://studio.youtube.com, con la visibilidad «No listado».

## Qué es cada cosa que dice «Google Calendar»

Hay tres formas de guardar un turno en un calendario, y sólo una usa el permiso que se verifica:

| Función | Dónde aparece desde E | Qué hace | Permiso de Google |
|---|---|---|---|
| **«Conectar mi cuenta Google»** (gestionado, con `GOOGLE_CALENDAR_MANAGED_ENABLED`) | En la tarjeta del recordatorio de la página del turno, en todos los dispositivos | La app crea el evento, lo actualiza si cambia el turno y lo borra si se cancela | `calendar.events.owned`, el que se verifica |
| **Enlace «Google Calendar»** (`/turno/<token>/ir/google`) | Computadora y teléfonos que no son Android ni iPhone | Abre Google Calendar con el turno cargado; la persona lo guarda | Ninguno |
| **Archivo `.ics`** («Guardar en mi calendario», «Agregar al calendario») | Android, iPhone y computadora | El sistema ofrece los calendarios reales del dispositivo | Ninguno |

**Historia, ya resuelta:** el botón gestionado existió del 4 al 5 de agosto (`4d0905d` → `adf8ddc`) atado a la pregunta por la marca del teléfono, y se retiró sin motivo documentado. El 3 de noviembre no había ninguna entrada visible. E lo devuelve como opción propia, sin depender de la marca: decisión D6 del [plan integral](../plans/plan-integral-avisos-20261105.md#d6-alternativas-de-calendario-sin-suponer-aplicaciones).

**Por qué hay dos permisos de Calendar en Google:** el proyecto «Dashboard Odontologia» tiene su propio cliente de Calendar, de octubre, con el mismo permiso. La app no lo usa desde el 2 de noviembre a las 03:03 UTC y se conserva como antecedente. El que se verifica es «Cita Suite Calendar».

## Declarar el permiso (pendiente, 3 de noviembre)

1. Google Cloud, proyecto «Cita Suite Calendar», menú izquierdo: **Acceso a los datos**.
2. Tocar **«Agregar o quitar permisos»**.
3. En el panel, buscar **Google Calendar API** y marcar exactamente **`.../auth/calendar.events.owned`**, con la descripción «Consultar, crear, modificar y borrar eventos en los calendarios de Google de los que seas propietario». No marcar `calendar.events` ni `calendar`: son otros permisos, más amplios.
4. Tocar **«Actualizar»** y después **«Guardar»** al pie de la página.
5. Comprobar que la tabla **«Tus permisos sensibles»** ahora lista ese permiso. Si no aparece el buscador, verificar en «APIs y servicios → Biblioteca» que Google Calendar API figure como «Administrar» (ya lo estaba el 2 de noviembre).

Mientras no esté declarado, el Centro de verificación no pide la justificación ni el video para ese permiso. Hacerlo antes de pedir la verificación.

**Declarado el 3 de noviembre:** la tabla «Tus permisos sensibles» ya lista `calendar.events.owned` y aparece «Se requiere aprobación». En el campo «¿Cómo se usarán los permisos?» el límite es **1000 caracteres**. La justificación de abajo, sin el texto largo de la sección anterior, ocupa 751. Está también en `.verification/calendar-proyecto-propio-20261102/justificacion-1000.txt`.

> Cita Suite is an appointment-booking app for healthcare practices. Only when a patient chooses "Add to calendar" for their own appointment, we use calendar.events.owned to create one event in the patient's primary calendar with a reminder, update that same event if the practice reschedules the appointment, and delete it if the appointment is cancelled. We only touch events our app created for that appointment; we never read or change the user's other events. The event text is neutral and does not include the patient's name or the booked service. A narrower scope cannot do this: calendar.app.created only covers calendars created by the app, so the event would not appear in the patient's own calendar, and read-only scopes cannot create events.

## Dónde se pide

Google Cloud → proyecto **Cita Suite Calendar** → Google Auth Platform → **Centro de verificación** → «Preparar para la verificación» o «Enviar para verificación». Google pide revisar la información de marca, que ya está verificada, y después el acceso a los datos.

## Justificación del permiso (pegar en inglés, que es lo que leen los revisores)

> **Scope:** `https://www.googleapis.com/auth/calendar.events.owned`
>
> Cita Suite is an appointment-booking app for healthcare practices. After a patient books an appointment, the appointment page offers "Add to calendar". Only if the patient chooses it, we request this scope to create one event for that appointment in the patient's own primary Google Calendar, with a reminder, and to keep that same event in sync: we update it if the practice reschedules the appointment and we delete it if the appointment is cancelled.
>
> The event text is neutral: it does not include the patient's name or the booked service. We only touch events that our app created for the patient's own appointments. We never list, read or modify any other event of the user, and we do not share calendar data with third parties. The refresh token is stored encrypted and is removed when it is no longer needed (for example, when the appointment is cancelled). The patient can revoke access at any time from their Google Account.
>
> A narrower scope does not cover this feature: `calendar.app.created` only works on secondary calendars created by the app, but patients expect the appointment in their own main calendar, next to their other events. Read-only scopes cannot create the event.

Si piden un texto corto en castellano, el sentido es el mismo: sólo si el paciente elige «Agregar al calendario» se crea un evento de su turno en su calendario principal, que se actualiza si el turno cambia y se borra si se cancela. No se leen ni se tocan sus demás eventos.

## Video de demostración: guion exacto

**Requisitos oficiales**, leídos el 5 de noviembre en la [guía de permisos sensibles](https://developers.google.com/identity/protocols/oauth2/production-readiness/sensitive-scope-verification): mostrar en inglés el permiso tal como lo ve un usuario; que la pantalla de consentimiento muestre el nombre de la app; que la barra de direcciones de esa pantalla muestre el ID de cliente; mostrar cómo empieza la persona el pedido y el uso de cada permiso; subirlo a YouTube como **No listado**. La guía no fija una duración. La política de privacidad debe estar en el mismo dominio que la página principal y decir cómo se usan los datos de Google; desde E, `/privacidad` incluye además la frase de uso limitado.

**Antes de grabar.** Comprobado de punta a punta el 6 de noviembre sobre producción: en el teléfono con la cuenta `citasuite` crear, mover y retirar, y en computadora la entrada y el `client_id` hasta la elección de cuenta:
1. Producción con E publicada y `GOOGLE_CALENDAR_MANAGED_ENABLED` encendido.
2. Ya está listo un turno sintético del 20 de noviembre en «Consultorio de demostración», con horarios para reprogramar. Su enlace y el comando para limpiarlo están en el archivo privado `~/.local/share/cita-suite/google-video/turno-video.txt`, no en el repositorio.
3. Un perfil de Chrome en la computadora con **inglés como primer idioma** (Configuración → Idiomas), para que Google muestre la pantalla de permiso en inglés.
4. En ese perfil, la cuenta `citasuite@gmail.com` ya iniciada **antes** de grabar: la contraseña no aparece en el video.
5. Sin otras pestañas, marcadores ni notificaciones personales visibles.
6. En `https://myaccount.google.com/connections`, con `citasuite@gmail.com`, quitar el acceso de Cita Suite. Si la cuenta ya lo dio, Google muestra «ya tiene acceso parcial» y ninguna casilla; sin ese acceso, muestra el permiso completo, como a un paciente nuevo.

**Grabación**, con carteles breves en inglés (entre comillas, el texto sugerido):
1. `https://cita-suite.com.ar`: «Cita Suite: appointment booking for healthcare practices».
2. `https://app.cita-suite.com.ar/privacidad`, sección «Google Calendar»: «How Google data is used (Limited Use)».
3. El enlace del turno sintético: «A patient opens their appointment page».
4. En la tarjeta del recordatorio (en computadora, dentro de «Agregar al calendario»), tocar **«Conectar mi cuenta Google»**: «The patient chooses to save this appointment in their Google Calendar».
5. En la pantalla de elección de cuenta de Google, **hacer clic en la barra de direcciones** y mostrar `client_id=702611060405-…`: «OAuth client ID». Comprobado el 6 de noviembre: esa pantalla lo muestra, y la siguiente advertencia ya no.
6. Elegir `citasuite@gmail.com`. Si Google muestra que la app no está verificada, seguir con «Advanced» y «Go to Cita Suite»: es lo esperado hasta que Google apruebe.
7. Google pide dos pasos, comprobados en el teléfono el 6 de noviembre: primero el ingreso a Cita Suite, con «Continue»; después la pantalla de permisos, con el nombre **Cita Suite**, el permiso de Calendar y **una casilla que hay que marcar**. Mostrar el nombre y el permiso: «App name and requested permission». Marcar la casilla y aceptar con «Continue».
8. De vuelta en la página del turno, recargar hasta ver **«Recordatorio guardado en tu calendario»**: «The app created one event for this appointment».
9. En `calendar.google.com`, abrir el evento del día del turno: «Neutral title, with reminders».
10. En la página del turno, **Reprogramar** a otro horario y confirmar; recargar Google Calendar y mostrar el evento en el horario nuevo: «Rescheduling updates the same event».
11. En la página del turno, **Cancelar** y confirmar; recargar Google Calendar y mostrar que el evento ya no está: «Cancelling deletes that event. No other event is read or changed».

**Después de grabar:**
1. Revisar el video completo: no deben verse contraseñas, códigos, correos privados ni otra cuenta.
2. El agente invalida el enlace del turno sintético, que quedó en la barra de direcciones.
3. Subirlo en `https://studio.youtube.com` con visibilidad **No listado**.
4. En el Centro de verificación, pegar el enlace y la justificación de arriba. **No cambiar la marca** (nombre, logo, dominios) mientras Google revisa.

## Después de enviarla

Google responde por correo a la cuenta del proyecto. Suele pedir aclaraciones: reenviarlas al agente para preparar la respuesta. Mientras revisa, la app sigue funcionando con el aviso.
