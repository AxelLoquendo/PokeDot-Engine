# Effect System — Arquitectura

## Objetivo

El BattleManager se convierte en un **administrador de estados y eventos**.  
La lógica de cada habilidad, efecto de movimiento y hold item vive en archivos `.txt` compuestos por comandos pequeños (Lego).

## Estructura

```
effect_system/
├── effect_context.gd      # Contexto que viaja con cada evento
├── effect_command.gd      # Clase base de un comando
├── effect_script.gd       # Script parseado (bloques por evento)
├── effect_parser.gd       # Parser de .txt → EffectScript
├── effect_runner.gd       # Ejecutor con chance/if
├── ability_system.gd      # Punto de entrada para habilidades
├── effect_bootstrap.gd    # Registro de comandos
├── commands/              # Un archivo por comando
│   ├── cmd_status.gd
│   ├── cmd_chance.gd
│   ├── cmd_message.gd
│   └── ...
└── scripts/
	├── abilities/         # intimidate.txt, static.txt, ...
	├── moves/             # EFFECT_ABSORB.txt, ...
	└── items/             # leftovers.txt, ...
```

## Eventos que emite el BattleManager

| Evento | Cuándo |
|--------|--------|
| `on_switch_in` | Un Pokémon entra al campo |
| `on_switch_out` | Un Pokémon sale del campo |
| `on_hit` | El usuario conecta un movimiento |
| `on_hit_by` | El usuario recibe un movimiento |
| `on_contact` | Alias útil cuando `is_contact == true` |
| `on_faint` | El usuario se debilita |
| `on_end_turn` | Final de turno |
| `on_stat_change` | Alguien cambia stats |
| `on_status` | Se aplica un estado |
| `on_weather` | Cambia el clima |
| `on_terrain` | Cambia el terreno |

## Cómo se integra (ejemplo)

```gdscript
# Dentro de BattleManager, después de un cambio de Pokémon:
var ctx := EffectContext.new(entering_battler, opponent, null, self)
AbilitySystem.on_event("on_switch_in", ctx)
# Los mensajes de ctx.messages se muestran en la UI
```

```gdscript
# Después de un golpe de contacto:
var ctx := EffectContext.new(defender, attacker, move, self)
ctx.attacker = attacker
ctx.is_contact = move.makes_contact
ctx.damage = damage_dealt
AbilitySystem.on_event("on_hit_by", ctx)
```

## Estado

`AbilityRuntime` es una **fachada pura**: no implementa efectos por `AbilityId`.
Toda la lógica de habilidad vive en `scripts/abilities/*.txt`.

Documentación de usuario: `docs/HABILIDADES.md`.

## Principio

> El código define las **piezas posibles**.  
> Los datos definen **cómo se combinan**.


## Cobertura

316 habilidades oficiales con `.txt` (se excluyen `CUSTOM_314` y `CUSTOM_317`).
Ver `docs/HABILIDADES.md`.
