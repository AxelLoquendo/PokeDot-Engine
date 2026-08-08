extends WeatherBase
class_name RainWeather

const RainDropScene: PackedScene = preload(
	"res://data_core/scripts/map/weather_effects/rain/rain_drop.tscn"
)
const CANTIDAD_GOTAS: int = 40
const DURACION_TRANSICION: float = 0.8

var intensidad: float = 1.0
var deteniendo: bool = false
var gotas: Array[RainDrop] = []

var _fade_tween: Tween

func start() -> void:
	deteniendo = false
	intensidad = 0.0
	for _i: int in range(CANTIDAD_GOTAS):
		crear_gota()

func crear_gota() -> void:
	if deteniendo:
		return
	var gota: RainDrop = RainDropScene.instantiate()
	gota.weather = self
	WeatherManager.get_weather_container().add_child(gota)
	gotas.append(gota)

func stop() -> void:
	deteniendo = true

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

func fade_out() -> Signal:
	deteniendo = true

	if _fade_tween:
		_fade_tween.kill()

	_fade_tween = create_tween()
	_fade_tween.tween_property(
		self,
		"intensidad",
		0.0,
		DURACION_TRANSICION
	)
	_fade_tween.finished.connect(_al_terminar_fade_out)
	return _fade_tween.finished

func _al_terminar_fade_out() -> void:
	for gota: RainDrop in gotas:
		if is_instance_valid(gota):
			gota.queue_free()
	gotas.clear()

func update_weather(_delta: float) -> void:
	var vivas: Array[RainDrop] = []
	for gota: RainDrop in gotas:
		if is_instance_valid(gota):
			vivas.append(gota)
	gotas = vivas
