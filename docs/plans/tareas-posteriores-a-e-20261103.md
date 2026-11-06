# Tareas posteriores a E

**Estado vigente desde el 6 de noviembre de 2026:** P1, P2 y P3 **reanudadas por Juan**, en ese orden y por separado ([plan 12.34](propuesta-senas-avisos-natalia.md#reanudacion-p1-p2-p3-20261106)). Sustituye la pausa de [12.26](propuesta-senas-avisos-natalia.md#posteriores-a-e-pospuestas). Publicar no está incluido: se pide aparte. Estado de producción en el [registro único](../ESTADO-VIGENTE.md).

## Orden obligatorio y seguimiento

| Orden | Trabajo | Estado | Condición de avance |
|---|---|---|---|
| Previo | E completa: correo, autogestión, señas y sus 97 casos | Publicada el 6 de noviembre | [Registro de E](ejecucion-etapa-e-20261103.md) |
| P1 | Habilitar cancelar turnos desde recepción | En curso | Ver [punto de trabajo](#punto-de-trabajo) |
| P2 | Estilar todos los controles y superficies de la app, en claro y oscuro, y revisar el diseño y la experiencia de toda la app | En relevamiento | Después de P1 |
| P3 / nueva D | Avisos internos generales para horarios liberados, con patrón similar a Seguimientos | Sin iniciar | Después de P2 |

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

**6 de noviembre, noche.** Relevamiento hecho sobre las 665 capturas de la corrida 42290663360 (`main` `f459b95c`). P1 en implementación. Nada publicado todavía.
