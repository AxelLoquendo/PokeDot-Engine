extends RefCounted
class_name BattleMoveResolution
## Pipeline de un movimiento (extraído de BattleManager._execute_move).

static func resolve_action(battle: Object, action: BattleAction) -> void:
	if action == null or action.actor == null:
		return
	match action.kind:
		BattleAction.Kind.MOVE:
			await execute_move(battle, action)
		BattleAction.Kind.SWITCH:
			await BattleSwitchIn.execute_switch_action(battle, action)
		BattleAction.Kind.RUN:
			pass


static func resolve_move(battle: Object, action: BattleAction) -> void:
	await execute_move(battle, action)


static func execute_move(battle: Object, action: BattleAction) -> void:
	# Pipeline modular puro

	if action == null or action.actor == null:
		return

	var spread_cont: bool = action.has_meta("_skip_pp") and bool(action.get_meta("_skip_pp"))
	if not spread_cont and AbilityRuntime.should_skip_turn(action.actor):
		if battle.has_method("ability_announce"):
			await battle.ability_announce(action.actor)
		_msg(battle, "¡%s holgazanea!" % action.actor.get_display_name())
		await _wait(battle, 0.8)
		return

	if not spread_cont and AbilityRuntime.check_infatuation_blocks_move(action.actor, battle):
		await _wait(battle, 0.8)
		return

	var actor: BattleBattler = action.actor
	var target: BattleBattler = action.target
	var move: MoveData = action.move
	if move == null:
		return

	if not _move_allowed_by_volatiles(actor, move):
		_msg(battle, "¡%s no puede usar %s!" % [actor.get_display_name(), move.move_name])
		await _wait(battle, 0.8)
		return

	if _is_multi(battle) and not action.has_meta("_multi_resolved"):
		var multi_targets: Array[BattleBattler] = _resolve_targets(battle, actor, move, target)
		if multi_targets.is_empty() and target != null and not target.is_fainted():
			multi_targets.append(target)
		if not multi_targets.is_empty():
			target = multi_targets[0]
			action.target = target
			if multi_targets.size() > 1:
				action.set_meta("_multi_rest", multi_targets.slice(1))
		action.set_meta("_multi_resolved", true)

	if not spread_cont and action.move_slot_index >= 0 and actor.pokemon != null:
		if action.move_slot_index < actor.pokemon.moves.size():
			var ms: PokemonMoveSlot = actor.pokemon.moves[action.move_slot_index]
			if ms != null and ms.current_pp > 0:
				ms.current_pp -= 1

	_msg(battle, "¡%s usó %s!" % [actor.get_display_name(), move.move_name])
	await _wait(battle, 0.55)

	if TwoTurnResolver.is_charge_move(move) and actor.charging_move == null:
		actor.charging_move = move
		_msg(battle, "¡%s se prepara!" % actor.get_display_name())
		await _wait(battle, 0.7)
		return
	if actor.charging_move != null:
		actor.charging_move = null

	if not await _check_fail_conditions(battle, actor, target, move):
		return

	actor.set_meta("acted_this_turn", true)
	_register_last_move(battle, actor, move)

	if TwoTurnResolver.is_recharge_move(move):
		actor.must_recharge = true

	if ProtectResolver.is_protect_move(move):
		await BattleProtect.resolve_move(battle, actor, move)
		return

	if target == null:
		await _apply_status_move(battle, actor, actor, move)
		return

	if target.semi_invulnerable:
		_msg(battle, "¡%s esquivó el ataque!" % target.get_display_name())
		await _wait(battle, 0.8)
		return

	var gravity_turns: int = int(battle.gravity_turns) if battle.get("gravity_turns") != null else 0
	if move.gravity_banned and gravity_turns > 0:
		_msg(battle, "¡Pero falló!")
		await _wait(battle, 0.6)
		return

	if await _blocked_by_protect(battle, actor, target, move):
		return

	if FixedDamageResolver.is_special_damage_effect(move.effect) \
			or move.effect == MoveStruct.MoveEffect.EFFECT_FALSE_SWIPE \
			or move.effect == MoveStruct.MoveEffect.EFFECT_DREAM_EATER \
			or move.effect == MoveStruct.MoveEffect.EFFECT_ABSORB:
		await BattleDamage.execute_special_or_standard(battle, actor, target, move, action)
		await _execute_multi_rest(battle, action, actor, move)
		return

	if move.category == MoveStruct.DamageCategory.STATUS or move.power <= 0:
		var locked: bool = _is_locked_on(actor, target)
		var weather: int = _effective_weather(battle)
		var status_hits: bool = locked or DamageCalculator.check_hit(move, actor, target, weather)
		if locked:
			target.locked_on_by_side = -1
		if not status_hits:
			_msg(battle, "¡El ataque de %s falló!" % actor.get_display_name())
			await _wait(battle, 0.8)
			return
		await _apply_status_move(battle, actor, target, move)
		await _execute_multi_rest(battle, action, actor, move)
		return

	await _execute_damage_path(battle, actor, target, move, action, false)
	await _execute_multi_rest(battle, action, actor, move)


static func _execute_damage_path(
	battle: Object,
	actor: BattleBattler,
	target: BattleBattler,
	move: MoveData,
	action: BattleAction,
	special: bool
) -> void:
	var weather: int = _effective_weather(battle)
	var locked: bool = _is_locked_on(actor, target)
	if locked:
		target.locked_on_by_side = -1

	if not locked and not DamageCalculator.check_hit(move, actor, target, weather):
		_msg(battle, "¡El ataque de %s falló!" % actor.get_display_name())
		await _wait(battle, 0.8)
		if move.effect == MoveStruct.MoveEffect.EFFECT_RECOIL_IF_MISS:
			await _apply_crash(battle, actor)
		return

	if special:
		await BattleDamage.execute_special_or_standard(battle, actor, target, move, action)
		return
		var fixed: int = 0
		fixed = int(FixedDamageResolver.compute_fixed(actor, target, move))
		if fixed > 0:
			var taken_f: int = target.apply_damage(fixed)
			_emit_hp(battle, target)
			_msg(battle, "¡%s perdió PS!" % target.get_display_name())
			await _wait(battle, 0.55)
			if target.is_fainted():
				await BattleFaint.on_fainted(battle, target, actor)
		return

	var result: Variant = DamageCalculator.calculate(actor, target, move, weather, false, _is_multi(battle))
	if result == null:
		return

	var ability_imm: String = ""
	if result is Dictionary:
		ability_imm = str(result.get("ability_immunity", ""))
	elif "ability_immunity" in result:
		ability_imm = str(result.ability_immunity)
	if ability_imm != "":
		_msg(battle, "¡No afecta a %s!" % target.get_display_name())
		await _wait(battle, 0.6)
		return

	var damage: int = 0
	if result is Dictionary:
		damage = int(result.get("damage", 0))
	elif "damage" in result:
		damage = int(result.damage)

	if damage <= 0:
		_msg(battle, "¡No afecta a %s!" % target.get_display_name())
		await _wait(battle, 0.6)
		return

	var taken: int = target.apply_damage(damage)
	target.set_meta("took_damage_this_turn", true)
	_emit_hp(battle, target)

	var is_crit: bool = false
	if result is Dictionary:
		is_crit = bool(result.get("critical", result.get("is_critical", false)))
	elif "is_critical" in result:
		is_crit = bool(result.is_critical)
	elif "critical" in result:
		is_crit = bool(result.critical)
	if is_crit:
		_msg(battle, "¡Un golpe crítico!")
		await _wait(battle, 0.4)

	_msg(battle, "¡%s perdió PS!" % target.get_display_name())
	await _wait(battle, 0.5)

	if move.drain_percent > 0:
		await _apply_drain(battle, actor, taken, move.drain_percent)
	if move.recoil_percent > 0:
		await _apply_recoil(battle, actor, taken, move.recoil_percent)

	# on_hit: scripts primero; si no hay script, match legacy del manager
	await BattleMoveEffects.try_on_hit(battle, actor, target, move, taken)

	if target.is_fainted():
		await BattleFaint.on_fainted(battle, target, actor)
		return

	if move.secondary_effect != MoveStruct.SecondaryEffect.MOVE_EFFECT_NONE \
			and not AbilityRuntime.has(actor, AbilityId.Id.SHEER_FORCE):
		var chance: int = move.secondary_chance
		if AbilityRuntime.has(actor, AbilityId.Id.SERENE_GRACE):
			chance = mini(100, chance * 2)
		if randi_range(1, 100) <= chance:
			if not await BattleMoveEffects.try_on_secondary(battle, actor, target, move):
				await BattleStatChange.apply_secondary(battle, actor, target, move)


static func _execute_multi_rest(
	battle: Object, action: BattleAction, actor: BattleBattler, move: MoveData
) -> void:
	if action == null or not action.has_meta("_multi_rest"):
		return
	var rest: Array = action.get_meta("_multi_rest")
	action.remove_meta("_multi_rest")
	for tg: Variant in rest:
		var tg_b: BattleBattler = tg as BattleBattler
		if tg_b == null or tg_b.is_fainted() or actor.is_fainted():
			continue
		var follow: BattleAction = BattleAction.make_move(actor, tg_b, move, action.move_slot_index)
		follow.set_meta("_skip_pp", true)
		follow.set_meta("_multi_resolved", true)
		await execute_move(battle, follow)


static func _check_fail_conditions(
	battle: Object, actor: BattleBattler, target: BattleBattler, move: MoveData
) -> bool:
	if move.effect == MoveStruct.MoveEffect.EFFECT_SUCKER_PUNCH:
		if target != null and (
			bool(target.get_meta("acted_this_turn", false))
			or bool(target.get_meta("chose_status_move", false))
		):
			_msg(battle, "¡Pero falló!")
			await _wait(battle, 0.6)
			return false
	if move.effect == MoveStruct.MoveEffect.EFFECT_BELCH:
		if actor.last_berry_id == 0:
			_msg(battle, "¡No surtirá efecto!")
			await _wait(battle, 0.6)
			return false
	if move.effect == MoveStruct.MoveEffect.EFFECT_FIRST_TURN_ONLY:
		if not actor.just_switched_in:
			_msg(battle, "¡Pero falló!")
			await _wait(battle, 0.6)
			return false
	if move.effect == MoveStruct.MoveEffect.EFFECT_POLTERGEIST:
		if target == null or target.pokemon == null \
				or target.pokemon.held_item == Items.ItemId.ITEM_NONE:
			_msg(battle, "¡Pero falló!")
			await _wait(battle, 0.6)
			return false
	return true


static func _blocked_by_protect(
	battle: Object, actor: BattleBattler, target: BattleBattler, move: MoveData
) -> bool:
	if move.ignores_protect or AbilityRuntime.ignores_protect_contact(actor, move):
		return false
	var tside: FieldSide = _side_for(battle, target)
	var blocked_side: bool = false
	if tside != null:
		if tside.wide_guard_turns > 0 and ProtectResolver.blocks_move(ProtectResolver.Kind.WIDE_GUARD, move):
			blocked_side = true
		elif tside.quick_guard_turns > 0 and ProtectResolver.blocks_move(ProtectResolver.Kind.QUICK_GUARD, move):
			blocked_side = true
		elif tside.crafty_shield_turns > 0 and ProtectResolver.blocks_move(ProtectResolver.Kind.CRAFTY_SHIELD, move):
			blocked_side = true
	if blocked_side or (target.protect_active and ProtectResolver.blocks_move(target.protect_kind, move)):
		_msg(battle, "¡%s se protegió del ataque!" % target.get_display_name())
		await _wait(battle, 0.8)
		await BattleProtect.resolve_contact(battle, actor, target, move)
		return true
	return false


static func _resolve_protect(battle: Object, actor: BattleBattler, move: MoveData) -> void:
	var success: bool = true
	if actor.protect_counter > 0:
		success = randf() < (1.0 / float(1 << mini(actor.protect_counter, 6)))
	if not success:
		_msg(battle, "¡Pero falló!")
		await _wait(battle, 0.6)
		actor.protect_counter = 0
		return
	actor.protect_active = true
	actor.protect_kind = ProtectResolver.Kind.BASIC
	actor.used_protect_this_turn = true
	actor.protect_counter += 1
	_msg(battle, "¡%s se protegió!" % actor.get_display_name())
	await _wait(battle, 0.6)


static func _apply_status_move(
	battle: Object, actor: BattleBattler, target: BattleBattler, move: MoveData
) -> void:
	await BattleSetEffect.apply(battle, actor, target, move)


static func _move_allowed_by_volatiles(actor: BattleBattler, move: MoveData) -> bool:
	if actor.taunt_turns > 0 and move.category == MoveStruct.DamageCategory.STATUS:
		return false
	if actor.disable_turns > 0 and int(move.move_id) == actor.disable_move_id:
		return false
	if actor.encore_turns > 0 and int(move.move_id) != actor.encore_move_id:
		return false
	if actor.torment_active and int(move.move_id) == actor.torment_last_move_id:
		return false
	return true


static func _is_locked_on(actor: BattleBattler, target: BattleBattler) -> bool:
	if target == null:
		return false
	return target.locked_on_by_side == (0 if actor.is_player_side else 1)


static func _register_last_move(battle: Object, actor: BattleBattler, move: MoveData) -> void:
	actor.last_move_used_id = int(move.move_id)
	if actor.torment_active:
		actor.torment_last_move_id = int(move.move_id)
	var skip: bool = (
		move.effect == MoveStruct.MoveEffect.EFFECT_MIRROR_MOVE
		or move.effect == MoveStruct.MoveEffect.EFFECT_COPYCAT
		or move.effect == MoveStruct.MoveEffect.EFFECT_METRONOME
		or move.effect == MoveStruct.MoveEffect.EFFECT_SLEEP_TALK
	)
	if not skip and battle.get("last_move_used_field") != null:
		battle.last_move_used_field = move
		battle.last_move_user_was_player = actor.is_player_side


static func _apply_drain(battle: Object, actor: BattleBattler, damage: int, percent: int) -> void:
	if actor.heal_block_turns > 0:
		return
	@warning_ignore("integer_division")
	var heal: int = maxi(1, int(float(damage) * float(percent) / 100.0))
	if actor.pokemon:
		actor.pokemon.apply_heal(heal)
	_emit_hp(battle, actor)
	_msg(battle, "¡%s recuperó PS!" % actor.get_display_name())
	await _wait(battle, 0.45)


static func _apply_recoil(battle: Object, actor: BattleBattler, damage: int, percent: int) -> void:
	if AbilityRuntime.has(actor, AbilityId.Id.ROCK_HEAD) \
			or AbilityRuntime.has(actor, AbilityId.Id.MAGIC_GUARD):
		return
	@warning_ignore("integer_division")
	var rec: int = maxi(1, int(float(damage) * float(percent) / 100.0))
	actor.apply_damage(rec)
	_emit_hp(battle, actor)
	_msg(battle, "¡%s también se hizo daño!" % actor.get_display_name())
	await _wait(battle, 0.45)


static func _apply_crash(battle: Object, actor: BattleBattler) -> void:
	@warning_ignore("integer_division")
	var dmg: int = maxi(1, actor.get_max_hp() / 2)
	actor.apply_damage(dmg)
	_emit_hp(battle, actor)
	_msg(battle, "¡%s se estrelló!" % actor.get_display_name())
	await _wait(battle, 0.5)


static func _resolve_targets(
	battle: Object, actor: BattleBattler, move: MoveData, chosen: BattleBattler
) -> Array[BattleBattler]:
	if battle.has_method("resolve_move_targets"):
		return battle.resolve_move_targets(actor, move, chosen)
	var slot: int = chosen.slot_index if chosen != null else -1
	return BattleUtil.resolve_move_targets(battle, actor, move, slot)


static func _is_multi(battle: Object) -> bool:
	if battle.has_method("is_multi_battle"):
		return battle.is_multi_battle()
	return false


static func _effective_weather(battle: Object) -> int:
	if battle.has_method("get_effective_weather"):
		return battle.get_effective_weather()
	return int(battle.weather) if battle.get("weather") != null else 0


static func _side_for(battle: Object, battler: BattleBattler) -> FieldSide:
	if battle.has_method("_side_for"):
		return battle._side_for(battler)
	return battle.player_side if battler.is_player_side else battle.enemy_side


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
