@tool
extends Node2D
class_name MapAttributes

@export var map_name: String = "Sin nombre"
@export var map_id_section: MapSection.SectionId = MapSection.SectionId.MAPSEC_NONE
@export var map_region: MapSection.RegionId = MapSection.RegionId.REGION_NONE
@export var map_size: Vector2i = Vector2i(40, 40):
	set(new_val):
		map_size = new_val
		queue_redraw()

@export var color_borde: Color = Color(0, 1, 1, 1.0)
@export var tile_size: int = 16

@export var mostrar_limite: bool = true:
	set(new_val):
		mostrar_limite = new_val
		queue_redraw()

@export var is_indoor: bool = false
@export var allow_escape_rope: bool = false
@export var allow_fly: bool = false

@export var north_map: MapConnection
@export var east_map: MapConnection
@export var south_map: MapConnection
@export var west_map: MapConnection

@export_file("*.ogg", "*.wav", "*.mp3") var music_path: String = ""
@export var silence_end: float = 0.0

func _ready() -> void:
	if not Engine.is_editor_hint():
		conectar_actualizaciones()

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

func aplicar_limites_camara(camara: Camera2D) -> void:
	if not camara:
		return

	var esquina_superior_izquierda: Vector2 = to_global(Vector2.ZERO)
	var esquina_inferior_derecha: Vector2 = to_global(
		Vector2(
			map_size.x * tile_size,
			map_size.y * tile_size
		)
	)

	camara.limit_left = floori(esquina_superior_izquierda.x)
	camara.limit_top = floori(esquina_superior_izquierda.y)
	camara.limit_right = ceili(esquina_inferior_derecha.x)
	camara.limit_bottom = ceili(esquina_inferior_derecha.y)

	# Evita que el suavizado permita ver fuera del mapa.
	camara.limit_smoothed = false

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
	#print("NORTE")

	var mapa: MapAttributes = obtener_map_attributes(north_map)

	if mapa == null:
		#print("mapa null")
		return

	#print("mapa:", mapa.map_name)

	var posicion: Vector2 = Vector2(
		float(north_map.offset.x * tile_size),
		float(-mapa.map_size.y * tile_size)
	)

	dibujar_conexion(north_map, posicion, Color.RED)

func dibujar_conexion_sur() -> void:
	var mapa: MapAttributes = obtener_map_attributes(south_map)

	if mapa == null:
		return

	var posicion: Vector2 = Vector2(
		float(south_map.offset.x * tile_size),
		float(map_size.y * tile_size)
	)

	dibujar_conexion(south_map, posicion, Color.GREEN)

func dibujar_conexion_este() -> void:
	var mapa: MapAttributes = obtener_map_attributes(east_map)

	if mapa == null:
		return

	var posicion: Vector2 = Vector2(
		float(map_size.x * tile_size),
		float(east_map.offset.y * tile_size)
	)

	dibujar_conexion(east_map, posicion, Color.YELLOW)

func dibujar_conexion_oeste() -> void:
	var mapa: MapAttributes = obtener_map_attributes(west_map)

	if mapa == null:
		return

	var posicion: Vector2 = Vector2(
		float(-mapa.map_size.x * tile_size),
		float(west_map.offset.y * tile_size)
	)

	dibujar_conexion(west_map, posicion, Color.ORANGE)

func dibujar_conexion(conexion: MapConnection, posicion: Vector2, color: Color) -> void:

	var mapa: MapAttributes = obtener_map_attributes(conexion)

	if mapa == null:
		return

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
