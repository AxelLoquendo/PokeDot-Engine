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
	
	if jugador.get_parent():
		jugador.get_parent().remove_child(jugador)
	mapa_nodo.add_child(jugador)
	
	jugador.position = Vector2(
		casilla_inicio.x * jugador.TILE_SIZE + 8,
		casilla_inicio.y * jugador.TILE_SIZE
	)
	
	jugador.position = jugador.snap_to_grid(jugador.position)

	jugador.casilla_actual = casilla_inicio
	EventObjects.registrar_casilla(casilla_inicio, jugador)
	
	print("Jugador en casilla: ", casilla_inicio, " | Posición: ", jugador.position)
	if DnsManager and DnsManager.has_method("activar"):
		DnsManager.activar()  # Quitamos el "return" de aquí
