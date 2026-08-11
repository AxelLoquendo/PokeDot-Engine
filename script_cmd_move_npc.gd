@tool
extends ScriptCommand
class_name ScriptCmdMoveNpc

## Mueve al NPC en una dirección específica
## Puede ser síncrono (movimiento instantáneo) o asíncrono (animado)

enum MoveType {
	INSTANT,      ## Movimiento instantáneo
	ANIMATED,     ## Movimiento animado paso a paso
	WALK_TO_TILE  ## Caminar hasta una casilla específica
}

@export var move_type: MoveType = MoveType.ANIMATED
@export var direction: Vector2i = Vector2i(0, -1)  ## Arriba por defecto
@export var steps: int = 1
@export var target_tile: Vector2i = Vector2i.ZERO  ## Solo para WALK_TO_TILE
@export_range(0.1, 2.0, 0.1) var speed: float = 0.5

func execute(context: ScriptExecutionContext) -> bool:
	if not context.npc:
		return true
	
	var controller = context.get_npc_controller()
	if not controller:
		return true
	
	match move_type:
		MoveType.INSTANT:
			var new_pos = controller.position + (direction * 16 * steps)  ## Asumiendo tiles de 16px
			controller.position = new_pos
			return true
			
		MoveType.ANIMATED:
			controller.mirar_hacia_direccion(direction)
			for i in range(steps):
				controller.mover_un_paso(direction)
				await controller.get_tree().create_timer(speed).timeout
			return true
			
		MoveType.WALK_TO_TILE:
			if controller.has_method("mover_a_casilla"):
				controller.mover_a_casilla(target_tile)
				context.is_waiting = true
				return false
			return true
	
	return true

func get_display_text() -> String:
	var dir_names = {
		Vector2i(0, -1): "Arriba",
		Vector2i(0, 1): "Abajo",
		Vector2i(-1, 0): "Izquierda",
		Vector2i(1, 0): "Derecha"
	}
	var dir_name = dir_names.get(direction, "Desconocida")
	return "🚶 Mover NPC: %s (%d pasos)" % [dir_name, steps]
