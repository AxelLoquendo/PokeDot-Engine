extends Node
## Puente overworld ↔ batalla. No destruye el mapa.
## Elige escena 1v1 o dobles según battle_format (commit 9e8ce44).

signal battle_finished(result: int)

enum BattleResult {
	WIN,
	LOSE,
	RUN,
	CAUGHT,
}

enum BattleType {
	WILD,
	ROAMING,
	TRAINER,
	GYM_LEADER,
	ELITE_FOUR,
	CHAMPION,
	RAID_BASIC,
	RAID_MAX,
	RAID_TERA,
	RAID_ULTRA,
}

const BATTLE_SCENE_SINGLE: PackedScene = preload("res://scenes/ui_battle/battle.tscn")
const BATTLE_SCENE_DOUBLE: PackedScene = preload("res://scenes/ui_battle/battle_double.tscn")

const BATTLE_MUSIC_BY_TYPE: Dictionary = {
	BattleType.WILD: SFXGame.BattleMusicID.BGM_BATTLE_WILD,
	BattleType.ROAMING: SFXGame.BattleMusicID.BGM_BATTLE_ROAMING,
	BattleType.TRAINER: SFXGame.BattleMusicID.BGM_BATTLE_TRAINER,
	BattleType.GYM_LEADER: SFXGame.BattleMusicID.BGM_BATTLE_GYM_LEADER,
	BattleType.ELITE_FOUR: SFXGame.BattleMusicID.BGM_BATTLE_ELITE,
	BattleType.CHAMPION: SFXGame.BattleMusicID.BGM_BATTLE_CHAMPION,
	BattleType.RAID_BASIC: SFXGame.BattleMusicID.BGM_RAID_BASIC_BATTLE_1,
	BattleType.RAID_MAX: SFXGame.BattleMusicID.BGM_RAID_MAX_BATTLE_1,
	BattleType.RAID_TERA: SFXGame.BattleMusicID.BGM_RAID_TERA_BATTLE_1,
	BattleType.RAID_ULTRA: SFXGame.BattleMusicID.BGM_RAID_ULTRA_BATTLE_1,
}

var is_active: bool = false
var is_wild: bool = true
var player_pokemon: PokemonInstance = null
var enemy_pokemon: PokemonInstance = null
var enemy_party: Array[PokemonInstance] = []
var player_controller: CharacterController = null
var player_leads: Array[PokemonInstance] = []

var _battle_layer: CanvasLayer = null

var battle_background: BattleBackground.Background = BattleBackground.Background.BG_LONG_GRASS
var battle_type: BattleType = BattleType.WILD
var battle_music: SFXGame.BattleMusicID = SFXGame.BattleMusicID.BGM_BATTLE_WILD

## 0 SINGLE, 1 ONE_V_TWO, 2 TWO_V_ONE, 3 DOUBLE (BattleState.BattleFormat)
var battle_format: int = 0

var trainer_name: String = ""
var trainer_money: int = 0


func preparar_salvaje(
	jugador: CharacterController,
	lead: PokemonInstance,
	salvaje: PokemonInstance,
	es_roaming: bool = false,
	salvaje_2: PokemonInstance = null,
	formato: int = 0
) -> void:
	player_controller = jugador
	player_pokemon = lead
	enemy_pokemon = salvaje
	var leads: Array[PokemonInstance] = []
	if lead != null:
		leads.append(lead)
	player_leads = leads
	enemy_party.clear()
	if salvaje != null:
		enemy_party.append(salvaje)
	if salvaje_2 != null:
		enemy_party.append(salvaje_2)
	is_wild = true
	battle_format = formato
	var tipo: BattleType = BattleType.ROAMING if es_roaming else BattleType.WILD
	_configurar_combate(jugador, tipo)


func preparar_multi(
	jugador: CharacterController,
	leads: Array[PokemonInstance],
	enemy_leads: Array[PokemonInstance],
	full_enemy_party: Array[PokemonInstance],
	formato: int,
	tipo: BattleType = BattleType.TRAINER
) -> void:
	player_controller = jugador
	player_leads = leads.duplicate()
	player_pokemon = leads[0] if not leads.is_empty() else null
	enemy_pokemon = enemy_leads[0] if not enemy_leads.is_empty() else null
	enemy_party = full_enemy_party.duplicate()
	is_wild = (tipo == BattleType.WILD or tipo == BattleType.ROAMING)
	battle_format = formato
	_configurar_combate(jugador, tipo)


func preparar_entrenador(
	jugador: CharacterController,
	lead: PokemonInstance,
	party_rival: Array[PokemonInstance],
	tipo: BattleType = BattleType.TRAINER
) -> void:
	player_controller = jugador
	player_pokemon = lead
	var leads: Array[PokemonInstance] = []
	if lead != null:
		leads.append(lead)
	player_leads = leads
	enemy_party = party_rival
	enemy_pokemon = party_rival[0] if not party_rival.is_empty() else null
	is_wild = false
	battle_format = 0
	_configurar_combate(jugador, tipo)


func preparar_desde_entrenador(jugador: CharacterController, trainer: TrainerData) -> bool:
	var datos: CharacterPlayer = jugador.character_data as CharacterPlayer if jugador else null
	if datos == null:
		push_error("BattleSession: el jugador no tiene datos de partida")
		return false
	var disponibles: Array[PokemonInstance] = []
	for mon: PokemonInstance in datos.party:
		if mon != null and not mon.is_fainted():
			disponibles.append(mon)
	var rivales: Array[PokemonInstance] = trainer.build_party()
	if disponibles.is_empty() or rivales.is_empty():
		push_warning("BattleSession: %s no puede combatir (equipo vacío)" % trainer.trainer_id)
		return false

	var tipo: BattleType = trainer.battle_type as BattleType
	if trainer.double_battle and rivales.size() >= 2:
		var formato: int = 3 if disponibles.size() >= 2 else 1  # DOUBLE / ONE_V_TWO
		var n_player: int = 2 if formato == 3 else 1
		preparar_multi(
			jugador,
			disponibles.slice(0, n_player),
			rivales.slice(0, 2),
			rivales,
			formato,
			tipo
		)
	else:
		battle_format = 0
		preparar_entrenador(jugador, disponibles[0], rivales, tipo)
	trainer_name = trainer.get_display_name()
	trainer_money = trainer.money
	return true


func _configurar_combate(jugador: CharacterController, tipo: BattleType) -> void:
	battle_type = tipo
	battle_music = BATTLE_MUSIC_BY_TYPE.get(tipo, SFXGame.BattleMusicID.BGM_BATTLE_WILD)
	var mapa: MapAttributes = jugador.mapa_raiz as MapAttributes if jugador else null
	battle_background = mapa.battle_scene if mapa != null else BattleBackground.Background.BG_LONG_GRASS
	_registrar_vistos(jugador)


func _registrar_vistos(jugador: CharacterController) -> void:
	if jugador == null:
		return
	var data: CharacterPlayer = jugador.character_data as CharacterPlayer
	if data == null:
		return
	var dex: PokedexData = null
	if data.has_method("ensure_pokedex"):
		dex = data.ensure_pokedex()
	else:
		dex = data.pokedex
	if dex == null:
		return
	for mon: PokemonInstance in enemy_party:
		if mon != null:
			dex.set_seen(int(mon.species_id))
	if enemy_pokemon != null:
		dex.set_seen(int(enemy_pokemon.species_id))


func is_multi_format() -> bool:
	return battle_format != 0


func scene_for_format() -> PackedScene:
	return BATTLE_SCENE_DOUBLE if is_multi_format() else BATTLE_SCENE_SINGLE


func iniciar_como_overlay(parent: Node) -> void:
	if is_active:
		return
	if player_pokemon == null or enemy_pokemon == null:
		push_warning("BattleSession: faltan Pokémon para iniciar la batalla")
		return
	if parent == null:
		push_warning("BattleSession: parent nulo")
		return

	is_active = true
	if player_controller != null:
		player_controller.ejecutando_evento = true

	_battle_layer = CanvasLayer.new()
	_battle_layer.name = "BattleOverlay"
	_battle_layer.layer = 100
	parent.add_child(_battle_layer)

	var batalla: Node = scene_for_format().instantiate()
	_battle_layer.add_child(batalla)


func finalizar(result: int) -> void:
	if _battle_layer != null and is_instance_valid(_battle_layer):
		_battle_layer.queue_free()
	_battle_layer = null

	is_active = false

	if result == BattleResult.WIN or result == BattleResult.CAUGHT:
		if player_controller != null and is_instance_valid(player_controller):
			var data: CharacterPlayer = player_controller.character_data as CharacterPlayer
			if data != null and data.party != null:
				AbilityRuntime.try_pickup_after_battle(data.party)
				AbilityRuntime.try_honey_gather_after_battle(data.party)
				if result == BattleResult.WIN and not is_wild:
					data.money += trainer_money

	if player_controller != null and is_instance_valid(player_controller):
		player_controller.ejecutando_evento = false
		var mapa: MapAttributes = player_controller.mapa_raiz as MapAttributes
		if mapa != null:
			MusicManager.reproducir_mapa(mapa.map_music)

	player_pokemon = null
	enemy_pokemon = null
	enemy_party = []
	player_leads = []
	player_controller = null
	trainer_name = ""
	trainer_money = 0
	battle_format = 0

	battle_finished.emit(result)


func tiene_datos() -> bool:
	return player_pokemon != null and enemy_pokemon != null
