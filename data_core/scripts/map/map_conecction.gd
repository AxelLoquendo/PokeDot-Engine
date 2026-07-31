@tool
extends Resource
class_name MapConnection

signal connection_changed

@export var target_section: MapSection.SectionId:
	set(value):
		target_section = value
		connection_changed.emit()

@export var offset: Vector2i:
	set(value):
		offset = value
		connection_changed.emit()

@export var entrada: Vector2i = Vector2i.ZERO

func get_scene_path() -> String:
	return MapSection.SECTION_TO_SCENE.get(target_section, "")

func get_scene() -> PackedScene:
	var ruta: String = get_scene_path()

	if ruta.is_empty():
		return null

	return load(ruta)

func obtener_posicion_entrada() -> Vector2:
	return Vector2(
		entrada.x * 16 + 8,
		entrada.y * 16
	)
