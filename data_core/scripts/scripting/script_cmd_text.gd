@tool
extends ScriptCommand
class_name ScriptCmdText

## Muestra un cuadro de texto con un mensaje
## Comando asíncrono: espera a que el jugador cierre el diálogo
##
## En scripts .txt se puede indicar el hablante por ID (como applymovement):
##   text "Hola" MSGBOX_NPC KAIDA
##   text "Hola" KAIDA

@export_multiline var message: String = "Hola, soy un NPC"
@export var messages: Array[String] = []
@export var speaker_name: String = ""  ## Nombre del hablante (vacío = usa nombre del NPC)
@export var speaker_id: StringName = &""  ## ID del hablante (npc_id / PLAYER_ID), como en applymovement
@export var show_portrait: bool = true
@export var choices: Array[String] = []
@export var choice_variable: String = ""
@export var hide_speaker: bool = false
@export var choice_position: Vector2 = Vector2(-1, -1)

func execute(context: ScriptExecutionContext) -> bool:
	var final_speaker: String = speaker_name
	var speaker_node: CharacterController = null

	# 1) Hablante explícito por ID (map scripts / triggers)
	#    Acepta npc_id de NPCs y LOCALID_PLAYER (CharacterPlayer.PLAYER_ID).
	if speaker_id != &"":
		speaker_node = context.find_character_by_id(speaker_id)
		if speaker_node == null:
			push_warning("ScriptCmdText: no se encontró personaje con id '%s'" % str(speaker_id))
		elif final_speaker.is_empty():
			final_speaker = _display_name_from_controller(speaker_node)

	# 2) NPC dueño del script (interacción normal)
	if speaker_node == null and context.npc:
		speaker_node = context.npc as CharacterController

	if not hide_speaker and final_speaker.is_empty() and speaker_node:
		final_speaker = _display_name_from_controller(speaker_node)

	var text_pages: Array[String] = messages.duplicate()
	if text_pages.is_empty():
		text_pages.append(message)

	var dialogue_box: DialogueBox = null
	if context.npc:
		dialogue_box = context.npc.get_tree().get_first_node_in_group("dialogue_box") as DialogueBox
	elif context.player:
		dialogue_box = context.player.get_tree().get_first_node_in_group("dialogue_box") as DialogueBox
	elif speaker_node:
		dialogue_box = speaker_node.get_tree().get_first_node_in_group("dialogue_box") as DialogueBox

	# Map scripts no tienen NPC dueño: hay que completar el async al cerrar.
	# Aunque se resuelva un speaker_node por ID, terminar_dialogo() de ese NPC
	# no avisa al runner del mapa.
	if dialogue_box and context.npc == null:
		dialogue_box.dialogue_closed.connect(context.complete_async, CONNECT_ONE_SHOT)

	if not choices.is_empty() and not choice_variable.is_empty():
		if dialogue_box:
			# Los .txt comparan el índice visible (0 = primera opción). No
			# dependemos de choice_id, que puede ser personalizado por una UI.
			dialogue_box.choice_index_selected.connect(_on_choice_index_selected.bind(context), CONNECT_ONE_SHOT)

	if DialogueManager and DialogueManager.has_method("show_texts"):
		DialogueManager.show_texts(text_pages, final_speaker, speaker_node, choices, choice_position)
		context.is_waiting = true
		return false

	# Verificar si existe DialogueManager
	if not DialogueManager:
		push_warning("ScriptCmdText: DialogueManager no disponible, mostrando mensaje en consola.")
		print("[DIALOGO] %s: %s" % [final_speaker if final_speaker != "" else "NPC", message])
		return true

	# Opción A: Si tu DialogueManager acepta iniciar diálogo con texto directo
	if DialogueManager.has_method("start_dialogue_with_text"):
		DialogueManager.call("start_dialogue_with_text", message, final_speaker)

	# Opción B: Si usa un recurso Dialogue personalizado (sin DialogueLine)
	elif DialogueManager.has_method("start_dialogue_simple"):
		DialogueManager.call("start_dialogue_simple", message, final_speaker)

	# Opción C: Si requiere crear un array de líneas manualmente
	elif DialogueManager.has_method("start_dialogue_from_array"):
		var lines: Array = [message] # Solo el texto, sin envolver en clase
		DialogueManager.call("start_dialogue_from_array", lines, final_speaker)

	# Opción D: Fallback genérico 'start_dialogue' asumiendo que maneja strings
	elif DialogueManager.has_method("start_dialogue"):
		# Intentamos pasar solo el string, dependiendo de tu implementación
		DialogueManager.call("start_dialogue", message, final_speaker)

	else:
		push_warning("ScriptCmdText: Ningún método de diálogo conocido encontrado en DialogueManager.")
		print("[DIALOGO] %s: %s" % [final_speaker if final_speaker != "" else "NPC", message])
		return true

	# Marcar como asíncrono (espera a que termine el diálogo)
	# NOTA: Asegúrate de que tu DialogueManager emita una señal o llame a un callback cuando termine
	context.is_waiting = true
	return false

func _on_choice_index_selected(index: int, context: ScriptExecutionContext) -> void:
	context.set_variable(choice_variable, str(index))


## Nombre visible: CharacterNpc.nombre o CharacterPlayer.name (jugador).
func _display_name_from_controller(controller: CharacterController) -> String:
	if controller == null or controller.character_data == null:
		return ""
	if controller.character_data is CharacterNpc:
		return (controller.character_data as CharacterNpc).nombre
	if controller.character_data is CharacterPlayer:
		return (controller.character_data as CharacterPlayer).name
	return ""


func get_display_text() -> String:
	var max_len: int = mini(30, message.length())
	var preview: String = message.substr(0, max_len)
	if message.length() > 30:
		preview += "..."
	var who: String = str(speaker_id) if speaker_id != &"" else speaker_name
	if who != "":
		return "📝 Texto [%s]: %s" % [who, preview]
	return "📝 Texto: " + preview
