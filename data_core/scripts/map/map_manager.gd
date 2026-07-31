extends Node
class_name MapManager


var current_map: MapAttributes
var jugador: CharacterController

func load_map(map: MapAttributes) -> void:

	current_map = map
