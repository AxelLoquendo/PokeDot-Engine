extends Resource
class_name TypeIcons

## Índice = PokemonData.Type
@export var icons: Array[Texture2D] = []
@export var tera_icons: Array[Texture2D] = []


func get_icon(type: PokemonData.Type) -> Texture2D:
	return _get_from_array(icons, type)


func get_tera_icon(type: PokemonData.Type) -> Texture2D:
	return _get_from_array(tera_icons, type)


func has_icon(type: PokemonData.Type) -> bool:
	return get_icon(type) != null


func has_tera_icon(type: PokemonData.Type) -> bool:
	return get_tera_icon(type) != null


func _get_from_array(array: Array[Texture2D], type: PokemonData.Type) -> Texture2D:
	var index: int = int(type)
	if index <= int(PokemonData.Type.TYPE_NONE):
		return null
	if index >= array.size():
		return null
	return array[index]
