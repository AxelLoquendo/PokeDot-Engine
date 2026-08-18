extends RefCounted
class_name EvolutionSystem


static func get_available_evolutions(
	pokemon: PokemonInstance,
	mode: PokemonData.EvolutionMode
) -> Array[EvolutionResult]:

	var results: Array[EvolutionResult] = []

	if pokemon == null:
		return results

	var species_data: PokemonDataStruct = pokemon.get_species()

	if species_data == null:
		return results

	for evolution: EvolutionData in species_data.evolutions:

		if evolution == null:
			continue

		if can_evolve(pokemon, evolution, mode):
			results.append(
				EvolutionResult.new(evolution)
			)

	return results

static func can_evolve(pokemon: PokemonInstance, evolution: EvolutionData, mode: PokemonData.EvolutionMode) -> bool:

	if pokemon == null:
		return false

	if evolution == null:
		return false

	if not _check_method(pokemon, evolution, mode):
		return false

	if not _check_condition(pokemon, evolution):
		return false

	return true

static func _check_method(
	pokemon: PokemonInstance,
	evolution: EvolutionData,
	mode: PokemonData.EvolutionMode
) -> bool:

	match evolution.method:

		PokemonData.EvolutionMethods.EVO_NONE:
			return false

		PokemonData.EvolutionMethods.EVO_LEVEL:
			if mode != PokemonData.EvolutionMode.EVO_MODE_NORMAL:
				return false

			return pokemon.level >= evolution.parameter

		PokemonData.EvolutionMethods.EVO_TRADE:
			return mode == PokemonData.EvolutionMode.EVO_MODE_TRADE

		PokemonData.EvolutionMethods.EVO_ITEM:
			return mode == PokemonData.EvolutionMode.EVO_MODE_ITEM_USE

		PokemonData.EvolutionMethods.EVO_SCRIPT_TRIGGER:
			return mode == PokemonData.EvolutionMode.EVO_MODE_SCRIPT_TRIGGER

		PokemonData.EvolutionMethods.EVO_LEVEL_BATTLE_ONLY:
			if mode != PokemonData.EvolutionMode.EVO_MODE_BATTLE_ONLY:
				return false

			return pokemon.level >= evolution.parameter

		PokemonData.EvolutionMethods.EVO_BATTLE_END:
			return mode == PokemonData.EvolutionMode.EVO_MODE_BATTLE_SPECIAL

		PokemonData.EvolutionMethods.EVO_SPIN:
			return mode == PokemonData.EvolutionMode.EVO_MODE_OVERWORLD_SPECIAL

		PokemonData.EvolutionMethods.EVO_SPLIT_FROM_EVO:
			return false

		_:
			return false

static func _check_condition(pokemon: PokemonInstance, evolution: EvolutionData) -> bool:

	match evolution.condition:

		PokemonData.EvolutionConditions.NONE:
			return true

		PokemonData.EvolutionConditions.IF_MIN_FRIENDSHIP:
			return _check_min_friendship(
				pokemon,
				evolution.condition_value
			)

		_:
			return false

static func _check_min_friendship(pokemon: PokemonInstance, required_friendship: int) -> bool:
	return pokemon.friendship >= required_friendship

static func evolve(pokemon: PokemonInstance, result: EvolutionResult, mode: PokemonData.EvolutionMode) -> bool:

	if pokemon == null:
		return false

	if result == null:
		return false

	if result.target_species == Species.SpeciesID.SPECIES_NONE:
		return false

	if not can_evolve(pokemon, result.evolution, mode):
		return false

	pokemon.species_id = result.target_species

	return true
