@tool
extends EvolutionCondition

class_name EvolutionConditionFriendship

enum TimeRequirement { ANY, DAY, NIGHT }

@export_range(0, 255) var minimum_friendship: int = 160
@export var time_requirement: TimeRequirement = TimeRequirement.ANY

func is_met(context: EvolutionContext) -> bool:
	if context == null or context.pokemon == null:
		return false
	if context.pokemon.friendship < minimum_friendship:
		return false
	if time_requirement == TimeRequirement.DAY and not context.is_day:
		return false
	if time_requirement == TimeRequirement.NIGHT and context.is_day:
		return false
	return true

func get_description() -> String:
	var result: String = "Amistad %d+" % minimum_friendship
	if time_requirement == TimeRequirement.DAY:
		result += " durante el día"
	elif time_requirement == TimeRequirement.NIGHT:
		result += " durante la noche"
	return result
