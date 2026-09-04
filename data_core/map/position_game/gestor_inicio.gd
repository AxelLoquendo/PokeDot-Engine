extends Node

@export var mapa_inicial: PackedScene
@export var casilla_inicio: Vector2i = Vector2i.ZERO

@onready var jugador: CharacterController = $Player

var map_manager: MapManager


func _ready() -> void:
	var datos_guardados: Dictionary = SaveManager.consume_pending_load()
	# Las referencias de ocupación pertenecen a la escena anterior y no deben
	# sobrevivir al cambio de partida/mapa.
	EventObjects.casillas_ocupadas.clear()
	EventObjects.casillas_reservadas.clear()

	var escena_mapa: PackedScene = mapa_inicial
	if not datos_guardados.is_empty():
		var ruta_mapa: String = str(MapSection.SECTION_TO_SCENE.get(int(datos_guardados.get("map_section", 0)), ""))
		if not ruta_mapa.is_empty() and ResourceLoader.exists(ruta_mapa):
			escena_mapa = load(ruta_mapa) as PackedScene
		else:
			push_warning("La partida apunta a un mapa no disponible; se cargará el mapa inicial.")

	if escena_mapa == null:
		push_error("Selecciona un mapa inicial.")
		return

	var mapa: MapAttributes = escena_mapa.instantiate() as MapAttributes
	if mapa == null:
		push_error("La escena inicial no tiene MapAttributes.")
		return

	# Crear gestor de mapas
	map_manager = MapManager.new()
	add_child(map_manager)
	map_manager.jugador = jugador

	# Cargar mapa inicial
	map_manager.load_map(mapa)

	# El jugador pertenece al gestor de mapas
	var posicion_global: Vector2 = jugador.global_position
	jugador.reparent(map_manager)
	jugador.global_position = posicion_global

	# Colocar jugador inicial o restaurar su posición guardada.
	if datos_guardados.has("player_position"):
		var posicion_guardada: Variant = datos_guardados.get("player_position", [])
		var posicion: Array = posicion_guardada as Array if posicion_guardada is Array else []
		if posicion.size() >= 2:
			jugador.global_position = Vector2(float(posicion[0]), float(posicion[1]))
	else:
		jugador.global_position = jugador.snap_to_grid(
			Vector2(
				casilla_inicio.x * jugador.TILE_SIZE + 8,
				casilla_inicio.y * jugador.TILE_SIZE
			)
		)

	var datos_jugador: CharacterPlayer = jugador.character_data as CharacterPlayer
	print(SaveManager.pending_new_character)

	if datos_jugador and not datos_guardados.is_empty():
		datos_jugador.money = int(datos_guardados.get("player_money", datos_jugador.money))
		var nombre_guardado: String = str(datos_guardados.get("player_name", ""))
		if not nombre_guardado.is_empty():
			datos_jugador.name = nombre_guardado
		SaveManager.restore_player_collection(datos_jugador, datos_guardados)
	elif datos_jugador and not SaveManager.pending_new_character.is_empty():
		var pendiente: Dictionary = SaveManager.pending_new_character
		datos_jugador.name = str(pendiente.get("name", datos_jugador.name))
		datos_jugador.gender = int(pendiente.get("gender", datos_jugador.gender))
		datos_jugador.sprite_overworld = int(pendiente.get("sprite_overworld", datos_jugador.sprite_overworld)) as EventObjects.PlayerID
		datos_jugador.created_at = str(pendiente.get("created_at", datos_jugador.created_at))
		datos_jugador.trainer_id = int(pendiente.get("trainer_id", 0))
		SaveManager.pending_new_character.clear()

	# DEBUG: equipo de prueba si el party está vacío
	if datos_jugador and datos_jugador.party.is_empty():
		_dar_party_debug(datos_jugador)

	var personajes: Array[Node] = map_manager.current_map.find_children(
		"*",
		"CharacterController",
		true,
		false
	)
	personajes.append(jugador)

	for personaje: Node in personajes:
		var controlador: CharacterController = personaje as CharacterController
		if controlador == null:
			continue
		controlador.sincronizar_con_mapa(map_manager.current_map, map_manager)

	jugador.casilla_actual = jugador.posicion_a_casilla(jugador.global_position)
	EventObjects.registrar_casilla(jugador.casilla_actual, jugador)

	map_manager.current_map.activar_musica()
	map_manager.current_map.trigger_map_scripts(MapScriptEntry.Trigger.ON_LOAD)

	if DnsManager:
		DnsManager.activar()
	if CloudsManager:
		CloudsManager.activar()


func _dar_party_debug(datos: CharacterPlayer) -> void:
	var equipo: Array[PokemonInstance] = [
		PokemonInstance.create(Species.SpeciesID.SPECIES_BULBASAUR, 5),
		PokemonInstance.create(Species.SpeciesID.SPECIES_CHARMANDER, 5),
		PokemonInstance.create(Species.SpeciesID.SPECIES_SQUIRTLE, 5),
		PokemonInstance.create(Species.SpeciesID.SPECIES_GRENINJA_BOND, 36),
		PokemonInstance.create(Species.SpeciesID.SPECIES_GRENINJA_MEGA, 36),
		PokemonInstance.create(Species.SpeciesID.SPECIES_GRENINJA_ASH, 36),
	]
	for mon: PokemonInstance in equipo:
		if mon == null:
			continue
		datos.add_pokemon(mon)
