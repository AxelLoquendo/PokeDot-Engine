extends RefCounted
class_name BattleProtect
## Protect / Detect / Wide Guard / contact hazards.


static func resolve_move(battle: Object, actor: BattleBattler, move: MoveData) -> void:
	if actor == null or move == null:
		return
	var chance: float = 1.0
	chance = float(ProtectResolver.success_chance(actor.protect_counter))
	if randf() >= chance:
		BattleMessage.say(battle, "¡Pero falló!")
		await _w(battle, 0.8)
		actor.protect_counter = 0
		return

	actor.protect_counter += 1
	actor.used_protect_this_turn = true

	if move.effect == MoveStruct.MoveEffect.EFFECT_ENDURE:
		actor.endure_active = true
		BattleMessage.say(battle, "¡%s se preparó para resistir el golpe!" % actor.get_display_name())
	else:
		var pk: ProtectResolver.Kind = ProtectResolver.kind_for(move)
		if pk == ProtectResolver.Kind.WIDE_GUARD:
			_side(battle, actor).wide_guard_turns = 1
			BattleMessage.say(battle, "¡%s protegió a su equipo con Vastaguardia!" % actor.get_display_name())
		elif pk == ProtectResolver.Kind.QUICK_GUARD:
			_side(battle, actor).quick_guard_turns = 1
			BattleMessage.say(battle, "¡%s protegió a su equipo con Anticipo!" % actor.get_display_name())
		elif pk == ProtectResolver.Kind.CRAFTY_SHIELD:
			_side(battle, actor).crafty_shield_turns = 1
			BattleMessage.say(battle, "¡%s protegió a su equipo con Truco Defensa!" % actor.get_display_name())
		else:
			actor.protect_active = true
			actor.protect_kind = pk
			BattleMessage.say(battle, "¡%s se protegió!" % actor.get_display_name())
	await _w(battle, 0.8)


static func resolve_contact(
	battle: Object,
	actor: BattleBattler,
	target: BattleBattler,
	move: MoveData
) -> void:
	if actor == null or target == null or move == null:
		return
	if not AbilityRuntime.move_makes_contact(actor, move):
		return
	match target.protect_kind:
		ProtectResolver.Kind.SPIKY_SHIELD:
			@warning_ignore("integer_division")
			var dmg: int = maxi(1, int(actor.get_max_hp() / 8))
			actor.apply_damage(dmg)
			if battle.has_method("_emit_hp_battler"):
				battle._emit_hp_battler(actor)
			BattleMessage.say(battle, "¡%s se lastimó con las púas!" % actor.get_display_name())
			await _w(battle, 0.6)
		ProtectResolver.Kind.BANEFUL_BUNKER:
			await BattleStatChange.apply_status(battle, actor, PokemonInstance.Status.POISON)
		_:
			pass


static func _side(battle: Object, battler: BattleBattler) -> FieldSide:
	if battle.has_method("_side_for"):
		return battle._side_for(battler) as FieldSide
	return battle.player_side if battler.is_player_side else battle.enemy_side


static func _w(battle: Object, seconds: float) -> void:
	if battle.has_method("_wait"):
		await battle._wait(seconds)
	else:
		await Engine.get_main_loop().create_timer(seconds).timeout
