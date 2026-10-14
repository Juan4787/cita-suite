# Implementación y auditoría de Natalia / Cita Suite

Base: `a480dbbe319e1a5dfc4f34e6d771828831b90b29`. Plan vigente:
[propuesta](2026-10-14-natalia-cita-suite-propuesta.md). Contrato y operación:
[turnero, documentos y contacto](2026-10-14-booking-extensions-contract.md).

## Alcance y estado

Implementación local de ajustes mensuales de aranceles, bloqueos múltiples, franjas de
seguimiento, documentos privados de profesional/paciente, presupuesto de almacenamiento,
indicaciones y contacto WhatsApp. Se reutilizan y verifican cuestionarios e historia clínica.
Noticias y cursos siguen postergados. No hay notificaciones automáticas por WhatsApp ni
cola de validación estructural de PDFs.

Las cuatro migraciones nuevas **no se aplicaron a producción**. No se desplegó un nuevo
artefacto en Cloudflare ni Vercel en esta entrega. La inspección remota fue de sólo lectura,
sin consultar registros de pacientes. Los datos reales del consultorio no se inventaron;
la configuración de Natalia requiere datos confirmados antes de activarla.

## Decisiones incorporadas de la última revisión

- Política monetaria en ARS con `bigint` y pesos enteros. Se conserva precisión acumulada y
  se redondea cada cotización al final; no se encadena el valor mostrado.
- Porcentaje habitual y cambios por mes ingresados por el consultorio. No se obtiene IPC.
- Se mantienen 10 MB y tres documentos por turno. El control usa bytes reales, separado
  de la reserva global pesimista de 5 MB por permiso de carga. 3,5 + 3,5 + 0,2 MB es válido.
- PDF se verifica con metadata y lecturas parciales. No se promete integridad estructural,
  escaneo antivirus ni comparación de SHA completo en el Worker.

## Matriz de evidencia

| Área | Evidencia ejecutada | Alcance |
| --- | --- | --- |
| Modelo, permisos y operaciones | Reconstrucción de 97 migraciones y diez contratos SQL | PostgreSQL 17.6.1 aislado; schema de Storage API real v1.70.3; Auth/Realtime de fixture |
| Lógica y servidor | 129 archivos, 958 tests aprobados, incluida la regresión de cabeceras nativas | Vitest, un worker, sin paralelismo de archivos |
| Componentes | Ocho archivos, 74 tests aprobados | jsdom; no prueba de dispositivo físico |
| Tipos | Svelte check sin errores ni advertencias después de los ajustes visuales | Código local |
| Cloudflare | Build con adapter-cloudflare completado | Compatibilidad de compilación, no ejecución remota del Worker |
| Natalia | Astro check/build; 14 páginas; contrato de diez secciones y destinos públicos | Sitio estático construido localmente |
| Regresión pública sintética | Seis escenarios existentes de SDK/contacto/fallback | Respuestas de negocio interceptadas; cero escrituras de datos |
| Turnero, documentos y administración | 13 casos de navegador y HTTP con base, PostgREST y Storage reales | Fixture aislado, Auth simulado, CSP/CORS adaptados a loopback |
| Natalia y backend vinculados | Catálogo/contacto reales del fixture, SDK real, iframe real, independencia de WhatsApp y formulario sin JavaScript | Cinco comprobaciones locales; cero mensajes WhatsApp |
| Privilegios de despliegue | `postgres` puede leer objetos, actualizar bucket y crear trigger en `storage.objects` | Sólo lectura en producción; no certifica que se aplicó DDL |
| UX/UI | Capturas 1440/390/320 y tema público oscuro; detector sin hallazgos; revisión independiente | Ver cierre visual al pie; no sustituye pruebas de producción |

Fixture de navegador: `cita-booking-test-39a648573e81`, con contenedores de PostgREST y
Storage propios. El runner vuelve a reconstruir una base independiente para la comprobación
final del schema. Ninguna prueba usa el destino remoto vinculado. Los cron del fixture están
desactivados; no se detuvieron contenedores ajenos.

## Casos comprobados directamente

- Después de elegir noviembre, el paciente ve $20.400 antes del horario; no aparecen
  centavos. La reserva real aislada conserva ese importe y sus indicaciones.
- El cuestionario cambia medicación en la ficha y conserva envíos anteriores. Se verifica
  el guardado posterior sin JavaScript, con valores renderizados desde servidor.
- El paciente sube un PDF de 3,5 MB desde el formulario. Se agregan 3,5 MB y 200 KB: total
  real 7,2 MB. Se rechaza el cuarto archivo. Repetir inicio/finalización no duplica estudios.
- Una capacidad de reserva ajena no puede finalizar ese documento.
- El profesional sube PDF sin miniatura; la ficha lista ambas procedencias. La descarga lleva
  nombre y apellido del paciente y devuelve exactamente el mismo SHA-256 que el original.
- El límite de 5 MB se aplica en el endpoint y en Storage, incluso con una URL válida que
  recibe un byte extra. Un archivo de exactamente 5.000.000 bytes termina correctamente.
- El Storage real responde `206` a `bytes=0-1023`, con exactamente 1.024 bytes y Content-Range
  correcto. Las pruebas de servidor también comprueban rechazo/cancelación si ignora Range.
- La disponibilidad real excluye consulta general a las 17:00 y admite seguimiento en esa
  franja. Se guarda un lote de fechas no consecutivas. Los contratos SQL prueban creación
  manual, restricciones con buffers, borrado de última prestación, replay, rollback y bloqueo
  sobre turnos existentes con reconocimiento explícito.
- La configuración conserva el borrador de indicaciones al guardar otro formulario y los
  valores ingresados si falla el teléfono. No se cambia la configuración parcialmente.
- Natalia carga el SDK después de la intención de reservar, abre el iframe real y lo cierra
  con Escape. El enlace WhatsApp sigue funcionando si se deshabilita la reserva; apagar su
  flag quita el enlace y conserva la dirección aprobada. No se abre ni envía ese enlace.

## Hallazgos corregidos durante la auditoría

| Hallazgo | Corrección y comprobación |
| --- | --- |
| Registros vencidos de miniaturas abandonadas se perdían al comenzar otra carga | Se conserva la referencia hasta limpiar por Storage API. Contrato SQL con original confirmado intacto |
| Una franja restringida podía perderse en sanitización/restauración del borrador | Normalización conserva scope e IDs; vacío permanece cerrado. Contratos de horarios y de guardado atómico |
| Confirmar un turno existente después de bloquear su franja se trataba como reserva nueva | Se conserva ese turno; reactivar uno cancelado sí valida de nuevo. Contrato SQL |
| La cuota de turno sumaba la reserva global de 5 MB en lugar del tamaño correspondiente | Controles separados, trigger sobre bytes reales incluso sin lease. SQL y HTTP con 7,2 MB |
| Datos del formulario se sobrescribían durante la hidratación inicial | Sincronización sólo ante nueva versión/esquema/reserva; guardado inmediato comprobado |
| POST sin JavaScript podía guardar y después mostrar error por cabecera duplicada | Cabeceras privadas una vez por request compartido entre acción y load. Regresión unitaria y POST nativo real |
| Un profesional no podía leer la tarifa predeterminada aplicable a su prestación | SELECT limitado a prestaciones asignadas; modificar la predeterminada sigue reservado a administradores. Contrato RLS |
| WhatsApp de contacto se confundía con la bandera heredada de mensajería | Flag independiente. Contrato SQL comprueba que no activa mensajería automática |
| Fallo del catálogo reemplazaba contacto aprobado que sólo tenía dirección | Se conserva cualquier contacto válido previamente cargado. Caso real de reserva deshabilitada |
| Datos JSON de metadata de Storage podían crecer sin cota | Trigger limita nueva metadata; objetos existentes no alterados se conservan. Contrato SQL |
| Importes se partían en la vista de 320 px | Celdas monetarias sin corte; importes completos comprobados en recaptura |
| El icono nativo de mes tapaba el último dígito del año a 320 px | Padding horizontal móvil acotado, fuente de 16 px y control nativo conservados. Recapturas 1440/390/320 y septiembre largo |
| Botones de listados de horarios se partían letra por letra | Distribución vertical del bloque y acciones sin corte, con altura de uso móvil |
| Enlace WhatsApp tenía poco contraste en la sección marrón | Reutiliza la variante crema ya existente; conserva la variante de la página de contacto |
| Restricción fechada aparecía como “Horario extra” | Etiqueta correcta y prestaciones permitidas en listados, incluidas franjas cerradas |

## Reproducción y custodia de evidencia

Comandos mínimos, siempre secuenciales:

```sh
node scripts/test-booking-foundation.mjs --real-storage
NODE_OPTIONS=--max-old-space-size=1024 pnpm --filter web test --maxWorkers=1 --fileParallelism=false
NODE_OPTIONS=--max-old-space-size=1024 pnpm --filter web test:client --maxWorkers=1 --fileParallelism=false
NODE_OPTIONS=--max-old-space-size=1024 pnpm --filter web check
NODE_OPTIONS=--max-old-space-size=1024 pnpm --filter web build:cloudflare
NODE_OPTIONS=--max-old-space-size=1024 pnpm --filter natalia build
pnpm --filter natalia test:browser
```

Para integración real local, mantener el fixture conforme al contrato y ejecutar
`scripts/qa-booking-extensions.mjs` y después `scripts/qa-natalia-booking-contact.mjs`.
Los runners validan etiquetas y destinos locales. El test reinicia sólo contadores de límites
de su fixture entre escenarios, para permitir repetición con una única IP de prueba.

Capturas/JSON de ejecución: `.impeccable/review/booking-extensions/`. Logs locales:
`/tmp/cita-implementation-schema-final.log`, `...-unit-reviewed.log`, `...-client-final.log`,
`...-check-price-final.log`, `...-cloudflare-price-final.log`, `...-natalia-final.log`; informes visuales
bajo `/tmp/cita-extensions-qa/`. El resumen persistente y hashes se guardan junto a este
registro. No publicar archivos runtime con tokens, URLs firmadas, `.env`, credenciales ni los
adjuntos antiguos del workspace. Los números/nombres en capturas son exclusivamente sintéticos.

Las capturas de componente ocultan temporalmente navegación fija ajena al recorte; las
capturas de página la conservan. Capturas largas de la homepage no se usan para evaluar texto
ni la sección de contacto: se emplean recortes legibles y se mantiene el contrato de contenido
completo del build. El navegador del host no estuvo disponible; se reutilizó Playwright.

## Límites y cierre

Storage físico del proveedor, egress mensual facturado, consumo de otros proyectos de la
organización, Auth real, push recibido en un dispositivo y activación/configuración real de
Natalia no quedan certificados por estas pruebas. El panel distingue consumo SQL y estimación
de descargas autorizadas. El margen de 700 MB no garantiza permanecer indefinidamente en Free.

La revisión visual independiente completa validó fidelidad, cobertura y estados dentro del
alcance, y pidió un arreglo: evitar que el icono nativo tape el año del selector de mes a
320 px. La puntuación posterior marcó ese arreglo **resuelto**, con disposición `ship`
limitada a esa corrección. Se conservaron ambos informes y las capturas de 1440/390/320,
incluida la comprobación de septiembre largo. No se ejecutó un segundo detector.

El [paquete de evidencia](evidence/2026-10-14-booking-extensions/README.md) conserva resultados,
privilegios remotos consultados en sólo lectura, informes y hashes de fuente/build/capturas.
Se retiraron los tres contenedores y ambas redes exclusivos del fixture; se verificó cada
etiqueta y pertenencia antes de retirar. Se cerró su grupo de Vite y se eliminaron los
archivos runtime con tokens. No quedaron listeners en 5177/43021 ni contenedores etiquetados
de esta prueba. La terminación inicial de la sesión dejó recursos que se retiraron de forma
explícita; los contenedores de otros proyectos no se modificaron.

La documentación independiente de la extensión está completa en
[las notas de diseño](2026-10-14-ui-extension-design-notes.md). PRODUCT.md refleja el alcance
actual; DESIGN.md y su sidecar se conservaron sin cambios. Se informa allí su deriva
histórica de alcance, sin reemplazar identidad ni tokens. No se da por publicada una
función por haber aprobado pruebas o build.
