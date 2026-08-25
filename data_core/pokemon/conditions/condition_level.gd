@tool
extends EvolutionCondition

class_name EvolutionConditionLevel

@export_range(1, 100) var minimum_level: int = 16

func is_met(context: EvolutionContext) -> bool:
	return context != null and context.pokemon != null and context.pokemon.level >= minimum_level

func get_description() -> String:
	return "Nivel %d o superior" % minimum_level
