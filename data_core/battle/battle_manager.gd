extends RefCounted
class_name BattleManager

signal message(text: String)
signal hp_changed(is_player: bool, current_hp: int, max_hp: int)
signal battle_ended(player_won: bool)
signal turn_ended
## El mon activo se debilitó y hay reemplazo en el party.
signal player_must_switch

var player: BattleBattler
var enemy: BattleBattler
var is_running: bool = false
var player_party: Array[PokemonInstance] = []


func start_battle(
	player_pokemon: PokemonInstance,
	enemy_pokemon: PokemonInstance,
	party: Array[PokemonInstance] = []
) -> void:
	player = BattleBattler.new()
	player.setup(player_pokemon, true)
	enemy = BattleBattler.new()
	enemy.setup(enemy_pokemon, false)
	player_party = party
	is_running = true
	_emit_hp(true)
	_emit_hp(false)


func _emit_hp(is_player_side: bool) -> void:
	var b: BattleBattler = player if is_player_side else enemy
	hp_changed.emit(is_player_side, b.get_current_hp(), b.get_max_hp())


func player_choose_move(slot_index: int) -> void:
	if not is_running:
		return
	if player.is_fainted() or enemy.is_fainted():
		return

	var player_action: BattleAction = _build_move_action(player, enemy, slot_index)
	if player_action == null:
		message.emit("¡No se puede usar ese movimiento!")
		return

	var enemy_action: BattleAction = _enemy_choose_move()
	await _resolve_turn(player_action, enemy_action)


## free_switch = true → cambio forzado tras debilitarse (el rival no ataca otra vez).
func player_choose_switch(nuevo: PokemonInstance, free_switch: bool = false) -> void:
	if not is_running:
		return
	if nuevo == null or nuevo.is_fainted():
		message.emit("¡No puede combatir!")
		return
	if player.pokemon == nuevo:
		message.emit("¡Ese Pokémon ya está en combate!")
		return

	var saliente_nombre: String = player.get_display_name()
	if not player.is_fainted():
		message.emit("¡%s, vuelve!" % saliente_nombre)
		await _wait(0.6)

	player.setup(nuevo, true)
	_emit_hp(true)
	message.emit("¡Adelante, %s!" % player.get_display_name())
	await _wait(0.8)

	if free_switch:
		turn_ended.emit()
		return

	# Cambio voluntario: el rival actúa
	var enemy_action: BattleAction = _enemy_choose_move()
	if enemy_action != null:
		await _execute_move(enemy_action)

	if enemy.is_fainted():
		message.emit("¡%s se debilitó!" % enemy.get_display_name())
		await _wait(1.2)
		message.emit("¡Ganaste!")
		is_running = false
		battle_ended.emit(true)
		return

	if player.is_fainted():
		await _manejar_debilitacion_jugador()
		return

	turn_ended.emit()


func player_choose_run() -> void:
	if not is_running:
		return
	message.emit("¡Escapaste con éxito!")
	is_running = false
	battle_ended.emit(true)


func tiene_reemplazo() -> bool:
	for mon: PokemonInstance in player_party:
		if mon == null:
			continue
		if mon == player.pokemon:
			continue
		if not mon.is_fainted():
			return true
	return false


func _build_move_action(
	actor: BattleBattler,
	target: BattleBattler,
	slot_index: int
) -> BattleAction:
	if actor.pokemon == null:
		return null
	if slot_index < 0 or slot_index >= actor.pokemon.moves.size():
		return null
	var slot: PokemonMoveSlot = actor.pokemon.moves[slot_index]
	if slot == null or slot.is_empty():
		return null
	if slot.current_pp <= 0:
		return null
	var move_data: MoveData = MoveDatabase.get_move(slot.move_id)
	if move_data == null:
		return null
	return BattleAction.make_move(actor, target, move_data, slot_index)


func _enemy_choose_move() -> BattleAction:
	for i: int in enemy.pokemon.moves.size():
		var action: BattleAction = _build_move_action(enemy, player, i)
		if action != null:
			return action
	return null


func _resolve_turn(player_action: BattleAction, enemy_action: BattleAction) -> void:
	var actions: Array[BattleAction] = []
	if player_action:
		actions.append(player_action)
	if enemy_action:
		actions.append(enemy_action)

	actions = _sort_actions(actions)

	for action: BattleAction in actions:
		if action.actor.is_fainted():
			continue
		if action.kind == BattleAction.Kind.MOVE:
			await _execute_move(action)
		if player.is_fainted() or enemy.is_fainted():
			break

	if enemy.is_fainted():
		message.emit("¡%s se debilitó!" % enemy.get_display_name())
		await _wait(1.2)
		message.emit("¡Ganaste!")
		is_running = false
		battle_ended.emit(true)
		return

	if player.is_fainted():
		await _manejar_debilitacion_jugador()
		return

	turn_ended.emit()


func _manejar_debilitacion_jugador() -> void:
	message.emit("¡%s se debilitó!" % player.get_display_name())
	await _wait(1.0)

	if tiene_reemplazo():
		player_must_switch.emit()
		return

	message.emit("Has perdido...")
	await _wait(1.0)
	is_running = false
	battle_ended.emit(false)


func _sort_actions(actions: Array[BattleAction]) -> Array[BattleAction]:
	actions.sort_custom(func(a: BattleAction, b: BattleAction) -> bool:
		if a.priority != b.priority:
			return a.priority > b.priority
		var sa: int = a.actor.get_effective_stat(PokemonInstance.Stat.SPEED)
		var sb: int = b.actor.get_effective_stat(PokemonInstance.Stat.SPEED)
		if sa != sb:
			return sa > sb
		return randf() < 0.5
	)
	return actions


func _execute_move(action: BattleAction) -> void:
	var actor: BattleBattler = action.actor
	var target: BattleBattler = action.target
	var move: MoveData = action.move

	if not actor.consume_pp(action.move_slot_index):
		message.emit("%s no tiene PP para usar %s!" % [actor.get_display_name(), move.move_name])
		await _wait(0.8)
		return

	message.emit("%s usó %s!" % [actor.get_display_name(), move.move_name])
	await _wait(0.9)

	var result: DamageCalculator.HitResult = DamageCalculator.calculate(actor, target, move)

	if result.is_status:
		message.emit("¡Pero no tuvo efecto todavía!")
		await _wait(0.8)
		return

	if not result.hit:
		message.emit("¡El ataque de %s falló!" % actor.get_display_name())
		await _wait(0.8)
		return

	if result.effectiveness <= 0.0:
		message.emit("No afecta a %s..." % target.get_display_name())
		await _wait(0.8)
		return

	var dealt: int = target.apply_damage(result.damage)
	_emit_hp(target.is_player_side)

	if result.critical:
		message.emit("¡Un golpe crítico!")
		await _wait(0.6)

	if result.effectiveness > 1.0:
		message.emit("¡Es muy efectivo!")
		await _wait(0.6)
	elif result.effectiveness < 1.0:
		message.emit("No es muy efectivo...")
		await _wait(0.6)

	message.emit("Hizo %d PS de daño." % dealt)
	await _wait(0.7)


func _wait(seconds: float) -> void:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree:
		await tree.create_timer(seconds).timeout
	else:
		await Engine.get_main_loop().process_frame
