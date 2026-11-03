# Gestión del turno del paciente

Mode: Operate. Extensión de la pantalla de turno existente, sin rediseño.

## Direction contract

THESIS: Consultar el estado vigente y confirmar una sola acción sobre ese turno.
OWN-WORLD: Se conservan BookingAppearance, los tokens ux/bk y los temas claro/oscuro del consultorio; sin identidad visual adicional ni imágenes nuevas.
STORY: Turno vigente → cancelar o elegir otro horario → revisar condiciones y dinero registrado → confirmar → consultar resultado persistido.
FIRST VIEWPORT: Fecha y estado del turno conservados en la pantalla existente; panel de acción con una pregunta directa, salida sin cambios y alternativa discreta. Cancelación ya realizada e inicio/pasado no ofrecen cancelar/reprogramar.
FORM: Una columna; horarios elegibles como enlaces GET accesibles, día etiquetado y resumen económico explícito antes del único POST. Funciona sin JavaScript, conserva operación/revisión aceptadas y bloquea doble envío durante la espera. El transporte incierto permite comprobar la misma acción, sin anunciar una reversión no demostrada.
FINISH: unreviewed and undocumented is unfinished; this build ends with the finish review, the verdict, DESIGN.md, and every shipping raster carrying its provenance.

## Estado

Pantalla y servidor compartidos escritos. Fast y primer navegador de dos casos aprobados con límites en el registro de E; la revisión de capturas detectó selección de día no acreditada. El selector retira horarios/resumen anteriores al editar la fecha (roja/verde dirigida 8/8), con nueva comprobación de día y capturas del selector pendientes. Revisión final de los cinco anchos, ambos temas y estados aún abierta. No hay raster nuevo ni prueba productiva.
