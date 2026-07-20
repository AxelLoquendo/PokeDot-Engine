extends Node
class_name TiempoManager

enum TimeOfDay { MORNING, DAY, DUSK, NIGHT }

var current_hour: int = 0
var current_time_state: TimeOfDay = TimeOfDay.DAY
var _activo: bool = false

const COLOR_MORNING: Color = Color(1.08, 1.02, 0.90, 1.0)
const COLOR_DAY: Color     = Color(1.00, 1.00, 1.00, 1.0)
const COLOR_DUSK: Color    = Color(1.12, 0.592, 0.456, 1.0)
const COLOR_NIGHT: Color   = Color(0.423, 0.388, 1.1, 1.0)

var canvas_modulate: CanvasModulate


func _ready() -> void:
	var raiz: Node = get_tree().root
	
	if raiz.has_node("FiltroDiaNoche"):
		raiz.get_node("FiltroDiaNoche").queue_free()
	
	canvas_modulate = CanvasModulate.new()
	canvas_modulate.name = "FiltroDiaNoche"
	canvas_modulate.z_index = 4096
	raiz.add_child.call_deferred(canvas_modulate)
	
	print("Filtro creado en raíz")
	desactivar()


func _process(delta: float) -> void:
	if not _activo: return

	_read_system_time()
	_smooth_transition(delta)


func _leer_configuracion_mapa() -> bool:
	var gestor: Node = get_tree().root.get_node_or_null("Gestor_Inicio")
	if not gestor:
		print("No se encontró el Gestor_Inicio")
		return false
	
	var mapa: MapAttributes = null
	for hijo: Node in gestor.get_children():
		if hijo is MapAttributes:
			mapa = hijo as MapAttributes
			break
	
	var _es_interior: String = "ninguno"
	if mapa != null:
		_es_interior = str(mapa.is_indoor)
	
	var resultado: bool = mapa != null and not mapa.is_indoor
	#print("Mapa detectado: ", mapa != null, " | Es interior: ", _es_interior, " → Aplica filtro: ", resultado)
	return resultado


func _read_system_time() -> void:
	var now: Dictionary = Time.get_datetime_dict_from_system()
	current_hour = now.hour

	var new_state: TimeOfDay = _get_state(current_hour)
	if new_state != current_time_state:
		current_time_state = new_state
		print("Cambio horario → ", TimeOfDay.keys()[int(current_time_state)])


func _get_state(h: int) -> TimeOfDay:
	if h >= 5  and h < 10: return TimeOfDay.MORNING
	if h >= 10 and h < 18: return TimeOfDay.DAY
	if h >= 18 and h < 20: return TimeOfDay.DUSK
	return TimeOfDay.NIGHT


func _smooth_transition(delta: float) -> void:
	var debe_aplicar: bool = _leer_configuracion_mapa()
	
	if not debe_aplicar:
		if canvas_modulate.color != COLOR_DAY:
			canvas_modulate.color = canvas_modulate.color.lerp(COLOR_DAY, delta * 2.0)
		return

	var target: Color
	match current_time_state:
		TimeOfDay.MORNING: target = COLOR_MORNING
		TimeOfDay.DAY:     target = COLOR_DAY
		TimeOfDay.DUSK:    target = COLOR_DUSK
		TimeOfDay.NIGHT:   target = COLOR_NIGHT

	var velocidad: float = 1.5
	canvas_modulate.color = canvas_modulate.color.lerp(target, delta * velocidad)
	#print("Color actual: ", canvas_modulate.color)


func _apply_state(_instant: bool = false) -> void:
	if not _activo: return
	
	var debe_aplicar: bool = _leer_configuracion_mapa()
	if not debe_aplicar:
		canvas_modulate.color = COLOR_DAY
		return

	var target: Color
	match current_time_state:
		TimeOfDay.MORNING: target = COLOR_MORNING
		TimeOfDay.DAY:     target = COLOR_DAY
		TimeOfDay.DUSK:    target = COLOR_DUSK
		TimeOfDay.NIGHT:   target = COLOR_NIGHT

	canvas_modulate.color = target


func activar() -> void:
	_activo = true
	_apply_state(true)
	print("Sistema día/noche ACTIVADO")


func desactivar() -> void:
	_activo = false
	canvas_modulate.color = COLOR_DAY
	print("Sistema día/noche DESACTIVADO")
