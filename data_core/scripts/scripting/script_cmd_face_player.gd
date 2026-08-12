@tool
extends ScriptCommand
class_name ScriptCmdFacePlayer

## Hace que el NPC que ejecuta el script mire al jugador.
func execute(context: ScriptExecutionContext) -> bool:
	if context.npc and context.player and context.npc.has_method("mirar_hacia_posicion"):
		context.npc.mirar_hacia_posicion(context.player.global_position)
		if context.npc.has_method("reproducir_idle"):
			context.npc.reproducir_idle()
	return true
