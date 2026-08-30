extends Node2D
class_name FollowerPokemon

## Pokémon acompañante: 1 casilla detrás, movimiento en paralelo al jugador.
## Carga dinámicamente overworld_scene (o graphics/pokemon/follower/<NOMBRE>.png).

const FOLLOWER_FOLDER: String = "res://graphics/pokemon/follower/"
const FRAMES_SMALL: SpriteFrames = preload("res://data_core/pokemon/follower_mon_small.tres")
const FRAMES_LARGE: SpriteFrames = preload("res://data_core/pokemon/follower_mon_large.tres")
const SHEET_LARGE_MIN: int = 256

const SHADOW_TEXTURES: Array[String] = [
	"",
	"res://graphics/overworld/shadow/shadow_small.png",
	"res://graphics/overworld/shadow/shadow_medium.png",
	"res://graphics/overworld/shadow/shadow_large.png",
	"res://graphics/overworld/shadow/shadow_extra_large.png",
]

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var sombra: Sprite2D = $Shadow

@export var shadow_offset: Vector2 = Vector2(-0.5, 11.0)
## 1=S, 2=M, 3=L, 4=XL — por defecto según celda si queda en 0
@export var shadow_size_small: int = 2
@export var shadow_size_large: int = 3

var jugador: CharacterController = null
var activo: bool = false
var mon_actual: PokemonInstance = null

@export var sprite_offset: Vector2 = Vector2(0, -4)

var tween_mov: Tween = null
var alternar_paso: bool = false
var idle_actual: String = "idle_down"
var _frames_propios: bool = false
## Evita lanzar el mismo paso dos veces mientras el jugador sigue is_moving.
var _siguiendo_paso_actual: bool = false
## true mientras salta rampa o se desliza por escalera
var en_secuencia_especial: bool = false

@export var idle_anim_speed: float = 2.5  ## frames por segundo del “respirar”
var _idle_timer: float = 0.0
var _idle_usando_first: bool = true

func _ready() -> void:
	top_level = true
	visible = false
	if anim != null:
		anim.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		anim.scale = Vector2.ONE
	if sombra != null:
		sombra.visible = false
		sombra.z_as_relative = true
		sombra.z_index = -1


func _aplicar_textura(textura: Texture2D) -> bool:
	if anim == null:
		return false

	var plantilla: SpriteFrames = _elegir_plantilla(textura)
	if plantilla == null:
		return false

	var copia: SpriteFrames = plantilla.duplicate(true) as SpriteFrames
	if copia == null:
		return false

	anim.sprite_frames = copia
	_frames_propios = true

	var frames: SpriteFrames = anim.sprite_frames
	var nombres: PackedStringArray = frames.get_animation_names()
	for anim_nombre: String in nombres:
		var frame_count: int = frames.get_frame_count(anim_nombre)
		for i: int in range(frame_count):
			var original: Texture2D = frames.get_frame_texture(anim_nombre, i)
			var duracion: float = frames.get_frame_duration(anim_nombre, i)
			if original is AtlasTexture:
				var atlas: AtlasTexture = (original as AtlasTexture).duplicate() as AtlasTexture
				atlas.atlas = textura
				frames.set_frame(anim_nombre, i, atlas, duracion)
			else:
				frames.set_frame(anim_nombre, i, textura, duracion)

	anim.sprite_frames = frames
	anim.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	anim.scale = Vector2.ONE
	anim.centered = true

	# Alinear pies con la línea base de un frame de 32px
	var celda: int = _tamano_celda(textura)
	var extra_y: float = -float(celda - 32) * 0.5
	anim.offset = sprite_offset + Vector2(0.0, extra_y)
	_actualizar_sombra(celda)
	return true

func _actualizar_sombra(celda: int) -> void:
	if sombra == null:
		return

	var indice: int = shadow_size_small if celda <= 32 else shadow_size_large
	if indice < 1 or indice >= SHADOW_TEXTURES.size():
		sombra.visible = false
		return

	var ruta: String = SHADOW_TEXTURES[indice]
	if ruta.is_empty() or not ResourceLoader.exists(ruta):
		sombra.visible = false
		return

	var textura: Texture2D = load(ruta) as Texture2D
	if textura == null:
		sombra.visible = false
		return

	sombra.texture = textura
	sombra.position = shadow_offset
	sombra.modulate = Color(1.0, 1.0, 1.0, 0.505)
	# La visibilidad la controla refrescar_desde_party / el nodo raíz
	sombra.visible = true

func _tamano_celda(textura: Texture2D) -> int:
	# Sheet 256 → celdas 64; sheet 128 → celdas 32
	if textura.get_width() >= SHEET_LARGE_MIN:
		return 64
	return 32

func _elegir_plantilla(textura: Texture2D) -> SpriteFrames:
	var ancho: int = textura.get_width()
	if ancho >= SHEET_LARGE_MIN:
		return FRAMES_LARGE
	return FRAMES_SMALL


func setup(p_jugador: CharacterController) -> void:
	jugador = p_jugador
	refrescar_desde_party()


func _exit_tree() -> void:
	if tween_mov != null and tween_mov.is_valid():
		tween_mov.kill()


func _process(_delta: float) -> void:
	if not activo or jugador == null:
		return

	z_index = int(global_position.y) - 1

	if en_secuencia_especial:
		return

	if jugador.is_moving:
		if not _siguiendo_paso_actual:
			_siguiendo_paso_actual = true
			var velocidad: float = jugador.obtener_velocidad_movimiento()
			_mover_a_casilla(jugador.casilla_actual, velocidad)
	else:
		_siguiendo_paso_actual = false
		_corregir_si_quedo_lejos()
		_actualizar_idle_animado(_delta)

func _actualizar_idle_animado(delta: float) -> void:
	if anim == null or anim.sprite_frames == null:
		return
	# No pisar un tween de paso que aún no terminó
	if tween_mov != null and tween_mov.is_valid() and tween_mov.is_running():
		return

	_idle_timer += delta
	var intervalo: float = 1.0 / maxf(idle_anim_speed, 0.01)
	if _idle_timer < intervalo:
		return

	_idle_timer = 0.0
	_idle_usando_first = not _idle_usando_first
	_reproducir_idle_paso()


func _reproducir_idle_paso() -> void:
	if anim == null or anim.sprite_frames == null:
		return

	# idle_down → down, idle_left → left, etc.
	var direccion_nombre: String = idle_actual.trim_prefix("idle_")
	var prefijo: String = "first_step_" if _idle_usando_first else "second_step_"
	var nombre: String = prefijo + direccion_nombre

	if anim.sprite_frames.has_animation(nombre):
		anim.play(nombre)
	elif anim.sprite_frames.has_animation(idle_actual):
		anim.play(idle_actual)

func _corregir_si_quedo_lejos() -> void:
	var casilla_follower: Vector2i = _global_a_casilla(global_position)
	var casilla_jugador: Vector2i = jugador.casilla_actual
	var dist: int = absi(casilla_follower.x - casilla_jugador.x) + absi(casilla_follower.y - casilla_jugador.y)
	# > 1 = no está en la casilla de atrás (rampa salta 2, escalera diagonal, warp…)
	if dist > 1:
		resetear_seguimiento()


func refrescar_desde_party() -> void:
	activo = false
	visible = false
	mon_actual = null
	_siguiendo_paso_actual = false
	_limpiar_anim()
	if sombra != null:
		sombra.visible = false

	if jugador == null or anim == null:
		return

	var data: CharacterPlayer = jugador.character_data as CharacterPlayer
	if data == null:
		return

	var mon: PokemonInstance = _elegir_mon(data.party)
	if mon == null:
		return

	var textura: Texture2D = _resolver_textura(mon)
	if textura == null:
		push_warning("FollowerPokemon: sin sprite overworld para %s" % str(mon.species_id))
		return

	if not _aplicar_textura(textura):
		return

	mon_actual = mon
	activo = true
	visible = true
	_sincronizar_posicion_inicial()

func _offset_actual() -> Vector2:
	if mon_actual == null:
		return sprite_offset
	var tex: Texture2D = _resolver_textura(mon_actual)
	if tex == null:
		return sprite_offset
	var celda: int = _tamano_celda(tex)
	var extra_y: float = -float(celda - 32) * 0.5
	return sprite_offset + Vector2(0.0, extra_y)

func _elegir_mon(party: Array[PokemonInstance]) -> PokemonInstance:
	for mon: PokemonInstance in party:
		if mon == null:
			continue
		if _resolver_textura(mon) != null:
			return mon
	return null


func _resolver_textura(mon: PokemonInstance) -> Texture2D:
	var sp: PokemonDataStruct = mon.get_species()
	if sp == null:
		return null

	if sp.overworld_scene != null:
		return sp.overworld_scene

	var nombre: String = _nombre_archivo_especie(sp)
	if nombre.is_empty():
		return null

	var ruta: String = FOLLOWER_FOLDER + nombre + ".png"
	if ResourceLoader.exists(ruta):
		return load(ruta) as Texture2D

	return null


func _nombre_archivo_especie(sp: PokemonDataStruct) -> String:
	if not sp.species_name.is_empty():
		return sp.species_name.to_upper().replace(" ", "").replace(".", "").replace("'", "")

	var keys: Array = Species.SpeciesID.keys()
	var values: Array = Species.SpeciesID.values()
	var idx: int = values.find(sp.species_id)
	if idx < 0:
		return ""
	var key: String = str(keys[idx])
	if key.begins_with("SPECIES_"):
		return key.substr(8)
	return key

func _limpiar_anim() -> void:
	if anim == null:
		return
	anim.stop()


func _sincronizar_posicion_inicial() -> void:
	if jugador == null or not activo:
		return

	if tween_mov != null and tween_mov.is_valid():
		tween_mov.kill()

	_siguiendo_paso_actual = false

	var direccion_atras: Vector2i = _vector_direccion(jugador.current_direction)
	var casilla_detras: Vector2i = jugador.casilla_actual - direccion_atras
	global_position = _casilla_a_global(casilla_detras)

	idle_actual = _obtener_idle(Vector2(direccion_atras))
	_idle_timer = 0.0
	_idle_usando_first = true
	_reproducir_idle_paso()
	if anim != null and anim.sprite_frames != null:
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


func _mover_a_casilla(casilla_destino: Vector2i, velocidad: float) -> void:
	if anim == null or anim.sprite_frames == null:
		return

	var destino: Vector2 = _casilla_a_global(casilla_destino)
	var casilla_actual_follower: Vector2i = _global_a_casilla(global_position)
	var desplazamiento: Vector2i = casilla_destino - casilla_actual_follower

	if desplazamiento == Vector2i.ZERO:
		_reproducir_idle()
		return

	_mirar(Vector2(desplazamiento))

	var duracion: float = 1.0 / maxf(velocidad, 0.01)

	if tween_mov != null and tween_mov.is_valid():
		tween_mov.kill()

	tween_mov = create_tween()
	tween_mov.tween_property(self, "global_position", destino, duracion)
	tween_mov.finished.connect(_reproducir_idle, CONNECT_ONE_SHOT)


func _global_a_casilla(posicion: Vector2) -> Vector2i:
	var tile_size: float = float(CharacterController.TILE_SIZE)
	return Vector2i(
		floori(posicion.x / tile_size),
		floori(posicion.y / tile_size)
	)


func _casilla_a_global(casilla: Vector2i) -> Vector2:
	var ts: float = float(CharacterController.TILE_SIZE)
	return Vector2(
		float(casilla.x) * ts + ts * 0.5,
		float(casilla.y) * ts
	)


func _mirar(direccion: Vector2) -> void:
	if anim == null or anim.sprite_frames == null:
		return

	_idle_timer = 0.0

	var direccion_nombre: String = "down"

	# Escaleras / diagonales: priorizar eje horizontal
	if absf(direccion.x) > 0.0:
		if direccion.x < 0.0:
			direccion_nombre = "left"
		else:
			direccion_nombre = "right"
	elif direccion.y < 0.0:
		direccion_nombre = "up"
	elif direccion.y > 0.0:
		direccion_nombre = "down"

	idle_actual = "idle_" + direccion_nombre

	var prefijo: String = "first_step_" if not alternar_paso else "second_step_"
	var nombre_animacion: String = prefijo + direccion_nombre
	alternar_paso = not alternar_paso

	if anim.sprite_frames.has_animation(nombre_animacion):
		anim.play(nombre_animacion)
	else:
		_reproducir_idle()


func _reproducir_idle() -> void:
	_idle_timer = 0.0
	_reproducir_idle_paso()


## Llamar tras warp / cambio de mapa / teletransporte.
func resetear_seguimiento() -> void:
	if tween_mov != null and tween_mov.is_valid():
		tween_mov.kill()
	en_secuencia_especial = false
	_siguiendo_paso_actual = false
	if anim != null:
		anim.offset = _offset_actual()
	_sincronizar_posicion_inicial()

## Misma parábola que el jugador (2 casillas en `direccion`).
func saltar_rampa(direccion: Vector2) -> void:
	if not activo or anim == null:
		return

	en_secuencia_especial = true
	_siguiendo_paso_actual = false

	if tween_mov != null and tween_mov.is_valid():
		tween_mov.kill()

	_mirar(direccion)

	var inicio: Vector2 = global_position
	var distancia: float = float(CharacterController.TILE_SIZE) * 2.0
	var final: Vector2 = inicio + direccion * distancia
	var duracion: float = 0.4
	var altura: float = -16.0
	var offset_base: Vector2 = _offset_actual()

	tween_mov = create_tween()
	tween_mov.tween_method(
		func(t: float) -> void:
			var pos: Vector2 = inicio.lerp(final, t)
			var arco: float = sin(t * PI) * altura
			global_position = pos
			anim.offset = offset_base + Vector2(0.0, arco),
		0.0,
		1.0,
		duracion
	)
	tween_mov.finished.connect(
		func() -> void:
			global_position = _casilla_a_global(_global_a_casilla(final))
			anim.offset = offset_base
			en_secuencia_especial = false
			_reproducir_idle(),
		CONNECT_ONE_SHOT
	)


## Mismo desliz diagonal que el jugador (`desplazamiento` en casillas, p.ej. Vector2(1, -1)).
func deslizar_escalera(desplazamiento: Vector2) -> void:
	if not activo:
		return

	en_secuencia_especial = true
	_siguiendo_paso_actual = false

	if tween_mov != null and tween_mov.is_valid():
		tween_mov.kill()

	# Escaleras laterales: siempre mirar izq/der, nunca arriba/abajo
	var mirar_dir: Vector2 = Vector2(signf(desplazamiento.x), 0.0)
	if mirar_dir == Vector2.ZERO:
		mirar_dir = desplazamiento
	_mirar(mirar_dir)

	var inicio: Vector2 = global_position
	var destino: Vector2 = inicio + desplazamiento * float(CharacterController.TILE_SIZE)
	var duracion: float = 0.30

	tween_mov = create_tween()
	tween_mov.tween_property(self, "global_position", destino, duracion).set_trans(Tween.TRANS_LINEAR)
	tween_mov.finished.connect(
		func() -> void:
			global_position = _casilla_a_global(_global_a_casilla(destino))
			en_secuencia_especial = false
			_reproducir_idle(),
		CONNECT_ONE_SHOT
	)
