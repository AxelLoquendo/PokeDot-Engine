@tool
extends ScriptCommand
class_name ScriptCmdLock

## Bloquea o libera el control del jugador durante una secuencia.
@export var lock_player: bool = true

func execute(context: ScriptExecutionContext) -> bool:
	if context.player:
		context.player.ejecutando_evento = lock_player
	return true
