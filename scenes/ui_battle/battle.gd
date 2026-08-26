extends Node2D

# --- Referencias de la UI ---
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

# --- Datos de la batalla ---
var player_pokemon: PokemonInstance
var enemy_pokemon: PokemonInstance
var player_current_hp: int
var enemy_current_hp: int
var player_sprite_base_pos: Vector2
var enemy_sprite_base_pos: Vector2

const PLAYER_HP_BAR_MAX_WIDTH: float = 48.0
const ENEMY_HP_BAR_MAX_WIDTH: float = 48.0
const HP_ANIM_SPEED: float = 40.0  # píxeles por segundo (ajusta a gusto)

# Navegación
enum MenuState { ACTIONS, MOVES, BUSY }
var current_menu: MenuState = MenuState.ACTIONS
var selected_action: int = 0
var selected_move: int = 0

# Animación de barras
var player_hp_bar_target: float = 48.0
var enemy_hp_bar_target: float = 48.0


func _ready() -> void:
	player_sprite_base_pos = player_sprite.position
	enemy_sprite_base_pos = enemy_sprite.position
	
	player_pokemon = PokemonInstance.create(Species.SpeciesID.SPECIES_HYDRAPPLE, 12)
	enemy_pokemon = PokemonInstance.create(Species.SpeciesID.SPECIES_BULBASAUR, 11)
	
	player_current_hp = player_pokemon.current_hp
	enemy_current_hp = enemy_pokemon.current_hp
	
	_update_ui()
	
	# Estado inicial de las barras (sin animación al empezar)
	player_hp_bar.size.x = player_hp_bar_target
	enemy_hp_bar.size.x = enemy_hp_bar_target
	
	fight_menu.visible = false
	action_menu.visible = true
	current_menu = MenuState.ACTIONS
	selected_action = 0
	_update_action_focus()
	
	_show_message_box("¿Qué debe hacer %s?" % player_pokemon.get_display_name())


func _process(delta: float) -> void:
	# Animar barras de HP suavemente
	if absf(player_hp_bar.size.x - player_hp_bar_target) > 0.5:
		player_hp_bar.size.x = move_toward(player_hp_bar.size.x, player_hp_bar_target, HP_ANIM_SPEED * delta)
		var ratio: float = player_hp_bar.size.x / PLAYER_HP_BAR_MAX_WIDTH
		player_hp_bar.color = _hp_color(ratio)
	else:
		player_hp_bar.size.x = player_hp_bar_target
	
	if absf(enemy_hp_bar.size.x - enemy_hp_bar_target) > 0.5:
		enemy_hp_bar.size.x = move_toward(enemy_hp_bar.size.x, enemy_hp_bar_target, HP_ANIM_SPEED * delta)
		var ratio: float = enemy_hp_bar.size.x / ENEMY_HP_BAR_MAX_WIDTH
		enemy_hp_bar.color = _hp_color(ratio)
	else:
		enemy_hp_bar.size.x = enemy_hp_bar_target


func _unhandled_input(event: InputEvent) -> void:
	if current_menu == MenuState.BUSY:
		return
	
	if current_menu == MenuState.ACTIONS:
		_handle_action_input(event)
	elif current_menu == MenuState.MOVES:
		_handle_move_input(event)


# ============================================================
# NAVEGACIÓN - MENÚ DE ACCIONES
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
		if i == selected_action:
			action_buttons[i].grab_focus()
		else:
			action_buttons[i].release_focus()


func _activate_action(index: int) -> void:
	match index:
		0: _on_fight_pressed()
		1: _on_bag_pressed()
		2: _on_pkmn_pressed()
		3: _on_run_pressed()


# ============================================================
# NAVEGACIÓN - MENÚ DE MOVIMIENTOS
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
		# Volver al menú de acciones
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
		if i == selected_move:
			move_buttons[i].grab_focus()
		else:
			move_buttons[i].release_focus()


# ============================================================
# UI
# ============================================================

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


func _set_gender(label: Label, gender: PokemonData.Gender) -> void:
	# Asegurar que tenemos un LabelSettings propio
	if label.label_settings == null:
		label.label_settings = LabelSettings.new()
	elif label.label_settings.resource_path != "":
		# Está usando un recurso compartido → duplicar para no afectar a otros
		label.label_settings = label.label_settings.duplicate()
	
	match gender:
		PokemonData.Gender.MALE:
			label.text = "♂"
			label.label_settings.font_color = Color(0.2, 0.45, 1.0)  # Azul
		PokemonData.Gender.FEMALE:
			label.text = "♀"
			label.label_settings.font_color = Color(1.0, 0.35, 0.55) # Rosa
		_:
			label.text = ""


func _update_hp_bars() -> void:
	player_hp_label.text = "%d/%d" % [player_current_hp, player_pokemon.max_hp]
	
	var player_ratio: float = float(player_current_hp) / float(maxi(player_pokemon.max_hp, 1))
	player_hp_bar_target = PLAYER_HP_BAR_MAX_WIDTH * player_ratio
	
	var enemy_ratio: float = float(enemy_current_hp) / float(maxi(enemy_pokemon.max_hp, 1))
	enemy_hp_bar_target = ENEMY_HP_BAR_MAX_WIDTH * enemy_ratio


func _hp_color(ratio: float) -> Color:
	if ratio > 0.5:
		return Color(0.18, 0.93, 0.29)
	elif ratio > 0.2:
		return Color(0.95, 0.85, 0.2)
	else:
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
	_show_message("¡Escapaste con éxito!")
	await get_tree().create_timer(1.5).timeout
	current_menu = MenuState.ACTIONS


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
	if index >= player_pokemon.moves.size():
		return
	
	var move_slot: PokemonMoveSlot = player_pokemon.moves[index]
	if move_slot == null or move_slot.is_empty():
		return
	
	var move_data: MoveData = MoveDatabase.get_move(move_slot.move_id)
	if move_data == null:
		return
	
	fight_menu.visible = false
	current_menu = MenuState.BUSY
	await _execute_turn(move_data)


# ============================================================
# COMBATE
# ============================================================

func _execute_turn(player_move: MoveData) -> void:
	_show_message("%s usó %s!" % [player_pokemon.get_display_name(), player_move.move_name])
	await get_tree().create_timer(1.0).timeout
	
	var damage_to_enemy: int = _calculate_damage(player_pokemon, enemy_pokemon, player_move)
	enemy_current_hp = maxi(0, enemy_current_hp - damage_to_enemy)
	_update_hp_bars()
	
	# Esperar a que la barra termine de bajar
	await _wait_hp_animation()
	
	_show_message("¡Hizo %d de daño!" % damage_to_enemy)
	await get_tree().create_timer(0.8).timeout
	
	if enemy_current_hp <= 0:
		_show_message("¡%s se debilitó!" % enemy_pokemon.get_display_name())
		await get_tree().create_timer(1.5).timeout
		_show_message("¡Ganaste!")
		return
	
	var enemy_move: MoveData = null
	for slot: PokemonMoveSlot in enemy_pokemon.moves:
		if slot and not slot.is_empty():
			enemy_move = MoveDatabase.get_move(slot.move_id)
			break
	
	if enemy_move == null:
		enemy_move = MoveDatabase.get_move(Moves.MoveId.MOVE_POUND)
	
	_show_message("%s usó %s!" % [enemy_pokemon.get_display_name(), enemy_move.move_name])
	await get_tree().create_timer(1.0).timeout
	
	var damage_to_player: int = _calculate_damage(enemy_pokemon, player_pokemon, enemy_move)
	player_current_hp = maxi(0, player_current_hp - damage_to_player)
	_update_hp_bars()
	
	await _wait_hp_animation()
	
	_show_message("¡Hizo %d de daño!" % damage_to_player)
	await get_tree().create_timer(0.8).timeout
	
	if player_current_hp <= 0:
		_show_message("¡%s se debilitó!" % player_pokemon.get_display_name())
		await get_tree().create_timer(1.5).timeout
		_show_message("Has perdido...")
		return
	
	action_menu.visible = true
	current_menu = MenuState.ACTIONS
	selected_action = 0
	_update_action_focus()
	_show_message_box("¿Qué debe hacer %s?" % player_pokemon.get_display_name())


func _wait_hp_animation() -> void:
	# Espera hasta que ambas barras lleguen a su objetivo
	while absf(player_hp_bar.size.x - player_hp_bar_target) > 0.5 \
		or absf(enemy_hp_bar.size.x - enemy_hp_bar_target) > 0.5:
		await get_tree().process_frame


func _calculate_damage(attacker: PokemonInstance, defender: PokemonInstance, move: MoveData) -> int:
	var power: int = maxi(move.power, 1)
	var attack: int = attacker.get_stat(PokemonInstance.Stat.ATTACK)
	var defense: int = maxi(defender.get_stat(PokemonInstance.Stat.DEFENSE), 1)
	
	var damage: int = int((float(power) * float(attack) / float(defense)) / 5.0) + 2
	return maxi(damage, 1)
