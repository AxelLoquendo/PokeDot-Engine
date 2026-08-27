extends RefCounted

class_name EvolutionSystem

static func get_available_evolutions(
	pokemon: PokemonInstance,
	mode: PokemonData.EvolutionMode,
	context: EvolutionContext = null
) -> Array[EvolutionResult]:
	var results: Array[EvolutionResult] = []
	if pokemon == null:
		return results

	var species_data: PokemonDataStruct = pokemon.get_species()
	if species_data == null:
		return results

	var evaluation_context: EvolutionContext = context
	if evaluation_context == null:
		evaluation_context = EvolutionContext.new(pokemon)
	evaluation_context.pokemon = pokemon
	evaluation_context.mode = mode

	for evolution: EvolutionData in _get_evolution_rules(pokemon, species_data):
		if evolution != null and can_evolve(pokemon, evolution, evaluation_context):
			results.append(EvolutionResult.new(evolution))

	results.sort_custom(func(a: EvolutionResult, b: EvolutionResult) -> bool:
		return a.evolution.priority < b.evolution.priority
	)
	return results

static func _get_evolution_rules(
	pokemon: PokemonInstance,
	species_data: PokemonDataStruct
) -> Array[EvolutionData]:
	var rules: Array[EvolutionData] = species_data.evolutions.duplicate(true)
	var form: PokemonFormData = PokemonFormResolver.get_form(pokemon)
	if form == null:
		return rules
	if not form.inherit_base_evolutions:
		return form.evolutions.duplicate(true)
	for rule: EvolutionData in form.evolutions:
		if rule != null:
			rules.append(rule)
	return rules

## Acepta el contexto nuevo y también el modo antiguo para no romper llamadas existentes.
static func can_evolve(
	pokemon: PokemonInstance,
	evolution: EvolutionData,
	value: Variant
) -> bool:
	if pokemon == null or evolution == null or not evolution.enabled:
		return false

	if evolution.is_advanced_rule():
		var context: EvolutionContext
		if value is EvolutionContext:
			context = value as EvolutionContext
		else:
			context = EvolutionContext.new(pokemon)
			context.mode = value as PokemonData.EvolutionMode
		context.pokemon = pokemon
		return _check_advanced_rule(evolution, context)

	var mode: PokemonData.EvolutionMode = value as PokemonData.EvolutionMode
	return _check_legacy_rule(pokemon, evolution, mode)

static func _check_advanced_rule(
	evolution: EvolutionData,
	context: EvolutionContext
) -> bool:
	if not _check_trigger(evolution.trigger, context.mode):
		return false

	for condition: EvolutionCondition in evolution.conditions:
		if condition == null:
			continue
		if not condition.is_met(context):
			return false
	return true

static func _check_trigger(
	trigger: EvolutionTrigger.Trigger,
	mode: PokemonData.EvolutionMode
) -> bool:
	match trigger:
		EvolutionTrigger.Trigger.LEVEL_UP:
			return mode == PokemonData.EvolutionMode.EVO_MODE_NORMAL
		EvolutionTrigger.Trigger.LEVEL_UP_BATTLE_ONLY:
			return mode == PokemonData.EvolutionMode.EVO_MODE_BATTLE_ONLY
		EvolutionTrigger.Trigger.ITEM_USED:
			return mode == PokemonData.EvolutionMode.EVO_MODE_ITEM_USE
		EvolutionTrigger.Trigger.TRADE:
			return mode == PokemonData.EvolutionMode.EVO_MODE_TRADE
		EvolutionTrigger.Trigger.BATTLE_END:
			return mode == PokemonData.EvolutionMode.EVO_MODE_BATTLE_SPECIAL
		EvolutionTrigger.Trigger.OVERWORLD_EVENT:
			return mode == PokemonData.EvolutionMode.EVO_MODE_OVERWORLD_SPECIAL
		EvolutionTrigger.Trigger.SCRIPT_EVENT:
			return mode == PokemonData.EvolutionMode.EVO_MODE_SCRIPT_TRIGGER
	return false

static func _check_legacy_rule(
	pokemon: PokemonInstance,
	evolution: EvolutionData,
	mode: PokemonData.EvolutionMode
) -> bool:
	if not _check_legacy_method(pokemon, evolution, mode):
		return false
	return _check_legacy_condition(pokemon, evolution)

static func _check_legacy_method(
	pokemon: PokemonInstance,
	evolution: EvolutionData,
	mode: PokemonData.EvolutionMode
) -> bool:
	match evolution.method:
		PokemonData.EvolutionMethods.EVO_NONE:
			return false
		PokemonData.EvolutionMethods.EVO_LEVEL:
			return mode == PokemonData.EvolutionMode.EVO_MODE_NORMAL and pokemon.level >= evolution.parameter
		PokemonData.EvolutionMethods.EVO_TRADE:
			return mode == PokemonData.EvolutionMode.EVO_MODE_TRADE
		PokemonData.EvolutionMethods.EVO_ITEM:
			return mode == PokemonData.EvolutionMode.EVO_MODE_ITEM_USE
		PokemonData.EvolutionMethods.EVO_SCRIPT_TRIGGER:
			return mode == PokemonData.EvolutionMode.EVO_MODE_SCRIPT_TRIGGER
		PokemonData.EvolutionMethods.EVO_LEVEL_BATTLE_ONLY:
			return mode == PokemonData.EvolutionMode.EVO_MODE_BATTLE_ONLY and pokemon.level >= evolution.parameter
		PokemonData.EvolutionMethods.EVO_BATTLE_END:
			return mode == PokemonData.EvolutionMode.EVO_MODE_BATTLE_SPECIAL
		PokemonData.EvolutionMethods.EVO_SPIN:
			return mode == PokemonData.EvolutionMode.EVO_MODE_OVERWORLD_SPECIAL
		PokemonData.EvolutionMethods.EVO_SPLIT_FROM_EVO:
			return false
	return false

static func _check_legacy_condition(
	pokemon: PokemonInstance,
	evolution: EvolutionData
) -> bool:
	match evolution.condition:
		PokemonData.EvolutionConditions.NONE:
			return true
		PokemonData.EvolutionConditions.IF_MIN_FRIENDSHIP:
			return pokemon.friendship >= evolution.condition_value
	return false

static func evolve(
	pokemon: PokemonInstance,
	result: EvolutionResult,
	value: Variant
) -> bool:
	if pokemon == null or result == null:
		return false
	if result.target_species == Species.SpeciesID.SPECIES_NONE:
		return false
	if not can_evolve(pokemon, result.evolution, value):
		return false
	# En el modelo nuevo, target_species puede ser el ID de una especie base
	# o directamente el ID de una forma declarado en species.gd.
	pokemon.species_id = result.target_species
	pokemon.form_id = &"base"

	# Compatibilidad con reglas antiguas que todavía apuntan a una forma textual.
	if result.target_form_id != &"base":
		pokemon.form_id = result.target_form_id
		var target_base: PokemonDataStruct = pokemon.get_species()
		if target_base != null:
			for form: PokemonFormData in target_base.forms:
				if form != null and form.form_id == result.target_form_id and form.species_id != Species.SpeciesID.SPECIES_NONE:
					pokemon.species_id = form.species_id
					break
	return true
