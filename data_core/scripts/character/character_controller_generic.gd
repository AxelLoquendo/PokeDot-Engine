@tool
extends Node2D

class_name CharacterController

const TILE_SIZE: int = 16
const CAPA_PERSONAJES: int = 0

var _character_data: CharacterGame

@export var character_data: CharacterGame:
	set(value):
		if _character_data == value:
			if Engine.is_editor_hint():
				call_deferred("_actualizar_sprite")
			return

		if _character_data:
			if _character_data.changed.is_connected(_on_character_data_changed):
				_character_data.changed.disconnect(_on_character_data_changed)

		_character_data = value

		if _character_data:
			_character_data.changed.connect(_on_character_data_changed)

		_actualizar_sprite()

	get:
		return _character_data

@export var anim_player: AnimatedSprite2D
@export var cuerpo_colision: StaticBody2D
@export var forma_colision: CollisionShape2D

@export var sonido_colision: AudioStream
var reproductor_audio: AudioStreamPlayer
@export var tiempo_entre_sonidos: float = 0.3
var tiempo_ultimo_sonido: float = 0.0

var is_moving: bool = false
var is_first_step: bool = true
enum Direction { NORTH, SOUTH, EAST, WEST }
var input_direction: Vector2 = Vector2.ZERO
var percent_moved_to_next_tile: float = 0.0
var initial_position: Vector2 = Vector2.ZERO
var current_direction: Direction = Direction.SOUTH
var casilla_actual: Vector2i = Vector2i.ZERO
var casilla_reservada: Vector2i = Vector2i.ZERO

var capa_datos_mapa: TileMapLayer
var mapa_raiz: Node

func _ready() -> void:
	if not Engine.is_editor_hint():
		position = snap_to_grid(position)
		
	if character_data:
		if not Engine.is_editor_hint():
			var copia: CharacterGame = character_data.duplicate(true)
			if copia:
				character_data = copia

		if not character_data.changed.is_connected(_on_character_data_changed):
			character_data.changed.connect(_on_character_data_changed)

	initial_position = position
	casilla_actual = posicion_a_casilla(global_position)
	casilla_reservada = casilla_actual
	EventObjects.registrar_casilla(casilla_actual, self)
	print(
	"NPC registrado: ",
	name,
	" posición: ",
	global_position,
	" casilla: ",
	casilla_actual
	)
	process_priority = 100 if character_data is CharacterPlayer else -100

	if not cuerpo_colision:
		cuerpo_colision = $StaticBody2D as StaticBody2D
	if cuerpo_colision and not forma_colision:
		forma_colision = cuerpo_colision.get_node_or_null("CollisionShape2D") as CollisionShape2D

	if cuerpo_colision:
		cuerpo_colision.collision_layer = 1 << CAPA_PERSONAJES

	_actualizar_sprite()

	var nodo_sombra: CharacterShadow = $CharacterShadow as CharacterShadow
	if nodo_sombra and character_data:
		nodo_sombra._vincular_datos(character_data)

	if mapa_raiz:
		buscar_capa_colisiones()

	if Engine.is_editor_hint():
		return

	await get_tree().process_frame
	await get_tree().process_frame

	reproductor_audio = AudioStreamPlayer.new()
	reproductor_audio.stream = sonido_colision
	add_child(reproductor_audio)

func _on_character_data_changed() -> void:
	print("CAMBIO DETECTADO")
	_actualizar_sprite()

func _actualizar_sprite() -> void:
	if not anim_player or not character_data:
		return

	var ruta_sprite: String = ""

	if character_data is CharacterPlayer:
		var datos: CharacterPlayer = character_data as CharacterPlayer
		var id: int = datos.sprite_overworld

		if id >= 0 and id < EventObjects.player_sprites.size():
			ruta_sprite = EventObjects.player_sprites[id]

	elif character_data is CharacterNpc:
		var id: int = character_data.sprite_overworld
	
		if id == EventObjects.NpcID.NONE:
			print("NPC sin sprite asignado")
			return
	
		if id >= 0 and id < EventObjects.npc_sprites.size():
			ruta_sprite = EventObjects.npc_sprites[id]


	if ruta_sprite.is_empty():
		return

	if not ResourceLoader.exists(ruta_sprite):
		print("Sprite no encontrado: ", ruta_sprite)
		return

	var textura: Texture2D = load(ruta_sprite) as Texture2D

	if not textura:
		push_error("No se pudo cargar: " + ruta_sprite)
		return


	var frames: SpriteFrames = anim_player.sprite_frames

	if not frames:
		return


	for anim_nombre: String in frames.get_animation_names():
		for i: int in range(frames.get_frame_count(anim_nombre)):

			var original: Texture2D = frames.get_frame_texture(anim_nombre, i)

			if original is AtlasTexture:
				var atlas: AtlasTexture = original.duplicate()
				atlas.atlas = textura

				frames.set_frame(
					anim_nombre,
					i,
					atlas,
					frames.get_frame_duration(anim_nombre, i)
				)

			else:
				frames.set_frame(
					anim_nombre,
					i,
					textura,
					frames.get_frame_duration(anim_nombre, i)
				)


	anim_player.sprite_frames = frames
	anim_player.play("idle_down")
	anim_player.queue_redraw()

func buscar_capa_colisiones() -> void:
	capa_datos_mapa = null

	var raiz_busqueda: Node = mapa_raiz
	if not raiz_busqueda:
		raiz_busqueda = self
		while raiz_busqueda and raiz_busqueda.get_parent() != get_tree().root:
			raiz_busqueda = raiz_busqueda.get_parent()

	var map_data: Node = raiz_busqueda.get_node_or_null("MapData")
	if map_data:
		var ruta: String = str(map_data.get_path())
		if ruta.begins_with("/root/MapData/"):
			map_data = null
	
	if map_data:
		var behaviours: Node = map_data.get_node_or_null("Behaviours")
		if behaviours:
			var collisions: Node = behaviours.get_node_or_null("Collisions")
			if collisions and collisions is TileMapLayer:
				capa_datos_mapa = collisions as TileMapLayer
	
	if not capa_datos_mapa:
		var cola: Array[Node] = [raiz_busqueda]
		while cola.size() > 0:
			var nodo_actual: Node = cola.pop_front()
			if nodo_actual.name == "Collisions" and nodo_actual is TileMapLayer:
				var ruta_colision: String = str(nodo_actual.get_path())
				if not ruta_colision.begins_with("/root/MapData/"):
					capa_datos_mapa = nodo_actual as TileMapLayer
					break
			var hijos: Array = nodo_actual.get_children(true)
			for hijo: Node in hijos:
				cola.append(hijo)

func hay_personaje_en(destino_global: Vector2) -> bool:
	var espacio: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
	if not espacio:
		return false

	var forma_casilla: RectangleShape2D = RectangleShape2D.new()
	forma_casilla.size = Vector2(TILE_SIZE - 4, TILE_SIZE - 4)

	var consulta: PhysicsShapeQueryParameters2D = PhysicsShapeQueryParameters2D.new()
	consulta.shape = forma_casilla
	var offset_colision: Vector2 = Vector2.ZERO
	if cuerpo_colision:
		offset_colision += cuerpo_colision.position
	if forma_colision:
		offset_colision += forma_colision.position
	consulta.transform = Transform2D(0, destino_global + offset_colision)
	consulta.exclude = [self, cuerpo_colision, forma_colision]
	consulta.collision_mask = (1 << CAPA_PERSONAJES) | (1 << 1)
	consulta.collide_with_bodies = true
	consulta.collide_with_areas = false

	var resultado: Array = espacio.intersect_shape(consulta)
	return resultado.size() > 0

func intentar_mover(direccion: Vector2) -> bool:
	input_direction = direccion

	var casilla_destino: Vector2i = casilla_actual + Vector2i(direccion)
	var posicion_destino_global: Vector2 = global_position + (direccion * TILE_SIZE)
	
	var permitida: bool = casilla_permitida(posicion_destino_global)
	if not permitida:
		if reproductor_audio and sonido_colision:
			if Time.get_ticks_msec() - tiempo_ultimo_sonido > tiempo_entre_sonidos * 1000:
				reproductor_audio.play()
				tiempo_ultimo_sonido = Time.get_ticks_msec()
		return false
	
	var ocupada: bool = EventObjects.hay_otro_en_casilla(casilla_destino, self)

	if ocupada:
		if reproductor_audio and sonido_colision:
			if Time.get_ticks_msec() - tiempo_ultimo_sonido > tiempo_entre_sonidos * 1000:
				reproductor_audio.play()
				tiempo_ultimo_sonido = Time.get_ticks_msec()
		return false
	
	var hay_colision: bool = hay_personaje_en(posicion_destino_global)
	if hay_colision:
		return false

	casilla_reservada = casilla_destino
	EventObjects.reservar_casilla(casilla_destino, self)
	initial_position = position
	is_moving = true
	return true

func _process(_delta: float) -> void:
	z_index = int(global_position.y)
	if Engine.is_editor_hint():
		return

func _physics_process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if !is_moving:
		process_input()
	else:
		move(_delta)

func process_input() -> void:
	pass

func move(_delta: float) -> void:
	if not character_data:
		return

	var velocidad: float = obtener_velocidad_movimiento()
	percent_moved_to_next_tile += velocidad * _delta

	if percent_moved_to_next_tile >= 1.0:
		complete_move()
	else:
		reproducir_paso()
		position = initial_position + input_direction * TILE_SIZE * percent_moved_to_next_tile

func obtener_velocidad_movimiento() -> float:
	return character_data.walk_speed

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

func complete_move() -> void:
	if input_direction == Vector2.ZERO:
		is_moving = false
		return

	var casilla_vieja: Vector2i = casilla_actual
	casilla_actual = casilla_reservada
	position = snap_to_grid(initial_position + input_direction * TILE_SIZE)

	EventObjects.liberar_casilla(casilla_vieja)
	EventObjects.liberar_reserva(casilla_actual)
	EventObjects.registrar_casilla(casilla_actual, self)

	percent_moved_to_next_tile = 0.0
	is_moving = false
	#print("📍 Posición final: ", global_position, " → Casilla: ", casilla_actual)

func snap_to_grid(pos: Vector2) -> Vector2:
	pos.x = floor(pos.x / TILE_SIZE) * TILE_SIZE + TILE_SIZE / 2.0
	pos.y = floor(pos.y / TILE_SIZE) * TILE_SIZE
	return pos

func posicion_a_casilla(pos: Vector2) -> Vector2i:
	return Vector2i(
		floori(pos.x / TILE_SIZE),
		floori(pos.y / TILE_SIZE)
	)

func casilla_permitida(posicion_global: Vector2) -> bool:
	if not capa_datos_mapa:
		return false

	var local: Vector2 = capa_datos_mapa.to_local(posicion_global)
	var casilla_real: Vector2i = capa_datos_mapa.local_to_map(local)

	# Impide salir de los límites definidos por map_size.
	var atributos_mapa: MapAttributes = mapa_raiz as MapAttributes
	if atributos_mapa and not atributos_mapa.esta_dentro_limites(casilla_real):
		return false

	var datos_baldosa: TileData = capa_datos_mapa.get_cell_tile_data(casilla_real)

	# No hay tile de comportamiento: se puede caminar.
	if datos_baldosa == null:
		return true

	var bloqueada: bool = false
	if datos_baldosa.has_custom_data("blocked"):
		bloqueada = bool(datos_baldosa.get_custom_data("blocked"))

	var requiere_nivel_1: bool = false
	if datos_baldosa.has_custom_data("pass_lvl_1"):
		requiere_nivel_1 = bool(datos_baldosa.get_custom_data("pass_lvl_1"))

	if bloqueada:
		return false

	if requiere_nivel_1:
		var puede_pasar: bool = (
			character_data is CharacterPlayer
			or character_data is CharacterNpc
		)
		return puede_pasar

	return true

func mirar_hacia_posicion(posicion: Vector2) -> void:
	var diferencia: Vector2 = posicion - global_position

	if abs(diferencia.x) > abs(diferencia.y):
		if diferencia.x > 0:
			current_direction = Direction.EAST
		else:
			current_direction = Direction.WEST
	else:
		if diferencia.y > 0:
			current_direction = Direction.SOUTH
		else:
			current_direction = Direction.NORTH

func cancelar_movimiento() -> void:
	if not is_moving:
		return

	EventObjects.liberar_reserva(casilla_reservada)
	casilla_reservada = casilla_actual

	position = snap_to_grid(initial_position)

	percent_moved_to_next_tile = 0.0
	input_direction = Vector2.ZERO
	is_moving = false
	casilla_reservada = casilla_actual
