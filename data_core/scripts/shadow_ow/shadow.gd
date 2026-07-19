extends Sprite2D
class_name CharacterShadow

enum ShadowSize { NONE, S, M, L, XL }

var shadow_textures: Array[String] = [
	"",
	"res://graphics/overworld/shadow/shadow_small.png",
	"res://graphics/overworld/shadow/shadow_medium.png",
	"res://graphics/overworld/shadow/shadow_large.png",
	"res://graphics/overworld/shadow/shadow_extra_large.png"
]

var datos_vinculados: CharacterGame


func _ready() -> void:
	position = Vector2.ZERO
	var controlador: CharacterController = get_parent() as CharacterController
	if controlador and controlador.character_data:
		_vincular_datos(controlador.character_data)
	actualizar_sombra()


func _vincular_datos(nuevos_datos: CharacterGame) -> void:
	if datos_vinculados:
		datos_vinculados.changed.disconnect(actualizar_sombra)
	datos_vinculados = nuevos_datos
	if datos_vinculados:
		datos_vinculados.changed.connect(actualizar_sombra)
		actualizar_sombra()


func actualizar_sombra() -> void:
	if not datos_vinculados:
		visible = false
		return

	var indice: int = datos_vinculados.shadow_size
	if indice < 0 or indice >= shadow_textures.size():
		visible = false
		return

	var ruta: String = shadow_textures[indice]
	if ruta == "":
		visible = false
		return

	if not texture or texture.resource_path != ruta:
		var textura: CompressedTexture2D = load(ruta) as CompressedTexture2D
		if not textura:
			visible = false
			return
		texture = textura

	position = Vector2(
		datos_vinculados.shadow_offset_x,
		datos_vinculados.shadow_offset_y
	)
	modulate = Color("ffffff81")
	visible = true
