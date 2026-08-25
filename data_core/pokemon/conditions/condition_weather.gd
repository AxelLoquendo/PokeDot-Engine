@tool
extends EvolutionCondition

class_name EvolutionConditionWeather

@export var required_weather_id: int = 0
@export var invert: bool = false

func is_met(context: EvolutionContext) -> bool:
	if context == null:
		return false
	var result: bool = context.current_weather_id == required_weather_id
	return not result if invert else result

func get_description() -> String:
	return ("No tener clima [%d]" if invert else "Tener clima [%d]") % required_weather_id
