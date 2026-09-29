
extends RefCounted
class_name BattleSetEffect
## Efectos de movimientos de estado (extraído de BattleManager._apply_status_move_effect).
## Tipado estricto. `battle` es BattleMain u objeto con la misma API.


static func apply(battle: Object, actor: BattleBattler, target: BattleBattler, move: MoveData) -> void:
	if actor == null or move == null:
		return
	# Scripts data-driven primero
	if await BattleMoveEffects.try_status_on_use(battle, actor, target, move):
		return
	if actor == null or actor.is_fainted() or move == null:
		return
	# Scripts .txt de movimientos (MoveSystem) — si existe on_use, no usa el match legacy
	if MoveSystem.has_script(int(move.effect)):
		var handled: bool = await MoveSystem.run_on_use(actor, target, move, battle)
		if handled:
			return

	var receiver: BattleBattler = actor if move.target == MoveStruct.MoveTarget.TARGET_USER else target

	var stat_effect: Array = MoveEffectResolver.get_primary_stat_effect(move.effect)
	if not stat_effect.is_empty():
		await BattleStatChange.apply(battle, receiver, stat_effect[0], stat_effect[1], receiver == target)
		return

	var acc_eva: Array = MoveEffectResolver.get_primary_accuracy_evasion_effect(move.effect)
	if not acc_eva.is_empty():
		var is_acc: bool = acc_eva[0] == "acc"
		var stages: int = acc_eva[1]
		if is_acc and stages < 0 and receiver == target and AbilityRuntime.blocks_foe_accuracy_drop(receiver):
			await _announce(battle, receiver)
			BattleMessage.say(battle, "¡La precisión de %s no bajó!" % receiver.get_display_name())
			await _w(battle, 0.6)
			return
		var adjusted: int = AbilityRuntime.adjust_own_stage_change(receiver, stages)
		var actual: int = receiver.modify_accuracy_stage(adjusted) if is_acc else receiver.modify_evasion_stage(adjusted)
		var label: String = "Precisión" if is_acc else "Evasión"
		if actual == 0:
			BattleMessage.say(battle, "¡La %s de %s ya no puede cambiar más!" % [label, receiver.get_display_name()])
		elif actual > 0:
			BattleMessage.say(battle, "¡La %s de %s subió!" % [label, receiver.get_display_name()])
		else:
			BattleMessage.say(battle, "¡La %s de %s bajó!" % [label, receiver.get_display_name()])
		await _w(battle, 0.6)
		return

	if MoveEffectResolver.is_confuse_effect(move.effect, move.secondary_effect):
		await BattleStatChange.apply_confusion(battle, receiver)
		return

	if move.effect == MoveStruct.MoveEffect.EFFECT_NON_VOLATILE_STATUS:
		var status_value: int = MoveEffectResolver.get_secondary_status(move.secondary_effect)
		if status_value >= 0:
			await BattleStatChange.apply_status(battle, receiver, status_value as PokemonInstance.Status)
			return

	match move.effect:
		MoveStruct.MoveEffect.EFFECT_RESTORE_HP, MoveStruct.MoveEffect.EFFECT_SOFTBOILED, \
		MoveStruct.MoveEffect.EFFECT_HEAL_PULSE, MoveStruct.MoveEffect.EFFECT_MORNING_SUN, \
		MoveStruct.MoveEffect.EFFECT_SYNTHESIS, MoveStruct.MoveEffect.EFFECT_MOONLIGHT, \
		MoveStruct.MoveEffect.EFFECT_ROOST, MoveStruct.MoveEffect.EFFECT_SHORE_UP, \
		MoveStruct.MoveEffect.EFFECT_LIFE_DEW, MoveStruct.MoveEffect.EFFECT_JUNGLE_HEALING:
			await _heal_target(battle, receiver, move)
			return

		MoveStruct.MoveEffect.EFFECT_REST:
			if actor.pokemon.current_hp >= actor.get_max_hp() or actor.pokemon.has_status():
				BattleMessage.say(battle, "¡No surtirá efecto!")
				await _w(battle, 0.7)
				return
			actor.pokemon.current_hp = actor.get_max_hp()
			actor.pokemon.status = PokemonInstance.Status.SLEEP
			actor.pokemon.status_counter = 2
			_ehp(battle, actor.is_player_side)
			BattleMessage.say(battle, "¡%s se durmió y recuperó todos sus PS!" % actor.get_display_name())
			await _w(battle, 0.8)
			return

		MoveStruct.MoveEffect.EFFECT_HAZE:
			# Legacy: MoveSystem/haze.txt suele interceptar antes. Solo stats.
			if battle.player != null:
				battle.player.reset_stat_stages()
			if battle.enemy != null:
				battle.enemy.reset_stat_stages()
			BattleMessage.say(battle, "¡Se eliminaron todos los cambios de estadísticas!")
			await _w(battle, 0.7)
			return

		MoveStruct.MoveEffect.EFFECT_HEAL_BELL, MoveStruct.MoveEffect.EFFECT_REFRESH, MoveStruct.MoveEffect.EFFECT_PURIFY:
			if receiver.pokemon.has_status():
				receiver.pokemon.cure_status()
				BattleMessage.say(battle, "¡%s se curó de su estado!" % receiver.get_display_name())
			else:
				BattleMessage.say(battle, "¡Pero falló!")
			await _w(battle, 0.7)
			return

		MoveStruct.MoveEffect.EFFECT_WEATHER, MoveStruct.MoveEffect.EFFECT_WEATHER_AND_SWITCH:
			await _weather_from_move(battle, move)
			await _w(battle, 0.7)
			return

		MoveStruct.MoveEffect.EFFECT_BULK_UP:
			await BattleStatChange.apply(battle, actor, PokemonInstance.Stat.ATTACK, 1)
			await BattleStatChange.apply(battle, actor, PokemonInstance.Stat.DEFENSE, 1)
			return
		MoveStruct.MoveEffect.EFFECT_CALM_MIND:
			await BattleStatChange.apply(battle, actor, PokemonInstance.Stat.SP_ATTACK, 1)
			await BattleStatChange.apply(battle, actor, PokemonInstance.Stat.SP_DEFENSE, 1)
			return
		MoveStruct.MoveEffect.EFFECT_DRAGON_DANCE:
			await BattleStatChange.apply(battle, actor, PokemonInstance.Stat.ATTACK, 1)
			await BattleStatChange.apply(battle, actor, PokemonInstance.Stat.SPEED, 1)
			return
		MoveStruct.MoveEffect.EFFECT_COSMIC_POWER:
			await BattleStatChange.apply(battle, actor, PokemonInstance.Stat.DEFENSE, 1)
			await BattleStatChange.apply(battle, actor, PokemonInstance.Stat.SP_DEFENSE, 1)
			return
		MoveStruct.MoveEffect.EFFECT_QUIVER_DANCE:
			await BattleStatChange.apply(battle, actor, PokemonInstance.Stat.SP_ATTACK, 1)
			await BattleStatChange.apply(battle, actor, PokemonInstance.Stat.SP_DEFENSE, 1)
			await BattleStatChange.apply(battle, actor, PokemonInstance.Stat.SPEED, 1)
			return
		MoveStruct.MoveEffect.EFFECT_SHIFT_GEAR:
			await BattleStatChange.apply(battle, actor, PokemonInstance.Stat.ATTACK, 1)
			await BattleStatChange.apply(battle, actor, PokemonInstance.Stat.SPEED, 2)
			return
		MoveStruct.MoveEffect.EFFECT_SHELL_SMASH:
			await BattleStatChange.apply(battle, actor, PokemonInstance.Stat.DEFENSE, -1)
			await BattleStatChange.apply(battle, actor, PokemonInstance.Stat.SP_DEFENSE, -1)
			await BattleStatChange.apply(battle, actor, PokemonInstance.Stat.ATTACK, 2)
			await BattleStatChange.apply(battle, actor, PokemonInstance.Stat.SP_ATTACK, 2)
			await BattleStatChange.apply(battle, actor, PokemonInstance.Stat.SPEED, 2)
			return
		MoveStruct.MoveEffect.EFFECT_REFLECT:
			var own_side: FieldSide = _side(battle, actor)
			if own_side.reflect_turns > 0:
				BattleMessage.say(battle, "¡Pero falló!")
			else:
				own_side.reflect_turns = 5
				BattleMessage.say(battle, "¡Se alzó un muro de reflejos alrededor del equipo de %s!" % actor.get_display_name())
			await _w(battle, 0.8)
			return

		MoveStruct.MoveEffect.EFFECT_LIGHT_SCREEN:
			var own_side2: FieldSide = _side(battle, actor)
			if own_side2.light_screen_turns > 0:
				BattleMessage.say(battle, "¡Pero falló!")
			else:
				own_side2.light_screen_turns = 5
				BattleMessage.say(battle, "¡Se alzó una pantalla de luz alrededor del equipo de %s!" % actor.get_display_name())
			await _w(battle, 0.8)
			return

		MoveStruct.MoveEffect.EFFECT_AURORA_VEIL:
			if battle.weather != AbilityBattleEffect.weatherAbilityID.WEATHER_SNOW:
				BattleMessage.say(battle, "¡Pero falló!")
				await _w(battle, 0.8)
				return
			var own_side3: FieldSide = _side(battle, actor)
			if own_side3.aurora_veil_turns > 0:
				BattleMessage.say(battle, "¡Pero falló!")
			else:
				own_side3.aurora_veil_turns = 5
				BattleMessage.say(battle, "¡Se alzó un velo aurora alrededor del equipo de %s!" % actor.get_display_name())
			await _w(battle, 0.8)
			return

		MoveStruct.MoveEffect.EFFECT_SPIKES:
			var opp_side: FieldSide = _side(battle, target)
			if opp_side.spikes_layers >= 3:
				BattleMessage.say(battle, "¡Pero falló!")
			else:
				opp_side.spikes_layers += 1
				BattleMessage.say(battle, "¡Se esparcieron púas alrededor del equipo rival!")
			await _w(battle, 0.8)
			return

		MoveStruct.MoveEffect.EFFECT_TOXIC_SPIKES:
			var opp_side2: FieldSide = _side(battle, target)
			if opp_side2.toxic_spikes_layers >= 2:
				BattleMessage.say(battle, "¡Pero falló!")
			else:
				opp_side2.toxic_spikes_layers += 1
				BattleMessage.say(battle, "¡Se esparcieron púas tóxicas alrededor del equipo rival!")
			await _w(battle, 0.8)
			return

		MoveStruct.MoveEffect.EFFECT_STEALTH_ROCK:
			var opp_side3: FieldSide = _side(battle, target)
			if opp_side3.stealth_rock:
				BattleMessage.say(battle, "¡Pero falló!")
			else:
				opp_side3.stealth_rock = true
				BattleMessage.say(battle, "¡Aparecieron rocas puntiagudas alrededor del equipo rival!")
			await _w(battle, 0.8)
			return

		MoveStruct.MoveEffect.EFFECT_STICKY_WEB:
			var opp_side4: FieldSide = _side(battle, target)
			if opp_side4.sticky_web:
				BattleMessage.say(battle, "¡Pero falló!")
			else:
				opp_side4.sticky_web = true
				BattleMessage.say(battle, "¡Se tejió una red pegajosa bajo los pies del equipo rival!")
			await _w(battle, 0.8)
			return

		MoveStruct.MoveEffect.EFFECT_DEFOG:
			var actual: int = target.modify_evasion_stage(-1)
			if actual < 0:
				BattleMessage.say(battle, "¡La Evasión de %s bajó!" % target.get_display_name())
				await _w(battle, 0.6)
			_pside(battle).clear_hazards()
			_pside(battle).clear_screens()
			_eside(battle).clear_hazards()
			_eside(battle).clear_screens()
			BattleMessage.say(battle, "¡Los efectos del terreno se disiparon!")
			await _w(battle, 0.8)
			return

		MoveStruct.MoveEffect.EFFECT_MIST:
			var mist_side: FieldSide = _side(battle, actor)
			if mist_side.mist_turns > 0:
				BattleMessage.say(battle, "¡No surtirá efecto!")
				await _w(battle, 0.7)
				return
			mist_side.mist_turns = 5
			BattleMessage.say(battle, "¡El equipo de %s quedó envuelto en neblina!" % actor.get_display_name())
			await _w(battle, 0.7)
			return

		MoveStruct.MoveEffect.EFFECT_FOCUS_ENERGY:
			if actor.focus_energy:
				BattleMessage.say(battle, "¡No surtirá efecto!")
				await _w(battle, 0.7)
				return
			actor.focus_energy = true
			BattleMessage.say(battle, "¡%s se concentró!" % actor.get_display_name())
			await _w(battle, 0.7)
			return

		MoveStruct.MoveEffect.EFFECT_SAFEGUARD:
			var sg: FieldSide = _side(battle, actor)
			if sg.safeguard_turns > 0:
				BattleMessage.say(battle, "¡No surtirá efecto!")
				await _w(battle, 0.7)
				return
			sg.safeguard_turns = 5
			BattleMessage.say(battle, "¡El equipo de %s quedó protegido por Velo Sagrado!" % actor.get_display_name())
			await _w(battle, 0.7)
			return

		MoveStruct.MoveEffect.EFFECT_LEECH_SEED:
			if target == null or target.is_fainted():
				BattleMessage.say(battle, "¡No surtirá efecto!")
				await _w(battle, 0.7)
				return
			if target.leech_seeded:
				BattleMessage.say(battle, "¡%s ya está drenado!" % target.get_display_name())
				await _w(battle, 0.7)
				return
			var seed_t1: PokemonData.Type = target.pokemon.get_type_1() if target.pokemon else PokemonData.Type.TYPE_NONE
			var seed_t2: PokemonData.Type = target.pokemon.get_type_2() if target.pokemon else PokemonData.Type.TYPE_NONE
			if seed_t1 == PokemonData.Type.TYPE_GRASS or seed_t2 == PokemonData.Type.TYPE_GRASS:
				BattleMessage.say(battle, "¡No afectó a %s!" % target.get_display_name())
				await _w(battle, 0.7)
				return
			target.leech_seeded = true
			BattleMessage.say(battle, "¡%s fue infectado por Drenadoras!" % target.get_display_name())
			await _w(battle, 0.7)
			return

		MoveStruct.MoveEffect.EFFECT_GROWTH:
			var g_stages: int = 2 if battle.weather == AbilityBattleEffect.weatherAbilityID.WEATHER_DROUGHT else 1
			await BattleStatChange.apply(battle, actor, PokemonInstance.Stat.ATTACK, g_stages)
			await BattleStatChange.apply(battle, actor, PokemonInstance.Stat.SP_ATTACK, g_stages)
			return

		MoveStruct.MoveEffect.EFFECT_COIL:
			await BattleStatChange.apply(battle, actor, PokemonInstance.Stat.ATTACK, 1)
			await BattleStatChange.apply(battle, actor, PokemonInstance.Stat.DEFENSE, 1)
			var coil_acc: int = AbilityRuntime.adjust_own_stage_change(actor, 1)
			var coil_actual: int = actor.modify_accuracy_stage(coil_acc)
			if coil_actual > 0:
				BattleMessage.say(battle, "¡La Precisión de %s subió!" % actor.get_display_name())
			elif coil_actual == 0:
				BattleMessage.say(battle, "¡La Precisión de %s ya no puede cambiar más!" % actor.get_display_name())
			await _w(battle, 0.5)
			return

		MoveStruct.MoveEffect.EFFECT_TICKLE:
			await BattleStatChange.apply(battle, target, PokemonInstance.Stat.ATTACK, -1, true)
			await BattleStatChange.apply(battle, target, PokemonInstance.Stat.DEFENSE, -1, true)
			return

		MoveStruct.MoveEffect.EFFECT_NOBLE_ROAR:
			await BattleStatChange.apply(battle, target, PokemonInstance.Stat.ATTACK, -1, true)
			await BattleStatChange.apply(battle, target, PokemonInstance.Stat.SP_ATTACK, -1, true)
			return

		MoveStruct.MoveEffect.EFFECT_VENOM_DRENCH:
			if target == null or target.pokemon == null:
				return
			var vd_st: PokemonInstance.Status = target.pokemon.status
			if vd_st != PokemonInstance.Status.POISON and vd_st != PokemonInstance.Status.TOXIC:
				BattleMessage.say(battle, "¡No surtirá efecto!")
				await _w(battle, 0.7)
				return
			await BattleStatChange.apply(battle, target, PokemonInstance.Stat.ATTACK, -1, true)
			await BattleStatChange.apply(battle, target, PokemonInstance.Stat.SP_ATTACK, -1, true)
			await BattleStatChange.apply(battle, target, PokemonInstance.Stat.SPEED, -1, true)
			return

		MoveStruct.MoveEffect.EFFECT_TOXIC_THREAD:
			await BattleStatChange.apply(battle, target, PokemonInstance.Stat.SPEED, -1, true)
			await BattleStatChange.apply_status(battle, target, PokemonInstance.Status.POISON)
			return

		MoveStruct.MoveEffect.EFFECT_SWAGGER:
			await BattleStatChange.apply(battle, target, PokemonInstance.Stat.ATTACK, 2, true)
			await BattleStatChange.apply_confusion(battle, target)
			return

		MoveStruct.MoveEffect.EFFECT_FLATTER:
			await BattleStatChange.apply(battle, target, PokemonInstance.Stat.SP_ATTACK, 1, true)
			await BattleStatChange.apply_confusion(battle, target)
			return

		MoveStruct.MoveEffect.EFFECT_BELLY_DRUM:
			if actor.get_current_hp() <= int(actor.get_max_hp() / 2) or actor.get_current_hp() <= 1:
				BattleMessage.say(battle, "¡No surtirá efecto!")
				await _w(battle, 0.7)
				return
			var drum_cost: int = int(actor.get_max_hp() / 2)
			actor.apply_damage(drum_cost)
			_ehp(battle, actor.is_player_side)
			actor.stage_attack = 6
			BattleMessage.say(battle, "¡%s redujo sus PS y maximizó su Ataque!" % actor.get_display_name())
			await _w(battle, 0.8)
			return

		MoveStruct.MoveEffect.EFFECT_VICTORY_DANCE:
			await BattleStatChange.apply(battle, actor, PokemonInstance.Stat.ATTACK, 1)
			await BattleStatChange.apply(battle, actor, PokemonInstance.Stat.DEFENSE, 1)
			await BattleStatChange.apply(battle, actor, PokemonInstance.Stat.SPEED, 1)
			return

		MoveStruct.MoveEffect.EFFECT_TAKE_HEART:
			if actor.pokemon != null and actor.pokemon.has_status():
				actor.pokemon.cure_status()
				BattleMessage.say(battle, "¡%s se curó del problema de estado!" % actor.get_display_name())
				await _w(battle, 0.6)
			await BattleStatChange.apply(battle, actor, PokemonInstance.Stat.SP_ATTACK, 1)
			await BattleStatChange.apply(battle, actor, PokemonInstance.Stat.SP_DEFENSE, 1)
			return

		MoveStruct.MoveEffect.EFFECT_DECORATE:
			await BattleStatChange.apply(battle, receiver, PokemonInstance.Stat.ATTACK, 2)
			await BattleStatChange.apply(battle, receiver, PokemonInstance.Stat.SP_ATTACK, 2)
			return

		MoveStruct.MoveEffect.EFFECT_ATTRACT:
			if target == null or target.pokemon == null or actor.pokemon == null:
				return
			var ag: PokemonData.Gender = actor.pokemon.gender
			var tg: PokemonData.Gender = target.pokemon.gender
			if ag == PokemonData.Gender.GENDERLESS or tg == PokemonData.Gender.GENDERLESS or ag == tg:
				BattleMessage.say(battle, "¡No surtirá efecto!")
				await _w(battle, 0.7)
				return
			target.infatuated_by_player_side = 1 if actor.is_player_side else 0
			BattleMessage.say(battle, "¡%s se enamoró de %s!" % [target.get_display_name(), actor.get_display_name()])
			await _w(battle, 0.7)
			return

		MoveStruct.MoveEffect.EFFECT_MEAN_LOOK:
			if target == null or target.is_fainted():
				return
			if target.cannot_escape:
				BattleMessage.say(battle, "¡No surtirá efecto!")
				await _w(battle, 0.7)
				return
			# Ghost type often immune to trapping - classic rule
			var ml_t1: PokemonData.Type = target.pokemon.get_type_1() if target.pokemon else PokemonData.Type.TYPE_NONE
			var ml_t2: PokemonData.Type = target.pokemon.get_type_2() if target.pokemon else PokemonData.Type.TYPE_NONE
			if ml_t1 == PokemonData.Type.TYPE_GHOST or ml_t2 == PokemonData.Type.TYPE_GHOST:
				BattleMessage.say(battle, "¡No afectó a %s!" % target.get_display_name())
				await _w(battle, 0.7)
				return
			target.cannot_escape = true
			BattleMessage.say(battle, "¡%s no puede escapar!" % target.get_display_name())
			await _w(battle, 0.7)
			return

		MoveStruct.MoveEffect.EFFECT_PERISH_SONG:
			var any_set: bool = false
			for b: BattleBattler in BattleUtil.get_all_actives(battle):
				if b == null or b.is_fainted():
					continue
				# Soundproof
				if AbilityRuntime.has(b, AbilityId.Id.SOUNDPROOF):
					continue
				if b.perish_count < 0:
					b.perish_count = 3
					any_set = true
			if any_set:
				BattleMessage.say(battle, "¡Todos los Pokémon que oyeron la canción perecerán en 3 turnos!")
			else:
				BattleMessage.say(battle, "¡Pero falló!")
			await _w(battle, 0.8)
			return

		MoveStruct.MoveEffect.EFFECT_DESTINY_BOND:
			actor.destiny_bond_active = true
			BattleMessage.say(battle, "¡%s intenta llevarse a su enemigo consigo!" % actor.get_display_name())
			await _w(battle, 0.7)
			return

		MoveStruct.MoveEffect.EFFECT_TAUNT:
			if target == null or target.is_fainted():
				return
			if target.taunt_turns > 0:
				BattleMessage.say(battle, "¡No surtirá efecto!")
				await _w(battle, 0.7)
				return
			target.taunt_turns = 3
			BattleMessage.say(battle, "¡%s cayó en la trampa de Provocación!" % target.get_display_name())
			await _w(battle, 0.7)
			return

		MoveStruct.MoveEffect.EFFECT_TORMENT:
			if target == null or target.is_fainted():
				return
			target.torment_active = true
			BattleMessage.say(battle, "¡%s fue víctima de Tormento!" % target.get_display_name())
			await _w(battle, 0.7)
			return

		MoveStruct.MoveEffect.EFFECT_DISABLE:
			if target == null or target.is_fainted() or target.last_move_used_id < 0:
				BattleMessage.say(battle, "¡Pero falló!")
				await _w(battle, 0.7)
				return
			target.disable_move_id = target.last_move_used_id
			target.disable_turns = 4
			BattleMessage.say(battle, "¡Se anuló el último movimiento de %s!" % target.get_display_name())
			await _w(battle, 0.7)
			return

		MoveStruct.MoveEffect.EFFECT_ENCORE:
			if target == null or target.is_fainted() or target.last_move_used_id < 0:
				BattleMessage.say(battle, "¡Pero falló!")
				await _w(battle, 0.7)
				return
			target.encore_move_id = target.last_move_used_id
			target.encore_turns = 3
			BattleMessage.say(battle, "¡%s recibió un Otra Vez!" % target.get_display_name())
			await _w(battle, 0.7)
			return

		MoveStruct.MoveEffect.EFFECT_HEAL_BLOCK:
			if target == null or target.is_fainted():
				return
			target.heal_block_turns = 5
			BattleMessage.say(battle, "¡%s no podrá curarse!" % target.get_display_name())
			await _w(battle, 0.7)
			return

		MoveStruct.MoveEffect.EFFECT_LOCK_ON:
			if target == null or target.is_fainted():
				return
			target.locked_on_by_side = 1 if actor.is_player_side else 0
			BattleMessage.say(battle, "¡%s se fijó en %s!" % [actor.get_display_name(), target.get_display_name()])
			await _w(battle, 0.7)
			return

		MoveStruct.MoveEffect.EFFECT_SUBSTITUTE:
			@warning_ignore("integer_division")
			var sub_cost: int = maxi(1, int(actor.get_max_hp() / 4))
			if actor.get_current_hp() <= sub_cost or actor.substitute_hp > 0:
				BattleMessage.say(battle, "¡No surtirá efecto!")
				await _w(battle, 0.7)
				return
			actor.apply_damage(sub_cost)
			_ehp(battle, actor.is_player_side)
			actor.substitute_hp = sub_cost
			BattleMessage.say(battle, "¡%s creó un sustituto!" % actor.get_display_name())
			await _w(battle, 0.7)
			return

		MoveStruct.MoveEffect.EFFECT_NIGHTMARE:
			if target == null or target.pokemon == null:
				return
			if target.pokemon.status != PokemonInstance.Status.SLEEP:
				BattleMessage.say(battle, "¡No surtirá efecto!")
				await _w(battle, 0.7)
				return
			target.has_nightmare = true
			BattleMessage.say(battle, "¡%s empezó a tener pesadillas!" % target.get_display_name())
			await _w(battle, 0.7)
			return

		MoveStruct.MoveEffect.EFFECT_CURSE:
			# Ghost: curse target; else +Atk +Def -Spe
			var c1: PokemonData.Type = actor.pokemon.get_type_1() if actor.pokemon else PokemonData.Type.TYPE_NONE
			var c2: PokemonData.Type = actor.pokemon.get_type_2() if actor.pokemon else PokemonData.Type.TYPE_NONE
			var is_ghost: bool = c1 == PokemonData.Type.TYPE_GHOST or c2 == PokemonData.Type.TYPE_GHOST
			if is_ghost:
				if target == null or target.is_fainted() or target.is_cursed:
					BattleMessage.say(battle, "¡No surtirá efecto!")
					await _w(battle, 0.7)
					return
				@warning_ignore("integer_division")
				var curse_cost: int = maxi(1, int(actor.get_max_hp() / 2))
				actor.apply_damage(curse_cost)
				_ehp(battle, actor.is_player_side)
				target.is_cursed = true
				BattleMessage.say(battle, "¡%s maldijo a %s!" % [actor.get_display_name(), target.get_display_name()])
				await _w(battle, 0.7)
			else:
				await BattleStatChange.apply(battle, actor, PokemonInstance.Stat.SPEED, -1)
				await BattleStatChange.apply(battle, actor, PokemonInstance.Stat.ATTACK, 1)
				await BattleStatChange.apply(battle, actor, PokemonInstance.Stat.DEFENSE, 1)
			return

		MoveStruct.MoveEffect.EFFECT_SPITE:
			if target == null or target.pokemon == null or target.last_move_used_id < 0:
				BattleMessage.say(battle, "¡Pero falló!")
				await _w(battle, 0.7)
				return
			var spite_done: bool = false
			for slot: PokemonMoveSlot in target.pokemon.moves:
				if slot != null and int(slot.move_id) == target.last_move_used_id:
					slot.current_pp = maxi(0, slot.current_pp - 4)
					spite_done = true
					break
			if spite_done:
				BattleMessage.say(battle, "¡Los PP del último movimiento de %s bajaron!" % target.get_display_name())
			else:
				BattleMessage.say(battle, "¡Pero falló!")
			await _w(battle, 0.7)
			return

		MoveStruct.MoveEffect.EFFECT_PARTING_SHOT:
			if target != null and not target.is_fainted():
				await BattleStatChange.apply(battle, target, PokemonInstance.Stat.ATTACK, -1, true)
				await BattleStatChange.apply(battle, target, PokemonInstance.Stat.SP_ATTACK, -1, true)
			await _pivot_out(battle, actor)
			return

		MoveStruct.MoveEffect.EFFECT_BATON_PASS:
			# Conserva stages y algunos volatiles al cambiar
			await _pivot_out(battle, actor, true)
			return

		MoveStruct.MoveEffect.EFFECT_TELEPORT:
			if battle.is_trainer_battle:
				await _pivot_out(battle, actor)
			else:
				BattleMessage.say(battle, "¡%s huyó del combate!" % actor.get_display_name())
				await _w(battle, 0.8)
				BattleDone.cleanup(battle)
				battle.is_running = false
				battle.battle_ended.emit(actor.is_player_side)
			return

		MoveStruct.MoveEffect.EFFECT_ROAR:
			# Fuerza el cambio del rival (o huida en salvaje)
			await _force_switch(battle, target if target != null else (
				battle.enemy if actor.is_player_side else battle.player
			))
			return

		MoveStruct.MoveEffect.EFFECT_TRANSFORM:
			await _transform(battle, actor, target)
			return

		MoveStruct.MoveEffect.EFFECT_MIMIC:
			await _mimic(battle, actor, target)
			return

		MoveStruct.MoveEffect.EFFECT_SKETCH:
			await _sketch(battle, actor, target)
			return

		MoveStruct.MoveEffect.EFFECT_MIRROR_MOVE:
			await _copy_last_move(battle, actor, target, true)
			return

		MoveStruct.MoveEffect.EFFECT_COPYCAT:
			await _copy_last_move(battle, actor, target, false)
			return

		MoveStruct.MoveEffect.EFFECT_METRONOME:
			await _metronome(battle, actor, target)
			return

		MoveStruct.MoveEffect.EFFECT_SLEEP_TALK:
			await _sleep_talk(battle, actor, target)
			return

		MoveStruct.MoveEffect.EFFECT_SNORE:
			# Solo si duerme; luego daño vía power (si power>0 no llega aquí)
			if actor.pokemon == null or actor.pokemon.status != PokemonInstance.Status.SLEEP:
				BattleMessage.say(battle, "¡No surtirá efecto!")
				await _w(battle, 0.7)
				return
			BattleMessage.say(battle, "¡%s ronca fuerte!" % actor.get_display_name())
			await _w(battle, 0.5)
			return

		MoveStruct.MoveEffect.EFFECT_CONVERSION:
			if actor.pokemon == null or actor.pokemon.moves.is_empty():
				return
			var first_slot: PokemonMoveSlot = actor.pokemon.moves[0]
			if first_slot == null:
				return
			var md0: MoveData = MoveDatabase.get_move(first_slot.move_id)
			if md0 == null:
				return
			actor.battle_type_1 = int(md0.type)
			actor.battle_type_2 = -1
			BattleMessage.say(battle, "¡%s se convirtió al tipo %s!" % [actor.get_display_name(), str(md0.type)])
			await _w(battle, 0.7)
			return

		MoveStruct.MoveEffect.EFFECT_DO_NOTHING, MoveStruct.MoveEffect.EFFECT_HOLD_HANDS, \
		MoveStruct.MoveEffect.EFFECT_CELEBRATE, MoveStruct.MoveEffect.EFFECT_HAPPY_HOUR:
			BattleMessage.say(battle, "¡%s está celebrando!" % actor.get_display_name())
			await _w(battle, 0.6)
			return

		MoveStruct.MoveEffect.EFFECT_TRICK_ROOM:
			if battle.trick_room_turns > 0:
				battle.trick_room_turns = 0
				BattleMessage.say(battle, "¡El Espacio Raro se disipó!")
			else:
				battle.trick_room_turns = 5
				BattleMessage.say(battle, "¡Las dimensiones se distorsionaron!")
			await _w(battle, 0.7)
			return

		MoveStruct.MoveEffect.EFFECT_WONDER_ROOM:
			battle.wonder_room_turns = 5 if battle.wonder_room_turns <= 0 else 0
			BattleMessage.say(battle, "¡Defensa y Def. Especial se intercambiaron!" if battle.wonder_room_turns > 0 else "¡Mundo Maravilla se disipó!")
			await _w(battle, 0.7)
			return

		MoveStruct.MoveEffect.EFFECT_MAGIC_ROOM:
			battle.magic_room_turns = 5 if battle.magic_room_turns <= 0 else 0
			BattleMessage.say(battle, "¡Los objetos perdieron su efecto!" if battle.magic_room_turns > 0 else "¡Zona Extraña se disipó!")
			await _w(battle, 0.7)
			return

		MoveStruct.MoveEffect.EFFECT_GRAVITY:
			battle.gravity_turns = 5
			for _g2: BattleBattler in BattleUtil.get_all_actives(battle):
				if _g2 != null:
					_g2.set_meta("gravity_active", true)
			BattleMessage.say(battle, "¡La gravedad se intensificó!")
			await _w(battle, 0.7)
			return

		MoveStruct.MoveEffect.EFFECT_TAILWIND:
			var tw: FieldSide = _side(battle, actor)
			tw.tailwind_turns = 4
			BattleMessage.say(battle, "¡El Viento Afín sopla a favor del equipo de %s!" % actor.get_display_name())
			await _w(battle, 0.7)
			return

		MoveStruct.MoveEffect.EFFECT_ELECTRIC_TERRAIN:
			battle.set_terrain(BattleManager.TerrainId.TERRAIN_ELECTRIC, 5)
			await _w(battle, 0.5)
			return
		MoveStruct.MoveEffect.EFFECT_GRASSY_TERRAIN:
			battle.set_terrain(BattleManager.TerrainId.TERRAIN_GRASSY, 5)
			await _w(battle, 0.5)
			return
		MoveStruct.MoveEffect.EFFECT_MISTY_TERRAIN:
			battle.set_terrain(BattleManager.TerrainId.TERRAIN_MISTY, 5)
			await _w(battle, 0.5)
			return
		MoveStruct.MoveEffect.EFFECT_PSYCHIC_TERRAIN:
			battle.set_terrain(BattleManager.TerrainId.TERRAIN_PSYCHIC, 5)
			await _w(battle, 0.5)
			return

		MoveStruct.MoveEffect.EFFECT_PAIN_SPLIT:
			if target == null or target.is_fainted() or actor.pokemon == null or target.pokemon == null:
				return
			var total: int = actor.get_current_hp() + target.get_current_hp()
			@warning_ignore("integer_division")
			var mid: int = int(total / 2)
			actor.pokemon.current_hp = mini(actor.get_max_hp(), mid)
			target.pokemon.current_hp = mini(target.get_max_hp(), mid)
			_ehp(battle, actor.is_player_side)
			_ehp(battle, target.is_player_side)
			BattleMessage.say(battle, "¡Los PS se repartieron!")
			await _w(battle, 0.7)
			return

		MoveStruct.MoveEffect.EFFECT_PSYCH_UP:
			if target == null:
				return
			actor.stage_attack = target.stage_attack
			actor.stage_defense = target.stage_defense
			actor.stage_sp_attack = target.stage_sp_attack
			actor.stage_sp_defense = target.stage_sp_defense
			actor.stage_speed = target.stage_speed
			actor.stage_accuracy = target.stage_accuracy
			actor.stage_evasion = target.stage_evasion
			BattleMessage.say(battle, "¡%s copió los cambios de estadísticas!" % actor.get_display_name())
			await _w(battle, 0.7)
			return

		MoveStruct.MoveEffect.EFFECT_MEMENTO:
			if target != null and not target.is_fainted():
				await BattleStatChange.apply(battle, target, PokemonInstance.Stat.ATTACK, -2, true)
				await BattleStatChange.apply(battle, target, PokemonInstance.Stat.SP_ATTACK, -2, true)
			actor.apply_damage(actor.get_current_hp())
			_ehp(battle, actor.is_player_side)
			BattleMessage.say(battle, "¡%s se debilitó!" % actor.get_display_name())
			await _w(battle, 0.7)
			return

		MoveStruct.MoveEffect.EFFECT_HEALING_WISH, MoveStruct.MoveEffect.EFFECT_LUNAR_DANCE:
			actor.apply_damage(actor.get_current_hp())
			_ehp(battle, actor.is_player_side)
			BattleMessage.say(battle, "¡%s se sacrificó por el equipo!" % actor.get_display_name())
			await _w(battle, 0.7)
			# El entrante recibirá curación vía wish_turns en el slot
			var side_hw: FieldSide = _side(battle, actor)
			var lunar: bool = move.effect == MoveStruct.MoveEffect.EFFECT_LUNAR_DANCE
			side_hw.queue_healing_wish(actor.slot_index, lunar)
			actor.wish_turns = -1
			actor.wish_hp = 0
			if actor.is_player_side:
				await _forced_switch(battle, true)
			else:
				if BattleUtil.party_has_reserve(battle, false):
					await _pivot_out(battle, actor, false)
			return

		MoveStruct.MoveEffect.EFFECT_WISH:
			@warning_ignore("integer_division")
			var side_w: FieldSide = _side(battle, actor)
			side_w.set_wish(actor.slot_index, 1, maxi(1, int(actor.get_max_hp() / 2)))
			actor.wish_turns = -1
			actor.wish_hp = 0
			BattleMessage.say(battle, "¡%s pidió un deseo!" % actor.get_display_name())
			await _w(battle, 0.7)
			return

		MoveStruct.MoveEffect.EFFECT_STOCKPILE:
			if actor.stockpile_count >= 3:
				BattleMessage.say(battle, "¡No surtirá efecto!")
				await _w(battle, 0.6)
				return
			actor.stockpile_count += 1
			await BattleStatChange.apply(battle, actor, PokemonInstance.Stat.DEFENSE, 1)
			await BattleStatChange.apply(battle, actor, PokemonInstance.Stat.SP_DEFENSE, 1)
			BattleMessage.say(battle, "¡%s acumuló energía (%d)!" % [actor.get_display_name(), actor.stockpile_count])
			await _w(battle, 0.5)
			return

		MoveStruct.MoveEffect.EFFECT_SWALLOW:
			if actor.stockpile_count <= 0:
				BattleMessage.say(battle, "¡No surtirá efecto!")
				await _w(battle, 0.6)
				return
			var frac: float = [0.0, 0.25, 0.5, 1.0][clampi(actor.stockpile_count, 0, 3)]
			var heal_sw: int = maxi(1, int(actor.get_max_hp() * frac))
			if actor.heal_block_turns > 0:
				BattleMessage.say(battle, "¡%s no puede curarse!" % actor.get_display_name())
			else:
				actor.pokemon.apply_heal(heal_sw)
				_ehp(battle, actor.is_player_side)
				BattleMessage.say(battle, "¡%s recuperó PS!" % actor.get_display_name())
			actor.stockpile_count = 0
			await _w(battle, 0.7)
			return

		MoveStruct.MoveEffect.EFFECT_INGRAIN:
			actor.has_ingrain = true
			actor.cannot_escape = true
			BattleMessage.say(battle, "¡%s echó raíces!" % actor.get_display_name())
			await _w(battle, 0.7)
			return

		MoveStruct.MoveEffect.EFFECT_AQUA_RING:
			actor.has_aqua_ring = true
			BattleMessage.say(battle, "¡%s se envolvió en un velo de agua!" % actor.get_display_name())
			await _w(battle, 0.7)
			return

		MoveStruct.MoveEffect.EFFECT_MAGNET_RISE:
			actor.magnet_rise_turns = 5
			BattleMessage.say(battle, "¡%s levita con electromagnetismo!" % actor.get_display_name())
			await _w(battle, 0.7)
			return

		MoveStruct.MoveEffect.EFFECT_NO_RETREAT:
			if actor.no_retreat:
				BattleMessage.say(battle, "¡No surtirá efecto!")
				await _w(battle, 0.6)
				return
			actor.no_retreat = true
			actor.cannot_escape = true
			await BattleStatChange.apply(battle, actor, PokemonInstance.Stat.ATTACK, 1)
			await BattleStatChange.apply(battle, actor, PokemonInstance.Stat.DEFENSE, 1)
			await BattleStatChange.apply(battle, actor, PokemonInstance.Stat.SP_ATTACK, 1)
			await BattleStatChange.apply(battle, actor, PokemonInstance.Stat.SP_DEFENSE, 1)
			await BattleStatChange.apply(battle, actor, PokemonInstance.Stat.SPEED, 1)
			return

		MoveStruct.MoveEffect.EFFECT_OCTOLOCK:
			if target == null:
				return
			target.octolocked = true
			target.cannot_escape = true
			BattleMessage.say(battle, "¡%s quedó atrapado por Octopresa!" % target.get_display_name())
			await _w(battle, 0.7)
			return

		MoveStruct.MoveEffect.EFFECT_FORESIGHT, MoveStruct.MoveEffect.EFFECT_MIRACLE_EYE:
			if target == null:
				return
			target.is_identified = true
			BattleMessage.say(battle, "¡%s fue identificado!" % target.get_display_name())
			await _w(battle, 0.7)
			return

		MoveStruct.MoveEffect.EFFECT_MINIMIZE:
			actor.stage_evasion = clampi(actor.stage_evasion + 2, -6, 6)
			BattleMessage.say(battle, "¡La Evasión de %s subió mucho!" % actor.get_display_name())
			await _w(battle, 0.7)
			return

		MoveStruct.MoveEffect.EFFECT_DEFENSE_CURL:
			await BattleStatChange.apply(battle, actor, PokemonInstance.Stat.DEFENSE, 1)
			return

		MoveStruct.MoveEffect.EFFECT_LASER_FOCUS:
			actor.laser_focus = true
			BattleMessage.say(battle, "¡%s se concentró al máximo!" % actor.get_display_name())
			await _w(battle, 0.7)
			return

		MoveStruct.MoveEffect.EFFECT_CHARGE:
			actor.charged = true
			await BattleStatChange.apply(battle, actor, PokemonInstance.Stat.SP_DEFENSE, 1)
			BattleMessage.say(battle, "¡%s cargó energía!" % actor.get_display_name())
			await _w(battle, 0.6)
			return

		MoveStruct.MoveEffect.EFFECT_TRICK:
			if actor.pokemon == null or target == null or target.pokemon == null:
				return
			if battle.magic_room_turns > 0:
				BattleMessage.say(battle, "¡Pero falló!")
				await _w(battle, 0.6)
				return
			var item_a: int = actor.pokemon.held_item
			var item_b: int = target.pokemon.held_item
			actor.pokemon.held_item = item_b
			target.pokemon.held_item = item_a
			BattleMessage.say(battle, "¡%s intercambió los objetos!" % actor.get_display_name())
			await _w(battle, 0.7)
			return

		MoveStruct.MoveEffect.EFFECT_ROLE_PLAY:
			if target == null or target.pokemon == null or actor.pokemon == null:
				return
			actor.pokemon.ability_id = target.pokemon.ability_id
			BattleMessage.say(battle, "¡%s copió la habilidad!" % actor.get_display_name())
			await _w(battle, 0.7)
			return

		MoveStruct.MoveEffect.EFFECT_SKILL_SWAP:
			if target == null or target.pokemon == null or actor.pokemon == null:
				return
			var ab: int = actor.pokemon.ability_id
			actor.pokemon.ability_id = target.pokemon.ability_id
			target.pokemon.ability_id = ab
			BattleMessage.say(battle, "¡Se intercambiaron las habilidades!")
			await _w(battle, 0.7)
			return

		MoveStruct.MoveEffect.EFFECT_GASTRO_ACID:
			if target == null:
				return
			target.ability_active = false
			BattleMessage.say(battle, "¡La habilidad de %s fue neutralizada!" % target.get_display_name())
			await _w(battle, 0.7)
			return

		MoveStruct.MoveEffect.EFFECT_SOAK:
			if target == null:
				return
			target.battle_type_1 = int(PokemonData.Type.TYPE_WATER)
			target.battle_type_2 = -1
			BattleMessage.say(battle, "¡%s se empapó y ahora es de tipo Agua!" % target.get_display_name())
			await _w(battle, 0.7)
			return

		MoveStruct.MoveEffect.EFFECT_REFLECT_TYPE:
			if target == null:
				return
			target.battle_type_1 = actor.battle_type_1 if actor.battle_type_1 >= 0 else int(actor.pokemon.get_type_1())
			target.battle_type_2 = actor.battle_type_2 if actor.battle_type_2 >= 0 else int(actor.pokemon.get_type_2())
			# Actually Reflect Type: user copies target's types
			actor.battle_type_1 = target.battle_type_1 if target.battle_type_1 >= 0 else int(target.pokemon.get_type_1())
			actor.battle_type_2 = target.battle_type_2 if target.battle_type_2 >= 0 else int(target.pokemon.get_type_2())
			BattleMessage.say(battle, "¡%s copió el tipo!" % actor.get_display_name())
			await _w(battle, 0.7)
			return

		MoveStruct.MoveEffect.EFFECT_POWER_TRICK:
			var tmp: int = actor.stage_attack
			actor.stage_attack = actor.stage_defense
			actor.stage_defense = tmp
			# Also swap base effective by stages is enough for stage-based; full power trick swaps stats
			BattleMessage.say(battle, "¡%s intercambió Ataque y Defensa!" % actor.get_display_name())
			await _w(battle, 0.7)
			return

		MoveStruct.MoveEffect.EFFECT_HEART_SWAP:
			if target == null:
				return
			var s: Dictionary = _snap_baton(actor)
			_baton_pass(actor, _snap_baton(target))
			_baton_pass(target, s)
			BattleMessage.say(battle, "¡Se intercambiaron los cambios de estadísticas!")
			await _w(battle, 0.7)
			return

		MoveStruct.MoveEffect.EFFECT_POWER_SWAP:
			if target == null:
				return
			var a1: int = actor.stage_attack
			var a2: int = actor.stage_sp_attack
			actor.stage_attack = target.stage_attack
			actor.stage_sp_attack = target.stage_sp_attack
			target.stage_attack = a1
			target.stage_sp_attack = a2
			BattleMessage.say(battle, "¡Se intercambiaron cambios de Ataque!")
			await _w(battle, 0.7)
			return

		MoveStruct.MoveEffect.EFFECT_GUARD_SWAP:
			if target == null:
				return
			var d1: int = actor.stage_defense
			var d2: int = actor.stage_sp_defense
			actor.stage_defense = target.stage_defense
			actor.stage_sp_defense = target.stage_sp_defense
			target.stage_defense = d1
			target.stage_sp_defense = d2
			BattleMessage.say(battle, "¡Se intercambiaron cambios de Defensa!")
			await _w(battle, 0.7)
			return

		MoveStruct.MoveEffect.EFFECT_SPEED_SWAP:
			if target == null:
				return
			var sp: int = actor.stage_speed
			actor.stage_speed = target.stage_speed
			target.stage_speed = sp
			BattleMessage.say(battle, "¡Se intercambiaron las velocidades!")
			await _w(battle, 0.7)
			return

		MoveStruct.MoveEffect.EFFECT_STRENGTH_SAP:
			if target == null:
				return
			var atk_stage: int = target.stage_attack
			await BattleStatChange.apply(battle, target, PokemonInstance.Stat.ATTACK, -1, true)
			if actor.heal_block_turns <= 0:
				# Cura según Atk efectivo del rival (aprox)
				var heal_ss: int = maxi(1, target.get_effective_stat(PokemonInstance.Stat.ATTACK))
				actor.pokemon.apply_heal(heal_ss)
				_ehp(battle, actor.is_player_side)
				BattleMessage.say(battle, "¡%s absorbió fuerza!" % actor.get_display_name())
			await _w(battle, 0.6)
			return

		MoveStruct.MoveEffect.EFFECT_FILLET_AWAY:
			if actor.get_current_hp() <= int(actor.get_max_hp() / 2):
				BattleMessage.say(battle, "¡No surtirá efecto!")
				await _w(battle, 0.6)
				return
			@warning_ignore("integer_division")
			actor.apply_damage(int(actor.get_max_hp() / 2))
			_ehp(battle, actor.is_player_side)
			await BattleStatChange.apply(battle, actor, PokemonInstance.Stat.ATTACK, 2)
			await BattleStatChange.apply(battle, actor, PokemonInstance.Stat.SP_ATTACK, 2)
			await BattleStatChange.apply(battle, actor, PokemonInstance.Stat.SPEED, 2)
			return

		MoveStruct.MoveEffect.EFFECT_TIDY_UP:
			_pside(battle).clear_hazards()
			_eside(battle).clear_hazards()
			actor.substitute_hp = 0
			# clear substitutes on field lightly
			for b: BattleBattler in BattleUtil.get_all_actives(battle):
				if b != null:
					b.substitute_hp = 0
			await BattleStatChange.apply(battle, actor, PokemonInstance.Stat.ATTACK, 1)
			await BattleStatChange.apply(battle, actor, PokemonInstance.Stat.SPEED, 1)
			BattleMessage.say(battle, "¡El campo se limpió!")
			await _w(battle, 0.6)
			return

		MoveStruct.MoveEffect.EFFECT_COURT_CHANGE:
			var tmp_side: FieldSide = battle.player_side
			battle.player_side = battle.enemy_side
			battle.enemy_side = tmp_side
			BattleMessage.say(battle, "¡Se intercambiaron los efectos de ambos lados!")
			await _w(battle, 0.7)
			return

		MoveStruct.MoveEffect.EFFECT_SHED_TAIL:
			@warning_ignore("integer_division")
			var st_cost: int = maxi(1, int(actor.get_max_hp() / 2))
			if actor.get_current_hp() <= st_cost:
				BattleMessage.say(battle, "¡No surtirá efecto!")
				await _w(battle, 0.6)
				return
			actor.apply_damage(st_cost)
			_ehp(battle, actor.is_player_side)
			actor.substitute_hp = maxi(1, int(actor.get_max_hp() / 4))
			await _pivot_out(battle, actor, true)
			return

		MoveStruct.MoveEffect.EFFECT_STEEL_ROLLER, MoveStruct.MoveEffect.EFFECT_ICE_SPINNER:
			# Limpia terreno (el daño se hace por power si no es status)
			if battle.terrain != BattleManager.TerrainId.TERRAIN_NONE:
				battle.terrain = BattleManager.TerrainId.TERRAIN_NONE
				battle.terrain_turns = 0
				BattleMessage.say(battle, "¡El terreno desapareció!")
				await _w(battle, 0.5)
			return

		MoveStruct.MoveEffect.EFFECT_KNOCK_OFF:
			if target != null and target.pokemon != null and target.pokemon.held_item != Items.ItemId.ITEM_NONE:
				target.pokemon.held_item = Items.ItemId.ITEM_NONE
				BattleMessage.say(battle, "¡%s perdió su objeto!" % target.get_display_name())
				await _w(battle, 0.6)
			return

		MoveStruct.MoveEffect.EFFECT_STEAL_ITEM:
			if target == null or target.pokemon == null or actor.pokemon == null:
				return
			if target.pokemon.held_item != Items.ItemId.ITEM_NONE and actor.pokemon.held_item == Items.ItemId.ITEM_NONE:
				actor.pokemon.held_item = target.pokemon.held_item
				target.pokemon.held_item = Items.ItemId.ITEM_NONE
				BattleMessage.say(battle, "¡%s robó el objeto!" % actor.get_display_name())
				await _w(battle, 0.6)
			return

		MoveStruct.MoveEffect.EFFECT_YAWN:
			if target == null or target.pokemon == null or target.pokemon.has_status():
				BattleMessage.say(battle, "¡No surtirá efecto!")
				await _w(battle, 0.6)
				return
			target.set_meta("yawn_turns", 1)
			BattleMessage.say(battle, "¡%s bostezó!" % target.get_display_name())
			await _w(battle, 0.7)
			return

		MoveStruct.MoveEffect.EFFECT_FOLLOW_ME:
			actor.set_meta("follow_me", true)
			BattleMessage.say(battle, "¡%s se convirtió en el centro de atención!" % actor.get_display_name())
			await _w(battle, 0.7)
			return

		MoveStruct.MoveEffect.EFFECT_HELPING_HAND:
			if target != null:
				target.set_meta("helping_hand", true)
				BattleMessage.say(battle, "¡%s está listo para ayudar!" % actor.get_display_name())
				await _w(battle, 0.7)
			return


		MoveStruct.MoveEffect.EFFECT_SPIT_UP:
			if actor.stockpile_count <= 0:
				BattleMessage.say(battle, "¡No surtirá efecto!")
				await _w(battle, 0.6)
				return
			# Daño se calcula si power>0; si entró aquí, forzar vía special
			actor.stockpile_count = 0
			BattleMessage.say(battle, "¡%s liberó la energía acumulada!" % actor.get_display_name())
			await _w(battle, 0.5)
			return

		MoveStruct.MoveEffect.EFFECT_AUTOTOMIZE:
			await BattleStatChange.apply(battle, actor, PokemonInstance.Stat.SPEED, 2)
			BattleMessage.say(battle, "¡%s se aligeró!" % actor.get_display_name())
			await _w(battle, 0.5)
			return

		MoveStruct.MoveEffect.EFFECT_ACUPRESSURE:
			var stats: Array = [
				PokemonInstance.Stat.ATTACK, PokemonInstance.Stat.DEFENSE,
				PokemonInstance.Stat.SP_ATTACK, PokemonInstance.Stat.SP_DEFENSE,
				PokemonInstance.Stat.SPEED
			]
			await BattleStatChange.apply(battle, receiver, stats[randi() % stats.size()], 2)
			return

		MoveStruct.MoveEffect.EFFECT_ATTACK_ACCURACY_UP:
			await BattleStatChange.apply(battle, actor, PokemonInstance.Stat.ATTACK, 1)
			var acc: int = actor.modify_accuracy_stage(1)
			if acc > 0:
				BattleMessage.say(battle, "¡La Precisión de %s subió!" % actor.get_display_name())
				await _w(battle, 0.5)
			return

		MoveStruct.MoveEffect.EFFECT_ATTACK_SPATK_UP:
			await BattleStatChange.apply(battle, actor, PokemonInstance.Stat.ATTACK, 1)
			await BattleStatChange.apply(battle, actor, PokemonInstance.Stat.SP_ATTACK, 1)
			return

		MoveStruct.MoveEffect.EFFECT_CAPTIVATE:
			# Baja SpA si géneros opuestos
			if target == null or actor.pokemon == null or target.pokemon == null:
				return
			var g1: PokemonData.Gender = actor.pokemon.gender
			var g2: PokemonData.Gender = target.pokemon.gender
			if g1 == PokemonData.Gender.GENDERLESS or g2 == PokemonData.Gender.GENDERLESS or g1 == g2:
				BattleMessage.say(battle, "¡No surtirá efecto!")
				await _w(battle, 0.6)
				return
			await BattleStatChange.apply(battle, target, PokemonInstance.Stat.SP_ATTACK, -2, true)
			return

		MoveStruct.MoveEffect.EFFECT_TOPSY_TURVY:
			if target == null:
				return
			target.stage_attack = -target.stage_attack
			target.stage_defense = -target.stage_defense
			target.stage_sp_attack = -target.stage_sp_attack
			target.stage_sp_defense = -target.stage_sp_defense
			target.stage_speed = -target.stage_speed
			target.stage_accuracy = -target.stage_accuracy
			target.stage_evasion = -target.stage_evasion
			BattleMessage.say(battle, "¡Se invirtieron los cambios de estadísticas!")
			await _w(battle, 0.7)
			return

		MoveStruct.MoveEffect.EFFECT_EMBARGO:
			if target == null:
				return
			target.set_meta("embargo_turns", 5)
			BattleMessage.say(battle, "¡%s no puede usar objetos!" % target.get_display_name())
			await _w(battle, 0.7)
			return

		MoveStruct.MoveEffect.EFFECT_LUCKY_CHANT:
			_side(battle, actor).lucky_chant_turns = 5
			BattleMessage.say(battle, "¡El Conjuro se alzó!")
			await _w(battle, 0.7)
			return

		MoveStruct.MoveEffect.EFFECT_IMPRISON:
			actor.set_meta("imprison", true)
			BattleMessage.say(battle, "¡%s selló los movimientos del rival!" % actor.get_display_name())
			await _w(battle, 0.7)
			return

		MoveStruct.MoveEffect.EFFECT_GRUDGE:
			actor.set_meta("grudge", true)
			BattleMessage.say(battle, "¡%s está guardando rencor!" % actor.get_display_name())
			await _w(battle, 0.7)
			return

		MoveStruct.MoveEffect.EFFECT_RECYCLE:
			if actor.pokemon == null:
				return
			var last_berry: int = actor.last_berry_id
			if last_berry != 0 and actor.pokemon.held_item == Items.ItemId.ITEM_NONE:
				actor.pokemon.held_item = last_berry as Items.ItemId
				BattleMessage.say(battle, "¡%s recuperó su objeto!" % actor.get_display_name())
			else:
				BattleMessage.say(battle, "¡Pero falló!")
			await _w(battle, 0.7)
			return

		MoveStruct.MoveEffect.EFFECT_TELEKINESIS:
			if target == null:
				return
			target.magnet_rise_turns = 3
			BattleMessage.say(battle, "¡%s fue elevado por telequinesis!" % target.get_display_name())
			await _w(battle, 0.7)
			return

		MoveStruct.MoveEffect.EFFECT_POWER_SPLIT:
			if target == null or actor.pokemon == null or target.pokemon == null:
				return
			var ua: int = actor.get_effective_stat(PokemonInstance.Stat.ATTACK)
			var ta: int = target.get_effective_stat(PokemonInstance.Stat.ATTACK)
			var us: int = actor.get_effective_stat(PokemonInstance.Stat.SP_ATTACK)
			var ts: int = target.get_effective_stat(PokemonInstance.Stat.SP_ATTACK)
			@warning_ignore("integer_division")
			var avg_a: int = int((ua + ta) / 2)
			@warning_ignore("integer_division")
			var avg_s: int = int((us + ts) / 2)
			var ou: Dictionary = actor.get_meta("split_stat_override", {}) if actor.has_meta("split_stat_override") else {}
			var ot: Dictionary = target.get_meta("split_stat_override", {}) if target.has_meta("split_stat_override") else {}
			ou[int(PokemonInstance.Stat.ATTACK)] = avg_a
			ou[int(PokemonInstance.Stat.SP_ATTACK)] = avg_s
			ot[int(PokemonInstance.Stat.ATTACK)] = avg_a
			ot[int(PokemonInstance.Stat.SP_ATTACK)] = avg_s
			actor.set_meta("split_stat_override", ou)
			target.set_meta("split_stat_override", ot)
			BattleMessage.say(battle, "¡Se promediaron Ataque y At. Esp.!")
			await _w(battle, 0.7)
			return

		MoveStruct.MoveEffect.EFFECT_GUARD_SPLIT:
			if target == null or actor.pokemon == null or target.pokemon == null:
				return
			var ud: int = actor.get_effective_stat(PokemonInstance.Stat.DEFENSE)
			var td: int = target.get_effective_stat(PokemonInstance.Stat.DEFENSE)
			var usd: int = actor.get_effective_stat(PokemonInstance.Stat.SP_DEFENSE)
			var tsd: int = target.get_effective_stat(PokemonInstance.Stat.SP_DEFENSE)
			@warning_ignore("integer_division")
			var avg_d: int = int((ud + td) / 2)
			@warning_ignore("integer_division")
			var avg_sd: int = int((usd + tsd) / 2)
			var ou2: Dictionary = actor.get_meta("split_stat_override", {}) if actor.has_meta("split_stat_override") else {}
			var ot2: Dictionary = target.get_meta("split_stat_override", {}) if target.has_meta("split_stat_override") else {}
			ou2[int(PokemonInstance.Stat.DEFENSE)] = avg_d
			ou2[int(PokemonInstance.Stat.SP_DEFENSE)] = avg_sd
			ot2[int(PokemonInstance.Stat.DEFENSE)] = avg_d
			ot2[int(PokemonInstance.Stat.SP_DEFENSE)] = avg_sd
			actor.set_meta("split_stat_override", ou2)
			target.set_meta("split_stat_override", ot2)
			BattleMessage.say(battle, "¡Se promediaron Defensa y Def. Esp.!")
			await _w(battle, 0.7)
			return

		MoveStruct.MoveEffect.EFFECT_ENTRAINMENT:
			if target == null or target.pokemon == null or actor.pokemon == null:
				return
			target.pokemon.ability_id = actor.pokemon.ability_id
			BattleMessage.say(battle, "¡%s recibió la habilidad de %s!" % [target.get_display_name(), actor.get_display_name()])
			await _w(battle, 0.7)
			return

		MoveStruct.MoveEffect.EFFECT_OVERWRITE_ABILITY, MoveStruct.MoveEffect.EFFECT_DOODLE:
			if target == null or target.pokemon == null or actor.pokemon == null:
				return
			# Simple: copia ability del target al actor (Worry Seed style often sets Insomnia - data driven)
			actor.pokemon.ability_id = target.pokemon.ability_id
			BattleMessage.say(battle, "¡La habilidad de %s cambió!" % actor.get_display_name())
			await _w(battle, 0.7)
			return

		MoveStruct.MoveEffect.EFFECT_CAMOUFLAGE:
			# Tipo según terreno
			var cam_t: int = int(PokemonData.Type.TYPE_NORMAL)
			match battle.terrain:
				BattleManager.TerrainId.TERRAIN_ELECTRIC:
					cam_t = int(PokemonData.Type.TYPE_ELECTRIC)
				BattleManager.TerrainId.TERRAIN_GRASSY:
					cam_t = int(PokemonData.Type.TYPE_GRASS)
				BattleManager.TerrainId.TERRAIN_MISTY:
					cam_t = int(PokemonData.Type.TYPE_FAIRY)
				BattleManager.TerrainId.TERRAIN_PSYCHIC:
					cam_t = int(PokemonData.Type.TYPE_PSYCHIC)
			actor.battle_type_1 = cam_t
			actor.battle_type_2 = -1
			BattleMessage.say(battle, "¡%s cambió de tipo!" % actor.get_display_name())
			await _w(battle, 0.7)
			return

		MoveStruct.MoveEffect.EFFECT_MUD_SPORT, MoveStruct.MoveEffect.EFFECT_WATER_SPORT:
			BattleMessage.say(battle, "¡La potencia de ciertos movimientos bajó!" )
			await _w(battle, 0.6)
			return

		MoveStruct.MoveEffect.EFFECT_PRESENT:
			# 40% cura 80, 30% 40 dmg, 10% 80, 20% 120 - approx
			if target == null:
				return
			var roll: int = randi_range(1, 100)
			if roll <= 40:
				if target.heal_block_turns <= 0:
					target.pokemon.apply_heal(80)
					_ehp(battle, target.is_player_side)
					BattleMessage.say(battle, "¡%s recuperó PS!" % target.get_display_name())
			else:
				var pdmg: int = 40 if roll <= 70 else (80 if roll <= 90 else 120)
				_dmg_target(battle, target, pdmg)
				_ehp(battle, target.is_player_side)
				BattleMessage.say(battle, "Hizo %d PS de daño." % pdmg)
			await _w(battle, 0.7)
			return

		MoveStruct.MoveEffect.EFFECT_CLANGOROUS_SOUL:
			if actor.get_current_hp() <= int(actor.get_max_hp() / 3):
				BattleMessage.say(battle, "¡No surtirá efecto!")
				await _w(battle, 0.6)
				return
			@warning_ignore("integer_division")
			actor.apply_damage(maxi(1, int(actor.get_max_hp() / 3)))
			_ehp(battle, actor.is_player_side)
			await BattleStatChange.apply(battle, actor, PokemonInstance.Stat.ATTACK, 1)
			await BattleStatChange.apply(battle, actor, PokemonInstance.Stat.DEFENSE, 1)
			await BattleStatChange.apply(battle, actor, PokemonInstance.Stat.SP_ATTACK, 1)
			await BattleStatChange.apply(battle, actor, PokemonInstance.Stat.SP_DEFENSE, 1)
			await BattleStatChange.apply(battle, actor, PokemonInstance.Stat.SPEED, 1)
			return

		MoveStruct.MoveEffect.EFFECT_STUFF_CHEEKS:
			if actor.pokemon == null or actor.pokemon.held_item == Items.ItemId.ITEM_NONE:
				BattleMessage.say(battle, "¡No surtirá efecto!")
				await _w(battle, 0.6)
				return
			# Consume berry (simplificado: quita item + +2 Def)
			actor.last_berry_id = int(actor.pokemon.held_item)
			actor.pokemon.held_item = Items.ItemId.ITEM_NONE
			await BattleStatChange.apply(battle, actor, PokemonInstance.Stat.DEFENSE, 2)
			return

		MoveStruct.MoveEffect.EFFECT_TAR_SHOT:
			if target == null:
				return
			await BattleStatChange.apply(battle, target, PokemonInstance.Stat.SPEED, -1, true)
			target.set_meta("tar_shot", true)
			BattleMessage.say(battle, "¡%s se volvió vulnerable al Fuego!" % target.get_display_name())
			await _w(battle, 0.6)
			return

		MoveStruct.MoveEffect.EFFECT_SPICY_EXTRACT:
			if target == null:
				return
			await BattleStatChange.apply(battle, target, PokemonInstance.Stat.ATTACK, 2, true)
			await BattleStatChange.apply(battle, target, PokemonInstance.Stat.DEFENSE, -2, true)
			return

		MoveStruct.MoveEffect.EFFECT_COACHING:
			if target == null:
				return
			await BattleStatChange.apply(battle, target, PokemonInstance.Stat.ATTACK, 1)
			await BattleStatChange.apply(battle, target, PokemonInstance.Stat.DEFENSE, 1)
			return

		MoveStruct.MoveEffect.EFFECT_AROMATIC_MIST:
			if target == null:
				return
			await BattleStatChange.apply(battle, target, PokemonInstance.Stat.SP_DEFENSE, 1)
			return

		MoveStruct.MoveEffect.EFFECT_FLOWER_SHIELD:
			for b: BattleBattler in BattleUtil.get_all_actives(battle):
				if b == null or b.pokemon == null:
					continue
				var t1: PokemonData.Type = b.pokemon.get_type_1()
				var t2: PokemonData.Type = b.pokemon.get_type_2()
				if t1 == PokemonData.Type.TYPE_GRASS or t2 == PokemonData.Type.TYPE_GRASS:
					await BattleStatChange.apply(battle, b, PokemonInstance.Stat.DEFENSE, 1)
			return

		MoveStruct.MoveEffect.EFFECT_ROTOTILLER:
			for b: BattleBattler in BattleUtil.get_all_actives(battle):
				if b == null or b.pokemon == null:
					continue
				var t1: PokemonData.Type = b.pokemon.get_type_1()
				var t2: PokemonData.Type = b.pokemon.get_type_2()
				if t1 == PokemonData.Type.TYPE_GRASS or t2 == PokemonData.Type.TYPE_GRASS:
					await BattleStatChange.apply(battle, b, PokemonInstance.Stat.ATTACK, 1)
					await BattleStatChange.apply(battle, b, PokemonInstance.Stat.SP_ATTACK, 1)
			return

		MoveStruct.MoveEffect.EFFECT_GEAR_UP, MoveStruct.MoveEffect.EFFECT_MAGNETIC_FLUX:
			# Plus/Minus allies - simplificado: sube stats al usuario y aliados
			for b: BattleBattler in BattleUtil.get_side_actives(battle, actor.is_player_side):
				if b != null and not b.is_fainted():
					if move.effect == MoveStruct.MoveEffect.EFFECT_GEAR_UP:
						await BattleStatChange.apply(battle, b, PokemonInstance.Stat.ATTACK, 1)
						await BattleStatChange.apply(battle, b, PokemonInstance.Stat.SP_ATTACK, 1)
					else:
						await BattleStatChange.apply(battle, b, PokemonInstance.Stat.DEFENSE, 1)
						await BattleStatChange.apply(battle, b, PokemonInstance.Stat.SP_DEFENSE, 1)
			return

		MoveStruct.MoveEffect.EFFECT_DRAGON_CHEER:
			if target != null:
				target.focus_energy = true
				BattleMessage.say(battle, "¡%s se animó!" % target.get_display_name())
				await _w(battle, 0.6)
			return

		MoveStruct.MoveEffect.EFFECT_ALLY_SWITCH:
			# Solo multi: intercambia slots 0 y 1
			var actives: Array[BattleBattler] = battle.player_actives if actor.is_player_side else battle.enemy_actives
			if actives.size() >= 2 and actives[0] != null and actives[1] != null:
				var tmp: BattleBattler = actives[0]
				actives[0] = actives[1]
				actives[1] = tmp
				actives[0].slot_index = 0
				actives[1].slot_index = 1
				battle._sync_primary_refs() if battle.has_method("_sync_primary_refs") else null
				BattleMessage.say(battle, "¡Los aliados intercambiaron posiciones!")
				await _w(battle, 0.7)
			else:
				BattleMessage.say(battle, "¡Pero falló!")
				await _w(battle, 0.6)
			return

		MoveStruct.MoveEffect.EFFECT_FAIRY_LOCK:
			battle.set_meta("fairy_lock_turns", 2)
			BattleMessage.say(battle, "¡Nadie puede huir!")
			await _w(battle, 0.6)
			return

		MoveStruct.MoveEffect.EFFECT_CORROSIVE_GAS:
			if target != null and target.pokemon != null and target.pokemon.held_item != Items.ItemId.ITEM_NONE:
				target.pokemon.held_item = Items.ItemId.ITEM_NONE
				BattleMessage.say(battle, "¡El gas corrosivo derritió el objeto!")
				await _w(battle, 0.6)
			return

		MoveStruct.MoveEffect.EFFECT_TEATIME:
			BattleMessage.say(battle, "¡Es la hora del té!")
			await _w(battle, 0.6)
			return

		MoveStruct.MoveEffect.EFFECT_HIT_ESCAPE:
			await _pivot_out(battle, actor)
			return



		MoveStruct.MoveEffect.EFFECT_PROTECT, MoveStruct.MoveEffect.EFFECT_MAT_BLOCK, MoveStruct.MoveEffect.EFFECT_RECHARGE:
			# Protect/Endure vía ProtectResolver; Recharge vía TwoTurnResolver
			return

		MoveStruct.MoveEffect.EFFECT_SOLAR_BEAM, MoveStruct.MoveEffect.EFFECT_SKY_DROP:
			# Carga vía TwoTurnResolver
			return

		MoveStruct.MoveEffect.EFFECT_BIDE:
			if actor.bide_turns < 0:
				actor.bide_turns = 2
				actor.bide_damage = 0
				BattleMessage.say(battle, "¡%s está contando energía!" % actor.get_display_name())
				await _w(battle, 0.7)
			else:
				var bd: int = actor.bide_damage * 2
				actor.bide_turns = -1
				actor.bide_damage = 0
				if target != null and bd > 0:
					_dmg_target(battle, target, bd)
					_ehp(battle, target.is_player_side)
					BattleMessage.say(battle, "¡%s liberó energía!" % actor.get_display_name())
					await _w(battle, 0.7)
				else:
					BattleMessage.say(battle, "¡Pero falló!")
					await _w(battle, 0.6)
			return

		MoveStruct.MoveEffect.EFFECT_FUTURE_SIGHT:
			if target == null:
				return
			if target.future_sight_turns >= 0:
				BattleMessage.say(battle, "¡Pero falló!")
				await _w(battle, 0.6)
				return
			# Daño diferido aproximado
			var fs_probe: DamageCalculator.HitResult = DamageCalculator.compute_hit(actor, target, move, _weather(battle), false, BattleUtil.is_multi_battle(battle))
			var side_fs: FieldSide = _side(battle, target)
			side_fs.set_future_sight(target.slot_index, 2, maxi(1, fs_probe.damage), actor.is_player_side)
			target.future_sight_damage = 0
			target.future_sight_turns = -1
			BattleMessage.say(battle, "¡%s previó un ataque!" % actor.get_display_name())
			await _w(battle, 0.7)
			return

		MoveStruct.MoveEffect.EFFECT_UPROAR:
			actor.uproar_turns = 3
			if actor.pokemon != null and actor.pokemon.status == PokemonInstance.Status.SLEEP:
				actor.pokemon.cure_status()
			BattleMessage.say(battle, "¡%s armó un alboroto!" % actor.get_display_name())
			await _w(battle, 0.7)
			return

		MoveStruct.MoveEffect.EFFECT_BEAK_BLAST:
			actor.beak_blast_armed = true
			BattleMessage.say(battle, "¡%s está cargando Beak Blast!" % actor.get_display_name())
			await _w(battle, 0.6)
			return

		MoveStruct.MoveEffect.EFFECT_SHELL_TRAP:
			actor.shell_trap_armed = true
			BattleMessage.say(battle, "¡%s preparó una trampa de concha!" % actor.get_display_name())
			await _w(battle, 0.6)
			return

		MoveStruct.MoveEffect.EFFECT_DARK_VOID:
			if target != null:
				await BattleStatChange.apply_status(battle, target, PokemonInstance.Status.SLEEP)
			return

		MoveStruct.MoveEffect.EFFECT_REVIVAL_BLESSING:
			BattleMessage.say(battle, "¡%s rezó por un aliado caído!" % actor.get_display_name())
			await _w(battle, 0.7)
			# UI debe elegir mon KO; aquí intentamos el primero del party
			var party: Array = battle.player_party if actor.is_player_side else battle.enemy_party
			for mon: PokemonInstance in party:
				if mon != null and mon.is_fainted():
					mon.current_hp = maxi(1, int(mon.max_hp / 2))
					BattleMessage.say(battle, "¡%s recuperó la conciencia!" % mon.get_display_name())
					await _w(battle, 0.7)
					break
			return

		MoveStruct.MoveEffect.EFFECT_PSYCHO_SHIFT:
			if actor.pokemon == null or target == null or target.pokemon == null:
				return
			if not actor.pokemon.has_status() or target.pokemon.has_status():
				BattleMessage.say(battle, "¡No surtirá efecto!")
				await _w(battle, 0.6)
				return
			var st: PokemonInstance.Status = actor.pokemon.status
			actor.pokemon.cure_status()
			await BattleStatChange.apply_status(battle, target, st)
			return

		MoveStruct.MoveEffect.EFFECT_BESTOW:
			if actor.pokemon == null or target == null or target.pokemon == null:
				return
			if actor.pokemon.held_item == Items.ItemId.ITEM_NONE or target.pokemon.held_item != Items.ItemId.ITEM_NONE:
				BattleMessage.say(battle, "¡Pero falló!")
				await _w(battle, 0.6)
				return
			target.pokemon.held_item = actor.pokemon.held_item
			actor.pokemon.held_item = Items.ItemId.ITEM_NONE
			BattleMessage.say(battle, "¡%s entregó su objeto!" % actor.get_display_name())
			await _w(battle, 0.7)
			return

		MoveStruct.MoveEffect.EFFECT_AFTER_YOU:
			if target != null:
				target.set_meta("quash_priority", 99)
				BattleMessage.say(battle, "¡%s dejará pasar a %s!" % [actor.get_display_name(), target.get_display_name()])
				await _w(battle, 0.6)
			return

		MoveStruct.MoveEffect.EFFECT_QUASH:
			if target != null:
				target.set_meta("quash_priority", -99)
				BattleMessage.say(battle, "¡%s fue aplazado!" % target.get_display_name())
				await _w(battle, 0.6)
			return

		MoveStruct.MoveEffect.EFFECT_ION_DELUGE:
			battle.set_meta("ion_deluge", true)
			BattleMessage.say(battle, "¡Una lluvia de iones electrificó el campo!")
			await _w(battle, 0.6)
			return

		MoveStruct.MoveEffect.EFFECT_ELECTRIFY:
			if target != null:
				target.set_meta("electrify", true)
				BattleMessage.say(battle, "¡Los movimientos de %s serán Eléctricos!" % target.get_display_name())
				await _w(battle, 0.6)
			return

		MoveStruct.MoveEffect.EFFECT_POWDER:
			if target != null:
				target.set_meta("powder", true)
				BattleMessage.say(battle, "¡%s fue cubierto de polvo!" % target.get_display_name())
				await _w(battle, 0.6)
			return

		MoveStruct.MoveEffect.EFFECT_MAGIC_COAT:
			actor.set_meta("magic_coat", true)
			BattleMessage.say(battle, "¡%s esperó con Capa Mágica!" % actor.get_display_name())
			await _w(battle, 0.6)
			return

		MoveStruct.MoveEffect.EFFECT_SNATCH:
			actor.set_meta("snatch", true)
			BattleMessage.say(battle, "¡%s espera para robar un efecto!" % actor.get_display_name())
			await _w(battle, 0.6)
			return

		MoveStruct.MoveEffect.EFFECT_ASSIST:
			await _metronome(battle, actor, target)  # pool del party sería ideal
			return

		MoveStruct.MoveEffect.EFFECT_NATURE_POWER:
			# Usa un move según terreno
			var np: MoveData = move
			BattleMessage.say(battle, "¡Poder Natural se convirtió en un ataque!")
			await _w(battle, 0.5)
			return

		MoveStruct.MoveEffect.EFFECT_ME_FIRST:
			await _copy_last_move(battle, actor, target, true)
			return

		MoveStruct.MoveEffect.EFFECT_INSTRUCT:
			if target == null or target.last_move_used_id < 0:
				BattleMessage.say(battle, "¡Pero falló!")
				await _w(battle, 0.6)
				return
			var im: MoveData = MoveDatabase.get_move(target.last_move_used_id as Moves.MoveId)
			if im == null:
				BattleMessage.say(battle, "¡Pero falló!")
				await _w(battle, 0.6)
				return
			var ia: BattleAction = BattleAction.make_move(target, actor, im, -1)
			ia.set_meta("_skip_pp", true)
			ia.set_meta("_multi_resolved", true)
			await BattleMoveResolution.execute_move(battle, ia)
			return

		MoveStruct.MoveEffect.EFFECT_THIRD_TYPE:
			if target == null:
				return
			# Tipo extra (simplificado: Grass como Forest's Curse default data-driven)
			target.battle_type_2 = int(PokemonData.Type.TYPE_GRASS)
			BattleMessage.say(battle, "¡%s ganó el tipo Planta!" % target.get_display_name())
			await _w(battle, 0.6)
			return

		MoveStruct.MoveEffect.EFFECT_REVELATION_DANCE:
			# Tipo = tipo primario del usuario (AbilityRuntime.effective_move_type suele cubrirlo)
			return

		MoveStruct.MoveEffect.EFFECT_HIDDEN_POWER:
			return

		MoveStruct.MoveEffect.EFFECT_CONVERSION_2:
			if target == null or target.last_move_used_id < 0:
				BattleMessage.say(battle, "¡Pero falló!")
				await _w(battle, 0.6)
				return
			var c2: MoveData = MoveDatabase.get_move(target.last_move_used_id as Moves.MoveId)
			if c2 != null:
				actor.battle_type_1 = int(c2.type)
				actor.battle_type_2 = -1
				BattleMessage.say(battle, "¡%s cambió de tipo!" % actor.get_display_name())
				await _w(battle, 0.6)
			return

		MoveStruct.MoveEffect.EFFECT_AURA_WHEEL:
			await BattleStatChange.apply(battle, actor, PokemonInstance.Stat.SPEED, 1)
			return

		MoveStruct.MoveEffect.EFFECT_EXTREME_EVOBOOST:
			await BattleStatChange.apply(battle, actor, PokemonInstance.Stat.ATTACK, 2)
			await BattleStatChange.apply(battle, actor, PokemonInstance.Stat.DEFENSE, 2)
			await BattleStatChange.apply(battle, actor, PokemonInstance.Stat.SP_ATTACK, 2)
			await BattleStatChange.apply(battle, actor, PokemonInstance.Stat.SP_DEFENSE, 2)
			await BattleStatChange.apply(battle, actor, PokemonInstance.Stat.SPEED, 2)
			return

		MoveStruct.MoveEffect.EFFECT_RAGING_BULL:
			# Rompe screens del rival
			_side(battle, target if target else battle.enemy).clear_screens()
			BattleMessage.say(battle, "¡Las barreras del rival se rompieron!")
			await _w(battle, 0.5)
			return

		MoveStruct.MoveEffect.EFFECT_PHOTON_GEYSER:
			return

		MoveStruct.MoveEffect.EFFECT_STRUGGLE:
			return

		MoveStruct.MoveEffect.EFFECT_RECOIL:
			return

		MoveStruct.MoveEffect.EFFECT_TERRAIN_BOOST:
			return

		MoveStruct.MoveEffect.EFFECT_FUSION_COMBO:
			return

		MoveStruct.MoveEffect.EFFECT_REFLECT_DAMAGE:
			# Counter/Mirror Coat style - needs last damage taken
			if actor.get_meta("last_physical_damage", 0) > 0 and target != null:
				var rd: int = int(actor.get_meta("last_physical_damage")) * 2
				_dmg_target(battle, target, rd)
				_ehp(battle, target.is_player_side)
				BattleMessage.say(battle, "¡%s devolvió el golpe!" % actor.get_display_name())
				await _w(battle, 0.7)
			else:
				BattleMessage.say(battle, "¡Pero falló!")
				await _w(battle, 0.6)
			return

		MoveStruct.MoveEffect.EFFECT_TRIPLE_KICK:
			return

		MoveStruct.MoveEffect.EFFECT_PURSUIT:
			return

		MoveStruct.MoveEffect.EFFECT_EARTHQUAKE:
			return

		MoveStruct.MoveEffect.EFFECT_BEAT_UP:
			return

		MoveStruct.MoveEffect.EFFECT_FOCUS_PUNCH:
			return

		MoveStruct.MoveEffect.EFFECT_PLEDGE:
			return

		MoveStruct.MoveEffect.EFFECT_FLING:
			if actor.pokemon == null or actor.pokemon.held_item == Items.ItemId.ITEM_NONE:
				BattleMessage.say(battle, "¡Pero falló!")
				await _w(battle, 0.6)
				return
			actor.pokemon.held_item = Items.ItemId.ITEM_NONE
			BattleMessage.say(battle, "¡%s lanzó su objeto!" % actor.get_display_name())
			await _w(battle, 0.6)
			return

		MoveStruct.MoveEffect.EFFECT_NATURAL_GIFT:
			# Tipo/potencia se resuelven en el golpe; aquí solo validar baya.
			var ng_data: ItemData = HoldItemRuntime.get_item_data(actor)
			if ng_data == null or actor.pokemon == null:
				BattleMessage.say(battle, "¡Pero falló!")
				await _w(battle, 0.6)
				return
			if not _is_berry(int(actor.pokemon.held_item)):
				BattleMessage.say(battle, "¡Pero falló!")
				await _w(battle, 0.6)
				return
			actor.set_meta("natural_gift_active", true)
			return

		MoveStruct.MoveEffect.EFFECT_ROUND:
			return

		MoveStruct.MoveEffect.EFFECT_SUCKER_PUNCH:
			return

		MoveStruct.MoveEffect.EFFECT_SUPER_EFFECTIVE_ON_ARG:
			return

		MoveStruct.MoveEffect.EFFECT_TWO_TYPED_MOVE:
			return

		MoveStruct.MoveEffect.EFFECT_CHANGE_TYPE_ON_ITEM:
			return

		MoveStruct.MoveEffect.EFFECT_SYNCHRONOISE:
			return

		MoveStruct.MoveEffect.EFFECT_FAIL_IF_NOT_ARG_TYPE:
			return

		MoveStruct.MoveEffect.EFFECT_GRASSY_GLIDE:
			return

		MoveStruct.MoveEffect.EFFECT_SNIPE_SHOT:
			return

		MoveStruct.MoveEffect.EFFECT_HYPERSPACE_FURY:
			await BattleStatChange.apply(battle, actor, PokemonInstance.Stat.DEFENSE, -1)
			return

		MoveStruct.MoveEffect.EFFECT_POPULATION_BOMB:
			return

		MoveStruct.MoveEffect.EFFECT_IVY_CUDGEL:
			return

		MoveStruct.MoveEffect.EFFECT_FICKLE_BEAM:
			return

		MoveStruct.MoveEffect.EFFECT_UPPER_HAND:
			return

		MoveStruct.MoveEffect.EFFECT_SHELL_SIDE_ARM:
			return

		MoveStruct.MoveEffect.EFFECT_SPECIES_POWER_OVERRIDE:
			return


	BattleMessage.say(battle, "¡Pero no tuvo ningún efecto todavía!")
	await _w(battle, 0.8)




## Daño al mon o a su sustituto. Devuelve daño real al cuerpo (0 si solo el sub).


# ─── helpers locales tipados ─────────────────────────────────────────

static func _w(battle: Object, seconds: float) -> void:
	if battle.has_method("_wait"):
		await battle._wait(seconds)
	else:
		await Engine.get_main_loop().create_timer(seconds).timeout


static func _side(battle: Object, battler: BattleBattler) -> FieldSide:
	if battle.has_method("_side_for"):
		return battle._side_for(battler) as FieldSide
	return battle.player_side if battler.is_player_side else battle.enemy_side


static func _pside(battle: Object) -> FieldSide:
	return battle.player_side as FieldSide


static func _eside(battle: Object) -> FieldSide:
	return battle.enemy_side as FieldSide


static func _ehp(battle: Object, is_player_side: bool) -> void:
	if battle.has_method("_emit_hp"):
		battle._emit_hp(is_player_side)


static func _ehpb(battle: Object, battler: BattleBattler) -> void:
	if battle.has_method("_emit_hp_battler"):
		battle._emit_hp_battler(battler)


static func _weather(battle: Object) -> int:
	if battle.has_method("get_effective_weather"):
		return int(battle.get_effective_weather())
	return int(battle.weather) if battle.get("battle.weather") != null else 0


static func _heal_target(battle: Object, target: BattleBattler, move: MoveData) -> void:
	if target == null or target.pokemon == null or move == null:
		return
	if target.heal_block_turns > 0:
		BattleMessage.say(battle, "¡%s no puede curarse!" % target.get_display_name())
		await _w(battle, 0.5)
		return
	var amount: int = 0
	if move.heal_percent > 0:
		amount = maxi(1, int(float(target.get_max_hp()) * float(move.heal_percent) / 100.0))
	else:
		amount = maxi(1, target.get_max_hp() / 2)
	target.pokemon.apply_heal(amount)
	_ehpb(battle, target)
	BattleMessage.say(battle, "¡%s recuperó PS!" % target.get_display_name())
	await _w(battle, 0.55)


static func _weather_from_move(battle: Object, move: MoveData) -> void:
	if move == null:
		return
	if battle.has_method("set_weather"):
		# Mapping simplificado; el manager tenía la tabla completa
		pass


static func _announce(battle: Object, battler: BattleBattler) -> void:
	if battle.has_method("ability_announce"):
		await battle.ability_announce(battler)


static func _dmg_target(battle: Object, target: BattleBattler, amount: int) -> int:
	if target == null:
		return 0
	var dealt: int = target.apply_damage(amount)
	_ehpb(battle, target)
	return dealt


static func _pivot_out(battle: Object, actor: BattleBattler, baton_pass: bool = false) -> void:
	if battle.has_method("_request_pivot_out"):
		await battle._request_pivot_out(actor, baton_pass)
		return
	# Free switch request for battle.player; AI auto for battle.enemy
	if actor.is_player_side:
		if battle.has_signal("player_must_switch"):
			battle.player_must_switch.emit()
		if battle.has_method("await_forced_player_switch"):
			await battle.await_forced_player_switch(true)
	else:
		var nuevo: PokemonInstance = BattleUtil.first_reserve(battle, false)
		if nuevo != null:
			var action: BattleAction = BattleAction.make_switch(actor, nuevo)
			await BattleSwitchIn.execute_switch_action(battle, action)


static func _force_switch(battle: Object, target: BattleBattler) -> void:
	if battle.has_method("_force_switch_out"):
		await battle._force_switch_out(target)
		return
	await _pivot_out(battle, target, false)


static func _snap_baton(actor: BattleBattler) -> Dictionary:
	var data: Dictionary = {}
	if actor == null:
		return data
	data["stages"] = actor.stat_stages.duplicate() if "stat_stages" in actor else {}
	data["confusion"] = actor.confusion_turns
	data["focus_energy"] = actor.focus_energy
	return data


static func _baton_pass(actor: BattleBattler, data: Dictionary) -> void:
	if actor == null or data.is_empty():
		return
	if data.has("stages") and "stat_stages" in actor:
		actor.stat_stages = data["stages"]
	if data.has("confusion"):
		actor.confusion_turns = int(data["confusion"])
	if data.has("focus_energy"):
		actor.focus_energy = bool(data["focus_energy"])


static func _copy_last_move(battle: Object, actor: BattleBattler, target: BattleBattler, mirror: bool) -> void:
	var last: MoveData = null
	if battle.get("last_move_used_field") != null:
		last = battle.last_move_used_field as MoveData
	if last == null:
		BattleMessage.say(battle, "¡Pero falló!")
		await _w(battle, 0.6)
		return
	BattleMessage.say(battle, "¡%s usó %s!" % [actor.get_display_name(), last.move_name])
	await _w(battle, 0.5)
	var action: BattleAction = BattleAction.make_move(actor, target, last, -1)
	action.set_meta("_skip_pp", true)
	await BattleMoveResolution.execute_move(battle, action)


static func _metronome(battle: Object, actor: BattleBattler, target: BattleBattler) -> void:
	BattleMessage.say(battle, "¡%s usó Metrónomo!" % actor.get_display_name())
	await _w(battle, 0.5)
	# Random move: simplified — caller can improve
	BattleMessage.say(battle, "¡Pero falló!")
	await _w(battle, 0.5)


static func _mimic(battle: Object, actor: BattleBattler, target: BattleBattler) -> void:
	BattleMessage.say(battle, "¡%s usó Mimético!" % actor.get_display_name())
	await _w(battle, 0.5)


static func _sketch(battle: Object, actor: BattleBattler, target: BattleBattler) -> void:
	BattleMessage.say(battle, "¡%s usó Esquema!" % actor.get_display_name())
	await _w(battle, 0.5)


static func _transform(battle: Object, actor: BattleBattler, target: BattleBattler) -> void:
	if target == null or target.pokemon == null:
		BattleMessage.say(battle, "¡Pero falló!")
		await _w(battle, 0.5)
		return
	await AbilityRuntime.apply_transform(actor, target, battle, false)
	BattleMessage.say(battle, "¡%s se transformó!" % actor.get_display_name())
	await _w(battle, 0.7)
	if battle.has_signal("battler_appearance_changed"):
		battle.battler_appearance_changed.emit(actor.is_player_side)


static func _sleep_talk(battle: Object, actor: BattleBattler, target: BattleBattler) -> void:
	BattleMessage.say(battle, "¡%s está hablando dormido!" % actor.get_display_name())
	await _w(battle, 0.5)



static func _forced_switch(battle: Object, mid: bool = false) -> void:
	if battle.has_method("await_forced_player_switch"):
		await battle.await_forced_player_switch(mid)
	elif battle.has_method("_await_forced_player_switch"):
		await battle._await_forced_player_switch(mid)


static func _is_berry(item_id: int) -> bool:
	return false
