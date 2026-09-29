extends RefCounted
class_name BattleDone
## Limpieza al terminar el combate: formas, dynamax, volatiles de party.


static func cleanup(battle: Object) -> void:
	BattleGimmick.end_of_battle_cleanup(battle)
	for mon: PokemonInstance in _all_party_mons(battle):
		_revert_forms(mon)
		_clear_battle_volatiles_on_mon(mon)
	# Limpiar campos
	if battle is BattleMain:
		var main: BattleMain = battle as BattleMain
		main.state.is_running = false
	elif battle.get("is_running") != null:
		battle.is_running = false


static func finish(battle: Object, player_won: bool) -> void:
	cleanup(battle)
	if battle.has_signal("battle_ended"):
		battle.battle_ended.emit(player_won)


static func _all_party_mons(battle: Object) -> Array[PokemonInstance]:
	var result: Array[PokemonInstance] = []
	for mon: PokemonInstance in BattleUtil._party(battle, true):
		if mon != null:
			result.append(mon)
	for mon2: PokemonInstance in BattleUtil._party(battle, false):
		if mon2 != null:
			result.append(mon2)
	return result


static func _revert_forms(mon: PokemonInstance) -> void:
	if mon == null:
		return
	if mon.has_method("revert_battle_form"):
		mon.revert_battle_form()
	# Mega / form flags en meta del mon si se usaron
	if mon.has_meta("battle_form_id"):
		mon.remove_meta("battle_form_id")


static func _clear_battle_volatiles_on_mon(mon: PokemonInstance) -> void:
	# No tocamos status permanente; solo flags de combate si existen
	if mon == null:
		return
	if mon.has_meta("battle_trapped"):
		mon.remove_meta("battle_trapped")
