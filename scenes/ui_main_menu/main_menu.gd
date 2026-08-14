extends Node2D
class_name MainMenu

const RANURAS_TOTALES: int = 3
const ESCENA_OVERWORLD: String = "res://data_core/map/position_game/gestor_inicio.tscn"

@onready var btn_continue: TextureButton = $Continue
@onready var btn_new_game: TextureButton = $NewGame
@onready var btn_option: TextureButton = $Options
@onready var lbl_mapa: Label = $Continue/Map
@onready var lbl_tiempo: Label = $Continue/Time
@onready var lbl_nombre: Label = $Continue/Name
@onready var lbl_dex: Label = $Continue/Pokedex
@onready var lbl_medallas: Label = $Continue/Badges
@onready var sfx_mover: AudioStreamPlayer = $SFX_Move
@onready var sfx_aceptar: AudioStreamPlayer = $SFX_Action

var indice_foco: int = 0
var ranura_actual: int = 1
var _transitioning: bool = false


func _ready() -> void:
	btn_continue.pressed.connect(func() -> void: _seleccionar_con_mouse(0))
	btn_new_game.pressed.connect(func() -> void: _seleccionar_con_mouse(1))
	btn_option.pressed.connect(func() -> void: _seleccionar_con_mouse(2))
	actualizar_foco_visual()
	actualizar_info_ranura()


func _input(event: InputEvent) -> void:
	if _transitioning or not event.is_pressed() or event.is_echo():
		return
	if event.is_action_pressed("Up"):
		navegar(-1)
	elif event.is_action_pressed("Down"):
		navegar(1)
	elif event.is_action_pressed("Left"):
		if indice_foco == 0:
			cambiar_ranura(-1)
	elif event.is_action_pressed("Right"):
		if indice_foco == 0:
			cambiar_ranura(1)
	elif event.is_action_pressed("buttonA"):
		ejecutar_accion()


func navegar(paso: int) -> void:
	var anterior: int = indice_foco
	indice_foco = clampi(indice_foco + paso, 0, 2)
	if indice_foco != anterior and sfx_mover:
		sfx_mover.play()
	actualizar_foco_visual()
	actualizar_info_ranura()


func cambiar_ranura(paso: int) -> void:
	var anterior: int = ranura_actual
	ranura_actual = wrapi(ranura_actual + paso, 1, RANURAS_TOTALES + 1)
	if ranura_actual != anterior and sfx_mover:
		sfx_mover.play()
	actualizar_info_ranura()


func actualizar_foco_visual() -> void:
	btn_continue.modulate = Color(1, 1, 1) if indice_foco == 0 else Color(0.6, 0.6, 0.6)
	btn_new_game.modulate = Color(1, 1, 1) if indice_foco == 1 else Color(0.6, 0.6, 0.6)
	btn_option.modulate = Color(1, 1, 1) if indice_foco == 2 else Color(0.6, 0.6, 0.6)


func actualizar_info_ranura() -> void:
	if indice_foco != 0:
		_limpiar_info()
		return
	var datos: Dictionary = SaveManager.get_slot_data(ranura_actual)
	if datos.is_empty():
		lbl_mapa.text = "Ranura %d vacía" % ranura_actual
		lbl_tiempo.text = "--:--:--"
		lbl_nombre.text = "---"
		lbl_dex.text = "Dex ---"
		lbl_medallas.text = "Badges ---"
		return
	var segundos: int = int(float(datos.get("play_seconds", 0.0)))
	lbl_mapa.text = str(datos.get("map_name", "Sin mapa"))
	lbl_tiempo.text = "%02d:%02d:%02d" % [segundos / 3600.0, (segundos % 3600) / 60.0, segundos % 60]
	lbl_nombre.text = str(datos.get("player_name", "Sin nombre"))
	lbl_dex.text = "Dex ---"
	lbl_medallas.text = "Badges ---"


func _limpiar_info() -> void:
	lbl_mapa.text = ""
	lbl_tiempo.text = ""
	lbl_nombre.text = ""
	lbl_dex.text = ""
	lbl_medallas.text = ""


func ejecutar_accion() -> void:
	if sfx_aceptar:
		sfx_aceptar.play()
	match indice_foco:
		0:
			if SaveManager.request_load(ranura_actual):
				_cambiar_a_partida()
		1:
			SaveManager.start_new_game(ranura_actual)
			_cambiar_a_partida()
		2:
			print("Opciones: próximamente")


func _seleccionar_con_mouse(nuevo_foco: int) -> void:
	if _transitioning:
		return
	indice_foco = nuevo_foco
	actualizar_foco_visual()
	actualizar_info_ranura()
	ejecutar_accion()


func _cambiar_a_partida() -> void:
	_transitioning = true
	TransicionManager.cambiar_escena(ESCENA_OVERWORLD, 0.5)
