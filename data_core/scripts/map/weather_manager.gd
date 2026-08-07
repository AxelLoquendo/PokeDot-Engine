extends Node

enum WeatherState {
	IDLE,
	CHANGING
}

signal weather_changed(
	old_weather: WeatherEffect.WeatherID,
	new_weather: WeatherEffect.WeatherID
)

var map_manager: MapManager

var current_weather: WeatherEffect.WeatherID = WeatherEffect.WeatherID.WEATHER_NONE
var next_weather: WeatherEffect.WeatherID = WeatherEffect.WeatherID.WEATHER_NONE
var previous_weather: WeatherEffect.WeatherID = WeatherEffect.WeatherID.WEATHER_NONE

var state: WeatherState = WeatherState.IDLE

var weather_nodes: Dictionary[WeatherEffect.WeatherID, WeatherBase] = {}

func _ready() -> void:

	weather_nodes = {
		WeatherEffect.WeatherID.WEATHER_NONE: NoneWeather.new(),
		WeatherEffect.WeatherID.WEATHER_RAIN: RainWeather.new(),
		WeatherEffect.WeatherID.WEATHER_SNOW: SnowWeather.new(),
	}

	for weather: WeatherBase in weather_nodes.values():
		add_child(weather)

func set_weather(weather: WeatherEffect.WeatherID) -> void:

	if weather == current_weather:
		return

	next_weather = weather
	state = WeatherState.CHANGING

func _process(delta: float) -> void:

	match state:

		WeatherState.CHANGING:
			cambiar_clima()

		WeatherState.IDLE:
			actualizar_clima(delta)

func cambiar_clima() -> void:

	state = WeatherState.IDLE

	await _cambiar_clima()

func _cambiar_clima() -> void:

	previous_weather = current_weather

	await finalizar_clima(current_weather)

	current_weather = next_weather

	await iniciar_clima(current_weather)

	weather_changed.emit(
		previous_weather,
		current_weather
	)

func iniciar_clima(weather: WeatherEffect.WeatherID) -> void:

	var clima: WeatherBase = weather_nodes.get(weather)

	if clima == null:
		return

	clima.start()

	@warning_ignore("redundant_await")
	await clima.fade_in()

func finalizar_clima(weather: WeatherEffect.WeatherID) -> void:

	var clima: WeatherBase = weather_nodes.get(weather)

	if clima == null:
		return

	@warning_ignore("redundant_await")
	await clima.fade_out()

	clima.stop()

func actualizar_clima(delta: float) -> void:

	if not weather_nodes.has(current_weather):
		return

	var weather: WeatherBase = weather_nodes[current_weather]

	weather.update_weather(delta)
