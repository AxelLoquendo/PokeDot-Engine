extends CanvasLayer

@onready var primary: Sprite2D = $Primary
@onready var secondary: Sprite2D = $Secondary
@onready var primary_anim: AnimationPlayer = $Primary_anim
@onready var second_anim: AnimationPlayer = $Second_anim
@onready var map_name_label: Label = $Primary/MapName
@onready var time_label: Label = $Secondary/Time


func _ready() -> void:
	visible = false


func mostrar_mapa(mapa: MapAttributes) -> void:
	if mapa == null or not mapa.show_location_name:
		return

	map_name_label.text = mapa.map_name
	time_label.text = obtener_hora_actual()

	visible = true
	primary_anim.play("Entrar")
	second_anim.play("Entrar")

	await primary_anim.animation_finished
	await get_tree().create_timer(2.0).timeout

	primary_anim.play("Salir")
	second_anim.play("Salir")
	await primary_anim.animation_finished

	visible = false


func obtener_hora_actual() -> String:
	var tiempo: Dictionary = Time.get_time_dict_from_system()
	var hora: int = int(tiempo.get("hour", 0))
	var minuto: int = int(tiempo.get("minute", 0))

	var periodo: String = "AM"
	if hora >= 12:
		periodo = "PM"

	var hora_12: int = hora % 12
	if hora_12 == 0:
		hora_12 = 12

	return "%02d:%02d %s" % [hora_12, minuto, periodo]
