@tool
extends Node2D
class_name MapEvent

## Evento de casilla al estilo pokeemerald (sin Object/NPC).
## Colócalo como hijo del mapa y ajústalo en el inspector.
## En el editor, la posición se ajusta sola a la cuadrícula 16×16.

enum Kind {
	WARP,   ## Al pisar → teletransporte
	COORD,  ## Al pisar → script si se cumple la condición
	BG,     ## Al pulsar A mirando la casilla → cartel / objeto oculto
}

enum BgKind {
	SIGN,
	HIDDEN_ITEM,
}

const TILE_SIZE: int = 16

@export var kind: Kind = Kind.COORD
@export var elevation: int = 0
## Si true, se dibuja el rectángulo en el editor.
@export var show_debug: bool = true

@export_group("Warp")
## Nombre MAPSEC_* como en ScriptCmdWarp (ej. MAPSEC_PETALBURG_CITY).
@export var dest_map: String = ""
@export var dest_tile: Vector2i = Vector2i.ZERO
@export_range(0.05, 5.0, 0.05) var warp_fade_duration: float = 0.5
## Marca centros / puntos de cura para Escape Rope (futuro).
@export var is_heal_point: bool = false

@export_group("Coord / BG script")
@export var condition_flag: StringName = &""
@export var expected_value: String = "true"
@export_file("*.txt") var script_file: String = ""

@export_group("BG")
@export var bg_kind: BgKind = BgKind.SIGN
@export var hidden_item_id: Items.ItemId = Items.ItemId.ITEM_NONE
@export var hidden_item_flag: StringName = &""

var _snap_lock: bool = false


func _ready() -> void:
	add_to_group("map_events")
	z_index = 100
	if Engine.is_editor_hint():
		set_notify_transform(true)
		_snap_to_tile_grid()
		queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSFORM_CHANGED and Engine.is_editor_hint():
		_snap_to_tile_grid()


func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		queue_redraw()


func _snap_to_tile_grid() -> void:
	if _snap_lock:
		return
	# Origen arriba-izquierda del tile (coincide con get_tile y el rect de debug).
	var snapped_pos: Vector2 = Vector2(
		floorf(position.x / float(TILE_SIZE)) * float(TILE_SIZE),
		floorf(position.y / float(TILE_SIZE)) * float(TILE_SIZE)
	)
	if position != snapped_pos:
		_snap_lock = true
		position = snapped_pos
		_snap_lock = false


func _draw() -> void:
	if not Engine.is_editor_hint() and not show_debug:
		return
	if not show_debug:
		return
	var color: Color
	match kind:
		Kind.WARP:
			color = Color(0.2, 0.6, 1.0, 0.35)
		Kind.COORD:
			color = Color(0.85, 0.25, 0.95, 0.35)
		Kind.BG:
			color = Color(1.0, 0.85, 0.2, 0.35)
	draw_rect(Rect2(Vector2.ZERO, Vector2(TILE_SIZE, TILE_SIZE)), color)


func get_tile() -> Vector2i:
	return Vector2i(
		int(floor(global_position.x / float(TILE_SIZE))),
		int(floor(global_position.y / float(TILE_SIZE)))
	)


func condition_ok() -> bool:
	if condition_flag.is_empty():
		return true
	var valor: Variant = ScriptExecutionContext.global_flags.get(condition_flag, false)
	return str(valor).to_lower() == expected_value.to_lower()


func is_hidden_item_taken() -> bool:
	if hidden_item_flag.is_empty():
		return false
	return bool(ScriptExecutionContext.global_flags.get(hidden_item_flag, false))
