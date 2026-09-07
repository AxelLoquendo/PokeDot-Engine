extends Control
class_name MultichoiceBox

signal choice_selected(index: int, choice_id: String)
@warning_ignore("unused_signal")
signal cancelled()

@onready var window: NinePatchRect = $ChoiceWindow
@onready var margin: MarginContainer = $ChoiceWindow/MarginContainer
@onready var scroll: ScrollContainer = $ChoiceWindow/MarginContainer/ScrollContainer
@onready var options_container: VBoxContainer = $ChoiceWindow/MarginContainer/ScrollContainer/OptionsContainer
@onready var cursor: TextureRect = $ChoiceWindow/Cursor

@export var font_color: Color = Color(0.31, 0.31, 0.31, 1.0)
@export var font_shadow_color: Color = Color(0.8, 0.8, 0.8, 1.0)
@export var max_visible_options: int = 8
@export var cursor_left_margin: int = 14
@export var cursor_x: float = 6.0

const FONT_PATH: String = "res://pokemon-emerald-pro.ttf"
const FONT_SIZE: int = 32
# Debe ser >= alto real de la fuente (32) + un poco de aire
const LINE_HEIGHT: int = 36
const PADDING_X: int = 8
const PADDING_Y: int = 12
const MIN_WIDTH: int = 80
const SEPARATION: int = 4

var _choices: Array[DialogueChoice] = []
var _labels: Array[Label] = []
var _current_index: int = 0
var _active: bool = false
var _font: FontFile = null
var _show_call_id: int = 0
var _busy: bool = false  # evita doble A/B en el mismo frame

var _last_input_frame: int = -1

func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_INHERIT
	_font = load(FONT_PATH) as FontFile
	if _font == null:
		push_error("No se pudo cargar la fuente: %s" % FONT_PATH)

	if cursor != null:
		cursor.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cursor.visible = false
		cursor.z_index = 10

	margin.add_theme_constant_override("margin_left", cursor_left_margin + PADDING_X)
	margin.add_theme_constant_override("margin_right", PADDING_X)
	margin.add_theme_constant_override("margin_top", PADDING_Y)
	margin.add_theme_constant_override("margin_bottom", PADDING_Y)
	options_container.add_theme_constant_override("separation", SEPARATION)


func _input(event: InputEvent) -> void:
	if not _active or _busy:
		return
	if event.is_echo():
		return

	# Un solo manejo por frame (evita A+B fantasma)
	var frame: int = Engine.get_process_frames()
	if frame == _last_input_frame:
		return

	# Usamos el estado global del Input Map (más fiable que el event suelto)
	if Input.is_action_just_pressed("Up"):
		_last_input_frame = frame
		_move_cursor(-1)
		get_viewport().set_input_as_handled()
		return

	if Input.is_action_just_pressed("Down"):
		_last_input_frame = frame
		_move_cursor(1)
		get_viewport().set_input_as_handled()
		return

	if Input.is_action_just_pressed("buttonA"):
		_last_input_frame = frame
		_confirm_choice()
		get_viewport().set_input_as_handled()
		return

	if Input.is_action_just_pressed("buttonB"):
		_last_input_frame = frame
		_cancel()
		get_viewport().set_input_as_handled()
		return

func show_choices(
	choices: Array[DialogueChoice],
	menu_pos: Vector2 = Vector2(-1, -1),
	_use_anchor_bottom: bool = true
) -> void:
	if choices.is_empty():
		push_warning("MultichoiceBox: 0 opciones")
		return

	_show_call_id += 1
	var call_id: int = _show_call_id
	_busy = false

	_choices = choices
	_clear_options()
	_create_options()
	_resize_window()

	await get_tree().process_frame
	if call_id != _show_call_id:
		return
	await get_tree().process_frame
	if call_id != _show_call_id:
		return

	if menu_pos.x >= 0.0 and menu_pos.y >= 0.0:
		_place_menu(menu_pos)

	_current_index = 0
	_active = true
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = true
	if cursor != null:
		cursor.visible = true

	# Esperar un frame más para que los Label tengan global_rect real
	await get_tree().process_frame
	if call_id != _show_call_id:
		return
	_update_cursor()


func hide_menu() -> void:
	_show_call_id += 1
	_active = false
	_busy = false
	process_mode = Node.PROCESS_MODE_INHERIT
	visible = false
	if cursor != null:
		cursor.visible = false
	_clear_options()
	_choices.clear()


func _cancel() -> void:
	if _busy or not _active:
		return
	_busy = true
	_active = false

	# Cancel = misma señal, índice -1 (NO usamos signal cancelled)
	hide_menu()
	choice_selected.emit(-1, "")


func _create_options() -> void:
	for i: int in range(_choices.size()):
		var choice: DialogueChoice = _choices[i]
		var label: Label = Label.new()
		label.name = "Option_%d" % i
		label.text = choice.text
		label.mouse_filter = Control.MOUSE_FILTER_STOP
		label.custom_minimum_size = Vector2(0, LINE_HEIGHT)
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

		if _font != null:
			label.add_theme_font_override("font", _font)
			label.add_theme_font_size_override("font_size", FONT_SIZE)
		label.add_theme_color_override("font_color", font_color)
		label.add_theme_color_override("font_shadow_color", font_shadow_color)
		label.add_theme_constant_override("shadow_offset_x", 1)
		label.add_theme_constant_override("shadow_offset_y", 1)

		var idx: int = i
		label.gui_input.connect(func(ev: InputEvent) -> void:
			if not _active or _busy:
				return
			if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
				_current_index = idx
				_confirm_choice()
		)

		options_container.add_child(label)
		_labels.append(label)


func _clear_options() -> void:
	for label: Label in _labels:
		label.queue_free()
	_labels.clear()


func _resize_window() -> void:
	if _font == null or _choices.is_empty():
		return

	var max_text_width: int = 0
	for choice: DialogueChoice in _choices:
		var text_size: Vector2 = _font.get_string_size(
			choice.text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE
		)
		max_text_width = maxi(max_text_width, int(text_size.x))

	var content_width: int = maxi(max_text_width + cursor_left_margin + PADDING_X * 2 + 4, MIN_WIDTH)
	var visible_count: int = mini(_choices.size(), max_visible_options)
	var content_height: int = (
		visible_count * LINE_HEIGHT
		+ maxi(visible_count - 1, 0) * SEPARATION
		+ PADDING_Y * 2
	)

	window.size = Vector2(content_width, content_height)
	scroll.custom_minimum_size = Vector2(
		content_width - cursor_left_margin - PADDING_X * 2,
		content_height - PADDING_Y * 2
	)
	scroll.size = scroll.custom_minimum_size
	options_container.custom_minimum_size = Vector2(
		scroll.custom_minimum_size.x,
		_choices.size() * LINE_HEIGHT + maxi(_choices.size() - 1, 0) * SEPARATION
	)


func _place_menu(anchor: Vector2) -> void:
	var menu_size: Vector2 = window.size
	var target_x: float = anchor.x - menu_size.x
	var target_y: float = anchor.y - menu_size.y
	var vp: Vector2 = get_viewport().get_visible_rect().size
	target_x = clampf(target_x, 4.0, vp.x - menu_size.x - 4.0)
	target_y = clampf(target_y, 4.0, vp.y - menu_size.y - 4.0)
	global_position = Vector2(target_x, target_y)


func _move_cursor(direction: int) -> void:
	if _labels.is_empty():
		return
	_current_index = wrapi(_current_index + direction, 0, _labels.size())
	_ensure_cursor_visible()
	_update_cursor()


func _update_cursor() -> void:
	if cursor == null or _labels.is_empty():
		return
	if _current_index < 0 or _current_index >= _labels.size():
		return

	var label: Label = _labels[_current_index]
	# Rect global real de la opción → local del ChoiceWindow
	var label_rect: Rect2 = label.get_global_rect()
	var window_origin: Vector2 = window.global_position
	var local_y: float = label_rect.position.y - window_origin.y
	local_y += (label_rect.size.y - cursor.size.y) * 0.5

	cursor.position = Vector2(cursor_x, local_y)


func _ensure_cursor_visible() -> void:
	if scroll == null or _labels.is_empty():
		return
	scroll.ensure_control_visible(_labels[_current_index])
	call_deferred("_update_cursor")


func _confirm_choice() -> void:
	if _busy or not _active:
		return
	if _current_index < 0 or _current_index >= _choices.size():
		return

	_busy = true
	_active = false

	var index: int = _current_index
	var id: String = _choices[_current_index].choice_id

	# Emitir ANTES de hide_menu (evita perder listeners)
	choice_selected.emit(index, id)
	hide_menu()
