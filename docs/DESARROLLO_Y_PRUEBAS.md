# Desarrollo y pruebas

## Antes de editar

1. Conserva los IDs de enums: partidas y `.tres` los usan como identidad persistente.
2. Extiende un resolvedor (`BattleManager`, `ItemUseResolver`, `EvolutionSystem`) antes de poner reglas de juego en una escena.
3. Si un recurso nuevo necesita clase nueva, crea la clase antes de asignarla desde el inspector.

## Pruebas manuales recomendadas

### Overworld

- Entrar y salir de mapas conectados y mediante `warp`.
- Probar tiles de distinto suelo, altura, rampa y colisión tras un warp.
- Interactuar con NPC independientes que usen sprites y scripts distintos.
- Probar texto continuo, multichoice, `compare`, flags, `checkitem`, movimiento y guardado.

### Guardado

- Guardar en una ranura vacía y reemplazar una existente.
- Cargar y comprobar posición, mapa, dinero, flags, mochila, Pokédex y datos del equipo.

### Combate

- Elegir movimientos, agotar PP, cambiar Pokémon y finalizar combate.
- Probar clima, estados, hazards, habilidades de contacto y evolución por nivel.
- Usar un objeto soportado y confirmar que solo se consume si tuvo efecto.

## Límites conocidos

El catálogo contiene muchas mecánicas, pero no todos los `MoveEffect`, objetos equipados, bayas, habilidades o formatos dobles tienen implementación. Comprueba el resolvedor correspondiente antes de considerar una mecánica jugable.

La batalla actual es individual. La mochila ya permite escoger y usar objetos
desde la UI de combate; captura, IA avanzada, combates dobles,
teracristalización, megaevolución y reglas especiales de generaciones recientes
requieren integración adicional.

## Comprobación de scripts

Abre el proyecto en Godot y revisa Output después de modificar clases, recursos o enums. El escaneo debe terminar sin `Parser Error` ni `Compilation failed`. Un aviso de mecánica sin regla es una señal para implementarla, no para ocultarla.


## Revisar contenido

**Proyecto → Herramientas → 🔎 Revisar contenido** revisa el juego sin
ejecutarlo y muestra la lista en la pestaña Salida:

- Flags que se comprueban pero nada activa (normalmente una errata; sugiere la
  flag parecida que sí existe) y flags que se activan pero nunca se comprueban.
- Errores de los archivos de `res://game/trainers/` y `trainerbattle` que
  apuntan a un entrenador que no existe.
- `warp`, warps de mapa y conexiones que apuntan a un `MAPSEC` sin escena, y
  mapas con el mismo `MAPSEC`.

Pásalo antes de subir cambios de contenido.
