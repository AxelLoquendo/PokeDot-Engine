extends RefCounted
class_name BattleEndTurn
## Fin de turno: residuales, clima, items, rooms, sides.


static func process(battle: Object) -> void:
	await process_standalone(battle)


static func process_standalone(battle: Object) -> void:
	if battle.get("battle_turn_count") != null:
		battle.battle_turn_count = int(battle.battle_turn_count) + 1
	await _tick_dynamax(battle)

	if battle.has_method("_process_position_timed_effects"):
		await battle._process_position_timed_effects()

	var weather: int = _weather(battle)
	if weather != 0:
		await _apply_weather_damage(battle, weather)

	for battler: BattleBattler in BattleUtil.get_all_actives(battle):
		if battler == null or battler.is_fainted():
			continue
		await AbilityRuntime.end_of_turn(battler, _weather(battle), battle)
		await _status_tick(battle, battler)
		await _binding_tick(battle, battler)
		if battler.leech_seeded:
			await _leech_tick(battle, battler)
		# Item leftovers / black sludge etc. vía HoldItemRuntime si existe
		# Hold item EOT: AbilityRuntime / HoldItemRuntime según el proyecto

	await _tick_side_conditions(battle)
	await _tick_field_effects(battle)

	for battler2: BattleBattler in BattleUtil.get_all_actives(battle):
		if battler2 != null:
			battler2.just_switched_in = false


static func _tick_dynamax(battle: Object) -> void:
	for b: BattleBattler in BattleUtil.get_all_actives(battle):
		if b != null:
			await BattleDynamax.tick_end_turn(battle, b)


static func _status_tick(battle: Object, battler: BattleBattler) -> void:
	if battler.pokemon == null:
		return
	var st: PokemonInstance.Status = battler.pokemon.status
	match st:
		PokemonInstance.Status.POISON:
			if AbilityRuntime.has(battler, AbilityId.Id.POISON_HEAL):
				return
			var dmg: int = maxi(1, battler.get_max_hp() / 8)
			battler.apply_damage(dmg)
			_ehpb(battle, battler)
			BattleMessage.say(battle, "¡%s sufre por el veneno!" % battler.get_display_name())
			await _w(battle, 0.5)
		PokemonInstance.Status.TOXIC:
			if AbilityRuntime.has(battler, AbilityId.Id.POISON_HEAL):
				return
			battler.toxic_counter = maxi(1, battler.toxic_counter) + 1 if "toxic_counter" in battler else 1
			var tstack: int = int(battler.toxic_counter) if "toxic_counter" in battler else 1
			var tdmg: int = maxi(1, battler.get_max_hp() * tstack / 16)
			battler.apply_damage(tdmg)
			_ehpb(battle, battler)
			BattleMessage.say(battle, "¡%s sufre por el veneno!" % battler.get_display_name())
			await _w(battle, 0.5)
		PokemonInstance.Status.BURN:
			var bdmg: int = maxi(1, battler.get_max_hp() / 16)
			battler.apply_damage(bdmg)
			_ehpb(battle, battler)
			BattleMessage.say(battle, "¡%s sufre por sus quemaduras!" % battler.get_display_name())
			await _w(battle, 0.5)
		_:
			pass


static func _binding_tick(battle: Object, battler: BattleBattler) -> void:
	if battler.partially_trapped_turns <= 0:
		return
	battler.partially_trapped_turns -= 1
	var dmg: int = maxi(1, battler.get_max_hp() / 8)
	battler.apply_damage(dmg)
	_ehpb(battle, battler)
	BattleMessage.say(battle, "¡%s sufre por el atrapamiento!" % battler.get_display_name())
	await _w(battle, 0.45)
	if battler.partially_trapped_turns <= 0:
		BattleMessage.say(battle, "¡%s se liberó!" % battler.get_display_name())
		await _w(battle, 0.4)


static func _leech_tick(battle: Object, battler: BattleBattler) -> void:
	if battle.has_method("_apply_leech_seed_tick"):
		await battle._apply_leech_seed_tick(battler)
		return
	var dmg: int = maxi(1, battler.get_max_hp() / 8)
	battler.apply_damage(dmg)
	_ehpb(battle, battler)
	BattleMessage.say(battle, "¡Las semillas drenan a %s!" % battler.get_display_name())
	await _w(battle, 0.45)


static func _apply_weather_damage(battle: Object, weather: int) -> void:
	if battle.has_method("_apply_weather_damage"):
		await battle._apply_weather_damage()
		return
	# Sand / Hail residual básico
	for battler: BattleBattler in BattleUtil.get_all_actives(battle):
		if battler == null or battler.is_fainted():
			continue
		# IDs concretos dependen de AbilityBattleEffect; daño genérico si weather activo
		pass


static func _tick_side_conditions(battle: Object) -> void:
	for side_player: bool in [true, false]:
		var side: FieldSide = battle.player_side if side_player else battle.enemy_side
		if side == null:
			continue
		if side.reflect_turns > 0:
			side.reflect_turns -= 1
		if side.light_screen_turns > 0:
			side.light_screen_turns -= 1
		if side.aurora_veil_turns > 0:
			side.aurora_veil_turns -= 1
		if side.mist_turns > 0:
			side.mist_turns -= 1
		if side.safeguard_turns > 0:
			side.safeguard_turns -= 1
		if side.tailwind_turns > 0:
			side.tailwind_turns -= 1
		if side.wide_guard_turns > 0:
			side.wide_guard_turns = 0
		if side.quick_guard_turns > 0:
			side.quick_guard_turns = 0
		if side.crafty_shield_turns > 0:
			side.crafty_shield_turns = 0


static func _tick_field_effects(battle: Object) -> void:
	# Rooms / gravity / weather / terrain
	if battle.get("trick_room_turns") != null:
		var tr: int = int(battle.trick_room_turns)
		if tr > 0:
			tr -= 1
			battle.trick_room_turns = tr
			if tr == 0:
				BattleMessage.say(battle, "¡El Espacio Raro se disipó!")
				await _w(battle, 0.5)
	if battle.get("wonder_room_turns") != null:
		var wr: int = int(battle.wonder_room_turns)
		if wr > 0:
			wr -= 1
			battle.wonder_room_turns = wr
	if battle.get("magic_room_turns") != null:
		var mr: int = int(battle.magic_room_turns)
		if mr > 0:
			mr -= 1
			battle.magic_room_turns = mr
	if battle.get("gravity_turns") != null:
		var gr: int = int(battle.gravity_turns)
		if gr > 0:
			gr -= 1
			battle.gravity_turns = gr
			if gr == 0:
				BattleMessage.say(battle, "¡La gravedad volvió a la normalidad!")
				await _w(battle, 0.5)
	if battle.get("weather_turns") != null and battle.get("weather_primal") != true:
		var wt: int = int(battle.weather_turns)
		if wt > 0:
			wt -= 1
			battle.weather_turns = wt
			if wt == 0 and battle.get("weather") != null:
				battle.weather = 0
				BattleMessage.say(battle, "¡El clima se estabilizó!")
				await _w(battle, 0.5)
	if battle.get("terrain_turns") != null:
		var tt: int = int(battle.terrain_turns)
		if tt > 0:
			tt -= 1
			battle.terrain_turns = tt
			if tt == 0:
				if battle.get("terrain") != null:
					battle.terrain = 0
				BattleMessage.say(battle, "¡El campo se normalizó!")
				await _w(battle, 0.5)


static func _noop() -> void:
	pass


static func _w(battle: Object, seconds: float) -> void:
	if battle.has_method("_wait"):
		await battle._wait(seconds)
	else:
		await Engine.get_main_loop().create_timer(seconds).timeout


static func _ehpb(battle: Object, battler: BattleBattler) -> void:
	if battle.has_method("_emit_hp_battler"):
		battle._emit_hp_battler(battler)


static func _weather(battle: Object) -> int:
	if battle.has_method("get_effective_weather"):
		return int(battle.get_effective_weather())
	return int(battle.weather) if battle.get("weather") != null else 0
