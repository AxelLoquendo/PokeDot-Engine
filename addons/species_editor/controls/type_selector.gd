@tool
extends HBoxContainer

class_name TypeSelector

signal type_changed

var selected_type: PokemonData.Type = PokemonData.Type.TYPE_NONE
var type_button: Button
var type_popup: PopupMenu

func _ready() -> void:
	type_button = Button.new()
	type_button.custom_minimum_size = Vector2(190, 0)
	type_button.pressed.connect(_on_type_button_pressed)
	add_child(type_button)

	type_popup = PopupMenu.new()
	type_popup.id_pressed.connect(_on_type_selected)
	add_child(type_popup)

	_populate_type_menu()
	_update_button_text()

func _populate_type_menu() -> void:
	type_popup.clear()
	var names: Array = PokemonData.Type.keys()
	var values: Array = PokemonData.Type.values()

	for i: int in range(values.size()):
		var id: int = int(values[i])
		var display_name: String = str(names[i]).trim_prefix("TYPE_").replace("_", " ").capitalize()
		type_popup.add_item("[%d] %s" % [id, display_name], id)

func _on_type_button_pressed() -> void:
	var rect: Rect2 = type_button.get_global_rect()
	type_popup.popup(Rect2(
		rect.position + Vector2(0, rect.size.y),
		Vector2(210, 0)
	))

func _on_type_selected(id: int) -> void:
	selected_type = id as PokemonData.Type
	_update_button_text()
	type_changed.emit()

func _update_button_text() -> void:
	if type_button == null or type_popup == null:
		return

	for i: int in range(type_popup.get_item_count()):
		if type_popup.get_item_id(i) == int(selected_type):
			type_button.text = type_popup.get_item_text(i)
			return

	type_button.text = "[%d] UNKNOWN" % int(selected_type)

func get_selected_type() -> PokemonData.Type:
	return selected_type
