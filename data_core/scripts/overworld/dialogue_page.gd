@tool
extends Resource

class_name DialoguePage

@export var speaker: String = ""
@export_multiline var text: String = ""
@export var background_color: Color = Color.WHITE
## ID único de esta página para poder saltar a ella desde una elección.
@export var page_id: String = "" 
@export var next_page_id: String = ""

## NUEVO: Lista de opciones múltiples
@export var choices: Array[DialogueChoice] = []

func has_choices() -> bool:
	return not choices.is_empty()
