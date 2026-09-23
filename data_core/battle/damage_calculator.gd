extends RefCounted
class_name DamageCalculator

class HitResult:
	var hit: bool = false
	var damage: int = 0
	var effectiveness: float = 1.0
	var critical: bool = false
	var is_status: bool = false
	var ability_immunity: String = ""
	var sturdy_activated: bool = false
	var contact: bool = false
	## Pasivas que modificaron este golpe (una vez por movimiento en el manager).
	var activated_attacker: Array[AbilityId.Id] = []
	var activated_defender: Array[AbilityId.Id] = []

static func _note_atk(result: HitResult, id: AbilityId.Id) -> void:
	if id == AbilityId.Id.NONE:
		return
	if not result.activated_attacker.has(id):
		result.activated_attacker.append(id)


static func _note_def(result: HitResult, id: AbilityId.Id) -> void:
	if id == AbilityId.Id.NONE:
		return
	if not result.activated_defender.has(id):
		result.activated_defender.append(id)

static func check_hit(move: MoveData, attacker: BattleBattler, defender: BattleBattler) -> bool:
	if move == null:
		return false
	if move.always_hits:
		return true
	if AbilityRuntime.has(attacker, AbilityId.Id.NO_GUARD) or AbilityRuntime.has(defender, AbilityId.Id.NO_GUARD):
		return true
	if move.accuracy <= 0:
		return true

	var acc: int = clampi(move.accuracy, 1, 100)
	var acc_stage: int = clampi(attacker.stage_accuracy - defender.stage_evasion, -6, 6)
	var stage_mult: float = BattleBattler._stage_multiplier(acc_stage)
	var final_acc: float = float(acc) * stage_mult

	if AbilityRuntime.has(attacker, AbilityId.Id.COMPOUND_EYES):
		final_acc *= 1.3
	if AbilityRuntime.has(attacker, AbilityId.Id.HUSTLE) \
			and move.category == MoveStruct.DamageCategory.PHYSICAL:
		final_acc *= 0.8
	if AbilityRuntime.victory_star_active(attacker):
		final_acc *= 1.1
	# Wonder Skin: movimientos de estado al 50% de precisión máx.
	if move.category == MoveStruct.DamageCategory.STATUS \
			and AbilityRuntime.has(defender, AbilityId.Id.WONDER_SKIN):
		final_acc = minf(final_acc, 50.0)
	# Tangled Feet: +evasión si confundido (aprox. -20% precisión del rival)
	if defender.is_confused() and AbilityRuntime.has(defender, AbilityId.Id.TANGLED_FEET):
		final_acc *= 0.5

	var final_acc_i: int = clampi(int(round(final_acc)), 1, 100)
	return randi_range(1, 100) <= final_acc_i


## Cuántas veces golpea un movimiento este turno (1 si no es multi-golpe).
## Usa la distribución estándar 35/35/15/15 para el rango clásico 2-5.
static func roll_hit_count(move: MoveData) -> int:
	if move == null or not move.is_multi_hit or move.max_hits <= 1:
		return 1
	if move.min_hits == 2 and move.max_hits == 5:
		var roll: int = randi_range(1, 100)
		if roll <= 35:
			return 2
		elif roll <= 70:
			return 3
		elif roll <= 85:
			return 4
		else:
			return 5
	return randi_range(move.min_hits, move.max_hits)

static func compute_hit(
	attacker: BattleBattler,
	defender: BattleBattler,
	move: MoveData,
	weather: int = AbilityBattleEffect.weatherAbilityID.WEATHER_NONE,
	screen_active: bool = false
) -> HitResult:
	var result: HitResult = HitResult.new()
	if move == null or attacker == null or defender == null:
		return result

	result.hit = true
	result.contact = AbilityRuntime.move_makes_contact(attacker, move)
	var move_type: PokemonData.Type = AbilityRuntime.effective_move_type(attacker, move)

	var ignore_defender_ability: bool = AbilityRuntime.ignores_defender_ability(attacker)
	if ignore_defender_ability:
		_note_atk(result, AbilityRuntime.get_id(attacker))  # Mold Breaker / Teravolt / Turboblaze

	if not ignore_defender_ability:
		var immunity: String = AbilityRuntime.type_immunity_reaction(defender, move)
		if immunity != "":
			result.ability_immunity = immunity
			result.effectiveness = 0.0
			result.damage = 0
			return result

	var level: int = attacker.pokemon.level
	var power: int = maxi(move.power, 1)

	var atk: int
	var def: int
	if move.category == MoveStruct.DamageCategory.PHYSICAL:
		if AbilityRuntime.has(defender, AbilityId.Id.UNAWARE) and not ignore_defender_ability:
			atk = maxi(attacker.pokemon.get_stat(PokemonInstance.Stat.ATTACK), 1)
			_note_def(result, AbilityId.Id.UNAWARE)
		else:
			atk = attacker.get_effective_stat(PokemonInstance.Stat.ATTACK)
		if AbilityRuntime.has(attacker, AbilityId.Id.UNAWARE):
			def = maxi(defender.pokemon.get_stat(PokemonInstance.Stat.DEFENSE), 1)
			_note_atk(result, AbilityId.Id.UNAWARE)
		else:
			def = defender.get_effective_stat(PokemonInstance.Stat.DEFENSE)
		var guts_active: bool = AbilityRuntime.has(attacker, AbilityId.Id.GUTS)
		if attacker.pokemon.status == PokemonInstance.Status.BURN and not guts_active:
			@warning_ignore("integer_division")
			atk = maxi(1, atk / 2)
		var atk_mult: float = AbilityRuntime.attack_stat_multiplier(attacker, move.category)
		if atk_mult != 1.0:
			_note_atk(result, AbilityRuntime.get_id(attacker))
		atk = int(round(float(atk) * atk_mult))
	else:
		if AbilityRuntime.has(defender, AbilityId.Id.UNAWARE) and not ignore_defender_ability:
			atk = maxi(attacker.pokemon.get_stat(PokemonInstance.Stat.SP_ATTACK), 1)
			_note_def(result, AbilityId.Id.UNAWARE)
		else:
			atk = attacker.get_effective_stat(PokemonInstance.Stat.SP_ATTACK)
		if AbilityRuntime.has(attacker, AbilityId.Id.UNAWARE):
			def = maxi(defender.pokemon.get_stat(PokemonInstance.Stat.SP_DEFENSE), 1)
			_note_atk(result, AbilityId.Id.UNAWARE)
		else:
			def = defender.get_effective_stat(PokemonInstance.Stat.SP_DEFENSE)

	def = maxi(def, 1)

	var base: float = ((2.0 * float(level) / 5.0 + 2.0) * float(power) * float(atk) / float(def)) / 50.0 + 2.0

	var pow_mult: float = AbilityRuntime.power_multiplier(attacker, move)
	if pow_mult != 1.0:
		_note_atk(result, AbilityRuntime.get_id(attacker))
	base *= pow_mult

	var tech: float = AbilityRuntime.technician_multiplier(attacker, move)
	if tech != 1.0:
		_note_atk(result, AbilityId.Id.TECHNICIAN)
	base *= tech

	var type_chg: float = AbilityRuntime.type_change_power_multiplier(attacker, move)
	if type_chg != 1.0:
		_note_atk(result, AbilityRuntime.get_id(attacker))
	base *= type_chg

	match weather:
		AbilityBattleEffect.weatherAbilityID.WEATHER_RAIN:
			if move_type == PokemonData.Type.TYPE_WATER:
				base *= 1.5
			elif move_type == PokemonData.Type.TYPE_FIRE:
				base *= 0.5
		AbilityBattleEffect.weatherAbilityID.WEATHER_DROUGHT:
			if move_type == PokemonData.Type.TYPE_FIRE:
				base *= 1.5
			elif move_type == PokemonData.Type.TYPE_WATER:
				base *= 0.5

	var stab: float = 1.0
	var t1: PokemonData.Type = attacker.get_battle_type_1()
	var t2: PokemonData.Type = attacker.get_battle_type_2()
	if move_type == t1 or (t2 != PokemonData.Type.TYPE_NONE and move_type == t2):
		stab = AbilityRuntime.stab_multiplier(attacker)
		if AbilityRuntime.has(attacker, AbilityId.Id.ADAPTABILITY):
			_note_atk(result, AbilityId.Id.ADAPTABILITY)

	var eff: float = TypeChart.get_effectiveness(
		move_type,
		defender.get_battle_type_1(),
		defender.get_battle_type_2()
	)

	if eff <= 0.0 and AbilityRuntime.bypasses_ghost_immunity(attacker, move) \
			and (defender.get_battle_type_1() == PokemonData.Type.TYPE_GHOST \
				or defender.get_battle_type_2() == PokemonData.Type.TYPE_GHOST):
		eff = 1.0
		_note_atk(result, AbilityId.Id.SCRAPPY)

	if not ignore_defender_ability and eff > 0.0 and eff <= 1.0 \
			and AbilityRuntime.blocks_unless_super_effective(defender):
		eff = 0.0
		_note_def(result, AbilityId.Id.WONDER_GUARD)

	result.effectiveness = eff
	if eff <= 0.0:
		result.damage = 0
		return result

	var crit_stage: int = move.crit_stage
	if attacker.focus_energy:
		crit_stage += 2
	if AbilityRuntime.has(attacker, AbilityId.Id.SUPER_LUCK):
		crit_stage += 1
		_note_atk(result, AbilityId.Id.SUPER_LUCK)

	var crit_rate: float = 1.0 / 16.0
	match clampi(crit_stage, 0, 3):
		1: crit_rate = 1.0 / 8.0
		2: crit_rate = 1.0 / 2.0
		3: crit_rate = 1.0
	if move.always_critical or AbilityRuntime.always_crits(attacker, defender):
		crit_rate = 1.0
	if not ignore_defender_ability and AbilityRuntime.blocks_critical(defender):
		crit_rate = 0.0
		_note_def(result, AbilityRuntime.get_id(defender))
	result.critical = randf() < crit_rate
	var crit_mult: float = 1.0
	if result.critical:
		crit_mult = AbilityRuntime.crit_damage_multiplier(attacker)
		if AbilityRuntime.has(attacker, AbilityId.Id.SNIPER):
			_note_atk(result, AbilityId.Id.SNIPER)

	var random: float = randf_range(0.85, 1.0)
	var damage: int = int(floor(base * stab * eff * crit_mult * random))

	if screen_active and not result.critical:
		damage = int(round(float(damage) * 0.5))

	var tinted: float = AbilityRuntime.attacker_damage_multiplier(attacker, eff, result.critical)
	if tinted != 1.0:
		_note_atk(result, AbilityId.Id.TINTED_LENS)
	damage = int(round(float(damage) * tinted))

	var riv: float = AbilityRuntime.rivalry_multiplier(attacker, defender)
	if riv != 1.0:
		_note_atk(result, AbilityId.Id.RIVALRY)
	damage = int(round(float(damage) * riv))

	var stake: float = AbilityRuntime.stakeout_multiplier(attacker, defender)
	if stake != 1.0:
		_note_atk(result, AbilityId.Id.STAKEOUT)
	damage = int(round(float(damage) * stake))

	if not ignore_defender_ability:
		var taken: float = AbilityRuntime.damage_taken_multiplier(defender, move, eff)
		if taken != 1.0:
			_note_def(result, AbilityRuntime.get_id(defender))
		damage = int(round(float(damage) * taken))

	result.damage = maxi(damage, 1)

	if not ignore_defender_ability and AbilityRuntime.should_survive_with_sturdy(defender, result.damage):
		result.damage = defender.pokemon.current_hp - 1
		result.sturdy_activated = true

	return result

## Mantiene compatibilidad: comprueba accuracy Y calcula el primer golpe.
static func calculate(
	attacker: BattleBattler,
	defender: BattleBattler,
	move: MoveData,
	weather: int = AbilityBattleEffect.weatherAbilityID.WEATHER_NONE,
	screen_active: bool = false
) -> HitResult:
	var result: HitResult = HitResult.new()
	if move == null or attacker == null or defender == null:
		return result

	if move.category == MoveStruct.DamageCategory.STATUS or move.power <= 0:
		result.is_status = true
		result.hit = check_hit(move, attacker, defender)
		result.damage = 0
		return result

	if not check_hit(move, attacker, defender):
		result.hit = false
		return result

	return compute_hit(attacker, defender, move, weather, screen_active)
