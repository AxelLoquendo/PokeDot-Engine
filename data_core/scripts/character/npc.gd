@tool
extends CharacterController
class_name Npc

var casilla_inicial: Vector2i = Vector2i.ZERO
var yendo_a_derecha: bool = true
var yendo_a_arriba: bool = true
var tiempo_espera_restante: float = 0.0
var datos_npc: CharacterNpc
var en_dialogo: bool = false
var mapa_dueño: MapAttributes
var script_runner: ScriptRunner = null


func _ready() -> void:
	super._ready()
	mapa_dueño = get_parent().get_parent() as MapAttributes
	if mapa_dueño == null:
		push_warning("NPC sin mapa dueño")
		return

	datos_npc = character_data as CharacterNpc
	if not datos_npc:
		push_error("El NPC necesita un recurso CharacterNpc")
		return

	if not Engine.is_editor_hint():
		add_to_group(&"NPC")
		if datos_npc.scripts and script_runner == null:
			script_runner = ScriptRunner.new()
			add_child(script_runner)

	casilla_inicial = casilla_actual
	yendo_a_derecha = datos_npc.direccion_inicial != CharacterNpc.DireccionInicial.IZQUIERDA
	aplicar_direccion_inicial()


func process_input() -> void:
	if not datos_npc:
		return
	if en_dialogo:
		_detener_y_idle()
		return

	match datos_npc.comportamiento:
		CharacterNpc.Comportamiento.QUIETO:
			_detener_y_idle()
		CharacterNpc.Comportamiento.PATRULLA_HORIZONTAL:
			_procesar_patrulla_horizontal()
		CharacterNpc.Comportamiento.PATRULLA_VERTICAL:
			_procesar_patrulla_vertical()
		CharacterNpc.Comportamiento.RANDOM_WALK:
			_procesar_random_walk()
		CharacterNpc.Comportamiento.LOOK_AROUND:
			_procesar_mirar_alrededor()


func _detener_y_idle() -> void:
	is_moving = false
	input_direction = Vector2.ZERO
	reproducir_idle()


func _manejar_espera() -> bool:
	if tiempo_espera_restante <= 0.0:
		return false
	tiempo_espera_restante -= get_process_delta_time()
	_detener_y_idle()
	return true


func _intentar_paso(direccion: Vector2) -> bool:
	if is_moving:
		return false
	if intentar_mover(direccion):
		is_first_step = not is_first_step
		return true
	return false


func _procesar_patrulla_horizontal() -> void:
	if _manejar_espera():
		return

	var direccion: Vector2 = Vector2.RIGHT if yendo_a_derecha else Vector2.LEFT
	var destino: Vector2i = casilla_actual + Vector2i(direccion)
	var pos_global: Vector2 = global_position + direccion * float(TILE_SIZE)
	var max_x: int = casilla_inicial.x + datos_npc.distancia_patrulla
	var min_x: int = casilla_inicial.x - datos_npc.distancia_patrulla
	var permitida: bool = casilla_permitida(pos_global)

	if yendo_a_derecha and (destino.x > max_x or not permitida):
		yendo_a_derecha = false
		tiempo_espera_restante = datos_npc.tiempo_espera
		return
	if not yendo_a_derecha and (destino.x < min_x or not permitida):
		yendo_a_derecha = true
		tiempo_espera_restante = datos_npc.tiempo_espera
		return

	_intentar_paso(direccion)


func _procesar_patrulla_vertical() -> void:
	if _manejar_espera():
		return

	var direccion: Vector2 = Vector2.UP if yendo_a_arriba else Vector2.DOWN
	var destino: Vector2i = casilla_actual + Vector2i(direccion)
	var pos_global: Vector2 = global_position + direccion * float(TILE_SIZE)
	var max_y: int = casilla_inicial.y + datos_npc.distancia_patrulla
	var min_y: int = casilla_inicial.y - datos_npc.distancia_patrulla
	var permitida: bool = casilla_permitida(pos_global)

	if yendo_a_arriba and (destino.y < min_y or not permitida):
		yendo_a_arriba = false
		tiempo_espera_restante = datos_npc.tiempo_espera
		return
	if not yendo_a_arriba and (destino.y > max_y or not permitida):
		yendo_a_arriba = true
		tiempo_espera_restante = datos_npc.tiempo_espera
		return

	_intentar_paso(direccion)


func _procesar_random_walk() -> void:
	if _manejar_espera():
		return
	if is_moving:
		return

	var direcciones: Array[Vector2] = [Vector2.DOWN, Vector2.UP, Vector2.LEFT, Vector2.RIGHT]
	var dir: Vector2 = direcciones.pick_random()
	if casilla_permitida(global_position + dir * float(TILE_SIZE)):
		_intentar_paso(dir)
	tiempo_espera_restante = 1.5


func _procesar_mirar_alrededor() -> void:
	if _manejar_espera():
		return

	const DIRS: Array[Direction] = [Direction.NORTH, Direction.SOUTH, Direction.WEST, Direction.EAST]
	var nueva: Direction = current_direction
	while nueva == current_direction:
		nueva = DIRS.pick_random()
	current_direction = nueva
	reproducir_idle()
	tiempo_espera_restante = 1.0


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


func interact() -> void:
	if datos_npc.scripts and script_runner:
		var player: Node2D = get_tree().get_first_node_in_group("player") as Node2D
		var commands: Array[ScriptCommand] = [datos_npc.scripts]
		script_runner.start_script(commands, self, player, mapa_dueño)


func preparar_dialogo(posicion_jugador: Vector2) -> void:
	en_dialogo = true
	cancelar_movimiento()
	position = snap_to_grid(position)
	mirar_hacia_posicion(posicion_jugador)
	reproducir_idle()


func terminar_dialogo() -> void:
	en_dialogo = false
	tiempo_espera_restante = 0.5
	if script_runner and script_runner.is_running:
		script_runner.on_async_complete()
	reproducir_idle()
