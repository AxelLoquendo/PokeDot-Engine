extends CharacterController

@export var distancia_patrulla: int = 4
@export var tiempo_espera: float = 0.8

var casilla_inicial: Vector2i = Vector2i.ZERO
var yendo_a_derecha: bool = true
var tiempo_espera_restante: float = 0.0

func _ready() -> void:
	super._ready()
	casilla_inicial = casilla_actual

func process_input() -> void:
	var direccion: Vector2 = Vector2.RIGHT if yendo_a_derecha else Vector2.LEFT
	var casilla_destino: Vector2i = casilla_actual + Vector2i(direccion)
	var posicion_destino_global: Vector2 = global_position + direccion * TILE_SIZE
	var limite_max: int = casilla_inicial.x + distancia_patrulla
	
	if tiempo_espera_restante > 0:
		tiempo_espera_restante -= get_process_delta_time()
		is_moving = false
		current_direction = Direction.EAST if yendo_a_derecha else Direction.WEST
		match current_direction:
			Direction.EAST: anim_player.play("idle_right")
			Direction.WEST: anim_player.play("idle_left")
		return
		
	if is_moving: return

	var permitida: bool = casilla_permitida(posicion_destino_global)

	if yendo_a_derecha:
		if casilla_destino.x > limite_max or not permitida:
			yendo_a_derecha = false
			tiempo_espera_restante = tiempo_espera
			return
	else:
		if casilla_destino.x < casilla_inicial.x or not permitida:
			yendo_a_derecha = true
			tiempo_espera_restante = tiempo_espera
			return

	if intentar_mover(direccion):
		is_first_step = not is_first_step
