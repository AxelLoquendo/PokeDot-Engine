@tool
extends ScriptCommand
class_name ScriptCmdText

## Muestra un cuadro de texto con un mensaje
## Comando asíncrono: espera a que el jugador cierre el diálogo

@export_multiline var message: String = "Hola, soy un NPC"
@export var speaker_name: String = ""  ## Nombre del hablante (vacío = usa nombre del NPC)
@export var show_portrait: bool = true

func execute(context: ScriptExecutionContext) -> bool:
	var final_speaker: String = speaker_name
	
	# Intentar obtener el nombre del NPC si no se especificó uno
	if final_speaker == "" and context.npc:
		var npc_data: CharacterNpc = context.get_npc_data()
		if npc_data and npc_data.has_property("nombre"):
			final_speaker = npc_data.nombre as String
	
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

func get_display_text() -> String:
	var max_len: int = mini(30, message.length())
	var preview: String = message.substr(0, max_len)
	if message.length() > 30:
		preview += "..."
	return "📝 Texto: " + preview
