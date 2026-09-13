# Overworld, mapas y contenido de campo

## MapAttributes

El nodo raíz de una escena de mapa usa `MapAttributes`. Configura `map_name`, `map_id_section`, `map_region`, tamaño, conexiones cardinales, música, clima, fondo de combate, flags de interior, encuentros y `map_scripts`.

El campo legacy `map_script` se conserva para mapas existentes y se ejecuta en `ON_LOAD`. Para contenido nuevo usa `map_scripts`.

## NPC

Las instancias de NPC usan `CharacterNpc` como datos y un `Npc`/`CharacterController` como nodo. Asigna un `npc_id` único por mapa si quieres referenciarlo desde scripts:

```text
applymovement GUARDIA_01 "face left; walk down 2"
```

El jugador tiene `PLAYER_ID = LOCALID_PLAYER`, por lo que también puede ser objetivo de `applymovement`. El controlador adopta el nivel y altura del suelo para mantener orden visual, colisión e interacción.

## Warps y conexiones

```text
warp MAPSEC_PRADO_NATAL 7 11
```

El comando hace fundido, carga el destino, reposiciona al jugador, reconstruye datos de tiles y colisiones, actualiza suelo/altura, clima y música, y ejecuta scripts de entrada. Las coordenadas son casillas, no píxeles.

## Tiles y comportamiento

`TileBehaviourLayer` y `TileBehavioursManager` interpretan los custom data layers del tileset. Los comportamientos de suelo, altura, rampas y colisiones deben vivir en el gestor para que jugador, NPC y seguidor compartan reglas.

## Clima y encuentros

El clima visual usa `WeatherEffect.WeatherID` y se cambia desde `WeatherManager` o `weather` en un script. `DnsManager` controla hora ambiental y `MusicManager` la música.

`WildEncounterTable` se asigna a `grass_encounters`. Cada `WildEncounterEntry` define especie, rango de nivel y peso; el sistema de encuentro prepara el combate a través de `BattleSession`. `encounter_rate` es el porcentaje exacto por paso completado en hierba; el valor predeterminado es 12 para una ruta normal y se puede ajustar por mapa.

## Menú de depuración

Pulsa `buttonX + buttonSelect`. Si no existen esas acciones separadas, usa `buttonB + buttonSelected`. Permite probar sprite de jugador, PP, Pokédex, clima, warps, objetos, flags y guardado. Es una herramienta interna, no lógica de juego final.
