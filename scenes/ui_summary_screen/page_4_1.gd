extends Node2D

class_name SummaryPageMoveDetail

@onready var Cursor: Sprite2D = $Cursor_box
@onready var move_detail_panel: Sprite2D = $Move_Detail
@onready var PkmnIcon: Sprite2D = $Move_Detail/Icon
@onready var Category: Sprite2D = $Move_Detail/Category/Category_sprite
@onready var Power: Label = $Move_Detail/Power/Power_Number
@onready var Presision: Label = $Move_Detail/Presision/Percent
@onready var move_description: Label = $Move_Detail/Move_Description

const CATEGORY_ICONS: Dictionary = {
	MoveStruct.DamageCategory.PHYSICAL: preload("res://graphics/ui_summary_screen/physical.png"),
	MoveStruct.DamageCategory.SPECIAL: preload("res://graphics/ui_summary_screen/special.png"),
	MoveStruct.DamageCategory.STATUS: preload("res://graphics/ui_summary_screen/status.png"),
}

## Posición Y (local) del cursor para cada fila de movimiento.
## Ajusta estos 4 números en el Inspector si no calzan con tus filas.
@export var row_positions_y: PackedFloat32Array = [106.0, 166.0, 226.0, 286.0]


func setup(move_data: MoveData, pokemon: PokemonInstance) -> void:
	var species: PokemonDataStruct = pokemon.get_species() if pokemon != null else null
	PkmnIcon.texture = species.icon_sprite if species != null else null

	if move_data == null:
		Category.texture = null
		Power.text = "---"
		Presision.text = "---"
		move_description.text = ""
		return

	Category.texture = CATEGORY_ICONS.get(move_data.category)

	Power.text = str(move_data.power) if move_data.power > 0 else "---"
	Presision.text = "---" if move_data.always_hits or move_data.accuracy <= 0 else "%d%%" % move_data.accuracy

	move_description.text = move_data.description


func set_cursor_index(index: int) -> void:
	if index < 0 or index >= row_positions_y.size():
		return
	Cursor.position.y = row_positions_y[index]


## view_mode viene de SummaryPageMove.ViewMode: BROWSE = oculto, DETAIL = frame 0, SWAP = frame 1.
func set_cursor_state(view_mode: int) -> void:
	Cursor.visible = view_mode != SummaryPageMove.ViewMode.BROWSE
	Cursor.frame = 1 if view_mode == SummaryPageMove.ViewMode.SWAP else 0


func set_detail_visible(value: bool) -> void:
	move_detail_panel.visible = value
