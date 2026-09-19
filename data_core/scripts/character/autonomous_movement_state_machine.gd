@tool
extends RefCounted
class_name AutonomousMovementStateMachine

## One autonomous loop per NPC. Each loop is a list of atomic actions; after the
## list finishes, the type builds its next list. It never parses ApplyMovement.
## Delays are intentional: pokeemerald-style behaviours choose an action, finish
## it at controller speed, then spend time in an observable idle state.
const MIN_IDLE_SECONDS: float = 0.22
const MAX_IDLE_SECONDS: float = 0.72
const LOOK_MIN_SECONDS: float = 0.55
const LOOK_MAX_SECONDS: float = 1.25
const BOUNDARY_MIN_SECONDS: float = 0.45
const BOUNDARY_MAX_SECONDS: float = 0.95

var _type: MovementTypes.AutonomousBehavior
var _origin: Vector2i
var _horizontal_forward: bool = true
var _vertical_forward: bool = true

func _init(movement_type: MovementTypes.AutonomousBehavior, origin: Vector2i) -> void:
	_type = movement_type
	_origin = origin

func matches(movement_type: MovementTypes.AutonomousBehavior) -> bool:
	return _type == movement_type

func run_cycle(target: CharacterController) -> void:
	var actions: Array[Dictionary] = _next_actions(target)
	for action: Dictionary in actions:
		await MovementExecutor.execute_action(target, action)

func _wait(seconds: float) -> Dictionary:
	return {"kind": MovementTypes.MovementAction.WAIT, "seconds": seconds}

func _idle_wait() -> Dictionary:
	return _wait(randf_range(MIN_IDLE_SECONDS, MAX_IDLE_SECONDS))

func _boundary_wait() -> Dictionary:
	return _wait(randf_range(BOUNDARY_MIN_SECONDS, BOUNDARY_MAX_SECONDS))

func _npc_data(target: CharacterController) -> CharacterNpc:
	return target.character_data as CharacterNpc

func _next_actions(target: CharacterController) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	match _type:
		MovementTypes.AutonomousBehavior.QUIETO:
			result.append(_wait(randf_range(0.8, 1.6)))
		MovementTypes.AutonomousBehavior.PATRULLA_HORIZONTAL, MovementTypes.AutonomousBehavior.WALK_BACK_FORTH, MovementTypes.AutonomousBehavior.WALK_BACK_FORTH_SLOWER, MovementTypes.AutonomousBehavior.WALK_BACK_FORTH_LEFT_RIGHT, MovementTypes.AutonomousBehavior.WALK_BACK_FORTH_RIGHT_LEFT:
			var data_h: CharacterNpc = _npc_data(target)
			var span_h: int = maxi(1, data_h.distancia_patrulla if data_h else 1)
			var at_edge_h: bool = abs(target.casilla_actual.x - _origin.x) >= span_h
			if at_edge_h:
				_horizontal_forward = not _horizontal_forward
				result.append(_boundary_wait())
			var horizontal_direction: Vector2 = Vector2.RIGHT if _horizontal_forward else Vector2.LEFT
			result.append({"kind": MovementTypes.MovementAction.WALK, "direction": horizontal_direction, "mode": "walk"})
			result.append(_wait(0.3 if _type == MovementTypes.AutonomousBehavior.WALK_BACK_FORTH_SLOWER else 0.16))
		MovementTypes.AutonomousBehavior.PATRULLA_VERTICAL, MovementTypes.AutonomousBehavior.WALK_BACK_FORTH_UP_DOWN, MovementTypes.AutonomousBehavior.WALK_BACK_FORTH_DOWN_UP:
			var data_v: CharacterNpc = _npc_data(target)
			var span_v: int = maxi(1, data_v.distancia_patrulla if data_v else 1)
			var at_edge_v: bool = abs(target.casilla_actual.y - _origin.y) >= span_v
			if at_edge_v:
				_vertical_forward = not _vertical_forward
				result.append(_boundary_wait())
			var vertical_direction: Vector2 = Vector2.DOWN if _vertical_forward else Vector2.UP
			result.append({"kind": MovementTypes.MovementAction.WALK, "direction": vertical_direction, "mode": "walk"})
			result.append(_wait(0.16))
		MovementTypes.AutonomousBehavior.RANDOM_WALK, MovementTypes.AutonomousBehavior.WANDER_AROUND, MovementTypes.AutonomousBehavior.WANDER_SLOWER:
			result.append(_idle_wait())
			result.append({"kind": MovementTypes.MovementAction.WALK, "direction": [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT].pick_random(), "mode": "walk"})
			result.append(_wait(0.65 if _type == MovementTypes.AutonomousBehavior.WANDER_SLOWER else 0.3))
		MovementTypes.AutonomousBehavior.WANDER_UP_DOWN, MovementTypes.AutonomousBehavior.WANDER_DOWN_UP:
			result.append(_idle_wait())
			result.append({"kind": MovementTypes.MovementAction.WALK, "direction": [Vector2.UP, Vector2.DOWN].pick_random(), "mode": "walk"})
			result.append(_wait(0.35))
		MovementTypes.AutonomousBehavior.WANDER_LEFT_RIGHT, MovementTypes.AutonomousBehavior.WANDER_RIGHT_LEFT:
			result.append(_idle_wait())
			result.append({"kind": MovementTypes.MovementAction.WALK, "direction": [Vector2.LEFT, Vector2.RIGHT].pick_random(), "mode": "walk"})
			result.append(_wait(0.35))
		MovementTypes.AutonomousBehavior.LOOK_AROUND:
			result.append(_wait(randf_range(0.35, 0.8)))
			result.append({"kind": MovementTypes.MovementAction.FACE, "direction": [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT].pick_random()})
			result.append(_wait(randf_range(LOOK_MIN_SECONDS, LOOK_MAX_SECONDS)))
		MovementTypes.AutonomousBehavior.FACE_NORTH: result.append({"kind": MovementTypes.MovementAction.FACE, "direction": Vector2.UP})
		MovementTypes.AutonomousBehavior.FACE_SOUTH: result.append({"kind": MovementTypes.MovementAction.FACE, "direction": Vector2.DOWN})
		MovementTypes.AutonomousBehavior.FACE_EAST: result.append({"kind": MovementTypes.MovementAction.FACE, "direction": Vector2.RIGHT})
		MovementTypes.AutonomousBehavior.FACE_WEST: result.append({"kind": MovementTypes.MovementAction.FACE, "direction": Vector2.LEFT})
		MovementTypes.AutonomousBehavior.FACE_HORIZONTAL:
			result.append({"kind": MovementTypes.MovementAction.FACE, "direction": Vector2.RIGHT if target.current_direction == CharacterController.Direction.WEST else Vector2.LEFT})
		MovementTypes.AutonomousBehavior.FACE_VERTICAL:
			result.append({"kind": MovementTypes.MovementAction.FACE, "direction": Vector2.DOWN if target.current_direction == CharacterController.Direction.NORTH else Vector2.UP})
		MovementTypes.AutonomousBehavior.ROTATE_CLOCKWISE:
			result.append({"kind": MovementTypes.MovementAction.TURN_CLOCKWISE})
			result.append(_wait(0.45))
		MovementTypes.AutonomousBehavior.ROTATE_COUNTERCLOCKWISE:
			result.append({"kind": MovementTypes.MovementAction.TURN_COUNTERCLOCKWISE})
			result.append(_wait(0.45))
		MovementTypes.AutonomousBehavior.FOLLOW_PLAYER: result.append({"kind": MovementTypes.MovementAction.FOLLOW_PLAYER})
		MovementTypes.AutonomousBehavior.COPY_PLAYER, MovementTypes.AutonomousBehavior.COPY_PLAYER_IN_GRASS: result.append({"kind": MovementTypes.MovementAction.COPY_PLAYER})
		MovementTypes.AutonomousBehavior.WALK_IN_PLACE: result.append({"kind": MovementTypes.MovementAction.WALK_IN_PLACE, "mode": "walk"})
		MovementTypes.AutonomousBehavior.JOG_IN_PLACE: result.append({"kind": MovementTypes.MovementAction.WALK_IN_PLACE, "mode": "jog"})
		MovementTypes.AutonomousBehavior.RUN_IN_PLACE: result.append({"kind": MovementTypes.MovementAction.WALK_IN_PLACE, "mode": "run"})
		MovementTypes.AutonomousBehavior.SLOWLY_IN_PLACE: result.append({"kind": MovementTypes.MovementAction.WALK_IN_PLACE, "mode": "slowly"})
		MovementTypes.AutonomousBehavior.TREE_DISGUISE: result.append({"kind": MovementTypes.MovementAction.TREE_DISGUISE})
		MovementTypes.AutonomousBehavior.MOUNTAIN_DISGUISE: result.append({"kind": MovementTypes.MovementAction.MOUNTAIN_DISGUISE})
		MovementTypes.AutonomousBehavior.BURIED: result.append({"kind": MovementTypes.MovementAction.BURIED})
		MovementTypes.AutonomousBehavior.INVISIBLE: result.append({"kind": MovementTypes.MovementAction.HIDE})
		MovementTypes.AutonomousBehavior.BERRY_TREE_GROWTH: result.append({"kind": MovementTypes.MovementAction.BERRY_TREE_GROWTH})
		_: result.append(_wait(0.5))
	return result
