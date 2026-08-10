extends Node2D

#---------------
# Configuración
#---------------
const TIEMPO_APARICION: float = 1.0
const TIEMPO_ESPERA: float = 2.0
const TIEMPO_DESVANECIMIENTO: float = 1.0

var _activo: bool = true
var _tween: Tween


func _ready() -> void:
	CloudsManager.desactivar()
	DnsManager.desactivar()

	$Creditos.modulate.a = 0.0
	$Creditos.position = Vector2(145, 110)

	_iniciar_secuencia()


func _iniciar_secuencia() -> void:
	_tween = create_tween().set_ease(Tween.EASE_IN_OUT)

	_tween.tween_property($Creditos, "modulate:a", 1.0, TIEMPO_APARICION)

	_tween.tween_interval(TIEMPO_ESPERA)

	_tween.tween_property($Creditos, "modulate:a", 0.0, TIEMPO_DESVANECIMIENTO)

	_tween.tween_callback(_ir_a_titulo)


func _input(event: InputEvent) -> void:
	if not _activo: return

	if event.is_action_pressed("buttonStart"):
			_ir_a_titulo()


func _ir_a_titulo() -> void:
	if not _activo: return
	_activo = false
	TransicionManager.cambiar_escena("res://scenes/title_screen/title_screen.tscn", 0.5)
