@tool
extends EvolutionCondition

class_name EvolutionConditionPartySpecies

@export var required_species_id: Species.SpeciesID = Species.SpeciesID.SPECIES_NONE

func is_met(context: EvolutionContext) -> bool:
	if context == null:
		return false
	for member: PokemonInstance in context.party:
		if member != null and int(member.species_id) == required_species_id:
			return true
	return false

func get_description() -> String:
	return "Tener especie [%d] en el equipo" % required_species_id
