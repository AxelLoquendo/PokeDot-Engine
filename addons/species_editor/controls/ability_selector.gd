@tool
extends HBoxContainer

class_name AbilitySelector

signal ability_changed

var selected_ability: AbilityId.Id = AbilityId.Id.NONE
var available_abilities: Array[AbilityData] = []
var ability_button: Button
var ability_popup: PopupMenu
var ability_names: Dictionary = {}

func _ready() -> void:
	ability_button = Button.new()
	ability_button.custom_minimum_size = Vector2(240, 0)
	ability_button.pressed.connect(_on_ability_button_pressed)
	add_child(ability_button)

	ability_popup = PopupMenu.new()
	ability_popup.id_pressed.connect(_on_ability_selected)
	add_child(ability_popup)

	_index_names()
	_update_button_text()

func _index_names() -> void:
	ability_names.clear()
	for data: AbilityData in available_abilities:
		if data != null:
			ability_names[int(data.id)] = data.name_key

func _populate_ability_menu() -> void:
	ability_popup.clear()
	ability_names.clear()
	_add_ability_option(0, "NONE")

	for data: AbilityData in available_abilities:
		if data == null:
			continue
		var id: int = int(data.id)
		if ability_names.has(id):
			continue
		var display_name: String = data.name_key if not data.name_key.is_empty() else "UNKNOWN"
		_add_ability_option(id, display_name)

	if not ability_names.has(int(selected_ability)):
		_add_ability_option(int(selected_ability), "UNKNOWN")

func _add_ability_option(id: int, display_name: String) -> void:
	ability_popup.add_item("[%d] %s" % [id, display_name], id)
	ability_names[id] = display_name

func _on_ability_button_pressed() -> void:
	if ability_popup.get_item_count() == 0:
		_populate_ability_menu()
	var rect: Rect2 = ability_button.get_global_rect()
	ability_popup.popup(Rect2(
		rect.position + Vector2(0, rect.size.y),
		Vector2(270, 0)
	))

func _on_ability_selected(id: int) -> void:
	selected_ability = id as AbilityId.Id
	_update_button_text()
	ability_changed.emit()

func _update_button_text() -> void:
	if ability_button == null:
		return
	var id: int = int(selected_ability)
	ability_button.text = "[%d] %s" % [id, str(ability_names.get(id, "UNKNOWN"))]

func get_selected_ability() -> AbilityId.Id:
	return selected_ability
