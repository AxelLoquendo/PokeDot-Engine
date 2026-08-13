extends Node2D

const TIEMPO_PARPADEO: float = 1.6

var _tween_parpadeo: Tween
var _activo: bool = true
var _transicionando: bool = false


func _ready() -> void:
	set_process_input(true)
	CloudsManager.desactivar()
	DnsManager.desactivar()
	$Fondo.position = Vector2(240, 160)
	$TextoInicio.modulate.a = 1.0
	_iniciar_parpadeo()
	$MusicaTitulo.play()


func _iniciar_parpadeo() -> void:
	if not _activo:
		return
	_tween_parpadeo = create_tween()
	_tween_parpadeo.set_ease(Tween.EASE_IN_OUT)
	_tween_parpadeo.set_trans(Tween.TRANS_SINE)
	_tween_parpadeo.set_loops()
	_tween_parpadeo.tween_property($TextoInicio, "modulate:a", 0.25, TIEMPO_PARPADEO)
	_tween_parpadeo.tween_property($TextoInicio, "modulate:a", 1.0, TIEMPO_PARPADEO)


func _input(event: InputEvent) -> void:
	if not _activo or _transicionando or event.is_echo() or not event.is_pressed():
		return
	if event.is_action_pressed("buttonStart"):
		_empezar_juego()
		get_viewport().set_input_as_handled()


func _empezar_juego() -> void:
	# No desactiva esta pantalla mientras un fundido anterior siga vivo.
	if _transicionando or TransicionManager.esta_transicionando():
		return
	_transicionando = true
	_activo = false
	set_process_input(false)
	if _tween_parpadeo:
		_tween_parpadeo.kill()
	$MusicaTitulo.stop()
	TransicionManager.cambiar_escena("res://scenes/ui_main_menu/main_menu.tscn", 0.5)
