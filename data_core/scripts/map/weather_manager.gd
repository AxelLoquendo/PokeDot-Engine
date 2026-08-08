extends Node

var weather_container: Node2D

enum WeatherState {
	IDLE,
	CHANGING
}

signal weather_changed(
	old_weather: WeatherEffect.WeatherID,
	new_weather: WeatherEffect.WeatherID
)

var current_weather: WeatherEffect.WeatherID = (
	WeatherEffect.WeatherID.WEATHER_NONE
)
var next_weather: WeatherEffect.WeatherID = (
	WeatherEffect.WeatherID.WEATHER_NONE
)

var state: WeatherState = WeatherState.IDLE
var weather_nodes: Dictionary[WeatherEffect.WeatherID, WeatherBase] = {}

# Si algo pide un clima antes de que _ready() termine de armar
# weather_nodes, lo guardamos acá para aplicarlo apenas esté listo.
var _pending_weather: Variant = null
var _ready_done: bool = false

func get_weather_container() -> Node2D:
	return weather_container

func _ready() -> void:
	weather_container = Node2D.new()
	weather_container.name = "WeatherContainer"
	add_child(weather_container)

	weather_nodes = {
		WeatherEffect.WeatherID.WEATHER_NONE:
			NoneWeather.new(),
		WeatherEffect.WeatherID.WEATHER_RAIN:
			RainWeather.new(),
		WeatherEffect.WeatherID.WEATHER_SNOW:
			SnowWeather.new(),
		WeatherEffect.WeatherID.WEATHER_FOG_HORIZONTAL:
			FogWeather.new(),
		WeatherEffect.WeatherID.WEATHER_FOG_DIAGONAL:
			FogWeather.new()
	}

	for weather: WeatherBase in weather_nodes.values():
		add_child(weather)

	_ready_done = true

	if _pending_weather != null:
		var clima: WeatherEffect.WeatherID = _pending_weather
		_pending_weather = null
		set_weather(clima)

func set_weather(
	weather: WeatherEffect.WeatherID
) -> void:
	# Todavía no está armado weather_nodes: guardamos el pedido.
	if not _ready_done:
		_pending_weather = weather
		return

	next_weather = weather

	if (
		current_weather == next_weather
		and state == WeatherState.IDLE
	):
		return

	# Ya está yendo hacia ese mismo clima: no reiniciamos nada.
	if (
		state == WeatherState.CHANGING
		and next_weather == current_weather
	):
		return

	if state == WeatherState.CHANGING:
		return

	state = WeatherState.CHANGING
	cambiar_clima()

func _process(delta: float) -> void:
	if state == WeatherState.IDLE:
		actualizar_clima(delta)

func cambiar_clima() -> void:
	await _cambiar_clima()

func _cambiar_clima() -> void:
	var clima_objetivo: WeatherEffect.WeatherID = next_weather

	if clima_objetivo == current_weather:
		state = WeatherState.IDLE
		return

	var clima_anterior: WeatherBase = weather_nodes.get(
		current_weather
	)
	var clima_nuevo: WeatherBase = weather_nodes.get(
		clima_objetivo
	)

	if clima_nuevo == null:
		state = WeatherState.IDLE
		return

	# -----------------------------------------
	# INICIAR NUEVO CLIMA
	# -----------------------------------------
	clima_nuevo.start()
	var fade_in_signal: Signal = clima_nuevo.fade_in()

	# -----------------------------------------
	# TERMINAR CLIMA ANTERIOR
	# -----------------------------------------
	var fade_out_signal: Signal = get_tree().process_frame

	if clima_anterior != null:
		fade_out_signal = clima_anterior.fade_out()

	# -----------------------------------------
	# ESPERAR AMBOS (con duración acotada ahora)
	# -----------------------------------------
	await fade_in_signal
	await fade_out_signal

	# -----------------------------------------
	# CAMBIO REAL
	# -----------------------------------------
	var clima_anterior_id: WeatherEffect.WeatherID = current_weather
	current_weather = clima_objetivo

	weather_changed.emit(
		clima_anterior_id,
		current_weather
	)

	# -----------------------------------------
	# ¿EL MAPA CAMBIÓ DE CLIMA DURANTE
	# LA TRANSICIÓN?
	# -----------------------------------------
	if next_weather != current_weather:
		await _cambiar_clima()
	else:
		state = WeatherState.IDLE

func actualizar_clima(delta: float) -> void:
	if not weather_nodes.has(current_weather):
		return

	var weather: WeatherBase = weather_nodes[current_weather]
	weather.update_weather(delta)
