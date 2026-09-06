extends Node

var reproductor_salto: AudioStreamPlayer


func _ready() -> void:
	reproductor_salto = AudioStreamPlayer.new()
	reproductor_salto.stream = preload("res://sfx/se/Player jump.ogg")
	add_child(reproductor_salto)


# ====================== DISPATCH ======================

func ejecutar_comportamiento(
	comportamiento: String,
	personaje: CharacterController,
	tile_data: TileData,
	_casilla: Vector2i,
	direccion: Vector2
) -> bool:
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
			var dir: Vector2 = _direccion_escalera_subida_right(direccion)
			if dir != Vector2.ZERO:
				personaje.ultima_escalera = personaje.casilla_actual
				_mover_escalera(personaje, dir)
				return true
			return false

		"stairs_left":
			var dir: Vector2 = _direccion_escalera_subida_left(direccion)
			if dir != Vector2.ZERO:
				personaje.ultima_escalera = personaje.casilla_actual
				_mover_escalera(personaje, dir)
				return true
			return false

		"stairs_end_right":
			if direccion == Vector2.LEFT:
				_mover_escalera(personaje, Vector2(-1, 1))
				return true
			var dir: Vector2 = _direccion_escalera_bajada_right(direccion)
			if dir != Vector2.ZERO:
				personaje.ultima_escalera = obtener_stairs_right(personaje.casilla_actual)
				_mover_escalera(personaje, dir)
				return true
			return false

		"stairs_end_left":
			if direccion == Vector2.RIGHT:
				_mover_escalera(personaje, Vector2(1, 1))
				return true
			var dir: Vector2 = _direccion_escalera_bajada_left(direccion)
			if dir != Vector2.ZERO:
				personaje.ultima_escalera = obtener_stairs_left(personaje.casilla_actual)
				_mover_escalera(personaje, dir)
				return true
			return false

	return false


# ====================== RAMPA ======================

func comportamiento_rampa(
	personaje: CharacterController,
	tile_data: TileData,
	direccion_entrada: Vector2
) -> bool:
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

	# Solo se activa si entras en la dirección correcta
	if direccion_entrada != direccion_rampa:
		return false

	salto_rampa(personaje, direccion_rampa)
	return true


func salto_rampa(personaje: CharacterController, direccion: Vector2) -> void:
	personaje.ejecutando_evento = true

	if reproductor_salto:
		reproductor_salto.play()

	var follower: FollowerPokemon = _obtener_follower(personaje)
	if follower:
		follower.saltar_rampa(direccion)

	var inicio: Vector2 = personaje.position
	var distancia: float = float(personaje.TILE_SIZE * 2)
	var final: Vector2 = inicio + direccion * distancia
	var duracion: float = 0.4
	var altura: float = -16.0

	var tween: Tween = create_tween()
	tween.tween_method(
		func(t: float) -> void:
			var pos: Vector2 = inicio.lerp(final, t)
			var arco: float = sin(t * PI) * altura
			personaje.position = pos
			if personaje.anim_player:
				personaje.anim_player.position.y = arco,
		0.0,
		1.0,
		duracion
	)

	tween.finished.connect(func() -> void:
		personaje.position = final
		if personaje.anim_player:
			personaje.anim_player.position.y = 0.0

		personaje.casilla_actual = personaje.posicion_a_casilla(personaje.global_position)
		personaje.casilla_reservada = personaje.casilla_actual
		EventObjects.registrar_casilla(personaje.casilla_actual, personaje)

		personaje.ejecutando_evento = false
		_avisar_follower(personaje)
	)


# ====================== PUERTA / HIERBA ======================

func comportamiento_puerta(_personaje: CharacterController) -> void:
	# TODO: lógica real de entrada a interiores
	pass


func comportamiento_hierba(personaje: CharacterController) -> void:
	# Solo se evalúa al completar el paso
	if not personaje.is_moving:
		return
	if not (personaje.character_data is CharacterPlayer):
		return
	if BattleSession.is_active:
		return

	var mapa: MapAttributes = personaje.mapa_raiz as MapAttributes
	if mapa == null or mapa.grass_encounters == null:
		return

	var salvaje: PokemonInstance = mapa.grass_encounters.intentar_encuentro()
	if salvaje == null:
		return

	var data: CharacterPlayer = personaje.character_data as CharacterPlayer
	var lead: PokemonInstance = _primer_pokemon_apto(data.party)
	if lead == null:
		return

	_iniciar_encuentro_salvaje(personaje, lead, salvaje)


func _primer_pokemon_apto(party: Array[PokemonInstance]) -> PokemonInstance:
	for mon: PokemonInstance in party:
		if mon != null and not mon.is_fainted():
			return mon
	return null


func _iniciar_encuentro_salvaje(
	personaje: CharacterController,
	lead: PokemonInstance,
	salvaje: PokemonInstance
) -> void:
	BattleSession.preparar_salvaje(personaje, lead, salvaje)
	_correr_transicion_batalla(personaje)


func _correr_transicion_batalla(personaje: CharacterController) -> void:
	personaje.ejecutando_evento = true
	MusicManager.reproducir_batalla(BattleSession.battle_music)

	if TransicionManager != null:
		await TransicionManager.transicion_encuentro_salvaje()

	var parent: Node = personaje.get_tree().current_scene
	if parent == null:
		parent = personaje.get_tree().root

	BattleSession.iniciar_como_overlay(parent)

	if TransicionManager != null:
		await TransicionManager.fade_in(0.25)


# ====================== ESCALERAS ======================

func _direccion_escalera_subida_left(direccion: Vector2) -> Vector2:
	if direccion != Vector2.LEFT:
		return Vector2.ZERO
	return Vector2(-1, -1)


func _direccion_escalera_subida_right(direccion: Vector2) -> Vector2:
	if direccion != Vector2.RIGHT:
		return Vector2.ZERO
	return Vector2(1, -1)


func _direccion_escalera_bajada_left(direccion: Vector2) -> Vector2:
	if direccion != Vector2.RIGHT:
		return Vector2.ZERO
	return Vector2(1, 1)


func _direccion_escalera_bajada_right(direccion: Vector2) -> Vector2:
	if direccion != Vector2.LEFT:
		return Vector2.ZERO
	return Vector2(-1, 1)


func _mover_escalera(personaje: CharacterController, desplazamiento: Vector2) -> void:
	personaje.ejecutando_evento = true

	var follower: FollowerPokemon = _obtener_follower(personaje)
	if follower:
		follower.deslizar_escalera(desplazamiento)

	var inicio: Vector2 = personaje.global_position
	var destino: Vector2 = inicio + desplazamiento * float(personaje.TILE_SIZE)

	personaje.casilla_reservada = personaje.posicion_a_casilla(destino)
	EventObjects.reservar_casilla(personaje.casilla_reservada, personaje)

	var tween: Tween = create_tween()
	tween.tween_property(personaje, "global_position", destino, 0.30).set_trans(Tween.TRANS_LINEAR)

	tween.finished.connect(func() -> void:
		var casilla_vieja: Vector2i = personaje.casilla_actual
		var casilla_nueva: Vector2i = personaje.posicion_a_casilla(destino)

		personaje.global_position = destino
		personaje.casilla_actual = casilla_nueva
		personaje.casilla_reservada = casilla_nueva

		EventObjects.liberar_casilla(casilla_vieja)
		EventObjects.liberar_reserva(casilla_nueva)
		EventObjects.registrar_casilla(casilla_nueva, personaje)

		personaje.ejecutando_evento = false
		_avisar_follower(personaje)
	)


func obtener_stairs_right(casilla: Vector2i) -> Vector2i:
	return casilla + Vector2i(-1, 1)


func obtener_stairs_left(casilla: Vector2i) -> Vector2i:
	return casilla + Vector2i(1, 1)


# ====================== HELPERS ======================

func _obtener_follower(personaje: CharacterController) -> FollowerPokemon:
	var nodo: Node = personaje.get_node_or_null("FollowerMon")
	if nodo is FollowerPokemon:
		return nodo as FollowerPokemon
	return null


func _avisar_follower(personaje: CharacterController) -> void:
	var follower: FollowerPokemon = _obtener_follower(personaje)
	if follower:
		follower.resetear_seguimiento()
