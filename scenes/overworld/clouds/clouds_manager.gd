extends Node2D

var lista_nubes: Array[Texture2D] = [
	preload("res://scenes/overworld/clouds/clouds.png"),
]

@export var velocidad_min: float = 1.5
@export var velocidad_max: float = 4.0
@export var tiempo_creacion: float = 1.8
@export var alto_min: float = 40.0
@export var alto_max: float = 280.0
@export var color_base_nubes: Color = Color("ffffff44")
@export var maximo_nubes_activas: int = 10
@export var separacion_minima_x: float = 60.0
@export var separacion_minima_y: float = 25.0
@export var margen_fuera: float = 50.0

var _activo: bool = true # ✅ EMPIEZA ACTIVADO
var temporizador_nubes: Timer
var camara_actual: Camera2D


func _ready() -> void:
	randomize()
	z_index = 3001
	camara_actual = get_viewport().get_camera_2d()

	temporizador_nubes = Timer.new()
	temporizador_nubes.wait_time = tiempo_creacion
	temporizador_nubes.timeout.connect(crear_nube_entrante)
	temporizador_nubes.autostart = true
	add_child(temporizador_nubes)

	# ❌ ELIMINAMOS la llamada a desactivar() que bloqueaba todo
	print("Sistema de nubes INICIALIZADO")


func hay_superposicion(nueva_x: float, nueva_y: float) -> bool:
	for hijo: Node in get_children():
		if hijo is Sprite2D:
			var nube: Sprite2D = hijo as Sprite2D
			if nube.texture == null:
				continue
			var ancho: float = nube.texture.get_width() * nube.scale.x
			var alto: float = nube.texture.get_height() * nube.scale.y
			if abs(nube.position.x - nueva_x) < max(separacion_minima_x, ancho * 0.5) and abs(nube.position.y - nueva_y) < max(separacion_minima_y, alto * 0.5):
				return true
	return false


func crear_nube_en_borde(pos_y: float) -> void:
	if not camara_actual:
		return
	var rect_camara: Rect2 = camara_actual.get_viewport_rect()
	var borde_derecho: float = rect_camara.end.x + margen_fuera
	crear_nube(borde_derecho, pos_y)


func crear_nube(pos_x: float, pos_y: float) -> void:
	if not _activo or get_child_count() >= maximo_nubes_activas or hay_superposicion(pos_x, pos_y) or lista_nubes.is_empty():
		return

	var nube: Sprite2D = Sprite2D.new()
	nube.texture = lista_nubes[randi() % lista_nubes.size()]
	nube.position = Vector2(pos_x, pos_y)
	z_index = 3001
	var escala: float = randf_range(0.6, 1.0)
	nube.scale = Vector2.ONE * escala
	var brillo: float = randf_range(0.9,1.05)
	var alpha: float = color_base_nubes.a * randf_range(0.7, 1.0)
	nube.modulate = Color(color_base_nubes.r * brillo, color_base_nubes.g * brillo, color_base_nubes.b * brillo, alpha)
	nube.set_meta("velocidad", -randf_range(velocidad_min, velocidad_max))
	add_child(nube)


func cambiar_color_nubes(nuevo_color: Color) -> void:
	color_base_nubes = nuevo_color
	for hijo: Node in get_children():
		if hijo is Sprite2D:
			var nube: Sprite2D = hijo as Sprite2D
			nube.modulate = Color(nuevo_color.r, nuevo_color.g, nuevo_color.b, nube.modulate.a)


func crear_nube_entrante() -> void:
	if not _activo or not camara_actual:
		return
	var rect_camara: Rect2 = camara_actual.get_viewport_rect()
	var nueva_pos_x: float = rect_camara.end.x + margen_fuera
	var intentos: int = 0
	while intentos < 30:
		var nueva_pos_y: float = randf_range(alto_min, alto_max)
		if not hay_superposicion(nueva_pos_x, nueva_pos_y):
			crear_nube(nueva_pos_x, nueva_pos_y)
			return
		intentos += 1


func _process(delta: float) -> void:
	if not _activo:
		return

	var debe_haber_nubes: bool = _leer_configuracion_mapa()

	if not debe_haber_nubes:
		if temporizador_nubes:
			temporizador_nubes.paused = true
		visible = false
		for hijo: Node in get_children():
			if hijo is Sprite2D:
				hijo.queue_free()
		return

	if temporizador_nubes:
		temporizador_nubes.paused = false
	visible = true

	var cantidad: int = 0
	for hijo: Node in get_children():
		if hijo is Sprite2D:
			cantidad += 1

	if cantidad == 0:
		crear_nubes_iniciales()

	if camara_actual == null:
		camara_actual = get_viewport().get_camera_2d()
	if camara_actual == null:
		return

	var rect_camara: Rect2 = camara_actual.get_viewport_rect()
	for hijo: Node in get_children():
		if hijo is Sprite2D:
			var nube: Sprite2D = hijo as Sprite2D
			var velocidad: float = nube.get_meta("velocidad", -2.5)
			nube.position.x += velocidad * delta
			if nube.texture:
				var ancho: float = nube.texture.get_width() * nube.scale.x
				if nube.position.x + ancho * 0.5 < rect_camara.position.x - margen_fuera:
					nube.queue_free()


func activar() -> void:
	_activo = true
	visible = true
	if temporizador_nubes:
		temporizador_nubes.paused = false
	print("NUBES ACTIVADAS")
	if get_child_count() == 0:
		crear_nubes_iniciales()


func crear_nubes_iniciales() -> void:
	for _i: int in range(5):
		crear_nube(randf_range(0.0, 500.0), randf_range(alto_min, alto_max))


func desactivar() -> void:
	_activo = false
	visible = false
	if temporizador_nubes:
		temporizador_nubes.paused = true
	for hijo: Node in get_children():
		if hijo is Sprite2D:
			hijo.queue_free()
	print("NUBES DESACTIVADAS")


func _leer_configuracion_mapa() -> bool:
	var gestor: Node = get_tree().root.get_node_or_null("Gestor_Inicio")
	if gestor == null:
		print("No existe Gestor_Inicio → Nubes activas por defecto")
		return true

	var manager: MapManager = null
	for hijo: Node in gestor.get_children():
		if hijo is MapManager:
			manager = hijo as MapManager
			break

	if manager == null:
		print("No existe MapManager → Nubes activas por defecto")
		return true

	var mapa: MapAttributes = manager.current_map
	if mapa == null:
		print("No hay mapa actual → Nubes activas por defecto")
		return true

	#print("Mapa:", mapa.map_name, " | usar_nubes:", mapa.usar_nubes, " | indoor:", mapa.is_indoor)
	return mapa.usar_nubes and not mapa.is_indoor
