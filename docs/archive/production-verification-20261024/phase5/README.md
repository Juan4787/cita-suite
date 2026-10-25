# Comparación única de capacidad: fase 5

Run **40099997857**, fuente `0851de59ed7971debe2514e6d6851d142bbc5766`, ejecutado el24 de octubre13:52–14:41UTC. Protocolo previo: una comparación sin muestreo de SQL/instancia, mismos generador, volumen y umbrales. **Falló latencia:** rep2 escrituras p95=1689ms; rep3 lecturas p99=4476ms y escrituras p99=5400ms. Pública y abuso aprobaron, cero errores técnicos reportados. Conserva el fallo anterior40078561771. No demuestra causa exclusiva, capacidad Free ni aprobación de lanzamiento.

## Qué evidencia prevalece

- El JSON del generador coincide con el ZIP/digest de GitHub; los umbrales se recalcularon. Los marcadores del log son finales de fase, no comienzos exactos de sus ventanas.
- `capacity-two-control-analysis-v2-20261024.json` sustituye a la primera interpretación. V1 confundía `null===null` con continuidad de estadísticas y publicaba deltas: **esos deltas y su integridad global no quedan certificados**. Rojo local detectó la confusión; cuatro controles de la interpretación corregida aprobaron. V2 deja60deltas desconocidos, conserva cruces/superposiciones0 y no certifica delta de deadlocks. La primera carga también tenía `stats_reset:null`; se corrige su atribución acumulada sin cambiar sus bytes históricos.
- Las lecturas SQL posteriores ocurrieron el25 de octubre01:32UTC, más de10horas después del test. Incluyen actividad normal intermedia. No atribuir sus contadores a la carga ni inferir una demora de la aplicación por esa demora del operador.
- El observador terminó por su duración a14:56:42UTC, exit0/0parse. Ventana ordinaria incluida preparación:1171peticiones,617con CPU>10ms, sin atribuir esa tolerancia a un presupuesto contractual. HTTP200 no sustituye el clasificador de errores de la app. Se excluyó la ráfaga posterior del resumen ordinario.
- Limpieza25-oct01:33:2consultorios,12004pacientes,24045turnos,2dueños propios;0restos. Conteos anteriores19/121/107, Calendar1/1 y24objetos/11.599.541B restablecidos. Secreto temporalActions/local eliminado, credenciales de aplicación intactas.
- Comprobación pública25-oct01:36:130archivosapp/35Natalia exactos y70relaciones/0expuestas. Vercel conserva el despliegueGit. La sesión administrativa deCloudflare ve una cuenta ajena al destino y responde403/10000; no se cambió sesión ni se infirió nuevo estado decron/bindings. Última metadata aprobada24-oct13:36 se conserva como antecedente.

## Operadores y límites

Los `.mjs`/`.py` son copias de procedencia de los operadores originales en `.verification/`; sus importaciones relativas apuntan a ese lugar. **No ejecutarlos desde este archivo histórico ni repetir semillas, limpieza, publicación o medición ya terminadas.** Cada operador rechaza salidas existentes. CIlogsZIP, SQL completo de estadísticas y credenciales siguen privados; aquí sólo hay selección explícita saneada, bytes ySHA256. Se conservan las fallas de selectores/esquema del arnés en los recibos finales, sin repetir el generador.

Fastprincipal anterior40099372469 certificó257d928/13pasos; no es unfullrelease nuevo. El cierre documental posterior conserva las fuentesactivas y no cambia el artefacto0851. Dominio, SMTP, etiquetasSupabase, acceso administrativoCloudflare, custodia externa debackup y rendimiento de lanzamiento permanecen abiertos.
