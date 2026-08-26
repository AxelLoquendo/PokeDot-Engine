@tool
extends Resource

class_name EvolutionData

## Regla de evolución. Los campos legacy se conservan para no romper los .tres actuales.

@export_group("Destino")
@export var target_species: Species.SpeciesID = Species.SpeciesID.SPECIES_NONE
## Forma que tendrá el Pokémon al evolucionar; "base" conserva la forma normal.
@export var target_form_id: StringName = &"base"

@export_group("Regla nueva")
@export var use_advanced_rules: bool = false
@export var trigger: EvolutionTrigger.Trigger = EvolutionTrigger.Trigger.LEVEL_UP
@export var conditions: Array[EvolutionCondition] = []
@export var priority: int = 0
@export var enabled: bool = true

@export_group("Legacy (compatibilidad)")
@export var method: PokemonData.EvolutionMethods = PokemonData.EvolutionMethods.EVO_NONE
@export var parameter: int = 0
@export var condition: PokemonData.EvolutionConditions = PokemonData.EvolutionConditions.NONE
@export var condition_value: int = 0

func is_advanced_rule() -> bool:
	return use_advanced_rules

func get_condition_descriptions() -> Array[String]:
	var result: Array[String] = []
	for item: EvolutionCondition in conditions:
		if item != null:
			result.append(item.get_description())
	return result

func duplicate_rule() -> EvolutionData:
	return duplicate(true) as EvolutionData
