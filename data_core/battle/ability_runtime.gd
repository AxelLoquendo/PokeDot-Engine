extends RefCounted
class_name AbilityRuntime

## ─────────────────────────────────────────────────────────
## Capa central que conecta AbilityData/AbilityEffect con el
## combate real. Todo aquí es "best effort": si una habilidad
## no está contemplada en las tablas de abajo, simplemente no
## hace nada (no rompe el combate).
##
## NOTA sobre nombres heredados: el enum weatherAbilityID
## (en ability_battle_effect.gd) usa WEATHER_DROUGHT para
## representar el clima "sol" y WEATHER_SNOW para "granizo".
## Se mantienen esos nombres para no romper el editor de
## habilidades ya existente.
## ─────────────────────────────────────────────────────────

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


## ─── Inmunidades de tipo por habilidad (Levitate, absorciones...) ─
## Devuelve una "reacción" o "" si no hay inmunidad por habilidad:
## "immune", "heal", "spatk_up", "atk_up", "spe_up", "flash_fire"
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


## Wonder Guard: solo pasan movimientos súper efectivos.
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


## Multiplicador de POTENCIA del movimiento (Blaze/Torrent/Overgrow/Swarm,
## y el boost de Flash Fire una vez activado).
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


## Reduce el daño recibido (Thick Fat, Solid Rock/Filter/Prism Armor).
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
	return mult


## ─── Sturdy: sobrevive con 1 PS si estaba al máximo ─────
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


## ─── Entrada en combate: Intimidate y las habilidades de clima ──
static func on_switch_in(battler: BattleBattler, opponent: BattleBattler, battle: BattleManager) -> void:
	if battler == null or battler.pokemon == null or battle == null:
		return

	match get_id(battler):
		AbilityId.Id.INTIMIDATE:
			if opponent != null and not opponent.is_fainted():
				battle.ability_announce(battler)
				battle.ability_change_stat(opponent, PokemonInstance.Stat.ATTACK, -1)
		AbilityId.Id.DRIZZLE:
			battle.ability_announce(battler)
			battle.set_weather(WeatherId.WEATHER_RAIN, -1)
		AbilityId.Id.DROUGHT:
			battle.ability_announce(battler)
			battle.set_weather(WeatherId.WEATHER_DROUGHT, -1)
		AbilityId.Id.SAND_STREAM:
			battle.ability_announce(battler)
			battle.set_weather(WeatherId.WEATHER_SANDSTORM, -1)
		AbilityId.Id.SNOW_WARNING:
			battle.ability_announce(battler)
			battle.set_weather(WeatherId.WEATHER_SNOW, -1)


## ─── Contacto: Static / Poison Point / Flame Body / Rough Skin / Iron Barbs ─
## Llamar tras un golpe CON CONTACTO que impactó.
static func on_contact_hit(attacker: BattleBattler, defender: BattleBattler, move: MoveData, battle: BattleManager) -> void:
	if move == null or not move.makes_contact:
		return
	if attacker == null or attacker.is_fainted():
		return

	match get_id(defender):
		AbilityId.Id.STATIC:
			if randf() < 0.3:
				battle.ability_apply_status(attacker, PokemonInstance.Status.PARALYSIS, defender)
		AbilityId.Id.POISON_POINT:
			if randf() < 0.3:
				battle.ability_apply_status(attacker, PokemonInstance.Status.POISON, defender)
		AbilityId.Id.FLAME_BODY:
			if randf() < 0.3:
				battle.ability_apply_status(attacker, PokemonInstance.Status.BURN, defender)
		AbilityId.Id.ROUGH_SKIN, AbilityId.Id.IRON_BARBS:
			@warning_ignore("integer_division")
			var dmg: int = maxi(1, attacker.get_max_hp() / 8)
			battle.ability_deal_damage(attacker, dmg, defender)


## ─── Fin de turno: Speed Boost / Shed Skin / Rain Dish / Ice Body ───
static func end_of_turn(battler: BattleBattler, weather: int, battle: BattleManager) -> void:
	if battler == null or battler.is_fainted():
		return
	match get_id(battler):
		AbilityId.Id.SPEED_BOOST:
			battle.ability_change_stat(battler, PokemonInstance.Stat.SPEED, 1)
		AbilityId.Id.SHED_SKIN:
			if battler.pokemon.has_status() and randf() < 0.3:
				battle.ability_cure_status(battler)
		AbilityId.Id.RAIN_DISH:
			if weather == WeatherId.WEATHER_RAIN:
				@warning_ignore("integer_division")
				battle.ability_heal(battler, maxi(1, battler.get_max_hp() / 16))
		AbilityId.Id.ICE_BODY:
			if weather == WeatherId.WEATHER_SNOW:
				@warning_ignore("integer_division")
				battle.ability_heal(battler, maxi(1, battler.get_max_hp() / 16))


## ¿Este Pokémon NO recibe daño de la tormenta de arena / granizo?
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
