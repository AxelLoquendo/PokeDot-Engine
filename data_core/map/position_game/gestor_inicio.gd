extends Node
@export var mapa_inicial: PackedScene = null
@export var casilla_inicio: Vector2i = Vector2i(0, 0)
@onready var jugador: CharacterController = $Player
var mapa_nodo: Node

func _ready() -> void:
	if not mapa_inicial:
		push_error("Selecciona el mapa inicial en el Inspector")
		return
	
	mapa_nodo = mapa_inicial.instantiate()
	add_child(mapa_nodo)

	jugador.reparent(mapa_nodo)
	jugador.position = jugador.snap_to_grid(Vector2(
	casilla_inicio.x * jugador.TILE_SIZE + 8,
	casilla_inicio.y * jugador.TILE_SIZE
	))

	var personajes: Array[Node] = mapa_nodo.find_children(
		"*", "CharacterController", true, false
	)

	personajes.append(jugador)

	for personaje: Node in personajes:
		var controlador: CharacterController = personaje as CharacterController
		if controlador:
			controlador.mapa_raiz = mapa_nodo
			controlador.buscar_capa_colisiones()

	jugador.casilla_actual = jugador.posicion_a_casilla(jugador.global_position)
	EventObjects.registrar_casilla(jugador.casilla_actual, jugador)
	if DnsManager and DnsManager.has_method("activar"):
		DnsManager.activar()
