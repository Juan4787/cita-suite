# Verificación en Google del permiso de Calendar (proyecto «Cita Suite Calendar»)

**Estado al 2 de noviembre de 2026:**
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

Hay dos funciones distintas en la página del turno, y sólo una usa el permiso que se verifica:

| Función | Qué hace | Permiso de Google |
|---|---|---|
| **Enlace «Google Calendar»** (`calendar.google.com/calendar/render?…`) | Abre Google Calendar con el turno ya cargado, y el paciente lo guarda él mismo. | Ninguno. No hay conexión ni API. |
| **«Agregar al calendario» gestionado** (sólo Android, con `GOOGLE_CALENDAR_MANAGED_ENABLED`) | La app crea el evento, lo actualiza si cambia el turno y lo borra si se cancela. El aviso dice «El turno está guardado en tu cuenta Google». | `calendar.events.owned`, el permiso que se verifica. |

El botón «Agregar al calendario» que descarga un archivo `.ics` tampoco usa permisos: funciona con cualquier aplicación de calendario.

**Corrección del 3 de noviembre: hoy la función gestionada no tiene ningún botón**, ni en producción (V12b) ni en `main`:
- **Lo que queda:** el servidor la conserva (`/turno/[token]/google-calendar/connect`) y la página sólo muestra su estado cuando la conexión ya existe.
- **Lo que falta:** nada la inicia.
- **Historia:**
  - **4 de agosto (`4d0905d`):** cuando el aviso de prueba no llegaba, la página ofrecía «¿Tu teléfono es Samsung? → Agregar a Calendario Samsung», que guardaba el evento con avisos en la cuenta de Google que sincroniza Calendario Samsung, y «¿Usás otro teléfono Android? → Agregar a Google Calendar». Los dos usaban la función gestionada.
  - **5 de agosto (`adf8ddc`):** se reemplazaron por la guía de ajustes del teléfono y por el enlace manual. Una prueba exige desde entonces que en Samsung no aparezca Google Calendar. El motivo no quedó documentado.
- **La prueba del 2 de noviembre** abrió la dirección de conexión a mano, no desde un botón.
- **Error del agente:** dos respuestas del 3 de noviembre dijeron que esta guía ya estaba corregida, y no lo estaba.

**Por qué coexisten:** en el diseño del 4 de agosto convivían. El enlace manual y el archivo servían para quien no conecta su cuenta, y la función gestionada, para Android cuando el aviso no llegaba. Hoy en producción sólo funcionan el enlace manual y el archivo. Restaurar el botón es un pendiente (`docs/plans/pendientes-vigentes.md`, sección 4, punto 7).

**Por qué hay dos permisos de Calendar en Google:** el proyecto «Dashboard Odontologia» tiene su propio cliente de Calendar, de octubre, con el mismo permiso. Ese cliente ya no lo usa la app desde las 03:03 UTC del 2 de noviembre, y se conserva como vuelta atrás. El proyecto nuevo, «Cita Suite Calendar», es el que se verifica. Ver el cierre en la sección de pendientes.

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

## Video de demostración (sin audio alcanza; 1 a 2 minutos)

**No grabar todavía.** El video tiene que mostrar el recorrido que hace un paciente, y hoy la función gestionada no tiene botón (ver «Qué es cada cosa»). Se graba después de restaurarlo y publicarlo.

Grabarlo en la computadora, en inglés o en castellano con subtítulos o carteles breves en inglés. Subirlo a YouTube como **«No listado»** y pegar el enlace en el formulario.

1. Mostrar `https://cita-suite.com.ar` (qué es Cita Suite) y la política `https://app.cita-suite.com.ar/privacidad`, en la sección «Google Calendar».
2. Reservar un turno de prueba como paciente en un consultorio ficticio, por ejemplo el «Consultorio Ramirez». El agente puede dejar uno listo, con su enlace.
3. En la página del turno, tocar **«Agregar al calendario»**.
4. En la pantalla de Google, **mostrar la barra de direcciones** con el `client_id` (`702611060405-…`) y la pantalla de permiso con «Cita Suite», el logo y el permiso de Calendar. Aceptar.
5. Volver a la página del turno: muestra «Recordatorio activado».
6. Abrir Google Calendar y mostrar el evento del turno.
7. Volver a la página del turno, **cancelarlo** y mostrar en Google Calendar que el evento desapareció.

## Lo que Google suele pedir además

Para permisos delicados, los revisores a veces piden que la política de privacidad diga expresamente que el uso de los datos de Google cumple la «Google API Services User Data Policy», incluido el «Limited Use». La política publicada hoy describe el uso, pero no nombra esa política. Si lo piden, se agrega en la app una frase en la sección «Google Calendar» de `/privacidad` y se publica: es un cambio chico.

## Después de enviarla

Google responde por correo a la cuenta del proyecto. Suele pedir aclaraciones: reenviarlas al agente para preparar la respuesta. Mientras revisa, la app sigue funcionando con el aviso.
