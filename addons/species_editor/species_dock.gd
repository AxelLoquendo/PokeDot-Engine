@tool
extends Control

class_name SpeciesDock

# ============================================================
# UI COMPONENTS
# ============================================================

var search_box: LineEdit
var species_list: ItemList
var form_panel: SpeciesForm
var status_label: Label
var status_timer: Timer

var repository: SpeciesRepository
var validator: SpeciesValidator

# ============================================================
# STATE
# ============================================================

var selected_species: PokemonDataStruct = null
var original_species_data: Dictionary = {}
var all_species: Array[PokemonDataStruct] = []

func _init() -> void:
	name = "SpeciesEditor"
	custom_minimum_size = Vector2(450, 700)
	repository = SpeciesRepository.new()
	validator = SpeciesValidator.new()

func _ready() -> void:
	_setup_ui()
	_load_species()

func _setup_ui() -> void:
	var main_container = VBoxContainer.new()
	main_container.name = "MainContainer"
	main_container.add_theme_constant_override("separation", 8)
	add_child(main_container)

	# ─────────────────────────────
	# Header
	# ─────────────────────────────

	var header = HBoxContainer.new()
	main_container.add_child(header)

	var title = Label.new()
	title.text = "🔬 Pokémon Species Editor"
	title.add_theme_font_size_override("font_size", 14)
	header.add_child(title)
	header.add_spacer(false)

	# ─────────────────────────────
	# Search
	# ─────────────────────────────

	var search_container = VBoxContainer.new()
	search_container.add_theme_constant_override("separation", 3)
	main_container.add_child(search_container)

	var search_label = Label.new()
	search_label.text = "🔍 Search Species"
	search_label.add_theme_font_size_override("font_size", 11)
	add_theme_color_override("font_color", Color.GRAY)
	search_container.add_child(search_label)

	search_box = LineEdit.new()
	search_box.placeholder_text = "Type ID or name... (e.g. 1, Bulbasaur)"
	search_box.text_changed.connect(_on_search_changed)
	search_container.add_child(search_box)

	# ─────────────────────────────
	# Species List
	# ─────────────────────────────

	var list_label = Label.new()
	list_label.text = "Species List"
	list_label.add_theme_font_size_override("font_size", 11)
	main_container.add_child(list_label)

	species_list = ItemList.new()
	species_list.custom_minimum_size = Vector2(0, 180)
	species_list.item_selected.connect(_on_species_selected)
	main_container.add_child(species_list)

	# ─────────────────────────────
	# Form (scrollable)
	# ─────────────────────────────

	var form_label = Label.new()
	form_label.text = "Editor"
	form_label.add_theme_font_size_override("font_size", 11)
	main_container.add_child(form_label)

	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 250)
	main_container.add_child(scroll)

	form_panel = SpeciesForm.new()
	form_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	form_panel.form_changed.connect(_on_form_changed)
	scroll.add_child(form_panel)

	# ─────────────────────────────
	# Action Buttons
	# ─────────────────────────────

	var button_container = HBoxContainer.new()
	button_container.add_theme_constant_override("separation", 6)
	main_container.add_child(button_container)

	var save_btn = Button.new()
	save_btn.text = "💾 Save"
	save_btn.pressed.connect(_on_save_pressed)
	button_container.add_child(save_btn)

	var revert_btn = Button.new()
	revert_btn.text = "↶ Revert"
	revert_btn.pressed.connect(_on_revert_pressed)
	button_container.add_child(revert_btn)

	var validate_btn = Button.new()
	validate_btn.text = "✓ Validate"
	validate_btn.pressed.connect(_on_validate_pressed)
	button_container.add_child(validate_btn)

	# ─────────────────────────────
	# Status Bar
	# ─────────────────────────────

	status_label = Label.new()
	status_label.text = "Ready"
	status_label.add_theme_color_override("font_color", Color.GRAY)
	status_label.add_theme_font_size_override("font_size", 10)
	main_container.add_child(status_label)

	# Timer para limpiar mensajes de estado
	status_timer = Timer.new()
	status_timer.timeout.connect(_on_status_timer_timeout)
	add_child(status_timer)

func _load_species() -> void:
	all_species = repository.load_all_species()
	_refresh_list()
	_show_status("Loaded %d species" % all_species.size())

func _refresh_list() -> void:
	species_list.clear()

	for species in all_species:
		if species == null:
			continue

		var item_text = "[%d] %s" % [species.species_id, species.species_name]
		species_list.add_item(item_text)

func _on_search_changed(text: String) -> void:
	species_list.clear()

	var search_lower = text.to_lower()
	var count = 0

	if search_lower.is_empty():
		_refresh_list()
		return

	for species in all_species:
		if species == null:
			continue

		var id_match = str(species.species_id).contains(search_lower)
		var name_match = species.species_name.to_lower().contains(search_lower)

		if id_match or name_match:
			var item_text = "[%d] %s" % [species.species_id, species.species_name]
			species_list.add_item(item_text)
			count += 1

	_show_status("Found %d species" % count if count > 0 else "No results")

func _on_species_selected(index: int) -> void:
	if index < 0 or index >= species_list.item_count:
		return

	var item_text = species_list.get_item_text(index)

	for species in all_species:
		if species == null:
			continue

		if "[%d] %s" % [species.species_id, species.species_name] == item_text:
			selected_species = species
			original_species_data = _serialize_species(species)
			form_panel.load_species(species)
			_show_status("Selected: %s" % species.species_name)
			return

func _on_form_changed() -> void:
	if selected_species:
		_show_status("⚠ Unsaved changes", 2.0)

func _on_save_pressed() -> void:
	if selected_species == null:
		_show_status("❌ No species selected", 2.0)
		return

	if not form_panel.apply_to_species(selected_species):
		_show_status("❌ Invalid data", 2.0)
		return

	var errors = validator.validate(selected_species)
	if not errors.is_empty():
		_show_status("❌ Validation failed: " + errors[0], 3.0)
		return

	if ResourceSaver.save(selected_species) != OK:
		_show_status("❌ Failed to save", 2.0)
		return

	original_species_data = _serialize_species(selected_species)
	_show_status("✓ Saved: %s" % selected_species.species_name, 2.0)

func _on_revert_pressed() -> void:
	if selected_species == null:
		_show_status("❌ No species selected", 2.0)
		return

	# Restaurar desde el archivo
	var file_path = repository.get_species_path(selected_species.species_id)
	if file_path.is_empty():
		_show_status("❌ Could not find file path", 2.0)
		return

	var reloaded = load(file_path) as PokemonDataStruct
	if reloaded == null:
		_show_status("❌ Failed to reload", 2.0)
		return

	selected_species = reloaded
	original_species_data = _serialize_species(selected_species)
	form_panel.load_species(selected_species)
	_show_status("✓ Reverted changes", 2.0)

func _on_validate_pressed() -> void:
	if selected_species == null:
		_show_status("❌ No species selected", 2.0)
		return

	var errors = validator.validate(selected_species)

	if errors.is_empty():
		_show_status("✓ Validation OK", 2.0)
	else:
		var error_msg = "\n".join(errors)
		push_warning("Species validation errors:\n" + error_msg)
		_show_status("❌ %d errors (check console)" % errors.size(), 3.0)

func _show_status(message: String, duration: float = 0.0) -> void:
	status_label.text = message

	if duration > 0:
		status_timer.start(duration)

func _on_status_timer_timeout() -> void:
	status_label.text = "Ready"

func _serialize_species(species: PokemonDataStruct) -> Dictionary:
	var data = {}
	if species:
		data["species_id"] = species.species_id
		data["species_name"] = species.species_name
		data["national_dex_number"] = species.national_dex_number
	return data
