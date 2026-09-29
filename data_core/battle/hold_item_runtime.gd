extends RefCounted
class_name HoldItemRuntime

## Fachada de objetos equipados.
## Los multiplicadores y residuales viven en scripts/items/*.txt vía ItemSystem.
## Esta clase solo resuelve ItemData y delega consultas.


static func get_item_data(battler: BattleBattler) -> ItemData:
	if battler == null or battler.pokemon == null:
		return null
	if battler.pokemon.held_item == Items.ItemId.ITEM_NONE:
		return null
	return ItemDatabase.get_item(battler.pokemon.held_item)


static func get_hold_effect(battler: BattleBattler) -> HoldEffects.HoldEffect:
	var data: ItemData = get_item_data(battler)
	if data == null:
		return HoldEffects.HoldEffect.HOLD_EFFECT_NONE
	return data.hold_effect


static func get_hold_param(battler: BattleBattler) -> int:
	var data: ItemData = get_item_data(battler)
	if data == null:
		return 0
	return data.hold_effect_param


static func consume_held(battler: BattleBattler) -> void:
	if battler == null or battler.pokemon == null:
		return
	var id: int = int(battler.pokemon.held_item)
	if id != 0:
		battler.last_berry_id = id
	battler.pokemon.held_item = Items.ItemId.ITEM_NONE


static func attacker_power_multiplier(attacker: BattleBattler, move: MoveData, effectiveness: float) -> float:
	if attacker == null:
		return 1.0
	var ctx: EffectContext = EffectContext.new(attacker, null, move, null)
	ctx.effectiveness = effectiveness
	ctx.query_int = get_hold_param(attacker)
	return ItemSystem.query_float("on_power", ctx, 1.0)


static func defender_damage_multiplier(defender: BattleBattler, move: MoveData) -> float:
	if defender == null:
		return 1.0
	var ctx: EffectContext = EffectContext.new(defender, null, move, null)
	ctx.query_int = get_hold_param(defender)
	return ItemSystem.query_float("on_damage_taken", ctx, 1.0)


static func speed_multiplier(battler: BattleBattler) -> float:
	if battler == null:
		return 1.0
	var ctx: EffectContext = EffectContext.new(battler, null, null, null)
	return ItemSystem.query_float("on_speed", ctx, 1.0)


static func accuracy_multiplier(attacker: BattleBattler, defender: BattleBattler) -> float:
	if attacker == null:
		return 1.0
	var ctx: EffectContext = EffectContext.new(attacker, defender, null, null)
	if defender != null:
		ctx.target = defender
	return ItemSystem.query_float("on_accuracy", ctx, 1.0)


static func crit_stage_bonus(battler: BattleBattler) -> int:
	if battler == null:
		return 0
	var ctx: EffectContext = EffectContext.new(battler, null, null, null)
	ctx.query_int = 0
	ItemSystem.query("on_crit_stage", ctx)
	return ctx.query_int


static func try_endure_ko(defender: BattleBattler, damage: int) -> int:
	if defender == null or defender.pokemon == null or damage <= 0:
		return damage
	var ctx: EffectContext = EffectContext.new(defender, null, null, null)
	ctx.damage = damage
	ctx.blocked = false
	ctx.query_bool = false
	ItemSystem.query("on_endure_ko", ctx)
	if (ctx.blocked or ctx.query_bool) and damage >= defender.pokemon.current_hp:
		return maxi(defender.pokemon.current_hp - 1, 0)
	return damage


static func life_orb_recoil(attacker: BattleBattler, did_damage: bool) -> int:
	if not did_damage or attacker == null or attacker.is_fainted():
		return 0
	if get_hold_effect(attacker) != HoldEffects.HoldEffect.HOLD_EFFECT_LIFE_ORB:
		return 0
	@warning_ignore("integer_division")
	return maxi(1, attacker.get_max_hp() / 10)


static func shell_bell_heal(attacker: BattleBattler, damage_dealt: int) -> int:
	if damage_dealt <= 0 or attacker == null:
		return 0
	if get_hold_effect(attacker) != HoldEffects.HoldEffect.HOLD_EFFECT_SHELL_BELL:
		return 0
	var param: int = get_hold_param(attacker)
	if param <= 0:
		param = 8
	@warning_ignore("integer_division")
	return maxi(1, damage_dealt / param)


static func big_root_multiplier(battler: BattleBattler) -> float:
	if battler == null:
		return 1.0
	var ctx: EffectContext = EffectContext.new(battler, null, null, null)
	return ItemSystem.query_float("on_drain", ctx, 1.0)


static func rocky_helmet_damage(defender: BattleBattler, attacker: BattleBattler) -> int:
	if defender == null or attacker == null or attacker.is_fainted():
		return 0
	if get_hold_effect(defender) != HoldEffects.HoldEffect.HOLD_EFFECT_ROCKY_HELMET:
		return 0
	@warning_ignore("integer_division")
	return maxi(1, attacker.get_max_hp() / 6)


static func end_of_turn_effect(battler: BattleBattler) -> Dictionary:
	var out: Dictionary = {
		"heal": 0, "damage": 0, "message": "", "consume": false,
		"status": -1, "stat": -1, "stat_stages": 0,
	}
	if battler == null or battler.is_fainted() or battler.pokemon == null:
		return out
	var he: HoldEffects.HoldEffect = get_hold_effect(battler)
	# Residuales clásicos (Leftovers / BlackSludge / Orbs / pinch heal) —
	# se ejecutan por script on_end_turn cuando existe; el manager sigue
	# interpretando el Dictionary. Para scripts async de verdad usar ItemSystem.on_event.
	match he:
		HoldEffects.HoldEffect.HOLD_EFFECT_LEFTOVERS:
			@warning_ignore("integer_division")
			out["heal"] = maxi(1, battler.get_max_hp() / 16)
			out["message"] = "¡%s recuperó PS con sus Restos!" % battler.get_display_name()
		HoldEffects.HoldEffect.HOLD_EFFECT_BLACK_SLUDGE:
			var t1: PokemonData.Type = battler.get_battle_type_1()
			var t2: PokemonData.Type = battler.get_battle_type_2()
			var poison: bool = t1 == PokemonData.Type.TYPE_POISON or t2 == PokemonData.Type.TYPE_POISON
			if poison:
				@warning_ignore("integer_division")
				out["heal"] = maxi(1, battler.get_max_hp() / 16)
				out["message"] = "¡%s recuperó PS con el Lodo Negro!" % battler.get_display_name()
			else:
				@warning_ignore("integer_division")
				out["damage"] = maxi(1, battler.get_max_hp() / 8)
				out["message"] = "¡%s es herido por el Lodo Negro!" % battler.get_display_name()
		HoldEffects.HoldEffect.HOLD_EFFECT_STICKY_BARB:
			@warning_ignore("integer_division")
			out["damage"] = maxi(1, battler.get_max_hp() / 8)
			out["message"] = "¡%s es herido por la Toxiestrella!" % battler.get_display_name()
		HoldEffects.HoldEffect.HOLD_EFFECT_FLAME_ORB:
			if not battler.pokemon.has_status():
				out["status"] = int(PokemonInstance.Status.BURN)
		HoldEffects.HoldEffect.HOLD_EFFECT_TOXIC_ORB:
			if not battler.pokemon.has_status():
				out["status"] = int(PokemonInstance.Status.TOXIC)
		HoldEffects.HoldEffect.HOLD_EFFECT_RESTORE_PCT_HP:
			# Sitrus: ≤50%
			if battler.get_current_hp() * 2 <= battler.get_max_hp():
				@warning_ignore("integer_division")
				out["heal"] = maxi(1, battler.get_max_hp() / 4)
				out["message"] = "¡%s recuperó PS con su baya!" % battler.get_display_name()
				out["consume"] = true
		HoldEffects.HoldEffect.HOLD_EFFECT_RESTORE_HP:
			if battler.get_current_hp() * 2 <= battler.get_max_hp():
				out["heal"] = 10
				out["message"] = "¡%s recuperó PS con su baya!" % battler.get_display_name()
				out["consume"] = true
		_:
			pass
	return out


static func try_pinch_berry(battler: BattleBattler) -> Dictionary:
	var out: Dictionary = {
		"heal": 0, "message": "", "consume": false,
		"stat": -1, "stat_stages": 0, "cure_status": false, "cure_confusion": false,
	}
	if battler == null or battler.is_fainted() or battler.pokemon == null:
		return out
	if battler.get_current_hp() * 4 > battler.get_max_hp():
		return out
	var he: HoldEffects.HoldEffect = get_hold_effect(battler)
	var name: String = battler.get_display_name()
	match he:
		HoldEffects.HoldEffect.HOLD_EFFECT_ATTACK_UP:
			out["stat"] = int(PokemonInstance.Stat.ATTACK)
			out["stat_stages"] = 1
			out["message"] = "¡El Ataque de %s subió!" % name
			out["consume"] = true
		HoldEffects.HoldEffect.HOLD_EFFECT_DEFENSE_UP:
			out["stat"] = int(PokemonInstance.Stat.DEFENSE)
			out["stat_stages"] = 1
			out["message"] = "¡La Defensa de %s subió!" % name
			out["consume"] = true
		HoldEffects.HoldEffect.HOLD_EFFECT_SPEED_UP:
			out["stat"] = int(PokemonInstance.Stat.SPEED)
			out["stat_stages"] = 1
			out["message"] = "¡La Velocidad de %s subió!" % name
			out["consume"] = true
		HoldEffects.HoldEffect.HOLD_EFFECT_SP_ATTACK_UP:
			out["stat"] = int(PokemonInstance.Stat.SP_ATTACK)
			out["stat_stages"] = 1
			out["message"] = "¡El At. Esp. de %s subió!" % name
			out["consume"] = true
		HoldEffects.HoldEffect.HOLD_EFFECT_SP_DEFENSE_UP:
			out["stat"] = int(PokemonInstance.Stat.SP_DEFENSE)
			out["stat_stages"] = 1
			out["message"] = "¡La Def. Esp. de %s subió!" % name
			out["consume"] = true
		HoldEffects.HoldEffect.HOLD_EFFECT_CURE_STATUS, \
		HoldEffects.HoldEffect.HOLD_EFFECT_CURE_PAR, \
		HoldEffects.HoldEffect.HOLD_EFFECT_CURE_SLP, \
		HoldEffects.HoldEffect.HOLD_EFFECT_CURE_PSN, \
		HoldEffects.HoldEffect.HOLD_EFFECT_CURE_BRN, \
		HoldEffects.HoldEffect.HOLD_EFFECT_CURE_FRZ:
			if battler.pokemon.has_status():
				out["cure_status"] = true
				out["message"] = "¡%s se curó con su baya!" % name
				out["consume"] = true
		HoldEffects.HoldEffect.HOLD_EFFECT_CURE_CONFUSION:
			if battler.is_confused():
				out["cure_confusion"] = true
				out["message"] = "¡%s se libró de la confusión!" % name
				out["consume"] = true
		_:
			pass
	return out


static func is_choice_item(battler: BattleBattler) -> bool:
	var he: HoldEffects.HoldEffect = get_hold_effect(battler)
	return he == HoldEffects.HoldEffect.HOLD_EFFECT_CHOICE_BAND \
		or he == HoldEffects.HoldEffect.HOLD_EFFECT_CHOICE_SPECS \
		or he == HoldEffects.HoldEffect.HOLD_EFFECT_CHOICE_SCARF
