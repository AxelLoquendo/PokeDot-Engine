@tool
extends ScriptCommand
class_name ScriptCmdGiveItem

## Da un item al jugador

@export var item_id: String = "potion"
@export var amount: int = 1
@export var show_notification: bool = true
@export var check_bag_space: bool = true

func execute(context: ScriptExecutionContext) -> bool:
	if not context.player:
		return true
	
	#var success: bool = false
	
	#if check_bag_space:
	#	if BagManager.has_method("has_space"):
	#		if not BagManager.has_space(item_id, amount):
	#			if show_notification:
	#				_show_message("¡No hay espacio en la mochila!")
	#			return true
	
	#if BagManager.has_method("add_item"):
	#	success = BagManager.add_item(item_id, amount)
	
	#if success and show_notification:
	#	_show_message("¡Has recibido %dx %s!" % [amount, _get_item_name(item_id)])
	
	return true

#func _get_item_name(item_id: String) -> String:
#	if ItemDatabase.has_method("get_item_name"):
#		return ItemDatabase.get_item_name(item_id)
#	return item_id.capitalize()


func _show_message(text: String) -> void:
	# Usar el sistema de notificaciones o diálogo
	if DialogueManager.has_method("show_brief_message"):
		DialogueManager.show_brief_message(text)

func get_display_text() -> String:
	return "🎁 Dar Item: %s x%d" % [item_id, amount]
