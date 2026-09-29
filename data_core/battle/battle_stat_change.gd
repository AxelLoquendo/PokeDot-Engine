extends RefCounted
class_name BattleStatChange
## Cambios de stats y estados no volátiles / confusión.


static func apply(
	battle: Object,
	battler: BattleBattler,
	stat: PokemonInstance.Stat,
	stages: int,
	caused_by_foe: bool = false
) -> void:
	if battler == null or stages == 0:
		return

	# Clear Body / White Smoke / Full Metal Body bloquean bajadas del rival
	if stages < 0 and caused_by_foe:
		if AbilityRuntime.has(battler, AbilityId.Id.CLEAR_BODY) \
				or AbilityRuntime.has(battler, AbilityId.Id.WHITE_SMOKE) \
				or AbilityRuntime.has(battler, AbilityId.Id.FULL_METAL_BODY):
			if battle.has_method("ability_announce"):
				await battle.ability_announce(battler)
			_msg(battle, "¡Las características de %s no bajan!" % battler.get_display_name())
			await _wait(battle, 0.55)
			return
		# Mist
		var side: FieldSide = _side_for(battle, battler)
		if side != null and side.mist_turns > 0:
			_msg(battle, "¡La Neblina protege al equipo de %s!" % battler.get_display_name())
			await _wait(battle, 0.5)
			return

	var changed: int = 0
	match stat:
		PokemonInstance.Stat.ATTACK, PokemonInstance.Stat.DEFENSE, \
		PokemonInstance.Stat.SP_ATTACK, PokemonInstance.Stat.SP_DEFENSE, \
		PokemonInstance.Stat.SPEED:
			changed = battler.modify_stage(stat, stages)
		_:
			pass

	if changed == 0:
		var msg: String = (
			"¡Las características de %s no pueden subir más!"
			if stages > 0
			else "¡Las características de %s no pueden bajar más!"
		)
		_msg(battle, msg % battler.get_display_name())
		await _wait(battle, 0.45)
		return

	if stages < 0:
		battler.set_meta("stats_dropped_this_turn", true)

	var name: String = _stat_name(stat)
	var verb: String = _stage_verb(changed)
	_msg(battle, "¡%s de %s %s!" % [name, battler.get_display_name(), verb])
	await _wait(battle, 0.5)

	# Mirror Armor / Defiant / Competitive hooks
	if stages < 0 and caused_by_foe and battle.has_method("ability_change_stat"):
		pass  # AbilityRuntime scripts on_stat_lowered


static func apply_status(
	battle: Object,
	battler: BattleBattler,
	status: PokemonInstance.Status
) -> void:
	if battler == null or battler.pokemon == null:
		return
	if battler.pokemon.has_status():
		return
	# Safeguard
	var side: FieldSide = _side_for(battle, battler)
	if side != null and side.safeguard_turns > 0:
		_msg(battle, "¡%s está protegido por Velo Sagrado!" % battler.get_display_name())
		await _wait(battle, 0.5)
		return
	battler.pokemon.status = status
	_msg(battle, _status_message(battler, status))
	await _wait(battle, 0.55)
	if battle.has_method("_emit_hp_battler"):
		battle._emit_hp_battler(battler)


static func apply_confusion(battle: Object, battler: BattleBattler) -> void:
	if battler == null:
		return
	if battler.confusion_turns > 0:
		return
	battler.confusion_turns = randi_range(2, 5)
	_msg(battle, "¡%s se confundió!" % battler.get_display_name())
	await _wait(battle, 0.5)


static func apply_secondary(
	battle: Object,
	actor: BattleBattler,
	target: BattleBattler,
	move: MoveData
) -> void:
	if move == null:
		return
	# Delegación mínima; el match completo sigue en BattleManager._apply_secondary_effect
	match move.secondary_effect:
		MoveStruct.SecondaryEffect.MOVE_EFFECT_FLINCH:
			if target != null:
				target.flinched = true
		MoveStruct.SecondaryEffect.MOVE_EFFECT_POISON:
			await apply_status(battle, target, PokemonInstance.Status.POISON)
		MoveStruct.SecondaryEffect.MOVE_EFFECT_BURN:
			await apply_status(battle, target, PokemonInstance.Status.BURN)
		MoveStruct.SecondaryEffect.MOVE_EFFECT_PARALYSIS:
			await apply_status(battle, target, PokemonInstance.Status.PARALYSIS)
		MoveStruct.SecondaryEffect.MOVE_EFFECT_CONFUSION:
			await apply_confusion(battle, target)
		_:
			pass


static func _stat_name(stat: PokemonInstance.Stat) -> String:
	match stat:
		PokemonInstance.Stat.ATTACK: return "El Ataque"
		PokemonInstance.Stat.DEFENSE: return "La Defensa"
		PokemonInstance.Stat.SP_ATTACK: return "El At. Esp."
		PokemonInstance.Stat.SP_DEFENSE: return "La Def. Esp."
		PokemonInstance.Stat.SPEED: return "La Velocidad"
		_: return "La característica"


static func _stage_verb(changed: int) -> String:
	var a: int = absi(changed)
	if changed > 0:
		if a >= 3:
			return "subió muchísimo"
		if a == 2:
			return "subió mucho"
		return "subió"
	if a >= 3:
		return "bajó muchísimo"
	if a == 2:
		return "bajó mucho"
	return "bajó"


static func _status_message(battler: BattleBattler, status: PokemonInstance.Status) -> String:
	var n: String = battler.get_display_name()
	match status:
		PokemonInstance.Status.POISON: return "¡%s fue envenenado!" % n
		PokemonInstance.Status.TOXIC: return "¡%s fue gravemente envenenado!" % n
		PokemonInstance.Status.BURN: return "¡%s se ha quemado!" % n
		PokemonInstance.Status.PARALYSIS: return "¡%s está paralizado! ¡Quizá no se pueda mover!" % n
		PokemonInstance.Status.SLEEP: return "¡%s se durmió!" % n
		PokemonInstance.Status.FREEZE: return "¡%s se ha congelado!" % n
		_: return "¡%s sufrió un problema de estado!" % n


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
