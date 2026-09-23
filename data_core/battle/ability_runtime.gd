extends RefCounted
class_name AbilityRuntime

const WeatherId = AbilityBattleEffect.weatherAbilityID


## ─── Acceso básico ──────────────────────────────────────
static func get_id(battler: BattleBattler) -> AbilityId.Id:
	if battler == null or battler.pokemon == null:
		return AbilityId.Id.NONE
	if not battler.ability_active:
		return AbilityId.Id.NONE
	return battler.pokemon.ability_id


static func has(battler: BattleBattler, id: AbilityId.Id) -> bool:
	return get_id(battler) == id


static func ability_name(battler: BattleBattler) -> String:
	var id: AbilityId.Id = get_id(battler)
	if id == AbilityId.Id.NONE:
		return ""
	if AbilityDatabase != null and AbilityDatabase.has_ability(id):
		return AbilityDatabase.get_ability_name(id)
	return ""


## ─── Inmunidades de tipo por habilidad ───────────────────
static func type_immunity_reaction(defender: BattleBattler, move: MoveData) -> String:
	if move == null or move.category == MoveStruct.DamageCategory.STATUS:
		return ""

	match get_id(defender):
		AbilityId.Id.LEVITATE:
			if move.type == PokemonData.Type.TYPE_GROUND and not move.damages_airborne:
				return "immune"
		AbilityId.Id.VOLT_ABSORB:
			if move.type == PokemonData.Type.TYPE_ELECTRIC:
				return "heal"
		AbilityId.Id.WATER_ABSORB, AbilityId.Id.DRY_SKIN:
			if move.type == PokemonData.Type.TYPE_WATER:
				return "heal"
		AbilityId.Id.STORM_DRAIN:
			if move.type == PokemonData.Type.TYPE_WATER:
				return "spatk_up"
		AbilityId.Id.LIGHTNING_ROD:
			if move.type == PokemonData.Type.TYPE_ELECTRIC:
				return "spatk_up"
		AbilityId.Id.MOTOR_DRIVE:
			if move.type == PokemonData.Type.TYPE_ELECTRIC:
				return "spe_up"
		AbilityId.Id.SAP_SIPPER:
			if move.type == PokemonData.Type.TYPE_GRASS:
				return "atk_up"
		AbilityId.Id.FLASH_FIRE:
			if move.type == PokemonData.Type.TYPE_FIRE:
				return "flash_fire"
		AbilityId.Id.WELL_BAKED_BODY:
			if move.type == PokemonData.Type.TYPE_FIRE:
				return "def_up"
		AbilityId.Id.EARTH_EATER:
			if move.type == PokemonData.Type.TYPE_GROUND:
				return "heal"
		AbilityId.Id.SOUNDPROOF:
			if move.sound_move:
				return "immune"
		AbilityId.Id.BULLETPROOF:
			if move.ballistic_move:
				return "immune"
		AbilityId.Id.WIND_RIDER:
			if move.wind_move:
				return "atk_up"
	return ""


static func blocks_unless_super_effective(defender: BattleBattler) -> bool:
	return has(defender, AbilityId.Id.WONDER_GUARD)


## ─── Multiplicadores de daño ────────────────────────────
static func attack_stat_multiplier(attacker: BattleBattler, category: MoveStruct.DamageCategory) -> float:
	if attacker == null or attacker.pokemon == null:
		return 1.0
	var id: AbilityId.Id = get_id(attacker)
	var hp_ratio: float = 1.0
	if attacker.pokemon.max_hp > 0:
		hp_ratio = float(attacker.pokemon.current_hp) / float(attacker.pokemon.max_hp)
	if id == AbilityId.Id.DEFEATIST and hp_ratio <= 0.5:
		return 0.5
	if category == MoveStruct.DamageCategory.PHYSICAL:
		match id:
			AbilityId.Id.HUGE_POWER, AbilityId.Id.PURE_POWER:
				return 2.0
			AbilityId.Id.HUSTLE, AbilityId.Id.GORILLA_TACTICS:
				return 1.5
			AbilityId.Id.GUTS:
				if attacker.pokemon.has_status():
					return 1.5
			AbilityId.Id.TOXIC_BOOST:
				if attacker.pokemon.status == PokemonInstance.Status.POISON \
						or attacker.pokemon.status == PokemonInstance.Status.TOXIC:
					return 1.5
	else:
		match id:
			AbilityId.Id.FLARE_BOOST:
				if attacker.pokemon.status == PokemonInstance.Status.BURN:
					return 1.5
			AbilityId.Id.SOLAR_POWER:
				return 1.0  # el sol se aplica en power_multiplier / manager
	return 1.0


static func power_multiplier(attacker: BattleBattler, move: MoveData) -> float:
	if move == null or attacker == null or attacker.pokemon == null:
		return 1.0

	var id: AbilityId.Id = get_id(attacker)
	var mult: float = 1.0

	if id == AbilityId.Id.FLASH_FIRE and attacker.flash_fire_boosted \
			and move.type == PokemonData.Type.TYPE_FIRE:
		mult *= 1.5

	var low_hp: bool = attacker.pokemon.max_hp > 0 \
		and float(attacker.pokemon.current_hp) / float(attacker.pokemon.max_hp) <= 1.0 / 3.0
	if low_hp:
		match id:
			AbilityId.Id.BLAZE:
				if move.type == PokemonData.Type.TYPE_FIRE:
					mult *= 1.5
			AbilityId.Id.TORRENT:
				if move.type == PokemonData.Type.TYPE_WATER:
					mult *= 1.5
			AbilityId.Id.OVERGROW:
				if move.type == PokemonData.Type.TYPE_GRASS:
					mult *= 1.5
			AbilityId.Id.SWARM:
				if move.type == PokemonData.Type.TYPE_BUG:
					mult *= 1.5

	match id:
		AbilityId.Id.IRON_FIST:
			if move.punching_move:
				mult *= 1.2
		AbilityId.Id.STRONG_JAW:
			if move.biting_move:
				mult *= 1.5
		AbilityId.Id.MEGA_LAUNCHER:
			if move.pulse_move:
				mult *= 1.5
		AbilityId.Id.SHARPNESS:
			if move.slicing_move:
				mult *= 1.5
		AbilityId.Id.TOUGH_CLAWS:
			if move.makes_contact:
				mult *= 1.3
		AbilityId.Id.RECKLESS:
			if move.recoil_percent > 0:
				mult *= 1.2
		AbilityId.Id.STEELWORKER, AbilityId.Id.STEELY_SPIRIT:
			if move.type == PokemonData.Type.TYPE_STEEL:
				mult *= 1.5
		AbilityId.Id.ROCKY_PAYLOAD:
			if move.type == PokemonData.Type.TYPE_ROCK:
				mult *= 1.5
		AbilityId.Id.DRAGONS_MAW:
			if move.type == PokemonData.Type.TYPE_DRAGON:
				mult *= 1.5
		AbilityId.Id.TRANSISTOR:
			if move.type == PokemonData.Type.TYPE_ELECTRIC:
				mult *= 1.3
		AbilityId.Id.PUNK_ROCK:
			if move.sound_move:
				mult *= 1.3
		AbilityId.Id.WATER_BUBBLE:
			if move.type == PokemonData.Type.TYPE_WATER:
				mult *= 2.0
		AbilityId.Id.SHEER_FORCE:
			if move.secondary_effect != MoveStruct.SecondaryEffect.MOVE_EFFECT_NONE \
					or move.secondary_chance > 0:
				mult *= 1.3
	if attacker.charged:
		mult *= 2.0
	return mult


static func damage_taken_multiplier(defender: BattleBattler, move: MoveData, effectiveness: float) -> float:
	if move == null:
		return 1.0
	var mult: float = 1.0
	match get_id(defender):
		AbilityId.Id.THICK_FAT:
			if move.type == PokemonData.Type.TYPE_FIRE or move.type == PokemonData.Type.TYPE_ICE:
				mult *= 0.5
		AbilityId.Id.SOLID_ROCK, AbilityId.Id.FILTER, AbilityId.Id.PRISM_ARMOR:
			if effectiveness > 1.0:
				mult *= 0.75
		AbilityId.Id.MULTISCALE, AbilityId.Id.SHADOW_SHIELD:
			if defender.pokemon != null and defender.pokemon.current_hp == defender.pokemon.max_hp:
				mult *= 0.5
		AbilityId.Id.HEATPROOF:
			if move.type == PokemonData.Type.TYPE_FIRE:
				mult *= 0.5
		AbilityId.Id.FUR_COAT:
			if move.category == MoveStruct.DamageCategory.PHYSICAL:
				mult *= 0.5
		AbilityId.Id.FLUFFY:
			if move.makes_contact:
				mult *= 0.5
			if move.type == PokemonData.Type.TYPE_FIRE:
				mult *= 2.0
		AbilityId.Id.ICE_SCALES:
			if move.category == MoveStruct.DamageCategory.SPECIAL:
				mult *= 0.5
		AbilityId.Id.WATER_BUBBLE:
			if move.type == PokemonData.Type.TYPE_FIRE:
				mult *= 0.5
		AbilityId.Id.PUNK_ROCK:
			if move.sound_move:
				mult *= 0.5
	return mult


## ─── Sturdy ─────────────────────────────────────────────
static func should_survive_with_sturdy(defender: BattleBattler, incoming_damage: int) -> bool:
	if not has(defender, AbilityId.Id.STURDY):
		return false
	if defender.pokemon == null:
		return false
	return defender.pokemon.current_hp == defender.pokemon.max_hp \
		and incoming_damage >= defender.pokemon.current_hp


## ─── Inmunidades a estados / confusión / retroceso ──────
static func blocks_status(battler: BattleBattler, status: PokemonInstance.Status, weather: int = -1) -> bool:
	var id: AbilityId.Id = get_id(battler)
	if id == AbilityId.Id.COMATOSE or id == AbilityId.Id.PURIFYING_SALT:
		return true
	if id == AbilityId.Id.LEAF_GUARD and weather == WeatherId.WEATHER_DROUGHT:
		return true
	if id == AbilityId.Id.SWEET_VEIL and status == PokemonInstance.Status.SLEEP:
		return true
	if id == AbilityId.Id.PASTEL_VEIL and (status == PokemonInstance.Status.POISON or status == PokemonInstance.Status.TOXIC):
		return true
	match status:
		PokemonInstance.Status.SLEEP:
			return id == AbilityId.Id.INSOMNIA or id == AbilityId.Id.VITAL_SPIRIT
		PokemonInstance.Status.POISON, PokemonInstance.Status.TOXIC:
			return id == AbilityId.Id.IMMUNITY or id == AbilityId.Id.PASTEL_VEIL
		PokemonInstance.Status.BURN:
			return id == AbilityId.Id.WATER_VEIL or id == AbilityId.Id.WATER_BUBBLE or id == AbilityId.Id.THERMAL_EXCHANGE
		PokemonInstance.Status.PARALYSIS:
			return id == AbilityId.Id.LIMBER
		PokemonInstance.Status.FREEZE:
			return id == AbilityId.Id.MAGMA_ARMOR
	return false


static func blocks_confusion(battler: BattleBattler) -> bool:
	return has(battler, AbilityId.Id.OWN_TEMPO)


static func blocks_flinch(battler: BattleBattler) -> bool:
	return has(battler, AbilityId.Id.INNER_FOCUS)


static func blocks_critical(defender: BattleBattler) -> bool:
	var id: AbilityId.Id = get_id(defender)
	return id == AbilityId.Id.BATTLE_ARMOR or id == AbilityId.Id.SHELL_ARMOR


static func blocks_recoil(battler: BattleBattler) -> bool:
	return has(battler, AbilityId.Id.ROCK_HEAD)


static func victory_star_active(battler: BattleBattler) -> bool:
	return has(battler, AbilityId.Id.VICTORY_STAR)


static func prevents_escape(blocker: BattleBattler, runner: BattleBattler) -> bool:
	if blocker == null or runner == null or blocker.is_fainted() or runner.is_fainted():
		return false
	if has(runner, AbilityId.Id.RUN_AWAY):
		return false
	var rt1: PokemonData.Type = runner.get_battle_type_1()
	var rt2: PokemonData.Type = runner.get_battle_type_2()
	var ghost: bool = rt1 == PokemonData.Type.TYPE_GHOST or rt2 == PokemonData.Type.TYPE_GHOST
	if ghost:
		return false
	match get_id(blocker):
		AbilityId.Id.SHADOW_TAG:
			return not has(runner, AbilityId.Id.SHADOW_TAG)
		AbilityId.Id.ARENA_TRAP:
			var flying: bool = rt1 == PokemonData.Type.TYPE_FLYING or rt2 == PokemonData.Type.TYPE_FLYING
			return not flying and not has(runner, AbilityId.Id.LEVITATE)
		AbilityId.Id.MAGNET_PULL:
			return rt1 == PokemonData.Type.TYPE_STEEL or rt2 == PokemonData.Type.TYPE_STEEL
	return false


static func should_skip_turn(battler: BattleBattler) -> bool:
	if battler == null or not has(battler, AbilityId.Id.TRUANT):
		return false
	var skip: bool = battler.truant_skip_turn
	battler.truant_skip_turn = not skip
	return skip


## ─── Entrada en combate ─────────────────────────────────
static func on_switch_in(battler: BattleBattler, opponent: BattleBattler, battle: BattleManager) -> void:
	if battler == null or battler.pokemon == null or battle == null:
		return

	match get_id(battler):
		AbilityId.Id.INTIMIDATE:
			if opponent != null and not opponent.is_fainted():
				if _blocks_intimidate(opponent):
					if has(opponent, AbilityId.Id.GUARD_DOG):
						await battle.ability_announce(opponent)
						await battle.ability_change_stat(opponent, PokemonInstance.Stat.ATTACK, 1)
					else:
						await battle.ability_announce(opponent)
						battle.message.emit("¡%s no se intimidó!" % opponent.get_display_name())
						await battle._wait(0.5)
				else:
					await battle.ability_announce(battler)
					await battle.ability_change_stat(opponent, PokemonInstance.Stat.ATTACK, -1, true)

		AbilityId.Id.DRIZZLE:
			await battle.ability_announce(battler)
			battle.set_weather(WeatherId.WEATHER_RAIN, -1)

		AbilityId.Id.DROUGHT:
			await battle.ability_announce(battler)
			battle.set_weather(WeatherId.WEATHER_DROUGHT, -1)

		AbilityId.Id.SAND_STREAM:
			await battle.ability_announce(battler)
			battle.set_weather(WeatherId.WEATHER_SANDSTORM, -1)

		AbilityId.Id.SNOW_WARNING:
			await battle.ability_announce(battler)
			battle.set_weather(WeatherId.WEATHER_SNOW, -1)

		AbilityId.Id.PRESSURE:
			await battle.ability_announce(battler)

		AbilityId.Id.UNNERVE:
			await battle.ability_announce(battler)

		AbilityId.Id.DOWNLOAD:
			if opponent != null and not opponent.is_fainted():
				await battle.ability_announce(battler)
				var def_s: int = opponent.get_effective_stat(PokemonInstance.Stat.DEFENSE)
				var spd_s: int = opponent.get_effective_stat(PokemonInstance.Stat.SP_DEFENSE)
				if def_s < spd_s:
					await battle.ability_change_stat(battler, PokemonInstance.Stat.ATTACK, 1)
				else:
					await battle.ability_change_stat(battler, PokemonInstance.Stat.SP_ATTACK, 1)

		AbilityId.Id.INTREPID_SWORD:
			await battle.ability_announce(battler)
			await battle.ability_change_stat(battler, PokemonInstance.Stat.ATTACK, 1)

		AbilityId.Id.DAUNTLESS_SHIELD:
			await battle.ability_announce(battler)
			await battle.ability_change_stat(battler, PokemonInstance.Stat.DEFENSE, 1)

		AbilityId.Id.AIR_LOCK, AbilityId.Id.CLOUD_NINE:
			await battle.ability_announce(battler)

		AbilityId.Id.ELECTRIC_SURGE:
			await battle.ability_announce(battler)
			battle.set_terrain(BattleManager.TerrainId.TERRAIN_ELECTRIC, 5)

		AbilityId.Id.GRASSY_SURGE:
			await battle.ability_announce(battler)
			battle.set_terrain(BattleManager.TerrainId.TERRAIN_GRASSY, 5)

		AbilityId.Id.MISTY_SURGE:
			await battle.ability_announce(battler)
			battle.set_terrain(BattleManager.TerrainId.TERRAIN_MISTY, 5)

		AbilityId.Id.PSYCHIC_SURGE:
			await battle.ability_announce(battler)
			battle.set_terrain(BattleManager.TerrainId.TERRAIN_PSYCHIC, 5)

		AbilityId.Id.PRIMORDIAL_SEA:
			await battle.ability_announce(battler)
			battle.set_weather(
				AbilityBattleEffect.weatherAbilityID.WEATHER_RAIN, -1, true
			)

		AbilityId.Id.DESOLATE_LAND:
			await battle.ability_announce(battler)
			battle.set_weather(
				AbilityBattleEffect.weatherAbilityID.WEATHER_DROUGHT, -1, true
			)

		AbilityId.Id.DELTA_STREAM:
			await battle.ability_announce(battler)
			# Primigenio sin tipo de clima propio aún; no pisa con climas normales
			battle.weather_primal = true
			battle.message.emit("¡Corrientes de aire misteriosas protegen a los tipo Volador!")
			await battle._wait(0.6)
			battle.weather_changed.emit(battle.weather, true)

		AbilityId.Id.TRACE:
			if opponent != null and not opponent.is_fainted() and opponent.pokemon != null:
				var opp_id: AbilityId.Id = opponent.pokemon.ability_id
				if _is_traceable(opp_id):
					await battle.ability_announce(battler)
					battler.pokemon.ability_id = opp_id
					await on_switch_in(battler, opponent, battle)

		AbilityId.Id.FRISK:
			if opponent != null and not opponent.is_fainted() and opponent.pokemon != null:
				if opponent.pokemon.held_item != Items.ItemId.ITEM_NONE:
					await battle.ability_announce(battler)
					var item_name: String = "objeto"
					var idata: ItemData = ItemDatabase.get_item(opponent.pokemon.held_item)
					if idata != null and not idata.item_name.is_empty():
						item_name = idata.item_name
					battle.message.emit("%s friskó el %s de %s." % [
						battler.get_display_name(), item_name, opponent.get_display_name()
					])
					await battle._wait(0.8)

		AbilityId.Id.ANTICIPATION:
			if opponent != null and opponent.pokemon != null:
				var found: bool = false
				var t1: PokemonData.Type = battler.pokemon.get_type_1()
				var t2: PokemonData.Type = battler.pokemon.get_type_2()
				for slot: PokemonMoveSlot in opponent.pokemon.moves:
					if slot == null or slot.is_empty():
						continue
					var md: MoveData = MoveDatabase.get_move(slot.move_id)
					if md == null or md.power <= 0:
						continue
					var eff: float = TypeChart.get_effectiveness(md.type, t1, t2)
					if eff > 1.0:
						found = true
						break
				if found:
					await battle.ability_announce(battler)
					battle.message.emit("¡%s se estremeció!" % battler.get_display_name())
					await battle._wait(0.6)

		AbilityId.Id.FOREWARN:
			if opponent != null and opponent.pokemon != null:
				var best: MoveData = null
				var best_pow: int = -1
				for slot: PokemonMoveSlot in opponent.pokemon.moves:
					if slot == null or slot.is_empty():
						continue
					var md: MoveData = MoveDatabase.get_move(slot.move_id)
					if md == null:
						continue
					var p: int = md.power
					if p > best_pow:
						best_pow = p
						best = md
				if best != null:
					await battle.ability_announce(battler)
					battle.message.emit("¡%s advirtió el movimiento %s!" % [
						battler.get_display_name(), best.move_name
					])
					await battle._wait(0.8)

		AbilityId.Id.SLOW_START:
			await battle.ability_announce(battler)
			battler.slow_start_turns = 5

		AbilityId.Id.ILLUSION:
			if not battler.illusion_active:
				if prepare_illusion(battler, battle):
					battle.battler_appearance_changed.emit(battler.is_player_side)

		AbilityId.Id.IMPOSTER:
			if opponent != null and not opponent.is_fainted():
				await _setup_imposter(battler, opponent, battle)

		AbilityId.Id.SCREEN_CLEANER:
			await battle.ability_announce(battler)
			battle.player_side.clear_screens()
			battle.enemy_side.clear_screens()
			battle.message.emit("¡Las pantallas desaparecieron!")
			await battle._wait(0.5)

		AbilityId.Id.HADRON_ENGINE:
			await battle.ability_announce(battler)
			battle.set_terrain(BattleManager.TerrainId.TERRAIN_ELECTRIC, 5)

		AbilityId.Id.ORICHALCUM_PULSE:
			await battle.ability_announce(battler)
			battle.set_weather(WeatherId.WEATHER_DROUGHT, 5)

		AbilityId.Id.SUPERSWEET_SYRUP:
			if opponent != null and not opponent.is_fainted():
				await battle.ability_announce(battler)
				var dropped: int = opponent.modify_evasion_stage(-1)
				if dropped != 0:
					battle.message.emit("¡La evasión de %s bajó!" % opponent.get_display_name())
					await battle._wait(0.6)

		AbilityId.Id.EMBODY_ASPECT_TEAL_MASK:
			await battle.ability_announce(battler)
			await battle.ability_change_stat(battler, PokemonInstance.Stat.SPEED, 1)

		AbilityId.Id.EMBODY_ASPECT_WELLSPRING_MASK:
			await battle.ability_announce(battler)
			await battle.ability_change_stat(battler, PokemonInstance.Stat.SP_DEFENSE, 1)

		AbilityId.Id.EMBODY_ASPECT_HEARTHFLAME_MASK:
			await battle.ability_announce(battler)
			await battle.ability_change_stat(battler, PokemonInstance.Stat.ATTACK, 1)

		AbilityId.Id.EMBODY_ASPECT_CORNERSTONE_MASK:
			await battle.ability_announce(battler)
			await battle.ability_change_stat(battler, PokemonInstance.Stat.DEFENSE, 1)

		AbilityId.Id.MIMICRY:
			await _apply_mimicry(battler, battle)


## ─── Contacto ───────────────────────────────────────────
static func on_contact_hit(
	attacker: BattleBattler,
	defender: BattleBattler,
	move: MoveData,
	battle: BattleManager
) -> void:
	if move == null or not move.makes_contact:
		return
	if attacker == null or attacker.is_fainted() or defender == null:
		return

	match get_id(defender):
		AbilityId.Id.STATIC:
			if randf() < 0.3:
				await battle.ability_announce(defender)
				await battle.ability_apply_status(attacker, PokemonInstance.Status.PARALYSIS, defender)

		AbilityId.Id.POISON_POINT:
			if randf() < 0.3:
				await battle.ability_announce(defender)
				await battle.ability_apply_status(attacker, PokemonInstance.Status.POISON, defender)

		AbilityId.Id.FLAME_BODY:
			if randf() < 0.3:
				await battle.ability_announce(defender)
				await battle.ability_apply_status(attacker, PokemonInstance.Status.BURN, defender)

		AbilityId.Id.ROUGH_SKIN, AbilityId.Id.IRON_BARBS:
			await battle.ability_announce(defender)
			@warning_ignore("integer_division")
			var dmg: int = maxi(1, attacker.get_max_hp() / 8)
			await battle.ability_deal_damage(attacker, dmg, defender)

		AbilityId.Id.EFFECT_SPORE:
			if randf() < 0.3:
				await battle.ability_announce(defender)
				var statuses: Array[PokemonInstance.Status] = [
					PokemonInstance.Status.SLEEP,
					PokemonInstance.Status.POISON,
					PokemonInstance.Status.PARALYSIS,
				]
				var picked: PokemonInstance.Status = statuses[randi() % statuses.size()]
				await battle.ability_apply_status(attacker, picked, defender)

		AbilityId.Id.GOOEY, AbilityId.Id.TANGLING_HAIR:
			await battle.ability_announce(defender)
			await battle.ability_change_stat(attacker, PokemonInstance.Stat.SPEED, -1, true)

		AbilityId.Id.MUMMY, AbilityId.Id.LINGERING_AROMA:
			var atk_id: AbilityId.Id = get_id(attacker)
			if atk_id != AbilityId.Id.NONE and atk_id != AbilityId.Id.MUMMY \
					and atk_id != AbilityId.Id.LINGERING_AROMA and _is_traceable(atk_id):
				await battle.ability_announce(defender)
				attacker.pokemon.ability_id = get_id(defender)
				battle.message.emit("¡La habilidad de %s cambió!" % attacker.get_display_name())
				await battle._wait(0.6)

		AbilityId.Id.WANDERING_SPIRIT:
			var atk_id2: AbilityId.Id = get_id(attacker)
			if atk_id2 != AbilityId.Id.NONE and _is_traceable(atk_id2) \
					and atk_id2 != AbilityId.Id.WANDERING_SPIRIT:
				await battle.ability_announce(defender)
				var def_id: AbilityId.Id = AbilityId.Id.WANDERING_SPIRIT
				attacker.pokemon.ability_id = def_id
				defender.pokemon.ability_id = atk_id2
				battle.message.emit("¡%s intercambió su habilidad!" % defender.get_display_name())
				await battle._wait(0.6)

	match get_id(attacker):
		AbilityId.Id.POISON_TOUCH:
			if randf() < 0.3:
				await battle.ability_announce(attacker)
				await battle.ability_apply_status(defender, PokemonInstance.Status.POISON, attacker)
		AbilityId.Id.TOXIC_CHAIN:
			if randf() < 0.3:
				await battle.ability_announce(attacker)
				await battle.ability_apply_status(defender, PokemonInstance.Status.TOXIC, attacker)
		AbilityId.Id.STENCH:
			if randf() < 0.1 and not blocks_flinch(defender):
				await battle.ability_announce(attacker)
				defender.flinched = true
				await on_flinched(defender, battle)

	if not attacker.is_fainted() and has(defender, AbilityId.Id.PICKPOCKET):
		if defender.pokemon.held_item == Items.ItemId.ITEM_NONE \
				and attacker.pokemon.held_item != Items.ItemId.ITEM_NONE:
			if not has(attacker, AbilityId.Id.STICKY_HOLD):
				await battle.ability_announce(defender)
				defender.pokemon.held_item = attacker.pokemon.held_item
				attacker.pokemon.held_item = Items.ItemId.ITEM_NONE
				battle.message.emit("¡%s robó el objeto!" % defender.get_display_name())
				await battle._wait(0.5)


## ─── Fin de turno ───────────────────────────────────────
static func end_of_turn(battler: BattleBattler, weather: int, battle: BattleManager) -> void:
	if battler == null or battler.is_fainted():
		return

	# Contador Slow Start (aunque la habilidad siga activa)
	if battler.slow_start_turns > 0:
		battler.slow_start_turns -= 1
		if battler.slow_start_turns == 0 and has(battler, AbilityId.Id.SLOW_START):
			await battle.ability_announce(battler)
			battle.message.emit("¡%s recuperó su fuerza!" % battler.get_display_name())
			await battle._wait(0.5)

	match get_id(battler):
		AbilityId.Id.SPEED_BOOST:
			await battle.ability_announce(battler)
			await battle.ability_change_stat(battler, PokemonInstance.Stat.SPEED, 1)

		AbilityId.Id.SHED_SKIN:
			if battler.pokemon.has_status() and randf() < 0.3:
				await battle.ability_announce(battler)
				await battle.ability_cure_status(battler)

		AbilityId.Id.RAIN_DISH:
			if weather == WeatherId.WEATHER_RAIN:
				await battle.ability_announce(battler)
				@warning_ignore("integer_division")
				var heal_amt: int = maxi(1, battler.get_max_hp() / 16)
				await battle.ability_heal(battler, heal_amt)

		AbilityId.Id.ICE_BODY:
			if weather == WeatherId.WEATHER_SNOW:
				await battle.ability_announce(battler)
				@warning_ignore("integer_division")
				var heal_amt2: int = maxi(1, battler.get_max_hp() / 16)
				await battle.ability_heal(battler, heal_amt2)

		AbilityId.Id.HYDRATION:
			if weather == WeatherId.WEATHER_RAIN and battler.pokemon.has_status():
				await battle.ability_announce(battler)
				await battle.ability_cure_status(battler)

		AbilityId.Id.MOODY:
			await battle.ability_announce(battler)
			var stats: Array[PokemonInstance.Stat] = [
				PokemonInstance.Stat.ATTACK, PokemonInstance.Stat.DEFENSE,
				PokemonInstance.Stat.SP_ATTACK, PokemonInstance.Stat.SP_DEFENSE,
				PokemonInstance.Stat.SPEED
			]
			var up: PokemonInstance.Stat = stats[randi() % stats.size()]
			var down: PokemonInstance.Stat = stats[randi() % stats.size()]
			while down == up:
				down = stats[randi() % stats.size()]
			await battle.ability_change_stat(battler, up, 2)
			await battle.ability_change_stat(battler, down, -1)

		AbilityId.Id.SOLAR_POWER:
			if weather == WeatherId.WEATHER_DROUGHT and not blocks_indirect_damage(battler):
				await battle.ability_announce(battler)
				@warning_ignore("integer_division")
				await battle.ability_deal_damage(battler, maxi(1, battler.get_max_hp() / 8), battler)

		AbilityId.Id.DRY_SKIN:
			if weather == WeatherId.WEATHER_RAIN:
				await battle.ability_announce(battler)
				@warning_ignore("integer_division")
				await battle.ability_heal(battler, maxi(1, battler.get_max_hp() / 8))
			elif weather == WeatherId.WEATHER_DROUGHT and not blocks_indirect_damage(battler):
				await battle.ability_announce(battler)
				@warning_ignore("integer_division")
				await battle.ability_deal_damage(battler, maxi(1, battler.get_max_hp() / 8), battler)

		AbilityId.Id.BAD_DREAMS:
			var foe: BattleBattler = battle.enemy if battler.is_player_side else battle.player
			if foe != null and not foe.is_fainted() and foe.pokemon != null \
					and foe.pokemon.status == PokemonInstance.Status.SLEEP \
					and not blocks_indirect_damage(foe):
				await battle.ability_announce(battler)
				@warning_ignore("integer_division")
				await battle.ability_deal_damage(foe, maxi(1, foe.get_max_hp() / 8), battler)


static func is_immune_to_weather_damage(battler: BattleBattler, weather: int) -> bool:
	if battler == null or battler.pokemon == null:
		return true

	var t1: PokemonData.Type = battler.pokemon.get_type_1()
	var t2: PokemonData.Type = battler.pokemon.get_type_2()
	var id: AbilityId.Id = get_id(battler)

	match weather:
		WeatherId.WEATHER_SANDSTORM:
			if t1 == PokemonData.Type.TYPE_ROCK or t2 == PokemonData.Type.TYPE_ROCK:
				return true
			if t1 == PokemonData.Type.TYPE_GROUND or t2 == PokemonData.Type.TYPE_GROUND:
				return true
			if t1 == PokemonData.Type.TYPE_STEEL or t2 == PokemonData.Type.TYPE_STEEL:
				return true
			if id == AbilityId.Id.SAND_VEIL or id == AbilityId.Id.SAND_RUSH \
					or id == AbilityId.Id.SAND_FORCE or id == AbilityId.Id.OVERCOAT:
				return true
			return false
		WeatherId.WEATHER_SNOW:
			if t1 == PokemonData.Type.TYPE_ICE or t2 == PokemonData.Type.TYPE_ICE:
				return true
			if id == AbilityId.Id.SNOW_CLOAK or id == AbilityId.Id.OVERCOAT:
				return true
			return false
		_:
			return true


## ─── Bloqueo de bajadas de stat del rival ───────────────
static func blocks_foe_stat_drop(battler: BattleBattler, stat: PokemonInstance.Stat) -> bool:
	var id: AbilityId.Id = get_id(battler)
	if id == AbilityId.Id.CLEAR_BODY or id == AbilityId.Id.WHITE_SMOKE or id == AbilityId.Id.FULL_METAL_BODY:
		return true
	if id == AbilityId.Id.HYPER_CUTTER and stat == PokemonInstance.Stat.ATTACK:
		return true
	if id == AbilityId.Id.BIG_PECKS and stat == PokemonInstance.Stat.DEFENSE:
		return true
	if id == AbilityId.Id.FLOWER_VEIL:
		var t1: PokemonData.Type = battler.get_battle_type_1()
		var t2: PokemonData.Type = battler.get_battle_type_2()
		if t1 == PokemonData.Type.TYPE_GRASS or t2 == PokemonData.Type.TYPE_GRASS:
			return true
	return false


static func blocks_foe_accuracy_drop(battler: BattleBattler) -> bool:
	var id: AbilityId.Id = get_id(battler)
	return id == AbilityId.Id.CLEAR_BODY or id == AbilityId.Id.WHITE_SMOKE \
		or id == AbilityId.Id.FULL_METAL_BODY or id == AbilityId.Id.KEEN_EYE


static func adjust_own_stage_change(battler: BattleBattler, amount: int) -> int:
	match get_id(battler):
		AbilityId.Id.SIMPLE:
			return amount * 2
		AbilityId.Id.CONTRARY:
			return -amount
	return amount


## ─── Multiplicadores ofensivos ──────────────────────────
static func technician_multiplier(attacker: BattleBattler, move: MoveData) -> float:
	if move != null and has(attacker, AbilityId.Id.TECHNICIAN) and move.power > 0 and move.power <= 60:
		return 1.5
	return 1.0


static func stab_multiplier(attacker: BattleBattler) -> float:
	return 2.0 if has(attacker, AbilityId.Id.ADAPTABILITY) else 1.5


static func always_max_hits(attacker: BattleBattler) -> bool:
	return has(attacker, AbilityId.Id.SKILL_LINK)


static func attacker_damage_multiplier(attacker: BattleBattler, effectiveness: float, _is_critical: bool) -> float:
	var mult: float = 1.0
	if has(attacker, AbilityId.Id.TINTED_LENS) and effectiveness > 0.0 and effectiveness < 1.0:
		mult *= 2.0
	if has(attacker, AbilityId.Id.NEUROFORCE) and effectiveness > 1.0:
		mult *= 1.25
	return mult


static func crit_damage_multiplier(attacker: BattleBattler) -> float:
	return 2.25 if has(attacker, AbilityId.Id.SNIPER) else 1.5


static func rivalry_multiplier(attacker: BattleBattler, defender: BattleBattler) -> float:
	if not has(attacker, AbilityId.Id.RIVALRY):
		return 1.0
	var a: PokemonData.Gender = attacker.pokemon.gender
	var d: PokemonData.Gender = defender.pokemon.gender
	if a == PokemonData.Gender.GENDERLESS or d == PokemonData.Gender.GENDERLESS:
		return 1.0
	return 1.25 if a == d else 0.75


static func ignores_defender_ability(attacker: BattleBattler) -> bool:
	var id: AbilityId.Id = get_id(attacker)
	return id == AbilityId.Id.MOLD_BREAKER or id == AbilityId.Id.TERAVOLT or id == AbilityId.Id.TURBOBLAZE


static func bypasses_ghost_immunity(attacker: BattleBattler, move: MoveData) -> bool:
	if move == null:
		return false
	if has(attacker, AbilityId.Id.MINDS_EYE):
		return move.type == PokemonData.Type.TYPE_NORMAL or move.type == PokemonData.Type.TYPE_FIGHTING
	if not has(attacker, AbilityId.Id.SCRAPPY):
		return false
	return move.type == PokemonData.Type.TYPE_NORMAL or move.type == PokemonData.Type.TYPE_FIGHTING


static func blocks_indirect_damage(battler: BattleBattler) -> bool:
	return has(battler, AbilityId.Id.MAGIC_GUARD)

static func _is_traceable(id: AbilityId.Id) -> bool:
	match id:
		AbilityId.Id.NONE, AbilityId.Id.TRACE, AbilityId.Id.MULTITYPE, AbilityId.Id.ILLUSION, \
		AbilityId.Id.IMPOSTER, AbilityId.Id.STANCE_CHANGE, AbilityId.Id.SCHOOLING, \
		AbilityId.Id.RKS_SYSTEM, AbilityId.Id.DISGUISE, AbilityId.Id.BATTLE_BOND, \
		AbilityId.Id.POWER_CONSTRUCT, AbilityId.Id.NEUTRALIZING_GAS, AbilityId.Id.GULP_MISSILE, \
		AbilityId.Id.ICE_FACE, AbilityId.Id.HUNGER_SWITCH, \
		AbilityId.Id.AS_ONE_ICE_RIDER, AbilityId.Id.AS_ONE_SHADOW_RIDER:
			return false
	return true

## Velocidad por clima (llamar al calcular orden de turno)
static func speed_multiplier(battler: BattleBattler, weather: int, terrain: int = -1) -> float:
	if battler == null:
		return 1.0
	match get_id(battler):
		AbilityId.Id.CHLOROPHYLL:
			if weather == WeatherId.WEATHER_DROUGHT:
				return 2.0
		AbilityId.Id.SWIFT_SWIM:
			if weather == WeatherId.WEATHER_RAIN:
				return 2.0
		AbilityId.Id.SAND_RUSH:
			if weather == WeatherId.WEATHER_SANDSTORM:
				return 2.0
		AbilityId.Id.SLUSH_RUSH:
			if weather == WeatherId.WEATHER_SNOW:
				return 2.0
		AbilityId.Id.SURGE_SURFER:
			if terrain == BattleManager.TerrainId.TERRAIN_ELECTRIC:
				return 2.0
	return 1.0


## Tras recibir daño de un movimiento (no status)
static func on_damaged_by_move(
	defender: BattleBattler,
	attacker: BattleBattler,
	move: MoveData,
	was_critical: bool,
	battle: BattleManager
) -> void:
	if defender == null or defender.is_fainted() or move == null or battle == null:
		return

	match get_id(defender):
		AbilityId.Id.WEAK_ARMOR:
			if move.category == MoveStruct.DamageCategory.PHYSICAL:
				await battle.ability_announce(defender)
				await battle.ability_change_stat(defender, PokemonInstance.Stat.DEFENSE, -1)
				await battle.ability_change_stat(defender, PokemonInstance.Stat.SPEED, 1)

		AbilityId.Id.JUSTIFIED:
			if move.type == PokemonData.Type.TYPE_DARK:
				await battle.ability_announce(defender)
				await battle.ability_change_stat(defender, PokemonInstance.Stat.ATTACK, 1)

		AbilityId.Id.RATTLED:
			if move.type == PokemonData.Type.TYPE_DARK \
					or move.type == PokemonData.Type.TYPE_BUG \
					or move.type == PokemonData.Type.TYPE_GHOST:
				await battle.ability_announce(defender)
				await battle.ability_change_stat(defender, PokemonInstance.Stat.SPEED, 1)

		AbilityId.Id.STAMINA:
			await battle.ability_announce(defender)
			await battle.ability_change_stat(defender, PokemonInstance.Stat.DEFENSE, 1)

		AbilityId.Id.ANGER_POINT:
			if was_critical:
				await battle.ability_announce(defender)
				await battle.ability_change_stat(defender, PokemonInstance.Stat.ATTACK, 12)

		AbilityId.Id.STEAM_ENGINE:
			if move.type == PokemonData.Type.TYPE_FIRE or move.type == PokemonData.Type.TYPE_WATER:
				await battle.ability_announce(defender)
				await battle.ability_change_stat(defender, PokemonInstance.Stat.SPEED, 6)

		AbilityId.Id.WATER_COMPACTION:
			if move.type == PokemonData.Type.TYPE_WATER:
				await battle.ability_announce(defender)
				await battle.ability_change_stat(defender, PokemonInstance.Stat.DEFENSE, 2)

		AbilityId.Id.THERMAL_EXCHANGE:
			if move.type == PokemonData.Type.TYPE_FIRE:
				await battle.ability_announce(defender)
				await battle.ability_change_stat(defender, PokemonInstance.Stat.ATTACK, 1)

		AbilityId.Id.COTTON_DOWN:
			if attacker != null and not attacker.is_fainted():
				await battle.ability_announce(defender)
				await battle.ability_change_stat(attacker, PokemonInstance.Stat.SPEED, -1, true)

		AbilityId.Id.SAND_SPIT:
			await battle.ability_announce(defender)
			battle.set_weather(WeatherId.WEATHER_SANDSTORM, 5)

		AbilityId.Id.SEED_SOWER:
			await battle.ability_announce(defender)
			battle.set_terrain(BattleManager.TerrainId.TERRAIN_GRASSY, 5)

		AbilityId.Id.BERSERK:
			if defender.pokemon != null and defender.pokemon.max_hp > 0:
				var ratio: float = float(defender.pokemon.current_hp) / float(defender.pokemon.max_hp)
				if ratio <= 0.5:
					await battle.ability_announce(defender)
					await battle.ability_change_stat(defender, PokemonInstance.Stat.SP_ATTACK, 1)

		AbilityId.Id.ANGER_SHELL:
			if defender.pokemon != null and defender.pokemon.max_hp > 0:
				var ratio2: float = float(defender.pokemon.current_hp) / float(defender.pokemon.max_hp)
				if ratio2 <= 0.5:
					await battle.ability_announce(defender)
					await battle.ability_change_stat(defender, PokemonInstance.Stat.ATTACK, 1)
					await battle.ability_change_stat(defender, PokemonInstance.Stat.SP_ATTACK, 1)
					await battle.ability_change_stat(defender, PokemonInstance.Stat.SPEED, 1)
					await battle.ability_change_stat(defender, PokemonInstance.Stat.DEFENSE, -1)
					await battle.ability_change_stat(defender, PokemonInstance.Stat.SP_DEFENSE, -1)

		AbilityId.Id.TOXIC_DEBRIS:
			if move.category == MoveStruct.DamageCategory.PHYSICAL:
				await battle.ability_announce(defender)
				var foe_side: FieldSide = battle.enemy_side if defender.is_player_side else battle.player_side
				foe_side.toxic_spikes_layers = mini(2, foe_side.toxic_spikes_layers + 1)
				battle.message.emit("¡Se esparcieron Púas Tóxicas!")
				await battle._wait(0.5)

		AbilityId.Id.COLOR_CHANGE:
			var mt: PokemonData.Type = effective_move_type(attacker, move)
			if mt != PokemonData.Type.TYPE_NONE:
				defender.set_battle_types(mt)
				await battle.ability_announce(defender)
				battle.message.emit("¡%s cambió de tipo!" % defender.get_display_name())
				await battle._wait(0.5)

		AbilityId.Id.ELECTROMORPHOSIS:
			await battle.ability_announce(defender)
			defender.charged = true
			battle.message.emit("¡%s se cargó de electricidad!" % defender.get_display_name())
			await battle._wait(0.5)

		AbilityId.Id.WIND_POWER:
			if move.wind_move:
				await battle.ability_announce(defender)
				defender.charged = true
				battle.message.emit("¡%s se cargó de electricidad!" % defender.get_display_name())
				await battle._wait(0.5)


## Illusion: disfraza con el último Pokémon no debilitado del mismo equipo.
static func _setup_illusion(battler: BattleBattler, battle: BattleManager) -> void:
	if battler == null or battler.pokemon == null or battle == null:
		return

	var party: Array[PokemonInstance] = battle.player_party if battler.is_player_side else battle.enemy_party
	var disguise: PokemonInstance = null

	# El disfraz es el último miembro del party que no sea el activo y no esté KO.
	for i: int in range(party.size() - 1, -1, -1):
		var mon: PokemonInstance = party[i]
		if mon == null or mon == battler.pokemon:
			continue
		if mon.is_fainted():
			continue
		disguise = mon
		break

	if disguise == null:
		return  # sin disfraz posible: no anuncia, Illusion “falla” en silencio como en los juegos

	battler.illusion_active = true
	battler.illusion_species_id = disguise.species_id
	battler.illusion_nickname = disguise.get_display_name()
	battler.illusion_gender = disguise.gender
	battler.illusion_shiny = disguise.shiny if "shiny" in disguise else false
	battler.illusion_form_id = disguise.form_id if "form_id" in disguise else 0

	# No se anuncia Illusion al entrar: el truco es que no se note.
	battle.battler_appearance_changed.emit(battler.is_player_side)


## Se llama al recibir daño real (HP baja).
static func break_illusion(battler: BattleBattler, battle: BattleManager) -> void:
	if battler == null or not battler.illusion_active:
		return
	battler.clear_illusion()
	await battle.ability_announce(battler)
	battle.illusion_broken.emit(battler.is_player_side)
	battle.battler_appearance_changed.emit(battler.is_player_side)
	battle.message.emit("¡La ilusión de %s se disipó!" % battler.get_display_name())
	await battle._wait(0.7)


## Imposter = Transform completo del rival (stats base del transform, mismos moves, etc.).
static func _setup_imposter(
	battler: BattleBattler,
	opponent: BattleBattler,
	battle: BattleManager
) -> void:
	if battler == null or opponent == null or opponent.pokemon == null:
		return
	if battler.is_transformed:
		return

	await battle.ability_announce(battler)

	var src: PokemonInstance = opponent.pokemon
	var dst: PokemonInstance = battler.pokemon

	battler.transform_backup = {
		"species_id": dst.species_id,
		"form_id": dst.form_id,
		"ability_id": dst.ability_id,
		"moves": dst.moves.duplicate(true),
	}

	# HP / max_hp del Ditto se conservan
	dst.species_id = src.species_id
	dst.form_id = src.form_id
	dst.ability_id = src.ability_id

	dst.moves.clear()
	for slot: PokemonMoveSlot in src.moves:
		if slot == null or slot.is_empty():
			continue
		var copy: PokemonMoveSlot = PokemonMoveSlot.new()
		copy.move_id = slot.move_id
		copy.pp_ups = 0
		# Transform clásico: 5 PP (o el máximo del move si es menor)
		var md: MoveData = MoveDatabase.get_move(slot.move_id)
		var base_pp: int = md.pp if md != null else 5
		copy.current_pp = mini(5, base_pp)
		dst.moves.append(copy)

	battler.stage_attack = opponent.stage_attack
	battler.stage_defense = opponent.stage_defense
	battler.stage_sp_attack = opponent.stage_sp_attack
	battler.stage_sp_defense = opponent.stage_sp_defense
	battler.stage_speed = opponent.stage_speed
	battler.stage_accuracy = opponent.stage_accuracy
	battler.stage_evasion = opponent.stage_evasion

	battler.is_transformed = true
	battler.clear_illusion()

	battle.message.emit("¡%s se transformó en %s!" % [
		battler.get_display_name(),
		opponent.get_display_name()
	])
	battle.battler_appearance_changed.emit(battler.is_player_side)
	await battle._wait(0.9)

static func revert_transform(battler: BattleBattler) -> void:
	if battler == null or not battler.is_transformed:
		return
	if battler.pokemon == null or battler.transform_backup.is_empty():
		battler.is_transformed = false
		battler.transform_backup.clear()
		return

	var dst: PokemonInstance = battler.pokemon
	var bak: Dictionary = battler.transform_backup

	dst.species_id = bak.get("species_id", dst.species_id)
	dst.form_id = bak.get("form_id", dst.form_id)
	dst.ability_id = bak.get("ability_id", dst.ability_id)

	var moves_bak: Variant = bak.get("moves", null)
	if moves_bak is Array:
		dst.moves.clear()
		for slot: Variant in moves_bak:
			if slot is PokemonMoveSlot:
				dst.moves.append(slot)

	battler.is_transformed = false
	battler.transform_backup.clear()

## Solo estado visual. Sin await, sin Ability Bar.
## Llamar ANTES de mostrar sprites / nombres.
static func prepare_illusion(battler: BattleBattler, battle: BattleManager) -> bool:
	if battler == null or battler.pokemon == null or battle == null:
		return false
	if get_id(battler) != AbilityId.Id.ILLUSION:
		return false

	var party: Array[PokemonInstance] = (
		battle.player_party if battler.is_player_side else battle.enemy_party
	)
	var disguise: PokemonInstance = null
	for i: int in range(party.size() - 1, -1, -1):
		var mon: PokemonInstance = party[i]
		if mon == null or mon == battler.pokemon:
			continue
		if mon.is_fainted():
			continue
		disguise = mon
		break

	if disguise == null:
		battler.clear_illusion()
		return false

	battler.illusion_active = true
	battler.illusion_species_id = disguise.species_id
	battler.illusion_nickname = disguise.get_display_name()
	battler.illusion_gender = disguise.gender
	battler.illusion_shiny = disguise.shiny if "shiny" in disguise else false
	return true

static func _blocks_intimidate(battler: BattleBattler) -> bool:
	var id: AbilityId.Id = get_id(battler)
	return id == AbilityId.Id.INNER_FOCUS or id == AbilityId.Id.OWN_TEMPO \
		or id == AbilityId.Id.OBLIVIOUS or id == AbilityId.Id.SCRAPPY \
		or id == AbilityId.Id.GUARD_DOG


static func _apply_mimicry(battler: BattleBattler, battle: BattleManager) -> void:
	if battler == null or battle == null:
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
			battler.clear_battle_types()
			return
	battler.set_battle_types(t)
	await battle.ability_announce(battler)
	battle.message.emit("¡%s cambió de tipo por el terreno!" % battler.get_display_name())
	await battle._wait(0.5)


static func priority_bonus(battler: BattleBattler, move: MoveData) -> int:
	if battler == null or move == null:
		return 0
	match get_id(battler):
		AbilityId.Id.PRANKSTER:
			if move.category == MoveStruct.DamageCategory.STATUS:
				return 1
		AbilityId.Id.GALE_WINGS:
			if move.type == PokemonData.Type.TYPE_FLYING \
					and battler.pokemon != null \
					and battler.pokemon.current_hp == battler.pokemon.max_hp:
				return 1
		AbilityId.Id.TRIAGE:
			if move.healing_move:
				return 3
	return 0


static func blocks_priority_move(defender: BattleBattler, move: MoveData) -> bool:
	if defender == null or move == null:
		return false
	if move.priority <= 0:
		return false
	var id: AbilityId.Id = get_id(defender)
	return id == AbilityId.Id.DAZZLING or id == AbilityId.Id.QUEENLY_MAJESTY \
		or id == AbilityId.Id.ARMOR_TAIL


static func blocks_status_move(defender: BattleBattler, move: MoveData) -> bool:
	if defender == null or move == null:
		return false
	if move.category != MoveStruct.DamageCategory.STATUS:
		return false
	return has(defender, AbilityId.Id.GOOD_AS_GOLD) or has(defender, AbilityId.Id.MAGIC_BOUNCE)


static func effective_move_type(attacker: BattleBattler, move: MoveData) -> PokemonData.Type:
	if move == null:
		return PokemonData.Type.TYPE_NONE
	var t: PokemonData.Type = move.type
	if attacker == null:
		return t
	match get_id(attacker):
		AbilityId.Id.NORMALIZE:
			return PokemonData.Type.TYPE_NORMAL
		AbilityId.Id.PIXILATE:
			if t == PokemonData.Type.TYPE_NORMAL:
				return PokemonData.Type.TYPE_FAIRY
		AbilityId.Id.REFRIGERATE:
			if t == PokemonData.Type.TYPE_NORMAL:
				return PokemonData.Type.TYPE_ICE
		AbilityId.Id.AERILATE:
			if t == PokemonData.Type.TYPE_NORMAL:
				return PokemonData.Type.TYPE_FLYING
		AbilityId.Id.GALVANIZE:
			if t == PokemonData.Type.TYPE_NORMAL:
				return PokemonData.Type.TYPE_ELECTRIC
		AbilityId.Id.LIQUID_VOICE:
			if move.sound_move:
				return PokemonData.Type.TYPE_WATER
	return t


static func type_change_power_multiplier(attacker: BattleBattler, move: MoveData) -> float:
	if move == null or move.type != PokemonData.Type.TYPE_NORMAL:
		return 1.0
	match get_id(attacker):
		AbilityId.Id.PIXILATE, AbilityId.Id.REFRIGERATE, \
		AbilityId.Id.AERILATE, AbilityId.Id.GALVANIZE, AbilityId.Id.NORMALIZE:
			return 1.2
	return 1.0


static func aura_multiplier(_attacker: BattleBattler, _defender: BattleBattler, move_type: PokemonData.Type, battle: BattleManager) -> float:
	if battle == null:
		return 1.0
	if move_type != PokemonData.Type.TYPE_DARK and move_type != PokemonData.Type.TYPE_FAIRY:
		return 1.0
	var has_dark: bool = false
	var has_fairy: bool = false
	var has_break: bool = false
	for b: BattleBattler in [battle.player, battle.enemy]:
		if b == null or b.is_fainted():
			continue
		match get_id(b):
			AbilityId.Id.DARK_AURA:
				has_dark = true
			AbilityId.Id.FAIRY_AURA:
				has_fairy = true
			AbilityId.Id.AURA_BREAK:
				has_break = true
	if move_type == PokemonData.Type.TYPE_DARK and has_dark:
		return 0.75 if has_break else 1.33
	if move_type == PokemonData.Type.TYPE_FAIRY and has_fairy:
		return 0.75 if has_break else 1.33
	return 1.0


static func ruin_stat_multiplier(stat_owner: BattleBattler, stat: PokemonInstance.Stat, battle: BattleManager) -> float:
	if battle == null or stat_owner == null:
		return 1.0
	var mult: float = 1.0
	for b: BattleBattler in [battle.player, battle.enemy]:
		if b == null or b.is_fainted() or b == stat_owner:
			continue
		match get_id(b):
			AbilityId.Id.TABLETS_OF_RUIN:
				if stat == PokemonInstance.Stat.ATTACK:
					mult *= 0.75
			AbilityId.Id.SWORD_OF_RUIN:
				if stat == PokemonInstance.Stat.DEFENSE:
					mult *= 0.75
			AbilityId.Id.VESSEL_OF_RUIN:
				if stat == PokemonInstance.Stat.SP_ATTACK:
					mult *= 0.75
			AbilityId.Id.BEADS_OF_RUIN:
				if stat == PokemonInstance.Stat.SP_DEFENSE:
					mult *= 0.75
	return mult


static func try_protean(battler: BattleBattler, move: MoveData, battle: BattleManager) -> void:
	if battler == null or move == null or battle == null:
		return
	var id: AbilityId.Id = get_id(battler)
	if id != AbilityId.Id.PROTEAN and id != AbilityId.Id.LIBERO:
		return
	var mt: PokemonData.Type = effective_move_type(battler, move)
	if mt == PokemonData.Type.TYPE_NONE:
		return
	if battler.get_battle_type_1() == mt and battler.get_battle_type_2() == PokemonData.Type.TYPE_NONE:
		return
	battler.set_battle_types(mt)
	battle.message.emit("¡%s cambió al tipo del movimiento!" % battler.get_display_name())


static func always_crits(attacker: BattleBattler, defender: BattleBattler) -> bool:
	if not has(attacker, AbilityId.Id.MERCILESS):
		return false
	if defender == null or defender.pokemon == null:
		return false
	var st: PokemonInstance.Status = defender.pokemon.status
	return st == PokemonInstance.Status.POISON or st == PokemonInstance.Status.TOXIC


static func move_makes_contact(attacker: BattleBattler, move: MoveData) -> bool:
	if move == null or not move.makes_contact:
		return false
	if has(attacker, AbilityId.Id.LONG_REACH):
		return false
	return true


static func analytic_multiplier(attacker: BattleBattler, acted_after_target: bool) -> float:
	if acted_after_target and has(attacker, AbilityId.Id.ANALYTIC):
		return 1.3
	return 1.0


static func stakeout_multiplier(attacker: BattleBattler, defender: BattleBattler) -> float:
	if has(attacker, AbilityId.Id.STAKEOUT) and defender != null and defender.just_switched_in:
		return 2.0
	return 1.0


static func supreme_overlord_multiplier(attacker: BattleBattler, battle: BattleManager) -> float:
	if not has(attacker, AbilityId.Id.SUPREME_OVERLORD) or battle == null:
		return 1.0
	var party: Array[PokemonInstance] = battle.player_party if attacker.is_player_side else battle.enemy_party
	var fainted: int = 0
	for mon: PokemonInstance in party:
		if mon != null and mon.is_fainted():
			fainted += 1
	return 1.0 + 0.1 * float(mini(fainted, 5))


static func on_flinched(battler: BattleBattler, battle: BattleManager) -> void:
	if battler == null or battle == null:
		return
	if has(battler, AbilityId.Id.STEADFAST):
		await battle.ability_announce(battler)
		await battle.ability_change_stat(battler, PokemonInstance.Stat.SPEED, 1)


static func on_switch_out(battler: BattleBattler, battle: BattleManager) -> void:
	if battler == null or battler.pokemon == null or battle == null:
		return
	match get_id(battler):
		AbilityId.Id.NATURAL_CURE:
			if battler.pokemon.has_status():
				await battle.ability_announce(battler)
				await battle.ability_cure_status(battler)
		AbilityId.Id.REGENERATOR:
			await battle.ability_announce(battler)
			@warning_ignore("integer_division")
			await battle.ability_heal(battler, maxi(1, battler.get_max_hp() / 3))
	battler.clear_battle_types()
	battler.charged = false


static func after_own_stat_drop(battler: BattleBattler, actual: int, caused_by_foe: bool, battle: BattleManager) -> void:
	if not caused_by_foe or actual >= 0 or battler == null or battle == null:
		return
	match get_id(battler):
		AbilityId.Id.DEFIANT:
			await battle.ability_announce(battler)
			await battle.ability_change_stat(battler, PokemonInstance.Stat.ATTACK, 2)
		AbilityId.Id.COMPETITIVE:
			await battle.ability_announce(battler)
			await battle.ability_change_stat(battler, PokemonInstance.Stat.SP_ATTACK, 2)
		AbilityId.Id.GUARD_DOG:
			await battle.ability_announce(battler)
			await battle.ability_change_stat(battler, PokemonInstance.Stat.ATTACK, 1)


static func sand_force_active(battler: BattleBattler, move: MoveData, weather: int) -> float:
	if not has(battler, AbilityId.Id.SAND_FORCE):
		return 1.0
	if weather != WeatherId.WEATHER_SANDSTORM or move == null:
		return 1.0
	if move.type == PokemonData.Type.TYPE_ROCK or move.type == PokemonData.Type.TYPE_GROUND \
			or move.type == PokemonData.Type.TYPE_STEEL:
		return 1.3
	return 1.0


static func solar_power_multiplier(battler: BattleBattler, category: MoveStruct.DamageCategory, weather: int) -> float:
	if category != MoveStruct.DamageCategory.SPECIAL:
		return 1.0
	if has(battler, AbilityId.Id.SOLAR_POWER) and weather == WeatherId.WEATHER_DROUGHT:
		return 1.5
	return 1.0


static func hadron_orichalcum_multiplier(battler: BattleBattler, category: MoveStruct.DamageCategory, weather: int, terrain: int) -> float:
	if has(battler, AbilityId.Id.HADRON_ENGINE) and category == MoveStruct.DamageCategory.SPECIAL \
			and terrain == BattleManager.TerrainId.TERRAIN_ELECTRIC:
		return 1.3333
	if has(battler, AbilityId.Id.ORICHALCUM_PULSE) and category == MoveStruct.DamageCategory.PHYSICAL \
			and weather == WeatherId.WEATHER_DROUGHT:
		return 1.3333
	return 1.0


static func grass_pelt_multiplier(defender: BattleBattler, move: MoveData, terrain: int) -> float:
	if move == null or move.category != MoveStruct.DamageCategory.PHYSICAL:
		return 1.0
	if has(defender, AbilityId.Id.GRASS_PELT) and terrain == BattleManager.TerrainId.TERRAIN_GRASSY:
		return 0.6667
	return 1.0


static func marvel_scale_multiplier(defender: BattleBattler, move: MoveData) -> float:
	if move == null or move.category != MoveStruct.DamageCategory.PHYSICAL:
		return 1.0
	if has(defender, AbilityId.Id.MARVEL_SCALE) and defender.pokemon != null and defender.pokemon.has_status():
		return 0.6667
	return 1.0


static func damp_blocks_explosion(blocker: BattleBattler, move: MoveData) -> bool:
	if move == null or not move.is_explosion:
		return false
	return has(blocker, AbilityId.Id.DAMP)


static func ignores_protect_contact(attacker: BattleBattler, move: MoveData) -> bool:
	return has(attacker, AbilityId.Id.UNSEEN_FIST) and move != null and move.makes_contact


static func corrosion_can_poison(attacker: BattleBattler) -> bool:
	return has(attacker, AbilityId.Id.CORROSION)
