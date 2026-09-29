extends RefCounted
class_name BattleAction

enum Kind { MOVE, RUN, SWITCH }

var kind: Kind = Kind.MOVE
var actor: BattleBattler
## Snapshot del mon al elegir la acción (anti: reemplazo ejecuta el move del KO).
var actor_pokemon: PokemonInstance = null
var target: BattleBattler
var move: MoveData
var move_slot_index: int = -1
var priority: int = 0
var switch_to: PokemonInstance = null
## Slot del objetivo cuando hay varios rivales (0 o 1). -1 = auto.
var target_slot: int = -1


static func make_move(
	p_actor: BattleBattler,
	p_target: BattleBattler,
	p_move: MoveData,
	slot_index: int
) -> BattleAction:
	var action: BattleAction = BattleAction.new()
	action.kind = Kind.MOVE
	action.actor = p_actor
	action.actor_pokemon = p_actor.pokemon if p_actor != null else null
	action.target = p_target
	action.move = p_move
	action.move_slot_index = slot_index
	action.priority = p_move.priority if p_move else 0
	return action


static func make_run(p_actor: BattleBattler) -> BattleAction:
	var action: BattleAction = BattleAction.new()
	action.kind = Kind.RUN
	action.actor = p_actor
	action.actor_pokemon = p_actor.pokemon if p_actor != null else null
	action.priority = 0
	return action


static func make_switch(p_actor: BattleBattler, nuevo: PokemonInstance) -> BattleAction:
	var action: BattleAction = BattleAction.new()
	action.kind = Kind.SWITCH
	action.actor = p_actor
	action.actor_pokemon = p_actor.pokemon if p_actor != null else null
	action.switch_to = nuevo
	action.priority = 6  # prioritario al cambiar
	return action
