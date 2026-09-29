extends RefCounted
class_name BattleExperience
## Reparto de EXP al derrotar un Pokémon rival.


static func award_from(battle: Object, fainted_enemy: BattleBattler) -> void:
	if fainted_enemy != null and fainted_enemy.is_transformed:
		AbilityRuntime.revert_transform(fainted_enemy)
	if fainted_enemy == null or fainted_enemy.pokemon == null:
		return

	var awarded: Dictionary = _exp_map(battle)
	var eid: int = fainted_enemy.pokemon.get_instance_id()
	if bool(awarded.get(eid, false)):
		return
	awarded[eid] = true
	_set_exp_map(battle, awarded)

	var species: PokemonDataStruct = fainted_enemy.pokemon.get_species()
	if species == null:
		return

	var base_yield: int = 0
	if "exp_yield" in species:
		base_yield = int(species.exp_yield)
	if base_yield <= 0:
		base_yield = 1

	var is_trainer: bool = bool(battle.is_trainer_battle) if battle.get("is_trainer_battle") != null else false
	var trainer_mult: float = 1.5 if is_trainer else 1.0

	var participants: Array[PokemonInstance] = _participants(battle)
	var recipients: Array[PokemonInstance] = []
	for mon: PokemonInstance in participants:
		if mon != null and not mon.is_fainted():
			recipients.append(mon)

	if recipients.is_empty():
		var player_b: BattleBattler = battle.player as BattleBattler if battle.get("player") != null else null
		if player_b != null and player_b.pokemon != null and not player_b.is_fainted():
			recipients.append(player_b.pokemon)
	if recipients.is_empty():
		return

	var split: int = recipients.size()
	var total: int = maxi(
		1,
		int(floor(float(base_yield * fainted_enemy.pokemon.level) / 7.0 * trainer_mult))
	)
	var each: int = maxi(1, int(floor(float(total) / float(split))))

	for mon2: PokemonInstance in recipients:
		_msg(battle, "¡%s ganó %d puntos de experiencia!" % [mon2.get_display_name(), each])
		await _wait(battle, 0.55)
		if mon2.has_method("gain_evs_from_yield"):
			mon2.gain_evs_from_yield(species)
		var result: Dictionary = mon2.gain_exp(each) as Dictionary
		_refresh_if_active(battle, mon2)
		var levels: int = int(result.get("levels_gained", 0))
		if levels > 0:
			_msg(battle, "¡%s subió a nivel %d!" % [mon2.get_display_name(), mon2.level])
			await _wait(battle, 0.8)
			_refresh_if_active(battle, mon2)
			var learned: Array = result.get("learned_moves", []) as Array
			for move_id_v: Variant in learned:
				var move_id: Moves.MoveId = move_id_v as Moves.MoveId
				var move_data: MoveData = MoveDatabase.get_move(move_id)
				var move_name: String = move_data.move_name if move_data != null else "un movimiento"
				_msg(battle, "¡%s aprendió %s!" % [mon2.get_display_name(), move_name])
				await _wait(battle, 0.75)
			var pending: Array = result.get("pending_moves", []) as Array
			for move_id2_v: Variant in pending:
				var move_id2: Moves.MoveId = move_id2_v as Moves.MoveId
				if battle.has_method("_try_learn_move_interactive"):
					await battle._try_learn_move_interactive(mon2, move_id2)
			if battle.has_method("_check_evolution"):
				var battler_evo: BattleBattler = _find_battler_for_mon(battle, mon2)
				if battler_evo != null:
					await battle._check_evolution(battler_evo)


static func mark_participant(battle: Object, mon: PokemonInstance) -> void:
	if mon == null:
		return
	var list: Array[PokemonInstance] = _participants(battle)
	for existing: PokemonInstance in list:
		if existing == mon:
			return
	list.append(mon)
	if battle.get("exp_participants") != null:
		battle.exp_participants = list
	elif battle is BattleMain:
		(battle as BattleMain).state.exp_participants = list


static func _participants(battle: Object) -> Array[PokemonInstance]:
	var raw: Variant = battle.get("exp_participants")
	var result: Array[PokemonInstance] = []
	if raw is Array:
		for item: Variant in raw as Array:
			if item is PokemonInstance:
				result.append(item as PokemonInstance)
	return result


static func _exp_map(battle: Object) -> Dictionary:
	if battle is BattleMain:
		return (battle as BattleMain).state.exp_awarded_to
	var raw: Variant = battle.get("_exp_awarded_to")
	if raw is Dictionary:
		return raw as Dictionary
	return {}


static func _set_exp_map(battle: Object, map: Dictionary) -> void:
	if battle is BattleMain:
		(battle as BattleMain).state.exp_awarded_to = map
	elif battle.get("_exp_awarded_to") != null:
		battle._exp_awarded_to = map


static func _find_battler_for_mon(battle: Object, mon: PokemonInstance) -> BattleBattler:
	if battle.has_method("get_all_actives"):
		var actives: Array[BattleBattler] = battle.get_all_actives() as Array[BattleBattler]
		for b: BattleBattler in actives:
			if b != null and b.pokemon == mon:
				return b
	return null


static func _refresh_if_active(battle: Object, mon: PokemonInstance) -> void:
	var player_b: BattleBattler = battle.player as BattleBattler if battle.get("player") != null else null
	if player_b != null and player_b.pokemon == mon:
		if battle.has_method("_emit_hp"):
			battle._emit_hp(true)
		if battle.has_signal("player_progress_changed"):
			battle.player_progress_changed.emit()


static func _msg(battle: Object, text: String) -> void:
	if battle.has_signal("message"):
		battle.message.emit(text)


static func _wait(battle: Object, seconds: float) -> void:
	if battle.has_method("_wait"):
		await battle._wait(seconds)
	else:
		await Engine.get_main_loop().create_timer(seconds).timeout
