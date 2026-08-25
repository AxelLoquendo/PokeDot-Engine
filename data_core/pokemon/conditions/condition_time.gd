@tool
extends EvolutionCondition

class_name EvolutionConditionTime

enum RequiredTime { DAY, NIGHT }

@export var required_time: RequiredTime = RequiredTime.DAY

func is_met(context: EvolutionContext) -> bool:
	if context == null:
		return false
	return context.is_day if required_time == RequiredTime.DAY else not context.is_day

func get_description() -> String:
	return "Durante el día" if required_time == RequiredTime.DAY else "Durante la noche"
