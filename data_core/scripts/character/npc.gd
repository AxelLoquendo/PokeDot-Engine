@tool
extends CharacterController

var casilla_inicial: Vector2i = Vector2i.ZERO
var yendo_a_derecha: bool = true
var yendo_a_arriba: bool = true
var tiempo_espera_restante: float = 0.0
var datos_npc: CharacterNpc
var en_dialogo: bool = false

func _ready() -> void:
	super._ready()

	datos_npc = character_data as CharacterNpc
	if not datos_npc:
		push_error("El NPC necesita un recurso CharacterNpc en character_data")
		return

	add_to_group(&"NPC")
	casilla_inicial = casilla_actual
	yendo_a_derecha = datos_npc.direccion_inicial != CharacterNpc.DireccionInicial.IZQUIERDA
	aplicar_direccion_inicial()

func process_input() -> void:
	if not datos_npc:
		return

	if en_dialogo:
		is_moving = false
		input_direction = Vector2.ZERO
		reproducir_idle()
		return

	match datos_npc.comportamiento:
		CharacterNpc.Comportamiento.QUIETO:
			is_moving = false
			reproducir_idle()
			return
		CharacterNpc.Comportamiento.PATRULLA_HORIZONTAL:
			procesar_patrulla_horizontal()
		CharacterNpc.Comportamiento.PATRULLA_VERTICAL:
			procesar_patrulla_vertical()
		CharacterNpc.Comportamiento.RANDOM_WALK:
			procesar_random_walk()
		CharacterNpc.Comportamiento.LOOK_AROUND:
			procesar_mirar_alrededor()

func _process_input() -> void:
	if not datos_npc:
		return

	if en_dialogo:
		is_moving = false
		input_direction = Vector2.ZERO
		reproducir_idle()
		return

	match datos_npc.comportamiento:
		CharacterNpc.Comportamiento.QUIETO:
			is_moving = false
			reproducir_idle()
			return
		CharacterNpc.Comportamiento.PATRULLA_HORIZONTAL:
			procesar_patrulla_horizontal()
		CharacterNpc.Comportamiento.PATRULLA_VERTICAL:
			procesar_patrulla_vertical()
		CharacterNpc.Comportamiento.RANDOM_WALK:
			procesar_random_walk()
		CharacterNpc.Comportamiento.LOOK_AROUND:
			procesar_mirar_alrededor()


# inicio proceso de comportamientos
func procesar_patrulla_horizontal() -> void:
	var direccion: Vector2 = Vector2.RIGHT if yendo_a_derecha else Vector2.LEFT
	var casilla_destino: Vector2i = casilla_actual + Vector2i(direccion)
	var posicion_destino_global: Vector2 = global_position + direccion * TILE_SIZE
	var limite_max: int = casilla_inicial.x + datos_npc.distancia_patrulla
	var _limite_min: int = casilla_inicial.x - datos_npc.distancia_patrulla

	if tiempo_espera_restante > 0:
		tiempo_espera_restante -= get_process_delta_time()
		is_moving = false
		current_direction = Direction.EAST if yendo_a_derecha else Direction.WEST
		reproducir_idle()
		return
		
	if is_moving: return

	var permitida: bool = casilla_permitida(posicion_destino_global)

	if yendo_a_derecha:
		if casilla_destino.x > limite_max or not permitida:
			yendo_a_derecha = false
			tiempo_espera_restante = datos_npc.tiempo_espera
			return
	else:
		if casilla_destino.x < _limite_min or not permitida:
			yendo_a_derecha = true
			tiempo_espera_restante = datos_npc.tiempo_espera
			return

	if intentar_mover(direccion):
		is_first_step = not is_first_step

func procesar_patrulla_vertical() -> void:
	var direccion: Vector2 = Vector2.UP if yendo_a_arriba else Vector2.DOWN
	var casilla_destino: Vector2i = casilla_actual + Vector2i(direccion)
	var posicion_destino_global: Vector2 = global_position + direccion * TILE_SIZE
	var limite_max: int = casilla_inicial.y + datos_npc.distancia_patrulla
	var _limite_min: int = casilla_inicial.y - datos_npc.distancia_patrulla
	if tiempo_espera_restante > 0:
		tiempo_espera_restante -= get_process_delta_time()
		is_moving = false
		current_direction = Direction.NORTH if yendo_a_arriba else Direction.SOUTH
		reproducir_idle()
		return
		
	if is_moving: return

	var permitida: bool = casilla_permitida(posicion_destino_global)

	if yendo_a_arriba:
		if casilla_destino.y < _limite_min or not permitida:
			yendo_a_arriba = false
			tiempo_espera_restante = datos_npc.tiempo_espera
			return
	else:
		if casilla_destino.y > limite_max or not permitida:
			yendo_a_arriba = true
			tiempo_espera_restante = datos_npc.tiempo_espera
			return

	if intentar_mover(direccion):
		is_first_step = not is_first_step

func procesar_random_walk() -> void:
	if tiempo_espera_restante > 0:
		tiempo_espera_restante -= get_process_delta_time()
		reproducir_idle()
		return
	
	if is_moving:
		return
	
	var _direcciones: Array[Vector2] = [
		Vector2.DOWN,
		Vector2.UP,
		Vector2i.LEFT,
		Vector2.RIGHT,
	]
	var _direccion: Vector2 = _direcciones.pick_random()
	var _posicion_destino: Vector2 = global_position + _direccion * TILE_SIZE
	if casilla_permitida(_posicion_destino):
		intentar_mover(_direccion)
	tiempo_espera_restante = 1.5

func procesar_mirar_alrededor() -> void:
	if tiempo_espera_restante > 0:
		tiempo_espera_restante -= get_process_delta_time()
		reproducir_idle()
		return
	const DIRECCIONES: Array[Direction] = [
		Direction.NORTH,
		Direction.SOUTH,
		Direction.WEST,
		Direction.EAST
	]
	var direccion: Direction = current_direction
	while direccion == current_direction:
		direccion = DIRECCIONES.pick_random()
	current_direction = direccion
	reproducir_idle()
	tiempo_espera_restante = 1.0
# fin proceso de comportamientos

func aplicar_direccion_inicial() -> void:
	match datos_npc.direccion_inicial:
		CharacterNpc.DireccionInicial.ABAJO:
			current_direction = Direction.SOUTH
		CharacterNpc.DireccionInicial.ARRIBA:
			current_direction = Direction.NORTH
		CharacterNpc.DireccionInicial.IZQUIERDA:
			current_direction = Direction.WEST
		CharacterNpc.DireccionInicial.DERECHA:
			current_direction = Direction.EAST

	reproducir_idle()


func reproducir_idle() -> void:
	if not anim_player:
		return

	match current_direction:
		Direction.NORTH:
			anim_player.play("idle_up")
		Direction.SOUTH:
			anim_player.play("idle_down")
		Direction.EAST:
			anim_player.play("idle_right")
		Direction.WEST:
			anim_player.play("idle_left")

func interact() -> void:
	DialogueManager.start_dialogue(character_data)

func preparar_dialogo(posicion_jugador: Vector2) -> void:
	en_dialogo = true

	cancelar_movimiento()
	position = snap_to_grid(position)
	mirar_hacia_posicion(posicion_jugador)
	reproducir_idle()

func terminar_dialogo() -> void:
	en_dialogo = false
	tiempo_espera_restante = 0.5
	
	reproducir_idle()
