extends RefCounted
class_name BattleDamage
## Daño fijo / OHKO / multi-hit / estándar (extraído de BattleManager).


static func execute_special_or_standard(
	battle: Object,
	actor: BattleBattler,
	target: BattleBattler,
	move: MoveData,
	action: BattleAction
) -> void:
	if actor == null or target == null or move == null:
		return

	# Dream Eater: solo dormidos
	if move.effect == MoveStruct.MoveEffect.EFFECT_DREAM_EATER:
		if target.pokemon == null or target.pokemon.status != PokemonInstance.Status.SLEEP:
			BattleMessage.say(battle, "¡No surtirá efecto!")
			await _w(battle, 0.7)
			return

	# OHKO: precisión propia
	if move.effect == MoveStruct.MoveEffect.EFFECT_OHKO:
		if not FixedDamageResolver.ohko_hits(actor, target):
			BattleMessage.say(battle, "¡El ataque de %s falló!" % actor.get_display_name())
			await _w(battle, 0.8)
			return
		var ohko_dmg: int = FixedDamageResolver.compute_fixed(actor, target, move)
		if ohko_dmg < 0:
			BattleMessage.say(battle, "¡No surtirá efecto!")
			await _w(battle, 0.7)
			return
		BattleMessage.say(battle, "¡Es un golpe fulminante!")
		await _w(battle, 0.5)
		var ohko_dealt: int = _dmg(battle, target, ohko_dmg)
		_ehp(battle, target.is_player_side)
		BattleMessage.say(battle, "Hizo %d PS de daño." % ohko_dealt)
		await _w(battle, 0.6)
		if target.is_fainted():
			await BattleFaint.on_fainted(battle, target, actor)
		return

	# Fijo puro (sin fórmula)
	if move.effect == MoveStruct.MoveEffect.EFFECT_FIXED_PERCENT_DAMAGE \
			or move.effect == MoveStruct.MoveEffect.EFFECT_FIXED_HP_DAMAGE \
			or move.effect == MoveStruct.MoveEffect.EFFECT_LEVEL_DAMAGE \
			or move.effect == MoveStruct.MoveEffect.EFFECT_PSYWAVE \
			or move.effect == MoveStruct.MoveEffect.EFFECT_ENDEAVOR \
			or move.effect == MoveStruct.MoveEffect.EFFECT_FINAL_GAMBIT:
		if not DamageCalculator.check_hit(move, actor, target, _weather(battle)):
			BattleMessage.say(battle, "¡El ataque de %s falló!" % actor.get_display_name())
			await _w(battle, 0.8)
			return
		var fixed: int = FixedDamageResolver.compute_fixed(actor, target, move)
		if fixed <= 0:
			BattleMessage.say(battle, "¡No surtirá efecto!")
			await _w(battle, 0.7)
			return
		# Tipo inmunidad básica vía compute_hit type check: si effectiveness 0, fallar
		var probe: DamageCalculator.HitResult = DamageCalculator.compute_hit(actor, target, move, _weather(battle), false, BattleUtil.is_multi_battle(battle))
		if probe.effectiveness <= 0.0 or not probe.ability_immunity.is_empty():
			await _ability_imm(battle, target, move, probe)
			return
		var dealt_f: int = _dmg(battle, target, fixed)
		_ehp(battle, target.is_player_side)
		BattleMessage.say(battle, "Hizo %d PS de daño." % dealt_f)
		await _w(battle, 0.6)
		if move.effect == MoveStruct.MoveEffect.EFFECT_FINAL_GAMBIT:
			actor.apply_damage(actor.get_current_hp())
			_ehp(battle, actor.is_player_side)
			BattleMessage.say(battle, "¡%s se debilitó por su propio ataque!" % actor.get_display_name())
			await _w(battle, 0.7)
		if target.is_fainted():
			await BattleFaint.on_fainted(battle, target, actor)
		if actor.is_fainted():
			BattleMessage.say(battle, "¡%s se debilitó!" % actor.get_display_name())
			await _w(battle, 0.8)
		return

	# Flail / Return / Frustration / Absorb / Dream Eater / False Swipe: fórmula con potencia o flags
	if not DamageCalculator.check_hit(move, actor, target, _weather(battle)):
		if move.effect == MoveStruct.MoveEffect.EFFECT_RECOIL_IF_MISS:
			await _crash(battle, actor)
		else:
			BattleMessage.say(battle, "¡El ataque de %s falló!" % actor.get_display_name())
			await _w(battle, 0.8)
		return

	var hit_count: int = DamageCalculator.roll_hit_count(move)
	if move.is_multi_hit and AbilityRuntime.always_max_hits(actor):
		hit_count = move.max_hits
	var total_dealt: int = 0
	var last_result: DamageCalculator.HitResult = null
	var hits_landed: int = 0
	var saved_power: int = move.power
	var var_pow: int = FixedDamageResolver.variable_power(actor, move)
	if var_pow > 0:
		move.power = var_pow

	for i: int in hit_count:
		if target.is_fainted() or actor.is_fainted():
			break
		var screens: bool = _side(battle, target).has_screen(move.category == MoveStruct.DamageCategory.PHYSICAL)
		if AbilityRuntime.has(actor, AbilityId.Id.INFILTRATOR):
			screens = false
		var result: DamageCalculator.HitResult = DamageCalculator.compute_hit(
			actor, target, move, _weather(battle), screens, BattleUtil.is_multi_battle(battle)
		)
		last_result = result
		if result.effectiveness <= 0.0 or not result.ability_immunity.is_empty():
			if i == 0:
				await _ability_imm(battle, target, move, result)
			break
		var dealt: int = result.damage
		if move.effect == MoveStruct.MoveEffect.EFFECT_FALSE_SWIPE and dealt >= target.get_current_hp():
			dealt = maxi(0, target.get_current_hp() - 1)
		if dealt <= 0:
			continue
		dealt = target.apply_damage(dealt)
		total_dealt += dealt
		await _try_thaw(battle, target, move)
		hits_landed += 1
		_ehp(battle, target.is_player_side)
		if result.critical:
			BattleMessage.say(battle, "¡Un golpe crítico!")
			await _w(battle, 0.35)
		if move.is_multi_hit:
			BattleMessage.say(battle, "¡Golpe %d!" % hits_landed)
			await _w(battle, 0.25)
		else:
			BattleMessage.say(battle, "Hizo %d PS de daño." % dealt)
			await _w(battle, 0.45)
		if move.drain_percent > 0 or move.effect == MoveStruct.MoveEffect.EFFECT_ABSORB \
				or move.effect == MoveStruct.MoveEffect.EFFECT_DREAM_EATER:
			var drain_pct: int = move.drain_percent if move.drain_percent > 0 else 50
			await _drain(battle, actor, target, dealt, drain_pct)
		if move.recoil_percent > 0 and not actor.is_fainted():
			await _recoil(battle, actor, dealt, move.recoil_percent)
		if AbilityRuntime.move_makes_contact(actor, move):
			if target.beak_blast_armed:
				await BattleStatChange.apply_status(battle, actor, PokemonInstance.Status.BURN)
				target.beak_blast_armed = false
			await AbilityRuntime.on_contact_hit(actor, target, move, battle)
			var rh: int = HoldItemRuntime.rocky_helmet_damage(target, actor)
			if rh > 0 and not actor.is_fainted():
				actor.apply_damage(rh)
				_ehp(battle, actor.is_player_side)
				BattleMessage.say(battle, "¡%s fue herido por el Casco Dentado!" % actor.get_display_name())
				await _w(battle, 0.4)
			if target.shell_trap_armed and move.category == MoveStruct.DamageCategory.PHYSICAL:
				target.shell_trap_armed = false
				BattleMessage.say(battle, "¡La trampa de concha de %s se activó!" % target.get_display_name())
				await _w(battle, 0.4)

		if dealt > 0 and not target.is_fainted():
			await AbilityRuntime.on_damaged_by_move(target, actor, move, result.critical, battle)

	if var_pow > 0:
		move.power = saved_power

	if hits_landed > 1:
		BattleMessage.say(battle, "¡%d veces!" % hits_landed)
		await _w(battle, 0.5)
	if target.is_fainted():
		await BattleFaint.on_fainted(battle, target, actor)
	if actor.is_fainted():
		BattleMessage.say(battle, "¡%s se debilitó!" % actor.get_display_name())
		await _w(battle, 0.8)
	await _on_hit_effect(battle, actor, target, move, total_dealt)
	if move.secondary_effect != MoveStruct.SecondaryEffect.MOVE_EFFECT_NONE \
			and move.secondary_chance > 0 and not target.is_fainted() and hits_landed > 0 \
			and not AbilityRuntime.has(actor, AbilityId.Id.SHEER_FORCE):
		var chance_alt: int = move.secondary_chance
		if AbilityRuntime.has(actor, AbilityId.Id.SERENE_GRACE):
			chance_alt = mini(100, chance_alt * 2)
		if chance_alt >= 100 or randi_range(1, 100) <= chance_alt:
			await BattleStatChange.apply_secondary(battle, actor, target, move)




static func _w(battle: Object, seconds: float) -> void:
	if battle.has_method("_wait"):
		await battle._wait(seconds)
	else:
		await Engine.get_main_loop().create_timer(seconds).timeout


static func _ehp(battle: Object, is_player_side: bool) -> void:
	if battle.has_method("_emit_hp"):
		battle._emit_hp(is_player_side)


static func _ehpb(battle: Object, battler: BattleBattler) -> void:
	if battle.has_method("_emit_hp_battler"):
		battle._emit_hp_battler(battler)


static func _dmg(battle: Object, target: BattleBattler, amount: int) -> int:
	if target == null:
		return 0
	var dealt: int = target.apply_damage(amount)
	_ehpb(battle, target)
	return dealt


static func _weather(battle: Object) -> int:
	if battle.has_method("get_effective_weather"):
		return int(battle.get_effective_weather())
	return int(battle.weather) if battle.get("weather") != null else 0


static func _drain(battle: Object, actor: BattleBattler, target: BattleBattler, damage: int, percent: int) -> void:
	if actor == null or actor.heal_block_turns > 0:
		return
	var heal: int = maxi(1, int(float(damage) * float(percent) / 100.0))
	if actor.pokemon:
		actor.pokemon.apply_heal(heal)
	_ehpb(battle, actor)
	BattleMessage.say(battle, "¡%s recuperó PS!" % actor.get_display_name())
	await _w(battle, 0.45)


static func _recoil(battle: Object, actor: BattleBattler, damage: int, percent: int) -> void:
	if actor == null:
		return
	if AbilityRuntime.has(actor, AbilityId.Id.ROCK_HEAD) or AbilityRuntime.has(actor, AbilityId.Id.MAGIC_GUARD):
		return
	var rec: int = maxi(1, int(float(damage) * float(percent) / 100.0))
	actor.apply_damage(rec)
	_ehpb(battle, actor)
	BattleMessage.say(battle, "¡%s también se hizo daño!" % actor.get_display_name())
	await _w(battle, 0.45)


static func _ability_imm(battle: Object, target: BattleBattler, move: MoveData, result: Variant) -> void:
	if battle.has_method("ability_announce"):
		await battle.ability_announce(target)
	BattleMessage.say(battle, "¡No afecta a %s!" % target.get_display_name())
	await _w(battle, 0.6)


static func _on_hit_effect(battle: Object, actor: BattleBattler, target: BattleBattler, move: MoveData, damage: int) -> void:
	await BattleMoveEffects.try_on_hit(battle, actor, target, move, damage)


static func _side(battle: Object, battler: BattleBattler) -> FieldSide:
	if battle.has_method("_side_for"):
		return battle._side_for(battler) as FieldSide
	return battle.player_side if battler.is_player_side else battle.enemy_side


static func _crash(battle: Object, actor: BattleBattler) -> void:
	if actor == null:
		return
	@warning_ignore("integer_division")
	var dmg: int = maxi(1, int(actor.get_max_hp() / 2))
	actor.apply_damage(dmg)
	_ehpb(battle, actor)
	BattleMessage.say(battle, "¡%s se estrelló!" % actor.get_display_name())
	await _w(battle, 0.5)


static func _try_thaw(battle: Object, target: BattleBattler, move: MoveData) -> void:
	if target == null or target.pokemon == null or move == null:
		return
	if target.pokemon.status != PokemonInstance.Status.FREEZE:
		return
	# Fire moves thaw
	if move.type == PokemonData.Type.TYPE_FIRE:
		target.pokemon.status = PokemonInstance.Status.NONE
		BattleMessage.say(battle, "¡%s se descongeló!" % target.get_display_name())
		await _w(battle, 0.45)
