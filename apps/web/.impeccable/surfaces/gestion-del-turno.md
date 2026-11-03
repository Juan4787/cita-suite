# Gestión del turno del paciente

Mode: Operate. Extensión de la pantalla de turno existente, sin rediseño.

## Direction contract

THESIS: Consultar el estado vigente y confirmar una sola acción sobre ese turno.
OWN-WORLD: Se conservan BookingAppearance, los tokens ux/bk y los temas claro/oscuro del consultorio; sin identidad visual adicional ni imágenes nuevas.
STORY: Turno vigente → cancelar o elegir otro horario → revisar condiciones y dinero registrado → confirmar → consultar resultado persistido.
FIRST VIEWPORT: Al seguir cancelar/reprogramar, fecha neutral y pregunta directa antes de información/calendario/detalle, con salida sin cambios y alternativa discreta. La confirmación/resultados se muestran primero, conservando instrucciones de la nueva seña cuando corresponda. Cancelación ya realizada e inicio/pasado no ofrecen cancelar/reprogramar.
FORM: Una columna; horarios elegibles como enlaces GET accesibles, día etiquetado y resumen económico explícito antes del único POST. Funciona sin JavaScript, conserva operación/revisión aceptadas y bloquea doble envío durante la espera. El transporte incierto permite comprobar la misma acción, sin anunciar una reversión no demostrada.
FINISH: unreviewed and undocumented is unfinished; this build ends with the finish review, the verdict, DESIGN.md, and every shipping raster carrying its provenance.

## Estado

Pantalla y servidor compartidos escritos. Fast anterior y browser 41702920488 con día escogido comprobados. Después, revisión del primer viewport descubrió la pregunta bajo tareas auxiliares; prioridad de pregunta y resultado corregida (rojas/verde dirigido 11/11). Selector en fila propia móvil, retira opciones/resumen al editar día; nueva matriz incluye ambos modos. Fast y navegador de esta última prioridad pendientes; revisión final de los cinco anchos/temas/estados abierta. No hay raster nuevo ni prueba productiva.
