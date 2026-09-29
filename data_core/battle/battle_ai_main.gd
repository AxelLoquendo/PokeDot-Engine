extends RefCounted
class_name BattleAIMain
## AI de oponente: elige movimiento (daño estimado simple) o switch.


static func choose_move_for(battle: Object, battler: BattleBattler) -> BattleAction:
	if battler == null or battler.pokemon == null or battler.is_fainted():
		return null

	# Recharge / charge
	if battler.must_recharge:
		battler.must_recharge = false
		return null
	if battler.charging_move != null:
		var release: BattleAction = BattleAction.make_move(
			battler, _best_target(battle, battler), battler.charging_move, -1
		)
		return release

	var moves: Array[Dictionary] = _scored_moves(battle, battler)
	if moves.is_empty():
		# Struggle
		return null

	moves.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a["score"]) > float(b["score"])
	)
	var best: Dictionary = moves[0]
	var move: MoveData = best["move"] as MoveData
	var slot: int = int(best["slot"])
	var target: BattleBattler = best["target"] as BattleBattler
	var action: BattleAction = BattleAction.make_move(battler, target, move, slot)
	return action


static func choose_actions(battle: Object, actives: Array[BattleBattler]) -> Array[BattleAction]:
	var result: Array[BattleAction] = []
	for b: BattleBattler in actives:
		if b == null or b.pokemon == null or b.is_fainted():
			continue
		var action: BattleAction = choose_move_for(battle, b)
		if action != null:
			result.append(action)
	return result


static func _scored_moves(battle: Object, battler: BattleBattler) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if battler.pokemon.moves == null:
		return out
	for i: int in range(battler.pokemon.moves.size()):
		var ms: PokemonMoveSlot = battler.pokemon.moves[i] as PokemonMoveSlot
		if ms == null:
			continue
		var pp: int = 0
		if "current_pp" in ms:
			pp = int(ms.current_pp)
		elif "pp" in ms:
			pp = int(ms.pp)
		if pp <= 0:
			continue
		var move_id: Moves.MoveId = ms.move_id if "move_id" in ms else Moves.MoveId.MOVE_NONE
		var move: MoveData = MoveDatabase.get_move(move_id)
		if move == null:
			continue
		var target: BattleBattler = _best_target(battle, battler)
		var score: float = _estimate_score(battle, battler, target, move)
		out.append({"move": move, "slot": i, "target": target, "score": score})
	return out


static func _estimate_score(
	battle: Object,
	actor: BattleBattler,
	target: BattleBattler,
	move: MoveData
) -> float:
	if move == null:
		return 0.0
	var score: float = float(move.priority) * 10.0
	if move.category == MoveStruct.DamageCategory.STATUS or move.power <= 0:
		score += 15.0
		return score
	var power: float = float(maxi(1, move.power))
	score += power
	if target != null and not target.is_fainted():
		# Preferir KO potencial
		var weather: int = 0
		if battle.has_method("get_effective_weather"):
			weather = int(battle.get_effective_weather())
		# Estimación simple (DamageCalculator no expone estimate_damage estático)
		score += power * 1.5
		if power >= 100:
			score += 40.0
	score += randf() * 5.0
	return score


static func _best_target(battle: Object, actor: BattleBattler) -> BattleBattler:
	var opps: Array[BattleBattler] = BattleUtil.get_opponents(battle, actor)
	for o: BattleBattler in opps:
		if o != null and not o.is_fainted():
			return o
	return null
