extends Node

const SLOT_COUNT: int = 3
const SAVE_PATH_FORMAT: String = "user://save_slot_%d.json"

signal save_finished(success: bool)

var active_slot: int = 1
var pending_load_slot: int = 0
var new_game_requested: bool = false
var _play_started_msec: int = 0
var _stored_play_seconds: float = 0.0
var _awaiting_confirmation: bool = false
var _save_confirmed: bool = false

func _process(_delta: float) -> void:
	pass

func slot_path(slot: int) -> String:
	return SAVE_PATH_FORMAT % clampi(slot, 1, SLOT_COUNT)

func has_slot(slot: int) -> bool:
	return FileAccess.file_exists(slot_path(slot))

func get_slot_data(slot: int) -> Dictionary:
	if slot < 1 or slot > SLOT_COUNT:
		return {}
	var file: FileAccess = FileAccess.open(slot_path(slot), FileAccess.READ)
	if not file:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if not parsed is Dictionary:
		push_warning("SaveManager: la ranura %d tiene datos inválidos" % slot)
		return {}
	return (parsed as Dictionary).duplicate(true)

func get_play_seconds() -> float:
	if _play_started_msec == 0:
		return _stored_play_seconds
	return _stored_play_seconds + float(Time.get_ticks_msec() - _play_started_msec) / 1000.0

func start_new_game(slot: int) -> void:
	active_slot = clampi(slot, 1, SLOT_COUNT)
	pending_load_slot = 0
	new_game_requested = true
	_stored_play_seconds = 0.0
	_play_started_msec = Time.get_ticks_msec()
	ScriptExecutionContext.global_flags.clear()

func request_load(slot: int) -> bool:
	if not has_slot(slot):
		return false
	active_slot = clampi(slot, 1, SLOT_COUNT)
	pending_load_slot = active_slot
	new_game_requested = false
	return true

func consume_pending_load() -> Dictionary:
	if pending_load_slot == 0:
		return {}
	var data: Dictionary = get_slot_data(pending_load_slot)
	pending_load_slot = 0
	if data.is_empty():
		return {}
	_stored_play_seconds = float(data.get("play_seconds", 0.0))
	_play_started_msec = Time.get_ticks_msec()
	# JSON devuelve Dictionary sin tipado; copiarlo entrada por entrada evita
	# asignarlo directamente a Dictionary[String, Variant].
	ScriptExecutionContext.global_flags.clear()
	var saved_flags_value: Variant = data.get("flags", {})
	if saved_flags_value is Dictionary:
		for flag_name: Variant in (saved_flags_value as Dictionary):
			ScriptExecutionContext.global_flags[str(flag_name)] = (saved_flags_value as Dictionary)[flag_name]
	return data

func request_save(tree: SceneTree, menu: CanvasLayer = null) -> void:
	if _awaiting_confirmation:
		return
	_awaiting_confirmation = true
	_save_confirmed = false
	if menu and menu.has_method("toggle_menu"):
		menu.toggle_menu()
	# Deja de capturar el botón A del menú de pausa antes de mostrar la elección.
	await tree.process_frame
	_show_slot_choice(tree)

func _show_slot_choice(tree: SceneTree) -> void:
	var box: DialogueBox = tree.get_first_node_in_group("dialogue_box") as DialogueBox
	if not box:
		_finish_save(false)
		return
	box.choice_selected.connect(_on_slot_chosen.bind(tree), CONNECT_ONE_SHOT)
	DialogueManager.show_texts(["¿En qué ranura deseas guardar?"], "", null, ["Ranura 1", "Ranura 2", "Ranura 3"])

func _on_slot_chosen(choice: String, tree: SceneTree) -> void:
	active_slot = clampi(int(choice) + 1, 1, SLOT_COUNT)
	var box: DialogueBox = tree.get_first_node_in_group("dialogue_box") as DialogueBox
	if box:
		box.dialogue_closed.connect(_show_overwrite_choice.bind(tree), CONNECT_ONE_SHOT)

func _show_overwrite_choice(tree: SceneTree) -> void:
	var box: DialogueBox = tree.get_first_node_in_group("dialogue_box") as DialogueBox
	if not box:
		_finish_save(false)
		return
	box.choice_selected.connect(_on_overwrite_chosen.bind(tree), CONNECT_ONE_SHOT)
	box.dialogue_closed.connect(_complete_save_after_dialogue.bind(tree), CONNECT_ONE_SHOT)
	var prompt: String = "¿Deseas reemplazar esta partida?" if has_slot(active_slot) else "¿Deseas guardar la partida?"
	DialogueManager.show_texts([prompt], "", null, ["Sí", "No"])

func _on_overwrite_chosen(choice: String, _tree: SceneTree) -> void:
	_save_confirmed = choice == "0"

func _complete_save_after_dialogue(tree: SceneTree) -> void:
	var success: bool = false
	if _save_confirmed:
		# Deja que la acción de guardado tenga una pausa perceptible antes del aviso final.
		await tree.create_timer(0.35).timeout
		success = save_game(tree)
	_save_confirmed = false
	if success:
		_show_saved_message(tree)
	else:
		_finish_save(false)

func _show_saved_message(tree: SceneTree) -> void:
	var box: DialogueBox = tree.get_first_node_in_group("dialogue_box") as DialogueBox
	if not box:
		_finish_save(true)
		return
	box.dialogue_closed.connect(_finish_save.bind(true), CONNECT_ONE_SHOT)
	DialogueManager.show_texts(["La partida se guardó correctamente."], "", null)

func _finish_save(success: bool) -> void:
	_awaiting_confirmation = false
	save_finished.emit(success)

func save_game(tree: SceneTree) -> bool:
	var player: CharacterController = tree.get_first_node_in_group("player") as CharacterController
	if not player:
		return false
	var map: MapAttributes = player.mapa_raiz as MapAttributes
	var player_data: CharacterPlayer = player.character_data as CharacterPlayer
	var data: Dictionary = {
		"version": 2,
		"saved_at": Time.get_datetime_string_from_system(),
		"play_seconds": get_play_seconds(),
		"player_position": [player.global_position.x, player.global_position.y],
		"player_money": player_data.money if player_data else 0,
		"player_name": player_data.name if player_data else "",
		"map_name": map.map_name if map else "",
		"map_section": int(map.map_id_section) if map else 0,
		"flags": ScriptExecutionContext.global_flags
	}
	var file: FileAccess = FileAccess.open(slot_path(active_slot), FileAccess.WRITE)
	if not file:
		return false
	file.store_string(JSON.stringify(data))
	file.close()
	return true
