# Guía del sistema de efectos (habilidades)

Esta guía explica **cómo usar** el sistema: crear efectos, combinar comandos,
qué hace cada argumento y cómo razonar casos raros (dos Trace, Intimidación
en dobles, etc.).

Si solo quieres el mapa de arquitectura, ve a `HABILIDADES.md`.  
Si quieres la lista corta de comandos, ve a
`data_core/battle/effect_system/COMANDOS.md`.

---

## 1. Idea central (Lego)

No escribes “la habilidad Intimidación” en GDScript.

Escribes **piezas genéricas** (`announce`, `lower_stat`, `multiply`, `if`…)
y las **combinas** en un `.txt` por habilidad.

```text
on_switch_in:
  announce
  for_each opponents
    lower_stat ATK 1 target=current caused_by_foe
  end_for
```

| Quién | Qué aporta |
|-------|------------|
| Comandos (`.gd`) | Qué se *puede* hacer |
| Scripts (`.txt`) | Qué *hace* cada habilidad |
| `AbilityRuntime` | *Cuándo* se pregunta / se dispara |
| `BattleManager` | Combate, daño, señales de UI |

**Regla de oro:** si para una habilidad nueva necesitas un `match AbilityId`
en el runtime, algo va mal. O usas comandos existentes, o creas un comando
genérico nuevo (no un caso especial de esa habilidad).

---

## 2. Crear una habilidad desde cero

### Paso 1 — Enum e identidad

En `data_core/ability/ability.gd` el ID ya debe existir (`AbilityId.Id.MI_HABILIDAD`).
El archivo de efecto se nombra en minúsculas:

```text
AbilityId.Id.SPEED_BOOST  →  speed_boost.txt
AbilityId.Id.SHADOW_TAG   →  shadow_tag.txt
```

Ruta:

```text
data_core/battle/effect_system/scripts/abilities/<nombre>.txt
```

### Paso 2 — Elige el/los eventos

Los bloques del `.txt` son **nombres de evento** (o de consulta).

**Secuencias** (pueden usar `announce`, curar, bajar stats…):

| Evento | Cuándo lo dispara el runtime |
|--------|------------------------------|
| `on_switch_in` | Al entrar al campo |
| `on_switch_out` | Al salir |
| `on_end_turn` | Fin de turno |
| `on_hit` | Tras golpear con un movimiento |
| `on_hit_by` | Tras recibir un golpe |
| `on_damaged` | Tras recibir daño (similar; úsalo si el script lo pide) |
| `on_contact_hit` | Contacto (lado atacante o según el runtime) |
| `on_ko` | Al debilitar a un rival |
| `on_faint` | Al debilitarse el portador |
| `on_status` | Al recibir un estado |
| `on_weather` | Cambio / tick de clima (según cableado) |
| `on_move_use` | Al usar un movimiento (Protean, Libero…) |
| `on_berry_eat` | Al comer baya |
| `on_steal_item` | Momento de robo de objeto |
| `on_poison_applied` | Tras aplicar veneno (Poison Puppeteer) |

**Consultas** (síncronas, **no** deben anunciar ni animar):

| Evento | Devuelve | Ejemplo |
|--------|----------|---------|
| `on_speed` | multiplica `multiplier` | Swift Swim |
| `on_power` | multiplica potencia | Technician |
| `on_damage_taken` | multiplica daño recibido | Filter |
| `on_accuracy` | multiplica precisión | Compound Eyes |
| `on_evasion` | multiplica evasión | Tangled Feet |
| `on_attack_stat` / `on_defense_stat` | stats efectivos | Huge Power |
| `on_stab` | STAB | Adaptability |
| `on_crit` / `on_crit_stage` | crítico | Super Luck |
| `on_immunity` | `block` si inmune | Volt Absorb (parte flag) |
| `on_blocks_status` | `block` | Immunity |
| `on_blocks_stat_drop` | `block` | Clear Body |
| `on_blocks_accuracy_drop` | `block` | Keen Eye |
| `on_blocks_flinch` | `block` | Inner Focus |
| `on_blocks_intimidate` | `block` | Own Tempo / Oblivious / Inner Focus… |
| `on_blocks_item_theft` | `block` | Sticky Hold |
| `on_trap` | `block` = atrapa | Shadow Tag / Arena Trap / Magnet Pull |
| `on_skip_turn` | `block` = se salta el turno | Truant |
| `on_priority` | `priority N` | Gale Wings (vía script) |
| `on_supreme_overlord` | multiplica según KO del equipo | Supreme Overlord |
| `on_plus_minus` | Plus / Minus | |
| `on_aura` / `on_ruin_stat` | auras / ruin | |

El runtime elige el nombre al construir el `EffectContext` y llamar a
`AbilitySystem.on_event(...)` o `query_float` / `query_bool`.

### Paso 3 — Escribe el script

Ejemplo mínimo con barra de habilidad:

```text
# Speed Boost: +1 Speed al final del turno
on_end_turn:
  announce
  raise_stat SPEED 1 target=user
```

`announce` es **obligatorio** cada vez que quieras que se vea la ability bar.
Si no pones `announce`, el efecto puede aplicar en silencio (útil en consultas).

### Paso 4 — Prueba

1. Pon la habilidad a un Pokémon de prueba.
2. Fuerza el evento (entrar, atacar, fin de turno…).
3. Confirma: mensaje, barra, cambio de stat/HP/estado.
4. Prueba el caso borde (misma habilidad en ambos bandos, dobles, KO…).

---

## 3. Anatomía de un script

```text
# Comentarios con #

on_switch_in:          # ← cabecera de bloque (termina en :)
  announce             # indentación con tabs o espacios (sé consistente)
  if has_status
    heal_percent 12.5
  endif

on_speed:              # otro bloque en el mismo archivo
  if weather RAIN
    multiply speed 2.0
  endif
```

- Un archivo puede tener **varios** bloques.
- Solo se ejecuta el bloque cuyo nombre coincide con el evento pedido.
- Indentación no crea scope por sí sola: el control de flujo es
  `if` / `else` / `endif`, `chance` / `endchance`, `for_each` / `end_for`.

---

## 4. Comandos y argumentos (referencia práctica)

### 4.1 UI y texto

| Comando | Argumentos | Efecto |
|---------|------------|--------|
| `announce` | `target=user` (defecto), `target=current`, `target=target`, `target=attacker` | Ability bar + mensaje de activación |
| `message` | texto libre; placeholders `{user}`, `{target}`, `{current}` | Solo mensaje |

```text
announce
announce target=current
message "¡{current} no se intimidó!"
```

### 4.2 Estadísticas

| Comando | Argumentos |
|---------|------------|
| `raise_stat STAT N` | `STAT` = `ATK` `DEF` `SP_ATK`/`SP_ATTACK` `SP_DEF`/`SP_DEFENSE` `SPEED` `ACCURACY` `EVASION` (estas dos últimas son **stages del battler**, no `PokemonInstance.Stat`) |
| | `target=user\|target\|opponent\|attacker\|current` |
| | `caused_by_foe` — marca bajada causada por el rival (Clear Body, Mirror Armor…) |
| `lower_stat STAT N` | igual |

```text
lower_stat ATK 1 target=current caused_by_foe
raise_stat SPEED 2 target=user
```

### 4.3 Estados y daño relativo

| Comando | Argumentos |
|---------|------------|
| `status NAME` | `POISON` `TOXIC` `BURN` `PARALYSIS` `SLEEP` `FREEZE` + `target=...` |
| `cure_status` | `target=...` |
| `infatuate` | `target=attacker` típico |
| `damage_percent P` | `P` = porcentaje de **max HP** del objetivo; `target=...` |
| `heal_percent P` | igual, cura |

```text
status BURN target=attacker
damage_percent 12.5 target=attacker
heal_percent 25 target=user
```

### 4.4 Multiplicadores (consultas)

```text
multiply [canal] <expresión>
```

- Si el primer token **no** parece número, es el **canal** (`speed`, `power`, `damage_taken`, `attack_stat`, `stab`, …).
- Si solo hay un número, multiplica el `multiplier` del contexto.

```text
on_speed:
  if weather RAIN
    multiply speed 2.0
  endif

on_power:
  if move_type FIRE
    multiply power 1.5
  endif

on_supreme_overlord:
  set multiplier 1 + query_int * 0.1
```

Expresiones admiten `+ - * /`, paréntesis e identificadores del contexto:
`query_int`, `multiplier`, `damage`, `hp_percent`, `power`, …

### 4.5 Bloqueos e inmunidad

| Comando | Uso |
|---------|-----|
| `block` | En consultas bool: “sí, bloquea / atrapa / inmune” |
| `immunity` | Marca inmunidad de tipo/efecto (según el evento) |
| `block_status` | Variante específica de estados |

```text
on_blocks_intimidate:
  block

on_trap:
  if not has_ability SHADOW_TAG
    block
  endif
```

### 4.6 Control de flujo

```text
if <condiciones...>
  ...
else
  ...
endif

chance 30
  status PARALYSIS target=attacker
endchance

for_each opponents
  lower_stat ATK 1 target=current caused_by_foe
end_for
```

**Condiciones frecuentes** (se combinan con AND implícito entre tokens):

| Token | Significado |
|-------|-------------|
| `is_contact` | Movimiento de contacto |
| `category PHYSICAL\|SPECIAL\|STATUS` | Categoría |
| `move_type FIRE` (varios) | Tipo del movimiento |
| `weather RAIN\|DROUGHT\|SANDSTORM\|SNOW\|STRONG_WINDS` | Clima activo |
| `terrain ELECTRIC\|...` | Terreno |
| `has_status` / `has_status POISON TOXIC` | Estado del user |
| `hp_below 33` / `hp_full` | HP del user |
| `stat ATK` | En `on_blocks_stat_drop`: qué stat intentan bajar |
| `has_ability NAME` | Habilidad del **current** o user según contexto |
| `blocks_intimidate` | Consulta al objetivo actual |
| `acted_after_target` | Analytic |
| `target_just_switched` | Stakeout |

### 4.7 Campo, forma, habilidad

| Comando | Notas |
|---------|-------|
| `set_weather RAIN\|SUN\|DROUGHT\|SANDSTORM\|SNOW\|NONE [turns]` | `SUN` puede mapear a `DROUGHT` según enum del proyecto |
| `set_terrain ELECTRIC\|GRASSY\|MISTY\|PSYCHIC\|NONE [turns]` | |
| `change_form form_id` | `form_id` es **StringName** (`Hero`, `base`, `zen`…) |
| `set_type FIRE` / `set_type from=move` | Tipo de combate del battler (Protean) |
| `set_move_type FAIRY` / `set_move_type ELECTRIC if_type=NORMAL` | Tipo del movimiento (Pixilate) |
| `set_ability TRACE` / `set_ability from=target` | |
| `swap_ability` | |
| `set_meta clave valor` | Datos temporales en el battler/contexto |
| `setup_illusion` / `setup_imposter` | Piezas de entrada |

### 4.8 Specials

```text
special nombre_de_pieza
```

Piezas registradas en `EffectBootstrap` (Trace, Frisk, Moody, Pickpocket,
Schooling, Neutralizing Gas, …). Son **genéricas**: no digas el nombre de
la habilidad dentro del special; el `.txt` decide *cuándo* llamarlas.

Lista actual: ver `effect_bootstrap.gd` → array `specials`.

---

## 5. Cómo piensa el runtime (para no romperlo)

```text
BattleManager (momento X)
    → AbilityRuntime.on_*(…)
        → EffectContext(user, target, move, battle, …)
        → AbilitySystem.on_event("on_…", ctx)   o query_*
            → carga scripts/abilities/<ability>.txt
            → EffectRunner ejecuta el bloque
```

- **Secuencias** (`on_event`): pueden `await` (announce, daño, mensajes).
- **Consultas** (`query_float` / `query_bool`): síncronas. No uses `announce` ahí.
- `multiply` escribe en `ctx.multiplier`; el runtime **devuelve** ese valor.
- `block` pone `ctx.blocked` / `query_bool`.

---

## 6. Casos borde que debes diseñar a propósito

### 6.1 Dos Pokémon con Trace (Rastro)

Trace **no debe copiar Trace** ni habilidades de forma permanente listadas
en el special (`MULTITYPE`, `ILLUSION`, `IMPOSTER`, …).

Si ambos entran el mismo turno:

1. El orden de `on_switch_in` lo decide el combate (velocidad / lado).
2. El primero copia al rival (si es copiable).
3. El segundo ve al primero **ya con la habilidad copiada** o sigue viendo Trace
   (no copiable) según timing.

Diseño recomendado del script:

```text
on_switch_in:
  announce
  special trace_ability
```

La lógica de exclusión vive en `CmdSpecial._trace`, no en el runtime.

### 6.2 Shadow Tag vs Shadow Tag

```text
on_trap:
  if not has_ability SHADOW_TAG
    block
  endif
```

Si el rival **también** tiene Shadow Tag, no se atrapa (regla oficial).

### 6.3 Intimidación en dobles

```text
on_switch_in:
  announce
  for_each opponents
    if blocks_intimidate
      if has_ability GUARD_DOG
        announce target=current
        raise_stat ATK 1 target=current
      else
        announce target=current
        message "¡{current} no se intimidó!"
      endif
    else
      lower_stat ATK 1 target=current caused_by_foe
    endif
  end_for
```

- `for_each opponents` solo debe ver rivales **conscientes**.
- `announce target=current` anuncia la habilidad del **rival** (Guard Dog), no la tuya otra vez.
- `caused_by_foe` permite que Clear Body / Mirror Armor reaccionen.

### 6.4 Grito / ability bar con un Pokémon ya debilitado

Síntoma reportado: en dobles, tras un KO, al sacar Intimidación el grito del
debilitado se repetía.

Causas típicas:

1. `ability_announce` emitía señal con un battler/slot ya KO.
2. La UI reproduce grito en `ability_announced` sin comprobar si sigue en campo.
3. `for_each` o un `announce target=current` apuntaba a un battler inválido.

Mitigaciones:

- `announce` no anuncia si `is_fainted()`.
- `for_each` ignora debilitados.
- En `BattleManager.ability_announce`, salir si `battler.is_fainted()`  
  (ver `data_core/battle/PATCH_ability_announce.md`).

### 6.5 Same ability mirror (Intimidate vs Intimidate)

Ambos bajan el ATK del otro al entrar (según orden). No hay exclusión especial
salvo habilidades que bloquean Intimidación.

### 6.6 Truant

Usa meta `truant_skip_turn` en el battler. El special `tick_truant` alterna y
marca `on_skip_turn` como bloqueo en los turnos “vagos”.

---

## 7. Cómo añadir un comando nuevo

1. Crea `commands/cmd_mi_pieza.gd` con `class_name CmdMiPieza extends EffectCommand`.
2. Implementa `execute(ctx: EffectContext) -> bool` (tipado estricto).
3. Regístralo en `effect_bootstrap.gd`.
4. Úsalo desde cualquier `.txt`.
5. Documenta argumentos en `COMANDOS.md` y aquí.

**No** pongas el nombre de una habilidad dentro del comando salvo listas
genéricas (p. ej. habilidades no traceables).

---

## 8. Cómo añadir un special nuevo

1. Añade el nombre al array `specials` en `EffectBootstrap`.
2. Añade el `match` en `CmdSpecial.execute`.
3. Implementa `func _mi_special(...)` en `cmd_special.gd`.
4. Desde el `.txt`: `special mi_special`.

Specials sirven para lógica que no encaja en un comando de una línea
(Trace, Frisk, Moody, formas complejas…).

---

## 9. Checklist de calidad de un script

- [ ] ¿Cada activación *visible* tiene `announce`?
- [ ] ¿Las consultas (`on_speed`, etc.) **no** anuncian?
- [ ] ¿Los `target=` son correctos (`user` vs `current` en `for_each`)?
- [ ] ¿El caso “mismo ability en ambos” está pensado?
- [ ] ¿Dobles: `for_each opponents` en lugar de un solo `opponent`?
- [ ] ¿Bloqueos usan `block` en el evento bool correcto?
- [ ] ¿Formas usan `StringName` (`change_form zen`), no enteros sueltos?
- [ ] ¿Clima usa IDs del enum real (`DROUGHT`, no `SUN` inventado)?

---

## 10. Validación automática

```bash
python3 data_core/battle/effect_system/validate_ability_scripts.py
```

Debe reportar **316** oficiales, 0 faltantes, 0 vacíos  
(excluye `CUSTOM_314` y `CUSTOM_317`).

---

## 11. Ejemplos completos

### Rough Skin

```text
on_hit_by:
  if is_contact
    announce
    damage_percent 12.5 target=attacker
  endif
```

### Swift Swim

```text
on_speed:
  if weather RAIN
    multiply speed 2.0
  endif
```

### Flash Fire (patrón típico)

```text
on_immunity:
  if move_type FIRE
    block
  endif

on_hit_by:
  if move_type FIRE
    announce
    set_meta flash_fire 1
  endif

on_power:
  if move_type FIRE
    if has_meta flash_fire
      multiply power 1.5
    endif
  endif
```

*(Ajusta nombres de meta/condiciones a lo que exponga `EffectConditions`.)*

### Technician

```text
on_power:
  if power_at_most 60
    multiply power 1.5
  endif
```

---

## 12. Dónde mirar en el código

| Archivo | Para qué |
|---------|----------|
| `ability_runtime.gd` | Eventos y consultas que existen |
| `effect_context.gd` | Campos disponibles en expresiones y comandos |
| `effect_conditions.gd` | Condiciones de `if` |
| `effect_bootstrap.gd` | Comandos y specials registrados |
| `commands/` | Implementación de cada pieza |
| `scripts/abilities/*.txt` | Efectos de cada habilidad |
| `COMANDOS.md` / `CONSULTAS.md` | Referencia corta |

---

## 13. Política de diseño (resumen)

1. **Datos > código** para comportamientos de habilidad.
2. **Runtime = fachada**, no catálogo de efectos.
3. **Announce explícito** = ability bar.
4. **Consultas silenciosas** = multiplicadores y bloqueos.
5. **Casos espejo** (Trace–Trace, Shadow Tag–Shadow Tag) se resuelven en
   script o special genérico, nunca con `if AbilityId` en el BattleManager.
