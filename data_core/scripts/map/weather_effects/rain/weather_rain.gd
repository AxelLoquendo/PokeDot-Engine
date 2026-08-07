extends WeatherBase
class_name RainWeather


const RainDropScene: PackedScene = preload("res://data_core/scripts/map/weather_effects/rain/rain_drop.tscn")


var cantidad_gotas: int = 50
var intensidad: float = 1.0

var deteniendo: bool = false

var gotas: Array[RainDrop] = []


func start() -> void:

	deteniendo = false

	intensidad = 0.0

	print("Comienza lluvia")

	for i: int in range(cantidad_gotas):
		crear_gota()



func crear_gota() -> void:

	var gota: RainDrop = RainDropScene.instantiate()

	get_tree().current_scene.add_child(gota)

	gota.position = Vector2(
		randf_range(0, 1152),
		randf_range(-300, 700)
	)

	gota.iniciar()

	gotas.append(gota)



func stop() -> void:

	print("Finaliza lluvia")

	for gota: RainDrop in gotas:
		if is_instance_valid(gota):
			gota.begin_fade_out()

	gotas.clear()

func fade_in() -> void:

	var tween: Tween = create_tween()

	tween.tween_property(
		self,
		"intensidad",
		1.0,
		0.8
	)

	await tween.finished

func fade_out() -> void:

	deteniendo = true

	var tween: Tween = create_tween()

	tween.tween_property(
		self,
		"intensidad",
		0.0,
		0.8
	)

	await tween.finished

func update(_delta: float) -> void:

	pass
