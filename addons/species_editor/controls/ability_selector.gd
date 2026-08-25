extends HBoxContainer

class_name AbilitySelector

signal ability_changed

var selected_ability: AbilityId.Id = AbilityId.Id.NONE
var ability_button: Button
var ability_popup: PopupMenu
var ability_cache: Dictionary = {}  # id -> name

func _ready() -> void:
	ability_button = Button.new()
	ability_button.text = "Select Ability"
	ability_button.custom_minimum_size = Vector2(150, 0)
	ability_button.pressed.connect(_on_ability_button_pressed)
	add_child(ability_button)

	ability_popup = PopupMenu.new()
	ability_popup.id_pressed.connect(_on_ability_selected)
	add_child(ability_popup)

	_populate_ability_menu()
	_update_button_text()

func _populate_ability_menu() -> void:
	ability_popup.clear()
	ability_cache.clear()

	# Agregar opción "None"
	ability_popup.add_item("None", 0)
	ability_cache[0] = "None"

	# Obtener todas las habilidades de la base de datos
	# (Esto dependerá de cómo esté estructurada tu AbilityDatabase)
	# Por ahora, usamos algunos IDs conocidos
	var known_abilities = [
		{"id": 1, "name": "Overgrow"},
		{"id": 7, "name": "Illuminate"},
		{"id": 26, "name": "Static"},
		{"id": 34, "name": "Chlorophyll"},
		{"id": 61, "name": "Effect Spore"},
		{"id": 65, "name": "Overgrow"},
		{"id": 142, "name": "Chlorophyll"},
	]

	for ability in known_abilities:
		ability_popup.add_item("%d: %s" % [ability["id"], ability["name"]], ability["id"])
		ability_cache[ability["id"]] = ability["name"]

func _on_ability_button_pressed() -> void:
	var button_rect = ability_button.get_global_rect()
	ability_popup.popup_rect(Rect2(button_rect.position + Vector2(0, button_rect.size.y), Vector2(200, 0)))

func _on_ability_selected(id: int) -> void:
	selected_ability = id as AbilityId.Id
	_update_button_text()
	ability_changed.emit()

func _update_button_text() -> void:
	if int(selected_ability) in ability_cache:
		ability_button.text = ability_cache[int(selected_ability)]
	else:
		ability_button.text = "[%d] Unknown" % int(selected_ability)

func get_selected_ability() -> AbilityId.Id:
	return selected_ability
