extends WeatherBase
class_name SandstormWeather

const SandParticleScene: PackedScene = preload(
	"res://data_core/scripts/map/weather_effects/sandstorm/sand_particle.tscn"
)
const TEXTURAS: Array[Texture2D] = [
	preload("res://graphics/weather/sandstorm_1.png"),
	preload("res://graphics/weather/sandstorm_2.png"),
	preload("res://graphics/weather/sandstorm_3.png"),
	preload("res://graphics/weather/sandstorm_4.png")
]
const TEXTURA_POLVO: Texture2D = preload("res://graphics/weather/sandstorm_tile.png")
const CANTIDAD_PARTICULAS: int = 60
const TILE_SIZE: Vector2 = Vector2(256.0, 256.0)
const VELOCIDAD_POLVO: float = 200.0
const DURACION_TRANSICION: float = 0.8

@export_range(0.0, 1.0, 0.01) var alpha_maxima_polvo: float = 0.45

var intensidad: float = 0.0
var deteniendo: bool = false
var particulas: Array[SandParticle] = []
var polvo_root: Node2D
var polvo_tiles: Array[Sprite2D] = []
var _columnas_polvo: int = 0
var _filas_polvo: int = 0
var _desplazamiento_polvo_x: float = 0.0
var _fade_tween: Tween


static func obtener_textura() -> Texture2D:
	return TEXTURAS.pick_random()


func start() -> void:
	deteniendo = false
	intensidad = 0.0
	_desplazamiento_polvo_x = 0.0
	limpiar_particulas()
	limpiar_polvo()
	crear_capa_polvo()
	for _i: int in range(CANTIDAD_PARTICULAS):
		crear_particula()


func crear_particula() -> void:
	if deteniendo:
		return
	var particula: SandParticle = SandParticleScene.instantiate() as SandParticle
	particula.weather = self
	WeatherManager.get_weather_container().add_child(particula)
	particulas.append(particula)


func crear_capa_polvo() -> void:
	polvo_root = Node2D.new()
	polvo_root.name = "SandstormDust"
	polvo_root.z_index = 3002
	WeatherManager.get_weather_container().add_child(polvo_root)

	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	var camara: Camera2D = get_viewport().get_camera_2d()
	var zoom: Vector2 = camara.zoom if camara else Vector2.ONE

	var area_mundo: Vector2 = Vector2(
		viewport_size.x / zoom.x,
		viewport_size.y / zoom.y
	)

	var columnas: int = int(ceil(area_mundo.x / TILE_SIZE.x)) + 2
	var filas: int = int(ceil(area_mundo.y / TILE_SIZE.y)) + 2
	_columnas_polvo = columnas
	_filas_polvo = filas

	var ancho_total: float = float(columnas) * TILE_SIZE.x
	var alto_total: float = float(filas) * TILE_SIZE.y

	var escala_tile: Vector2 = Vector2.ONE
	if TEXTURA_POLVO:
		var tam_textura: Vector2 = TEXTURA_POLVO.get_size()
		if tam_textura.x > 0.0 and tam_textura.y > 0.0:
			escala_tile = Vector2(
				TILE_SIZE.x / tam_textura.x,
				TILE_SIZE.y / tam_textura.y
			)

	for y: int in range(filas):
		for x: int in range(columnas):
			var sprite: Sprite2D = Sprite2D.new()
			sprite.texture = TEXTURA_POLVO
			sprite.centered = false
			sprite.scale = escala_tile
			sprite.position = Vector2(float(x) * TILE_SIZE.x, float(y) * TILE_SIZE.y)
			sprite.modulate.a = 0.0
			polvo_root.add_child(sprite)
			polvo_tiles.append(sprite)

	var centro: Vector2 = camara.global_position if camara else Vector2.ZERO
	polvo_root.global_position = centro - Vector2(ancho_total, alto_total) * 0.5


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
	_fade_tween.finished.connect(limpiar_todo)
	return _fade_tween.finished


func update_weather(_delta: float) -> void:
	pass


func _process(delta: float) -> void:
	for sprite: Sprite2D in polvo_tiles:
		if is_instance_valid(sprite):
			sprite.modulate.a = intensidad * alpha_maxima_polvo

	_desplazamiento_polvo_x -= VELOCIDAD_POLVO * delta
	_desplazamiento_polvo_x = fmod(_desplazamiento_polvo_x, TILE_SIZE.x)

	if polvo_root == null:
		return

	var camara: Camera2D = get_viewport().get_camera_2d()
	if camara == null:
		return
	if _columnas_polvo <= 0 or _filas_polvo <= 0:
		return

	var ancho_total: float = float(_columnas_polvo) * TILE_SIZE.x
	var alto_total: float = float(_filas_polvo) * TILE_SIZE.y

	polvo_root.global_position = (
		camara.global_position
		- Vector2(ancho_total, alto_total) * 0.5
		+ Vector2(_desplazamiento_polvo_x, 0.0)
	)


func particula_terminada(particula: SandParticle) -> void:
	if particulas.has(particula):
		particulas.erase(particula)


func limpiar_particulas() -> void:
	for particula: SandParticle in particulas:
		if is_instance_valid(particula):
			particula.queue_free()
	particulas.clear()


func limpiar_polvo() -> void:
	for sprite: Sprite2D in polvo_tiles:
		if is_instance_valid(sprite):
			sprite.queue_free()
	polvo_tiles.clear()
	_columnas_polvo = 0
	_filas_polvo = 0
	if polvo_root and is_instance_valid(polvo_root):
		polvo_root.queue_free()
	polvo_root = null


func limpiar_todo() -> void:
	limpiar_particulas()
	limpiar_polvo()
