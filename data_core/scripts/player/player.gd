extends CharacterController

const VELOCIDAD_ANIM_BLOQUEO: float = 0.4
var tiempo_paso_bloqueo: float = 0.0


func process_input() -> void:
	var direccion_deseada: Vector2 = Vector2.ZERO
	if Input.is_action_pressed("Up"):
		direccion_deseada.y = -1
	elif Input.is_action_pressed("Down"):
		direccion_deseada.y = 1
	elif Input.is_action_pressed("Left"):
		direccion_deseada.x = -1
	elif Input.is_action_pressed("Right"):
		direccion_deseada.x = 1

	if direccion_deseada != Vector2.ZERO and !is_moving:
		if intentar_mover(direccion_deseada):
			# Movimiento normal: velocidad completa
			anim_player.speed_scale = 1.0
			if is_first_step:
				match direccion_deseada:
					Vector2(0, -1):
						current_direction = Direction.NORTH
						anim_player.play("first_step_up")
					Vector2(0, 1):
						current_direction = Direction.SOUTH
						anim_player.play("first_step_down")
					Vector2(1, 0):
						current_direction = Direction.EAST
						anim_player.play("first_step_right")
					Vector2(-1, 0):
						current_direction = Direction.WEST
						anim_player.play("first_step_left")
			else:
				match direccion_deseada:
					Vector2(0, -1):
						current_direction = Direction.NORTH
						anim_player.play("second_step_up")
					Vector2(0, 1):
						current_direction = Direction.SOUTH
						anim_player.play("second_step_down")
					Vector2(1, 0):
						current_direction = Direction.EAST
						anim_player.play("second_step_right")
					Vector2(-1, 0):
						current_direction = Direction.WEST
						anim_player.play("second_step_left")
			is_first_step = not is_first_step

		else:
			match direccion_deseada:
				Vector2(0, -1): current_direction = Direction.NORTH
				Vector2(0, 1): current_direction = Direction.SOUTH
				Vector2(1, 0): current_direction = Direction.EAST
				Vector2(-1, 0): current_direction = Direction.WEST

			tiempo_paso_bloqueo += get_process_delta_time()
			var duracion_paso: float = 1.0 / (VELOCIDAD_ANIM_BLOQUEO * 2.0)

			if tiempo_paso_bloqueo >= duracion_paso:
				tiempo_paso_bloqueo = 0.0
				is_first_step = not is_first_step

			anim_player.speed_scale = VELOCIDAD_ANIM_BLOQUEO
			if is_first_step:
				match current_direction:
					Direction.NORTH: anim_player.play("first_step_up")
					Direction.SOUTH: anim_player.play("first_step_down")
					Direction.EAST: anim_player.play("first_step_right")
					Direction.WEST: anim_player.play("first_step_left")
			else:
				match current_direction:
					Direction.NORTH: anim_player.play("second_step_up")
					Direction.SOUTH: anim_player.play("second_step_down")
					Direction.EAST: anim_player.play("second_step_right")
					Direction.WEST: anim_player.play("second_step_left")

	else:
		is_moving = false
		anim_player.speed_scale = 1.0
		match current_direction:
			Direction.NORTH: anim_player.play("idle_up")
			Direction.SOUTH: anim_player.play("idle_down")
			Direction.EAST: anim_player.play("idle_right")
			Direction.WEST: anim_player.play("idle_left")
