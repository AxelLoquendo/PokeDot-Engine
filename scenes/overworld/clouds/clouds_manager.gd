extends Node2D
# -----------------------------------------------------------
# AUTOLOAD global. Ver notas de versiones anteriores.
# -----------------------------------------------------------

var lista_nubes: Array[Texture2D] = [
	preload("res://scenes/overworld/clouds/clouds.png"),
]

@export var velocidad_min: float = 1.5
@export var velocidad_max: float = 4.0
@export var tiempo_creacion: float = 1.8
@export var alto_min: float = 40.0
@export var alto_max: float = 280.0
@export var color_base_nubes: Color = Color("ffffff44")
@export var maximo_nubes_activas: int = 20
@export var separacion_minima_x: float = 60.0
@export var separacion_minima_y: float = 25.0
@export var margen_fuera: float = 50.0
@export var duracion_transicion: float = 0.8

# Si el mapa actual quiere nubes visibles (controla el fade).
var _desea_nubes: bool = true

# Alpha objetivo animado (0.0 a 1.0). El modulate.a del propio
# CloudsManager se ata a esto, y como es CanvasItem, se propaga
# a todos los Sprite2D hijos automáticamente.
var intensidad: float = 1.0

var _fade_tween: Tween
var temporizador_nubes: Timer
var camara_actual: Camera2D
var _map_manager: MapManager


func _ready() -> void:
	randomize()
	z_index = 3003

	camara_actual = get_viewport().get_camera_2d()
	modulate.a = intensidad

	temporizador_nubes = Timer.new()
	temporizador_nubes.wait_time = tiempo_creacion
	temporizador_nubes.timeout.connect(crear_nube_entrante)
	temporizador_nubes.autostart = true
	add_child(temporizador_nubes)

#	print("Sistema de nubes INICIALIZADO (global)")


func hay_superposicion(nueva_x: float, nueva_y: float) -> bool:
	for hijo: Node in get_children():
		if hijo is Sprite2D:
			var nube: Sprite2D = hijo as Sprite2D
			if nube.texture == null:
				continue
			var ancho: float = nube.texture.get_width() * nube.scale.x
			var alto: float = nube.texture.get_height() * nube.scale.y
			if (
				abs(nube.position.x - nueva_x) < max(separacion_minima_x, ancho * 0.5)
				and abs(nube.position.y - nueva_y) < max(separacion_minima_y, alto * 0.5)
			):
				return true
	return false


func crear_nube_en_borde(pos_y: float) -> void:
	if not camara_actual:
		return
	var rect_camara: Rect2 = camara_actual.get_viewport_rect()
	var borde_derecho: float = rect_camara.end.x + margen_fuera
	crear_nube(borde_derecho, pos_y)


func crear_nube(pos_x: float, pos_y: float) -> void:
	# Ya no depende de "_activo": mientras el mapa quiera nubes,
	# se pueden seguir creando, aunque estén a mitad de un fade-in.
	if (
		not _desea_nubes
		or get_child_count() >= maximo_nubes_activas
		or hay_superposicion(pos_x, pos_y)
		or lista_nubes.is_empty()
	):
		return

	var nube: Sprite2D = Sprite2D.new()
	nube.texture = lista_nubes[randi() % lista_nubes.size()]
	nube.position = Vector2(pos_x, pos_y)
	z_index = 3001

	var escala: float = randf_range(0.6, 1.0)
	nube.scale = Vector2.ONE * escala

	var brillo: float = randf_range(0.9, 1.05)
	var alpha: float = color_base_nubes.a * randf_range(0.7, 1.0)
	nube.modulate = Color(
		color_base_nubes.r * brillo,
		color_base_nubes.g * brillo,
		color_base_nubes.b * brillo,
		alpha
	)

	nube.set_meta("velocidad", -randf_range(velocidad_min, velocidad_max))
	add_child(nube)


func cambiar_color_nubes(nuevo_color: Color) -> void:
	color_base_nubes = nuevo_color
	for hijo: Node in get_children():
		if hijo is Sprite2D:
			var nube: Sprite2D = hijo as Sprite2D
			nube.modulate = Color(nuevo_color.r, nuevo_color.g, nuevo_color.b, nube.modulate.a)


func crear_nube_entrante() -> void:
	if not _desea_nubes or not camara_actual:
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
	var debe_haber_nubes: bool = _leer_configuracion_mapa()

	if debe_haber_nubes != _desea_nubes:
		_desea_nubes = debe_haber_nubes
		if _desea_nubes:
			activar()
		else:
			desactivar()

	# El movimiento de las nubes existentes NUNCA se detiene de
	# golpe: sigue corriendo aunque estén en medio de un fade-out,
	# para que no se vean "congeladas" mientras se desvanecen.
	if camara_actual == null:
		camara_actual = get_viewport().get_camera_2d()

	if camara_actual == null:
		return

	var rect_camara: Rect2 = camara_actual.get_viewport_rect()

	for hijo: Node in get_children():
		if hijo is Sprite2D:
			var nube: Sprite2D = hijo
			var velocidad: float = nube.get_meta("velocidad", -2.5)

			nube.position.x += velocidad * delta

			if nube.texture:
				var ancho: float = nube.texture.get_width() * nube.scale.x
				if nube.position.x + ancho * 0.5 < rect_camara.position.x - margen_fuera:
					nube.queue_free()


func activar() -> void:
	if temporizador_nubes:
		temporizador_nubes.paused = false

	var cantidad: int = 0
	for hijo: Node in get_children():
		if hijo is Sprite2D:
			cantidad += 1

	# Solo crea nubes iniciales si de verdad no hay ninguna
	# (primera vez que un mapa con nubes se activa en la partida).
	if cantidad == 0:
		crear_nubes_iniciales()

	_fade_a(1.0)


func crear_nubes_iniciales() -> void:
	for _i: int in range(5):
		crear_nube(randf_range(0.0, 500.0), randf_range(alto_min, alto_max))


func desactivar() -> void:
	if temporizador_nubes:
		temporizador_nubes.paused = true

	# Intencional: NO se eliminan las nubes existentes.
	# Se desvanecen con el fade, pero siguen vivas en memoria
	# (y siguen moviéndose) por si el jugador vuelve pronto.
	_fade_a(0.0)


func _fade_a(objetivo: float) -> void:
	if _fade_tween:
		_fade_tween.kill()

	_fade_tween = create_tween()
	_fade_tween.tween_property(
		self,
		"intensidad",
		objetivo,
		duracion_transicion
	)
	_fade_tween.tween_callback(_aplicar_intensidad)

	# También actualizamos cada frame del tween, no solo al final.
	_fade_tween.step_finished.connect(_aplicar_intensidad)


func _aplicar_intensidad(_paso: int = 0) -> void:
	modulate.a = intensidad


func _leer_configuracion_mapa() -> bool:
	if _map_manager == null or not is_instance_valid(_map_manager):
		var gestor: Node = get_tree().root.get_node_or_null("Gestor_Inicio")
		if gestor == null:
			return true

		for hijo: Node in gestor.get_children():
			if hijo is MapManager:
				_map_manager = hijo as MapManager
				break

		if _map_manager == null:
			return true

	var mapa: MapAttributes = _map_manager.current_map
	if mapa == null:
		return true

	return mapa.usar_nubes and not mapa.is_indoor
