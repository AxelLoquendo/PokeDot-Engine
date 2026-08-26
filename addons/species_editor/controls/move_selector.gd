@tool
extends HBoxContainer

class_name MoveSelector

signal move_changed

var selected_move: Moves.MoveId = Moves.MoveId.MOVE_NONE
var available_moves: Array[MoveData] = []
var move_button: Button
var move_popup: PopupMenu
var move_names: Dictionary = {}

func _ready() -> void:
	move_button = Button.new()
	move_button.custom_minimum_size = Vector2(190, 0)
	move_button.pressed.connect(_on_move_button_pressed)
	add_child(move_button)

	move_popup = PopupMenu.new()
	move_popup.id_pressed.connect(_on_move_selected)
	add_child(move_popup)

	_index_names()
	_update_button_text()

func _index_names() -> void:
	move_names.clear()
	for data: MoveData in available_moves:
		if data != null:
			move_names[int(data.move_id)] = data.move_name

func _populate_move_menu() -> void:
	move_popup.clear()
	move_names.clear()
	_add_move_option(0, "NONE")

	for data: MoveData in available_moves:
		if data == null:
			continue
		var id: int = int(data.move_id)
		if move_names.has(id):
			continue
		var display_name: String = data.move_name if not data.move_name.is_empty() else "UNKNOWN"
		_add_move_option(id, display_name)

	if not move_names.has(int(selected_move)):
		_add_move_option(int(selected_move), "UNKNOWN")

func _add_move_option(id: int, display_name: String) -> void:
	move_popup.add_item("[%d] %s" % [id, display_name], id)
	move_names[id] = display_name

func _on_move_button_pressed() -> void:
	if move_popup.get_item_count() == 0:
		_populate_move_menu()
	var rect: Rect2 = move_button.get_global_rect()
	move_popup.popup(Rect2(
		rect.position + Vector2(0, rect.size.y),
		Vector2(230, 0)
	))

func _on_move_selected(id: int) -> void:
	selected_move = id as Moves.MoveId
	_update_button_text()
	move_changed.emit()

func _update_button_text() -> void:
	if move_button == null:
		return
	var id: int = int(selected_move)
	move_button.text = "[%d] %s" % [id, str(move_names.get(id, "UNKNOWN"))]
