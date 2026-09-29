extends RefCounted
class_name BattleFaint
## Debilitamientos mid-turn / post-acción: abilities de KO, EXP, reemplazos.


static func on_fainted(
	battle: Object,
	fainted: BattleBattler,
	killer: BattleBattler
) -> void:
	if fainted == null:
		return
	_msg(battle, "¡%s se debilitó!" % fainted.get_display_name())
	await _wait(battle, 0.8)

	if killer != null and not killer.is_fainted():
		await AbilityRuntime.on_ko(killer, fainted, battle)
	await AbilityRuntime.on_faint(fainted, killer, battle)

	if battle.has_method("get_all_actives"):
		var actives: Array[BattleBattler] = battle.get_all_actives() as Array[BattleBattler]
		for obs: BattleBattler in actives:
			if obs != null and not obs.is_fainted() and obs != killer:
				await AbilityRuntime.on_any_faint(obs, fainted, battle)

	if fainted != null and _is_multi(battle):
		var ally: BattleBattler = BattleUtil.get_ally(battle, fainted)
		if ally != null and not ally.is_fainted():
			await AbilityRuntime.try_receiver_or_alchemy(ally, fainted, battle)

	if not fainted.is_player_side:
		await BattleExperience.award_from(battle, fainted)


## Tras una acción: rellena slots KO del rival; pide party al jugador.
static func resolve_mid_turn(battle: Object) -> void:
	await _replace_enemy_slots(battle)
	await _request_player_replacements(battle, true)


static func request_end_turn_replacements(battle: Object) -> void:
	await _replace_enemy_slots(battle)
	await _request_player_replacements(battle, false)


static func _replace_enemy_slots(battle: Object) -> void:
	var enemy_actives: Array[BattleBattler] = _typed_actives(battle, false)
	for eb: BattleBattler in enemy_actives:
		if eb == null:
			continue
		if eb.pokemon != null and not eb.is_fainted():
			continue
		if not BattleUtil.party_has_reserve(battle, false):
			continue
		var nuevo: PokemonInstance = BattleUtil.first_reserve(battle, false)
		if nuevo == null:
			continue
		var slot: int = eb.slot_index
		eb.setup(nuevo, false, slot)
		AbilityRuntime.prepare_illusion(eb, battle)
		var sender: String = _trainer_name(battle)
		_msg(battle, "¡%s envía a %s!" % [sender, eb.get_display_name()])
		if battle.has_signal("pokemon_entered_field"):
			battle.pokemon_entered_field.emit(false)
		if battle.has_signal("battler_appearance_changed"):
			battle.battler_appearance_changed.emit(false)
		await _wait(battle, 0.55)
		await BattleSwitchIn.on_enter(battle, eb)
		_emit_hp(battle, eb)


static func _request_player_replacements(battle: Object, mid_turn: bool) -> void:
	var need: bool = false
	var forced_slot: int = -1
	var player_actives: Array[BattleBattler] = _typed_actives(battle, true)
	for i: int in range(player_actives.size()):
		var pb: BattleBattler = player_actives[i]
		if pb != null and (pb.pokemon == null or pb.is_fainted()) \
				and BattleUtil.party_has_reserve(battle, true):
			need = true
			if forced_slot < 0:
				forced_slot = i
	if not need:
		return

	if forced_slot >= 0:
		battle.set_meta("forced_replace_slot", forced_slot)

	if battle.has_signal("player_must_switch"):
		battle.player_must_switch.emit()

	if battle.has_method("_await_forced_player_switch"):
		await battle._await_forced_player_switch(mid_turn)
	elif battle is BattleMain:
		await (battle as BattleMain).await_forced_player_switch(mid_turn)


static func _typed_actives(battle: Object, is_player: bool) -> Array[BattleBattler]:
	var result: Array[BattleBattler] = []
	var raw: Variant = battle.player_actives if is_player else battle.enemy_actives
	if raw is Array:
		for item: Variant in raw as Array:
			if item is BattleBattler:
				result.append(item as BattleBattler)
	return result


static func _is_multi(battle: Object) -> bool:
	if battle.has_method("is_multi_battle"):
		return bool(battle.is_multi_battle())
	return false


static func _trainer_name(battle: Object) -> String:
	var n: String = ""
	if battle.get("trainer_name") != null:
		n = str(battle.trainer_name)
	return n if not n.is_empty() else "El rival"


static func _msg(battle: Object, text: String) -> void:
	if battle.has_signal("message"):
		battle.message.emit(text)


static func _wait(battle: Object, seconds: float) -> void:
	if battle.has_method("_wait"):
		await battle._wait(seconds)
	else:
		await Engine.get_main_loop().create_timer(seconds).timeout


static func _emit_hp(battle: Object, battler: BattleBattler) -> void:
	if battle.has_method("_emit_hp_battler"):
		battle._emit_hp_battler(battler)
	elif battle.has_method("_emit_hp"):
		battle._emit_hp(battler.is_player_side)
