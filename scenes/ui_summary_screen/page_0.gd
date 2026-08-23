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
	_actualizar_experiencia()
	# OT / ID los puedes dejar vacíos hasta tener trainer data en la instancia


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
	if number_exp:
		number_exp.text = str(pokemon.experience)
	if number_next_lvl:
		# Placeholder hasta tener curva de exp
		number_next_lvl.text = "—"


func _actualizar_ot() -> void:
	if ot_name:
		ot_name.text = "??????"


func _actualizar_id() -> void:
	if id_number:
		id_number.text = "00000"
