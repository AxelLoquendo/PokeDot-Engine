extends RefCounted
class_name FixedDamageResolver

## Daño no estándar (fase 2). No inventa efectos: solo MoveStruct.MoveEffect existentes.


static func is_special_damage_effect(effect: MoveStruct.MoveEffect) -> bool:
	match effect:
		MoveStruct.MoveEffect.EFFECT_OHKO, \
		MoveStruct.MoveEffect.EFFECT_FIXED_PERCENT_DAMAGE, \
		MoveStruct.MoveEffect.EFFECT_FIXED_HP_DAMAGE, \
		MoveStruct.MoveEffect.EFFECT_LEVEL_DAMAGE, \
		MoveStruct.MoveEffect.EFFECT_PSYWAVE, \
		MoveStruct.MoveEffect.EFFECT_ENDEAVOR, \
		MoveStruct.MoveEffect.EFFECT_FINAL_GAMBIT, \
		MoveStruct.MoveEffect.EFFECT_FLAIL, \
		MoveStruct.MoveEffect.EFFECT_RETURN, \
		MoveStruct.MoveEffect.EFFECT_FRUSTRATION:
			return true
		_:
			return false


## Potencia variable para Flail / Return / Frustration (0 = no aplica).
static func variable_power(actor: BattleBattler, move: MoveData) -> int:
	if actor == null or actor.pokemon == null or move == null:
		return 0
	match move.effect:
		MoveStruct.MoveEffect.EFFECT_FLAIL:
			return _flail_power(actor)
		MoveStruct.MoveEffect.EFFECT_RETURN:
			return clampi(int(float(actor.pokemon.friendship) / 2.5), 1, 102)
		MoveStruct.MoveEffect.EFFECT_FRUSTRATION:
			return clampi(int(float(255 - actor.pokemon.friendship) / 2.5), 1, 102)
		_:
			return 0


static func _flail_power(actor: BattleBattler) -> int:
	var max_hp: int = maxi(actor.get_max_hp(), 1)
	var hp: int = clampi(actor.get_current_hp(), 0, max_hp)
	var ratio: float = float(hp) / float(max_hp)
	if ratio > 0.6875:
		return 20
	if ratio > 0.3542:
		return 40
	if ratio > 0.2083:
		return 80
	if ratio > 0.1042:
		return 100
	if ratio > 0.0417:
		return 150
	return 200


## Calcula daño fijo. -1 = falló (OHKO nivel, etc.). 0 = sin efecto útil.
static func compute_fixed(
	actor: BattleBattler,
	target: BattleBattler,
	move: MoveData
) -> int:
	if actor == null or target == null or move == null or target.pokemon == null:
		return 0
	match move.effect:
		MoveStruct.MoveEffect.EFFECT_OHKO:
			if target.pokemon.level > actor.pokemon.level:
				return -1
			# Acierto se resuelve fuera; aquí el daño es PS actuales
			return target.get_current_hp()
		MoveStruct.MoveEffect.EFFECT_FIXED_HP_DAMAGE:
			# Dragon Rage / Sonic Boom: power del .tres = cantidad fija
			return maxi(1, move.power)
		MoveStruct.MoveEffect.EFFECT_FIXED_PERCENT_DAMAGE:
			# Super Fang: mitad de PS actuales (mín. 1)
			return maxi(1, int(target.get_current_hp() / 2))
		MoveStruct.MoveEffect.EFFECT_LEVEL_DAMAGE:
			# Seismic Toss / Night Shade
			return maxi(1, actor.pokemon.level)
		MoveStruct.MoveEffect.EFFECT_PSYWAVE:
			var factor: int = randi_range(50, 150)
			return maxi(1, int(actor.pokemon.level * factor / 100))
		MoveStruct.MoveEffect.EFFECT_ENDEAVOR:
			var diff: int = target.get_current_hp() - actor.get_current_hp()
			if diff <= 0:
				return 0
			return diff
		MoveStruct.MoveEffect.EFFECT_FINAL_GAMBIT:
			return maxi(1, actor.get_current_hp())
		_:
			return 0


## Precisión OHKO: 30% + (nivel_usuario - nivel_objetivo), máx 100.
static func ohko_hits(actor: BattleBattler, target: BattleBattler) -> bool:
	if actor == null or target == null or actor.pokemon == null or target.pokemon == null:
		return false
	if target.pokemon.level > actor.pokemon.level:
		return false
	if AbilityRuntime.has(actor, AbilityId.Id.NO_GUARD) or AbilityRuntime.has(target, AbilityId.Id.NO_GUARD):
		return true
	var chance: int = 30 + (actor.pokemon.level - target.pokemon.level)
	chance = clampi(chance, 1, 100)
	return randi_range(1, 100) <= chance
