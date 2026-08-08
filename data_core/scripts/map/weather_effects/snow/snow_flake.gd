extends Node2D
class_name SnowFlake

@onready var sprite: Sprite2D = $Sprite2D

var velocidad: float
var amplitud: float
var frecuencia: float
var tiempo: float
var viewport_size: Vector2
var weather: SnowWeather
var camara: Camera2D
var ultima_posicion_camara: Vector2

func _ready() -> void:
	z_index = 3001
	viewport_size = get_viewport_rect().size
	camara = get_viewport().get_camera_2d()
	if camara:
		ultima_posicion_camara = camara.global_position
	iniciar()

func iniciar() -> void:
	velocidad = randf_range(40.0, 90.0)
	amplitud = randf_range(20.0, 50.0)
	frecuencia = randf_range(1.0, 3.0)
	tiempo = randf_range(0.0, TAU)
	sprite.texture = SnowWeather.obtener_textura()
	reiniciar()

func _process(delta: float) -> void:
	tiempo += delta

	# Compensar el movimiento de cámara, igual que la lluvia,
	# para que la nieve no se quede "atrás" al caminar.
	if camara:
		var movimiento_camara: Vector2 = (
			camara.global_position - ultima_posicion_camara
		)
		position += movimiento_camara
		ultima_posicion_camara = camara.global_position

	position.y += velocidad * delta
	position.x += sin(tiempo * frecuencia) * amplitud * delta

	if weather != null:
		sprite.modulate.a = weather.intensidad

	var area: Rect2 = obtener_area_camara()
	if (
		position.y > area.end.y + 120.0
		or position.x < area.position.x - 60.0
		or position.x > area.end.x + 60.0
	):
		if weather != null and weather.deteniendo:
			terminar()
		else:
			reiniciar()

func terminar() -> void:
	if weather != null:
		var clima: SnowWeather = weather
		clima.copo_terminado(self)
	queue_free()

func obtener_area_camara() -> Rect2:
	if camara == null:
		camara = get_viewport().get_camera_2d()
	if camara == null:
		return Rect2(Vector2.ZERO, viewport_size)
	return Rect2(
		camara.global_position - viewport_size / 2.0,
		viewport_size
	)

func reiniciar() -> void:
	if camara:
		ultima_posicion_camara = camara.global_position
	var area: Rect2 = obtener_area_camara()
	position = Vector2(
		randf_range(area.position.x, area.end.x),
		randf_range(area.position.y - 300.0, area.position.y)
	)
