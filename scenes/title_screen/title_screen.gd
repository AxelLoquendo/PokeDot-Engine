extends Node2D

#----------------------
# Ajustes del parpadeo
#----------------------
const TIEMPO_PARPADEO: float = 1.6
var _tween_parpadeo: Tween
var _activo: bool = true


func _ready() -> void:
	CloudsManager.desactivar()
	DnsManager.desactivar()

	$Fondo.position = Vector2(240, 160)
	$TextoInicio.modulate.a = 1.0

	_iniciar_parpadeo()

	$MusicaTitulo.play()

func _iniciar_parpadeo() -> void:
	if not _activo: return

	_tween_parpadeo = create_tween()
	_tween_parpadeo.set_ease(Tween.EASE_IN_OUT)
	_tween_parpadeo.set_trans(Tween.TRANS_SINE)
	
	_tween_parpadeo.set_loops()

	_tween_parpadeo.tween_property($TextoInicio, "modulate:a", 0.25, TIEMPO_PARPADEO)
	_tween_parpadeo.tween_property($TextoInicio, "modulate:a", 1.0, TIEMPO_PARPADEO)


func _input(event: InputEvent) -> void:
	if not _activo: return

	if event.is_action_pressed("buttonStart"):
		_empezar_juego()

func _empezar_juego() -> void:
	if not _activo: return
	_activo = false

	_tween_parpadeo.kill()
	$MusicaTitulo.stop()

	TransicionManager.cambiar_escena("res://data_core/map/position_game/gestor_inicio.tscn", 0.5)
