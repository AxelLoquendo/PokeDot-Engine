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
	name = "🔬 Species Editor"
	custom_minimum_size = Vector2(0, 400)  # Altura inicial
	repository = SpeciesRepository.new()
	validator = SpeciesValidator.new()

func _ready() -> void:
	_setup_ui()
	_load_species()

func _setup_ui() -> void:
	# Asegurarse de que el Control se redimensiona correctamente
	anchor_left = 0.0
	anchor_top = 0.0
	anchor_right = 1.0
	anchor_bottom = 1.0

	# ─────────────────────────────────────────────────────────────────────────────────────────────────
	# Main layout: HSplitContainer para panel list y editor
	# ─────────────────────────────────────────────────────────────────────────────────────────────────

	var main_split = HSplitContainer.new()
	main_split.name = "MainSplit"
	main_split.anchor_left = 0.0
	main_split.anchor_top = 0.0
	main_split.anchor_right = 1.0
	main_split.anchor_bottom = 1.0
	add_child(main_split)

	# ══════════════════════════════════════════════════════════════════════════════════════════════════
	# Panel Izquierdo: Lista de especies
	# ══════════════════════════════════════════════════════════════════════════════════════════════════

	var left_panel = VBoxContainer.new()
	left_panel.name = "LeftPanel"
	left_panel.add_theme_constant_override("separation", 6)
	main_split.add_child(left_panel)

	# Encabezado izquierdo
	var left_header = HBoxContainer.new()
	left_header.add_theme_constant_override("separation", 4)
	left_panel.add_child(left_header)

	var left_title = Label.new()
	left_title.text = "📋 Species List"
	left_title.add_theme_font_size_override("font_size", 13)
	left_title.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
	left_header.add_child(left_title)
	left_header.add_spacer(false)

	# Búsqueda
	search_box = LineEdit.new()
	search_box.placeholder_text = "Search ID or name..."
	search_box.custom_minimum_size = Vector2(0, 28)
	search_box.text_changed.connect(_on_search_changed)
	left_panel.add_child(search_box)

	# Separador visual
	var sep1 = HSeparator.new()
	left_panel.add_child(sep1)

	# Lista de especies
	species_list = ItemList.new()
	species_list.custom_minimum_size = Vector2(180, 0)
	species_list.item_selected.connect(_on_species_selected)
	left_panel.add_child(species_list)

	# ══════════════════════════════════════════════════════════════════════════════════════════════════
	# Panel Derecho: Editor de propiedades
	# ══════════════════════════════════════════════════════════════════════════════════════════════════

	var right_panel = VBoxContainer.new()
	right_panel.name = "RightPanel"
	right_panel.add_theme_constant_override("separation", 6)
	main_split.add_child(right_panel)

	# Encabezado derecho
	var right_header = HBoxContainer.new()
	right_header.add_theme_constant_override("separation", 4)
	right_panel.add_child(right_header)

	var right_title = Label.new()
	right_title.text = "✏️  Properties"
	right_title.add_theme_font_size_override("font_size", 13)
	right_title.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
	right_header.add_child(right_title)
	right_header.add_spacer(false)

	# Separador visual
	var sep2 = HSeparator.new()
	right_panel.add_child(sep2)

	# Form scrollable
	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(300, 0)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_panel.add_child(scroll)

	form_panel = SpeciesForm.new()
	form_panel.form_changed.connect(_on_form_changed)
	scroll.add_child(form_panel)

	# Separador visual antes de botones
	var sep3 = HSeparator.new()
	right_panel.add_child(sep3)

	# Botones de acción
	var button_container = HBoxContainer.new()
	button_container.add_theme_constant_override("separation", 4)
	right_panel.add_child(button_container)

	var save_btn = Button.new()
	save_btn.text = "💾 Save"
	save_btn.custom_minimum_size = Vector2(0, 28)
	save_btn.pressed.connect(_on_save_pressed)
	button_container.add_child(save_btn)

	var revert_btn = Button.new()
	revert_btn.text = "⇶ Revert"
	revert_btn.custom_minimum_size = Vector2(0, 28)
	revert_btn.pressed.connect(_on_revert_pressed)
	button_container.add_child(revert_btn)

	var validate_btn = Button.new()
	validate_btn.text = "✓ Validate"
	validate_btn.custom_minimum_size = Vector2(0, 28)
	validate_btn.pressed.connect(_on_validate_pressed)
	button_container.add_child(validate_btn)

	# ══════════════════════════════════════════════════════════════════════════════════════════════════
	# Status Bar (abajo)
	# ══════════════════════════════════════════════════════════════════════════════════════════════════

	status_label = Label.new()
	status_label.text = "Ready"
	status_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	status_label.add_theme_font_size_override("font_size", 9)
	right_panel.add_child(status_label)

	# Timer para limpiar mensajes de estado
	status_timer = Timer.new()
	status_timer.timeout.connect(_on_status_timer_timeout)
	add_child(status_timer)

	# Ajustar split inicial
	main_split.split_offset = 200

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
		_show_status("✗ No species selected", 2.0)
		return

	if not form_panel.apply_to_species(selected_species):
		_show_status("✗ Invalid data", 2.0)
		return

	var errors = validator.validate(selected_species)
	if not errors.is_empty():
		_show_status("✗ Validation failed: " + errors[0], 3.0)
		return

	if ResourceSaver.save(selected_species) != OK:
		_show_status("✗ Failed to save", 2.0)
		return

	original_species_data = _serialize_species(selected_species)
	_show_status("✓ Saved: %s" % selected_species.species_name, 2.0)

func _on_revert_pressed() -> void:
	if selected_species == null:
		_show_status("✗ No species selected", 2.0)
		return

	var file_path = repository.get_species_path(selected_species.species_id)
	if file_path.is_empty():
		_show_status("✗ Could not find file path", 2.0)
		return

	var reloaded = load(file_path) as PokemonDataStruct
	if reloaded == null:
		_show_status("✗ Failed to reload", 2.0)
		return

	selected_species = reloaded
	original_species_data = _serialize_species(selected_species)
	form_panel.load_species(selected_species)
	_show_status("✓ Reverted changes", 2.0)

func _on_validate_pressed() -> void:
	if selected_species == null:
		_show_status("✗ No species selected", 2.0)
		return

	var errors = validator.validate(selected_species)

	if errors.is_empty():
		_show_status("✓ Validation OK", 2.0)
	else:
		var error_msg = "\n".join(errors)
		push_warning("Species validation errors:\n" + error_msg)
		_show_status("✗ %d errors (check console)" % errors.size(), 3.0)

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
