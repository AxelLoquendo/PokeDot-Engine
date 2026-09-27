# Sistema de habilidades

> **Guía práctica de uso (crear efectos, comandos, casos borde):** [`GUIA_SISTEMA_DE_EFECTOS.md`](GUIA_SISTEMA_DE_EFECTOS.md)

Las habilidades de combate **no se programan en GDScript por nombre**.  
Cada efecto vive en un archivo `.txt` compuesto por comandos pequeños (Lego).  
`AbilityRuntime` solo administra eventos y consultas: arma un `EffectContext` y llama a `AbilitySystem`.

Esto es el mismo criterio que los scripts de mapa y los entrenadores: el código define las **piezas posibles**; los datos definen **cómo se combinan**.

---

## Arquitectura

```
BattleManager
    │  emite momentos de combate (entra, golpea, fin de turno, …)
    ▼
AbilityRuntime          ← fachada tipada, sin lógica de habilidad concreta
    │  EffectContext
    ▼
AbilitySystem           ← carga scripts/abilities/<id>.txt
    │
    ▼
EffectRunner + comandos ← announce, multiply, raise_stat, status, …
```

| Capa | Responsabilidad | No debe |
|------|-----------------|---------|
| `BattleManager` | Turnos, daño, señales de UI | Conocer “qué hace Intimidate” |
| `AbilityRuntime` | Disparar eventos / devolver floats y bools | Tener `match AbilityId` ni efectos |
| `AbilitySystem` | Resolver el `.txt` de la habilidad activa | Pintar la ability bar |
| Comandos (`.gd`) | Piezas genéricas reutilizables | Mencionar una habilidad por nombre |
| Scripts (`.txt`) | Combinar piezas por habilidad | Código GDScript |

---

## Dónde viven los archivos

| Ruta | Contenido |
|------|-----------|
| `data_core/battle/ability_runtime.gd` | Fachada: `on_switch_in`, `speed_multiplier`, … |
| `data_core/battle/effect_system/` | Parser, runner, contexto, bootstrap |
| `data_core/battle/effect_system/commands/` | Un `.gd` por comando |
| `data_core/battle/effect_system/scripts/abilities/` | Un `.txt` por habilidad |
| `data_core/ability/resources/` | Catálogo `AbilityData` (nombre, gen, AI) |

Nombre del script: el enum `AbilityId.Id.SPEED_BOOST` → `speed_boost.txt` (minúsculas).

---

## Dos tipos de bloque en el `.txt`

### 1. Secuencias (async, pueden anunciar)

Se ejecutan cuando “pasa algo” visible: entrada, contacto, fin de turno, baya, etc.

```text
on_switch_in:
  announce
  lower_stat ATK 1 target=opponent caused_by_foe

on_end_turn:
  announce
  raise_stat SPEED 1 target=user

on_hit_by:
  if is_contact
    announce
    damage_percent 12.5 target=attacker
  endif
```

**Regla de la ability bar:** si la habilidad **hace algo** en este momento, el bloque debe incluir `announce`.  
Ejemplos: Speed Boost cada turno, Intimidate al entrar, Rough Skin al contacto.

### 2. Consultas (sync, sin announce)

El damage calc / orden de turnos **pregunta** un número o un bool.  
No hay mensajes ni espera.

```text
on_speed:
  if weather SUN
    multiply speed 2.0
  endif

on_power:
  if hp_percent <= 33.4
    if move_type FIRE
      multiply power 1.5
    endif
  endif

on_blocks_status:
  block_status SLEEP

on_sturdy:
  block
```

**No uses** `announce`, `heal`, `wait` ni `message` en consultas.

---

## Eventos de secuencia

| Evento | Cuándo lo dispara el runtime |
|--------|------------------------------|
| `on_switch_in` | Pokémon entra al campo |
| `on_switch_out` | Sale del campo |
| `on_hit` | El portador conecta un golpe |
| `on_hit_by` | El portador recibe un golpe |
| `on_damaged` | Tras bajar PS por un movimiento |
| `on_end_turn` | Fin de turno |
| `on_flinch` | Tras un flinch |
| `on_stat_drop` | Bajada de estadística causada por el rival |
| `on_berry_eaten` | Tras comer una baya |
| `on_move_use` | Al usar un movimiento (Protean / Libero) |
| `on_steal_item` | Tras golpear (Magician) |
| `on_hp_half` | Cruce de la mitad de PS (Wimp Out) |
| `on_booster` | Sol / terreno para Protosynthesis / Quark Drive |
| `on_foe_stat_up` | El rival sube stats (Opportunist) |
| `on_weather` | Cambia el clima |
| `on_hp_change` | Cambio relevante de PS (formas) |
| `on_dance` | Alguien usa un baile (Dancer) |
| `on_break_illusion` | Se rompe Illusion |

---

## Eventos de consulta

| Evento | Devuelve | API en `AbilityRuntime` |
|--------|----------|-------------------------|
| `on_immunity` | reacción string | `type_immunity_reaction` |
| `on_power` | `multiplier` | `power_multiplier` |
| `on_attack_stat` | `multiplier` | `attack_stat_multiplier` |
| `on_damage_taken` | `multiplier` | `damage_taken_multiplier` |
| `on_speed` | `multiplier` | `speed_multiplier` |
| `on_stab` / `on_crit` | `multiplier` | `stab_multiplier` / `crit_damage_multiplier` |
| `on_weight` | `multiplier` | `weight_multiplier` |
| `on_blocks_status` | bool | `blocks_status` |
| `on_blocks_critical` / `_flinch` / `_recoil` / `_confusion` | bool | los `blocks_*` |
| `on_blocks_stat_drop` | bool | `blocks_foe_stat_drop` |
| `on_blocks_intimidate` | bool | `blocks_intimidate` |
| `on_sturdy` | bool | `should_survive_with_sturdy` |
| `on_priority` | int | `priority_bonus` |
| `on_move_type` | tipo en `query_int` | `effective_move_type` |
| `on_always_crit` | bool | `always_crits` |
| `on_blocks_escape` | bool | `prevents_escape` (lado bloqueador) |
| `on_always_escape` | bool | `prevents_escape` (lado que huye) |
| `on_weather_immunity` | bool | `is_immune_to_weather_damage` |
| `on_removes_contact` | bool | `move_makes_contact` |
| `on_redirect` | `redirect_target` | `redirect_single_target` |
| `on_aura` / `on_ruin_stat` | `multiplier` | auras y Ruin (campo) |

---

## Comando `multiply`

Siempre escribe en `ctx.multiplier` (lo que devuelve `query_float`).

```text
multiply 1.5
multiply power 1.5
multiply speed 2.0
multiply damage_taken 0.5
multiply 3 / 4
```

El **canal** (`power`, `speed`, …) es opcional y documenta qué se multiplica.  
Acepta expresiones: `1.5`, `3 / 4`, `hp_percent / 100`.

---

## Comandos de presentación y efecto

| Comando | Ejemplo | Notas |
|---------|---------|--------|
| `announce` | `announce` / `announce target=current` | Ability bar |
| `message` | `message "¡{user} actuó!"` | Texto de combate |
| `raise_stat` / `lower_stat` | `raise_stat SPEED 1 target=user` | Stages |
| `status` | `status BURN target=attacker` | Estado primario |
| `cure_status` | `cure_status target=user` | Cura |
| `damage_percent` / `heal_percent` | `damage_percent 12.5 target=attacker` | Fracción de max PS |
| `set_weather` / `set_terrain` | `set_weather RAIN -1` | Campo |
| `chance` … `endchance` | `chance 30` | Probabilidad |
| `if` … `else` … `endif` | `if is_contact` | Condiciones |
| `for_each` … `end_for` | `for_each opponents` | Intimidate, etc. |
| `immunity` | `immunity immune GROUND` | Consulta de tipo |
| `block` / `block_status` | `block_status SLEEP` | Consultas bool |
| `setup_illusion` / `setup_imposter` | en `on_switch_in` | Formas especiales |

Lista completa y prioridad de implementación:  
`data_core/battle/effect_system/COMANDOS.md` y `CONSULTAS.md`.

---

## Condiciones `if` útiles

`is_contact`, `not …`, `move_type FIRE ICE`, `move_flag punching_move`,  
`category PHYSICAL`, `has_status BURN`, `target_has_status POISON`,  
`hp_percent <= 33.4`, `hp_full`, `weather SUN`, `terrain ELECTRIC`,  
`effectiveness > 1`, `was_critical`, `acted_after_target`, `target_just_switched`,  
`has_ability GUARD_DOG`, `blocks_intimidate`, `user_type GRASS`, `stat ATK`.

---

## Ejemplos completos

### Speed Boost (secuencia + announce cada turno)

```text
on_end_turn:
  announce
  raise_stat SPEED 1 target=user
```

### Chlorophyll (consulta de velocidad, sin announce)

```text
on_speed:
  if weather SUN
    multiply speed 2.0
  endif
```

### Blaze

```text
on_power:
  if hp_percent <= 33.4
    if move_type FIRE
      multiply power 1.5
    endif
  endif
```

### Intimidate

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

### Rough Skin

```text
on_hit_by:
  if is_contact
    announce
    damage_percent 12.5 target=attacker
  endif
```

### Levitate

```text
on_immunity:
  immunity immune GROUND unless=damages_airborne
```

---

## Cómo añadir una habilidad nueva

1. Añade el ID al enum `AbilityId` si no existe y el recurso `AbilityData` en `data_core/ability/resources/`.
2. Crea `data_core/battle/effect_system/scripts/abilities/<nombre_enum_en_minusculas>.txt`.
3. Elige eventos de secuencia y/o consulta.
4. Si hace falta una pieza nueva (p. ej. `steal_item`), añade un comando en `commands/` y regístralo en `EffectBootstrap`.
5. **No** escribas un `match` en `ability_runtime.gd`.
6. Prueba en combate; el validador de contenido puede avisar de scripts faltantes.

---

## Qué no va en `AbilityRuntime`

- `if has(battler, AbilityId.Id.X)` para decidir un efecto.
- `match get_id(battler)`.
- Mensajes o curaciones hardcodeadas por nombre de habilidad.
- Lógica de Illusion / Imposter / Magician fuera de comandos y `.txt`.

Sí puede: leer `ability_id`, construir contexto, iterar activos del campo para **preguntar** a cada script (`on_aura`, `on_ruin_stat`), devolver el resultado de la consulta.

---

## Integración en combate

Al arrancar la batalla:

```gdscript
EffectBootstrap.register_all()
```

El `BattleManager` solo llama a la fachada, por ejemplo:

```gdscript
await AbilityRuntime.on_switch_in(battler, opponent, self)
var spd: float = AbilityRuntime.speed_multiplier(battler, weather, terrain)
var power: float = AbilityRuntime.power_multiplier(attacker, move)
```

La UI reacciona a `battle.ability_announce` cuando un script ejecuta `announce`.

---

## Estabilidad y tipado

- API de `AbilityRuntime` y comandos con tipos explícitos (`BattleBattler`, `float`, `bool`, `AbilityId.Id`).
- Scripts desconocidos o vacíos: no-op (no rompen el combate).
- Condición o comando mal escrito: `push_warning` y el script continúa cuando es seguro.
- Caché de scripts en `AbilitySystem`; `clear_cache()` tras editar `.txt` en caliente (herramientas / debug).

---

## Relación con otras guías

| Documento | Enlace |
|-----------|--------|
| Arquitectura general | [ARQUITECTURA.md](ARQUITECTURA.md) |
| Combate y evoluciones | [COMBATE_Y_EVOLUCIONES.md](COMBATE_Y_EVOLUCIONES.md) |
| Datos Pokémon / catálogo | [DATOS_POKEMON.md](DATOS_POKEMON.md) |
| Scripts de campo (mismo estilo Lego) | [SISTEMA_DE_SCRIPTS.md](SISTEMA_DE_SCRIPTS.md) |
| Catálogo de comandos técnicos | `data_core/battle/effect_system/COMANDOS.md` |
| Consultas y aritmética | `data_core/battle/effect_system/CONSULTAS.md` |


---

## Cobertura

Hay **316 habilidades oficiales** con script de efecto.

- Enum `AbilityId.Id`: de `STENCH` (1) hasta las entradas posteriores a Gen 9 del proyecto.
- **Excluidas** (sin script de efecto de combate): `NONE`, `COUNT`, `CUSTOM_314`, `CUSTOM_317`.
- Cada una tiene archivo en `data_core/battle/effect_system/scripts/abilities/<nombre_en_minusculas>.txt`.

Para comprobar en local:

```bash
# Debe listar 316 archivos correspondientes a IDs oficiales
ls data_core/battle/effect_system/scripts/abilities/*.txt | wc -l
```

Las `CUSTOM_*` se reservan para contenido de usuario; no forman parte del set oficial.

Los comandos `special` (Download, Trace, Frisk, Moody, Perish Body, Schooling,
Neutralizing Gas, etc.) están implementados en `commands/cmd_special.gd`
(**47** piezas registradas en `EffectBootstrap`).
