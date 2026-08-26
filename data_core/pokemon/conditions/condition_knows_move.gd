@tool
extends EvolutionCondition

class_name EvolutionConditionKnowsMove

@export var required_move_id: Moves.MoveId = Moves.MoveId.MOVE_NONE

func is_met(context: EvolutionContext) -> bool:
	if context == null or context.pokemon == null:
		return false
	for slot: PokemonMoveSlot in context.pokemon.moves:
		if slot != null and int(slot.move_id) == required_move_id:
			return true
	return false

func get_description() -> String:
	return "Conocer movimiento [%d]" % required_move_id
