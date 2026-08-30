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


func preparar_salvaje(jugador: CharacterController, lead: PokemonInstance, salvaje: PokemonInstance) -> void:
	player_controller = jugador
	player_pokemon = lead
	enemy_pokemon = salvaje
	is_wild = true

func preparar_entrenador(jugador: CharacterController, lead: PokemonInstance, party_rival: Array[PokemonInstance]) -> void:
	player_controller = jugador
	player_pokemon = lead
	enemy_party = party_rival
	enemy_pokemon = party_rival[0] if not party_rival.is_empty() else null
	is_wild = false

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

	player_pokemon = null
	enemy_pokemon = null
	enemy_party = []
	player_controller = null

	battle_finished.emit(result)


func tiene_datos() -> bool:
	return player_pokemon != null and enemy_pokemon != null
