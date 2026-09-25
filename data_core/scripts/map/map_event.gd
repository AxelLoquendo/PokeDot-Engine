@tool
extends Node2D
class_name MapEvent

## Evento de casilla al estilo pokeemerald (sin Object/NPC).
## Colócalo como hijo del mapa y ajústalo en el inspector.

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


func _ready() -> void:
	add_to_group("map_events")
	z_index = 100
	if Engine.is_editor_hint():
		queue_redraw()


func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		queue_redraw()


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
