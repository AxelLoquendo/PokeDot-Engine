extends CanvasLayer
class_name PokedexUI

signal pokedex_closed

@onready var label_seen_regional: Label = $Seen/VBoxContainer/Number_Regional
@onready var label_seen_national: Label = $Seen/VBoxContainer/Number_Nacional
@onready var label_caught_regional: Label = $Caught/VBoxContainer/Number_Regional
@onready var label_caught_national: Label = $Caught/VBoxContainer/Number_Nacional

@onready var option_regional: Label = $Dex/VBoxContainer/Regional
@onready var option_nacional: Label = $Dex/VBoxContainer/Nacional
@onready var option_salir: Label = $Dex/VBoxContainer/Salir
@onready var cursor: TextureRect = $Dex/Cursor

enum Option { REGIONAL, NACIONAL, SALIR }

var _player_data: CharacterPlayer = null
var _pokedex: PokedexData = null
var _index: int = 0
var _options: Array[Label] = []
var _active: bool = false
var _list_ui: Node = null

var jugador_bloqueado: CharacterController = null

const CURSOR_X: float = -20.0  # ajusta si hace falta


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_options = [option_regional, option_nacional, option_salir]
	visible = true


func setup(player_data: CharacterPlayer) -> void:
	_player_data = player_data

	# Siempre tener un PokedexData válido
	if _player_data != null:
		if _player_data.pokedex == null:
			_player_data.pokedex = PokedexData.new()
		_pokedex = _player_data.pokedex
	else:
		_pokedex = PokedexData.new()

	_bloquear_jugador()
	_refresh_counts()
	_index = 0
	_active = true
	_update_cursor()


func _bloquear_jugador() -> void:
	var jugador: CharacterController = (
		get_tree().get_first_node_in_group("player") as CharacterController
	)
	if jugador == null:
		return

	jugador_bloqueado = jugador
	jugador.set_process(false)
	jugador.set_physics_process(false)          # ← esto es lo que frena el movimiento
	jugador.set_process_input(false)
	jugador.set_process_unhandled_input(false)


func _desbloquear_jugador() -> void:
	if jugador_bloqueado == null:
		return
	if not is_instance_valid(jugador_bloqueado):
		jugador_bloqueado = null
		return

	jugador_bloqueado.set_process(true)
	jugador_bloqueado.set_physics_process(true)
	jugador_bloqueado.set_process_input(true)
	jugador_bloqueado.set_process_unhandled_input(true)
	jugador_bloqueado = null

func _refresh_counts() -> void:
	if _pokedex == null:
		_pokedex = PokedexData.new()

	var index: Array[Dictionary] = SpeciesDatabase.get_dex_index()
	var seen_nat : int = 0
	var owned_nat : int = 0
	var seen_reg : int = 0
	var owned_reg : int = 0

	for e: Dictionary in index:
		var sid: int = int(e["id"])
		var nat: int = int(e["national"])
		var in_regional: bool = nat >= 1 and nat <= 151

		if _pokedex.is_seen(sid):
			seen_nat += 1
			if in_regional:
				seen_reg += 1
		if _pokedex.is_owned(sid):
			owned_nat += 1
			if in_regional:
				owned_reg += 1

	label_seen_regional.text = "%04d" % seen_reg
	label_seen_national.text = "%04d" % seen_nat
	label_caught_regional.text = "%04d" % owned_reg
	label_caught_national.text = "%04d" % owned_nat

func _input(event: InputEvent) -> void:
	if not _active or _list_ui != null:
		return
	if event.is_echo():
		return

	if Input.is_action_just_pressed("Up"):
		_index = wrapi(_index - 1, 0, _options.size())
		_update_cursor()
		get_viewport().set_input_as_handled()
	elif Input.is_action_just_pressed("Down"):
		_index = wrapi(_index + 1, 0, _options.size())
		_update_cursor()
		get_viewport().set_input_as_handled()
	elif Input.is_action_just_pressed("buttonA"):
		_confirm()
		get_viewport().set_input_as_handled()
	elif Input.is_action_just_pressed("buttonB"):
		_close()
		get_viewport().set_input_as_handled()


func _update_cursor() -> void:
	if cursor == null or _options.is_empty():
		return
	var opt: Label = _options[_index]
	cursor.global_position = Vector2(
		opt.global_position.x + CURSOR_X,
		opt.global_position.y + (opt.size.y - cursor.size.y) * 0.5
	)


func _confirm() -> void:
	match _index:
		Option.REGIONAL:
			_open_list(false)  # regional
		Option.NACIONAL:
			_open_list(true)   # national
		Option.SALIR:
			_close()


func _open_list(is_national: bool) -> void:
	_active = false
	var packed: PackedScene = load("res://scenes/ui_pokedex/pokedex_list.tscn") as PackedScene
	if packed == null:
		push_error("PokedexUI: no se pudo cargar pokedex_list.tscn")
		_active = true
		return
	_list_ui = packed.instantiate()
	get_parent().add_child(_list_ui)
	if _list_ui.has_method("setup"):
		_list_ui.call("setup", _player_data, _pokedex, is_national)
	if _list_ui.has_signal("list_closed"):
		_list_ui.connect("list_closed", _on_list_closed)
	visible = false


func _on_list_closed() -> void:
	if is_instance_valid(_list_ui):
		_list_ui.queue_free()
	_list_ui = null
	visible = true
	_active = true
	_refresh_counts()
	_update_cursor()


func _close() -> void:
	_active = false
	_desbloquear_jugador()
	pokedex_closed.emit()
	queue_free()
