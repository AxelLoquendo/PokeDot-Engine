extends RefCounted
class_name EvolutionResult

var evolution: EvolutionData
var target_species: Species.SpeciesID

func _init(data: EvolutionData = null) -> void:
	evolution = data

	if data:
		target_species = data.target_species
	else:
		target_species = Species.SpeciesID.SPECIES_NONE
