extends RefCounted
class_name BattleControllerOpponent
## IA del oponente: delega en BattleAIMain.


func choose_actions(battle: Object, side_actives: Array) -> Array[BattleAction]:
	var typed: Array[BattleBattler] = []
	if side_actives is Array:
		for item: Variant in side_actives:
			if item is BattleBattler:
				typed.append(item as BattleBattler)
	return BattleAIMain.choose_actions(battle, typed)
