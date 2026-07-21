extends CharacterController

const VELOCIDAD_ANIM_BLOQUEO: float = 0.4
const TIEMPO_MINIMO_PARA_CAMINAR: float = 0.10

var tiempo_paso_bloqueo: float = 0.0
var direccion_pendiente: Vector2 = Vector2.ZERO
var tiempo_direccion_pendiente: float = 0.0


func process_input() -> void:
	var direccion_deseada: Vector2 = Vector2.ZERO

	if Input.is_action_pressed("Up"):
		direccion_deseada = Vector2.UP
	elif Input.is_action_pressed("Down"):
		direccion_deseada = Vector2.DOWN
	elif Input.is_action_pressed("Left"):
		direccion_deseada = Vector2.LEFT
	elif Input.is_action_pressed("Right"):
		direccion_deseada = Vector2.RIGHT

	# No hay tecla pulsada: permanece mirando hacia la última dirección.
	if direccion_deseada == Vector2.ZERO:
		direccion_pendiente = Vector2.ZERO
		tiempo_direccion_pendiente = 0.0
		tiempo_paso_bloqueo = 0.0
		anim_player.speed_scale = 1.0
		reproducir_idle()
		return

	# Primera pulsación o cambio de dirección: solo gira.
	if direccion_deseada != direccion_pendiente:
		direccion_pendiente = direccion_deseada
		tiempo_direccion_pendiente = 0.0
		tiempo_paso_bloqueo = 0.0
		anim_player.speed_scale = 1.0
		mirar_hacia(direccion_pendiente)
		return

	# Solo camina si se mantiene pulsada la dirección un instante.
	tiempo_direccion_pendiente += get_physics_process_delta_time()

	if tiempo_direccion_pendiente < TIEMPO_MINIMO_PARA_CAMINAR:
		return

	# Movimiento normal.
	if intentar_mover(direccion_pendiente):
		anim_player.speed_scale = 1.0
		reproducir_paso()
		is_first_step = not is_first_step
		tiempo_paso_bloqueo = 0.0
		return

	# Se mantiene una tecla contra una casilla bloqueada.
	tiempo_paso_bloqueo += get_physics_process_delta_time()

	var duracion_paso: float = 1.0 / (VELOCIDAD_ANIM_BLOQUEO * 2.0)

	if tiempo_paso_bloqueo >= duracion_paso:
		tiempo_paso_bloqueo = 0.0
		is_first_step = not is_first_step

	anim_player.speed_scale = VELOCIDAD_ANIM_BLOQUEO
	reproducir_paso()


func mirar_hacia(direccion: Vector2) -> void:
	match direccion:
		Vector2.UP:
			current_direction = Direction.NORTH
		Vector2.DOWN:
			current_direction = Direction.SOUTH
		Vector2.RIGHT:
			current_direction = Direction.EAST
		Vector2.LEFT:
			current_direction = Direction.WEST

	reproducir_idle()


func reproducir_idle() -> void:
	match current_direction:
		Direction.NORTH:
			anim_player.play("idle_up")
		Direction.SOUTH:
			anim_player.play("idle_down")
		Direction.EAST:
			anim_player.play("idle_right")
		Direction.WEST:
			anim_player.play("idle_left")


func reproducir_paso() -> void:
	if is_first_step:
		match current_direction:
			Direction.NORTH:
				anim_player.play("first_step_up")
			Direction.SOUTH:
				anim_player.play("first_step_down")
			Direction.EAST:
				anim_player.play("first_step_right")
			Direction.WEST:
				anim_player.play("first_step_left")
	else:
		match current_direction:
			Direction.NORTH:
				anim_player.play("second_step_up")
			Direction.SOUTH:
				anim_player.play("second_step_down")
			Direction.EAST:
				anim_player.play("second_step_right")
			Direction.WEST:
				anim_player.play("second_step_left")
