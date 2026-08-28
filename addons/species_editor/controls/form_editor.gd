@tool
extends VBoxContainer

class_name PokemonFormEditor

signal changed

const EVOLUTION_TABLE_SCRIPT := preload("res://addons/species_editor/controls/evolution_table.gd")
const LEARNSET_TABLE_SCRIPT := preload("res://addons/species_editor/controls/learnset_table.gd")
const MOVE_LIST_SCRIPT := preload("res://addons/species_editor/controls/move_id_list_table.gd")

var current_form: PokemonFormData
var available_species: Array[PokemonDataStruct] = []
var available_moves: Array[MoveData] = []
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
var inherit_moves: CheckBox
var form_level_up_moves: LearnsetTable
var form_teachable_moves: MoveIdListTable
var form_egg_moves: MoveIdListTable
var override_pokedex: CheckBox
var pokedex_category_input: LineEdit
var pokedex_description_input: TextEdit
var pokedex_height_input: SpinBox
var pokedex_weight_input: SpinBox

func set_available_species(values: Array[PokemonDataStruct]) -> void:
	available_species = values

func set_available_moves(values: Array[MoveData]) -> void:
	available_moves = values

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

	_add_form_pokedex_editor()

	inherit_moves = CheckBox.new()
	inherit_moves.text = "Heredar movimientos de la especie base y añadir los de esta forma"
	inherit_moves.button_pressed = current_form.inherit_base_moves
	inherit_moves.toggled.connect(_on_changed)
	add_child(inherit_moves)
	_add_section_label("Movimientos por nivel propios")
	form_level_up_moves = LEARNSET_TABLE_SCRIPT.new()
	form_level_up_moves.available_moves = available_moves
	form_level_up_moves.load_moves(current_form.level_up_moves)
	form_level_up_moves.changed.connect(_on_changed)
	add_child(form_level_up_moves)
	_add_section_label("Movimientos MT/MO propios")
	form_teachable_moves = MOVE_LIST_SCRIPT.new()
	form_teachable_moves.available_moves = available_moves
	form_teachable_moves.load_moves(current_form.teachable_moves)
	form_teachable_moves.changed.connect(_on_changed)
	add_child(form_teachable_moves)
	_add_section_label("Movimientos huevo propios")
	form_egg_moves = MOVE_LIST_SCRIPT.new()
	form_egg_moves.available_moves = available_moves
	form_egg_moves.load_moves(current_form.egg_moves)
	form_egg_moves.changed.connect(_on_changed)
	add_child(form_egg_moves)

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

func _add_form_pokedex_editor() -> void:
	var title := Label.new()
	title.text = "📖 Entrada de Pokédex de la forma"
	title.add_theme_font_size_override("font_size", 13)
	add_child(title)
	override_pokedex = CheckBox.new()
	override_pokedex.text = "Usar una entrada de Pokédex propia"
	override_pokedex.button_pressed = current_form.override_pokedex
	override_pokedex.toggled.connect(_on_changed)
	add_child(override_pokedex)
	pokedex_category_input = _add_text_field("Categoría", current_form.category_name, false)
	pokedex_description_input = _add_multiline_field("Descripción", current_form.description)
	pokedex_height_input = _add_integer_field("Altura", current_form.height, 0, 9999)
	pokedex_weight_input = _add_integer_field("Peso", current_form.weight, 0, 999999)

func apply_to_form(form: PokemonFormData) -> void:
	if form == null or current_form == null:
		return
	form.species_id = int(form_species_id_input.value) as Species.SpeciesID
	form.form_id = StringName(form_id_input.text.strip_edges())
	form.display_name = name_input.text.strip_edges()
	form.override_types = override_types.button_pressed
	form.type_1 = type_1.selected_type
	form.type_2 = type_2.selected_type
	form.override_pokedex = override_pokedex.button_pressed
	form.category_name = pokedex_category_input.text.strip_edges()
	form.description = pokedex_description_input.text
	form.height = int(pokedex_height_input.value)
	form.weight = int(pokedex_weight_input.value)
	form.inherit_base_moves = inherit_moves.button_pressed
	form.level_up_moves = form_level_up_moves.get_moves()
	form.teachable_moves = form_teachable_moves.get_moves()
	form.egg_moves = form_egg_moves.get_moves()
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

func _add_section_label(text: String) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_color_override("font_color", Color(0.55, 0.85, 1.0))
	add_child(label)

func _add_text_field(label_text: String, value: String, is_id: bool) -> LineEdit:
	var row: HBoxContainer = HBoxContainer.new()
	var label: Label = Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(180, 0)
	row.add_child(label)
	var input := LineEdit.new()
	input.name = "__form_id_input" if is_id else "__name_input"
	input.text = value
	input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	input.text_changed.connect(_on_changed)
	row.add_child(input)
	add_child(row)
	return input

func _add_multiline_field(label_text: String, value: String) -> TextEdit:
	var row: HBoxContainer = HBoxContainer.new()
	var label: Label = Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(180, 0)
	row.add_child(label)
	var input := TextEdit.new()
	input.text = value
	input.custom_minimum_size = Vector2(0, 90)
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
