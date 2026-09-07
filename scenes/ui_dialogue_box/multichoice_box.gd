extends Control
class_name MultichoiceBox

signal choice_selected(index: int, choice_id: String)
signal cancelled()

@onready var window: NinePatchRect = $ChoiceWindow
@onready var margin: MarginContainer = $ChoiceWindow/MarginContainer
@onready var scroll: ScrollContainer = $ChoiceWindow/MarginContainer/ScrollContainer
@onready var options_container: VBoxContainer = $ChoiceWindow/MarginContainer/ScrollContainer/OptionsContainer
@onready var cursor: TextureRect = $ChoiceWindow/Cursor   # ← YA NO está dentro del MarginContainer

# --- Configuración exportable (Inspector) ---
@export var font_color: Color = Color(0.31, 0.31, 0.31, 1.0)          # color del texto
@export var font_shadow_color: Color = Color(0.8, 0.8, 0.8, 1.0)     # sombra suave
@export var max_visible_options: int = 8                             # a partir de aquí hace scroll
@export var cursor_left_margin: int = 14                             # espacio reservado para el cursor

const FONT_PATH: String = "res://pokemon-emerald-pro.ttf"
const FONT_SIZE: int = 32
const LINE_HEIGHT: int = 20
const PADDING_X: int = 8
const PADDING_Y: int = 10
const MIN_WIDTH: int = 80
const SEPARATION: int = 2

var _choices: Array[DialogueChoice] = []
var _buttons: Array[Button] = []
var _current_index: int = 0
var _active: bool = false
var _font: FontFile = null
var _show_call_id: int = 0


func _ready() -> void:
	visible = false
	_font = load(FONT_PATH) as FontFile
	if _font == null:
		push_error("No se pudo cargar la fuente: %s" % FONT_PATH)

	if cursor != null:
		cursor.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cursor.visible = false
		cursor.z_index = 10

	# Márgenes fijos: izquierda grande para el cursor, resto pequeño
	margin.add_theme_constant_override("margin_left", cursor_left_margin + PADDING_X)
	margin.add_theme_constant_override("margin_right", PADDING_X)
	margin.add_theme_constant_override("margin_top", PADDING_Y)
	margin.add_theme_constant_override("margin_bottom", PADDING_Y)

	options_container.add_theme_constant_override("separation", SEPARATION)


func _unhandled_input(event: InputEvent) -> void:
	if not _active:
		return

	if event.is_action_pressed("Up") or event.is_action_pressed("Down"):
		var direction: int = -1 if event.is_action_pressed("Up") else 1
		_move_cursor(direction)
		get_viewport().set_input_as_handled()

	elif event.is_action_pressed("buttonA"):
		_confirm_choice()
		get_viewport().set_input_as_handled()

	elif event.is_action_pressed("buttonB"):
		# Descomenta si quieres poder cancelar con B
		# cancelled.emit()
		# hide_menu()
		get_viewport().set_input_as_handled()


# ============================================================
# API PÚBLICA
# ============================================================

## position = punto ancla (normalmente esquina superior-derecha de la caja de diálogo).
## El menú se coloca con su esquina inferior-derecha pegada a ese punto
## (a la derecha y arriba, estilo pokeemerald expansion).
func show_choices(choices: Array[DialogueChoice], position: Vector2 = Vector2(-1, -1), anchor_bottom: bool = true) -> void:
	if choices.is_empty():
		push_warning("MultichoiceBox: se recibieron 0 opciones")
		return

	_show_call_id += 1
	var call_id: int = _show_call_id

	_choices = choices
	_clear_buttons()
	_create_buttons()
	_resize_window()

	await get_tree().process_frame
	if call_id != _show_call_id:
		return

	# Esperamos un frame más para que los tamaños reales de los botones estén listos
	await get_tree().process_frame
	if call_id != _show_call_id:
		return

	if position.x >= 0.0 and position.y >= 0.0:
		_place_menu(position, anchor_bottom)

	_current_index = 0
	_update_cursor()
	_ensure_cursor_visible()

	visible = true
	_active = true
	if cursor != null:
		cursor.visible = true


func hide_menu() -> void:
	_show_call_id += 1
	_active = false
	visible = false
	if cursor != null:
		cursor.visible = false
	_clear_buttons()
	_choices.clear()


# ============================================================
# INTERNO
# ============================================================

func _create_buttons() -> void:
	for i: int in range(_choices.size()):
		var choice: DialogueChoice = _choices[i]
		var btn: Button = Button.new()
		btn.name = "Option_%d" % i
		btn.text = choice.text
		btn.flat = true
		btn.focus_mode = Control.FOCUS_NONE
		btn.mouse_filter = Control.MOUSE_FILTER_STOP
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.custom_minimum_size = Vector2(0, LINE_HEIGHT)

		if _font != null:
			btn.add_theme_font_override("font", _font)
			btn.add_theme_font_size_override("font_size", FONT_SIZE)

		# Color de letra (exportable)
		btn.add_theme_color_override("font_color", font_color)
		btn.add_theme_color_override("font_hover_color", font_color)
		btn.add_theme_color_override("font_pressed_color", font_color)
		btn.add_theme_color_override("font_focus_color", font_color)
		btn.add_theme_color_override("font_shadow_color", font_shadow_color)
		btn.add_theme_constant_override("shadow_offset_x", 1)
		btn.add_theme_constant_override("shadow_offset_y", 1)

		# Quitar estilos nativos del Button
		var empty_style: StyleBoxEmpty = StyleBoxEmpty.new()
		btn.add_theme_stylebox_override("normal", empty_style)
		btn.add_theme_stylebox_override("hover", empty_style)
		btn.add_theme_stylebox_override("pressed", empty_style)
		btn.add_theme_stylebox_override("focus", empty_style)

		btn.pressed.connect(_on_button_pressed.bind(i))
		options_container.add_child(btn)
		_buttons.append(btn)


func _clear_buttons() -> void:
	for btn: Button in _buttons:
		btn.queue_free()
	_buttons.clear()


func _resize_window() -> void:
	if _font == null or _choices.is_empty():
		return

	var max_text_width: int = 0
	for choice: DialogueChoice in _choices:
		var text_size: Vector2 = _font.get_string_size(
			choice.text,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			FONT_SIZE
		)
		max_text_width = maxi(max_text_width, int(text_size.x))

	# Ancho total = texto + espacio del cursor + paddings
	var content_width: int = maxi(max_text_width + cursor_left_margin + PADDING_X * 2 + 4, MIN_WIDTH)

	# Altura: máximo max_visible_options líneas + paddings
	var visible_count: int = mini(_choices.size(), max_visible_options)
	var content_height: int = (
		visible_count * LINE_HEIGHT
		+ maxi(visible_count - 1, 0) * SEPARATION
		+ PADDING_Y * 2
	)

	window.size = Vector2(content_width, content_height)

	# El ScrollContainer debe ocupar todo el margen
	scroll.custom_minimum_size = Vector2(
		content_width - cursor_left_margin - PADDING_X * 2,
		content_height - PADDING_Y * 2
	)
	scroll.size = scroll.custom_minimum_size

	# Si hay más opciones de las visibles, el VBox puede crecer
	options_container.custom_minimum_size = Vector2(
		scroll.custom_minimum_size.x,
		_choices.size() * LINE_HEIGHT + maxi(_choices.size() - 1, 0) * SEPARATION
	)


func _place_menu(anchor: Vector2, anchor_bottom: bool) -> void:
	# anchor = esquina superior-derecha de la caja de diálogo (o el punto que nos pasen)
	# Queremos que la esquina inferior-derecha del menú quede justo encima de ese punto.
	var menu_size: Vector2 = window.size
	var target_x: float = anchor.x - menu_size.x          # alineado a la derecha
	var target_y: float = anchor.y - menu_size.y          # arriba de la caja

	# Seguridad: no salirse de la pantalla
	var vp: Vector2 = get_viewport().get_visible_rect().size
	target_x = clampf(target_x, 4.0, vp.x - menu_size.x - 4.0)
	target_y = clampf(target_y, 4.0, vp.y - menu_size.y - 4.0)

	global_position = Vector2(target_x, target_y)


func _move_cursor(direction: int) -> void:
	if _buttons.is_empty():
		return

	_current_index = wrapi(_current_index + direction, 0, _buttons.size())
	_update_cursor()
	_ensure_cursor_visible()


func _update_cursor() -> void:
	if _buttons.is_empty() or cursor == null:
		return

	var target_btn: Button = _buttons[_current_index]

	# Convertimos la posición global del botón a local del ChoiceWindow
	var btn_global: Vector2 = target_btn.global_position
	var window_global: Vector2 = window.global_position
	var local_y: float = btn_global.y - window_global.y + (target_btn.size.y - cursor.size.y) * 0.5

	cursor.position = Vector2(
		4,                          # un poco a la izquierda del texto
		local_y
	)


func _ensure_cursor_visible() -> void:
	if _buttons.is_empty() or scroll == null:
		return

	var target_btn: Button = _buttons[_current_index]
	# Hacemos que el ScrollContainer muestre el botón seleccionado
	scroll.ensure_control_visible(target_btn)


func _confirm_choice() -> void:
	if _current_index < 0 or _current_index >= _choices.size():
		return

	var choice: DialogueChoice = _choices[_current_index]
	var index: int = _current_index
	var id: String = choice.choice_id

	hide_menu()
	choice_selected.emit(index, id)


func _on_button_pressed(index: int) -> void:
	_current_index = index
	_confirm_choice()
