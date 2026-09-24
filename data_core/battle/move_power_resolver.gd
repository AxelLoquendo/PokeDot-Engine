extends RefCounted
class_name MovePowerResolver

## Potencia efectiva y reglas de stats de ataque/defensa según MoveEffect.


static func effective_power(
	actor: BattleBattler,
	target: BattleBattler,
	move: MoveData,
	weather: int = 0
) -> int:
	if move == null:
		return 0
	var base: int = move.power
	if actor == null:
		return base
	match move.effect:
		MoveStruct.MoveEffect.EFFECT_FLAIL, \
		MoveStruct.MoveEffect.EFFECT_RETURN, \
		MoveStruct.MoveEffect.EFFECT_FRUSTRATION:
			var vp: int = FixedDamageResolver.variable_power(actor, move)
			return vp if vp > 0 else base
		MoveStruct.MoveEffect.EFFECT_STORED_POWER:
			return 20 + 20 * _positive_stages(actor)
		MoveStruct.MoveEffect.EFFECT_PUNISHMENT:
			return mini(200, 60 + 20 * _positive_stages(target))
		MoveStruct.MoveEffect.EFFECT_ELECTRO_BALL:
			return _electro_ball(actor, target)
		MoveStruct.MoveEffect.EFFECT_GYRO_BALL:
			return _gyro_ball(actor, target)
		MoveStruct.MoveEffect.EFFECT_HEAT_CRASH:
			return _weight_ratio_power(actor, target)
		MoveStruct.MoveEffect.EFFECT_LOW_KICK:
			return _weight_power(target)
		MoveStruct.MoveEffect.EFFECT_POWER_BASED_ON_USER_HP:
			return maxi(1, int(float(base) * float(actor.get_current_hp()) / float(maxi(actor.get_max_hp(), 1))))
		MoveStruct.MoveEffect.EFFECT_POWER_BASED_ON_TARGET_HP:
			if target == null:
				return base
			return maxi(1, int(120.0 * float(target.get_current_hp()) / float(maxi(target.get_max_hp(), 1))))
		MoveStruct.MoveEffect.EFFECT_BRINE:
			if target != null and target.get_current_hp() * 2 <= target.get_max_hp():
				return base * 2
			return base
		MoveStruct.MoveEffect.EFFECT_FACADE:
			if actor.pokemon != null and actor.pokemon.has_status():
				return base * 2
			return base
		MoveStruct.MoveEffect.EFFECT_ACROBATICS:
			if actor.pokemon != null and actor.pokemon.held_item == Items.ItemId.ITEM_NONE:
				return base * 2
			return base
		MoveStruct.MoveEffect.EFFECT_WEATHER_BALL:
			if weather != AbilityBattleEffect.weatherAbilityID.WEATHER_NONE:
				return base * 2
			return base
		MoveStruct.MoveEffect.EFFECT_DOUBLE_POWER_ON_ARG_STATUS:
			if target != null and target.pokemon != null and target.pokemon.has_status():
				return base * 2
			return base
		MoveStruct.MoveEffect.EFFECT_PAYBACK:
			if target != null and bool(target.get_meta("acted_this_turn", false)):
				return base * 2
			return base
		MoveStruct.MoveEffect.EFFECT_ASSURANCE:
			if target != null and bool(target.get_meta("took_damage_this_turn", false)):
				return base * 2
			return base
		MoveStruct.MoveEffect.EFFECT_RETALIATE:
			if bool(actor.get_meta("ally_fainted_last_turn", false)):
				return base * 2
			return base
		MoveStruct.MoveEffect.EFFECT_STOMPING_TANTRUM:
			if bool(actor.get_meta("move_failed_last_turn", false)):
				return base * 2
			return base
		MoveStruct.MoveEffect.EFFECT_LASH_OUT:
			if bool(actor.get_meta("stats_dropped_this_turn", false)):
				return base * 2
			return base
		MoveStruct.MoveEffect.EFFECT_BOLT_BEAK:
			if target != null and not bool(target.get_meta("acted_this_turn", false)):
				return base * 2
			return base
		MoveStruct.MoveEffect.EFFECT_REVENGE:
			if bool(actor.get_meta("took_damage_this_turn", false)):
				return base * 2
			return base
		MoveStruct.MoveEffect.EFFECT_ROLLOUT, \
		MoveStruct.MoveEffect.EFFECT_FURY_CUTTER, \
		MoveStruct.MoveEffect.EFFECT_ECHOED_VOICE:
			var n: int = int(actor.get_meta("combo_hits", 0))
			return mini(160, maxi(base, 1) * (1 << mini(n, 4)))
		MoveStruct.MoveEffect.EFFECT_SPIT_UP:
			var sp: int = actor.stockpile_count
			if sp <= 0:
				return 0
			return [0, 100, 200, 300][clampi(sp, 0, 3)]
		MoveStruct.MoveEffect.EFFECT_MAGNITUDE:
			return _magnitude_power()
		MoveStruct.MoveEffect.EFFECT_LAST_RESPECTS:
			return base + 50 * int(actor.get_meta("fainted_allies", 0))
		MoveStruct.MoveEffect.EFFECT_RAGE_FIST:
			return mini(350, base + 50 * int(actor.get_meta("times_hit", 0)))
		MoveStruct.MoveEffect.EFFECT_TRUMP_CARD:
			return 40
		_:
			return base


static func _positive_stages(b: BattleBattler) -> int:
	if b == null:
		return 0
	var n: int = 0
	for s: int in [
		b.stage_attack, b.stage_defense, b.stage_sp_attack,
		b.stage_sp_defense, b.stage_speed, b.stage_accuracy, b.stage_evasion
	]:
		if s > 0:
			n += s
	return n


static func _electro_ball(actor: BattleBattler, target: BattleBattler) -> int:
	if target == null:
		return 40
	var sa: float = float(maxi(actor.get_effective_stat(PokemonInstance.Stat.SPEED), 1))
	var st: float = float(maxi(target.get_effective_stat(PokemonInstance.Stat.SPEED), 1))
	var r: float = sa / st
	if r >= 4.0:
		return 150
	if r >= 3.0:
		return 120
	if r >= 2.0:
		return 80
	if r >= 1.0:
		return 60
	return 40


static func _gyro_ball(actor: BattleBattler, target: BattleBattler) -> int:
	if target == null:
		return 1
	var sa: int = maxi(actor.get_effective_stat(PokemonInstance.Stat.SPEED), 1)
	var st: int = maxi(target.get_effective_stat(PokemonInstance.Stat.SPEED), 1)
	return clampi(int(25.0 * float(st) / float(sa)), 1, 150)


static func _weight_power(target: BattleBattler) -> int:
	if target == null or target.pokemon == null:
		return 20
	var lv: int = target.pokemon.level
	if lv < 10:
		return 20
	if lv < 20:
		return 40
	if lv < 30:
		return 60
	if lv < 40:
		return 80
	if lv < 50:
		return 100
	return 120


static func _weight_ratio_power(actor: BattleBattler, target: BattleBattler) -> int:
	if actor == null or target == null:
		return 40
	var wa: float = float(maxi(actor.get_max_hp(), 1))
	var wt: float = float(maxi(target.get_max_hp(), 1))
	var r: float = wa / wt
	if r >= 5.0:
		return 120
	if r >= 4.0:
		return 100
	if r >= 3.0:
		return 80
	if r >= 2.0:
		return 60
	return 40


static func _magnitude_power() -> int:
	var roll: int = randi_range(0, 99)
	if roll < 5:
		return 10
	if roll < 15:
		return 30
	if roll < 35:
		return 50
	if roll < 65:
		return 70
	if roll < 85:
		return 90
	if roll < 95:
		return 110
	return 150


static func uses_defense_as_attack(move: MoveData) -> bool:
	return move != null and move.effect == MoveStruct.MoveEffect.EFFECT_BODY_PRESS


static func uses_target_attack(move: MoveData) -> bool:
	return move != null and move.effect == MoveStruct.MoveEffect.EFFECT_FOUL_PLAY


static func uses_defense_vs_special(move: MoveData) -> bool:
	return move != null and move.effect == MoveStruct.MoveEffect.EFFECT_PSYSHOCK
