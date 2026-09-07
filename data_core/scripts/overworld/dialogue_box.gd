extends CanvasLayer
class_name DialogueBox

# Señal para notificar elecciones al sistema de guardado/quest
signal choice_selected(choice_id: String)
signal dialogue_closed()

# --- Referencias a nodos ---
@onready var animaciones: AnimationPlayer = $Control/Animacion
@onready var animaciones_cn: AnimationPlayer = $Control/Animacion_CN
@onready var caja: TextureRect = $Control/CajaDialogo
@onready var caja_nombre: TextureRect = $Control/CajaNombre
@onready var nombre: Label = $Control/CajaNombre/NameLabel
@onready var texto: Label = $Control/CajaDialogo/TextLabel
@onready var flecha_dialogo: Sprite2D = $Control/CajaDialogo/Flecha
@onready var sonido_dialogo: AudioStreamPlayer = $SonidoTexto

# --- Multichoice externo ---
@onready var multichoice: MultichoiceBox = get_tree().get_first_node_in_group("multichoice_box")

# --- Variables de estado ---
var dialogo_abierto: bool = false
var npc_actual: CharacterController = null
var escribiendo: bool = false
var pagina_actual: int = 0
var dialogo_actual: Dialogue = null
var texto_completo: String = ""
var id_escritura: int = 0
static var activo: bool = false
var animando: bool = false
var cerrando: bool = false
var bloqueado: bool = false
var mostrar_caja_nombre: bool = false

# --- Variables para multichoice ---
var esperando_eleccion: bool = false
# Si la dejas en (-1, -1), la posición se calcula automáticamente pegada
# a la caja de diálogo (ver _calcular_posicion_opciones). Asígnala desde
# afuera solo si necesitas una posición fija puntual para un diálogo en
# concreto.
var choice_position: Vector2 = Vector2(-1, -1)

# Offset del menú de opciones respecto a la esquina superior derecha de
# la caja de diálogo. Ajusta estos valores a ojo hasta que quede pegado
# donde lo tiene pokeemerald expansion en tu layout.
const CHOICE_OFFSET_X: int = 0
const CHOICE_ABOVE_GAP: int = 8  # espacio entre el menú y la caja de diálogo
const CHOICE_OFFSET_Y: int = -10


func _ready() -> void:
	visible = false
	texto.text = ""
	nombre.text = ""
	flecha_dialogo.visible = false


func iniciar(_dialogo: Dialogue, _nombre_personaje: String = "", _npc: CharacterController = null) -> void:
	npc_actual = _npc
	bloqueado = true
	activo = true
	dialogo_abierto = true
	dialogo_actual = _dialogo
	pagina_actual = 0
	esperando_eleccion = false

	mostrar_nombre(_nombre_personaje)

	texto.text = ""
	texto_completo = ""
	flecha_dialogo.visible = false
	_ocultar_opciones()

	visible = true
	animaciones.play("inicio")
	if mostrar_caja_nombre:
		animaciones_cn.play("inicio")

	await animaciones.animation_finished

	bloqueado = false
	mostrar_pagina()


func mostrar_pagina() -> void:
	if dialogo_actual == null:
		return

	if pagina_actual >= dialogo_actual.pages.size():
		cerrar()
		return

	id_escritura += 1
	var escritura_actual: int = id_escritura
	var pagina: DialoguePage = dialogo_actual.pages[pagina_actual]

	texto_completo = pagina.text
	texto.text = ""
	escribiendo = true
	flecha_dialogo.visible = false
	_ocultar_opciones()
	esperando_eleccion = false

	sonido_dialogo.play()

	for letra: String in texto_completo:
		if escritura_actual != id_escritura:
			return
		if not escribiendo:
			break
		texto.text += letra
		await get_tree().create_timer(0.03).timeout

	escribiendo = false
	_verificar_tipo_pagina(pagina)


func _verificar_tipo_pagina(pagina: DialoguePage) -> void:
	if pagina.has_choices():
		_mostrar_opciones(pagina.choices)
	else:
		flecha_dialogo.visible = true


func _mostrar_opciones(choices: Array[DialogueChoice]) -> void:
	if multichoice == null:
		push_error("No se encontró MultichoiceBox en el grupo 'multichoice_box'")
		return

	esperando_eleccion = true

	if not multichoice.choice_selected.is_connected(_on_multichoice_selected):
		multichoice.choice_selected.connect(_on_multichoice_selected)

	var pos: Vector2 = choice_position if choice_position.x >= 0.0 else _calcular_posicion_opciones()
	multichoice.show_choices(choices, pos, true)


func _calcular_posicion_opciones() -> Vector2:
	# Punto inferior-izquierdo del menú: pegado al borde superior de la
	# caja de diálogo, con un pequeño margen (CHOICE_ABOVE_GAP).
	var caja_rect: Rect2 = caja.get_global_rect()
	return Vector2(
		caja_rect.position.x + CHOICE_OFFSET_X,
		caja_rect.position.y - CHOICE_ABOVE_GAP
	)


func _on_multichoice_selected(index: int, choice_id: String) -> void:
	esperando_eleccion = false

	if dialogo_actual == null or pagina_actual >= dialogo_actual.pages.size():
		cerrar()
		return

	var pagina: DialoguePage = dialogo_actual.pages[pagina_actual]
	if index < 0 or index >= pagina.choices.size():
		cerrar()
		return

	var opcion: DialogueChoice = pagina.choices[index]

	if not opcion.choice_id.is_empty():
		choice_selected.emit(opcion.choice_id)

	var siguiente_id: String = opcion.next_page_id

	if not siguiente_id.is_empty():
		bloqueado = false
		var indice_destino: int = _buscar_indice_por_id(siguiente_id)

		if indice_destino != -1:
			pagina_actual = indice_destino
			mostrar_pagina()
		else:
			print("No se encontró la página con ID: '%s'" % siguiente_id)
			cerrar()
	else:
		bloqueado = true
		cerrar()


func _ocultar_opciones() -> void:
	if multichoice != null:
		multichoice.hide_menu()


func siguiente_pagina() -> void:
	if dialogo_actual == null:
		return

	var pagina_recurso: DialoguePage = dialogo_actual.pages[pagina_actual]

	# 1. Prioridad: Si hay un next_page_id explícito, úsalo
	if not pagina_recurso.next_page_id.is_empty():
		var nuevo_index: int = _buscar_indice_por_id(pagina_recurso.next_page_id)
		if nuevo_index != -1:
			pagina_actual = nuevo_index
			mostrar_pagina()
			return
		else:
			cerrar()
		return

	# 2. Si la página tiene elecciones, no avanzamos automáticamente
	if pagina_recurso.has_choices():
		cerrar()
		return

	# 3. Comportamiento por defecto: avanzar a la siguiente página lineal
	if pagina_actual + 1 >= dialogo_actual.pages.size():
		cerrar()
		return

	pagina_actual += 1
	mostrar_pagina()


func _buscar_indice_por_id(id_busqueda: String) -> int:
	if dialogo_actual == null:
		return -1

	var pages_count: int = dialogo_actual.pages.size()
	for i: int in range(pages_count):
		if dialogo_actual.pages[i].page_id == id_busqueda:
			return i
	return -1


func _unhandled_input(event: InputEvent) -> void:
	if not dialogo_abierto or bloqueado:
		return

	if esperando_eleccion:
		return

	if event.is_action_pressed("buttonA"):
		get_viewport().set_input_as_handled()
		sonido_dialogo.play()

		if escribiendo:
			terminar_escritura()
		else:
			siguiente_pagina()


func terminar_escritura() -> void:
	escribiendo = false
	texto.text = texto_completo

	if dialogo_actual != null and pagina_actual < dialogo_actual.pages.size():
		_verificar_tipo_pagina(dialogo_actual.pages[pagina_actual])


func mostrar_nombre(nombre_personaje: String) -> void:
	mostrar_caja_nombre = not nombre_personaje.is_empty()
	caja_nombre.visible = mostrar_caja_nombre

	if mostrar_caja_nombre:
		nombre.text = nombre_personaje
	else:
		nombre.text = ""


func cerrar() -> void:
	if cerrando:
		return

	cerrando = true
	dialogo_abierto = false
	id_escritura += 1
	escribiendo = false
	esperando_eleccion = false

	texto.text = ""
	nombre.text = ""
	_ocultar_opciones()

	if mostrar_caja_nombre:
		animaciones_cn.play("fin")

	animaciones.play("fin")
	await animaciones.animation_finished

	caja_nombre.visible = false
	mostrar_caja_nombre = false
	visible = false
	activo = false

	var npc_a_notificar: CharacterController = npc_actual
	npc_actual = null
	dialogo_actual = null
	pagina_actual = 0
	cerrando = false

	# El runner puede abrir otro diálogo inmediatamente.
	# Por eso toda la limpieza debe terminar antes de notificar al NPC.
	if npc_a_notificar != null:
		npc_a_notificar.terminar_dialogo()

	dialogue_closed.emit()
