extends RefCounted
class_name BattleManager

signal message(text: String)
signal hp_changed(is_player: bool, current_hp: int, max_hp: int)
signal player_progress_changed
signal battle_ended(player_won: bool)
signal turn_ended
## El mon activo se debilitó y hay reemplazo en el party.
signal player_must_switch

var player: BattleBattler
var enemy: BattleBattler
var is_running: bool = false
var player_party: Array[PokemonInstance] = []
var enemy_party: Array[PokemonInstance] = []
var is_trainer_battle: bool = false

## ─── Clima (ver ability_runtime.gd para las habilidades que lo activan) ──
var weather: int = AbilityBattleEffect.weatherAbilityID.WEATHER_NONE
## -1 = indefinido (activado por habilidad, hasta que otro clima lo reemplace).
## En el futuro, los movimientos de clima pueden usar un valor positivo (p.ej. 5).
var weather_turns: int = -1

func start_battle(player_pokemon: PokemonInstance, enemy_pokemon: PokemonInstance, party: Array[PokemonInstance] = [], enemy_trainer_party: Array[PokemonInstance] = []) -> void:
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
	_emit_hp(true)
	_emit_hp(false)

	AbilityRuntime.on_switch_in(player, enemy, self)
	AbilityRuntime.on_switch_in(enemy, player, self)


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
	AbilityRuntime.on_switch_in(player, enemy, self)

	if free_switch:
		turn_ended.emit()
		return

	# Cambio voluntario: el rival actúa
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
	message.emit("¡Escapaste con éxito!")
	is_running = false
	battle_ended.emit(true)

func _handle_enemy_faint() -> void:
	message.emit("¡%s se debilitó!" % enemy.get_display_name())
	await _wait(1.0)

	await _award_experience()

	if is_trainer_battle and _enemy_tiene_reemplazo():
		var nuevo: PokemonInstance = _enemy_siguiente_reemplazo()
		message.emit("¡El rival envía a %s!" % (nuevo.get_display_name() if nuevo else "???"))
		await _wait(0.8)
		enemy.setup(nuevo, false)
		_emit_hp(false)
		AbilityRuntime.on_switch_in(enemy, player, self)
		turn_ended.emit()
		return

	message.emit("¡Ganaste!")
	is_running = false
	battle_ended.emit(true)


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
	player_progress_changed.emit()

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
			AbilityRuntime.end_of_turn(battler, weather, self)


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
		if AbilityRuntime.is_immune_to_weather_damage(battler, weather):
			continue
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

	message.emit("%s usó %s!" % [actor.get_display_name(), move.move_name])
	await _wait(0.9)

	# Movimientos de estado: sin cambios respecto a antes.
	if move.category == MoveStruct.DamageCategory.STATUS or move.power <= 0:
		if not DamageCalculator.check_hit(move, actor, target):
			message.emit("¡El ataque de %s falló!" % actor.get_display_name())
			await _wait(0.8)
			return
		await _apply_status_move_effect(actor, target, move)
		return

	# --- Movimientos que dañan: comprobamos accuracy UNA vez ---
	if not DamageCalculator.check_hit(move, actor, target):
		message.emit("¡El ataque de %s falló!" % actor.get_display_name())
		await _wait(0.8)
		return

	var hit_count: int = DamageCalculator.roll_hit_count(move)
	var total_dealt: int = 0
	var last_result: DamageCalculator.HitResult = null
	var hits_landed: int = 0

	for i: int in hit_count:
		if target.is_fainted() or actor.is_fainted():
			break

		var result: DamageCalculator.HitResult = DamageCalculator.compute_hit(actor, target, move, weather)
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

		var dealt: int = target.apply_damage(result.damage)
		total_dealt += dealt
		hits_landed += 1
		_emit_hp(target.is_player_side)

		if result.critical:
			message.emit("¡Un golpe crítico!")
			await _wait(0.5)

		if result.sturdy_activated:
			message.emit("¡%s aguantó el golpe gracias a Sturdy!" % target.get_display_name())
			await _wait(0.5)

		# Retroceso: se aplica por cada golpe individual (moves multi-hit con
		# retroceso son rarísimos, pero así queda correcto si aparece alguno).
		if move.recoil_percent > 0 and not actor.is_fainted():
			await _apply_recoil(actor, dealt, move.recoil_percent)
			if actor.is_fainted():
				break

		# Drenaje (Absorb, Giga Drain, Drain Punch...)
		if move.drain_percent > 0:
			await _apply_drain(actor, dealt, move.drain_percent)

		# Habilidades de contacto del defensor (Static, Rough Skin...)
		AbilityRuntime.on_contact_hit(actor, target, move, self)
		if actor.is_fainted():
			break

	if last_result == null or last_result.ability_immunity != "" or last_result.effectiveness <= 0.0:
		return

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

	if target.is_fainted():
		if actor.is_fainted():
			return
		return

	if actor.is_fainted():
		return

	if move.secondary_effect != MoveStruct.SecondaryEffect.MOVE_EFFECT_NONE:
		var chance: int = move.secondary_chance
		if AbilityRuntime.has(actor, AbilityId.Id.SERENE_GRACE):
			chance = mini(100, chance * 2)
		if randi_range(1, 100) <= chance:
			await _apply_secondary_effect(actor, target, move)


## Mensaje + efecto cuando una habilidad del objetivo neutraliza el golpe
## (inmunidad de tipo, absorción de PS, o subida de estadística).
func _handle_ability_immunity(target: BattleBattler, move: MoveData, result: DamageCalculator.HitResult) -> void:
	var ability_display: String = AbilityRuntime.ability_name(target)
	match result.ability_immunity:
		"immune":
			message.emit("¡No afecta a %s por %s!" % [target.get_display_name(), ability_display])
			await _wait(0.8)
		"heal":
			message.emit("¡%s absorbió el ataque gracias a %s!" % [target.get_display_name(), ability_display])
			await _wait(0.6)
			ability_heal(target, maxi(1, target.get_max_hp() / 4))
		"spatk_up":
			message.emit("¡%s de %s se activó!" % [ability_display, target.get_display_name()])
			await _wait(0.6)
			ability_change_stat(target, PokemonInstance.Stat.SP_ATTACK, 1)
		"atk_up":
			message.emit("¡%s de %s se activó!" % [ability_display, target.get_display_name()])
			await _wait(0.6)
			ability_change_stat(target, PokemonInstance.Stat.ATTACK, 1)
		"spe_up":
			message.emit("¡%s de %s se activó!" % [ability_display, target.get_display_name()])
			await _wait(0.6)
			ability_change_stat(target, PokemonInstance.Stat.SPEED, 1)
		"flash_fire":
			target.flash_fire_boosted = true
			message.emit("¡%s de %s se activó! Sus movimientos de Fuego se potencian." % [ability_display, target.get_display_name()])
			await _wait(0.8)


## Retroceso: el atacante pierde un % del daño que ACABA de infligir.
func _apply_recoil(actor: BattleBattler, damage_dealt: int, percent: int) -> void:
	if damage_dealt <= 0:
		return
	var recoil: int = maxi(1, int(floor(float(damage_dealt) * float(percent) / 100.0)))
	var taken: int = actor.apply_damage(recoil)
	_emit_hp(actor.is_player_side)
	message.emit("%s recibió daño por el retroceso." % actor.get_display_name())
	await _wait(0.6)
	if taken > 0 and actor.is_fainted():
		message.emit("¡%s se debilitó!" % actor.get_display_name())
		await _wait(0.8)


## Drenaje: el atacante recupera un % del daño infligido (Absorb, Giga Drain...).
func _apply_drain(actor: BattleBattler, damage_dealt: int, percent: int) -> void:
	if damage_dealt <= 0 or actor.pokemon == null:
		return
	var heal: int = maxi(1, int(floor(float(damage_dealt) * float(percent) / 100.0)))
	actor.pokemon.apply_heal(heal)
	_emit_hp(actor.is_player_side)
	message.emit("¡%s absorbió energía!" % actor.get_display_name())
	await _wait(0.6)


func _apply_secondary_effect(actor: BattleBattler, target: BattleBattler, move: MoveData) -> void:
	var stat_effect: Array = MoveEffectResolver.get_secondary_stat_effect(move.secondary_effect)
	if not stat_effect.is_empty():
		var receiver: BattleBattler = actor if stat_effect[1] > 0 else target
		await _apply_stat_change(receiver, stat_effect[0], stat_effect[1])
		return

	if MoveEffectResolver.is_flinch_effect(move.secondary_effect):
		if not AbilityRuntime.blocks_flinch(target):
			target.flinched = true
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
		await _apply_stat_change(receiver, stat_effect[0], stat_effect[1])
		return

	var acc_eva: Array = MoveEffectResolver.get_primary_accuracy_evasion_effect(move.effect)
	if not acc_eva.is_empty():
		var is_acc: bool = acc_eva[0] == "acc"
		var actual: int = receiver.modify_accuracy_stage(acc_eva[1]) if is_acc else receiver.modify_evasion_stage(acc_eva[1])
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

	message.emit("¡Pero no tuvo ningún efecto todavía!")
	await _wait(0.8)


func _apply_stat_change(battler: BattleBattler, stat: PokemonInstance.Stat, stages: int) -> void:
	var actual: int = battler.modify_stage(stat, stages)
	var name: String = _stat_display_name(stat)
	if actual == 0:
		message.emit("¡El %s de %s ya no puede cambiar más!" % [name, battler.get_display_name()])
	elif actual > 0:
		message.emit("¡%s de %s subió!" % [name, battler.get_display_name()])
	else:
		message.emit("¡%s de %s bajó!" % [name, battler.get_display_name()])
	await _wait(0.6)


func _apply_status(battler: BattleBattler, status: PokemonInstance.Status) -> void:
	if AbilityRuntime.blocks_status(battler, status):
		message.emit("¡La habilidad de %s lo protegió!" % battler.get_display_name())
		await _wait(0.6)
		return
	if battler.pokemon.apply_status(status):
		message.emit("¡%s quedó %s!" % [battler.get_display_name(), StatusConditions.status_name(status)])
	else:
		message.emit("¡No tuvo efecto!")
	await _wait(0.6)


func _apply_confusion(battler: BattleBattler) -> void:
	if AbilityRuntime.blocks_confusion(battler):
		message.emit("¡La habilidad de %s evita que se confunda!" % battler.get_display_name())
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

func _wait(seconds: float) -> void:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree:
		await tree.create_timer(seconds).timeout
	else:
		await Engine.get_main_loop().process_frame


## ════════════════════════════════════════════════════════
## API pública usada por AbilityRuntime (data_core/battle/ability_runtime.gd).
## Son versiones SIN pausas (síncronas) para no forzar a todo el sistema de
## habilidades a ser una cadena de corutinas. Si más adelante quieres que
## se vean con el mismo ritmo que el resto de mensajes, estas son el sitio
## para añadir `await _wait(...)`.
## ════════════════════════════════════════════════════════

func ability_announce(battler: BattleBattler) -> void:
	var name: String = AbilityRuntime.ability_name(battler)
	if name.is_empty():
		return
	message.emit("¡Se activó %s de %s!" % [name, battler.get_display_name()])


func ability_change_stat(battler: BattleBattler, stat: PokemonInstance.Stat, stages: int) -> void:
	var actual: int = battler.modify_stage(stat, stages)
	if actual == 0:
		return
	var name: String = _stat_display_name(stat)
	if actual > 0:
		message.emit("¡%s de %s subió!" % [name, battler.get_display_name()])
	else:
		message.emit("¡%s de %s bajó!" % [name, battler.get_display_name()])


func ability_apply_status(battler: BattleBattler, status: PokemonInstance.Status, source: BattleBattler) -> void:
	if battler == null or battler.pokemon == null or battler.is_fainted():
		return
	if AbilityRuntime.blocks_status(battler, status):
		return
	if not battler.pokemon.apply_status(status):
		return
	message.emit("¡%s de %s afectó a %s: quedó %s!" % [
		AbilityRuntime.ability_name(source),
		source.get_display_name(),
		battler.get_display_name(),
		StatusConditions.status_name(status)
	])


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


func set_weather(new_weather: int, turns: int) -> void:
	if weather == new_weather:
		return
	weather = new_weather
	weather_turns = turns
	match new_weather:
		AbilityBattleEffect.weatherAbilityID.WEATHER_RAIN:
			message.emit("¡Empezó a llover!")
		AbilityBattleEffect.weatherAbilityID.WEATHER_DROUGHT:
			message.emit("¡El sol brilla con fuerza!")
		AbilityBattleEffect.weatherAbilityID.WEATHER_SANDSTORM:
			message.emit("¡Se levantó una tormenta de arena!")
		AbilityBattleEffect.weatherAbilityID.WEATHER_SNOW:
			message.emit("¡Empezó a granizar!")
		_:
			pass
