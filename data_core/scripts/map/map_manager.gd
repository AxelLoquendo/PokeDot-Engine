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

func load_map(map: MapAttributes) -> void:
	current_map = map

	mapas_cargados[current_map.map_id_section] = current_map

	add_child(current_map)

	cargar_conexiones()

	WeatherManager.set_weather(current_map.weather)
	MapPopUp.mostrar_mapa(current_map)

func cargar_conexiones() -> void:

	north_map = cargar_conexion(current_map.north_map)
	if north_map:
		colocar_vecino(
			north_map,
			MapAttributes.ConnectionDirection.NORTH,
			current_map.north_map
		)

	south_map = cargar_conexion(current_map.south_map)
	if south_map:
		colocar_vecino(
			south_map,
			MapAttributes.ConnectionDirection.SOUTH,
			current_map.south_map
		)

	east_map = cargar_conexion(current_map.east_map)
	if east_map:
		colocar_vecino(
			east_map,
			MapAttributes.ConnectionDirection.EAST,
			current_map.east_map
		)

	west_map = cargar_conexion(current_map.west_map)
	if west_map:
		colocar_vecino(
			west_map,
			MapAttributes.ConnectionDirection.WEST,
			current_map.west_map
		)

	#actualizar_limites_camara()

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

func actualizar_limites_camara() -> void:

	if camara == null:
		return

	var izquierda: float = 0.0
	var derecha: float = current_map.map_size.x * current_map.tile_size

	var arriba: float = 0.0
	var abajo: float = current_map.map_size.y * current_map.tile_size


	if west_map:
		izquierda = west_map.position.x


	if east_map:
		derecha = max(
			derecha,
			east_map.position.x +
			east_map.map_size.x * east_map.tile_size
		)


	if north_map:
		arriba = north_map.position.y


	if south_map:
		abajo = max(
			abajo,
			south_map.position.y +
			south_map.map_size.y * south_map.tile_size
		)


	var origen: Vector2 = current_map.to_global(
		Vector2(
			izquierda,
			arriba
		)
	)

	camara.limit_left = floori(origen.x)
	camara.limit_top = floori(origen.y)

	camara.limit_right = ceili(current_map.to_global(Vector2(derecha, abajo)).x)

	camara.limit_bottom = ceili(current_map.to_global(Vector2(derecha, abajo)).y)

	camara.limit_smoothed = false

func comprobar_transicion() -> void:

	if jugador == null:
		return

	var local: Vector2 = current_map.to_local(jugador.global_position)

	var ancho: float = current_map.map_size.x * current_map.tile_size
	var alto: float = current_map.map_size.y * current_map.tile_size

	if local.x < 0.0 and west_map:
		cambiar_mapa(west_map, MapAttributes.ConnectionDirection.WEST)
		return

	if local.x >= ancho and east_map:
		cambiar_mapa(east_map, MapAttributes.ConnectionDirection.EAST)
		return

	if local.y < 0.0 and north_map:
		cambiar_mapa(north_map, MapAttributes.ConnectionDirection.NORTH)
		return

	if local.y >= alto and south_map:
		cambiar_mapa(south_map, MapAttributes.ConnectionDirection.SOUTH)
		return

func cambiar_mapa(nuevo: MapAttributes, _direccion: MapAttributes.ConnectionDirection) -> void:

	if nuevo == current_map:
		return

	print("Entrando a:", nuevo.map_name)


	var jugador_global: Vector2 = jugador.global_position


	# Guardar la posición relativa al nuevo mapa antes de moverlo
	var jugador_local: Vector2 = nuevo.to_local(jugador_global)


	current_map = nuevo

	# El mapa activo siempre está en el origen
	current_map.position = Vector2.ZERO
	current_map.activo = true
	activar_contenido_mapa(current_map)

	# Recalcular posición del jugador
	jugador.position = jugador_local


	print(
		"Jugador local nuevo mapa:",
		jugador_local
	)


	jugador.mapa_raiz = current_map
	jugador.map_manager = self
	jugador.buscar_capa_colisiones()
	jugador.sincronizar_con_mapa(current_map, self)


	cargar_conexiones()
	EventObjects.casillas_ocupadas.clear()
	EventObjects.casillas_reservadas.clear()
	EventObjects.registrar_casilla(jugador.casilla_actual, jugador)
	_registrar_personajes_del_mapa(current_map)

#	actualizar_limites_camara()

	current_map.activar_musica()
	WeatherManager.set_weather(current_map.weather)
	MapPopUp.mostrar_mapa(current_map)
	current_map.trigger_map_scripts(MapScriptEntry.Trigger.ON_TRANSITION)
	current_map.trigger_map_scripts(MapScriptEntry.Trigger.ON_LOAD)


## Warp de script: solo mueve al jugador a una sección de mapa concreta.
func warp_player_to_section(section_id: int, target_tile: Vector2i) -> bool:
	if jugador == null:
		push_error("MapManager: no hay jugador para ejecutar warp")
		return false
	var target: MapAttributes = mapas_cargados.get(section_id, null) as MapAttributes
	if target == null:
		var scene_path: String = str(MapSection.SECTION_TO_SCENE.get(section_id, ""))
		if scene_path.is_empty() or not ResourceLoader.exists(scene_path):
			push_error("MapManager: MAPSEC inválido o sin escena: %s" % str(section_id))
			return false
		var packed_map: PackedScene = load(scene_path) as PackedScene
		target = packed_map.instantiate() as MapAttributes if packed_map else null
		if target == null:
			push_error("MapManager: no se pudo crear el mapa de destino")
			return false
		mapas_cargados[target.map_id_section] = target
		add_child(target)

	# El warp no es una conexión de mapas: el anterior deja de participar por
	# completo en físicas, TileBehaviours y eventos antes de activar el destino.
	var previous_map: MapAttributes = current_map
	if previous_map and previous_map != target:
		desactivar_contenido_mapa(previous_map)
		previous_map.visible = false

	if jugador is CharacterController: # o el tipo real de tu player
		var f: FollowerPokemon = jugador.get_node_or_null("FollowerMon") as FollowerPokemon
		if f:
			f.resetear_seguimiento()

	current_map = target
	current_map.position = Vector2.ZERO
	current_map.activo = true
	activar_contenido_mapa(current_map)
	jugador.global_position = current_map.to_global(Vector2(target_tile.x * current_map.tile_size + 8, target_tile.y * current_map.tile_size))
	jugador.mapa_raiz = current_map
	jugador.map_manager = self
	jugador.buscar_capa_colisiones()
	jugador.casilla_actual = jugador.posicion_a_casilla(jugador.global_position)
	# Lee los custom data layers del tile de llegada después de reiniciar el
	# estado. Así floor_lvl/floor_transition del mapa anterior no sobreviven.
	jugador.actualizar_nivel_suelo(jugador.global_position)
	jugador.sincronizar_con_mapa(current_map, self)
	EventObjects.casillas_ocupadas.clear()
	EventObjects.casillas_reservadas.clear()
	EventObjects.registrar_casilla(jugador.casilla_actual, jugador)
	_registrar_personajes_del_mapa(current_map)
	cargar_conexiones()
	current_map.activar_musica()
	WeatherManager.set_weather(current_map.weather)
	MapPopUp.mostrar_mapa(current_map)
	current_map.trigger_map_scripts(MapScriptEntry.Trigger.ON_TRANSITION)
	current_map.trigger_map_scripts(MapScriptEntry.Trigger.ON_LOAD)
	return true

func colocar_vecino(
	mapa: MapAttributes,
	direccion: MapAttributes.ConnectionDirection,
	conexion: MapConnection
) -> void:

	if mapa == current_map:
		return

	mapa.position = current_map.obtener_posicion_conexion(
		direccion,
		conexion
	)

	mapa.visible = true

	# Los vecinos nunca tienen contenido activo
	desactivar_contenido_mapa(mapa)

	print(
		"Vecino colocado:",
		mapa.map_name,
		" pos:",
		mapa.position
	)

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
				var visible_hijo: CanvasItem = hijo as CanvasItem
				visible_hijo.visible = true

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
				var visible_hijo: CanvasItem = hijo as CanvasItem
				visible_hijo.visible = false

			hijo.process_mode = Node.PROCESS_MODE_DISABLED


## Las TileMapLayer mantienen sus colisiones aunque no se vean. Este helper
## impide que un mapa dejado atrás por un warp bloquee al jugador.
func _set_behaviour_layers_active(behaviours: Node, enabled: bool) -> void:
	for layer: TileMapLayer in behaviours.find_children("*", "TileMapLayer", true, false):
		layer.collision_enabled = enabled
		layer.navigation_enabled = enabled


func _registrar_personajes_del_mapa(mapa: MapAttributes) -> void:
	for node: Node in mapa.find_children("*", "CharacterController", true, false):
		var character: CharacterController = node as CharacterController
		if character == null:
			continue
		character.sincronizar_con_mapa(mapa, self)
		EventObjects.registrar_casilla(character.casilla_actual, character)

func obtener_mapa_en_global(posicion: Vector2) -> MapAttributes:

	for mapa: MapAttributes in mapas_cargados.values():
		# Los mapas mantenidos en memoria tras un warp no forman parte del
		# mundo actual y no deben aportar colisiones ni tile behaviours.
		if not mapa.activo:
			continue

		var local: Vector2 = mapa.to_local(posicion)

		var margen: float = mapa.border_size * mapa.tile_size

		var ancho: float = mapa.map_size.x * mapa.tile_size
		var alto: float = mapa.map_size.y * mapa.tile_size


		if (
			local.x >= -margen
			and local.y >= -margen
			and local.x < ancho + margen
			and local.y < alto + margen
		):
			return mapa

	return null

func obtener_metatile_global(posicion: Vector2) -> int:

	var mapa: MapAttributes = obtener_mapa_en_global(posicion)

	if mapa:

		var local: Vector2 = mapa.to_local(posicion)

		var tile: Vector2i = Vector2i(
			floor(local.x / mapa.tile_size),
			floor(local.y / mapa.tile_size)
		)

		return mapa.obtener_metatile(tile)

	# Ningún mapa contiene esa posición

	var local_actual: Vector2 = current_map.to_local(posicion)

	var tile_actual: Vector2i = Vector2i(
		floor(local_actual.x / current_map.tile_size),
		floor(local_actual.y / current_map.tile_size)
	)

	return current_map.obtener_border_metatile(tile_actual)

func obtener_tile_data(posicion_global: Vector2) -> TileData:

	var mapa: MapAttributes = obtener_mapa_en_global(posicion_global)

	if mapa == null:
		return null


	var local: Vector2 = mapa.to_local(posicion_global)


	var casilla: Vector2i = Vector2i(
		floori(local.x / mapa.tile_size),
		floori(local.y / mapa.tile_size)
	)


	# Dentro del mapa real
	if (
		casilla.x >= 0
		and casilla.x < mapa.map_size.x
		and casilla.y >= 0
		and casilla.y < mapa.map_size.y
	):

		var collisions: TileMapLayer = mapa.get_node_or_null(
			"Behaviours/Collisions"
		) as TileMapLayer


		if collisions == null:
			return null


		return collisions.get_cell_tile_data(casilla)



	# Fuera del mapa real:
	# buscar vecino


	var borde: MapAttributes.Border = mapa.obtener_borde(casilla)

	var conexion: MapConnection = mapa.obtener_conexion(borde)

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


	if conexion:

		if conexion.contiene_conexion(casilla, direccion, mapa.map_size):

			var vecino: MapAttributes = cargar_conexion(conexion)

			if vecino:

				var posicion_vecino: Vector2 = vecino.to_local(posicion_global)

				var tile_vecino: Vector2i = Vector2i(floori(posicion_vecino.x / vecino.tile_size), floori(posicion_vecino.y / vecino.tile_size))

				var collisions_vecino: TileMapLayer = vecino.get_node_or_null("Behaviours/Collisions") as TileMapLayer

				if collisions_vecino:
					return collisions_vecino.get_cell_tile_data(tile_vecino)

	# Si no existe conexión:
	return mapa.obtener_border_tile_data(casilla)
