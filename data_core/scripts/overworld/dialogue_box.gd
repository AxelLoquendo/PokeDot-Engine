extends CanvasLayer

class_name DialogueBox

@onready var animaciones: AnimationPlayer = $Control/Animacion
@onready var caja: TextureRect = $Control/CajaDialogo
@onready var nombre: Label = $Control/CajaDialogo/NameLabel
@onready var texto: Label = $Control/CajaDialogo/TextLabel
@onready var flecha_dialogo: Sprite2D = $Control/CajaDialogo/Flecha
@onready var sonido_dialogo: AudioStreamPlayer = $SonidoTexto

var dialogo_abierto: bool = false
var npc_actual: CharacterController

var escribiendo: bool = false
var pagina_actual: int = 0
var dialogo_actual: Dialogue
var texto_completo: String = ""
var id_escritura: int = 0
static var activo: bool = false
var animando: bool = false
var cerrando: bool = false
var bloqueado: bool = false

func _ready() -> void:
	print("DialogueBox cargado")

	visible = false
	texto.text = ""
	nombre.text = ""
	flecha_dialogo.visible = false


func iniciar(_dialogo: Dialogue, _nombre_personaje: String, _npc: CharacterController) -> void:
	npc_actual = _npc

	bloqueado = true
	activo = true
	dialogo_abierto = true

	dialogo_actual = _dialogo
	pagina_actual = 0

	nombre.text = _nombre_personaje

	texto.text = ""
	texto_completo = ""
	flecha_dialogo.visible = false

	visible = true

	sonido_dialogo.play()

	animaciones.play("inicio")
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

	for letra: String in texto_completo:
		if escritura_actual != id_escritura:
			return

		if not escribiendo:
			break

		texto.text += letra
		await get_tree().create_timer(0.03).timeout

	escribiendo = false

func siguiente_pagina() -> void:
	if dialogo_actual == null:
		return

	if pagina_actual + 1 >= dialogo_actual.pages.size():
		cerrar()
		return

	pagina_actual += 1
	mostrar_pagina()

func _unhandled_input(event: InputEvent) -> void:
	if not dialogo_abierto or bloqueado:
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

func cerrar() -> void:
	if cerrando:
		return

	cerrando = true

	dialogo_abierto = false

	id_escritura += 1
	escribiendo = false

	texto.text = ""
	nombre.text = ""

	animaciones.play("fin")
	await animaciones.animation_finished

	visible = false

	activo = false

	if npc_actual:
		npc_actual.terminar_dialogo()
		npc_actual = null

	cerrando = false

	dialogo_actual = null
	pagina_actual = 0
