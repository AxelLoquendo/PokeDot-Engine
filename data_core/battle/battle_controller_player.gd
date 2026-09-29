extends RefCounted
class_name BattleControllerPlayer
## El jugador no elige aquí: la UI llama a BattleManager.player_choose_*.
## Este controller existe para simetría con opponent y para tests headless
## (inyectar acciones pre-hechas).


var queued: Array[BattleAction] = []


func queue_action(action: BattleAction) -> void:
	queued.append(action)


func choose_actions(_battle: Object, side_actives: Array) -> Array[BattleAction]:
	var needed: int = 0
	for b: BattleBattler in side_actives:
		if b != null and b.pokemon != null and not b.is_fainted():
			needed += 1
	var result: Array[BattleAction] = []
	while result.size() < needed and not queued.is_empty():
		result.append(queued.pop_front())
	return result


func clear() -> void:
	queued.clear()
