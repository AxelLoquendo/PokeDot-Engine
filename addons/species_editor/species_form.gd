@tool
extends VBoxContainer

class_name SpeciesForm

## Form to edit a PokemonDataStruct

signal form_changed

var current_species: PokemonDataStruct = null
var _is_loading: bool = false

# Field references
var fields: Dictionary = {}

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

	# Aplicar cambios desde el formulario
	species.species_name = fields["name"].text
	species.national_dex_number = int(fields["dex_number"].text) if fields["dex_number"].text.is_valid_int() else 1
	species.regional_dex_number = int(fields["regional_dex"].text) if fields["regional_dex"].text.is_valid_int() else 0

	# Stats
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

	# Otros
	species.catch_rate = int(fields["catch_rate"].text) if fields["catch_rate"].text.is_valid_int() else 45
	species.exp_yield = int(fields["exp_yield"].text) if fields["exp_yield"].text.is_valid_int() else 0
	species.friendship = int(fields["friendship"].text) if fields["friendship"].text.is_valid_int() else 70
	species.category_name = fields["category"].text
	species.description = fields["description"].text
	species.height = int(fields["height"].text) if fields["height"].text.is_valid_int() else 1
	species.weight = int(fields["weight"].text) if fields["weight"].text.is_valid_int() else 1

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

	return true

func _populate_form(species: PokemonDataStruct) -> void:
	if get_child_count() > 0:
		for child in get_children():
			child.queue_free()

	fields.clear()
	add_theme_constant_override("separation", 8)

	# ─────────────────────────────
	# Identity
	# ─────────────────────────────

	_add_group_label("🆔 Identity")

	_add_field("name", "Name", species.species_name, false)
	_add_field("dex_number", "National Dex", str(species.national_dex_number), false)
	_add_field("regional_dex", "Regional Dex", str(species.regional_dex_number), false)

	# ─────────────────────────────
	# Base Stats
	# ─────────────────────────────

	_add_group_label("📊 Base Stats")

	_add_field("hp", "HP", str(species.base_hp), true)
	_add_field("attack", "Attack", str(species.base_attack), true)
	_add_field("defense", "Defense", str(species.base_defense), true)
	_add_field("speed", "Speed", str(species.base_speed), true)
	_add_field("sp_attack", "Sp. Attack", str(species.base_sp_attack), true)
	_add_field("sp_defense", "Sp. Defense", str(species.base_sp_defense), true)

	# ─────────────────────────────
	# EV Yield
	# ─────────────────────────────

	_add_group_label("⭐ EV Yield")

	_add_field("ev_hp", "EV HP", str(species.evYield_HP), true)
	_add_field("ev_attack", "EV Attack", str(species.evYield_Attack), true)
	_add_field("ev_defense", "EV Defense", str(species.evYield_Defense), true)
	_add_field("ev_speed", "EV Speed", str(species.evYield_Speed), true)
	_add_field("ev_sp_attack", "EV Sp. Attack", str(species.evYield_SpAttack), true)
	_add_field("ev_sp_defense", "EV Sp. Defense", str(species.evYield_SpDefense), true)

	# ─────────────────────────────
	# General Data
	# ─────────────────────────────

	_add_group_label("⚙️ General Data")

	_add_field("catch_rate", "Catch Rate", str(species.catch_rate), true)
	_add_field("exp_yield", "EXP Yield", str(species.exp_yield), true)
	_add_field("friendship", "Base Friendship", str(species.friendship), true)

	# ─────────────────────────────
	# Pokédex
	# ─────────────────────────────

	_add_group_label("📖 Pokédex")

	_add_field("category", "Category", species.category_name, false)
	_add_field("description", "Description", species.description, false, true)
	_add_field("height", "Height", str(species.height), true)
	_add_field("weight", "Weight", str(species.weight), true)

func _clear_form() -> void:
	for child in get_children():
		child.queue_free()
	fields.clear()

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
	label.custom_minimum_size = Vector2(120, 0)
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
		if is_numeric:
			(input as LineEdit).text_changed.connect(_on_field_changed)
		else:
			(input as LineEdit).text_changed.connect(_on_field_changed)

	input.custom_minimum_size = Vector2(150, 0)
	container.add_child(input)

	fields[field_id] = input

func _on_field_changed(_value: String) -> void:
	if not _is_loading:
		form_changed.emit()
