# Datos de Pokémon, movimientos, habilidades e ítems

## Regla de separación

Los recursos de catálogo no se modifican durante una partida. El estado de una criatura concreta sí se modifica y se guarda en JSON.

| Catálogo compartido | Estado de la partida |
| --- | --- |
| `PokemonDataStruct` | `PokemonInstance` |
| `MoveData` | `PokemonMoveSlot` |
| `AbilityData` | `PokemonInstance.ability_id` |
| `ItemData` | `Bag` y `PokemonInstance.held_item` |

No cambies PP, PS ni estadísticas actuales dentro de un `.tres` de catálogo.

## Bases de datos e IDs

| Tipo | Enum | Recursos | Autoload |
| --- | --- | --- | --- |
| Especie | `Species.SpeciesID` | `data_core/pokemon/resources/` | `SpeciesDatabase` |
| Movimiento | `Moves.MoveId` | `data_core/move/resources/` | `MoveDatabase` |
| Habilidad | `AbilityId.Id` | `data_core/ability/resources/` | `AbilityDatabase` |
| Ítem | `Items.ItemId` | `data_core/items/resources/` | `ItemDatabase` |

Los índices cargan recursos de forma perezosa. Nunca repitas un ID: es un error de contenido.

## Especies, formas y equipo

Crea `PokemonDataStruct` dentro de `data_core/pokemon/resources/`. Configura ID, nombre, tipos, estadísticas base, ratio de captura, crecimiento, amistad, ratio de género, habilidades, learnset y evoluciones.

Las formas se declaran dentro de la especie con `PokemonFormData`; pueden tener `SpeciesID` propio y sobrescribir tipos, gráficos, estadísticas o evoluciones. Lo no sobrescrito se hereda de la especie base.

```gdscript
var mon := PokemonInstance.create(Species.SpeciesID.SPECIES_BULBASAUR, 5)
```

La instancia recibe experiencia de su nivel, naturaleza, género, IVs, habilidad primaria, tipo Tera y movimientos aplicables. `CharacterPlayer.party` tiene hasta seis Pokémon.

## Movimientos y habilidades

Un `MoveData` necesita ID, nombre, descripción, tipo, categoría, objetivo, PP, precisión, potencia y efecto. `effect` es el comportamiento principal; `secondary_effect` y `secondary_chance` son el comportamiento adicional. `PokemonMoveSlot` mantiene los PP actuales.

`AbilityData` es el catálogo. La lógica común de batalla está en `AbilityRuntime`; `AbilityEffect` es el punto de extensión para habilidades personalizadas.

## Ítems

`Bag` guarda cantidades por ID. Usa el punto único de la partida para aplicar un objeto:

```gdscript
var result := player_data.use_bag_item_on_pokemon(
    Items.ItemId.ITEM_POTION, player_data.party[0]
)
```

Valida la mochila, aplica el efecto y consume solo si fue útil. Soporta PS, estados, Revivir, PP y evoluciones por objeto. Vitaminas, bayas y efectos equipados que requieran una regla especial deben vivir en `ItemUseResolver` o `AbilityRuntime`, nunca en una UI.

La `BagUI` usa un selector independiente de `DialogueBox`: no duplica la caja
de diálogo de la escena. Al confirmar un objeto abre un menú contextual:

- Objetos utilizables fuera de combate: **Usar**, **Dar**, **Tirar**, **Salir**.
- Poké Balls y objetos exclusivos de combate, fuera de batalla: **Dar**,
  **Tirar**, **Salir**.
- Objetos clave: **Usar**, **Asignar**, **Salir**. El objeto asignado se guarda
  con la partida en `CharacterPlayer.registered_item`.
- Durante una batalla: **Usar**, **Salir**.

Al usar o dar un objeto de equipo, se abre la pantalla completa `PartyMenu`,
no una lista de nombres. Para restaurar PP aparece después el selector del
movimiento. **Dar** equipa el objeto al Pokémon elegido y devuelve a la mochila
el objeto equipado que tuviera.

## Evolución y persistencia

Para datos nuevos usa `EvolutionData.use_advanced_rules`, un `EvolutionTrigger` y condiciones de `EvolutionCondition`: nivel, amistad, género, hora, ítem, movimiento, equipo, mapa, región, clima, banderas o relación de estadísticas.

`EvolutionSystem.try_evolve()` solo encuentra la evolución; `PokemonInstance.apply_evolution()` cambia especie/forma, recalcula estadísticas y aprende movimientos. La serialización de `PokemonInstance` conserva forma, PS, estado, habilidad, objeto, amistad, naturaleza, IVs/EVs, movimientos, PP y procedencia.
