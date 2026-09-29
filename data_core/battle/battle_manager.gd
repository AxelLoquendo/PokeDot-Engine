
extends Node
class_name BattleManager
## Shim de compatibilidad: misma superficie pública que el monolito.
## Toda la lógica vive en BattleMain + módulos battle_*.gd.

enum TerrainId {
	TERRAIN_NONE,
	TERRAIN_ELECTRIC,
	TERRAIN_GRASSY,
	TERRAIN_MISTY,
	TERRAIN_PSYCHIC,
}

signal message(text: String)
signal hp_changed(is_player_side: bool, current_hp: int, max_hp: int, slot: int)
signal player_progress_changed
signal battle_ended(player_won: bool)
signal turn_ended
signal player_must_switch
signal player_switch_resolved
signal player_evolved
signal ability_announced(is_player: bool, pokemon: PokemonInstance)
signal ability_bar_finished
signal battler_appearance_changed(is_player: bool)
signal illusion_broken(is_player: bool)
signal pokemon_entered_field(is_player: bool)
signal terrain_changed(terrain: int)
signal weather_changed(weather: int, primal: bool)

var _core: BattleMain = BattleMain.new()


func _ready() -> void:
	_wire_signals()


func _wire_signals() -> void:
	_core.message.connect(func(t: String) -> void: message.emit(t))
	_core.hp_changed.connect(
		func(side: bool, cur: int, mx: int, slot: int) -> void: hp_changed.emit(side, cur, mx, slot)
	)
	_core.player_progress_changed.connect(func() -> void: player_progress_changed.emit())
	_core.battle_ended.connect(func(w: bool) -> void: battle_ended.emit(w))
	_core.turn_ended.connect(func() -> void: turn_ended.emit())
	_core.player_must_switch.connect(func() -> void: player_must_switch.emit())
	_core.player_switch_resolved.connect(func() -> void: player_switch_resolved.emit())
	_core.ability_announced.connect(
		func(side: bool, mon: PokemonInstance) -> void: ability_announced.emit(side, mon)
	)
	_core.battler_appearance_changed.connect(
		func(side: bool) -> void: battler_appearance_changed.emit(side)
	)
	_core.pokemon_entered_field.connect(
		func(side: bool) -> void: pokemon_entered_field.emit(side)
	)
	_core.terrain_changed.connect(func(t: int) -> void: terrain_changed.emit(t))
	_core.weather_changed.connect(
		func(w: int, p: bool) -> void: weather_changed.emit(w, p)
	)
	_core.player_evolved.connect(func() -> void: player_evolved.emit())
	_core.ability_bar_finished.connect(func() -> void: ability_bar_finished.emit())
	_core.illusion_broken.connect(func(side: bool) -> void: illusion_broken.emit(side))


var player: BattleBattler:
	get:
		return _core.player
var enemy: BattleBattler:
	get:
		return _core.enemy
var player_actives: Array[BattleBattler]:
	get:
		return _core.player_actives
var enemy_actives: Array[BattleBattler]:
	get:
		return _core.enemy_actives
var player_party: Array[PokemonInstance]:
	get:
		return _core.player_party
var enemy_party: Array[PokemonInstance]:
	get:
		return _core.enemy_party
var player_side: FieldSide:
	get:
		return _core.player_side
	set(v):
		_core.player_side = v
var enemy_side: FieldSide:
	get:
		return _core.enemy_side
	set(v):
		_core.enemy_side = v
var is_running: bool:
	get:
		return _core.is_running
	set(v):
		_core.is_running = v
var is_trainer_battle: bool:
	get:
		return _core.is_trainer_battle
var trainer_name: String:
	get:
		return _core.trainer_name
	set(v):
		_core.trainer_name = v
var weather: int:
	get:
		return _core.weather
	set(v):
		_core.weather = v
var weather_turns: int:
	get:
		return _core.weather_turns
	set(v):
		_core.weather_turns = v
var weather_primal: bool:
	get:
		return _core.state.weather_primal if _core.state != null else false
	set(v):
		if _core.state != null:
			_core.state.weather_primal = v
var terrain: int:
	get:
		return _core.terrain
	set(v):
		_core.terrain = v
var terrain_turns: int:
	get:
		return _core.terrain_turns
	set(v):
		_core.terrain_turns = v
var battle_turn_count: int:
	get:
		return _core.battle_turn_count
	set(v):
		_core.battle_turn_count = v
var trick_room_turns: int:
	get:
		return _core.trick_room_turns
	set(v):
		_core.trick_room_turns = v
var gravity_turns: int:
	get:
		return _core.gravity_turns
	set(v):
		_core.gravity_turns = v
var wonder_room_turns: int:
	get:
		return _core.state.wonder_room_turns if _core.state != null else 0
	set(v):
		if _core.state != null:
			_core.state.wonder_room_turns = v
var magic_room_turns: int:
	get:
		return _core.state.magic_room_turns if _core.state != null else 0
	set(v):
		if _core.state != null:
			_core.state.magic_room_turns = v
var exp_participants: Array[PokemonInstance]:
	get:
		return _core.exp_participants
	set(v):
		_core.exp_participants = v
var last_move_used_field: MoveData = null
var last_move_user_was_player: bool = false
var is_underwater: bool = false
var is_dark_place: bool = false


func start_battle(
	player_lead: PokemonInstance,
	enemy_lead: PokemonInstance,
	player_party_in: Array[PokemonInstance] = [],
	enemy_party_in: Array[PokemonInstance] = [],
	format: int = 0,
	is_wild: bool = true
) -> void:
	_core.start_battle(
		player_lead,
		enemy_lead,
		player_party_in,
		enemy_party_in,
		format as BattleState.BattleFormat,
		is_wild
	)


func start_battle_intro() -> void:
	await _core.start_battle_intro()


func player_choose_move(slot_index: int, actor_slot: int = 0, target_slot: int = -1) -> void:
	await _core.player_choose_move(slot_index, actor_slot, target_slot)


func player_choose_switch(
	nuevo: PokemonInstance,
	free_switch: bool = false,
	slot_index: int = -1
) -> void:
	await _core.player_choose_switch(nuevo, free_switch, slot_index)


func player_choose_run() -> void:
	await _core.player_choose_run()


func player_choose_item(
	item_id: Items.ItemId,
	target: PokemonInstance = null,
	move_slot_index: int = -1
) -> void:
	await _core.player_choose_item(item_id, target, move_slot_index)


func is_multi_battle() -> bool:
	return _core.is_multi_battle()


func get_all_actives() -> Array[BattleBattler]:
	return _core.get_all_actives()


func get_side_actives(is_player_side: bool) -> Array[BattleBattler]:
	return _core.get_side_actives(is_player_side)


func get_ally(battler: BattleBattler) -> BattleBattler:
	return _core.get_ally(battler)


func get_opponents(battler: BattleBattler) -> Array[BattleBattler]:
	return _core.get_opponents(battler)


func side_has_conscious(is_player_side: bool) -> bool:
	return _core.side_has_conscious(is_player_side)


func party_has_reserve(is_player_side: bool) -> bool:
	return _core.party_has_reserve(is_player_side)


func get_effective_weather() -> int:
	return _core.get_effective_weather()


func set_weather(new_weather: int, turns: int, primal: bool = false) -> void:
	_core.set_weather(new_weather, turns, primal)


func set_terrain(new_terrain: int, turns: int = 5) -> void:
	_core.set_terrain(new_terrain, turns)


func mark_exp_participant(mon: PokemonInstance) -> void:
	_core.mark_exp_participant(mon)


func ability_announce(battler: BattleBattler) -> void:
	await _core.ability_announce(battler)


func ability_change_stat(
	battler: BattleBattler,
	stat: PokemonInstance.Stat,
	stages: int,
	caused_by_foe: bool = false
) -> void:
	await _core.ability_change_stat(battler, stat, stages, caused_by_foe)


func ability_apply_status(
	battler: BattleBattler,
	status: PokemonInstance.Status,
	source: BattleBattler
) -> void:
	await _core.ability_apply_status(battler, status, source)


func ability_deal_damage(battler: BattleBattler, amount: int, cause: BattleBattler) -> void:
	_core.ability_deal_damage(battler, amount, cause)


func ability_heal(battler: BattleBattler, amount: int) -> void:
	_core.ability_heal(battler, amount)


func ability_cure_status(battler: BattleBattler) -> void:
	_core.ability_cure_status(battler)


func _wait(seconds: float) -> void:
	await _core._wait(seconds)


func _emit_hp(is_player_side: bool) -> void:
	_core._emit_hp(is_player_side)


func _emit_hp_battler(battler: BattleBattler) -> void:
	_core._emit_hp_battler(battler)


func _side_for(battler: BattleBattler) -> FieldSide:
	return _core._side_for(battler)


func end_battle_cleanup() -> void:
	_core.end_battle_cleanup()


func await_forced_player_switch(mid_turn: bool = false) -> void:
	await _core.await_forced_player_switch(mid_turn)


func _sync_primary_refs() -> void:
	_core.state.sync_primary_refs()


func party_has_conscious(is_player_side: bool) -> bool:
	return BattleUtil.party_has_conscious(self, is_player_side)
