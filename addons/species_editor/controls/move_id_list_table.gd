@tool
extends PanelContainer

class_name MoveIdListTable

signal changed

const MOVE_SELECTOR_SCRIPT := preload("res://addons/species_editor/controls/move_selector.gd")

var move_ids: Array[Moves.MoveId] = []
var available_moves: Array[MoveData] = []
var table: VBoxContainer

func load_moves(values: Array[Moves.MoveId]) -> void:
	move_ids = values.duplicate()
	if table != null:
		_refresh()

func _ready() -> void:
	table = VBoxContainer.new()
	table.add_theme_constant_override("separation", 3)
	add_child(table)
	_refresh()

func _refresh() -> void:
	if table == null:
		return
	for child: Node in table.get_children():
		child.queue_free()
	for index: int in range(move_ids.size()):
		var row: HBoxContainer = HBoxContainer.new()
		var selector: MoveSelector = MOVE_SELECTOR_SCRIPT.new()
		selector.available_moves = available_moves
		selector.selected_move = move_ids[index]
		selector.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		selector.move_changed.connect(_on_move_changed.bind(index, selector))
		row.add_child(selector)
		var remove: Button = Button.new()
		remove.text = "✕"
		remove.pressed.connect(_on_remove.bind(index))
		row.add_child(remove)
		table.add_child(row)
	var add: Button = Button.new()
	add.text = "+ Añadir movimiento"
	add.pressed.connect(_on_add)
	table.add_child(add)

func _on_add() -> void:
	move_ids.append(Moves.MoveId.MOVE_TACKLE)
	_refresh()
	changed.emit()

func _on_remove(index: int) -> void:
	if index < 0 or index >= move_ids.size():
		return
	move_ids.remove_at(index)
	_refresh()
	changed.emit()

func _on_move_changed(index: int, selector: MoveSelector) -> void:
	if index < 0 or index >= move_ids.size():
		return
	move_ids[index] = selector.selected_move
	changed.emit()

func get_moves() -> Array[Moves.MoveId]:
	return move_ids.duplicate()
