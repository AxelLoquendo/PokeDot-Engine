@tool
extends ScriptCommand
class_name ScriptCmdLock

## Bloquea o libera el control del jugador durante una secuencia.
@export var lock_player: bool = true

func execute(context: ScriptExecutionContext) -> bool:
	if context.player == null:
		return true

	var player: Node = context.player
	# Solo marca el flag. CharacterController._physics_process deja terminar el
	# paso actual (si lo hay) y luego no acepta más entrada.
	# NUNCA uses cancelar_movimiento aquí: empuja al jugador una casilla atrás.
	player.set("ejecutando_evento", lock_player)

	# Siempre idle al bloquear: el último frame del paso suele ser de caminar,
	# y además try_step puede ejecutarse antes de que is_moving pase a false.
	if lock_player and player.has_method("reproducir_idle"):
		player.reproducir_idle()
	return true
