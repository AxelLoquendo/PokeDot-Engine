extends Node2D
class_name RainDrop


enum RainState {
	FALLING,
	SPLASH
}

var camara: Camera2D
var ultima_posicion_camara: Vector2

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D


var state: RainState = RainState.FALLING

var velocidad: float = 600.0
var direccion: Vector2 = Vector2(-0.32, 1.0)

var viewport_size: Vector2


func _ready() -> void:

	z_index = 3001

	camara = get_viewport().get_camera_2d()

	viewport_size = get_viewport_rect().size

	if camara:
		ultima_posicion_camara = camara.global_position

	iniciar()

func obtener_area_camara() -> Rect2:

	if camara == null:
		camara = get_viewport().get_camera_2d()

	if camara == null:
		return Rect2(Vector2.ZERO, viewport_size)


	return Rect2(
		camara.global_position - viewport_size / 2,
		viewport_size
	)

func iniciar() -> void:

	velocidad = randf_range(
		500.0,
		800.0
	)

	direccion = Vector2(randf_range(-0.38, -0.28), 1.0)

	reiniciar()



func _process(delta: float) -> void:

	if state == RainState.FALLING:

		if camara:

			var movimiento_camara: Vector2 = (
				camara.global_position - ultima_posicion_camara
			)

			position += movimiento_camara

			ultima_posicion_camara = camara.global_position


		caer(delta)

func caer(delta: float) -> void:

	position += direccion * velocidad * delta


	# fuera de pantalla
	var area: Rect2 = obtener_area_camara()

	if (position.y > area.end.y + 50 or position.x < area.position.x - 50 or position.x > area.end.x + 50):
		mostrar_splash()

func mostrar_splash() -> void:

	state = RainState.SPLASH


	var area: Rect2 = obtener_area_camara()


	position = Vector2(
		randf_range(
			area.position.x,
			area.end.x
		),
		randf_range(
			area.position.y,
			area.end.y
		)
	)


	sprite.play("splash")


	await sprite.animation_finished


	reiniciar()

func reiniciar() -> void:

	state = RainState.FALLING


	if camara:
		ultima_posicion_camara = camara.global_position


	var area: Rect2 = obtener_area_camara()


	position = Vector2(
		randf_range(
			area.position.x,
			area.end.x
		),
		randf_range(
			area.position.y - 300,
			area.position.y - 50
		)
	)


	sprite.play("fall")


	sprite.frame = randi_range(
		0,
		sprite.sprite_frames.get_frame_count("fall") - 1
	)
