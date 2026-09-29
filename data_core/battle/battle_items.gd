extends RefCounted
class_name BattleItems
## Uso de objetos en combate (curativos, X-items, balls → BattleCapture).


static func use_item(
	battle: Object,
	item_id: Items.ItemId,
	target: PokemonInstance = null,
	move_slot_index: int = -1
) -> void:
	if battle.get("is_running") != null and not bool(battle.is_running):
		return

	var data: CharacterPlayer = _player_data()
	if data == null:
		return

	var item: ItemData = ItemDatabase.get_item(item_id) if ItemDatabase.has_method("get_item") else null
	if item == null:
		_msg(battle, "Objeto desconocido.")
		await _wait(battle, 0.5)
		return

	# Poké Balls
	if item.is_pokeball if "is_pokeball" in item else _is_ball(item_id):
		var captured: bool = await BattleCapture.attempt(battle, item, data)
		if not captured and bool(battle.is_running if battle.get("is_running") != null else true):
			await _enemy_turn_after_item(battle)
		return

	# Field / X-items / potions sobre el activo o target
	var battler: BattleBattler = _find_battler_for_mon(battle, target)
	if battler == null:
		battler = battle.player as BattleBattler if battle.get("player") != null else null

	if battler == null or battler.pokemon == null:
		_msg(battle, "No hay objetivo válido.")
		await _wait(battle, 0.5)
		return

	var used: bool = await _apply_item_effect(battle, item, battler, move_slot_index)
	if used and not item.not_consumed:
		data.bag.remove_item(item_id)

	if used:
		await _enemy_turn_after_item(battle)


static func _apply_item_effect(
	battle: Object,
	item: ItemData,
	battler: BattleBattler,
	move_slot_index: int
) -> bool:
	# HoldItemRuntime / Item effect scripts si existen
	# HoldItemRuntime no expone use_from_bag estático de forma fiable; fallback abajo

	# Fallback: curación simple por heal_amount en ItemData
	if "heal_amount" in item and int(item.heal_amount) > 0:
		if battler.pokemon.current_hp >= battler.get_max_hp():
			_msg(battle, "¡%s ya tiene todos los PS!" % battler.get_display_name())
			await _wait(battle, 0.5)
			return false
		battler.pokemon.apply_heal(int(item.heal_amount))
		if battle.has_method("_emit_hp_battler"):
			battle._emit_hp_battler(battler)
		_msg(battle, "¡%s recuperó PS!" % battler.get_display_name())
		await _wait(battle, 0.6)
		return true

	if "cure_status" in item and bool(item.cure_status):
		if battler.pokemon.has_status():
			battler.pokemon.status = PokemonInstance.Status.NONE
			_msg(battle, "¡%s se curó!" % battler.get_display_name())
			await _wait(battle, 0.55)
			return true

	_msg(battle, "¡No surtirá efecto!")
	await _wait(battle, 0.5)
	return false


static func _enemy_turn_after_item(battle: Object) -> void:
	# Solo la acción del rival (el item ya consumió el turno del jugador)
	if battle is BattleMain:
		var main: BattleMain = battle as BattleMain
		var enemy_actions: Array[BattleAction] = main._opponent_controller.choose_actions(
			main, main.state.enemy_actives
		)
		await BattleTurn.resolve_actions(main, enemy_actions)
	elif battle.has_method("_resolve_item_enemy_turn"):
		await battle._resolve_item_enemy_turn()


static func _is_ball(item_id: Items.ItemId) -> bool:
	match item_id:
		Items.ItemId.ITEM_POKE_BALL, Items.ItemId.ITEM_GREAT_BALL, \
		Items.ItemId.ITEM_ULTRA_BALL, Items.ItemId.ITEM_MASTER_BALL, \
		Items.ItemId.ITEM_SAFARI_BALL, Items.ItemId.ITEM_NET_BALL, \
		Items.ItemId.ITEM_NEST_BALL, Items.ItemId.ITEM_DIVE_BALL, \
		Items.ItemId.ITEM_DUSK_BALL, Items.ItemId.ITEM_TIMER_BALL, \
		Items.ItemId.ITEM_QUICK_BALL, Items.ItemId.ITEM_REPEAT_BALL, \
		Items.ItemId.ITEM_LUXURY_BALL, Items.ItemId.ITEM_PREMIER_BALL, \
		Items.ItemId.ITEM_HEAL_BALL, Items.ItemId.ITEM_FRIEND_BALL, \
		Items.ItemId.ITEM_CHERISH_BALL, Items.ItemId.ITEM_PARK_BALL, \
		Items.ItemId.ITEM_SPORT_BALL:
			return true
		_:
			return false


static func _player_data() -> CharacterPlayer:
	if BattleSession.player_controller == null:
		return null
	return BattleSession.player_controller.character_data as CharacterPlayer


static func _find_battler_for_mon(battle: Object, mon: PokemonInstance) -> BattleBattler:
	if mon == null:
		return null
	for b: BattleBattler in BattleUtil.get_all_actives(battle):
		if b != null and b.pokemon == mon:
			return b
	return null


static func _msg(battle: Object, text: String) -> void:
	if battle.has_signal("message"):
		battle.message.emit(text)


static func _wait(battle: Object, seconds: float) -> void:
	if battle.has_method("_wait"):
		await battle._wait(seconds)
	else:
		await Engine.get_main_loop().create_timer(seconds).timeout
