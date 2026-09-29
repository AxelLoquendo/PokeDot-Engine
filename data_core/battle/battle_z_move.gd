extends RefCounted
class_name BattleZMove
## Movimientos Z (stub: un Z por combate por lado).


static func can_z(battle: Object, battler: BattleBattler) -> bool:
	if battler == null or battler.pokemon == null:
		return false
	if battler.is_player_side and bool(battle.get_meta("z_used_player", false)):
		return false
	if not battler.is_player_side and bool(battle.get_meta("z_used_enemy", false)):
		return false
	return battler.pokemon.held_item != Items.ItemId.ITEM_NONE


static func activate(battle: Object, battler: BattleBattler) -> bool:
	if not can_z(battle, battler):
		return false
	if battler.is_player_side:
		battle.set_meta("z_used_player", true)
	else:
		battle.set_meta("z_used_enemy", true)
	battler.set_meta("z_active", true)
	_msg(battle, "¡%s rodea de energía Z!" % battler.get_display_name())
	await _wait(battle, 0.7)
	return true


static func clear_after_move(battler: BattleBattler) -> void:
	if battler != null and battler.has_meta("z_active"):
		battler.remove_meta("z_active")


static func _msg(battle: Object, text: String) -> void:
	if battle.has_signal("message"):
		battle.message.emit(text)


static func _wait(battle: Object, seconds: float) -> void:
	if battle.has_method("_wait"):
		await battle._wait(seconds)
	else:
		await Engine.get_main_loop().create_timer(seconds).timeout
