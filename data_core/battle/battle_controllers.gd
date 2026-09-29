extends RefCounted
class_name BattleControllers
## Factory de controladores de elección de acción.
## Player UI y AI/opponent implementan la misma interfaz mínima.


enum ControllerKind {
	PLAYER,
	OPPONENT,
	PLAYER_PARTNER,
	RECORDED,
	SAFARI,
}


## Interfaz conceptual (documental):
##   choose_actions(battle, side_actives) -> Array[BattleAction]
## Los controllers no resuelven efectos; solo eligen.


static func make(kind: ControllerKind) -> RefCounted:
	match kind:
		ControllerKind.PLAYER:
			return BattleControllerPlayer.new()
		ControllerKind.OPPONENT:
			return BattleControllerOpponent.new()
		_:
			return BattleControllerOpponent.new()
