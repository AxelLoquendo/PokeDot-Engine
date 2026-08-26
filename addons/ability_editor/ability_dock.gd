@tool
extends Control
class_name AbilityEditorDock

const CATALOG_SCRIPT := preload("res://addons/ability_editor/ability_catalog.gd")
const FORM_SCRIPT := preload("res://addons/ability_editor/ability_form.gd")
const VALIDATOR_SCRIPT := preload("res://addons/ability_editor/ability_validator.gd")

var catalog: AbilityEditorCatalog
var validator: AbilityEditorValidator
var form: AbilityEditorForm
var search_box: LineEdit
var ability_list: ItemList
var status_label: Label
var title_label: Label
var save_button: Button
var revert_button: Button
var duplicate_button: Button
var trash_button: Button
var restore_button: Button
var show_trash_button: CheckButton
var create_dialog: ConfirmationDialog
var create_name_input: LineEdit
var create_id_input: SpinBox
var create_generation_input: SpinBox
var delete_dialog: ConfirmationDialog
var discard_dialog: ConfirmationDialog

var records: Array[Dictionary] = []
var visible_records: Array[Dictionary] = []
var current_record: Dictionary = {}
var current_data: AbilityData
var current_path := ""
var pending_record: Dictionary = {}
var pending_reload := false
var has_unsaved_changes := false
var _loading := false

func _init() -> void:
	name = "⚙ Ability Editor"
	custom_minimum_size = Vector2(820, 560)
	catalog = CATALOG_SCRIPT.new()
	validator = VALIDATOR_SCRIPT.new()

func _ready() -> void:
	_build_ui()
	call_deferred("_load_catalog")

func _build_ui() -> void:
	var split := HSplitContainer.new()
	split.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(split)

	var left := VBoxContainer.new()
	left.custom_minimum_size = Vector2(280, 0)
	left.size_flags_vertical = Control.SIZE_EXPAND_FILL
	split.add_child(left)

	title_label = Label.new()
	title_label.text = "⚙ Habilidades"
	title_label.add_theme_font_size_override("font_size", 15)
	left.add_child(title_label)

	search_box = LineEdit.new()
	search_box.placeholder_text = "Buscar por ID, enum o name_key..."
	search_box.clear_button_enabled = true
	search_box.text_changed.connect(_on_search_changed)
	left.add_child(search_box)

	var list_actions := HBoxContainer.new()
	left.add_child(list_actions)
	var refresh := Button.new()
	refresh.text = "↻ Recargar"
	refresh.tooltip_text = "Volver a escanear recursos del proyecto"
	refresh.pressed.connect(_reload_catalog)
	list_actions.add_child(refresh)
	show_trash_button = CheckButton.new()
	show_trash_button.text = "Papelera"
	show_trash_button.tooltip_text = "Mostrar recursos enviados a la papelera"
	show_trash_button.toggled.connect(func(_pressed: bool) -> void: _render_list())
	list_actions.add_child(show_trash_button)

	var crud := HBoxContainer.new()
	left.add_child(crud)
	var new_button := Button.new()
	new_button.text = "+ Nueva"
	new_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	new_button.pressed.connect(_open_create_dialog)
	crud.add_child(new_button)
	duplicate_button = Button.new()
	duplicate_button.text = "Duplicar"
	duplicate_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	duplicate_button.pressed.connect(_duplicate_current)
	crud.add_child(duplicate_button)

	ability_list = ItemList.new()
	ability_list.select_mode = ItemList.SELECT_SINGLE
	ability_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	ability_list.item_selected.connect(_on_item_selected)
	left.add_child(ability_list)

	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.size_flags_vertical = Control.SIZE_EXPAND_FILL
	split.add_child(right)
	var heading := Label.new()
	heading.text = "Selecciona una habilidad"
	heading.add_theme_font_size_override("font_size", 15)
	right.add_child(heading)

	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_child(scroll)
	form = FORM_SCRIPT.new()
	form.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	form.form_changed.connect(_on_form_changed)
	form.set_catalog(catalog)
	scroll.add_child(form)

	var editor_actions := HBoxContainer.new()
	right.add_child(editor_actions)
	save_button = Button.new()
	save_button.text = "💾 Guardar"
	save_button.tooltip_text = "Validar y guardar el recurso actual"
	save_button.pressed.connect(_save_current)
	editor_actions.add_child(save_button)
	revert_button = Button.new()
	revert_button.text = "↶ Revertir"
	revert_button.pressed.connect(_revert_current)
	editor_actions.add_child(revert_button)
	var validate := Button.new()
	validate.text = "✓ Validar"
	validate.pressed.connect(_validate_current)
	editor_actions.add_child(validate)
	trash_button = Button.new()
	trash_button.text = "🗑 Papelera"
	trash_button.pressed.connect(_open_delete_dialog)
	editor_actions.add_child(trash_button)
	restore_button = Button.new()
	restore_button.text = "↥ Restaurar"
	restore_button.pressed.connect(_restore_current)
	editor_actions.add_child(restore_button)

	status_label = Label.new()
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.custom_minimum_size = Vector2(0, 42)
	right.add_child(status_label)

	_create_dialogs()
	split.split_offset = 280
	_update_buttons()

func _create_dialogs() -> void:
	create_dialog = ConfirmationDialog.new()
	create_dialog.title = "Crear habilidad"
	create_dialog.ok_button_text = "Crear"
	create_dialog.cancel_button_text = "Cancelar"
	create_dialog.confirmed.connect(_create_confirmed)
	var create_box := VBoxContainer.new()
	create_box.add_theme_constant_override("separation", 6)
	create_dialog.add_child(create_box)
	create_box.add_child(_dialog_label("name_key (requerido)"))
	create_name_input = LineEdit.new()
	create_name_input.placeholder_text = "ability.my_ability"
	create_box.add_child(create_name_input)
	create_box.add_child(_dialog_label("ID (AbilityId.Id, no repetido)"))
	create_id_input = SpinBox.new()
	create_id_input.min_value = 1
	create_id_input.max_value = int(AbilityId.Id.COUNT) - 1
	create_id_input.step = 1
	create_box.add_child(create_id_input)
	create_box.add_child(_dialog_label("Generación"))
	create_generation_input = SpinBox.new()
	create_generation_input.min_value = 1
	create_generation_input.max_value = 99
	create_generation_input.step = 1
	create_generation_input.value = 1
	create_box.add_child(create_generation_input)
	add_child(create_dialog)

	delete_dialog = ConfirmationDialog.new()
	delete_dialog.title = "Mover a la papelera"
	delete_dialog.ok_button_text = "Mover"
	delete_dialog.cancel_button_text = "Cancelar"
	delete_dialog.confirmed.connect(_delete_confirmed)
	add_child(delete_dialog)

	discard_dialog = ConfirmationDialog.new()
	discard_dialog.title = "Cambios sin guardar"
	discard_dialog.dialog_text = "Hay cambios sin guardar. ¿Descartarlos?"
	discard_dialog.ok_button_text = "Descartar"
	discard_dialog.cancel_button_text = "Cancelar"
	discard_dialog.confirmed.connect(_discard_pending)
	discard_dialog.canceled.connect(_cancel_discard)
	add_child(discard_dialog)

func _dialog_label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	return label

func _load_catalog() -> void:
	var preserved_path := current_path
	_loading = true
	records = catalog.load()
	_render_list()
	_loading = false
	if not preserved_path.is_empty():
		var refreshed := catalog.repository.get_record_by_path(preserved_path)
		if not refreshed.is_empty():
			_select_record(refreshed)
		else:
			current_record = {}
			current_data = null
			current_path = ""
			form.load_data(null)
			_update_buttons()
	if not catalog.load_errors.is_empty():
		_set_status("Carga completada con %d advertencia(s)." % catalog.load_errors.size(), true)
	else:
		_set_status("%d recurso(s) encontrado(s)." % records.size())

func _reload_catalog() -> void:
	if has_unsaved_changes:
		pending_record = {}
		pending_reload = true
		discard_dialog.dialog_text = "Hay cambios sin guardar. ¿Recargar y descartarlos?"
		discard_dialog.popup_centered()
		return
	_load_catalog()

func _render_list() -> void:
	if ability_list == null:
		return
	visible_records = catalog.search(search_box.text if search_box else "", show_trash_button.button_pressed if show_trash_button else false)
	ability_list.clear()
	var select_index := -1
	for index: int in range(visible_records.size()):
		var record := visible_records[index]
		var data := record.get("data") as AbilityData
		var prefix := "🗑 " if bool(record.get("trashed", false)) else ""
		var validity := " ⚠" if not bool(record.get("valid", true)) else ""
		ability_list.add_item(prefix + catalog.name_for(data) + validity)
		ability_list.set_item_tooltip(index, str(record.get("path", "")))
		if str(record.get("path", "")) == current_path:
			select_index = index
	if select_index >= 0:
		ability_list.select(select_index)
	_update_buttons()

func _on_search_changed(_text: String) -> void:
	_render_list()

func _on_item_selected(index: int) -> void:
	if index < 0 or index >= visible_records.size():
		return
	var record := visible_records[index]
	if str(record.get("path", "")) == current_path:
		return
	if has_unsaved_changes:
		pending_record = record
		discard_dialog.dialog_text = "Hay cambios sin guardar. ¿Descartarlos y abrir la selección?"
		discard_dialog.popup_centered()
		return
	_select_record(record)

func _cancel_discard() -> void:
	pending_record = {}
	pending_reload = false

func _discard_pending() -> void:
	if pending_reload or pending_record.is_empty():
		pending_reload = false
		pending_record = {}
		_load_catalog()
	else:
		has_unsaved_changes = false
		_select_record(pending_record)
		pending_record = {}
	discard_dialog.dialog_text = "Hay cambios sin guardar. ¿Descartarlos?"

func _select_record(record: Dictionary) -> void:
	_loading = true
	current_record = record
	current_path = str(record.get("path", ""))
	var source := record.get("data") as AbilityData
	current_data = source.duplicate(true) as AbilityData if source != null else null
	form.load_data(current_data)
	has_unsaved_changes = false
	_loading = false
	_render_list()
	_update_buttons()
	if current_data != null:
		_set_status(current_path)

func _on_form_changed() -> void:
	if not _loading:
		has_unsaved_changes = true
		_update_buttons()
		_set_status("Cambios sin guardar", false)

func _open_create_dialog() -> void:
	create_dialog.title = "Crear habilidad"
	create_name_input.text = "ability.new_ability"
	create_id_input.value = catalog.repository.get_next_id()
	create_generation_input.value = 1
	create_dialog.popup_centered(Vector2i(390, 250))
	create_name_input.grab_focus()

func _create_confirmed() -> void:
	var name_key := create_name_input.text.strip_edges()
	var id_value := int(create_id_input.value)
	if name_key.is_empty():
		_set_status("name_key no puede estar vacío.", true)
		return
	if id_value <= 0 or not catalog.repository.get_live_record_by_id(id_value).is_empty():
		_set_status("Ese ID ya está ocupado o no es válido.", true)
		return
	var data := AbilityData.new()
	data.id = id_value as AbilityId.Id
	data.name_key = name_key
	data.generation = int(create_generation_input.value)
	var path := catalog.repository.create(data, name_key)
	if path.is_empty():
		_set_status(_last_repository_error(), true)
		return
	catalog.reload()
	records = catalog.records
	has_unsaved_changes = false
	_render_list()
	_select_record(catalog.repository.get_record_by_path(path))
	_set_status("Creada: %s" % path)

func _duplicate_current() -> void:
	if current_data == null:
		_set_status("Selecciona una habilidad para duplicarla.", true)
		return
	if has_unsaved_changes and not form.apply_to_data(current_data):
		_set_status("No se pudo leer el formulario antes de duplicar.", true)
		return
	var duplicate_id := catalog.repository.get_next_id()
	if duplicate_id < 0:
		_set_status("No quedan IDs libres en AbilityId.Id.", true)
		return
	var path := catalog.repository.duplicate(current_data, duplicate_id, current_data.name_key + "_copy")
	if path.is_empty():
		_set_status(_last_repository_error(), true)
		return
	catalog.reload()
	records = catalog.records
	_render_list()
	_select_record(catalog.repository.get_record_by_path(path))
	_set_status("Duplicada: %s" % path)

func _save_current() -> void:
	if current_data == null or current_path.is_empty():
		_set_status("Selecciona una habilidad para guardar.", true)
		return
	if not form.apply_to_data(current_data):
		_set_status("stat_modifiers debe ser un objeto JSON válido.", true)
		return
	var errors := validator.validate(current_data, catalog)
	# The current catalog entry is itself counted by the duplicate check; a
	# duplicate id elsewhere is still caught by repository.save below.
	if not errors.is_empty():
		_set_status(validator.format_errors(errors), true)
		return
	if not catalog.repository.save(current_data, current_path):
		_set_status(_last_repository_error(), true)
		return
	has_unsaved_changes = false
	catalog.reload()
	records = catalog.records
	current_record = catalog.repository.get_record_by_path(current_path)
	_render_list()
	_update_buttons()
	_set_status("Guardada: %s" % current_path)

func _revert_current() -> void:
	if current_path.is_empty():
		return
	var record := catalog.repository.get_record_by_path(current_path)
	if record.is_empty():
		return
	_select_record(record)
	_set_status("Cambios descartados.")

func _validate_current() -> void:
	if current_data == null:
		_set_status("No hay una habilidad seleccionada.", true)
		return
	if not form.apply_to_data(current_data):
		_set_status("stat_modifiers debe ser un objeto JSON válido.", true)
		return
	var errors := validator.validate(current_data, catalog)
	_set_status(validator.format_errors(errors), not errors.is_empty())

func _open_delete_dialog() -> void:
	if current_data == null:
		_set_status("Selecciona una habilidad para enviarla a la papelera.", true)
		return
	if bool(current_record.get("trashed", false)):
		return
	delete_dialog.dialog_text = "Mover '%s' a la papelera?\n\n%s" % [catalog.name_for(current_data), current_path]
	delete_dialog.popup_centered(Vector2i(440, 180))

func _delete_confirmed() -> void:
	if has_unsaved_changes:
		_set_status("Guarda o revierte los cambios antes de mover a la papelera.", true)
		return
	if catalog.repository.move_to_trash(current_path):
		var deleted_path := current_path
		catalog.reload()
		records = catalog.records
		current_record = {}
		current_data = null
		current_path = ""
		form.load_data(null)
		_render_list()
		_set_status("Movida a la papelera: %s" % deleted_path)
	else:
		_set_status(_last_repository_error(), true)

func _restore_current() -> void:
	if current_record.is_empty() or not bool(current_record.get("trashed", false)):
		_set_status("Selecciona un recurso de la papelera para restaurarlo.", true)
		return
	if has_unsaved_changes:
		_set_status("Guarda o revierte los cambios antes de restaurar.", true)
		return
	var old_path := current_path
	var restored := catalog.repository.restore(current_path)
	if restored.is_empty():
		_set_status(_last_repository_error(), true)
		return
	catalog.reload()
	records = catalog.records
	_render_list()
	_select_record(catalog.repository.get_record_by_path(restored))
	_set_status("Restaurada desde %s" % old_path)

func _update_buttons() -> void:
	var has_data := current_data != null
	var trashed := bool(current_record.get("trashed", false))
	if save_button:
		save_button.disabled = not has_data or trashed or not has_unsaved_changes
		revert_button.disabled = not has_data or not has_unsaved_changes
		duplicate_button.disabled = not has_data or trashed
		trash_button.disabled = not has_data or trashed
		restore_button.disabled = not has_data or not trashed

func _set_status(text: String, error := false) -> void:
	if status_label == null:
		return
	status_label.text = text
	status_label.add_theme_color_override("font_color", Color(1.0, 0.48, 0.42) if error else Color(0.72, 0.86, 0.72))

func _last_repository_error() -> String:
	var errors := catalog.repository.get_errors()
	return errors.back() if not errors.is_empty() else "Operación no completada."
