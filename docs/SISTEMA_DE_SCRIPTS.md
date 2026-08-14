# Sistema de scripts de campo

Los NPC y los mapas ejecutan archivos `.txt`. Cada línea contiene un comando.
Las líneas vacías, las que empiezan por `#` y las que empiezan por `//` se ignoran.
Los textos o argumentos que contengan espacios deben escribirse entre comillas.

```text
text "¡Hola, mundo!"
text "Este mensaje es la segunda página."
end
```

## Diálogo

`text "mensaje"` muestra texto. Varios `text` seguidos forman páginas continuas de la misma caja.

```text
text "Bienvenido al Prado Natal." MSGBOX_NPC
text "Lee los carteles cuando explores."
end
```

Tipos disponibles en el segundo argumento de `text`:

- `MSGBOX_NPC`: diálogo normal de NPC.
- `MSGBOX_DEFAULT`: diálogo normal sin comportamiento especial.
- `MSGBOX_SIGN`: texto de cartel, sin nombre de personaje.
- `MSGBOX_YESNO`: muestra las opciones Sí y No. La respuesta queda en `last_choice`: `0` para Sí y `1` para No.

Ejemplo de decisión:

```text
text "¿Quieres abrir la puerta?" MSGBOX_YESNO
ifchoice 0 abrir
goto cancelar

label abrir
text "La puerta se abrió."
setflag FLAG_PUERTA_ABIERTA
return

label cancelar
text "Quizá más tarde."
end
```

`multichoice "Pregunta" "Opción uno" "Opción dos"` muestra una lista de opciones y también actualiza `last_choice`.

`waitbutton` espera el botón A. Normalmente no hace falta después de `text`, porque la caja de diálogo ya espera al jugador.

## Flujo y banderas

```text
setflag FLAG_CONOCIO_PROFESOR
ifflag FLAG_CONOCIO_PROFESOR saludo_repetido
goto primera_vez

label primera_vez
text "Encantado de conocerte."
return

label saludo_repetido
text "Nos vemos otra vez."
end
```

- `label NOMBRE`: marca un destino.
- `goto NOMBRE`: salta a una etiqueta.
- `ifchoice VALOR ETIQUETA`: salta si `last_choice` coincide.
- `ifflag BANDERA ETIQUETA`: salta si la bandera global vale `true`.
- `setflag BANDERA`: activa una bandera global y persistente.
- `clearflag BANDERA`: desactiva una bandera global.
- `return` y `end`: terminan el script.

Las banderas se guardan en la ranura de partida y se restauran al cargarla.

### Comparaciones

`compare` salta a una etiqueta si una comparación es verdadera. Sintaxis:

```text
compare <flag|variable|choice> <clave> <==|!=|>|>=|<|<=> <valor> <etiqueta>
```

Ejemplos:

```text
compare flag FLAG_PUERTA == true puerta_abierta
compare variable contador >= 3 recompensa
compare choice last_choice == 0 aceptado
```

`flag` lee una bandera global; `variable` lee una variable temporal del script; `choice` es una variable temporal, normalmente `last_choice`.

### Multichoice con posición

La forma actual admite una pregunta, tantas opciones como necesites (el diálogo muestra hasta cuatro) y dos coordenadas opcionales para dibujar el panel:

```text
multichoice "¿Qué eliges?" "Sí" "No" 260 42
```

Sin las coordenadas, el panel usa su posición habitual:

```text
multichoice "¿Qué eliges?" "Sí" "No"
```

La respuesta se guarda como texto numérico en `last_choice`: `0` para la primera opción, `1` para la segunda, etc.

## Movimiento, clima y pantallas

```text
lock
faceplayer
applymovement KAIDA "face down; walk left 2; face right"
weather rain
fadeout 0.4
fadein 0.4
release
end
```

- `lock` / `release`: bloquea o devuelve el control al jugador.
- `faceplayer`: hace que el NPC del evento mire al jugador.
- `applymovement ID "movimientos"`: mueve al NPC o jugador cuyo identificador coincida. Para el jugador usa `LOCALID_PLAYER`.
- `weather`: admite `rain`, `snow`, `fog`, `fog_diagonal`, `sandstorm`, `drought` y `none`.
- `fadeout [segundos]` y `fadein [segundos]`: fundidos de pantalla.
- `sound "res://ruta/al/sonido.ogg"`: reproduce un sonido.

## Warp

`warp` siempre afecta al jugador:

```text
warp MAPSEC_PUEBLO_ALBA 7 11
```

El primer argumento es una entrada existente de `MapSection.SectionId` (por ejemplo `MAPSEC_PRADO_NATAL` o `MAPSEC_PUEBLO_ALBA`). Los otros dos son coordenadas de casilla. El comando realiza un fundido de salida, cambia de mapa, coloca al jugador, actualiza clima/música y ejecuta los scripts de entrada; finalmente hace el fundido de entrada.

## Guardado

```text
savegame
```

Abre la selección de una de las tres ranuras. Si la ranura ya contiene datos, pide confirmación antes de reemplazarla.

## Scripts de mapa

Los scripts de mapa no pertenecen a un NPC. Se configuran en el nodo raíz `MapAttributes` de cada escena de mapa y se ejecutan con el jugador y el mapa como contexto.

### Configuración en el inspector

1. Abre la escena del mapa y selecciona su nodo `MapAttributes`.
2. En el grupo **Map Script**, añade un elemento a `map_scripts`.
3. Configura estas propiedades del elemento `MapScriptEntry`:

   - `trigger`: cuándo se revisa o ejecuta el script.
   - `script_file`: ruta al archivo `.txt`.
   - `condition_flag`: bandera opcional que debe cumplir una condición.
   - `expected_value`: valor esperado de esa bandera; normalmente `true` o `false`.

El campo antiguo `map_script` se conserva para tus mapas existentes: se ejecuta al cargar el mapa. Para mapas nuevos usa `map_scripts`, ya que permite varios scripts y condiciones.

### Tipos de map scripts

| Trigger | Cuándo ocurre | Uso recomendado |
| --- | --- | --- |
| `ON_TRANSITION` | Cuando el mapa pasa a ser el mapa actual, antes de sus scripts de carga. | Preparar estado de una entrada, clima o eventos visuales. |
| `ON_LOAD` | Al iniciar el mapa o terminar una transición hacia él. | Mensajes de bienvenida, eventos iniciales y lógica de mapa. |
| `ON_FRAME_TABLE` | Se revisa mientras ese mapa está activo. | Lanzar un evento al activarse una bandera. |
| `ON_RESUME` | Reservado para cuando el campo vuelva a tomar control. | Úsalo cuando conectes una pausa, menú o escena secundaria al campo. |
| `ON_RETURN_TO_FIELD` | Reservado para volver desde otra escena de juego. | Por ejemplo, al regresar de combate. |
| `ON_DIVE_WARP` | Reservado para warps de buceo. | Entradas/salidas de buceo. |
| `ON_WARP_INTO_MAP_TABLE` | Reservado para tablas condicionales de warp. | Variantes de entrada según una bandera. |

Los últimos cuatro tipos ya están disponibles en el inspector, pero necesitan que el sistema que origina ese evento llame a `trigger_map_scripts(...)`. `ON_TRANSITION`, `ON_LOAD` y `ON_FRAME_TABLE` ya se ejecutan automáticamente.

### `ON_LOAD`: mensaje al llegar a un mapa

Archivo `res://game/scripts/prado_bienvenida.txt`:

```text
# Se ejecuta al cargar Prado Natal.
text "Prado Natal" MSGBOX_SIGN
end
```

En `MapAttributes > map_scripts`, crea una entrada:

```text
trigger: ON_LOAD
script_file: res://game/scripts/prado_bienvenida.txt
condition_flag: (vacío)
```

### `ON_TRANSITION`: preparar una entrada

Archivo `res://game/scripts/entrada_con_lluvia.txt`:

```text
weather rain
end
```

Configuración:

```text
trigger: ON_TRANSITION
script_file: res://game/scripts/entrada_con_lluvia.txt
```

Usa este tipo para preparar el estado del mapa antes de los mensajes o eventos de `ON_LOAD`.

### `ON_FRAME_TABLE`: equivalente a `map_script_2`

Este trigger sirve para un evento condicionado a una bandera. No ejecuta el archivo en todos los frames: se dispara una vez cuando la condición cambia de no cumplirse a cumplirse. Para poder ejecutarlo otra vez, primero la condición debe dejar de cumplirse y volver a cumplirse.

Archivo `res://game/scripts/aparece_profesor.txt`:

```text
lock
text "¡Espera!" MSGBOX_NPC
applymovement PROFESOR "walk down 2; face down"
clearflag FLAG_PROFESOR_ENTRA
release
end
```

Configuración de la entrada:

```text
trigger: ON_FRAME_TABLE
script_file: res://game/scripts/aparece_profesor.txt
condition_flag: FLAG_PROFESOR_ENTRA
expected_value: true
```

Desde cualquier NPC o script de mapa puedes activar el evento:

```text
setflag FLAG_PROFESOR_ENTRA
end
```

Al quedar activa la bandera y estar el jugador en ese mapa, el script de aparición se ejecutará. El `clearflag` final evita que vuelva a activarse al volver a entrar.

### Ejemplo: entrada distinta según una bandera

Puedes crear dos entradas `ON_LOAD` con condiciones opuestas:

```text
# Entrada 1
trigger: ON_LOAD
script_file: res://game/scripts/pueblo_antes.txt
condition_flag: FLAG_PUEBLO_SALVADO
expected_value: false

# Entrada 2
trigger: ON_LOAD
script_file: res://game/scripts/pueblo_despues.txt
condition_flag: FLAG_PUEBLO_SALVADO
expected_value: true
```

`pueblo_antes.txt`:

```text
weather fog
end
```

`pueblo_despues.txt`:

```text
weather none
text "La paz ha vuelto al pueblo." MSGBOX_SIGN
end
```

### Ejecutar un trigger manualmente desde código

Cuando implementes combate, buceo u otra escena, puedes disparar los tipos reservados desde el mapa activo:

```gdscript
var map: MapAttributes = map_manager.current_map
map.trigger_map_scripts(MapScriptEntry.Trigger.ON_RETURN_TO_FIELD)
```

Para un warp condicional, usa:

```gdscript
map.trigger_map_scripts(MapScriptEntry.Trigger.ON_WARP_INTO_MAP_TABLE)
```

Después puedes usar `condition_flag` y `expected_value` en cada entrada para decidir cuál de esos scripts se ejecuta.
