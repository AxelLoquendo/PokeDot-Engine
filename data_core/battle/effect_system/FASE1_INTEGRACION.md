# Fase 1 — Integración

## 1. Copia estos archivos a tu proyecto

Sobrescribe / añade en `res://data_core/battle/effect_system/`:

- Todo lo de `commands/` (incluido `cmd_lower_stat.gd` nuevo)
- `ability_system.gd`, `effect_runner.gd`, `effect_bootstrap.gd`
- `scripts/abilities/intimidate.txt`, `static.txt`, `flame_body.txt`, `poison_point.txt`

## 2. En `BattleManager.start_battle` (al inicio)

```gdscript
EffectBootstrap.register_all()
```

## 3. En `AbilityRuntime.on_switch_in` — al principio, tras los null checks

```gdscript
static func on_switch_in(battler: BattleBattler, opponent: BattleBattler, battle: BattleManager) -> void:
	if battler == null or battler.pokemon == null or battle == null:
		return

	var aid: AbilityId.Id = get_id(battler)
	if AbilitySystem.has_script(aid):
		var ctx := EffectContext.new(battler, opponent, null, battle)
		await AbilitySystem.on_event("on_switch_in", ctx)
		return

	match aid:
		# ... el match de siempre, sin los case ya migrados
```

## 4. En `AbilityRuntime.on_contact_hit` (o como se llame) — igual

Al inicio, si `AbilitySystem.has_script(get_id(defender))`:

```gdscript
var ctx := EffectContext.new(defender, attacker, move, battle)
ctx.attacker = attacker
ctx.is_contact = move != null and move.makes_contact
await AbilitySystem.on_event("on_hit_by", ctx)
return
```

## 5. Quitar del match los case migrados

Cuando confirmes que funcionan, borra:

- `AbilityId.Id.INTIMIDATE` del `on_switch_in`
- `AbilityId.Id.STATIC`, `FLAME_BODY`, `POISON_POINT` del match de contacto

## 6. Probar

1. Combate con un Pokémon con Intimidate → debe bajar ATK del rival.
2. Golpe de contacto a Static → 30% paralizar.
3. Sin script → el match viejo sigue activo.

## Nombres de archivo

El sistema busca:

`AbilityId.Id.INTIMIDATE` → `intimidate.txt`

Si el enum usa otro nombre, renombra el `.txt` o ajusta `_id_to_filename`.
