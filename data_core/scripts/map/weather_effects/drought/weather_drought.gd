extends WeatherBase
class_name DroughtWeather


const SHADER_DISTORSION: Shader = preload(
	"res://data_core/scripts/map/weather_effects/drought/drought_heat.gdshader"
)

const DURACION_TRANSICION: float = 0.8


# -----------------------------------------------------------
# COLOR DEL CALOR
# -----------------------------------------------------------

@export var color_filtro: Color = Color(
	0.95,
	0.68,
	0.28,
	1.0
)

# Intensidad máxima del tinte.
@export_range(0.0, 1.0, 0.01)
var alpha_maxima: float = 0.38


# -----------------------------------------------------------
# CAPA DE RENDER
# -----------------------------------------------------------

@export var capa_render: int = 90


# -----------------------------------------------------------
# DISTORSIÓN DEL AIRE
# -----------------------------------------------------------

# Fuerza máxima de la distorsión.
@export_range(0.0, 0.02, 0.0005)
var distorsion_fuerza: float = 0.006

# Velocidad de las ondas.
@export_range(0.1, 5.0, 0.1)
var velocidad_calor: float = 1.2

# Cantidad/tamaño de las ondas.
@export_range(1.0, 30.0, 0.5)
var escala_distorsion: float = 9.0

# Cuánto movimiento vertical tiene la distorsión.
@export_range(0.0, 2.0, 0.05)
var distorsion_vertical: float = 0.7


# -----------------------------------------------------------
# VARIABLES INTERNAS
# -----------------------------------------------------------

var intensidad: float = 0.0

var _fade_tween: Tween
var _capa: CanvasLayer
var _rect: ColorRect


# -----------------------------------------------------------
# INICIAR CLIMA
# -----------------------------------------------------------

func start() -> void:

	intensidad = 0.0

	crear_filtro()


# -----------------------------------------------------------
# CREAR FILTRO
# -----------------------------------------------------------

func crear_filtro() -> void:

	limpiar_filtro()


	# -------------------------------------------------------
	# CANVAS LAYER
	# -------------------------------------------------------

	_capa = CanvasLayer.new()

	_capa.name = "DroughtFilter"

	_capa.layer = capa_render

	WeatherManager.get_weather_container().add_child(
		_capa
	)


	# -------------------------------------------------------
	# COLOR RECT
	# -------------------------------------------------------

	_rect = ColorRect.new()

	_rect.name = "DroughtFilterRect"

	_rect.color = Color.WHITE

	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE

	_rect.set_anchors_preset(
		Control.PRESET_FULL_RECT
	)


	# -------------------------------------------------------
	# MATERIAL DEL SHADER
	# -------------------------------------------------------

	var shader_material: ShaderMaterial = (
		ShaderMaterial.new()
	)

	shader_material.shader = SHADER_DISTORSION


	# Fuerza de distorsión.
	shader_material.set_shader_parameter(
		"distortion_strength",
		distorsion_fuerza
	)


	# Velocidad.
	shader_material.set_shader_parameter(
		"distortion_speed",
		velocidad_calor
	)


	# Tamaño de las ondas.
	shader_material.set_shader_parameter(
		"distortion_scale",
		escala_distorsion
	)


	# Movimiento vertical.
	shader_material.set_shader_parameter(
		"distortion_vertical",
		distorsion_vertical
	)


	# Color cálido.
	shader_material.set_shader_parameter(
		"heat_color",
		color_filtro
	)


	# Alpha inicial.
	shader_material.set_shader_parameter(
		"heat_alpha",
		0.0
	)


	_rect.material = shader_material


	_capa.add_child(
		_rect
	)


# -----------------------------------------------------------
# DETENER
# -----------------------------------------------------------

func stop() -> void:

	pass


# -----------------------------------------------------------
# FADE IN
# -----------------------------------------------------------

func fade_in() -> Signal:

	if _fade_tween:

		_fade_tween.kill()


	_fade_tween = create_tween()


	_fade_tween.tween_property(
		self,
		"intensidad",
		1.0,
		DURACION_TRANSICION
	)


	return _fade_tween.finished


# -----------------------------------------------------------
# FADE OUT
# -----------------------------------------------------------

func fade_out() -> Signal:

	if _fade_tween:

		_fade_tween.kill()


	_fade_tween = create_tween()


	_fade_tween.tween_property(
		self,
		"intensidad",
		0.0,
		DURACION_TRANSICION
	)


	_fade_tween.finished.connect(
		limpiar_filtro
	)


	return _fade_tween.finished


# -----------------------------------------------------------
# UPDATE WEATHER
# -----------------------------------------------------------

func update_weather(_delta: float) -> void:

	return


# -----------------------------------------------------------
# PROCESAMIENTO
# -----------------------------------------------------------

func _process(_delta: float) -> void:

	if _rect == null:

		return


	if not is_instance_valid(_rect):

		return


	var material: ShaderMaterial = (
		_rect.material as ShaderMaterial
	)


	if material == null:

		return


	# -------------------------------------------------------
	# INTENSIDAD DEL TINTE
	# -------------------------------------------------------

	var alpha: float = (
		intensidad
		* alpha_maxima
	)


	material.set_shader_parameter(
		"heat_alpha",
		alpha
	)


	# -------------------------------------------------------
	# DISTORSIÓN
	# -------------------------------------------------------

	material.set_shader_parameter(
		"distortion_strength",
		distorsion_fuerza * intensidad
	)


	material.set_shader_parameter(
		"distortion_speed",
		velocidad_calor
	)


	material.set_shader_parameter(
		"distortion_scale",
		escala_distorsion
	)


	material.set_shader_parameter(
		"distortion_vertical",
		distorsion_vertical
	)


	# -------------------------------------------------------
	# COLOR
	# -------------------------------------------------------

	material.set_shader_parameter(
		"heat_color",
		color_filtro
	)


# -----------------------------------------------------------
# LIMPIAR FILTRO
# -----------------------------------------------------------

func limpiar_filtro() -> void:

	if _rect and is_instance_valid(_rect):

		_rect.queue_free()


	_rect = null


	if _capa and is_instance_valid(_capa):

		_capa.queue_free()


	_capa = null
