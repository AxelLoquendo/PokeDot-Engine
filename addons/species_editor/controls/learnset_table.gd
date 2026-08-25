extends PanelContainer

class_name LearnsetTable

## Tabla editable para Level Up Moves

var moves: Array[LevelUpMove] = []
var table: GridContainer
var add_button: Button
var remove_buttons: Array[Button] = []

func load_moves(moves_array: Array[LevelUpMove]) -> void:
	moves = moves_array.duplicate()
	_refresh_table()

func _ready() -> void:
	var container = VBoxContainer.new()
	container.add_theme_constant_override("separation", 4)
	add_child(container)

	# Header
	var header = HBoxContainer.new()
	container.add_child(header)

	var title = Label.new()
	title.text = "Level | Move ID | Move Name"
	title.add_theme_color_override("font_color", Color.LIGHT_GRAY)
	key_val title.add_theme_font_size_override("font_size", 10)
	header.add_child(title)
	header.add_spacer(false)

	var add_btn = Button.new()
	add_btn.text = "+ Add Move"
	add_btn.pressed.connect(_on_add_move_pressed)
	header.add_child(add_btn)

	# Table
	table = GridContainer.new()
	table.columns = 4
	container.add_child(table)

	_refresh_table()

func _refresh_table() -> void:
	if table == null:
		return

	table.clear()
	remove_buttons.clear()

	for i in range(moves.size()):
		var move = moves[i]

		# Level
		var level_spin = SpinBox.new()
		level_spin.value = move.level
		level_spin.min_value = 0
		level_spin.max_value = 100
		level_spin.custom_minimum_size = Vector2(50, 0)
		table.add_child(level_spin)

		# Move ID
		var move_id_label = Label.new()
		move_id_label.text = str(move.move)
		move_id_label.custom_minimum_size = Vector2(60, 0)
		table.add_child(move_id_label)

		# Move Name (placeholder)
		var move_name_label = Label.new()
		move_name_label.text = "[Move %d]" % move.move
		move_name_label.custom_minimum_size = Vector2(120, 0)
		table.add_child(move_name_label)

		# Remove button
		var remove_btn = Button.new()
		remove_btn.text = "✕"
		remove_btn.custom_minimum_size = Vector2(30, 0)
		remove_btn.pressed.connect(_on_remove_move_pressed.bind(i))
		table.add_child(remove_btn)
		remove_buttons.append(remove_btn)

func _on_add_move_pressed() -> void:
	var new_move = LevelUpMove.new()
	new_move.level = 1
	new_move.move = 1  # Tackle
	moves.append(new_move)
	_refresh_table()

func _on_remove_move_pressed(index: int) -> void:
	if index >= 0 and index < moves.size():
		moves.remove_at(index)
		_refresh_table()

func get_moves() -> Array[LevelUpMove]:
	return moves
