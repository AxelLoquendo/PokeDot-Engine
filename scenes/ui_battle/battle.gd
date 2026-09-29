extends Node2D
## UI de combate. Compatible con battle.tscn (1v1) y battle_double.tscn (multi)
## vía BattleUILayout (estructura commit 9e8ce44).
##
## Esta versión virtual:
## - Enlaza nodos con la jerarquía nueva (BattleMonSprites / BattleHPBox / BattleBox)
## - Usa BattleMain como orquestador (sustituible por BattleManager durante migración)
## - Mantiene el flujo de menús ACTIONS → MOVES → TARGET → BUSY

enum MenuState { ACTIONS, MOVES, TARGET, BUSY }

var layout: BattleUILayout
var battle: BattleMain

var player_pokemon: PokemonInstance
var enemy_pokemon: PokemonInstance

var current_menu: MenuState = MenuState.ACTIONS
var selected_action: int = 0
var selected_move: int = 0
var _input_actor_slot: int = 0
var _input_target_slot: int = 0
var _pending_move_index: int = -1

var _ended_by_capture: bool = false
var _ended_by_run: bool = false
var _battle_closing: bool = false
var _force_switch_pending: bool = false

const PLAYER_HP_BAR_MAX_WIDTH: float = 48.0
const ENEMY_HP_BAR_MAX_WIDTH: float = 48.0


func _ready() -> void:
	layout = BattleUILayout.bind(self)
	# En singles, ocultar slots secundarios si existieran
	if not layout.is_double_scene:
		layout.hide_secondary_slots()

	_connect_action_buttons()
	_connect_move_buttons()

	if layout.fight_menu:
		layout.fight_menu.visible = false
	if layout.action_menu:
		layout.action_menu.visible = false

	await _boot_battle()


func _boot_battle() -> void:
	if BattleSession.tiene_datos():
		player_pokemon = BattleSession.player_pokemon
		enemy_pokemon = BattleSession.enemy_pokemon
	else:
		push_warning("Battle UI: BattleSession sin datos")
		return

	MusicManager.reproducir_batalla(BattleSession.battle_music)

	var party: Array[PokemonInstance] = []
	if BattleSession.player_controller != null:
		var pdata: CharacterPlayer = (
			BattleSession.player_controller.character_data as CharacterPlayer
		)
		if pdata != null:
			party = pdata.party

	if layout.bg != null and BattleSession.battle_background >= 0:
		# La textura de fondo la puede setear un helper de backgrounds
		pass

	battle = BattleMain.new()
	battle.message.connect(_on_battle_message)
	battle.hp_changed.connect(_on_hp_changed)
	battle.player_progress_changed.connect(_on_player_progress_changed)
	battle.battle_ended.connect(_on_battle_ended)
	battle.turn_ended.connect(_on_turn_ended)
	battle.player_must_switch.connect(_on_player_must_switch)
	battle.ability_announced.connect(_on_ability_announced)
	battle.battler_appearance_changed.connect(_on_battler_appearance_changed)
	battle.pokemon_entered_field.connect(_on_pokemon_entered_field)
	battle.terrain_changed.connect(_on_terrain_changed)
	battle.weather_changed.connect(_on_weather_changed)

	battle.trainer_name = BattleSession.trainer_name
	battle.start_battle(
		player_pokemon,
		enemy_pokemon,
		party,
		BattleSession.enemy_party,
		BattleSession.battle_format as BattleState.BattleFormat,
		BattleSession.is_wild
	)

	_apply_slot_visibility()
	_refresh_all_appearances()
	current_menu = MenuState.BUSY
	await battle.start_battle_intro()
	_begin_player_command_phase()


func _apply_slot_visibility() -> void:
	if battle == null:
		return
	var show_p2: bool = battle.is_multi_battle() and battle._player_slot_count() >= 2
	var show_e2: bool = battle.is_multi_battle() and battle._enemy_slot_count() >= 2
	layout.set_slot_visible(true, 1, show_p2)
	layout.set_slot_visible(false, 1, show_e2)


func _connect_action_buttons() -> void:
	for i: int in range(layout.action_buttons.size()):
		var btn: TextureButton = layout.action_buttons[i]
		var idx: int = i
		if not btn.pressed.is_connected(_on_action_button.bind(idx)):
			btn.pressed.connect(_on_action_button.bind(idx))


func _connect_move_buttons() -> void:
	for i: int in range(layout.move_buttons.size()):
		var btn: TextureButton = layout.move_buttons[i]
		var idx: int = i
		if not btn.pressed.is_connected(_on_move_button.bind(idx)):
			btn.pressed.connect(_on_move_button.bind(idx))


func _on_action_button(index: int) -> void:
	match index:
		0:
			_open_moves()
		1:
			_open_bag()
		2:
			_open_party(false)
		3:
			current_menu = MenuState.BUSY
			if layout.action_menu:
				layout.action_menu.visible = false
			await battle.player_choose_run()
			if battle != null and battle.is_running:
				_begin_player_command_phase()


func _open_moves() -> void:
	_fill_move_buttons()
	if layout.action_menu:
		layout.action_menu.visible = false
	if layout.fight_menu:
		layout.fight_menu.visible = true
	current_menu = MenuState.MOVES
	selected_move = 0


func _on_move_button(index: int) -> void:
	var mon: PokemonInstance = _mon_for_player_slot(_input_actor_slot)
	if mon == null or index < 0 or index >= mon.moves.size():
		return
	var slot: PokemonMoveSlot = mon.moves[index]
	if slot == null or slot.is_empty() or slot.current_pp <= 0:
		_show_message("¡No quedan PP para este movimiento!")
		return

	if layout.fight_menu:
		layout.fight_menu.visible = false
	current_menu = MenuState.BUSY
	await battle.player_choose_move(index, _input_actor_slot, _input_target_slot)


func _fill_move_buttons() -> void:
	var mon: PokemonInstance = _mon_for_player_slot(_input_actor_slot)
	if mon == null:
		return
	for i: int in range(layout.move_buttons.size()):
		var button: TextureButton = layout.move_buttons[i]
		var name_label: Label = button.get_node_or_null("Move_Name") as Label
		if i < mon.moves.size() and mon.moves[i] != null and not mon.moves[i].is_empty():
			var move_data: MoveData = MoveDatabase.get_move(mon.moves[i].move_id)
			if name_label and move_data:
				name_label.text = move_data.move_name
			button.disabled = mon.moves[i].current_pp <= 0
		else:
			if name_label:
				name_label.text = "---"
			button.disabled = true


func _begin_player_command_phase() -> void:
	_input_actor_slot = _next_conscious_player_slot(0)
	if _input_actor_slot < 0:
		_input_actor_slot = 0
	_sync_player_pokemon_ref()
	if layout.action_menu:
		layout.action_menu.visible = true
	current_menu = MenuState.ACTIONS
	var name: String = player_pokemon.get_display_name() if player_pokemon else "—"
	_show_message_box("¿Qué debe hacer %s?" % name)


func _next_conscious_player_slot(from_slot: int) -> int:
	if battle == null:
		return 0
	for i: int in range(from_slot, battle.player_actives.size()):
		var b: BattleBattler = battle.player_actives[i]
		if b != null and b.pokemon != null and not b.is_fainted():
			return i
	return -1


func _mon_for_player_slot(slot: int) -> PokemonInstance:
	if battle != null and slot < battle.player_actives.size():
		var b: BattleBattler = battle.player_actives[slot]
		if b != null:
			return b.pokemon
	return player_pokemon if slot == 0 else null


func _sync_player_pokemon_ref() -> void:
	var mon: PokemonInstance = _mon_for_player_slot(_input_actor_slot)
	if mon != null:
		player_pokemon = mon


func _refresh_all_appearances() -> void:
	if battle == null:
		return
	for i: int in range(battle.player_actives.size()):
		_refresh_slot(true, i)
	for j: int in range(battle.enemy_actives.size()):
		_refresh_slot(false, j)


func _refresh_slot(is_player: bool, slot: int) -> void:
	if battle == null:
		return
	var actives: Array[BattleBattler] = (
		battle.player_actives if is_player else battle.enemy_actives
	)
	if slot < 0 or slot >= actives.size():
		return
	var battler: BattleBattler = actives[slot]
	await BattleInterface.refresh_slot(layout, battler, false)



func _fill_hp_box(view: BattleUILayout.SlotView, battler: BattleBattler, is_player: bool) -> void:
	var mon: PokemonInstance = battler.pokemon
	if mon == null:
		return
	if view.name_label:
		view.name_label.text = battler.get_display_name()
	if view.level_label:
		view.level_label.text = str(mon.level)
	if view.hp_label:
		view.hp_label.text = "%d/%d" % [mon.current_hp, mon.max_hp]
	if view.hp_bar:
		var max_w: float = PLAYER_HP_BAR_MAX_WIDTH if is_player else ENEMY_HP_BAR_MAX_WIDTH
		var ratio: float = float(mon.current_hp) / float(maxi(mon.max_hp, 1))
		view.hp_bar.size.x = max_w * clampf(ratio, 0.0, 1.0)


# ─── señales del orquestador ────────────────────────────────────────

func _on_battle_message(text: String) -> void:
	_show_message(text)


func _on_hp_changed(is_player_side: bool, current: int, maximum: int, slot: int = 0) -> void:
	if battle == null:
		return
	var actives: Array[BattleBattler] = (
		battle.player_actives if is_player_side else battle.enemy_actives
	)
	if slot >= 0 and slot < actives.size():
		await BattleInterface.refresh_slot(layout, actives[slot], true)
	else:
		_refresh_slot(is_player_side, 0)



func _on_player_progress_changed() -> void:
	_refresh_all_appearances()


func _on_battle_ended(player_won: bool) -> void:
	if battle != null:
		BattleDone.cleanup(battle)
	current_menu = MenuState.BUSY
	_battle_closing = true
	var result: int = (
		BattleSession.BattleResult.WIN if player_won else BattleSession.BattleResult.LOSE
	)
	if _ended_by_run:
		result = BattleSession.BattleResult.RUN
	if _ended_by_capture:
		result = BattleSession.BattleResult.CAUGHT
	BattleSession.finalizar(result)


func _on_turn_ended() -> void:
	_refresh_all_appearances()
	if battle != null and battle.is_running:
		_begin_player_command_phase()


func _on_player_must_switch() -> void:
	_force_switch_pending = true
	_show_message("Debes elegir un Pokémon de reemplazo.")
	_open_party(true)


func _on_ability_announced(_is_player: bool, _pokemon: PokemonInstance) -> void:
	pass


func _on_battler_appearance_changed(is_player: bool) -> void:
	var actives: Array[BattleBattler] = (
		battle.player_actives if is_player else battle.enemy_actives
	)
	for i: int in range(actives.size()):
		_refresh_slot(is_player, i)


func _on_pokemon_entered_field(is_player: bool) -> void:
	_on_battler_appearance_changed(is_player)


func _on_terrain_changed(_terrain: int) -> void:
	pass


func _on_weather_changed(_weather: int, _primal: bool) -> void:
	pass


func _show_message(text: String) -> void:
	if layout.battle_normal_text:
		layout.battle_normal_text.visible = true
		layout.battle_normal_text.text = text
	if layout.battle_text:
		layout.battle_text.visible = false


func _show_message_box(text: String) -> void:
	if layout.battle_text:
		layout.battle_text.visible = true
		layout.battle_text.text = text
	if layout.battle_normal_text:
		layout.battle_normal_text.visible = false


func _open_bag() -> void:
	# La escena de mochila real se abre por UIManager; aquí cableado mínimo
	_show_message("Elige un objeto (usa battle.player_choose_item desde la mochila).")
	# Ejemplo de API para la mochila externa:
	# await battle.player_choose_item(Items.ItemId.ITEM_POKE_BALL)


func _open_party(forced: bool) -> void:
	_force_switch_pending = forced
	current_menu = MenuState.BUSY
	if layout.action_menu:
		layout.action_menu.visible = false
	_show_message("Elige un Pokémon del equipo." if forced else "¿Cambiar de Pokémon?")
	# Party screen real: al seleccionar mon llama:
	# await battle.player_choose_switch(selected_mon, forced, slot)


## Llamado por la pantalla de equipo al confirmar el mon.
func on_party_mon_selected(mon: PokemonInstance, slot: int = -1) -> void:
	if battle == null or mon == null:
		return
	var forced: bool = _force_switch_pending or battle.state.awaiting_player_switch
	_force_switch_pending = false
	await battle.player_choose_switch(mon, forced, slot)
	if battle != null and battle.is_running and not battle.state.awaiting_player_switch:
		_refresh_all_appearances()
		_begin_player_command_phase()
