# Tareas posteriores a E, pospuestas

**Estado vigente por pedido posterior de Juan del 3 de noviembre de 2026:** P1, P2 y P3 **pospuestas; no iniciarlas al cerrar E**. E continúa siendo la única tarea activa hasta completarla, publicarla, verificarla y entregar su documentación. Precedencia y literal en [plan 12.26](propuesta-senas-avisos-natalia.md#posteriores-a-e-pospuestas); el encargo anterior de ejecución automática de [12.23](propuesta-senas-avisos-natalia.md#tareas-posteriores-a-e) queda sustituido en ese punto. Estado de producción en el [registro único](../ESTADO-VIGENTE.md).

## Orden obligatorio y seguimiento

| Orden | Trabajo | Estado | Condición de avance |
|---|---|---|---|
| Previo | E completa: correo, autogestión, señas y sus 97 casos | En implementación E1 | [Registro de E](ejecucion-etapa-e-20261103.md): cierre por evidencia, publicación y auditoría pendientes |
| P1 | Habilitar cancelar turnos desde recepción | Pospuesta; no iniciada | Reanudación expresa de Juan después de E |
| P2 | Estilar todos los controles/superficies de la app, en claro y oscuro | Pospuesta; no iniciada | Reanudación expresa de Juan; orden previsto después de P1 |
| P3 / nueva D | Avisos internos generales para horarios liberados, con patrón similar a Seguimientos | Pospuesta; no iniciada | Reanudación expresa de Juan; orden previsto después de P2 |

Si Juan las reanuda, cada tarea conservará cambios, reproducción/contraste, pruebas, auditoría, publicación y documentación propios. Conservar sus límites e incidencias, y no atribuirles evidencia de otra revisión. El cierre de E no es una instrucción para reanudarlas.

## P1: cancelación desde recepción

Revisar primero permisos y acciones reales después de E, porque parte de la autorización puede existir ya. Habilitar la opción visible y utilizable para recepción donde corresponda, con confirmación contextual, resultado persistente y mensajes humanos. Probar su rol real, tenant ajeno, permiso retirado, turno iniciado/cancelado y la coherencia con dinero, disponibilidad y notificaciones. No duplicar el comando transaccional de E ni ampliar otros permisos por inferencia.

## P2: estilos completos en los dos modos

Inventariar las superficies reales de la aplicación y reserva pública: formularios, selectores, fechas/horas, botones, menús, diálogos, avisos, carga de archivos, estados vacíos/errores y controles del navegador que hoy queden sin estilo propio. Conservar semántica, teclado y accesibilidad al sustituir la presentación. Usar el sistema existente de tokens y componentes, sin colores sueltos ni un rediseño de marca no pedido.

Verificar claro/oscuro, anchos 320/390/768/1280/1600, zoom, foco y contenido largo con evidencia de interfaz renderizada. Auditar controles nativos visibles y llamadas alert/confirm/prompt, sin asumir que un análisis de código o una captura del estado normal prueban todos los menús y estados. Documentar el alcance efectivo de los controles de la web; no presentar como personalizado un diálogo externo que el navegador/sistema siga dibujando.

## P3: reemplazo de D por notificación interna

**La D anterior de aviso al celular del consultorio queda reemplazada por este alcance.** El objetivo son avisos de horarios liberados dentro de una bandeja/notificación general de la app, con lógica similar al patrón real de Seguimientos, que se inspeccionará al iniciar esta tarea. No incorporar suscripciones push al personal, permisos del navegador, manifiesto instalable ni requisito de conocer Android/iPhone para esta D. Los push/calendarios existentes del paciente y el correo de E conservan su alcance propio.

Contrastar y reutilizar el registro/alerta C de horarios liberados para evitar dos fuentes, notificaciones duplicadas o avisos de un horario ya ocupado. Verificar visibilidad por consultorio/rol, acciones, pendientes/resueltos, recuentos, cambios concurrentes, caducidad y coherencia de navegación. Definir sus detalles a partir del código y del patrón de Seguimientos; no inventar otros tipos de aviso comercial no encargados.

## Continuidad

Después de una compactación: leer AGENTS, estado vigente, plan completo/ajustes, registro de la tarea activa y esta cola. Continuar E desde su checkpoint; P1/P2/P3 siguen pospuestas incluso después de cerrar E. Registrar aquí una eventual reanudación expresa, inicio y cierre de cada tarea, revisión/corridas/evidencia y el siguiente paso concreto. La lista general de pendientes enlaza este documento y no duplica su seguimiento.
