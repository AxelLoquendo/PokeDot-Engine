# PokeDot Engine

Motor de RPG inspirado en Pokémon, construido en Godot. El proyecto está dividido entre datos estáticos (`.tres` y enums), estado de partida y sistemas de mundo.

## Flujo de juego

`title_screen` → `ui_main_menu` → `gestor_inicio` → mapa activo.

- **Title screen:** entrada al menú principal mediante fundido.
- **Main menu:** selección de tres ranuras, continuar y nueva partida.
- **Gestor de inicio:** crea el mapa y jugador, o restaura la partida.
- **MapManager:** carga conexiones, cambios de mapa, warps, clima y música.
- **Overworld:** movimiento por tiles, colisiones, altura, NPCs, diálogos y scripts.

## Carpetas principales

| Ruta | Contenido |
| --- | --- |
| `data_core/scripts/` | Sistemas de overworld, personaje, mapa, guardado y scripts. |
| `data_core/pokemon/` | Especies, instancias, evoluciones y learnsets. |
| `data_core/move/` | IDs, estructura, recursos y base de datos de movimientos. |
| `data_core/ability/` | IDs, efectos, recursos y base de datos de habilidades. |
| `data_core/items/` | IDs, datos, mochila, efectos y base de datos de ítems. |
| `data_core/battle/` | Base del futuro combate por turnos. |
| `game/data_core_eb/map_eb/` | Escenas de mapas y scripts `.txt` específicos. |
| `scenes/` | Escenas reutilizables de jugador, NPC, menús y diálogos. |

## Autoloads relevantes

- `SaveManager`: tres ranuras, tiempo de juego, flags, mochila y equipo Pokémon.
- `SpeciesDatabase`, `MoveDatabase`, `AbilityDatabase`, `ItemDatabase`: cargan datos `.tres`.
- `DialogueManager`: muestra diálogo y multichoices.
- `TransicionManager`: fundidos y cambio de escena.
- `WeatherManager`, `MusicManager`, `MapPopUp`: presentación del mapa.
- `TileBehavioursManager`, `EventObjects`: comportamiento de tiles e interacción.

## Estado actual

El overworld, guardado, diálogos y scripts de mapa están implementados. El núcleo de datos Pokémon está preparado para crear recursos. El combate aún es una base y no debe considerarse funcional hasta implementar acciones, cálculo de daño, estados y UI.

Consulta [SISTEMA_DE_SCRIPTS.md](SISTEMA_DE_SCRIPTS.md) para eventos y scripts `.txt`, y [DATOS_POKEMON.md](DATOS_POKEMON.md) para crear recursos de juego.
