

extends RefCounted
class_name BattleMain
## Orquestador del combate. Posee BattleState y delega en módulos de fase.
##
## Fase de migración: expone la misma API pública que usaba BattleManager
## para que la UI (battle.gd) pueda apuntar aquí cuando esté listo.
## Mientras tanto BattleManager puede reenviar a estos métodos.

signal message(text: String)
signal hp_changed(is_player: bool, current_hp: int, max_hp: int, slot: int)
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

var state: BattleState = BattleState.new()

## Compat: propiedades que la UI y AbilityRuntime leen en "battle.*"
var player: BattleBattler:
	get:
		return state.player
	set(v):
		state.player = v

var enemy: BattleBattler:
	get:
		return state.enemy
	set(v):
		state.enemy = v

var player_actives: Array[BattleBattler]:
	get:
		return state.player_actives
	set(v):
		state.player_actives = v

var enemy_actives: Array[BattleBattler]:
	get:
		return state.enemy_actives
	set(v):
		state.enemy_actives = v

var player_party: Array[PokemonInstance]:
	get:
		return state.player_party
	set(v):
		state.player_party = v

var enemy_party: Array[PokemonInstance]:
	get:
		return state.enemy_party
	set(v):
		state.enemy_party = v

var player_side: FieldSide:
	get:
		return state.player_side
	set(v):
		state.player_side = v

var enemy_side: FieldSide:
	get:
		return state.enemy_side
	set(v):
		state.enemy_side = v

var is_running: bool:
	get:
		return state.is_running
	set(v):
		state.is_running = v

var is_trainer_battle: bool:
	get:
		return state.is_trainer_battle
	set(v):
		state.is_trainer_battle = v

var trainer_name: String:
	get:
		return state.trainer_name
	set(v):
		state.trainer_name = v

var format: BattleState.BattleFormat:
	get:
		return state.format
	set(v):
		state.format = v

var weather: int:
	get:
		return state.weather
	set(v):
		state.weather = v

var weather_turns: int:
	get:
		return state.weather_turns
	set(v):
		state.weather_turns = v

var terrain: int:
	get:
		return state.terrain
	set(v):
		state.terrain = v

var terrain_turns: int:
	get:
		return state.terrain_turns
	set(v):
		state.terrain_turns = v

var battle_turn_count: int:
	get:
		return state.battle_turn_count
	set(v):
		state.battle_turn_count = v

var trick_room_turns: int:
	get:
		return state.trick_room_turns
	set(v):
		state.trick_room_turns = v

var gravity_turns: int:
	get:
		return state.gravity_turns
	set(v):
		state.gravity_turns = v

var exp_participants: Array[PokemonInstance]:
	get:
		return state.exp_participants
	set(v):
		state.exp_participants = v

var _player_controller: BattleControllerPlayer = BattleControllerPlayer.new()
var _opponent_controller: BattleControllerOpponent = BattleControllerOpponent.new()


func start_battle(
	player_pokemon: PokemonInstance,
	enemy_pokemon: PokemonInstance,
	party: Array[PokemonInstance] = [],
	enemy_trainer_party: Array[PokemonInstance] = [],
	p_format: BattleState.BattleFormat = BattleState.BattleFormat.SINGLE,
	p_is_wild: bool = false
) -> void:
	BattleSetup.build_field(
		state,
		player_pokemon,
		enemy_pokemon,
		party,
		enemy_trainer_party,
		int(p_format),
		p_is_wild
	)
	# Sincronizar refs públicas
	state.sync_primary_refs()
	# Illusion necesita el orquestador (señales + parties), no el BattleState
	for battler: BattleBattler in state.get_all_actives():
		if battler != null:
			AbilityRuntime.prepare_illusion(battler, self)


func start_battle_intro() -> void:
	await BattleIntro.run(self)



func is_multi_battle() -> bool:
	return state.is_multi_battle()


func get_all_actives() -> Array[BattleBattler]:
	return state.get_all_actives()


func get_side_actives(is_player_side: bool) -> Array[BattleBattler]:
	return state.get_side_actives(is_player_side)


func get_ally(battler: BattleBattler) -> BattleBattler:
	return BattleUtil.get_ally(state, battler)


func get_opponents(battler: BattleBattler) -> Array[BattleBattler]:
	return BattleUtil.get_opponents(state, battler)


func side_has_conscious(is_player_side: bool) -> bool:
	return BattleUtil.side_has_conscious(state, is_player_side)


func party_has_reserve(is_player_side: bool) -> bool:
	return BattleUtil.party_has_reserve(state, is_player_side)


func get_effective_weather() -> int:
	return state.get_effective_weather()


func is_weather_suppressed() -> bool:
	return state.is_weather_suppressed()


func _player_slot_count() -> int:
	return state.player_slot_count()


func _enemy_slot_count() -> int:
	return state.enemy_slot_count()


func _side_for(battler: BattleBattler) -> FieldSide:
	return state.side_for(battler)


func _emit_hp(is_player_side: bool) -> void:
	var actives: Array[BattleBattler] = state.get_side_actives(is_player_side)
	for b: BattleBattler in actives:
		if b != null and b.pokemon != null:
			_emit_hp_battler(b)


func _emit_hp_battler(battler: BattleBattler) -> void:
	if battler == null or battler.pokemon == null:
		return
	hp_changed.emit(
		battler.is_player_side,
		battler.get_current_hp(),
		battler.get_max_hp(),
		battler.slot_index
	)


func _wait(seconds: float) -> void:
	await Engine.get_main_loop().create_timer(seconds).timeout


func set_weather(new_weather: int, turns: int, primal: bool = false) -> void:
	state.weather = new_weather
	state.weather_turns = turns
	state.weather_primal = primal
	weather_changed.emit(new_weather, primal)


func set_terrain(new_terrain: int, turns: int = 5) -> void:
	state.terrain = new_terrain
	state.terrain_turns = turns
	terrain_changed.emit(new_terrain)


## Acciones del jugador (la UI llama esto). En multi acumula hasta tener todos.
func player_choose_move(slot_index: int, actor_slot: int = 0, target_slot: int = -1) -> void:
	if not state.is_running:
		return
	if not side_has_conscious(true) or not side_has_conscious(false):
		return

	var actor: BattleBattler = BattleUtil.player_battler_at(state, actor_slot)
	if actor == null or actor.is_fainted():
		return

	var target: BattleBattler = null
	if target_slot == -2:
		target = get_ally(actor)
		if target == null:
			message.emit("¡No hay aliado al que apuntar!")
			return
	else:
		target = BattleUtil.enemy_battler_at(state, target_slot)
		if target == null:
			var opps: Array[BattleBattler] = get_opponents(actor)
			target = opps[0] if not opps.is_empty() else state.enemy

	var player_action: BattleAction = BattleAction.make_move(
		actor, target, _move_at(actor, slot_index), slot_index
	)
	if player_action.move == null:
		message.emit("¡No se puede usar ese movimiento!")
		return
	player_action.target_slot = target_slot
	BattleExperience.mark_participant(self, actor.pokemon)

	if not is_multi_battle() or state.player_slot_count() <= 1:
		var enemy_actions: Array[BattleAction] = _opponent_controller.choose_actions(
			self, state.enemy_actives
		)
		var all_actions: Array[BattleAction] = [player_action]
		all_actions.append_array(enemy_actions)
		await _resolve_turn_actions(all_actions)
		return

	state.pending_player_actions.append(player_action)
	var needed: int = 0
	for b: BattleBattler in state.player_actives:
		if b != null and b.pokemon != null and not b.is_fainted():
			needed += 1
	if state.pending_player_actions.size() < needed:
		return
	await _flush_pending_turn()


func _flush_pending_turn() -> void:
	var player_actions: Array[BattleAction] = []
	for a: BattleAction in state.pending_player_actions:
		if a != null:
			player_actions.append(a)
	state.pending_player_actions.clear()
	var enemy_actions: Array[BattleAction] = _opponent_controller.choose_actions(
		self, state.enemy_actives
	)
	var all_actions: Array[BattleAction] = []
	all_actions.append_array(player_actions)
	all_actions.append_array(enemy_actions)
	await _resolve_turn_actions(all_actions)


func _resolve_turn_actions(actions: Array[BattleAction]) -> void:
	await BattleTurn.resolve_actions(self, actions)


func _check_battle_end() -> void:
	## Alineado con BattleTurn: solo termina si no hay activos NI reservas.
	if not side_has_conscious(true) and not party_has_reserve(true):
		state.is_running = false
		battle_ended.emit(false)
	elif not side_has_conscious(false) and not party_has_reserve(false):
		state.is_running = false
		battle_ended.emit(true)


func _move_at(actor: BattleBattler, slot_index: int) -> MoveData:
	if actor == null or actor.pokemon == null:
		return null
	if slot_index < 0 or slot_index >= actor.pokemon.moves.size():
		return null
	var ms: PokemonMoveSlot = actor.pokemon.moves[slot_index]
	if ms == null or ms.is_empty():
		return null
	return MoveDatabase.get_move(ms.move_id)


## API que AbilityRuntime / SwitchIn esperan en el objeto "battle"
func ability_announce(battler: BattleBattler) -> void:
	if battler == null or battler.pokemon == null:
		return
	ability_announced.emit(battler.is_player_side, battler.pokemon)
	# La UI reproduce la barra y emite ability_bar_finished.
	# Timeout de respaldo para no colgar el combate si la UI no responde.
	var done: Array[bool] = [false]
	var on_done: Callable = func() -> void:
		done[0] = true
	if not ability_bar_finished.is_connected(on_done):
		ability_bar_finished.connect(on_done, CONNECT_ONE_SHOT)
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree != null:
		var timeout: float = 2.2
		while not done[0] and timeout > 0.0:
			await tree.process_frame
			var delta: float = 0.016
			if tree.root != null:
				delta = tree.root.get_process_delta_time()
			timeout -= delta


func ability_change_stat(
	battler: BattleBattler,
	stat: PokemonInstance.Stat,
	stages: int,
	_caused_by_foe: bool = false
) -> void:
	if battler == null:
		return
	battler.modify_stage(stat, stages)


func ability_apply_status(
	battler: BattleBattler,
	status: PokemonInstance.Status,
	_source: BattleBattler
) -> void:
	if battler == null or battler.pokemon == null:
		return
	if status == PokemonInstance.Status.NONE:
		if battler.pokemon.has_method("cure_status"):
			battler.pokemon.cure_status()
		else:
			battler.pokemon.status = PokemonInstance.Status.NONE
		return
	# No sobrescribir un estado primario ya presente
	if battler.pokemon.status != PokemonInstance.Status.NONE 			and battler.pokemon.status != status:
		return
	battler.pokemon.status = status
	if status == PokemonInstance.Status.SLEEP and battler.pokemon.status_counter <= 0:
		battler.pokemon.status_counter = randi_range(1, 3)
	elif status == PokemonInstance.Status.TOXIC:
		battler.pokemon.status_counter = 0
		if "toxic_counter" in battler:
			battler.toxic_counter = 0


func ability_deal_damage(battler: BattleBattler, amount: int, _cause: BattleBattler) -> void:
	if battler == null:
		return
	battler.apply_damage(amount)
	_emit_hp_battler(battler)


func ability_heal(battler: BattleBattler, amount: int) -> void:
	if battler == null or battler.pokemon == null:
		return
	battler.pokemon.apply_heal(amount)
	_emit_hp_battler(battler)


func ability_cure_status(battler: BattleBattler) -> void:
	if battler == null or battler.pokemon == null:
		return
	battler.pokemon.status = PokemonInstance.Status.NONE


## La UI conecta player_must_switch; al terminar player_choose_switch emite player_switch_resolved.
func await_forced_player_switch(mid_turn: bool = false) -> void:
	state.awaiting_player_switch = true
	state.player_switch_mid_turn = mid_turn
	if not player_switch_resolved.is_connected(_on_player_switch_resolved_flag):
		player_switch_resolved.connect(_on_player_switch_resolved_flag, CONNECT_ONE_SHOT)
	while state.awaiting_player_switch and state.is_running:
		await Engine.get_main_loop().process_frame


func _on_player_switch_resolved_flag() -> void:
	state.awaiting_player_switch = false
	state.player_switch_mid_turn = false


func mark_exp_participant(mon: PokemonInstance) -> void:
	BattleExperience.mark_participant(self, mon)


func player_choose_switch(
	nuevo: PokemonInstance,
	free_switch: bool = false,
	slot_index: int = -1
) -> void:
	if nuevo == null:
		return
	var slot: int = slot_index
	if slot < 0:
		slot = 0
		if has_meta("forced_replace_slot"):
			slot = int(get_meta("forced_replace_slot"))
			remove_meta("forced_replace_slot")
	var actor: BattleBattler = BattleUtil.player_battler_at(state, slot)
	if actor == null:
		return
	var action: BattleAction = BattleAction.make_switch(actor, nuevo)
	if free_switch or state.awaiting_player_switch:
		await BattleSwitchIn.execute_switch_action(self, action)
		player_switch_resolved.emit()
		state.awaiting_player_switch = false
		return
	# Switch como acción de turno (no free): se resuelve con el turno enemigo
	var enemy_actions: Array[BattleAction] = _opponent_controller.choose_actions(
		self, state.enemy_actives
	)
	var all_actions: Array[BattleAction] = [action]
	all_actions.append_array(enemy_actions)
	await _resolve_turn_actions(all_actions)


func player_choose_run() -> void:
	var escaped: bool = await BattleRun.attempt(self)
	if not escaped and state.is_running:
		# turno del rival tras fallar huida
		var enemy_actions: Array[BattleAction] = _opponent_controller.choose_actions(
			self, state.enemy_actives
		)
		await _resolve_turn_actions(enemy_actions)


func player_choose_item(
	item_id: Items.ItemId,
	target: PokemonInstance = null,
	move_slot_index: int = -1
) -> void:
	await BattleItems.use_item(self, item_id, target, move_slot_index)


func end_battle_cleanup() -> void:
	BattleDone.cleanup(self)
