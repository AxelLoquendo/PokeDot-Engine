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
@onready var container_opciones: VBoxContainer = $Control/CajaDialogo/ContainerOpciones

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
var choice_position: Vector2 = Vector2(-1, -1)
var default_choice_position: Vector2 = Vector2.ZERO
var botones_pool: Array[Button] = []
const MAX_OPCIONES: int = 4


func _ready() -> void:
	print("DialogueBox cargado")
	visible = false
	texto.text = ""
	nombre.text = ""
	flecha_dialogo.visible = false
	
	if container_opciones != null:
		default_choice_position = container_opciones.position
		container_opciones.visible = false
		_preparar_botones()


func _preparar_botones() -> void:
	# Cargamos la fuente una sola vez
	var fuente_personalizada: FontFile = load("res://pokemon-emerald-pro.ttf") as FontFile
	
	# Validación por si la ruta está mal o el archivo no existe
	if fuente_personalizada == null:
		push_error("No se pudo cargar la fuente 'pokemon-emerald-pro.ttf'. Verifica la ruta.")
	
	for i: int in range(MAX_OPCIONES):
		var btn: Button = Button.new()
		btn.name = "BtnOpcion_%d" % i
		btn.visible = false
		
		# --- APLICACIÓN DE LA FUENTE ---
		if fuente_personalizada != null:
			# Asignamos la fuente al tema del botón para el estado normal
			btn.add_theme_font_override("font", fuente_personalizada)
			# Opcional: Ajustar tamaño si la fuente por defecto es muy pequeña/grande
			btn.add_theme_font_size_override("font_size", 32) 
		else:
			# Fallback por si falla la carga (usa la fuente por defecto del proyecto)
			pass
		# -------------------------------
		
		btn.pressed.connect(_on_opcion_presionada.bind(i))
		container_opciones.add_child(btn)
		botones_pool.append(btn)


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
		esperando_eleccion = true
	else:
		flecha_dialogo.visible = true


func _mostrar_opciones(choices: Array[DialogueChoice]) -> void:
	if container_opciones == null:
		push_error("Falta el nodo ContainerOpciones en la escena del DialogueBox")
		return
		
	container_opciones.visible = true
	if choice_position.x >= 0.0 and choice_position.y >= 0.0:
		container_opciones.position = choice_position
	else:
		container_opciones.position = default_choice_position
	var indice_valido: int = 0
	
	for btn: Button in botones_pool:
		btn.visible = false

	for choice: DialogueChoice in choices:
		if indice_valido >= MAX_OPCIONES:
			push_warning("Demasiadas opciones en diálogo. Máximo: %d" % MAX_OPCIONES)
			break
			
		var btn: Button = botones_pool[indice_valido]
		btn.text = choice.text
		btn.visible = true
		btn.set_meta("dato_elecion", choice)
		
		indice_valido += 1


func _ocultar_opciones() -> void:
	if container_opciones != null:
		container_opciones.visible = false
	for btn: Button in botones_pool:
		btn.visible = false


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

	# 2. Lógica de corrección: Si NO hay next_page_id
	# Si la página tiene elecciones (es un punto de decisión), NO avanzamos automáticamente.
	# Esto evita caer en la rama del "No" después de elegir "Sí".
	if pagina_recurso.has_choices():
		cerrar()
		return

	# 3. Comportamiento por defecto: Avanzar a la siguiente página lineal
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

	# El runner puede abrir otro diálogo inmediatamente. Por eso toda la
	# limpieza debe terminar antes de notificar al NPC.
	if npc_a_notificar != null:
		npc_a_notificar.terminar_dialogo()
	dialogue_closed.emit()


func _on_opcion_presionada(indice: int) -> void:
	if indice < 0 or indice >= botones_pool.size():
		push_error("Índice de opción fuera de rango: %d" % indice)
		return
	
	var btn: Button = botones_pool[indice]
	if not btn.visible:
		return

	var opcion: DialogueChoice = btn.get_meta("dato_elecion") as DialogueChoice
	if opcion == null:
		push_error("Meta 'dato_elecion' no es válida o es null en botón índice %d" % indice)
		return

	if not opcion.choice_id.is_empty():
		choice_selected.emit(opcion.choice_id)

	var siguiente_id: String = opcion.next_page_id
	
	esperando_eleccion = false
	_ocultar_opciones()
	
	if not siguiente_id.is_empty():
		bloqueado = false
		var indice_destino: int = _buscar_indice_por_id(siguiente_id)
		
		if indice_destino != -1:
			pagina_actual = indice_destino
			mostrar_pagina()
		else:
			print("No se encontró la página con ID: '%s' en el diálogo actual." % siguiente_id)
			cerrar()
	else:
		# Si la opción no tiene destino, cerramos el diálogo inmediatamente
		bloqueado = true
		cerrar()
