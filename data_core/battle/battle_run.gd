extends RefCounted
class_name BattleRun
## Intento de huida en combates salvajes.


static func attempt(battle: Object) -> bool:
	if battle.get("is_running") != null and not bool(battle.is_running):
		return false

	var is_trainer: bool = bool(battle.is_trainer_battle) if battle.get("is_trainer_battle") != null else false
	if is_trainer:
		_msg(battle, "¡No puedes huir de un combate contra un entrenador!")
		await _wait(battle, 0.8)
		return false

	var player: BattleBattler = battle.player as BattleBattler if battle.get("player") != null else null
	if player != null and player.cannot_escape:
		_msg(battle, "¡No puedes escapar!")
		await _wait(battle, 0.8)
		return false

	for foe: BattleBattler in BattleUtil.get_side_actives(battle, false):
		if foe != null and not foe.is_fainted() and AbilityRuntime.prevents_escape(foe, player):
			_msg(battle, "¡No puedes escapar!")
			await _wait(battle, 0.8)
			return false

	# Fórmula clásica: speed ratio
	var p_speed: int = 1
	var e_speed: int = 1
	if player != null:
		p_speed = maxi(1, player.get_effective_stat(PokemonInstance.Stat.SPEED))
	var enemy: BattleBattler = battle.enemy as BattleBattler if battle.get("enemy") != null else null
	if enemy != null and not enemy.is_fainted():
		e_speed = maxi(1, enemy.get_effective_stat(PokemonInstance.Stat.SPEED))

	var odds: int = int(floor(float(p_speed * 128) / float(e_speed))) + 30 * int(battle.battle_turn_count if battle.get("battle_turn_count") != null else 1)
	odds = clampi(odds, 1, 255)
	var roll: int = randi_range(0, 255)
	if roll < odds:
		_msg(battle, "¡Escapaste sin problemas!")
		await _wait(battle, 0.7)
		_end(battle, false)
		return true

	_msg(battle, "¡No pudiste escapar!")
	await _wait(battle, 0.7)
	return false


static func _end(battle: Object, player_won: bool) -> void:
	if battle.get("is_running") != null:
		battle.is_running = false
	if battle.has_signal("battle_ended"):
		battle.battle_ended.emit(player_won)


static func _msg(battle: Object, text: String) -> void:
	if battle.has_signal("message"):
		battle.message.emit(text)


static func _wait(battle: Object, seconds: float) -> void:
	if battle.has_method("_wait"):
		await battle._wait(seconds)
	else:
		await Engine.get_main_loop().create_timer(seconds).timeout
