extends Node

## Menú interno para probar sistemas sin escenas extra.
var _open: bool = false
var _screen: String = "root"
var _choice: String = ""


func _input(event: InputEvent) -> void:
	if _open or DialogueBox.activo or not event.is_pressed() or event.is_echo():
		return
	var select_pressed: bool = event.is_action_pressed("buttonSelect") if InputMap.has_action("buttonSelect") else event.is_action_pressed("buttonSelected")
	var x_held: bool = Input.is_action_pressed("buttonX") if InputMap.has_action("buttonX") else Input.is_action_pressed("buttonB")
	if select_pressed and x_held:
		_open = true
		_show("root")
		get_viewport().set_input_as_handled()


func _show(screen: String) -> void:
	_screen = screen
	var box: DialogueBox = get_tree().get_first_node_in_group("dialogue_box") as DialogueBox
	if box == null:
		_open = false
		return
	box.choice_selected.connect(func(value: String) -> void: _choice = value, CONNECT_ONE_SHOT)
	box.dialogue_closed.connect(_on_dialogue_closed, CONNECT_ONE_SHOT)
	match screen:
		"root": DialogueManager.show_texts(["DEBUG MENU"], "", null, ["Jugador", "Mundo", "Objetos y flags", "Guardar / info"])
		"player": DialogueManager.show_texts(["Jugador"], "", null, ["Cambiar sprite", "Curar PP", "Volver"])
		"world": DialogueManager.show_texts(["Mundo"], "", null, ["Clima", "Warp Prado Natal", "Warp Pueblo Alba", "Volver"])
		"weather": DialogueManager.show_texts(["Clima"], "", null, ["Ninguno", "Lluvia", "Nieve", "Tormenta arena"])
		"items": DialogueManager.show_texts(["Objetos y flags"], "", null, ["+10 Pociones", "Toggle FLAG_DEBUG", "Volver"])
		"save": DialogueManager.show_texts([_debug_info()], "", null, ["Guardar", "Volver"])


func _on_dialogue_closed() -> void:
	call_deferred("_handle_choice")


func _handle_choice() -> void:
	match _screen:
		"root": _show(["player", "world", "items", "save"][_choice.to_int()] if _choice.to_int() < 4 else "root")
		"player":
			if _choice == "0": _cycle_player_sprite()
			elif _choice == "1": _restore_party_pp()
			_show("root" if _choice == "2" else "player")
		"world":
			if _choice == "0": _show("weather")
			elif _choice == "1": _warp(MapSection.SectionId.MAPSEC_PRADO_NATAL)
			elif _choice == "2": _warp(MapSection.SectionId.MAPSEC_PUEBLO_ALBA)
			else: _show("root")
		"weather":
			var climates: Array[WeatherEffect.WeatherID] = [WeatherEffect.WeatherID.WEATHER_NONE, WeatherEffect.WeatherID.WEATHER_RAIN, WeatherEffect.WeatherID.WEATHER_SNOW, WeatherEffect.WeatherID.WEATHER_SANDSTORM]
			if _choice.to_int() < climates.size(): WeatherManager.set_weather(climates[_choice.to_int()])
			_show("world")
		"items":
			if _choice == "0": _add_potions()
			elif _choice == "1": ScriptExecutionContext.global_flags["FLAG_DEBUG"] = not bool(ScriptExecutionContext.global_flags.get("FLAG_DEBUG", false))
			_show("root" if _choice == "2" else "items")
		"save":
			if _choice == "0": SaveManager.request_save(get_tree())
			else: _show("root")


func _player() -> CharacterController:
	return get_tree().get_first_node_in_group("player") as CharacterController

func _cycle_player_sprite() -> void:
	var player: CharacterController = _player()
	var data: CharacterPlayer = player.character_data as CharacterPlayer if player else null
	if data:
		var next: int = (int(data.sprite_overworld) + 1) % EventObjects.PlayerID.size()
		data.sprite_overworld = next as EventObjects.PlayerID

func _restore_party_pp() -> void:
	var player: CharacterController = _player()
	var data: CharacterPlayer = player.character_data as CharacterPlayer if player else null
	if data:
		for pokemon: PokemonInstance in data.party:
			if pokemon: pokemon.restore_pp()

func _add_potions() -> void:
	var player: CharacterController = _player()
	var data: CharacterPlayer = player.character_data as CharacterPlayer if player else null
	if data:
		if data.bag == null: data.bag = Bag.new()
		data.bag.add_item(Items.ItemId.ITEM_POTION, 10)

func _warp(section: MapSection.SectionId) -> void:
	var player: CharacterController = _player()
	if player and player.map_manager:
		player.map_manager.warp_player_to_section(section, Vector2i(7, 11))
	_open = false

func _debug_info() -> String:
	var player: CharacterController = _player()
	var map_name: String = player.mapa_raiz.map_name if player and player.mapa_raiz is MapAttributes else "Sin mapa"
	return "Mapa: %s\nFlags: %d\nTiempo: %ds" % [map_name, ScriptExecutionContext.global_flags.size(), int(SaveManager.get_play_seconds())]
