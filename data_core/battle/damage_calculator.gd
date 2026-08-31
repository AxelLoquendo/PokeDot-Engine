extends RefCounted
class_name DamageCalculator

class HitResult:
	var hit: bool = false
	var damage: int = 0
	var effectiveness: float = 1.0
	var critical: bool = false
	var is_status: bool = false


static func check_hit(move: MoveData, attacker: BattleBattler, defender: BattleBattler) -> bool:
	if move == null:
		return false
	if move.always_hits:
		return true
	if move.accuracy <= 0:
		return true

	var acc: int = clampi(move.accuracy, 1, 100)
	var acc_stage: int = clampi(attacker.stage_accuracy - defender.stage_evasion, -6, 6)
	var stage_mult: float = BattleBattler._stage_multiplier(acc_stage)
	var final_acc: int = clampi(int(round(float(acc) * stage_mult)), 1, 100)
	return randi_range(1, 100) <= final_acc


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


## Calcula el daño de UN golpe, asumiendo que ya se comprobó que acierta.
## Independiente de accuracy: útil para golpes sucesivos de un multi-hit.
static func compute_hit(attacker: BattleBattler, defender: BattleBattler, move: MoveData) -> HitResult:
	var result: HitResult = HitResult.new()
	if move == null or attacker == null or defender == null:
		return result

	result.hit = true

	var level: int = attacker.pokemon.level
	var power: int = maxi(move.power, 1)

	var atk: int
	var def: int
	if move.category == MoveStruct.DamageCategory.PHYSICAL:
		atk = attacker.get_effective_stat(PokemonInstance.Stat.ATTACK)
		def = defender.get_effective_stat(PokemonInstance.Stat.DEFENSE)
		if attacker.pokemon.status == PokemonInstance.Status.BURN:
			@warning_ignore("integer_division")
			atk = maxi(1, atk / 2)
	else:
		atk = attacker.get_effective_stat(PokemonInstance.Stat.SP_ATTACK)
		def = defender.get_effective_stat(PokemonInstance.Stat.SP_DEFENSE)

	def = maxi(def, 1)

	var base: float = ((2.0 * float(level) / 5.0 + 2.0) * float(power) * float(atk) / float(def)) / 50.0 + 2.0

	var stab: float = 1.0
	var t1: PokemonData.Type = attacker.pokemon.get_type_1()
	var t2: PokemonData.Type = attacker.pokemon.get_type_2()
	if move.type == t1 or (t2 != PokemonData.Type.TYPE_NONE and move.type == t2):
		stab = 1.5

	var eff: float = TypeChart.get_effectiveness(
		move.type,
		defender.pokemon.get_type_1(),
		defender.pokemon.get_type_2()
	)
	result.effectiveness = eff

	if eff <= 0.0:
		result.damage = 0
		return result

	var crit_rate: float = 1.0 / 16.0
	# crit_stage del movimiento sube la probabilidad (tabla clásica: 1/24, 1/8, 1/2, 1/1 para stage 0-3+)
	match clampi(move.crit_stage, 0, 3):
		1: crit_rate = 1.0 / 8.0
		2: crit_rate = 1.0 / 2.0
		3: crit_rate = 1.0
	if move.always_critical:
		crit_rate = 1.0
	result.critical = randf() < crit_rate
	var crit_mult: float = 1.5 if result.critical else 1.0

	var random: float = randf_range(0.85, 1.0)
	var damage: int = int(floor(base * stab * eff * crit_mult * random))
	result.damage = maxi(damage, 1)
	return result


## Mantiene compatibilidad: comprueba accuracy Y calcula el primer golpe.
static func calculate(attacker: BattleBattler, defender: BattleBattler, move: MoveData) -> HitResult:
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

	return compute_hit(attacker, defender, move)
