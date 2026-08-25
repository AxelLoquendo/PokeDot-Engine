@tool
extends EvolutionCondition

class_name EvolutionConditionRegion

@export var required_region_id: int = 0
@export var invert: bool = false

func is_met(context: EvolutionContext) -> bool:
	if context == null:
		return false
	var result: bool = context.current_region_id == required_region_id
	return not result if invert else result

func get_description() -> String:
	return ("No estar en región [%d]" if invert else "Estar en región [%d]") % required_region_id
