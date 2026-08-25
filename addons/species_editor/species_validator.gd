extends RefCounted

class_name SpeciesValidator

## Validates PokemonDataStruct for data integrity

func validate(species: PokemonDataStruct) -> Array[String]:
	var errors: Array[String] = []

	if species == null:
		errors.append("Species is null")
		return errors

	# Identity
	if species.species_id == Species.SpeciesID.SPECIES_NONE:
		errors.append("Missing species_id")

	if species.species_name.is_empty():
		errors.append("Missing species_name")

	if species.national_dex_number < 1:
		errors.append("Invalid national_dex_number")

	# Base Stats
	if species.base_hp < 1:
		errors.append("base_hp must be >= 1")
	if species.base_attack < 1:
		errors.append("base_attack must be >= 1")
	if species.base_defense < 1:
		errors.append("base_defense must be >= 1")
	if species.base_speed < 1:
		errors.append("base_speed must be >= 1")
	if species.base_sp_attack < 1:
		errors.append("base_sp_attack must be >= 1")
	if species.base_sp_defense < 1:
		errors.append("base_sp_defense must be >= 1")

	# Types
	if species.type_1 == PokemonData.Type.TYPE_NONE:
		errors.append("type_1 must not be TYPE_NONE")

	# Abilities
	if species.ability_1 == AbilityId.Id.NONE:
		errors.append("ability_1 must not be NONE")

	return errors
