@tool
extends PanelContainer

class_name EvolutionTable

signal changed

const SPECIES_SELECTOR_SCRIPT := preload("res://addons/species_editor/controls/species_selector.gd")

enum ConditionType {
	LEVEL,
	FRIENDSHIP,
	ITEM,
	TIME,
	GENDER,
	MOVE,
	PARTY_SPECIES,
	STAT_RELATION,
	MAP,
	WEATHER,
	REGION,
	FLAG,
}

var evolutions: Array[EvolutionData] = []
var available_species: Array[PokemonDataStruct] = []
var content: VBoxContainer
var rebuilding := false

func load_evolutions(values: Array[EvolutionData]) -> void:
	evolutions = values.duplicate(true)
	if content != null:
		_refresh_table()

func _ready() -> void:
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 6)
	add_child(root)

	var header := HBoxContainer.new()
	root.add_child(header)
	var title := Label.new()
	title.text = "Reglas de evolución"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var add_button := Button.new()
	add_button.text = "+ Añadir regla"
	add_button.pressed.connect(_on_add_evolution_pressed)
	header.add_child(add_button)

	content = VBoxContainer.new()
	content.add_theme_constant_override("separation", 6)
	root.add_child(content)
	_refresh_table()

func _clear_content() -> void:
	for child: Node in content.get_children():
		child.free()

func _refresh_table() -> void:
	if content == null or rebuilding:
		return
	rebuilding = true
	_clear_content()
	for index: int in range(evolutions.size()):
		if evolutions[index] != null:
			content.add_child(_build_rule(index, evolutions[index]))
	rebuilding = false

func _build_rule(index: int, evolution: EvolutionData) -> Control:
	var panel := PanelContainer.new()
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 4)
	panel.add_child(root)

	var header := HBoxContainer.new()
	root.add_child(header)
	var target := SPECIES_SELECTOR_SCRIPT.new() as SpeciesSelector
	target.available_species = available_species
	target.selected_species = evolution.target_species
	target.custom_minimum_size = Vector2(210, 0)
	target.species_changed.connect(func() -> void:
		evolution.target_species = target.selected_species
		changed.emit()
	)
	header.add_child(target)

	var trigger := _enum_option(EvolutionTrigger.Trigger.keys(), EvolutionTrigger.Trigger.values(), int(evolution.trigger))
	trigger.tooltip_text = "Activador"
	trigger.item_selected.connect(func(_selected: int) -> void:
		evolution.trigger = trigger.get_selected_id() as EvolutionTrigger.Trigger
		changed.emit()
	)
	header.add_child(trigger)

	var advanced := CheckBox.new()
	advanced.text = "Regla avanzada"
	advanced.button_pressed = evolution.use_advanced_rules
	advanced.toggled.connect(func(value: bool) -> void:
		evolution.use_advanced_rules = value
		if value and evolution.conditions.is_empty():
			evolution.conditions.append(_new_condition(ConditionType.LEVEL))
		_refresh_table()
		changed.emit()
	)
	header.add_child(advanced)

	var remove := Button.new()
	remove.text = "✕"
	remove.tooltip_text = "Eliminar regla"
	remove.pressed.connect(func() -> void:
		evolutions.remove_at(index)
		_refresh_table()
		changed.emit()
	)
	header.add_child(remove)

	if evolution.use_advanced_rules:
		_build_advanced_editor(root, index, evolution)
	else:
		_build_legacy_editor(root, index, evolution)
	return panel

func _build_legacy_editor(root: VBoxContainer, index: int, evolution: EvolutionData) -> void:
	var grid := GridContainer.new()
	grid.columns = 4
	root.add_child(grid)
	grid.add_child(_label("Método"))
	var method := _enum_option(PokemonData.EvolutionMethods.keys(), PokemonData.EvolutionMethods.values(), int(evolution.method))
	method.item_selected.connect(func(_selected: int) -> void:
		evolution.method = method.get_selected_id() as PokemonData.EvolutionMethods
		changed.emit()
	)
	grid.add_child(method)
	grid.add_child(_label("Parámetro"))
	var parameter := _spin(0, 999999, evolution.parameter)
	parameter.value_changed.connect(func(value: float) -> void:
		evolution.parameter = int(value)
		changed.emit()
	)
	grid.add_child(parameter)

	grid.add_child(_label("Condición"))
	var condition := _enum_option(PokemonData.EvolutionConditions.keys(), PokemonData.EvolutionConditions.values(), int(evolution.condition))
	condition.item_selected.connect(func(_selected: int) -> void:
		evolution.condition = condition.get_selected_id() as PokemonData.EvolutionConditions
		changed.emit()
	)
	grid.add_child(condition)
	grid.add_child(_label("Valor"))
	var value := _spin(0, 999999, evolution.condition_value)
	value.value_changed.connect(func(number: float) -> void:
		evolution.condition_value = int(number)
		changed.emit()
	)
	grid.add_child(value)

func _build_advanced_editor(root: VBoxContainer, _index: int, evolution: EvolutionData) -> void:
	var title := Label.new()
	title.text = "Condiciones (todas deben cumplirse)"
	title.add_theme_color_override("font_color", Color.LIGHT_GRAY)
	root.add_child(title)

	for condition_index: int in range(evolution.conditions.size()):
		var condition: EvolutionCondition = evolution.conditions[condition_index]
		if condition != null:
			root.add_child(_build_condition_editor(evolution, condition_index, condition))

	var add_condition := Button.new()
	add_condition.text = "+ Añadir condición"
	add_condition.pressed.connect(func() -> void:
		evolution.conditions.append(_new_condition(ConditionType.LEVEL))
		_refresh_table()
		changed.emit()
	)
	root.add_child(add_condition)

func _build_condition_editor(evolution: EvolutionData, condition_index: int, condition: EvolutionCondition) -> Control:
	var row := VBoxContainer.new()
	var top := HBoxContainer.new()
	row.add_child(top)

	var type_option := OptionButton.new()
	var types := _condition_types()
	var current_type := _condition_type(condition)
	for type_id: int in types:
		type_option.add_item(types[type_id], type_id)
	if types.has(current_type):
		type_option.select(types.keys().find(current_type))
	type_option.item_selected.connect(func(_selected: int) -> void:
		evolution.conditions[condition_index] = _new_condition(type_option.get_selected_id())
		_refresh_table()
		changed.emit()
	)
	top.add_child(type_option)

	var remove := Button.new()
	remove.text = "Eliminar"
	remove.pressed.connect(func() -> void:
		evolution.conditions.remove_at(condition_index)
		_refresh_table()
		changed.emit()
	)
	top.add_child(remove)
	row.add_child(_build_condition_fields(condition))
	return row

func _build_condition_fields(condition: EvolutionCondition) -> Control:
	var fields := HBoxContainer.new()
	if condition is EvolutionConditionLevel:
		fields.add_child(_label("Nivel mínimo"))
		var level := _spin(1, 100, condition.minimum_level)
		level.value_changed.connect(func(value: float) -> void: condition.minimum_level = int(value); changed.emit())
		fields.add_child(level)
	elif condition is EvolutionConditionFriendship:
		fields.add_child(_label("Amistad mínima"))
		var friendship := _spin(0, 255, condition.minimum_friendship)
		friendship.value_changed.connect(func(value: float) -> void: condition.minimum_friendship = int(value); changed.emit())
		fields.add_child(friendship)
		var time := _enum_option(EvolutionConditionFriendship.TimeRequirement.keys(), EvolutionConditionFriendship.TimeRequirement.values(), int(condition.time_requirement))
		time.item_selected.connect(func(_selected: int) -> void: condition.time_requirement = time.get_selected_id() as EvolutionConditionFriendship.TimeRequirement; changed.emit())
		fields.add_child(time)
	elif condition is EvolutionConditionItem:
		fields.add_child(_label("ID objeto"))
		var item := _spin(0, 999999, condition.required_item_id)
		item.value_changed.connect(func(value: float) -> void: condition.required_item_id = int(value); changed.emit())
		fields.add_child(item)
		var held := CheckBox.new()
		held.text = "Objeto equipado"
		held.button_pressed = condition.check_held_item
		held.toggled.connect(func(value: bool) -> void: condition.check_held_item = value; changed.emit())
		fields.add_child(held)
	elif condition is EvolutionConditionTime:
		fields.add_child(_label("Hora"))
		var time := _enum_option(EvolutionConditionTime.RequiredTime.keys(), EvolutionConditionTime.RequiredTime.values(), int(condition.required_time))
		time.item_selected.connect(func(_selected: int) -> void: condition.required_time = time.get_selected_id() as EvolutionConditionTime.RequiredTime; changed.emit())
		fields.add_child(time)
	elif condition is EvolutionConditionGender:
		fields.add_child(_label("Género"))
		var gender := _enum_option(PokemonData.Gender.keys(), PokemonData.Gender.values(), int(condition.required_gender))
		gender.item_selected.connect(func(_selected: int) -> void: condition.required_gender = gender.get_selected_id() as PokemonData.Gender; changed.emit())
		fields.add_child(gender)
	elif condition is EvolutionConditionKnowsMove:
		fields.add_child(_label("ID movimiento"))
		var move := _spin(0, 999999, condition.required_move_id)
		move.value_changed.connect(func(value: float) -> void: condition.required_move_id = int(value); changed.emit())
		fields.add_child(move)
	elif condition is EvolutionConditionPartySpecies:
		fields.add_child(_label("ID especie"))
		var species := _spin(0, 999999, condition.required_species_id)
		species.value_changed.connect(func(value: float) -> void: condition.required_species_id = int(value); changed.emit())
		fields.add_child(species)
	elif condition is EvolutionConditionStatRelation:
		var left := _enum_option(PokemonInstance.Stat.keys(), PokemonInstance.Stat.values(), int(condition.left_stat))
		left.item_selected.connect(func(_selected: int) -> void: condition.left_stat = left.get_selected_id() as PokemonInstance.Stat; changed.emit())
		fields.add_child(left)
		var relation := _enum_option(EvolutionConditionStatRelation.Relation.keys(), EvolutionConditionStatRelation.Relation.values(), int(condition.relation))
		relation.item_selected.connect(func(_selected: int) -> void: condition.relation = relation.get_selected_id() as EvolutionConditionStatRelation.Relation; changed.emit())
		fields.add_child(relation)
		var right := _enum_option(PokemonInstance.Stat.keys(), PokemonInstance.Stat.values(), int(condition.right_stat))
		right.item_selected.connect(func(_selected: int) -> void: condition.right_stat = right.get_selected_id() as PokemonInstance.Stat; changed.emit())
		fields.add_child(right)
	elif condition is EvolutionConditionMap:
		fields.add_child(_label("ID mapa"))
		var map := _spin(0, 999999, condition.required_map_id)
		map.value_changed.connect(func(value: float) -> void: condition.required_map_id = int(value); changed.emit())
		fields.add_child(map)
	elif condition is EvolutionConditionWeather:
		fields.add_child(_label("ID clima"))
		var weather := _spin(0, 999999, condition.required_weather_id)
		weather.value_changed.connect(func(value: float) -> void: condition.required_weather_id = int(value); changed.emit())
		fields.add_child(weather)
	elif condition is EvolutionConditionRegion:
		fields.add_child(_label("ID región"))
		var region := _spin(0, 999999, condition.required_region_id)
		region.value_changed.connect(func(value: float) -> void: condition.required_region_id = int(value); changed.emit())
		fields.add_child(region)
	elif condition is EvolutionConditionFlag:
		fields.add_child(_label("Flag"))
		var flag := LineEdit.new()
		flag.text = str(condition.required_flag)
		flag.custom_minimum_size = Vector2(160, 0)
		flag.text_changed.connect(func(value: String) -> void: condition.required_flag = StringName(value); changed.emit())
		fields.add_child(flag)
	return fields

func _new_condition(type_id: int) -> EvolutionCondition:
	match type_id:
		ConditionType.LEVEL: return EvolutionConditionLevel.new()
		ConditionType.FRIENDSHIP: return EvolutionConditionFriendship.new()
		ConditionType.ITEM: return EvolutionConditionItem.new()
		ConditionType.TIME: return EvolutionConditionTime.new()
		ConditionType.GENDER: return EvolutionConditionGender.new()
		ConditionType.MOVE: return EvolutionConditionKnowsMove.new()
		ConditionType.PARTY_SPECIES: return EvolutionConditionPartySpecies.new()
		ConditionType.STAT_RELATION: return EvolutionConditionStatRelation.new()
		ConditionType.MAP: return EvolutionConditionMap.new()
		ConditionType.WEATHER: return EvolutionConditionWeather.new()
		ConditionType.REGION: return EvolutionConditionRegion.new()
		ConditionType.FLAG: return EvolutionConditionFlag.new()
	return EvolutionConditionLevel.new()

func _condition_type(condition: EvolutionCondition) -> int:
	if condition is EvolutionConditionLevel: return ConditionType.LEVEL
	if condition is EvolutionConditionFriendship: return ConditionType.FRIENDSHIP
	if condition is EvolutionConditionItem: return ConditionType.ITEM
	if condition is EvolutionConditionTime: return ConditionType.TIME
	if condition is EvolutionConditionGender: return ConditionType.GENDER
	if condition is EvolutionConditionKnowsMove: return ConditionType.MOVE
	if condition is EvolutionConditionPartySpecies: return ConditionType.PARTY_SPECIES
	if condition is EvolutionConditionStatRelation: return ConditionType.STAT_RELATION
	if condition is EvolutionConditionMap: return ConditionType.MAP
	if condition is EvolutionConditionWeather: return ConditionType.WEATHER
	if condition is EvolutionConditionRegion: return ConditionType.REGION
	if condition is EvolutionConditionFlag: return ConditionType.FLAG
	return ConditionType.LEVEL

func _condition_types() -> Dictionary:
	return {
		ConditionType.LEVEL: "Nivel",
		ConditionType.FRIENDSHIP: "Amistad",
		ConditionType.ITEM: "Objeto",
		ConditionType.TIME: "Hora",
		ConditionType.GENDER: "Género",
		ConditionType.MOVE: "Movimiento conocido",
		ConditionType.PARTY_SPECIES: "Especie en equipo",
		ConditionType.STAT_RELATION: "Relación de estadísticas",
		ConditionType.MAP: "Mapa",
		ConditionType.WEATHER: "Clima",
		ConditionType.REGION: "Región",
		ConditionType.FLAG: "Flag de evento",
	}

func _enum_option(names: Array, values: Array, current_value: int) -> OptionButton:
	var option := OptionButton.new()
	var selected := 0
	for i: int in range(values.size()):
		var id := int(values[i])
		option.add_item("[%d] %s" % [id, str(names[i]).replace("_", " ").capitalize()], id)
		if id == current_value:
			selected = i
	option.select(selected)
	return option

func _spin(minimum: float, maximum: float, value: int) -> SpinBox:
	var spin := SpinBox.new()
	spin.min_value = minimum
	spin.max_value = maximum
	spin.step = 1
	spin.value = value
	return spin

func _label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	return label

func _on_add_evolution_pressed() -> void:
	var rule := EvolutionData.new()
	rule.target_species = Species.SpeciesID.SPECIES_NONE
	rule.method = PokemonData.EvolutionMethods.EVO_LEVEL
	rule.parameter = 16
	rule.condition = PokemonData.EvolutionConditions.NONE
	rule.use_advanced_rules = true
	rule.trigger = EvolutionTrigger.Trigger.LEVEL_UP
	var level := EvolutionConditionLevel.new()
	level.minimum_level = 16
	rule.conditions.append(level)
	evolutions.append(rule)
	_refresh_table()
	changed.emit()

func get_evolutions() -> Array[EvolutionData]:
	return evolutions.duplicate(true)
