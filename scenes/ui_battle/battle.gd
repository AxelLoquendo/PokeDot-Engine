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

var player_pokemon: PokemonInstance
var enemy_pokemon: PokemonInstance
var player_sprite_base_pos: Vector2
var enemy_sprite_base_pos: Vector2

var battle: BattleManager

const PLAYER_HP_BAR_MAX_WIDTH: float = 48.0
const ENEMY_HP_BAR_MAX_WIDTH: float = 48.0
const HP_ANIM_SPEED: float = 40.0

enum MenuState { ACTIONS, MOVES, BUSY }
var current_menu: MenuState = MenuState.ACTIONS
var selected_action: int = 0
var selected_move: int = 0

var player_hp_bar_target: float = 48.0
var enemy_hp_bar_target: float = 48.0
var player_current_hp: int = 0
var enemy_current_hp: int = 0

# Texturas normales para restaurar al cambiar selección
var _action_normals: Array[Texture2D] = []
var _action_focused: Array[Texture2D] = []
var _move_normals: Array[Texture2D] = []
var _move_focused: Array[Texture2D] = []


func _ready() -> void:
	player_sprite_base_pos = player_sprite.position
	enemy_sprite_base_pos = enemy_sprite.position
	
	# Guardar texturas y desactivar foco nativo
	_action_normals.clear()
	_action_focused.clear()
	for b: TextureButton in action_buttons:
		_action_normals.append(b.texture_normal)
		_action_focused.append(b.texture_focused)
		b.focus_mode = Control.FOCUS_NONE
		b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	_move_normals.clear()
	_move_focused.clear()
	for b: TextureButton in move_buttons:
		_move_normals.append(b.texture_normal)
		_move_focused.append(b.texture_focused)
		b.focus_mode = Control.FOCUS_NONE
		b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	player_pokemon = PokemonInstance.create(Species.SpeciesID.SPECIES_HYDRAPPLE, 5)
	enemy_pokemon = PokemonInstance.create(Species.SpeciesID.SPECIES_BULBASAUR, 8)
	
	battle = BattleManager.new()
	battle.message.connect(_on_battle_message)
	battle.hp_changed.connect(_on_hp_changed)
	battle.battle_ended.connect(_on_battle_ended)
	battle.turn_ended.connect(_on_turn_ended)
	battle.start_battle(player_pokemon, enemy_pokemon)
	
	player_current_hp = player_pokemon.current_hp
	enemy_current_hp = enemy_pokemon.current_hp
	
	_update_ui()
	player_hp_bar.size.x = player_hp_bar_target
	enemy_hp_bar.size.x = enemy_hp_bar_target
	
	fight_menu.visible = false
	action_menu.visible = true
	current_menu = MenuState.ACTIONS
	selected_action = 0
	_update_action_focus()
	_show_message_box("¿Qué debe hacer %s?" % player_pokemon.get_display_name())


func _process(delta: float) -> void:
	if absf(player_hp_bar.size.x - player_hp_bar_target) > 0.5:
		player_hp_bar.size.x = move_toward(player_hp_bar.size.x, player_hp_bar_target, HP_ANIM_SPEED * delta)
		player_hp_bar.color = _hp_color(player_hp_bar.size.x / PLAYER_HP_BAR_MAX_WIDTH)
	else:
		player_hp_bar.size.x = player_hp_bar_target
	
	if absf(enemy_hp_bar.size.x - enemy_hp_bar_target) > 0.5:
		enemy_hp_bar.size.x = move_toward(enemy_hp_bar.size.x, enemy_hp_bar_target, HP_ANIM_SPEED * delta)
		enemy_hp_bar.color = _hp_color(enemy_hp_bar.size.x / ENEMY_HP_BAR_MAX_WIDTH)
	else:
		enemy_hp_bar.size.x = enemy_hp_bar_target


func _input(event: InputEvent) -> void:
	if current_menu == MenuState.BUSY:
		return
	if current_menu == MenuState.ACTIONS:
		_handle_action_input(event)
	elif current_menu == MenuState.MOVES:
		_handle_move_input(event)


# ============================================================
# NAVEGACIÓN - ACCIONES
# ============================================================

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
		var b: TextureButton = action_buttons[i]
		if i == selected_action and _action_focused[i]:
			b.texture_normal = _action_focused[i]
		else:
			b.texture_normal = _action_normals[i]


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


# ============================================================
# NAVEGACIÓN - MOVIMIENTOS
# ============================================================

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
		var b: TextureButton = move_buttons[i]
		if i == selected_move and _move_focused[i]:
			b.texture_normal = _move_focused[i]
		else:
			b.texture_normal = _move_normals[i]


# ============================================================
# UI
# ============================================================

func _update_ui() -> void:
	player_sprite.texture = player_pokemon.get_back_sprite()
	enemy_sprite.texture = enemy_pokemon.get_front_sprite()
	
	var back_offset: Vector2 = _get_back_offset_px(player_pokemon)
	var front_offset: Vector2 = _get_front_offset_px(enemy_pokemon)
	player_sprite.position = Vector2(player_sprite_base_pos.x, player_sprite_base_pos.y + back_offset.y)
	enemy_sprite.position = Vector2(enemy_sprite_base_pos.x, enemy_sprite_base_pos.y + front_offset.y)
	
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
	player_hp_bar_target = PLAYER_HP_BAR_MAX_WIDTH * (float(player_current_hp) / float(maxi(player_pokemon.max_hp, 1)))
	enemy_hp_bar_target = ENEMY_HP_BAR_MAX_WIDTH * (float(enemy_current_hp) / float(maxi(enemy_pokemon.max_hp, 1)))


func _hp_color(ratio: float) -> Color:
	if ratio > 0.5:
		return Color(0.18, 0.93, 0.29)
	elif ratio > 0.2:
		return Color(0.95, 0.85, 0.2)
	return Color(0.9, 0.2, 0.2)


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


# ============================================================
# SEÑALES DEL BATTLE MANAGER
# ============================================================

func _on_battle_message(text: String) -> void:
	_show_message(text)


func _on_hp_changed(is_player: bool, current_hp: int, _max_hp: int) -> void:
	if is_player:
		player_current_hp = current_hp
	else:
		enemy_current_hp = current_hp
	_update_hp_bars()


func _on_battle_ended(_player_won: bool) -> void:
	current_menu = MenuState.BUSY
	action_menu.visible = false
	fight_menu.visible = false


func _on_turn_ended() -> void:
	action_menu.visible = true
	current_menu = MenuState.ACTIONS
	selected_action = 0
	_update_action_focus()
	_show_message_box("¿Qué debe hacer %s?" % player_pokemon.get_display_name())


# ============================================================
# ACCIONES DE MENÚ
# ============================================================

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
	_show_message("¡Aún no implementado!")


func _on_run_pressed() -> void:
	current_menu = MenuState.BUSY
	battle.player_choose_run()


func _fill_move_buttons() -> void:
	var moves: Array[PokemonMoveSlot] = player_pokemon.moves
	for i: int in move_buttons.size():
		var button: TextureButton = move_buttons[i]
		var name_label: Label = button.get_node("Move_Name") as Label
		if i < moves.size() and moves[i] != null and not moves[i].is_empty():
			var move_data: MoveData = MoveDatabase.get_move(moves[i].move_id)
			if move_data:
				name_label.text = move_data.move_name
				button.disabled = false
			else:
				name_label.text = "---"
				button.disabled = true
		else:
			name_label.text = "---"
			button.disabled = true


func _on_move_pressed(index: int) -> void:
	if index < 0 or index >= player_pokemon.moves.size():
		return
	var slot: PokemonMoveSlot = player_pokemon.moves[index]
	if slot == null or slot.is_empty():
		return
	
	fight_menu.visible = false
	current_menu = MenuState.BUSY
	await battle.player_choose_move(index)
