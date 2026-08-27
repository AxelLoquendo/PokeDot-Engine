@tool
extends VBoxContainer

class_name PokemonFormEditor

signal changed

const EVOLUTION_TABLE_SCRIPT := preload("res://addons/species_editor/controls/evolution_table.gd")

var current_form: PokemonFormData
var available_species: Array[PokemonDataStruct] = []
var form_species_id_input: SpinBox
var form_id_input: LineEdit
var name_input: LineEdit
var type_1: TypeSelector
var type_2: TypeSelector
var override_types: CheckBox
var override_graphics: CheckBox
var front_picker: EditorResourcePicker
var shiny_picker: EditorResourcePicker
var back_picker: EditorResourcePicker
var back_shiny_picker: EditorResourcePicker
var icon_picker: EditorResourcePicker
var cry_picker: EditorResourcePicker
var front_x: SpinBox
var front_y: SpinBox
var back_x: SpinBox
var back_y: SpinBox
var notes_input: TextEdit
var evolution_table: EvolutionTable
var inherit_evolutions: CheckBox

func set_available_species(values: Array[PokemonDataStruct]) -> void:
	available_species = values

func load_form(form: PokemonFormData) -> void:
	current_form = form
	if is_inside_tree():
		_rebuild()

func _ready() -> void:
	_rebuild()

func _rebuild() -> void:
	for child: Node in get_children():
		child.queue_free()
	if current_form == null:
		var empty: Label = Label.new()
		empty.text = "Selecciona o crea una forma."
		add_child(empty)
		return

	form_species_id_input = _add_integer_field(
		"SpeciesID de forma (species.gd)",
		int(current_form.species_id),
		0,
		999999
	)
	form_id_input = _add_text_field("Clave interna legacy", str(current_form.form_id), true)
	name_input = _add_text_field("Nombre visible", current_form.display_name, false)

	override_types = CheckBox.new()
	override_types.text = "Sobrescribir tipos de la especie base"
	override_types.button_pressed = current_form.override_types
	override_types.toggled.connect(_on_changed)
	add_child(override_types)
	type_1 = _make_type_selector(current_form.type_1)
	type_2 = _make_type_selector(current_form.type_2)
	_add_labeled_control("Tipo 1 (NONE = heredar)", type_1)
	_add_labeled_control("Tipo 2 (NONE = heredar)", type_2)

	inherit_evolutions = CheckBox.new()
	inherit_evolutions.text = "Heredar evoluciones de la especie base"
	inherit_evolutions.button_pressed = current_form.inherit_base_evolutions
	inherit_evolutions.toggled.connect(_on_changed)
	add_child(inherit_evolutions)
	evolution_table = EVOLUTION_TABLE_SCRIPT.new()
	evolution_table.available_species = available_species
	evolution_table.load_evolutions(current_form.evolutions)
	evolution_table.changed.connect(_on_changed)
	add_child(evolution_table)

	override_graphics = CheckBox.new()
	override_graphics.text = "Sobrescribir gráficos de la especie base"
	override_graphics.button_pressed = current_form.override_graphics
	override_graphics.toggled.connect(_on_changed)
	add_child(override_graphics)
	front_picker = _add_resource_picker("Frontal", current_form.front_sprite, "Texture2D")
	shiny_picker = _add_resource_picker("Frontal shiny", current_form.front_sprite_shiny, "Texture2D")
	back_picker = _add_resource_picker("Trasero", current_form.back_sprite, "Texture2D")
	back_shiny_picker = _add_resource_picker("Trasero shiny", current_form.back_sprite_shiny, "Texture2D")
	icon_picker = _add_resource_picker("Icono", current_form.icon_sprite, "Texture2D")
	cry_picker = _add_resource_picker("Cry", current_form.cry, "AudioStream")

	front_x = _add_offset("Frontal X", current_form.front_sprite_offset.x)
	front_y = _add_offset("Frontal Y", current_form.front_sprite_offset.y)
	back_x = _add_offset("Trasero X", current_form.back_sprite_offset.x)
	back_y = _add_offset("Trasero Y", current_form.back_sprite_offset.y)

	var notes_label: Label = Label.new()
	notes_label.text = "Notas"
	add_child(notes_label)
	notes_input = TextEdit.new()
	notes_input.text = current_form.notes
	notes_input.custom_minimum_size = Vector2(0, 70)
	notes_input.text_changed.connect(_on_changed)
	add_child(notes_input)

func apply_to_form(form: PokemonFormData) -> void:
	if form == null or current_form == null:
		return
	form.species_id = int(form_species_id_input.value) as Species.SpeciesID
	form.form_id = StringName(form_id_input.text.strip_edges())
	form.display_name = name_input.text.strip_edges()
	form.override_types = override_types.button_pressed
	form.type_1 = type_1.selected_type
	form.type_2 = type_2.selected_type
	form.inherit_base_evolutions = inherit_evolutions.button_pressed
	form.evolutions = evolution_table.get_evolutions()
	form.override_graphics = override_graphics.button_pressed
	form.front_sprite = front_picker.edited_resource as Texture2D
	form.front_sprite_shiny = shiny_picker.edited_resource as Texture2D
	form.back_sprite = back_picker.edited_resource as Texture2D
	form.back_sprite_shiny = back_shiny_picker.edited_resource as Texture2D
	form.icon_sprite = icon_picker.edited_resource as Texture2D
	form.cry = cry_picker.edited_resource as AudioStream
	form.front_sprite_offset = Vector2(front_x.value, front_y.value)
	form.back_sprite_offset = Vector2(back_x.value, back_y.value)
	form.notes = notes_input.text

func _add_integer_field(label_text: String, value: int, minimum: int, maximum: int) -> SpinBox:
	var row: HBoxContainer = HBoxContainer.new()
	var label: Label = Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(180, 0)
	row.add_child(label)
	var input := SpinBox.new()
	input.min_value = minimum
	input.max_value = maximum
	input.step = 1
	input.value = value
	input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	input.value_changed.connect(_on_changed)
	row.add_child(input)
	add_child(row)
	return input

func _add_text_field(label_text: String, value: String, is_id: bool) -> LineEdit:
	var row: HBoxContainer = HBoxContainer.new()
	var label: Label = Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(180, 0)
	row.add_child(label)
	var input: LineEdit = LineEdit.new()
	input.name = "__form_id_input" if is_id else "__name_input"
	input.text = value
	input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	input.text_changed.connect(_on_changed)
	row.add_child(input)
	add_child(row)
	return input

func _add_labeled_control(label_text: String, control: Control) -> void:
	var row: HBoxContainer = HBoxContainer.new()
	var label: Label = Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(180, 0)
	row.add_child(label)
	control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(control)
	add_child(row)

func _make_type_selector(value: PokemonData.Type) -> TypeSelector:
	var selector: TypeSelector = preload("res://addons/species_editor/controls/type_selector.gd").new()
	selector.selected_type = value
	selector.type_changed.connect(_on_changed)
	return selector

func _add_resource_picker(label_text: String, value: Resource, base_type: String) -> EditorResourcePicker:
	var row: HBoxContainer = HBoxContainer.new()
	var label: Label = Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(180, 0)
	row.add_child(label)
	var picker: EditorResourcePicker = EditorResourcePicker.new()
	picker.base_type = base_type
	picker.edited_resource = value
	picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	picker.resource_changed.connect(_on_resource_changed)
	row.add_child(picker)
	add_child(row)
	return picker

func _add_offset(label_text: String, value: float) -> SpinBox:
	var row: HBoxContainer = HBoxContainer.new()
	var label: Label = Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(180, 0)
	row.add_child(label)
	var spin: SpinBox = SpinBox.new()
	spin.min_value = -20
	spin.max_value = 20
	spin.step = 0.125
	spin.value = value
	spin.value_changed.connect(_on_changed)
	row.add_child(spin)
	add_child(row)
	return spin

func _on_resource_changed(_resource: Resource) -> void:
	changed.emit()

func _on_changed(_value: Variant = null) -> void:
	changed.emit()
