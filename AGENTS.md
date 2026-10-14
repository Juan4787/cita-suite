# Directivas del Proyecto y Restricciones de Entorno

## Restricciones de Rendimiento y Memoria RAM
- **Memoria RAM muy limitada:** La máquina del usuario cuenta con poca memoria RAM y se satura con extrema facilidad.
- **Prohibido el paralelismo en pruebas:** Correr tests en paralelo casi garantiza el congelamiento del sistema.

### Reglas de Ejecución:
- **Tests / Pruebas:** Ejecutar siempre en modo secuencial (`--workers=1`, `--threads=false`, `--maxWorkers=1`, etc.).
- **Procesos en segundo plano:** Evitar spawnear múltiples tareas o compilaciones concurrentes pesadas.
