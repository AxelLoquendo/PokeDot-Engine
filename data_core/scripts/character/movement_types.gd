@tool
extends RefCounted
class_name MovementTypes

## Pokeemerald-style movement vocabulary.
## MovementType is the one autonomous selector on CharacterNpc. MovementAction
## contains only atomic operations; ApplyMovement and autonomous loops both use it.
enum Direction { NORTH, SOUTH, EAST, WEST }

enum AutonomousBehavior {
	QUIETO, PATRULLA_HORIZONTAL, PATRULLA_VERTICAL, RANDOM_WALK, LOOK_AROUND, FOLLOW_PLAYER,
	WANDER_AROUND, WANDER_SLOWER, WANDER_UP_DOWN, WANDER_DOWN_UP, WANDER_LEFT_RIGHT, WANDER_RIGHT_LEFT,
	FACE_NORTH, FACE_SOUTH, FACE_EAST, FACE_WEST, FACE_HORIZONTAL, FACE_VERTICAL,
	ROTATE_CLOCKWISE, ROTATE_COUNTERCLOCKWISE, WALK_BACK_FORTH, WALK_BACK_FORTH_SLOWER,
	WALK_BACK_FORTH_UP_DOWN, WALK_BACK_FORTH_DOWN_UP, WALK_BACK_FORTH_LEFT_RIGHT, WALK_BACK_FORTH_RIGHT_LEFT,
	COPY_PLAYER, COPY_PLAYER_IN_GRASS, TREE_DISGUISE, MOUNTAIN_DISGUISE, BURIED, WALK_IN_PLACE,
	JOG_IN_PLACE, RUN_IN_PLACE, SLOWLY_IN_PLACE, INVISIBLE, BERRY_TREE_GROWTH
}

enum MovementAction {
	WAIT, FACE, TURN_CLOCKWISE, TURN_COUNTERCLOCKWISE, WALK, JOG, RUN, WALK_IN_PLACE,
	COPY_PLAYER, FOLLOW_PLAYER, HIDE, SHOW, TREE_DISGUISE, MOUNTAIN_DISGUISE, BURIED,
	BERRY_TREE_GROWTH
}

static func direction_from_text(value: String) -> Vector2:
	match value.to_lower():
		"up", "north", "arriba", "n": return Vector2.UP
		"down", "south", "abajo", "s": return Vector2.DOWN
		"left", "west", "izquierda", "o": return Vector2.LEFT
		"right", "east", "derecha", "e": return Vector2.RIGHT
	return Vector2.ZERO

static func direction_name(value: Vector2) -> String:
	if value == Vector2.UP: return "north"
	if value == Vector2.DOWN: return "south"
	if value == Vector2.LEFT: return "west"
	if value == Vector2.RIGHT: return "east"
	return "south"

## Kept for callers from previous overlays; this is metadata, not another behavior.
static func command_metadata(action: MovementAction) -> Dictionary[String, Variant]:
	return {"action": action, "atomic": true}
