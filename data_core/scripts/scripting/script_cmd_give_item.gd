@tool
extends ScriptCommand
class_name ScriptCmdGiveItem

## Añade un ítem a la mochila del jugador. Acepta POTION o ITEM_POTION.
@export var item_id: String = "ITEM_POTION"
@export var amount: int = 1
@export var show_notification: bool = true


func execute(context: ScriptExecutionContext) -> bool:
	var player: CharacterController = context.player as CharacterController
	var player_data: CharacterPlayer = player.character_data as CharacterPlayer if player else null
	if player_data == null:
		push_warning("ScriptCmdGiveItem: no se encontró CharacterPlayer")
		return true
	var resolved_id: int = _resolve_item_id(item_id)
	if resolved_id < 0:
		push_warning("ScriptCmdGiveItem: item desconocido '%s'" % item_id)
		return true
	if player_data.bag == null:
		player_data.bag = Bag.new()
	if not player_data.bag.add_item(resolved_id, amount):
		return true
	if show_notification:
		_show_message("Has recibido %dx %s." % [amount, _display_name(resolved_id)])
	return true


func _resolve_item_id(value: String) -> int:
	var key: String = value.to_upper()
	if not key.begins_with("ITEM_"):
		key = "ITEM_" + key
	return int(Items.ItemId.get(key, -1))


func _display_name(resolved_id: int) -> String:
	var key: String = str(Items.ItemId.find_key(resolved_id))
	return key.trim_prefix("ITEM_").replace("_", " ").capitalize()


func _show_message(text: String) -> void:
	if DialogueManager and DialogueManager.has_method("show_brief_message"):
		DialogueManager.show_brief_message(text)
	else:
		print(text)


func get_display_text() -> String:
	return "Dar Item: %s x%d" % [item_id, amount]
