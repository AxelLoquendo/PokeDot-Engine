extends RefCounted
class_name BattleAction

enum Kind { MOVE, RUN }

var kind: Kind = Kind.MOVE
var actor: BattleBattler
var target: BattleBattler
var move: MoveData
var move_slot_index: int = -1
var priority: int = 0


static func make_move(p_actor: BattleBattler, p_target: BattleBattler, p_move: MoveData, slot_index: int) -> BattleAction:
	var action: BattleAction = BattleAction.new()
	action.kind = Kind.MOVE
	action.actor = p_actor
	action.target = p_target
	action.move = p_move
	action.move_slot_index = slot_index
	action.priority = p_move.priority if p_move else 0
	return action


static func make_run(p_actor: BattleBattler) -> BattleAction:
	var action: BattleAction = BattleAction.new()
	action.kind = Kind.RUN
	action.actor = p_actor
	action.priority = 0
	return action
