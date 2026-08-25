@tool
extends Control

class_name SpeciesDock

# ============================================================
# UI COMPONENTS
# ============================================================

var search_box: LineEdit
var species_list: ItemList
var detail_panel: Control
var status_label: Label

var repository: SpeciesRepository

# ============================================================
# STATE
# ============================================================

var selected_species: PokemonDataStruct = null
var all_species: Array[PokemonDataStruct] = []

func _init() -> void:
	name = "SpeciesEditor"
	custom_minimum_size = Vector2(350, 600)
	repository = SpeciesRepository.new()

func _ready() -> void:
	_setup_ui()
	_load_species()

func _setup_ui() -> void:
	# Main container
	var main_box = VBoxContainer.new()
	main_box.name = "MainBox"
	add_child(main_box)

	# Title
	var title = Label.new()
	title.text = "Species Editor (Phase 1)"
	title.add_theme_font_size_override("font_size", 16)
	main_box.add_child(title)

	# Search section
	var search_label = Label.new()
	search_label.text = "Search Species:"
	main_box.add_child(search_label)

	search_box = LineEdit.new()
	search_box.placeholder_text = "Type name or ID..."
	search_box.text_changed.connect(_on_search_changed)
	main_box.add_child(search_box)

	# Species list
	species_list = ItemList.new()
	species_list.custom_minimum_size = Vector2(0, 300)
	species_list.item_selected.connect(_on_species_selected)
	main_box.add_child(species_list)

	# Detail panel (placeholder for Phase 2)
	detail_panel = Control.new()
	detail_panel.custom_minimum_size = Vector2(0, 200)
	main_box.add_child(detail_panel)

	var detail_label = Label.new()
	detail_label.text = "[Phase 2: Edit fields here]"
	detail_panel.add_child(detail_label)

	# Status bar
	status_label = Label.new()
	status_label.text = "Loading..."
	status_label.add_theme_color_override("font_color", Color.GRAY)
	main_box.add_child(status_label)

func _load_species() -> void:
	all_species = repository.load_all_species()
	_refresh_list()

func _refresh_list() -> void:
	species_list.clear()

	for species in all_species:
		if species == null:
			continue

		var item_text = "[%d] %s" % [species.species_id, species.species_name]
		species_list.add_item(item_text)

	status_label.text = "Loaded %d species" % all_species.size()

func _on_search_changed(text: String) -> void:
	species_list.clear()

	var search_lower = text.to_lower()
	var count = 0

	for species in all_species:
		if species == null:
			continue

		# Match by ID or name
		var id_match = str(species.species_id).contains(search_lower)
		var name_match = species.species_name.to_lower().contains(search_lower)

		if id_match or name_match:
			var item_text = "[%d] %s" % [species.species_id, species.species_name]
			species_list.add_item(item_text)
			count += 1

	if count == 0:
		status_label.text = "No species found"
	else:
		status_label.text = "Found %d species" % count

func _on_species_selected(index: int) -> void:
	if index < 0 or index >= species_list.item_count:
		return

	# Find the species from the current filtered view
	var item_text = species_list.get_item_text(index)

	for species in all_species:
		if species == null:
			continue

		if "[%d] %s" % [species.species_id, species.species_name] == item_text:
			selected_species = species
			_display_species_info(species)
			return

func _display_species_info(species: PokemonDataStruct) -> void:
	# Phase 1: Just show basic info
	var info_text = ""
	info_text += "ID: %d\n" % species.species_id
	info_text += "Name: %s\n" % species.species_name
	info_text += "Dex: %d\n" % species.national_dex_number
	info_text += "\nTypes: "

	if species.type_1:
		info_text += str(species.type_1)
	if species.type_2 != PokemonData.Type.TYPE_NONE:
		info_text += ", " + str(species.type_2)

	info_text += "\n\nStats:\n"
	info_text += "HP: %d\n" % species.base_hp
	info_text += "Atk: %d | Def: %d\n" % [species.base_attack, species.base_defense]
	info_text += "SpA: %d | SpD: %d\n" % [species.base_sp_attack, species.base_sp_defense]
	info_text += "Spe: %d\n" % species.base_speed

	if detail_panel.get_child_count() > 0:
		detail_panel.get_child(0).queue_free()

	var info_label = Label.new()
	info_label.text = info_text
	info_label.clip_text = true
	detail_panel.add_child(info_label)
