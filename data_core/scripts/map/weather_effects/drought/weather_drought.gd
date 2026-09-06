extends WeatherBase
class_name DroughtWeather

const SHADER_DISTORSION: Shader = preload(
	"res://data_core/scripts/map/weather_effects/drought/drought_heat.gdshader"
)
const DURACION_TRANSICION: float = 0.8

@export var color_filtro: Color = Color(0.95, 0.68, 0.28, 1.0)
@export_range(0.0, 1.0, 0.01) var alpha_maxima: float = 0.38
@export var capa_render: int = 90
@export_range(0.0, 0.02, 0.0005) var distorsion_fuerza: float = 0.006
@export_range(0.1, 5.0, 0.1) var velocidad_calor: float = 1.2
@export_range(1.0, 30.0, 0.5) var escala_distorsion: float = 9.0
@export_range(0.0, 2.0, 0.05) var distorsion_vertical: float = 0.7

var intensidad: float = 0.0
var _fade_tween: Tween
var _capa: CanvasLayer
var _rect: ColorRect


func start() -> void:
	intensidad = 0.0
	crear_filtro()


func crear_filtro() -> void:
	limpiar_filtro()

	_capa = CanvasLayer.new()
	_capa.name = "DroughtFilter"
	_capa.layer = capa_render
	WeatherManager.get_weather_container().add_child(_capa)

	_rect = ColorRect.new()
	_rect.name = "DroughtFilterRect"
	_rect.color = Color.WHITE
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rect.set_anchors_preset(Control.PRESET_FULL_RECT)

	var shader_material: ShaderMaterial = ShaderMaterial.new()
	shader_material.shader = SHADER_DISTORSION
	shader_material.set_shader_parameter("distortion_strength", distorsion_fuerza)
	shader_material.set_shader_parameter("distortion_speed", velocidad_calor)
	shader_material.set_shader_parameter("distortion_scale", escala_distorsion)
	shader_material.set_shader_parameter("distortion_vertical", distorsion_vertical)
	shader_material.set_shader_parameter("heat_color", color_filtro)
	shader_material.set_shader_parameter("heat_alpha", 0.0)

	_rect.material = shader_material
	_capa.add_child(_rect)


func stop() -> void:
	pass


func fade_in() -> Signal:
	if _fade_tween:
		_fade_tween.kill()
	_fade_tween = create_tween()
	_fade_tween.tween_property(self, "intensidad", 1.0, DURACION_TRANSICION)
	return _fade_tween.finished


func fade_out() -> Signal:
	if _fade_tween:
		_fade_tween.kill()
	_fade_tween = create_tween()
	_fade_tween.tween_property(self, "intensidad", 0.0, DURACION_TRANSICION)
	_fade_tween.finished.connect(limpiar_filtro)
	return _fade_tween.finished


func update_weather(_delta: float) -> void:
	pass


func _process(_delta: float) -> void:
	if _rect == null or not is_instance_valid(_rect):
		return

	var material: ShaderMaterial = _rect.material as ShaderMaterial
	if material == null:
		return

	material.set_shader_parameter("heat_alpha", intensidad * alpha_maxima)
	material.set_shader_parameter("distortion_strength", distorsion_fuerza * intensidad)
	material.set_shader_parameter("distortion_speed", velocidad_calor)
	material.set_shader_parameter("distortion_scale", escala_distorsion)
	material.set_shader_parameter("distortion_vertical", distorsion_vertical)
	material.set_shader_parameter("heat_color", color_filtro)


func limpiar_filtro() -> void:
	if _rect and is_instance_valid(_rect):
		_rect.queue_free()
	_rect = null
	if _capa and is_instance_valid(_capa):
		_capa.queue_free()
	_capa = null
