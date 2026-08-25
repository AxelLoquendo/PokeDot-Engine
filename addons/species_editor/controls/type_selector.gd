extends HBoxContainer

class_name TypeSelector

signal type_changed

var selected_type: PokemonData.Type = PokemonData.Type.TYPE_NORMAL
var type_button: Button
var type_popup: PopupMenu

func _ready() -> void:
	type_button = Button.new()
	type_button.text = "Select Type"
	type_button.custom_minimum_size = Vector2(150, 0)
	type_button.pressed.connect(_on_type_button_pressed)
	add_child(type_button)

	type_popup = PopupMenu.new()
	type_popup.id_pressed.connect(_on_type_selected)
	add_child(type_popup)

	_populate_type_menu()
	_update_button_text()

func _populate_type_menu() -> void:
	type_popup.clear()

	var type_names = [
		"Normal", "Fighting", "Flying", "Poison", "Ground",
		"Rock", "Bug", "Ghost", "Steel", "Fire",
		"Water", "Grass", "Electric", "Psychic", "Ice",
		"Dragon", "Dark", "Fairy"
	]

	for i in range(type_names.size()):
		type_popup.add_item(type_names[i], i)

func _on_type_button_pressed() -> void:
	var button_rect = type_button.get_global_rect()
	type_popup.popup_rect(Rect2(button_rect.position + Vector2(0, button_rect.size.y), Vector2(150, 0)))

func _on_type_selected(id: int) -> void:
	selected_type = id as PokemonData.Type
	_update_button_text()
	type_changed.emit()

func _update_button_text() -> void:
	var type_names = [
		"Normal", "Fighting", "Flying", "Poison", "Ground",
		"Rock", "Bug", "Ghost", "Steel", "Fire",
		"Water", "Grass", "Electric", "Psychic", "Ice",
		"Dragon", "Dark", "Fairy"
	]

	if int(selected_type) < type_names.size():
		type_button.text = type_names[int(selected_type)]
	else:
		type_button.text = "Unknown"

func get_selected_type() -> PokemonData.Type:
	return selected_type
