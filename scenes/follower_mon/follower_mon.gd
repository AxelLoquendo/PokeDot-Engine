extends Node2D
class_name FollowerPokemon

## Pokémon acompañante: sigue al jugador con 1 casilla de retraso.
## Usa overworld_scene (Texture2D) del primer mon del party que lo tenga.

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

var jugador: CharacterController = null
var activo: bool = false

## Desfase visual del sprite (píxeles). Ajusta si flota o se hunde.
@export var sprite_offset: Vector2 = Vector2(0, -8)

var tween_mov: Tween = null
var alternar_paso: bool = false
var idle_actual: String = "idle_down"


func setup(p_jugador: CharacterController) -> void:
	jugador = p_jugador

	if (jugador and not jugador.paso_completado.is_connected(_on_jugador_paso)):
		jugador.paso_completado.connect(_on_jugador_paso)

	refrescar_desde_party()



func _exit_tree() -> void:
	if jugador and is_instance_valid(jugador):
		if jugador.paso_completado.is_connected(_on_jugador_paso):
			jugador.paso_completado.disconnect(_on_jugador_paso)


func refrescar_desde_party() -> void:
	activo = false
	visible = false
	_limpiar_anim()

	if jugador == null:
		return

	var data: CharacterPlayer = jugador.character_data as CharacterPlayer
	if data == null:
		return

	var mon: PokemonInstance = _elegir_mon(data.party)
	if mon == null:
		return

	if anim == null or anim.sprite_frames == null:
		return

	anim.offset = sprite_offset

	activo = true
	visible = true
	_sincronizar_posicion_inicial()


func _elegir_mon(party: Array[PokemonInstance]) -> PokemonInstance:
	for mon: PokemonInstance in party:
		if mon == null:
			continue
		var sp: PokemonDataStruct = mon.get_species()
		if sp != null and sp.overworld_scene != null:
			return mon
	return null

func _limpiar_anim() -> void:
	if anim == null:
		return

	anim.stop()



func _sincronizar_posicion_inicial() -> void:
	if jugador == null or not activo:
		return

	if tween_mov and tween_mov.is_valid():
		tween_mov.kill()

	var direccion_atras: Vector2i = (
		_vector_direccion(jugador.current_direction)
	)

	var casilla_detras: Vector2i = (
		jugador.casilla_actual - direccion_atras
	)

	global_position = _casilla_a_global(casilla_detras)

	idle_actual = _obtener_idle(
		Vector2(direccion_atras)
	)

	if anim and anim.sprite_frames:
		if anim.sprite_frames.has_animation(idle_actual):
			anim.play(idle_actual)

func _vector_direccion(direccion: CharacterController.Direction) -> Vector2i:
	match direccion:
		CharacterController.Direction.NORTH:
			return Vector2i.UP

		CharacterController.Direction.SOUTH:
			return Vector2i.DOWN

		CharacterController.Direction.EAST:
			return Vector2i.RIGHT

		CharacterController.Direction.WEST:
			return Vector2i.LEFT

	return Vector2i.DOWN

func _obtener_idle(direccion: Vector2) -> String:
	if direccion.y < 0.0:
		return "idle_up"

	if direccion.y > 0.0:
		return "idle_down"

	if direccion.x < 0.0:
		return "idle_left"

	if direccion.x > 0.0:
		return "idle_right"

	return "idle_down"


func _on_jugador_paso(casilla_origen: Vector2i, _direccion_jugador: Vector2, velocidad: float) -> void:
	if not activo:
		return

	_mover_a_casilla(casilla_origen, velocidad)



func _mover_a_casilla(
	casilla_destino: Vector2i,
	velocidad: float
) -> void:
	if anim == null or anim.sprite_frames == null:
		return

	var destino: Vector2 = (
		_casilla_a_global(casilla_destino)
	)

	var casilla_actual_follower: Vector2i = (
		_global_a_casilla(global_position)
	)

	var desplazamiento: Vector2i = (
		casilla_destino - casilla_actual_follower
	)

	if desplazamiento == Vector2i.ZERO:
		_reproducir_idle()
		return

	# La dirección se calcula según el movimiento real
	# del acompañante, no según la dirección nueva del jugador.
	_mirar(Vector2(desplazamiento))

	var duracion: float = 1.0 / maxf(
		velocidad,
		0.01
	)

	if tween_mov and tween_mov.is_valid():
		tween_mov.kill()

	tween_mov = create_tween()

	tween_mov.tween_property(
		self,
		"global_position",
		destino,
		duracion
	)

	tween_mov.finished.connect(_reproducir_idle, CONNECT_ONE_SHOT)

func _global_a_casilla(posicion: Vector2) -> Vector2i:
	var tile_size: float = float(
		CharacterController.TILE_SIZE
	)

	return Vector2i(
		floori(posicion.x / tile_size),
		floori(posicion.y / tile_size)
	)

func _casilla_a_global(casilla: Vector2i) -> Vector2:
	# Igual que CharacterController.snap_to_grid / posicion_a_casilla
	var ts: float = float(CharacterController.TILE_SIZE)
	return Vector2(
		float(casilla.x) * ts + ts * 0.5,
		float(casilla.y) * ts
	)


func _mirar(direccion: Vector2) -> void:
	if anim == null or anim.sprite_frames == null:
		return

	var direccion_nombre: String = "down"

	if direccion.y < 0.0:
		direccion_nombre = "up"
	elif direccion.y > 0.0:
		direccion_nombre = "down"
	elif direccion.x < 0.0:
		direccion_nombre = "left"
	elif direccion.x > 0.0:
		direccion_nombre = "right"

	idle_actual = "idle_" + direccion_nombre

	var prefijo: String = (
		"first_step_"
		if not alternar_paso
		else "second_step_"
	)

	var nombre_animacion: String = (
		prefijo + direccion_nombre
	)

	alternar_paso = not alternar_paso

	if anim.sprite_frames.has_animation(nombre_animacion):
		anim.play(nombre_animacion)
	else:
		_reproducir_idle()

func _reproducir_idle() -> void:
	if anim == null or anim.sprite_frames == null:
		return

	if anim.sprite_frames.has_animation(idle_actual):
		anim.play(idle_actual)


## Tras warp / cambio de mapa / teletransporte del jugador
func resetear_seguimiento() -> void:
	if tween_mov and tween_mov.is_valid():
		tween_mov.kill()

	_sincronizar_posicion_inicial()
