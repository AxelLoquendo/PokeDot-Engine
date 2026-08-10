extends CanvasLayer
class_name TransitionManager


@export var duracion: float = 0.5


var _pantalla: ColorRect
var _transicionando: bool = false


func _ready() -> void:

	layer = 4000

	visible = true


	if has_node("Pantalla"):

		_pantalla = $Pantalla

	else:

		_pantalla = ColorRect.new()

		_pantalla.name = "Pantalla"

		add_child(_pantalla)


	_pantalla.set_anchors_preset(
		Control.PRESET_FULL_RECT
	)

	_pantalla.color = Color.BLACK

	_pantalla.modulate.a = 0.0

	_pantalla.mouse_filter = Control.MOUSE_FILTER_IGNORE

	_pantalla.z_index = 4096


func fade_out(
	tiempo: float = duracion
) -> Signal:

	if _transicionando:

		return get_tree().process_frame


	_transicionando = true

	visible = true

	_pantalla.modulate.a = 0.0


	var tween: Tween = create_tween()

	tween.set_ease(
		Tween.EASE_IN_OUT
	)

	tween.set_trans(
		Tween.TRANS_SINE
	)

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

	tween.set_ease(
		Tween.EASE_IN_OUT
	)

	tween.set_trans(
		Tween.TRANS_SINE
	)

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


	# -----------------------------------------
	# FADE OUT
	# -----------------------------------------

	var tween: Tween = create_tween()

	tween.set_ease(
		Tween.EASE_IN_OUT
	)

	tween.set_trans(
		Tween.TRANS_SINE
	)

	tween.tween_property(
		_pantalla,
		"modulate:a",
		1.0,
		tiempo
	)


	# -----------------------------------------
	# CAMBIAR ESCENA
	# -----------------------------------------

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

				_transicionando = false
	)


	# -----------------------------------------
	# ESPERAR A QUE LA NUEVA ESCENA EXISTA
	# -----------------------------------------

	tween.tween_interval(
		0.05
	)


	# -----------------------------------------
	# FADE IN
	# -----------------------------------------

	tween.tween_property(
		_pantalla,
		"modulate:a",
		0.0,
		tiempo
	)


	# -----------------------------------------
	# FINALIZAR
	# -----------------------------------------

	tween.tween_callback(
		_finalizar_transicion
	)


func _finalizar_transicion() -> void:

	_transicionando = false

	visible = false


func esta_transicionando() -> bool:

	return _transicionando
