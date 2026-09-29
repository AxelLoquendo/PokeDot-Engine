extends RefCounted
class_name BattleTerastal
## Teracristalización: cambia tipo efectivo al tera_type del mon.


static func can_tera(battle: Object, battler: BattleBattler) -> bool:
	if battler == null or battler.pokemon == null or battler.is_fainted():
		return false
	if bool(battler.get_meta("is_tera", false)):
		return false
	if battler.is_player_side and bool(battle.get_meta("tera_used_player", false)):
		return false
	if not battler.is_player_side and bool(battle.get_meta("tera_used_enemy", false)):
		return false
	# Requiere tera_type definido en el mon
	if not ("tera_type" in battler.pokemon):
		return false
	return true


static func activate(battle: Object, battler: BattleBattler) -> bool:
	if not can_tera(battle, battler):
		return false
	battler.set_meta("is_tera", true)
	var tera: int = int(battler.pokemon.tera_type)
	battler.set_meta("tera_type", tera)
	if battler.is_player_side:
		battle.set_meta("tera_used_player", true)
	else:
		battle.set_meta("tera_used_enemy", true)
	_msg(battle, "¡%s se teracristalizó!" % battler.get_display_name())
	await _wait(battle, 0.85)
	if battle.has_signal("battler_appearance_changed"):
		battle.battler_appearance_changed.emit(battler.is_player_side)
	return true


static func force_end(battle: Object, battler: BattleBattler) -> void:
	if battler == null:
		return
	if battler.has_meta("is_tera"):
		battler.remove_meta("is_tera")
	if battler.has_meta("tera_type"):
		battler.remove_meta("tera_type")


static func get_effective_types(battler: BattleBattler) -> PackedInt32Array:
	var result: PackedInt32Array = PackedInt32Array()
	if battler != null and bool(battler.get_meta("is_tera", false)):
		result.append(int(battler.get_meta("tera_type", 0)))
		return result
	# Fallback: tipos de species — el caller usa get_species normalmente
	return result


static func _msg(battle: Object, text: String) -> void:
	if battle.has_signal("message"):
		battle.message.emit(text)


static func _wait(battle: Object, seconds: float) -> void:
	if battle.has_method("_wait"):
		await battle._wait(seconds)
	else:
		await Engine.get_main_loop().create_timer(seconds).timeout
