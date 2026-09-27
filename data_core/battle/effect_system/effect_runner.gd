## Ejecutor con chance / if / else / for_each. Soporta await.
class_name EffectRunner
extends RefCounted


static func run_block(commands: Array, ctx: EffectContext) -> void:
	await _run_range(commands, 0, commands.size(), ctx)


static func _run_range(commands: Array, start: int, end: int, ctx: EffectContext) -> void:
	var i: int = start
	while i < end:
		var cmd: EffectCommand = commands[i] as EffectCommand
		var name: String = cmd.command_name.to_lower()

		if name == "chance":
			await cmd.execute(ctx)
			var success: bool = bool(ctx.get_meta("last_chance_success", true))
			var end_i: int = _find_matching(commands, i, "chance", "endchance")
			if success:
				await _run_range(commands, i + 1, end_i, ctx)
			i = end_i + 1
			continue

		if name == "endchance":
			i += 1
			continue

		if name == "if":
			var cond_ok: bool = _eval_condition(cmd, ctx)
			var else_i: int = _find_else(commands, i)
			var end_i: int = _find_matching(commands, i, "if", "endif")
			if cond_ok:
				var sub_end: int = else_i if else_i >= 0 else end_i
				await _run_range(commands, i + 1, sub_end, ctx)
			elif else_i >= 0:
				await _run_range(commands, else_i + 1, end_i, ctx)
			i = end_i + 1
			continue

		if name == "else" or name == "endif":
			i += 1
			continue

		if name == "for_each":
			var end_i: int = _find_matching(commands, i, "for_each", "end_for")
			var what: String = cmd.arg_string(0).to_lower()
			var list: Array[BattleBattler] = _foreach_list(what, ctx)
			for battler: BattleBattler in list:
				if battler == null or battler.is_fainted():
					continue
				ctx.set_meta("foreach_current", battler)
				await _run_range(commands, i + 1, end_i, ctx)
			if ctx.has_meta("foreach_current"):
				ctx.remove_meta("foreach_current")
			i = end_i + 1
			continue

		if name == "end_for":
			i += 1
			continue

		var cont: bool = await cmd.execute(ctx)
		if not cont:
			break
		i += 1


static func _find_matching(commands: Array, start: int, open_name: String, close_name: String) -> int:
	var depth: int = 0
	for i: int in range(start, commands.size()):
		var n: String = (commands[i] as EffectCommand).command_name.to_lower()
		if n == open_name:
			depth += 1
		elif n == close_name:
			depth -= 1
			if depth == 0:
				return i
	return commands.size() - 1


static func _find_else(commands: Array, if_index: int) -> int:
	var depth: int = 0
	for i: int in range(if_index, commands.size()):
		var n: String = (commands[i] as EffectCommand).command_name.to_lower()
		if n == "if":
			depth += 1
		elif n == "endif":
			depth -= 1
			if depth == 0:
				return -1
		elif n == "else" and depth == 1:
			return i
	return -1


static func _foreach_list(what: String, ctx: EffectContext) -> Array[BattleBattler]:
	var out: Array[BattleBattler] = []
	if ctx.battle == null or ctx.user == null:
		return out
	if what == "opponents" or what == "foes" or what == "all_opponents":
		if ctx.battle.has_method("get_opponents"):
			var foes: Array = ctx.battle.get_opponents(ctx.user)
			for f: Variant in foes:
				var b: BattleBattler = f as BattleBattler
				if b != null:
					out.append(b)
		elif ctx.target != null:
			out.append(ctx.target)
	elif what == "allies" or what == "ally":
		if ctx.battle.has_method("get_ally"):
			var ally: BattleBattler = ctx.battle.get_ally(ctx.user)
			if ally != null:
				out.append(ally)
	return out


static func _eval_condition(cmd: EffectCommand, ctx: EffectContext) -> bool:
	var cond: String = cmd.arg_string(0).to_lower()
	match cond:
		"is_contact":
			return ctx.is_contact
		"is_multi":
			return ctx.battle != null and ctx.battle.is_multi_battle()
		"blocks_intimidate":
			var who: BattleBattler = _current_or_target(ctx)
			return who != null and AbilityRuntime.blocks_intimidate(who)
		"has_ability":
			var who2: BattleBattler = _current_or_target(ctx)
			if who2 == null:
				return false
			var ab_name: String = cmd.arg_string(1).to_upper()
			var keys: Array = AbilityId.Id.keys()
			for i: int in range(keys.size()):
				if str(keys[i]) == ab_name:
					return AbilityRuntime.has(who2, i as AbilityId.Id)
			return false
		"hp_percent":
			var op: String = cmd.arg_string(1)
			var value: float = cmd.arg_float(2)
			var current: float = ctx.user_hp_percent() * 100.0
			return _compare(current, op, value)
		"weather":
			if ctx.battle == null:
				return false
			var want: String = cmd.arg_string(1).to_lower()
			var w: int = ctx.battle.get_effective_weather() if ctx.battle.has_method("get_effective_weather") else ctx.battle.weather
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
			return false
		"has_meta":
			var meta_key: String = cmd.arg_string(1)
			if ctx.user == null:
				return false
			if ctx.user.has_meta(meta_key) and bool(ctx.user.get_meta(meta_key)):
				return true
			if ctx.user.pokemon != null and ctx.user.pokemon.has_meta(meta_key):
				return bool(ctx.user.pokemon.get_meta(meta_key))
			# propiedades directas
			if meta_key == "zero_to_hero_transformed":
				return ctx.user.zero_to_hero_transformed
			return false
		_:
			push_warning("EffectRunner: condición desconocida '%s'" % cond)
			return false


static func _current_or_target(ctx: EffectContext) -> BattleBattler:
	if ctx.has_meta("foreach_current"):
		return ctx.get_meta("foreach_current") as BattleBattler
	return ctx.target if ctx.target != null else ctx.user


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
