extends Node2D

@onready var player_sprite: Sprite2D = $Pkmn_Player
@onready var enemy_sprite: Sprite2D = $Pkmn_Enemy

@onready var player_name_label: Label = $PlayerHPBox/NamePkmnPlayer
@onready var player_level_label: Label = $PlayerHPBox/Level
@onready var player_hp_label: Label = $PlayerHPBox/HP
@onready var player_hp_bar: ColorRect = $PlayerHPBox/HpBar
@onready var player_gender: Label = $PlayerHPBox/Genero

@onready var enemy_name_label: Label = $EnemyHPBox/NamePkmnEnemy
@onready var enemy_level_label: Label = $EnemyHPBox/Level
@onready var enemy_hp_bar: ColorRect = $EnemyHPBox/HpBar
@onready var enemy_gender: Label = $EnemyHPBox/Genero

@onready var action_menu: Control = $ActionBattle
@onready var fight_menu: Sprite2D = $Overlay_Fight
@onready var move_pp_label: Label = $Overlay_Fight/PP/Number_PP
@onready var move_type_sprite: Sprite2D = $Overlay_Fight/Type
@onready var battle_text: Label = $TextBox/BattleText
@onready var battle_normal_text: Label = $TextBox/BattleNormalText

@onready var action_buttons: Array[TextureButton] = [
	$ActionBattle/GridContainer/Fight,
	$ActionBattle/GridContainer/Bag,
	$ActionBattle/GridContainer/Pkmn,
	$ActionBattle/GridContainer/Run
]

@onready var move_buttons: Array[TextureButton] = [
	$Overlay_Fight/Moves/GridContainer/Move,
	$Overlay_Fight/Moves/GridContainer/Move2,
	$Overlay_Fight/Moves/GridContainer/Move3,
	$Overlay_Fight/Moves/GridContainer/Move4
]
@onready var player_exp_bar: ColorRect = $PlayerHPBox/ExpBar

@onready var bg_sprite: Sprite2D = $BG

const PARTY_SCENE: PackedScene = preload("res://scenes/ui_party_menu/party_menu.tscn")

var player_pokemon: PokemonInstance
var enemy_pokemon: PokemonInstance
var player_sprite_base_pos: Vector2
var enemy_sprite_base_pos: Vector2

var battle: BattleManager

const PLAYER_HP_BAR_MAX_WIDTH: float = 48.0
const ENEMY_HP_BAR_MAX_WIDTH: float = 48.0
const HP_ANIM_SPEED: float = 40.0

const PLAYER_EXP_BAR_MAX_WIDTH: float = 63.5
var player_exp_bar_target: float = 0.0

enum MenuState { ACTIONS, MOVES, BUSY }
var current_menu: MenuState = MenuState.ACTIONS
var selected_action: int = 0
var selected_move: int = 0

var player_hp_bar_target: float = 48.0
var enemy_hp_bar_target: float = 48.0
var player_current_hp: int = 0
var enemy_current_hp: int = 0

var _action_normals: Array[Texture2D] = []
var _action_focused: Array[Texture2D] = []
var _move_normals: Array[Texture2D] = []
var _move_focused: Array[Texture2D] = []
var _current_move_normals: Array[Texture2D] = []
var _current_move_focused: Array[Texture2D] = []

var _ended_by_run: bool = false
var _battle_closing: bool = false
var _party_ui: PartyMenu = null
var _force_switch_pending: bool = false
var _battle_canvas_modulate: CanvasModulate = null

func _ready() -> void:
	player_sprite_base_pos = player_sprite.position
	enemy_sprite_base_pos = enemy_sprite.position

	_action_normals.clear()
	_action_focused.clear()
	for b: TextureButton in action_buttons:
		_action_normals.append(b.texture_normal)
		_action_focused.append(b.texture_focused)
		b.focus_mode = Control.FOCUS_NONE
		b.mouse_filter = Control.MOUSE_FILTER_IGNORE

	_move_normals.clear()
	_move_focused.clear()
	_current_move_normals.clear()
	_current_move_focused.clear()
	for b: TextureButton in move_buttons:
		_move_normals.append(b.texture_normal)
		_move_focused.append(b.texture_focused)
		_current_move_normals.append(b.texture_normal)
		_current_move_focused.append(b.texture_focused)
		b.focus_mode = Control.FOCUS_NONE
		b.mouse_filter = Control.MOUSE_FILTER_IGNORE

	_ended_by_run = false
	_battle_closing = false
	_force_switch_pending = false

	if BattleSession.tiene_datos():
		player_pokemon = BattleSession.player_pokemon
		enemy_pokemon = BattleSession.enemy_pokemon
	else:
		player_pokemon = PokemonInstance.create(Species.SpeciesID.SPECIES_HYDRAPPLE, 5)
		enemy_pokemon = PokemonInstance.create(Species.SpeciesID.SPECIES_BULBASAUR, 8)

	MusicManager.reproducir_batalla(BattleSession.battle_music)

	var party: Array[PokemonInstance] = []
	if BattleSession.player_controller != null:
		var pdata: CharacterPlayer = BattleSession.player_controller.character_data as CharacterPlayer
		if pdata != null:
			party = pdata.party

	battle = BattleManager.new()
	battle.message.connect(_on_battle_message)
	battle.hp_changed.connect(_on_hp_changed)
	battle.player_progress_changed.connect(_on_player_progress_changed)
	battle.battle_ended.connect(_on_battle_ended)
	battle.turn_ended.connect(_on_turn_ended)
	battle.player_must_switch.connect(_on_player_must_switch)
	battle.start_battle(player_pokemon, enemy_pokemon, party, BattleSession.enemy_party)

	player_exp_bar.size.x = player_exp_bar_target
	player_current_hp = player_pokemon.current_hp
	enemy_current_hp = enemy_pokemon.current_hp

	_battle_canvas_modulate = CanvasModulate.new()
	if DnsManager != null and DnsManager.canvas_modulate != null:
		_battle_canvas_modulate.color = DnsManager.canvas_modulate.color
	add_child(_battle_canvas_modulate)

	var textura_fondo: Texture2D = BattleBackground.get_texture(BattleSession.battle_background)
	if textura_fondo != null:
		bg_sprite.texture = textura_fondo

	_update_ui()
	player_hp_bar.size.x = player_hp_bar_target
	enemy_hp_bar.size.x = enemy_hp_bar_target

	fight_menu.visible = false
	action_menu.visible = true
	current_menu = MenuState.ACTIONS
	selected_action = 0
	_update_action_focus()
	_show_message_box("¿Qué debe hacer %s?" % player_pokemon.get_display_name())

func _on_player_progress_changed() -> void:
	player_level_label.text = str(player_pokemon.level)
	_update_exp_bar()

func _process(delta: float) -> void:
	if absf(player_hp_bar.size.x - player_hp_bar_target) > 0.5:
		player_hp_bar.size.x = move_toward(player_hp_bar.size.x, player_hp_bar_target, HP_ANIM_SPEED * delta)
	else:
		player_hp_bar.size.x = player_hp_bar_target
	player_hp_bar.color = _hp_color(player_hp_bar.size.x / PLAYER_HP_BAR_MAX_WIDTH)

	if absf(enemy_hp_bar.size.x - enemy_hp_bar_target) > 0.5:
		enemy_hp_bar.size.x = move_toward(enemy_hp_bar.size.x, enemy_hp_bar_target, HP_ANIM_SPEED * delta)
	else:
		enemy_hp_bar.size.x = enemy_hp_bar_target
	enemy_hp_bar.color = _hp_color(enemy_hp_bar.size.x / ENEMY_HP_BAR_MAX_WIDTH)

	if absf(player_exp_bar.size.x - player_exp_bar_target) > 0.5:
		player_exp_bar.size.x = move_toward(player_exp_bar.size.x, player_exp_bar_target, HP_ANIM_SPEED * delta)
	else:
		player_exp_bar.size.x = player_exp_bar_target

func _input(event: InputEvent) -> void:
	if current_menu == MenuState.BUSY:
		return
	if current_menu == MenuState.ACTIONS:
		_handle_action_input(event)
	elif current_menu == MenuState.MOVES:
		_handle_move_input(event)


func _handle_action_input(event: InputEvent) -> void:
	var cols: int = 2
	var moved: bool = false

	if event.is_action_pressed("Right"):
		selected_action = (selected_action + 1) % action_buttons.size()
		moved = true
	elif event.is_action_pressed("Left"):
		selected_action = (selected_action - 1 + action_buttons.size()) % action_buttons.size()
		moved = true
	elif event.is_action_pressed("Down"):
		selected_action = (selected_action + cols) % action_buttons.size()
		moved = true
	elif event.is_action_pressed("Up"):
		selected_action = (selected_action - cols + action_buttons.size()) % action_buttons.size()
		moved = true
	elif event.is_action_pressed("buttonA"):
		_activate_action(selected_action)
		return

	if moved:
		_update_action_focus()


func _update_action_focus() -> void:
	for i: int in action_buttons.size():
		var button: TextureButton = action_buttons[i]
		if i >= _action_normals.size() or i >= _action_focused.size():
			continue
		if i == selected_action and _action_focused[i] != null:
			button.texture_normal = _action_focused[i]
		else:
			button.texture_normal = _action_normals[i]


func _activate_action(index: int) -> void:
	match index:
		0:
			_on_fight_pressed()
		1:
			_on_bag_pressed()
		2:
			_on_pkmn_pressed()
		3:
			_on_run_pressed()


func _handle_move_input(event: InputEvent) -> void:
	var cols: int = 2
	var moved: bool = false

	if event.is_action_pressed("Right"):
		selected_move = (selected_move + 1) % move_buttons.size()
		moved = true
	elif event.is_action_pressed("Left"):
		selected_move = (selected_move - 1 + move_buttons.size()) % move_buttons.size()
		moved = true
	elif event.is_action_pressed("Down"):
		selected_move = (selected_move + cols) % move_buttons.size()
		moved = true
	elif event.is_action_pressed("Up"):
		selected_move = (selected_move - cols + move_buttons.size()) % move_buttons.size()
		moved = true
	elif event.is_action_pressed("buttonA"):
		_on_move_pressed(selected_move)
		return
	elif event.is_action_pressed("buttonB"):
		fight_menu.visible = false
		action_menu.visible = true
		current_menu = MenuState.ACTIONS
		_update_action_focus()
		_show_message_box("¿Qué debe hacer %s?" % player_pokemon.get_display_name())
		return

	if moved:
		_update_move_focus()


func _update_move_focus() -> void:
	for i: int in move_buttons.size():
		var button: TextureButton = move_buttons[i]
		if i >= _current_move_normals.size() or i >= _current_move_focused.size():
			continue
		var normal_texture: Texture2D = _current_move_normals[i]
		var focused_texture: Texture2D = _current_move_focused[i]
		button.texture_focused = focused_texture
		if i == selected_move:
			button.texture_normal = focused_texture
		else:
			button.texture_normal = normal_texture
	_update_selected_move_info()


func _get_move_button_texture(
	move_type: PokemonData.Type,
	focused: bool,
	fallback: Texture2D
) -> Texture2D:
	if move_type == PokemonData.Type.TYPE_NONE:
		return fallback

	var type_name: String = PokemonData.Type.keys()[int(move_type)]
	type_name = type_name.trim_prefix("TYPE_").to_lower()
	var file_name: String = type_name
	if focused:
		file_name += "_focus"

	var path: String = "res://graphics/battle_interface/cursor_fight/%s.png" % file_name
	if not ResourceLoader.exists(path):
		return fallback

	var texture: Texture2D = load(path) as Texture2D
	if texture == null:
		return fallback
	return texture


func _update_selected_move_info() -> void:
	move_pp_label.text = "--/--"
	move_type_sprite.texture = null
	move_type_sprite.visible = false

	if player_pokemon == null:
		return
	if selected_move < 0 or selected_move >= player_pokemon.moves.size():
		return

	var slot: PokemonMoveSlot = player_pokemon.moves[selected_move]
	if slot == null or slot.is_empty():
		return

	var move_data: MoveData = MoveDatabase.get_move(slot.move_id)
	if move_data == null:
		return

	move_pp_label.text = "%d/%d" % [slot.current_pp, move_data.pp]
	move_type_sprite.texture = TypeIconsDb.get_icon(move_data.type)
	move_type_sprite.visible = move_type_sprite.texture != null


func _update_ui() -> void:
	player_sprite.texture = player_pokemon.get_back_sprite()
	enemy_sprite.texture = enemy_pokemon.get_front_sprite()

	var back_offset: Vector2 = _get_back_offset_px(player_pokemon)
	var front_offset: Vector2 = _get_front_offset_px(enemy_pokemon)
	player_sprite.position = Vector2(
		player_sprite_base_pos.x,
		player_sprite_base_pos.y + back_offset.y
	)
	enemy_sprite.position = Vector2(
		enemy_sprite_base_pos.x,
		enemy_sprite_base_pos.y + front_offset.y
	)

	if player_name_label.has_method("cambiar_texto"):
		player_name_label.cambiar_texto(player_pokemon.get_display_name())
	else:
		player_name_label.text = player_pokemon.get_display_name()

	if enemy_name_label.has_method("cambiar_texto"):
		enemy_name_label.cambiar_texto(enemy_pokemon.get_display_name())
	else:
		enemy_name_label.text = enemy_pokemon.get_display_name()

	player_level_label.text = str(player_pokemon.level)
	enemy_level_label.text = str(enemy_pokemon.level)

	_set_gender(player_gender, player_pokemon.gender)
	_set_gender(enemy_gender, enemy_pokemon.gender)
	_update_hp_bars()
	_update_exp_bar()

func _set_gender(label: Label, gender: PokemonData.Gender) -> void:
	if label.label_settings == null:
		label.label_settings = LabelSettings.new()
	elif label.label_settings.resource_path != "":
		label.label_settings = label.label_settings.duplicate()

	match gender:
		PokemonData.Gender.MALE:
			label.text = "♂"
			label.label_settings.font_color = Color(0.2, 0.45, 1.0)
		PokemonData.Gender.FEMALE:
			label.text = "♀"
			label.label_settings.font_color = Color(1.0, 0.35, 0.55)
		_:
			label.text = ""


func _update_hp_bars() -> void:
	player_hp_label.text = "%d/%d" % [player_current_hp, player_pokemon.max_hp]
	player_hp_bar_target = PLAYER_HP_BAR_MAX_WIDTH * (
		float(player_current_hp) / float(maxi(player_pokemon.max_hp, 1))
	)
	enemy_hp_bar_target = ENEMY_HP_BAR_MAX_WIDTH * (
		float(enemy_current_hp) / float(maxi(enemy_pokemon.max_hp, 1))
	)


func _hp_color(ratio: float) -> Color:
	if ratio > 0.5:
		return Color(0.18, 0.93, 0.29)
	elif ratio > 0.2:
		return Color(0.95, 0.85, 0.2)
	return Color(0.9, 0.2, 0.2)

func _update_exp_bar() -> void:
	var species: PokemonDataStruct = player_pokemon.get_species()
	if species == null:
		player_exp_bar_target = 0.0
		return
	if player_pokemon.level >= ExperienceSystem.MAX_LEVEL:
		player_exp_bar_target = PLAYER_EXP_BAR_MAX_WIDTH
		return
	var exp_this_level: int = ExperienceSystem.get_total_exp_for_level(player_pokemon.level, species.growth_rate)
	var exp_next_level: int = ExperienceSystem.get_total_exp_for_level(player_pokemon.level + 1, species.growth_rate)
	var span: int = maxi(exp_next_level - exp_this_level, 1)
	var progress: float = float(player_pokemon.experience - exp_this_level) / float(span)
	player_exp_bar_target = PLAYER_EXP_BAR_MAX_WIDTH * clampf(progress, 0.0, 1.0)

func _get_back_offset_px(pokemon: PokemonInstance) -> Vector2:
	var species: PokemonDataStruct = pokemon.get_species()
	if species == null:
		return Vector2.ZERO
	var form: PokemonFormData = PokemonFormResolver.get_form(pokemon)
	if form != null and form.override_graphics:
		return form.back_sprite_offset * PokemonDataStruct.BATTLE_OFFSET_SCALE
	return species.get_back_sprite_offset_px()


func _get_front_offset_px(pokemon: PokemonInstance) -> Vector2:
	var species: PokemonDataStruct = pokemon.get_species()
	if species == null:
		return Vector2.ZERO
	var form: PokemonFormData = PokemonFormResolver.get_form(pokemon)
	if form != null and form.override_graphics:
		return form.front_sprite_offset * PokemonDataStruct.BATTLE_OFFSET_SCALE
	return species.get_front_sprite_offset_px()


func _show_message(text: String) -> void:
	battle_text.visible = false
	battle_normal_text.visible = true
	battle_normal_text.text = text


func _show_message_box(text: String) -> void:
	battle_text.visible = true
	battle_normal_text.visible = false
	battle_text.text = text


func _on_battle_message(text: String) -> void:
	_show_message(text)


func _on_hp_changed(is_player: bool, current_hp: int, _max_hp: int) -> void:
	if is_player:
		player_current_hp = current_hp
	else:
		enemy_current_hp = current_hp
	_update_hp_bars()


func _on_battle_ended(player_won: bool) -> void:
	if _battle_closing:
		return
	_battle_closing = true

	current_menu = MenuState.BUSY
	action_menu.visible = false
	fight_menu.visible = false

	var result: int = BattleSession.BattleResult.LOSE
	if _ended_by_run:
		result = BattleSession.BattleResult.RUN
		_show_message_box("¡Escapaste sin problemas!")
	elif player_won:
		result = BattleSession.BattleResult.WIN
		_show_message_box("¡Has ganado!")
	else:
		_show_message_box("...")

	await get_tree().create_timer(1.0).timeout

	if TransicionManager != null:
		await TransicionManager.fade_out(0.25)

	BattleSession.finalizar(result)

	if TransicionManager != null:
		await TransicionManager.fade_in(0.25)


func _on_turn_ended() -> void:
	if battle.player.charging_move != null or battle.player.must_recharge:
		current_menu = MenuState.BUSY
		action_menu.visible = false
		fight_menu.visible = false
		await battle.player_choose_move(0)
		return

	action_menu.visible = true
	current_menu = MenuState.ACTIONS
	selected_action = 0
	_update_action_focus()
	_show_message_box("¿Qué debe hacer %s?" % player_pokemon.get_display_name())


func _on_fight_pressed() -> void:
	action_menu.visible = false
	fight_menu.visible = true
	current_menu = MenuState.MOVES
	selected_move = 0
	_fill_move_buttons()
	_update_move_focus()


func _on_bag_pressed() -> void:
	_show_message("¡Aún no implementado!")


func _on_pkmn_pressed() -> void:
	_abrir_party_batalla(false)


func _on_player_must_switch() -> void:
	_force_switch_pending = true
	_abrir_party_batalla(true)


func _abrir_party_batalla(forzar: bool) -> void:
	if _party_ui != null and is_instance_valid(_party_ui):
		return

	current_menu = MenuState.BUSY
	action_menu.visible = false
	fight_menu.visible = false

	var datos: CharacterPlayer = null
	if BattleSession.player_controller != null:
		datos = BattleSession.player_controller.character_data as CharacterPlayer

	if datos == null:
		_show_message("¡No hay equipo disponible!")
		current_menu = MenuState.ACTIONS
		action_menu.visible = true
		return

	_party_ui = PARTY_SCENE.instantiate() as PartyMenu
	# Encima del overlay de batalla (layer 100)
	_party_ui.layer = 120
	_party_ui.visible = true

	# Mejor como hijo del root/tree para no heredar rarezas del Node2D de batalla
	var host: Node = get_tree().root
	host.add_child(_party_ui)

	_party_ui.battle_pokemon_selected.connect(_on_party_pokemon_selected)
	_party_ui.battle_cancelled.connect(_on_party_cancelled)
	_party_ui.party_closed.connect(_on_party_closed)
	_party_ui.setup_battle(datos, player_pokemon, forzar)

func _on_party_pokemon_selected(mon: PokemonInstance) -> void:
	var free_switch: bool = _force_switch_pending
	_force_switch_pending = false
	player_pokemon = mon
	await battle.player_choose_switch(mon, free_switch)
	_update_ui()


func _on_party_cancelled() -> void:
	_force_switch_pending = false
	action_menu.visible = true
	current_menu = MenuState.ACTIONS
	selected_action = 0
	_update_action_focus()
	_show_message_box("¿Qué debe hacer %s?" % player_pokemon.get_display_name())


func _on_party_closed() -> void:
	_party_ui = null


func _on_run_pressed() -> void:
	current_menu = MenuState.BUSY
	_ended_by_run = true
	battle.player_choose_run()


func _fill_move_buttons() -> void:
	var moves: Array[PokemonMoveSlot] = player_pokemon.moves

	for i: int in move_buttons.size():
		var button: TextureButton = move_buttons[i]
		var name_label: Label = button.get_node("Move_Name") as Label

		var normal_texture: Texture2D = _move_normals[i]
		var focused_texture: Texture2D = _move_focused[i]

		if i < moves.size() and moves[i] != null and not moves[i].is_empty():
			var slot: PokemonMoveSlot = moves[i]
			var move_data: MoveData = MoveDatabase.get_move(slot.move_id)

			if move_data:
				name_label.text = move_data.move_name
				button.disabled = slot.current_pp <= 0
				normal_texture = _get_move_button_texture(
					move_data.type, false, _move_normals[i]
				)
				focused_texture = _get_move_button_texture(
					move_data.type, true, _move_focused[i]
				)
			else:
				name_label.text = "---"
				button.disabled = true
		else:
			name_label.text = "---"
			button.disabled = true

		_current_move_normals[i] = normal_texture
		_current_move_focused[i] = focused_texture
		button.texture_normal = normal_texture
		button.texture_focused = focused_texture

	_update_selected_move_info()


func _on_move_pressed(index: int) -> void:
	if index < 0 or index >= player_pokemon.moves.size():
		return

	var slot: PokemonMoveSlot = player_pokemon.moves[index]
	if slot == null or slot.is_empty():
		return
	if slot.current_pp <= 0:
		_show_message("¡No quedan PP para este movimiento!")
		return

	fight_menu.visible = false
	current_menu = MenuState.BUSY
	await battle.player_choose_move(index)
	_update_selected_move_info()
