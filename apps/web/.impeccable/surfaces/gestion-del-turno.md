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

Estado al 4 de noviembre: prioridad/foco del panel principal comprobados en browser 41708652093; personal en 41757455635 conserva su alcance propio. Extensión clínica reutiliza BookingAppearance/ux-bk y comparte formulario/uploader entre canal de capacidad y legado. Fast 41791538890 aprobado (1822 servidor/280 cliente, cero errores/un aviso DOM corregido después). Browser **41793557725 aprobado** para dos marcas, cinco anchos/ambos modos, formulario nativo y recuperación de respuesta ilegible/Storage aislado/revocación, sin reproducir el aviso; límites exactos en E1.70. No es cierre de E, revisión visual integral final ni publicación. No hay raster nuevo; P2 global sigue pospuesta.

Disponibilidad auxiliar (E1.75, sin publicar): información requiere contexto clínico propio y los recordatorios tienen permiso independiente de reprogramar/reserva online. Acceso mínimo no muestra esos CTA ni inicia activación automática. Dirigidas 41 servidor/55 cliente aprobadas; browser ampliado pendiente. No cambia el diseño visual ni inicia P2.
