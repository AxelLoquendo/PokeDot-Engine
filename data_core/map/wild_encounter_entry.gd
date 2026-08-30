extends Resource
class_name WildEncounterEntry

@export var species_id: Species.SpeciesID = Species.SpeciesID.SPECIES_NONE
@export_range(1, 100) var min_level: int = 2
@export_range(1, 100) var max_level: int = 4
@export_range(1, 255) var weight: int = 20
