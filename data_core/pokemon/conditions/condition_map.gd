@tool
extends EvolutionCondition

class_name EvolutionConditionMap

@export var required_map_id: int = 0
@export var invert: bool = false

func is_met(context: EvolutionContext) -> bool:
	if context == null:
		return false
	var result: bool = context.current_map_id == required_map_id
	return not result if invert else result

func get_description() -> String:
	return ("No estar en mapa [%d]" if invert else "Estar en mapa [%d]") % required_map_id
