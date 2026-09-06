extends Node2D
class_name SandParticle

@onready var sprite: Sprite2D = $Sprite2D

var weather: SandstormWeather
var velocidad: float = 0.0
var velocidad_vertical: float = 0.0
var tiempo: float = 0.0
var amplitud: float = 0.0
var frecuencia: float = 0.0
var camara: Camera2D
var ultima_posicion_camara: Vector2
var viewport_size: Vector2
var _oculta_esperando_limpieza: bool = false


func _ready() -> void:
	z_index = 3002
	viewport_size = get_viewport_rect().size
	_asignar_camara()
	iniciar()


func iniciar() -> void:
	velocidad = randf_range(180.0, 320.0)
	velocidad_vertical = randf_range(-25.0, 25.0)
	amplitud = randf_range(5.0, 20.0)
	frecuencia = randf_range(2.0, 5.0)
	tiempo = randf_range(0.0, TAU)
	if sprite:
		sprite.texture = SandstormWeather.obtener_textura()
		sprite.modulate.a = 0.0
	reiniciar()


func _asignar_camara() -> void:
	var nueva: Camera2D = get_viewport().get_camera_2d()
	if nueva == camara:
		return
	camara = nueva
	if camara:
		ultima_posicion_camara = camara.global_position


func _process(delta: float) -> void:
	if weather == null:
		return
	if camara == null:
		_asignar_camara()

	tiempo += delta

	if camara:
		var mov: Vector2 = camara.global_position - ultima_posicion_camara
		position += mov
		ultima_posicion_camara = camara.global_position

	position.x -= velocidad * delta
	position.y += velocidad_vertical * delta
	position.y += sin(tiempo * frecuencia) * amplitud * delta

	if sprite:
		sprite.modulate.a = weather.intensidad

	var area: Rect2 = _obtener_area_camara()
	if position.x < area.position.x - 80.0:
		if weather.deteniendo:
			_oculta_esperando_limpieza = true
			visible = false
		else:
			reiniciar()


func reiniciar() -> void:
	_oculta_esperando_limpieza = false
	visible = true
	var area: Rect2 = _obtener_area_camara()
	position = Vector2(
		randf_range(area.end.x + 20.0, area.end.x + 120.0),
		randf_range(area.position.y - 40.0, area.end.y + 40.0)
	)


func _obtener_area_camara() -> Rect2:
	if camara == null:
		return Rect2(Vector2.ZERO, viewport_size)
	var centro: Vector2 = camara.global_position
	var tamaño: Vector2 = viewport_size / camara.zoom
	return Rect2(centro - tamaño * 0.5, tamaño)
