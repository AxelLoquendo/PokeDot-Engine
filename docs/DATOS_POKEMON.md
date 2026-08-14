# Datos de Pokémon, movimientos, habilidades e ítems

## Regla principal

Los datos de catálogo son recursos `.tres` inmutables durante la partida. El estado variable vive en recursos de partida.

| Catálogo | Estado de partida |
| --- | --- |
| `PokemonDataStruct` | `PokemonInstance` |
| `MoveData` | `PokemonMoveSlot` (PP actuales) |
| `AbilityData` | `ability_id` de `PokemonInstance` |
| `ItemData` | `Bag` y `held_item` |

## Especies

Guarda un `PokemonDataStruct` dentro de `data_core/pokemon/resources/<generación>/`.

Campos esenciales: `species_id`, nombre, estadísticas base, tipos, ratio de captura, crecimiento, habilidades, learnset y evoluciones. `SpeciesDatabase` carga los recursos de forma recursiva y rechaza IDs duplicados o datos inválidos.

## Movimientos

Los `.tres` de `MoveData` van en `data_core/move/resources/<generación>/`. Deben tener ID, nombre, descripción, tipo, categoría, objetivo, PP, precisión, poder y efecto válidos. `MoveDatabase` carga y valida todo el árbol.

`PokemonMoveSlot` guarda el ID y sus PP actuales. No modifiques los PP de `MoveData`: ese recurso es compartido por todas las criaturas.

## Habilidades

Los `.tres` de `AbilityData` van en `data_core/ability/resources/<generación>/`. Una habilidad puede apuntar a una subclase de `AbilityEffect` para reaccionar a eventos de combate; las banderas `triggers_on_*` declaran cuándo debe llamarse.

## Ítems

Crea los `.tres` de `ItemData` en `data_core/items/resources/<bolsillo>/`. `ItemDatabase` los descubre de forma recursiva, valida campos y detecta IDs duplicados.

`ItemData` requiere al menos ID distinto de `ITEM_NONE`, nombre singular/plural, descripción, precio no negativo y bolsillo/tipo válidos.

`Bag` guarda cantidades por ID y expone:

```gdscript
player_data.bag.add_item(Items.ItemId.ITEM_POTION, 2)
player_data.bag.remove_item(Items.ItemId.ITEM_POTION, 1)
player_data.bag.has_item(Items.ItemId.ITEM_POTION)
```

## Pokémon de partida

`PokemonInstance.create(Species.SpeciesID.SPECIES_BULBASAUR, 5)` crea una instancia, elige la habilidad primaria y aprende los movimientos de nivel aplicables. `CharacterPlayer.party` admite hasta seis y `CharacterPlayer.bag` es la mochila.

Mochila, equipo, Pokémon, movimientos y PP se serializan dentro de las ranuras de `SaveManager`.

## Scripts de campo

Para dar objetos desde un `.txt`:

```text
giveitem ITEM_POTION 2
# También admite: giveitem POTION 2
```

Esto añade el objeto a `CharacterPlayer.bag`. Los efectos de uso de ítems y el combate aún requieren sus sistemas específicos.
