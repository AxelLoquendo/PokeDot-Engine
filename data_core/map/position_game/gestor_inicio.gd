extends Node

@export var mapa_inicial: PackedScene
@export var casilla_inicio: Vector2i = Vector2i.ZERO

@onready var jugador: CharacterController = $Player

var map_manager: MapManager


func _ready() -> void:

	if mapa_inicial == null:
		push_error("Selecciona un mapa inicial.")
		return

	var mapa: MapAttributes = mapa_inicial.instantiate() as MapAttributes

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


# Colocar jugador inicial
	jugador.global_position = jugador.snap_to_grid(
		Vector2(
		casilla_inicio.x * jugador.TILE_SIZE + 8,
		casilla_inicio.y * jugador.TILE_SIZE
	)
)

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

		controlador.mapa_raiz = map_manager.current_map
		controlador.map_manager = map_manager
		controlador.buscar_capa_colisiones()

	jugador.casilla_actual = jugador.posicion_a_casilla(
		jugador.global_position
	)

	EventObjects.registrar_casilla(
		jugador.casilla_actual,
		jugador
	)

	map_manager.current_map.activar_musica()

	if DnsManager and DnsManager.has_method("activar"):
		DnsManager.activar()
