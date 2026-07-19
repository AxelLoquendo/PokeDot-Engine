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
	if tiempo_espera_restante > 0:
		tiempo_espera_restante -= get_process_delta_time()
		is_moving = false
		current_direction = Direction.EAST if yendo_a_derecha else Direction.WEST
		match current_direction:
			Direction.EAST: anim_player.play("idle_right")
			Direction.WEST: anim_player.play("idle_left")
		return
		
	if is_moving: return

	if yendo_a_derecha:
		if casilla_actual.x >= casilla_inicial.x + distancia_patrulla:
			yendo_a_derecha = false
			tiempo_espera_restante = tiempo_espera
			return
	else:
		if casilla_actual.x <= casilla_inicial.x:
			yendo_a_derecha = true
			tiempo_espera_restante = tiempo_espera
			return

	var direccion: Vector2 = Vector2.RIGHT if yendo_a_derecha else Vector2.LEFT

	if not intentar_mover(direccion):
		return

	is_first_step = not is_first_step
