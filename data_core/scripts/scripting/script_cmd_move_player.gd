@tool
extends ScriptCommand
class_name ScriptCmdMovePlayer

## Mueve al jugador forzosamente
## Útil para cutscenes o eventos scripted

enum MoveType {
	INSTANT,
	ANIMATED,
	WALK_TO_TILE
}

@export var move_type: MoveType = MoveType.ANIMATED
@export var direction: Vector2i = Vector2i(0, -1)
@export var steps: int = 1
@export var target_tile: Vector2i = Vector2i.ZERO
@export_range(0.1, 2.0, 0.1) var speed: float = 0.5

func execute(context: ScriptExecutionContext) -> bool:
	if not context.player:
		return true
	
	var player_controller = context.get_player_controller()
	if not player_controller:
		return true
	
	match move_type:
		MoveType.INSTANT:
			var new_pos = player_controller.position + (direction * 16 * steps)
			player_controller.position = new_pos
			return true
			
		MoveType.ANIMATED:
			for i in range(steps):
				if player_controller.has_method("mover_un_paso"):
					player_controller.mover_un_paso(direction)
				await player_controller.get_tree().create_timer(speed).timeout
			return true
			
		MoveType.WALK_TO_TILE:
			if player_controller.has_method("mover_a_casilla"):
				player_controller.mover_a_casilla(target_tile)
				context.is_waiting = true
				return false
			return true
	
	return true

func get_display_text() -> String:
	return "🎮 Mover Jugador: %d pasos" % steps
