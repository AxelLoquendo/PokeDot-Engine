extends Node

## Probabilidad (0–1) de encuentro salvaje doble en hierba.
const WILD_DOUBLE_CHANCE: float = 50.0

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

		# Escalera lateral: el paso diagonal solo se dispara en try_stairs_step
		# al ENTRAR al tile. Si ya estás encima, no hacer nada aquí (movimiento normal).
		"stairs_right", "stairs_end_right", "stairs_left", "stairs_end_left":
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

	var inicio: Vector2 = personaje.position
	var distancia: float = float(personaje.TILE_SIZE * 2)
	var final: Vector2 = inicio + direccion * distancia
	var duracion: float = 0.4
	var altura: float = -16.0
	var casilla_despegue: Vector2i = personaje.casilla_actual
	var casilla_aterrizaje: Vector2i = personaje.posicion_a_casilla(final)

	# Follower: primero al borde (despegue), luego salta cuando el aterrizaje quede libre.
	var follower: FollowerPokemon = _obtener_follower(personaje)
	if follower and follower.has_method("notificar_rampa_jugador"):
		follower.notificar_rampa_jugador(direccion, casilla_despegue, casilla_aterrizaje)

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
		# No resetear_seguimiento: el follower saltará solo cuando se desocupe esta casilla.
	)


# ====================== PUERTA / HIERBA ======================

func comportamiento_puerta(_personaje: CharacterController) -> void:
	# TODO: lógica real de entrada a interiores
	pass



## Resta un paso de repelente al completar un movimiento del jugador.
func tick_repel(personaje: CharacterController) -> void:
	if personaje == null:
		return
	if not (personaje.character_data is CharacterPlayer):
		return
	var data: CharacterPlayer = personaje.character_data as CharacterPlayer
	if data == null or data.repel_steps <= 0:
		return
	data.repel_steps -= 1
	if data.repel_steps == 0:
		# El mensaje lo puede mostrar la UI del overworld si se conecta después.
		pass


func comportamiento_hierba(personaje: CharacterController) -> void:
	tick_repel(personaje)
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

	var data: CharacterPlayer = personaje.character_data as CharacterPlayer
	if data == null:
		return

	# Honey / forzar encuentro
	var force: bool = bool(data.get_meta("force_wild_encounter", false))
	if force:
		data.set_meta("force_wild_encounter", false)

	# Repel activo: no hay encuentros salvajes (salvo forzado)
	if data.repel_steps > 0 and not force:
		return

	# Illuminate + flautas (encounter_rate_modifier del jugador)
	var rate_mult: float = AbilityRuntime.wild_encounter_rate_multiplier(data.party)
	rate_mult *= data.encounter_rate_modifier
	if force:
		rate_mult = 999.0
	var salvaje: PokemonInstance = mapa.grass_encounters.intentar_encuentro(rate_mult)
	if salvaje == null:
		return

	var lead: PokemonInstance = _primer_pokemon_apto(data.party)
	if lead == null:
		return

	# Chance de combate doble salvaje
	var salvaje_2: PokemonInstance = null
	var formato: int = 0  # BattleManager.BattleFormat.SINGLE
	if randf() < WILD_DOUBLE_CHANCE:
		salvaje_2 = mapa.grass_encounters.intentar_encuentro(1.0)
		# Evitar null; si la tabla no tira otro mon, queda 1v1
		if salvaje_2 != null:
			var conscious: int = _contar_conscientes(data.party)
			if conscious >= 2:
				# 2v2: segundo lead del jugador
				formato = 3  # DOUBLE
			else:
				formato = 1  # ONE_V_TWO

	_iniciar_encuentro_salvaje(personaje, lead, salvaje, salvaje_2, formato)


func _primer_pokemon_apto(party: Array[PokemonInstance]) -> PokemonInstance:
	for mon: PokemonInstance in party:
		if mon != null and not mon.is_fainted():
			return mon
	return null


func _iniciar_encuentro_salvaje(
	personaje: CharacterController,
	lead: PokemonInstance,
	salvaje: PokemonInstance,
	salvaje_2: PokemonInstance = null,
	formato: int = 0
) -> void:
	BattleSession.preparar_salvaje(personaje, lead, salvaje, false, salvaje_2, formato)
	_correr_transicion_batalla(personaje)


func _contar_conscientes(party: Array[PokemonInstance]) -> int:
	var n: int = 0
	for mon: PokemonInstance in party:
		if mon != null and not mon.is_fainted():
			n += 1
	return n


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


# ====================== ESCALERAS (recta / función lineal) ======================
#
# Cada tramo es una recta de pendiente ±1 en el grid:
#   stairs_right:  y = -x + b   (subir →, bajar ←)
#   stairs_left:   y =  x + b   (subir ←, bajar →)
#
# Un “paso” = un escalón de esa recta. Sin ultima_escalera ni tweens.

## Dado el tipo de escalera y la tecla horizontal, devuelve el vector del peldaño.
static func stairs_step_for(behaviour: String, direccion: Vector2) -> Vector2:
	match behaviour:
		"stairs_right", "stairs_end_right":
			# Pendiente -1: derecha sube, izquierda baja
			if direccion == Vector2.RIGHT:
				return Vector2(1, -1)
			if direccion == Vector2.LEFT:
				return Vector2(-1, 1)
		"stairs_left", "stairs_end_left":
			# Pendiente +1: izquierda sube, derecha baja
			if direccion == Vector2.LEFT:
				return Vector2(-1, -1)
			if direccion == Vector2.RIGHT:
				return Vector2(1, 1)
	return Vector2.ZERO


## Solo al ENTRAR a un tile de escalera (desde fuera).
## Si ya estás encima, ←/→ es movimiento normal: no vuelve a subir/bajar en diagonal.
func try_stairs_step(personaje: CharacterController, direccion: Vector2) -> bool:
	if personaje == null:
		return false
	if direccion != Vector2.LEFT and direccion != Vector2.RIGHT:
		return false
	# Ya sobre un tile de escalera → no forzar diagonal
	if _casilla_es_escalera(personaje, personaje.casilla_actual):
		return false
	# Entrar: la casilla horizontal vecina tiene escalera
	var vecina: Vector2i = personaje.casilla_actual + Vector2i(direccion)
	var step: Vector2 = _stairs_step_en_casilla(personaje, vecina, direccion)
	if step == Vector2.ZERO:
		return false
	return _mover_escalera(personaje, step)


func _casilla_es_escalera(personaje: CharacterController, casilla: Vector2i) -> bool:
	return (
		_stairs_step_en_casilla(personaje, casilla, Vector2.RIGHT) != Vector2.ZERO
		or _stairs_step_en_casilla(personaje, casilla, Vector2.LEFT) != Vector2.ZERO
	)


func _stairs_step_en_casilla(
	personaje: CharacterController,
	casilla: Vector2i,
	direccion: Vector2
) -> Vector2:
	for capa: TileBehaviourLayer in personaje.capas_comportamiento:
		if not is_instance_valid(capa):
			continue
		var tile_data: TileData = capa.get_cell_tile_data(casilla)
		if tile_data == null or not tile_data.has_custom_data("behaviour"):
			continue
		var beh: String = str(tile_data.get_custom_data("behaviour"))
		var step: Vector2 = stairs_step_for(beh, direccion)
		if step != Vector2.ZERO:
			return step
	return Vector2.ZERO


## Inicia un peldaño diagonal con el movimiento normal del personaje.
## Devuelve true si el paso arrancó (para que intentar_mover no siga).
func _mover_escalera(personaje: CharacterController, desplazamiento: Vector2) -> bool:
	if personaje == null or desplazamiento == Vector2.ZERO:
		return false
	if personaje.is_moving or personaje.ejecutando_evento:
		return false

	var casilla_destino: Vector2i = personaje.casilla_actual + Vector2i(desplazamiento)
	if EventObjects.hay_otro_en_casilla(casilla_destino, personaje):
		return false

	var destino_global: Vector2 = (
		personaje.position + desplazamiento * float(personaje.TILE_SIZE)
	)
	# Respetar colisión de mapa en la casilla destino del peldaño
	if personaje.has_method("casilla_permitida") and not personaje.casilla_permitida(destino_global):
		return false
	if personaje.has_method("hay_personaje_en") and personaje.hay_personaje_en(destino_global):
		return false

	personaje.input_direction = desplazamiento
	personaje.initial_position = personaje.position
	personaje.casilla_reservada = casilla_destino
	EventObjects.reservar_casilla(casilla_destino, personaje)
	personaje.percent_moved_to_next_tile = 0.0
	personaje.is_moving = true

	if desplazamiento.x > 0.0:
		personaje.current_direction = CharacterController.Direction.EAST
	elif desplazamiento.x < 0.0:
		personaje.current_direction = CharacterController.Direction.WEST

	if personaje.has_method("reproducir_paso"):
		personaje.reproducir_paso()
	personaje.is_first_step = not personaje.is_first_step
	return true


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
