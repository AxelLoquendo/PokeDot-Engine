extends RefCounted
class_name BattleCapture
## Lanzamiento de Ball y registro de captura (delega a CaptureResolver).


static func attempt(battle: Object, item: ItemData, data: CharacterPlayer) -> bool:
	if item == null or data == null:
		return false

	var is_trainer: bool = bool(battle.is_trainer_battle) if battle.get("is_trainer_battle") != null else false
	if is_trainer:
		_msg(battle, "¡El entrenador bloqueó la Poké Ball!")
		await _wait(battle, 0.8)
		return false

	var target: BattleBattler = battle.enemy as BattleBattler if battle.get("enemy") != null else null
	if target == null or target.pokemon == null or target.is_fainted():
		_msg(battle, "¡No hay ningún Pokémon al que lanzar la Ball!")
		await _wait(battle, 0.7)
		return false

	if data.party.size() >= 6:
		_msg(battle, "¡Tu equipo está completo! No puedes capturar más Pokémon.")
		await _wait(battle, 0.9)
		return false

	var ball_id: Items.ItemId = item.item_id
	var ball_name: String = item.item_name if not item.item_name.is_empty() else "Poké Ball"
	_msg(battle, "¡Usaste una %s!" % ball_name)
	await _wait(battle, 0.6)

	if not item.not_consumed:
		data.bag.remove_item(ball_id)

	var already_owned: bool = false
	if data.pokedex != null:
		already_owned = data.pokedex.is_owned(int(target.pokemon.species_id))

	var turn_for_ball: int = maxi(1, int(battle.battle_turn_count) if battle.get("battle_turn_count") != null else 1)
	var cap: CaptureResolver.Result = CaptureResolver.attempt(
		ball_id,
		target.pokemon,
		battle,
		turn_for_ball,
		already_owned,
		battle.player if battle.get("player") != null else null
	)

	if not cap.success:
		for _s: int in range(cap.shakes):
			_msg(battle, "…")
			await _wait(battle, 0.35)
		_msg(battle, cap.message)
		await _wait(battle, 0.8)
		if AbilityRuntime.try_ball_fetch(data.party, ball_id):
			_msg(battle, "¡Ball Fetch recuperó la Ball!")
			await _wait(battle, 0.6)
		return false

	for _s2: int in range(3):
		_msg(battle, "…")
		await _wait(battle, 0.35)
	_msg(battle, "¡Listo! ¡%s atrapado!" % target.get_display_name())
	await _wait(battle, 0.9)

	var caught: PokemonInstance = CaptureResolver.clone_for_party(target.pokemon, ball_id)
	if caught == null:
		_msg(battle, "Error al guardar el Pokémon capturado.")
		await _wait(battle, 0.7)
		return false

	if caught.has_method("set_provenance"):
		var map_name: String = _map_name(battle)
		caught.set_provenance(map_name, caught.level)

	if not data.add_pokemon(caught):
		_msg(battle, "¡Tu equipo está completo!")
		await _wait(battle, 0.8)
		_msg(battle, "No hay espacio. El Pokémon se escapó al no poder guardarlo.")
		await _wait(battle, 0.8)
		return false

	var first_owned: bool = false
	if CaptureFlow != null:
		first_owned = CaptureFlow.register_owned(data, caught)
		CaptureFlow.register_seen(data, caught)

	_msg(battle, "¡%s atrapado!" % caught.get_display_name())
	await _wait(battle, 0.85)

	if first_owned:
		_msg(battle, "Los datos de %s se registraron en la Pokédex." % caught.get_display_name())
		await _wait(battle, 0.85)

	if battle.get("is_running") != null:
		battle.is_running = false
	if battle.has_signal("battle_ended"):
		battle.battle_ended.emit(true)
	return true


static func _map_name(battle: Object) -> String:
	if battle.has_method("_current_map_display_name"):
		return str(battle._current_map_display_name())
	return "Desconocido"


static func _msg(battle: Object, text: String) -> void:
	if battle.has_signal("message"):
		battle.message.emit(text)


static func _wait(battle: Object, seconds: float) -> void:
	if battle.has_method("_wait"):
		await battle._wait(seconds)
	else:
		await Engine.get_main_loop().create_timer(seconds).timeout
