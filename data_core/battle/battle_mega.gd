extends RefCounted
class_name BattleMega
## Mega evolución (stub funcional: flag + mensaje; species swap vía datos).


static func can_mega(battle: Object, battler: BattleBattler) -> bool:
	if battler == null or battler.pokemon == null:
		return false
	if bool(battler.get_meta("is_mega", false)):
		return false
	# Un mega por combate y por lado (simplificado)
	if bool(battle.get_meta("mega_used_player", false)) and battler.is_player_side:
		return false
	if bool(battle.get_meta("mega_used_enemy", false)) and not battler.is_player_side:
		return false
	# Requiere held item stone — se valida con datos de species si existen
	if battler.pokemon.held_item == Items.ItemId.ITEM_NONE:
		return false
	return true


static func activate(battle: Object, battler: BattleBattler) -> bool:
	if not can_mega(battle, battler):
		return false
	battler.set_meta("is_mega", true)
	if battler.is_player_side:
		battle.set_meta("mega_used_player", true)
	else:
		battle.set_meta("mega_used_enemy", true)
	_msg(battle, "¡%s reaccionó a la Mega Piedra!" % battler.get_display_name())
	await _wait(battle, 0.6)
	_msg(battle, "¡%s megaevolucionó!" % battler.get_display_name())
	await _wait(battle, 0.9)
	if battle.has_signal("battler_appearance_changed"):
		battle.battler_appearance_changed.emit(battler.is_player_side)
	return true


static func force_end(battle: Object, battler: BattleBattler) -> void:
	if battler != null and bool(battler.get_meta("is_mega", false)):
		battler.remove_meta("is_mega")


static func _msg(battle: Object, text: String) -> void:
	if battle.has_signal("message"):
		battle.message.emit(text)


static func _wait(battle: Object, seconds: float) -> void:
	if battle.has_method("_wait"):
		await battle._wait(seconds)
	else:
		await Engine.get_main_loop().create_timer(seconds).timeout
