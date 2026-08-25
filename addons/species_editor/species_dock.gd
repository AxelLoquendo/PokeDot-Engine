@tool
extends Control

class_name SpeciesDock

const REPOSITORY_SCRIPT := preload("res://addons/species_editor/species_repository.gd")
const CATALOG_SCRIPT := preload("res://addons/species_editor/editor_catalog.gd")
const ENUM_MANAGER_SCRIPT := preload("res://addons/species_editor/species_enum_manager.gd")
const VALIDATOR_SCRIPT := preload("res://addons/species_editor/species_validator.gd")
const FORM_SCRIPT := preload("res://addons/species_editor/species_form.gd")
const CUSTOM_SPECIES_PATH := "res://data_core/pokemon/resources/custom/"
const SPECIES_TRASH_PATH := "res://data_core/pokemon/trash/"

var search_box: LineEdit
var species_list: ItemList
var form_panel: SpeciesForm
var status_label: Label
var status_timer: Timer
var save_button: Button
var revert_button: Button
var new_button: Button
var duplicate_button: Button
var delete_button: Button
var discard_dialog: ConfirmationDialog
var create_dialog: ConfirmationDialog
var delete_dialog: ConfirmationDialog
var create_name_input: LineEdit
var create_id_input: SpinBox
var create_as_duplicate := false

var repository: SpeciesRepository
var catalog: SpeciesEditorCatalog
var enum_manager: SpeciesEnumManager
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
	enum_manager = ENUM_MANAGER_SCRIPT.new()
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

	var crud_buttons: HBoxContainer = HBoxContainer.new()
	left_panel.add_child(crud_buttons)

	new_button = Button.new()
	new_button.text = "+ Nueva"
	new_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	new_button.pressed.connect(_on_new_species_pressed)
	crud_buttons.add_child(new_button)

	duplicate_button = Button.new()
	duplicate_button.text = "Duplicar"
	duplicate_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	duplicate_button.pressed.connect(_on_duplicate_species_pressed)
	crud_buttons.add_child(duplicate_button)

	delete_button = Button.new()
	delete_button.text = "Papelera"
	delete_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	delete_button.pressed.connect(_on_delete_species_pressed)
	crud_buttons.add_child(delete_button)

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

	_create_species_dialog()
	_create_delete_dialog()
	_update_buttons()

	main_split.split_offset = 220

func _create_species_dialog() -> void:
	create_dialog = ConfirmationDialog.new()
	create_dialog.title = "Crear especie"
	create_dialog.ok_button_text = "Crear"
	create_dialog.cancel_button_text = "Cancelar"
	create_dialog.confirmed.connect(_on_create_species_confirmed)

	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	create_dialog.add_child(box)

	var name_label: Label = Label.new()
	name_label.text = "Nombre"
	box.add_child(name_label)
	create_name_input = LineEdit.new()
	create_name_input.placeholder_text = "Ejemplo: Mi Pokemon"
	box.add_child(create_name_input)

	var id_label: Label = Label.new()
	id_label.text = "ID"
	box.add_child(id_label)
	create_id_input = SpinBox.new()
	create_id_input.min_value = 1
	create_id_input.max_value = 999999
	create_id_input.step = 1
	box.add_child(create_id_input)
	add_child(create_dialog)

func _create_delete_dialog() -> void:
	delete_dialog = ConfirmationDialog.new()
	delete_dialog.title = "Enviar especie a la papelera"
	delete_dialog.ok_button_text = "Mover"
	delete_dialog.cancel_button_text = "Cancelar"
	delete_dialog.confirmed.connect(_on_delete_species_confirmed)
	add_child(delete_dialog)

func _on_new_species_pressed() -> void:
	_open_create_dialog(false)

func _on_duplicate_species_pressed() -> void:
	if selected_species == null:
		_show_status("Selecciona una especie para duplicarla", 2.0)
		return
	_open_create_dialog(true)

func _open_create_dialog(as_duplicate: bool) -> void:
	create_as_duplicate = as_duplicate
	create_dialog.title = "Duplicar especie" if as_duplicate else "Crear especie"
	create_name_input.text = (selected_species.species_name + " Copy") if as_duplicate and selected_species else "Nueva especie"
	create_id_input.value = _get_next_species_id()
	create_dialog.popup_centered(Vector2i(360, 220))
	create_name_input.grab_focus()

func _get_next_species_id() -> int:
	return enum_manager.get_next_custom_id(all_species)

func _on_create_species_confirmed() -> void:
	var name: String = create_name_input.text.strip_edges()
	var new_id: int = int(create_id_input.value)
	if name.is_empty():
		_show_status("El nombre no puede estar vacío", 3.0)
		return
	if new_id <= 0 or _species_id_is_used(new_id):
		_show_status("Ese ID ya está ocupado o no es válido", 3.0)
		return

	var data: PokemonDataStruct
	if create_as_duplicate and selected_species != null:
		if has_unsaved_changes and not form_panel.apply_to_species(selected_species):
			_show_status("No se pudieron aplicar los cambios antes de duplicar", 3.0)
			return
		data = selected_species.duplicate(true) as PokemonDataStruct
	else:
		data = _make_species_template()
	data.species_id = new_id as Species.SpeciesID
	data.hatch_species = data.species_id
	data.species_name = name

	var folder_error: Error = DirAccess.make_dir_recursive_absolute(
		ProjectSettings.globalize_path(CUSTOM_SPECIES_PATH)
	)
	if folder_error != OK and folder_error != ERR_ALREADY_EXISTS:
		_show_status("No se pudo crear la carpeta de especies", 3.0)
		return

	var file_name: String = "custom_%d_%s.tres" % [new_id, _slugify(name)]
	var path: String = CUSTOM_SPECIES_PATH.path_join(file_name)
	if FileAccess.file_exists(path):
		_show_status("Ya existe un archivo con ese nombre", 3.0)
		return

	var enum_error: Error = enum_manager.register_custom_species(name, new_id)
	if enum_error != OK:
		_show_status("No se pudo registrar el ID en species.gd", 3.0)
		return

	var save_error: Error = ResourceSaver.save(data, path)
	if save_error != OK:
		enum_manager.unregister_custom_species(name, new_id)
		_show_status("No se pudo guardar la nueva especie", 3.0)
		return

	EditorInterface.get_resource_filesystem().scan()
	_show_status("✓ Especie creada y registrada en species.gd", 2.0)
	_load_species()
	_load_species_from_path(path)

func _make_species_template() -> PokemonDataStruct:
	var data: PokemonDataStruct = PokemonDataStruct.new()
	data.national_dex_number = 9999
	data.regional_dex_number = 0
	data.base_hp = 1
	data.base_attack = 1
	data.base_defense = 1
	data.base_speed = 1
	data.base_sp_attack = 1
	data.base_sp_defense = 1
	data.type_1 = PokemonData.Type.TYPE_NORMAL
	data.type_2 = PokemonData.Type.TYPE_NONE
	data.growth_rate = PokemonData.GrowthRate.GROWTH_MEDIUM_FAST
	data.category_name = "Especie"
	data.description = "Nueva especie personalizada."
	data.height = 1
	data.weight = 1
	data.body_color = PokemonData.BodyColor.BODY_COLOR_GRAY
	data.level_up_moves = []
	data.teachable_moves = []
	data.egg_moves = []
	data.evolutions = []
	data.ability_1 = AbilityId.Id.NONE
	data.ability_2 = AbilityId.Id.NONE
	data.hidden_ability = AbilityId.Id.NONE
	data.item_common = Items.ItemId.ITEM_NONE
	data.item_rare = Items.ItemId.ITEM_NONE
	data.egg_group_1 = PokemonData.EggGroup.EGG_GROUP_NO_EGGS_DISCOVERED
	data.egg_group_2 = PokemonData.EggGroup.EGG_GROUP_NO_EGGS_DISCOVERED
	data.egg_cycles = 1
	data.gender_ratio = PokemonData.GenderRatio.GENDER_GENDERLESS
	return data

func _species_id_is_used(value: int) -> bool:
	for species: PokemonDataStruct in all_species:
		if species != null and int(species.species_id) == value:
			return true
	return false

func _slugify(value: String) -> String:
	var result: String = value.to_lower().strip_edges()
	result = result.replace(" ", "_").replace("-", "_")
	var clean: String = ""
	for character: String in result:
		if character.is_valid_identifier() or character == "_":
			clean += character
	return clean if not clean.is_empty() else "species"

func _on_delete_species_pressed() -> void:
	if selected_species == null or selected_path.is_empty():
		_show_status("Selecciona una especie para enviarla a la papelera", 2.0)
		return
	if not selected_path.begins_with(CUSTOM_SPECIES_PATH):
		_show_status("Por seguridad, solo se pueden mover especies custom a la papelera", 3.0)
		return
	delete_dialog.dialog_text = "¿Mover '%s' a la papelera?\\n\\nNo se eliminará definitivamente." % selected_species.species_name
	delete_dialog.popup_centered()

func _on_delete_species_confirmed() -> void:
	if selected_path.is_empty():
		return
	var error: Error = DirAccess.make_dir_recursive_absolute(
		ProjectSettings.globalize_path(SPECIES_TRASH_PATH)
	)
	if error != OK and error != ERR_ALREADY_EXISTS:
		_show_status("No se pudo crear la papelera", 3.0)
		return

	var source_path: String = ProjectSettings.globalize_path(selected_path)
	var file_name: String = selected_path.get_file()
	var destination: String = SPECIES_TRASH_PATH.path_join(
		"%d_%s" % [Time.get_unix_time_from_system(), file_name]
	)
	var move_error: Error = DirAccess.rename_absolute(
		source_path,
		ProjectSettings.globalize_path(destination)
	)
	if move_error != OK:
		_show_status("No se pudo mover la especie a la papelera", 3.0)
		return

	selected_species = null
	selected_path = ""
	has_unsaved_changes = false
	species_list.deselect_all()
	form_panel.load_species(null)
	EditorInterface.get_resource_filesystem().scan()
	_load_species()
	_show_status("✓ Especie movida a la papelera", 2.0)

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
	if duplicate_button:
		duplicate_button.disabled = selected_species == null
	if delete_button:
		delete_button.disabled = selected_species == null or selected_path.is_empty()

func _show_status(message: String, duration: float = 0.0) -> void:
	if status_label == null:
		return
	status_label.text = message
	if duration > 0.0:
		status_timer.start(duration)
