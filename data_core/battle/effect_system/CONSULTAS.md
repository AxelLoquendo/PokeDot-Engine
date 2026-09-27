# Consultas, inmunidades, multiplicadores y aritmética

Las habilidades pasivas (las que el damage calc **pregunta**) ahora también van en `.txt`.
El BattleManager no cambia: `AbilityRuntime` pregunta a `AbilitySystem.query(...)`.

## Eventos de consulta (síncronos)

| Evento | Qué devuelve | API runtime |
|--------|----------------|-------------|
| `on_immunity` | reacción (`immune`, `heal`, `spatk_up`…) | `type_immunity_reaction` |
| `on_power` | `multiplier` | `power_multiplier` |
| `on_attack_stat` | `multiplier` | `attack_stat_multiplier` |
| `on_damage_taken` | `multiplier` | `damage_taken_multiplier` |
| `on_speed` | `multiplier` | `speed_multiplier` |
| `on_blocks_status` | bool | `blocks_status` |
| `on_blocks_flinch` / `_critical` / `_recoil` / `_confusion` | bool | los `blocks_*` |
| `on_blocks_stat_drop` | bool | `blocks_foe_stat_drop` |
| `on_sturdy` | bool | `should_survive_with_sturdy` |
| `on_priority` | int | `priority_bonus` |
| `on_move_type` | tipo | `effective_move_type` |
| `on_type_power` | multiplier | `type_change_power_multiplier` |
| `on_stab` / `on_crit` / `on_attacker_damage` | multiplier | STAB / Sniper / Tinted Lens |
| `on_damaged` | secuencia (async) | `on_damaged_by_move` |

## Inmunidad — uno o más argumentos (OR)

```text
on_immunity:
  immunity immune GROUND unless=damages_airborne
  immunity heal ELECTRIC
  immunity heal WATER
  immunity spatk_up WATER ELECTRIC
  immunity immune SOUND BALLISTIC
  immunity atk_up WIND
  immunity flash_fire FIRE
```

Matchers: tipos (`FIRE`, `GROUND`…) **o** flags (`SOUND`, `BALLISTIC`, `WIND`, `CONTACT`, `PUNCH`…).

Reacciones: `immune`, `heal`, `spatk_up`, `spe_up`, `atk_up`, `def_up`, `flash_fire`.

## Multiplicar

```text
on_power:
  if move_flag punching_move
    multiply power 1.2
  endif
  if hp_percent <= 33.4
    if move_type FIRE
      multiply power 1.5
    endif
  endif

on_speed:
  if weather SUN
    multiply speed 2.0
  endif
```

Sintaxis:

- `multiply <expresión>` — multiplica el canal del evento (`ctx.multiplier`).
- `multiply <canal> <expresión>` — igual, con canal explícito (`power`, `speed`,
  `damage_taken`, `attack_stat`, `stab`, `crit`, `weight`, …).

`multiply` acepta **expresión**: `1.5`, `3 / 4`, `(2 + 1) * 0.5`, `hp_percent / 100`.

## Aritmética sobre variables

```text
set dmg damage
mul dmg 1.5
div dmg 8
add dmg 1
sub dmg 2
multiply dmg
```

Identificadores: `damage`, `hp_percent`, `hp_ratio`, `max_hp`, `current_hp`, `power`, `effectiveness`, `multiplier`, `recoil_percent`, `drain_percent`.

## Bloqueos

```text
on_blocks_status:
  block_status SLEEP
  block_status POISON TOXIC
  block_status ALL

on_blocks_critical:
  block

on_blocks_stat_drop:
  if stat ATK
    block
  endif
```

## Condiciones `if`

`is_contact`, `not …`, `move_type FIRE ICE`, `move_flag sound_move`, `category PHYSICAL`, `has_status BURN`, `hp_percent <= 33.4`, `hp_full`, `weather RAIN`, `terrain ELECTRIC`, `effectiveness > 1`, `was_critical`, `flash_fire_boosted`, `stat ATK`, `same_gender`, `user_type GRASS`.

## Ejemplos reales

```text
# levitate.txt
on_immunity:
  immunity immune GROUND unless=damages_airborne

# iron_fist.txt
on_power:
  if move_flag punching_move
    multiply 1.2
  endif

# guts.txt
on_attack_stat:
  if category PHYSICAL
    if has_status
      multiply 1.5
    endif
  endif

# thick_fat.txt
on_damage_taken:
  if move_type FIRE ICE
    multiply 0.5
  endif
```

Las consultas **no** deben usar `announce` / `heal` / `wait`. Eso es para eventos de secuencia.
