extends Node

var reproductor_salto: AudioStreamPlayer

func _ready() -> void:
	reproductor_salto = AudioStreamPlayer.new()
	reproductor_salto.stream = preload("res://sfx/se/Player jump.ogg")
	add_child(reproductor_salto)

func _avisar_follower(personaje: CharacterController) -> void:
	var nodo: Node = personaje.get_node_or_null("FollowerMon")
	if nodo is FollowerPokemon:
		(nodo as FollowerPokemon).resetear_seguimiento()

func ejecutar_comportamiento(comportamiento: String, personaje: CharacterController, tile_data: TileData, _casilla: Vector2i, direccion: Vector2) -> bool:

	match comportamiento:
		"ramp":
			return comportamiento_rampa(personaje, tile_data, direccion)

		"door":
			comportamiento_puerta(personaje)
			return true

		"grass":
			comportamiento_hierba(personaje)
			return false

		"stairs_right":
			var dir: Vector2 = comportamiento_escalera_subida_right(direccion)

			if dir != Vector2.ZERO:
				personaje.ultima_escalera = personaje.casilla_actual
				mover_escalera_right(personaje, dir)
				return true
			return false


		"stairs_left":
			var dir: Vector2 = comportamiento_escalera_subida_left(direccion)

			if dir != Vector2.ZERO:
				personaje.ultima_escalera = personaje.casilla_actual
				mover_escalera_left(personaje, dir)
				return true
			return false


		"stairs_end_right":
			# Si el jugador quiere regresar por la escalera
			if direccion == Vector2.LEFT:
				mover_escalera_right(personaje, Vector2(-1, 1))
				return true

			var dir: Vector2 = comportamiento_escalera_bajada_right(direccion)

			if dir != Vector2.ZERO:
				personaje.ultima_escalera = obtener_stairs_right(personaje.casilla_actual)
				mover_escalera_right(personaje, dir)
				return true

			return false


		"stairs_end_left":
			if direccion == Vector2.RIGHT:
				mover_escalera_left(personaje, Vector2(1, 1))
				return true

			var dir: Vector2 = comportamiento_escalera_bajada_left(direccion)

			if dir != Vector2.ZERO:
				personaje.ultima_escalera = obtener_stairs_left(personaje.casilla_actual)
				mover_escalera_left(personaje, dir)
				return true
			return false
	return false

# Logica para los comportamientos
func comportamiento_rampa(personaje: CharacterController, tile_data: TileData, direccion_entrada: Vector2) -> bool:
	var direccion_rampa: Vector2 = Vector2.DOWN

	if tile_data.has_custom_data("ramp_direction"):
		var valor: String = str(tile_data.get_custom_data("ramp_direction"))

		match valor:
			"up":
				direccion_rampa = Vector2.UP
			"down":
				direccion_rampa = Vector2.DOWN
			"left":
				direccion_rampa = Vector2.LEFT
			"right":
				direccion_rampa = Vector2.RIGHT


	# Solo activa si entras por la dirección correcta
	if direccion_entrada != direccion_rampa:
		return false


	print("Salto rampa hacia: ", direccion_rampa)


	salto_rampa(personaje, direccion_rampa)

	return true

func salto_rampa(personaje: CharacterController, direccion: Vector2) -> void:
	personaje.ejecutando_evento = true

	if reproductor_salto:
		reproductor_salto.play()

	var follower: FollowerPokemon = _obtener_follower(personaje)
	if follower != null:
		follower.saltar_rampa(direccion)

	var inicio: Vector2 = personaje.position
	var distancia: float = personaje.TILE_SIZE * 2

	var final: Vector2 = inicio + direccion * distancia

	var duracion: float = 0.4
	var altura: float = -16

	var tween: Tween = create_tween()

	tween.tween_method(
		func(t: float) -> void:
			var pos: Vector2 = inicio.lerp(final, t)

			# parábola
			var arco: float = sin(t * PI) * altura

			personaje.position = pos
			personaje.anim_player.position.y = arco, 0.0, 1.0, duracion)


	tween.finished.connect(
		func() -> void:
			personaje.position = final
			personaje.anim_player.position.y = 0.0

			personaje.casilla_actual = personaje.posicion_a_casilla(personaje.global_position)
			personaje.casilla_reservada = personaje.casilla_actual

			EventObjects.registrar_casilla(personaje.casilla_actual, personaje)

			personaje.ejecutando_evento = false
			_avisar_follower(personaje)
	)

func comportamiento_puerta(_personaje: CharacterController) -> void:
	print("Entrando puerta")

func comportamiento_hierba(personaje: CharacterController) -> void:
	# Solo al completar el paso, no al comprobar el destino
	if not personaje.is_moving:
		return
	if not (personaje.character_data is CharacterPlayer):
		return

	var mapa: MapAttributes = personaje.mapa_raiz as MapAttributes
	if mapa == null or mapa.grass_encounters == null:
		return

	var salvaje: PokemonInstance = mapa.grass_encounters.intentar_encuentro()
	if salvaje == null:
		return

	_iniciar_encuentro_salvaje(personaje, salvaje)


func _iniciar_encuentro_salvaje(personaje: CharacterController, salvaje: PokemonInstance) -> void:
	# De momento: log + bloquear input. Luego: transición a batalla.
	print("¡Encuentro salvaje! ", salvaje.species_id, " Nv.", salvaje.level)
	personaje.ejecutando_evento = true
	# TODO: BattleManager.start_wild_battle(personaje, salvaje)
	# Al volver de batalla: personaje.ejecutando_evento = false

# Escaleras Laterales
func comportamiento_escalera_subida_left(direccion: Vector2) -> Vector2:

	# Solo movimiento lateral
	if direccion != Vector2.LEFT:
		return Vector2.ZERO


	# Subimos un nivel
	return Vector2(-1, -1)

func comportamiento_escalera_subida_right(direccion: Vector2) -> Vector2:

	if direccion != Vector2.RIGHT:
		return Vector2.ZERO

	return Vector2(1,-1)

func comportamiento_escalera_bajada_left(direccion: Vector2) -> Vector2:

	# La escalera izquierda baja entrando desde la izquierda
	if direccion != Vector2.RIGHT:
		return Vector2.ZERO

	# Bajamos hacia la derecha
	return Vector2(1, 1)

func comportamiento_escalera_bajada_right(direccion: Vector2) -> Vector2:

	# La escalera derecha baja únicamente entrando desde la derecha
	if direccion != Vector2.LEFT:
		return Vector2.ZERO


	return Vector2(-1, 1)
	

func mover_escalera_right(personaje: CharacterController, desplazamiento: Vector2) -> void:
	personaje.ejecutando_evento = true

	var follower: FollowerPokemon = _obtener_follower(personaje)
	if follower != null:
		follower.deslizar_escalera(desplazamiento)

	var inicio: Vector2 = personaje.global_position
	var destino: Vector2 = inicio + desplazamiento * personaje.TILE_SIZE


	# Punto de seguridad derecha
	# Aquí puedes validar cosas específicas después


	personaje.casilla_reservada = personaje.posicion_a_casilla(destino)
	EventObjects.reservar_casilla(
		personaje.casilla_reservada,
		personaje
	)

	var tween: Tween = create_tween()

	tween.tween_property(
		personaje,
		"global_position",
		destino,
		0.30
	).set_trans(Tween.TRANS_LINEAR)


	tween.finished.connect(func() -> void:

		var casilla_vieja: Vector2i = personaje.casilla_actual
		var casilla_nueva: Vector2i = personaje.posicion_a_casilla(destino)


		personaje.global_position = destino
		personaje.casilla_actual = casilla_nueva
		personaje.casilla_reservada = casilla_nueva


		EventObjects.liberar_casilla(casilla_vieja)
		EventObjects.liberar_reserva(casilla_nueva)

		EventObjects.registrar_casilla(
			casilla_nueva,
			personaje
		)

		personaje.ejecutando_evento = false
		_avisar_follower(personaje)
	)

func mover_escalera_left(personaje: CharacterController, desplazamiento: Vector2) -> void:
	personaje.ejecutando_evento = true

	var follower: FollowerPokemon = _obtener_follower(personaje)
	if follower != null:
		follower.deslizar_escalera(desplazamiento)

	var inicio: Vector2 = personaje.global_position
	var destino: Vector2 = inicio + desplazamiento * personaje.TILE_SIZE


	# Punto de seguridad izquierda
	# Aquí puedes validar cosas específicas después


	personaje.casilla_reservada = personaje.posicion_a_casilla(destino)
	EventObjects.reservar_casilla(
		personaje.casilla_reservada,
		personaje
	)

	var tween: Tween = create_tween()

	tween.tween_property(
		personaje,
		"global_position",
		destino,
		0.30
	).set_trans(Tween.TRANS_LINEAR)


	tween.finished.connect(func() -> void:

		var casilla_vieja: Vector2i = personaje.casilla_actual
		var casilla_nueva: Vector2i = personaje.posicion_a_casilla(destino)


		personaje.global_position = destino
		personaje.casilla_actual = casilla_nueva
		personaje.casilla_reservada = casilla_nueva


		EventObjects.liberar_casilla(casilla_vieja)
		EventObjects.liberar_reserva(casilla_nueva)

		EventObjects.registrar_casilla(
			casilla_nueva,
			personaje
		)

		personaje.ejecutando_evento = false
		_avisar_follower(personaje)
	)

func obtener_stairs_right(casilla: Vector2i) -> Vector2i:
	return casilla + Vector2i(-1, 1)

func obtener_stairs_left(casilla: Vector2i) -> Vector2i:
	return casilla + Vector2i(1, 1)

func _obtener_follower(personaje: CharacterController) -> FollowerPokemon:
	var nodo: Node = personaje.get_node_or_null("FollowerMon")
	if nodo is FollowerPokemon:
		return nodo as FollowerPokemon
	return null
