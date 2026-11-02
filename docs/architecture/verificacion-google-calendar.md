# Verificación en Google del permiso de Calendar (proyecto «Cita Suite Calendar»)

**Estado al 2 de noviembre de 2026:**
- **Proyecto:** `cita-suite-calendar-513502`, publicado («En producción»).
- **Cliente:** en uso por la app desde las 03:03 UTC.
- **Marca:** Google ya la verificó.
- **Falta:** verificar el permiso delicado `https://www.googleapis.com/auth/calendar.events.owned`. Hasta entonces los pacientes ven «Google no verificó esta app» y el límite es de 100 usuarios.

La lista de pendientes vigente está en `docs/plans/pendientes-vigentes.md`, sección 4, punto 1.

## Las dos verificaciones de Google (comprobado en la documentación oficial el 2 de noviembre)

1. **Verificación de marca:** Google revisa el nombre, el logo, el dominio y las páginas. **Ya está aprobada** («Se verificó la información de tu marca y se muestra a los usuarios», captura de Juan del 2-nov). Es el requisito previo de la segunda: «you must have a published branding status before you can request verification for data access».
2. **Verificación del acceso a datos:** se pide sólo para los permisos que Google clasifica como sensibles o restringidos. La consola de este proyecto lista `calendar.events.owned` en «Tus permisos sensibles». Pide:
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
- **Acceso a los datos (permisos):** https://console.cloud.google.com/auth/scopes?project=cita-suite-calendar-513502
- **Subir el video:** https://studio.youtube.com, con la visibilidad «No listado».

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
