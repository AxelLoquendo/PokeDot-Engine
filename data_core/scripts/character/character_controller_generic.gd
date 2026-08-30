extends Node2D
class_name CharacterController

signal paso_completado(casilla_origen: Vector2i, direccion: Vector2, velocidad: float)
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
var map_manager: MapManager
var capas_comportamiento: Array[TileBehaviourLayer] = []
var ultima_casilla_comportamiento: Vector2i = Vector2i(-999, -999)
var ultima_escalera: Vector2i = Vector2i(-999, -999)
var nivel_suelo: int = 1
var nivel_render: int = 1
var ejecutando_evento: bool = false
var _sprite_frames_son_propios: bool = false


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
	actualizar_nivel_suelo(global_position)
	EventObjects.registrar_casilla(casilla_actual, self)

	var mapa: Node = self
	while mapa and not (mapa is MapAttributes):
		mapa = mapa.get_parent()

	#print("NPC registrado: ", name, " | mapa: ", (mapa as MapAttributes).map_name if mapa else "???", " | posición: ", global_position)

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
	cargar_capas_comportamiento()


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

		if EventObjects.player_sprites.has(id):
			ruta_sprite = EventObjects.player_sprites[id]

	elif character_data is CharacterNpc:
		var id: int = character_data.sprite_overworld

		if id == EventObjects.NpcID.NONE:
			print("NPC sin sprite asignado")
			return

		if EventObjects.npc_sprites.has(id):  
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

	# SpriteFrames contiene AtlasTexture mutables. La escena base comparte el
	# recurso, así que cada personaje necesita su copia antes de reemplazar el
	# atlas; de lo contrario, cambiar un NPC cambia la apariencia de todos.
	_asegurar_sprite_frames_propios()
	var frames: SpriteFrames = anim_player.sprite_frames
	if not frames:
		return

	for anim_nombre: String in frames.get_animation_names():
		for i: int in range(frames.get_frame_count(anim_nombre)):
			var original: Texture2D = frames.get_frame_texture(anim_nombre, i)

			if original is AtlasTexture:
				var atlas: AtlasTexture = original.duplicate()
				atlas.atlas = textura
				frames.set_frame(anim_nombre, i, atlas, frames.get_frame_duration(anim_nombre, i))
			else:
				frames.set_frame(anim_nombre, i, textura, frames.get_frame_duration(anim_nombre, i))

	anim_player.sprite_frames = frames
	anim_player.play("idle_down")
	anim_player.queue_redraw()


func _asegurar_sprite_frames_propios() -> void:
	if _sprite_frames_son_propios or not anim_player or not anim_player.sprite_frames:
		return
	var copia: SpriteFrames = anim_player.sprite_frames.duplicate(true) as SpriteFrames
	if copia:
		anim_player.sprite_frames = copia
		_sprite_frames_son_propios = true


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
	# Las capas de comportamiento pertenecen al mapa actual. Recargarlas aquí
	# evita conservar rampas/escaleras de un mapa anterior tras un warp.
	cargar_capas_comportamiento()


## Restablece datos derivados del tileset antes de leer la baldosa de un mapa
## nuevo. No se conserva ningún comportamiento ni nivel del mapa anterior.
func resetear_estado_de_mapa() -> void:
	cancelar_movimiento()
	capas_comportamiento.clear()
	ultima_casilla_comportamiento = Vector2i(-999, -999)
	ultima_escalera = Vector2i(-999, -999)
	nivel_suelo = 1
	nivel_render = 1
	if anim_player:
		anim_player.position.y = 0.0


## Relee los datos del mapa y tile actual para un personaje recién activado.
func sincronizar_con_mapa(nuevo_mapa: MapAttributes, nuevo_map_manager: MapManager) -> void:
	mapa_raiz = nuevo_mapa
	map_manager = nuevo_map_manager
	resetear_estado_de_mapa()
	buscar_capa_colisiones()
	casilla_actual = posicion_a_casilla(global_position)
	casilla_reservada = casilla_actual
	actualizar_nivel_suelo(global_position)


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


const _BEHAVIOURS_ACTIVOS: Dictionary = {
	"stairs": true,
	"stairs_end": true
}


func intentar_mover(direccion: Vector2) -> bool:
	input_direction = direccion
	var casilla_destino: Vector2i = casilla_actual + Vector2i(input_direction)

	# Si tenemos una escalera registrada, comprobamos si el jugador
	# intenta volver exactamente a esa casilla.
	if ultima_escalera != Vector2i(-999, -999):
		var desplazamiento: Vector2i = ultima_escalera - casilla_actual

		# Solo aceptamos un desplazamiento diagonal de una casilla.
		if abs(desplazamiento.x) == 1 and abs(desplazamiento.y) == 1:
			# Si el jugador pulsa la dirección horizontal correcta,
			# convertimos el movimiento en diagonal.
			if direccion.x == desplazamiento.x:
				input_direction = Vector2(desplazamiento)
				casilla_destino = ultima_escalera

	# Primero comprobar transición de piso
	var posicion_destino_global: Vector2 = (global_position + input_direction * TILE_SIZE)
	var datos_destino: TileData = map_manager.obtener_tile_data(posicion_destino_global)
	var es_transicion: bool = false

	if datos_destino:
		if datos_destino.has_custom_data("floor_transition"):
			es_transicion = bool(datos_destino.get_custom_data("floor_transition"))

	# Si es transición, dejamos pasar el movimiento normal
	# para que complete_move() actualice el piso
	if not es_transicion:
		for capa: TileBehaviourLayer in capas_comportamiento:
			if not is_instance_valid(capa):
				continue
			if capa.comprobar_casilla(casilla_destino, self, input_direction):
				return true

		# Colisión de mapa
		if not casilla_permitida(posicion_destino_global):
			if reproductor_audio and sonido_colision:
				if Time.get_ticks_msec() - tiempo_ultimo_sonido > tiempo_entre_sonidos * 1000:
					reproductor_audio.play()
					tiempo_ultimo_sonido = Time.get_ticks_msec()
			return false

	# Personajes
	if EventObjects.hay_otro_en_casilla(casilla_destino, self):
		return false

	if hay_personaje_en(posicion_destino_global):
		return false

	# Reservar movimiento
	casilla_reservada = casilla_destino
	EventObjects.reservar_casilla(
		casilla_destino,
		self
	)

	initial_position = position
	is_moving = true
	return true


func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return

	z_as_relative = false
	# La profundidad base siempre depende de Y: quien está más abajo se dibuja
	# delante. floor_lvl 1..5 son niveles lógicos de colisión, no z-index.
	# Los valores 1000/2000 sí son bandas visuales de Tile2/Tile3 y se suman,
	# nunca sustituyen a Y; así dos NPCs de la misma banda siguen ordenándose.
	var banda_visual: int = nivel_render if nivel_render >= 1000 else 0
	z_index = banda_visual + int(global_position.y)


func _physics_process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if ejecutando_evento:
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
	var prefijo: String = (
		"first_step_"
		if is_first_step
		else "second_step_"
	)

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
		# Escalera lateral derecha subiendo
		Vector2(1, -1):
			current_direction = Direction.EAST
			anim_player.play("first_step_right")
		# Escalera lateral izquierda subiendo
		Vector2(-1, -1):
			current_direction = Direction.WEST
			anim_player.play("first_step_left")
		# Escalera lateral derecha bajando
		Vector2(1, 1):
			current_direction = Direction.EAST
			anim_player.play("first_step_right")
		# Escalera lateral izquierda bajando
		Vector2(-1, 1):
			current_direction = Direction.WEST
			anim_player.play("first_step_left")


func complete_move() -> void:
	if input_direction == Vector2.ZERO:
		is_moving = false
		return
	var casilla_vieja: Vector2i = casilla_actual
	casilla_actual = casilla_reservada

	if casilla_actual == ultima_escalera:
		ultima_escalera = Vector2i(-999, -999)

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

	# Acompañante / sistemas que siguen al personaje
	paso_completado.emit(casilla_vieja, input_direction, obtener_velocidad_movimiento())

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

	var datos_destino: TileData = map_manager.obtener_tile_data(posicion_global)
	if datos_destino == null:
		return true

	# Este tile conserva el nivel anterior del piso.
	var mantener_piso : bool = false
	if datos_destino.has_custom_data("keep_floor"):
		mantener_piso  = bool(datos_destino.get_custom_data("keep_floor"))

	# Bloqueo normal
	if datos_destino.has_custom_data("blocked"):
		if bool(datos_destino.get_custom_data("blocked")) and not mantener_piso :
			return false

	# Si es transición de piso, siempre permitir
	if datos_destino.has_custom_data("floor_transition"):
		if bool(datos_destino.get_custom_data("floor_transition")):
			return true

	# Revisar nivel del piso destino
	if datos_destino.has_custom_data("floor_lvl"):
		var piso_destino: int = int(datos_destino.get_custom_data("floor_lvl"))
		if mantener_piso :
			piso_destino = nivel_suelo
#		print("Actual:", nivel_suelo, " Destino:", piso_destino, " Tile:", posicion_global)
		# Comparación normal de niveles
		if nivel_suelo != -1 and piso_destino != nivel_suelo:
			return false

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


func cargar_capas_comportamiento() -> void:
	capas_comportamiento.clear()
	if not mapa_raiz:
		return

	var nodos: Array[Node] = mapa_raiz.find_children(
		"*",
		"TileBehaviourLayer",
		true,
		false
	)

	for nodo: Node in nodos:
		if nodo is TileBehaviourLayer:
			var capa: TileBehaviourLayer = nodo as TileBehaviourLayer
			if is_instance_valid(capa):
				capas_comportamiento.append(capa)


func revisar_conexion_mapa() -> void:
	if not mapa_raiz:
		return
	var borde: MapAttributes.Border = mapa_raiz.obtener_borde(casilla_actual)
	if borde == MapAttributes.Border.NONE:
		return

	var conexion: MapConnection = mapa_raiz.obtener_conexion(borde)
	if conexion == null:
		return

#	print("Cambiar al mapa:", conexion.target_section)


func actualizar_nivel_suelo(posicion_global: Vector2) -> void:
	if not map_manager:
		return

	var datos_baldosa: TileData = map_manager.obtener_tile_data(posicion_global)
	if not datos_baldosa:
		return

	# Entramos al puente
	if datos_baldosa.has_custom_data("keep_floor"):
		if bool(datos_baldosa.get_custom_data("keep_floor")):
			# Conservamos el último nivel.
			# No modificamos nivel_suelo.
			nivel_render = nivel_suelo
			return

	if datos_baldosa.has_custom_data("floor_transition"):
		if bool(datos_baldosa.get_custom_data("floor_transition")):
			nivel_suelo = -1
			nivel_render = -1
			return

	if datos_baldosa.has_custom_data("floor_lvl"):
		nivel_suelo = int(datos_baldosa.get_custom_data("floor_lvl"))
		nivel_render = nivel_suelo

#		print(name, " ahora está en piso ", nivel_suelo)
