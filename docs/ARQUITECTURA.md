# Arquitectura y autoloads

## Capas

```text
Recursos .tres / enums ──► Bases de datos ──► Estado de partida
                                             ├─ Overworld y mapas
                                             ├─ UI
                                             └─ Combate
```

- **Recursos:** definiciones reutilizables de especies, movimientos, ítems, habilidades, mapas y encuentros.
- **Estado:** `CharacterPlayer`, `PokemonInstance`, `Bag`, Pokédex, flags y `SaveManager`.
- **Presentación:** escenas de `scenes/`, que usan la lógica sin duplicarla.

## Autoloads

| Autoload | Responsabilidad |
| --- | --- |
| `SaveManager` | Ranuras, serialización y tiempo de juego. |
| `SpeciesDatabase`, `MoveDatabase`, `AbilityDatabase`, `ItemDatabase` | Índices y acceso a datos `.tres`. |
| `BattleSession` | Puente entre mapa y overlay de combate. |
| `DialogueManager` | Caja de diálogo, páginas y multichoices. |
| `TransicionManager` | Fundidos y transición visual. |
| `MusicManager` | Música de mapas y combate. |
| `WeatherManager`, `DnsManager`, `CloudsManager` | Clima, hora y presentación ambiental. |
| `TileBehavioursManager`, `EventObjects` | Comportamiento de tiles e interacción de overworld. |
| `TypeIconsDb` | Iconos de tipos para UI. |
| `DebugMenu` | Herramientas internas de pruebas. |

## Ciclos importantes

### Cargar partida

`MainMenu` selecciona una ranura → `SaveManager.request_load()` marca la carga pendiente → `GestorInicio` consume los datos y crea/restaura jugador y mapa.

### Ejecutar evento

NPC o mapa → `ScriptCmdTextFile` → `ScriptTextParser` → `ScriptRunner` → comandos con `ScriptExecutionContext`.

### Iniciar combate

Evento/encuentro → `BattleSession.preparar_*()` → overlay `battle.tscn` → `BattleManager.start_battle()` → señales hacia la UI → `BattleSession.finalizar()`.

## Convenciones

- Enum e ID son la identidad del dato; el nombre mostrado no debe usarse como clave de lógica.
- Los datos variables pertenecen a instancias y no a recursos compartidos.
- Las UIs solicitan acciones a los sistemas; no deben calcular daño, consumir objetos ni modificar flags directamente.
- Las rutas `res://` son contenido del proyecto; `user://` se reserva para partidas locales y datos de usuario.
