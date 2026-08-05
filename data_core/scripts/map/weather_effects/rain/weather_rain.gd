extends WeatherBase
class_name RainWeather


const RainDropScene: PackedScene = preload("res://data_core/scripts/map/weather_effects/rain/rain_drop.tscn")


var cantidad_gotas: int = 50


var gotas: Array[RainDrop] = []


func start() -> void:

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

		gota.queue_free()

	gotas.clear()



func update(_delta: float) -> void:

	pass
