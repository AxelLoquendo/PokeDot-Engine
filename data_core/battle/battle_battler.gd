extends RefCounted
class_name BattleBattler

var pokemon: PokemonInstance
var is_player_side: bool = true

var stage_attack: int = 0
var stage_defense: int = 0
var stage_sp_attack: int = 0
var stage_sp_defense: int = 0
var stage_speed: int = 0
var stage_accuracy: int = 0
var stage_evasion: int = 0

var confusion_turns: int = 0
var flinched: bool = false

var protect_active: bool = false
var protect_kind: int = ProtectResolver.Kind.NONE
var endure_active: bool = false
var protect_counter: int = 0
var charging_move: MoveData = null
var charging_target: BattleBattler = null
var charging_slot_index: int = -1
var semi_invulnerable: bool = false
var must_recharge: bool = false
## Focus Energy aumenta dos niveles la probabilidad de golpe crítico.
var focus_energy: bool = false

## ─── Habilidades (ver ability_runtime.gd) ────────────────
## Si es false, la habilidad de este Pokémon no tiene ningún efecto
## en combate (p. ej. tras Gas Neutralizante / Mold Breaker, a futuro).
var ability_active: bool = true
## Se activa cuando Flash Fire absorbe un movimiento de Fuego; potencia
## un 50% sus propios movimientos de Fuego mientras siga en combate.
var flash_fire_boosted: bool = false

## Slow Start: 5 turnos con Atk/Spe a la mitad
var slow_start_turns: int = 0
## Unburden: se activa al perder el objeto en combate
var unburden_active: bool = false
## Truant: alterna turnos de inacción
var truant_skip_turn: bool = false
var just_switched_in: bool = false
## Color Change / Protean: tipo temporal en combate (-1 = sin override)
var battle_type_1: int = -1
var battle_type_2: int = -1

## Illusion: se ve como otro Pokémon del equipo hasta que reciba daño.
var illusion_active: bool = false
var illusion_species_id: int = -1          # species_id del mon disfraz
var illusion_nickname: String = ""
var illusion_gender: int = 0               # PokemonData.Gender
var illusion_shiny: bool = false
var illusion_form_id: int = 0

## Imposter: copia temporal del rival (Transform).
var is_transformed: bool = false
var transform_backup: Dictionary = {}      # para restaurar al salir si hace falta

func setup(p: PokemonInstance, player_side: bool) -> void:
	pokemon = p
	is_player_side = player_side
	_reset_stages()
	clear_illusion()
	is_transformed = false
	transform_backup.clear()

func clear_illusion() -> void:
	illusion_active = false
	illusion_species_id = -1
	illusion_nickname = ""
	illusion_gender = 0
	illusion_shiny = false
	illusion_form_id = 0

func _reset_stages() -> void:
	stage_attack = 0
	stage_defense = 0
	stage_sp_attack = 0
	stage_sp_defense = 0
	stage_speed = 0
	stage_accuracy = 0
	stage_evasion = 0
	confusion_turns = 0
	flinched = false
	ability_active = true
	flash_fire_boosted = false
	slow_start_turns = 0
	unburden_active = false
	truant_skip_turn = false
	just_switched_in = true
	battle_type_1 = -1
	battle_type_2 = -1
	protect_active = false
	protect_kind = ProtectResolver.Kind.NONE
	endure_active = false
	protect_counter = 0
	charging_move = null
	charging_target = null
	charging_slot_index = -1
	semi_invulnerable = false
	must_recharge = false
	focus_energy = false
	clear_illusion()
	is_transformed = false
	transform_backup.clear()

func is_fainted() -> bool:
	return pokemon == null or pokemon.current_hp <= 0


func get_current_hp() -> int:
	return pokemon.current_hp if pokemon else 0


func get_max_hp() -> int:
	return pokemon.max_hp if pokemon else 1


func apply_damage(amount: int) -> int:
	if pokemon == null or amount <= 0:
		return 0
	var before: int = pokemon.current_hp
	pokemon.apply_damage(amount)
	return before - pokemon.current_hp


func get_effective_stat(stat: PokemonInstance.Stat) -> int:
	if pokemon == null:
		return 1
	var base: int = maxi(pokemon.get_stat(stat), 1)
	var stage: int = 0
	match stat:
		PokemonInstance.Stat.ATTACK:
			stage = stage_attack
		PokemonInstance.Stat.DEFENSE:
			stage = stage_defense
		PokemonInstance.Stat.SP_ATTACK:
			stage = stage_sp_attack
		PokemonInstance.Stat.SP_DEFENSE:
			stage = stage_sp_defense
		PokemonInstance.Stat.SPEED:
			stage = stage_speed
		_:
			stage = 0
	var value: float = float(base) * _stage_multiplier(stage)

	# Slow Start: Atk y Spe a la mitad
	if slow_start_turns > 0:
		if stat == PokemonInstance.Stat.ATTACK or stat == PokemonInstance.Stat.SPEED:
			value *= 0.5

	if stat == PokemonInstance.Stat.DEFENSE:
		if AbilityRuntime.has(self, AbilityId.Id.MARVEL_SCALE) and pokemon.has_status():
			value *= 1.5

	# Velocidad por habilidades de clima / estado (el weather lo pasa el manager al ordenar)
	# Aquí solo Unburden / Quick Feet locales; Chlorophyll etc. vía AbilityRuntime.speed_multiplier
	if stat == PokemonInstance.Stat.SPEED:
		if AbilityRuntime.has(self, AbilityId.Id.QUICK_FEET) and pokemon.has_status():
			value *= 1.5
		if unburden_active and AbilityRuntime.has(self, AbilityId.Id.UNBURDEN):
			value *= 2.0

	return maxi(1, int(floor(value)))

static func _stage_multiplier(stage: int) -> float:
	stage = clampi(stage, -6, 6)
	if stage >= 0:
		return (2.0 + float(stage)) / 2.0
	return 2.0 / (2.0 - float(stage))


func consume_pp(slot_index: int) -> bool:
	if pokemon == null:
		return false
	if slot_index < 0 or slot_index >= pokemon.moves.size():
		return false
	var slot: PokemonMoveSlot = pokemon.moves[slot_index]
	if slot == null or slot.is_empty() or slot.current_pp <= 0:
		return false
	slot.current_pp -= 1
	return true



func get_battle_type_1() -> PokemonData.Type:
	if battle_type_1 >= 0:
		return battle_type_1 as PokemonData.Type
	return pokemon.get_type_1() if pokemon else PokemonData.Type.TYPE_NONE


func get_battle_type_2() -> PokemonData.Type:
	if battle_type_1 >= 0:
		# Override activo: monotipo salvo que type_2 también esté seteado
		if battle_type_2 >= 0:
			return battle_type_2 as PokemonData.Type
		return PokemonData.Type.TYPE_NONE
	return pokemon.get_type_2() if pokemon else PokemonData.Type.TYPE_NONE


func set_battle_types(t1: PokemonData.Type, t2: PokemonData.Type = PokemonData.Type.TYPE_NONE) -> void:
	battle_type_1 = int(t1)
	battle_type_2 = int(t2) if t2 != PokemonData.Type.TYPE_NONE else -1

func get_display_name() -> String:
	if illusion_active and not illusion_nickname.is_empty():
		return illusion_nickname
	return pokemon.get_display_name() if pokemon else "???"

func get_visual_species_id() -> int:
	if illusion_active and illusion_species_id >= 0:
		return illusion_species_id
	if pokemon == null:
		return -1
	return pokemon.species_id

func get_visual_form_id() -> int:
	if illusion_active:
		return illusion_form_id
	if pokemon == null:
		return 0
	return pokemon.form_id if "form_id" in pokemon else 0

func is_confused() -> bool:
	return confusion_turns > 0


## Aplica un cambio de stage. Devuelve el cambio REAL (puede ser 0 si ya estaba al tope).
func modify_stage(stat: PokemonInstance.Stat, amount: int) -> int:
	var before: int
	match stat:
		PokemonInstance.Stat.ATTACK: before = stage_attack
		PokemonInstance.Stat.DEFENSE: before = stage_defense
		PokemonInstance.Stat.SP_ATTACK: before = stage_sp_attack
		PokemonInstance.Stat.SP_DEFENSE: before = stage_sp_defense
		PokemonInstance.Stat.SPEED: before = stage_speed
		_: before = 0
	var after: int = clampi(before + amount, -6, 6)
	match stat:
		PokemonInstance.Stat.ATTACK: stage_attack = after
		PokemonInstance.Stat.DEFENSE: stage_defense = after
		PokemonInstance.Stat.SP_ATTACK: stage_sp_attack = after
		PokemonInstance.Stat.SP_DEFENSE: stage_sp_defense = after
		PokemonInstance.Stat.SPEED: stage_speed = after
	return after - before


func modify_accuracy_stage(amount: int) -> int:
	var before: int = stage_accuracy
	stage_accuracy = clampi(before + amount, -6, 6)
	return stage_accuracy - before


func modify_evasion_stage(amount: int) -> int:
	var before: int = stage_evasion
	stage_evasion = clampi(before + amount, -6, 6)
	return stage_evasion - before
