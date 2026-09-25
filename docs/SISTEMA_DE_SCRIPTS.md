# Sistema de scripts de campo

Los NPC y los mapas ejecutan archivos `.txt`. Cada línea contiene un comando.
Las líneas vacías, las que empiezan por `#` y las que empiezan por `//` se ignoran.
Los textos o argumentos que contengan espacios deben escribirse entre comillas.

El parser acepta argumentos entre comillas sin incluir las comillas en el valor:

```text
text "Una frase con espacios."
applymovement GUARDIA_01 "face down; walk left 2; wait 0.3"
```

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

`MSGBOX_AUTOCLOSE` y `MSGBOX_GETINPUT` están reconocidos por el parser, pero
por ahora se comportan como una caja de texto normal. No los uses para una
secuencia que dependa de un cierre automático o de entrada de texto.

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
- `checkitem OBJETO [cantidad]`: guarda si la mochila tiene el objeto en
  `last_result` y deja la cantidad disponible en `last_item_count`.
- `setflag BANDERA`: activa una bandera global y persistente.
- `clearflag BANDERA`: desactiva una bandera global.
- `return` y `end`: terminan el script.

Las banderas se guardan en la ranura de partida y se restauran al cargarla.

### Comprobar objetos

```text
checkitem POTION 2
compare variable last_result == true tiene_pociones
text "Necesitas dos Pociones."
end

label tiene_pociones
text "Tienes suficientes Pociones."
end
```

`checkitem` acepta `POTION` o el nombre completo `ITEM_POTION`. No consume
objetos; sirve para puertas, recompensas y decisiones de eventos.

### Comparaciones

`compare` salta a una etiqueta si una comparación es verdadera. Sintaxis:

```text
compare <flag|variable|choice> <clave> <==|!=|>|>=|<|<= <valor> <etiqueta>
```

Ejemplos:

```text
compare flag FLAG_PUERTA == true puerta_abierta
compare variable contador >= 3 recompensa
compare choice last_choice == 0 aceptado
```

`flag` lee una bandera global; `variable` lee una variable temporal del script; `choice` es una variable temporal, normalmente `last_choice`.

`compare` compara números cuando ambos lados son numéricos. Con texto solo son
válidos `==` y `!=`. El operador debe ir separado por espacios.

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

### Referencia de comandos de campo

| Comando | Sintaxis | Resultado |
| --- | --- | --- |
| `lock` | `lock` | Bloquea el control del jugador. |
| `release` | `release` | Devuelve el control al jugador. |
| `faceplayer` | `faceplayer` | El NPC que inició el script mira al jugador. |
| `moveplayer` | `moveplayer <up\|down\|left\|right> [pasos]` | Fuerza movimiento animado del jugador. |
| `applymovement` | `applymovement ID "instrucciones"` | Ejecuta una secuencia sobre un NPC o el jugador. |
| `weather` | `weather <tipo>` | Cambia clima de mapa y efecto visual. |
| `fadeout` | `fadeout [segundos]` | Fundido hacia negro y espera a terminar. |
| `fadein` | `fadein [segundos]` | Fundido desde negro y espera a terminar. |
| `sound` | `sound "res://audio.ogg"` | Reproduce un SFX local sin bloquear el script. |
| `warp` | `warp MAPSEC_* x y` | Cambia el mapa y mueve al jugador. |
| `savegame` | `savegame` | Abre la selección y confirmación de una ranura. |
| `giveitem` | `giveitem ITEM_ID [cantidad]` | Añade un objeto a la mochila. |
| `checkitem` | `checkitem ITEM_ID [cantidad]` | Actualiza `last_result` y `last_item_count`. |
| `trainerbattle` | `trainerbattle TRAINER_ID` | Combate contra un entrenador y espera a que acabe. Al ganar activa la flag `TRAINER_ID`; `last_result` indica si ganó. Ver [ENTRENADORES.md](ENTRENADORES.md). |
| `waitbutton` | `waitbutton` | Espera la acción `buttonA`. |
| `label` | `label nombre` | Declara un destino de salto. |
| `goto` | `goto nombre` | Salta incondicionalmente. |
| `ifchoice` | `ifchoice valor nombre` | Salta si `last_choice` coincide. |
| `ifflag` | `ifflag FLAG nombre` | Salta si la bandera vale `true`. |
| `compare` | `compare fuente clave operador valor nombre` | Salta si la comparación es verdadera. |
| `setflag` | `setflag FLAG` | Guarda una bandera global con valor `true`. |
| `clearflag` | `clearflag FLAG` | Guarda una bandera global con valor `false`. |
| `return` / `end` | `return` / `end` | Finaliza el runner actual. |

### `applymovement`

La secuencia se separa con `;`. Instrucciones implementadas:

| Instrucción | Ejemplo | Resultado |
| --- | --- | --- |
| `face dirección` | `face left` | Cambia la dirección sin mover. |
| `walk dirección [pasos]` | `walk up 2` | Camina una o más casillas, esperando cada paso. |
| `wait segundos` | `wait 0.5` | Pausa dentro de la secuencia. |

Las direcciones aceptan inglés y español: `up/arriba`, `down/abajo`,
`left/izquierda`, `right/derecha`. Si el ID no existe, el comando registra un
aviso y el script continúa.

`moveplayer` es una versión corta para una dirección. No acepta destino por
coordenadas: el modo interno `WALK_TO_TILE` aún no está implementado.

### Clima y sonido

`weather` acepta `none`, `rain`, `snow`, `fog`, `fog_diagonal`, `sandstorm` y
`drought` (también sus equivalentes españoles documentados antes).

El comando textual `sound` crea un SFX con la ruta indicada. No admite aún
elegir música, voz, volumen, bucle ni esperar a que termine; esas opciones solo
existen en el recurso visual `ScriptCmdSound` del inspector.

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

El comando espera a que el flujo de guardado finalice. Si no hay una
`DialogueBox` activa en la escena, el guardado falla y el script continúa para
evitar que el runner quede bloqueado.

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

## Ejemplos completos

### NPC que da un objeto una sola vez

```text
ifflag FLAG_RECIBIO_POCION ya_recibio
lock
faceplayer
text "Toma esto para tu aventura." MSGBOX_NPC
giveitem POTION 2
setflag FLAG_RECIBIO_POCION
text "¡Usa las Pociones si un Pokémon pierde PS!"
release
end

label ya_recibio
text "Cuida bien de tu equipo." MSGBOX_NPC
end
```

### Puerta que comprueba la mochila

```text
checkitem SECRET_KEY 1
compare variable last_result == true abrir
text "La puerta está cerrada con llave." MSGBOX_SIGN
end

label abrir
text "La llave abre la puerta." MSGBOX_SIGN
warp MAPSEC_PUEBLO_ALBA 4 9
end
```

### Cutscene con movimiento, clima y elección

```text
lock
applymovement PROFESOR "face down; walk down 2"
text "¿Comenzamos el experimento?" MSGBOX_YESNO
ifchoice 0 aceptar
text "Entiendo. Volveré después."
release
end

label aceptar
weather rain
fadeout 0.3
fadein 0.3
text "¡Perfecto! Observa el cambio de clima."
release
end
```

## Límites del lenguaje actual

- No hay bloques `if`/`else`/`endif` dentro de un `.txt`; usa etiquetas,
  `goto`, `ifchoice`, `ifflag` y `compare`.
- Las variables temporales solo viven mientras el `ScriptRunner` está activo.
  Para persistir decisiones entre mapas o sesiones usa flags.
- No existe aún un comando de quitar objetos, iniciar un combate salvaje,
  aplicar una evolución o modificar dinero desde texto. Los combates contra
  entrenadores se inician con `trainerbattle`.
- Las flags son texto libre: una errata crea otra flag distinta sin avisar al
  jugar. **Proyecto → Herramientas → 🔎 Revisar contenido** las detecta.
- `giveitem` añade objetos sin comprobar un límite de capacidad de mochila.

## Selector de opciones independiente

`MultichoiceBox` ya no es hijo de `DialogueBox`: `DialogueManager` lo crea en
una capa propia. Los scripts de texto siguen comportándose igual, pero otros
sistemas pueden mostrar opciones sin abrir el diálogo inferior.

Desde código, usa:

```gdscript
var result: int = await DialogueManager.choose(
    ["Sí", "No"], Vector2(468, 308)
)
if result == 0:
    # primera opción
    pass
```

Devuelve el índice de la opción, o `-1` al cancelar. Para abrirlo sin esperar,
usa `DialogueManager.show_choices_only(...)` y conecta la señal
`choice_selected(index, choice_id)` del `MultichoiceBox` retornado.
