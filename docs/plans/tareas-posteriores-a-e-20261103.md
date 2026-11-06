# Tareas posteriores a E

**Estado vigente desde el 6 de noviembre de 2026:** P1, P2 y P3 **reanudadas por Juan**, en ese orden y por separado ([plan 12.34](propuesta-senas-avisos-natalia.md#reanudacion-p1-p2-p3-20261106)). Sustituye la pausa de [12.26](propuesta-senas-avisos-natalia.md#posteriores-a-e-pospuestas). Publicar no está incluido: se pide aparte. Estado de producción en el [registro único](../ESTADO-VIGENTE.md).

## Orden obligatorio y seguimiento

| Orden | Trabajo | Estado | Condición de avance |
|---|---|---|---|
| Previo | E completa: correo, autogestión, señas y sus 97 casos | Publicada el 6 de noviembre | [Registro de E](ejecucion-etapa-e-20261103.md) |
| P1 | Habilitar cancelar turnos desde recepción | Implementada, en verificación | Ver [punto de trabajo](#punto-de-trabajo) |
| P2 | Estilar todos los controles y superficies de la app, en claro y oscuro, y revisar el diseño y la experiencia de toda la app | Implementada, en verificación | Ver [punto de trabajo](#punto-de-trabajo) |
| P3 / nueva D | Avisos internos generales para horarios liberados, con patrón similar a Seguimientos | Implementada, en verificación | Ver [punto de trabajo](#punto-de-trabajo) |

Cada tarea conserva cambios, reproducción/contraste, pruebas, auditoría, publicación y documentación propios. Conservar sus límites e incidencias, y no atribuirles evidencia de otra revisión.

## P1: cancelación desde recepción

Revisar primero permisos y acciones reales después de E, porque parte de la autorización puede existir ya. Habilitar la opción visible y utilizable para recepción donde corresponda, con confirmación contextual, resultado persistente y mensajes humanos. Probar su rol real, tenant ajeno, permiso retirado, turno iniciado/cancelado y la coherencia con dinero, disponibilidad y notificaciones. No duplicar el comando transaccional de E ni ampliar otros permisos por inferencia.

**Decisión de Juan, 6 de noviembre ([12.34](propuesta-senas-avisos-natalia.md#reanudacion-p1-p2-p3-20261106)):** un turno que ya empezó o ya pasó no se cancela. La pantalla debe aclararlo en vez de esconder el botón sin explicación.

## P2: estilos completos en los dos modos

Inventariar las superficies reales de la aplicación y reserva pública: formularios, selectores, fechas/horas, botones, menús, diálogos, avisos, carga de archivos, estados vacíos/errores y controles del navegador que hoy queden sin estilo propio. Conservar semántica, teclado y accesibilidad al sustituir la presentación. Usar el sistema existente de tokens y componentes, sin colores sueltos ni un rediseño de marca no pedido.

Desde el 6 de noviembre P2 incluye la revisión de diseño y experiencia de toda la app: espacios vacíos, bloques que no encajan, jerarquía y coherencia entre pantallas, a partir de las capturas reales.

Verificar claro/oscuro, anchos 320/390/768/1280/1600, zoom, foco y contenido largo con evidencia de interfaz renderizada. Auditar controles nativos visibles y llamadas alert/confirm/prompt, sin asumir que un análisis de código o una captura del estado normal prueban todos los menús y estados. Documentar el alcance efectivo de los controles de la web; no presentar como personalizado un diálogo externo que el navegador/sistema siga dibujando.

## P3: reemplazo de D por notificación interna

**La D anterior de aviso al celular del consultorio queda reemplazada por este alcance.** El objetivo son avisos de horarios liberados dentro de una bandeja/notificación general de la app, con lógica similar al patrón real de Seguimientos, que se inspeccionará al iniciar esta tarea. No incorporar suscripciones push al personal, permisos del navegador, manifiesto instalable ni requisito de conocer Android/iPhone para esta D. Los push/calendarios existentes del paciente y el correo de E conservan su alcance propio.

Contrastar y reutilizar el registro/alerta C de horarios liberados para evitar dos fuentes, notificaciones duplicadas o avisos de un horario ya ocupado. Verificar visibilidad por consultorio/rol, acciones, pendientes/resueltos, recuentos, cambios concurrentes, caducidad y coherencia de navegación. Definir sus detalles a partir del código y del patrón de Seguimientos; no inventar otros tipos de aviso comercial no encargados.

## Continuidad

Después de una compactación: leer AGENTS, estado vigente, [12.34](propuesta-senas-avisos-natalia.md#reanudacion-p1-p2-p3-20261106) y el punto de trabajo de abajo. Se registra acá el inicio y cierre de cada tarea, la revisión, las corridas, la evidencia y el siguiente paso concreto. La lista general de pendientes enlaza este documento y no duplica su seguimiento.

<a id="punto-de-trabajo"></a>

## Punto de trabajo

**6 de noviembre, noche.** Relevamiento hecho sobre las 665 capturas de la corrida 42290663360 (`main` `f459b95c`). Nada publicado todavía.

**P1, lo implementado:**
- `supabase/migrations/20261106040000_staff_cancel_before_start.sql`: el comando rechaza cancelar un turno ya iniciado con `APPOINTMENT_ALREADY_STARTED`. Hasta acá sólo lo impedía la pantalla. Reprogramar un turno pasado sigue permitido.
- Detalle del turno: «Cancelar turno» sale del final de la página y queda arriba, en `StaffCancelPanel.svelte`, con lo que pasa con el horario, la seña y el aviso al paciente antes de confirmar. Sólo lo ven los roles que operan.
- Turno pasado o en curso: etiqueta «Turno pasado» o «En curso» y un aviso que explica por qué no se cancela. La agenda y «Mis turnos» usan la misma etiqueta, en reemplazo de «Expirado».
- Pruebas: `e2e/reception-cancel.spec.ts`, casos 11a a 11c de `supabase/tests/staff_appointment_management.sql`, y pruebas de cliente y servidor.
- Corridas: SQL 42307475373 aprobada. Navegador 42308051622: toda la conducta aprobada; falló sólo el control de diseño a 320 px por una palabra partida en el título anterior, reemplazado en P2.

**P2, lo implementado:**
- Detalle del turno rehecho: datos clave arriba, acciones visibles y grupos a todo el ancho. Se fue la grilla de cuatro columnas que dejaba el vacío.
- Desplegables con `ux-disclosure`: resuelve las dos flechas y los títulos corridos de Reprogramar, Historial y Horarios que se liberaron.
- Nada nativo: selectores, fechas, archivo, avisos de validación y ayudas emergentes son de la app. `native-controls.test.mjs` lo controla y `theme-modes.spec.ts` lo mide en pantalla.
- Diálogos de pacientes con los botones y campos del sistema: se va el azul de una paleta vieja. Configuración con encabezado y ancho únicos. Pestañas iguales en todo el editor del profesional.
- Defectos corregidos: «Último paso» oscuro e ilegible en modo claro, fechas como «6 De Noviembre De 2026», «Odontología» como título en celular, «Página no encontrada» con un mensaje de error de otra cosa, botón rojo de «Reportar problema», clases sin definir (`ux-success`, `ux-error`, `ux-link`, `ux-alert-danger`).

**P3, lo implementado:** `SlotReleasesNotice.svelte` en la parte superior de la app, con `loadSlotReleaseNotice`. Sin migraciones: reusa `get_appointment_slot_releases`. Sólo para dueño, administración y recepción, y no en la agenda. Detalle en el [contrato funcional](../architecture/functional-contracts.md).
