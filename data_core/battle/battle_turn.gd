
extends RefCounted
class_name BattleTurn
## Resolución de un turno completo: ordenar acciones → ejecutar → KO mid-turn → fin de turno.
## Extraído de BattleManager._resolve_turn_actions / _sort_actions.


static func resolve_actions(battle: Object, actions: Array[BattleAction]) -> void:
	actions = sort_actions(battle, actions)
	_reset_turn_flags(battle)
	_mark_planned_actions(actions)

	var i: int = 0
	while i < actions.size():
		var action: BattleAction = actions[i]
		if action == null or action.actor == null or action.actor.is_fainted():
			i += 1
			continue

		# Anti: el slot se rellenó con otro mon; no ejecutar el move del debilitado
		if action.kind == BattleAction.Kind.MOVE and action.actor_pokemon != null \
				and action.actor.pokemon != action.actor_pokemon:
			i += 1
			continue

		if action.kind == BattleAction.Kind.MOVE:
			if action.target != null and action.target.is_fainted():
				var alts: Array[BattleBattler] = BattleUtil.get_opponents(battle, action.actor)
				var retarget: BattleBattler = null
				for a: BattleBattler in alts:
					if a != null and not a.is_fainted():
						retarget = a
						break
				if retarget == null:
					i += 1
					continue
				action.target = retarget
			await BattleMoveResolution.execute_move(battle, action)

		elif action.kind == BattleAction.Kind.SWITCH:
			await BattleSwitchIn.execute_switch_action(battle, action)

		# After You / Quash podrían reordenar aquí (meta en actions)
		_apply_after_you_quash(actions, i)

		await BattleFaint.resolve_mid_turn(battle)
		if not _still_running(battle):
			return
		i += 1

	await BattleEndTurn.process(battle)
	_clear_just_switched_in(battle)
	await BattleFaint.request_end_turn_replacements(battle)

	if battle.has_signal("turn_ended"):
		battle.turn_ended.emit()
	_check_battle_end(battle)


static func sort_actions(battle: Object, actions: Array[BattleAction]) -> Array[BattleAction]:
	var keyed: Array = []
	var trick_room: int = 0
	if battle.get("trick_room_turns") != null:
		trick_room = int(battle.trick_room_turns)
	elif battle is BattleMain and (battle as BattleMain).state != null:
		trick_room = (battle as BattleMain).state.trick_room_turns

	for a: BattleAction in actions:
		if a == null:
			continue
		var pri: int = a.priority
		var spd: int = 0
		if a.actor != null and not a.actor.is_fainted():
			spd = a.actor.get_effective_stat(PokemonInstance.Stat.SPEED)
			if trick_room > 0:
				spd = -spd
		var tie: int = randi()
		keyed.append({"a": a, "pri": pri, "spd": spd, "tie": tie})

	keyed.sort_custom(func(x: Dictionary, y: Dictionary) -> bool:
		if int(x["pri"]) != int(y["pri"]):
			return int(x["pri"]) > int(y["pri"])
		if int(x["spd"]) != int(y["spd"]):
			return int(x["spd"]) > int(y["spd"])
		return int(x["tie"]) > int(y["tie"])
	)

	var out: Array[BattleAction] = []
	for k: Dictionary in keyed:
		out.append(k["a"] as BattleAction)
	return out


static func resolve_mid_turn_faints(battle: Object) -> void:
	await BattleFaint.resolve_mid_turn(battle)



# ─── internos ───────────────────────────────────────────────────────


static func _mark_planned_actions(actions: Array[BattleAction]) -> void:
	## Antes de ejecutar: marca quién eligió status (Sucker Punch / etc.).
	for a: BattleAction in actions:
		if a == null or a.actor == null:
			continue
		if a.actor.has_meta("chose_status_move"):
			a.actor.remove_meta("chose_status_move")
		if a.kind == BattleAction.Kind.MOVE and a.move != null:
			if a.move.category == MoveStruct.DamageCategory.STATUS or a.move.power <= 0:
				a.actor.set_meta("chose_status_move", true)


static func _reset_turn_flags(battle: Object) -> void:
	for battler: BattleBattler in _all_actives(battle):
		if battler == null:
			continue
		if not battler.used_protect_this_turn:
			battler.protect_counter = 0
		battler.used_protect_this_turn = false
		battler.protect_active = false
		battler.protect_kind = ProtectResolver.Kind.NONE
		battler.endure_active = false
		battler.destiny_bond_active = false
		battler.set_meta("acted_this_turn", false)
		if battler.has_meta("chose_status_move"):
			battler.remove_meta("chose_status_move")
		battler.beak_blast_armed = false
		battler.flinched = false
		battler.set_meta("took_damage_this_turn", false)
		battler.set_meta("stats_dropped_this_turn", false)
		if battler.has_meta("follow_me"):
			battler.remove_meta("follow_me")
		if battler.has_meta("helping_hand"):
			battler.remove_meta("helping_hand")


static func _clear_just_switched_in(battle: Object) -> void:
	for battler: BattleBattler in _all_actives(battle):
		if battler != null:
			battler.just_switched_in = false


static func _apply_after_you_quash(actions: Array[BattleAction], current_i: int) -> void:
	# Placeholder: After You / Quash reordenan pendientes vía meta en actor
	var j: int = current_i + 1
	while j < actions.size():
		var other: BattleAction = actions[j]
		if other == null or other.actor == null:
			j += 1
			continue
		if bool(other.actor.get_meta("after_you_pending", false)):
			other.actor.remove_meta("after_you_pending")
			actions.remove_at(j)
			actions.insert(current_i + 1, other)
			break
		if bool(other.actor.get_meta("quash_pending", false)):
			other.actor.remove_meta("quash_pending")
			actions.remove_at(j)
			actions.append(other)
			continue
		j += 1


static func _check_battle_end(battle: Object) -> void:
	var player_ok: bool = BattleUtil.side_has_conscious(battle, true) \
			or BattleUtil.party_has_reserve(battle, true)
	var enemy_ok: bool = BattleUtil.side_has_conscious(battle, false) \
			or BattleUtil.party_has_reserve(battle, false)

	# Si el lado activo está vacío y no hay reservas → fin
	if not BattleUtil.side_has_conscious(battle, true) \
			and not BattleUtil.party_has_reserve(battle, true):
		_set_running(battle, false)
		if battle.has_signal("battle_ended"):
			battle.battle_ended.emit(false)
	elif not BattleUtil.side_has_conscious(battle, false) \
			and not BattleUtil.party_has_reserve(battle, false):
		_set_running(battle, false)
		if battle.has_signal("battle_ended"):
			battle.battle_ended.emit(true)


static func _still_running(battle: Object) -> bool:
	if battle.get("is_running") != null:
		return bool(battle.is_running)
	return true


static func _set_running(battle: Object, value: bool) -> void:
	if battle.get("is_running") != null:
		battle.is_running = value


static func _all_actives(battle: Object) -> Array[BattleBattler]:
	if battle.has_method("get_all_actives"):
		return battle.get_all_actives()
	var result: Array[BattleBattler] = []
	for b: BattleBattler in _player_actives(battle):
		if b != null:
			result.append(b)
	for b2: BattleBattler in _enemy_actives(battle):
		if b2 != null:
			result.append(b2)
	return result


static func _player_actives(battle: Object) -> Array:
	return battle.player_actives if battle.get("player_actives") != null else []


static func _enemy_actives(battle: Object) -> Array:
	return battle.enemy_actives if battle.get("enemy_actives") != null else []


static func _trainer_name(battle: Object) -> String:
	var n: String = str(battle.get("trainer_name") if battle.get("trainer_name") != null else "")
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
