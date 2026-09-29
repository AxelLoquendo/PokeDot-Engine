extends RefCounted
class_name BattleMoveEffects
## Puente tipado hacia MoveSystem / fallbacks de efectos de estado.
## MoveSystem tipa `battle` como BattleManager; aquí aceptamos Object
## y solo invocamos si el duck-typing es compatible.


static func try_status_on_use(
	battle: Object,
	actor: BattleBattler,
	target: BattleBattler,
	move: MoveData
) -> bool:
	if move == null or actor == null:
		return false
	if MoveSystem.has_script(int(move.effect)):
		# MoveSystem.run_on_use espera BattleManager; BattleMain expone la misma API.
		var handled: bool = await MoveSystem.run_on_use(actor, target, move, battle)
		return handled
	return false


static func try_on_hit(
	battle: Object,
	actor: BattleBattler,
	target: BattleBattler,
	move: MoveData,
	damage_dealt: int
) -> bool:
	if move == null or actor == null:
		return false
	if MoveSystem.has_script(int(move.effect)):
		var handled: bool = await MoveSystem.run_on_hit(actor, target, move, battle, damage_dealt)
		return handled
	return false


static func try_on_secondary(
	battle: Object,
	actor: BattleBattler,
	target: BattleBattler,
	move: MoveData
) -> bool:
	if move == null or actor == null:
		return false
	if MoveSystem.has_script(int(move.effect)):
		var handled: bool = await MoveSystem.run_on_secondary(actor, target, move, battle)
		return handled
	return false
