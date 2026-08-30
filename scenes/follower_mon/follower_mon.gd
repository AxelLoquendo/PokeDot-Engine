extends Node2D
class_name FollowerPokemon

## Pokémon acompañante: sigue al jugador con 1 casilla de retraso.
## Usa overworld_scene (Texture2D) del primer mon del party que lo tenga.

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

var jugador: CharacterController = null
var activo: bool = false

var cola: Array[Vector2i] = []
@export var retraso_casillas: int = 1

## Desfase visual del sprite (píxeles). Ajusta si flota o se hunde.
@export var sprite_offset: Vector2 = Vector2(0, -8)

var tween_mov: Tween = null


func setup(p_jugador: CharacterController) -> void:
	jugador = p_jugador
	if jugador and not jugador.paso_completado.is_connected(_on_jugador_paso):
		jugador.paso_completado.connect(_on_jugador_paso)
	refrescar_desde_party()
	_sincronizar_posicion_inicial()


func _exit_tree() -> void:
	if jugador and is_instance_valid(jugador):
		if jugador.paso_completado.is_connected(_on_jugador_paso):
			jugador.paso_completado.disconnect(_on_jugador_paso)


func refrescar_desde_party() -> void:
	cola.clear()
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

	var species: PokemonDataStruct = mon.get_species()
	if species == null:
		return

	var tex: Texture2D = species.overworld_scene
	if mon.gender == PokemonData.Gender.FEMALE and species.overworld_scene_female != null:
		tex = species.overworld_scene_female

	if tex == null:
		return

	_aplicar_textura(tex)
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


func _aplicar_textura(tex: Texture2D) -> void:
	if anim == null or tex == null:
		return

	var frames: SpriteFrames = SpriteFrames.new()

	frames.add_animation("idle")
	frames.set_animation_loop("idle", true)
	frames.add_frame("idle", tex)

	for nombre: String in ["walk_down", "walk_up", "walk_left", "walk_right"]:
		frames.add_animation(nombre)
		frames.set_animation_loop(nombre, true)
		frames.add_frame(nombre, tex)

	anim.sprite_frames = frames
	anim.offset = sprite_offset
	anim.play("idle")


func _limpiar_anim() -> void:
	if anim == null:
		return
	anim.stop()
	anim.sprite_frames = null


func _sincronizar_posicion_inicial() -> void:
	if jugador == null or not activo:
		return
	if tween_mov and tween_mov.is_valid():
		tween_mov.kill()
	global_position = _casilla_a_global(jugador.casilla_actual)


func _on_jugador_paso(casilla_origen: Vector2i, direccion: Vector2, velocidad: float) -> void:
	if not activo:
		return
	cola.append(casilla_origen)
	if cola.size() <= retraso_casillas:
		return
	var dest: Vector2i = cola.pop_front()
	_mover_a_casilla(dest, direccion, velocidad)


func _mover_a_casilla(casilla: Vector2i, direccion: Vector2, velocidad: float) -> void:
	var destino: Vector2 = _casilla_a_global(casilla)
	var duracion: float = 1.0 / maxf(velocidad, 0.01)

	if tween_mov and tween_mov.is_valid():
		tween_mov.kill()

	_mirar(direccion)

	tween_mov = create_tween()
	tween_mov.tween_property(self, "global_position", destino, duracion)
	tween_mov.finished.connect(_on_paso_terminado, CONNECT_ONE_SHOT)


func _on_paso_terminado() -> void:
	if anim and anim.sprite_frames and anim.sprite_frames.has_animation("idle"):
		anim.play("idle")


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

	var nombre: String = "walk_down"
	if direccion.y < 0.0:
		nombre = "walk_up"
	elif direccion.y > 0.0:
		nombre = "walk_down"
	elif direccion.x < 0.0:
		nombre = "walk_left"
	elif direccion.x > 0.0:
		nombre = "walk_right"

	if anim.sprite_frames.has_animation(nombre):
		anim.play(nombre)
	elif anim.sprite_frames.has_animation("idle"):
		anim.play("idle")


## Tras warp / cambio de mapa / teletransporte del jugador
func resetear_seguimiento() -> void:
	cola.clear()
	if tween_mov and tween_mov.is_valid():
		tween_mov.kill()
	_sincronizar_posicion_inicial()
	if anim and anim.sprite_frames and anim.sprite_frames.has_animation("idle"):
		anim.play("idle")
