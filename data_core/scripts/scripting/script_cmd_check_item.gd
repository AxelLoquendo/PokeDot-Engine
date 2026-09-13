@tool
extends ScriptCommand
class_name ScriptCmdCheckItem

## checkitem POTION 2
## Guarda true/false en last_result y la cantidad en last_item_count.
@export var item_id: String = "ITEM_POTION"
@export_range(1, 999) var amount: int = 1

func execute(context: ScriptExecutionContext) -> bool:
	var player: CharacterController = context.player as CharacterController
	var data: CharacterPlayer = player.character_data as CharacterPlayer if player else null
	var resolved: int = _resolve_item_id(item_id)
	var count: int = data.bag.get_quantity(resolved as Items.ItemId) if data != null and data.bag != null and resolved >= 0 else 0
	context.set_variable("last_item_count", count)
	context.set_variable("last_result", count >= amount)
	return true

func _resolve_item_id(value: String) -> int:
	var key: String = value.to_upper()
	if not key.begins_with("ITEM_"):
		key = "ITEM_" + key
	return int(Items.ItemId.get(key, -1))

func get_display_text() -> String:
	return "Comprobar ítem: %s x%d" % [item_id, amount]
