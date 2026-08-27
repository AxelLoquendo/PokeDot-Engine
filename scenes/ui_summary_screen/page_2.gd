extends Node2D
class_name SummaryPageSkills


var pokemon: PokemonInstance = null


@onready var number_hp: Label = $Skills_1/HP/Number_Hp
@onready var hp_bar: ColorRect = $Skills_1/HP/Hp_Bar

@onready var number_attack: Label = $Skills_1/Attack/Number_Attack
@onready var number_defense: Label = $Skills_1/Defense/Number_Defense
@onready var number_sp_attack: Label = $Skills_1/SP_Attack/Number_Sp_Attack
@onready var number_sp_defense: Label = $Skills_1/SP_Defense/Number_Sp_Defense
@onready var number_speed: Label = $Skills_1/Speed/Number_Speed

@onready var ability_name: Label = $Skills_1/Ability/Ability_Name
@onready var ability_description: Label = $Skills_1/Ability/Ability_Description


const HP_BAR_MAX_WIDTH: float = 96.0


func setup(nuevo_pokemon: PokemonInstance) -> void:
	pokemon = nuevo_pokemon

	if pokemon == null:
		return

	_actualizar_ui()


func _actualizar_ui() -> void:
	_actualizar_hp()
	_actualizar_estadisticas()
	_actualizar_habilidad()


func _actualizar_hp() -> void:
	if pokemon == null:
		return

	if number_hp:
		number_hp.text = "%d/%d" % [
			pokemon.current_hp,
			pokemon.max_hp
		]

	if hp_bar:
		var porcentaje: float = pokemon.get_hp_percent()
		hp_bar.size.x = HP_BAR_MAX_WIDTH * porcentaje


func _actualizar_estadisticas() -> void:
	if pokemon == null:
		return

	if number_attack:
		number_attack.text = str(
			_obtener_stat(PokemonInstance.Stat.ATTACK)
		)

	if number_defense:
		number_defense.text = str(
			_obtener_stat(PokemonInstance.Stat.DEFENSE)
		)

	if number_sp_attack:
		number_sp_attack.text = str(
			_obtener_stat(PokemonInstance.Stat.SP_ATTACK)
		)

	if number_sp_defense:
		number_sp_defense.text = str(
			_obtener_stat(PokemonInstance.Stat.SP_DEFENSE)
		)

	if number_speed:
		number_speed.text = str(
			_obtener_stat(PokemonInstance.Stat.SPEED)
		)


func _obtener_stat(stat: PokemonInstance.Stat) -> int:
	var stat_index: int = int(stat)

	if stat_index < 0:
		return 0

	if stat_index >= pokemon.stats.size():
		return 0

	return pokemon.stats[stat_index]


func _actualizar_habilidad() -> void:
	if pokemon == null:
		return

	if ability_name:
		ability_name.text = "---"

	if ability_description:
		ability_description.text = "Sin descripción"

	if pokemon.ability_id == AbilityId.Id.NONE:
		return

	var ability_data: AbilityData = (
		AbilityDatabase.get_ability(pokemon.ability_id)
	)

	if ability_data == null:
		return

	if ability_name:
		ability_name.text = AbilityDatabase.get_ability_name(
			pokemon.ability_id
		)

	if ability_description:
		if not ability_data.description_key.is_empty():
			ability_description.text = tr(
				ability_data.description_key
			)
		else:
			ability_description.text = "Sin descripción"
