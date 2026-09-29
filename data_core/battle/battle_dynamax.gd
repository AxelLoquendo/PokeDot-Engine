extends RefCounted
class_name BattleDynamax
## Dynamax / Gigantamax: 3 turnos, HP ×2 visual, max moves (stub).


const DYNAMAX_TURNS: int = 3


static func can_dynamax(battle: Object, battler: BattleBattler) -> bool:
	if battler == null or battler.pokemon == null or battler.is_fainted():
		return false
	if bool(battler.get_meta("is_dynamax", false)):
		return false
	if battler.is_player_side and bool(battle.get_meta("dmax_used_player", false)):
		return false
	if not battler.is_player_side and bool(battle.get_meta("dmax_used_enemy", false)):
		return false
	return true


static func activate(battle: Object, battler: BattleBattler, gigantamax: bool = false) -> bool:
	if not can_dynamax(battle, battler):
		return false
	battler.set_meta("is_dynamax", true)
	battler.set_meta("is_gigantamax", gigantamax)
	battler.set_meta("dynamax_turns", DYNAMAX_TURNS)
	# HP pool visual ×2 (no cambia max real del mon fuera de combate)
	var max_hp: int = battler.get_max_hp()
	battler.set_meta("dynamax_hp_max", max_hp * 2)
	battler.set_meta("dynamax_hp_current", battler.get_current_hp() * 2)
	if battler.is_player_side:
		battle.set_meta("dmax_used_player", true)
	else:
		battle.set_meta("dmax_used_enemy", true)
	var label: String = "Gigantamax" if gigantamax else "Dynamax"
	_msg(battle, "¡%s usó %s!" % [battler.get_display_name(), label])
	await _wait(battle, 0.9)
	if battle.has_signal("battler_appearance_changed"):
		battle.battler_appearance_changed.emit(battler.is_player_side)
	if battle.has_method("_emit_hp_battler"):
		battle._emit_hp_battler(battler)
	return true


static func tick_end_turn(battle: Object, battler: BattleBattler) -> void:
	if battler == null or not bool(battler.get_meta("is_dynamax", false)):
		return
	var turns: int = int(battler.get_meta("dynamax_turns", 0)) - 1
	battler.set_meta("dynamax_turns", turns)
	if turns <= 0:
		await force_end(battle, battler)


static func force_end(battle: Object, battler: BattleBattler) -> void:
	if battler == null or not bool(battler.get_meta("is_dynamax", false)):
		return
	battler.remove_meta("is_dynamax")
	battler.remove_meta("is_gigantamax")
	battler.remove_meta("dynamax_turns")
	battler.remove_meta("dynamax_hp_max")
	battler.remove_meta("dynamax_hp_current")
	_msg(battle, "¡%s recuperó su tamaño normal!" % battler.get_display_name())
	await _wait(battle, 0.6)
	if battle.has_signal("battler_appearance_changed"):
		battle.battler_appearance_changed.emit(battler.is_player_side)
	if battle.has_method("_emit_hp_battler"):
		battle._emit_hp_battler(battler)


static func _msg(battle: Object, text: String) -> void:
	if battle.has_signal("message"):
		battle.message.emit(text)


static func _wait(battle: Object, seconds: float) -> void:
	if battle.has_method("_wait"):
		await battle._wait(seconds)
	else:
		await Engine.get_main_loop().create_timer(seconds).timeout
