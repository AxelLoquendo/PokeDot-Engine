extends RefCounted
class_name BattleState
## Estado mutable del combate. El orquestador (BattleManager / BattleMain)
## posee una instancia; los módulos de lógica leen y escriben aquí.
## No emite señales ni hace await: solo datos.

enum BattleFormat {
	SINGLE,    ## 1 vs 1
	ONE_V_TWO, ## 1 vs 2
	TWO_V_ONE, ## 2 vs 1
	DOUBLE,    ## 2 vs 2
}

enum TerrainId {
	TERRAIN_NONE,
	TERRAIN_ELECTRIC,
	TERRAIN_GRASSY,
	TERRAIN_MISTY,
	TERRAIN_PSYCHIC,
}

## ─── Formato y bandos ───────────────────────────────────────────────
var format: BattleFormat = BattleFormat.SINGLE
var is_trainer_battle: bool = false
var trainer_name: String = ""

var player_party: Array[PokemonInstance] = []
var enemy_party: Array[PokemonInstance] = []

## Activos en campo (índice = slot). Puede haber null / fainted.
var player_actives: Array[BattleBattler] = []
var enemy_actives: Array[BattleBattler] = []

## Compat 1v1: apuntan al slot 0 de cada lado.
var player: BattleBattler = null
var enemy: BattleBattler = null

var player_side: FieldSide = FieldSide.new()
var enemy_side: FieldSide = FieldSide.new()

## ─── Campo global ──────────────────────────────────────────────────
var weather: int = AbilityBattleEffect.weatherAbilityID.WEATHER_NONE
var weather_turns: int = -1
var weather_primal: bool = false
var terrain: int = TerrainId.TERRAIN_NONE
var terrain_turns: int = 0

var trick_room_turns: int = 0
var wonder_room_turns: int = 0
var magic_room_turns: int = 0
var gravity_turns: int = 0

## Turnos de combate completados (útil Quick/Timer Ball).
var battle_turn_count: int = 0

var last_move_used_field: MoveData = null
var last_move_user_was_player: bool = false

## Contexto de captura / encuentro
var is_underwater: bool = false
var is_dark_place: bool = false
var is_fishing: bool = false

## ─── Control de flujo (lo gestiona el orquestador, vive aquí) ─────
var is_running: bool = false
var awaiting_player_switch: bool = false
var player_switch_mid_turn: bool = false
var pending_player_actions: Array[BattleAction] = []
var escape_attempts: int = 0

## EXP
var exp_participants: Array[PokemonInstance] = []
## instance_id del mon enemigo -> true si ya se otorgó EXP
var exp_awarded_to: Dictionary = {}


func reset_field_effects() -> void:
	weather = AbilityBattleEffect.weatherAbilityID.WEATHER_NONE
	weather_turns = -1
	weather_primal = false
	terrain = TerrainId.TERRAIN_NONE
	terrain_turns = 0
	trick_room_turns = 0
	wonder_room_turns = 0
	magic_room_turns = 0
	gravity_turns = 0
	battle_turn_count = 0
	last_move_used_field = null
	last_move_user_was_player = false
	player_side = FieldSide.new()
	enemy_side = FieldSide.new()
	pending_player_actions.clear()
	exp_participants.clear()
	exp_awarded_to.clear()
	escape_attempts = 0


func player_slot_count() -> int:
	match format:
		BattleFormat.SINGLE, BattleFormat.ONE_V_TWO:
			return 1
		BattleFormat.TWO_V_ONE, BattleFormat.DOUBLE:
			return 2
	return 1


func enemy_slot_count() -> int:
	match format:
		BattleFormat.SINGLE, BattleFormat.TWO_V_ONE:
			return 1
		BattleFormat.ONE_V_TWO, BattleFormat.DOUBLE:
			return 2
	return 1


func is_multi_battle() -> bool:
	return format != BattleFormat.SINGLE


func sync_primary_refs() -> void:
	player = player_actives[0] if not player_actives.is_empty() else null
	enemy = enemy_actives[0] if not enemy_actives.is_empty() else null


func get_all_actives() -> Array[BattleBattler]:
	var result: Array[BattleBattler] = []
	for b: BattleBattler in player_actives:
		if b != null:
			result.append(b)
	for b2: BattleBattler in enemy_actives:
		if b2 != null:
			result.append(b2)
	return result


func get_side_actives(is_player_side: bool) -> Array[BattleBattler]:
	return player_actives if is_player_side else enemy_actives


func get_side(is_player_side: bool) -> FieldSide:
	return player_side if is_player_side else enemy_side


func side_for(battler: BattleBattler) -> FieldSide:
	if battler == null:
		return player_side
	return player_side if battler.is_player_side else enemy_side


func get_party(is_player_side: bool) -> Array[PokemonInstance]:
	return player_party if is_player_side else enemy_party


func is_weather_suppressed() -> bool:
	for b: BattleBattler in get_all_actives():
		if b == null or b.is_fainted():
			continue
		if AbilityRuntime.has(b, AbilityId.Id.CLOUD_NINE) \
				or AbilityRuntime.has(b, AbilityId.Id.AIR_LOCK):
			return true
	return false


func get_effective_weather() -> int:
	if is_weather_suppressed():
		return AbilityBattleEffect.weatherAbilityID.WEATHER_NONE
	return weather
