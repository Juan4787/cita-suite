# Modo claro predeterminado en toda la app — plan aprobado

**Estado:** aprobado por Juan el 2 de noviembre de 2026 (sección 3), con autorización expresa para publicar en producción. Este documento es la fuente de verdad de la campaña.

- Las secciones 1 a 11 no se editan. Los ajustes posteriores van como subsecciones nuevas de la sección 12, con su motivo y lo que reemplazan.
- **Registro** (qué se hizo, cuándo, con qué resultado): [registro-modo-claro-20261102.md](registro-modo-claro-20261102.md).
- **Traspaso** (punto exacto y cómo retomar): [traspaso-modo-claro-20261102.md](traspaso-modo-claro-20261102.md).
- **Evidencia:** `.verification/modo-claro-20261102/` (carpeta con permiso 700, recibos con permiso 600, nunca se sobrescriben).
- **Al retomar** después de una compactación de contexto o antes de cada etapa: leer este plan completo, el traspaso y el registro. No reconstruir el plan de memoria.

## 1. Pedido literal de Juan (2 de noviembre de 2026)

> Quiero agregar un modo claro completo por defecto, manteniendo el modo oscuro actual, pero que aplique de punta a punta a toda la app, y todas y cada una de sus secciones. Primero quiero preguntarte cual es la mejor forma de hacerlo con claude code, si es recomendable activar claude desing y como se hace y ademas quiero que definamos cual serian los mejores colores para el nicho de consultorios, basado en logica y evidencia. Investiga y decime

## 2. Propuesta presentada y aprobada

### 2.1 Diagnóstico de la app (medido el 2 de noviembre sobre la versión publicada V11f)

- 103 archivos de interfaz: 53 páginas y 46 componentes.
- La hoja global `apps/web/src/app.css` ya tiene variables de color, pero con sólo 288 usos. Hay unos 3.500 colores escritos a mano:
  - 601 colores hexadecimales;
  - 122 colores `rgba`;
  - 2.365 clases de color de Tailwind;
  - 499 clases con color arbitrario, como `bg-[#7c3aed]`.
- `apps/web/src/app.html` agrega siempre la clase `dark` y `apps/web/DESIGN.md` lo fija como regla («The Tema único Rule»).
- Tres situaciones conviven:
  - componentes con clases claras más su versión `dark:` (667 casos): la mitad clara nunca se diseñó;
  - componentes sólo oscuros (`text-white`, `bg-white/10`…): en claro quedarían con texto blanco sobre blanco;
  - componentes que ya usan variables: cambian solos.
- Seis azules casi iguales escritos a mano (`#152642`, `#0f1f36`, `#1f3554` con 113 usos, `#122641`, `#13243d`, `#101f35`).
- Los archivos con más colores fijos: `routes/odonto/+layout.svelte` (293), la página de un turno (191), `PatientProfilePanel` (172), el esqueleto de carga (164), el listado de pacientes (144) y la página de un paciente (140).
- El tema oscuro tiene cuatro fallas de accesibilidad medidas (sección 2.6).

### 2.2 Arquitectura

1. **Las mismas variables, con valor claro y oscuro.** Los valores claros van como predeterminados y los oscuros actuales bajo la clase `.dark`. Se conservan los nombres actuales (`--bg`, `--surface`, `--text`, `--accent`…), así los usos existentes cambian solos. Se agregan las que faltan: borde de campo, información, esqueletos de carga y sombras por modo.
2. **Tailwind apunta a esas variables** (por ejemplo `bg-surface`). Cada elemento queda con una sola clase por color y desaparecen las versiones `dark:` duplicadas.
3. **Preferencia guardada en una cookie**, leída por el servidor: la página sale ya en el modo elegido, sin parpadeo y sin depender de JavaScript.
4. **Selector en el menú de la cuenta:** Claro (predeterminado), Oscuro y Automático (según el dispositivo).
5. **`color-scheme` y `theme-color` por modo**, para calendarios nativos, barras de desplazamiento y la barra del navegador del celular.
6. **Excepciones deliberadas:**
   - el visor de radiografías e imágenes clínicas queda siempre oscuro;
   - la reserva de Natalia conserva su propio modo;
   - el script para sitios externos, los PDF y los Excel no cambian;
   - la página de servicio no disponible (`auth-unavailable.ts`) pasa a respetar el modo.
7. **Prueba guardiana:** falla si aparece un color fijo fuera de las variables, salvo excepciones justificadas.

### 2.3 Etapas propuestas

0. Preparación: plan, registro y traspaso; capturas de referencia del oscuro actual.
1. Base: variables, Tailwind, cookie, selector y la prueba de colores en modo informe.
2. Estructura común: diseño principal, navegación, menús, diálogos, esqueletos de carga, páginas de error, ingreso, registro y recuperación.
3. Agenda y turnos.
4. Pacientes y ficha clínica, con el visor oscuro.
5. Equipo y configuración: suscripción, ayuda y maestro.
6. Páginas públicas: reserva y página del turno del paciente.
7. Cierre: prueba de colores estricta, matriz completa de capturas, revisión automática de contraste en los dos modos, DESIGN.md, candidata, CI y publicación.

Cada etapa se cierra con capturas en claro y oscuro. Todo se ejecuta de a una prueba por vez, por la memoria de la máquina.

### 2.4 Claude Design

- Ya está dentro de Claude y activo en la cuenta de Juan (tipos «Design» y «Design System»). El sitio aparte claude.ai/design cierra el 14 de diciembre de 2026.
- No hace falta para este trabajo: casi todo es ingeniería dentro del código. La referencia de diseño ya vive en el repositorio (`DESIGN.md` y `.impeccable/design.json`).
- Sólo se ofreció como vista previa opcional de la paleta antes de migrar.

### 2.5 Evidencia que sostiene la paleta

1. Texto oscuro sobre fondo claro se lee mejor, también en personas mayores (Piepenbrock, Mayr y Buchner, 2013; Nielsen Norman Group, 2020): claro por defecto.
2. El oscuro sigue disponible: cerca de un tercio lo prefiere y las personas con cataratas pueden leer mejor en oscuro.
3. Lo que más pesa es la luminosidad y la saturación (Valdez y Mehrabian, 1994; Wilms y Oberfeld, 2018): superficies grandes claras y poco saturadas; color fuerte sólo en acciones y estados. El violeta está entre los tonos más agradables.
4. Fondos de lectura (Rello y Bigham, 2017): lectura sobre blanco; fondo de página casi neutro, nunca un gris azulado notorio.
5. Azul y competencia (Labrecque y Milne, 2012): el azul marino de la marca es el color del texto.
6. Daltonismo (Birch, 2012): ningún estado se comunica sólo por color.
7. Envejecimiento visual: ningún significado depende de distinguir azul de violeta ni de tonos pastel.
8. Imágenes clínicas: el visor de radiografías queda siempre oscuro.
9. Norma: WCAG 2.2 nivel AA como piso, AAA para el texto principal, APCA como control perceptual.
10. No está respaldado que un tono concreto genere emociones en salud (Tofle y colegas, 2004; revisión sistemática de 2024).

### 2.6 Paleta aprobada

**Modo claro** (contrastes medidos con WCAG 2.2):

| Variable | Color | Uso | Contraste |
|---|---|---|---|
| `--bg` | `#f5f6f8` | fondo de página | — |
| `--surface` | `#ffffff` | tarjetas y todo lo que se lee | — |
| `--surface-2` | `#f2f4f7` | zonas internas y filas resaltadas | — |
| `--surface-raised` | `#ffffff` con sombra suave | menús y diálogos | — |
| `--border` / `--border-strong` | `#e4e7ec` / `#d0d5dd` | separadores y contornos (decorativos) | — |
| `--field-border` | `#7e889b` | borde de campos | 3,2 a 3,6:1 |
| `--text` | `#0f1b2d` | texto principal | 16,0 a 17,3:1 |
| `--text-muted` | `#475467` | texto secundario | 7,0 a 7,7:1 |
| `--text-subtle` | `#5d6b82` | texto terciario | 4,9 a 5,4:1 |
| `--accent` | `#7640cf` | violeta del logo: foco, selección, íconos | 5,6 a 6,2:1 |
| `--accent-strong` | `#6633c2` | botón principal con texto blanco | 7,45:1 |
| `--accent-press` y `--accent-text` | `#5627a8` | botón presionado, enlaces y texto violeta | 9,3:1 |
| `--accent-soft` | `#f3eefc` | fondo de lo seleccionado | texto violeta encima: 8,2:1 |
| Éxito | `#15803d` / `#ecfdf3` / `#166534` | ícono / fondo / texto | 5,0:1 y 6,8:1 |
| Advertencia | `#b45309` / `#fff7e6` / `#8a3c0c` | ícono / fondo / texto | 5,0:1 y 7,2:1 |
| Error | `#d92d20` / `#fef3f2` / `#b42318` | ícono / fondo / texto | 4,4 a 4,8:1 y 6,1 a 6,6:1 |
| Botón destructivo | `#c4221a`, presionado `#9f1c15` | eliminar | 5,9:1 y 7,9:1 |
| Información | `#175cd3` / `#eff6ff` / `#1849a9` | ícono / fondo / texto | 5,4 a 6,0:1 y 7,5:1 |

El rojo de íconos `#d92d20` no se usa para texto sobre el fondo de página (4,47:1); el texto de error usa `#b42318`.

**Modo oscuro:** se conserva, con cuatro correcciones:

| Qué | Hoy | Corrección | Resultado |
|---|---|---|---|
| Texto terciario (`--text-subtle`) | blanco al 42 %: 3,5 a 3,7:1 | `#8a97ab` | 5,05 a 6,13:1 |
| `text-white/45` (63 usos) y `text-white/40` (24 usos) | 4,41:1 y 3,74:1 | pasan a texto terciario | 5,05:1 o más |
| Contorno de foco | violeta al 65 %: 2,51:1 | `#a78bfa` opaco | 5,5 a 6,7:1 |
| Borde de campos | sin variable | `#647899` | 3,3 a 4,1:1 |

### 2.7 Decisiones recomendadas

1. Paleta: aprobarla así o pedir antes la vista previa.
2. «Automático»: incluirlo, con Claro como predeterminado aunque el dispositivo esté en oscuro.
3. Preferencia por dispositivo (cookie, sin tocar la base), no por cuenta.
4. Páginas públicas para pacientes en claro por defecto; la integración de Natalia sigue el modo de su web.
5. Trabajo en curso: cerrarlo y publicarlo primero, o empezar por lo que no lo toca.
6. Aplicar las correcciones del oscuro.
7. La landing y la web de Natalia quedan fuera de esta entrega.

### 2.8 Riesgos presentados

Tamaño (varias sesiones), romper el oscuro al migrar, parpadeo del modo equivocado, cupo de uso compartido, memoria de la máquina y publicación con autorización expresa.

## 3. Aprobación literal (2 de noviembre de 2026, recibida antes de las 04:25 UTC)

> autorizo todo lo que dijiste y la subida a produccion. No me pidan mas permisos ni autorizaciones, avanza con rigor extremo y exigencia de calidad muy alta. Deja todo perfectamente documentado de forma clara y ordenada

## 4. Lo que decide esa aprobación

1. **La paleta de 2.6 queda aprobada tal cual.** La vista previa era una puerta de aprobación opcional y deja de serlo. La evidencia visual son capturas de la app real en los dos modos, más fieles que una maqueta.
2. **Selector con tres opciones:** Claro, Oscuro y Automático. Sin preferencia guardada, la app es clara aunque el dispositivo esté en oscuro.
3. **Preferencia por dispositivo** en una cookie, sin migración de base.
4. **Páginas públicas en claro por defecto.** La apariencia de Natalia conserva su lógica de modo.
5. **Trabajo en curso:** al revisarlo resultó que los 15 archivos eran V11 («ayuda con duraciones»), ya publicada y comprobada el 2 de noviembre (revisión `72d59ab00db67a8502ca560c762c61e6cfac1923`). En `apps/web` la carpeta es idéntica a V11f. No queda trabajo que cerrar: **la base de esta campaña es V11f.**
6. **Se aplican las cuatro correcciones del oscuro** y la unificación de los azules casi iguales.
7. **Fuera de alcance:** la landing (`cita-suite.com.ar`) y la web de Natalia.
8. **Publicación en producción autorizada,** sin nuevas consultas. Se mantienen los controles: CI sobre la candidata exacta, comprobación del destino y vuelta atrás disponible.

## 5. Alcance

**Entra:** toda la aplicación `apps/web`: las 53 rutas, sus componentes, la hoja global, los esqueletos de carga, las páginas de error, los diálogos, los menús y la página de servicio no disponible.

**No entra:** la landing, la web de Natalia (`apps/natalia` y su sitio), los PDF, los Excel, los correos de Supabase, el programador y el script para sitios externos (`static/booking/embed-v1.*`, que usa la paleta de la integración).

**Excepciones deliberadas dentro de la app:**
- **Visor de imágenes clínicas:** siempre oscuro, porque las imágenes médicas se leen con entorno oscuro para conservar el contraste de las zonas oscuras.
- **Apariencia de Natalia** (`BookingAppearance.svelte`): sigue su `color_mode`. Debe verse igual que antes en sus dos modos.
- **Colores ajenos a la paleta:** el logo de Google y otras marcas de terceros conservan sus colores oficiales.

## 6. Diseño técnico

### 6.1 Variables

- Valores claros en `:root` y oscuros en `:root.dark`. El modo automático repite el bloque oscuro dentro de `@media (prefers-color-scheme: dark)` para la clase `theme-system`. Una prueba exige que ambos bloques oscuros sean idénticos.
- Las variables que Tailwind usa con opacidad (por ejemplo `bg-surface/95`) tienen además su versión en canales (`--surface-rgb: 255 255 255`).
- **Regla de migración: el oscuro actual es la especificación.** Cada color escrito a mano se reemplaza por la variable cuyo valor oscuro sea el mismo, o perceptualmente indistinguible: diferencia ΔE2000 de 2 o menos. Las únicas excepciones son las cuatro correcciones de 2.6 y la unificación de azules aprobada, cada una con su diferencia medida.
- El valor claro de cada variable sale de la paleta de 2.6. Para los niveles intermedios se respeta el orden de énfasis del oscuro y se exige el contraste mínimo.

### 6.2 Preferencia

- **Cookie `cita-theme`**, con los valores `light`, `dark` o `system`. Ruta `/`, un año, `SameSite=Lax` y `Secure` en HTTPS. No es `HttpOnly`, porque el selector la escribe; no contiene datos personales. La política de privacidad ya menciona las «preferencias de tema».
- **El servidor** (`hooks.server.ts`, `transformPageChunk`) pone en `<html>` la clase `dark` (oscuro), `theme-system` (automático) o ninguna (claro), y el `theme-color` correspondiente.
- **Sin cookie o con un valor inválido:** claro.
- **Automático** sigue `prefers-color-scheme` sólo con CSS, también si el sistema cambia mientras la página está abierta.
- **El selector** aplica el cambio al instante, sin recargar, y escribe la cookie.

### 6.3 Natalia

Dentro de `.booking-natalia` se definen todas las variables que usan los componentes de reserva, con su paleta en sus dos modos. Sus reglas por nombre de clase se trasladan a las clases nuevas. Criterio: capturas de su reserva antes y después iguales.

### 6.4 Prueba guardiana

`scripts/lib/theme-colors.test.mjs` (entra sola en la verificación rápida de CI):
- recorre `apps/web/src`;
- falla ante cualquier clase de paleta (`text-white`, `bg-neutral-100`, `border-primary-500`…), clase arbitraria con color (`bg-[#…]`) o literal de color en estilos fuera de las variables y de la lista de excepciones;
- cada excepción lleva su motivo;
- incluye casos adversarios que demuestran que detecta lo que prohíbe.

### 6.5 Pruebas que cambian de contrato

Cinco pruebas de navegador exigían hoy el tema único: la clase `dark` y `color-scheme: dark` aunque el navegador prefiriera claro. Son `patient-structure-ux`, `roles-agenda-regression`, `booking-embed`, `appointment-deposits` y `appointment-slot-releases`. Pasan a exigir el contrato nuevo. Es un cambio de requisito documentado, no una prueba ajustada para que pase.

## 7. Criterios de aceptación

| # | Criterio | Evidencia |
|---|---|---|
| C1 | Sin preferencia guardada, toda página HTML sale del servidor en claro (sin clase `dark`, `color-scheme: light`), aunque el navegador prefiera oscuro. | Prueba de navegador y unitaria del servidor. |
| C2 | Con `cita-theme=dark` sale en oscuro desde el servidor. Con `system` sigue al dispositivo sin JavaScript, también en vivo. Un valor inválido da claro. Sin parpadeo. | Pruebas de navegador con los tres valores. |
| C3 | Selector accesible en el menú de cuenta, en computadora y en celular: grupo de opciones con teclado; aplica al instante y persiste. | Prueba de navegador y capturas. |
| C4 | Toda ruta que el entorno de prueba puede abrir funciona en claro y en oscuro: sin violaciones de contraste de axe (`color-contrast`) y sin problemas de `layoutIssues`, al menos a 390 y 1280 px. | Matriz nueva de navegador y capturas. |
| C5 | Cero colores fijos fuera de las variables y de las excepciones justificadas. | Prueba guardiana con casos adversarios. |
| C6 | El oscuro conserva cada color con ΔE2000 de 2 o menos, salvo las excepciones aprobadas, listadas con su ΔE. | Recibo de la herramienta y capturas de antes y después. |
| C7 | La reserva de Natalia se ve igual, en sus dos modos, en computadora y en celular. | Capturas de antes y después. |
| C8 | Visor clínico oscuro en los dos modos. PDF, Excel y script externo sin cambios. | Prueba y archivos sin modificar. |
| C9 | Los pares de la paleta cumplen WCAG 2.2: AA en todo y AAA en el texto principal, medidos sobre los valores reales de `app.css`. | Prueba automática. |
| C10 | Las cinco pruebas de contrato están actualizadas y hay pruebas nuevas de la preferencia. | CI. |
| C11 | CI aprobado sobre la candidata exacta: `fast`, paquete y navegador completo; `svelte-check` con 0 errores y 0 advertencias. | Corridas. |
| C12 | Producción sirve la candidata: `verify-production-release.mjs` aprobado, los dos orígenes con esa revisión y revisión visual de claro y oscuro en producción. Vuelta atrás documentada. | Recibos. |
| C13 | Documentación coherente: DESIGN.md (regla de dos modos), `.impeccable/design.json`, registro, traspaso, `publicacion-y-reversion.md`, AGENTS.md, README y pendientes. | Revisión final. |

## 8. Etapas, en este orden

- **E0. Documentación de la campaña:** este plan, registro, traspaso, sección en AGENTS.md y entrada en pendientes.
- **E1. Herramientas:**
  - inventario de colores;
  - prueba guardiana, primero en modo informe;
  - medición inicial con recibo;
  - capturas de referencia: las 239 de la corrida de navegador de V11f (41368132842) ya cubren el oscuro y la reserva de Natalia.
- **E2. Base:**
  - variables claras y oscuras;
  - Tailwind;
  - preferencia: cookie, servidor y modo automático;
  - selector;
  - `theme-color`;
  - página de servicio no disponible;
  - pruebas unitarias.
- **E3. Migración por secciones:**
  - estructura común;
  - agenda y turnos;
  - pacientes y ficha;
  - equipo, configuración y maestro;
  - páginas públicas, con Natalia;
  - el resto.

  En cada sección: cambio mecánico revisado, revisión manual, revisión visual local en modo demostración y `svelte-check`.
- **E4. Pruebas de navegador:** las cinco de contrato y la matriz nueva de modos con contraste.
- **E5. Candidata y CI:**
  - `fast`, paquete y navegador completo;
  - revisión de capturas: oscuro antes y después, y Natalia antes y después.
- **E6. Producción:** publicación del paquete probado, comprobaciones, certificado y puntero de la fuente.
- **E7. Cierre:** DESIGN.md, `design.json`, guías, AGENTS.md, README, pendientes, auditoría contra la sección 7 e informe.

## 9. Verificación

- **En esta máquina** (pocos recursos): sólo pruebas unitarias puntuales, de a una, y un único servidor en modo demostración (`DEMO_MODE=true`) para mirar pantallas. Las suites, la compilación y el navegador corren en CI.
- **En CI** (repositorio auxiliar público `Juan4787/cita-suite-verificacion`): candidatas armadas con `.verification/senas-avisos-20261029/build.sh` sobre V11f. Nunca llevan datos personales.
- **Tolerancias:**
  - ΔE2000 de 2 o menos para conservar el oscuro;
  - contraste según WCAG 2.2 medido por axe en el navegador real;
  - ningún «verde» se fabrica relajando una condición. Si un verificador tiene una condición obsoleta, se corrige con su motivo documentado.

## 10. Publicación y recuperación

- **Publicación:** `NODE_OPTIONS=--max-old-space-size=192 node scripts/deploy-production-workers.mjs app "<carpeta del paquete>"` con el paquete de CI de la candidata aprobada. Después `node scripts/verify-production-release.mjs "<carpeta del paquete>"` y lectura de `/_app/version.json` en los dos orígenes.
- **Sin migraciones de base:** el cambio es sólo de interfaz. La vuelta atrás no necesita pasos de datos; V11f ignora la cookie nueva.
- **Vuelta atrás:** desde `apps/web`, `npx wrangler rollback 986cf666-ae09-423b-ae05-1928007dccde --name app --message "<motivo>" --yes`. Esa es la versión vigente antes de esta campaña: V11f con el cliente nuevo de Google Calendar. **No** volver a `59f81e89…`, que restauraría el cliente anterior de Calendar.

## 11. Riesgos y cómo se controlan

| Riesgo | Control |
|---|---|
| Cambiar la reserva de Natalia, la única clienta real | Variables definidas en su ámbito, sus reglas trasladadas y capturas de antes y después. |
| Contraste insuficiente por un reemplazo mecánico equivocado | axe en todas las rutas y en los dos modos, más revisión manual de cada archivo. |
| Deriva del oscuro | ΔE medido por la herramienta y capturas comparadas. |
| Parpadeo del modo equivocado | El servidor arma la página en el modo elegido; el automático es sólo CSS. |
| Memoria de la máquina | Todo secuencial; lo pesado, en CI. |
| Volumen (unos 3.500 usos) | Etapas, traspaso actualizado y prueba guardiana que mide lo que falta. |

## 12. Ajustes posteriores

(Esta sección sólo crece. Cada ajuste lleva fecha, motivo y lo que reemplaza.)

### 12.1 Fidelidad del oscuro por niveles y correcciones adicionales de accesibilidad (2 de noviembre, 04:50 UTC)

**Motivo:** la medición del oscuro actual (`.verification/modo-claro-20261102/distancias-oscuro.py`) mostró que los niveles de texto translúcido (blanco al 85 %, 80 %, 75 %…) difieren entre sí y de las tres variables de texto existentes entre 3 y 26 de ΔE2000. Unificarlos en pocas variables cambiaría el oscuro de forma visible, contra el pedido.

**Decisión:**
1. **Cada color que hoy se ve en oscuro tiene su variable.** Sólo se une a otra si la diferencia es ΔE2000 de 2 o menos.
   - Resultado: 251 variables (26 existentes y 225 nuevas), con nombres por función y nivel (`text-fg-55` es «tinta al 55 %»; `bg-danger-500-15` es «rojo 500 al 15 %»).
   - Su valor claro sale de la paleta aprobada según la función (sección 6.1).
   - Herramienta: `generar-variables.mjs`.
2. **Unificación de azules:**
   - `#0f1f36`, `#122641`, `#13243d` y `#101f35` quedan a ΔE de 1,35 a 1,91 de las variables existentes;
   - `#152642` (2,66) y `#1f3554` (3,81) superan 2 y se unifican igual, porque así se aprobó; quedan documentados;
   - los azules de paso del puntero `#1b2d4b`, `#19354f` y `#1f2b45` no estaban en la aprobación y conservan variable propia.
3. **Correcciones adicionales del oscuro.** Todo texto del oscuro que no cumpla 4,5:1, y todo indicador no textual que no cumpla 3:1, se corrige a la variable accesible más cercana. Cada caso queda listado en el registro con su contraste antes y después.
   - Es el mismo criterio de las cuatro correcciones aprobadas en 2.6. Reemplaza la frase «todo lo demás del oscuro queda igual» sólo para esos casos.
   - Los íconos marcados como decorativos (`aria-hidden`) y los controles deshabilitados quedan exentos, como establece WCAG.
4. **Pastillas invariables.** Los fondos claros sólidos y las tintas oscuras que hoy ya se ven igual en oscuro (19 casos, por ejemplo la insignia de `Timeline` o el botón de Google) quedan iguales en los dos modos.

### 12.2 Recorrido completo y medición del peor caso (2 de noviembre, 13:55 UTC)

**Motivo:** el navegador de la candidata 2 (corrida 41410132980) mostró tres huecos:
- **textos bajo el mínimo** que ninguna guardia estática veía:
  - una opacidad sobre la tarjeta del día sin turnos;
  - texto pintado con el violeta de íconos;
- **un recorrido incompleto:** faltaban rutas y estados del criterio C4;
- **nodos que axe deja sin decidir,** sobre todo textos sobre los degradados suaves de tarjetas y cabeceras. No se contaban como aprobados, pero tampoco se medían.

Detalle en el registro, sección E6.

**Decisión:**
1. **Correcciones de contraste,** con el criterio de 12.1, punto 3:
   - el texto no se pinta con `--accent` sino con `--accent-text`;
   - el día sin turnos se atenúa con colores de texto, no con opacidad;
   - `--on-accent-muted` oscuro pasa de blanco al 72 % a blanco al 88 %.

   Cada caso queda en el registro con su contraste antes y después.
2. **Correcciones de diseño fuera del color,** halladas por el mismo recorrido con la regla `layoutIssues` del proyecto. Ya existían en V11f y son chicas:
   - «Ver como paciente» no se parte en dos renglones;
   - los separadores «·» quedan unidos a lo que sigue;
   - el ejemplo del campo de dirección entra a 390 px.
3. **Cobertura del criterio C4:** el recorrido abre toda ruta con página que el entorno de prueba puede abrir, incluidas las que redirigen, las páginas de error, el panel maestro (con su usuario sintético) y la reserva embebida.
   - Suma los estados que no son rutas: menús de cuenta y de Configuración, asistente de turno nuevo, alta rápida de paciente y campo de dirección vacío.
   - Los diálogos y menús se miden en su propio alcance.
4. **Medición del peor caso:** lo que axe no decide se mide contra cada combinación de paradas de los degradados de sus ancestros, con colores y opacidades compuestos. El mínimo es 4,5:1, o 3:1 en texto grande.
   - Lo que no se puede medir hace fallar la prueba, salvo los campos vacíos, que no tienen texto.
   - Una prueba sintética demuestra que la medición detecta fallas.
5. **Guardia nueva:** todo `color:` de CSS lee una variable probada como texto por los pares de la paleta, con la reserva de Natalia como excepción por su paleta congelada.

**Reemplaza:** nada del texto aprobado. Precisa cómo se demuestra el criterio C4 y amplía la lista de correcciones de 12.1.

### 12.3 El lienzo de la página de Natalia sigue su modo (2 de noviembre, 14:05 UTC)

**Motivo:** en V11f, el documento de su reserva era el de la app oscura, con fondo azul marino detrás de su papel y esquema oscuro. Con el claro predeterminado, ese lienzo pasaría a gris claro con esquema claro, aunque ella esté en oscuro. Su papel cubre la ventana, así que el cambio no se ve en una captura. Sí se ve al estirar la página en el celular, y en la barra de desplazamiento de la página.

**Decisión:** cuando su página se abre sola, como la abre su web, el lienzo y el esquema del documento siguen su modo, con el color de su papel.
- Lo que ella diseñó no cambia.
- Lo único distinto respecto de V11f es ese lienzo: antes era del azul de la app y ahora es de su papel, en sus dos modos.
- Dentro de un marco, el lienzo queda como el de la página que la contiene.

**Reemplaza:** precisa la sección 6.3 («su apariencia sigue el `color_mode` de su web»). El criterio C7 se cumple con su página idéntica, y con el lienzo coherente con su modo en lugar del azul de la app oscura.

### 12.4 Las capas que flotan sobre contenido conservan su opacidad exacta (2 de noviembre, 14:20 UTC)

**Motivo:** la comparación de capturas de la candidata 3 con V11f mostró que, en oscuro, a través de la barra superior fija se leía más el contenido que pasa por detrás.
- **La causa es el método de unificación (12.1):** midió la distancia ΔE2000 de cada color translúcido compuesto sobre el fondo de página.
  - Eso vale para un tinte sobre una superficie lisa.
  - No vale para una capa que flota sobre contenido variable.
- **Lo que pasó:** `[#0f1f36]/95` (barra superior) y `[#0b1d32]/95` (barra inferior del celular) se unieron con `[#13243d]/70`.
  - Sobre el fondo liso, la diferencia era ΔE de 0,44 y 1,57.
  - Con texto blanco o un botón violeta pasando por detrás, llegaba a ΔE 20 y 11.
- **Control hecho:**
  - se comparó con V11f la opacidad de los 208 usos de fondos translúcidos de la app;
  - salieron 11 diferencias: las dos barras, 3 falsos positivos de condiciones de dos ramas y 6 tintes sobre fondos lisos, con ΔE de 0,54 a 1,99 sobre su fondo real;
  - el menú de los controles con estilo y la cortina de los diálogos conservan su valor exacto.

**Decisión:**
- Las dos barras fijas tienen variables propias, con la opacidad y el color exactos de V11f en oscuro y blanco al 95 % en claro.
- La prueba del selector exige esos valores en los dos modos.
- En adelante, una capa que flota sobre contenido no se une a otro color aunque su ΔE sobre el fondo liso sea bajo.

**Reemplaza:** precisa el criterio de unificación de 12.1 para las capas que flotan sobre contenido.

### 12.5 Fondo general apenas más cálido (2 de noviembre, 15:15 UTC)

**Pedido literal de Juan, después de ver V12:** «Lo que mejoraria del modo claro: el fondo gris general podria ser apenas mas calido o neutro».

**Medición** (`.verification/modo-claro-20261102/fondo-calido/`):
- **El fondo de V12, `#f5f6f8`,** es un gris levemente azulado: tono 265° y croma 0,0029 en OKLCH.
- **Se compararon cuatro variantes en la app,** a tamaño real:
  - la actual;
  - `#f6f5f3`, cálido;
  - `#f5f5f5`, neutro;
  - `#f6f5f3` con los demás grises internos neutralizados.
- **La diferencia de los grises internos casi no se nota.** Llevarlos al tono cálido con su intensidad actual vuelve beige a los bordes (por ejemplo, `#d8d4cc`), que es mucho más que «apenas».

**Decisión:** el fondo general pasa a **`#f6f5f3`**.
- Tiene la misma intensidad de tinte que el anterior (croma 0,0029), pero cálida (tono 85°) en lugar de azulada. Es un gris que apenas se entibia, lejos del papel beige de Natalia (`#f3eee5`).
- Los demás grises no cambian.
- Contraste de los textos sobre el fondo nuevo:

  | Texto | Contraste |
  |---|---|
  | Principal | 15,86:1 |
  | Secundario | 7,06:1 |
  | Terciario | 4,95:1 |
  | Violeta | 8,56:1 |

  Todos cumplen sus mínimos y los controla `theme-palette.test.mjs`.
- La barra del navegador del modo claro y la página de servicio no disponible usan el mismo valor.

**Reemplaza:** el valor claro de `--bg` de la paleta aprobada (2.6). El oscuro no cambia.
