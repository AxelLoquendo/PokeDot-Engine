@tool
extends ScriptCommand
class_name ScriptCmdText

## Muestra un cuadro de texto con un mensaje
## Comando asíncrono: espera a que el jugador cierre el diálogo

@export_multiline var message: String = "Hola, soy un NPC"
@export var messages: Array[String] = []
@export var speaker_name: String = ""  ## Nombre del hablante (vacío = usa nombre del NPC)
@export var show_portrait: bool = true
@export var choices: Array[String] = []
@export var choice_variable: String = ""
@export var hide_speaker: bool = false

func execute(context: ScriptExecutionContext) -> bool:
	var final_speaker: String = speaker_name
	
	# Intentar obtener el nombre del NPC si no se especificó uno
	if not hide_speaker and final_speaker == "" and context.npc:
		var npc_data: CharacterNpc = context.get_npc_data()
		if npc_data:
			final_speaker = npc_data.nombre

	var text_pages: Array[String] = messages.duplicate()
	if text_pages.is_empty():
		text_pages.append(message)
	var dialogue_box: DialogueBox = null
	if context.npc:
		dialogue_box = context.npc.get_tree().get_first_node_in_group("dialogue_box") as DialogueBox
	elif context.player:
		dialogue_box = context.player.get_tree().get_first_node_in_group("dialogue_box") as DialogueBox
	if dialogue_box and not context.npc:
		dialogue_box.dialogue_closed.connect(context.complete_async, CONNECT_ONE_SHOT)
	if not choices.is_empty() and not choice_variable.is_empty():
		if dialogue_box:
			dialogue_box.choice_selected.connect(_on_choice_selected.bind(context), CONNECT_ONE_SHOT)
	if DialogueManager and DialogueManager.has_method("show_texts"):
		DialogueManager.show_texts(text_pages, final_speaker, context.npc as CharacterController, choices)
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

func _on_choice_selected(choice_id: String, context: ScriptExecutionContext) -> void:
	context.set_variable(choice_variable, choice_id)


func get_display_text() -> String:
	var max_len: int = mini(30, message.length())
	var preview: String = message.substr(0, max_len)
	if message.length() > 30:
		preview += "..."
	return "📝 Texto: " + preview
