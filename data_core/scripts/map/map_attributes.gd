@tool
extends Node2D
class_name MapAttributes

@export var map_name: String = "Sin nombre"
@export var map_id_section: MapSection.SectionId = MapSection.SectionId.MAPSEC_NONE
@export var map_region: MapSection.RegionId = MapSection.RegionId.REGION_NONE
@export var map_size: Vector2i = Vector2i(40, 40):
	set(new_val):
		map_size = new_val
		queue_redraw()

@export var color_borde: Color = Color(0, 1, 1, 1.0)
@export var tile_size: int = 16

@export var mostrar_limite: bool = true:
	set(new_val):
		mostrar_limite = new_val
		queue_redraw()

@export var is_indoor: bool = false
@export var allow_escape_rope: bool = false
@export var allow_fly: bool = false

@export var north_map: MapConnection = null
@export var east_map: MapConnection = null
@export var south_map: MapConnection = null
@export var west_map: MapConnection = null

@export_file("*.ogg", "*.wav", "*.mp3") var music_path: String = ""
@export var silence_end: float = 0.0


func _ready() -> void:
	if not Engine.is_editor_hint() and not music_path.is_empty():
		MusicManager.reproducir(music_path, silence_end)


func _draw() -> void:
	if not Engine.is_editor_hint() or not mostrar_limite:
		return
	if map_size.x <= 0 or map_size.y <= 0:
		return
	
	var ancho: float = map_size.x * tile_size
	var alto: float = map_size.y * tile_size
	
	draw_line(Vector2.ZERO, Vector2(ancho, 0), color_borde, 2.0)
	draw_line(Vector2(ancho, 0), Vector2(ancho, alto), color_borde, 2.0)
	draw_line(Vector2(ancho, alto), Vector2(0, alto), color_borde, 2.0)
	draw_line(Vector2(0, alto), Vector2.ZERO, color_borde, 2.0)


func esta_dentro_limites(casilla: Vector2i) -> bool:
	return casilla.x >= 0 and casilla.x < map_size.x and casilla.y >= 0 and casilla.y < map_size.y
