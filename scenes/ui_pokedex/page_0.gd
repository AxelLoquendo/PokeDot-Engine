extends Node2D
class_name PokedexPageInfo

@onready var sprite_front: Sprite2D = $Front
@onready var label_dex: Label = $Dex_number
@onready var label_name: Label = $Name_Specie
@onready var label_category: Label = $Category_Name
@onready var label_altura: Label = $Altura/Altura_number
@onready var label_peso: Label = $Peso/Peso_number
@onready var label_desc: Label = $Specie_Description
@onready var status: Sprite2D = $Status
@onready var type_1: Sprite2D = $Tipos/Type_1
@onready var type_2: Sprite2D = $Tipos/Type_2

@export var icon_own: Texture2D
@export var icon_seen: Texture2D

var _species: PokemonDataStruct = null
var _owned: bool = false


func setup(species: PokemonDataStruct, owned: bool = false) -> void:
	_species = species
	_owned = owned
	if _species == null:
		return
	_actualizar_ui()


func _actualizar_ui() -> void:
	if sprite_front:
		sprite_front.texture = _species.front_sprite

	if label_dex:
		label_dex.text = "%04d" % _species.national_dex_number

	if label_name:
		label_name.text = _species.species_name

	if label_category:
		# "Pokémon Semilla" / category_name
		var cat: String = _species.category_name
		if not cat.is_empty() and not cat.contains("Pokémon"):
			cat = "Pokémon " + cat
		label_category.text = cat

	# height/weight en tus datos suelen ser decímetros / hectogramos (estilo games)
	if label_altura:
		label_altura.text = _format_height(_species.height)
	if label_peso:
		label_peso.text = _format_weight(_species.weight)

	if label_desc:
		label_desc.text = _species.description

	if status:
		if _owned and icon_own:
			status.texture = icon_own
			status.visible = true
		elif icon_seen:
			status.texture = icon_seen
			status.visible = true
		else:
			status.visible = false

	_actualizar_tipos()


func _actualizar_tipos() -> void:
	var icon1: Texture2D = TypeIconsDb.get_icon(_species.type_1)
	if type_1:
		type_1.texture = icon1
		type_1.visible = icon1 != null

	var icon2: Texture2D = null
	if _species.type_2 != PokemonData.Type.TYPE_NONE:
		icon2 = TypeIconsDb.get_icon(_species.type_2)
	if type_2:
		type_2.texture = icon2
		type_2.visible = icon2 != null


func _format_height(raw: int) -> String:
	# raw en decímetros → metros (ej. 7 → 0.7 m)
	var meters: float = float(raw) / 10.0
	return "%.1f m" % meters


func _format_weight(raw: int) -> String:
	# raw en hectogramos → kg (ej. 69 → 6.9 kg)
	var kg: float = float(raw) / 10.0
	return "%.1f kg" % kg
