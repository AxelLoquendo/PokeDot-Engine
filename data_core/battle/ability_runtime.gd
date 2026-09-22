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
	return ""


static func blocks_unless_super_effective(defender: BattleBattler) -> bool:
	return has(defender, AbilityId.Id.WONDER_GUARD)


## ─── Multiplicadores de daño ────────────────────────────
static func attack_stat_multiplier(attacker: BattleBattler, category: MoveStruct.DamageCategory) -> float:
	if category != MoveStruct.DamageCategory.PHYSICAL:
		return 1.0
	match get_id(attacker):
		AbilityId.Id.HUGE_POWER, AbilityId.Id.PURE_POWER:
			return 2.0
		AbilityId.Id.HUSTLE:
			return 1.5
		AbilityId.Id.GUTS:
			if attacker.pokemon.has_status():
				return 1.5
	return 1.0


static func power_multiplier(attacker: BattleBattler, move: MoveData) -> float:
	if move == null or attacker.pokemon == null:
		return 1.0

	var id: AbilityId.Id = get_id(attacker)

	if id == AbilityId.Id.FLASH_FIRE and attacker.flash_fire_boosted \
			and move.type == PokemonData.Type.TYPE_FIRE:
		return 1.5

	var low_hp: bool = attacker.pokemon.max_hp > 0 \
		and float(attacker.pokemon.current_hp) / float(attacker.pokemon.max_hp) <= 1.0 / 3.0
	if not low_hp:
		return 1.0

	match id:
		AbilityId.Id.BLAZE:
			if move.type == PokemonData.Type.TYPE_FIRE:
				return 1.5
		AbilityId.Id.TORRENT:
			if move.type == PokemonData.Type.TYPE_WATER:
				return 1.5
		AbilityId.Id.OVERGROW:
			if move.type == PokemonData.Type.TYPE_GRASS:
				return 1.5
		AbilityId.Id.SWARM:
			if move.type == PokemonData.Type.TYPE_BUG:
				return 1.5
	return 1.0


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
static func blocks_status(battler: BattleBattler, status: PokemonInstance.Status) -> bool:
	var id: AbilityId.Id = get_id(battler)
	match status:
		PokemonInstance.Status.SLEEP:
			return id == AbilityId.Id.INSOMNIA or id == AbilityId.Id.VITAL_SPIRIT
		PokemonInstance.Status.POISON, PokemonInstance.Status.TOXIC:
			return id == AbilityId.Id.IMMUNITY
		PokemonInstance.Status.BURN:
			return id == AbilityId.Id.WATER_VEIL or id == AbilityId.Id.WATER_BUBBLE
		PokemonInstance.Status.PARALYSIS:
			return id == AbilityId.Id.LIMBER
		PokemonInstance.Status.FREEZE:
			return id == AbilityId.Id.MAGMA_ARMOR
	return false


static func blocks_confusion(battler: BattleBattler) -> bool:
	return has(battler, AbilityId.Id.OWN_TEMPO)


static func blocks_flinch(battler: BattleBattler) -> bool:
	return has(battler, AbilityId.Id.INNER_FOCUS)


## ─── Entrada en combate ─────────────────────────────────
static func on_switch_in(battler: BattleBattler, opponent: BattleBattler, battle: BattleManager) -> void:
	if battler == null or battler.pokemon == null or battle == null:
		return

	match get_id(battler):
		AbilityId.Id.INTIMIDATE:
			if opponent != null and not opponent.is_fainted():
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
			await _setup_illusion(battler, battle)

		AbilityId.Id.IMPOSTER:
			if opponent != null and not opponent.is_fainted():
				await _setup_imposter(battler, opponent, battle)

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
			battle.set_weather(WeatherId.WEATHER_RAIN, -1, true)

		AbilityId.Id.DESOLATE_LAND:
			await battle.ability_announce(battler)
			battle.set_weather(WeatherId.WEATHER_DROUGHT, -1, true)

		AbilityId.Id.DELTA_STREAM:
			await battle.ability_announce(battler)
			# Si no tienes WEATHER_STRONG_WINDS, usa un id propio o reutiliza uno
			# y trátalo como “vientos fuertes” en TypeChart (Flying no débil a Rock/Ice/Electric).
			battle.set_weather(WeatherId.WEATHER_NONE, -1, true)  # ajusta al enum real
			battle.message.emit("¡Se formaron misteriosas corrientes de aire!")
			await battle._wait(0.7)

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
	if has(attacker, AbilityId.Id.TINTED_LENS) and effectiveness > 0.0 and effectiveness < 1.0:
		return 2.0
	return 1.0


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
	if move == null or not has(attacker, AbilityId.Id.SCRAPPY):
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
static func speed_multiplier(battler: BattleBattler, weather: int) -> float:
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

	await battle.ability_announce(battler)

	# Backup mínimo por si más adelante quieres des-transformar al cambiar.
	battler.transform_backup = {
		"species_id": battler.pokemon.species_id,
		"ability_id": battler.pokemon.ability_id,
		"moves": battler.pokemon.moves.duplicate(true),
	}

	# Copia visual + datos de combate del rival (HP/max HP se mantienen del original).
	var src: PokemonInstance = opponent.pokemon
	var dst: PokemonInstance = battler.pokemon

	# Ajusta a tu API real de especie/forma:
	dst.species_id = src.species_id
	if "form_id" in dst and "form_id" in src:
		dst.form_id = src.form_id
	dst.ability_id = src.ability_id

	# Moves: copia slots (PP al máximo del move copiado o PP actuales del rival; típico = PP del move).
	dst.moves.clear()
	for slot: PokemonMoveSlot in src.moves:
		if slot == null or slot.is_empty():
			continue
		var copy: PokemonMoveSlot = PokemonMoveSlot.new()
		copy.move_id = slot.move_id
		copy.current_pp = slot.current_pp
		copy.max_pp = slot.max_pp
		dst.moves.append(copy)

	# Stages del transform: se copian los del rival (comportamiento clásico de Transform).
	battler.stage_attack = opponent.stage_attack
	battler.stage_defense = opponent.stage_defense
	battler.stage_sp_attack = opponent.stage_sp_attack
	battler.stage_sp_defense = opponent.stage_sp_defense
	battler.stage_speed = opponent.stage_speed
	battler.stage_accuracy = opponent.stage_accuracy
	battler.stage_evasion = opponent.stage_evasion

	battler.is_transformed = true
	battler.clear_illusion()  # por si acaso

	battle.message.emit("¡%s se transformó en %s!" % [
		battler.get_display_name(),
		opponent.get_display_name()
	])
	battle.battler_appearance_changed.emit(battler.is_player_side)
	await battle._wait(0.9)
