@tool
extends VBoxContainer

class_name SpeciesForm

## Form to edit a PokemonDataStruct

signal form_changed

var current_species: PokemonDataStruct = null
var _is_loading: bool = false

# Field references
var fields: Dictionary = {}
var type_selectors: Dictionary = {}  # type_1, type_2
var ability_selectors: Dictionary = {}  # ability_1, ability_2, hidden_ability
var learnset_table: LearnsetTable
var evolution_table: EvolutionTable

func load_species(species: PokemonDataStruct) -> void:
	_is_loading = true
	current_species = species

	if species == null:
		_clear_form()
		_is_loading = false
		return

	_populate_form(species)
	_is_loading = false

func apply_to_species(species: PokemonDataStruct) -> bool:
	if species == null:
		return false

	# Identity
	species.species_name = fields["name"].text
	species.national_dex_number = int(fields["dex_number"].text) if fields["dex_number"].text.is_valid_int() else 1
	species.regional_dex_number = int(fields["regional_dex"].text) if fields["regional_dex"].text.is_valid_int() else 0

	# Types
	if "type_1" in type_selectors:
		species.type_1 = type_selectors["type_1"].get_selected_type()
	if "type_2" in type_selectors:
		species.type_2 = type_selectors["type_2"].get_selected_type()

	# Base Stats
	for stat_name in ["hp", "attack", "defense", "sp_attack", "sp_defense", "speed"]:
		if stat_name in fields:
			var value = int(fields[stat_name].text) if fields[stat_name].text.is_valid_int() else 1
			value = maxi(1, value)

			match stat_name:
				"hp":
					species.base_hp = value
				"attack":
					species.base_attack = value
				"defense":
					species.base_defense = value
				"sp_attack":
					species.base_sp_attack = value
				"sp_defense":
					species.base_sp_defense = value
				"speed":
					species.base_speed = value

	# EV Yield
	for stat_name in ["hp", "attack", "defense", "sp_attack", "sp_defense", "speed"]:
		var ev_field = "ev_" + stat_name
		if ev_field in fields:
			var value = int(fields[ev_field].text) if fields[ev_field].text.is_valid_int() else 0

			match stat_name:
				"hp":
					species.evYield_HP = value
				"attack":
					species.evYield_Attack = value
				"defense":
					species.evYield_Defense = value
				"sp_attack":
					species.evYield_SpAttack = value
				"sp_defense":
					species.evYield_SpDefense = value
				"speed":
					species.evYield_Speed = value

	# Abilities
	if "ability_1" in ability_selectors:
		species.ability_1 = ability_selectors["ability_1"].get_selected_ability()
	if "ability_2" in ability_selectors:
		species.ability_2 = ability_selectors["ability_2"].get_selected_ability()
	if "hidden_ability" in ability_selectors:
		species.hidden_ability = ability_selectors["hidden_ability"].get_selected_ability()

	# General Data
	species.catch_rate = int(fields["catch_rate"].text) if fields["catch_rate"].text.is_valid_int() else 45
	species.exp_yield = int(fields["exp_yield"].text) if fields["exp_yield"].text.is_valid_int() else 0
	species.friendship = int(fields["friendship"].text) if fields["friendship"].text.is_valid_int() else 70
	species.category_name = fields["category"].text
	species.description = fields["description"].text
	species.height = int(fields["height"].text) if fields["height"].text.is_valid_int() else 1
	species.weight = int(fields["weight"].text) if fields["weight"].text.is_valid_int() else 1

	return true

func _populate_form(species: PokemonDataStruct) -> void:
	if get_child_count() > 0:
		for child in get_children():
			child.queue_free()

	fields.clear()
	type_selectors.clear()
	ability_selectors.clear()
	add_theme_constant_override("separation", 8)

	# ════════════════════════════════════════════════════════════════════════
	# Identity
	# ════════════════════════════════════════════════════════════════════════

	_add_group_label("🔠 Identity")

	_add_field("name", "Name", species.species_name, false)
	_add_field("dex_number", "National Dex", str(species.national_dex_number), false)
	_add_field("regional_dex", "Regional Dex", str(species.regional_dex_number), false)

	# ════════════════════════════════════════════════════════════════════════
	# Types
	# ════════════════════════════════════════════════════════════════════════

	_add_group_label("🎨 Types")

	_add_type_selector("type_1", "Type 1", species.type_1)
	_add_type_selector("type_2", "Type 2", species.type_2)

	# ════════════════════════════════════════════════════════════════════════
	# Base Stats
	# ════════════════════════════════════════════════════════════════════════

	_add_group_label("📊 Base Stats")

	_add_stat_row("hp", "HP", species.base_hp, "attack", "Atk", species.base_attack)
	_add_stat_row("defense", "Def", species.base_defense, "sp_attack", "SpA", species.base_sp_attack)
	_add_stat_row("sp_defense", "SpD", species.base_sp_defense, "speed", "Spe", species.base_speed)

	# ════════════════════════════════════════════════════════════════════════
	# EV Yield
	# ════════════════════════════════════════════════════════════════════════

	_add_group_label("⭐ EV Yield")

	_add_stat_row("ev_hp", "EV HP", species.evYield_HP, "ev_attack", "EV Atk", species.evYield_Attack)
	_add_stat_row("ev_defense", "EV Def", species.evYield_Defense, "ev_sp_attack", "EV SpA", species.evYield_SpAttack)
	_add_stat_row("ev_sp_defense", "EV SpD", species.evYield_SpDefense, "ev_speed", "EV Spe", species.evYield_Speed)

	# ════════════════════════════════════════════════════════════════════════
	# Abilities
	# ════════════════════════════════════════════════════════════════════════

	_add_group_label("💪 Abilities")

	_add_ability_selector("ability_1", "Ability 1", species.ability_1)
	_add_ability_selector("ability_2", "Ability 2", species.ability_2)
	_add_ability_selector("hidden_ability", "Hidden Ability", species.hidden_ability)

	# ════════════════════════════════════════════════════════════════════════
	# General Data
	# ════════════════════════════════════════════════════════════════════════

	_add_group_label("⚙️ General Data")

	_add_field("catch_rate", "Catch Rate", str(species.catch_rate), true)
	_add_field("exp_yield", "EXP Yield", str(species.exp_yield), true)
	_add_field("friendship", "Base Friendship", str(species.friendship), true)

	# ════════════════════════════════════════════════════════════════════════
	# Pokédex
	# ════════════════════════════════════════════════════════════════════════

	_add_group_label("📖 Pokédex")

	_add_field("category", "Category", species.category_name, false)
	_add_field("description", "Description", species.description, false, true)
	_add_field("height", "Height", str(species.height), true)
	_add_field("weight", "Weight", str(species.weight), true)

	# ════════════════════════════════════════════════════════════════════════
	# Learnset
	# ════════════════════════════════════════════════════════════════════════

	_add_group_label("📚 Level Up Moves")

	learnset_table = LearnsetTable.new()
	learnset_table.load_moves(species.level_up_moves)
	learnset_table.custom_minimum_size = Vector2(0, 150)
	add_child(learnset_table)

	# ════════════════════════════════════════════════════════════════════════
	# Evolutions
	# ════════════════════════════════════════════════════════════════════════

	_add_group_label("🔄 Evolutions")

	evolution_table = EvolutionTable.new()
	evolution_table.load_evolutions(species.evolutions)
	evolution_table.custom_minimum_size = Vector2(0, 120)
	add_child(evolution_table)

func _clear_form() -> void:
	for child in get_children():
		child.queue_free()
	fields.clear()
	type_selectors.clear()
	ability_selectors.clear()

func _add_group_label(label_text: String) -> void:
	var label = Label.new()
	label.text = label_text
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", Color.LIGHT_GRAY)
	add_child(label)

func _add_field(field_id: String, label_text: String, default_value: String, is_numeric: bool = false, is_multiline: bool = false) -> void:
	var container = HBoxContainer.new()
	container.add_theme_constant_override("separation", 8)
	add_child(container)

	var label = Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(100, 0)
	container.add_child(label)

	var input: Control

	if is_multiline:
		input = TextEdit.new()
		input.text = default_value
		input.custom_minimum_size = Vector2(0, 60)
		(input as TextEdit).text_changed.connect(_on_field_changed)
	else:
		input = LineEdit.new()
		input.text = default_value
		(input as LineEdit).text_changed.connect(_on_field_changed)

	input.custom_minimum_size = Vector2(150, 0)
	container.add_child(input)

	fields[field_id] = input

func _add_stat_row(stat1_id: String, stat1_label: String, stat1_value: int, stat2_id: String, stat2_label: String, stat2_value: int) -> void:
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	add_child(row)

	# Stat 1
	var label1 = Label.new()
	label1.text = stat1_label
	label1.custom_minimum_size = Vector2(50, 0)
	row.add_child(label1)

	var input1 = SpinBox.new()
	input1.value = stat1_value
	input1.min_value = 1
	input1.max_value = 255
	input1.custom_minimum_size = Vector2(80, 0)
	input1.value_changed.connect(_on_field_changed.bindv([null]))
	row.add_child(input1)
	fields[stat1_id] = input1

	row.add_spacer(false)

	# Stat 2
	var label2 = Label.new()
	label2.text = stat2_label
	label2.custom_minimum_size = Vector2(50, 0)
	row.add_child(label2)

	var input2 = SpinBox.new()
	input2.value = stat2_value
	input2.min_value = 1
	input2.max_value = 255
	input2.custom_minimum_size = Vector2(80, 0)
	input2.value_changed.connect(_on_field_changed.bindv([null]))
	row.add_child(input2)
	fields[stat2_id] = input2

func _add_type_selector(selector_id: String, label_text: String, default_type: PokemonData.Type) -> void:
	var container = HBoxContainer.new()
	container.add_theme_constant_override("separation", 8)
	add_child(container)

	var label = Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(100, 0)
	container.add_child(label)

	var selector = TypeSelector.new()
	selector.selected_type = default_type
	selector.type_changed.connect(_on_field_changed)
	container.add_child(selector)

	type_selectors[selector_id] = selector

func _add_ability_selector(selector_id: String, label_text: String, default_ability: AbilityId.Id) -> void:
	var container = HBoxContainer.new()
	container.add_theme_constant_override("separation", 8)
	add_child(container)

	var label = Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(100, 0)
	container.add_child(label)

	var selector = AbilitySelector.new()
	selector.selected_ability = default_ability
	selector.ability_changed.connect(_on_field_changed)
	container.add_child(selector)

	ability_selectors[selector_id] = selector

func _on_field_changed(_value = null) -> void:
	if not _is_loading:
		form_changed.emit()
