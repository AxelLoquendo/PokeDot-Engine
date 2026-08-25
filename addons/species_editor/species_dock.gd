@tool
extends Control

class_name SpeciesDock

const REPOSITORY_SCRIPT := preload("res://addons/species_editor/species_repository.gd")
const CATALOG_SCRIPT := preload("res://addons/species_editor/editor_catalog.gd")
const VALIDATOR_SCRIPT := preload("res://addons/species_editor/species_validator.gd")
const FORM_SCRIPT := preload("res://addons/species_editor/species_form.gd")

var search_box: LineEdit
var species_list: ItemList
var form_panel: SpeciesForm
var status_label: Label
var status_timer: Timer
var save_button: Button
var revert_button: Button
var discard_dialog: ConfirmationDialog

var repository: SpeciesRepository
var catalog: SpeciesEditorCatalog
var validator: SpeciesValidator
var all_species: Array[PokemonDataStruct] = []
var selected_species: PokemonDataStruct
var selected_path := ""
var pending_path := ""
var has_unsaved_changes := false
var _is_ready := false

func _init() -> void:
	name = "🔬 Species Editor"
	custom_minimum_size = Vector2(700, 500)
	repository = REPOSITORY_SCRIPT.new()
	catalog = CATALOG_SCRIPT.new()
	validator = VALIDATOR_SCRIPT.new()

func _ready() -> void:
	_build_ui()
	_is_ready = true
	call_deferred("_load_species")

func _build_ui() -> void:
	var main_split := HSplitContainer.new()
	main_split.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(main_split)

	var left_panel := VBoxContainer.new()
	left_panel.custom_minimum_size = Vector2(220, 0)
	left_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_split.add_child(left_panel)

	var title := Label.new()
	title.text = "📋 Especies"
	title.add_theme_font_size_override("font_size", 14)
	left_panel.add_child(title)

	search_box = LineEdit.new()
	search_box.placeholder_text = "Buscar por ID o nombre..."
	search_box.text_changed.connect(_on_search_changed)
	left_panel.add_child(search_box)

	var refresh_button := Button.new()
	refresh_button.text = "↻ Recargar lista"
	refresh_button.pressed.connect(_load_species)
	left_panel.add_child(refresh_button)

	species_list = ItemList.new()
	species_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	species_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	species_list.item_selected.connect(_on_species_selected)
	left_panel.add_child(species_list)

	var right_panel := VBoxContainer.new()
	right_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_split.add_child(right_panel)

	var properties_title := Label.new()
	properties_title.text = "✏️ Propiedades"
	properties_title.add_theme_font_size_override("font_size", 14)
	right_panel.add_child(properties_title)

	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	right_panel.add_child(scroll)

	form_panel = FORM_SCRIPT.new()
	form_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	form_panel.form_changed.connect(_on_form_changed)
	scroll.add_child(form_panel)

	var buttons := HBoxContainer.new()
	right_panel.add_child(buttons)

	save_button = Button.new()
	save_button.text = "💾 Guardar"
	save_button.disabled = true
	save_button.pressed.connect(_on_save_pressed)
	buttons.add_child(save_button)

	revert_button = Button.new()
	revert_button.text = "↶ Revertir"
	revert_button.disabled = true
	revert_button.pressed.connect(_on_revert_pressed)
	buttons.add_child(revert_button)

	var validate_button := Button.new()
	validate_button.text = "✓ Validar"
	validate_button.pressed.connect(_on_validate_pressed)
	buttons.add_child(validate_button)

	status_label = Label.new()
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	right_panel.add_child(status_label)

	status_timer = Timer.new()
	status_timer.one_shot = true
	status_timer.timeout.connect(func() -> void:
		if status_label:
			status_label.text = "Listo"
	)
	add_child(status_timer)

	discard_dialog = ConfirmationDialog.new()
	discard_dialog.title = "Cambios sin guardar"
	discard_dialog.dialog_text = "Hay cambios sin guardar. ¿Descartarlos?"
	discard_dialog.confirmed.connect(_discard_and_load_pending)
	add_child(discard_dialog)

	main_split.split_offset = 220

func _load_species() -> void:
	if not _is_ready:
		return

	all_species = repository.load_all_species()
	catalog.load_all()
	form_panel.set_catalog(catalog, all_species)
	_refresh_list()

	if not repository.get_errors().is_empty():
		_show_status(
			"⚠ %d problemas encontrados. Revisa la consola."
			% repository.get_errors().size(),
			4.0
		)
	else:
		_show_status("✓ %d especies cargadas" % all_species.size(), 2.0)

func _refresh_list() -> void:
	if species_list == null:
		return

	species_list.clear()
	var query := search_box.text.strip_edges().to_lower() if search_box else ""

	for entry: Dictionary in repository_entries_filtered(query):
		var index: int = species_list.add_item(
			"[%d] %s" % [int(entry.get("id", 0)), str(entry.get("name", ""))]
		)
		species_list.set_item_metadata(index, str(entry.get("path", "")))

func repository_entries_filtered(query: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for species: PokemonDataStruct in all_species:
		if species == null:
			continue
		var id_text := str(int(species.species_id))
		var name := species.species_name
		if not query.is_empty() and not id_text.contains(query) and not name.to_lower().contains(query):
			continue
		result.append({
			"id": int(species.species_id),
			"name": name,
			"path": repository.get_species_path(species.species_id),
		})
	return result

func _on_search_changed(_text: String) -> void:
	_refresh_list()

func _on_species_selected(index: int) -> void:
	if index < 0 or index >= species_list.item_count:
		return

	var path: String = str(species_list.get_item_metadata(index))
	if path.is_empty():
		return

	if has_unsaved_changes and path != selected_path:
		pending_path = path
		discard_dialog.popup_centered()
		return

	_load_species_from_path(path)

func _load_species_from_path(path: String, force_reload: bool = false) -> void:
	var resource: Resource
	if force_reload:
		resource = ResourceLoader.load(
			path,
			"",
			ResourceLoader.CACHE_MODE_IGNORE
		)
	else:
		resource = load(path)
	if resource == null or not resource is PokemonDataStruct:
		_show_status("✗ No se pudo cargar: %s" % path, 3.0)
		return

	selected_path = path
	selected_species = resource as PokemonDataStruct
	has_unsaved_changes = false
	form_panel.load_species(selected_species)
	_update_buttons()
	_show_status("Seleccionada: %s" % selected_species.species_name, 2.0)

func _discard_and_load_pending() -> void:
	has_unsaved_changes = false
	if not pending_path.is_empty():
		_load_species_from_path(pending_path)
	pending_path = ""

func _on_form_changed() -> void:
	if selected_species == null:
		return
	has_unsaved_changes = true
	_update_buttons()
	_show_status("⚠ Cambios sin guardar", 2.0)

func _on_save_pressed() -> void:
	if selected_species == null or selected_path.is_empty():
		_show_status("✗ No hay especie seleccionada", 2.0)
		return

	if not form_panel.apply_to_species(selected_species):
		_show_status("✗ No se pudieron aplicar los campos", 3.0)
		return

	var errors: Array[String] = validator.validate(selected_species)
	if not errors.is_empty():
		_show_status("✗ Hay %d errores de validación" % errors.size(), 4.0)
		push_warning("Species Editor:\n" + "\n".join(errors))
		return

	var result: Error = ResourceSaver.save(selected_species, selected_path)
	if result != OK:
		_show_status("✗ Error al guardar: %s" % error_string(result), 3.0)
		return

	has_unsaved_changes = false
	_update_buttons()
	_show_status("✓ Guardado: %s" % selected_species.species_name, 3.0)

func _on_revert_pressed() -> void:
	if selected_path.is_empty():
		return
	_load_species_from_path(selected_path, true)

func _on_validate_pressed() -> void:
	if selected_species == null:
		_show_status("No hay especie seleccionada", 2.0)
		return

	var errors: Array[String] = validator.validate(selected_species)
	if errors.is_empty():
		_show_status("✓ Validación correcta", 2.0)
	else:
		_show_status("✗ %d errores. Revisa la consola." % errors.size(), 4.0)
		push_warning("Species Editor:\n" + "\n".join(errors))

func _update_buttons() -> void:
	if save_button:
		save_button.disabled = selected_species == null or not has_unsaved_changes
	if revert_button:
		revert_button.disabled = selected_species == null or not has_unsaved_changes

func _show_status(message: String, duration: float = 0.0) -> void:
	if status_label == null:
		return
	status_label.text = message
	if duration > 0.0:
		status_timer.start(duration)
