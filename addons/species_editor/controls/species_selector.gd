@tool
extends HBoxContainer

class_name SpeciesSelector

signal species_changed

var selected_species: Species.SpeciesID = Species.SpeciesID.SPECIES_NONE
var available_species: Array[PokemonDataStruct] = []
var button: Button
var popup: PopupMenu
var names: Dictionary = {}

func _ready() -> void:
	button = Button.new()
	button.custom_minimum_size = Vector2(210, 0)
	button.pressed.connect(_on_pressed)
	add_child(button)

	popup = PopupMenu.new()
	popup.id_pressed.connect(_on_selected)
	add_child(popup)

	_populate()
	_update_text()

func _populate() -> void:
	popup.clear()
	names.clear()

	for data: PokemonDataStruct in available_species:
		if data == null:
			continue
		var id: int = int(data.species_id)
		if names.has(id):
			continue
		popup.add_item("[%d] %s" % [id, data.species_name], id)
		names[id] = data.species_name

	if not names.has(int(selected_species)):
		popup.add_item("[%d] UNKNOWN" % int(selected_species), int(selected_species))
		names[int(selected_species)] = "UNKNOWN"

func _on_pressed() -> void:
	var rect: Rect2 = button.get_global_rect()
	popup.popup(Rect2(
		rect.position + Vector2(0, rect.size.y),
		Vector2(240, 0)
	))

func _on_selected(id: int) -> void:
	selected_species = id as Species.SpeciesID
	_update_text()
	species_changed.emit()

func _update_text() -> void:
	if button == null:
		return
	var id: int = int(selected_species)
	button.text = "[%d] %s" % [id, str(names.get(id, "UNKNOWN"))]
