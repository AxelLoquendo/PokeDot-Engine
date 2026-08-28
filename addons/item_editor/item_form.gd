@tool
extends VBoxContainer

## Dynamic form for every exported ItemData property.  Keeping the form
## explicit makes enum values and resource picker types visible in the editor,
## while avoiding a fragile reflection-based write-back layer.
class_name ItemEditorForm

signal changed

var current_item: ItemData
var fields: Dictionary = {}
var enum_fields: Dictionary = {}
var resource_fields: Dictionary = {}
var preview: TextureRect
var rebuilding: bool = false

func set_item(item: ItemData) -> void:
	current_item = item
	if is_inside_tree():
		_rebuild()

func _ready() -> void:
	_rebuild()

func _rebuild() -> void:
	rebuilding = true
	_clear_children()
	fields.clear()
	enum_fields.clear()
	resource_fields.clear()
	preview = null
	if current_item == null:
		var empty: Label = Label.new()
		empty.text = "Selecciona un ítem para editarlo."
		empty.add_theme_color_override("font_color", Color.LIGHT_GRAY)
		add_child(empty)
		rebuilding = false
		return

	_add_heading("🔖 Identidad")
	_add_enum("item_id", "ID del ítem", Items.ItemId.keys(), Items.ItemId.values(), current_item.item_id)
	_add_text("item_name", "Nombre", current_item.item_name)
	_add_text("plural_name", "Nombre plural", current_item.plural_name)
	_add_text("item_description", "Descripción", current_item.item_description, true)

	_add_heading("💰 Economía y mochila")
	_add_spin("secondary_id", "ID secundario", current_item.secondary_id, 0, 999999, 1)
	_add_spin("price", "Precio", current_item.price, 0, 999999999, 1)
	_add_enum("pocket", "Bolsillo", ItemConstants.Pocket.keys(), ItemConstants.Pocket.values(), current_item.pocket)
	_add_enum("item_type", "Tipo de uso", Items.ItemType.keys(), Items.ItemType.values(), current_item.item_type)

	_add_heading("⚔️ Uso y efectos")
	_add_enum("hold_effect", "Efecto al sostener", HoldEffects.HoldEffect.keys(), HoldEffects.HoldEffect.values(), current_item.hold_effect)
	_add_spin("hold_effect_param", "Parámetro del efecto", current_item.hold_effect_param, 0, 999999999, 1)
	_add_enum("battle_usage", "Uso en batalla", Items.BattleUsage.keys(), Items.BattleUsage.values(), current_item.battle_usage)
	_add_spin("fling_power", "Potencia de Lanzamiento", current_item.fling_power, 0, 999, 1)
	_add_enum("effect", "Efecto real", Items.EffectItem.keys(), Items.EffectItem.values(), current_item.effect)

	_add_heading("🏷️ Banderas")
	_add_check("importance", "Ítem clave / importante", current_item.importance)
	_add_check("not_consumed", "No se consume al usarlo", current_item.not_consumed)

	_add_heading("🖼️ Presentación")
	_add_texture("icon", "Icono", current_item.icon)
	rebuilding = false

func apply_to_item(item: ItemData) -> bool:
	if item == null or current_item == null:
		return false
	item.item_id = _enum_value("item_id", item.item_id) as Items.ItemId
	item.item_name = _text_value("item_name", item.item_name).strip_edges()
	item.plural_name = _text_value("plural_name", item.plural_name).strip_edges()
	item.item_description = _text_value("item_description", item.item_description)
	item.secondary_id = _spin_value("secondary_id", item.secondary_id)
	item.price = _spin_value("price", item.price)
	item.pocket = _enum_value("pocket", item.pocket) as ItemConstants.Pocket
	item.item_type = _enum_value("item_type", item.item_type) as Items.ItemType
	item.hold_effect = _enum_value("hold_effect", item.hold_effect) as HoldEffects.HoldEffect
	item.hold_effect_param = _spin_value("hold_effect_param", item.hold_effect_param)
	item.battle_usage = _enum_value("battle_usage", item.battle_usage) as Items.BattleUsage
	item.fling_power = _spin_value("fling_power", item.fling_power)
	item.importance = _check_value("importance", item.importance)
	item.not_consumed = _check_value("not_consumed", item.not_consumed)
	if resource_fields.has("icon"):
		item.icon = (resource_fields["icon"] as EditorResourcePicker).edited_resource as Texture2D
	item.effect = _enum_value("effect", item.effect) as Items.EffectItem
	return true

func _clear_children() -> void:
	for child: Node in get_children():
		remove_child(child)
		child.queue_free()

func _add_heading(text: String) -> void:
	var label: Label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Color(0.55, 0.85, 1.0))
	add_child(label)

func _add_text(id: String, label_text: String, value: String, multiline: bool = false) -> void:
	var row: HBoxContainer = _row(label_text)
	if multiline:
		var edit: TextEdit = TextEdit.new()
		edit.text = value
		edit.custom_minimum_size = Vector2(0, 86)
		edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		edit.text_changed.connect(_on_changed)
		row.add_child(edit)
		fields[id] = edit
	else:
		var edit: LineEdit = LineEdit.new()
		edit.text = value
		edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		edit.text_changed.connect(_on_text_changed)
		row.add_child(edit)
		fields[id] = edit
	add_child(row)

func _add_spin(id: String, label_text: String, value: int, minimum: int, maximum: int, step: int) -> void:
	var row: HBoxContainer = _row(label_text)
	var spin: SpinBox = SpinBox.new()
	spin.min_value = minimum
	spin.max_value = maximum
	spin.step = step
	spin.value = value
	spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spin.value_changed.connect(_on_changed)
	row.add_child(spin)
	fields[id] = spin
	add_child(row)

func _add_enum(id: String, label_text: String, keys: Array, values: Array, value: Variant) -> void:
	var row: HBoxContainer = _row(label_text)
	var option: OptionButton = OptionButton.new()
	option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var numeric_value: int = 0 if value is Dictionary else int(value)
	for index: int in range(values.size()):
		option.add_item(_enum_label(str(keys[index])), int(values[index]))
	if option.get_item_index(numeric_value) < 0:
		option.add_item("SIN EFECTO" if numeric_value == 0 else "[%d] DESCONOCIDO" % numeric_value, numeric_value)
	option.select(option.get_item_index(numeric_value))
	option.item_selected.connect(_on_changed)
	row.add_child(option)
	enum_fields[id] = option
	add_child(row)

func _add_check(id: String, label_text: String, value: bool) -> void:
	var check: CheckBox = CheckBox.new()
	check.text = label_text
	check.button_pressed = value
	check.toggled.connect(_on_changed)
	add_child(check)
	fields[id] = check

func _add_texture(id: String, label_text: String, value: Texture2D) -> void:
	var row: HBoxContainer = _row(label_text)
	var picker: EditorResourcePicker = EditorResourcePicker.new()
	picker.base_type = "Texture2D"
	picker.edited_resource = value
	picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	picker.resource_changed.connect(_on_resource_changed)
	row.add_child(picker)
	var image: TextureRect = TextureRect.new()
	image.custom_minimum_size = Vector2(52, 52)
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image.texture = value
	row.add_child(image)
	resource_fields[id] = picker
	preview = image
	add_child(row)

func _row(label_text: String) -> HBoxContainer:
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var label: Label = Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(170, 0)
	row.add_child(label)
	return row

func _text_value(id: String, fallback: String) -> String:
	if not fields.has(id):
		return fallback
	var control: Control = fields[id] as Control
	if control is LineEdit:
		return (control as LineEdit).text
	if control is TextEdit:
		return (control as TextEdit).text
	return fallback

func _spin_value(id: String, fallback: int) -> int:
	return int((fields[id] as SpinBox).value) if fields.has(id) else fallback

func _check_value(id: String, fallback: bool) -> bool:
	return (fields[id] as CheckBox).button_pressed if fields.has(id) else fallback

func _enum_value(id: String, fallback: Variant) -> int:
	var numeric_fallback: int = 0 if fallback is Dictionary else int(fallback)
	return (enum_fields[id] as OptionButton).get_selected_id() if enum_fields.has(id) else numeric_fallback

func _enum_label(raw: String) -> String:
	var value: String = raw
	var prefixes: Array[String] = ["ITEM_", "POCKET_", "ITEM_USE_", "HOLD_EFFECT_"]
	for prefix: String in prefixes:
		if value.begins_with(prefix):
			value = value.trim_prefix(prefix)
	value = value.replace("_", " ").to_lower()
	return value.capitalize()

func _on_text_changed(_value: String) -> void:
	_on_changed()

func _on_changed(_value: Variant = null) -> void:
	if not rebuilding:
		changed.emit()

func _on_resource_changed(resource: Resource) -> void:
	if preview != null:
		preview.texture = resource as Texture2D
	_on_changed()
