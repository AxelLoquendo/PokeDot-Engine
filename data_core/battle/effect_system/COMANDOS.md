# Catálogo de comandos — Effect System

Análisis basado en `AbilityRuntime` + APIs de `BattleManager`.

## Principio

| Tipo de lógica | Dónde vive |
|----------------|------------|
| **Secuencias** (al entrar, al contacto, fin de turno…) | `.txt` + comandos |
| **Consultas pasivas** (× daño, inmunidad, ¿bloquea estado?) | Código GDScript (helpers) |
| **Casos únicos muy raros** (Illusion setup, Imposter, formas) | Código o comandos especiales al final |

Las llamadas reales que más usa el runtime:

| API BattleManager | Usos aprox. | Comando |
|-------------------|-------------|---------|
| `ability_announce` | 103 | `announce` |
| `ability_change_stat` | 41 | `lower_stat` / `raise_stat` |
| `message.emit` + `_wait` | 29+ | `message` |
| `ability_heal` | 7 | `heal` / `heal_percent` |
| `set_weather` | 6 | `set_weather` |
| `set_terrain` | 6 | `set_terrain` |
| `ability_apply_status` | 6 | `status` |
| `ability_deal_damage` | 4 | `damage` / `damage_percent` |
| `ability_cure_status` | 4 | `cure_status` |

---

## Eventos (bloques del .txt)

| Evento | Origen en runtime |
|--------|-------------------|
| `on_switch_in` | `on_switch_in` |
| `on_switch_out` | `on_switch_out` |
| `on_hit_by` | `on_contact_hit` / daño recibido |
| `on_hit` | tras golpear (contacto u otro) |
| `on_end_turn` | `end_of_turn` |
| `on_faint` | al debilitarse |
| `on_stat_drop` | `after_own_stat_drop` |
| `on_flinch` | `on_flinched` |
| `on_berry_eaten` | `on_berry_eaten` |

---

## Comandos — set completo (expansible)

### A. Control de flujo (obligatorio)

| Comando | Sintaxis | Notas |
|---------|----------|--------|
| `chance` | `chance 30` … `endchance` | Ya existe |
| `if` | `if <cond>` … `endif` | Ya existe (ampliar condiciones) |
| `for_each` | `for_each opponents` … `end_for` | Multi: Intimidate, etc. |
| `else` | `else` | Dentro de if |

### B. Presentación

| Comando | Sintaxis | API |
|---------|----------|-----|
| `announce` | `announce` / `announce target=current` | `ability_announce` |
| `message` | `message "texto {user} {target}"` | `message.emit` + wait opcional |
| `wait` | `wait 0.5` | `_wait` |

### C. Stats

| Comando | Sintaxis | API |
|---------|----------|-----|
| `lower_stat` | `lower_stat ATK 1 target=opponent caused_by_foe` | `ability_change_stat` |
| `raise_stat` | `raise_stat SPEED 2 target=user` | idem |
| `reset_stages` | `reset_stages target=ally` | `_reset_stages` (Curious Medicine) |
| `copy_stages` | `copy_stages from=ally` | Costar |

### D. Estados

| Comando | Sintaxis | API |
|---------|----------|-----|
| `status` | `status BURN target=attacker` | `ability_apply_status` |
| `status_random` | `status_random SLEEP POISON PARALYSIS` | Effect Spore |
| `cure_status` | `cure_status target=user` | `ability_cure_status` |
| `infatuate` | `infatuate target=attacker` | Cute Charm (`infatuated_by_player_side`) |

### E. PS

| Comando | Sintaxis | API |
|---------|----------|-----|
| `heal` | `heal 50` | `ability_heal` cantidad fija |
| `heal_percent` | `heal_percent 12.5` / `heal_percent max_hp/8` | fracción de max HP |
| `damage` | `damage 20 target=attacker` | `ability_deal_damage` |
| `damage_percent` | `damage_percent 12.5 target=attacker` | Rough Skin (max_hp/8) |

### F. Campo

| Comando | Sintaxis | API |
|---------|----------|-----|
| `set_weather` | `set_weather RAIN` / `set_weather SUN -1` / `set_weather RAIN -1 primal` | `set_weather` |
| `set_terrain` | `set_terrain ELECTRIC 5` | `set_terrain` |
| `clear_screens` | `clear_screens` | Screen Cleaner ambos lados |

### G. Habilidad / identidad

| Comando | Sintaxis | Notas |
|---------|----------|--------|
| `set_ability` | `set_ability target=attacker from=user` | Mummy |
| `swap_ability` | `swap_ability with=attacker` | Wandering Spirit |
| `copy_ability` | `copy_ability from=opponent` | Trace |
| `set_meta` | `set_meta slow_start_turns 5` | Slow Start, flags |

### H. Condiciones `if` (ampliar)

| Condición | Significado |
|-----------|-------------|
| `is_contact` | movimiento de contacto |
| `blocks_intimidate` | Inner Focus, Own Tempo, Oblivious, Scrappy, Guard Dog |
| `has_ability GUARD_DOG` | el **current** (en for_each) o target |
| `is_fainted` | current/target debilitado |
| `is_multi` | combate múltiple |
| `hp_percent < 50` | ya esbozado |
| `weather RAIN` | clima actual |
| `terrain ELECTRIC` | terreno |
| `has_status` | tiene estado |
| `held_item` | lleva objeto (Frisk) |
| `can_trace` | habilidad traceable |

### I. Targets

| Valor | Quién |
|-------|--------|
| `user` | dueño de la habilidad |
| `target` | target del contexto |
| `attacker` | quien golpeó |
| `opponent` | primer rival vivo |
| `all_opponents` / `for_each opponents` | todos los rivales |
| `ally` | aliado en dobles |
| `current` | iteración actual de `for_each` |

---

## Qué NO va a comandos (se queda en código)

Estas son **consultas** en medio del cálculo de daño / precisión / orden; no secuencias:

- `type_immunity_reaction`, multiplicadores de poder/daño
- `blocks_status`, `blocks_critical`, `blocks_recoil`, `blocks_flinch`
- `prevents_escape`, `should_survive_with_sturdy`
- `redirect_single_target` (Lightning Rod en targeting)
- `speed_multiplier`, Technician, etc.

Illusion / Imposter / cambios de forma complejos pueden tener comandos `setup_illusion` más adelante o quedarse en código hasta Fase 2–3.

---

## Prioridad de implementación

### P0 — Ya / inmediato
- announce, message, chance, if, lower/raise_stat, status

### P1 — Cubrir ~80% de secuencias de habilidades
- for_each opponents, else
- damage_percent, heal_percent, cure_status
- set_weather, set_terrain
- status_random, infatuate
- if blocks_intimidate, has_ability, is_multi
- clear_screens, set_meta

### P2 — Intercambio de habilidades y dobles
- set_ability, swap_ability, copy_ability
- reset_stages, copy_stages
- ally targets

### P3 — Especiales
- setup_illusion, setup_imposter, form_change
- frisk (mensaje de objeto)

---

## Ejemplo: Intimidate completo

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

## Ejemplo: Rough Skin

```text
on_hit_by:
  if is_contact
	announce
	damage_percent 12.5 target=attacker
  endif
```

## Ejemplo: Drizzle

```text
on_switch_in:
  announce
  set_weather RAIN -1
```

## Ejemplo: Defiant (on_stat_drop)

```text
on_stat_drop:
  announce
  raise_stat ATK 2 target=user
```
