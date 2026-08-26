@tool
extends EvolutionCondition

class_name EvolutionConditionItem

@export var required_item_id: Items.ItemId = Items.ItemId.ITEM_NONE
@export var check_held_item: bool = false

func is_met(context: EvolutionContext) -> bool:
	if context == null or context.pokemon == null:
		return false
	if check_held_item:
		return int(context.pokemon.held_item) == required_item_id
	return context.used_item_id == required_item_id

func get_description() -> String:
	return ("Llevar objeto [%d]" if check_held_item else "Usar objeto [%d]") % required_item_id
