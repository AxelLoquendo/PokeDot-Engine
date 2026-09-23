extends RefCounted
class_name BattleManager

signal message(text: String)
signal hp_changed(is_player: bool, current_hp: int, max_hp: int)
signal player_progress_changed
signal battle_ended(player_won: bool)
signal turn_ended
## El mon activo se debilitó y hay reemplazo en el party.
signal player_must_switch
signal player_evolved

signal ability_announced(is_player: bool, pokemon: PokemonInstance)
signal ability_bar_finished
## La UI debe cambiar sprite/nombre/barra del lado indicado.
signal battler_appearance_changed(is_player: bool)
## Illusion se rompió: animación de “destello” + sprite real.
signal illusion_broken(is_player: bool)

signal pokemon_entered_field(is_player: bool)

var player: BattleBattler
var enemy: BattleBattler
var is_running: bool = false
var player_party: Array[PokemonInstance] = []
var enemy_party: Array[PokemonInstance] = []
var player_side: FieldSide = FieldSide.new()
var enemy_side: FieldSide = FieldSide.new()
var is_trainer_battle: bool = false

var weather: int = AbilityBattleEffect.weatherAbilityID.WEATHER_NONE
var weather_turns: int = -1

## Pantalla para elegir qué movimiento olvidar cuando un Pokémon con 4
## movimientos completos quiere aprender uno nuevo durante el combate.
const MOVE_LEARN_SCENE: PackedScene = preload("res://scenes/ui_summary_screen/move_learn_screen.tscn")

signal terrain_changed(terrain: int)
signal weather_changed(weather: int, primal: bool)

enum TerrainId {
	TERRAIN_NONE,
	TERRAIN_ELECTRIC,
	TERRAIN_GRASSY,
	TERRAIN_MISTY,
	TERRAIN_PSYCHIC,
}

var terrain: int = TerrainId.TERRAIN_NONE
var terrain_turns: int = 0
var weather_primal: bool = false

func start_battle(
	player_pokemon: PokemonInstance,
	enemy_pokemon: PokemonInstance,
	party: Array[PokemonInstance] = [],
	enemy_trainer_party: Array[PokemonInstance] = []
) -> void:
	player = BattleBattler.new()
	player.setup(player_pokemon, true)
	enemy = BattleBattler.new()
	enemy.setup(enemy_pokemon, false)
	player_party = party
	enemy_party = enemy_trainer_party
	is_trainer_battle = not enemy_party.is_empty()
	is_running = true
	weather = AbilityBattleEffect.weatherAbilityID.WEATHER_NONE
	weather_turns = -1
	terrain = TerrainId.TERRAIN_NONE
	terrain_turns = 0
	weather_primal = false
	
	# Disfraz listo ANTES de que la UI pinte
	AbilityRuntime.prepare_illusion(player, self)
	AbilityRuntime.prepare_illusion(enemy, self)
	
	_emit_hp(true)
	_emit_hp(false)


## Secuencia de mensajes + habilidades de entrada. Se llama aparte de
## start_battle() para que la UI pueda mostrar sprites/HP antes de que
## empiecen los textos.
func start_battle_intro() -> void:
	if is_trainer_battle:
		message.emit("¡El rival envía a %s!" % enemy.get_display_name())
	else:
		message.emit("¡Un %s salvaje apareció!" % enemy.get_display_name())
	pokemon_entered_field.emit(false)
	await _wait(1.0)
	await AbilityRuntime.on_switch_in(enemy, player, self)

	message.emit("¡Adelante, %s!" % player.get_display_name())
	pokemon_entered_field.emit(true)
	await _wait(0.8)
	await AbilityRuntime.on_switch_in(player, enemy, self)

func _emit_hp(is_player_side: bool) -> void:
	var b: BattleBattler = player if is_player_side else enemy
	hp_changed.emit(is_player_side, b.get_current_hp(), b.get_max_hp())


func player_choose_move(slot_index: int) -> void:
	if not is_running:
		return
	if player.is_fainted() or enemy.is_fainted():
		return

	if player.must_recharge:
		player.must_recharge = false
		message.emit("¡%s debe recargar energías!" % player.get_display_name())
		await _wait(0.8)
		var recharge_enemy_action: BattleAction = _enemy_choose_move()
		await _resolve_turn(null, recharge_enemy_action)
		return

	var player_action: BattleAction
	if player.charging_move != null:
		player_action = _build_charge_release_action(player)
	else:
		player_action = _build_move_action(player, enemy, slot_index)
	if player_action == null:
		message.emit("¡No se puede usar ese movimiento!")
		return

	var enemy_action: BattleAction = _enemy_choose_move()
	await _resolve_turn(player_action, enemy_action)

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
		await AbilityRuntime.on_switch_out(player, self)

	AbilityRuntime.revert_transform(player)

	player.setup(nuevo, true)
	AbilityRuntime.prepare_illusion(player, self)
	_emit_hp(true)
	battler_appearance_changed.emit(true)

	# 1) Aviso de envío
	message.emit("¡Adelante, %s!" % player.get_display_name())
	# 2) Grito YA (UI lo oye; habilidades todavía no)
	pokemon_entered_field.emit(true)
	await _wait(0.8)

	# 3) Habilidades de entrada (Ability Bar, etc.)
	await AbilityRuntime.on_switch_in(player, enemy, self)
	await _apply_hazards_on_switch_in(player)

	if free_switch:
		turn_ended.emit()
		return

	var enemy_action: BattleAction = _enemy_choose_move()
	if enemy_action != null:
		await _execute_move(enemy_action)

	if enemy.is_fainted():
		await _handle_enemy_faint()
		return

	if player.is_fainted():
		await _manejar_debilitacion_jugador()
		return

	turn_ended.emit()


func player_choose_run() -> void:
	if not is_running:
		return
	if AbilityRuntime.prevents_escape(enemy, player):
		message.emit("¡No puedes escapar!")
		await _wait(0.8)
		return
	message.emit("¡Escapaste con éxito!")
	_cleanup_battle_pokemon()
	is_running = false
	battle_ended.emit(true)


## Usa un objeto de la mochila durante el combate. La UI decide qué objeto y
## qué movimiento (para Éter/Elixir) apunta; la lógica y el consumo viven aquí.
func player_choose_item(item_id: Items.ItemId, target: PokemonInstance = null, move_slot_index: int = -1) -> void:
	if not is_running or player == null:
		return
	var controller: CharacterController = BattleSession.player_controller
	var data: CharacterPlayer = controller.character_data as CharacterPlayer if controller else null
	if data == null or data.bag == null or not data.bag.has_item(item_id):
		message.emit("¡No queda ese objeto!")
		return
	var item: ItemData = ItemDatabase.get_item(item_id)
	if item == null:
		message.emit("¡Ese objeto no tiene datos válidos!")
		return
	if await _try_use_battle_field_item(item, data):
		return
	var recipient: PokemonInstance = target if target != null else player.pokemon
	var result: ItemUseResolver.Result = ItemUseResolver.use_on_pokemon(item, recipient, null, move_slot_index)
	message.emit(result.message)
	await _wait(0.7)
	if not result.success:
		return
	if result.consume_item:
		data.bag.remove_item(item_id)
	if result.evolved != null:
		var battler: BattleBattler = player if recipient == player.pokemon else null
		if battler != null:
			var evo_context: EvolutionContext = EvolutionContext.new(recipient)
			evo_context.mode = PokemonData.EvolutionMode.EVO_MODE_ITEM_USE
			evo_context.used_item_id = item_id
			await _apply_evolution(battler, result.evolved, evo_context)
	_emit_hp(player.is_player_side)
	var enemy_action: BattleAction = _enemy_choose_move()
	if enemy_action != null:
		await _resolve_turn(null, enemy_action)


## Efectos de objetos que pertenecen al campo de batalla, no a un Pokémon
## concreto. Devuelve true cuando el objeto fue reconocido, incluso si no pudo
## surtir efecto, para impedir que el resolvedor de objetos de equipo lo trate
## como un objeto de curación.
func _try_use_battle_field_item(item: ItemData, data: CharacterPlayer) -> bool:
	match item.effect:
		Items.EffectItem.EFFECT_ITEM_SET_MIST:
			var side: FieldSide = _side_for(player)
			if side.mist_turns > 0:
				message.emit("¡No surtirá efecto!")
				await _wait(0.7)
				return true
			side.mist_turns = 5
			if not item.not_consumed:
				data.bag.remove_item(item.item_id)
			message.emit("¡El equipo quedó protegido por Neblina!")
			await _wait(0.7)
			await _resolve_item_enemy_turn()
			return true
		Items.EffectItem.EFFECT_ITEM_SET_FOCUS_ENERGY:
			if player.focus_energy:
				message.emit("¡No surtirá efecto!")
				await _wait(0.7)
				return true
			player.focus_energy = true
			if not item.not_consumed:
				data.bag.remove_item(item.item_id)
			message.emit("¡%s se concentró para asestar golpes críticos!" % player.get_display_name())
			await _wait(0.7)
			await _resolve_item_enemy_turn()
			return true
		Items.EffectItem.EFFECT_ITEM_INCREASE_STAT:
			if item.effect_stat == PokemonInstance.Stat.HP:
				message.emit("¡No surtirá efecto!")
				await _wait(0.7)
				return true
			var change: int = player.modify_stage(item.effect_stat, maxi(1, item.effect_amount))
			if change == 0:
				message.emit("¡No surtirá efecto!")
				await _wait(0.7)
				return true
			if not item.not_consumed:
				data.bag.remove_item(item.item_id)
			message.emit("¡El %s de %s subió!" % [_stat_display_name(item.effect_stat), player.get_display_name()])
			await _wait(0.7)
			await _resolve_item_enemy_turn()
			return true
		Items.EffectItem.EFFECT_ITEM_INCREASE_ALL_STATS:
			var changed: bool = false
			for stat: PokemonInstance.Stat in [
				PokemonInstance.Stat.ATTACK, PokemonInstance.Stat.DEFENSE,
				PokemonInstance.Stat.SP_ATTACK, PokemonInstance.Stat.SP_DEFENSE,
				PokemonInstance.Stat.SPEED
			]:
				changed = player.modify_stage(stat, maxi(1, item.effect_amount)) != 0 or changed
			if not changed:
				message.emit("¡No surtirá efecto!")
				await _wait(0.7)
				return true
			if not item.not_consumed:
				data.bag.remove_item(item.item_id)
			message.emit("¡Las estadísticas de %s subieron!" % player.get_display_name())
			await _wait(0.7)
			await _resolve_item_enemy_turn()
			return true
		_:
			return false


func _resolve_item_enemy_turn() -> void:
	var enemy_action: BattleAction = _enemy_choose_move()
	if enemy_action != null:
		await _resolve_turn(null, enemy_action)

func _handle_enemy_faint() -> void:
	message.emit("¡%s se debilitó!" % enemy.get_display_name())
	await _wait(1.0)

	await _award_experience()

	if is_trainer_battle and _enemy_tiene_reemplazo():
		var nuevo: PokemonInstance = _enemy_siguiente_reemplazo()
		AbilityRuntime.revert_transform(enemy)
		enemy.setup(nuevo, false)
		AbilityRuntime.prepare_illusion(enemy, self)
		_emit_hp(false)
		battler_appearance_changed.emit(false)

		message.emit("¡El rival envía a %s!" % enemy.get_display_name())
		pokemon_entered_field.emit(false)
		await _wait(0.8)

		await AbilityRuntime.on_switch_in(enemy, player, self)
		await _apply_hazards_on_switch_in(enemy)
		turn_ended.emit()
		return

	await _check_battle_end_evolution()

	message.emit("¡Ganaste!")
	_cleanup_battle_pokemon()
	is_running = false
	battle_ended.emit(true)

func _check_evolution(battler: BattleBattler) -> void:
	if battler.pokemon == null:
		return

	var context: EvolutionContext = EvolutionContext.new(battler.pokemon)
	context.party = player_party if battler == player else enemy_party
	context.is_day = DnsManager.current_time_state == DnsManager.TimeOfDay.MORNING \
		or DnsManager.current_time_state == DnsManager.TimeOfDay.DAY

	context.mode = PokemonData.EvolutionMode.EVO_MODE_BATTLE_ONLY
	var result: EvolutionResult = EvolutionSystem.try_evolve(battler.pokemon, context.mode, context)
	if result == null:
		context.mode = PokemonData.EvolutionMode.EVO_MODE_NORMAL
		result = EvolutionSystem.try_evolve(battler.pokemon, context.mode, context)
	if result == null:
		return

	await _apply_evolution(battler, result, context)
	await _check_evolution(battler)  # por si encadena otra evolución más


func _apply_evolution(battler: BattleBattler, result: EvolutionResult, context: EvolutionContext) -> void:
	var old_name: String = battler.pokemon.get_display_name()

	message.emit("¡Qué! ¡%s está evolucionando!" % old_name)
	await _wait(1.0)

	var outcome: Dictionary = battler.pokemon.apply_evolution(result, context)
	if not outcome.get("evolved", false):
		return

	message.emit("¡Felicidades! ¡Tu %s ahora es %s!" % [old_name, battler.pokemon.get_display_name()])
	_emit_hp(battler.is_player_side)
	if battler == player:
		player_evolved.emit()
	await _wait(1.0)

	for move_id: Moves.MoveId in outcome.get("learned_moves", []):
		var move_data: MoveData = MoveDatabase.get_move(move_id)
		message.emit("¡%s aprendió %s!" % [
			battler.pokemon.get_display_name(),
			move_data.move_name if move_data else "un movimiento"
		])
		await _wait(0.9)


func _check_battle_end_evolution() -> void:
	if player.pokemon == null:
		return
	var context: EvolutionContext = EvolutionContext.new(player.pokemon)
	context.party = player_party
	context.mode = PokemonData.EvolutionMode.EVO_MODE_BATTLE_SPECIAL
	var result: EvolutionResult = EvolutionSystem.try_evolve(player.pokemon, context.mode, context)
	if result != null:
		await _apply_evolution(player, result, context)

func _award_experience() -> void:
	if player.pokemon == null or enemy.pokemon == null:
		return
	var species: PokemonDataStruct = enemy.pokemon.get_species()
	if species == null:
		return

	var trainer_mult: float = 1.5 if is_trainer_battle else 1.0
	var exp_gained: int = maxi(
		1,
		int(floor(float(species.exp_yield * enemy.pokemon.level) / 7.0 * trainer_mult))
	)

	message.emit("¡%s ganó %d puntos de experiencia!" % [player.get_display_name(), exp_gained])
	await _wait(0.8)

	var result: Dictionary = player.pokemon.gain_exp(exp_gained)
	if result.get("levels_gained", 0) > 0:
		message.emit("¡%s subió a nivel %d!" % [player.get_display_name(), player.pokemon.level])
		_emit_hp(true)
		await _wait(0.9)
		for move_id: Moves.MoveId in result.get("learned_moves", []):
			var move_data: MoveData = MoveDatabase.get_move(move_id)
			message.emit("¡%s aprendió %s!" % [
				player.get_display_name(),
				move_data.move_name if move_data else "un movimiento"
			])
			await _wait(0.9)
		for move_id: Moves.MoveId in result.get("pending_moves", []):
			await _try_learn_move_interactive(player.pokemon, move_id)
		await _check_evolution(player)
	player_progress_changed.emit()


## Se llama cuando un Pokémon ya tiene 4 movimientos y quiere aprender uno
## nuevo. Le pregunta al jugador si quiere aprenderlo (Sí/No) y, en caso
## afirmativo, abre la pantalla de selección (Page_4_2) para elegir qué
## movimiento olvidar. Si el jugador cancela en cualquier punto, el Pokémon
## simplemente no aprende el movimiento.
func _try_learn_move_interactive(pokemon: PokemonInstance, move_id: Moves.MoveId) -> void:
	var move_data: MoveData = MoveDatabase.get_move(move_id)
	var move_name: String = move_data.move_name if move_data else "un movimiento nuevo"
	var pkmn_nombre: String = pokemon.get_display_name()

	message.emit("¡%s quiere aprender %s!" % [pkmn_nombre, move_name])
	await _wait(0.7)
	message.emit("Pero %s ya conoce cuatro movimientos." % pkmn_nombre)
	await _wait(0.7)

	var quiere_aprender: bool = await _preguntar_si_no(
		"¿Quieres que %s aprenda %s?" % [pkmn_nombre, move_name]
	)

	if not quiere_aprender:
		var abandona: bool = await _preguntar_si_no(
			"¿Renunciar a que %s aprenda %s?" % [pkmn_nombre, move_name]
		)
		if not abandona:
			# El jugador se arrepintió: volvemos a preguntar desde el inicio.
			await _try_learn_move_interactive(pokemon, move_id)
			return
		message.emit("%s no aprendió %s." % [pkmn_nombre, move_name])
		await _wait(0.7)
		return

	var eleccion: Dictionary = await _elegir_movimiento_a_olvidar(pokemon, move_id)
	if eleccion.get("cancelado", true):
		message.emit("%s no aprendió %s." % [pkmn_nombre, move_name])
		await _wait(0.7)
		return

	var indice: int = eleccion.get("indice", -1)
	var slot_anterior: PokemonMoveSlot = (
		pokemon.moves[indice] if indice >= 0 and indice < pokemon.moves.size() else null
	)
	var nombre_olvidado: String = ""
	if slot_anterior and not slot_anterior.is_empty():
		var data_anterior: MoveData = MoveDatabase.get_move(slot_anterior.move_id)
		nombre_olvidado = data_anterior.move_name if data_anterior else ""

	if not pokemon.replace_move_at(indice, move_id):
		return

	if nombre_olvidado != "":
		message.emit("¡%s olvidó %s...!" % [pkmn_nombre, nombre_olvidado])
		await _wait(0.6)
	message.emit("¡%s aprendió %s!" % [pkmn_nombre, move_name])
	await _wait(0.9)


## Muestra una pregunta de Sí/No usando el DialogueBox del árbol de escena
## (grupo "dialogue_box") y devuelve true si el jugador elige "Sí".
## Si no hay caja de diálogo disponible, se asume "Sí" para no bloquear
## el combate.
func _preguntar_si_no(pregunta: String) -> bool:
	# Battle usa su propia caja de mensajes. Solo las opciones se muestran en
	# la capa independiente, sin abrir DialogueBox sobre el combate.
	message.emit(pregunta)
	await _wait(0.2)
	var choice: int = await DialogueManager.choose(["Sí", "No"], Vector2(468, 308))
	return choice == 0


## Instancia la pantalla de aprendizaje de movimiento (MoveLearnScreen, que
## envuelve a Page_4_2 / SummaryPageMoveLearned), espera la elección del
## jugador y devuelve {"cancelado": bool, "indice": int}.
func _elegir_movimiento_a_olvidar(pokemon: PokemonInstance, move_id: Moves.MoveId) -> Dictionary:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null:
		return {"cancelado": true, "indice": -1}

	var pantalla: MoveLearnScreen = MOVE_LEARN_SCENE.instantiate() as MoveLearnScreen
	tree.root.add_child(pantalla)
	pantalla.setup(pokemon, move_id)

	var resultado: Array = await pantalla.resolved
	pantalla.queue_free()

	return {"cancelado": resultado[0], "indice": resultado[1]}

func tiene_reemplazo() -> bool:
	for mon: PokemonInstance in player_party:
		if mon == null:
			continue
		if mon == player.pokemon:
			continue
		if not mon.is_fainted():
			return true
	return false

func _enemy_tiene_reemplazo() -> bool:
	for mon: PokemonInstance in enemy_party:
		if mon == null or mon == enemy.pokemon:
			continue
		if not mon.is_fainted():
			return true
	return false


func _enemy_siguiente_reemplazo() -> PokemonInstance:
	for mon: PokemonInstance in enemy_party:
		if mon == null or mon == enemy.pokemon:
			continue
		if not mon.is_fainted():
			return mon
	return null

func _build_move_action(actor: BattleBattler, target: BattleBattler, slot_index: int) -> BattleAction:
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
	var action: BattleAction = BattleAction.make_move(actor, target, move_data, slot_index)
	if action != null:
		action.priority += AbilityRuntime.priority_bonus(actor, move_data)
	return action

func _build_charge_release_action(actor: BattleBattler) -> BattleAction:
	var move: MoveData = actor.charging_move
	var slot_index: int = actor.charging_slot_index
	var target: BattleBattler = actor.charging_target
	if target == null:
		target = enemy if actor == player else player
	return BattleAction.make_move(actor, target, move, slot_index)

func _enemy_choose_move() -> BattleAction:
	if enemy.must_recharge:
		enemy.must_recharge = false
		return null
	if enemy.charging_move != null:
		return _build_charge_release_action(enemy)
	var valid_indices: Array[int] = []
	for i: int in enemy.pokemon.moves.size():
		if _build_move_action(enemy, player, i) != null:
			valid_indices.append(i)
	if valid_indices.is_empty():
		return null

	var weighted: Array[int] = []
	for i: int in valid_indices:
		var slot: PokemonMoveSlot = enemy.pokemon.moves[i]
		var move_data: MoveData = MoveDatabase.get_move(slot.move_id)
		var weight: int = 1
		if move_data and move_data.category != MoveStruct.DamageCategory.STATUS:
			var eff: float = TypeChart.get_effectiveness(
				move_data.type, player.pokemon.get_type_1(), player.pokemon.get_type_2()
			)
			if eff > 1.0:
				weight = 3
			elif eff <= 0.0:
				weight = 0
		for _n: int in weight:
			weighted.append(i)

	var pool: Array[int] = weighted if not weighted.is_empty() else valid_indices
	return _build_move_action(enemy, player, pool[randi() % pool.size()])


func _resolve_turn(player_action: BattleAction, enemy_action: BattleAction) -> void:
	var actions: Array[BattleAction] = []
	if player_action:
		actions.append(player_action)
	if enemy_action:
		actions.append(enemy_action)

	actions = _sort_actions(actions)

	for battler: BattleBattler in [player, enemy]:
		battler.protect_active = false
		battler.protect_kind = ProtectResolver.Kind.NONE
		battler.endure_active = false
		battler.just_switched_in = false

	for action: BattleAction in actions:
		if action.actor.is_fainted():
			continue
		if action.kind == BattleAction.Kind.MOVE:
			await _execute_move(action)
		if player.is_fainted() or enemy.is_fainted():
			break

	if not player.is_fainted() and not enemy.is_fainted():
		await _process_end_of_turn()

	if enemy.is_fainted():
		await _handle_enemy_faint()
		return

	if player.is_fainted():
		await _manejar_debilitacion_jugador()
		return

	turn_ended.emit()

func _process_end_of_turn() -> void:
	if weather != AbilityBattleEffect.weatherAbilityID.WEATHER_NONE:
		await _apply_weather_damage()

	for battler: BattleBattler in [player, enemy]:
		if battler.is_fainted():
			continue
		if AbilityRuntime.has(battler, AbilityId.Id.POISON_HEAL) \
				and (battler.pokemon.status == PokemonInstance.Status.POISON \
					or battler.pokemon.status == PokemonInstance.Status.TOXIC):
			await ability_announce(battler)
			@warning_ignore("integer_division")
			var heal: int = maxi(1, battler.get_max_hp() / 8)
			battler.pokemon.apply_heal(heal)
			_emit_hp(battler.is_player_side)
			message.emit("¡%s se recuperó un poco!" % battler.get_display_name())
			await _wait(0.6)
			continue
		var res: Dictionary = StatusConditions.end_of_turn_damage(battler)
		if res.damage > 0:
			message.emit(res.message)
			await _wait(0.6)
			battler.apply_damage(res.damage)
			_emit_hp(battler.is_player_side)
			await _wait(0.6)
			if battler.is_fainted():
				message.emit("¡%s se debilitó!" % battler.get_display_name())
				await _wait(0.8)

	for battler: BattleBattler in [player, enemy]:
		if not battler.is_fainted():
			await AbilityRuntime.end_of_turn(battler, weather, self)

	player_side.tick_down()
	enemy_side.tick_down()
	if weather_turns > 0:
		weather_turns -= 1
		if weather_turns == 0:
			weather = AbilityBattleEffect.weatherAbilityID.WEATHER_NONE
			message.emit("¡El clima volvió a la normalidad!")
			await _wait(0.6)
	if terrain_turns > 0:
		terrain_turns -= 1
		if terrain_turns == 0:
			terrain = TerrainId.TERRAIN_NONE
			message.emit("¡El terreno volvió a la normalidad!")
			await _wait(0.6)

func _apply_weather_damage() -> void:
	match weather:
		AbilityBattleEffect.weatherAbilityID.WEATHER_SANDSTORM:
			message.emit("¡La tormenta de arena azota el campo!")
		AbilityBattleEffect.weatherAbilityID.WEATHER_SNOW:
			message.emit("¡Sigue granizando!")
		_:
			return
	await _wait(0.6)

	for battler: BattleBattler in [player, enemy]:
		if battler.is_fainted():
			continue
		if AbilityRuntime.is_immune_to_weather_damage(battler, weather) or AbilityRuntime.blocks_indirect_damage(battler):
			continue
		@warning_ignore("integer_division")
		var dmg: int = maxi(1, battler.get_max_hp() / 16)
		battler.apply_damage(dmg)
		_emit_hp(battler.is_player_side)
		message.emit("%s es azotado por el clima." % battler.get_display_name())
		await _wait(0.5)
		if battler.is_fainted():
			message.emit("¡%s se debilitó!" % battler.get_display_name())
			await _wait(0.8)


func _manejar_debilitacion_jugador() -> void:
	message.emit("¡%s se debilitó!" % player.get_display_name())
	await _wait(1.0)

	if tiene_reemplazo():
		player_must_switch.emit()
		return

	message.emit("Has perdido...")
	await _wait(1.0)
	_cleanup_battle_pokemon()
	is_running = false
	battle_ended.emit(false)


func _sort_actions(actions: Array[BattleAction]) -> Array[BattleAction]:
	actions.sort_custom(func(a: BattleAction, b: BattleAction) -> bool:
		if a.priority != b.priority:
			return a.priority > b.priority
		var sa: float = float(a.actor.get_effective_stat(PokemonInstance.Stat.SPEED)) \
			* AbilityRuntime.speed_multiplier(a.actor, weather, terrain)
		var sb: float = float(b.actor.get_effective_stat(PokemonInstance.Stat.SPEED)) \
			* AbilityRuntime.speed_multiplier(b.actor, weather, terrain)
		if sa != sb:
			return sa > sb
		var stall_a: bool = AbilityRuntime.has(a.actor, AbilityId.Id.STALL)
		var stall_b: bool = AbilityRuntime.has(b.actor, AbilityId.Id.STALL)
		if stall_a != stall_b:
			return not stall_a
		# Quick Draw: 30% gana el desempate de velocidad
		var qd_a: bool = AbilityRuntime.quick_draw_wins_speed_tie(a.actor)
		var qd_b: bool = AbilityRuntime.quick_draw_wins_speed_tie(b.actor)
		if qd_a != qd_b:
			return qd_a
		return randf() < 0.5
	)
	return actions


func _execute_move(action: BattleAction) -> void:
	if action == null or action.actor == null:
		return
	if AbilityRuntime.should_skip_turn(action.actor):
		await ability_announce(action.actor)
		message.emit("¡%s holgazanea!" % action.actor.get_display_name())
		await _wait(0.8)
		return
	var actor: BattleBattler = action.actor
	var target: BattleBattler = action.target
	var move: MoveData = action.move

	AbilityRuntime.try_protean(actor, move, self)

	if target != null and AbilityRuntime.damp_blocks_explosion(target, move):
		await ability_announce(target)
		message.emit("¡%s no puede usar %s!" % [actor.get_display_name(), move.move_name])
		await _wait(0.8)
		return
	if actor != null and AbilityRuntime.damp_blocks_explosion(actor, move):
		await ability_announce(actor)
		message.emit("¡%s no puede usar %s!" % [actor.get_display_name(), move.move_name])
		await _wait(0.8)
		return

	if target != null and AbilityRuntime.blocks_priority_move(target, move):
		var effective_prio: int = move.priority + AbilityRuntime.priority_bonus(actor, move)
		if effective_prio > 0:
			await ability_announce(target)
			message.emit("¡%s no puede usar movimientos con prioridad!" % actor.get_display_name())
			await _wait(0.8)
			return

	if target != null and AbilityRuntime.blocks_status_move(target, move) \
			and move.target != MoveStruct.MoveTarget.TARGET_USER:
		await ability_announce(target)
		message.emit("¡No afecta a %s!" % target.get_display_name())
		await _wait(0.8)
		return

	var is_charge_release: bool = actor.charging_move != null
	if is_charge_release:
		actor.charging_move = null
		actor.charging_target = null
		actor.semi_invulnerable = false

	if not is_charge_release:
		if not actor.consume_pp(action.move_slot_index):
			message.emit("%s no tiene PP para usar %s!" % [actor.get_display_name(), move.move_name])
			await _wait(0.8)
			return

	var check: StatusConditions.ActionCheck = StatusConditions.check_can_act(actor)
	actor.flinched = false
	if not check.message.is_empty():
		message.emit(check.message)
		await _wait(0.8)
	if not check.can_act:
		if check.is_confusion_hit:
			var self_damage: int = StatusConditions.self_hit_confusion(actor)
			var dealt_self: int = actor.apply_damage(self_damage)
			_emit_hp(actor.is_player_side)
			message.emit("Hizo %d PS de daño." % dealt_self)
			await _wait(0.7)
			if actor.is_fainted():
				message.emit("¡%s se debilitó!" % actor.get_display_name())
				await _wait(0.8)
		return

	if not is_charge_release and TwoTurnResolver.is_charge_move(move) \
			and not TwoTurnResolver.skips_charge_in_weather(move, weather):
		message.emit(TwoTurnResolver.charge_message(move, actor.get_display_name()))
		await _wait(0.9)
		actor.charging_move = move
		actor.charging_target = target
		actor.charging_slot_index = action.move_slot_index
		if TwoTurnResolver.grants_invulnerability(move):
			actor.semi_invulnerable = true
		return

	message.emit("%s usó %s!" % [actor.get_display_name(), move.move_name])
	await _wait(0.9)

	if TwoTurnResolver.is_recharge_move(move):
		actor.must_recharge = true

	if ProtectResolver.is_protect_move(move):
		await _resolve_protect_move(actor, move)
		return

	if target.semi_invulnerable:
		message.emit("¡%s esquivó el ataque!" % target.get_display_name())
		await _wait(0.8)
		return

	if target.protect_active and ProtectResolver.blocks_move(target.protect_kind, move) \
			and not AbilityRuntime.ignores_protect_contact(actor, move):
		message.emit("¡%s se protegió del ataque!" % target.get_display_name())
		await _wait(0.8)
		await _resolve_protect_contact(actor, target, move)
		return

	if move.effect == MoveStruct.MoveEffect.EFFECT_GEOMANCY and is_charge_release:
		await _apply_stat_change(actor, PokemonInstance.Stat.SP_ATTACK, 2)
		await _apply_stat_change(actor, PokemonInstance.Stat.SP_DEFENSE, 2)
		await _apply_stat_change(actor, PokemonInstance.Stat.SPEED, 2)
		return

	# Movimientos de estado:
	if move.category == MoveStruct.DamageCategory.STATUS or move.power <= 0:
		if not DamageCalculator.check_hit(move, actor, target):
			message.emit("¡El ataque de %s falló!" % actor.get_display_name())
			await _wait(0.8)
			return
		await _apply_status_move_effect(actor, target, move)
		return

	if not DamageCalculator.check_hit(move, actor, target):
		message.emit("¡El ataque de %s falló!" % actor.get_display_name())
		await _wait(0.8)
		return

	var hit_count: int = DamageCalculator.roll_hit_count(move)
	if move.is_multi_hit and AbilityRuntime.always_max_hits(actor):
		hit_count = move.max_hits

	var total_dealt: int = 0
	var last_result: DamageCalculator.HitResult = null
	var hits_landed: int = 0

	for i: int in hit_count:
		if target.is_fainted() or actor.is_fainted():
			break

		var screens: bool = _side_for(target).has_screen(move.category == MoveStruct.DamageCategory.PHYSICAL)
		if AbilityRuntime.has(actor, AbilityId.Id.INFILTRATOR):
			screens = false
		var result: DamageCalculator.HitResult = DamageCalculator.compute_hit(
			actor, target, move, weather, screens
		)
		if result.damage > 0:
			var ctx_mult: float = 1.0
			ctx_mult *= AbilityRuntime.supreme_overlord_multiplier(actor, self)
			ctx_mult *= AbilityRuntime.aura_multiplier(actor, target, AbilityRuntime.effective_move_type(actor, move), self)
			if move.category == MoveStruct.DamageCategory.PHYSICAL:
				ctx_mult *= AbilityRuntime.ruin_stat_multiplier(actor, PokemonInstance.Stat.ATTACK, self)
				var def_ruin: float = AbilityRuntime.ruin_stat_multiplier(target, PokemonInstance.Stat.DEFENSE, self)
				if def_ruin > 0.0:
					ctx_mult /= def_ruin
			else:
				ctx_mult *= AbilityRuntime.ruin_stat_multiplier(actor, PokemonInstance.Stat.SP_ATTACK, self)
				var spd_ruin: float = AbilityRuntime.ruin_stat_multiplier(target, PokemonInstance.Stat.SP_DEFENSE, self)
				if spd_ruin > 0.0:
					ctx_mult /= spd_ruin
			ctx_mult *= AbilityRuntime.sand_force_active(actor, move, weather)
			ctx_mult *= AbilityRuntime.solar_power_multiplier(actor, move.category, weather)
			ctx_mult *= AbilityRuntime.hadron_orichalcum_multiplier(actor, move.category, weather, terrain)
			if not AbilityRuntime.ignores_defender_ability(actor):
				ctx_mult *= AbilityRuntime.grass_pelt_multiplier(target, move, terrain)
			var acted_after: bool = action.priority < 0 or (
				target != null
				and actor.get_effective_stat(PokemonInstance.Stat.SPEED)
					< target.get_effective_stat(PokemonInstance.Stat.SPEED)
				and move.priority <= 0
			)
			ctx_mult *= AbilityRuntime.analytic_multiplier(actor, acted_after)
			if ctx_mult != 1.0:
				result.damage = maxi(1, int(round(float(result.damage) * ctx_mult)))
		last_result = result

		if result.ability_immunity != "":
			if i == 0:
				await _handle_ability_immunity(target, move, result)
			break

		if result.effectiveness <= 0.0:
			if i == 0:
				message.emit("No afecta a %s..." % target.get_display_name())
				await _wait(0.8)
			break

		if target.endure_active and target.pokemon.current_hp > 1 and result.damage >= target.pokemon.current_hp:
			result.damage = target.pokemon.current_hp - 1

		var hp_before_hit: int = target.pokemon.current_hp if target.pokemon else 0
		var dealt: int = target.apply_damage(result.damage)
		total_dealt += dealt
		hits_landed += 1
		_emit_hp(target.is_player_side)

		# Illusion se rompe con el primer daño real
		if dealt > 0 and target.illusion_active:
			await AbilityRuntime.break_illusion(target, self)

		if result.critical:
			message.emit("¡Un golpe crítico!")
			await _wait(0.5)

		if result.sturdy_activated:
			await ability_announce(target)
			message.emit("¡%s aguantó el golpe!" % target.get_display_name())
			await _wait(0.5)

		if target.endure_active and target.pokemon.current_hp == 1 and dealt > 0 and not result.sturdy_activated:
			message.emit("¡%s resistió el golpe!" % target.get_display_name())
			await _wait(0.5)

		# Weak Armor, Justified, Rattled, Stamina, Anger Point, Steam Engine, Water Compaction
		if dealt > 0 and not target.is_fainted():
			await AbilityRuntime.on_damaged_by_move(target, actor, move, result.critical, self)
			# Wimp Out / Emergency Exit
			if await AbilityRuntime.check_wimp_or_emergency(target, hp_before_hit, self):
				if target.is_player_side:
					player_must_switch.emit()
				else:
					# IA simple: el manager ya tiene flujo de cambio enemigo si aplica
					pass

		if move.recoil_percent > 0 and not actor.is_fainted():
			await _apply_recoil(actor, dealt, move.recoil_percent)
			if actor.is_fainted():
				break

		if move.drain_percent > 0:
			await _apply_drain(actor, target, dealt, move.drain_percent)

		if AbilityRuntime.move_makes_contact(actor, move):
			await AbilityRuntime.on_contact_hit(actor, target, move, self)
		if not actor.is_fainted() and not target.is_fainted() and dealt > 0:
			await AbilityRuntime.try_magician(actor, target, self)
		if actor.is_fainted():
			break

		if target.is_fainted() and AbilityRuntime.has(target, AbilityId.Id.AFTERMATH) \
				and AbilityRuntime.move_makes_contact(actor, move):
			await ability_announce(target)
			@warning_ignore("integer_division")
			var aftermath_dmg: int = maxi(1, actor.get_max_hp() / 4)
			await ability_deal_damage(actor, aftermath_dmg, target)
			if actor.is_fainted():
				break
		if target.is_fainted() and AbilityRuntime.has(target, AbilityId.Id.INNARDS_OUT):
			await ability_announce(target)
			await ability_deal_damage(actor, dealt, target)
			if actor.is_fainted():
				break

	if last_result == null or last_result.ability_immunity != "" or last_result.effectiveness <= 0.0:
		return

	if AbilityRuntime.has(actor, AbilityId.Id.PARENTAL_BOND) and not move.parental_bond_banned \
			and not target.is_fainted() and not actor.is_fainted() and hits_landed > 0:
		await ability_announce(actor)
		var bond: DamageCalculator.HitResult = DamageCalculator.compute_hit(
			actor, target, move, weather, false
		)
		if bond.damage > 0:
			bond.damage = maxi(1, int(round(float(bond.damage) * 0.25)))
			var bond_dealt: int = target.apply_damage(bond.damage)
			total_dealt += bond_dealt
			hits_landed += 1
			_emit_hp(target.is_player_side)
			if bond_dealt > 0 and not target.is_fainted():
				await AbilityRuntime.on_damaged_by_move(target, actor, move, bond.critical, self)

	await _announce_passive_abilities(actor, target, last_result)

	if hits_landed > 1:
		message.emit("¡Golpeó %d veces!" % hits_landed)
		await _wait(0.5)

	if last_result.effectiveness > 1.0:
		message.emit("¡Es muy efectivo!")
		await _wait(0.6)
	elif last_result.effectiveness < 1.0:
		message.emit("No es muy efectivo...")
		await _wait(0.6)

	message.emit("Hizo %d PS de daño." % total_dealt)
	await _wait(0.7)
	if actor.charged and total_dealt > 0:
		actor.charged = false

	await _apply_damaging_move_effect(actor, target, move, total_dealt)

	if target.is_fainted():
		await _trigger_ko_ability(actor, target)
		return

	if actor.is_fainted():
		return

	if move.secondary_effect != MoveStruct.SecondaryEffect.MOVE_EFFECT_NONE \
			and not AbilityRuntime.has(actor, AbilityId.Id.SHEER_FORCE):
		var chance: int = move.secondary_chance
		if AbilityRuntime.has(actor, AbilityId.Id.SERENE_GRACE):
			chance = mini(100, chance * 2)
		if randi_range(1, 100) <= chance:
			await _apply_secondary_effect(actor, target, move)

@warning_ignore("unused_parameter")
func _handle_ability_immunity(target: BattleBattler, move: MoveData, result: DamageCalculator.HitResult) -> void:
	await ability_announce(target)

	match result.ability_immunity:
		"immune":
			message.emit("¡No afecta a %s!" % target.get_display_name())
			await _wait(0.8)

		"heal":
			message.emit("¡%s absorbió el ataque!" % target.get_display_name())
			await _wait(0.6)
			@warning_ignore("integer_division")
			await ability_heal(target, maxi(1, target.get_max_hp() / 4))

		"spatk_up":
			await ability_change_stat(target, PokemonInstance.Stat.SP_ATTACK, 1)

		"atk_up":
			await ability_change_stat(target, PokemonInstance.Stat.ATTACK, 1)

		"def_up":
			await ability_change_stat(target, PokemonInstance.Stat.DEFENSE, 2)

		"spe_up":
			await ability_change_stat(target, PokemonInstance.Stat.SPEED, 1)

		"flash_fire":
			target.flash_fire_boosted = true
			message.emit("¡Los movimientos de tipo Fuego de %s se potenciarán!" % target.get_display_name())
			await _wait(0.8)

		_:
			message.emit("¡La habilidad de %s anuló el ataque!" % target.get_display_name())
			await _wait(0.8)

func _apply_recoil(actor: BattleBattler, damage_dealt: int, percent: int) -> void:
	if damage_dealt <= 0 or AbilityRuntime.blocks_indirect_damage(actor) or AbilityRuntime.blocks_recoil(actor):
		return
	var recoil: int = maxi(1, int(floor(float(damage_dealt) * float(percent) / 100.0)))
	var taken: int = actor.apply_damage(recoil)
	_emit_hp(actor.is_player_side)
	message.emit("%s recibió daño por el retroceso." % actor.get_display_name())
	await _wait(0.6)
	if taken > 0 and actor.is_fainted():
		message.emit("¡%s se debilitó!" % actor.get_display_name())
		await _wait(0.8)

func _trigger_ko_ability(actor: BattleBattler, _fainted_target: BattleBattler) -> void:
	if actor.is_fainted():
		return
	match AbilityRuntime.get_id(actor):
		AbilityId.Id.MOXIE, AbilityId.Id.CHILLING_NEIGH:
			await ability_announce(actor)
			await ability_change_stat(actor, PokemonInstance.Stat.ATTACK, 1)
		AbilityId.Id.GRIM_NEIGH, AbilityId.Id.SOUL_HEART:
			await ability_announce(actor)
			await ability_change_stat(actor, PokemonInstance.Stat.SP_ATTACK, 1)
		AbilityId.Id.BEAST_BOOST:
			await ability_announce(actor)
			await ability_change_stat(actor, _highest_stat(actor), 1)


func _highest_stat(battler: BattleBattler) -> PokemonInstance.Stat:
	var best_stat: PokemonInstance.Stat = PokemonInstance.Stat.ATTACK
	var best_value: int = -1
	for stat: PokemonInstance.Stat in [
		PokemonInstance.Stat.ATTACK, PokemonInstance.Stat.DEFENSE,
		PokemonInstance.Stat.SP_ATTACK, PokemonInstance.Stat.SP_DEFENSE,
		PokemonInstance.Stat.SPEED
	]:
		var value: int = battler.get_effective_stat(stat)
		if value > best_value:
			best_value = value
			best_stat = stat
	return best_stat

func _apply_drain(actor: BattleBattler, target: BattleBattler, damage_dealt: int, percent: int) -> void:
	if damage_dealt <= 0 or actor.pokemon == null:
		return
	var amount: int = maxi(1, int(floor(float(damage_dealt) * float(percent) / 100.0)))

	if AbilityRuntime.has(target, AbilityId.Id.LIQUID_OOZE):
		await ability_announce(target)
		var taken: int = actor.apply_damage(amount)
		_emit_hp(actor.is_player_side)
		message.emit("¡%s fue dañado por Liquid Ooze!" % actor.get_display_name())
		await _wait(0.6)
		if taken > 0 and actor.is_fainted():
			message.emit("¡%s se debilitó!" % actor.get_display_name())
			await _wait(0.8)
		return

	actor.pokemon.apply_heal(amount)
	_emit_hp(actor.is_player_side)
	message.emit("¡%s absorbió energía!" % actor.get_display_name())
	await _wait(0.6)

func _resolve_protect_move(actor: BattleBattler, move: MoveData) -> void:
	var chance: float = ProtectResolver.success_chance(actor.protect_counter)
	if randf() >= chance:
		message.emit("¡Pero falló!")
		await _wait(0.8)
		actor.protect_counter = 0
		return

	actor.protect_counter += 1

	if move.effect == MoveStruct.MoveEffect.EFFECT_ENDURE:
		actor.endure_active = true
		message.emit("¡%s se preparó para resistir el golpe!" % actor.get_display_name())
	else:
		actor.protect_active = true
		actor.protect_kind = ProtectResolver.kind_for(move)
		message.emit("¡%s se protegió!" % actor.get_display_name())
	await _wait(0.8)


func _resolve_protect_contact(actor: BattleBattler, target: BattleBattler, move: MoveData) -> void:
	if not move.makes_contact:
		return
	match target.protect_kind:
		ProtectResolver.Kind.SPIKY_SHIELD:
			@warning_ignore("integer_division")
			var dmg: int = maxi(1, actor.get_max_hp() / 8)
			var taken: int = actor.apply_damage(dmg)
			_emit_hp(actor.is_player_side)
			message.emit("¡%s se lastimó con las púas!" % actor.get_display_name())
			await _wait(0.6)
			if taken > 0 and actor.is_fainted():
				message.emit("¡%s se debilitó!" % actor.get_display_name())
				await _wait(0.8)
		ProtectResolver.Kind.KINGS_SHIELD:
			await _apply_stat_change(actor, PokemonInstance.Stat.ATTACK, -2, true)
		ProtectResolver.Kind.OBSTRUCT:
			await _apply_stat_change(actor, PokemonInstance.Stat.DEFENSE, -2, true)
		ProtectResolver.Kind.BANEFUL_BUNKER:
			await _apply_status(actor, PokemonInstance.Status.POISON)

func _apply_secondary_effect(actor: BattleBattler, target: BattleBattler, move: MoveData) -> void:
	if AbilityRuntime.has(target, AbilityId.Id.SHIELD_DUST):
		return
	var stat_effect: Array = MoveEffectResolver.get_secondary_stat_effect(move.secondary_effect)
	if not stat_effect.is_empty():
		var receiver: BattleBattler = actor if stat_effect[1] > 0 else target
		await _apply_stat_change(receiver, stat_effect[0], stat_effect[1], receiver == target)
		return

	if MoveEffectResolver.is_flinch_effect(move.secondary_effect):
		if not AbilityRuntime.blocks_flinch(target):
			target.flinched = true
			await AbilityRuntime.on_flinched(target, self)
		return

	if MoveEffectResolver.is_confuse_effect(move.effect, move.secondary_effect):
		await _apply_confusion(target)
		return

	var status_value: int = MoveEffectResolver.get_secondary_status(move.secondary_effect)
	if status_value >= 0:
		await _apply_status(target, status_value as PokemonInstance.Status)


func _apply_status_move_effect(actor: BattleBattler, target: BattleBattler, move: MoveData) -> void:
	var receiver: BattleBattler = actor if move.target == MoveStruct.MoveTarget.TARGET_USER else target

	var stat_effect: Array = MoveEffectResolver.get_primary_stat_effect(move.effect)
	if not stat_effect.is_empty():
		await _apply_stat_change(receiver, stat_effect[0], stat_effect[1], receiver == target)
		return

	var acc_eva: Array = MoveEffectResolver.get_primary_accuracy_evasion_effect(move.effect)
	if not acc_eva.is_empty():
		var is_acc: bool = acc_eva[0] == "acc"
		var stages: int = acc_eva[1]
		if is_acc and stages < 0 and receiver == target and AbilityRuntime.blocks_foe_accuracy_drop(receiver):
			await ability_announce(receiver)
			message.emit("¡La precisión de %s no bajó!" % receiver.get_display_name())
			await _wait(0.6)
			return
		var adjusted: int = AbilityRuntime.adjust_own_stage_change(receiver, stages)
		var actual: int = receiver.modify_accuracy_stage(adjusted) if is_acc else receiver.modify_evasion_stage(adjusted)
		var label: String = "Precisión" if is_acc else "Evasión"
		if actual == 0:
			message.emit("¡La %s de %s ya no puede cambiar más!" % [label, receiver.get_display_name()])
		elif actual > 0:
			message.emit("¡La %s de %s subió!" % [label, receiver.get_display_name()])
		else:
			message.emit("¡La %s de %s bajó!" % [label, receiver.get_display_name()])
		await _wait(0.6)
		return

	if MoveEffectResolver.is_confuse_effect(move.effect, move.secondary_effect):
		await _apply_confusion(receiver)
		return

	if move.effect == MoveStruct.MoveEffect.EFFECT_NON_VOLATILE_STATUS:
		var status_value: int = MoveEffectResolver.get_secondary_status(move.secondary_effect)
		if status_value >= 0:
			await _apply_status(receiver, status_value as PokemonInstance.Status)
			return

	match move.effect:
		MoveStruct.MoveEffect.EFFECT_RESTORE_HP, MoveStruct.MoveEffect.EFFECT_SOFTBOILED, \
		MoveStruct.MoveEffect.EFFECT_HEAL_PULSE, MoveStruct.MoveEffect.EFFECT_MORNING_SUN, \
		MoveStruct.MoveEffect.EFFECT_SYNTHESIS, MoveStruct.MoveEffect.EFFECT_MOONLIGHT, \
		MoveStruct.MoveEffect.EFFECT_ROOST, MoveStruct.MoveEffect.EFFECT_SHORE_UP, \
		MoveStruct.MoveEffect.EFFECT_LIFE_DEW, MoveStruct.MoveEffect.EFFECT_JUNGLE_HEALING:
			await _heal_move_target(receiver, move)
			return

		MoveStruct.MoveEffect.EFFECT_REST:
			if actor.pokemon.current_hp >= actor.get_max_hp() or actor.pokemon.has_status():
				message.emit("¡No surtirá efecto!")
				await _wait(0.7)
				return
			actor.pokemon.current_hp = actor.get_max_hp()
			actor.pokemon.status = PokemonInstance.Status.SLEEP
			actor.pokemon.status_counter = 2
			_emit_hp(actor.is_player_side)
			message.emit("¡%s se durmió y recuperó todos sus PS!" % actor.get_display_name())
			await _wait(0.8)
			return

		MoveStruct.MoveEffect.EFFECT_HAZE:
			player._reset_stages()
			enemy._reset_stages()
			message.emit("¡Se eliminaron todos los cambios de estadísticas!")
			await _wait(0.7)
			return

		MoveStruct.MoveEffect.EFFECT_HEAL_BELL, MoveStruct.MoveEffect.EFFECT_REFRESH, MoveStruct.MoveEffect.EFFECT_PURIFY:
			if receiver.pokemon.has_status():
				receiver.pokemon.cure_status()
				message.emit("¡%s se curó de su estado!" % receiver.get_display_name())
			else:
				message.emit("¡Pero falló!")
			await _wait(0.7)
			return

		MoveStruct.MoveEffect.EFFECT_WEATHER, MoveStruct.MoveEffect.EFFECT_WEATHER_AND_SWITCH:
			_set_weather_from_move(move)
			await _wait(0.7)
			return

		MoveStruct.MoveEffect.EFFECT_BULK_UP:
			await _apply_stat_change(actor, PokemonInstance.Stat.ATTACK, 1)
			await _apply_stat_change(actor, PokemonInstance.Stat.DEFENSE, 1)
			return
		MoveStruct.MoveEffect.EFFECT_CALM_MIND:
			await _apply_stat_change(actor, PokemonInstance.Stat.SP_ATTACK, 1)
			await _apply_stat_change(actor, PokemonInstance.Stat.SP_DEFENSE, 1)
			return
		MoveStruct.MoveEffect.EFFECT_DRAGON_DANCE:
			await _apply_stat_change(actor, PokemonInstance.Stat.ATTACK, 1)
			await _apply_stat_change(actor, PokemonInstance.Stat.SPEED, 1)
			return
		MoveStruct.MoveEffect.EFFECT_COSMIC_POWER:
			await _apply_stat_change(actor, PokemonInstance.Stat.DEFENSE, 1)
			await _apply_stat_change(actor, PokemonInstance.Stat.SP_DEFENSE, 1)
			return
		MoveStruct.MoveEffect.EFFECT_QUIVER_DANCE:
			await _apply_stat_change(actor, PokemonInstance.Stat.SP_ATTACK, 1)
			await _apply_stat_change(actor, PokemonInstance.Stat.SP_DEFENSE, 1)
			await _apply_stat_change(actor, PokemonInstance.Stat.SPEED, 1)
			return
		MoveStruct.MoveEffect.EFFECT_SHIFT_GEAR:
			await _apply_stat_change(actor, PokemonInstance.Stat.ATTACK, 1)
			await _apply_stat_change(actor, PokemonInstance.Stat.SPEED, 2)
			return
		MoveStruct.MoveEffect.EFFECT_SHELL_SMASH:
			await _apply_stat_change(actor, PokemonInstance.Stat.DEFENSE, -1)
			await _apply_stat_change(actor, PokemonInstance.Stat.SP_DEFENSE, -1)
			await _apply_stat_change(actor, PokemonInstance.Stat.ATTACK, 2)
			await _apply_stat_change(actor, PokemonInstance.Stat.SP_ATTACK, 2)
			await _apply_stat_change(actor, PokemonInstance.Stat.SPEED, 2)
			return
		MoveStruct.MoveEffect.EFFECT_REFLECT:
			var own_side: FieldSide = _side_for(actor)
			if own_side.reflect_turns > 0:
				message.emit("¡Pero falló!")
			else:
				own_side.reflect_turns = 5
				message.emit("¡Se alzó un muro de reflejos alrededor del equipo de %s!" % actor.get_display_name())
			await _wait(0.8)
			return

		MoveStruct.MoveEffect.EFFECT_LIGHT_SCREEN:
			var own_side2: FieldSide = _side_for(actor)
			if own_side2.light_screen_turns > 0:
				message.emit("¡Pero falló!")
			else:
				own_side2.light_screen_turns = 5
				message.emit("¡Se alzó una pantalla de luz alrededor del equipo de %s!" % actor.get_display_name())
			await _wait(0.8)
			return

		MoveStruct.MoveEffect.EFFECT_AURORA_VEIL:
			if weather != AbilityBattleEffect.weatherAbilityID.WEATHER_SNOW:
				message.emit("¡Pero falló!")
				await _wait(0.8)
				return
			var own_side3: FieldSide = _side_for(actor)
			if own_side3.aurora_veil_turns > 0:
				message.emit("¡Pero falló!")
			else:
				own_side3.aurora_veil_turns = 5
				message.emit("¡Se alzó un velo aurora alrededor del equipo de %s!" % actor.get_display_name())
			await _wait(0.8)
			return

		MoveStruct.MoveEffect.EFFECT_SPIKES:
			var opp_side: FieldSide = _side_for(target)
			if opp_side.spikes_layers >= 3:
				message.emit("¡Pero falló!")
			else:
				opp_side.spikes_layers += 1
				message.emit("¡Se esparcieron púas alrededor del equipo rival!")
			await _wait(0.8)
			return

		MoveStruct.MoveEffect.EFFECT_TOXIC_SPIKES:
			var opp_side2: FieldSide = _side_for(target)
			if opp_side2.toxic_spikes_layers >= 2:
				message.emit("¡Pero falló!")
			else:
				opp_side2.toxic_spikes_layers += 1
				message.emit("¡Se esparcieron púas tóxicas alrededor del equipo rival!")
			await _wait(0.8)
			return

		MoveStruct.MoveEffect.EFFECT_STEALTH_ROCK:
			var opp_side3: FieldSide = _side_for(target)
			if opp_side3.stealth_rock:
				message.emit("¡Pero falló!")
			else:
				opp_side3.stealth_rock = true
				message.emit("¡Aparecieron rocas puntiagudas alrededor del equipo rival!")
			await _wait(0.8)
			return

		MoveStruct.MoveEffect.EFFECT_STICKY_WEB:
			var opp_side4: FieldSide = _side_for(target)
			if opp_side4.sticky_web:
				message.emit("¡Pero falló!")
			else:
				opp_side4.sticky_web = true
				message.emit("¡Se tejió una red pegajosa bajo los pies del equipo rival!")
			await _wait(0.8)
			return

		MoveStruct.MoveEffect.EFFECT_DEFOG:
			var actual: int = target.modify_evasion_stage(-1)
			if actual < 0:
				message.emit("¡La Evasión de %s bajó!" % target.get_display_name())
				await _wait(0.6)
			player_side.clear_hazards()
			player_side.clear_screens()
			enemy_side.clear_hazards()
			enemy_side.clear_screens()
			message.emit("¡Los efectos del terreno se disiparon!")
			await _wait(0.8)
			return

	message.emit("¡Pero no tuvo ningún efecto todavía!")
	await _wait(0.8)


func _heal_move_target(target: BattleBattler, move: MoveData) -> void:
	if target == null or target.pokemon == null or target.is_fainted() or target.get_current_hp() >= target.get_max_hp():
		message.emit("¡No surtirá efecto!")
		await _wait(0.7)
		return
	var fraction: float = 0.5
	if move.effect == MoveStruct.MoveEffect.EFFECT_MORNING_SUN \
			or move.effect == MoveStruct.MoveEffect.EFFECT_SYNTHESIS \
			or move.effect == MoveStruct.MoveEffect.EFFECT_MOONLIGHT:
		if weather == AbilityBattleEffect.weatherAbilityID.WEATHER_DROUGHT:
			fraction = 2.0 / 3.0
		elif weather != AbilityBattleEffect.weatherAbilityID.WEATHER_NONE:
			fraction = 0.25
	elif move.effect == MoveStruct.MoveEffect.EFFECT_SHORE_UP and weather == AbilityBattleEffect.weatherAbilityID.WEATHER_SANDSTORM:
		fraction = 2.0 / 3.0
	var amount: int = maxi(1, int(floor(float(target.get_max_hp()) * fraction)))
	target.pokemon.apply_heal(amount)
	_emit_hp(target.is_player_side)
	message.emit("¡%s recuperó PS!" % target.get_display_name())
	await _wait(0.7)


func _set_weather_from_move(move: MoveData) -> void:
	var weather_from_type: int = AbilityBattleEffect.weatherAbilityID.WEATHER_NONE
	match move.type:
		PokemonData.Type.TYPE_WATER:
			weather_from_type = AbilityBattleEffect.weatherAbilityID.WEATHER_RAIN
		PokemonData.Type.TYPE_FIRE:
			weather_from_type = AbilityBattleEffect.weatherAbilityID.WEATHER_DROUGHT
		PokemonData.Type.TYPE_ROCK:
			weather_from_type = AbilityBattleEffect.weatherAbilityID.WEATHER_SANDSTORM
		PokemonData.Type.TYPE_ICE:
			weather_from_type = AbilityBattleEffect.weatherAbilityID.WEATHER_SNOW
		_:
			pass
	if weather_from_type == AbilityBattleEffect.weatherAbilityID.WEATHER_NONE:
		message.emit("¡Pero falló!")
		return
	set_weather(weather_from_type, 5)


func _apply_damaging_move_effect(actor: BattleBattler, target: BattleBattler, move: MoveData, damage_dealt: int) -> void:
	if damage_dealt <= 0 or actor.is_fainted():
		return
	match move.effect:
		MoveStruct.MoveEffect.EFFECT_RAPID_SPIN:
			_side_for(actor).clear_hazards()
			message.emit("¡%s eliminó los peligros de su lado!" % actor.get_display_name())
			await _wait(0.5)
		MoveStruct.MoveEffect.EFFECT_STONE_AXE:
			_side_for(target).stealth_rock = true
			message.emit("¡Aparecieron rocas puntiagudas alrededor del rival!")
			await _wait(0.5)
		MoveStruct.MoveEffect.EFFECT_CEASELESS_EDGE:
			_side_for(target).spikes_layers = mini(3, _side_for(target).spikes_layers + 1)
			message.emit("¡Se esparcieron púas alrededor del rival!")
			await _wait(0.5)
		MoveStruct.MoveEffect.EFFECT_HIT_ENEMY_HEAL_ALLY:
			await _heal_move_target(actor, move)
		MoveStruct.MoveEffect.EFFECT_FELL_STINGER:
			if target.is_fainted():
				await _apply_stat_change(actor, PokemonInstance.Stat.ATTACK, 3)

func _apply_stat_change(battler: BattleBattler, stat: PokemonInstance.Stat, stages: int, caused_by_foe: bool = false) -> void:
	if caused_by_foe and stages < 0 and _side_for(battler).mist_turns > 0:
		message.emit("¡Neblina protege a %s de la bajada de estadística!" % battler.get_display_name())
		await _wait(0.6)
		return
	if caused_by_foe and stages < 0 and AbilityRuntime.blocks_foe_stat_drop(battler, stat):
		await ability_announce(battler)
		message.emit("¡Las estadísticas de %s no bajaron!" % battler.get_display_name())
		await _wait(0.6)
		return

	var adjusted: int = AbilityRuntime.adjust_own_stage_change(battler, stages)
	var actual: int = battler.modify_stage(stat, adjusted)
	var name: String = _stat_display_name(stat)
	if actual == 0:
		message.emit("¡El %s de %s ya no puede cambiar más!" % [name, battler.get_display_name()])
	elif actual > 0:
		message.emit("¡%s de %s subió!" % [name, battler.get_display_name()])
	else:
		message.emit("¡%s de %s bajó!" % [name, battler.get_display_name()])
	await _wait(0.6)
	if caused_by_foe and actual < 0:
		await AbilityRuntime.after_own_stat_drop(battler, actual, true, self)

func _apply_status(battler: BattleBattler, status: PokemonInstance.Status) -> void:
	if AbilityRuntime.blocks_status(battler, status, weather):
		await ability_announce(battler)
		message.emit("¡%s no se vio afectado!" % battler.get_display_name())
		await _wait(0.6)
		return
	if battler.pokemon.apply_status(status):
		message.emit("¡%s quedó %s!" % [battler.get_display_name(), StatusConditions.status_name(status)])
	else:
		message.emit("¡No tuvo efecto!")
	await _wait(0.6)


func _apply_confusion(battler: BattleBattler) -> void:
	if AbilityRuntime.blocks_confusion(battler):
		await ability_announce(battler)
		message.emit("¡%s no se confundió!" % battler.get_display_name())
		await _wait(0.6)
		return
	if battler.is_confused():
		message.emit("¡No tuvo efecto!")
	else:
		battler.confusion_turns = randi_range(2, 5)
		message.emit("¡%s se confundió!" % battler.get_display_name())
	await _wait(0.6)


func _stat_display_name(stat: PokemonInstance.Stat) -> String:
	match stat:
		PokemonInstance.Stat.ATTACK: return "Ataque"
		PokemonInstance.Stat.DEFENSE: return "Defensa"
		PokemonInstance.Stat.SP_ATTACK: return "Ataque Especial"
		PokemonInstance.Stat.SP_DEFENSE: return "Defensa Especial"
		PokemonInstance.Stat.SPEED: return "Velocidad"
		_: return "Estadística"

func _side_for(battler: BattleBattler) -> FieldSide:
	return player_side if battler.is_player_side else enemy_side

func _apply_hazards_on_switch_in(battler: BattleBattler) -> void:
	if battler.pokemon == null or battler.is_fainted():
		return
	var side: FieldSide = _side_for(battler)
	var is_flying: bool = battler.pokemon.get_type_1() == PokemonData.Type.TYPE_FLYING \
		or battler.pokemon.get_type_2() == PokemonData.Type.TYPE_FLYING
	var is_grounded: bool = not is_flying and not AbilityRuntime.has(battler, AbilityId.Id.LEVITATE)

	if side.stealth_rock:
		var eff: float = TypeChart.get_effectiveness(
			PokemonData.Type.TYPE_ROCK, battler.pokemon.get_type_1(), battler.pokemon.get_type_2()
		)
		var dmg: int = maxi(1, int(float(battler.get_max_hp()) * 0.125 * eff))
		var taken: int = battler.apply_damage(dmg)
		_emit_hp(battler.is_player_side)
		message.emit("¡A %s le dañaron las Rocas Afiladas!" % battler.get_display_name())
		await _wait(0.6)
		if taken > 0 and battler.is_fainted():
			message.emit("¡%s se debilitó!" % battler.get_display_name())
			await _wait(0.8)
			return

	if side.sticky_web and is_grounded:
		message.emit("¡%s quedó atrapado en la Red Viscosa!" % battler.get_display_name())
		await _apply_stat_change(battler, PokemonInstance.Stat.SPEED, -1, true)

	if side.spikes_layers > 0 and is_grounded:
		var fraction: float = [0.0, 1.0 / 8.0, 1.0 / 6.0, 1.0 / 4.0][side.spikes_layers]
		var dmg2: int = maxi(1, int(float(battler.get_max_hp()) * fraction))
		var taken2: int = battler.apply_damage(dmg2)
		_emit_hp(battler.is_player_side)
		message.emit("¡A %s le dañaron las Púas!" % battler.get_display_name())
		await _wait(0.6)
		if taken2 > 0 and battler.is_fainted():
			message.emit("¡%s se debilitó!" % battler.get_display_name())
			await _wait(0.8)
			return

	if side.toxic_spikes_layers > 0 and is_grounded:
		var is_poison: bool = battler.pokemon.get_type_1() == PokemonData.Type.TYPE_POISON \
			or battler.pokemon.get_type_2() == PokemonData.Type.TYPE_POISON
		var is_steel: bool = battler.pokemon.get_type_1() == PokemonData.Type.TYPE_STEEL \
			or battler.pokemon.get_type_2() == PokemonData.Type.TYPE_STEEL
		if is_poison:
			side.toxic_spikes_layers = 0
			message.emit("¡%s absorbió las Púas Tóxicas!" % battler.get_display_name())
			await _wait(0.6)
		elif not is_steel:
			var status: PokemonInstance.Status = PokemonInstance.Status.TOXIC if side.toxic_spikes_layers >= 2 else PokemonInstance.Status.POISON
			await _apply_status(battler, status)

func _wait(seconds: float) -> void:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree:
		await tree.create_timer(seconds).timeout
	else:
		await Engine.get_main_loop().process_frame

func ability_announce(battler: BattleBattler) -> void:
	if battler == null or battler.pokemon == null:
		return
	var name: String = AbilityRuntime.ability_name(battler)
	ability_announced.emit(battler.is_player_side, battler.pokemon)
	if ability_announced.get_connections().size() > 0:
		await ability_bar_finished
	if name.is_empty():
		return
	message.emit("¡Se activó %s de %s!" % [name, battler.get_display_name()])
	await _wait(0.4)

func ability_change_stat(battler: BattleBattler, stat: PokemonInstance.Stat, stages: int, caused_by_foe: bool = false) -> void:
	if caused_by_foe and stages < 0 and AbilityRuntime.blocks_foe_stat_drop(battler, stat):
		await ability_announce(battler)
		message.emit("¡Las estadísticas de %s no bajaron!" % battler.get_display_name())
		await _wait(0.6)
		return
	# Mirror Armor: refleja bajadas del rival hacia el atacante (quien causó la bajada)
	if caused_by_foe and stages < 0 and AbilityRuntime.reflects_stat_drop(battler):
		await ability_announce(battler)
		var foe: BattleBattler = enemy if battler.is_player_side else player
		if foe != null and not foe.is_fainted():
			message.emit("¡%s reflejó el cambio de estadística!" % battler.get_display_name())
			await _wait(0.5)
			# aplicar al rival sin caused_by_foe para no re-reflejar en bucle
			await ability_change_stat(foe, stat, stages, false)
		return
	var adjusted: int = AbilityRuntime.adjust_own_stage_change(battler, stages)
	var actual: int = battler.modify_stage(stat, adjusted)
	if actual == 0:
		return
	var name: String = _stat_display_name(stat)
	if actual > 0:
		message.emit("¡%s de %s subió!" % [name, battler.get_display_name()])
	else:
		message.emit("¡%s de %s bajó!" % [name, battler.get_display_name()])
	await _wait(0.6)
	if caused_by_foe and actual < 0:
		await AbilityRuntime.after_own_stat_drop(battler, actual, true, self)
	# Opportunist: el rival copia subidas
	if actual > 0:
		var opp: BattleBattler = enemy if battler.is_player_side else player
		if opp != null and not opp.is_fainted():
			await AbilityRuntime.try_opportunist(opp, battler, stat, actual, self)

func ability_apply_status(battler: BattleBattler, status: PokemonInstance.Status, source: BattleBattler) -> void:
	if battler == null or battler.pokemon == null or battler.is_fainted():
		return
	if AbilityRuntime.blocks_status(battler, status, weather):
		return
	if not battler.pokemon.apply_status(status):
		return
	# Early Bird: sueño más corto
	if status == PokemonInstance.Status.SLEEP:
		AbilityRuntime.apply_early_bird_sleep(battler)
	message.emit("¡%s de %s afectó a %s: quedó %s!" % [
		AbilityRuntime.ability_name(source),
		source.get_display_name(),
		battler.get_display_name(),
		StatusConditions.status_name(status)
	])
	# Poison Puppeteer
	if source != null and (status == PokemonInstance.Status.POISON or status == PokemonInstance.Status.TOXIC):
		await AbilityRuntime.try_poison_puppeteer(source, battler, self)
	if AbilityRuntime.has(battler, AbilityId.Id.SYNCHRONIZE) and source != null and source != battler:
		await ability_announce(battler)
		if not AbilityRuntime.blocks_status(source, status, weather):
			source.pokemon.apply_status(status)
			message.emit("¡%s sincronizó el estado!" % battler.get_display_name())
			await _wait(0.5)

func ability_deal_damage(battler: BattleBattler, amount: int, cause: BattleBattler) -> void:
	var dealt: int = battler.apply_damage(amount)
	if dealt <= 0:
		return
	_emit_hp(battler.is_player_side)
	message.emit("%s recibió daño por %s." % [battler.get_display_name(), AbilityRuntime.ability_name(cause)])
	if battler.is_fainted():
		message.emit("¡%s se debilitó!" % battler.get_display_name())


func ability_heal(battler: BattleBattler, amount: int) -> void:
	if battler == null or battler.pokemon == null or battler.is_fainted():
		return
	battler.pokemon.apply_heal(amount)
	_emit_hp(battler.is_player_side)
	message.emit("¡%s se recuperó un poco gracias a su habilidad!" % battler.get_display_name())


func ability_cure_status(battler: BattleBattler) -> void:
	if battler == null or battler.pokemon == null or not battler.pokemon.has_status():
		return
	battler.pokemon.cure_status()
	message.emit("¡%s se curó gracias a su habilidad!" % battler.get_display_name())

func set_weather(new_weather: int, turns: int, primal: bool = false) -> void:
	if weather_primal and not primal:
		return
	if weather == new_weather and weather_primal == primal:
		return

	weather = new_weather
	weather_turns = turns
	weather_primal = primal

	match new_weather:
		AbilityBattleEffect.weatherAbilityID.WEATHER_RAIN:
			message.emit("¡Empezó a llover!" if not primal else "¡Una lluvia torrencial azotó la zona!")
		AbilityBattleEffect.weatherAbilityID.WEATHER_DROUGHT:
			message.emit("¡El sol brilla con fuerza!" if not primal else "¡El sol se volvió extremadamente intenso!")
		AbilityBattleEffect.weatherAbilityID.WEATHER_SANDSTORM:
			message.emit("¡Se levantó una tormenta de arena!")
		AbilityBattleEffect.weatherAbilityID.WEATHER_SNOW:
			message.emit("¡Empezó a nevar!")
		AbilityBattleEffect.weatherAbilityID.WEATHER_NONE:
			message.emit("¡El clima volvió a la normalidad!")
		_:
			pass

	weather_changed.emit(weather, weather_primal)


func set_terrain(new_terrain: int, turns: int = 5) -> void:
	if terrain == new_terrain:
		return
	terrain = new_terrain
	terrain_turns = turns

	match new_terrain:
		TerrainId.TERRAIN_ELECTRIC:
			message.emit("¡El campo se electrificó!")
		TerrainId.TERRAIN_GRASSY:
			message.emit("¡El campo se cubrió de hierba!")
		TerrainId.TERRAIN_MISTY:
			message.emit("¡El campo se cubrió de una niebla misteriosa!")
		TerrainId.TERRAIN_PSYCHIC:
			message.emit("¡El campo se volvió extraño!")
		TerrainId.TERRAIN_NONE:
			message.emit("¡El terreno volvió a la normalidad!")
		_:
			pass

	terrain_changed.emit(terrain)


func is_weather_suppressed() -> bool:
	if player != null and (
		AbilityRuntime.has(player, AbilityId.Id.AIR_LOCK)
		or AbilityRuntime.has(player, AbilityId.Id.CLOUD_NINE)
	):
		return true
	if enemy != null and (
		AbilityRuntime.has(enemy, AbilityId.Id.AIR_LOCK)
		or AbilityRuntime.has(enemy, AbilityId.Id.CLOUD_NINE)
	):
		return true
	return false


func get_effective_weather() -> int:
	if is_weather_suppressed():
		return AbilityBattleEffect.weatherAbilityID.WEATHER_NONE
	return weather

func _announce_passive_abilities(
	actor: BattleBattler,
	target: BattleBattler,
	result: DamageCalculator.HitResult
) -> void:
	if result == null:
		return
	# Una vez por habilidad y por movimiento (no por cada multi-hit).
	for ab_id: AbilityId.Id in result.activated_attacker:
		if AbilityRuntime.get_id(actor) == ab_id:
			await ability_announce(actor)
	for ab_id: AbilityId.Id in result.activated_defender:
		if AbilityRuntime.get_id(target) == ab_id:
			await ability_announce(target)

func _cleanup_battle_pokemon() -> void:
	if player != null:
		AbilityRuntime.revert_transform(player)
		player.clear_illusion()
	if enemy != null:
		AbilityRuntime.revert_transform(enemy)
		enemy.clear_illusion()
