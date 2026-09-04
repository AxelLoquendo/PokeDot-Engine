extends CanvasLayer

@export var duracion: float = 0.5


var _pantalla: ColorRect
var _transicionando: bool = false


const SHADER_SHATTER: Shader = preload(
	"res://data_core/scripts/overworld/battle_shatter.gdshader"
)

var _flash: ColorRect
var _shatter: ColorRect

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

func crear_flash() -> void:
	if has_node("Flash"):
		_flash = $Flash
	else:
		_flash = ColorRect.new()
		_flash.name = "Flash"
		add_child(_flash)

	_flash.color = Color.WHITE
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flash.z_index = 4097
	_flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_flash.modulate.a = 0.0


func crear_shatter() -> void:
	if has_node("Shatter"):
		_shatter = $Shatter
	else:
		_shatter = ColorRect.new()
		_shatter.name = "Shatter"
		add_child(_shatter)

	_shatter.color = Color.WHITE # el shader decide el color real
	_shatter.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_shatter.z_index = 4098
	_shatter.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_shatter.visible = false

	if _shatter.material == null:
		var shader_material: ShaderMaterial = ShaderMaterial.new()
		shader_material.shader = SHADER_SHATTER
		_shatter.material = shader_material


func transicion_encuentro_salvaje(
	num_flashes: int = 2,
	tiempo_flash: float = 0.10,
	tiempo_shatter: float = 0.7,
	tamano_bloque: float = 18.0
) -> void:
	if _transicionando:
		return

	_transicionando = true
	visible = true

	crear_flash()
	crear_shatter()

	var shader_material: ShaderMaterial = _shatter.material as ShaderMaterial
	shader_material.set_shader_parameter(
		"pantalla_size",
		get_viewport().get_visible_rect().size
	)
	shader_material.set_shader_parameter("tamano_bloque", tamano_bloque)
	shader_material.set_shader_parameter("progress", 0.0)

	# --- Parpadeo ---
	for i: int in num_flashes:
		var tween_in: Tween = create_tween()
		tween_in.tween_property(_flash, "modulate:a", 1.0, tiempo_flash)
		await tween_in.finished

		var tween_out: Tween = create_tween()
		tween_out.tween_property(_flash, "modulate:a", 0.0, tiempo_flash)
		await tween_out.finished

	# --- Desarme en cuadritos desde la esquina inferior derecha ---
	_shatter.visible = true

	var tween_shatter: Tween = create_tween()
	tween_shatter.set_ease(Tween.EASE_IN)
	tween_shatter.set_trans(Tween.TRANS_QUAD)
	tween_shatter.tween_method(
		func(valor: float) -> void:
			shader_material.set_shader_parameter("progress", valor),
		0.0,
		1.0,
		tiempo_shatter
	)
	await tween_shatter.finished

	# Dejamos la pantalla negra "de siempre" para poder usar fade_in() después.
	_pantalla.modulate.a = 1.0
	_flash.visible = false
	_shatter.visible = false
