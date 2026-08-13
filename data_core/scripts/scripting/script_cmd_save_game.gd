@tool
extends ScriptCommand
class_name ScriptCmdSaveGame

## Abre la confirmación de guardado y espera a que el jugador responda.
func execute(context: ScriptExecutionContext) -> bool:
	var tree: SceneTree = context.npc.get_tree() if context.npc else context.player.get_tree() if context.player else null
	if not tree:
		return true
	context.is_waiting = true
	SaveManager.save_finished.connect(func(_success: bool) -> void: context.complete_async(), CONNECT_ONE_SHOT)
	SaveManager.request_save(tree)
	return false
