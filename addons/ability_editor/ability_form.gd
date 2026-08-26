@tool
extends VBoxContainer
class_name AbilityEditorForm

signal form_changed

var catalog: AbilityEditorCatalog
var current_data: AbilityData
var controls: Dictionary = {}
var trigger_controls: Dictionary = {}
var behavior_picker: EditorResourcePicker
var _loading := false

func set_catalog(value: AbilityEditorCatalog) -> void:
	catalog = value

func load_data(data: AbilityData) -> void:
	_loading = true
	current_data = data
	_clear()
	if data != null:
		_build(data)
	_loading = false

func apply_to_data(data: AbilityData) -> bool:
	if data == null:
		return false
	data.id = int(_spin("id", int(data.id))) as AbilityId.Id
	data.name_key = _line("name_key", data.name_key)
	data.description_key = _line("description_key", data.description_key)
	data.generation = maxi(1, _spin("generation", data.generation))
	data.is_hidden_ability = _check("hidden", data.is_hidden_ability)
	data.ai_rating = clampi(_spin("ai_rating", data.ai_rating), 0, 10)
	for key: String in trigger_controls:
		data.set(key, bool(trigger_controls[key].button_pressed))
	data.weather_override = _option_value("weather", int(data.weather_override)) as AbilityBattleEffect.weatherAbilityID
	data.terrain_override = _option_value("terrain", int(data.terrain_override)) as AbilityBattleEffect.terrainID
	var dictionary_text := _text("stat_modifiers", "{}")
	var parsed = JSON.parse_string(dictionary_text)
	if not parsed is Dictionary:
		return false
	data.stat_modifiers = parsed
	data.priority_modifier = _spin("priority_modifier", data.priority_modifier)
	if behavior_picker != null:
		data.behavior = behavior_picker.edited_resource as AbilityEffect
	return true

func get_validation_hint() -> String:
	var data := AbilityData.new()
	if not apply_to_data(data):
		return "✗ stat_modifiers debe ser un objeto JSON válido"
	return ""

func _build(data: AbilityData) -> void:
	_add_heading("Identificación")
	_add_spin("id", "ID (AbilityId.Id)", int(data.id), 0, int(AbilityId.Id.COUNT) - 1, 1)
	_add_line("name_key", "Clave de nombre", data.name_key)
	_add_line("description_key", "Clave de descripción", data.description_key)

	_add_heading("Clasificación")
	_add_spin("generation", "Generación", data.generation, 1, 99, 1)
	_add_check("hidden", "Es habilidad oculta", data.is_hidden_ability)
	_add_spin("ai_rating", "AI rating", data.ai_rating, 0, 10, 1)

	_add_heading("Activación")
	var trigger_fields := [
		["triggers_on_enter", "Al entrar"],
		["triggers_on_switch_in", "Al cambiar/entrar"],
		["triggers_on_hit", "Al golpear"],
		["triggers_on_hit_by", "Al recibir golpe"],
		["triggers_on_faint", "Al debilitarse"],
		["triggers_on_stat_change", "Al cambiar estadísticas"],
		["triggers_on_status", "Al aplicar estado"],
		["triggers_on_weather", "Al cambiar clima"],
		["triggers_on_terrain", "Al cambiar terreno"],
	]
	for item: Array in trigger_fields:
		var trigger_id: String = str(item[0])
		_add_trigger(trigger_id, str(item[1]), bool(data.get(trigger_id)))

	_add_heading("Gameplay")
	_add_weather(data.weather_override)
	_add_terrain(data.terrain_override)
	_add_json("stat_modifiers", "Modificadores de estadísticas", data.stat_modifiers)
	_add_spin("priority_modifier", "Modificador de prioridad", data.priority_modifier, -99, 99, 1)

	_add_heading("Behavior")
	var behavior_row := HBoxContainer.new()
	var behavior_label := Label.new()
	behavior_label.text = "AbilityEffect"
	behavior_label.custom_minimum_size = Vector2(180, 0)
	behavior_row.add_child(behavior_label)
	behavior_picker = EditorResourcePicker.new()
	behavior_picker.base_type = "AbilityEffect"
	behavior_picker.edited_resource = data.behavior
	behavior_picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	behavior_picker.resource_changed.connect(_on_changed)
	behavior_row.add_child(behavior_picker)
	add_child(behavior_row)
	var behavior_note := Label.new()
	behavior_note.text = "Selecciona un recurso AbilityEffect; déjalo vacío si no tiene comportamiento."
	behavior_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	behavior_note.add_theme_color_override("font_color", Color(0.65, 0.65, 0.65))
	add_child(behavior_note)

func _add_heading(text: String) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Color(0.55, 0.85, 1.0))
	add_child(label)

func _add_line(id: String, caption: String, value: String) -> void:
	var row := _row(caption)
	var input := LineEdit.new()
	input.text = value
	input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	input.text_changed.connect(_on_changed)
	row.add_child(input)
	controls[id] = input

func _add_spin(id: String, caption: String, value: int, minimum: int, maximum: int, step: int) -> void:
	var row := _row(caption)
	var input := SpinBox.new()
	input.min_value = minimum
	input.max_value = maximum
	input.step = step
	input.value = value
	input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	input.value_changed.connect(_on_changed)
	row.add_child(input)
	controls[id] = input

func _add_check(id: String, caption: String, value: bool) -> void:
	var row := HBoxContainer.new()
	add_child(row)
	var input := CheckButton.new()
	input.text = caption
	input.button_pressed = value
	input.toggled.connect(_on_changed)
	row.add_child(input)
	controls[id] = input

func _add_trigger(id: String, caption: String, value: bool) -> void:
	var row := HBoxContainer.new()
	add_child(row)
	var input := CheckButton.new()
	input.text = caption
	input.button_pressed = value
	input.toggled.connect(_on_changed)
	row.add_child(input)
	trigger_controls[id] = input

func _add_weather(value: int) -> void:
	var row := _row("Clima override")
	var input := OptionButton.new()
	var names: Array = AbilityBattleEffect.weatherAbilityID.keys()
	var values: Array = AbilityBattleEffect.weatherAbilityID.values()
	for index: int in range(values.size()):
		input.add_item(str(names[index]).replace("_", " ").capitalize(), int(values[index]))
	_select_option(input, value)
	input.item_selected.connect(func(index: int) -> void:
		_on_changed()
	)
	input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(input)
	controls["weather"] = input

func _add_terrain(value: int) -> void:
	var row: HBoxContainer = _row("Terreno override")
	var input: OptionButton = OptionButton.new()
	var names: Array = AbilityBattleEffect.terrainID.keys()
	var values: Array = AbilityBattleEffect.terrainID.values()
	for index: int in range(values.size()):
		input.add_item(str(names[index]).replace("_", " ").capitalize(), int(values[index]))
	_select_option(input, value)
	input.item_selected.connect(_on_changed)
	input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(input)
	controls["terrain"] = input

func _add_json(id: String, caption: String, value: Dictionary) -> void:
	var row := VBoxContainer.new()
	add_child(row)
	var label := Label.new()
	label.text = caption
	row.add_child(label)
	var input := TextEdit.new()
	input.text = JSON.stringify(value, "  ")
	input.custom_minimum_size = Vector2(0, 88)
	input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	input.text_changed.connect(_on_changed)
	row.add_child(input)
	controls[id] = input

func _row(caption: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	add_child(row)
	var label := Label.new()
	label.text = caption
	label.custom_minimum_size = Vector2(180, 0)
	row.add_child(label)
	return row

func _clear() -> void:
	for child: Node in get_children():
		child.queue_free()
	controls.clear()
	trigger_controls.clear()
	behavior_picker = null

func _line(id: String, fallback: String) -> String:
	var input := controls.get(id) as LineEdit
	return input.text if input != null else fallback

func _text(id: String, fallback: String) -> String:
	var input := controls.get(id) as TextEdit
	return input.text if input != null else fallback

func _spin(id: String, fallback: int) -> int:
	var input := controls.get(id) as SpinBox
	return int(input.value) if input != null else fallback

func _check(id: String, fallback: bool) -> bool:
	var input := controls.get(id) as CheckButton
	return input.button_pressed if input != null else fallback

func _option_value(id: String, fallback: int) -> int:
	var input := controls.get(id) as OptionButton
	if input == null or input.selected < 0:
		return fallback
	return input.get_item_id(input.selected)

func _select_option(input: OptionButton, value: int) -> void:
	for index: int in range(input.item_count):
		if input.get_item_id(index) == value:
			input.select(index)
			return
	if input.item_count > 0:
		input.select(0)

func _on_changed(_value = null) -> void:
	if not _loading:
		form_changed.emit()
