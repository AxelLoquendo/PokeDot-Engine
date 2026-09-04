extends Node
## Puente overworld ↔ batalla. No destruye el mapa.

signal battle_finished(result: int)

enum BattleResult {
	WIN,
	LOSE,
	RUN,
	CAUGHT,
}



var is_active: bool = false
var is_wild: bool = true
var player_pokemon: PokemonInstance = null
var enemy_pokemon: PokemonInstance = null
var enemy_party: Array[PokemonInstance] = []
var player_controller: CharacterController = null

var _battle_layer: CanvasLayer = null
const BATTLE_SCENE: PackedScene = preload("res://scenes/ui_battle/battle.tscn")

var battle_background: BattleBackground.Background = BattleBackground.Background.BG_LONG_GRASS

## Tipo de combate: determina qué música suena.
## El escenario visual sigue viniendo del mapa (MapAttributes.battle_scene).
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

var battle_type: BattleType = BattleType.WILD
var battle_music: SFXGame.BattleMusicID = SFXGame.BattleMusicID.BGM_BATTLE_WILD



func preparar_salvaje(jugador: CharacterController, lead: PokemonInstance, salvaje: PokemonInstance, es_roaming: bool = false) -> void:
	player_controller = jugador
	player_pokemon = lead
	enemy_pokemon = salvaje
	is_wild = true
	_configurar_combate(jugador, BattleType.ROAMING if es_roaming else BattleType.WILD)

func preparar_entrenador(jugador: CharacterController, lead: PokemonInstance, party_rival: Array[PokemonInstance], tipo: BattleType = BattleType.TRAINER) -> void:
	player_controller = jugador
	player_pokemon = lead
	enemy_party = party_rival
	enemy_pokemon = party_rival[0] if not party_rival.is_empty() else null
	is_wild = false
	_configurar_combate(jugador, tipo)

func _obtener_escenario(jugador: CharacterController) -> BattleBackground.Background:
	if jugador == null:
		return BattleBackground.Background.BG_LONG_GRASS
	var mapa: MapAttributes = jugador.mapa_raiz as MapAttributes
	if mapa == null:
		return BattleBackground.Background.BG_LONG_GRASS
	return mapa.battle_scene

func _configurar_combate(jugador: CharacterController, tipo: BattleType) -> void:
	battle_type = tipo
	battle_music = BATTLE_MUSIC_BY_TYPE.get(tipo, SFXGame.BattleMusicID.BGM_BATTLE_WILD)

	var mapa: MapAttributes = jugador.mapa_raiz as MapAttributes if jugador else null
	battle_background = mapa.battle_scene if mapa != null else BattleBackground.Background.BG_LONG_GRASS

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

	var batalla: Node = BATTLE_SCENE.instantiate()
	_battle_layer.add_child(batalla)


func finalizar(result: int) -> void:
	if _battle_layer != null and is_instance_valid(_battle_layer):
		_battle_layer.queue_free()
	_battle_layer = null

	is_active = false

	if player_controller != null and is_instance_valid(player_controller):
		player_controller.ejecutando_evento = false
		var mapa: MapAttributes = player_controller.mapa_raiz as MapAttributes
		if mapa != null:
			MusicManager.reproducir_mapa(mapa.map_music)

	player_pokemon = null
	enemy_pokemon = null
	enemy_party = []
	player_controller = null

	battle_finished.emit(result)

func tiene_datos() -> bool:
	return player_pokemon != null and enemy_pokemon != null
