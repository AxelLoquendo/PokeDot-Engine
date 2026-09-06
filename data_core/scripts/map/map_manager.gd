extends Node
class_name MapManager

var jugador: CharacterController
var current_map: MapAttributes
var camara: Camera2D

var north_map: MapAttributes
var south_map: MapAttributes
var east_map: MapAttributes
var west_map: MapAttributes

var mapas_cargados: Dictionary[MapSection.SectionId, MapAttributes] = {}


# ====================== CARGA INICIAL ======================

func load_map(map: MapAttributes) -> void:
	current_map = map
	mapas_cargados[current_map.map_id_section] = current_map
	add_child(current_map)

	cargar_conexiones()
	_aplicar_entorno_mapa(current_map)


# ====================== CONEXIONES ======================

func cargar_conexiones() -> void:
	north_map = _cargar_y_colocar_vecino(current_map.north_map, MapAttributes.ConnectionDirection.NORTH)
	south_map = _cargar_y_colocar_vecino(current_map.south_map, MapAttributes.ConnectionDirection.SOUTH)
	east_map  = _cargar_y_colocar_vecino(current_map.east_map,  MapAttributes.ConnectionDirection.EAST)
	west_map  = _cargar_y_colocar_vecino(current_map.west_map,  MapAttributes.ConnectionDirection.WEST)


func _cargar_y_colocar_vecino(
	conexion: MapConnection,
	direccion: MapAttributes.ConnectionDirection
) -> MapAttributes:
	var mapa: MapAttributes = cargar_conexion(conexion)
	if mapa:
		colocar_vecino(mapa, direccion, conexion)
	return mapa


func cargar_conexion(conexion: MapConnection) -> MapAttributes:
	if conexion == null:
		return null

	if mapas_cargados.has(conexion.target_section):
		return mapas_cargados[conexion.target_section]

	var escena: PackedScene = conexion.get_scene()
	if escena == null:
		return null

	var mapa: MapAttributes = escena.instantiate() as MapAttributes
	if mapa == null:
		return null

	mapas_cargados[conexion.target_section] = mapa
	add_child(mapa)
	mapa.activo = false
	desactivar_contenido_mapa(mapa)
	return mapa


func colocar_vecino(
	mapa: MapAttributes,
	direccion: MapAttributes.ConnectionDirection,
	conexion: MapConnection
) -> void:
	if mapa == current_map:
		return

	mapa.position = current_map.obtener_posicion_conexion(direccion, conexion)
	mapa.visible = true
	desactivar_contenido_mapa(mapa)


# ====================== TRANSICIONES ======================

func comprobar_transicion() -> void:
	if jugador == null or current_map == null:
		return

	var local: Vector2 = current_map.to_local(jugador.global_position)
	var tile: float = float(current_map.tile_size)
	var ancho: float = float(current_map.map_size.x * current_map.tile_size)
	var alto: float = float(current_map.map_size.y * current_map.tile_size)
	var casilla: Vector2i = Vector2i(floori(local.x / tile), floori(local.y / tile))

	if local.x < 0.0 and west_map and _conexion_valida(current_map.west_map, casilla, MapAttributes.ConnectionDirection.WEST):
		cambiar_mapa(west_map, MapAttributes.ConnectionDirection.WEST)
		return
	if local.x >= ancho and east_map and _conexion_valida(current_map.east_map, casilla, MapAttributes.ConnectionDirection.EAST):
		cambiar_mapa(east_map, MapAttributes.ConnectionDirection.EAST)
		return
	if local.y < 0.0 and north_map and _conexion_valida(current_map.north_map, casilla, MapAttributes.ConnectionDirection.NORTH):
		cambiar_mapa(north_map, MapAttributes.ConnectionDirection.NORTH)
		return
	if local.y >= alto and south_map and _conexion_valida(current_map.south_map, casilla, MapAttributes.ConnectionDirection.SOUTH):
		cambiar_mapa(south_map, MapAttributes.ConnectionDirection.SOUTH)
		return


func _conexion_valida(conexion: MapConnection, casilla: Vector2i, direccion: MapAttributes.ConnectionDirection) -> bool:
	if conexion == null:
		return false
	return conexion.contiene_conexion(casilla, direccion, current_map.map_size)


func cambiar_mapa(nuevo: MapAttributes, _direccion: MapAttributes.ConnectionDirection) -> void:
	if nuevo == null or nuevo == current_map:
		return

	# 1. Calcular la posición nueva MIENTRAS el jugador todavía está en la posición cruzada
	var jugador_global: Vector2 = jugador.global_position
	var jugador_local: Vector2 = nuevo.to_local(jugador_global)

	# 2. Ahora sí cancelar el movimiento (ya no necesitamos la posición vieja)
	if jugador.is_moving:
		# Versión que NO mueve al jugador, solo limpia el estado
		jugador.is_moving = false
		jugador.percent_moved_to_next_tile = 0.0
		jugador.input_direction = Vector2.ZERO
		EventObjects.liberar_reserva(jugador.casilla_reservada)
		jugador.casilla_reservada = jugador.casilla_actual

	_desactivar_mapa_actual()
	current_map = nuevo
	current_map.position = Vector2.ZERO
	current_map.activo = true
	activar_contenido_mapa(current_map)

	# 3. Colocar al jugador en la posición correcta
	jugador.position = jugador.snap_to_grid(jugador_local)

	_setup_jugador_en_mapa(current_map)
	_post_cambio_mapa()

## Warp desde script.
func warp_player_to_section(section_id: int, target_tile: Vector2i) -> bool:
	if jugador == null:
		push_error("MapManager: no hay jugador para ejecutar warp")
		return false

	var target: MapAttributes = mapas_cargados.get(section_id) as MapAttributes
	if target == null:
		var scene_path: String = str(MapSection.SECTION_TO_SCENE.get(section_id, ""))
		if scene_path.is_empty() or not ResourceLoader.exists(scene_path):
			push_error("MapManager: no se encontró escena para section_id %s" % section_id)
			return false
		var escena: PackedScene = load(scene_path) as PackedScene
		if escena == null:
			return false
		target = escena.instantiate() as MapAttributes
		if target == null:
			return false
		mapas_cargados[section_id] = target
		add_child(target)

	_desactivar_mapa_actual()
	current_map = target
	current_map.position = Vector2.ZERO
	current_map.activo = true
	activar_contenido_mapa(current_map)

	# Posicionar jugador en la casilla objetivo
	var tile_size: float = float(current_map.tile_size)
	jugador.position = Vector2(
		float(target_tile.x) * tile_size + tile_size * 0.5,
		float(target_tile.y) * tile_size
	)
	jugador.casilla_actual = target_tile
	jugador.casilla_reservada = target_tile

	_setup_jugador_en_mapa(current_map)
	_post_cambio_mapa()
	return true


# ====================== HELPERS DE CAMBIO DE MAPA ======================

func _desactivar_mapa_actual() -> void:
	if current_map:
		desactivar_contenido_mapa(current_map)


func _setup_jugador_en_mapa(mapa: MapAttributes) -> void:
	jugador.mapa_raiz = mapa
	jugador.map_manager = self
	jugador.buscar_capa_colisiones()
	jugador.sincronizar_con_mapa(mapa, self)
	jugador.actualizar_nivel_suelo(jugador.global_position)


func _post_cambio_mapa() -> void:
	EventObjects.casillas_ocupadas.clear()
	EventObjects.casillas_reservadas.clear()
	EventObjects.registrar_casilla(jugador.casilla_actual, jugador)
	_registrar_personajes_del_mapa(current_map)

	cargar_conexiones()
	_aplicar_entorno_mapa(current_map)

	current_map.trigger_map_scripts(MapScriptEntry.Trigger.ON_TRANSITION)
	current_map.trigger_map_scripts(MapScriptEntry.Trigger.ON_LOAD)
	_avisar_follower_jugador()


func _aplicar_entorno_mapa(mapa: MapAttributes) -> void:
	mapa.activar_musica()
	WeatherManager.set_weather(mapa.weather)
	MapPopUp.mostrar_mapa(mapa)


func _avisar_follower_jugador() -> void:
	if jugador == null:
		return
	var nodo: Node = jugador.get_node_or_null("FollowerMon")
	if nodo is FollowerPokemon:
		(nodo as FollowerPokemon).resetear_seguimiento()


func _registrar_personajes_del_mapa(mapa: MapAttributes) -> void:
	var nodos: Array[Node] = mapa.find_children("*", "CharacterController", true, false)
	for node: Node in nodos:
		var character: CharacterController = node as CharacterController
		if character == null:
			continue
		character.sincronizar_con_mapa(mapa, self)
		EventObjects.registrar_casilla(character.casilla_actual, character)


# ====================== ACTIVAR / DESACTIVAR CONTENIDO ======================

func activar_contenido_mapa(mapa: MapAttributes) -> void:
	for mapa_cargado: MapAttributes in mapas_cargados.values():
		if mapa_cargado != mapa:
			desactivar_contenido_mapa(mapa_cargado)

	var behaviours: Node2D = mapa.get_node_or_null("Behaviours") as Node2D
	if behaviours:
		behaviours.visible = true
		behaviours.process_mode = Node.PROCESS_MODE_INHERIT
		_set_behaviour_layers_active(behaviours, true)

	var eventos: Node = mapa.get_node_or_null("EventObject")
	if eventos:
		eventos.process_mode = Node.PROCESS_MODE_INHERIT
		for hijo: Node in eventos.get_children():
			if hijo is CanvasItem:
				(hijo as CanvasItem).visible = true
			hijo.process_mode = Node.PROCESS_MODE_INHERIT


func desactivar_contenido_mapa(mapa: MapAttributes) -> void:
	mapa.activo = false

	var behaviours: Node2D = mapa.get_node_or_null("Behaviours") as Node2D
	if behaviours:
		behaviours.visible = false
		behaviours.process_mode = Node.PROCESS_MODE_DISABLED
		_set_behaviour_layers_active(behaviours, false)

	var eventos: Node = mapa.get_node_or_null("EventObject")
	if eventos:
		eventos.process_mode = Node.PROCESS_MODE_DISABLED
		for hijo: Node in eventos.get_children():
			if hijo is CanvasItem:
				(hijo as CanvasItem).visible = false
			hijo.process_mode = Node.PROCESS_MODE_DISABLED


func _set_behaviour_layers_active(behaviours: Node, enabled: bool) -> void:
	var layers: Array[Node] = behaviours.find_children("*", "TileMapLayer", true, false)
	for layer_node: Node in layers:
		var layer: TileMapLayer = layer_node as TileMapLayer
		if layer:
			layer.collision_enabled = enabled
			layer.navigation_enabled = enabled


# ====================== CONSULTAS DE TILE ======================

func obtener_mapa_en_global(posicion: Vector2) -> MapAttributes:
	for mapa: MapAttributes in mapas_cargados.values():
		if not mapa.activo:
			continue

		var local: Vector2 = mapa.to_local(posicion)
		var margen: float = float(mapa.border_size * mapa.tile_size)
		var ancho: float = float(mapa.map_size.x * mapa.tile_size)
		var alto: float = float(mapa.map_size.y * mapa.tile_size)

		if (
			local.x >= -margen
			and local.y >= -margen
			and local.x < ancho + margen
			and local.y < alto + margen
		):
			return mapa
	return null


func obtener_tile_data(posicion_global: Vector2) -> TileData:
	var mapa: MapAttributes = obtener_mapa_en_global(posicion_global)
	if mapa == null:
		return null

	var local: Vector2 = mapa.to_local(posicion_global)
	var casilla: Vector2i = Vector2i(
		floori(local.x / float(mapa.tile_size)),
		floori(local.y / float(mapa.tile_size))
	)

	# Dentro del mapa real
	if (
		casilla.x >= 0
		and casilla.x < mapa.map_size.x
		and casilla.y >= 0
		and casilla.y < mapa.map_size.y
	):
		var collisions: TileMapLayer = mapa.get_node_or_null("Behaviours/Collisions") as TileMapLayer
		if collisions:
			return collisions.get_cell_tile_data(casilla)
		return null

	# Fuera → buscar vecino o borde
	return _obtener_tile_data_borde_o_vecino(mapa, casilla, posicion_global)


func _obtener_tile_data_borde_o_vecino(
	mapa: MapAttributes,
	casilla: Vector2i,
	posicion_global: Vector2
) -> TileData:
	var borde: MapAttributes.Border = mapa.obtener_borde(casilla)
	var conexion: MapConnection = mapa.obtener_conexion(borde)

	if conexion == null:
		return mapa.obtener_border_tile_data(casilla)

	var direccion: MapAttributes.ConnectionDirection
	match borde:
		MapAttributes.Border.NORTH:
			direccion = MapAttributes.ConnectionDirection.NORTH
		MapAttributes.Border.SOUTH:
			direccion = MapAttributes.ConnectionDirection.SOUTH
		MapAttributes.Border.EAST:
			direccion = MapAttributes.ConnectionDirection.EAST
		MapAttributes.Border.WEST:
			direccion = MapAttributes.ConnectionDirection.WEST
		_:
			return mapa.obtener_border_tile_data(casilla)

	if not conexion.contiene_conexion(casilla, direccion, mapa.map_size):
		return mapa.obtener_border_tile_data(casilla)

	var vecino: MapAttributes = cargar_conexion(conexion)
	if vecino == null:
		return mapa.obtener_border_tile_data(casilla)

	var pos_vecino: Vector2 = vecino.to_local(posicion_global)
	var tile_vecino: Vector2i = Vector2i(
		floori(pos_vecino.x / float(vecino.tile_size)),
		floori(pos_vecino.y / float(vecino.tile_size))
	)

	var collisions_vecino: TileMapLayer = vecino.get_node_or_null("Behaviours/Collisions") as TileMapLayer
	if collisions_vecino:
		return collisions_vecino.get_cell_tile_data(tile_vecino)

	return mapa.obtener_border_tile_data(casilla)


func obtener_metatile_global(posicion: Vector2) -> int:
	var mapa: MapAttributes = obtener_mapa_en_global(posicion)
	if mapa:
		var local: Vector2 = mapa.to_local(posicion)
		var tile: Vector2i = Vector2i(
			floori(local.x / float(mapa.tile_size)),
			floori(local.y / float(mapa.tile_size))
		)
		return mapa.obtener_metatile(tile)

	# Fallback al mapa actual
	var local_actual: Vector2 = current_map.to_local(posicion)
	var tile_actual: Vector2i = Vector2i(
		floori(local_actual.x / float(current_map.tile_size)),
		floori(local_actual.y / float(current_map.tile_size))
	)
	return current_map.obtener_border_metatile(tile_actual)
