extends Control
class_name MultichoiceBox

signal choice_selected(index: int, choice_id: String)
signal cancelled()

@onready var window: NinePatchRect = $ChoiceWindow
@onready var options_container: VBoxContainer = $ChoiceWindow/MarginContainer/OptionsContainer
@onready var cursor: TextureRect = $ChoiceWindow/MarginContainer/Cursor

const FONT_PATH: String = "res://pokemon-emerald-pro.ttf"
const FONT_SIZE: int = 32
const LINE_HEIGHT: int = 18
const PADDING_X: int = 20
const PADDING_Y: int = 12
const CURSOR_OFFSET_X: int = -14
const MIN_WIDTH: int = 64

var _choices: Array[DialogueChoice] = []
var _buttons: Array[Button] = []
var _current_index: int = 0
var _active: bool = false
var _font: FontFile = null

# Token para evitar condiciones de carrera si show_choices()/hide_menu()
# se llaman muy seguido mientras esperamos el process_frame.
var _show_call_id: int = 0


func _ready() -> void:
	visible = false
	_font = load(FONT_PATH) as FontFile
	if _font == null:
		push_error("No se pudo cargar la fuente: %s" % FONT_PATH)
	
	if cursor != null:
		cursor.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cursor.visible = false


func _unhandled_input(event: InputEvent) -> void:
	if not _active:
		return
	
	if event.is_action_pressed("ui_up") or event.is_action_pressed("ui_down"):
		var direction: int = -1 if event.is_action_pressed("ui_up") else 1
		_move_cursor(direction)
		get_viewport().set_input_as_handled()
	
	elif event.is_action_pressed("ui_accept"):
		_confirm_choice()
		get_viewport().set_input_as_handled()
	
	elif event.is_action_pressed("ui_cancel"):
		# Opcional: descomenta si quieres cancelar con B
		# cancelled.emit()
		# hide_menu()
		get_viewport().set_input_as_handled()


# ============================================================
# API PÚBLICA
# ============================================================

## anchor.y es la coordenada que el FONDO de la ventana no debe cruzar
## (p. ej. el borde superior de la caja de diálogo). anchor.x es la
## coordenada X de la esquina izquierda de la ventana. Pasa (-1, -1)
## para no reposicionar nada.
func show_choices(choices: Array[DialogueChoice], position: Vector2 = Vector2(-1, -1), anchor_bottom: bool = false) -> void:
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
	
	if position.x >= 0.0 and position.y >= 0.0:
		if anchor_bottom:
			# 'position' es el punto inferior-izquierdo deseado (justo
			# encima de la caja de diálogo). Ahora que window.size ya
			# está calculado, subimos la ventana su propia altura.
			global_position = Vector2(position.x, position.y - window.size.y)
		else:
			global_position = position
	
	_current_index = 0
	_update_cursor()
	
	visible = true
	_active = true
	if cursor != null:
		cursor.visible = true


func hide_menu() -> void:
	_show_call_id += 1  # invalida cualquier show_choices() en vuelo
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
		
		if _font != null:
			btn.add_theme_font_override("font", _font)
			btn.add_theme_font_size_override("font_size", FONT_SIZE)
		
		# Quitar estilos visuales nativos del Button
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
	
	var content_width: int = maxi(max_text_width + PADDING_X * 2, MIN_WIDTH)
	content_width += absi(CURSOR_OFFSET_X)
	
	# El VBoxContainer añade su propio "separation" entre elementos (por
	# defecto no es 0). Si no lo sumamos, la ventana queda más chica que
	# el contenido real y la última opción se corta.
	var separation: int = options_container.get_theme_constant("separation")
	var content_height: int = (
		_choices.size() * LINE_HEIGHT
		+ maxi(_choices.size() - 1, 0) * separation
		+ PADDING_Y * 2
	)
	
	window.size = Vector2(content_width, content_height)
	options_container.custom_minimum_size = Vector2(
		content_width - PADDING_X,
		content_height - PADDING_Y
	)


func _move_cursor(direction: int) -> void:
	if _buttons.is_empty():
		return
	
	_current_index = wrapi(_current_index + direction, 0, _buttons.size())
	_update_cursor()


func _update_cursor() -> void:
	if _buttons.is_empty() or cursor == null:
		return
	
	var target_btn: Button = _buttons[_current_index]
	cursor.position = Vector2(
		CURSOR_OFFSET_X,
		target_btn.position.y + (target_btn.size.y - cursor.size.y) * 0.5
	)


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
