@tool
extends VBoxContainer

class_name SpeciesForm

const TYPE_SELECTOR_SCRIPT := preload("res://addons/species_editor/controls/type_selector.gd")
const ABILITY_SELECTOR_SCRIPT := preload("res://addons/species_editor/controls/ability_selector.gd")
const LEARNSET_TABLE_SCRIPT := preload("res://addons/species_editor/controls/learnset_table.gd")
const EVOLUTION_TABLE_SCRIPT := preload("res://addons/species_editor/controls/evolution_table.gd")

signal form_changed

var current_species: PokemonDataStruct
var editor_catalog: SpeciesEditorCatalog
var available_species: Array[PokemonDataStruct] = []
var _is_loading := false
var fields: Dictionary = {}
var type_selectors: Dictionary = {}
var ability_selectors: Dictionary = {}
var learnset_table: LearnsetTable
var evolution_table: EvolutionTable

func set_catalog(catalog: SpeciesEditorCatalog, species: Array[PokemonDataStruct]) -> void:
	editor_catalog = catalog
	available_species = species

func load_species(species: PokemonDataStruct) -> void:
	_is_loading = true
	current_species = species
	_clear_form()
	if species != null:
		_populate_form(species)
	_is_loading = false

func apply_to_species(species: PokemonDataStruct) -> bool:
	if species == null:
		return false

	species.species_name = _read_text_field("name", species.species_name)
	species.national_dex_number = _read_int_field("dex_number", species.national_dex_number)
	species.regional_dex_number = _read_int_field("regional_dex", species.regional_dex_number)

	for id: String in ["type_1", "type_2"]:
		if type_selectors.has(id):
			species.set(id, type_selectors[id].get_selected_type())

	var stat_map := {
		"hp": "base_hp",
		"attack": "base_attack",
		"defense": "base_defense",
		"speed": "base_speed",
		"sp_attack": "base_sp_attack",
		"sp_defense": "base_sp_defense",
	}
	for field_id: String in stat_map:
		species.set(stat_map[field_id], maxi(1, _read_int_field(field_id, 1)))

	var ev_map := {
		"ev_hp": "evYield_HP",
		"ev_attack": "evYield_Attack",
		"ev_defense": "evYield_Defense",
		"ev_speed": "evYield_Speed",
		"ev_sp_attack": "evYield_SpAttack",
		"ev_sp_defense": "evYield_SpDefense",
	}
	for field_id: String in ev_map:
		species.set(ev_map[field_id], maxi(0, _read_int_field(field_id, 0)))

	for id: String in ["ability_1", "ability_2", "hidden_ability"]:
		if ability_selectors.has(id):
			species.set(id, ability_selectors[id].get_selected_ability())

	species.catch_rate = clampi(_read_int_field("catch_rate", 45), 0, 255)
	species.exp_yield = maxi(0, _read_int_field("exp_yield", 0))
	species.friendship = clampi(_read_int_field("friendship", 70), 0, 255)
	species.category_name = _read_text_field("category", species.category_name)
	species.description = _read_text_field("description", species.description)
	species.height = maxi(0, _read_int_field("height", 1))
	species.weight = maxi(0, _read_int_field("weight", 1))

	if learnset_table:
		species.level_up_moves = learnset_table.get_moves()
	if evolution_table:
		species.evolutions = evolution_table.get_evolutions()

	return true

func _populate_form(species: PokemonDataStruct) -> void:
	_add_group_label("🔠 Identidad")
	_add_field("name", "Nombre", species.species_name)
	_add_field("dex_number", "Dex nacional", str(species.national_dex_number), true)
	_add_field("regional_dex", "Dex regional", str(species.regional_dex_number), true)

	_add_group_label("🎨 Tipos")
	_add_type_selector("type_1", "Tipo 1", species.type_1)
	_add_type_selector("type_2", "Tipo 2", species.type_2)

	_add_group_label("📊 Estadísticas base")
	_add_stat_row("hp", "PS", species.base_hp, "attack", "Atk", species.base_attack)
	_add_stat_row("defense", "Def", species.base_defense, "sp_attack", "SpA", species.base_sp_attack)
	_add_stat_row("sp_defense", "SpD", species.base_sp_defense, "speed", "Spe", species.base_speed)

	_add_group_label("⭐ EVs entregados")
	_add_stat_row("ev_hp", "EV PS", species.evYield_HP, "ev_attack", "EV Atk", species.evYield_Attack)
	_add_stat_row("ev_defense", "EV Def", species.evYield_Defense, "ev_sp_attack", "EV SpA", species.evYield_SpAttack)
	_add_stat_row("ev_sp_defense", "EV SpD", species.evYield_SpDefense, "ev_speed", "EV Spe", species.evYield_Speed)

	_add_group_label("💪 Habilidades")
	_add_ability_selector("ability_1", "Habilidad 1", species.ability_1)
	_add_ability_selector("ability_2", "Habilidad 2", species.ability_2)
	_add_ability_selector("hidden_ability", "Oculta", species.hidden_ability)

	_add_group_label("⚙️ Datos generales")
	_add_field("catch_rate", "Captura", str(species.catch_rate), true)
	_add_field("exp_yield", "EXP", str(species.exp_yield), true)
	_add_field("friendship", "Amistad", str(species.friendship), true)

	_add_group_label("📖 Pokédex")
	_add_field("category", "Categoría", species.category_name)
	_add_field("description", "Descripción", species.description, false, true)
	_add_field("height", "Altura", str(species.height), true)
	_add_field("weight", "Peso", str(species.weight), true)

	_add_group_label("📚 Movimientos por nivel")
	learnset_table = LEARNSET_TABLE_SCRIPT.new()
	if editor_catalog:
		learnset_table.available_moves = editor_catalog.moves
	learnset_table.load_moves(species.level_up_moves)
	learnset_table.custom_minimum_size = Vector2(0, 160)
	learnset_table.changed.connect(_on_field_changed)
	add_child(learnset_table)

	_add_group_label("🔄 Evoluciones")
	evolution_table = EVOLUTION_TABLE_SCRIPT.new()
	evolution_table.available_species = available_species
	evolution_table.load_evolutions(species.evolutions)
	evolution_table.custom_minimum_size = Vector2(0, 150)
	evolution_table.changed.connect(_on_field_changed)
	add_child(evolution_table)

func _clear_form() -> void:
	for child: Node in get_children():
		child.queue_free()
	fields.clear()
	type_selectors.clear()
	ability_selectors.clear()
	learnset_table = null
	evolution_table = null

func _add_group_label(text: String) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 13)
	label.add_theme_color_override("font_color", Color(0.55, 0.85, 1.0))
	add_child(label)

func _add_field(id: String, label_text: String, value: String, _numeric := false, multiline := false) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	add_child(row)

	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(110, 0)
	row.add_child(label)

	var input: Control
	if multiline:
		var edit := TextEdit.new()
		edit.text = value
		edit.custom_minimum_size = Vector2(0, 70)
		edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		edit.text_changed.connect(_on_field_changed)
		input = edit
	else:
		var line := LineEdit.new()
		line.text = value
		line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		line.text_changed.connect(_on_field_changed)
		input = line

	row.add_child(input)
	fields[id] = input

func _add_stat_row(id_a: String, label_a: String, value_a: int, id_b: String, label_b: String, value_b: int) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	add_child(row)

	var label_a_node := Label.new()
	label_a_node.text = label_a
	label_a_node.custom_minimum_size = Vector2(45, 0)
	row.add_child(label_a_node)

	var input_a := SpinBox.new()
	input_a.min_value = 0
	input_a.max_value = 255
	input_a.step = 1
	input_a.value = value_a
	input_a.custom_minimum_size = Vector2(70, 0)
	input_a.value_changed.connect(_on_field_changed)
	row.add_child(input_a)
	fields[id_a] = input_a

	var label_b_node := Label.new()
	label_b_node.text = label_b
	label_b_node.custom_minimum_size = Vector2(45, 0)
	row.add_child(label_b_node)

	var input_b := SpinBox.new()
	input_b.min_value = 0
	input_b.max_value = 255
	input_b.step = 1
	input_b.value = value_b
	input_b.custom_minimum_size = Vector2(70, 0)
	input_b.value_changed.connect(_on_field_changed)
	row.add_child(input_b)
	fields[id_b] = input_b

func _add_type_selector(id: String, label_text: String, value: PokemonData.Type) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	add_child(row)

	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(110, 0)
	row.add_child(label)

	var selector: TypeSelector = TYPE_SELECTOR_SCRIPT.new()
	selector.selected_type = value
	selector.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	selector.type_changed.connect(_on_field_changed)
	row.add_child(selector)
	type_selectors[id] = selector

func _add_ability_selector(id: String, label_text: String, value: AbilityId.Id) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	add_child(row)

	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(110, 0)
	row.add_child(label)

	var selector: AbilitySelector = ABILITY_SELECTOR_SCRIPT.new()
	if editor_catalog:
		selector.available_abilities = editor_catalog.abilities
	selector.selected_ability = value
	selector.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	selector.ability_changed.connect(_on_field_changed)
	row.add_child(selector)
	ability_selectors[id] = selector

func _read_text_field(id: String, fallback: String) -> String:
	if not fields.has(id):
		return fallback
	var control: Control = fields[id]
	if control is LineEdit:
		return (control as LineEdit).text
	if control is TextEdit:
		return (control as TextEdit).text
	return fallback

func _read_int_field(id: String, fallback: int) -> int:
	if not fields.has(id):
		return fallback
	var control: Control = fields[id]
	if control is SpinBox:
		return int((control as SpinBox).value)
	if control is LineEdit:
		var text: String = (control as LineEdit).text
		if text.is_valid_int():
			return int(text)
	return fallback

func _on_field_changed(_value: Variant = null) -> void:
	if not _is_loading:
		form_changed.emit()
