extends TileMapLayer

class_name TileBehaviourLayer


func _ready() -> void:
	add_to_group("tile_behaviour")


func comprobar_casilla(casilla: Vector2i, personaje: CharacterController, direccion: Vector2) -> bool:

	var tile_data: TileData = get_cell_tile_data(casilla)

	if tile_data == null:
		return false

	if not tile_data.has_custom_data("behaviour"):
		return false

	var comportamiento: String = str(tile_data.get_custom_data("behaviour"))

	return TileBehavioursManager.ejecutar_comportamiento(comportamiento, personaje, tile_data, casilla, direccion)
