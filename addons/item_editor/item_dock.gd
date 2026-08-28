@tool
extends Control

## Bottom-panel editor for ItemData resources.
class_name ItemEditorDock

const REPOSITORY_SCRIPT := preload("res://addons/item_editor/item_repository.gd")
const CATALOG_SCRIPT := preload("res://addons/item_editor/item_catalog.gd")
const VALIDATOR_SCRIPT := preload("res://addons/item_editor/item_validator.gd")
const FORM_SCRIPT := preload("res://addons/item_editor/item_form.gd")

const CUSTOM_PATH: String = "res://data_core/items/resources/custom/"

var repository: ItemEditorRepository
var catalog: ItemEditorCatalog
var validator: ItemEditorValidator
var form_panel: ItemEditorForm

var search_box: LineEdit
var item_list: ItemList
var status_label: Label
var status_timer: Timer
var save_button: Button
var revert_button: Button
var duplicate_button: Button
var delete_button: Button
var restore_button: Button
var validate_button: Button
var trash_popup: PopupMenu
var discard_dialog: ConfirmationDialog
var create_dialog: ConfirmationDialog
var delete_dialog: ConfirmationDialog
var create_name_input: LineEdit
var create_id_option: OptionButton
var create_as_duplicate: bool = false

var records: Array[Dictionary] = []
var selected_item: ItemData
var selected_path: String = ""
var pending_path: String = ""
var has_unsaved_changes: bool = false
var is_ready: bool = false

func _init() -> void:
	name = "🧰 Item Editor"
	custom_minimum_size = Vector2(760, 520)
	repository = REPOSITORY_SCRIPT.new()
	catalog = CATALOG_SCRIPT.new()
	validator = VALIDATOR_SCRIPT.new()

func _ready() -> void:
	_build_ui()
	is_ready = true
	call_deferred("_load_items")

func _build_ui() -> void:
	var split: HSplitContainer = HSplitContainer.new()
	split.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(split)

	var left: VBoxContainer = VBoxContainer.new()
	left.custom_minimum_size = Vector2(275, 0)
	left.size_flags_vertical = Control.SIZE_EXPAND_FILL
	split.add_child(left)

	var title: Label = Label.new()
	title.text = "📋 Catálogo de ítems"
	title.add_theme_font_size_override("font_size", 14)
	left.add_child(title)

	search_box = LineEdit.new()
	search_box.placeholder_text = "Buscar por ID, nombre o efecto..."
	search_box.clear_button_enabled = true
	search_box.text_changed.connect(_on_search_changed)
	left.add_child(search_box)

	var refresh: Button = Button.new()
	refresh.text = "↻ Recargar catálogo"
	refresh.pressed.connect(_load_items)
	left.add_child(refresh)

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
	delete_button = Button.new()
	delete_button.text = "Papelera"
	delete_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	delete_button.pressed.connect(_on_delete_pressed)
	actions.add_child(delete_button)

	restore_button = Button.new()
	restore_button.text = "♻ Restaurar desde papelera"
	restore_button.pressed.connect(_on_restore_pressed)
	left.add_child(restore_button)

	item_list = ItemList.new()
	item_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	item_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	item_list.item_selected.connect(_on_item_selected)
	left.add_child(item_list)

	var right: VBoxContainer = VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.size_flags_vertical = Control.SIZE_EXPAND_FILL
	split.add_child(right)
	var properties: Label = Label.new()
	properties.text = "✏️ Propiedades de ItemData"
	properties.add_theme_font_size_override("font_size", 14)
	right.add_child(properties)

	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	right.add_child(scroll)
	form_panel = FORM_SCRIPT.new()
	form_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	form_panel.changed.connect(_on_form_changed)
	scroll.add_child(form_panel)

	var footer: HBoxContainer = HBoxContainer.new()
	right.add_child(footer)
	save_button = _make_button("💾 Guardar", _on_save_pressed)
	footer.add_child(save_button)
	revert_button = _make_button("↶ Revertir", _on_revert_pressed)
	footer.add_child(revert_button)
	validate_button = _make_button("✓ Validar", _on_validate_pressed)
	footer.add_child(validate_button)

	status_label = Label.new()
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	right.add_child(status_label)
	status_timer = Timer.new()
	status_timer.one_shot = true
	status_timer.timeout.connect(func() -> void:
		if is_instance_valid(status_label):
			status_label.text = "Listo"
	)
	add_child(status_timer)

	trash_popup = PopupMenu.new()
	trash_popup.id_pressed.connect(_on_restore_option_selected)
	add_child(trash_popup)
	_create_dialogs()
	_update_buttons()
	split.split_offset = 275

func _make_button(text: String, callback: Callable) -> Button:
	var button: Button = Button.new()
	button.text = text
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.pressed.connect(callback)
	return button

func _create_dialogs() -> void:
	discard_dialog = ConfirmationDialog.new()
	discard_dialog.title = "Cambios sin guardar"
	discard_dialog.dialog_text = "Hay cambios sin guardar. ¿Descartarlos?"
	discard_dialog.ok_button_text = "Descartar"
	discard_dialog.confirmed.connect(_discard_and_load_pending)
	discard_dialog.canceled.connect(func() -> void: pending_path = "")
	add_child(discard_dialog)

	create_dialog = ConfirmationDialog.new()
	create_dialog.title = "Crear ítem"
	create_dialog.ok_button_text = "Crear"
	create_dialog.cancel_button_text = "Cancelar"
	create_dialog.confirmed.connect(_on_create_confirmed)
	var create_box: VBoxContainer = VBoxContainer.new()
	create_box.add_theme_constant_override("separation", 6)
	create_dialog.add_child(create_box)
	var name_label: Label = Label.new()
	name_label.text = "Nombre"
	create_box.add_child(name_label)
	create_name_input = LineEdit.new()
	create_name_input.placeholder_text = "Ejemplo: Medalla de prueba"
	create_box.add_child(create_name_input)
	var id_label: Label = Label.new()
	id_label.text = "ID (debe pertenecer a Items.ItemId)"
	create_box.add_child(id_label)
	create_id_option = OptionButton.new()
	create_id_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	create_box.add_child(create_id_option)
	add_child(create_dialog)

	delete_dialog = ConfirmationDialog.new()
	delete_dialog.title = "Enviar ítem a la papelera"
	delete_dialog.ok_button_text = "Mover"
	delete_dialog.cancel_button_text = "Cancelar"
	delete_dialog.confirmed.connect(_on_delete_confirmed)
	add_child(delete_dialog)

func _load_items() -> void:
	if not is_ready and not is_inside_tree():
		return
	catalog.reload()
	records = repository.load_all()
	_refresh_list()
	_update_buttons()
	var problem_count: int = repository.get_errors().size() + catalog.get_errors().size()
	if problem_count > 0:
		_show_status("⚠ %d problemas encontrados; revisa la consola." % problem_count, 4.0)
	else:
		_show_status("✓ %d ítems cargados" % records.size(), 2.0)

func _refresh_list() -> void:
	if item_list == null:
		return
	item_list.clear()
	var query: String = search_box.text.strip_edges().to_lower() if search_box else ""
	for record: Dictionary in records:
		var item: ItemData = record.get("item") as ItemData
		if item == null:
			continue
		var id_text: String = str(int(item.item_id))
		var haystack: String = "%s %s %s %s %s" % [
			id_text, item.item_name, item.plural_name,
			_enum_text(Items.ItemType.keys(), Items.ItemType.values(), item.item_type),
			_enum_text(Items.EffectItem.keys(), Items.EffectItem.values(), item.effect)
		]
		if not query.is_empty() and not haystack.to_lower().contains(query):
			continue
		var index: int = item_list.add_item(
			"[%d] %s" % [int(item.item_id), item.item_name], item.icon, true
		)
		item_list.set_item_metadata(index, str(record.get("path", "")))

func _enum_text(keys: Array, values: Array, value: Variant) -> String:
	var numeric_value: int = _enum_int(value)
	for index: int in range(values.size()):
		if int(values[index]) == numeric_value:
			return str(keys[index])
	return "SIN EFECTO" if numeric_value == 0 else "UNKNOWN (%d)" % numeric_value

func _enum_int(value: Variant) -> int:
	# `Items.EffectItem` sin un miembro produjo el diccionario del enum.
	return 0 if value is Dictionary else int(value)

func _on_search_changed(_text: String) -> void:
	_refresh_list()

func _on_item_selected(index: int) -> void:
	if index < 0 or index >= item_list.item_count:
		return
	var path: String = str(item_list.get_item_metadata(index))
	if path.is_empty():
		return
	if has_unsaved_changes and path != selected_path:
		pending_path = path
		discard_dialog.popup_centered()
		return
	_load_item_from_path(path)

func _load_item_from_path(path: String, force_reload: bool = true) -> void:
	var item: ItemData = repository.get_item_at(path, force_reload)
	if item == null:
		_show_status("✗ No se pudo cargar: %s" % path, 3.0)
		return
	selected_item = item
	selected_path = path
	has_unsaved_changes = false
	form_panel.set_item(item)
	_update_buttons()
	_show_status("Seleccionado: %s" % item.item_name, 2.0)

func _discard_and_load_pending() -> void:
	has_unsaved_changes = false
	var path: String = pending_path
	pending_path = ""
	if not path.is_empty():
		_load_item_from_path(path)

func _on_form_changed() -> void:
	if selected_item == null or not is_instance_valid(form_panel):
		return
	has_unsaved_changes = true
	_update_buttons()
	_show_status("⚠ Cambios sin guardar", 2.0)

func _on_save_pressed() -> void:
	if selected_item == null or selected_path.is_empty():
		_show_status("✗ No hay ítem seleccionado", 2.0)
		return
	if not form_panel.apply_to_item(selected_item):
		_show_status("✗ No se pudieron aplicar los campos", 3.0)
		return
	var errors: Array[String] = validator.validate(selected_item, repository, selected_path)
	if not errors.is_empty():
		_show_status("✗ %d errores de validación; revisa la consola" % errors.size(), 4.0)
		push_warning("Item Editor:\n" + "\n".join(errors))
		return
	var result: Error = repository.save_item(selected_item, selected_path)
	if result != OK:
		_show_status("✗ Error al guardar: %s" % error_string(result), 3.0)
		return
	has_unsaved_changes = false
	EditorInterface.get_resource_filesystem().scan()
	_load_items()
	_update_buttons()
	_show_status("✓ Guardado: %s" % selected_item.item_name, 3.0)

func _on_revert_pressed() -> void:
	if not selected_path.is_empty():
		_load_item_from_path(selected_path, true)

func _on_validate_pressed() -> void:
	if selected_item == null:
		_show_status("No hay ítem seleccionado", 2.0)
		return
	if has_unsaved_changes:
		form_panel.apply_to_item(selected_item)
	var errors: Array[String] = validator.validate(selected_item, repository, selected_path)
	if errors.is_empty():
		_show_status("✓ Validación correcta", 2.0)
	else:
		_show_status("✗ %d errores; revisa la consola" % errors.size(), 4.0)
		push_warning("Item Editor:\n" + "\n".join(errors))

func _on_new_pressed() -> void:
	_open_create_dialog(false)

func _on_duplicate_pressed() -> void:
	if selected_item == null:
		_show_status("Selecciona un ítem para duplicarlo", 2.0)
		return
	_open_create_dialog(true)

func _open_create_dialog(as_duplicate: bool) -> void:
	create_as_duplicate = as_duplicate
	create_dialog.title = "Duplicar ítem" if as_duplicate else "Crear ítem"
	create_name_input.text = (selected_item.item_name + " Copy") if as_duplicate and selected_item else "Nuevo ítem"
	_create_id_options()
	create_dialog.popup_centered(Vector2i(440, 250))
	create_name_input.grab_focus()

func _create_id_options() -> void:
	create_id_option.clear()
	var selected_index: int = -1
	var wanted: int = repository.next_available_id()
	for value: int in catalog.enum_ids():
		if value <= 0 or repository.id_is_used(value):
			continue
		create_id_option.add_item("[%d] %s" % [value, _item_enum_name(value)], value)
		if value == wanted:
			selected_index = create_id_option.get_item_count() - 1
	if selected_index >= 0:
		create_id_option.select(selected_index)
	create_dialog.get_ok_button().disabled = selected_index < 0

func _item_enum_name(value: int) -> String:
	var keys: Array = Items.ItemId.keys()
	var values: Array = Items.ItemId.values()
	for index: int in range(values.size()):
		if int(values[index]) == value:
			return _pretty(str(keys[index]))
	return "UNKNOWN"

func _on_create_confirmed() -> void:
	var item_name: String = create_name_input.text.strip_edges()
	var new_id: int = create_id_option.get_selected_id()
	if item_name.is_empty() or new_id <= 0 or not catalog.enum_ids().has(new_id) or repository.id_is_used(new_id):
		_show_status("El nombre o el ID no es válido/disponible", 3.0)
		return
	var data: ItemData
	if create_as_duplicate and selected_item != null:
		if has_unsaved_changes:
			if not form_panel.apply_to_item(selected_item):
				_show_status("No se pudieron aplicar cambios antes de duplicar", 3.0)
				return
		data = selected_item.duplicate(true) as ItemData
	else:
		data = _make_template()
	data.item_id = new_id as Items.ItemId
	data.item_name = item_name
	data.plural_name = item_name
	if not create_as_duplicate:
		data.item_description = "Descripción pendiente."
	var directory_error: Error = repository.make_directory(CUSTOM_PATH)
	if directory_error != OK and directory_error != ERR_ALREADY_EXISTS:
		_show_status("No se pudo crear la carpeta custom", 3.0)
		return
	var path: String = CUSTOM_PATH.path_join("custom_%d_%s.tres" % [new_id, _slugify(item_name)])
	if FileAccess.file_exists(path):
		_show_status("Ya existe un archivo con ese nombre", 3.0)
		return
	var save_error: Error = repository.save_item(data, path)
	if save_error != OK:
		_show_status("No se pudo guardar el nuevo ítem: %s" % error_string(save_error), 3.0)
		return
	EditorInterface.get_resource_filesystem().scan()
	_load_items()
	_load_item_from_path(path, true)
	_show_status("✓ Ítem creado", 2.0)

func _make_template() -> ItemData:
	var data: ItemData = ItemData.new()
	data.item_id = Items.ItemId.ITEM_NONE
	data.secondary_id = 0
	data.item_name = "Nuevo ítem"
	data.plural_name = "Nuevos ítems"
	data.item_description = "Descripción pendiente."
	data.price = 0
	data.pocket = ItemConstants.Pocket.POCKET_ITEMS
	data.item_type = Items.ItemType.ITEM_USE_FIELD
	data.hold_effect = HoldEffects.HoldEffect.HOLD_EFFECT_NONE
	data.hold_effect_param = 0
	data.battle_usage = Items.BattleUsage.NONE
	data.fling_power = 0
	data.importance = false
	data.not_consumed = false
	data.effect = 0 as Items.EffectItem
	return data

func _on_delete_pressed() -> void:
	if selected_item == null or selected_path.is_empty():
		_show_status("Selecciona un ítem para enviarlo a la papelera", 2.0)
		return
	if has_unsaved_changes:
		_show_status("Guarda o revierte los cambios antes de moverlo", 3.0)
		return
	if not selected_path.begins_with(CUSTOM_PATH):
		_show_status("Por seguridad, solo se pueden mover ítems custom", 3.0)
		return
	delete_dialog.dialog_text = "¿Mover '%s' a la papelera?\n\nNo se eliminará definitivamente." % selected_item.item_name
	delete_dialog.popup_centered()

func _on_delete_confirmed() -> void:
	var destination: String = repository.move_to_trash(selected_path)
	if destination.is_empty():
		_show_status("✗ No se pudo mover el ítem a la papelera", 3.0)
		return
	selected_item = null
	selected_path = ""
	has_unsaved_changes = false
	form_panel.set_item(null)
	EditorInterface.get_resource_filesystem().scan()
	_load_items()
	_show_status("✓ Ítem movido a la papelera", 2.0)

func _on_restore_pressed() -> void:
	trash_popup.clear()
	var paths: Array[String] = repository.list_trash()
	if paths.is_empty():
		_show_status("La papelera está vacía", 2.0)
		return
	for index: int in range(paths.size()):
		trash_popup.add_item(paths[index].get_file(), index)
		trash_popup.set_item_metadata(index, paths[index])
	var button_rect: Rect2 = restore_button.get_global_rect()
	trash_popup.popup(Rect2(button_rect.position + Vector2(0, button_rect.size.y), Vector2(360, 0)))

func _on_restore_option_selected(index: int) -> void:
	if index < 0 or index >= trash_popup.item_count:
		return
	var trash_path: String = str(trash_popup.get_item_metadata(index))
	var destination: String = repository.restore_from_trash(trash_path)
	if destination.is_empty():
		_show_status("No se pudo restaurar (¿ya existe el archivo?)", 3.0)
		return
	EditorInterface.get_resource_filesystem().scan()
	_load_items()
	_load_item_from_path(destination, true)
	_show_status("✓ Ítem restaurado", 2.0)

func _update_buttons() -> void:
	if save_button:
		save_button.disabled = selected_item == null or not has_unsaved_changes
	if revert_button:
		revert_button.disabled = selected_item == null or not has_unsaved_changes
	if duplicate_button:
		duplicate_button.disabled = selected_item == null
	if delete_button:
		delete_button.disabled = selected_item == null or selected_path.is_empty()
	if restore_button:
		restore_button.disabled = false

func _show_status(message: String, duration: float = 0.0) -> void:
	if status_label == null:
		return
	status_label.text = message
	if duration > 0.0:
		status_timer.start(duration)

func _pretty(raw: String) -> String:
	var value: String = raw
	for prefix: String in ["ITEM_", "POCKET_", "ITEM_USE_", "HOLD_EFFECT_"]:
		if value.begins_with(prefix):
			value = value.trim_prefix(prefix)
	return value.replace("_", " ").to_lower().capitalize()

func _slugify(value: String) -> String:
	var result: String = value.to_lower().strip_edges().replace(" ", "_").replace("-", "_")
	var clean: String = ""
	for character: String in result:
		if character.is_valid_identifier() or character == "_":
			clean += character
	return clean if not clean.is_empty() else "item"
