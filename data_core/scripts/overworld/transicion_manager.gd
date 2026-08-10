extends CanvasLayer

@export var duracion: float = 0.5


var _pantalla: ColorRect
var _transicionando: bool = false


func _ready() -> void:

	layer = 4001
	visible = true

	crear_pantalla()


func crear_pantalla() -> void:

	if has_node("Pantalla"):

		_pantalla = $Pantalla

	else:

		_pantalla = ColorRect.new()
		_pantalla.name = "Pantalla"
		add_child(_pantalla)

	_pantalla.color = Color.BLACK
	_pantalla.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pantalla.z_index = 4096

	_pantalla.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)

	_pantalla.modulate.a = 0.0


func fade_out(
	tiempo: float = duracion
) -> Signal:

	if _transicionando:
		return get_tree().process_frame

	_transicionando = true
	visible = true

	_pantalla.modulate.a = 0.0

	var tween: Tween = create_tween()

	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_SINE)

	tween.tween_property(
		_pantalla,
		"modulate:a",
		1.0,
		tiempo
	)

	return tween.finished


func fade_in(
	tiempo: float = duracion
) -> Signal:

	visible = true

	var tween: Tween = create_tween()

	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_SINE)

	tween.tween_property(
		_pantalla,
		"modulate:a",
		0.0,
		tiempo
	)

	tween.finished.connect(
		_finalizar_transicion,
		CONNECT_ONE_SHOT
	)

	return tween.finished


func cambiar_escena(
	ruta_escena: String,
	tiempo: float = duracion
) -> void:

	if _transicionando:
		return

	_transicionando = true
	visible = true

	_pantalla.modulate.a = 0.0

	var tween: Tween = create_tween()

	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_SINE)

	# -------------------------------------------------------
	# FADE OUT
	# -------------------------------------------------------

	tween.tween_property(
		_pantalla,
		"modulate:a",
		1.0,
		tiempo
	)

	# -------------------------------------------------------
	# CAMBIO DE ESCENA
	# -------------------------------------------------------

	tween.tween_callback(
		func() -> void:

			var resultado: int = (
				get_tree().change_scene_to_file(
					ruta_escena
				)
			)

			if resultado != OK:

				push_error(
					"TransitionManager: "
					+ "No se pudo cargar la escena: "
					+ ruta_escena
				)

				_finalizar_transicion()
	)

	# Esperamos un frame para asegurarnos de que
	# la nueva escena ya fue colocada.
	tween.tween_callback(
		func() -> void:
			pass
	)

	tween.tween_interval(0.05)

	# -------------------------------------------------------
	# FADE IN
	# -------------------------------------------------------

	tween.tween_property(
		_pantalla,
		"modulate:a",
		0.0,
		tiempo
	)

	tween.tween_callback(
		_finalizar_transicion
	)


func _finalizar_transicion() -> void:

	_transicionando = false
	visible = false


func esta_transicionando() -> bool:

	return _transicionando
