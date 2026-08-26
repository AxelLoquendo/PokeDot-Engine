@tool
extends VBoxContainer

class_name MoveEditorForm

signal changed

const ENUM_FIELDS: Array[Dictionary] = [
	{"field": "move_id", "label": "ID del movimiento", "enum": "MoveId"},
	{"field": "type", "label": "Tipo", "enum": "Type"},
	{"field": "category", "label": "Categoría de daño", "enum": "DamageCategory"},
	{"field": "target", "label": "Objetivo", "enum": "MoveTarget"},
	{"field": "effect", "label": "Efecto principal", "enum": "MoveEffect"},
	{"field": "secondary_effect", "label": "Efecto secundario", "enum": "SecondaryEffect"},
	{"field": "z_effect", "label": "Efecto Z", "enum": "ZEffect"},
]

const NUMBER_FIELDS: Array[Dictionary] = [
	{"field": "power", "label": "Potencia", "min": 0, "max": 999, "step": 1},
	{"field": "accuracy", "label": "Precisión (0 = no chequeo)", "min": 0, "max": 100, "step": 1},
	{"field": "pp", "label": "PP", "min": 1, "max": 999, "step": 1},
	{"field": "priority", "label": "Prioridad", "min": -7, "max": 7, "step": 1},
	{"field": "crit_stage", "label": "Etapa de crítico", "min": 0, "max": 10, "step": 1},
	{"field": "min_hits", "label": "Golpes mínimos", "min": 1, "max": 10, "step": 1},
	{"field": "max_hits", "label": "Golpes máximos", "min": 1, "max": 10, "step": 1},
	{"field": "drain_percent", "label": "Drenaje (%)", "min": 0, "max": 100, "step": 1},
	{"field": "recoil_percent", "label": "Retroceso (%)", "min": 0, "max": 100, "step": 1},
	{"field": "secondary_chance", "label": "Probabilidad secundaria (%)", "min": 0, "max": 100, "step": 1},
]

const FLAG_GROUPS: Array[Dictionary] = [
	{"title": "Flags mecánicas de combate", "fields": ["is_multi_hit", "is_explosion"]},
	{"title": "Flags de tipo de movimiento", "fields": ["makes_contact", "punching_move", "biting_move", "slicing_move", "sound_move", "ballistic_move", "pulse_move", "powder_move", "wind_move", "dance_move", "healing_move"]},
	{"title": "Flags de interacción extensa", "fields": ["magic_coat_affected", "snatch_affected", "ignores_kings_rock", "thaws_user", "force_pressure", "cant_use_twice"]},
	{"title": "Flags de precisión y evasión", "fields": ["always_hits", "ignores_protect", "ignores_substitute", "always_critical", "ignores_target_ability", "ignores_target_defense_evasion_stages"]},
	{"title": "Flags de clima", "fields": ["always_hits_in_rain", "always_hits_in_hail_snow", "accuracy_50_in_sun"]},
	{"title": "Flags de estados especiales del rival", "fields": ["minimize_double_damage", "damages_underground", "damages_underwater", "damages_airborne", "damages_airborne_double_damage"]},
	{"title": "Baneos", "fields": ["gravity_banned", "mirror_move_banned", "me_first_banned", "mimic_banned", "metronome_banned", "copycat_banned", "assist_banned", "sleep_talk_banned", "instruct_banned", "encore_banned", "parental_bond_banned", "sky_battle_banned", "sketch_banned", "damp_banned"]},
]

var current_move: MoveData
var controls: Dictionary = {}
var rebuilding: bool = false

func load_move(data: MoveData) -> void:
	current_move = data
	if is_inside_tree():
		_rebuild()

func _ready() -> void:
	_rebuild()

func _rebuild() -> void:
	rebuilding = true
	controls.clear()
	for child: Node in get_children():
		child.free()
	if current_move == null:
		var empty: Label = Label.new()
		empty.text = "Selecciona o crea un movimiento."
		empty.add_theme_color_override("font_color", Color.LIGHT_GRAY)
		add_child(empty)
		rebuilding = false
		return

	_add_section_title("Información base")
	_add_line_edit("move_name", "Nombre visible", current_move.move_name)
	_add_enum_row(ENUM_FIELDS[0])
	_add_enum_row(ENUM_FIELDS[1])
	_add_enum_row(ENUM_FIELDS[2])
	_add_enum_row(ENUM_FIELDS[3])
	_add_multiline("description", "Descripción", current_move.description)

	_add_section_title("Parámetros numéricos")
	for config: Dictionary in NUMBER_FIELDS:
		_add_number_row(config)

	_add_section_title("Efectos")
	_add_enum_row(ENUM_FIELDS[4])
	_add_enum_row(ENUM_FIELDS[5])
	_add_number_row({"field": "secondary_chance", "label": "Probabilidad secundaria (%)", "min": 0, "max": 100, "step": 1}, true)
	_add_enum_row(ENUM_FIELDS[6])

	for group: Dictionary in FLAG_GROUPS:
		_add_flag_group(str(group["title"]), group["fields"] as Array)
	rebuilding = false

func _add_section_title(text: String) -> void:
	var title: Label = Label.new()
	title.text = text
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", Color(0.55, 0.85, 1.0))
	add_child(title)

func _add_line_edit(field: String, label_text: String, value: String) -> void:
	var row: HBoxContainer = _row(label_text)
	var input: LineEdit = LineEdit.new()
	input.text = value
	input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	input.text_changed.connect(_on_control_changed)
	row.add_child(input)
	controls[field] = input
	add_child(row)

func _add_multiline(field: String, label_text: String, value: String) -> void:
	var label: Label = Label.new()
	label.text = label_text
	add_child(label)
	var input: TextEdit = TextEdit.new()
	input.text = value
	input.custom_minimum_size = Vector2(0, 80)
	input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	input.text_changed.connect(_on_control_changed)
	controls[field] = input
	add_child(input)

func _add_number_row(config: Dictionary, duplicate_allowed: bool = false) -> void:
	var field: String = str(config["field"])
	if duplicate_allowed and controls.has(field):
		return
	var row: HBoxContainer = _row(str(config["label"]))
	var spin: SpinBox = SpinBox.new()
	spin.min_value = float(config["min"])
	spin.max_value = float(config["max"])
	spin.step = float(config["step"])
	spin.value = float(current_move.get(field))
	spin.custom_minimum_size = Vector2(110, 0)
	spin.value_changed.connect(_on_control_changed)
	row.add_child(spin)
	controls[field] = spin
	add_child(row)

func _add_enum_row(config: Dictionary) -> void:
	var field: String = str(config["field"])
	var row: HBoxContainer = _row(str(config["label"]))
	var option: OptionButton = OptionButton.new()
	option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var enum_dictionary: Dictionary = _get_enum(str(config["enum"]))
	var keys: Array = enum_dictionary.keys()
	var values: Array = enum_dictionary.values()
	var selected_index: int = -1
	for index: int in range(min(keys.size(), values.size())):
		var value: int = int(values[index])
		option.add_item("[%d] %s" % [value, _enum_display(str(config["enum"]), str(keys[index]))], value)
		if value == int(current_move.get(field)):
			selected_index = index
	if selected_index < 0:
		option.add_item("[%d] UNKNOWN" % int(current_move.get(field)), int(current_move.get(field)))
		selected_index = option.item_count - 1
	option.select(selected_index)
	option.item_selected.connect(_on_enum_changed.bind(field, option))
	row.add_child(option)
	controls[field] = option
	add_child(row)

func _add_flag_group(title_text: String, fields: Array) -> void:
	_add_section_title(title_text)
	var grid: GridContainer = GridContainer.new()
	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for field_value: Variant in fields:
		var field: String = str(field_value)
		var check: CheckBox = CheckBox.new()
		check.text = _humanize(field)
		check.button_pressed = bool(current_move.get(field))
		check.toggled.connect(_on_control_changed)
		check.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_child(check)
		controls[field] = check
	add_child(grid)

func _row(label_text: String) -> HBoxContainer:
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var label: Label = Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(190, 0)
	row.add_child(label)
	return row

func _get_enum(enum_name: String) -> Dictionary:
	match enum_name:
		"MoveId": return Moves.MoveId
		"Type": return PokemonData.Type
		"DamageCategory": return MoveStruct.DamageCategory
		"MoveTarget": return MoveStruct.MoveTarget
		"MoveEffect": return MoveStruct.MoveEffect
		"SecondaryEffect": return MoveStruct.SecondaryEffect
		"ZEffect": return MoveStruct.ZEffect
	return {}

func _enum_display(enum_name: String, key: String) -> String:
	var clean: String = key
	if enum_name == "MoveId":
		clean = clean.trim_prefix("MOVE_")
	elif enum_name == "Type":
		clean = clean.trim_prefix("TYPE_")
	elif enum_name == "MoveTarget":
		clean = clean.trim_prefix("TARGET_")
	elif enum_name == "MoveEffect":
		clean = clean.trim_prefix("EFFECT_")
	elif enum_name == "SecondaryEffect":
		clean = clean.trim_prefix("MOVE_EFFECT_")
	elif enum_name == "ZEffect":
		clean = clean.trim_prefix("Z_EFFECT_")
	return clean.replace("_", " ").capitalize()

func _humanize(field: String) -> String:
	return field.replace("_", " ").capitalize()

func _on_enum_changed(_index: int, field: String, option: OptionButton) -> void:
	if current_move != null and controls.has(field):
		current_move.set(field, option.get_selected_id())
	if not rebuilding:
		changed.emit()

func _on_control_changed(_value: Variant = null) -> void:
	if not rebuilding:
		changed.emit()

func apply_to_move(data: MoveData) -> void:
	if data == null:
		return
	for field: String in controls.keys():
		var control: Control = controls[field] as Control
		if control is LineEdit:
			data.set(field, (control as LineEdit).text.strip_edges())
		elif control is TextEdit:
			data.set(field, (control as TextEdit).text)
		elif control is SpinBox:
			data.set(field, int((control as SpinBox).value))
		elif control is CheckBox:
			data.set(field, (control as CheckBox).button_pressed)
		elif control is OptionButton:
			data.set(field, (control as OptionButton).get_selected_id())

func validate_current() -> Array[String]:
	if current_move == null:
		return ["No hay un movimiento seleccionado."]
	apply_to_move(current_move)
	return current_move._validate()
