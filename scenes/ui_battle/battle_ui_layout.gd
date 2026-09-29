extends RefCounted
class_name BattleUILayout
## Resuelve nodos de UI según la estructura del commit 9e8ce44:
##
## battle.tscn (1v1):
##   BattleMonSprites/Pkmn_Player | Pkmn_Enemy
##   BattleHPBox/PlayerHPBox | EnemyHPBox
##   BattleBox/{TextBox, ActionBattle, Overlay_Fight}
##   BattleTriggers/...
##
## battle_double.tscn (multi):
##   BattleMonSprites/Pkmn_First_Player | Pkmn_Second_Player
##                    Pkmn_First_Enemy  | Pkmn_Second_Enemy
##   BattleHPBox/Player_First_HPBox | Player_Second_HPBox
##              Enemy_First_HPBox   | Enemy_Second_HPBox
##   BattleBox + BattleTriggers (igual)
##
## La UI no debe hardcodear rutas planas ($Pkmn_Player): usa este layout.


class SlotView:
	var sprite: Sprite2D = null
	var cry: AudioStreamPlayer = null
	var hp_box: Sprite2D = null
	var name_label: Label = null
	var level_label: Label = null
	var hp_label: Label = null
	var hp_bar: ColorRect = null
	var exp_bar: ColorRect = null
	var gender_label: Label = null
	var status_sprite: Sprite2D = null
	var indicator: Sprite2D = null
	var base_sprite_pos: Vector2 = Vector2.ZERO
	var base_box_pos: Vector2 = Vector2.ZERO


var root: Node = null
var is_double_scene: bool = false

var player_slots: Array[SlotView] = []
var enemy_slots: Array[SlotView] = []

var bg: Sprite2D = null
var battle_box: Node = null
var text_box: Control = null
var battle_text: Label = null
var battle_normal_text: Label = null
var action_menu: Control = null
var action_buttons: Array[TextureButton] = []
var fight_menu: Sprite2D = null
var move_buttons: Array[TextureButton] = []
var move_pp_label: Label = null
var move_type_sprite: Sprite2D = null
var ability_bar_player: Sprite2D = null
var ability_bar_enemy: Sprite2D = null
var ability_anim: AnimationPlayer = null


static func bind(root_node: Node) -> BattleUILayout:
	var layout: BattleUILayout = BattleUILayout.new()
	layout.root = root_node
	layout._detect_and_bind()
	return layout


func _detect_and_bind() -> void:
	# Detectar escena por nombre de nodo raíz o por presencia de Second slots
	is_double_scene = (
		root.name == "Battle_Double"
		or root.get_node_or_null("BattleMonSprites/Pkmn_Second_Player") != null
		or root.get_node_or_null("BattleHPBox/Player_Second_HPBox") != null
	)

	bg = root.get_node_or_null("BG") as Sprite2D
	battle_box = root.get_node_or_null("BattleBox")
	# Menús: bajo BattleBox (estructura nueva) o en raíz (legado)
	var menu_root: Node = battle_box if battle_box != null else root

	text_box = menu_root.get_node_or_null("TextBox") as Control
	if text_box == null:
		text_box = root.get_node_or_null("TextBox") as Control
	battle_text = _find_label(text_box, "BattleText")
	battle_normal_text = _find_label(text_box, "BattleNormalText")

	action_menu = menu_root.get_node_or_null("ActionBattle") as Control
	if action_menu == null:
		action_menu = root.get_node_or_null("ActionBattle") as Control
	_bind_action_buttons()

	fight_menu = menu_root.get_node_or_null("Overlay_Fight") as Sprite2D
	if fight_menu == null:
		fight_menu = root.get_node_or_null("Overlay_Fight") as Sprite2D
	_bind_move_buttons()
	if fight_menu != null:
		move_pp_label = fight_menu.get_node_or_null("PP/Number_PP") as Label
		move_type_sprite = fight_menu.get_node_or_null("Type") as Sprite2D

	var triggers: Node = root.get_node_or_null("BattleTriggers")
	if triggers != null:
		ability_bar_player = triggers.get_node_or_null("Ability_Bar_Player") as Sprite2D
		ability_bar_enemy = triggers.get_node_or_null("Ability_Bar_Enemy") as Sprite2D
		ability_anim = triggers.get_node_or_null("Animated_Ability_Bar") as AnimationPlayer

	if is_double_scene:
		_bind_double_slots()
	else:
		_bind_single_slots()


func _bind_single_slots() -> void:
	player_slots.clear()
	enemy_slots.clear()

	var p: SlotView = SlotView.new()
	p.sprite = _sprite_path([
		"BattleMonSprites/Pkmn_Player",
		"Pkmn_Player",
	])
	p.cry = _cry_under(p.sprite, "Cry_Mon_Player")
	p.hp_box = _sprite_path([
		"BattleHPBox/PlayerHPBox",
		"PlayerHPBox",
	])
	_fill_box_children(p, true)
	player_slots.append(p)

	var e: SlotView = SlotView.new()
	e.sprite = _sprite_path([
		"BattleMonSprites/Pkmn_Enemy",
		"Pkmn_Enemy",
	])
	e.cry = _cry_under(e.sprite, "Cry_Mon_Enemy")
	e.hp_box = _sprite_path([
		"BattleHPBox/EnemyHPBox",
		"EnemyHPBox",
	])
	_fill_box_children(e, false)
	enemy_slots.append(e)

	# Slot 1 vacío en singles (API uniforme)
	player_slots.append(SlotView.new())
	enemy_slots.append(SlotView.new())


func _bind_double_slots() -> void:
	player_slots.clear()
	enemy_slots.clear()

	player_slots.append(_make_slot(
		"BattleMonSprites/Pkmn_First_Player",
		"Cry_Mon_Player",
		"BattleHPBox/Player_First_HPBox",
		true
	))
	player_slots.append(_make_slot(
		"BattleMonSprites/Pkmn_Second_Player",
		"Cry_Mon_Player",
		"BattleHPBox/Player_Second_HPBox",
		true
	))
	enemy_slots.append(_make_slot(
		"BattleMonSprites/Pkmn_First_Enemy",
		"Cry_Mon_Enemy",
		"BattleHPBox/Enemy_First_HPBox",
		false
	))
	enemy_slots.append(_make_slot(
		"BattleMonSprites/Pkmn_Second_Enemy",
		"Cry_Mon_Enemy",
		"BattleHPBox/Enemy_Second_HPBox",
		false
	))


func _make_slot(
	sprite_path: String,
	cry_name: String,
	box_path: String,
	is_player: bool
) -> SlotView:
	var s: SlotView = SlotView.new()
	s.sprite = root.get_node_or_null(sprite_path) as Sprite2D
	s.cry = _cry_under(s.sprite, cry_name)
	s.hp_box = root.get_node_or_null(box_path) as Sprite2D
	_fill_box_children(s, is_player)
	if s.sprite != null:
		s.base_sprite_pos = s.sprite.position
	if s.hp_box != null:
		s.base_box_pos = s.hp_box.position
	return s


func _fill_box_children(s: SlotView, is_player: bool) -> void:
	if s.hp_box == null:
		return
	if is_player:
		s.name_label = s.hp_box.get_node_or_null("NamePkmnPlayer") as Label
	else:
		s.name_label = s.hp_box.get_node_or_null("NamePkmnEnemy") as Label
	s.level_label = s.hp_box.get_node_or_null("Level") as Label
	s.hp_label = s.hp_box.get_node_or_null("HP") as Label
	s.hp_bar = s.hp_box.get_node_or_null("HpBar") as ColorRect
	if s.hp_label == null:
		s.hp_label = s.hp_box.get_node_or_null("HpText") as Label
	if s.hp_label == null:
		s.hp_label = s.hp_box.get_node_or_null("HP") as Label
	s.exp_bar = s.hp_box.get_node_or_null("ExpBar") as ColorRect
	s.gender_label = s.hp_box.get_node_or_null("Genero") as Label
	s.status_sprite = s.hp_box.get_node_or_null("Status") as Sprite2D
	s.indicator = s.hp_box.get_node_or_null("Indicador") as Sprite2D
	if s.sprite != null:
		s.base_sprite_pos = s.sprite.position
	s.base_box_pos = s.hp_box.position


func player_slot(i: int) -> SlotView:
	if i < 0 or i >= player_slots.size():
		return SlotView.new()
	return player_slots[i]


func enemy_slot(i: int) -> SlotView:
	if i < 0 or i >= enemy_slots.size():
		return SlotView.new()
	return enemy_slots[i]


func slot(is_player: bool, i: int) -> SlotView:
	return player_slot(i) if is_player else enemy_slot(i)


func set_slot_visible(is_player: bool, i: int, visible: bool) -> void:
	var s: SlotView = slot(is_player, i)
	if s.sprite != null:
		s.sprite.visible = visible
	if s.hp_box != null:
		s.hp_box.visible = visible


func hide_secondary_slots() -> void:
	set_slot_visible(true, 1, false)
	set_slot_visible(false, 1, false)


# ─── helpers ────────────────────────────────────────────────────────

func _sprite_path(candidates: PackedStringArray) -> Sprite2D:
	for path: String in candidates:
		var n: Node = root.get_node_or_null(path)
		if n is Sprite2D:
			return n as Sprite2D
	return null


func _cry_under(sprite: Sprite2D, child_name: String) -> AudioStreamPlayer:
	if sprite == null:
		return null
	return sprite.get_node_or_null(child_name) as AudioStreamPlayer


func _find_label(parent: Node, child: String) -> Label:
	if parent == null:
		return null
	return parent.get_node_or_null(child) as Label


func _bind_action_buttons() -> void:
	action_buttons.clear()
	if action_menu == null:
		return
	var grid: Node = action_menu.get_node_or_null("GridContainer")
	if grid == null:
		return
	for name: String in ["Fight", "Bag", "Pkmn", "Run"]:
		var btn: TextureButton = grid.get_node_or_null(name) as TextureButton
		if btn != null:
			action_buttons.append(btn)


func _bind_move_buttons() -> void:
	move_buttons.clear()
	if fight_menu == null:
		return
	var grid: Node = fight_menu.get_node_or_null("Moves/GridContainer")
	if grid == null:
		return
	for name: String in ["Move", "Move2", "Move3", "Move4"]:
		var btn: TextureButton = grid.get_node_or_null(name) as TextureButton
		if btn != null:
			move_buttons.append(btn)
