# Confirmación de correo: alta y experiencia de uso

**Estado de cierre:** publicada y comprobada el 31 de octubre de 2026. [Traspaso final](traspaso-confirmacion-email-20261030.md), [registro](registro-confirmacion-email-20261030.md) y [guía](../architecture/confirmacion-de-correo.md). Los resultados buscados siguientes son los criterios de la entrega, no trabajo pendiente de publicación.

## Pedido y alcance (30 de octubre de 2026)

Juan habilitó la obligación de confirmar email enSupabase y pidió revisar a fondo ese flujo y suUX. Al pedirse esta corrección, el alta mostraba en rojo «La cuenta se creó pero falta confirmar el correo electrónico»; debe abrir una pantalla propia de confirmación y tratarlo como un paso normal. Autorización productiva anterior vigente. La corrección posterior del usuario mantiene la auditoría rigurosa y exige elegir controles según el contexto real, sin imponer CI/staging/respaldo/reversión como una secuencia automática. No se desactiva el requisito de confirmar correo.

Configuración deNatalia yD quedan en espera por instrucción del usuario; E ya estaba pospuesta. El acceso deNatalia se releyó: activo/no permanente/12meses otorgados porJuan; no se cambia. Su operación anterior de alta terminó17:25:47 y sólo se verifica su recibo al cambiar de tarea; no se repite.

## Resultado buscado

1. Alta aceptada sin sesión → pantalla «Revisá tu correo», sin mensaje rojo ni apariencia de fallo, correo legible y siguientes pasos.
2. Ingreso con correo todavía no confirmado → el mismo paso, sin repetir el alta ni perder el correo.
3. Reenvío accesible, con espera y límites; errores reales tienen texto humano. No revelar si existe una cuenta.
4. Enlace del correo → resultado verificado porAuth. No aceptar un fragmento, parámetro o clic como prueba de confirmación. No crear sesión antes de confirmar.
5. Enlaces vencidos/usados, otro dispositivo, recarga, vuelta al ingreso, correo mal escrito, JavaScript desactivado, escritorio/móvil y teclado tienen una salida clara.
6. No regresan Google, ingreso normal, alta sin confirmación cuando un entorno lo permite, recuperación de contraseña ni sesión de otro usuario. La app no agrega contraseñas, tokens ni correos a consultas públicas o registros. Los enlaces implícitos del proveedor traen un fragmento transitorio: conJavaScript se retira antes de verificarlo; sinJavaScript hay confirmación enAuth e ingreso manual, con el límite de limpieza documentado.

## Método y destino vigentes

- El usuario confirmó que no hay pacientes reales. Los pacientes y turnos ficticios pueden crearse, cambiarse, borrarse o regenerarse para probar; no exigir su preservación exacta. Proteger cuentas reales, secretos, permisos, código, infraestructura y configuración comercial.
- Mantener auditoría profunda, intentos de refutar hipótesis y correcciones de causa raíz. Ampliar la investigación cuando sea útil; no prohibir nuevas auditorías ni confundir cobertura con sobreingeniería.
- Usar directamente producción para las pruebas y escrituras autorizadas cuando sea la vía que aporta evidencia real sin comprometer activos reales. Staging o aislamiento se eligen por una necesidad concreta, no como paso obligatorio para duplicar todas las pruebas.
- Reutilizar código, paquetes y resultados ya comprobados. No repetir campañas completas por inercia. La app tiene release aprobado y quedó publicada/comprobada en producción el 31 de octubre; el cierre y sus evidencias están en el registro y el traspaso vigentes.
- La entrega no migra la base. Ni un backup de menos de seis horas ni las huellas idénticas de turnos ficticios son condiciones automáticas de publicación. Mantener una recuperación utilizable y recurrir a ella si hace falta; un ensayo adicional debe justificarse por el cambio y el daño posibles.
- No modificar SMTP, plantillas, DNS, scheduler o datos comerciales por inercia. No retomar Natalia/D/E. Conservar el trabajo del usuario y no mover su HEAD/índice.
- La RAM limitada sigue siendo un recurso real: compilaciones y suites pesadas en CI, con un trabajador. Esto no impone reproducir todo un entorno antes de una comprobación directa en producción.

## Evidencia y seguimiento

Evidencia: `.verification/confirmacion-email-20261030/`. El registro y el traspaso específicos llevarán cada corrida/fallo/causa/resultado y el punto exacto. Las fuentes técnicas son la documentación oficial deSupabase y el código instalado, no los textos de error como contrato único.

## Precisión de retorno y reversión

El origen principal configurado enPUBLIC_SITE_URL acepta `/confirmar-correo`; el alternativo workers.dev vuelve alSiteURL al pedir una ruta no registrada. Alta/reenvío usan el origen principal comoreset. No se cambianAuth/SMTP/DNS. La recuperación debe conservar la ruta nueva y el resultado firmado para enlaces ya emitidos; C9 puro no es compatible. La pantalla atiende tanto navegación deSvelteKit como cambio nativo del fragmento.

## Corrección metodológica posterior del usuario

El usuario aclaró que el problema no era abrir auditorías, ser exigente o cubrir inconsistencias: todo eso sigue siendo lo que busca. Rechazó la sobreingeniería inútil, en particular invertir el doble para probar primero en otro entorno y proteger turnos de pacientes ficticios. Esta decisión sustituye los requisitos de procedimiento anteriores que resulten incompatibles, sin reducir la calidad exigida ni la protección de activos reales. El registro conserva el método que se aplicó y sus resultados como historia, no como obligación para repetirlo.
