@tool
extends Control

class_name MoveEditorDock

const REPOSITORY_SCRIPT := preload("res://addons/move_editor/move_repository.gd")
const CATALOG_SCRIPT := preload("res://addons/move_editor/move_catalog.gd")
const FORM_SCRIPT := preload("res://addons/move_editor/move_form.gd")
const CUSTOM_MOVE_PATH: String = "res://data_core/move/resources/custom/"
const MOVE_TRASH_PATH: String = "res://data_core/move/trash/"

var repository: MoveEditorRepository
var catalog: MoveEditorCatalog
var all_entries: Array[Dictionary] = []
var selected_move: MoveData
var selected_path: String = ""
var pending_path: String = ""
var has_unsaved_changes: bool = false
var is_ready: bool = false

var search_box: LineEdit
var move_list: ItemList
var form: MoveEditorForm
var status_label: Label
var save_button: Button
var revert_button: Button
var duplicate_button: Button
var trash_button: Button
var restore_button: Button
var restore_menu: PopupMenu
var discard_dialog: ConfirmationDialog
var create_dialog: ConfirmationDialog
var trash_dialog: ConfirmationDialog
var create_name_input: LineEdit
var create_id_input: SpinBox
var create_as_duplicate: bool = false

func _init() -> void:
	name = "⚔ Move Editor"
	custom_minimum_size = Vector2(760, 540)
	repository = REPOSITORY_SCRIPT.new()
	catalog = CATALOG_SCRIPT.new()
	catalog.load_all()

func _ready() -> void:
	_build_ui()
	is_ready = true
	call_deferred("reload_moves")

func _build_ui() -> void:
	var split: HSplitContainer = HSplitContainer.new()
	split.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(split)

	var left: VBoxContainer = VBoxContainer.new()
	left.custom_minimum_size = Vector2(245, 0)
	left.size_flags_vertical = Control.SIZE_EXPAND_FILL
	split.add_child(left)

	var title: Label = Label.new()
	title.text = "⚔ Movimientos"
	title.add_theme_font_size_override("font_size", 15)
	left.add_child(title)

	search_box = LineEdit.new()
	search_box.placeholder_text = "Buscar por ID o nombre..."
	search_box.clear_button_enabled = true
	search_box.text_changed.connect(_on_search_changed)
	left.add_child(search_box)

	var reload_button: Button = Button.new()
	reload_button.text = "↻ Recargar catálogo"
	reload_button.pressed.connect(reload_moves)
	left.add_child(reload_button)

	var actions: HBoxContainer = HBoxContainer.new()
	left.add_child(actions)
	var new_button: Button = Button.new()
	new_button.text = "+ Nuevo"
	new_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	new_button.pressed.connect(_on_new_pressed)
	actions.add_child(new_button)
	duplicate_button = Button.new()
	duplicate_button.text = "Duplicar"
	duplicate_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	duplicate_button.pressed.connect(_on_duplicate_pressed)
	actions.add_child(duplicate_button)
	trash_button = Button.new()
	trash_button.text = "Papelera"
	trash_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	trash_button.pressed.connect(_on_trash_pressed)
	actions.add_child(trash_button)

	restore_button = Button.new()
	restore_button.text = "Restaurar desde papelera"
	restore_button.pressed.connect(_on_restore_pressed)
	left.add_child(restore_button)

	move_list = ItemList.new()
	move_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	move_list.item_selected.connect(_on_list_selected)
	left.add_child(move_list)

	var right: VBoxContainer = VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.size_flags_vertical = Control.SIZE_EXPAND_FILL
	split.add_child(right)

	var properties_title: Label = Label.new()
	properties_title.text = "✏ Propiedades de MoveData"
	properties_title.add_theme_font_size_override("font_size", 15)
	right.add_child(properties_title)

	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	right.add_child(scroll)
	form = FORM_SCRIPT.new()
	form.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	form.changed.connect(_on_form_changed)
	scroll.add_child(form)

	var bottom: HBoxContainer = HBoxContainer.new()
	right.add_child(bottom)
	save_button = Button.new()
	save_button.text = "💾 Guardar"
	save_button.pressed.connect(_on_save_pressed)
	bottom.add_child(save_button)
	revert_button = Button.new()
	revert_button.text = "↶ Revertir"
	revert_button.pressed.connect(_on_revert_pressed)
	bottom.add_child(revert_button)
	var validate: Button = Button.new()
	validate.text = "✓ Validar"
	validate.pressed.connect(_on_validate_pressed)
	bottom.add_child(validate)

	status_label = Label.new()
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.custom_minimum_size = Vector2(0, 34)
	right.add_child(status_label)

	restore_menu = PopupMenu.new()
	restore_menu.id_pressed.connect(_on_restore_option)
	add_child(restore_menu)
	_create_dialogs()
	_update_buttons()
	split.split_offset = 245

func _create_dialogs() -> void:
	create_dialog = ConfirmationDialog.new()
	create_dialog.title = "Crear movimiento"
	create_dialog.ok_button_text = "Crear"
	create_dialog.cancel_button_text = "Cancelar"
	create_dialog.confirmed.connect(_on_create_confirmed)
	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	create_dialog.add_child(box)
	var name_label: Label = Label.new()
	name_label.text = "Nombre visible"
	box.add_child(name_label)
	create_name_input = LineEdit.new()
	create_name_input.placeholder_text = "Ejemplo: Rayo de prueba"
	box.add_child(create_name_input)
	var id_label: Label = Label.new()
	id_label.text = "ID (de Moves.MoveId)"
	box.add_child(id_label)
	create_id_input = SpinBox.new()
	create_id_input.min_value = 1
	create_id_input.max_value = 9999
	create_id_input.step = 1
	box.add_child(create_id_input)
	add_child(create_dialog)

	trash_dialog = ConfirmationDialog.new()
	trash_dialog.title = "Enviar movimiento a la papelera"
	trash_dialog.ok_button_text = "Mover"
	trash_dialog.cancel_button_text = "Cancelar"
	trash_dialog.confirmed.connect(_on_trash_confirmed)
	add_child(trash_dialog)

	discard_dialog = ConfirmationDialog.new()
	discard_dialog.title = "Cambios sin guardar"
	discard_dialog.dialog_text = "Hay cambios sin guardar. ¿Descartarlos?"
	discard_dialog.ok_button_text = "Descartar"
	discard_dialog.cancel_button_text = "Cancelar"
	discard_dialog.confirmed.connect(_discard_and_load_pending)
	add_child(discard_dialog)

func reload_moves() -> void:
	if not is_ready:
		return
	all_entries = repository.load_all()
	_refresh_list()
	_update_buttons()
	var errors: Array[String] = repository.get_errors()
	if errors.is_empty():
		_show_status("✓ %d movimientos cargados" % all_entries.size(), 2.0)
	else:
		_show_status("⚠ %d problemas al cargar movimientos (ver consola)" % errors.size(), 4.0)
		for error: String in errors:
			push_warning("Move Editor: " + error)

func _refresh_list() -> void:
	if move_list == null:
		return
	move_list.clear()
	var query: String = search_box.text.strip_edges().to_lower() if search_box else ""
	for entry: Dictionary in all_entries:
		var id_text: String = str(int(entry.get("id", 0)))
		var move_name: String = str(entry.get("name", ""))
		if not query.is_empty() and not id_text.contains(query) and not move_name.to_lower().contains(query):
			continue
		var suffix: String = " ⚠" if not bool(entry.get("valid", true)) else ""
		var item_index: int = move_list.add_item("[%s] %s%s" % [id_text, move_name, suffix])
		move_list.set_item_metadata(item_index, str(entry.get("path", "")))

func _on_search_changed(_text: String) -> void:
	_refresh_list()

func _on_list_selected(index: int) -> void:
	if index < 0 or index >= move_list.item_count:
		return
	var path: String = str(move_list.get_item_metadata(index))
	if path.is_empty():
		return
	if has_unsaved_changes and path != selected_path:
		pending_path = path
		discard_dialog.popup_centered(Vector2i(360, 150))
		return
	_load_from_path(path)

func _load_from_path(path: String) -> void:
	var resource: Resource = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE)
	if resource == null or not resource is MoveData:
		_show_status("✗ No se pudo cargar: %s" % path, 3.0)
		return
	selected_path = path
	selected_move = resource as MoveData
	has_unsaved_changes = false
	form.load_move(selected_move)
	_update_buttons()
	_show_status("Seleccionado: %s" % selected_move.move_name, 2.0)

func _discard_and_load_pending() -> void:
	has_unsaved_changes = false
	var path: String = pending_path
	pending_path = ""
	if not path.is_empty():
		_load_from_path(path)

func _on_form_changed() -> void:
	if not form.rebuilding:
		has_unsaved_changes = true
		_update_buttons()

func _on_save_pressed() -> void:
	if selected_move == null or selected_path.is_empty():
		return
	var errors: Array[String] = form.validate_current()
	if not errors.is_empty():
		_show_status("✗ No se guardó: " + errors[0], 4.0)
		return
	var save_error: Error = ResourceSaver.save(selected_move, selected_path)
	if save_error != OK:
		_show_status("✗ No se pudo guardar el recurso (%s)" % save_error, 4.0)
		return
	has_unsaved_changes = false
	EditorInterface.get_resource_filesystem().scan()
	reload_moves()
	_load_from_path(selected_path)
	_show_status("✓ Movimiento guardado", 2.0)

func _on_revert_pressed() -> void:
	if selected_path.is_empty():
		return
	_load_from_path(selected_path)
	_show_status("Cambios descartados", 2.0)

func _on_validate_pressed() -> void:
	if selected_move == null:
		_show_status("Selecciona un movimiento para validar", 2.0)
		return
	var errors: Array[String] = form.validate_current()
	if errors.is_empty():
		_show_status("✓ MoveData válido", 2.0)
	else:
		_show_status("✗ %d errores: %s" % [errors.size(), errors[0]], 4.0)

func _on_new_pressed() -> void:
	create_as_duplicate = false
	create_dialog.title = "Crear movimiento"
	create_name_input.text = "Nuevo movimiento"
	create_id_input.value = _next_move_id()
	create_dialog.popup_centered(Vector2i(390, 230))
	create_name_input.grab_focus()

func _on_duplicate_pressed() -> void:
	if selected_move == null:
		_show_status("Selecciona un movimiento para duplicarlo", 2.0)
		return
	create_as_duplicate = true
	create_dialog.title = "Duplicar movimiento"
	create_name_input.text = selected_move.move_name + " Copy"
	create_id_input.value = _next_move_id()
	create_dialog.popup_centered(Vector2i(390, 230))
	create_name_input.grab_focus()

func _on_create_confirmed() -> void:
	var move_name: String = create_name_input.text.strip_edges()
	var new_id: int = int(create_id_input.value)
	if move_name.is_empty():
		_show_status("El nombre no puede estar vacío", 3.0)
		return
	if not _move_id_is_declared(new_id) or _id_is_used(new_id):
		_show_status("El ID debe existir en Moves.MoveId y no estar ocupado", 3.0)
		return
	var data: MoveData
	if create_as_duplicate and selected_move != null:
		form.apply_to_move(selected_move)
		data = selected_move.duplicate(true) as MoveData
	else:
		data = _make_template()
	data.move_id = new_id as Moves.MoveId
	data.move_name = move_name
	var folder_error: Error = DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(CUSTOM_MOVE_PATH))
	if folder_error != OK and folder_error != ERR_ALREADY_EXISTS:
		_show_status("No se pudo crear la carpeta custom", 3.0)
		return
	var file_path: String = CUSTOM_MOVE_PATH.path_join("custom_%d_%s.tres" % [new_id, catalog.make_slug(move_name)])
	if FileAccess.file_exists(file_path):
		_show_status("Ya existe un archivo con ese nombre", 3.0)
		return
	var validation: Array[String] = data._validate()
	if not validation.is_empty():
		_show_status("La plantilla no es válida: " + validation[0], 3.0)
		return
	var save_error: Error = ResourceSaver.save(data, file_path)
	if save_error != OK:
		_show_status("No se pudo guardar el nuevo movimiento", 3.0)
		return
	EditorInterface.get_resource_filesystem().scan()
	reload_moves()
	_load_from_path(file_path)
	_show_status("✓ Movimiento creado", 2.0)

func _make_template() -> MoveData:
	var data: MoveData = MoveData.new()
	data.type = PokemonData.Type.TYPE_NORMAL
	data.category = MoveStruct.DamageCategory.PHYSICAL
	data.target = MoveStruct.MoveTarget.TARGET_SELECTED
	data.effect = MoveStruct.MoveEffect.EFFECT_HIT
	data.secondary_effect = MoveStruct.SecondaryEffect.MOVE_EFFECT_NONE
	data.z_effect = MoveStruct.ZEffect.Z_EFFECT_NONE
	data.description = "Descripción del nuevo movimiento."
	data.power = 40
	data.accuracy = 100
	data.pp = 35
	data.min_hits = 1
	data.max_hits = 1
	return data

func _next_move_id() -> int:
	var values: Array = Moves.MoveId.values()
	for value: Variant in values:
		var id: int = int(value)
		if id > 0 and not _id_is_used(id):
			return id
	return 1

func _move_id_is_declared(value: int) -> bool:
	return value in Moves.MoveId.values()

func _id_is_used(value: int) -> bool:
	for entry: Dictionary in all_entries:
		if int(entry.get("id", 0)) == value:
			return true
	return false

func _id_is_used_elsewhere(value: int, ignored_path: String) -> bool:
	for entry: Dictionary in all_entries:
		if int(entry.get("id", 0)) == value and str(entry.get("path", "")) != ignored_path:
			return true
	return false

func _on_trash_pressed() -> void:
	if selected_move == null or selected_path.is_empty():
		_show_status("Selecciona un movimiento para enviarlo a la papelera", 2.0)
		return
	if not selected_path.begins_with(CUSTOM_MOVE_PATH):
		_show_status("Por seguridad, solo se pueden mover movimientos custom", 3.0)
		return
	trash_dialog.dialog_text = "¿Mover '%s' a la papelera?\nNo se eliminará definitivamente." % selected_move.move_name
	trash_dialog.popup_centered(Vector2i(390, 170))

func _on_trash_confirmed() -> void:
	var old_path: String = selected_path
	if old_path.is_empty():
		return
	var error: Error = DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(MOVE_TRASH_PATH))
	if error != OK and error != ERR_ALREADY_EXISTS:
		_show_status("No se pudo crear la papelera", 3.0)
		return
	var destination: String = MOVE_TRASH_PATH.path_join("%d__%s" % [Time.get_unix_time_from_system(), old_path.get_file()])
	var move_error: Error = DirAccess.rename_absolute(ProjectSettings.globalize_path(old_path), ProjectSettings.globalize_path(destination))
	if move_error != OK:
		_show_status("No se pudo mover el movimiento a la papelera", 3.0)
		return
	selected_move = null
	selected_path = ""
	has_unsaved_changes = false
	form.load_move(null)
	EditorInterface.get_resource_filesystem().scan()
	reload_moves()
	_show_status("✓ Movimiento enviado a la papelera", 2.0)

func _on_restore_pressed() -> void:
	restore_menu.clear()
	var paths: Array[String] = repository.list_trash(MOVE_TRASH_PATH)
	if paths.is_empty():
		_show_status("La papelera está vacía", 2.0)
		return
	for index: int in range(paths.size()):
		restore_menu.add_item(paths[index].get_file(), index)
		restore_menu.set_item_metadata(index, paths[index])
	restore_menu.popup()

func _on_restore_option(index: int) -> void:
	var source: String = str(restore_menu.get_item_metadata(index))
	if source.is_empty():
		return
	var trash_name: String = source.get_file()
	var marker: int = trash_name.find("__")
	var original_name: String = trash_name.substr(marker + 2) if marker >= 0 else trash_name
	var destination: String = CUSTOM_MOVE_PATH.path_join(original_name)
	if FileAccess.file_exists(destination):
		_show_status("Ya existe un movimiento con ese archivo", 3.0)
		return
	var trashed_resource: Resource = ResourceLoader.load(source, "", ResourceLoader.CACHE_MODE_IGNORE)
	if trashed_resource is MoveData and _id_is_used_elsewhere(int((trashed_resource as MoveData).move_id), source):
		_show_status("No se puede restaurar: el ID ya está ocupado", 3.0)
		return
	var folder_error: Error = DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(CUSTOM_MOVE_PATH))
	if folder_error != OK and folder_error != ERR_ALREADY_EXISTS:
		_show_status("No se pudo crear la carpeta custom", 3.0)
		return
	var move_error: Error = DirAccess.rename_absolute(ProjectSettings.globalize_path(source), ProjectSettings.globalize_path(destination))
	if move_error != OK:
		_show_status("No se pudo restaurar el movimiento", 3.0)
		return
	EditorInterface.get_resource_filesystem().scan()
	reload_moves()
	_load_from_path(destination)
	_show_status("✓ Movimiento restaurado", 2.0)

func _update_buttons() -> void:
	if save_button == null:
		return
	save_button.disabled = selected_move == null or selected_path.is_empty() or not has_unsaved_changes
	revert_button.disabled = selected_move == null or not has_unsaved_changes
	duplicate_button.disabled = selected_move == null
	trash_button.disabled = selected_move == null or selected_path.is_empty()

func _show_status(message: String, _duration: float = 2.0) -> void:
	if status_label != null:
		status_label.text = message
