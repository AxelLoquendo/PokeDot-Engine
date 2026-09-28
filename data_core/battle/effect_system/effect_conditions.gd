## Condiciones de `if` para el runner (consultas y secuencias).
class_name EffectConditions
extends RefCounted

const TYPE_NAMES: Dictionary = {
	"normal": 0, "fighting": 1, "flying": 2, "poison": 3, "ground": 4,
	"rock": 5, "bug": 6, "ghost": 7, "steel": 8, "fire": 9, "water": 10,
	"grass": 11, "electric": 12, "psychic": 13, "ice": 14, "dragon": 15,
	"dark": 16, "fairy": 17,
}


static func eval(cmd: EffectCommand, ctx: EffectContext) -> bool:
	if cmd.args.is_empty():
		return false
	var start: int = 0
	var negate: bool = false
	if cmd.arg_string(0).to_lower() == "not":
		negate = true
		start = 1
	var result: bool = _eval_from(cmd, ctx, start)
	return not result if negate else result


static func _eval_from(cmd: EffectCommand, ctx: EffectContext, start: int) -> bool:
	var cond: String = cmd.arg_string(start).to_lower()
	match cond:
		"is_contact":
			return ctx.is_contact or (ctx.move != null and ctx.move.makes_contact)
		"is_multi":
			return ctx.battle != null and ctx.battle.is_multi_battle()
		"hp_full":
			return ctx.user != null and ctx.user.pokemon != null \
				and ctx.user.pokemon.current_hp == ctx.user.pokemon.max_hp
		"was_critical":
			return ctx.was_critical
		"flash_fire_boosted":
			return ctx.user != null and ctx.user.flash_fire_boosted
		"charged":
			return ctx.user != null and ctx.user.charged
		"has_status":
			if ctx.user == null or ctx.user.pokemon == null:
				return false
			if start + 1 >= cmd.args.size():
				return ctx.user.pokemon.has_status()
			return _status_matches(ctx.user.pokemon.status, cmd.args, start + 1)
		"status":
			if ctx.user == null or ctx.user.pokemon == null:
				return false
			return _status_matches(ctx.user.pokemon.status, cmd.args, start + 1)
		"query_status":
			return _status_matches(ctx.query_status, cmd.args, start + 1)
		"move_type":
			return _move_type_matches(ctx, cmd.args, start + 1)
		"move_flag":
			return _move_flag_matches(ctx, cmd.arg_string(start + 1).to_lower())
		"category":
			return _category_matches(ctx, cmd.arg_string(start + 1).to_lower())
		"hp_percent":
			var op: String = cmd.arg_string(start + 1)
			var value: float = cmd.arg_float(start + 2)
			return _compare(ctx.user_hp_percent() * 100.0, op, value)
		"effectiveness":
			return _compare(ctx.effectiveness, cmd.arg_string(start + 1), cmd.arg_float(start + 2))
		"move_power":
			var powv: float = float(ctx.move.power) if ctx.move != null else 0.0
			return _compare(powv, cmd.arg_string(start + 1), cmd.arg_float(start + 2))
		"weather":
			return _weather_matches(ctx, cmd.arg_string(start + 1).to_lower())
		"terrain":
			return _terrain_matches(ctx, cmd.arg_string(start + 1).to_lower())
		"has_ability":
			return _has_ability(ctx, cmd.arg_string(start + 1).to_upper())
		"user_type":
			return _battler_has_type(ctx.user, cmd.arg_string(start + 1).to_lower())
		"target_type":
			return _battler_has_type(ctx.target, cmd.arg_string(start + 1).to_lower())
		"same_gender":
			return _same_gender(ctx)
		"blocks_intimidate":
			var who: BattleBattler = ctx.target if ctx.target != null else ctx.user
			return who != null and AbilityRuntime.blocks_intimidate(who)
		"has_meta":
			return _has_meta(ctx, cmd.arg_string(start + 1))
		"stat":
			return _stat_matches(ctx.query_int, cmd.arg_string(start + 1).to_lower())
		"acted_after_target":
			return ctx.acted_after_target
		"target_just_switched":
			return ctx.target_just_switched
		"target_has_status":
			if ctx.target == null or ctx.target.pokemon == null:
				return false
			if start + 1 >= cmd.args.size():
				return ctx.target.pokemon.has_status()
			return _status_matches(int(ctx.target.pokemon.status), cmd.args, start + 1)
		"same_side":
			if ctx.user == null or ctx.target == null:
				return false
			return ctx.user.is_player_side == ctx.target.is_player_side
		_:
			push_warning("EffectConditions: condición desconocida '%s'" % cond)
			return false


static func _status_matches(status: int, args: PackedStringArray, start: int) -> bool:
	if start >= args.size():
		return status != 0
	for i: int in range(start, args.size()):
		var n: String = args[i].to_lower()
		if n == "all":
			return status != int(PokemonInstance.Status.NONE)
		if n == "poison" and (status == int(PokemonInstance.Status.POISON) or status == int(PokemonInstance.Status.TOXIC)):
			return true
		if n == "toxic" and status == int(PokemonInstance.Status.TOXIC):
			return true
		if n == "burn" and status == int(PokemonInstance.Status.BURN):
			return true
		if n == "paralysis" and status == int(PokemonInstance.Status.PARALYSIS):
			return true
		if n == "sleep" and status == int(PokemonInstance.Status.SLEEP):
			return true
		if n == "freeze" and status == int(PokemonInstance.Status.FREEZE):
			return true
	return false


static func _move_type_matches(ctx: EffectContext, args: PackedStringArray, start: int) -> bool:
	if ctx.move == null:
		return false
	var mt: int = int(ctx.move.type)
	for i: int in range(start, args.size()):
		var n: String = args[i].to_lower()
		if TYPE_NAMES.has(n) and int(TYPE_NAMES[n]) == mt:
			return true
		# Also compare against PokemonData.Type if available
		if n == "ground" and mt == int(PokemonData.Type.TYPE_GROUND):
			return true
	# Fallback: name vs enum keys
	var keys: Array = PokemonData.Type.keys()
	for i2: int in range(start, args.size()):
		var want: String = "TYPE_" + args[i2].to_upper()
		for k: Variant in keys:
			if str(k) == want and int(PokemonData.Type[str(k)]) == int(ctx.move.type):
				return true
	return false


static func _move_flag_matches(ctx: EffectContext, flag: String) -> bool:
	if ctx.move == null:
		return false
	var m: MoveData = ctx.move
	match flag:
		"sound", "sound_move":
			return m.sound_move
		"ballistic", "ballistic_move", "bullet":
			return m.ballistic_move
		"wind", "wind_move":
			return m.wind_move
		"punch", "punching_move":
			return m.punching_move
		"bite", "biting_move":
			return m.biting_move
		"pulse", "pulse_move":
			return m.pulse_move
		"slice", "slicing_move":
			return m.slicing_move
		"contact", "makes_contact":
			return m.makes_contact
		"healing", "healing_move":
			return m.healing_move
		"recoil":
			return m.recoil_percent > 0
		"dance", "dance_move":
			return m.dance_move
		"damages_airborne":
			return m.damages_airborne
		"secondary":
			return m.secondary_chance > 0 \
				or m.secondary_effect != MoveStruct.SecondaryEffect.MOVE_EFFECT_NONE
	return false


static func _category_matches(ctx: EffectContext, cat: String) -> bool:
	var cat_id: int = -1
	if ctx.move != null:
		cat_id = int(ctx.move.category)
	elif ctx.move_category >= 0:
		cat_id = ctx.move_category
	else:
		return false
	match cat:
		"physical":
			return cat_id == int(MoveStruct.DamageCategory.PHYSICAL)
		"special":
			return cat_id == int(MoveStruct.DamageCategory.SPECIAL)
		"status":
			return cat_id == int(MoveStruct.DamageCategory.STATUS)
	return false


static func _weather_matches(ctx: EffectContext, want: String) -> bool:
	var w: int = ctx.weather
	if ctx.battle != null:
		w = ctx.battle.get_effective_weather() if ctx.battle.has_method("get_effective_weather") else ctx.battle.weather
	if w < 0:
		return false
	match want:
		"rain":
			return w == AbilityBattleEffect.weatherAbilityID.WEATHER_RAIN
		"sun", "drought":
			return w == AbilityBattleEffect.weatherAbilityID.WEATHER_DROUGHT
		"sand", "sandstorm":
			return w == AbilityBattleEffect.weatherAbilityID.WEATHER_SANDSTORM
		"snow", "hail":
			return w == AbilityBattleEffect.weatherAbilityID.WEATHER_SNOW
		"none":
			return w == AbilityBattleEffect.weatherAbilityID.WEATHER_NONE
		"strong_winds":
			return w == AbilityBattleEffect.weatherAbilityID.WEATHER_STRONG_WINDS
	return false


static func _terrain_matches(ctx: EffectContext, want: String) -> bool:
	var t: int = ctx.terrain
	if ctx.battle != null:
		t = ctx.battle.terrain
	if t < 0:
		return false
	match want:
		"electric":
			return t == BattleManager.TerrainId.TERRAIN_ELECTRIC
		"grassy", "grass":
			return t == BattleManager.TerrainId.TERRAIN_GRASSY
		"misty":
			return t == BattleManager.TerrainId.TERRAIN_MISTY
		"psychic":
			return t == BattleManager.TerrainId.TERRAIN_PSYCHIC
		"none":
			return t == BattleManager.TerrainId.TERRAIN_NONE
	return false


static func _has_ability(ctx: EffectContext, ab_name: String) -> bool:
	var who: BattleBattler = ctx.user
	if ctx.has_meta("foreach_current"):
		who = ctx.get_meta("foreach_current") as BattleBattler
	if who == null:
		return false
	var keys: Array = AbilityId.Id.keys()
	for i: int in range(keys.size()):
		if str(keys[i]) == ab_name:
			return AbilityRuntime.has(who, i as AbilityId.Id)
	return false


static func _battler_has_type(b: BattleBattler, type_name: String) -> bool:
	if b == null:
		return false
	var want: String = "TYPE_" + type_name.to_upper()
	var t1: PokemonData.Type = b.get_battle_type_1() if b.has_method("get_battle_type_1") else PokemonData.Type.TYPE_NONE
	var t2: PokemonData.Type = b.get_battle_type_2() if b.has_method("get_battle_type_2") else PokemonData.Type.TYPE_NONE
	var keys: Array = PokemonData.Type.keys()
	for k: Variant in keys:
		if str(k) == want:
			var v: int = int(PokemonData.Type[str(k)])
			return int(t1) == v or int(t2) == v
	return false


static func _same_gender(ctx: EffectContext) -> bool:
	if ctx.user == null or ctx.target == null or ctx.user.pokemon == null or ctx.target.pokemon == null:
		return false
	var a: PokemonData.Gender = ctx.user.pokemon.gender
	var d: PokemonData.Gender = ctx.target.pokemon.gender
	if a == PokemonData.Gender.GENDERLESS or d == PokemonData.Gender.GENDERLESS:
		return false
	return a == d


static func _stat_matches(stat_id: int, name: String) -> bool:
	match name:
		"atk", "attack":
			return stat_id == int(PokemonInstance.Stat.ATTACK)
		"def", "defense":
			return stat_id == int(PokemonInstance.Stat.DEFENSE)
		"spatk", "spa", "sp_attack":
			return stat_id == int(PokemonInstance.Stat.SP_ATTACK)
		"spdef", "spd", "sp_defense":
			return stat_id == int(PokemonInstance.Stat.SP_DEFENSE)
		"speed", "spe":
			return stat_id == int(PokemonInstance.Stat.SPEED)
	return false


static func _has_meta(ctx: EffectContext, meta_key: String) -> bool:
	if ctx.user == null:
		return false
	if ctx.user.has_meta(meta_key) and bool(ctx.user.get_meta(meta_key)):
		return true
	if ctx.user.pokemon != null and ctx.user.pokemon.has_meta(meta_key):
		return bool(ctx.user.pokemon.get_meta(meta_key))
	if meta_key == "zero_to_hero_transformed":
		return ctx.user.zero_to_hero_transformed
	return false


static func _compare(a: float, op: String, b: float) -> bool:
	match op:
		"<":
			return a < b
		"<=":
			return a <= b
		">":
			return a > b
		">=":
			return a >= b
		"==":
			return is_equal_approx(a, b)
		"!=":
			return not is_equal_approx(a, b)
	return false
