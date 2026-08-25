@tool
extends EvolutionCondition

class_name EvolutionConditionFlag

@export var required_flag: StringName = &""
@export var expected_value: bool = true

func is_met(context: EvolutionContext) -> bool:
	if context == null or required_flag.is_empty():
		return false
	return context.has_event_flag(required_flag) == expected_value

func get_description() -> String:
	return "Evento: %s = %s" % [required_flag, expected_value]
