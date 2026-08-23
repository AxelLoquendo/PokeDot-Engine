extends Node

var type_icons: TypeIcons

func _ready() -> void:
	type_icons = load("res://data_core/pokemon/type_icons.tres") as TypeIcons
	if type_icons == null:
		push_error("No se cargó type_icons.tres")
		return

func get_icon(type: PokemonData.Type) -> Texture2D:
	return type_icons.get_icon(type) if type_icons else null

func get_tera_icon(type: PokemonData.Type) -> Texture2D:
	return type_icons.get_tera_icon(type) if type_icons else null
