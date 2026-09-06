extends Node2D
class_name CharacterController

signal paso_completado(casilla_origen: Vector2i, direccion: Vector2, velocidad: float)

const TILE_SIZE: int = 16
const CAPA_PERSONAJES: int = 0
const CASILLA_INVALIDA: Vector2i = Vector2i(-999, -999)

enum Direction { NORTH, SOUTH, EAST, WEST }

# --- Datos ---
var _character_data: CharacterGame
@export var character_data: CharacterGame:
	set(value):
		if _character_data == value:
			if Engine.is_editor_hint():
				call_deferred("_actualizar_sprite")
			return
		if _character_data and _character_data.changed.is_connected(_on_character_data_changed):
			_character_data.changed.disconnect(_on_character_data_changed)
		_character_data = value
		if _character_data:
			_character_data.changed.connect(_on_character_data_changed)
		_actualizar_sprite()
	get:
		return _character_data

# --- Nodos ---
@export var anim_player: AnimatedSprite2D
@export var cuerpo_colision: StaticBody2D
@export var forma_colision: CollisionShape2D
@export var sonido_colision: AudioStream

var reproductor_audio: AudioStreamPlayer
@export var tiempo_entre_sonidos: float = 0.3
var tiempo_ultimo_sonido: float = 0.0

# --- Estado de movimiento ---
var is_moving: bool = false
var is_first_step: bool = true
var input_direction: Vector2 = Vector2.ZERO
var percent_moved_to_next_tile: float = 0.0
var initial_position: Vector2 = Vector2.ZERO
var current_direction: Direction = Direction.SOUTH

var casilla_actual: Vector2i = Vector2i.ZERO
var casilla_reservada: Vector2i = Vector2i.ZERO

# --- Mapa ---
var capa_datos_mapa: TileMapLayer
var mapa_raiz: Node
var map_manager: MapManager
var capas_comportamiento: Array[TileBehaviourLayer] = []

var ultima_casilla_comportamiento: Vector2i = CASILLA_INVALIDA
var ultima_escalera: Vector2i = CASILLA_INVALIDA
var nivel_suelo: int = 1
var nivel_render: int = 1
var ejecutando_evento: bool = false

var _sprite_frames_son_propios: bool = false


func _ready() -> void:
	if not Engine.is_editor_hint():
		position = snap_to_grid(position)

	if character_data and not Engine.is_editor_hint():
		var copia: CharacterGame = character_data.duplicate(true) as CharacterGame
		if copia:
			character_data = copia

	if character_data and not character_data.changed.is_connected(_on_character_data_changed):
		character_data.changed.connect(_on_character_data_changed)

	initial_position = position
	casilla_actual = posicion_a_casilla(global_position)
	casilla_reservada = casilla_actual
	actualizar_nivel_suelo(global_position)
	EventObjects.registrar_casilla(casilla_actual, self)

	var mapa: Node = self
	while mapa and not (mapa is MapAttributes):
		mapa = mapa.get_parent()
	mapa_raiz = mapa

	process_priority = 100 if character_data is CharacterPlayer else -100

	if not cuerpo_colision:
		cuerpo_colision = $StaticBody2D as StaticBody2D
	if cuerpo_colision and not forma_colision:
		forma_colision = cuerpo_colision.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if cuerpo_colision:
		cuerpo_colision.collision_layer = 1 << CAPA_PERSONAJES

	_actualizar_sprite()

	var sombra: CharacterShadow = $CharacterShadow as CharacterShadow
	if sombra and character_data:
		sombra._vincular_datos(character_data)

	if mapa_raiz:
		buscar_capa_colisiones()

	if Engine.is_editor_hint():
		return

	await get_tree().process_frame
	await get_tree().process_frame

	reproductor_audio = AudioStreamPlayer.new()
	reproductor_audio.stream = sonido_colision
	add_child(reproductor_audio)
	cargar_capas_comportamiento()


func _on_character_data_changed() -> void:
	_actualizar_sprite()


# ====================== SPRITE ======================

func _actualizar_sprite() -> void:
	if not anim_player or not character_data:
		return

	var ruta: String = _obtener_ruta_sprite()
	if ruta.is_empty() or not ResourceLoader.exists(ruta):
		return

	var textura: Texture2D = load(ruta) as Texture2D
	if not textura:
		push_error("No se pudo cargar sprite: " + ruta)
		return

	_asegurar_sprite_frames_propios()
	_aplicar_textura_a_frames(textura)
	anim_player.play("idle_down")
	anim_player.queue_redraw()


func _obtener_ruta_sprite() -> String:
	if character_data is CharacterPlayer:
		var datos: CharacterPlayer = character_data as CharacterPlayer
		return EventObjects.player_sprites.get(datos.sprite_overworld, "") as String
	elif character_data is CharacterNpc:
		var id: int = (character_data as CharacterNpc).sprite_overworld
		if id == EventObjects.NpcID.NONE:
			return ""
		return EventObjects.npc_sprites.get(id, "") as String
	return ""


func _asegurar_sprite_frames_propios() -> void:
	if _sprite_frames_son_propios or not anim_player or not anim_player.sprite_frames:
		return
	var copia: SpriteFrames = anim_player.sprite_frames.duplicate(true) as SpriteFrames
	if copia:
		anim_player.sprite_frames = copia
		_sprite_frames_son_propios = true


func _aplicar_textura_a_frames(textura: Texture2D) -> void:
	var frames: SpriteFrames = anim_player.sprite_frames
	if not frames:
		return
	for anim_nombre: String in frames.get_animation_names():
		for i: int in range(frames.get_frame_count(anim_nombre)):
			var original: Texture2D = frames.get_frame_texture(anim_nombre, i)
			if original is AtlasTexture:
				var atlas: AtlasTexture = original.duplicate() as AtlasTexture
				atlas.atlas = textura
				frames.set_frame(anim_nombre, i, atlas, frames.get_frame_duration(anim_nombre, i))
			else:
				frames.set_frame(anim_nombre, i, textura, frames.get_frame_duration(anim_nombre, i))
	anim_player.sprite_frames = frames


# ====================== MOVIMIENTO ======================

func process_input() -> void:
	pass


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint() or ejecutando_evento:
		return
	if not is_moving:
		process_input()
	else:
		move(delta)


func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return
	z_as_relative = false
	var banda_visual: int = nivel_render if nivel_render >= 1000 else 0
	z_index = banda_visual + int(global_position.y)


func intentar_mover(direccion: Vector2) -> bool:
	input_direction = direccion
	var casilla_destino: Vector2i = casilla_actual + Vector2i(input_direction)

	if ultima_escalera != CASILLA_INVALIDA:
		var despl: Vector2i = ultima_escalera - casilla_actual
		if abs(despl.x) == 1 and abs(despl.y) == 1 and direccion.x == despl.x:
			input_direction = Vector2(despl)
			casilla_destino = ultima_escalera

	var pos_destino: Vector2 = global_position + input_direction * TILE_SIZE
	var datos_destino: TileData = map_manager.obtener_tile_data(pos_destino) if map_manager else null
	var es_transicion: bool = false
	if datos_destino and datos_destino.has_custom_data("floor_transition"):
		es_transicion = bool(datos_destino.get_custom_data("floor_transition"))

	if not es_transicion:
		for capa: TileBehaviourLayer in capas_comportamiento:
			if is_instance_valid(capa) and capa.comprobar_casilla(casilla_destino, self, input_direction):
				return true

		if not casilla_permitida(pos_destino):
			_reproducir_sonido_colision()
			return false

	if EventObjects.hay_otro_en_casilla(casilla_destino, self):
		return false
	if hay_personaje_en(pos_destino):
		return false

	casilla_reservada = casilla_destino
	EventObjects.reservar_casilla(casilla_destino, self)
	initial_position = position
	is_moving = true
	return true


func move(delta: float) -> void:
	if not character_data:
		return
	var velocidad: float = obtener_velocidad_movimiento()
	percent_moved_to_next_tile += velocidad * delta

	if percent_moved_to_next_tile >= 1.0:
		complete_move()
	else:
		reproducir_paso()
		position = initial_position + input_direction * TILE_SIZE * percent_moved_to_next_tile


func complete_move() -> void:
	if input_direction == Vector2.ZERO:
		is_moving = false
		return

	var casilla_vieja: Vector2i = casilla_actual
	casilla_actual = casilla_reservada

	if casilla_actual == ultima_escalera:
		ultima_escalera = CASILLA_INVALIDA

	position = snap_to_grid(initial_position + input_direction * TILE_SIZE)

	EventObjects.liberar_casilla(casilla_vieja)
	EventObjects.liberar_reserva(casilla_actual)
	EventObjects.registrar_casilla(casilla_actual, self)
	actualizar_nivel_suelo(global_position)

	if character_data is CharacterPlayer:
		revisar_conexion_mapa()

	for capa: TileBehaviourLayer in capas_comportamiento:
		if is_instance_valid(capa):
			capa.comprobar_casilla(casilla_actual, self, input_direction)

	percent_moved_to_next_tile = 0.0
	is_moving = false

	if map_manager:
		map_manager.comprobar_transicion()

	paso_completado.emit(casilla_vieja, input_direction, obtener_velocidad_movimiento())


func obtener_velocidad_movimiento() -> float:
	if character_data:
		return character_data.walk_speed
	return 4.0


func cancelar_movimiento() -> void:
	if not is_moving:
		return
	EventObjects.liberar_reserva(casilla_reservada)
	casilla_reservada = casilla_actual
	position = snap_to_grid(initial_position)
	percent_moved_to_next_tile = 0.0
	input_direction = Vector2.ZERO
	is_moving = false


# ====================== ANIMACIÓN ======================

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


func reproducir_paso() -> void:
	if not anim_player:
		return
	var prefijo: String = "first_step_" if is_first_step else "second_step_"
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
		Vector2(1, -1), Vector2(1, 1):
			current_direction = Direction.EAST
			anim_player.play("first_step_right")
		Vector2(-1, -1), Vector2(-1, 1):
			current_direction = Direction.WEST
			anim_player.play("first_step_left")


func mirar_hacia_posicion(posicion: Vector2) -> void:
	var dif: Vector2 = posicion - global_position
	if abs(dif.x) > abs(dif.y):
		current_direction = Direction.EAST if dif.x > 0.0 else Direction.WEST
	else:
		current_direction = Direction.SOUTH if dif.y > 0.0 else Direction.NORTH
	reproducir_idle()


# ====================== UTILIDADES ======================

func snap_to_grid(pos: Vector2) -> Vector2:
	pos.x = floor(pos.x / float(TILE_SIZE)) * float(TILE_SIZE) + float(TILE_SIZE) / 2.0
	pos.y = floor(pos.y / float(TILE_SIZE)) * float(TILE_SIZE)
	return pos


func posicion_a_casilla(pos: Vector2) -> Vector2i:
	return Vector2i(floori(pos.x / float(TILE_SIZE)), floori(pos.y / float(TILE_SIZE)))


func casilla_permitida(posicion_global: Vector2) -> bool:
	if not capa_datos_mapa or not map_manager:
		return false
	var datos: TileData = map_manager.obtener_tile_data(posicion_global)
	if datos == null:
		return true

	var mantener_piso: bool = datos.has_custom_data("keep_floor") and bool(datos.get_custom_data("keep_floor"))
	if datos.has_custom_data("blocked") and bool(datos.get_custom_data("blocked")) and not mantener_piso:
		return false
	if datos.has_custom_data("floor_transition") and bool(datos.get_custom_data("floor_transition")):
		return true
	if datos.has_custom_data("floor_lvl"):
		var piso_destino: int = int(datos.get_custom_data("floor_lvl"))
		if mantener_piso:
			piso_destino = nivel_suelo
		if nivel_suelo != -1 and piso_destino != nivel_suelo:
			return false
	return true


func hay_personaje_en(destino_global: Vector2) -> bool:
	var espacio: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
	if not espacio:
		return false
	var forma: RectangleShape2D = RectangleShape2D.new()
	forma.size = Vector2(TILE_SIZE - 4, TILE_SIZE - 4)
	var consulta: PhysicsShapeQueryParameters2D = PhysicsShapeQueryParameters2D.new()
	consulta.shape = forma
	var offset: Vector2 = Vector2.ZERO
	if cuerpo_colision:
		offset += cuerpo_colision.position
	if forma_colision:
		offset += forma_colision.position
	consulta.transform = Transform2D(0.0, destino_global + offset)
	consulta.exclude = [self, cuerpo_colision, forma_colision]
	consulta.collision_mask = (1 << CAPA_PERSONAJES) | (1 << 1)
	consulta.collide_with_bodies = true
	return espacio.intersect_shape(consulta).size() > 0


func _reproducir_sonido_colision() -> void:
	if reproductor_audio and sonido_colision:
		if Time.get_ticks_msec() - tiempo_ultimo_sonido > tiempo_entre_sonidos * 1000.0:
			reproductor_audio.play()
			tiempo_ultimo_sonido = float(Time.get_ticks_msec())


# ====================== MAPA / PISO ======================

func buscar_capa_colisiones() -> void:
	capa_datos_mapa = null
	var raiz: Node = mapa_raiz if mapa_raiz else self
	while raiz and raiz.get_parent() != get_tree().root:
		raiz = raiz.get_parent()

	var map_data: Node = raiz.get_node_or_null("MapData")
	if map_data and str(map_data.get_path()).begins_with("/root/MapData/"):
		map_data = null

	if map_data:
		var behaviours: Node = map_data.get_node_or_null("Behaviours")
		if behaviours:
			var collisions: Node = behaviours.get_node_or_null("Collisions")
			if collisions is TileMapLayer:
				capa_datos_mapa = collisions as TileMapLayer

	if not capa_datos_mapa:
		var cola: Array[Node] = [raiz]
		while cola.size() > 0:
			var n: Node = cola.pop_front()
			if n.name == "Collisions" and n is TileMapLayer:
				if not str(n.get_path()).begins_with("/root/MapData/"):
					capa_datos_mapa = n as TileMapLayer
					break
			for hijo: Node in n.get_children(true):
				cola.append(hijo)

	cargar_capas_comportamiento()


func resetear_estado_de_mapa() -> void:
	capas_comportamiento.clear()
	ultima_casilla_comportamiento = CASILLA_INVALIDA
	ultima_escalera = CASILLA_INVALIDA
	nivel_suelo = 1
	nivel_render = 1
	if anim_player:
		anim_player.position.y = 0.0


func sincronizar_con_mapa(nuevo_mapa: MapAttributes, nuevo_map_manager: MapManager) -> void:
	mapa_raiz = nuevo_mapa
	map_manager = nuevo_map_manager
	resetear_estado_de_mapa()
	buscar_capa_colisiones()
	casilla_actual = posicion_a_casilla(global_position)
	casilla_reservada = casilla_actual
	actualizar_nivel_suelo(global_position)


func cargar_capas_comportamiento() -> void:
	capas_comportamiento.clear()
	if not mapa_raiz:
		return
	var nodos: Array[Node] = mapa_raiz.find_children("*", "TileBehaviourLayer", true, false)
	for nodo: Node in nodos:
		if nodo is TileBehaviourLayer and is_instance_valid(nodo):
			capas_comportamiento.append(nodo as TileBehaviourLayer)


func actualizar_nivel_suelo(posicion_global: Vector2) -> void:
	if not map_manager:
		return
	var datos: TileData = map_manager.obtener_tile_data(posicion_global)
	if not datos:
		return
	if datos.has_custom_data("keep_floor") and bool(datos.get_custom_data("keep_floor")):
		nivel_render = nivel_suelo
		return
	if datos.has_custom_data("floor_transition") and bool(datos.get_custom_data("floor_transition")):
		nivel_suelo = -1
		nivel_render = -1
		return
	if datos.has_custom_data("floor_lvl"):
		nivel_suelo = int(datos.get_custom_data("floor_lvl"))
		nivel_render = nivel_suelo


func revisar_conexion_mapa() -> void:
	if not mapa_raiz:
		return
	var borde: MapAttributes.Border = (mapa_raiz as MapAttributes).obtener_borde(casilla_actual)
	if borde == MapAttributes.Border.NONE:
		return
	var _conexion: MapConnection = (mapa_raiz as MapAttributes).obtener_conexion(borde)
