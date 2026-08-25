@tool
extends Resource

class_name EvolutionCondition

## Las subclases implementan una condición concreta.
func is_met(_context: EvolutionContext) -> bool:
	return false

func get_description() -> String:
	return "Condición desconocida"
