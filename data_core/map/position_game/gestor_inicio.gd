extends Node

@export var mapa_inicial: PackedScene
@export var casilla_inicio: Vector2i = Vector2i.ZERO

@onready var jugador: CharacterController = $Player

var map_manager: MapManager


func _ready() -> void:
	var datos_guardados: Dictionary = SaveManager.consume_pending_load()
	# Las referencias de ocupación pertenecen a la escena anterior y no deben
	# sobrevivir al cambio de partida/mapa.
	EventObjects.casillas_ocupadas.clear()
	EventObjects.casillas_reservadas.clear()
	var escena_mapa: PackedScene = mapa_inicial
	if not datos_guardados.is_empty():
		var ruta_mapa: String = str(MapSection.SECTION_TO_SCENE.get(int(datos_guardados.get("map_section", 0)), ""))
		if not ruta_mapa.is_empty() and ResourceLoader.exists(ruta_mapa):
			escena_mapa = load(ruta_mapa) as PackedScene
		else:
			push_warning("La partida apunta a un mapa no disponible; se cargará el mapa inicial.")

	if escena_mapa == null:
		push_error("Selecciona un mapa inicial.")
		return

	var mapa: MapAttributes = escena_mapa.instantiate() as MapAttributes

	if mapa == null:
		push_error("La escena inicial no tiene MapAttributes.")
		return

	# Crear gestor de mapas
	map_manager = MapManager.new()
	add_child(map_manager)

	map_manager.jugador = jugador

# Cargar mapa inicial
	map_manager.load_map(mapa)


#	var camara: Camera2D = jugador.get_node_or_null("Camera2D")

#	if camara:
#		map_manager.camara = camara
#		map_manager.actualizar_limites_camara()


# El jugador pertenece al gestor de mapas
	var posicion_global: Vector2 = jugador.global_position
	jugador.reparent(map_manager)
	jugador.global_position = posicion_global


	# Colocar jugador inicial o restaurar su posición guardada.
	if datos_guardados.has("player_position"):
		var posicion_guardada: Variant = datos_guardados.get("player_position", [])
		var posicion: Array = posicion_guardada as Array if posicion_guardada is Array else []
		if posicion.size() >= 2:
			jugador.global_position = Vector2(float(posicion[0]), float(posicion[1]))
	else:
		jugador.global_position = jugador.snap_to_grid(Vector2(casilla_inicio.x * jugador.TILE_SIZE + 8, casilla_inicio.y * jugador.TILE_SIZE))
	var datos_jugador: CharacterPlayer = jugador.character_data as CharacterPlayer
	if datos_jugador and not datos_guardados.is_empty():
		datos_jugador.money = int(datos_guardados.get("player_money", datos_jugador.money))
		var nombre_guardado: String = str(datos_guardados.get("player_name", ""))
		if not nombre_guardado.is_empty():
			datos_jugador.name = nombre_guardado

	var personajes: Array[Node] = map_manager.current_map.find_children(
		"*",
		"CharacterController",
		true,
		false
	)

	personajes.append(jugador)

	for personaje: Node in personajes:

		var controlador: CharacterController = personaje as CharacterController

		if controlador == null:
			continue

		controlador.sincronizar_con_mapa(map_manager.current_map, map_manager)

	jugador.casilla_actual = jugador.posicion_a_casilla(
		jugador.global_position
	)

	EventObjects.registrar_casilla(
		jugador.casilla_actual,
		jugador
	)

	map_manager.current_map.activar_musica()
	map_manager.current_map.trigger_map_scripts(MapScriptEntry.Trigger.ON_LOAD)

	if DnsManager:
		DnsManager.activar()

	if CloudsManager:
		CloudsManager.activar()
