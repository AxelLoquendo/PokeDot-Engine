extends Node2D

@onready var player_sprite: Sprite2D = $Pkmn_Player
@onready var enemy_sprite: Sprite2D = $Pkmn_Enemy
@onready var player_sprite_2: Sprite2D = get_node_or_null("Pkmn_Player2") as Sprite2D
@onready var enemy_sprite_2: Sprite2D = get_node_or_null("Pkmn_Enemy2") as Sprite2D
@onready var cry_player: AudioStreamPlayer = $Pkmn_Player/Cry_Mon_Player
@onready var cry_enemy: AudioStreamPlayer = $Pkmn_Enemy/Cry_Mon_Enemy
@onready var cry_player_2: AudioStreamPlayer = get_node_or_null("Pkmn_Player2/Cry_Mon_Player") as AudioStreamPlayer
@onready var cry_enemy_2: AudioStreamPlayer = get_node_or_null("Pkmn_Enemy2/Cry_Mon_Enemy") as AudioStreamPlayer
@onready var player_hp_box: Sprite2D = $PlayerHPBox
@onready var player_hp_box_2: Sprite2D = get_node_or_null("PlayerHPBox2") as Sprite2D
@onready var enemy_hp_box: Sprite2D = get_node_or_null("EnemyHPBox") as Sprite2D
@onready var enemy_hp_box_2: Sprite2D = get_node_or_null("EnemyHPBox2") as Sprite2D

@onready var player_name_label: Label = $PlayerHPBox/NamePkmnPlayer
@onready var player_level_label: Label = $PlayerHPBox/Level
@onready var player_hp_label: Label = $PlayerHPBox/HP
@onready var player_hp_bar: ColorRect = $PlayerHPBox/HpBar
@onready var player_gender: Label = $PlayerHPBox/Genero
@onready var player_status: Sprite2D = $PlayerHPBox/Status

@onready var enemy_name_label: Label = $EnemyHPBox/NamePkmnEnemy
@onready var enemy_level_label: Label = $EnemyHPBox/Level
@onready var enemy_hp_bar: ColorRect = $EnemyHPBox/HpBar
@onready var enemy_gender: Label = $EnemyHPBox/Genero
@onready var enemy_status: Sprite2D = $EnemyHPBox/Status

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
@onready var player_exp_bar_2: ColorRect = get_node_or_null("PlayerHPBox2/ExpBar") as ColorRect

@onready var bg_sprite: Sprite2D = $BG

@onready var ability_bar_player: Sprite2D = $Ability_Bar_Player
@onready var ability_bar_enemy: Sprite2D = $Ability_Bar_Enemy
@onready var ability_label_player: Label = $Ability_Bar_Player/Ability_Name
@onready var ability_label_enemy: Label = $Ability_Bar_Enemy/Ability_Name
@onready var ability_icon_player: Sprite2D = $Ability_Bar_Player/Icon_Mon
@onready var ability_icon_enemy: Sprite2D = $Ability_Bar_Enemy/Icon_Mon
@onready var ability_anim: AnimationPlayer = $Animated_Ability_Bar

@export var ability_icon_frame_time: float = 0.15
@export var ability_bar_hold_time: float = 1.0

var _ability_icon_timer_player: float = 0.0
var _ability_icon_timer_enemy: float = 0.0
var _ability_bar_busy: bool = false

const PARTY_SCENE: PackedScene = preload("res://scenes/ui_party_menu/party_menu.tscn")
const BAG_SCENE: PackedScene = preload("res://scenes/ui_bag/bag.tscn")

const ABILITY_POS_PLAYER_OFF: Vector2 = Vector2(-128, 152)
const ABILITY_POS_PLAYER_ON: Vector2 = Vector2(128, 152)
const ABILITY_POS_ENEMY_OFF: Vector2 = Vector2(640, 88)
const ABILITY_POS_ENEMY_ON: Vector2 = Vector2(352, 88)

var player_pokemon: PokemonInstance
var enemy_pokemon: PokemonInstance
var player_sprite_base_pos: Vector2
var enemy_sprite_base_pos: Vector2
var player_hp_box_base_pos: Vector2
var player_sprite_b_base_pos: Vector2 = Vector2.ZERO
var enemy_sprite_b_base_pos: Vector2 = Vector2.ZERO
var enemy_hp_box_base_pos: Vector2 = Vector2.ZERO

var _player_sprite_species_offset_y: float = 0.0

# Bob discreto e independiente
var _bob_sprite_time: float = 0.0
var _bob_box_time: float = 0.0
var _bob_sprite_down: bool = false
var _bob_box_down: bool = false

const BOB_PIXELS: float = 2.0
## Periodos distintos → no se sincronizan (estilo juegos oficiales)
const BOB_SPRITE_HALF_PERIOD: float = 0.50
const BOB_BOX_HALF_PERIOD: float = 0.55

var battle: BattleManager

const PLAYER_HP_BAR_MAX_WIDTH: float = 48.0
const ENEMY_HP_BAR_MAX_WIDTH: float = 48.0
const HP_ANIM_SPEED: float = 96.0  # gradual pero rápido

const PLAYER_EXP_BAR_MAX_WIDTH: float = 63.5
var player_exp_bar_target: float = 0.0
var player_exp_bar_2_target: float = 0.0

enum MenuState { ACTIONS, MOVES, TARGET, BUSY }
var current_menu: MenuState = MenuState.ACTIONS
var selected_action: int = 0
var selected_move: int = 0

var player_hp_bar_target: float = 48.0
var enemy_hp_bar_target: float = 48.0
var player_current_hp: int = 0

## ─── UI multi (nodos de escena Pkmn_*2 / *HPBox2) ───────
var _multi_ui_ready: bool = false
var _input_actor_slot: int = 0
## Objetivo: >=0 rival slot, -2 = aliado, -1 = auto
var _input_target_slot: int = 0
var _pending_move_index: int = -1
## Aliases slot 1 (nodos de la escena)
var player_sprite_b: Sprite2D = null
var enemy_sprite_b: Sprite2D = null
var player_hp_box_b: Sprite2D = null
var enemy_hp_box_b: Sprite2D = null
## Posiciones 1v1 vs doble (eje X sprites / Y HP boxes)
const POS_PLAYER_X_SINGLE: float = 128.0
const POS_PLAYER_X_DOUBLE: float = 84.0
const POS_ENEMY_X_SINGLE: float = 353.0
const POS_ENEMY_X_DOUBLE: float = 316.0
const POS_PLAYER_HP_Y_SINGLE: float = 183.0
const POS_PLAYER_HP_Y_DOUBLE: float = 158.0
const POS_ENEMY_HP_Y_SINGLE: float = 64.0
const POS_ENEMY_HP_Y_DOUBLE: float = 34.0
const FOCUS_MOD: Color = Color(1.15, 1.15, 1.15, 1.0)
const UNFOCUS_MOD: Color = Color(0.55, 0.55, 0.55, 1.0)
const NORMAL_MOD: Color = Color(1, 1, 1, 1)
const Z_HP_FOCUS: int = 40
const Z_HP_BACK: int = 12
const Z_HP_NORMAL: int = 20
## Evitar repetir animación de KO
var _faint_animating: Dictionary = {}  # "p0","p1","e0","e1" -> true
## ColorRect -> ancho objetivo (animación suave de HP multi)
var _hp_bar_anim_targets: Dictionary = {}  # int (instance_id) -> float (ancho)
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
var _bag_ui: BagUI = null
var _battle_item_pending: bool = false
var _force_switch_pending: bool = false
var _battle_canvas_modulate: CanvasModulate = null

var _default_bg_texture: Texture2D
var _weather_container_parent: Node = null
var _weather_attached: bool = false

func _ready() -> void:
	player_sprite_base_pos = player_sprite.position
	enemy_sprite_base_pos = enemy_sprite.position
	player_hp_box_base_pos = player_hp_box.position
	# Slot 2 oculto hasta saber si es multi (evita flash en 1v1)
	if player_sprite_2 != null:
		player_sprite_2.visible = false
		player_sprite_b_base_pos = player_sprite_2.position
	if enemy_sprite_2 != null:
		enemy_sprite_2.visible = false
		enemy_sprite_b_base_pos = enemy_sprite_2.position
	if player_hp_box_2 != null:
		player_hp_box_2.visible = false
	if enemy_hp_box_2 != null:
		enemy_hp_box_2.visible = false
	if enemy_hp_box != null:
		enemy_hp_box_base_pos = enemy_hp_box.position

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

	_default_bg_texture = bg_sprite.texture

	battle = BattleManager.new()
	battle.message.connect(_on_battle_message)
	battle.hp_changed.connect(_on_hp_changed)
	if battle.has_signal("status_changed"):
		battle.status_changed.connect(_on_status_changed)
	battle.player_progress_changed.connect(_on_player_progress_changed)
	battle.battle_ended.connect(_on_battle_ended)
	battle.turn_ended.connect(_on_turn_ended)
	battle.player_must_switch.connect(_on_player_must_switch)
	if battle.has_signal("ability_announced"):
		battle.ability_announced.connect(_on_ability_announced)
	if battle.has_signal("battler_appearance_changed"):
		battle.battler_appearance_changed.connect(_on_battler_appearance_changed)
	if battle.has_signal("illusion_broken"):
		battle.illusion_broken.connect(_on_illusion_broken)
	if battle.has_signal("pokemon_entered_field"):
		battle.pokemon_entered_field.connect(_on_pokemon_entered_field)
	if battle.has_signal("terrain_changed"):
		battle.terrain_changed.connect(_on_terrain_changed)
	if battle.has_signal("weather_changed"):
		battle.weather_changed.connect(_on_battle_weather_changed)

	_attach_battle_weather()

	battle.start_battle(
		player_pokemon, enemy_pokemon, party, BattleSession.enemy_party,
		BattleSession.battle_format as BattleManager.BattleFormat,
		BattleSession.is_wild
	)

	player_exp_bar.size.x = player_exp_bar_target
	if player_exp_bar_2 != null:
		player_exp_bar_2.size.x = player_exp_bar_2_target
	player_current_hp = player_pokemon.current_hp
	enemy_current_hp = enemy_pokemon.current_hp

	# Layout + sprites/HP listos ANTES de que el jugador vea la intro
	_setup_multi_battle_ui()
	_update_ui()
	_refresh_side_appearance(false)
	_refresh_side_appearance(true)
	_refresh_all_multi_appearances()

	player_hp_bar.size.x = player_hp_bar_target
	enemy_hp_bar.size.x = enemy_hp_bar_target

	fight_menu.visible = false
	action_menu.visible = false
	current_menu = MenuState.BUSY
	_reset_ability_bars()

	# Gritos salen desde pokemon_entered_field dentro de start_battle_intro
	await battle.start_battle_intro()

	_refresh_all_multi_appearances()
	_apply_actor_focus()
	_begin_player_command_phase()

func _on_player_progress_changed() -> void:
	# Niveles y EXP de ambos slots del jugador
	var m0: PokemonInstance = _mon_for_player_slot(0)
	var m1: PokemonInstance = _mon_for_player_slot(1)
	if m0 != null and player_level_label != null:
		player_level_label.text = str(m0.level)
	if m1 != null and player_hp_box_2 != null:
		var lvl2: Label = player_hp_box_2.get_node_or_null("Level") as Label
		if lvl2 != null:
			lvl2.text = str(m1.level)
	_update_exp_bar()

func _on_terrain_changed(terrain: int) -> void:
	var path: String = AbilityBattleEffect.BG_TERRAIN_SPRITES.get(terrain, "")
	if path.is_empty():
		bg_sprite.texture = _default_bg_texture
		return
	var tex: Texture2D = load(path) as Texture2D
	if tex != null:
		bg_sprite.texture = tex

func _process(delta: float) -> void:
	if absf(player_hp_bar.size.x - player_hp_bar_target) > 0.5:
		player_hp_bar.size.x = move_toward(player_hp_bar.size.x, player_hp_bar_target, HP_ANIM_SPEED * delta)
	else:
		player_hp_bar.size.x = player_hp_bar_target
	player_hp_bar.color = _hp_color(player_hp_bar.size.x / PLAYER_HP_BAR_MAX_WIDTH)

	if enemy_hp_bar != null:
		if absf(enemy_hp_bar.size.x - enemy_hp_bar_target) > 0.5:
			enemy_hp_bar.size.x = move_toward(enemy_hp_bar.size.x, enemy_hp_bar_target, HP_ANIM_SPEED * delta)
		else:
			enemy_hp_bar.size.x = enemy_hp_bar_target
		enemy_hp_bar.color = _hp_color(enemy_hp_bar.size.x / ENEMY_HP_BAR_MAX_WIDTH)

	# Barras de HP de cajas multi (slot 2, etc.)
	_animate_tracked_hp_bars(delta)

	if absf(player_exp_bar.size.x - player_exp_bar_target) > 0.5:
		player_exp_bar.size.x = move_toward(player_exp_bar.size.x, player_exp_bar_target, HP_ANIM_SPEED * delta)
	else:
		player_exp_bar.size.x = player_exp_bar_target
	if player_exp_bar_2 != null and player_exp_bar_2.visible:
		if absf(player_exp_bar_2.size.x - player_exp_bar_2_target) > 0.5:
			player_exp_bar_2.size.x = move_toward(player_exp_bar_2.size.x, player_exp_bar_2_target, HP_ANIM_SPEED * delta)
		else:
			player_exp_bar_2.size.x = player_exp_bar_2_target

	_animate_ability_icon(delta, ability_icon_player, true)
	_animate_ability_icon(delta, ability_icon_enemy, false)

	_update_player_idle_bob(delta)

func _input(event: InputEvent) -> void:
	if current_menu == MenuState.BUSY:
		return
	if current_menu == MenuState.ACTIONS:
		_handle_action_input(event)
	elif current_menu == MenuState.MOVES:
		_handle_move_input(event)
	elif current_menu == MenuState.TARGET:
		_handle_target_input(event)


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

	_player_sprite_species_offset_y = back_offset.y   # ← AÑADIR
	player_sprite.position = Vector2(
		player_sprite_base_pos.x,
		player_sprite_base_pos.y + _player_sprite_species_offset_y
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
	_update_status_icons()
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


func _update_status_icons() -> void:
	if player_pokemon != null:
		StatusConditions.apply_icon_from_pokemon(player_status, player_pokemon)
	else:
		StatusConditions.apply_icon(player_status, PokemonInstance.Status.NONE)
	if enemy_pokemon != null:
		StatusConditions.apply_icon_from_pokemon(enemy_status, enemy_pokemon)
	else:
		StatusConditions.apply_icon(enemy_status, PokemonInstance.Status.NONE)


func _on_status_changed(_is_player: bool) -> void:
	_update_status_icons()



func _hp_color(ratio: float) -> Color:
	if ratio > 0.5:
		return Color(0.18, 0.93, 0.29)
	elif ratio > 0.2:
		return Color(0.95, 0.85, 0.2)
	return Color(0.9, 0.2, 0.2)


func _update_exp_bar() -> void:
	# Slot 0
	player_exp_bar_target = _exp_progress_width(_mon_for_player_slot(0))
	# Slot 1 (dobles)
	player_exp_bar_2_target = _exp_progress_width(_mon_for_player_slot(1))


func _mon_for_player_slot(slot: int) -> PokemonInstance:
	if battle != null and slot < battle.player_actives.size():
		var b: BattleBattler = battle.player_actives[slot]
		if b != null and b.pokemon != null:
			return b.pokemon
	if slot == 0:
		return player_pokemon
	return null


func _exp_progress_width(mon: PokemonInstance) -> float:
	if mon == null:
		return 0.0
	var species: PokemonDataStruct = mon.get_species()
	if species == null:
		return 0.0
	if mon.level >= ExperienceSystem.MAX_LEVEL:
		return PLAYER_EXP_BAR_MAX_WIDTH
	var exp_this_level: int = ExperienceSystem.get_total_exp_for_level(mon.level, species.growth_rate)
	var exp_next_level: int = ExperienceSystem.get_total_exp_for_level(mon.level + 1, species.growth_rate)
	var span: int = maxi(exp_next_level - exp_this_level, 1)
	var progress: float = float(mon.experience - exp_this_level) / float(span)
	return PLAYER_EXP_BAR_MAX_WIDTH * clampf(progress, 0.0, 1.0)


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
	_update_multi_hp_boxes()
	# KO: grito + animación (cualquier modo)
	if current_hp <= 0 and battle != null:
		var actives: Array = battle.player_actives if is_player else battle.enemy_actives
		for i: int in range(actives.size()):
			var b: BattleBattler = actives[i]
			if b != null and b.pokemon != null and b.is_fainted():
				var key: String = ("p" if is_player else "e") + str(i)
				if not bool(_faint_animating.get(key, false)):
					_faint_animating[key] = true
					_play_faint_animation(is_player, i, b)
	if _multi_ui_ready:
		_refresh_all_multi_appearances()


func _on_battle_ended(player_won: bool) -> void:
	if _battle_closing:
		return
	_battle_closing = true
	current_menu = MenuState.BUSY
	action_menu.visible = false
	fight_menu.visible = false

	_detach_battle_weather()

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
	_update_status_icons()
	_refresh_all_multi_appearances()
	_pending_move_index = -1
	# Recarga / carga del mon que está en input (o todos en multi)
	if battle != null and battle.is_multi_battle():
		for b: BattleBattler in battle.player_actives:
			if b != null and not b.is_fainted() and (b.charging_move != null or b.must_recharge):
				current_menu = MenuState.BUSY
				action_menu.visible = false
				fight_menu.visible = false
				await battle.player_choose_move(0, b.slot_index, _input_target_slot)
				return
	elif battle.player.charging_move != null or battle.player.must_recharge:
		current_menu = MenuState.BUSY
		action_menu.visible = false
		fight_menu.visible = false
		await battle.player_choose_move(0)
		return

	_begin_player_command_phase()


func _on_fight_pressed() -> void:
	action_menu.visible = false
	fight_menu.visible = true
	current_menu = MenuState.MOVES
	selected_move = 0
	_fill_move_buttons()
	_update_move_focus()


func _on_bag_pressed() -> void:
	if _bag_ui != null and is_instance_valid(_bag_ui):
		return
	var data: CharacterPlayer = BattleSession.player_controller.character_data as CharacterPlayer if BattleSession.player_controller else null
	if data == null:
		_show_message("¡No hay mochila disponible!")
		return
	current_menu = MenuState.BUSY
	action_menu.visible = false
	_bag_ui = BAG_SCENE.instantiate() as BagUI
	_bag_ui.layer = 120
	get_tree().root.add_child(_bag_ui)
	_bag_ui.setup(data, BagUI.BagMode.BATTLE)
	_bag_ui.battle_item_selected.connect(_on_battle_item_selected)
	_bag_ui.bag_closed.connect(_on_battle_bag_closed)


func _on_pkmn_pressed() -> void:
	_abrir_party_batalla(false)


func _on_player_must_switch() -> void:
	_ask_fainted_action()


func _ask_fainted_action() -> void:
	current_menu = MenuState.BUSY
	_show_message_box("¿Qué hará el entrenador?")
	var options: Array[String] = ["Cambiar Pokémon"]
	if not battle.is_trainer_battle:
		options.append("Escapar")
	var choice: int = await DialogueManager.choose(options, Vector2(468, 308))
	if choice == 1 and not battle.is_trainer_battle:
		_ended_by_run = true
		battle.player_choose_run()
		return
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
	_party_ui.layer = 120
	_party_ui.visible = true

	var host: Node = get_tree().root
	host.add_child(_party_ui)

	_party_ui.battle_pokemon_selected.connect(_on_party_pokemon_selected)
	_party_ui.battle_cancelled.connect(_on_party_cancelled)
	_party_ui.party_closed.connect(_on_party_closed)
	# Mon del slot que está eligiendo (o el KO forzado)
	var active_for_party: PokemonInstance = player_pokemon
	if battle != null:
		var slot_p: int = _input_actor_slot
		if forzar:
			for i2: int in range(battle.player_actives.size()):
				var bk: BattleBattler = battle.player_actives[i2]
				if bk != null and (bk.pokemon == null or bk.is_fainted()):
					slot_p = i2
					break
		var ba: BattleBattler = battle.player_actives[slot_p] if slot_p < battle.player_actives.size() else null
		if ba != null and ba.pokemon != null:
			active_for_party = ba.pokemon
	_party_ui.setup_battle(datos, active_for_party, forzar)


func _on_party_pokemon_selected(mon: PokemonInstance) -> void:
	var free_switch: bool = _force_switch_pending
	_force_switch_pending = false
	var switch_slot: int = _input_actor_slot
	if free_switch and battle != null:
		# Sustituir el primer slot KO
		for i: int in range(battle.player_actives.size()):
			var b: BattleBattler = battle.player_actives[i]
			if b != null and (b.pokemon == null or b.is_fainted()):
				switch_slot = i
				break

	await battle.player_choose_switch(mon, free_switch, switch_slot)

	_sync_player_pokemon_ref_from_slot()
	_refresh_all_multi_appearances()
	_update_hp_bars()
	_update_status_icons()
	_update_exp_bar()
	if player_pokemon != null and player_level_label != null:
		player_level_label.text = str(player_pokemon.level)

	if not battle.is_running:
		return

	# En multi voluntario: igual que tras un ataque, pasar al siguiente mon
	if not free_switch and battle.is_multi_battle():
		var needed: int = 0
		for b2: BattleBattler in battle.player_actives:
			if b2 != null and b2.pokemon != null and not b2.is_fainted():
				needed += 1
		if battle._pending_player_actions.size() > 0 and battle._pending_player_actions.size() < needed:
			var next_slot: int = _next_conscious_player_slot(switch_slot + 1)
			if next_slot >= 0:
				_input_actor_slot = next_slot
				_sync_player_pokemon_ref_from_slot()
				_apply_actor_focus()
				action_menu.visible = true
				current_menu = MenuState.ACTIONS
				selected_action = 0
				_update_action_focus()
				_show_message_box("¿Qué debe hacer %s?" % (
					player_pokemon.get_display_name() if player_pokemon else "???"
				))
				return
	# Turno resuelto o 1v1: el turn_ended / busy se encargan

func _on_party_cancelled() -> void:
	_force_switch_pending = false
	action_menu.visible = true
	current_menu = MenuState.ACTIONS
	selected_action = 0
	_update_action_focus()
	_show_message_box("¿Qué debe hacer %s?" % player_pokemon.get_display_name())


func _on_party_closed() -> void:
	_party_ui = null


func _on_battle_item_selected(item_id: Items.ItemId) -> void:
	_battle_item_pending = true
	var data: ItemData = ItemDatabase.get_item(item_id)
	if data == null:
		_battle_item_pending = false
		_on_battle_bag_closed()
		return
	var move_index: int = -1
	if data.effect == Items.EffectItem.EFFECT_ITEM_RESTORE_PP:
		var choices: Array[String] = []
		for slot: PokemonMoveSlot in player_pokemon.moves:
			var move: MoveData = MoveDatabase.get_move(slot.move_id) if slot else null
			choices.append(move.move_name if move else "---")
		move_index = await DialogueManager.choose(choices, Vector2(468, 308))
		if move_index < 0:
			_battle_item_pending = false
			_on_battle_bag_closed()
			return
	await battle.player_choose_item(item_id, player_pokemon, move_index)
	_update_ui()
	_battle_item_pending = false
	if battle.is_running and current_menu == MenuState.BUSY:
		_on_battle_bag_closed()


func _on_battle_bag_closed() -> void:
	_bag_ui = null
	if _battle_item_pending:
		return
	if battle != null and battle.is_running and current_menu == MenuState.BUSY:
		if not _force_switch_pending:
			action_menu.visible = true
			current_menu = MenuState.ACTIONS
			selected_action = 0
			_update_action_focus()
			_show_message_box("¿Qué debe hacer %s?" % player_pokemon.get_display_name())


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
	if player_pokemon == null or index < 0 or index >= player_pokemon.moves.size():
		return

	var slot: PokemonMoveSlot = player_pokemon.moves[index]
	if slot == null or slot.is_empty():
		return
	if slot.current_pp <= 0:
		_show_message("¡No quedan PP para este movimiento!")
		return

	fight_menu.visible = false
	# En multi: elegir objetivo (rivales / aliado) salvo movimientos que no lo requieren
	if battle != null and battle.is_multi_battle():
		var move_data: MoveData = MoveDatabase.get_move(slot.move_id)
		if move_data != null and _move_needs_target_select(move_data):
			await _begin_target_select(index)
			_update_selected_move_info()
			return
	current_menu = MenuState.BUSY
	await _submit_move_for_current_slot(index)
	_update_selected_move_info()


func _move_needs_target_select(move: MoveData) -> bool:
	if move == null:
		return false
	match move.target:
		MoveStruct.MoveTarget.TARGET_USER, MoveStruct.MoveTarget.TARGET_FIELD, \
		MoveStruct.MoveTarget.TARGET_BOTH, MoveStruct.MoveTarget.TARGET_ALL_BATTLERS, \
		MoveStruct.MoveTarget.TARGET_OPPONENTS_FIELD, MoveStruct.MoveTarget.TARGET_FOES_AND_ALLY, \
		MoveStruct.MoveTarget.TARGET_USER_AND_ALLY:
			return false
		_:
			return true


# ============================================================
# BARRA DE HABILIDAD
# ============================================================

func _reset_ability_bars() -> void:
	if ability_bar_player != null:
		ability_bar_player.visible = false
		ability_bar_player.position = ABILITY_POS_PLAYER_OFF
	if ability_bar_enemy != null:
		ability_bar_enemy.visible = false
		ability_bar_enemy.position = ABILITY_POS_ENEMY_OFF


func _animate_ability_icon(delta: float, icon: Sprite2D, is_player: bool) -> void:
	if icon == null or icon.texture == null:
		return
	var bar: Sprite2D = ability_bar_player if is_player else ability_bar_enemy
	if bar == null or not bar.visible:
		return
	if icon.hframes < 2:
		icon.hframes = 2
	if is_player:
		_ability_icon_timer_player += delta
		if _ability_icon_timer_player >= ability_icon_frame_time:
			_ability_icon_timer_player = 0.0
			icon.frame = 1 - icon.frame
	else:
		_ability_icon_timer_enemy += delta
		if _ability_icon_timer_enemy >= ability_icon_frame_time:
			_ability_icon_timer_enemy = 0.0
			icon.frame = 1 - icon.frame


func _on_ability_announced(is_player: bool, mon: PokemonInstance) -> void:
	_run_ability_bar(is_player, mon)


func _run_ability_bar(is_player: bool, mon: PokemonInstance) -> void:
	await show_ability_activation(is_player, mon)
	if battle != null:
		battle.ability_bar_finished.emit()


func show_ability_activation(is_player: bool, mon: PokemonInstance) -> void:
	if mon == null or ability_anim == null:
		if battle != null:
			battle.ability_bar_finished.emit()
		return

	while _ability_bar_busy:
		await get_tree().process_frame

	_ability_bar_busy = true

	var bar: Sprite2D = ability_bar_player if is_player else ability_bar_enemy
	var label: Label = ability_label_player if is_player else ability_label_enemy
	var icon: Sprite2D = ability_icon_player if is_player else ability_icon_enemy
	var anim_in: String = "Entrada_Player" if is_player else "Entrada_Enemy"
	var anim_out: String = "Salida_Player" if is_player else "Salida_Enemy"

	var ability_name: String = "???"
	if mon.ability_id != AbilityId.Id.NONE:
		ability_name = AbilityDatabase.get_ability_name(mon.ability_id)

	var pkmn_name: String = ""
	if mon.has_method("get_display_name"):
		pkmn_name = String(mon.get_display_name())
	if pkmn_name.is_empty():
		var sp0: PokemonDataStruct = mon.get_species()
		pkmn_name = sp0.species_name if sp0 != null else "???"

	if label != null:
		label.text = "%s\nde %s" % [ability_name, pkmn_name]

	if icon != null:
		var sp: PokemonDataStruct = mon.get_species()
		icon.texture = sp.icon_sprite if sp != null else null
		icon.hframes = 2
		icon.vframes = 1
		icon.frame = 0
		if is_player:
			_ability_icon_timer_player = 0.0
		else:
			_ability_icon_timer_enemy = 0.0

	# Anti-parpadeo: posición OFF → visible → animación de entrada
	if bar != null:
		bar.frame = 0 if is_player else 1
		bar.position = ABILITY_POS_PLAYER_OFF if is_player else ABILITY_POS_ENEMY_OFF
		bar.visible = true

	if ability_anim.has_animation(anim_in):
		ability_anim.play(anim_in)
		await ability_anim.animation_finished
	elif bar != null:
		bar.position = ABILITY_POS_PLAYER_ON if is_player else ABILITY_POS_ENEMY_ON

	await get_tree().create_timer(ability_bar_hold_time).timeout

	if ability_anim.has_animation(anim_out):
		ability_anim.play(anim_out)
		await ability_anim.animation_finished

	if bar != null:
		bar.visible = false
		bar.position = ABILITY_POS_PLAYER_OFF if is_player else ABILITY_POS_ENEMY_OFF

	_ability_bar_busy = false

# ============================================================
# APARIENCIA (Illusion / Imposter)
# ============================================================

func _on_battler_appearance_changed(is_player: bool) -> void:
	_refresh_side_appearance(is_player)
	_refresh_all_multi_appearances()
	# Grito solo si NO es solo Illusion (el disfraz no debe delatarse con el grito real)
	if battle == null:
		return
	var actives: Array = battle.player_actives if is_player else battle.enemy_actives
	for i: int in range(actives.size()):
		var b: BattleBattler = actives[i]
		if b == null or b.pokemon == null or b.is_fainted():
			continue
		if b.illusion_active:
			continue  # Illusion: sin grito al poner el disfraz
		_play_cry_slot(is_player, i, b.pokemon, 1.0)
		break


func _on_illusion_broken(is_player: bool) -> void:
	var sprite: Sprite2D = player_sprite if is_player else enemy_sprite
	if sprite != null:
		var old_mod: Color = sprite.modulate
		sprite.modulate = Color(1.6, 1.6, 1.6, 1.0)
		await get_tree().create_timer(0.12).timeout
		sprite.modulate = old_mod
	_refresh_side_appearance(is_player)


func _on_pokemon_entered_field(is_player: bool) -> void:
	_play_cry(is_player)


func _refresh_side_appearance(is_player: bool) -> void:
	if battle == null:
		return

	var battler: BattleBattler = battle.player if is_player else battle.enemy
	if battler == null or battler.pokemon == null:
		return

	if is_player:
		player_pokemon = battler.pokemon
	else:
		enemy_pokemon = battler.pokemon

	var mon: PokemonInstance = battler.pokemon
	var tex: Texture2D
	var offset: Vector2
	var display_name: String
	var gender: PokemonData.Gender

	if battler.illusion_active and battler.illusion_species_id != Species.SpeciesID.SPECIES_NONE:
		tex = _sprite_for_species_id(
			battler.illusion_species_id,
			battler.illusion_shiny,
			is_player
		)
		offset = _offset_for_species_id(battler.illusion_species_id, is_player)
		if not battler.illusion_nickname.is_empty():
			display_name = battler.illusion_nickname
		else:
			display_name = battler.get_display_name()
		gender = battler.illusion_gender
	else:
		var shiny: bool = false
		if "shiny" in mon:
			shiny = mon.shiny
		if is_player:
			tex = mon.get_back_sprite(shiny)
			offset = _get_back_offset_px(mon)
		else:
			tex = mon.get_front_sprite(shiny)
			offset = _get_front_offset_px(mon)
		display_name = battler.get_display_name()
		gender = mon.gender

	if is_player:
		player_sprite.texture = tex
		_player_sprite_species_offset_y = offset.y
		player_sprite.position = Vector2(
			player_sprite_base_pos.x,
			player_sprite_base_pos.y + _player_sprite_species_offset_y
		)
		if player_name_label.has_method("cambiar_texto"):
			player_name_label.cambiar_texto(display_name)
		else:
			player_name_label.text = display_name
		_set_gender(player_gender, gender)
	else:
		enemy_sprite.texture = tex
		enemy_sprite.position = Vector2(
			enemy_sprite_base_pos.x,
			enemy_sprite_base_pos.y + offset.y
		)
		if enemy_name_label.has_method("cambiar_texto"):
			enemy_name_label.cambiar_texto(display_name)
		else:
			enemy_name_label.text = display_name
		_set_gender(enemy_gender, gender)


func _sprite_for_species_id(
	species_id: Species.SpeciesID,
	shiny: bool,
	back: bool
) -> Texture2D:
	var form: PokemonFormData = SpeciesDatabase.get_form(species_id)
	if form != null and form.override_graphics:
		var form_tex: Texture2D
		if back:
			form_tex = form.back_sprite_shiny if shiny else form.back_sprite
		else:
			form_tex = form.front_sprite_shiny if shiny else form.front_sprite
		if form_tex != null:
			return form_tex

	var species: PokemonDataStruct = SpeciesDatabase.get_species(species_id)
	if species == null:
		species = SpeciesDatabase.get_base_species(species_id)
	if species == null:
		return null

	if back:
		return species.back_sprite_shiny if shiny else species.back_sprite
	return species.front_sprite_shiny if shiny else species.front_sprite


func _offset_for_species_id(species_id: Species.SpeciesID, back: bool) -> Vector2:
	var form: PokemonFormData = SpeciesDatabase.get_form(species_id)
	if form != null and form.override_graphics:
		var off: Vector2 = form.back_sprite_offset if back else form.front_sprite_offset
		return off * PokemonDataStruct.BATTLE_OFFSET_SCALE

	var species: PokemonDataStruct = SpeciesDatabase.get_species(species_id)
	if species == null:
		species = SpeciesDatabase.get_base_species(species_id)
	if species == null:
		return Vector2.ZERO

	if back:
		return species.get_back_sprite_offset_px()
	return species.get_front_sprite_offset_px()

# ============================================================
# IDLE BOB (solo en menú de acciones / movimientos)
# Estilo oficial: salto de 2 px, mon y caja independientes
# ============================================================

func _update_player_idle_bob(delta: float) -> void:
	var should_bob: bool = (
		current_menu == MenuState.ACTIONS or current_menu == MenuState.MOVES
	)

	if not should_bob:
		_bob_sprite_time = 0.0
		_bob_box_time = 0.0
		_bob_sprite_down = false
		_bob_box_down = false
		_apply_sprite_bob(false)
		_apply_box_bob(false)
		return

	# --- Sprite del jugador ---
	_bob_sprite_time += delta
	if _bob_sprite_time >= BOB_SPRITE_HALF_PERIOD:
		_bob_sprite_time = 0.0
		_bob_sprite_down = not _bob_sprite_down
		_apply_sprite_bob(_bob_sprite_down)

	# --- PlayerHPBox (ritmo distinto) ---
	_bob_box_time += delta
	if _bob_box_time >= BOB_BOX_HALF_PERIOD:
		_bob_box_time = 0.0
		_bob_box_down = not _bob_box_down
		_apply_box_bob(_bob_box_down)


func _apply_sprite_bob(down: bool) -> void:
	var y_extra: float = BOB_PIXELS if down else 0.0
	player_sprite.position = Vector2(
		player_sprite_base_pos.x,
		player_sprite_base_pos.y + _player_sprite_species_offset_y + y_extra
	)


func _apply_box_bob(down: bool) -> void:
	var y_extra: float = BOB_PIXELS if down else 0.0
	player_hp_box.position = Vector2(
		player_hp_box_base_pos.x,
		player_hp_box_base_pos.y + y_extra
	)

func _play_cry(is_player: bool, mon: PokemonInstance = null) -> void:
	var player_node: AudioStreamPlayer = cry_player if is_player else cry_enemy
	if player_node == null:
		return

	var target: PokemonInstance = mon
	if target == null:
		target = player_pokemon if is_player else enemy_pokemon
	if target == null:
		return

	# Illusion: grito del disfraz (opcional; si prefieres el real, salta esto)
	if battle != null:
		var battler: BattleBattler = battle.player if is_player else battle.enemy
		if battler != null and battler.illusion_active \
				and battler.illusion_species_id != Species.SpeciesID.SPECIES_NONE:
			var ill_sp: PokemonDataStruct = SpeciesDatabase.get_species(battler.illusion_species_id)
			if ill_sp == null:
				ill_sp = SpeciesDatabase.get_base_species(battler.illusion_species_id)
			if ill_sp != null and ill_sp.cry != null:
				player_node.stream = ill_sp.cry
				player_node.play()
				return

	var form: PokemonFormData = PokemonFormResolver.get_form(target)
	if form != null and form.override_graphics and "cry" in form and form.cry != null:
		player_node.stream = form.cry
		player_node.play()
		return

	var species: PokemonDataStruct = target.get_species()
	if species == null or species.cry == null:
		return

	player_node.stream = species.cry
	player_node.play()

func _attach_battle_weather() -> void:
	if _weather_attached:
		return
	if WeatherManager == null:
		return
	var container: Node2D = WeatherManager.get_weather_container()
	if container == null:
		return
	_weather_container_parent = container.get_parent()
	container.reparent(self)
	_fit_weather_to_battle(container)
	_weather_attached = true


## El clima del overworld está pensado para el mapa/cámara.
## En batalla lo anclamos al origen y lo escalamos al tamaño de la escena de combate.
func _fit_weather_to_battle(container: Node2D) -> void:
	if container == null:
		return
	container.position = Vector2.ZERO
	container.rotation = 0.0
	# Encima del fondo, debajo de sprites/UI (BG suele ser bajo)
	var bg_z: int = bg_sprite.z_index if bg_sprite != null else 0
	container.z_index = bg_z + 1

	# Área de batalla: preferir el tamaño del BG o del viewport del combate
	var battle_size: Vector2 = Vector2(480, 270)  # fallback típico
	if bg_sprite != null and bg_sprite.texture != null:
		var tex_size: Vector2 = Vector2(bg_sprite.texture.get_width(), bg_sprite.texture.get_height())
		if tex_size.x > 1.0 and tex_size.y > 1.0:
			battle_size = tex_size * bg_sprite.scale
	else:
		var vr: Rect2 = get_viewport().get_visible_rect()
		if vr.size.x > 1.0 and vr.size.y > 1.0:
			battle_size = vr.size

	# Si el contenedor (o un hijo tipo ColorRect/Particle) tiene un tamaño base conocido, escalar
	var base: Vector2 = Vector2.ZERO
	if container.has_method("get_rect"):
		var r: Variant = container.call("get_rect")
		if r is Rect2:
			base = (r as Rect2).size
	# Buscar ColorRect / GPUParticles2D hijos que cubran pantalla en overworld
	for child: Node in container.get_children():
		if child is ColorRect:
			var cr: ColorRect = child as ColorRect
			base = cr.size if cr.size.x > base.x else base
			cr.position = Vector2.ZERO
			cr.size = battle_size
		elif child is CPUParticles2D:
			var p: CPUParticles2D = child as CPUParticles2D
			p.position = battle_size * 0.5
			p.visibility_rect = Rect2(-battle_size * 0.5, battle_size)
			# emission_rect_extents cubre toda el área
			p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
			p.emission_rect_extents = battle_size * 0.5
		elif child is GPUParticles2D:
			var gp: GPUParticles2D = child as GPUParticles2D
			gp.position = battle_size * 0.5
			gp.visibility_rect = Rect2(-battle_size * 0.5, battle_size)

	# Escala del contenedor si tiene tamaño intrínseco distinto
	if base.x > 1.0 and base.y > 1.0:
		container.scale = Vector2(battle_size.x / base.x, battle_size.y / base.y)
	else:
		container.scale = Vector2.ONE

	# Visible y al frente del BG en el árbol
	container.visible = true
	move_child(container, bg_sprite.get_index() + 1 if bg_sprite != null else 0)


func _detach_battle_weather() -> void:
	if not _weather_attached:
		return
	var container: Node2D = WeatherManager.get_weather_container() if WeatherManager != null else null
	if container != null and is_instance_valid(container):
		WeatherManager.set_weather(WeatherEffect.WeatherID.WEATHER_NONE)
		# Restaurar transform por si el overworld lo necesita limpio
		container.position = Vector2.ZERO
		container.scale = Vector2.ONE
		if _weather_container_parent != null and is_instance_valid(_weather_container_parent):
			container.reparent(_weather_container_parent)
		else:
			WeatherManager.add_child(container)
		if bg_sprite != null:
			container.z_index = bg_sprite.z_index
	_weather_attached = false
	_weather_container_parent = null

func _on_battle_weather_changed(weather: int, _primal: bool) -> void:
	if WeatherManager == null:
		return
	if battle != null and battle.is_weather_suppressed():
		WeatherManager.set_weather(WeatherEffect.WeatherID.WEATHER_NONE)
		return

	match weather:
		AbilityBattleEffect.weatherAbilityID.WEATHER_RAIN:
			WeatherManager.set_weather(WeatherEffect.WeatherID.WEATHER_RAIN)
		AbilityBattleEffect.weatherAbilityID.WEATHER_SNOW:
			WeatherManager.set_weather(WeatherEffect.WeatherID.WEATHER_SNOW)
		AbilityBattleEffect.weatherAbilityID.WEATHER_SANDSTORM:
			WeatherManager.set_weather(WeatherEffect.WeatherID.WEATHER_SANDSTORM)
		AbilityBattleEffect.weatherAbilityID.WEATHER_DROUGHT:
			WeatherManager.set_weather(WeatherEffect.WeatherID.WEATHER_DROUGHT)
		_:
			WeatherManager.set_weather(WeatherEffect.WeatherID.WEATHER_NONE)

	# Tras cambiar el clima, reajustar cobertura a toda la pantalla de batalla
	if _weather_attached:
		var container: Node2D = WeatherManager.get_weather_container()
		if container != null:
			_fit_weather_to_battle(container)


# ============================================================
# MULTI BATTLE UI (duplicar sprites + HP boxes)

# ============================================================
# MULTI BATTLE UI (nodos de escena)
# ============================================================

func _setup_multi_battle_ui() -> void:
	# Enlazar nodos 2 de la escena (posiciones del editor = base)
	player_sprite_b = player_sprite_2
	enemy_sprite_b = enemy_sprite_2
	player_hp_box_b = player_hp_box_2
	enemy_hp_box_b = enemy_hp_box_2

	if player_sprite_b != null:
		player_sprite_b_base_pos = player_sprite_b.position
	if enemy_sprite_b != null:
		enemy_sprite_b_base_pos = enemy_sprite_b.position
	if enemy_hp_box != null:
		enemy_hp_box_base_pos = enemy_hp_box.position

	var multi: bool = battle != null and battle.is_multi_battle()
	_multi_ui_ready = multi

	var show_p2: bool = multi and battle != null and battle._player_slot_count() >= 2
	var show_e2: bool = multi and battle != null and battle._enemy_slot_count() >= 2
	_set_slot2_visible(show_p2, show_e2)

	_apply_layout_positions(multi)
	_input_actor_slot = 0
	_input_target_slot = 0
	_faint_animating.clear()
	_clear_all_focus_mods()


func _set_slot2_visible(show_player2: bool, show_enemy2: bool) -> void:
	if player_sprite_b != null:
		player_sprite_b.visible = show_player2
	if player_hp_box_b != null:
		player_hp_box_b.visible = show_player2
	if enemy_sprite_b != null:
		enemy_sprite_b.visible = show_enemy2
	if enemy_hp_box_b != null:
		enemy_hp_box_b.visible = show_enemy2


func _apply_layout_positions(multi: bool) -> void:
	# Sprites principales: solo cambia X (Y lo pone el offset del .tres al refrescar)
	if player_sprite != null:
		player_sprite_base_pos.x = POS_PLAYER_X_DOUBLE if multi else POS_PLAYER_X_SINGLE
		player_sprite.position.x = player_sprite_base_pos.x
	if enemy_sprite != null:
		enemy_sprite_base_pos.x = POS_ENEMY_X_DOUBLE if multi else POS_ENEMY_X_SINGLE
		enemy_sprite.position.x = enemy_sprite_base_pos.x
	# Slot 2: posición base = la de la escena (capturada en _ready / setup)
	# Solo se le suma el offset Y del .tres al refrescar apariencia
	# HP boxes principales: solo cambia Y
	if player_hp_box != null:
		player_hp_box_base_pos.y = POS_PLAYER_HP_Y_DOUBLE if multi else POS_PLAYER_HP_Y_SINGLE
		player_hp_box.position.y = player_hp_box_base_pos.y
	if enemy_hp_box != null:
		enemy_hp_box_base_pos.y = POS_ENEMY_HP_Y_DOUBLE if multi else POS_ENEMY_HP_Y_SINGLE
		enemy_hp_box.position.y = enemy_hp_box_base_pos.y


func _begin_player_command_phase() -> void:
	if battle == null:
		return
	_input_actor_slot = _next_conscious_player_slot(0)
	if _input_actor_slot < 0:
		_input_actor_slot = 0
	_input_target_slot = _default_target_slot()
	_pending_move_index = -1
	_apply_actor_focus()
	_sync_player_pokemon_ref_from_slot()
	action_menu.visible = true
	fight_menu.visible = false
	current_menu = MenuState.ACTIONS
	selected_action = 0
	_update_action_focus()
	var pname: String = player_pokemon.get_display_name() if player_pokemon else "???"
	_show_message_box("¿Qué debe hacer %s?" % pname)


func _next_conscious_player_slot(from_slot: int) -> int:
	if battle == null:
		return 0
	for i: int in range(from_slot, battle.player_actives.size()):
		var b: BattleBattler = battle.player_actives[i]
		if b != null and b.pokemon != null and not b.is_fainted():
			return i
	return -1


func _default_target_slot() -> int:
	if battle == null:
		return 0
	for i: int in range(battle.enemy_actives.size()):
		var b: BattleBattler = battle.enemy_actives[i]
		if b != null and b.pokemon != null and not b.is_fainted():
			return i
	return 0


func _sync_player_pokemon_ref_from_slot() -> void:
	if battle == null:
		return
	if _input_actor_slot < 0 or _input_actor_slot >= battle.player_actives.size():
		if battle.player != null:
			player_pokemon = battle.player.pokemon
		return
	var b: BattleBattler = battle.player_actives[_input_actor_slot]
	if b != null and b.pokemon != null:
		player_pokemon = b.pokemon


func _clear_all_focus_mods() -> void:
	for s: Sprite2D in [player_sprite, player_sprite_b, enemy_sprite, enemy_sprite_b,
			player_hp_box, player_hp_box_b, enemy_hp_box, enemy_hp_box_b]:
		if s != null and s.visible:
			s.modulate = NORMAL_MOD


func _reset_hp_box_layers() -> void:
	for box: Sprite2D in [player_hp_box, player_hp_box_b, enemy_hp_box, enemy_hp_box_b]:
		if box != null:
			box.z_index = Z_HP_NORMAL


func _animate_tracked_hp_bars(delta: float) -> void:
	if _hp_bar_anim_targets.is_empty():
		return
	var done: Array[int] = []
	for id: Variant in _hp_bar_anim_targets.keys():
		var bar_id: int = int(id)
		var bar: ColorRect = instance_from_id(bar_id) as ColorRect
		if bar == null or not is_instance_valid(bar):
			done.append(bar_id)
			continue
		var target_w: float = float(_hp_bar_anim_targets[bar_id])
		if absf(bar.size.x - target_w) > 0.5:
			bar.size.x = move_toward(bar.size.x, target_w, HP_ANIM_SPEED * delta)
		else:
			bar.size.x = target_w
			done.append(bar_id)
		bar.color = _hp_color(bar.size.x / maxf(PLAYER_HP_BAR_MAX_WIDTH, 1.0))
	for bar_id2: int in done:
		_hp_bar_anim_targets.erase(bar_id2)

## Turno del jugador: solo HP boxes (focus + capa). Los sprites NO se oscurecen.
func _apply_actor_focus() -> void:
	_clear_all_focus_mods()
	_reset_hp_box_layers()
	# 1v1: resaltar la HP box del jugador
	if battle == null or not battle.is_multi_battle():
		if player_hp_box != null:
			player_hp_box.modulate = FOCUS_MOD
			player_hp_box.z_index = Z_HP_FOCUS
		return
	for slot: int in range(2):
		var box: Sprite2D = _hp_box_for_slot(true, slot)
		if box == null or not box.visible:
			continue
		var active: bool = (slot == _input_actor_slot)
		box.modulate = FOCUS_MOD if active else UNFOCUS_MOD
		box.z_index = Z_HP_FOCUS if active else Z_HP_BACK


## Solo al elegir objetivo: focus en sprites (y HP del objetivo).
func _apply_target_focus() -> void:
	_clear_all_focus_mods()
	_reset_hp_box_layers()
	if not _multi_ui_ready:
		return
	# HP del mon que está eligiendo sigue arriba
	var actor_box: Sprite2D = _hp_box_for_slot(true, _input_actor_slot)
	if actor_box != null and actor_box.visible:
		actor_box.modulate = FOCUS_MOD
		actor_box.z_index = Z_HP_FOCUS
	# Rivales: sprite + hpbox
	for slot: int in range(2):
		var spr: Sprite2D = _sprite_for_slot(false, slot)
		var box: Sprite2D = _hp_box_for_slot(false, slot)
		var sel: bool = (_input_target_slot == slot)
		if spr != null and spr.visible:
			spr.modulate = FOCUS_MOD if sel else UNFOCUS_MOD
		if box != null and box.visible:
			box.modulate = FOCUS_MOD if sel else UNFOCUS_MOD
			box.z_index = Z_HP_FOCUS if sel else Z_HP_BACK
	# Aliado
	var ally_slot: int = 1 if _input_actor_slot == 0 else 0
	var ally_spr: Sprite2D = _sprite_for_slot(true, ally_slot)
	var ally_box: Sprite2D = _hp_box_for_slot(true, ally_slot)
	var ally_sel: bool = (_input_target_slot == -2)
	if ally_spr != null and ally_spr.visible:
		ally_spr.modulate = FOCUS_MOD if ally_sel else UNFOCUS_MOD
	if ally_box != null and ally_box.visible:
		ally_box.modulate = FOCUS_MOD if ally_sel else UNFOCUS_MOD
		ally_box.z_index = Z_HP_FOCUS if ally_sel else Z_HP_BACK


func _target_options() -> Array[int]:
	## Lista de ids de objetivo: 0/1 = rival, -2 = aliado si existe
	var opts: Array[int] = []
	if battle == null:
		return opts
	for i: int in range(battle.enemy_actives.size()):
		var b: BattleBattler = battle.enemy_actives[i]
		if b != null and b.pokemon != null and not b.is_fainted():
			opts.append(i)
	var ally: BattleBattler = battle.get_ally(battle.player_actives[_input_actor_slot]) if _input_actor_slot < battle.player_actives.size() else null
	if ally != null and not ally.is_fainted():
		opts.append(-2)
	return opts


func _begin_target_select(move_index: int) -> void:
	_pending_move_index = move_index
	var opts: Array[int] = _target_options()
	if opts.is_empty():
		await _submit_move_for_current_slot(move_index)
		return
	# Si solo hay un objetivo posible y no es multi, enviar directo
	if opts.size() == 1 and not battle.is_multi_battle():
		_input_target_slot = opts[0]
		await _submit_move_for_current_slot(move_index)
		return
	_input_target_slot = opts[0]
	current_menu = MenuState.TARGET
	fight_menu.visible = false
	action_menu.visible = false
	_apply_target_focus()
	_show_target_prompt()


func _show_target_prompt() -> void:
	var name: String = "???"
	if _input_target_slot == -2:
		var ally_slot: int = 1 if _input_actor_slot == 0 else 0
		if battle != null and ally_slot < battle.player_actives.size():
			var ab: BattleBattler = battle.player_actives[ally_slot]
			if ab != null:
				name = ab.get_display_name()
		_show_message_box("¿Atacar a tu aliado %s?" % name)
	else:
		if battle != null and _input_target_slot >= 0 and _input_target_slot < battle.enemy_actives.size():
			var eb: BattleBattler = battle.enemy_actives[_input_target_slot]
			if eb != null:
				name = eb.get_display_name()
		_show_message_box("¿Atacar a %s?" % name)


func _cycle_target_slot(dir: int = 1) -> void:
	var opts: Array[int] = _target_options()
	if opts.size() <= 1:
		return
	var idx: int = opts.find(_input_target_slot)
	if idx < 0:
		idx = 0
	idx = (idx + dir) % opts.size()
	if idx < 0:
		idx += opts.size()
	_input_target_slot = opts[idx]
	_apply_target_focus()
	_show_target_prompt()


func _handle_target_input(event: InputEvent) -> void:
	if event.is_action_pressed("Right") or event.is_action_pressed("Down"):
		_cycle_target_slot(1)
	elif event.is_action_pressed("Left") or event.is_action_pressed("Up"):
		_cycle_target_slot(-1)
	elif event.is_action_pressed("buttonA"):
		var move_i: int = _pending_move_index
		_pending_move_index = -1
		current_menu = MenuState.BUSY
		_clear_all_focus_mods()
		await _submit_move_for_current_slot(move_i)
	elif event.is_action_pressed("buttonB"):
		_pending_move_index = -1
		current_menu = MenuState.MOVES
		fight_menu.visible = true
		_apply_actor_focus()
		_update_move_focus()
		_show_message_box("¿Qué ataque usará %s?" % (player_pokemon.get_display_name() if player_pokemon else "???"))


func _refresh_all_multi_appearances() -> void:
	if battle == null:
		return
	_refresh_slot_appearance(true, 0)
	_refresh_slot_appearance(false, 0)
	if battle._player_slot_count() >= 2:
		_refresh_slot_appearance(true, 1)
	if battle._enemy_slot_count() >= 2:
		_refresh_slot_appearance(false, 1)
	_update_multi_hp_boxes()



func _sprite_base_pos(is_player: bool, slot: int) -> Vector2:
	if is_player:
		return player_sprite_base_pos if slot == 0 else player_sprite_b_base_pos
	return enemy_sprite_base_pos if slot == 0 else enemy_sprite_b_base_pos


func _sprite_for_slot(is_player: bool, slot: int) -> Sprite2D:
	if is_player:
		return player_sprite if slot == 0 else player_sprite_b
	return enemy_sprite if slot == 0 else enemy_sprite_b


func _hp_box_for_slot(is_player: bool, slot: int) -> Sprite2D:
	if is_player:
		return player_hp_box if slot == 0 else player_hp_box_b
	return enemy_hp_box if slot == 0 else enemy_hp_box_b


func _cry_for_slot(is_player: bool, slot: int) -> AudioStreamPlayer:
	if is_player:
		return cry_player if slot == 0 else cry_player_2
	return cry_enemy if slot == 0 else cry_enemy_2


func _refresh_slot_appearance(is_player: bool, slot: int) -> void:
	if battle == null:
		return
	var actives: Array = battle.player_actives if is_player else battle.enemy_actives  # Array[BattleBattler]
	if slot < 0 or slot >= actives.size():
		return
	var battler: BattleBattler = actives[slot]
	var sprite: Sprite2D = _sprite_for_slot(is_player, slot)
	var box: Sprite2D = _hp_box_for_slot(is_player, slot)
	if battler == null or battler.pokemon == null:
		if sprite != null:
			sprite.visible = false
		if box != null:
			box.visible = false
		return
	if battler.is_fainted():
		# Animación de KO si aún no se hizo
		var key: String = ("p" if is_player else "e") + str(slot)
		if not _faint_animating.get(key, false):
			_faint_animating[key] = true
			_play_faint_animation(is_player, slot, battler)
		return
	if sprite != null:
		sprite.visible = true
		var mon: PokemonInstance = battler.pokemon
		var offset: Vector2 = Vector2.ZERO
		var tex: Texture2D = null
		# Illusion: sprite/offset del disfraz
		if battler.illusion_active and battler.illusion_species_id >= 0:
			tex = _sprite_for_species_id(
				battler.illusion_species_id as Species.SpeciesID,
				battler.illusion_shiny,
				is_player
			)
			offset = _offset_for_species_id(
				battler.illusion_species_id as Species.SpeciesID,
				is_player
			)
		elif is_player:
			tex = mon.get_back_sprite() if mon.has_method("get_back_sprite") else null
			offset = _get_back_offset_px(mon)
		else:
			tex = mon.get_front_sprite() if mon.has_method("get_front_sprite") else null
			offset = _get_front_offset_px(mon)
		sprite.texture = tex
		var base: Vector2 = _sprite_base_pos(is_player, slot)
		sprite.position = Vector2(base.x, base.y + offset.y)
		if is_player and slot == 0:
			_player_sprite_species_offset_y = offset.y
	if box != null:
		box.visible = true
		_fill_hp_box_labels(box, battler, is_player)


func _fill_hp_box_labels(box: Sprite2D, battler: BattleBattler, is_player: bool) -> void:
	if box == null or battler == null or battler.pokemon == null:
		return
	var mon: PokemonInstance = battler.pokemon
	var name_l: Label = box.get_node_or_null("NamePkmnPlayer") as Label
	if name_l == null:
		name_l = box.get_node_or_null("NamePkmnEnemy") as Label
	if name_l != null:
		if name_l.has_method("cambiar_texto"):
			name_l.cambiar_texto(battler.get_display_name())
		else:
			name_l.text = battler.get_display_name()
	var level_l: Label = box.get_node_or_null("Level") as Label
	if level_l != null:
		level_l.text = str(mon.level)
	var hp_l: Label = box.get_node_or_null("HP") as Label
	if hp_l != null:
		hp_l.text = "%d/%d" % [mon.current_hp, mon.max_hp]
	var bar: ColorRect = box.get_node_or_null("HpBar") as ColorRect
	if bar != null:
		var max_w: float = PLAYER_HP_BAR_MAX_WIDTH if is_player else ENEMY_HP_BAR_MAX_WIDTH
		var ratio: float = float(mon.current_hp) / float(maxi(mon.max_hp, 1))
		var target_w: float = max_w * clampf(ratio, 0.0, 1.0)
		_hp_bar_anim_targets[bar.get_instance_id()] = target_w
		# Si es la primera vez (ancho 0 o casi), saltar animación
		if bar.size.x <= 0.01 or absf(bar.size.x - target_w) > max_w * 0.95:
			bar.size.x = target_w
		bar.color = _hp_color(bar.size.x / maxf(max_w, 1.0))
	var gender_l: Label = box.get_node_or_null("Genero") as Label
	if gender_l != null:
		_set_gender(gender_l, mon.gender)
	var status_s: Sprite2D = box.get_node_or_null("Status") as Sprite2D
	if status_s != null:
		StatusConditions.apply_icon_from_pokemon(status_s, mon)


func _update_multi_hp_boxes() -> void:
	if battle == null:
		return
	for side_player: bool in [true, false]:
		var actives: Array = battle.player_actives if side_player else battle.enemy_actives
		for i: int in range(actives.size()):
			var b: BattleBattler = actives[i]
			if b != null and b.pokemon != null and not b.is_fainted():
				_fill_hp_box_labels(_hp_box_for_slot(side_player, i), b, side_player)

	_update_exp_bar()


func _play_cry_slot(is_player: bool, slot: int, mon: PokemonInstance = null, pitch: float = 1.0) -> void:
	var node: AudioStreamPlayer = _cry_for_slot(is_player, slot)
	if node == null:
		# Fallback slot 0
		node = cry_player if is_player else cry_enemy
	if node == null:
		return
	var target: PokemonInstance = mon
	if target == null and battle != null:
		var actives: Array = battle.player_actives if is_player else battle.enemy_actives  # Array[BattleBattler]
		if slot < actives.size() and actives[slot] != null:
			target = actives[slot].pokemon
	if target == null:
		return
	var species: PokemonDataStruct = target.get_species() if target.has_method("get_species") else null
	var form: PokemonFormData = null
	if target.has_method("get_species") or true:
		form = PokemonFormResolver.get_form(target)
	if form != null and form.override_graphics and "cry" in form and form.cry != null:
		node.stream = form.cry
	elif species != null and species.cry != null:
		node.stream = species.cry
	else:
		return
	node.pitch_scale = pitch
	node.play()


func _play_faint_animation(is_player: bool, slot: int, battler: BattleBattler) -> void:
	var sprite: Sprite2D = _sprite_for_slot(is_player, slot)
	var box: Sprite2D = _hp_box_for_slot(is_player, slot)
	# 1) Esperar a que la barra de PS llegue a 0 visualmente
	await _wait_hp_bar_drained(is_player, slot)
	# 2) Grito (un poco más lento) y esperar a que termine
	if battler != null and battler.pokemon != null:
		await _play_cry_slot_and_wait(is_player, slot, battler.pokemon, 0.88)
	# 3) Animación: baja y desaparece
	if sprite != null:
		var start_y: float = sprite.position.y
		var tween: Tween = create_tween()
		tween.tween_property(sprite, "position:y", start_y + 48.0, 0.45)
		tween.parallel().tween_property(sprite, "modulate:a", 0.0, 0.45)
		await tween.finished
		sprite.visible = false
		sprite.modulate.a = 1.0
		sprite.position.y = start_y
	if box != null:
		box.visible = false


func _wait_hp_bar_drained(is_player: bool, slot: int) -> void:
	var box: Sprite2D = _hp_box_for_slot(is_player, slot)
	var bar: ColorRect = null
	if box != null:
		bar = box.get_node_or_null("HpBar") as ColorRect
	if bar == null:
		if is_player and slot == 0:
			bar = player_hp_bar
		elif (not is_player) and slot == 0:
			bar = enemy_hp_bar
	if bar == null:
		await get_tree().create_timer(0.15).timeout
		return
	# Esperar hasta que la barra visual esté ~0 (máx 2s)
	var elapsed: float = 0.0
	while bar.size.x > 0.75 and elapsed < 2.0:
		await get_tree().process_frame
		elapsed += get_process_delta_time()
	await get_tree().create_timer(0.08).timeout


func _play_cry_slot_and_wait(is_player: bool, slot: int, mon: PokemonInstance, pitch: float = 1.0) -> void:
	_play_cry_slot(is_player, slot, mon, pitch)
	var node: AudioStreamPlayer = _cry_for_slot(is_player, slot)
	if node == null:
		node = cry_player if is_player else cry_enemy
	if node == null or node.stream == null:
		await get_tree().create_timer(0.35).timeout
		return
	# Duración del stream / pitch
	var dur: float = 0.5
	if node.stream is AudioStream:
		var st: AudioStream = node.stream
		if st.has_method("get_length"):
			dur = maxf(0.25, float(st.get_length()) / maxf(pitch, 0.01))
	await get_tree().create_timer(dur + 0.05).timeout


func _submit_move_for_current_slot(move_index: int) -> void:
	if battle == null:
		return
	current_menu = MenuState.BUSY
	action_menu.visible = false
	fight_menu.visible = false
	await battle.player_choose_move(move_index, _input_actor_slot, _input_target_slot)

	if not battle.is_running:
		return
	if not battle.is_multi_battle():
		_clear_all_focus_mods()
		return

	var needed: int = 0
	for b: BattleBattler in battle.player_actives:
		if b != null and b.pokemon != null and not b.is_fainted():
			needed += 1
	if battle._pending_player_actions.size() > 0 and battle._pending_player_actions.size() < needed:
		var next_slot: int = _next_conscious_player_slot(_input_actor_slot + 1)
		if next_slot >= 0:
			_input_actor_slot = next_slot
			_sync_player_pokemon_ref_from_slot()
			_apply_actor_focus()
			action_menu.visible = true
			current_menu = MenuState.ACTIONS
			selected_action = 0
			_update_action_focus()
			_show_message_box("¿Qué debe hacer %s?" % player_pokemon.get_display_name())
			if has_method("_fill_move_buttons"):
				_fill_move_buttons()
	else:
		_clear_all_focus_mods()
