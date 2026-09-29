
extends RefCounted
class_name BattleIntro
## Secuencia de entrada al combate (dex, mensajes, switch-in abilities).


static func run(battle: Object) -> void:
	_register_encounter_dex(battle)
	if battle.has_method("_sync_primary_refs"):
		battle._sync_primary_refs()
	elif battle is BattleMain:
		(battle as BattleMain).state.sync_primary_refs()

	var enemy_names: PackedStringArray = PackedStringArray()
	for b: BattleBattler in _actives(battle, false):
		if b != null and b.pokemon != null and not b.is_fainted():
			enemy_names.append(b.get_display_name())

	var is_trainer: bool = bool(battle.is_trainer_battle) if battle.get("is_trainer_battle") != null else false
	if is_trainer:
		var sender: String = str(battle.trainer_name) if battle.get("trainer_name") != null else ""
		if sender.is_empty():
			sender = "El rival"
		_msg(battle, "¡%s envía a %s!" % [sender, ", ".join(enemy_names)])
	else:
		if enemy_names.size() > 1:
			_msg(battle, "¡Aparecieron %s!" % " y ".join(enemy_names))
		elif enemy_names.size() == 1:
			_msg(battle, "¡Un %s salvaje apareció!" % enemy_names[0])

	if battle.has_signal("pokemon_entered_field"):
		battle.pokemon_entered_field.emit(false)
	await _wait(battle, 1.0)

	for eb: BattleBattler in _actives(battle, false):
		if eb == null or eb.pokemon == null or eb.is_fainted():
			continue
		await BattleSwitchIn.on_enter(battle, eb)

	var player_names: PackedStringArray = PackedStringArray()
	for pb: BattleBattler in _actives(battle, true):
		if pb != null and pb.pokemon != null and not pb.is_fainted():
			player_names.append(pb.get_display_name())
	_msg(battle, "¡Adelante, %s!" % ", ".join(player_names))
	if battle.has_signal("pokemon_entered_field"):
		battle.pokemon_entered_field.emit(true)
	await _wait(battle, 0.8)

	for pb2: BattleBattler in _actives(battle, true):
		if pb2 == null or pb2.pokemon == null or pb2.is_fainted():
			continue
		await BattleSwitchIn.on_enter(battle, pb2)


static func _register_encounter_dex(_battle: Object) -> void:
	## Marca seen en la Pokédex del jugador.
	## PokedexData expone set_seen / set_owned (no register_seen).
	if BattleSession.player_controller == null:
		return
	var pdata: CharacterPlayer = (
		BattleSession.player_controller.character_data as CharacterPlayer
	)
	if pdata == null:
		return

	var dex: PokedexData = null
	if pdata.has_method("ensure_pokedex"):
		dex = pdata.ensure_pokedex()
	else:
		dex = pdata.pokedex
	if dex == null:
		return

	for b: BattleBattler in _actives(_battle, false):
		if b != null and b.pokemon != null:
			dex.set_seen(int(b.pokemon.species_id))


static func _actives(battle: Object, is_player: bool) -> Array[BattleBattler]:
	return BattleUtil.get_side_actives(battle, is_player)


static func _msg(battle: Object, text: String) -> void:
	if battle.has_signal("message"):
		battle.message.emit(text)


static func _wait(battle: Object, seconds: float) -> void:
	if battle.has_method("_wait"):
		await battle._wait(seconds)
	else:
		await Engine.get_main_loop().create_timer(seconds).timeout
