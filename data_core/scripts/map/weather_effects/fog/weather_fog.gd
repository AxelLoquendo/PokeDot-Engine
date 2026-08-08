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


const TILE_SIZE: Vector2 = Vector2(
	64.0,
	64.0
)


const COLUMNAS: int = 20
const FILAS: int = 13


const DURACION_TRANSICION: float = 0.8


enum FogType {
	HORIZONTAL,
	DIAGONAL
}


var tipo: FogType = FogType.HORIZONTAL

var intensidad: float = 0.0

var deteniendo: bool = false

var tiles: Array[FogTile] = []

var _fade_tween: Tween


func start() -> void:

	deteniendo = false

	intensidad = 0.0

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

	crear_malla()


func crear_malla() -> void:

	var area: Rect2 = obtener_area_camara()


	for y: int in range(FILAS):

		for x: int in range(COLUMNAS):

			crear_tile(
				x,
				y,
				area
			)


func crear_tile(
	grid_x: int,
	grid_y: int,
	area: Rect2
) -> void:

	var tile: FogTile = (
		FogTileScene.instantiate()
	)


	tile.weather = self


	tile.grid_position = Vector2i(
		grid_x,
		grid_y
	)


	if tipo == FogType.HORIZONTAL:

		tile.texture = TEXTURA_HORIZONTAL

	else:

		tile.texture = TEXTURA_DIAGONAL


	WeatherManager.get_weather_container().add_child(
		tile
	)


	# La posición se calcula una sola vez.
	tile.position = (
		area.position
		+ Vector2(
			grid_x * TILE_SIZE.x,
			grid_y * TILE_SIZE.y
		)
	)


	tiles.append(tile)


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


	_fade_tween.finished.connect(
		limpiar_tiles
	)


	return _fade_tween.finished


func update_weather(_delta: float) -> void:

	# La niebla es completamente estática.
	#
	# No hay movimiento.
	# No hay desplazamiento.
	# No hay reinicio de tiles.

	return


func obtener_area_camara() -> Rect2:

	var viewport: Viewport = get_viewport()

	return viewport.get_visible_rect()


func limpiar_tiles() -> void:

	for tile: FogTile in tiles:

		if is_instance_valid(tile):

			tile.queue_free()


	tiles.clear()
