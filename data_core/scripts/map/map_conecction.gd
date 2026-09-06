@tool
extends Resource
class_name MapConnection

signal connection_changed

@export var target_section: MapSection.SectionId = MapSection.SectionId.MAPSEC_NONE:
	set(value):
		target_section = value
		connection_changed.emit()

@export var offset: Vector2i = Vector2i.ZERO:
	set(value):
		offset = value
		connection_changed.emit()

@export var connection_size: Vector2i = Vector2i.ZERO:
	set(value):
		connection_size = value
		connection_changed.emit()

@export var entrada: Vector2i = Vector2i.ZERO


func get_scene_path() -> String:
	return str(MapSection.SECTION_TO_SCENE.get(target_section, ""))


func get_scene() -> PackedScene:
	var ruta: String = get_scene_path()
	if ruta.is_empty():
		return null
	return load(ruta) as PackedScene


func obtener_posicion_entrada() -> Vector2:
	return Vector2(entrada.x * 16.0 + 8.0, entrada.y * 16.0)


func contiene_casilla(casilla: Vector2i) -> bool:
	return (
		casilla.x >= offset.x
		and casilla.y >= offset.y
		and casilla.x < offset.x + connection_size.x
		and casilla.y < offset.y + connection_size.y
	)


func contiene_conexion(
	celda: Vector2i,
	direccion: MapAttributes.ConnectionDirection,
	tamano_mapa: Vector2i
) -> bool:
	match direccion:
		MapAttributes.ConnectionDirection.SOUTH:
			return (
				celda.y >= tamano_mapa.y
				and celda.x >= offset.x
				and celda.x < offset.x + connection_size.x
			)
		MapAttributes.ConnectionDirection.NORTH:
			return (
				celda.y < 0
				and celda.x >= offset.x
				and celda.x < offset.x + connection_size.x
			)
		MapAttributes.ConnectionDirection.EAST:
			return (
				celda.x >= tamano_mapa.x
				and celda.y >= offset.y
				and celda.y < offset.y + connection_size.y
			)
		MapAttributes.ConnectionDirection.WEST:
			return (
				celda.x < 0
				and celda.y >= offset.y
				and celda.y < offset.y + connection_size.y
			)
	return false
