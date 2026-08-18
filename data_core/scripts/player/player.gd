@tool
extends CharacterController

const VELOCIDAD_ANIM_BLOQUEO: float = 0.4
const TIEMPO_MINIMO_PARA_CAMINAR: float = 0.09

# ----------------
@export var start_menu: CanvasLayer
@export var trainer_card: CanvasLayer
# ----------------

var tiempo_paso_bloqueo: float = 0.0
var direccion_pendiente: Vector2 = Vector2.ZERO
var tiempo_direccion_pendiente: float = 0.0
var corriendo_en_paso: bool = false


func _ready() -> void:
	super._ready()
	add_to_group(&"player")

func obtener_velocidad_movimiento() -> float:
	if corriendo_en_paso:
		return character_data.running_speed

	return character_data.walk_speed

func process_input() -> void:  
	if start_menu and start_menu.is_open or trainer_card and trainer_card.is_open:
		input_direction = Vector2.ZERO  
		is_moving = false 
		reproducir_idle() 
		return

	if DialogueBox.activo:
		direccion_pendiente = Vector2.ZERO
		tiempo_direccion_pendiente = 0.0
		tiempo_paso_bloqueo = 0.0

		is_moving = false
		input_direction = Vector2.ZERO
		anim_player.speed_scale = 1.0
		reproducir_idle()
		return

	var direccion_deseada: Vector2 = obtener_direccion_deseada()

	if direccion_deseada == Vector2.ZERO:
		direccion_pendiente = Vector2.ZERO
		tiempo_direccion_pendiente = 0.0
		tiempo_paso_bloqueo = 0.0
		anim_player.speed_scale = 1.0
		reproducir_idle()
		return

	if direccion_deseada != direccion_pendiente:
		direccion_pendiente = direccion_deseada
		tiempo_direccion_pendiente = 0.0
		tiempo_paso_bloqueo = 0.0
		anim_player.speed_scale = 1.0
		mirar_hacia(direccion_pendiente)
		return

	tiempo_direccion_pendiente += get_physics_process_delta_time()

	if tiempo_direccion_pendiente < TIEMPO_MINIMO_PARA_CAMINAR:
		return

	if intentar_mover(direccion_pendiente):
		corriendo_en_paso = Input.is_action_pressed("buttonB")
		anim_player.speed_scale = 1.0
		reproducir_paso()
		is_first_step = not is_first_step
		tiempo_paso_bloqueo = 0.0
		return

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



func obtener_direccion_deseada() -> Vector2:
	# La última tecla pulsada siempre tiene prioridad.
	if Input.is_action_just_pressed("Up"):
		return Vector2.UP
	if Input.is_action_just_pressed("Down"):
		return Vector2.DOWN
	if Input.is_action_just_pressed("Left"):
		return Vector2.LEFT
	if Input.is_action_just_pressed("Right"):
		return Vector2.RIGHT

	if direccion_pendiente != Vector2.ZERO and direccion_sigue_presionada(direccion_pendiente):
		return direccion_pendiente

	if Input.is_action_pressed("Up"):
		return Vector2.UP
	if Input.is_action_pressed("Down"):
		return Vector2.DOWN
	if Input.is_action_pressed("Left"):
		return Vector2.LEFT
	if Input.is_action_pressed("Right"):
		return Vector2.RIGHT

	return Vector2.ZERO

func direccion_sigue_presionada(direccion: Vector2) -> bool:
	match direccion:
		Vector2.UP:
			return Input.is_action_pressed("Up")
		Vector2.DOWN:
			return Input.is_action_pressed("Down")
		Vector2.LEFT:
			return Input.is_action_pressed("Left")
		Vector2.RIGHT:
			return Input.is_action_pressed("Right")

	return false

func reproducir_paso() -> void:
	if not anim_player:
		return

	if not corriendo_en_paso:
		super.reproducir_paso()
		return

	var prefijo: String = "first_run_" if is_first_step else "second_run_"

	match input_direction:
		Vector2.UP:
			current_direction = Direction.NORTH
			anim_player.play(prefijo + "up")
		Vector2.DOWN:
			current_direction = Direction.SOUTH
			anim_player.play(prefijo + "down")
		Vector2.RIGHT:
			current_direction = Direction.EAST
			anim_player.play(prefijo + "right")
		Vector2.LEFT:
			current_direction = Direction.WEST
			anim_player.play(prefijo + "left")

func obtener_casilla_frontal() -> Vector2i:
	match current_direction:
		Direction.NORTH:
			return casilla_actual + Vector2i.UP
		Direction.SOUTH:
			return casilla_actual + Vector2i.DOWN
		Direction.WEST:
			return casilla_actual + Vector2i.LEFT
		Direction.EAST:
			return casilla_actual + Vector2i.RIGHT

	return casilla_actual

func _unhandled_input(event: InputEvent) -> void:
	if start_menu and start_menu.is_open:
		return

	if DialogueBox.activo:
		return

	if event.is_action_pressed("buttonA"):
		var personaje: CharacterController = EventObjects.obtener_personaje_en_casilla(obtener_casilla_frontal())

		if personaje == null:
			return

		if personaje.character_data is CharacterNpc:
			var npc: CharacterController = personaje

			if npc.has_method("interact"):
				cancelar_movimiento()
				npc.interact()
				get_viewport().set_input_as_handled()
				return
	if Input.is_action_just_pressed("buttonStart"):
		if start_menu and start_menu.has_method("toggle_menu"):
			start_menu.toggle_menu()
			get_viewport().set_input_as_handled()
