@tool
extends PanelContainer

class_name LearnsetTable

signal changed

const MOVE_SELECTOR_SCRIPT := preload("res://addons/species_editor/controls/move_selector.gd")

var moves: Array[LevelUpMove] = []
var available_moves: Array[MoveData] = []
var table: GridContainer
var refresh_queued := false

func load_moves(moves_array: Array[LevelUpMove]) -> void:
	moves = moves_array.duplicate(true)
	if table != null:
		_request_refresh()

func _request_refresh() -> void:
	if refresh_queued:
		return
	refresh_queued = true
	call_deferred("_refresh_table_deferred")

func _refresh_table_deferred() -> void:
	refresh_queued = false
	_refresh_table()

func _ready() -> void:
	var container := VBoxContainer.new()
	container.add_theme_constant_override("separation", 4)
	add_child(container)

	var header := HBoxContainer.new()
	container.add_child(header)

	var title := Label.new()
	title.text = "Nivel | Movimiento | Acción"
	title.add_theme_color_override("font_color", Color.LIGHT_GRAY)
	header.add_child(title)
	header.add_spacer(false)

	var add_button := Button.new()
	add_button.text = "+ Añadir"
	add_button.pressed.connect(_on_add_move_pressed)
	header.add_child(add_button)

	table = GridContainer.new()
	table.columns = 3
	table.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	container.add_child(table)

	_refresh_table()

func _clear_table() -> void:
	if table == null:
		return
	for child: Node in table.get_children():
		child.queue_free()

func _refresh_table() -> void:
	if table == null:
		return

	_clear_table()

	for i: int in range(moves.size()):
		var move := moves[i]
		if move == null:
			continue

		var level_spin := SpinBox.new()
		level_spin.min_value = 1
		level_spin.max_value = 100
		level_spin.step = 1
		level_spin.value = move.level
		level_spin.custom_minimum_size = Vector2(70, 0)
		level_spin.value_changed.connect(_on_level_changed.bind(i))
		table.add_child(level_spin)

		var selector: MoveSelector = MOVE_SELECTOR_SCRIPT.new()
		selector.available_moves = available_moves
		selector.selected_move = move.move
		selector.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		selector.move_changed.connect(_on_move_changed.bind(i, selector))
		table.add_child(selector)

		var remove_button := Button.new()
		remove_button.text = "✕"
		remove_button.tooltip_text = "Eliminar movimiento"
		remove_button.pressed.connect(_on_remove_move_pressed.bind(i))
		table.add_child(remove_button)

func _on_level_changed(value: float, index: int) -> void:
	if index < 0 or index >= moves.size() or moves[index] == null:
		return
	moves[index].level = int(value)
	changed.emit()

func _on_move_changed(index: int, selector: MoveSelector) -> void:
	if index < 0 or index >= moves.size() or moves[index] == null:
		return
	moves[index].move = selector.selected_move
	changed.emit()

func _on_add_move_pressed() -> void:
	var new_move := LevelUpMove.new()
	new_move.level = 1
	new_move.move = Moves.MoveId.MOVE_TACKLE
	moves.append(new_move)
	_request_refresh()
	changed.emit()

func _on_remove_move_pressed(index: int) -> void:
	if index < 0 or index >= moves.size():
		return
	moves.remove_at(index)
	_request_refresh()
	changed.emit()

func get_moves() -> Array[LevelUpMove]:
	return moves.duplicate(true)
