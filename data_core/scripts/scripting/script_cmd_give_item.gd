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
	
	# NO IMPLEMENTADO AUN - requiere sistema de items/mochila
	push_warning("ScriptCmdGiveItem: sistema de items aun no implementado")
	
	if show_notification:
		_show_message("¡Has recibido %dx %s!" % [amount, item_id])
	
	return true

func _show_message(text: String) -> void:
	# Usar el sistema de notificaciones o diálogo si existe
	if DialogueManager and DialogueManager.has_method("show_brief_message"):
		DialogueManager.show_brief_message(text)
	else:
		push_warning(text)

func get_display_text() -> String:
	return "🎁 Dar Item: %s x%d" % [item_id, amount]
