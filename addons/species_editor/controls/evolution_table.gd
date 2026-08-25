extends PanelContainer

class_name EvolutionTable

## Tabla editable para Evolutions

var evolutions: Array[EvolutionData] = []
var table: GridContainer

func load_evolutions(evolutions_array: Array[EvolutionData]) -> void:
	evolutions = evolutions_array.duplicate()
	_refresh_table()

func _ready() -> void:
	var container = VBoxContainer.new()
	container.add_theme_constant_override("separation", 4)
	add_child(container)

	# Header
	var header = HBoxContainer.new()
	container.add_child(header)

	var title = Label.new()
	title.text = "Method | Species | Param | Condition | Value"
	title.add_theme_color_override("font_color", Color.LIGHT_GRAY)
	title.add_theme_font_size_override("font_size", 10)
	header.add_child(title)
	header.add_spacer(false)

	var add_btn = Button.new()
	add_btn.text = "+ Add Evolution"
	add_btn.pressed.connect(_on_add_evolution_pressed)
	header.add_child(add_btn)

	# Table
	table = GridContainer.new()
	table.columns = 5
	container.add_child(table)

	_refresh_table()

func _refresh_table() -> void:
	if table == null:
		return

	table.clear()

	for i in range(evolutions.size()):
		var evo = evolutions[i]

		# Method (read-only label)
		var method_label = Label.new()
		method_label.text = _get_method_name(evo.method)
		method_label.custom_minimum_size = Vector2(80, 0)
		table.add_child(method_label)

		# Target Species
		var species_label = Label.new()
		species_label.text = str(evo.target_species)
		species_label.custom_minimum_size = Vector2(70, 0)
		table.add_child(species_label)

		# Parameter
		var param_spin = SpinBox.new()
		param_spin.value = evo.parameter
		param_spin.min_value = 0
		param_spin.max_value = 255
		param_spin.custom_minimum_size = Vector2(50, 0)
		table.add_child(param_spin)

		# Condition (read-only)
		var condition_label = Label.new()
		condition_label.text = _get_condition_name(evo.condition)
		condition_label.custom_minimum_size = Vector2(80, 0)
		table.add_child(condition_label)

		# Condition Value
		var value_spin = SpinBox.new()
		value_spin.value = evo.condition_value
		value_spin.min_value = 0
		value_spin.max_value = 255
		value_spin.custom_minimum_size = Vector2(50, 0)
		table.add_child(value_spin)

func _get_method_name(method: PokemonData.EvolutionMethods) -> String:
	match method:
		PokemonData.EvolutionMethods.EVO_LEVEL:
			return "Level"
		PokemonData.EvolutionMethods.EVO_TRADE:
			return "Trade"
		PokemonData.EvolutionMethods.EVO_ITEM:
			return "Item"
		_:
			return "Unknown"

func _get_condition_name(condition: PokemonData.EvolutionConditions) -> String:
	match condition:
		PokemonData.EvolutionConditions.NONE:
			return "None"
		PokemonData.EvolutionConditions.IF_MIN_FRIENDSHIP:
			return "Friendship"
		_:
			return "Unknown"

func get_evolutions() -> Array[EvolutionData]:
	return evolutions
