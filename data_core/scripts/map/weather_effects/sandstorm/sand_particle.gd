extends Node2D
class_name SandParticle

@onready var sprite: Sprite2D = $Sprite2D

var weather: SandstormWeather

var velocidad: float
var velocidad_vertical: float
var tiempo: float
var amplitud: float
var frecuencia: float

var camara: Camera2D
var ultima_posicion_camara: Vector2
var viewport_size: Vector2

# Mientras el clima está "deteniendo", en vez de eliminarse al
# salir de pantalla, la partícula se oculta y espera a que
# SandstormWeather.limpiar_todo() la elimine al terminar el fade.
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
	sprite.texture = SandstormWeather.obtener_textura()
	sprite.modulate.a = 0.0
	reiniciar()

func _asignar_camara() -> void:
	var nueva_camara: Camera2D = get_viewport().get_camera_2d()

	if nueva_camara == camara:
		return

	camara = nueva_camara

	# Clave: al (re)asignar la cámara, sincronizamos también su
	# última posición conocida, para que el próximo cálculo de
	# "movimiento_camara" no sea un salto gigante desde CERO.
	if camara:
		ultima_posicion_camara = camara.global_position

func _process(delta: float) -> void:
	if weather == null:
		return

	if camara == null:
		_asignar_camara()

	tiempo += delta

	# -----------------------------------------
	# COMPENSAR MOVIMIENTO DE CÁMARA
	# -----------------------------------------
	if camara:
		var movimiento_camara: Vector2 = (
			camara.global_position - ultima_posicion_camara
		)
		position += movimiento_camara
		ultima_posicion_camara = camara.global_position

	# -----------------------------------------
	# MOVIMIENTO DE ARENA
	# -----------------------------------------
	position.x -= velocidad * delta
	position.y += velocidad_vertical * delta
	position.y += sin(tiempo * frecuencia) * amplitud * delta

	# -----------------------------------------
	# TRANSPARENCIA
	# -----------------------------------------
	# Si está oculta esperando limpieza, no la volvemos a mostrar
	# aunque intensidad todavía no haya llegado a 0.
	if not _oculta_esperando_limpieza:
		sprite.modulate.a = weather.intensidad

	# -----------------------------------------
	# COMPROBAR LÍMITES
	# -----------------------------------------
	var area: Rect2 = obtener_area_camara()
	if (
		position.x < area.position.x - 100.0
		or position.x > area.end.x + 100.0
		or position.y > area.end.y + 100.0
		or position.y < area.position.y - 100.0
	):
		if weather.deteniendo:
			# Antes: terminar() -> queue_free() inmediato, cortando
			# el fade a mitad de camino. Ahora: se oculta y sigue
			# "viva" (aunque invisible) hasta que el tween de
			# intensidad termine y SandstormWeather.limpiar_todo()
			# la elimine junto con el resto.
			_ocultar_y_esperar()
		else:
			reiniciar()

func _ocultar_y_esperar() -> void:
	if _oculta_esperando_limpieza:
		return

	_oculta_esperando_limpieza = true
	sprite.modulate.a = 0.0
	visible = false

func terminar() -> void:
	if weather != null:
		weather.particula_terminada(self)
	queue_free()

func obtener_area_camara() -> Rect2:
	if camara == null:
		_asignar_camara()

	if camara == null:
		return Rect2(Vector2.ZERO, viewport_size)

	# Igual que hace SandstormWeather al armar la capa de polvo:
	# el área real de mundo visible depende del zoom.
	var area_mundo: Vector2 = Vector2(
		viewport_size.x / camara.zoom.x,
		viewport_size.y / camara.zoom.y
	)

	return Rect2(
		camara.global_position - area_mundo / 2.0,
		area_mundo
	)

func reiniciar() -> void:
	var area: Rect2 = obtener_area_camara()
	# Las nuevas partículas aparecen desde el lado derecho y
	# atraviesan la pantalla hacia la izquierda.
	position = Vector2(
		randf_range(area.end.x, area.end.x + 100.0),
		randf_range(area.position.y, area.end.y)
	)
