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

	actualizar_limites_camara()

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


	cargar_conexiones()

	actualizar_limites_camara()

	current_map.activar_musica()

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


	var eventos: Node = mapa.get_node_or_null("EventObject")

	if eventos:

		eventos.process_mode = Node.PROCESS_MODE_INHERIT

		for hijo: Node in eventos.get_children():

			if hijo is CanvasItem:
				var visible_hijo: CanvasItem = hijo as CanvasItem
				visible_hijo.visible = true

			hijo.process_mode = Node.PROCESS_MODE_INHERIT

func desactivar_contenido_mapa(mapa: MapAttributes) -> void:

	var eventos: Node = mapa.get_node_or_null("EventObject")

	if eventos:

		eventos.process_mode = Node.PROCESS_MODE_DISABLED

		for hijo: Node in eventos.get_children():

			if hijo is CanvasItem:
				var visible_hijo: CanvasItem = hijo as CanvasItem
				visible_hijo.visible = false

			hijo.process_mode = Node.PROCESS_MODE_DISABLED
