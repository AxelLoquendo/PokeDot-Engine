extends RefCounted

class_name EvolutionResult

var evolution: EvolutionData
var target_species: Species.SpeciesID
var target_form_id: StringName = &"base"

func _init(data: EvolutionData = null) -> void:
	evolution = data
	if data:
		target_species = data.target_species
		target_form_id = data.target_form_id
	else:
		target_species = Species.SpeciesID.SPECIES_NONE
