extends RefCounted
class_name BattleAnim
## Punto de entrada de animaciones de combate.
## Las animaciones por tipo (battle_anim_fire, etc.) se registrarán aquí.


static func play_move(
	battle: Object,
	actor: BattleBattler,
	target: BattleBattler,
	move: MoveData
) -> void:
	if move == null:
		return
	# Stub: espera corta; en el futuro despacha a battle_anim_<type>
	await _wait(battle, 0.25)


static func play_status(battle: Object, battler: BattleBattler, status: PokemonInstance.Status) -> void:
	await _wait(battle, 0.15)


static func play_faint(battle: Object, battler: BattleBattler) -> void:
	await _wait(battle, 0.35)


static func play_switch(battle: Object, is_player: bool) -> void:
	await _wait(battle, 0.2)


static func _wait(battle: Object, seconds: float) -> void:
	if battle.has_method("_wait"):
		await battle._wait(seconds)
	else:
		await Engine.get_main_loop().create_timer(seconds).timeout
