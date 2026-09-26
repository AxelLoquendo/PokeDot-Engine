# PokeDot Engine — documentación

Motor de RPG inspirado en Pokémon, construido con Godot 4.7. El proyecto separa los recursos de catálogo (`.tres`), el estado mutable de la partida y la lógica de escenas.

## Recorrido de juego

```text
Title Screen → Main Menu → GestorInicio → mapa activo
									  ├─ scripts / diálogos / NPC
									  ├─ menús de pausa, mochila, equipo y dex
									  └─ combate como overlay → regreso al mapa
```

`SaveManager` conserva tres ranuras. Una partida contiene jugador, posición, mapa, tiempo jugado, banderas, mochila, equipo Pokémon y Pokédex.

## Guías

| Documento | Para qué sirve |
| --- | --- |
| [ARQUITECTURA.md](ARQUITECTURA.md) | Mapa de carpetas, autoloads y responsabilidades. |
| [OVERWORLD_Y_MAPAS.md](OVERWORLD_Y_MAPAS.md) | Crear mapas, NPC, warps, tiles, clima y encuentros. |
| [SISTEMA_DE_SCRIPTS.md](SISTEMA_DE_SCRIPTS.md) | Lenguaje `.txt` para NPC y scripts de mapa. |
| [DATOS_POKEMON.md](DATOS_POKEMON.md) | Crear especies, formas, movimientos, habilidades e ítems. |
| [COMBATE_Y_EVOLUCIONES.md](COMBATE_Y_EVOLUCIONES.md) | Flujo de combate, evolución y uso de objetos. |
| [TRAINER.md](TRAINER.md) | Definir entrenadores en texto (formato Showdown) y combatir con `trainerbattle`. |
| [DESARROLLO_Y_PRUEBAS.md](DESARROLLO_Y_PRUEBAS.md) | Convenciones, depuración y límites actuales. |

## Carpetas principales

| Ruta | Contenido |
| --- | --- |
| `data_core/scripts/` | Overworld, personajes, mapas, diálogo, guardado y scripts. |
| `data_core/pokemon/` | Especies, instancias, formas, experiencia y evolución. |
| `data_core/move/`, `ability/`, `items/` | Enums, recursos `.tres`, índices y bases de datos. |
| `data_core/battle/` | Resolución de turnos, daño, estados, campo y habilidades. |
| `data_core/map/` | Encuentros salvajes y datos de mapa. |
| `scenes/` | Escenas de UI, jugador, NPC, menús y combate. |
| `game/` | Contenido del juego: escenas de mapas, scripts concretos y entrenadores (`game/trainers/`). |

## Estado de los sistemas

El overworld, los mapas, diálogos, guardado, datos Pokémon y combate simple por turnos están conectados. Algunos efectos particulares de movimientos, objetos equipados y habilidades todavía requieren reglas específicas; consulta la guía de combate antes de asumir que una mecánica de generaciones recientes ya funciona.
