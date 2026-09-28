## Comandos especiales de habilidades (tipado estricto).
class_name CmdSpecial
extends EffectCommand


func _init(p_name: String = "special", p_args: PackedStringArray = []) -> void:
	super._init(p_name, p_args)


func execute(ctx: EffectContext) -> bool:
	if ctx.user == null:
		return true
	var b: BattleBattler = ctx.user
	var battle: BattleManager = ctx.battle
	var opp: BattleBattler = ctx.target

	match command_name:
		"download_boost":
			await _download_boost(b, opp, battle)
		"trace_ability":
			await _trace(b, opp, battle)
		"frisk":
			await _frisk(b, battle)
		"anticipation":
			await _anticipation(b, battle)
		"forewarn":
			await _forewarn(b, battle)
		"hospitality":
			await _hospitality(b, battle)
		"curious_medicine":
			await _curious_medicine(b, battle)
		"delta_stream":
			await _delta_stream(battle)
		"mimicry":
			await _mimicry(b, battle)
		"booster_energy":
			await _booster_energy(b, battle)
		"teraform_zero":
			await _teraform_zero(b, battle)
		"forecast":
			await _forecast(b, battle)
		"flower_gift":
			await _flower_gift(b, battle)
		"zen_mode":
			await _zen_mode(b, battle)
		"shields_down":
			await _shields_down(b, battle)
		"moody":
			await _moody(b, battle)
		"bad_dreams":
			await _bad_dreams(b, battle)
		"harvest":
			await _harvest(b, battle)
		"healer":
			await _healer(b, battle)
		"cud_chew":
			await _cud_chew(b, battle)
		"pickpocket":
			await _steal_item(b, ctx.attacker if ctx.attacker != null else opp, battle)
		"tick_slow_start":
			await _tick_slow_start(b, battle)
		"tick_truant":
			_tick_truant(b, ctx)
		"status_random":
			await _status_random(ctx)
		"flinch":
			_flinch(ctx)
		"lower_evasion":
			if opp != null:
				opp.stage_evasion = maxi(opp.stage_evasion - 1, -6)
				if battle != null:
					battle.message.emit("¡Bajó la evasión!")
					await battle._wait(0.3)
		"pickup":
			pass
		"multitype":
			await _announce_only(b, battle)
		"symbiosis":
			await _symbiosis(b, battle)
		"innards_out":
			await _innards_out(b, ctx.attacker, battle)
		"dancer":
			pass
		"beast_boost":
			await _beast_boost(b, battle)
		"rks_system":
			await _announce_only(b, battle)
		"ball_fetch":
			pass
		"gulp_missile_catch":
			b.set_meta("gulp_missile", 1)
		"gulp_missile_spit":
			await _gulp_missile_spit(b, ctx.attacker, battle)
		"perish_body":
			await _perish_body(b, ctx.attacker if ctx.attacker != null else opp, battle)
		"neutralizing_gas":
			await _neutralizing_gas(battle, true)
		"neutralizing_gas_end":
			await _neutralizing_gas(battle, false)
		"hunger_switch":
			await _hunger_switch(b, battle)
		"unnerve":
			if battle != null:
				battle.message.emit("¡Los rivales están demasiado nerviosos para comer bayas!")
				await battle._wait(0.5)
		"commander":
			await _commander(b, battle)
		"costar":
			await _costar(b, battle)
		"toxic_spikes":
			await _toxic_spikes(b, battle)
		"confuse_target":
			await _confuse(ctx.target if ctx.target != null else opp, battle, b)
		"schooling":
			await _schooling(b, battle)
		"liquid_ooze":
			ctx.query_bool = true
			ctx.blocked = true
		_:
			push_warning("CmdSpecial: desconocido '%s'" % command_name)
	return true


func _opponents(b: BattleBattler, battle: BattleManager) -> Array[BattleBattler]:
	var out: Array[BattleBattler] = []
	if battle == null or b == null:
		return out
	if battle.has_method("get_opponents"):
		for f: Variant in battle.get_opponents(b):
			var bb: BattleBattler = f as BattleBattler
			if bb != null:
				out.append(bb)
	else:
		var foe: BattleBattler = battle.enemy if b.is_player_side else battle.player
		if foe != null:
			out.append(foe)
	return out


func _ally(b: BattleBattler, battle: BattleManager) -> BattleBattler:
	return AbilityRuntime.get_ally(b, battle)


func _sticky_hold_blocks(holder: BattleBattler) -> bool:
	if holder == null:
		return false
	var ctx: EffectContext = EffectContext.new(holder, null, null, null)
	return AbilitySystem.query_bool("on_blocks_item_theft", ctx)


func _announce_only(b: BattleBattler, battle: BattleManager) -> void:
	if battle == null or b == null:
		return
	await battle.ability_announce(b)
	await battle._wait(0.3)


func _download_boost(b: BattleBattler, opp: BattleBattler, battle: BattleManager) -> void:
	if battle == null or opp == null or opp.is_fainted():
		return
	var def_s: int = opp.get_effective_stat(PokemonInstance.Stat.DEFENSE)
	var spd_s: int = opp.get_effective_stat(PokemonInstance.Stat.SP_DEFENSE)
	if def_s < spd_s:
		await battle.ability_change_stat(b, PokemonInstance.Stat.ATTACK, 1)
	else:
		await battle.ability_change_stat(b, PokemonInstance.Stat.SP_ATTACK, 1)


func _trace(b: BattleBattler, opp: BattleBattler, battle: BattleManager) -> void:
	if battle == null or b == null or opp == null or opp.pokemon == null or b.pokemon == null:
		return
	var src_id: AbilityId.Id = opp.pokemon.ability_id
	if src_id == AbilityId.Id.NONE or src_id == AbilityId.Id.TRACE:
		return
	match src_id:
		AbilityId.Id.MULTITYPE, AbilityId.Id.ILLUSION, AbilityId.Id.IMPOSTER, \
		AbilityId.Id.STANCE_CHANGE, AbilityId.Id.SCHOOLING, AbilityId.Id.RKS_SYSTEM, \
		AbilityId.Id.DISGUISE, AbilityId.Id.BATTLE_BOND, AbilityId.Id.POWER_CONSTRUCT, \
		AbilityId.Id.NEUTRALIZING_GAS, AbilityId.Id.GULP_MISSILE, AbilityId.Id.ICE_FACE, \
		AbilityId.Id.HUNGER_SWITCH, AbilityId.Id.AS_ONE_ICE_RIDER, AbilityId.Id.AS_ONE_SHADOW_RIDER:
			return
		_:
			pass
	await battle.ability_announce(b)
	b.pokemon.ability_id = src_id
	battle.message.emit("¡%s copió la habilidad!" % b.get_display_name())
	await battle._wait(0.6)


func _frisk(b: BattleBattler, battle: BattleManager) -> void:
	if battle == null:
		return
	for foe: BattleBattler in _opponents(b, battle):
		if foe == null or foe.pokemon == null:
			continue
		if foe.pokemon.held_item == Items.ItemId.ITEM_NONE:
			continue
		await battle.ability_announce(b)
		var item_name: String = str(foe.pokemon.held_item)
		battle.message.emit("¡%s friskó el objeto %s!" % [b.get_display_name(), item_name])
		await battle._wait(0.5)


func _anticipation(b: BattleBattler, battle: BattleManager) -> void:
	if battle == null or b == null:
		return
	for foe: BattleBattler in _opponents(b, battle):
		if foe == null or foe.pokemon == null:
			continue
		for slot: PokemonMoveSlot in foe.pokemon.moves:
			if slot == null or slot.is_empty():
				continue
			var md: MoveData = MoveDatabase.get_move(slot.move_id)
			if md == null:
				continue
			if md.power >= 1 and md.ohko:
				await battle.ability_announce(b)
				battle.message.emit("¡%s estremeció!" % b.get_display_name())
				await battle._wait(0.5)
				return
			if md.power >= 100:
				await battle.ability_announce(b)
				battle.message.emit("¡%s estremeció!" % b.get_display_name())
				await battle._wait(0.5)
				return


func _forewarn(b: BattleBattler, battle: BattleManager) -> void:
	if battle == null or b == null:
		return
	var best_name: String = ""
	var best_power: int = -1
	for foe: BattleBattler in _opponents(b, battle):
		if foe == null or foe.pokemon == null:
			continue
		for slot: PokemonMoveSlot in foe.pokemon.moves:
			if slot == null or slot.is_empty():
				continue
			var md: MoveData = MoveDatabase.get_move(slot.move_id)
			if md == null:
				continue
			var powv: int = md.power
			if md.ohko:
				powv = 150
			if powv > best_power:
				best_power = powv
				best_name = md.move_name if "move_name" in md else str(slot.move_id)
	if best_name.is_empty():
		return
	await battle.ability_announce(b)
	battle.message.emit("¡%s detectó %s!" % [b.get_display_name(), best_name])
	await battle._wait(0.5)


func _hospitality(b: BattleBattler, battle: BattleManager) -> void:
	if battle == null:
		return
	var ally: BattleBattler = _ally(b, battle)
	if ally == null or ally.is_fainted():
		return
	await battle.ability_announce(b)
	@warning_ignore("integer_division")
	await battle.ability_heal(ally, maxi(1, ally.get_max_hp() / 4))


func _curious_medicine(b: BattleBattler, battle: BattleManager) -> void:
	if battle == null:
		return
	var ally: BattleBattler = _ally(b, battle)
	if ally == null:
		return
	await battle.ability_announce(b)
	ally.stage_attack = 0
	ally.stage_defense = 0
	ally.stage_sp_attack = 0
	ally.stage_sp_defense = 0
	ally.stage_speed = 0
	ally.stage_accuracy = 0
	ally.stage_evasion = 0
	battle.message.emit("¡Las estadísticas de %s se reiniciaron!" % ally.get_display_name())
	await battle._wait(0.5)


func _delta_stream(battle: BattleManager) -> void:
	if battle == null:
		return
	battle.set_weather(AbilityBattleEffect.weatherAbilityID.WEATHER_STRONG_WINDS, -1, true)
	battle.message.emit("¡Corrientes de aire misteriosas protegen a los tipo Volador!")
	await battle._wait(0.6)


func _mimicry(b: BattleBattler, battle: BattleManager) -> void:
	if battle == null or b == null:
		return
	var t: PokemonData.Type = PokemonData.Type.TYPE_NONE
	match battle.terrain:
		BattleManager.TerrainId.TERRAIN_ELECTRIC:
			t = PokemonData.Type.TYPE_ELECTRIC
		BattleManager.TerrainId.TERRAIN_GRASSY:
			t = PokemonData.Type.TYPE_GRASS
		BattleManager.TerrainId.TERRAIN_MISTY:
			t = PokemonData.Type.TYPE_FAIRY
		BattleManager.TerrainId.TERRAIN_PSYCHIC:
			t = PokemonData.Type.TYPE_PSYCHIC
		_:
			if b.has_method("clear_battle_types"):
				b.clear_battle_types()
			return
	b.set_battle_types(t)
	await battle.ability_announce(b)
	battle.message.emit("¡%s cambió de tipo por el terreno!" % b.get_display_name())
	await battle._wait(0.5)


func _booster_energy(b: BattleBattler, battle: BattleManager) -> void:
	if battle == null or b == null:
		return
	await battle.ability_announce(b)
	var best: PokemonInstance.Stat = PokemonInstance.Stat.ATTACK
	var best_val: int = -1
	for stat: PokemonInstance.Stat in [
		PokemonInstance.Stat.ATTACK, PokemonInstance.Stat.DEFENSE,
		PokemonInstance.Stat.SP_ATTACK, PokemonInstance.Stat.SP_DEFENSE,
		PokemonInstance.Stat.SPEED
	]:
		var v: int = b.get_effective_stat(stat)
		if v > best_val:
			best_val = v
			best = stat
	await battle.ability_change_stat(b, best, 1)


func _teraform_zero(b: BattleBattler, battle: BattleManager) -> void:
	if battle == null:
		return
	await battle.ability_announce(b)
	if battle.has_method("set_weather"):
		battle.set_weather(AbilityBattleEffect.weatherAbilityID.WEATHER_NONE, 0)
	if battle.has_method("set_terrain"):
		battle.set_terrain(BattleManager.TerrainId.TERRAIN_NONE, 0)
	battle.message.emit("¡El clima y el terreno desaparecieron!")
	await battle._wait(0.6)


func _forecast(b: BattleBattler, battle: BattleManager) -> void:
	if battle == null or b == null or b.pokemon == null:
		return
	var form: StringName = &"base"
	match battle.weather:
		AbilityBattleEffect.weatherAbilityID.WEATHER_DROUGHT:
			form = &"sunny"
		AbilityBattleEffect.weatherAbilityID.WEATHER_RAIN:
			form = &"rainy"
		AbilityBattleEffect.weatherAbilityID.WEATHER_SNOW:
			form = &"snowy"
		_:
			form = &"base"
	if b.pokemon.form_id == form:
		return
	b.pokemon.form_id = form
	await battle.ability_announce(b)
	if battle.has_signal("battler_appearance_changed"):
		battle.battler_appearance_changed.emit(b.is_player_side)
	await battle._wait(0.4)


func _flower_gift(b: BattleBattler, battle: BattleManager) -> void:
	if battle == null or b == null:
		return
	var sunny: bool = battle.weather == AbilityBattleEffect.weatherAbilityID.WEATHER_DROUGHT
	b.set_meta("flower_gift_active", sunny)
	if sunny:
		await battle.ability_announce(b)
		await battle._wait(0.3)


func _zen_mode(b: BattleBattler, battle: BattleManager) -> void:
	if battle == null or b == null or b.pokemon == null:
		return
	var half: float = float(b.get_max_hp()) / 2.0
	var want_zen: bool = float(b.pokemon.current_hp) <= half
	var is_zen: bool = bool(b.get_meta("zen_mode", false))
	if want_zen == is_zen:
		return
	b.set_meta("zen_mode", want_zen)
	b.pokemon.form_id = &"zen" if want_zen else &"base"
	await battle.ability_announce(b)
	if battle.has_signal("battler_appearance_changed"):
		battle.battler_appearance_changed.emit(b.is_player_side)
	await battle._wait(0.5)


func _shields_down(b: BattleBattler, battle: BattleManager) -> void:
	if battle == null or b == null or b.pokemon == null:
		return
	var half: float = float(b.get_max_hp()) / 2.0
	var meteor: bool = float(b.pokemon.current_hp) > half
	var cur: bool = bool(b.get_meta("shields_down_meteor", true))
	if meteor == cur:
		return
	b.set_meta("shields_down_meteor", meteor)
	b.pokemon.form_id = &"meteor" if meteor else &"core"
	await battle.ability_announce(b)
	if battle.has_signal("battler_appearance_changed"):
		battle.battler_appearance_changed.emit(b.is_player_side)
	await battle._wait(0.5)


func _moody(b: BattleBattler, battle: BattleManager) -> void:
	if battle == null or b == null:
		return
	var stats: Array[PokemonInstance.Stat] = [
		PokemonInstance.Stat.ATTACK, PokemonInstance.Stat.DEFENSE,
		PokemonInstance.Stat.SP_ATTACK, PokemonInstance.Stat.SP_DEFENSE,
		PokemonInstance.Stat.SPEED,
	]
	var up: PokemonInstance.Stat = stats[randi() % stats.size()]
	var down: PokemonInstance.Stat = stats[randi() % stats.size()]
	while down == up:
		down = stats[randi() % stats.size()]
	await battle.ability_announce(b)
	await battle.ability_change_stat(b, up, 2)
	await battle.ability_change_stat(b, down, -1)


func _bad_dreams(b: BattleBattler, battle: BattleManager) -> void:
	if battle == null:
		return
	for foe: BattleBattler in _opponents(b, battle):
		if foe == null or foe.is_fainted() or foe.pokemon == null:
			continue
		if foe.pokemon.status != PokemonInstance.Status.SLEEP:
			continue
		if AbilityRuntime.blocks_indirect_damage(foe):
			continue
		await battle.ability_announce(b)
		@warning_ignore("integer_division")
		await battle.ability_deal_damage(foe, maxi(1, foe.get_max_hp() / 8), b)


func _harvest(b: BattleBattler, battle: BattleManager) -> void:
	if battle == null or b == null or b.pokemon == null:
		return
	if b.pokemon.held_item != Items.ItemId.ITEM_NONE:
		return
	var berry_id: int = 0
	if "last_berry_id" in b:
		berry_id = int(b.last_berry_id)
	elif b.has_meta("harvest_item"):
		berry_id = int(b.get_meta("harvest_item"))
	if berry_id == 0 or berry_id == int(Items.ItemId.ITEM_NONE):
		return
	var sunny: bool = battle.weather == AbilityBattleEffect.weatherAbilityID.WEATHER_DROUGHT
	if not sunny and randf() >= 0.5:
		return
	b.pokemon.held_item = berry_id as Items.ItemId
	await battle.ability_announce(b)
	battle.message.emit("¡%s recuperó su baya!" % b.get_display_name())
	await battle._wait(0.5)


func _healer(b: BattleBattler, battle: BattleManager) -> void:
	if battle == null:
		return
	var ally: BattleBattler = _ally(b, battle)
	if ally == null or ally.is_fainted() or ally.pokemon == null:
		return
	if not ally.pokemon.has_status():
		return
	if randf() >= 0.3:
		return
	await battle.ability_announce(b)
	await battle.ability_cure_status(ally)


func _cud_chew(b: BattleBattler, battle: BattleManager) -> void:
	if battle == null or b == null:
		return
	if not bool(b.get_meta("cud_chew_pending", false)):
		return
	b.set_meta("cud_chew_pending", false)
	await battle.ability_announce(b)
	@warning_ignore("integer_division")
	await battle.ability_heal(b, maxi(1, b.get_max_hp() / 3))


func _steal_item(thief: BattleBattler, victim: BattleBattler, battle: BattleManager) -> void:
	if battle == null or thief == null or victim == null:
		return
	if thief.is_fainted() or victim.is_fainted():
		return
	if thief.pokemon == null or victim.pokemon == null:
		return
	if thief.pokemon.held_item != Items.ItemId.ITEM_NONE:
		return
	if victim.pokemon.held_item == Items.ItemId.ITEM_NONE:
		return
	if _sticky_hold_blocks(victim):
		return
	await battle.ability_announce(thief)
	thief.pokemon.held_item = victim.pokemon.held_item
	victim.pokemon.held_item = Items.ItemId.ITEM_NONE
	AbilityRuntime.notify_item_lost(victim)
	battle.message.emit("¡%s robó el objeto!" % thief.get_display_name())
	await battle._wait(0.5)


func _tick_slow_start(b: BattleBattler, battle: BattleManager) -> void:
	if b == null:
		return
	if b.slow_start_turns <= 0:
		return
	b.slow_start_turns -= 1
	if b.slow_start_turns == 0 and battle != null:
		await battle.ability_announce(b)
		battle.message.emit("¡%s recuperó su fuerza!" % b.get_display_name())
		await battle._wait(0.5)


func _tick_truant(b: BattleBattler, ctx: EffectContext) -> void:
	if b == null:
		return
	var skip: bool = b.truant_skip_turn
	b.truant_skip_turn = not skip
	if skip:
		ctx.query_bool = true
		ctx.blocked = true


func _status_random(ctx: EffectContext) -> void:
	var statuses: Array[String] = []
	var target_mode: String = "attacker"
	for i: int in range(args.size()):
		var a: String = args[i].to_lower()
		if a.begins_with("target="):
			target_mode = a.substr(7)
			continue
		statuses.append(a)
	if statuses.is_empty():
		return
	var pick: String = statuses[randi() % statuses.size()]
	var sub_args: PackedStringArray = PackedStringArray([pick, "target=%s" % target_mode])
	var sub: CmdStatus = CmdStatus.new(sub_args)
	await sub.execute(ctx)


func _flinch(ctx: EffectContext) -> void:
	var who: BattleBattler = ctx.target
	if who == null:
		who = ctx.attacker
	if who == null:
		return
	if AbilityRuntime.blocks_flinch(who):
		return
	who.flinched = true


func _symbiosis(b: BattleBattler, battle: BattleManager) -> void:
	if battle == null or b == null or b.pokemon == null:
		return
	var ally: BattleBattler = _ally(b, battle)
	if ally == null or ally.pokemon == null:
		return
	if b.pokemon.held_item == Items.ItemId.ITEM_NONE:
		return
	if ally.pokemon.held_item != Items.ItemId.ITEM_NONE:
		return
	await battle.ability_announce(b)
	ally.pokemon.held_item = b.pokemon.held_item
	b.pokemon.held_item = Items.ItemId.ITEM_NONE
	battle.message.emit("¡%s pasó su objeto!" % b.get_display_name())
	await battle._wait(0.5)


func _innards_out(b: BattleBattler, attacker: BattleBattler, battle: BattleManager) -> void:
	if battle == null or b == null or attacker == null or attacker.is_fainted():
		return
	var dmg: int = int(b.get_meta("hp_before_faint", b.get_max_hp()))
	if dmg <= 0:
		dmg = b.get_max_hp()
	await battle.ability_announce(b)
	await battle.ability_deal_damage(attacker, dmg, b)


func _beast_boost(b: BattleBattler, battle: BattleManager) -> void:
	if battle == null or b == null:
		return
	var best: PokemonInstance.Stat = PokemonInstance.Stat.ATTACK
	var best_val: int = -1
	for stat: PokemonInstance.Stat in [
		PokemonInstance.Stat.ATTACK, PokemonInstance.Stat.DEFENSE,
		PokemonInstance.Stat.SP_ATTACK, PokemonInstance.Stat.SP_DEFENSE,
		PokemonInstance.Stat.SPEED
	]:
		var v: int = b.get_effective_stat(stat)
		if v > best_val:
			best_val = v
			best = stat
	await battle.ability_change_stat(b, best, 1)


func _gulp_missile_spit(b: BattleBattler, attacker: BattleBattler, battle: BattleManager) -> void:
	if battle == null or b == null:
		return
	if not bool(b.get_meta("gulp_missile", 0)):
		return
	b.set_meta("gulp_missile", 0)
	if attacker == null or attacker.is_fainted():
		return
	await battle.ability_announce(b)
	@warning_ignore("integer_division")
	await battle.ability_deal_damage(attacker, maxi(1, attacker.get_max_hp() / 4), b)
	if randf() < 0.5:
		await battle.ability_change_stat(attacker, PokemonInstance.Stat.DEFENSE, -1)
	else:
		await battle.ability_apply_status(attacker, PokemonInstance.Status.PARALYSIS, b)


func _perish_body(b: BattleBattler, other: BattleBattler, battle: BattleManager) -> void:
	if battle == null or b == null or other == null:
		return
	await battle.ability_announce(b)
	b.perish_count = 3
	other.perish_count = 3
	battle.message.emit("¡Ambos Pokémon perecerán en tres turnos!")
	await battle._wait(0.6)


func _neutralizing_gas(battle: BattleManager, active: bool) -> void:
	if battle == null:
		return
	battle.set_meta("neutralizing_gas", active)
	if active:
		battle.message.emit("¡El gas neutralizante impregnó el área!")
	else:
		battle.message.emit("¡Los efectos del gas desaparecieron!")
	await battle._wait(0.5)


func _hunger_switch(b: BattleBattler, battle: BattleManager) -> void:
	if battle == null or b == null or b.pokemon == null:
		return
	var form: StringName = &"hangry"
	if b.pokemon.form_id == &"hangry":
		form = &"full"
	b.pokemon.form_id = form
	await battle.ability_announce(b)
	if battle.has_signal("battler_appearance_changed"):
		battle.battler_appearance_changed.emit(b.is_player_side)
	await battle._wait(0.4)


func _commander(b: BattleBattler, battle: BattleManager) -> void:
	if battle == null:
		return
	var ally: BattleBattler = _ally(b, battle)
	if ally == null:
		return
	b.set_meta("commander_inside", true)
	ally.set_meta("commander_host", true)
	await battle.ability_announce(b)
	battle.message.emit("¡%s se metió en la boca de %s!" % [b.get_display_name(), ally.get_display_name()])
	await battle._wait(0.6)


func _costar(b: BattleBattler, battle: BattleManager) -> void:
	if battle == null or b == null:
		return
	var ally: BattleBattler = _ally(b, battle)
	if ally == null:
		return
	await battle.ability_announce(b)
	b.stage_attack = ally.stage_attack
	b.stage_defense = ally.stage_defense
	b.stage_sp_attack = ally.stage_sp_attack
	b.stage_sp_defense = ally.stage_sp_defense
	b.stage_speed = ally.stage_speed
	b.stage_accuracy = ally.stage_accuracy
	b.stage_evasion = ally.stage_evasion
	battle.message.emit("¡%s copió los cambios de estadística!" % b.get_display_name())
	await battle._wait(0.5)


func _toxic_spikes(b: BattleBattler, battle: BattleManager) -> void:
	if battle == null or b == null:
		return
	# Hazards van al lado RIVAL del portador.
	var side: FieldSide = battle.enemy_side if b.is_player_side else battle.player_side
	if side == null:
		return
	if side.toxic_spikes_layers >= 2:
		return
	side.toxic_spikes_layers += 1
	await battle.ability_announce(b)
	battle.message.emit("¡Se esparcieron púas tóxicas!")
	await battle._wait(0.5)


func _confuse(target: BattleBattler, battle: BattleManager, source: BattleBattler) -> void:
	if battle == null or target == null or target.is_fainted():
		return
	if AbilityRuntime.blocks_confusion(target):
		return
	target.confusion_turns = maxi(target.confusion_turns, 2)
	var who: BattleBattler = source if source != null else target
	await battle.ability_announce(who)
	battle.message.emit("¡%s se confundió!" % target.get_display_name())
	await battle._wait(0.4)


func _schooling(b: BattleBattler, battle: BattleManager) -> void:
	if battle == null or b == null or b.pokemon == null:
		return
	var quarter: float = float(b.get_max_hp()) / 4.0
	var school: bool = float(b.pokemon.current_hp) > quarter and b.pokemon.level >= 20
	var cur: bool = bool(b.get_meta("schooling", false))
	if school == cur:
		return
	b.set_meta("schooling", school)
	b.pokemon.form_id = &"school" if school else &"solo"
	await battle.ability_announce(b)
	if battle.has_signal("battler_appearance_changed"):
		battle.battler_appearance_changed.emit(b.is_player_side)
	await battle._wait(0.5)

## ─── Specials de movimientos ─────────────────────────────
