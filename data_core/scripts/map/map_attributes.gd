@tool
extends Node2D
class_name MapAttributes

enum Border {
	NONE,
	NORTH,
	SOUTH,
	EAST,
	WEST,
}

enum ConnectionDirection {
	NORTH,
	SOUTH,
	EAST,
	WEST
}
@export_group("Map Attributes")
@export var map_name: String = "Sin nombre"
@export var map_id_section: MapSection.SectionId = MapSection.SectionId.MAPSEC_NONE
@export var map_region: MapSection.RegionId = MapSection.RegionId.REGION_NONE
@export var map_type: Array #Proximamente tipo de mapa (ruta, pueblo, ciudad, cueva, etc)
@export var map_size: Vector2i = Vector2i(40, 40):
	set(new_val):
		map_size = new_val
		queue_redraw()
@export var battle_scene: Array #Proximamente tipo de escena de batalla
@export_group("Editor")
@export var color_borde: Color = Color(0, 1, 1, 1.0)
@export var tile_size: int = 16

@export var mostrar_limite: bool = true:
	set(new_val):
		mostrar_limite = new_val
		queue_redraw()

@export var border_source_id: int = 0
@export var border_origin: Vector2i = Vector2i.ZERO

@export var border_size: int = 2

@export var actualizar_borde: bool = false:
	set(value):
		actualizar_borde = value
		if value:
			actualizar_borde_visual()
			actualizar_borde = false

@export_group("Flags Map")
signal show_location_name_changed(estado: bool)
@export var show_location_name: bool = false:
	set(nuevo_valor):

		show_location_name = nuevo_valor

		if not Engine.is_editor_hint():
			show_location_name_changed.emit(
				nuevo_valor
			)
signal usar_nubes_cambiado(estado: bool)
@export var usar_nubes: bool = true:
	set(nuevo_valor):
		usar_nubes = nuevo_valor
		usar_nubes_cambiado.emit(nuevo_valor)
@export var is_indoor: bool = false
@export var allow_dig_escape_rope: bool = false #Proximamente permiso para usar excavar o cuerda huida
@export var allow_fly: bool = false #Proximamente para dar permiso de volar a este mapa
@export var requires_flash: bool = false #Proximamente verificar si el mapa necesita de Flash
@export_group("Coneccted Map")
@export var north_map: MapConnection
@export var east_map: MapConnection
@export var south_map: MapConnection
@export var west_map: MapConnection
@export_group("Music")
@export_file("*.ogg", "*.wav", "*.mp3") var music_path: String = ""
@export var silence_end: float = 0.0
@export_group("Weather")
@export var weather: WeatherEffect.WeatherID = WeatherEffect.WeatherID.WEATHER_NONE
@export_group("Map Script")
## Compatibilidad con mapas creados antes del sistema de tipos.
@export_file("*.gd", "*.txt") var map_script: String = ""
@export var map_scripts: Array[MapScriptEntry] = []

# Lógica
var activo: bool = true
var map_script_runner: ScriptRunner = null
var _frame_conditions_active: Dictionary[MapScriptEntry, bool] = {}

func _ready() -> void:
	if not Engine.is_editor_hint():
		conectar_actualizaciones()

	if Engine.is_editor_hint():
		actualizar_borde_visual()

	if not activo:
		return

	if not Engine.is_editor_hint():
		call_deferred("trigger_map_scripts", MapScriptEntry.Trigger.ON_TRANSITION)


func run_map_script() -> void:
	if not map_script.is_empty():
		_run_script_file(map_script)


## Ejecuta las filas configuradas para un disparador de mapa.
func trigger_map_scripts(trigger_type: MapScriptEntry.Trigger) -> void:
	if Engine.is_editor_hint() or not activo:
		return
	for entry: MapScriptEntry in map_scripts:
		if entry == null or entry.trigger != trigger_type or entry.script_file.is_empty():
			continue
		if entry.condition_matches():
			_run_script_file(entry.script_file)
	if trigger_type == MapScriptEntry.Trigger.ON_LOAD:
		run_map_script()


func _process(_delta: float) -> void:
	if Engine.is_editor_hint() or not activo:
		return
	for entry: MapScriptEntry in map_scripts:
		if entry == null or entry.trigger != MapScriptEntry.Trigger.ON_FRAME_TABLE:
			continue
		var matches: bool = entry.condition_matches()
		var was_active: bool = _frame_conditions_active.get(entry, false)
		if matches and not was_active:
			_run_script_file(entry.script_file)
		_frame_conditions_active[entry] = matches


func _run_script_file(path: String) -> void:
	if path.is_empty() or not FileAccess.file_exists(path):
		push_error("MapAttributes: no existe el script de mapa %s" % path)
		return
	var script_file: ScriptCmdTextFile = ScriptCmdTextFile.new()
	script_file.script_file_path = path
	var runner: ScriptRunner = ScriptRunner.new()
	add_child(runner)
	var player: Node2D = get_tree().get_first_node_in_group("player") as Node2D
	runner.script_finished.connect(runner.queue_free, CONNECT_ONE_SHOT)
	runner.start_script([script_file], null, player, self)

func activar_musica() -> void:
	if music_path.is_empty():
		return

	MusicManager.reproducir(
		music_path,
		silence_end
	)

func conectar_actualizaciones() -> void:

	var conexiones: Array[MapConnection] = [
		north_map,
		south_map,
		east_map,
		west_map
	]

	for conexion: MapConnection in conexiones:

		if conexion:
			conexion.connection_changed.connect(
				queue_redraw
			)

func _draw() -> void:
	#print("_draw")
	if not Engine.is_editor_hint() or not mostrar_limite:
		return
	if map_size.x <= 0 or map_size.y <= 0:
		return
	
	var ancho: float = map_size.x * tile_size
	var alto: float = map_size.y * tile_size
	
	draw_line(Vector2.ZERO, Vector2(ancho, 0), color_borde, 2.0)
	draw_line(Vector2(ancho, 0), Vector2(ancho, alto), color_borde, 2.0)
	draw_line(Vector2(ancho, alto), Vector2(0, alto), color_borde, 2.0)
	draw_line(Vector2(0, alto), Vector2.ZERO, color_borde, 2.0)
	
	dibujar_conexiones()

func esta_dentro_limites(casilla: Vector2i) -> bool:
	return casilla.x >= 0 and casilla.x < map_size.x and casilla.y >= 0 and casilla.y < map_size.y

func obtener_borde(casilla: Vector2i) -> Border:

	if casilla.y < 0:
		return Border.NORTH

	if casilla.y >= map_size.y:
		return Border.SOUTH

	if casilla.x < 0:
		return Border.WEST

	if casilla.x >= map_size.x:
		return Border.EAST

	return Border.NONE

func obtener_conexion(borde: Border) -> MapConnection:

	match borde:

		Border.NORTH:
			return north_map

		Border.SOUTH:
			return south_map

		Border.EAST:
			return east_map

		Border.WEST:
			return west_map

	return null

func obtener_map_attributes(conexion: MapConnection) -> MapAttributes:
	var escena: PackedScene = conexion.get_scene()
	if escena == null:
		return null

	return escena.instantiate() as MapAttributes

func dibujar_conexiones() -> void:
	if north_map:
		dibujar_conexion_norte()

	if south_map:
		dibujar_conexion_sur()

	if east_map:
		dibujar_conexion_este()

	if west_map:
		dibujar_conexion_oeste()

func dibujar_conexion_norte() -> void:

	if north_map == null:
		return

	dibujar_conexion(
		ConnectionDirection.NORTH,
		north_map,
		Color.RED
	)

func dibujar_conexion_sur() -> void:

	if south_map == null:
		return

	dibujar_conexion(
		ConnectionDirection.SOUTH,
		south_map,
		Color.GREEN
	)

func dibujar_conexion_este() -> void:

	if east_map == null:
		return

	dibujar_conexion(
		ConnectionDirection.EAST,
		east_map,
		Color.YELLOW
	)

func dibujar_conexion_oeste() -> void:

	if west_map == null:
		return

	dibujar_conexion(
		ConnectionDirection.WEST,
		west_map,
		Color.ORANGE
	)

func dibujar_conexion(_direccion: ConnectionDirection, conexion: MapConnection, color: Color) -> void:
	var mapa: MapAttributes = obtener_map_attributes(conexion)

	if mapa == null:
		return

	var posicion: Vector2 = obtener_posicion_conexion(_direccion, conexion)

	dibujar_preview_mapa(mapa, posicion)
	var tamaño: Vector2 = Vector2(
		float(mapa.map_size.x * tile_size),
		float(mapa.map_size.y * tile_size)
	)

	draw_rect(
		Rect2(posicion, tamaño),
		color,
		false,
		2.0
	)

	var fuente: Font = ThemeDB.fallback_font

	if fuente:
		draw_string(
			fuente,
			posicion + Vector2(6,18),
			mapa.map_name,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			16,
			color
		)

func dibujar_preview_mapa(
	mapa: MapAttributes,
	posicion: Vector2
) -> void:

	var tilesets: Node = mapa.get_node_or_null("Tilesets")

	if tilesets == null:
		print("No existe Tilesets en ", mapa.map_name)
		return

	for hijo: Node in tilesets.get_children():

		if hijo is TileMapLayer:

			var layer: TileMapLayer = hijo as TileMapLayer

			dibujar_tilemap(
				layer,
				posicion
			)

func dibujar_tilemap(
	layer: TileMapLayer,
	offset: Vector2
) -> void:

	var tileset: TileSet = layer.tile_set

	if tileset == null:
		return

	for celda: Vector2i in layer.get_used_cells():

		var source_id: int = layer.get_cell_source_id(celda)

		if source_id == -1:
			continue

		var source: TileSetAtlasSource = \
			tileset.get_source(source_id) as TileSetAtlasSource

		if source == null:
			continue

		var atlas: Texture2D = source.texture

		var atlas_coords: Vector2i = layer.get_cell_atlas_coords(celda)

		var region: Rect2 = Rect2(
			Vector2(atlas_coords * tile_size),
			Vector2(tile_size, tile_size)
		)

		draw_texture_rect_region(atlas, Rect2(offset + Vector2(celda * tile_size), Vector2(tile_size, tile_size)), region)

func get_chunk_count() -> Vector2i:
	return Vector2i(
		ceili(float(map_size.x) / MapChunk.SIZE),
		ceili(float(map_size.y) / MapChunk.SIZE)
	)

func obtener_posicion_conexion(
	direccion: ConnectionDirection,
	conexion: MapConnection
) -> Vector2:

	if conexion == null:
		return Vector2.ZERO

	var mapa: MapAttributes = obtener_map_attributes(conexion)

	if mapa == null:
		return Vector2.ZERO

	match direccion:

		ConnectionDirection.NORTH:
			return Vector2(
				float(conexion.offset.x * tile_size),
				float(-mapa.map_size.y * tile_size)
			)

		ConnectionDirection.SOUTH:
			return Vector2(
				float(conexion.offset.x * tile_size),
				float(map_size.y * tile_size)
			)

		ConnectionDirection.EAST:
			return Vector2(
				float(map_size.x * tile_size),
				float(conexion.offset.y * tile_size)
			)

		ConnectionDirection.WEST:
			return Vector2(
				float(-mapa.map_size.x * tile_size),
				float(conexion.offset.y * tile_size)
			)

	return Vector2.ZERO

func obtener_border_atlas(tile: Vector2i) -> Vector2i:

	var x: int = abs(tile.x) & 1
	var y: int = abs(tile.y) & 1

	return border_origin + Vector2i(x, y)

func obtener_border_tile_data(tile: Vector2i) -> TileData:

	var tileset: TileSet = obtener_tileset()

	if tileset == null:
		return null


	var source: TileSetSource = tileset.get_source(border_source_id)

	if source == null:
		return null


	if source is TileSetAtlasSource:

		var atlas: TileSetAtlasSource = source as TileSetAtlasSource

		var coords: Vector2i = obtener_border_atlas(tile)


		if not atlas.has_tile(coords):
			return null


		return atlas.get_tile_data(
			coords,
			0
		)

	return null

func obtener_tileset() -> TileSet:

	var tilesets: Node = get_node_or_null("Tilesets")

	if tilesets == null:
		return null

	for child: Node in tilesets.get_children():

		if child is TileMapLayer:

			var layer: TileMapLayer = child as TileMapLayer

			if layer.tile_set != null:
				return layer.tile_set

	return null

func actualizar_borde_visual() -> void:

	var borde: TileMapLayer = get_node_or_null(
		"Behaviours/Borde"
	) as TileMapLayer

	if borde == null:
		return

	borde.clear()


	var grosor: int = border_size


	# Superior e inferior
	for x: int in range(-grosor, map_size.x + grosor):

		for y: int in range(-grosor, 0):
			crear_tile_borde(
				borde,
				Vector2i(x,y)
			)

		for y: int in range(map_size.y, map_size.y + grosor):
			crear_tile_borde(
				borde,
				Vector2i(x,y)
			)


	# Laterales
	for y: int in range(0, map_size.y):

		for x: int in range(-grosor, 0):
			crear_tile_borde(
				borde,
				Vector2i(x,y)
			)

		for x: int in range(map_size.x, map_size.x + grosor):
			crear_tile_borde(
				borde,
				Vector2i(x,y)
			)

func crear_tile_borde(layer: TileMapLayer, pos: Vector2i) -> void:

	var atlas: Vector2i = obtener_border_atlas(pos)

	#print("Borde:", pos, " atlas:", atlas)

	layer.set_cell(
		pos,
		border_source_id,
		atlas
	)
