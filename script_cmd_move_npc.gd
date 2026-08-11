@tool
extends ScriptCommand
class_name ScriptCmdMoveNpc

## Mueve al NPC en una dirección específica
## Puede ser síncrono (movimiento instantáneo) o asíncrono (animado)

enum MoveType {
	INSTANT,      ## Movimiento instantáneo
	ANIMATED,     ## Movimiento animado paso a paso
	WALK_TO_TILE  ## Caminar hasta una casilla específica (NO IMPLEMENTADO AUN)
}

@export var move_type: MoveType = MoveType.ANIMATED
@export var direction: Vector2i = Vector2i(0, -1)  ## Arriba por defecto
@export var steps: int = 1
@export var target_tile: Vector2i = Vector2i.ZERO  ## Solo para WALK_TO_TILE
@export_range(0.1, 2.0, 0.1) var speed: float = 0.5


func execute(context: ScriptExecutionContext) -> bool:
	if not context.npc:
		return true
	
	var controller: CharacterController = context.get_npc_controller()
	if not controller:
		return true
	
	match move_type:
		MoveType.INSTANT:
			# Movimiento instantáneo sin animación
			var new_pos: Vector2 = controller.position + (Vector2(direction) * controller.TILE_SIZE * float(steps))
			controller.position = new_pos
			controller.casilla_actual = controller.posicion_a_casilla(controller.global_position)
			return true
			
		MoveType.ANIMATED:
			# Movimiento animado usando intentar_mover()
			var dir_vector: Vector2 = Vector2(direction)
			# Mirar hacia la dirección
			controller.mirar_hacia_posicion(controller.global_position + dir_vector * controller.TILE_SIZE)
			
			for i: int in range(steps):
				if controller.intentar_mover(dir_vector):
					# Esperar a que complete el movimiento
					await controller.get_tree().create_timer(speed).timeout
			return true
			
		MoveType.WALK_TO_TILE:
			# NO IMPLEMENTADO AUN - requiere pathfinding
			push_warning("ScriptCmdMoveNpc: WALK_TO_TILE aun no implementado")
			return true
	
	return true


func get_display_text() -> String:
	var dir_names: Dictionary = {
		Vector2i(0, -1): "Arriba",
		Vector2i(0, 1): "Abajo",
		Vector2i(-1, 0): "Izquierda",
		Vector2i(1, 0): "Derecha"
	}
	var dir_name: String = dir_names.get(direction, "Desconocida") as String
	return "🚶 Mover NPC: %s (%d pasos)" % [dir_name, steps]
