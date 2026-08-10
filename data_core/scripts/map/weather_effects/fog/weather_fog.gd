extends WeatherBase
class_name FogWeather

const FogTileScene: PackedScene = preload(
	"res://data_core/scripts/map/weather_effects/fog/fog_tile.tscn"
)
const TEXTURA_HORIZONTAL: Texture2D = preload(
	"res://graphics/weather/fog_tile.png"
)
const TEXTURA_DIAGONAL: Texture2D = preload(
	"res://graphics/weather/fog_tile_2.png"
)
const TILE_SIZE: Vector2 = Vector2(64.0, 64.0)

# Tiles de más para cubrir bordes al moverse la cámara y al
# hacer scroll.
const MARGEN_TILES: int = 2

const DURACION_TRANSICION: float = 0.8

# Velocidad del desplazamiento del patrón de niebla (px/s).
@export var velocidad_niebla: float = 15.0

enum FogType {
	HORIZONTAL,
	DIAGONAL
}

var tipo: FogType = FogType.HORIZONTAL
var intensidad: float = 0.0
var deteniendo: bool = false
var tiles: Array[FogTile] = []

var _fade_tween: Tween
var camara: Camera2D
var fog_root: Node2D
var columnas: int = 0
var filas: int = 0

# Desplazamiento acumulado del scroll, envuelto dentro del
# tamaño de un tile para que el patrón repetido loopee sin
# cortes visibles (misma técnica que el polvo de la tormenta).
var _desplazamiento: Vector2 = Vector2.ZERO


func start() -> void:
	deteniendo = false
	intensidad = 0.0
	_desplazamiento = Vector2.ZERO

	camara = get_viewport().get_camera_2d()

	# -----------------------------------------
	# DETERMINAR TIPO DE NIEBLA
	# -----------------------------------------
	if (
		WeatherManager.next_weather
		== WeatherEffect.WeatherID.WEATHER_FOG_DIAGONAL
	):
		tipo = FogType.DIAGONAL
	else:
		tipo = FogType.HORIZONTAL

	# -----------------------------------------
	# CREAR NIEBLA
	# -----------------------------------------
	limpiar_tiles()
	crear_root()
	crear_malla()
	posicionar_root()


func crear_root() -> void:
	if fog_root and is_instance_valid(fog_root):
		fog_root.queue_free()

	fog_root = Node2D.new()
	fog_root.name = "FogRoot"
	WeatherManager.get_weather_container().add_child(fog_root)


func calcular_dimensiones_grilla() -> void:
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size

	var zoom: Vector2 = Vector2.ONE
	if camara:
		zoom = camara.zoom

	var area_mundo: Vector2 = Vector2(
		viewport_size.x / zoom.x,
		viewport_size.y / zoom.y
	)

	columnas = int(ceil(area_mundo.x / TILE_SIZE.x)) + MARGEN_TILES
	filas = int(ceil(area_mundo.y / TILE_SIZE.y)) + MARGEN_TILES


func obtener_textura_actual() -> Texture2D:
	if tipo == FogType.HORIZONTAL:
		return TEXTURA_HORIZONTAL
	return TEXTURA_DIAGONAL


func calcular_escala_tile() -> Vector2:
	var textura: Texture2D = obtener_textura_actual()

	if textura == null:
		return Vector2.ONE

	var tam_textura: Vector2 = textura.get_size()

	if tam_textura.x <= 0.0 or tam_textura.y <= 0.0:
		return Vector2.ONE

	# Fuerza a que la textura real, sea cual sea su tamaño en
	# píxeles, ocupe exactamente un tile de TILE_SIZE. Sin esto,
	# si el .png no mide 64x64 exactos, quedan huecos o
	# superposiciones entre tiles (se ve como manchas raras de
	# transparencia en vez de una niebla continua).
	return Vector2(
		TILE_SIZE.x / tam_textura.x,
		TILE_SIZE.y / tam_textura.y
	)


func crear_malla() -> void:
	calcular_dimensiones_grilla()

	var escala_tile: Vector2 = calcular_escala_tile()

	for y: int in range(filas):
		for x: int in range(columnas):
			crear_tile(x, y, escala_tile)


func crear_tile(grid_x: int, grid_y: int, escala_tile: Vector2) -> void:
	var tile: FogTile = FogTileScene.instantiate()
	tile.weather = self
	tile.grid_position = Vector2i(grid_x, grid_y)
	tile.texture = obtener_textura_actual()

	fog_root.add_child(tile)

	tile.escala_tile = escala_tile

	tile.position = Vector2(
		grid_x * TILE_SIZE.x,
		grid_y * TILE_SIZE.y
	)

	tiles.append(tile)


func posicionar_root() -> void:
	if fog_root == null:
		return

	var centro: Vector2 = Vector2.ZERO
	if camara:
		centro = camara.global_position

	var tamano_total: Vector2 = Vector2(
		columnas * TILE_SIZE.x,
		filas * TILE_SIZE.y
	)

	fog_root.global_position = (
		centro
		- tamano_total / 2.0
		+ _desplazamiento
	)


func _actualizar_scroll(delta: float) -> void:
	var direccion: Vector2

	match tipo:
		FogType.HORIZONTAL:
			# Deriva pareja hacia un lado.
			direccion = Vector2(-1.0, 0.0)
		FogType.DIAGONAL:
			# Deriva en diagonal (ajustá el signo si querés
			# que vaya para el otro lado).
			direccion = Vector2(-1.0, 1.0).normalized()
		_:
			direccion = Vector2.ZERO

	_desplazamiento += direccion * velocidad_niebla * delta

	# Envolver dentro del tamaño de un tile para que el patrón
	# repetido pueda scrollear infinito sin cortes.
	_desplazamiento.x = fmod(_desplazamiento.x, TILE_SIZE.x)
	_desplazamiento.y = fmod(_desplazamiento.y, TILE_SIZE.y)


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
	_fade_tween.finished.connect(limpiar_tiles)
	return _fade_tween.finished


func update_weather(_delta: float) -> void:
	return


func _process(delta: float) -> void:
	if fog_root == null or not is_instance_valid(fog_root):
		return

	if camara == null or not is_instance_valid(camara):
		camara = get_viewport().get_camera_2d()

	_actualizar_scroll(delta)
	posicionar_root()


func limpiar_tiles() -> void:
	for tile: FogTile in tiles:
		if is_instance_valid(tile):
			tile.queue_free()
	tiles.clear()

	if fog_root and is_instance_valid(fog_root):
		fog_root.queue_free()
		fog_root = null
