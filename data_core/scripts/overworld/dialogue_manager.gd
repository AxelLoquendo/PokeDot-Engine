extends Node

var current_dialogue: Dialogue
var current_page: int = 0

func start(dialogue: Dialogue) -> void:
	if dialogue == null:
		return

	current_dialogue = dialogue
	current_page = 0

	mostrar_pagina()

func mostrar_pagina() -> void:
	if current_dialogue == null:
		return

	var page: DialoguePage = current_dialogue.pages[current_page]

	print("=== DIALOGO ===")
	print(page.speaker)
	print(page.text)
