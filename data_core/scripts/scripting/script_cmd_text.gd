@tool
extends ScriptCommand
class_name ScriptCmdText

## Muestra un cuadro de texto con un mensaje
## Comando asíncrono: espera a que el jugador cierre el diálogo

@export_multiline var message: String = "Hola, soy un NPC"
@export var speaker_name: String = ""  ## Nombre del hablante (vacío = usa nombre del NPC)
@export var show_portrait: bool = true

func execute(context: ScriptExecutionContext) -> bool:
	var final_speaker = speaker_name
	if final_speaker == "" and context.npc:
		var npc_data = context.get_npc_data()
		if npc_data:
			final_speaker = npc_data.nombre
	
	# Iniciar diálogo usando tu sistema existente
	var dialogue_resource = Dialogue.new()
	dialogue_resource.lines = [DialogueLine.new(message, final_speaker)]
	
	# Llamar al gestor de diálogos
	if DialogueManager.has_method("start_dialogue_with_resource"):
		DialogueManager.start_dialogue_with_resource(dialogue_resource)
	else:
		DialogueManager.start_dialogue(dialogue_resource)
	
	# Marcar como asíncrono (espera a que termine el diálogo)
	context.is_waiting = true
	return false

func get_display_text() -> String:
	var preview = message.substr(0, min(30, message.length()))
	if message.length() > 30:
		preview += "..."
	return "📝 Texto: " + preview
