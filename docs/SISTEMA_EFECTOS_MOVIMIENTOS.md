# Sistema de efectos de movimientos — cobertura completa

## Principio

Todo efecto de **estado / campo / utility** va por `.txt` + comandos/specials.
Todo efecto de **cálculo de daño puro** queda en DamageCalculator / FixedDamageResolver / flags del BM
(no necesita script; si se pusiera script vacío se rompería el flujo de daño).

## Cableado BM

1. `_apply_status_move_effect` → `MoveSystem.run_on_use` (si hay script)
2. `_apply_damaging_move_effect` → `MoveSystem.run_on_hit`
3. `_apply_secondary_effect` → `MoveSystem.run_on_secondary`
4. Fallback: `match` legacy + resolvers

## Specials funcionales (CmdMoveSpecial)

Incluye Gen9 y casos raros:

| Special | Comportamiento |
|---------|----------------|
| power_split / guard_split | Promedia stats reales vía `split_stat_override` en battler |
| power_trick | Meta `power_trick` leída en `get_effective_stat` |
| nature_power | Elige tipo por terreno y ejecuta golpe 80 SpA |
| fillet_away | -50% PS, +2 Atk/SpA/Spe |
| tidy_up | Limpia hazards + substitutes, +1 Atk/Spe |
| transform, mimic, sketch, metronome, copycat, sleep_talk | Delega a métodos BM existentes |
| pain_split, psych_up, swaps, trick, curse, future_sight, bide… | Implementados en special |
| rest, protect/endure, belly_drum, court_change… | Implementados |

## Daño puro (sin script — correcto)

OHKO, Absorb, Dream Eater, Recoil, Struggle, Facade, multi-hit, Rollout,
Fixed/Level/Psywave, Endeavor, Final Gambit, False Swipe, Focus Punch,
Sucker Punch, Belch, First Turn Only, Poltergeist, Last Resort, Upper Hand,
Two Turns, Semi-invulnerable, Solar Beam, Hidden Power, Revelation Dance,
Terrain Boost, Photon Geyser, Shell Side Arm, Population Bomb, etc.

Estos **funcionan** por el path de daño del BM; no están "fuera".

## Archivos clave

- `move_system.gd`, `cmd_move_special.gd`, `effect_bootstrap.gd`
- `scripts/moves/*.txt` (~239)
- `battle_battler.gd` — `get_effective_stat` con split/power_trick
- `battle_manager.gd` — cableado + fallback power/guard split
