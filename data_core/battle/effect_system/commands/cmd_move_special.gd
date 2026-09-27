## Specials de movimientos (scripts moves/*.txt → special <nombre>).
class_name CmdMoveSpecial
extends EffectCommand


func _init(p_name: String = "move_special", p_args: PackedStringArray = []) -> void:
	super._init(p_name, p_args)


func execute(ctx: EffectContext) -> bool:
	if ctx == null:
		return true
	match command_name:
		"weather_from_move":
			await _weather_from_move(ctx)
		"rest":
			await _rest(ctx)
		"haze_reset":
			await _haze_reset(ctx)
		"resolve_protect":
			await _resolve_protect(ctx)
		"belly_drum":
			await _belly_drum(ctx)
		"court_change":
			await _court_change(ctx)
		"clear_terrain":
			await _clear_terrain(ctx)
		"knock_off":
			await _knock_off(ctx)
		"steal_item":
			await _steal_item(ctx)
		"topsy_turvy":
			await _topsy_turvy(ctx)
		"self_ko":
			await _self_ko(ctx)
		"apply_move_status":
			await _apply_move_status(ctx)
		"accuracy_stage":
			await _accuracy_or_evasion_stage(ctx, false)
		"evasion_stage":
			await _accuracy_or_evasion_stage(ctx, true)
		"transform":
			await _call_bm(ctx, "_apply_transform")
		"mimic":
			await _call_bm(ctx, "_apply_mimic")
		"sketch":
			await _call_bm(ctx, "_apply_sketch")
		"metronome":
			await _call_bm(ctx, "_apply_metronome")
		"mirror_move":
			await _call_bm_mirror(ctx, true)
		"copycat":
			await _call_bm_mirror(ctx, false)
		"sleep_talk":
			await _call_bm(ctx, "_apply_sleep_talk")
		"nature_power":
			await _nature_power(ctx)
		"conversion":
			await _conversion(ctx, false)
		"conversion_2":
			await _conversion(ctx, true)
		"pain_split":
			await _pain_split(ctx)
		"psych_up":
			await _psych_up(ctx)
		"heart_swap":
			await _heart_swap(ctx)
		"power_swap":
			await _stat_swap(ctx, PackedStringArray(["attack", "sp_attack"]))
		"guard_swap":
			await _stat_swap(ctx, PackedStringArray(["defense", "sp_defense"]))
		"speed_swap":
			await _stat_swap(ctx, PackedStringArray(["speed"]))
		"power_trick":
			await _power_trick(ctx)
		"power_split":
			await _power_split(ctx)
		"guard_split":
			await _guard_split(ctx)
		"fillet_away":
			await _fillet_away(ctx)
		"tidy_up":
			await _tidy_up(ctx)
		"role_play":
			await _copy_ability(ctx, false)
		"skill_swap":
			await _copy_ability(ctx, true)
		"entrainment":
			await _entrainment(ctx)
		"overwrite_ability":
			await _copy_ability(ctx, false)
		"gastro_acid":
			if ctx.target != null:
				ctx.target.ability_active = false
				if ctx.battle:
					ctx.battle.message.emit("¡La habilidad de %s fue neutralizada!" % ctx.target.get_display_name())
					await ctx.battle._wait(0.4)
		"trick":
			await _trick_items(ctx)
		"bestow":
			await _bestow(ctx)
		"recycle":
			await _recycle(ctx)
		"spite":
			await _spite(ctx)
		"heal_bell":
			await _heal_bell(ctx)
		"reflect_type":
			await _reflect_type(ctx)
		"camouflage":
			await _camouflage(ctx)
		"third_type":
			if ctx.target != null:
				ctx.target.battle_type_2 = int(PokemonData.Type.TYPE_GRASS)
				if ctx.battle:
					ctx.battle.message.emit("¡%s ganó el tipo Planta!" % ctx.target.get_display_name())
					await ctx.battle._wait(0.4)
		"curse":
			await _curse(ctx)
		"swallow":
			await _swallow(ctx)
		"spit_up":
			if ctx.user != null:
				ctx.user.stockpile_count = 0
				if ctx.battle:
					ctx.battle.message.emit("¡%s liberó la energía acumulada!" % ctx.user.get_display_name())
					await ctx.battle._wait(0.4)
		"strength_sap":
			await _strength_sap(ctx)
		"acupressure":
			await _acupressure(ctx)
		"flower_shield":
			await _type_stat_boost(ctx, PokemonData.Type.TYPE_GRASS, PokemonInstance.Stat.DEFENSE, 1, false)
		"rototiller":
			await _type_stat_boost(ctx, PokemonData.Type.TYPE_GRASS, PokemonInstance.Stat.ATTACK, 1, true)
		"gear_up":
			await _side_stat_boost(ctx, PokemonInstance.Stat.ATTACK, 1, true, false)
		"magnetic_flux":
			await _side_stat_boost(ctx, PokemonInstance.Stat.DEFENSE, 1, false, true)
		"ally_switch":
			await _ally_switch(ctx)
		"healing_wish":
			await _healing_wish(ctx)
		"revival_blessing":
			await _revival_blessing(ctx)
		"psycho_shift":
			await _psycho_shift(ctx)
		"instruct":
			await _instruct(ctx)
		"future_sight":
			await _future_sight(ctx)
		"bide":
			await _bide(ctx)
		"present":
			await _present(ctx)
		"telekinesis":
			if ctx.target != null:
				ctx.target.magnet_rise_turns = 3
				if ctx.battle:
					ctx.battle.message.emit("¡%s fue elevado por telequinesis!" % ctx.target.get_display_name())
					await ctx.battle._wait(0.4)
		"fairy_lock":
			if ctx.battle:
				ctx.battle.set_meta("fairy_lock_turns", 2)
				ctx.battle.message.emit("¡Nadie puede huir!")
				await ctx.battle._wait(0.4)
		"ion_deluge":
			if ctx.battle:
				ctx.battle.set_meta("ion_deluge", true)
				ctx.battle.message.emit("¡Una lluvia de iones electrificó el campo!")
				await ctx.battle._wait(0.4)
		"electrify":
			if ctx.target != null:
				ctx.target.set_meta("electrify", true)
				if ctx.battle:
					ctx.battle.message.emit("¡Los movimientos de %s serán Eléctricos!" % ctx.target.get_display_name())
					await ctx.battle._wait(0.4)
		"powder":
			if ctx.target != null:
				ctx.target.set_meta("powder", true)
				if ctx.battle:
					ctx.battle.message.emit("¡%s fue cubierto de polvo!" % ctx.target.get_display_name())
					await ctx.battle._wait(0.4)
		"after_you":
			if ctx.target != null:
				ctx.target.set_meta("quash_priority", 99)
				if ctx.battle and ctx.user != null:
					ctx.battle.message.emit("¡%s dejará pasar a %s!" % [ctx.user.get_display_name(), ctx.target.get_display_name()])
					await ctx.battle._wait(0.4)
		"quash":
			if ctx.target != null:
				ctx.target.set_meta("quash_priority", -99)
				if ctx.battle:
					ctx.battle.message.emit("¡%s fue aplazado!" % ctx.target.get_display_name())
					await ctx.battle._wait(0.4)
		"teatime":
			if ctx.battle:
				ctx.battle.message.emit("¡Es la hora del té!")
				await ctx.battle._wait(0.4)
		"corrosive_gas":
			await _knock_off(ctx)
		"stuff_cheeks":
			await _stuff_cheeks(ctx)
		"fling":
			await _fling(ctx)
		"natural_gift":
			await _fling(ctx)
		"snore":
			await _snore(ctx)
		"fell_stinger":
			if ctx.target != null and ctx.target.is_fainted() and ctx.user != null and ctx.battle != null:
				await ctx.battle.ability_change_stat(ctx.user, PokemonInstance.Stat.ATTACK, 3)
		"clear_leech_seed":
			if ctx.user != null and ctx.user.leech_seeded:
				ctx.user.leech_seeded = false
				if ctx.battle:
					ctx.battle.message.emit("¡%s se liberó de las Drenadoras!" % ctx.user.get_display_name())
					await ctx.battle._wait(0.35)
		"smack_down":
			if ctx.target != null:
				ctx.target.magnet_rise_turns = 0
				ctx.target.semi_invulnerable = false
				if ctx.battle:
					ctx.battle.message.emit("¡%s fue derribado!" % ctx.target.get_display_name())
					await ctx.battle._wait(0.35)
		_:
			push_warning("CmdMoveSpecial: desconocido '%s'" % command_name)
	return true


func _weather_from_move(ctx: EffectContext) -> void:
	if ctx == null or ctx.battle == null or ctx.move == null:
		return
	if ctx.battle.has_method("_set_weather_from_move"):
		ctx.battle._set_weather_from_move(ctx.move)


func _rest(ctx: EffectContext) -> void:
	if ctx == null or ctx.user == null or ctx.user.pokemon == null:
		return
	var b: BattleBattler = ctx.user
	if b.pokemon.current_hp >= b.get_max_hp() or b.pokemon.has_status():
		if ctx.battle:
			ctx.battle.message.emit("¡No surtirá efecto!")
			await ctx.battle._wait(0.5)
		return
	b.pokemon.current_hp = b.get_max_hp()
	b.pokemon.status = PokemonInstance.Status.SLEEP
	b.pokemon.status_counter = 2
	if ctx.battle:
		ctx.battle.hp_changed.emit(b.is_player_side, b.get_current_hp(), b.get_max_hp())
		ctx.battle.message.emit("¡%s se durmió y recuperó todos sus PS!" % b.get_display_name())
		await ctx.battle._wait(0.6)


func _haze_reset(ctx: EffectContext) -> void:
	if ctx == null or ctx.battle == null:
		return
	for b: BattleBattler in ctx.battle.get_all_actives():
		if b != null and b.has_method("_reset_stages"):
			b._reset_stages()
	ctx.battle.message.emit("¡Se eliminaron todos los cambios de estadísticas!")
	await ctx.battle._wait(0.5)


func _resolve_protect(ctx: EffectContext) -> void:
	if ctx == null or ctx.user == null or ctx.battle == null or ctx.move == null:
		return
	if ctx.battle.has_method("_resolve_protect_move"):
		await ctx.battle._resolve_protect_move(ctx.user, ctx.move)


func _belly_drum(ctx: EffectContext) -> void:
	if ctx == null or ctx.user == null:
		return
	var b: BattleBattler = ctx.user
	if b.get_current_hp() <= int(b.get_max_hp() / 2) or b.get_current_hp() <= 1:
		if ctx.battle:
			ctx.battle.message.emit("¡No surtirá efecto!")
			await ctx.battle._wait(0.5)
		return
	var cost: int = int(b.get_max_hp() / 2)
	b.apply_damage(cost)
	b.stage_attack = 6
	if ctx.battle:
		ctx.battle.hp_changed.emit(b.is_player_side, b.get_current_hp(), b.get_max_hp())
		ctx.battle.message.emit("¡%s maximizó su Ataque!" % b.get_display_name())
		await ctx.battle._wait(0.5)


func _court_change(ctx: EffectContext) -> void:
	if ctx == null or ctx.battle == null:
		return
	var tmp: FieldSide = ctx.battle.player_side
	ctx.battle.player_side = ctx.battle.enemy_side
	ctx.battle.enemy_side = tmp
	ctx.battle.message.emit("¡Se intercambiaron los efectos de ambos lados!")
	await ctx.battle._wait(0.5)


func _clear_terrain(ctx: EffectContext) -> void:
	if ctx == null or ctx.battle == null:
		return
	if ctx.battle.terrain != BattleManager.TerrainId.TERRAIN_NONE:
		ctx.battle.terrain = BattleManager.TerrainId.TERRAIN_NONE
		ctx.battle.terrain_turns = 0
		ctx.battle.message.emit("¡El terreno desapareció!")
		await ctx.battle._wait(0.4)


func _knock_off(ctx: EffectContext) -> void:
	if ctx == null or ctx.target == null or ctx.target.pokemon == null:
		return
	if ctx.target.pokemon.held_item != Items.ItemId.ITEM_NONE:
		ctx.target.pokemon.held_item = Items.ItemId.ITEM_NONE
		if ctx.battle:
			ctx.battle.message.emit("¡%s perdió su objeto!" % ctx.target.get_display_name())
			await ctx.battle._wait(0.4)


func _steal_item(ctx: EffectContext) -> void:
	if ctx == null or ctx.user == null or ctx.target == null:
		return
	if ctx.user.pokemon == null or ctx.target.pokemon == null:
		return
	if ctx.target.pokemon.held_item != Items.ItemId.ITEM_NONE and ctx.user.pokemon.held_item == Items.ItemId.ITEM_NONE:
		ctx.user.pokemon.held_item = ctx.target.pokemon.held_item
		ctx.target.pokemon.held_item = Items.ItemId.ITEM_NONE
		if ctx.battle:
			ctx.battle.message.emit("¡%s robó el objeto!" % ctx.user.get_display_name())
			await ctx.battle._wait(0.4)


func _topsy_turvy(ctx: EffectContext) -> void:
	if ctx == null or ctx.target == null:
		return
	var tg: BattleBattler = ctx.target
	tg.stage_attack = -tg.stage_attack
	tg.stage_defense = -tg.stage_defense
	tg.stage_sp_attack = -tg.stage_sp_attack
	tg.stage_sp_defense = -tg.stage_sp_defense
	tg.stage_speed = -tg.stage_speed
	tg.stage_accuracy = -tg.stage_accuracy
	tg.stage_evasion = -tg.stage_evasion
	if ctx.battle:
		ctx.battle.message.emit("¡Se invirtieron los cambios de estadísticas!")
		await ctx.battle._wait(0.5)


func _self_ko(ctx: EffectContext) -> void:
	if ctx == null or ctx.user == null:
		return
	ctx.user.apply_damage(ctx.user.get_current_hp())
	if ctx.battle:
		ctx.battle.hp_changed.emit(ctx.user.is_player_side, ctx.user.get_current_hp(), ctx.user.get_max_hp())
		ctx.battle.message.emit("¡%s se debilitó!" % ctx.user.get_display_name())
		await ctx.battle._wait(0.5)


func _apply_move_status(ctx: EffectContext) -> void:
	if ctx == null or ctx.move == null or ctx.battle == null:
		return
	var status_value: int = MoveEffectResolver.get_secondary_status(ctx.move.secondary_effect)
	if status_value < 0:
		return
	var who: BattleBattler = ctx.target
	if ctx.move.target == MoveStruct.MoveTarget.TARGET_USER:
		who = ctx.user
	if who != null and ctx.battle.has_method("_apply_status"):
		await ctx.battle._apply_status(who, status_value as PokemonInstance.Status)


func _accuracy_or_evasion_stage(ctx: EffectContext, is_evasion: bool) -> void:
	if ctx == null or ctx.battle == null:
		return
	var stages: int = 1
	if args.size() > 0 and str(args[0]).is_valid_int():
		stages = int(args[0])
	var who: BattleBattler = ctx.user
	for a: String in args:
		if a.begins_with("target="):
			match a.substr(7).to_lower():
				"opponent", "foe", "target":
					who = ctx.target
				"user":
					who = ctx.user
	if who == null:
		return
	var actual: int = 0
	if is_evasion:
		var before_e: int = who.stage_evasion
		who.stage_evasion = clampi(who.stage_evasion + stages, -6, 6)
		actual = who.stage_evasion - before_e
	else:
		var before_a: int = who.stage_accuracy
		who.stage_accuracy = clampi(who.stage_accuracy + stages, -6, 6)
		actual = who.stage_accuracy - before_a
	var label: String = "Evasión" if is_evasion else "Precisión"
	if actual == 0:
		ctx.battle.message.emit("¡La %s de %s ya no puede cambiar más!" % [label, who.get_display_name()])
	elif actual > 0:
		ctx.battle.message.emit("¡La %s de %s subió!" % [label, who.get_display_name()])
	else:
		ctx.battle.message.emit("¡La %s de %s bajó!" % [label, who.get_display_name()])
	await ctx.battle._wait(0.45)


func _call_bm(ctx: EffectContext, method: String) -> void:
	if ctx == null or ctx.battle == null:
		return
	match method:
		"_apply_transform":
			if ctx.battle.has_method("_apply_transform"):
				await ctx.battle._apply_transform(ctx.user, ctx.target)
		"_apply_mimic":
			if ctx.battle.has_method("_apply_mimic"):
				await ctx.battle._apply_mimic(ctx.user, ctx.target)
		"_apply_sketch":
			if ctx.battle.has_method("_apply_sketch"):
				await ctx.battle._apply_sketch(ctx.user, ctx.target)
		"_apply_metronome":
			if ctx.battle.has_method("_apply_metronome"):
				await ctx.battle._apply_metronome(ctx.user, ctx.target)
		"_apply_sleep_talk":
			if ctx.battle.has_method("_apply_sleep_talk"):
				await ctx.battle._apply_sleep_talk(ctx.user, ctx.target)


func _call_bm_mirror(ctx: EffectContext, mirror: bool) -> void:
	if ctx == null or ctx.battle == null:
		return
	if ctx.battle.has_method("_apply_copy_last_move"):
		await ctx.battle._apply_copy_last_move(ctx.user, ctx.target, mirror)


func _conversion(ctx: EffectContext, from_foe_move: bool) -> void:
	if ctx == null or ctx.user == null or ctx.user.pokemon == null:
		return
	var md: MoveData = null
	if from_foe_move and ctx.target != null and ctx.target.last_move_used_id >= 0:
		md = MoveDatabase.get_move(ctx.target.last_move_used_id)
	elif not ctx.user.pokemon.moves.is_empty():
		var slot: PokemonMoveSlot = ctx.user.pokemon.moves[0]
		if slot != null:
			md = MoveDatabase.get_move(slot.move_id)
	if md == null:
		if ctx.battle:
			ctx.battle.message.emit("¡Pero falló!")
			await ctx.battle._wait(0.4)
		return
	ctx.user.battle_type_1 = int(md.type)
	ctx.user.battle_type_2 = -1
	if ctx.battle:
		ctx.battle.message.emit("¡%s cambió de tipo!" % ctx.user.get_display_name())
		await ctx.battle._wait(0.45)


func _pain_split(ctx: EffectContext) -> void:
	if ctx == null or ctx.user == null or ctx.target == null:
		return
	if ctx.user.pokemon == null or ctx.target.pokemon == null:
		return
	var total: int = ctx.user.get_current_hp() + ctx.target.get_current_hp()
	@warning_ignore("integer_division")
	var mid: int = int(total / 2)
	ctx.user.pokemon.current_hp = mini(ctx.user.get_max_hp(), mid)
	ctx.target.pokemon.current_hp = mini(ctx.target.get_max_hp(), mid)
	if ctx.battle:
		ctx.battle.hp_changed.emit(ctx.user.is_player_side, ctx.user.get_current_hp(), ctx.user.get_max_hp())
		ctx.battle.hp_changed.emit(ctx.target.is_player_side, ctx.target.get_current_hp(), ctx.target.get_max_hp())
		ctx.battle.message.emit("¡Los PS se repartieron!")
		await ctx.battle._wait(0.5)


func _psych_up(ctx: EffectContext) -> void:
	if ctx == null or ctx.user == null or ctx.target == null:
		return
	ctx.user.stage_attack = ctx.target.stage_attack
	ctx.user.stage_defense = ctx.target.stage_defense
	ctx.user.stage_sp_attack = ctx.target.stage_sp_attack
	ctx.user.stage_sp_defense = ctx.target.stage_sp_defense
	ctx.user.stage_speed = ctx.target.stage_speed
	ctx.user.stage_accuracy = ctx.target.stage_accuracy
	ctx.user.stage_evasion = ctx.target.stage_evasion
	if ctx.battle:
		ctx.battle.message.emit("¡%s copió los cambios de estadísticas!" % ctx.user.get_display_name())
		await ctx.battle._wait(0.45)


func _stat_swap(ctx: EffectContext, fields: PackedStringArray) -> void:
	if ctx == null or ctx.user == null or ctx.target == null:
		return
	for f: String in fields:
		match f:
			"attack":
				var a: int = ctx.user.stage_attack
				ctx.user.stage_attack = ctx.target.stage_attack
				ctx.target.stage_attack = a
			"defense":
				var d: int = ctx.user.stage_defense
				ctx.user.stage_defense = ctx.target.stage_defense
				ctx.target.stage_defense = d
			"sp_attack":
				var sa: int = ctx.user.stage_sp_attack
				ctx.user.stage_sp_attack = ctx.target.stage_sp_attack
				ctx.target.stage_sp_attack = sa
			"sp_defense":
				var sd: int = ctx.user.stage_sp_defense
				ctx.user.stage_sp_defense = ctx.target.stage_sp_defense
				ctx.target.stage_sp_defense = sd
			"speed":
				var sp: int = ctx.user.stage_speed
				ctx.user.stage_speed = ctx.target.stage_speed
				ctx.target.stage_speed = sp
	if ctx.battle:
		ctx.battle.message.emit("¡Se intercambiaron cambios de estadísticas!")
		await ctx.battle._wait(0.45)


func _heart_swap(ctx: EffectContext) -> void:
	if ctx == null or ctx.battle == null or ctx.user == null or ctx.target == null:
		return
	if ctx.battle.has_method("_snapshot_baton_pass") and ctx.battle.has_method("_apply_baton_pass"):
		var s: Dictionary = ctx.battle._snapshot_baton_pass(ctx.user)
		ctx.battle._apply_baton_pass(ctx.user, ctx.battle._snapshot_baton_pass(ctx.target))
		ctx.battle._apply_baton_pass(ctx.target, s)
		ctx.battle.message.emit("¡Se intercambiaron los cambios de estadísticas!")
		await ctx.battle._wait(0.45)


func _power_trick(ctx: EffectContext) -> void:
	if ctx == null or ctx.user == null:
		return
	var on: bool = not bool(ctx.user.get_meta("power_trick", false))
	ctx.user.set_meta("power_trick", on)
	if ctx.battle:
		ctx.battle.message.emit("¡%s intercambió Ataque y Defensa!" % ctx.user.get_display_name())
		await ctx.battle._wait(0.45)


func _power_split(ctx: EffectContext) -> void:
	if ctx == null or ctx.user == null or ctx.target == null:
		return
	if ctx.user.pokemon == null or ctx.target.pokemon == null:
		return
	var ua: int = ctx.user.get_effective_stat(PokemonInstance.Stat.ATTACK)
	var ta: int = ctx.target.get_effective_stat(PokemonInstance.Stat.ATTACK)
	var us: int = ctx.user.get_effective_stat(PokemonInstance.Stat.SP_ATTACK)
	var ts: int = ctx.target.get_effective_stat(PokemonInstance.Stat.SP_ATTACK)
	@warning_ignore("integer_division")
	var avg_a: int = int((ua + ta) / 2)
	@warning_ignore("integer_division")
	var avg_s: int = int((us + ts) / 2)
	var ou: Dictionary = ctx.user.get_meta("split_stat_override", {}) if ctx.user.has_meta("split_stat_override") else {}
	var ot: Dictionary = ctx.target.get_meta("split_stat_override", {}) if ctx.target.has_meta("split_stat_override") else {}
	ou[int(PokemonInstance.Stat.ATTACK)] = avg_a
	ou[int(PokemonInstance.Stat.SP_ATTACK)] = avg_s
	ot[int(PokemonInstance.Stat.ATTACK)] = avg_a
	ot[int(PokemonInstance.Stat.SP_ATTACK)] = avg_s
	ctx.user.set_meta("split_stat_override", ou)
	ctx.target.set_meta("split_stat_override", ot)
	if ctx.battle:
		ctx.battle.message.emit("¡Se promediaron Ataque y At. Esp.!")
		await ctx.battle._wait(0.5)


func _guard_split(ctx: EffectContext) -> void:
	if ctx == null or ctx.user == null or ctx.target == null:
		return
	if ctx.user.pokemon == null or ctx.target.pokemon == null:
		return
	var ud: int = ctx.user.get_effective_stat(PokemonInstance.Stat.DEFENSE)
	var td: int = ctx.target.get_effective_stat(PokemonInstance.Stat.DEFENSE)
	var usd: int = ctx.user.get_effective_stat(PokemonInstance.Stat.SP_DEFENSE)
	var tsd: int = ctx.target.get_effective_stat(PokemonInstance.Stat.SP_DEFENSE)
	@warning_ignore("integer_division")
	var avg_d: int = int((ud + td) / 2)
	@warning_ignore("integer_division")
	var avg_sd: int = int((usd + tsd) / 2)
	var ou: Dictionary = ctx.user.get_meta("split_stat_override", {}) if ctx.user.has_meta("split_stat_override") else {}
	var ot: Dictionary = ctx.target.get_meta("split_stat_override", {}) if ctx.target.has_meta("split_stat_override") else {}
	ou[int(PokemonInstance.Stat.DEFENSE)] = avg_d
	ou[int(PokemonInstance.Stat.SP_DEFENSE)] = avg_sd
	ot[int(PokemonInstance.Stat.DEFENSE)] = avg_d
	ot[int(PokemonInstance.Stat.SP_DEFENSE)] = avg_sd
	ctx.user.set_meta("split_stat_override", ou)
	ctx.target.set_meta("split_stat_override", ot)
	if ctx.battle:
		ctx.battle.message.emit("¡Se promediaron Defensa y Def. Esp.!")
		await ctx.battle._wait(0.5)


func _fillet_away(ctx: EffectContext) -> void:
	if ctx == null or ctx.user == null or ctx.battle == null:
		return
	@warning_ignore("integer_division")
	if ctx.user.get_current_hp() <= int(ctx.user.get_max_hp() / 2):
		ctx.battle.message.emit("¡No surtirá efecto!")
		await ctx.battle._wait(0.5)
		return
	@warning_ignore("integer_division")
	var cost: int = int(ctx.user.get_max_hp() / 2)
	ctx.user.apply_damage(cost)
	ctx.battle.hp_changed.emit(ctx.user.is_player_side, ctx.user.get_current_hp(), ctx.user.get_max_hp())
	await ctx.battle._apply_stat_change(ctx.user, PokemonInstance.Stat.ATTACK, 2)
	await ctx.battle._apply_stat_change(ctx.user, PokemonInstance.Stat.SP_ATTACK, 2)
	await ctx.battle._apply_stat_change(ctx.user, PokemonInstance.Stat.SPEED, 2)


func _tidy_up(ctx: EffectContext) -> void:
	if ctx == null or ctx.battle == null:
		return
	ctx.battle.player_side.clear_hazards()
	ctx.battle.enemy_side.clear_hazards()
	for b: BattleBattler in ctx.battle.get_all_actives():
		if b != null and b.substitute_hp > 0:
			b.substitute_hp = 0
	ctx.battle.message.emit("¡Se limpió el campo!")
	await ctx.battle._wait(0.4)
	if ctx.user != null and not ctx.user.is_fainted():
		await ctx.battle._apply_stat_change(ctx.user, PokemonInstance.Stat.ATTACK, 1)
		await ctx.battle._apply_stat_change(ctx.user, PokemonInstance.Stat.SPEED, 1)


func _nature_power(ctx: EffectContext) -> void:
	if ctx == null or ctx.battle == null or ctx.user == null:
		return
	# Mapeo simplificado por terreno → efecto de movimiento de daño típico
	# Ejecuta un golpe de tipo según terreno (usa el mismo move con tipo override)
	var type_id: int = int(PokemonData.Type.TYPE_NORMAL)
	match ctx.battle.terrain:
		BattleManager.TerrainId.TERRAIN_ELECTRIC:
			type_id = int(PokemonData.Type.TYPE_ELECTRIC)
		BattleManager.TerrainId.TERRAIN_GRASSY:
			type_id = int(PokemonData.Type.TYPE_GRASS)
		BattleManager.TerrainId.TERRAIN_MISTY:
			type_id = int(PokemonData.Type.TYPE_FAIRY)
		BattleManager.TerrainId.TERRAIN_PSYCHIC:
			type_id = int(PokemonData.Type.TYPE_PSYCHIC)
		_:
			type_id = int(PokemonData.Type.TYPE_NORMAL)
	ctx.battle.message.emit("¡Poder Natural se convirtió en un ataque!")
	await ctx.battle._wait(0.4)
	if ctx.target == null or ctx.move == null:
		return
	# Golpe fijo 80 potencia del tipo elegido
	var probe_move: MoveData = ctx.move.duplicate(true) if ctx.move.has_method("duplicate") else ctx.move
	if probe_move != null:
		probe_move.type = type_id as PokemonData.Type
		probe_move.power = 80
		probe_move.category = MoveStruct.DamageCategory.SPECIAL
		probe_move.effect = MoveStruct.MoveEffect.EFFECT_HIT
		var action: BattleAction = BattleAction.make_move(ctx.user, ctx.target, probe_move, -1)
		action.set_meta("_skip_pp", true)
		action.set_meta("_multi_resolved", true)
		await ctx.battle._execute_move(action)


func _copy_ability(ctx: EffectContext, swap: bool) -> void:
	if ctx == null or ctx.user == null or ctx.target == null:
		return
	if ctx.user.pokemon == null or ctx.target.pokemon == null:
		return
	if swap:
		var ab: int = ctx.user.pokemon.ability_id
		ctx.user.pokemon.ability_id = ctx.target.pokemon.ability_id
		ctx.target.pokemon.ability_id = ab
		if ctx.battle:
			ctx.battle.message.emit("¡Se intercambiaron las habilidades!")
	else:
		ctx.user.pokemon.ability_id = ctx.target.pokemon.ability_id
		if ctx.battle:
			ctx.battle.message.emit("¡%s copió la habilidad!" % ctx.user.get_display_name())
	if ctx.battle:
		await ctx.battle._wait(0.45)


func _entrainment(ctx: EffectContext) -> void:
	if ctx == null or ctx.user == null or ctx.target == null:
		return
	if ctx.user.pokemon == null or ctx.target.pokemon == null:
		return
	ctx.target.pokemon.ability_id = ctx.user.pokemon.ability_id
	if ctx.battle:
		ctx.battle.message.emit("¡%s recibió la habilidad de %s!" % [ctx.target.get_display_name(), ctx.user.get_display_name()])
		await ctx.battle._wait(0.45)


func _trick_items(ctx: EffectContext) -> void:
	if ctx == null or ctx.user == null or ctx.target == null:
		return
	if ctx.user.pokemon == null or ctx.target.pokemon == null:
		return
	if ctx.battle != null and ctx.battle.magic_room_turns > 0:
		ctx.battle.message.emit("¡Pero falló!")
		await ctx.battle._wait(0.4)
		return
	var ia: int = ctx.user.pokemon.held_item
	var ib: int = ctx.target.pokemon.held_item
	ctx.user.pokemon.held_item = ib
	ctx.target.pokemon.held_item = ia
	if ctx.battle:
		ctx.battle.message.emit("¡%s intercambió los objetos!" % ctx.user.get_display_name())
		await ctx.battle._wait(0.45)


func _bestow(ctx: EffectContext) -> void:
	if ctx == null or ctx.user == null or ctx.target == null:
		return
	if ctx.user.pokemon == null or ctx.target.pokemon == null:
		return
	if ctx.user.pokemon.held_item == Items.ItemId.ITEM_NONE or ctx.target.pokemon.held_item != Items.ItemId.ITEM_NONE:
		if ctx.battle:
			ctx.battle.message.emit("¡Pero falló!")
			await ctx.battle._wait(0.4)
		return
	ctx.target.pokemon.held_item = ctx.user.pokemon.held_item
	ctx.user.pokemon.held_item = Items.ItemId.ITEM_NONE
	if ctx.battle:
		ctx.battle.message.emit("¡%s entregó su objeto!" % ctx.user.get_display_name())
		await ctx.battle._wait(0.45)


func _recycle(ctx: EffectContext) -> void:
	if ctx == null or ctx.user == null or ctx.user.pokemon == null:
		return
	var last_berry: int = ctx.user.last_berry_id
	if last_berry != 0 and ctx.user.pokemon.held_item == Items.ItemId.ITEM_NONE:
		ctx.user.pokemon.held_item = last_berry as Items.ItemId
		if ctx.battle:
			ctx.battle.message.emit("¡%s recuperó su objeto!" % ctx.user.get_display_name())
			await ctx.battle._wait(0.45)
	elif ctx.battle:
		ctx.battle.message.emit("¡Pero falló!")
		await ctx.battle._wait(0.4)


func _spite(ctx: EffectContext) -> void:
	if ctx == null or ctx.target == null or ctx.target.pokemon == null or ctx.target.last_move_used_id < 0:
		if ctx != null and ctx.battle != null:
			ctx.battle.message.emit("¡Pero falló!")
			await ctx.battle._wait(0.4)
		return
	var done: bool = false
	for slot: PokemonMoveSlot in ctx.target.pokemon.moves:
		if slot != null and int(slot.move_id) == ctx.target.last_move_used_id:
			slot.current_pp = maxi(0, slot.current_pp - 4)
			done = true
			break
	if ctx.battle:
		if done:
			ctx.battle.message.emit("¡Los PP del último movimiento de %s bajaron!" % ctx.target.get_display_name())
		else:
			ctx.battle.message.emit("¡Pero falló!")
		await ctx.battle._wait(0.45)


func _heal_bell(ctx: EffectContext) -> void:
	if ctx == null:
		return
	var who: BattleBattler = ctx.target if ctx.target != null else ctx.user
	if who == null or who.pokemon == null:
		return
	if who.pokemon.has_status():
		who.pokemon.cure_status()
		if ctx.battle:
			ctx.battle.message.emit("¡%s se curó de su estado!" % who.get_display_name())
			await ctx.battle._wait(0.45)
	elif ctx.battle:
		ctx.battle.message.emit("¡Pero falló!")
		await ctx.battle._wait(0.4)


func _reflect_type(ctx: EffectContext) -> void:
	if ctx == null or ctx.user == null or ctx.target == null or ctx.target.pokemon == null:
		return
	var t1: int = ctx.target.battle_type_1 if ctx.target.battle_type_1 >= 0 else int(ctx.target.pokemon.get_type_1())
	var t2: int = ctx.target.battle_type_2 if ctx.target.battle_type_2 >= 0 else int(ctx.target.pokemon.get_type_2())
	ctx.user.battle_type_1 = t1
	ctx.user.battle_type_2 = t2
	if ctx.battle:
		ctx.battle.message.emit("¡%s copió el tipo!" % ctx.user.get_display_name())
		await ctx.battle._wait(0.45)


func _camouflage(ctx: EffectContext) -> void:
	if ctx == null or ctx.user == null or ctx.battle == null:
		return
	var cam_t: int = int(PokemonData.Type.TYPE_NORMAL)
	match ctx.battle.terrain:
		BattleManager.TerrainId.TERRAIN_ELECTRIC:
			cam_t = int(PokemonData.Type.TYPE_ELECTRIC)
		BattleManager.TerrainId.TERRAIN_GRASSY:
			cam_t = int(PokemonData.Type.TYPE_GRASS)
		BattleManager.TerrainId.TERRAIN_MISTY:
			cam_t = int(PokemonData.Type.TYPE_FAIRY)
		BattleManager.TerrainId.TERRAIN_PSYCHIC:
			cam_t = int(PokemonData.Type.TYPE_PSYCHIC)
	ctx.user.battle_type_1 = cam_t
	ctx.user.battle_type_2 = -1
	ctx.battle.message.emit("¡%s cambió de tipo!" % ctx.user.get_display_name())
	await ctx.battle._wait(0.45)


func _curse(ctx: EffectContext) -> void:
	if ctx == null or ctx.user == null or ctx.user.pokemon == null:
		return
	var c1: PokemonData.Type = ctx.user.pokemon.get_type_1()
	var c2: PokemonData.Type = ctx.user.pokemon.get_type_2()
	var is_ghost: bool = c1 == PokemonData.Type.TYPE_GHOST or c2 == PokemonData.Type.TYPE_GHOST
	if is_ghost:
		if ctx.target == null or ctx.target.is_cursed:
			if ctx.battle:
				ctx.battle.message.emit("¡No surtirá efecto!")
				await ctx.battle._wait(0.4)
			return
		@warning_ignore("integer_division")
		var cost: int = maxi(1, int(ctx.user.get_max_hp() / 2))
		ctx.user.apply_damage(cost)
		ctx.target.is_cursed = true
		if ctx.battle:
			ctx.battle.hp_changed.emit(ctx.user.is_player_side, ctx.user.get_current_hp(), ctx.user.get_max_hp())
			ctx.battle.message.emit("¡%s maldijo a %s!" % [ctx.user.get_display_name(), ctx.target.get_display_name()])
			await ctx.battle._wait(0.5)
	else:
		if ctx.battle:
			await ctx.battle._apply_stat_change(ctx.user, PokemonInstance.Stat.SPEED, -1)
			await ctx.battle._apply_stat_change(ctx.user, PokemonInstance.Stat.ATTACK, 1)
			await ctx.battle._apply_stat_change(ctx.user, PokemonInstance.Stat.DEFENSE, 1)


func _swallow(ctx: EffectContext) -> void:
	if ctx == null or ctx.user == null or ctx.user.pokemon == null:
		return
	if ctx.user.stockpile_count <= 0:
		if ctx.battle:
			ctx.battle.message.emit("¡No surtirá efecto!")
			await ctx.battle._wait(0.4)
		return
	var frac: float = 0.25
	if ctx.user.stockpile_count == 2:
		frac = 0.5
	elif ctx.user.stockpile_count >= 3:
		frac = 1.0
	var heal_sw: int = maxi(1, int(float(ctx.user.get_max_hp()) * frac))
	if ctx.user.heal_block_turns > 0:
		if ctx.battle:
			ctx.battle.message.emit("¡%s no puede curarse!" % ctx.user.get_display_name())
	else:
		ctx.user.pokemon.apply_heal(heal_sw)
		if ctx.battle:
			ctx.battle.hp_changed.emit(ctx.user.is_player_side, ctx.user.get_current_hp(), ctx.user.get_max_hp())
			ctx.battle.message.emit("¡%s recuperó PS!" % ctx.user.get_display_name())
	ctx.user.stockpile_count = 0
	if ctx.battle:
		await ctx.battle._wait(0.45)


func _strength_sap(ctx: EffectContext) -> void:
	if ctx == null or ctx.target == null or ctx.user == null or ctx.user.pokemon == null:
		return
	if ctx.battle:
		await ctx.battle._apply_stat_change(ctx.target, PokemonInstance.Stat.ATTACK, -1, true)
		if ctx.user.heal_block_turns <= 0:
			var heal_ss: int = maxi(1, ctx.target.get_effective_stat(PokemonInstance.Stat.ATTACK))
			ctx.user.pokemon.apply_heal(heal_ss)
			ctx.battle.hp_changed.emit(ctx.user.is_player_side, ctx.user.get_current_hp(), ctx.user.get_max_hp())
			ctx.battle.message.emit("¡%s absorbió fuerza!" % ctx.user.get_display_name())
			await ctx.battle._wait(0.45)


func _acupressure(ctx: EffectContext) -> void:
	if ctx == null or ctx.battle == null:
		return
	var who: BattleBattler = ctx.target if ctx.target != null else ctx.user
	if who == null:
		return
	var stats: Array[PokemonInstance.Stat] = [
		PokemonInstance.Stat.ATTACK, PokemonInstance.Stat.DEFENSE,
		PokemonInstance.Stat.SP_ATTACK, PokemonInstance.Stat.SP_DEFENSE,
		PokemonInstance.Stat.SPEED,
	]
	var pick: PokemonInstance.Stat = stats[randi() % stats.size()]
	await ctx.battle._apply_stat_change(who, pick, 2)


func _type_stat_boost(ctx: EffectContext, ptype: PokemonData.Type, stat: PokemonInstance.Stat, stages: int, also_spatk: bool = false) -> void:
	if ctx == null or ctx.battle == null:
		return
	for b: BattleBattler in ctx.battle.get_all_actives():
		if b == null or b.pokemon == null:
			continue
		var t1: PokemonData.Type = b.pokemon.get_type_1()
		var t2: PokemonData.Type = b.pokemon.get_type_2()
		if t1 == ptype or t2 == ptype:
			await ctx.battle._apply_stat_change(b, stat, stages)
			if also_spatk:
				await ctx.battle._apply_stat_change(b, PokemonInstance.Stat.SP_ATTACK, stages)


func _side_stat_boost(ctx: EffectContext, stat: PokemonInstance.Stat, stages: int, also_spatk: bool = false, also_spdef: bool = false) -> void:
	if ctx == null or ctx.battle == null or ctx.user == null:
		return
	for b: BattleBattler in ctx.battle.get_side_actives(ctx.user.is_player_side):
		if b != null and not b.is_fainted():
			await ctx.battle._apply_stat_change(b, stat, stages)
			if also_spatk:
				await ctx.battle._apply_stat_change(b, PokemonInstance.Stat.SP_ATTACK, stages)
			if also_spdef:
				await ctx.battle._apply_stat_change(b, PokemonInstance.Stat.SP_DEFENSE, stages)


func _ally_switch(ctx: EffectContext) -> void:
	if ctx == null or ctx.battle == null or ctx.user == null:
		return
	var actives: Array[BattleBattler] = ctx.battle.player_actives if ctx.user.is_player_side else ctx.battle.enemy_actives
	if actives.size() >= 2 and actives[0] != null and actives[1] != null:
		var tmp: BattleBattler = actives[0]
		actives[0] = actives[1]
		actives[1] = tmp
		actives[0].slot_index = 0
		actives[1].slot_index = 1
		if ctx.battle.has_method("_sync_primary_refs"):
			ctx.battle._sync_primary_refs()
		ctx.battle.message.emit("¡Los aliados intercambiaron posiciones!")
		await ctx.battle._wait(0.5)
	else:
		ctx.battle.message.emit("¡Pero falló!")
		await ctx.battle._wait(0.4)


func _healing_wish(ctx: EffectContext) -> void:
	if ctx == null or ctx.user == null:
		return
	ctx.user.apply_damage(ctx.user.get_current_hp())
	ctx.user.wish_turns = 0
	ctx.user.wish_hp = ctx.user.get_max_hp()
	if ctx.battle:
		ctx.battle.hp_changed.emit(ctx.user.is_player_side, ctx.user.get_current_hp(), ctx.user.get_max_hp())
		ctx.battle.message.emit("¡%s se sacrificó por el equipo!" % ctx.user.get_display_name())
		await ctx.battle._wait(0.5)
		if ctx.user.is_player_side:
			ctx.battle.player_must_switch.emit()


func _revival_blessing(ctx: EffectContext) -> void:
	if ctx == null or ctx.user == null or ctx.battle == null:
		return
	ctx.battle.message.emit("¡%s rezó por un aliado caído!" % ctx.user.get_display_name())
	await ctx.battle._wait(0.5)
	var party: Array[PokemonInstance] = ctx.battle.player_party if ctx.user.is_player_side else ctx.battle.enemy_party
	for mon: PokemonInstance in party:
		if mon != null and mon.is_fainted():
			@warning_ignore("integer_division")
			mon.current_hp = maxi(1, int(mon.max_hp / 2))
			ctx.battle.message.emit("¡%s recuperó la conciencia!" % mon.get_display_name())
			await ctx.battle._wait(0.5)
			break


func _psycho_shift(ctx: EffectContext) -> void:
	if ctx == null or ctx.user == null or ctx.target == null:
		return
	if ctx.user.pokemon == null or ctx.target.pokemon == null:
		return
	if not ctx.user.pokemon.has_status() or ctx.target.pokemon.has_status():
		if ctx.battle:
			ctx.battle.message.emit("¡No surtirá efecto!")
			await ctx.battle._wait(0.4)
		return
	var st: PokemonInstance.Status = ctx.user.pokemon.status
	ctx.user.pokemon.cure_status()
	if ctx.battle and ctx.battle.has_method("_apply_status"):
		await ctx.battle._apply_status(ctx.target, st)


func _instruct(ctx: EffectContext) -> void:
	if ctx == null or ctx.target == null or ctx.target.last_move_used_id < 0:
		if ctx != null and ctx.battle != null:
			ctx.battle.message.emit("¡Pero falló!")
			await ctx.battle._wait(0.4)
		return
	var im: MoveData = MoveDatabase.get_move(ctx.target.last_move_used_id)
	if im == null or ctx.battle == null:
		return
	var ia: BattleAction = BattleAction.make_move(ctx.target, ctx.user, im, -1)
	ia.set_meta("_skip_pp", true)
	ia.set_meta("_multi_resolved", true)
	await ctx.battle._execute_move(ia)


func _future_sight(ctx: EffectContext) -> void:
	if ctx == null or ctx.target == null or ctx.user == null or ctx.move == null or ctx.battle == null:
		return
	if ctx.target.future_sight_turns >= 0:
		ctx.battle.message.emit("¡Pero falló!")
		await ctx.battle._wait(0.4)
		return
	var probe: DamageCalculator.HitResult = DamageCalculator.compute_hit(ctx.user, ctx.target, ctx.move, ctx.battle.weather, false)
	ctx.target.future_sight_damage = maxi(1, probe.damage)
	ctx.target.future_sight_turns = 2
	ctx.target.future_sight_from_player = ctx.user.is_player_side
	ctx.battle.message.emit("¡%s previó un ataque!" % ctx.user.get_display_name())
	await ctx.battle._wait(0.5)


func _bide(ctx: EffectContext) -> void:
	if ctx == null or ctx.user == null or ctx.battle == null:
		return
	if ctx.user.bide_turns < 0:
		ctx.user.bide_turns = 2
		ctx.user.bide_damage = 0
		ctx.battle.message.emit("¡%s está contando energía!" % ctx.user.get_display_name())
		await ctx.battle._wait(0.5)
	else:
		var bd: int = ctx.user.bide_damage * 2
		ctx.user.bide_turns = -1
		ctx.user.bide_damage = 0
		if ctx.target != null and bd > 0:
			ctx.battle._apply_damage_to_target(ctx.target, bd)
			ctx.battle.hp_changed.emit(ctx.target.is_player_side, ctx.target.get_current_hp(), ctx.target.get_max_hp())
			ctx.battle.message.emit("¡%s liberó energía!" % ctx.user.get_display_name())
			await ctx.battle._wait(0.5)
		else:
			ctx.battle.message.emit("¡Pero falló!")
			await ctx.battle._wait(0.4)


func _present(ctx: EffectContext) -> void:
	if ctx == null or ctx.target == null or ctx.battle == null or ctx.target.pokemon == null:
		return
	var roll: int = randi_range(1, 100)
	if roll <= 40:
		if ctx.target.heal_block_turns <= 0:
			ctx.target.pokemon.apply_heal(80)
			ctx.battle.hp_changed.emit(ctx.target.is_player_side, ctx.target.get_current_hp(), ctx.target.get_max_hp())
			ctx.battle.message.emit("¡%s recuperó PS!" % ctx.target.get_display_name())
	else:
		var pdmg: int = 40 if roll <= 70 else (80 if roll <= 90 else 120)
		ctx.battle._apply_damage_to_target(ctx.target, pdmg)
		ctx.battle.hp_changed.emit(ctx.target.is_player_side, ctx.target.get_current_hp(), ctx.target.get_max_hp())
		ctx.battle.message.emit("Hizo %d PS de daño." % pdmg)
	await ctx.battle._wait(0.5)


func _stuff_cheeks(ctx: EffectContext) -> void:
	if ctx == null or ctx.user == null or ctx.user.pokemon == null:
		return
	if ctx.user.pokemon.held_item == Items.ItemId.ITEM_NONE:
		if ctx.battle:
			ctx.battle.message.emit("¡No surtirá efecto!")
			await ctx.battle._wait(0.4)
		return
	ctx.user.last_berry_id = int(ctx.user.pokemon.held_item)
	ctx.user.pokemon.held_item = Items.ItemId.ITEM_NONE
	if ctx.battle:
		await ctx.battle._apply_stat_change(ctx.user, PokemonInstance.Stat.DEFENSE, 2)


func _fling(ctx: EffectContext) -> void:
	if ctx == null or ctx.user == null or ctx.user.pokemon == null:
		return
	if ctx.user.pokemon.held_item == Items.ItemId.ITEM_NONE:
		if ctx.battle:
			ctx.battle.message.emit("¡Pero falló!")
			await ctx.battle._wait(0.4)
		return
	ctx.user.pokemon.held_item = Items.ItemId.ITEM_NONE
	if ctx.battle:
		ctx.battle.message.emit("¡%s lanzó su objeto!" % ctx.user.get_display_name())
		await ctx.battle._wait(0.4)


func _snore(ctx: EffectContext) -> void:
	if ctx == null or ctx.user == null or ctx.user.pokemon == null:
		return
	if ctx.user.pokemon.status == PokemonInstance.Status.SLEEP:
		if ctx.battle:
			ctx.battle.message.emit("¡%s ronca fuerte!" % ctx.user.get_display_name())
			await ctx.battle._wait(0.4)
	else:
		if ctx.battle:
			ctx.battle.message.emit("¡No surtirá efecto!")
			await ctx.battle._wait(0.4)
