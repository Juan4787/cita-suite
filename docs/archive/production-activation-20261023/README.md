# Producción: checkpoint del 23 de octubre de 2026

Este archivo conserva la activación, el fallo real de autenticación, su corrección y la observación posterior. El [checkpoint](checkpoint.json) identifica versiones, alcance y pendientes; el [manifiesto](manifest.json) contiene origen, tamaño y SHA-256 de cada copia. Las observaciones34 son un prefijo consistente de la corrida que sigue activa, no su recibo final.

La aplicación probada corresponde a478c096 y release39901784288. El commit3ebb44a conserva cinco correcciones de herramientas operativas posteriores, aprobadas por140 pruebas Node locales secuenciales; no es otro binario de app con CI completo. Los dos401 previos siguen siendo evidencia fallida. La ventana rutinaria posterior distingue éxito HTTP/presupuesto, CPU Free incumplida, calendario sin configuración y mantenimiento/dispositivo pendientes. No acredita entrega en una cola vacía.

No se incluyen dumps, archivos clínicos, configuración privada ni valores de credenciales. El recibo del respaldo sólo contiene comprobaciones y huellas. Los datos de las pruebas negativas son sintéticos. Para reproducir el clasificador sobre este checkpoint:

```bash
python3 scheduler-observation-report-20261023.py observer34-jobs-checkpoint.jsonl observer34-live-checkpoint.json resultado-nuevo.json
python3 scheduler-observation-report-20261023.test.py
```

Ejecutar esos comandos desde esta carpeta. El observador MJS se archiva para auditar su fuente; para operarlo debe copiarse de vuelta a su ubicación original.verification/observe-production-20261023.mjs, desde la raíz y con las bibliotecas operativas de3ebb44a. Usa un solo Wrangler, sin escribir eventos crudos, y no debe iniciarse junto a otro tail. No repetir despliegues o semillas para reproducir una lectura de evidencia.
