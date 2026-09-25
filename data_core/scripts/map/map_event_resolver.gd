extends RefCounted
class_name MapEventResolver

## Evalúa eventos de casilla al terminar un paso o al pulsar A.
## Warps se enlazan por warp_id ↔ dest_warp_id (estilo pokeemerald).


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


static func find_warp_by_id(map_root: Node, warp_id: int) -> MapEvent:
	if map_root == null:
		return null
	return _find_warp_recursive(map_root, warp_id)


static func _find_warp_recursive(node: Node, warp_id: int) -> MapEvent:
	if node is MapEvent:
		var ev: MapEvent = node as MapEvent
		if ev.kind == MapEvent.Kind.WARP and ev.warp_id == warp_id:
			return ev
	for child: Node in node.get_children():
		var found: MapEvent = _find_warp_recursive(child, warp_id)
		if found != null:
			return found
	return null


static func try_step(player: CharacterController) -> bool:
	if player == null or player.mapa_raiz == null:
		return false
	if not (player.character_data is CharacterPlayer):
		return false

	var tile: Vector2i = player.casilla_actual
	var events: Array[MapEvent] = events_on_tile(player.mapa_raiz, tile)

	for ev: MapEvent in events:
		if ev.kind != MapEvent.Kind.COORD:
			continue
		if not ev.condition_ok():
			continue
		if ev.script_file.is_empty():
			continue
		_run_script(player, ev.script_file)
		return true

	for ev: MapEvent in events:
		if ev.kind != MapEvent.Kind.WARP:
			continue
		if not ev.condition_ok():
			continue
		_start_warp(player, ev)
		return true

	return false


static func try_interact(player: CharacterController) -> bool:
	if player == null or player.mapa_raiz == null:
		return false
	if not (player.character_data is CharacterPlayer):
		return false

	var tile: Vector2i = player.casilla_actual
	if player is Player:
		tile = (player as Player).obtener_casilla_frontal()
	else:
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
				print("Objeto oculto obtenido: ", ev.hidden_item_id)
			if not ev.script_file.is_empty():
				_run_script(player, ev.script_file)
			return true
		if not ev.script_file.is_empty():
			_run_script(player, ev.script_file)
			return true
	return false


static func _run_script(player: CharacterController, path: String) -> void:
	if path.is_empty() or not FileAccess.file_exists(path):
		push_error("MapEventResolver: no existe el script %s" % path)
		return
	var map_node: Node = player.mapa_raiz
	var script_cmd: ScriptCmdTextFile = ScriptCmdTextFile.new()
	script_cmd.script_file_path = path
	var runner: ScriptRunner = ScriptRunner.new()
	map_node.add_child(runner)
	runner.script_finished.connect(runner.queue_free, CONNECT_ONE_SHOT)
	runner.start_script([script_cmd], null, player, map_node)


static func _start_warp(player: CharacterController, ev: MapEvent) -> void:
	if player.map_manager == null:
		push_error("MapEventResolver: sin MapManager")
		return
	var section_id: int = int(ev.dest_map)
	if section_id == int(MapSection.SectionId.MAPSEC_NONE):
		push_error("MapEventResolver: dest_map no configurado en el warp")
		return

	# Bloquear sin retroceder de casilla
	player.is_moving = false
	player.percent_moved_to_next_tile = 0.0
	player.input_direction = Vector2.ZERO
	player.casilla_reservada = player.casilla_actual
	player.ejecutando_evento = true
	if player.has_method("reproducir_idle"):
		player.reproducir_idle()

	var fade_out_finished: Signal = TransicionManager.fade_out(ev.warp_fade_duration)
	fade_out_finished.connect(func() -> void:
		_finish_warp(player, ev, section_id)
		var fade_in_finished: Signal = TransicionManager.fade_in(ev.warp_fade_duration)
		fade_in_finished.connect(func() -> void:
			if is_instance_valid(player):
				player.ejecutando_evento = false
				if player.has_method("reproducir_idle"):
					player.reproducir_idle()
		, CONNECT_ONE_SHOT)
	, CONNECT_ONE_SHOT)


static func _finish_warp(player: CharacterController, source_ev: MapEvent, section_id: int) -> void:
	var provisional: Vector2i = source_ev.dest_tile_fallback
	player.map_manager.warp_player_to_section(section_id, provisional)

	var dest_map_node: Node = player.mapa_raiz
	var dest_ev: MapEvent = find_warp_by_id(dest_map_node, source_ev.dest_warp_id)
	if dest_ev == null:
		push_warning(
			"MapEventResolver: no hay WARP con warp_id=%d en el mapa destino; uso dest_tile_fallback %s"
			% [source_ev.dest_warp_id, str(source_ev.dest_tile_fallback)]
		)
		if source_ev.is_heal_point and player.character_data is CharacterPlayer:
			var data0: CharacterPlayer = player.character_data as CharacterPlayer
			data0.set_meta("last_heal_section", section_id)
			data0.set_meta("last_heal_tile", provisional)
		return

	var arrival: Vector2i = dest_ev.get_tile()
	var tile_size: float = 16.0
	if player.mapa_raiz is MapAttributes:
		tile_size = float((player.mapa_raiz as MapAttributes).tile_size)

	player.position = Vector2(
		float(arrival.x) * tile_size + tile_size * 0.5,
		float(arrival.y) * tile_size
	)
	player.casilla_actual = arrival
	player.casilla_reservada = arrival
	if player.has_method("actualizar_nivel_suelo"):
		player.actualizar_nivel_suelo(player.global_position)
	EventObjects.casillas_ocupadas.clear()
	EventObjects.casillas_reservadas.clear()
	EventObjects.registrar_casilla(arrival, player)

	if source_ev.is_heal_point and player.character_data is CharacterPlayer:
		var data: CharacterPlayer = player.character_data as CharacterPlayer
		data.set_meta("last_heal_section", section_id)
		data.set_meta("last_heal_tile", arrival)
