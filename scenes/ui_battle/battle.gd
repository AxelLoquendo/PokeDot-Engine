
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

	# Fondo de combate según el mapa / sesión
	BattleInterface.apply_background(layout, int(BattleSession.battle_background))

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



func _unhandled_input(event: InputEvent) -> void:
	if event.is_echo():
		return
	if current_menu == MenuState.BUSY or battle == null or not battle.is_running:
		return
	if _battle_closing:
		return

	# Mapa de entrada del proyecto: Up/Down/Left/Right, buttonA, buttonB
	if event.is_action_pressed("Up", true):
		_nav(-1, 0)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("Down", true):
		_nav(1, 0)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("Left", true):
		_nav(0, -1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("Right", true):
		_nav(0, 1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("buttonA", true):
		_confirm_menu()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("buttonB", true):
		_cancel_menu()
		get_viewport().set_input_as_handled()


## Grid 2x2: 0=TL, 1=TR, 2=BL, 3=BR
func _nav(drow: int, dcol: int) -> void:
	if current_menu == MenuState.ACTIONS:
		var row: int = selected_action / 2
		var col: int = selected_action % 2
		row = clampi(row + drow, 0, 1)
		col = clampi(col + dcol, 0, 1)
		selected_action = row * 2 + col
		_refresh_action_focus()
	elif current_menu == MenuState.MOVES:
		var row2: int = selected_move / 2
		var col2: int = selected_move % 2
		row2 = clampi(row2 + drow, 0, 1)
		col2 = clampi(col2 + dcol, 0, 1)
		selected_move = row2 * 2 + col2
		_refresh_move_focus()
		_update_move_info(selected_move)


func _confirm_menu() -> void:
	match current_menu:
		MenuState.ACTIONS:
			_on_action_button(selected_action)
		MenuState.MOVES:
			_on_move_button(selected_move)


func _cancel_menu() -> void:
	match current_menu:
		MenuState.MOVES:
			_hide_fight_menu()
			if layout.action_menu:
				layout.action_menu.visible = true
			current_menu = MenuState.ACTIONS
			selected_action = 0
			_refresh_action_focus()
			var name: String = player_pokemon.get_display_name() if player_pokemon else "—"
			_show_message_box("¿Qué debe hacer %s?" % name)
		MenuState.ACTIONS:
			pass  # en comandos B no cancela el combate


func _refresh_action_focus() -> void:
	if layout == null:
		return
	for i: int in range(layout.action_buttons.size()):
		var btn: TextureButton = layout.action_buttons[i]
		if i == selected_action:
			btn.grab_focus()
			btn.button_pressed = false
		# TextureButton usa texture_focused al tener focus


func _refresh_move_focus() -> void:
	if layout == null:
		return
	for i: int in range(layout.move_buttons.size()):
		var btn: TextureButton = layout.move_buttons[i]
		if i == selected_move:
			btn.grab_focus()

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
	_update_move_info(0)
	_refresh_move_focus()


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
			# Caja del slot según tipo del movimiento
			if move_data != null:
				_apply_move_slot_textures(button, move_data.type)
			else:
				_apply_move_slot_textures(button, PokemonData.Type.TYPE_NORMAL)
		else:
			if name_label:
				name_label.text = "---"
			button.disabled = true
			_apply_move_slot_textures(button, PokemonData.Type.TYPE_NORMAL)


func _apply_move_slot_textures(button: TextureButton, p_type: PokemonData.Type) -> void:
	if button == null:
		return
	var type_key: String = _type_key(p_type)
	var base_path: String = "res://graphics/battle_interface/cursor_fight/%s.png" % type_key
	var focus_path: String = "res://graphics/battle_interface/cursor_fight/%s_focus.png" % type_key
	# Fallback a normal si no existe el tipo
	if not ResourceLoader.exists(base_path):
		base_path = "res://graphics/battle_interface/cursor_fight/normal.png"
	if not ResourceLoader.exists(focus_path):
		focus_path = "res://graphics/battle_interface/cursor_fight/normal_focus.png"
	if ResourceLoader.exists(base_path):
		button.texture_normal = load(base_path) as Texture2D
	if ResourceLoader.exists(focus_path):
		button.texture_focused = load(focus_path) as Texture2D
		button.texture_hover = button.texture_focused


func _type_key(p_type: PokemonData.Type) -> String:
	# Nombres de archivo en graphics/battle_interface/cursor_fight/
	match int(p_type):
		1: return "normal"
		2: return "fighting"
		3: return "flying"
		4: return "poison"
		5: return "ground"
		6: return "rock"
		7: return "bug"
		8: return "ghost"
		9: return "steel"
		10: return "mystery"
		11: return "fire"
		12: return "water"
		13: return "grass"
		14: return "electric"
		15: return "psychic"
		16: return "ice"
		17: return "dragon"
		18: return "dark"
		19: return "fairy"
		_:
			return "normal"


func _on_move_hover(index: int) -> void:
	selected_move = index
	_update_move_info(index)
	_refresh_move_focus()


func _update_move_info(index: int) -> void:
	var mon: PokemonInstance = _mon_for_player_slot(_input_actor_slot)
	if mon == null or layout == null:
		return
	if index < 0 or index >= mon.moves.size() or mon.moves[index] == null:
		if layout.move_pp_label:
			layout.move_pp_label.text = "--/--"
		return
	var slot: PokemonMoveSlot = mon.moves[index]
	var move_data: MoveData = MoveDatabase.get_move(slot.move_id)
	if layout.move_pp_label != null:
		var max_pp: int = 0
		if "max_pp" in slot:
			max_pp = int(slot.max_pp)
		elif move_data != null:
			max_pp = int(move_data.pp)
		layout.move_pp_label.text = "%d/%d" % [slot.current_pp, max_pp]
	if layout.move_type_sprite != null and move_data != null:
		var tex: Texture2D = _type_icon(move_data.type)
		if tex != null:
			layout.move_type_sprite.texture = tex
			layout.move_type_sprite.visible = true


func _type_icon(p_type: PokemonData.Type) -> Texture2D:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree != null:
		var db: Node = tree.root.get_node_or_null("TypeIconsDb")
		if db != null and db.has_method("get_icon"):
			return db.get_icon(p_type) as Texture2D
	var icons: Resource = load("res://data_core/pokemon/type_icons.tres")
	if icons != null and icons.has_method("get_icon"):
		return icons.get_icon(p_type) as Texture2D
	var path: String = "res://graphics/types/%s.png" % _type_key(p_type)
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	return null



func _begin_player_command_phase() -> void:
	_input_actor_slot = _next_conscious_player_slot(0)
	if _input_actor_slot < 0:
		_input_actor_slot = 0
	_sync_player_pokemon_ref()
	_hide_fight_menu()
	if layout.action_menu:
		layout.action_menu.visible = true
	current_menu = MenuState.ACTIONS
	selected_action = 0
	_refresh_action_focus()
	var name: String = player_pokemon.get_display_name() if player_pokemon else "—"
	_show_message_box("¿Qué debe hacer %s?" % name)


func _hide_fight_menu() -> void:
	if layout != null and layout.fight_menu != null:
		layout.fight_menu.visible = false


func _hide_action_menu() -> void:
	if layout != null and layout.action_menu != null:
		layout.action_menu.visible = false


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
		await _refresh_slot(true, i)
	for j: int in range(battle.enemy_actives.size()):
		await _refresh_slot(false, j)


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


func _on_ability_announced(is_player: bool, pokemon: PokemonInstance) -> void:
	await _show_ability_bar(is_player, pokemon)


func _show_ability_bar(is_player: bool, pokemon: PokemonInstance) -> void:
	if layout == null or pokemon == null:
		if battle != null:
			battle.ability_bar_finished.emit()
		return

	var bar: Sprite2D = layout.ability_bar_player if is_player else layout.ability_bar_enemy
	var anim_name_in: String = "Entrada_Player" if is_player else "Entrada_Enemy"
	var anim_name_out: String = "Salida_Player" if is_player else "Salida_Enemy"

	if bar != null:
		var name_label: Label = bar.get_node_or_null("Ability_Name") as Label
		if name_label != null:
			name_label.text = _ability_display_name(pokemon)
		var icon: Sprite2D = bar.get_node_or_null("Icon_Mon") as Sprite2D
		if icon != null:
			var tex: Texture2D = null
			if pokemon.has_method("get_icon_sprite"):
				tex = pokemon.get_icon_sprite()
			if tex == null:
				tex = PokemonFormResolver.get_icon_sprite(pokemon)
			if tex != null:
				icon.texture = tex

	var anim: AnimationPlayer = layout.ability_anim
	if anim != null and anim.has_animation(anim_name_in):
		anim.play(anim_name_in)
		await anim.animation_finished
	else:
		if bar != null:
			bar.visible = true
		await get_tree().create_timer(0.9).timeout

	if anim != null and anim.has_animation(anim_name_out):
		anim.play(anim_name_out)
		await anim.animation_finished
	else:
		if bar != null:
			bar.visible = false

	if battle != null:
		battle.ability_bar_finished.emit()


func _ability_display_name(pokemon: PokemonInstance) -> String:
	if pokemon == null:
		return ""
	var aid: int = int(pokemon.ability_id) if "ability_id" in pokemon else 0
	var keys: Array = AbilityId.Id.keys()
	if aid >= 0 and aid < keys.size():
		var key: String = str(keys[aid])
		if key != "NONE" and key != "COUNT":
			return key.replace("_", " ").capitalize()
	return "Habilidad"


func _on_battler_appearance_changed(is_player: bool) -> void:
	var actives: Array[BattleBattler] = (
		battle.player_actives if is_player else battle.enemy_actives
	)
	for i: int in range(actives.size()):
		_refresh_slot(is_player, i)


func _on_pokemon_entered_field(is_player: bool) -> void:
	_on_battler_appearance_changed(is_player)
	if battle == null:
		return
	var actives: Array[BattleBattler] = (
		battle.player_actives if is_player else battle.enemy_actives
	)
	for b: BattleBattler in actives:
		if b != null and b.pokemon != null and not b.is_fainted():
			BattleInterface.play_cry(layout, b)


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
	_hide_action_menu()
	_hide_fight_menu()
	current_menu = MenuState.BUSY
	# La escena de mochila real se abre por UIManager; cableado mínimo:
	_show_message("Elige un objeto (la mochila debe llamar a battle.player_choose_item).")
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
