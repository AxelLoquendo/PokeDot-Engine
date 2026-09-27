## Comandos especiales de habilidades (lógica concreta, sin has_method sobre la clase).
class_name CmdSpecial
extends EffectCommand


func _init(p_name: String = "special", p_args: PackedStringArray = []) -> void:
	super._init(p_name, p_args)


func execute(ctx: EffectContext) -> bool:
	if ctx.battle == null or ctx.user == null:
		return true
	var b: BattleBattler = ctx.user
	var battle: BattleManager = ctx.battle
	var opp: BattleBattler = ctx.target

	match command_name:
		"download_boost":
			await _download_boost(b, opp, battle)
		"trace_ability":
			await _trace(b, opp, battle, ctx)
		"frisk":
			await _frisk(b, opp, battle)
		"anticipation":
			await _anticipation(b, opp, battle)
		"forewarn":
			await _forewarn(b, opp, battle)
		"hospitality":
			var ally: BattleBattler = AbilityRuntime.get_ally(b, battle)
			if ally != null:
				await AbilityRuntime.try_hospitality(b, ally, battle)
		"curious_medicine":
			var ally2: BattleBattler = AbilityRuntime.get_ally(b, battle)
			if ally2 != null:
				await AbilityRuntime.try_curious_medicine(b, ally2, battle)
		"delta_stream":
			battle.weather_primal = true
			battle.message.emit("¡Corrientes de aire misteriosas protegen a los tipo Volador!")
			await battle._wait(0.6)
			battle.weather_changed.emit(battle.weather, true)
		"mimicry":
			await AbilityRuntime._apply_mimicry(b, battle)
		"booster_energy":
			await AbilityRuntime.try_booster_energy_style(b, battle.weather, battle.terrain, battle)
		"teraform_zero":
			await AbilityRuntime.try_teraform_zero(b, battle)
		"forecast":
			await AbilityRuntime.try_forecast(b, battle.weather, battle)
		"flower_gift":
			await AbilityRuntime.try_flower_gift(b, battle.weather, battle)
		"zen_mode":
			await AbilityRuntime.try_zen_mode(b, battle)
		"shields_down":
			await AbilityRuntime.try_shields_down(b, battle)
		"moody":
			await _moody(b, battle)
		"bad_dreams":
			await _bad_dreams(b, battle)
		"harvest":
			await AbilityRuntime.try_harvest(b, battle.weather, battle)
		"healer":
			var ally3: BattleBattler = AbilityRuntime.get_ally(b, battle)
			if ally3 != null:
				await AbilityRuntime.try_healer(b, ally3, battle)
		"cud_chew":
			await AbilityRuntime.try_cud_chew(b, battle)
		"pickpocket":
			await _pickpocket(b, ctx.attacker, battle)
		"tick_slow_start":
			await _tick_slow_start(b, battle)
		"status_random":
			await _status_random(ctx)
		"flinch":
			var who: BattleBattler = ctx.target
			if who != null and not AbilityRuntime.blocks_flinch(who):
				who.flinched = true
				await AbilityRuntime.on_flinched(who, battle)
		"lower_evasion":
			if opp != null and not opp.is_fainted():
				var dropped: int = opp.modify_evasion_stage(-arg_int(0, 1))
				if dropped != 0:
					battle.message.emit("¡La evasión de %s bajó!" % opp.get_display_name())
					await battle._wait(0.6)
		_:
			push_warning("CmdSpecial: desconocido '%s'" % command_name)
	return true


func _download_boost(b: BattleBattler, opp: BattleBattler, battle: BattleManager) -> void:
	if opp == null or opp.is_fainted():
		return
	var def_s: int = opp.get_effective_stat(PokemonInstance.Stat.DEFENSE)
	var spd_s: int = opp.get_effective_stat(PokemonInstance.Stat.SP_DEFENSE)
	if def_s < spd_s:
		await battle.ability_change_stat(b, PokemonInstance.Stat.ATTACK, 1)
	else:
		await battle.ability_change_stat(b, PokemonInstance.Stat.SP_ATTACK, 1)


func _trace(b: BattleBattler, opp: BattleBattler, battle: BattleManager, ctx: EffectContext) -> void:
	if opp == null or opp.is_fainted() or opp.pokemon == null or b.pokemon == null:
		return
	var opp_id: AbilityId.Id = opp.pokemon.ability_id
	if not AbilityRuntime._is_traceable(opp_id):
		return
	await battle.ability_announce(b)
	b.pokemon.ability_id = opp_id
	await AbilitySystem.on_event("on_switch_in", ctx)


func _frisk(b: BattleBattler, opp: BattleBattler, battle: BattleManager) -> void:
	if opp == null or opp.is_fainted() or opp.pokemon == null:
		return
	if opp.pokemon.held_item == Items.ItemId.ITEM_NONE:
		return
	await battle.ability_announce(b)
	var item_name: String = "objeto"
	var idata: ItemData = ItemDatabase.get_item(opp.pokemon.held_item)
	if idata != null and not idata.item_name.is_empty():
		item_name = idata.item_name
	battle.message.emit("%s friskó el %s de %s." % [
		b.get_display_name(), item_name, opp.get_display_name()
	])
	await battle._wait(0.8)


func _anticipation(b: BattleBattler, opp: BattleBattler, battle: BattleManager) -> void:
	if opp == null or opp.pokemon == null or b.pokemon == null:
		return
	var found: bool = false
	var t1: PokemonData.Type = b.pokemon.get_type_1()
	var t2: PokemonData.Type = b.pokemon.get_type_2()
	for slot: PokemonMoveSlot in opp.pokemon.moves:
		if slot == null or slot.is_empty():
			continue
		var md: MoveData = MoveDatabase.get_move(slot.move_id)
		if md == null or md.power <= 0:
			continue
		if TypeChart.get_effectiveness(md.type, t1, t2) > 1.0:
			found = true
			break
	if found:
		await battle.ability_announce(b)
		battle.message.emit("¡%s se estremeció!" % b.get_display_name())
		await battle._wait(0.6)


func _forewarn(b: BattleBattler, opp: BattleBattler, battle: BattleManager) -> void:
	if opp == null or opp.pokemon == null:
		return
	var best: MoveData = null
	var best_pow: int = -1
	for slot: PokemonMoveSlot in opp.pokemon.moves:
		if slot == null or slot.is_empty():
			continue
		var md: MoveData = MoveDatabase.get_move(slot.move_id)
		if md == null:
			continue
		if md.power > best_pow:
			best_pow = md.power
			best = md
	if best != null:
		await battle.ability_announce(b)
		battle.message.emit("¡%s advirtió el movimiento %s!" % [
			b.get_display_name(), best.move_name
		])
		await battle._wait(0.8)


func _moody(b: BattleBattler, battle: BattleManager) -> void:
	await battle.ability_announce(b)
	var stats: Array[PokemonInstance.Stat] = [
		PokemonInstance.Stat.ATTACK, PokemonInstance.Stat.DEFENSE,
		PokemonInstance.Stat.SP_ATTACK, PokemonInstance.Stat.SP_DEFENSE,
		PokemonInstance.Stat.SPEED
	]
	var up: PokemonInstance.Stat = stats[randi() % stats.size()]
	var down: PokemonInstance.Stat = stats[randi() % stats.size()]
	while down == up:
		down = stats[randi() % stats.size()]
	await battle.ability_change_stat(b, up, 2)
	await battle.ability_change_stat(b, down, -1)


func _bad_dreams(b: BattleBattler, battle: BattleManager) -> void:
	var foes: Array[BattleBattler] = []
	if battle.has_method("get_opponents"):
		var raw: Array = battle.get_opponents(b)
		for f: Variant in raw:
			var bb: BattleBattler = f as BattleBattler
			if bb != null:
				foes.append(bb)
	else:
		var foe: BattleBattler = battle.enemy if b.is_player_side else battle.player
		if foe != null:
			foes.append(foe)
	for foe2: BattleBattler in foes:
		if foe2 == null or foe2.is_fainted() or foe2.pokemon == null:
			continue
		if foe2.pokemon.status != PokemonInstance.Status.SLEEP:
			continue
		if AbilityRuntime.blocks_indirect_damage(foe2):
			continue
		await battle.ability_announce(b)
		@warning_ignore("integer_division")
		await battle.ability_deal_damage(foe2, maxi(1, foe2.get_max_hp() / 8), b)


func _pickpocket(defender: BattleBattler, attacker: BattleBattler, battle: BattleManager) -> void:
	if defender == null or attacker == null or attacker.is_fainted():
		return
	if defender.pokemon == null or attacker.pokemon == null:
		return
	if defender.pokemon.held_item != Items.ItemId.ITEM_NONE:
		return
	if attacker.pokemon.held_item == Items.ItemId.ITEM_NONE:
		return
	if AbilityRuntime.has(attacker, AbilityId.Id.STICKY_HOLD):
		return
	await battle.ability_announce(defender)
	defender.pokemon.held_item = attacker.pokemon.held_item
	attacker.pokemon.held_item = Items.ItemId.ITEM_NONE
	AbilityRuntime.notify_item_lost(attacker)
	battle.message.emit("¡%s robó el objeto!" % defender.get_display_name())
	await battle._wait(0.5)


func _tick_slow_start(b: BattleBattler, battle: BattleManager) -> void:
	if b.slow_start_turns <= 0:
		return
	b.slow_start_turns -= 1
	if b.slow_start_turns == 0 and AbilityRuntime.has(b, AbilityId.Id.SLOW_START):
		await battle.ability_announce(b)
		battle.message.emit("¡%s recuperó su fuerza!" % b.get_display_name())
		await battle._wait(0.5)


func _status_random(ctx: EffectContext) -> void:
	var statuses: Array[String] = []
	for i: int in range(args.size()):
		var a: String = args[i].to_lower()
		if a.begins_with("target="):
			continue
		statuses.append(a)
	if statuses.is_empty():
		return
	var pick: String = statuses[randi() % statuses.size()]
	var sub_args: PackedStringArray = PackedStringArray([pick, "target=attacker"])
	var sub: CmdStatus = CmdStatus.new(sub_args)
	await sub.execute(ctx)
