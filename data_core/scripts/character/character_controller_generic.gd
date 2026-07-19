extends Node2D

class_name CharacterController

const TILE_SIZE: int = 16

@export var character_data: CharacterGame = CharacterGame.new()
# Forma segura: tipo solo, sin | null en declaración de clase (se asume implícito para objetos)
@export var anim_player: AnimatedSprite2D
@export var cuerpo_colision: StaticBody2D
@export var forma_colision: CollisionShape2D

var is_moving: bool = false
var is_first_step: bool = true
enum Direction { NORTH, SOUTH, EAST, WEST }
var input_direction: Vector2 = Vector2.ZERO
var percent_moved_to_next_tile: float = 0.0
var initial_position: Vector2 = Vector2.ZERO
var current_direction: Direction = Direction.SOUTH
var casilla_actual: Vector2i = Vector2i.ZERO


func _ready() -> void:
	var copia: CharacterGame = null
	if character_data:
		copia = character_data.duplicate(true)
		if copia:
			character_data = copia
	
	position = snap_to_grid(position)
	initial_position = position
	casilla_actual = posicion_a_casilla(position)
	EventObjects.registrar_casilla(casilla_actual, self)

	process_priority = -100 if character_data is CharacterPlayer else 100

	if not cuerpo_colision:
		cuerpo_colision = $StaticBody2D as StaticBody2D
	if cuerpo_colision and not forma_colision:
		forma_colision = cuerpo_colision.get_node_or_null("CollisionShape2D") as CollisionShape2D

	if anim_player and character_data:
		var plantilla: SpriteFrames = anim_player.get_sprite_frames()
		if not plantilla:
			print("Asigna tu plantilla de animaciones al AnimatedSprite2D en el editor")
			return

		var ruta_sprite: String = ""
		if character_data is CharacterPlayer:
			var id: int = character_data.sprite_overworld
			if id >= 0 and id < EventObjects.player_sprites.size():
				ruta_sprite = EventObjects.player_sprites[id]
		elif character_data is CharacterNpc:
			var id: int = character_data.sprite_overworld
			if id >= 0 and id < EventObjects.npc_sprites.size():
				ruta_sprite = EventObjects.npc_sprites[id]

		var textura_nueva: CompressedTexture2D
		if ruta_sprite != "" and ruta_sprite.begins_with("res://"):
			textura_nueva = load(ruta_sprite) as CompressedTexture2D
		else:
			print("Sin sprite asignado para este personaje (ID NONE o ruta inválida)")

		if textura_nueva and plantilla:
			var frames_personalizados: SpriteFrames = plantilla.duplicate()
			for anim_nombre: String in frames_personalizados.get_animation_names():
				for cuadro_idx: int in range(frames_personalizados.get_frame_count(anim_nombre)):
					var cuadro_original: Texture2D = frames_personalizados.get_frame_texture(anim_nombre, cuadro_idx)
					var duracion: float = frames_personalizados.get_frame_duration(anim_nombre, cuadro_idx)

					if cuadro_original is AtlasTexture:
						var nuevo_atlas: AtlasTexture = cuadro_original.duplicate()
						nuevo_atlas.atlas = textura_nueva
						frames_personalizados.set_frame(anim_nombre, cuadro_idx, nuevo_atlas, duracion)
					else:
						frames_personalizados.set_frame(anim_nombre, cuadro_idx, textura_nueva, duracion)

			anim_player.set_sprite_frames(frames_personalizados)
			anim_player.play("idle_down")
	
	var nodo_sombra: CharacterShadow = $CharacterShadow as CharacterShadow
	if nodo_sombra and character_data:
		nodo_sombra._vincular_datos(character_data)


func hay_personaje_en(destino: Vector2) -> bool:
	if not cuerpo_colision or not forma_colision or not forma_colision.shape:
		return false

	var espacio: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
	if not espacio:
		return false

	var consulta: PhysicsShapeQueryParameters2D = PhysicsShapeQueryParameters2D.new()
	
	consulta.shape = forma_colision.shape
	consulta.transform = Transform2D(0, destino)
	consulta.exclude = [self, cuerpo_colision]
	consulta.collision_mask = cuerpo_colision.collision_layer
	consulta.collide_with_bodies = true
	consulta.collide_with_areas = false

	var resultado: Array = espacio.intersect_shape(consulta)
	return resultado.size() > 0


func intentar_mover(direccion: Vector2) -> bool:
	var casilla_destino: Vector2i = casilla_actual + Vector2i(direccion)
	var posicion_destino: Vector2 = snap_to_grid(position + direccion * TILE_SIZE)

	if EventObjects.hay_otro_en_casilla(casilla_destino, self):
		return false
	
	if hay_personaje_en(posicion_destino):
		return false

	EventObjects.registrar_casilla(casilla_destino, self)

	input_direction = direccion
	initial_position = position
	is_moving = true
	return true


func _process(_delta: float) -> void:
	z_index = int(global_position.y)


func _physics_process(_delta: float) -> void:
	if !is_moving:
		process_input()
	else:
		move(_delta)


func process_input() -> void:
	pass


func move(_delta: float) -> void:
	if not character_data:
		return
	
	var velocidad: float = character_data.walk_speed

	percent_moved_to_next_tile += velocidad * _delta
	if percent_moved_to_next_tile >= 1.0:
		complete_move()
	else:
		if is_first_step:
			match input_direction:
				Vector2(0, -1):
					if anim_player: anim_player.play("first_step_up")
					current_direction = Direction.NORTH
				Vector2(0, 1):
					if anim_player: anim_player.play("first_step_down")
					current_direction = Direction.SOUTH
				Vector2(1, 0):
					if anim_player: anim_player.play("first_step_right")
					current_direction = Direction.EAST
				Vector2(-1, 0):
					if anim_player: anim_player.play("first_step_left")
					current_direction = Direction.WEST
		else:
			match input_direction:
				Vector2(0, -1):
					if anim_player: anim_player.play("second_step_up")
					current_direction = Direction.NORTH
				Vector2(0, 1):
					if anim_player: anim_player.play("second_step_down")
					current_direction = Direction.SOUTH
				Vector2(1, 0):
					if anim_player: anim_player.play("second_step_right")
					current_direction = Direction.EAST
				Vector2(-1, 0):
					if anim_player: anim_player.play("second_step_left")
					current_direction = Direction.WEST

		position = initial_position + input_direction * TILE_SIZE * percent_moved_to_next_tile


func complete_move() -> void:
	if input_direction == Vector2.ZERO:
		is_moving = false
		return

	var casilla_vieja: Vector2i = casilla_actual
	var casilla_nueva: Vector2i = casilla_actual + Vector2i(input_direction)

	casilla_actual = casilla_nueva
	position = snap_to_grid(initial_position + input_direction * TILE_SIZE)

	EventObjects.liberar_casilla(casilla_vieja)
	EventObjects.registrar_casilla(casilla_nueva, self)

	percent_moved_to_next_tile = 0.0
	is_moving = false


func snap_to_grid(pos: Vector2) -> Vector2:
	if int(pos.x + 8) % 16 != 0:
		pos.x = (int(pos.x / TILE_SIZE) * TILE_SIZE) - 8
	elif int(pos.y) % TILE_SIZE != 0:
		pos.y = int(pos.y / TILE_SIZE) * TILE_SIZE
	return pos


func posicion_a_casilla(pos: Vector2) -> Vector2i:
	return Vector2i(
		int((pos.x + 8) / TILE_SIZE),
		int(pos.y / TILE_SIZE)
	)
