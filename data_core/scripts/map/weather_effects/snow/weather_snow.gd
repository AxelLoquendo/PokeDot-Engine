extends WeatherBase
class_name SnowWeather

const SnowFlakeScene: PackedScene = preload(
	"res://data_core/scripts/map/weather_effects/snow/snow_flake.tscn"
)
const TEXTURAS: Array[Texture2D] = [
	preload("res://graphics/weather/snow0.png"),
	preload("res://graphics/weather/snow1.png")
]
const CANTIDAD: int = 40
const DURACION_TRANSICION: float = 0.8

var intensidad: float = 1.0
var deteniendo: bool = false
var copos: Array[SnowFlake] = []
var _fade_tween: Tween


static func obtener_textura() -> Texture2D:
	return TEXTURAS.pick_random()


func start() -> void:
	deteniendo = false
	intensidad = 0.0
	for _i: int in range(CANTIDAD):
		crear_copo()


func crear_copo() -> void:
	if deteniendo:
		return
	var copo: SnowFlake = SnowFlakeScene.instantiate() as SnowFlake
	copo.weather = self
	WeatherManager.get_weather_container().add_child(copo)
	copos.append(copo)


func stop() -> void:
	deteniendo = true


func fade_in() -> Signal:
	if _fade_tween:
		_fade_tween.kill()
	_fade_tween = create_tween()
	_fade_tween.tween_property(self, "intensidad", 1.0, DURACION_TRANSICION)
	return _fade_tween.finished


func fade_out() -> Signal:
	deteniendo = true
	if _fade_tween:
		_fade_tween.kill()
	_fade_tween = create_tween()
	_fade_tween.tween_property(self, "intensidad", 0.0, DURACION_TRANSICION)
	_fade_tween.finished.connect(_al_terminar_fade_out)
	return _fade_tween.finished


func _al_terminar_fade_out() -> void:
	for copo: SnowFlake in copos:
		if is_instance_valid(copo):
			copo.queue_free()
	copos.clear()


func copo_terminado(copo: SnowFlake) -> void:
	if deteniendo:
		return
	# Reciclar
	if is_instance_valid(copo):
		copo.iniciar()
