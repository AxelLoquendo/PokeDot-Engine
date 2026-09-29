## Volátiles del battler: protect, focus_energy, substitute, leech_seed, taunt, etc.
class_name CmdVolatile
extends EffectCommand

func _init(p_name: String = "volatile", p_args: PackedStringArray = []) -> void:
	super._init(p_name, p_args)


## Sintaxis (ejemplos):
##   volatile focus_energy
##   volatile protect
##   volatile endure
##   volatile substitute
##   volatile leech_seed target=opponent
##   volatile cannot_escape target=opponent
##   volatile taunt 3 target=opponent
##   volatile disable target=opponent
##   volatile encore 3 target=opponent
##   volatile heal_block 5 target=opponent
##   volatile destiny_bond
##   volatile lock_on target=opponent
##   volatile identified target=opponent
##   volatile nightmare target=opponent
##   volatile curse target=opponent
##   volatile charged
##   volatile laser_focus
##   volatile follow_me
##   volatile helping_hand target=ally
##   volatile stockpile
##   volatile perish_song   (all field)
##   volatile wish
##   volatile ingrain
##   volatile aqua_ring
##   volatile magnet_rise 5
##   volatile no_retreat
##   volatile octolock target=opponent
##   volatile yawn target=opponent

func execute(ctx: EffectContext) -> bool:
	if ctx == null or ctx.battle == null:
		return false
	var kind: String = arg_string(0).to_lower()
	if kind.is_empty():
		return false

	var who: BattleBattler = _resolve_target(ctx)
	match kind:
		"clear_confusion":
			if who == null:
				return false
			who.confusion_turns = 0
		"focus_energy":
			if who == null:
				return false
			if who.focus_energy:
				_fail(ctx)
				return true
			who.focus_energy = true
			_msg(ctx, "¡%s se concentró!" % who.get_display_name())
		"protect":
			if who == null:
				return false
			# Deja que ProtectResolver lleve la probabilidad si se llama desde BM;
			# aquí solo marca protect genérico.
			who.protect_active = true
			who.used_protect_this_turn = true
			who.protect_counter += 1
			_msg(ctx, "¡%s se protegió!" % who.get_display_name())
		"endure":
			if who == null:
				return false
			who.endure_active = true
			who.used_protect_this_turn = true
			who.protect_counter += 1
			_msg(ctx, "¡%s se preparó para resistir!" % who.get_display_name())
		"substitute":
			if who == null or who.pokemon == null:
				return false
			@warning_ignore("integer_division")
			var cost: int = maxi(1, int(who.get_max_hp() / 4))
			if who.get_current_hp() <= cost or who.substitute_hp > 0:
				_fail(ctx)
				return true
			who.apply_damage(cost)
			who.substitute_hp = cost
			_emit_hp(ctx, who)
			_msg(ctx, "¡%s creó un sustituto!" % who.get_display_name())
		"leech_seed":
			if who == null or who.is_fainted() or who.pokemon == null:
				_fail(ctx)
				return true
			if who.leech_seeded:
				_msg(ctx, "¡%s ya está drenado!" % who.get_display_name())
				return true
			var t1: PokemonData.Type = who.pokemon.get_type_1()
			var t2: PokemonData.Type = who.pokemon.get_type_2()
			if t1 == PokemonData.Type.TYPE_GRASS or t2 == PokemonData.Type.TYPE_GRASS:
				_msg(ctx, "¡No afectó a %s!" % who.get_display_name())
				return true
			who.leech_seeded = true
			_msg(ctx, "¡%s fue infectado por Drenadoras!" % who.get_display_name())
		"cannot_escape", "mean_look", "trap":
			if who == null or who.is_fainted():
				return false
			if who.cannot_escape:
				_fail(ctx)
				return true
			if who.pokemon != null:
				var g1: PokemonData.Type = who.pokemon.get_type_1()
				var g2: PokemonData.Type = who.pokemon.get_type_2()
				if g1 == PokemonData.Type.TYPE_GHOST or g2 == PokemonData.Type.TYPE_GHOST:
					_msg(ctx, "¡No afectó a %s!" % who.get_display_name())
					return true
			who.cannot_escape = true
			_msg(ctx, "¡%s no puede escapar!" % who.get_display_name())
		"taunt":
			if who == null:
				return false
			var turns: int = arg_int(1, 3)
			if who.taunt_turns > 0:
				_fail(ctx)
				return true
			who.taunt_turns = turns
			_msg(ctx, "¡%s cayó en Provocación!" % who.get_display_name())
		"torment":
			if who == null:
				return false
			who.torment_active = true
			_msg(ctx, "¡%s fue víctima de Tormento!" % who.get_display_name())
		"disable":
			if who == null or who.last_move_used_id < 0:
				_fail(ctx)
				return true
			who.disable_move_id = who.last_move_used_id
			who.disable_turns = arg_int(1, 4)
			_msg(ctx, "¡Se anuló el último movimiento de %s!" % who.get_display_name())
		"encore":
			if who == null or who.last_move_used_id < 0:
				_fail(ctx)
				return true
			who.encore_move_id = who.last_move_used_id
			who.encore_turns = arg_int(1, 3)
			_msg(ctx, "¡%s recibió un Otra Vez!" % who.get_display_name())
		"heal_block":
			if who == null:
				return false
			who.heal_block_turns = arg_int(1, 5)
			_msg(ctx, "¡%s no podrá curarse!" % who.get_display_name())
		"destiny_bond":
			if who == null:
				return false
			who.destiny_bond_active = true
			_msg(ctx, "¡%s intenta llevarse a su enemigo consigo!" % who.get_display_name())
		"lock_on":
			if who == null or ctx.user == null:
				return false
			who.locked_on_by_side = 1 if ctx.user.is_player_side else 0
			_msg(ctx, "¡%s se fijó en %s!" % [ctx.user.get_display_name(), who.get_display_name()])
		"identified", "foresight", "miracle_eye":
			if who == null:
				return false
			who.is_identified = true
			_msg(ctx, "¡%s fue identificado!" % who.get_display_name())
		"nightmare":
			if who == null or who.pokemon == null:
				return false
			if who.pokemon.status != PokemonInstance.Status.SLEEP:
				_fail(ctx)
				return true
			who.has_nightmare = true
			_msg(ctx, "¡%s empezó a tener pesadillas!" % who.get_display_name())
		"curse_ghost":
			# Ghost curse: user loses 50% HP, target is cursed
			if ctx.user == null or who == null:
				return false
			if who.is_cursed:
				_fail(ctx)
				return true
			@warning_ignore("integer_division")
			var ccost: int = maxi(1, int(ctx.user.get_max_hp() / 2))
			ctx.user.apply_damage(ccost)
			_emit_hp(ctx, ctx.user)
			who.is_cursed = true
			_msg(ctx, "¡%s maldijo a %s!" % [ctx.user.get_display_name(), who.get_display_name()])
		"charged":
			if who == null:
				return false
			who.charged = true
			_msg(ctx, "¡%s cargó energía!" % who.get_display_name())
		"laser_focus":
			if who == null:
				return false
			who.laser_focus = true
			_msg(ctx, "¡%s se concentró al máximo!" % who.get_display_name())
		"follow_me":
			if who == null:
				return false
			who.set_meta("follow_me", true)
			_msg(ctx, "¡%s se convirtió en el centro de atención!" % who.get_display_name())
		"helping_hand":
			if who == null:
				return false
			who.set_meta("helping_hand", true)
			_msg(ctx, "¡%s está listo para ayudar!" % (ctx.user.get_display_name() if ctx.user else ""))
		"stockpile":
			if who == null:
				return false
			if who.stockpile_count >= 3:
				_fail(ctx)
				return true
			who.stockpile_count += 1
			_msg(ctx, "¡%s acumuló energía (%d)!" % [who.get_display_name(), who.stockpile_count])
		"perish_song":
			var any_set: bool = false
			for b: BattleBattler in ctx.battle.get_all_actives():
				if b == null or b.is_fainted():
					continue
				if AbilityRuntime.has(b, AbilityId.Id.SOUNDPROOF):
					continue
				if b.perish_count < 0:
					b.perish_count = 3
					any_set = true
			if any_set:
				_msg(ctx, "¡Todos los que oyeron la canción perecerán en 3 turnos!")
			else:
				_fail(ctx)
		"wish":
			if who == null:
				return false
			@warning_ignore("integer_division")
			who.wish_hp = maxi(1, int(who.get_max_hp() / 2))
			who.wish_turns = 1
			_msg(ctx, "¡%s pidió un deseo!" % who.get_display_name())
		"ingrain":
			if who == null:
				return false
			who.has_ingrain = true
			who.cannot_escape = true
			_msg(ctx, "¡%s echó raíces!" % who.get_display_name())
		"aqua_ring":
			if who == null:
				return false
			who.has_aqua_ring = true
			_msg(ctx, "¡%s se envolvió en un velo de agua!" % who.get_display_name())
		"magnet_rise":
			if who == null:
				return false
			who.magnet_rise_turns = arg_int(1, 5)
			_msg(ctx, "¡%s levita con electromagnetismo!" % who.get_display_name())
		"no_retreat":
			if who == null:
				return false
			if who.no_retreat:
				_fail(ctx)
				return true
			who.no_retreat = true
			who.cannot_escape = true
			_msg(ctx, "¡%s ya no puede retirarse!" % who.get_display_name())
		"octolock":
			if who == null:
				return false
			who.octolocked = true
			who.cannot_escape = true
			_msg(ctx, "¡%s quedó atrapado por Octopresa!" % who.get_display_name())
		"yawn":
			if who == null or who.pokemon == null or who.pokemon.has_status():
				_fail(ctx)
				return true
			who.set_meta("yawn_turns", 1)
			_msg(ctx, "¡%s bostezó!" % who.get_display_name())
		"minimize":
			if who == null:
				return false
			who.stage_evasion = clampi(who.stage_evasion + 2, -6, 6)
			_msg(ctx, "¡La Evasión de %s subió mucho!" % who.get_display_name())
		"uproar":
			if who == null:
				return false
			who.uproar_turns = arg_int(1, 3)
			if who.pokemon != null and who.pokemon.status == PokemonInstance.Status.SLEEP:
				who.pokemon.cure_status()
			_msg(ctx, "¡%s armó un alboroto!" % who.get_display_name())
		"beak_blast":
			if who == null:
				return false
			who.beak_blast_armed = true
			_msg(ctx, "¡%s está cargando Beak Blast!" % who.get_display_name())
		"shell_trap":
			if who == null:
				return false
			who.shell_trap_armed = true
			_msg(ctx, "¡%s preparó una trampa de concha!" % who.get_display_name())
		"embargo":
			if who == null:
				return false
			who.set_meta("embargo_turns", arg_int(1, 5))
			_msg(ctx, "¡%s no puede usar objetos!" % who.get_display_name())
		"imprison":
			if who == null:
				return false
			who.set_meta("imprison", true)
			_msg(ctx, "¡%s selló los movimientos del rival!" % who.get_display_name())
		"grudge":
			if who == null:
				return false
			who.set_meta("grudge", true)
			_msg(ctx, "¡%s está guardando rencor!" % who.get_display_name())
		"magic_coat":
			if who == null:
				return false
			who.set_meta("magic_coat", true)
			_msg(ctx, "¡%s esperó con Capa Mágica!" % who.get_display_name())
		"snatch":
			if who == null:
				return false
			who.set_meta("snatch", true)
			_msg(ctx, "¡%s espera para robar un efecto!" % who.get_display_name())
		_:
			push_warning("CmdVolatile: kind desconocido '%s'" % kind)
			return false
	return true


func _resolve_target(ctx: EffectContext) -> BattleBattler:
	# target=user | target=opponent | target=ally | default user
	var tag: String = ""
	for i: int in range(args.size()):
		var a: String = arg_string(i)
		if a.begins_with("target="):
			tag = a.substr(7).to_lower()
			break
	match tag:
		"opponent", "foe", "target", "rival":
			return ctx.target
		"ally":
			if ctx.battle != null and ctx.user != null:
				return ctx.battle.get_ally(ctx.user)
			return null
		"attacker":
			return ctx.attacker if ctx.attacker else ctx.user
		_:
			return ctx.user


func _fail(ctx: EffectContext) -> void:
	_msg(ctx, "¡No surtirá efecto!")


func _msg(ctx: EffectContext, text: String) -> void:
	if ctx.battle != null:
		ctx.battle.message.emit(text)
	ctx.add_message(text)


func _emit_hp(ctx: EffectContext, b: BattleBattler) -> void:
	if ctx.battle != null and b != null and ctx.battle.has_method("_emit_hp_battler"):
		ctx.battle._emit_hp_battler(b)
	elif ctx.battle != null and b != null:
		ctx.battle.hp_changed.emit(b.is_player_side, b.get_current_hp(), b.get_max_hp())
