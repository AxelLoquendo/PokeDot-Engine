extends RefCounted
class_name MapEventResolver

## Evalúa eventos de casilla al terminar un paso o al pulsar A.


static func events_on_tile(map_root: Node, tile: Vector2i) -> Array[MapEvent]:
	var result: Array[MapEvent] = []
	if map_root == null:
		return result
	_collect_recursive(map_root, tile, result)
	return result


static func _collect_recursive(node: Node, tile: Vector2i, out: Array[MapEvent]) -> void:
	if node is MapEvent:
		var ev: MapEvent = node as MapEvent
		if ev.get_tile() == tile:
			out.append(ev)
	for child: Node in node.get_children():
		_collect_recursive(child, tile, out)


## Llamar al completar un paso del jugador.
## Devuelve true si se consumió el paso (script o warp).
static func try_step(player: CharacterController) -> bool:
	if player == null or player.mapa_raiz == null:
		return false
	if not (player.character_data is CharacterPlayer):
		return false

	var tile: Vector2i = player.casilla_actual
	var events: Array[MapEvent] = events_on_tile(player.mapa_raiz, tile)

	# 1) COORD
	for ev: MapEvent in events:
		if ev.kind != MapEvent.Kind.COORD:
			continue
		if not ev.condition_ok():
			continue
		if ev.script_file.is_empty():
			continue
		_run_script(player, ev.script_file)
		return true

	# 2) WARP
	for ev: MapEvent in events:
		if ev.kind != MapEvent.Kind.WARP:
			continue
		if not ev.condition_ok():
			continue
		_start_warp(player, ev)
		return true

	return false


## Llamar cuando el jugador pulsa A (interacción).
static func try_interact(player: CharacterController) -> bool:
	if player == null or player.mapa_raiz == null:
		return false
	if not (player.character_data is CharacterPlayer):
		return false

	var tile: Vector2i = player.casilla_actual
	if player is Player:
		tile = (player as Player).obtener_casilla_frontal()
	else:
		# fallback
		tile = player.casilla_actual + Vector2i(0, 1)

	var events: Array[MapEvent] = events_on_tile(player.mapa_raiz, tile)

	for ev: MapEvent in events:
		if ev.kind != MapEvent.Kind.BG:
			continue
		if not ev.condition_ok():
			continue
		if ev.bg_kind == MapEvent.BgKind.HIDDEN_ITEM:
			if ev.is_hidden_item_taken():
				continue
			if ev.hidden_item_id != Items.ItemId.ITEM_NONE:
				var data: CharacterPlayer = player.character_data as CharacterPlayer
				if data != null and data.bag != null:
					data.bag.add_item(ev.hidden_item_id, 1)
				if not ev.hidden_item_flag.is_empty():
					ScriptExecutionContext.global_flags[ev.hidden_item_flag] = true
				# Mensaje simple; puedes cambiarlo por diálogo
				print("Objeto oculto obtenido: ", ev.hidden_item_id)
			if not ev.script_file.is_empty():
				_run_script(player, ev.script_file)
			return true
		# SIGN
		if not ev.script_file.is_empty():
			_run_script(player, ev.script_file)
			return true
	return false


static func _last_facing(player: CharacterController) -> Vector2i:
	# Fallback: abajo
	if player.get("facing_direction") != null:
		var f: Variant = player.get("facing_direction")
		if f is Vector2:
			return Vector2i(f as Vector2)
		if f is Vector2i:
			return f as Vector2i
	return Vector2i(0, 1)


static func _run_script(player: CharacterController, path: String) -> void:
	if path.is_empty() or not FileAccess.file_exists(path):
		push_error("MapEventResolver: no existe el script %s" % path)
		return
	var map_node: Node = player.mapa_raiz
	var script_file: ScriptCmdTextFile = ScriptCmdTextFile.new()
	script_file.script_file_path = path
	var runner: ScriptRunner = ScriptRunner.new()
	map_node.add_child(runner)
	runner.script_finished.connect(runner.queue_free, CONNECT_ONE_SHOT)
	runner.start_script([script_file], null, player, map_node)


static func _start_warp(player: CharacterController, ev: MapEvent) -> void:
	if player.map_manager == null:
		push_error("MapEventResolver: sin MapManager")
		return
	var section_id: int = _section_from_text(ev.dest_map)
	if section_id < 0:
		push_error("MapEventResolver: MAPSEC desconocido '%s'" % ev.dest_map)
		return
	# Heal point futuro para Escape Rope
	if ev.is_heal_point and player.character_data is CharacterPlayer:
		var data: CharacterPlayer = player.character_data as CharacterPlayer
		data.set_meta("last_heal_section", section_id)
		data.set_meta("last_heal_tile", ev.dest_tile)

	var fade_out_finished: Signal = TransicionManager.fade_out(ev.warp_fade_duration)
	fade_out_finished.connect(func() -> void:
		player.map_manager.warp_player_to_section(section_id, ev.dest_tile)
		TransicionManager.fade_in(ev.warp_fade_duration)
	, CONNECT_ONE_SHOT)


static func _section_from_text(text: String) -> int:
	if text.is_empty():
		return -1
	var normalized: String = text.to_upper()
	if MapSection.SectionId.has(normalized):
		return int(MapSection.SectionId[normalized])
	if not normalized.begins_with("MAPSEC_"):
		normalized = "MAPSEC_" + normalized
	if MapSection.SectionId.has(normalized):
		return int(MapSection.SectionId[normalized])
	return -1
