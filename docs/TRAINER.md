# Entrenadores

Los entrenadores se escriben en archivos de texto dentro de `res://game/trainers/`
(cualquier `.txt`, también en subcarpetas). El formato es el de
pokeemerald-expansion (`trainers.party`): una cabecera con los datos del
entrenador y después sus Pokémon en formato **Showdown**, así que un equipo
exportado desde Pokémon Showdown se puede pegar tal cual.

```text
=== TRAINER_ROCIO ===
Name: Rocío
Class: Cazabichos
Money: 160
Music: Trainer

Wurmple
Level: 4
- Tackle
- String Shot

Caterpie (M)
Level: 5
```

- Cada entrenador empieza con `=== TRAINER_ID ===`. El ID solo admite letras,
  números y `_`, y no se puede repetir entre archivos.
- La cabecera termina en la primera línea en blanco.
- Cada Pokémon es un bloque separado del siguiente por una línea en blanco.
  Máximo seis por entrenador y cuatro movimientos por Pokémon.
- Las líneas que empiezan por `#` o `//` son comentarios.

## Datos del entrenador

| Campo | Ejemplo | Efecto |
| --- | --- | --- |
| `Name` | `Name: Rocío` | Nombre en los mensajes del combate. |
| `Class` | `Class: Cazabichos` | Se muestra delante del nombre: "Cazabichos Rocío". |
| `Money` | `Money: 160` | Dinero que recibe el jugador al ganar. |
| `Music` | `Music: Gym Leader` | Música del combate: `Trainer`, `Gym Leader`, `Elite Four` o `Champion`. |
| `Double Battle` | `Double Battle: Yes` | Combate doble. Si el jugador solo tiene un Pokémon en pie, es 1 contra 2. |
| `Pic` | `Pic: res://…/rocio.png` | Se guarda, pero todavía no se muestra en combate. |

`Gender`, `Items`, `AI`, `Mugshot`, `Starting Status` y `Party Size` se aceptan
para poder pegar archivos `.party` existentes, pero aún no tienen efecto.

## Datos de cada Pokémon

La primera línea es `Apodo (Especie) (M) @ Objeto`; el apodo, el género
(`(M)` o `(F)`) y el objeto son opcionales.

| Línea | Si no se escribe |
| --- | --- |
| `Level: 50` | Nivel 100, como en Showdown (el comprobador avisa). |
| `Ability: Rough Skin` | Primera habilidad de la especie. |
| `Jolly Nature` | Serious (neutra), como en Showdown. |
| `EVs: 252 Atk / 4 SpD / 252 Spe` | Todos a 0. |
| `IVs: 0 Atk` | Todos a 31; solo cambian los que aparecen. |
| `Shiny: Yes` | No shiny. |
| `Happiness: 255` | Amistad base de la especie. |
| `Tera Type: Steel` | El tipo Tera por defecto. |
| `- Earthquake` | Los movimientos que tendría por nivel. |

Los nombres van en inglés, como los exporta Showdown (`Rotom-Wash`,
`Heavy-Duty Boots`, `Will-O-Wisp`), o como la constante del enum
(`SPECIES_ROTOM_WASH`, `ITEM_LEFTOVERS`). Las formas regionales y alternativas
se escriben con guion: `Ninetales-Alola`, `Tauros-Paldea-Aqua`.

`Ball`, `Dynamax Level`, `Gigantamax` y `Hidden Power` se ignoran por ahora.

## Combatir desde un script

```text
lock
faceplayer
ifflag TRAINER_ROCIO ya_vencida
text "¡Los bichos son lo mejor!" MSGBOX_NPC
trainerbattle TRAINER_ROCIO
compare variable last_result == true gano
text "Vuelve cuando seas más fuerte."
release
end

label gano
text "Mis bichos… ¡qué derrota!"
release
end

label ya_vencida
text "Sigo entrenando a mis bichos."
release
end
```

- `trainerbattle` espera a que termine el combate.
- Si gana el jugador, recibe el dinero, se activa la flag con el mismo nombre
  que el entrenador (`TRAINER_ROCIO`) y `last_result` vale `true`.
- Si el entrenador ya estaba derrotado no hay combate y `last_result` vale `true`.
- En un combate de entrenador no se puede huir ni capturar.
- Si el jugador pierde, `last_result` vale `false` y el script sigue: todavía
  no hay regreso al último Centro Pokémon.

## Errores

Un error de escritura no rompe el juego: ese entrenador o ese Pokémon se
descarta y el error aparece en la salida con archivo, línea y una sugerencia:

```text
res://game/trainers/entrenadores.txt:12: Especie desconocida: "Garchomps". ¿Quisiste decir SPECIES_GARCHOMP…?
```

Para revisarlos todos sin jugar usa **Proyecto → Herramientas → 🔎 Revisar
contenido** (ver [DESARROLLO_Y_PRUEBAS.md](DESARROLLO_Y_PRUEBAS.md)).
