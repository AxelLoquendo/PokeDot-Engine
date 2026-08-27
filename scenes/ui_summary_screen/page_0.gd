extends Node2D
class_name SummaryPageInfo

var pokemon: PokemonInstance = null

@onready var title: Label = $Info/Title
@onready var dex_number: Label = $Info_2/Dex/Number_Dex
@onready var specie_name: Label = $Info_2/Specie/Specie_Name
@onready var tera_type: Sprite2D = $Info_2/Type/Tera_Type
@onready var type_1: Sprite2D = $Info_2/Type/Type_Icon_1
@onready var type_2: Sprite2D = $Info_2/Type/Type_Icon_2
@onready var ot_name: Label = $Info_2/OT/OT_Name
@onready var id_number: Label = $Info_2/ID/ID_Number
@onready var number_exp: Label = $Info_2/Exp_Point/Number_Exp
@onready var number_next_lvl: Label = $Info_2/Next_Lvl/Number_lvl
@onready var exp_bar: ColorRect = $Info_2/Next_Lvl/Exp_Bar

const EXP_BAR_MAX_WIDTH: float = 132.0

func setup(nuevo_pokemon: PokemonInstance) -> void:
	pokemon = nuevo_pokemon
	if pokemon == null:
		return
	_actualizar_ui()


func _actualizar_ui() -> void:
	_actualizar_dex()
	_actualizar_especie()
	_actualizar_tipos()
	_actualizar_tera()
	_actualizar_ot()
	_actualizar_id()
	_actualizar_experiencia()


func _actualizar_dex() -> void:
	if dex_number == null:
		return
	var species: PokemonDataStruct = pokemon.get_species()
	if species == null:
		dex_number.text = "---"
		return
	dex_number.text = "%04d" % species.national_dex_number


func _actualizar_especie() -> void:
	if specie_name == null:
		return
	var species: PokemonDataStruct = pokemon.get_species()
	if species == null:
		specie_name.text = "???"
		return
	specie_name.text = species.species_name


func _actualizar_tipos() -> void:
	var species: PokemonDataStruct = pokemon.get_species()
	if species == null:
		if type_1: type_1.visible = false
		if type_2: type_2.visible = false
		return

	# Tipo 1
	var icon1: Texture2D = TypeIconsDb.get_icon(species.type_1)
	if type_1:
		type_1.texture = icon1
		type_1.visible = icon1 != null

	# Tipo 2
	var icon2: Texture2D = null
	if species.type_2 != PokemonData.Type.TYPE_NONE:
		icon2 = TypeIconsDb.get_icon(species.type_2)
	if type_2:
		type_2.texture = icon2
		type_2.visible = icon2 != null

func _actualizar_tera() -> void:
	if tera_type == null or pokemon == null:
		if tera_type:
			tera_type.visible = false
		return

	var icon: Texture2D = TypeIconsDb.get_tera_icon(pokemon.tera_type)
	tera_type.texture = icon
	tera_type.visible = icon != null

func _actualizar_experiencia() -> void:
	if pokemon == null:
		return

	if number_exp:
		number_exp.text = str(pokemon.experience)

	if number_next_lvl == null:
		return

	var species: PokemonDataStruct = pokemon.get_species()

	if species == null:
		number_next_lvl.text = "---"
		_actualizar_barra_exp(0.0)
		return

	if pokemon.level >= ExperienceSystem.MAX_LEVEL:
		number_next_lvl.text = "MAX"
		_actualizar_barra_exp(1.0)
		return

	var experiencia_nivel_actual: int = (
		ExperienceSystem.get_total_exp_for_level(
			pokemon.level,
			species.growth_rate
		)
	)

	var experiencia_siguiente_nivel: int = (
		ExperienceSystem.get_total_exp_for_level(
			pokemon.level + 1,
			species.growth_rate
		)
	)

	var experiencia_del_nivel: int = (
		experiencia_siguiente_nivel
		- experiencia_nivel_actual
	)

	var experiencia_obtenida: int = (
		pokemon.experience
		- experiencia_nivel_actual
	)

	var progreso: float = 0.0

	if experiencia_del_nivel > 0:
		progreso = float(experiencia_obtenida) / float(experiencia_del_nivel)

	progreso = clampf(progreso, 0.0, 1.0)

	var experiencia_faltante: int = maxi(
		experiencia_siguiente_nivel - pokemon.experience,
		0
	)

	number_next_lvl.text = str(experiencia_faltante)

	_actualizar_barra_exp(progreso)

func _actualizar_barra_exp(progreso: float) -> void:
	if exp_bar == null:
		return

	progreso = clampf(progreso, 0.0, 1.0)

	exp_bar.size.x = EXP_BAR_MAX_WIDTH * progreso

func _actualizar_ot() -> void:
	if ot_name == null:
		return

	var datos_entrenador: CharacterPlayer = _obtener_datos_entrenador()

	if datos_entrenador == null:
		ot_name.text = "---"
		return

	ot_name.text = datos_entrenador.name

func _actualizar_id() -> void:
	if id_number == null:
		return

	var datos_entrenador: CharacterPlayer = _obtener_datos_entrenador()

	if datos_entrenador == null:
		id_number.text = "00000"
		return

	id_number.text = "%05d" % datos_entrenador.trainer_id


func _obtener_datos_entrenador() -> CharacterPlayer:
	var jugador: CharacterController = (get_tree().get_first_node_in_group("player") as CharacterController)

	if jugador == null:
		return null

	return jugador.character_data as CharacterPlayer
