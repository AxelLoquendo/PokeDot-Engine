@tool
extends ScriptCommand
class_name ScriptCmdMovePlayer

## Mueve al jugador forzosamente
## Útil para cutscenes o eventos scripted

enum MoveType {
	INSTANT,
	ANIMATED,
	WALK_TO_TILE  ## NO IMPLEMENTADO AUN
}

@export var move_type: MoveType = MoveType.ANIMATED
@export var direction: Vector2i = Vector2i(0, -1)
@export var steps: int = 1
@export var target_tile: Vector2i = Vector2i.ZERO
@export_range(0.1, 2.0, 0.1) var speed: float = 0.5


func execute(context: ScriptExecutionContext) -> bool:
	if not context.player:
		return true
	
	var player_controller: Node2D = context.get_player_controller()
	if not player_controller:
		return true
	
	match move_type:
		MoveType.INSTANT:
			var new_pos: Vector2 = player_controller.position + (Vector2(direction) * 16.0 * float(steps))
			player_controller.position = new_pos
			return true
			
		MoveType.ANIMATED:
			# Usar intentar_mover() del controller del jugador
			var dir_vector: Vector2 = Vector2(direction)
			for i: int in range(steps):
				if player_controller.has_method("intentar_mover"):
					player_controller.call("intentar_mover", dir_vector)
			context.is_waiting = true
			player_controller.get_tree().create_timer(speed * float(steps)).timeout.connect(context.complete_async)
			return false
			
		MoveType.WALK_TO_TILE:
			# NO IMPLEMENTADO AUN
			push_warning("ScriptCmdMovePlayer: WALK_TO_TILE aun no implementado")
			return true
	
	return true


func get_display_text() -> String:
	return "🎮 Mover Jugador: %d pasos" % steps
