---
name: Cita Suite
description: Sistema oscuro de trabajo para consultorios.
colors:
  bg: "#0b1626"
  surface: "#0b1d32"
  surface-2: "#0f2238"
  surface-raised: "#102842"
  border: "rgba(255, 255, 255, 0.1)"
  border-strong: "#244062"
  text: "#eaf1ff"
  text-muted: "rgba(234, 241, 255, 0.64)"
  text-subtle: "rgba(234, 241, 255, 0.42)"
  accent: "#8b5cf6"
  accent-strong: "#7c3aed"
  accent-press: "#6d28d9"
  accent-soft: "rgba(124, 58, 237, 0.18)"
  accent-text: "#c4b5fd"
  ring: "rgba(139, 92, 246, 0.65)"
  success: "#34d399"
  success-soft: "rgba(52, 211, 153, 0.14)"
  success-text: "#a7f3d0"
  warning: "#fbbf24"
  warning-soft: "rgba(251, 191, 36, 0.14)"
  warning-text: "#fde68a"
  danger: "#f87171"
  danger-strong: "#dc2626"
  danger-press: "#b91c1c"
  danger-soft: "rgba(248, 113, 113, 0.13)"
  danger-text: "#fecaca"
  on-accent: "#ffffff"
  field: "rgba(255, 255, 255, 0.045)"
typography:
  headline:
    fontFamily: "Inter, system-ui, -apple-system, sans-serif"
    fontSize: "clamp(1.7rem, 2.4vw, 2.5rem)"
    fontWeight: 700
    lineHeight: 1.1
    letterSpacing: "-0.01em"
  title:
    fontFamily: "Inter, system-ui, -apple-system, sans-serif"
    fontSize: "1.15rem"
    fontWeight: 700
    letterSpacing: "-0.01em"
  body:
    fontFamily: "Inter, system-ui, -apple-system, sans-serif"
    fontSize: "17px"
  supporting:
    fontFamily: "Inter, system-ui, -apple-system, sans-serif"
    fontSize: "0.95rem"
    lineHeight: 1.55
  label:
    fontFamily: "Inter, system-ui, -apple-system, sans-serif"
    fontSize: "0.9rem"
    fontWeight: 700
  button:
    fontFamily: "Inter, system-ui, -apple-system, sans-serif"
    fontSize: "0.95rem"
    fontWeight: 700
    lineHeight: 1
  badge:
    fontFamily: "Inter, system-ui, -apple-system, sans-serif"
    fontSize: "0.78rem"
    fontWeight: 700
rounded:
  sm: "0.85rem"
  md: "1rem"
  lg: "1.4rem"
  xl: "1.75rem"
  menu: "0.75rem"
  pill: "999px"
spacing:
  xs: "0.5rem"
  sm: "0.75rem"
  md: "1rem"
  lg: "1.25rem"
  xl: "1.5rem"
components:
  button-primary:
    backgroundColor: "{colors.accent-strong}"
    textColor: "{colors.on-accent}"
    typography: "{typography.button}"
    rounded: "{rounded.md}"
    padding: "0.7rem 1.25rem"
  button-primary-hover:
    backgroundColor: "{colors.accent-press}"
  button-secondary:
    backgroundColor: "rgba(255, 255, 255, 0.05)"
    textColor: "{colors.text}"
    typography: "{typography.button}"
    rounded: "{rounded.md}"
    padding: "0.7rem 1.25rem"
  button-danger:
    backgroundColor: "{colors.danger-strong}"
    textColor: "{colors.on-accent}"
    typography: "{typography.button}"
    rounded: "{rounded.md}"
    padding: "0.7rem 1.25rem"
  input:
    backgroundColor: "{colors.field}"
    textColor: "{colors.text}"
    rounded: "{rounded.md}"
    padding: "0.75rem 1rem"
  card:
    textColor: "{colors.text}"
    rounded: "{rounded.lg}"
    padding: "1.25rem"
  badge-success:
    backgroundColor: "{colors.success-soft}"
    textColor: "{colors.success-text}"
    typography: "{typography.badge}"
    rounded: "{rounded.pill}"
    padding: "0.4rem 0.8rem"
  control-menu:
    backgroundColor: "{colors.surface-raised}"
    textColor: "{colors.text}"
    rounded: "{rounded.menu}"
    padding: "0.4rem"
  confirm-dialog:
    backgroundColor: "{colors.surface-raised}"
    textColor: "{colors.text}"
    rounded: "{rounded.md}"
    padding: "1.5rem"
---

# Design System: Cita Suite

## Overview

**Creative North Star: "Cita Suite: claridad para trabajar"**

Se conserva la identidad existente: Inter, fondos azul oscuro y acento violeta. La precisión de los controles, la jerarquía de texto y los estados hacen reconocible el sistema. Esta frase describe el trabajo del producto; no introduce una identidad comercial nueva.

La interfaz permite encontrar una tarea y completarla con campos visibles, agrupaciones cortas y opciones secundarias progresivas. Este documento registra los estilos compartidos y los patrones implementados en configuración de reservas; no certifica una renovación de todas las páginas de la aplicación.

**Key Characteristics:**

- Una familia tipográfica para títulos, datos y controles.
- Superficies oscuras con diferencias de tono, bordes y elevación suave.
- Violeta para acciones principales, foco y selección; estados con texto propio.
- Controles consistentes, nombres cotidianos y adaptación estructural al celular.

## Colors

### Primary

El violeta de `accent` identifica foco y selección. `accent-strong` sostiene la acción principal; `accent-press` acompaña la interacción. `accent-soft` y `accent-text` permiten estados suaves legibles sobre las superficies oscuras.

### Neutral

`bg` es el fondo de la página; `surface` y `surface-2` agrupan contenido; `surface-raised` distingue menús y diálogos. `border-strong` delimita contenedores, mientras `border` separa filas y elementos secundarios. `text`, `text-muted` y `text-subtle` mantienen la jerarquía de lectura. Los valores del frontmatter conservan el formato del CSS original.

Verde comunica éxito; ámbar, advertencia o cambios pendientes; rojo, error o acción destructiva. Sus variantes suaves y de texto se usan juntas en avisos y estados. Cada estado necesita una etiqueta o mensaje además del color.

**The Estado legible Rule.** La persona debe poder reconocer un estado por su texto, sin depender sólo del color.

## Typography

**Body Font:** Inter, con los fallbacks declarados en el frontmatter. La misma familia sostiene toda la jerarquía; no hay una fuente ornamental independiente.

`headline` corresponde al título de página; `title`, a grupos de trabajo. `body` registra el tamaño base del documento. `supporting` acompaña títulos con contexto breve; `label` nombra campos; `button` y `badge` mantienen acciones y estados compactos. Los campos usan un tamaño de una unidad rem para conservar legibilidad y evitar el zoom automático en iOS.

## Layout

La página compartida apila sus grupos con una separación de `lg`. Los contenedores admiten columnas para campos relacionados y se apilan cuando falta espacio. Los valores de spacing registran medidas recurrentes del código, no una nueva escala de CSS.

Reserva online y su editor de sitios se centran con un ancho máximo de 64rem; Configuración admite 72rem. Alrededor de 640px se reorganizan cabeceras, acciones y el bloque para compartir. La navegación de preguntas se convierte en dos columnas por debajo de 480px. Enlaces largos, nombres y mensajes deben partir líneas sin ensanchar la pantalla. Estas composiciones pertenecen a sus superficies, no son una plantilla obligatoria para toda la app.

## Elevation & Depth

El sistema combina capas tonales y sombras difusas. Los contenedores existentes conservan un fondo con gradientes discretos; los menús y diálogos usan una superficie sólida elevada. La sidecar registra las sombras reales y su propósito. Los menús se muestran en la capa superior cuando existe la API de popover, con posicionamiento fijo como alternativa, para evitar recortes en formularios y diálogos.

## Shapes

Campos y botones comparten curvas suaves de `md`; tarjetas usan `lg` y las cabeceras destacadas existentes usan `xl`. Los estados compactos tienen forma de píldora. Menús y casillas tienen radios propios adecuados a su densidad. Bordes finos separan filas sin convertir cada dato en una tarjeta independiente.

## Components

### Buttons

Una acción principal violeta; acciones secundarias sobre una superficie tenue; rojo para una acción destructiva. El alto mínimo compartido es 2.75rem. Hover modifica tono y desplaza ligeramente el botón; active reduce su escala; disabled baja la opacidad y elimina elevación. Las operaciones muestran texto como “Guardando…” y bloquean acciones incompatibles mientras están pendientes.

### Cards / Containers

Tarjetas para un grupo de trabajo completo; filas y separadores para listas de tareas, sitios y preguntas. El padding pasa de `lg` a `xl` en pantallas amplias. El borde, el fondo y la sombra provienen de los tokens existentes.

### Inputs / Fields

Campos oscuros, etiquetas encima y foco visible. Error y cambios sin guardar tienen borde y mensajes propios. Selectores y fechas/meses mejoran progresivamente sus controles originales: el menú, calendario y trigger tienen acabado propio mientras la fuente conserva nombre, valor, validación y bindings. Las horas usan un campo de texto con entrada numérica y normalización al formato HH:mm, sin menú. Casillas y radios conservan su semántica nativa con dibujo propio. No ocultar la fuente hasta que su mejora esté montada.

### Navigation

Los enlaces de Configuración nombran tareas y ofrecen una línea corta de contexto. En un profesional, Perfil, Servicios y aranceles, Horarios y Preguntas al paciente mantienen una ubicación estable. La selección se distingue visualmente y, donde corresponda, con `aria-current`. El detalle de esta arquitectura pertenece a la nota de superficie.

### Menus, calendars and dialogs

Los selectores permiten teclado, búsqueda por texto y opciones deshabilitadas. Los calendarios anuncian etiqueta y valor seleccionado, incluso tras cambios de atributos; respetan límites de fecha. Escape cierra el selector y devuelve el foco. El diálogo de cambios sin guardar prioriza “Seguir editando” y ofrece “Descartar cambios”; sólo después de aceptar limpia el borrador y navega. La salida o recarga de pestaña conserva la advertencia del navegador.

## Do's and Don'ts

### Do:

- **Do** conservar Inter y los tokens compartidos del sistema oscuro existente.
- **Do** usar etiquetas visibles, foco reconocible y texto para comunicar cada estado.
- **Do** agrupar por tarea y plegar opciones secundarias después de los campos principales.
- **Do** conservar la semántica, validación y datos del formulario al mejorar sus controles.

### Don't:

- **Don't** inventar datos reales, tarifas, contactos ni promesas de marca.
- **Don't** compensar una estructura confusa con párrafos de instrucciones.
- **Don't** dejar menús, calendarios o confirmaciones interiores con acabado nativo cuando están mejorados con JavaScript.
- **Don't** convertir patrones de esta entrega en afirmaciones sobre páginas que no se revisaron.
