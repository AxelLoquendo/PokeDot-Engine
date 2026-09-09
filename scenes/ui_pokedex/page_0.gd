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


func apply_form_display(form_data: Dictionary) -> void:
	if form_data.is_empty() or _species == null:
		return

	if sprite_front and form_data.get("front"):
		sprite_front.texture = form_data["front"] as Texture2D

	if label_name:
		var form_name: String = str(form_data.get("name", ""))
		if form_name != "" and form_name != "Normal":
			label_name.text = _species.species_name

	if label_category and form_data.has("category_name"):
		var cat: String = str(form_data["category_name"])
		if not cat.is_empty() and not cat.contains("Pokémon"):
			cat = "Pokémon " + cat
		label_category.text = cat

	if label_desc and form_data.has("description"):
		label_desc.text = str(form_data["description"])

	if label_altura and form_data.has("height"):
		label_altura.text = _format_height(int(form_data["height"]))
	if label_peso and form_data.has("weight"):
		label_peso.text = _format_weight(int(form_data["weight"]))

	if form_data.has("type_1"):
		var t1: PokemonData.Type = form_data["type_1"] as PokemonData.Type
		var icon1: Texture2D = TypeIconsDb.get_icon(t1)
		if type_1:
			type_1.texture = icon1
			type_1.visible = icon1 != null

	if form_data.has("type_2"):
		var t2: PokemonData.Type = form_data["type_2"] as PokemonData.Type
		var icon2: Texture2D = null
		if t2 != PokemonData.Type.TYPE_NONE:
			icon2 = TypeIconsDb.get_icon(t2)
		if type_2:
			type_2.texture = icon2
			type_2.visible = icon2 != null


func _actualizar_ui() -> void:
	if sprite_front:
		sprite_front.texture = _species.front_sprite

	if label_dex:
		label_dex.text = "%04d" % _species.national_dex_number

	if label_name:
		label_name.text = _species.species_name

	if label_category:
		var cat: String = _species.category_name
		if not cat.is_empty() and not cat.contains("Pokémon"):
			cat = "Pokémon " + cat
		label_category.text = cat

	if label_altura:
		label_altura.text = _format_height(_species.height)
	if label_peso:
		label_peso.text = _format_weight(_species.weight)

	if label_desc:
		label_desc.text = _species.description

	if status:
		if _owned:
			if icon_own == null:
				icon_own = load("res://graphics/ui_pokedex/icon_own.png") as Texture2D
			status.texture = icon_own
			status.visible = icon_own != null
		else:
			if icon_seen == null:
				icon_seen = load("res://graphics/ui_pokedex/icon_seen.png") as Texture2D
			status.texture = icon_seen
			status.visible = icon_seen != null

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
	return "%.1f m" % (float(raw) / 10.0)


func _format_weight(raw: int) -> String:
	return "%.1f kg" % (float(raw) / 10.0)
