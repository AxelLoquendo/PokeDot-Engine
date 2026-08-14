extends Resource
class_name PokemonMoveSlot

## Estado de un movimiento en un Pokémon concreto. MoveData es estático;
## los PP pertenecen a cada criatura.
@export var move_id: Moves.MoveId = Moves.MoveId.MOVE_NONE
@export var current_pp: int = 0
@export var pp_ups: int = 0


func setup(id: Moves.MoveId) -> void:
	move_id = id
	var data: MoveData = MoveDatabase.get_move(id)
	current_pp = data.pp if data else 0


func is_empty() -> bool:
	return move_id == Moves.MoveId.MOVE_NONE
