extends Sprite2D
class_name ReflejoAgua

## Reflejo del personaje en el agua (tiles de colisión con "surf").

const SHADER: Shader = preload("res://data_core/scripts/overworld/reflejo_agua.gdshader")
const RUTA_COLISIONES: NodePath = ^"Behaviours/Collisions"
const META_MASCARA: StringName = &"reflejo_agua_mascara"
## Casillas que se revisan arriba/abajo para saber si está en un puente.
const MAX_FILAS_PUENTE: int = 4

## Sprite que se refleja.
@export var fuente: AnimatedSprite2D
## Por si el sprite tiene margen transparente bajo los pies.
@export var ajuste_y: float = 0.0

var _personaje: CharacterController = null
var _mapa: MapAttributes = null
var _material: ShaderMaterial = null


## Solo en juego, no en el editor.
static func agregar_a(padre: Node, sprite: AnimatedSprite2D) -> ReflejoAgua:
	if Engine.is_editor_hint() or padre == null or sprite == null:
		return null
	var reflejo: ReflejoAgua = ReflejoAgua.new()
	reflejo.name = "ReflejoAgua"
	reflejo.fuente = sprite
	padre.add_child(reflejo)
	return reflejo


## "imagen": casillas de agua. "textura": agua + la fila de encima (vigas,
## orilla); el shader ya descarta los píxeles que no son agua.
static func mascara_de(mapa: MapAttributes) -> Dictionary:
	if mapa == null:
		return {}
	if mapa.has_meta(META_MASCARA):
		return mapa.get_meta(META_MASCARA)
	var datos: Dictionary = {}
	var capa: TileMapLayer = mapa.get_node_or_null(RUTA_COLISIONES) as TileMapLayer
	var tamano: Vector2i = Vector2i(maxi(mapa.map_size.x, 1), maxi(mapa.map_size.y, 1))
	if capa != null:
		var imagen: Image = Image.create(tamano.x, tamano.y, false, Image.FORMAT_L8)
		var hay_agua: bool = false
		for celda: Vector2i in capa.get_used_cells():
			if celda.x < 0 or celda.y < 0 or celda.x >= tamano.x or celda.y >= tamano.y:
				continue
			var tile: TileData = capa.get_cell_tile_data(celda)
			if tile != null and tile.has_custom_data("surf") and bool(tile.get_custom_data("surf")):
				imagen.set_pixelv(celda, Color.WHITE)
				hay_agua = true
		if hay_agua:
			var dibujo: Image = imagen.duplicate() as Image
			for y: int in range(tamano.y - 1):
				for x: int in range(tamano.x):
					if imagen.get_pixel(x, y + 1).r > 0.5:
						dibujo.set_pixel(x, y, Color.WHITE)
			datos = {"imagen": imagen, "textura": ImageTexture.create_from_image(dibujo)}
	mapa.set_meta(META_MASCARA, datos)
	return datos


func _ready() -> void:
	# Sobre el suelo y bajo los personajes. top_level para quedar delante del
	# reflejo del seguidor.
	top_level = true
	z_as_relative = false
	z_index = 0
	flip_v = true
	visible = false
	_material = ShaderMaterial.new()
	_material.shader = SHADER
	material = _material
	var nodo: Node = get_parent()
	while nodo != null and not (nodo is CharacterController):
		nodo = nodo.get_parent()
	_personaje = nodo as CharacterController


func _process(_delta: float) -> void:
	var mapa: MapAttributes = _personaje.mapa_raiz as MapAttributes if _personaje != null else null
	var mascara: Dictionary = mascara_de(mapa)
	var cuadro: Texture2D = null
	if fuente != null and fuente.sprite_frames != null and fuente.is_visible_in_tree():
		cuadro = fuente.sprite_frames.get_frame_texture(fuente.animation, fuente.frame)
	if cuadro == null or mascara.is_empty():
		visible = false
		return

	texture = cuadro
	centered = fuente.centered
	flip_h = fuente.flip_h
	global_position = fuente.global_position
	global_scale = fuente.global_scale
	var bajada: float = _bajada_por_puente(mapa, mascara["imagen"], cuadro.get_height())
	offset = Vector2(fuente.offset.x, fuente.offset.y + cuadro.get_height() + ajuste_y + bajada)

	if mapa != _mapa:
		_mapa = mapa
		_material.set_shader_parameter("mascara", mascara["textura"])
		_material.set_shader_parameter("mascara_tamano", Vector2(mapa.map_size))
		_material.set_shader_parameter("tile_size", float(mapa.tile_size))
	_material.set_shader_parameter("mascara_origen", mapa.global_position)
	visible = _hay_agua_debajo(mapa, mascara["imagen"])


## En un puente el reflejo baja hasta la fila de las vigas.
func _bajada_por_puente(mapa: MapAttributes, imagen: Image, alto_sprite: float) -> float:
	var ts: float = float(mapa.tile_size)
	var bajo_pies: float = fuente.offset.y + (alto_sprite * 0.5 if fuente.centered else alto_sprite)
	var pies: Vector2 = fuente.global_position + Vector2(0.0, bajo_pies * fuente.global_scale.y - 0.5)
	var casilla: Vector2i = Vector2i(((pies - mapa.global_position) / ts).floor())
	if _es_agua(imagen, casilla):
		return 0.0
	var filas_abajo: int = _distancia_al_agua(imagen, casilla, 1)
	if filas_abajo <= 2 or _distancia_al_agua(imagen, casilla, -1) < 0:
		return 0.0
	return float(filas_abajo - 2) * ts


## -1 si no hay agua. Los huecos sueltos entre vigas no cuentan.
func _distancia_al_agua(imagen: Image, casilla: Vector2i, direccion: int) -> int:
	for filas: int in range(1, MAX_FILAS_PUENTE + 1):
		var celda: Vector2i = casilla + Vector2i(0, filas * direccion)
		if not _es_agua(imagen, celda):
			continue
		var hueco: bool = not _es_agua(imagen, celda + Vector2i.LEFT) and not _es_agua(imagen, celda + Vector2i.RIGHT)
		if not hueco:
			return filas
	return -1


func _es_agua(imagen: Image, celda: Vector2i) -> bool:
	if celda.x < 0 or celda.y < 0 or celda.x >= imagen.get_width() or celda.y >= imagen.get_height():
		return false
	return imagen.get_pixelv(celda).r > 0.5


func _hay_agua_debajo(mapa: MapAttributes, imagen: Image) -> bool:
	var rect: Rect2 = Rect2(global_position + offset * global_scale.abs(), texture.get_size() * global_scale.abs())
	if centered:
		rect.position -= rect.size * 0.5
	var ts: float = float(mapa.tile_size)
	var desde: Vector2i = Vector2i(((rect.position - mapa.global_position) / ts).floor())
	var hasta: Vector2i = Vector2i(((rect.end - mapa.global_position) / ts).floor())
	for y: int in range(maxi(desde.y, 0), mini(hasta.y, imagen.get_height() - 1) + 1):
		for x: int in range(maxi(desde.x, 0), mini(hasta.x, imagen.get_width() - 1) + 1):
			if imagen.get_pixel(x, y).r > 0.5:
				return true
	return false
