extends RefCounted
class_name BattleSwitchIn
## Entrada a campo: hazards, heals de slot (Wish / Healing Wish),
## habilidades on_switch_in. El orquestador pasa `battle` (BattleManager)
## porque hace falta message / _wait / _emit_hp / _apply_status.


## Aplica hazards al entrante. Devuelve true si el mon se debilitó.
static func apply_hazards(battle: Object, battler: BattleBattler) -> bool:
	if battler == null or battler.pokemon == null or battler.is_fainted():
		return false

	var side: FieldSide = _side_for(battle, battler)
	var t1: PokemonData.Type = battler.get_battle_type_1()
	var t2: PokemonData.Type = battler.get_battle_type_2()
	var is_flying: bool = (
		t1 == PokemonData.Type.TYPE_FLYING or t2 == PokemonData.Type.TYPE_FLYING
	)
	var airborne: bool = is_flying or AbilityRuntime.has(battler, AbilityId.Id.LEVITATE)
	var gravity_turns: int = int(battle.get("gravity_turns") if battle.get("gravity_turns") != null else 0)
	if gravity_turns > 0 or bool(battler.get_meta("gravity_active", false)):
		airborne = false
	if battler.magnet_rise_turns > 0:
		airborne = true
	var is_grounded: bool = not airborne

	# Stealth Rock
	if side.stealth_rock and not AbilityRuntime.blocks_indirect_damage(battler):
		var eff: float = TypeChart.get_effectiveness(PokemonData.Type.TYPE_ROCK, t1, t2)
		var dmg: int = maxi(1, int(float(battler.get_max_hp()) * 0.125 * eff))
		var taken: int = battler.apply_damage(dmg)
		_emit_hp(battle, battler)
		_msg(battle, "¡A %s le dañaron las Rocas Afiladas!" % battler.get_display_name())
		await _wait(battle, 0.6)
		if taken > 0 and battler.is_fainted():
			_msg(battle, "¡%s se debilitó!" % battler.get_display_name())
			await _wait(battle, 0.8)
			return true

	# Spikes
	if side.spikes_layers > 0 and is_grounded and not AbilityRuntime.blocks_indirect_damage(battler):
		var fraction: float = [0.0, 1.0 / 8.0, 1.0 / 6.0, 1.0 / 4.0][
			clampi(side.spikes_layers, 0, 3)
		]
		var dmg2: int = maxi(1, int(float(battler.get_max_hp()) * fraction))
		var taken2: int = battler.apply_damage(dmg2)
		_emit_hp(battle, battler)
		_msg(battle, "¡%s resultó herido por las Púas!" % battler.get_display_name())
		await _wait(battle, 0.6)
		if taken2 > 0 and battler.is_fainted():
			_msg(battle, "¡%s se debilitó!" % battler.get_display_name())
			await _wait(battle, 0.8)
			return true

	# Toxic Spikes
	if side.toxic_spikes_layers > 0 and is_grounded:
		var is_poison: bool = (
			t1 == PokemonData.Type.TYPE_POISON or t2 == PokemonData.Type.TYPE_POISON
		)
		var is_steel: bool = (
			t1 == PokemonData.Type.TYPE_STEEL or t2 == PokemonData.Type.TYPE_STEEL
		)
		if is_poison:
			side.toxic_spikes_layers = 0
			_msg(battle, "¡%s absorbió las Púas Tóxicas!" % battler.get_display_name())
			await _wait(battle, 0.6)
		elif not is_steel:
			var status: PokemonInstance.Status = (
				PokemonInstance.Status.TOXIC
				if side.toxic_spikes_layers >= 2
				else PokemonInstance.Status.POISON
			)
			await _apply_status(battle, battler, status)

	# Sticky Web
	if side.sticky_web and is_grounded:
		_msg(battle, "¡%s quedó atrapado en la Red Viscosa!" % battler.get_display_name())
		await _apply_stat_change(battle, battler, PokemonInstance.Stat.SPEED, -1, true)

	return battler.is_fainted()


## Secuencia completa al entrar: hazards → slot heals → ability on_switch_in.
static func on_enter(
	battle: Object,
	battler: BattleBattler,
	opponent: BattleBattler = null
) -> void:
	if battler == null or battler.pokemon == null:
		return

	if battle.has_method("_apply_slot_entry_heals"):
		await battle._apply_slot_entry_heals(battler)

	var fainted: bool = await apply_hazards(battle, battler)
	if fainted:
		return

	if opponent == null:
		var opps: Array[BattleBattler] = BattleUtil.get_opponents(battle, battler)
		opponent = opps[0] if not opps.is_empty() else null

	await AbilityRuntime.on_switch_in(battler, opponent, battle)


# ─── puentes al orquestador ─────────────────────────────────────────

static func _side_for(battle: Object, battler: BattleBattler) -> FieldSide:
	if battle.has_method("_side_for"):
		return battle._side_for(battler)
	if battle is BattleState:
		return (battle as BattleState).side_for(battler)
	return battle.player_side if battler.is_player_side else battle.enemy_side


static func _msg(battle: Object, text: String) -> void:
	if battle.has_signal("message"):
		battle.message.emit(text)
	elif battle.has_method("emit_signal"):
		battle.emit_signal("message", text)


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


static func _apply_status(
	battle: Object,
	battler: BattleBattler,
	status: PokemonInstance.Status
) -> void:
	await BattleStatChange.apply_status(battle, battler, status)


static func _apply_stat_change(
	battle: Object,
	battler: BattleBattler,
	stat: PokemonInstance.Stat,
	stages: int,
	caused_by_foe: bool
) -> void:
	if battle.has_method("_apply_stat_change"):
		await battle._apply_stat_change(battler, stat, stages, caused_by_foe)


## Cambio voluntario (acción SWITCH del turno).
static func execute_switch_action(battle: Object, action: BattleAction) -> void:
	if action == null or action.switch_to == null or action.actor == null:
		return
	var side_player: bool = action.actor.is_player_side
	var slot: int = action.actor.slot_index
	var name_out: String = action.actor.get_display_name()
	if action.actor.pokemon != null and not action.actor.is_fainted():
		_msg(battle, "¡%s, vuelve!" % name_out)
		await _wait(battle, 0.45)
	await AbilityRuntime.on_switch_out(action.actor, battle)
	AbilityRuntime.revert_transform(action.actor)
	action.actor.setup(action.switch_to, side_player, slot)
	if battle.has_method("mark_exp_participant"):
		battle.mark_exp_participant(action.switch_to)
	AbilityRuntime.prepare_illusion(action.actor, battle)
	if battle.has_method("_apply_slot_entry_heals"):
		await battle._apply_slot_entry_heals(action.actor)
	if battle.has_method("_sync_primary_refs"):
		battle._sync_primary_refs()
	elif battle is BattleMain:
		(battle as BattleMain).state.sync_primary_refs()
	_msg(battle, "¡Adelante, %s!" % action.actor.get_display_name())
	if battle.has_signal("pokemon_entered_field"):
		battle.pokemon_entered_field.emit(side_player)
	if battle.has_signal("battler_appearance_changed"):
		battle.battler_appearance_changed.emit(side_player)
	await _wait(battle, 0.6)
	await on_enter(battle, action.actor)
	_emit_hp(battle, action.actor)
