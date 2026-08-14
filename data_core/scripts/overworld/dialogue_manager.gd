extends Node

func start(dialogue: Dialogue, speaker_name: String = "", speaker: CharacterController = null) -> void:
	var caja: DialogueBox = get_tree().get_first_node_in_group("dialogue_box") as DialogueBox

	if caja == null:
		return

	if speaker:
		var player: Node2D = get_tree().get_first_node_in_group("player") as Node2D
		var look_target: Vector2 = player.global_position if player else speaker.global_position
		speaker.preparar_dialogo(look_target)

	caja.iniciar(dialogue, speaker_name, speaker)

func show_text(texto: String, speaker: String = "", speaker_node: CharacterController = null) -> void:
	show_texts([texto], speaker, speaker_node)


func show_texts(textos: Array[String], speaker: String = "", speaker_node: CharacterController = null, choices: Array[String] = [], choice_position: Vector2 = Vector2(-1, -1)) -> void:
	var d: Dialogue = Dialogue.new()
	for texto: String in textos:
		var page: DialoguePage = DialoguePage.new()
		page.text = texto
		d.pages.append(page)
	if not choices.is_empty() and not d.pages.is_empty():
		for index: int in range(choices.size()):
			var choice: DialogueChoice = DialogueChoice.new()
			choice.text = choices[index]
			choice.choice_id = str(index)
			d.pages[d.pages.size() - 1].choices.append(choice)

	var caja: DialogueBox = get_tree().get_first_node_in_group("dialogue_box") as DialogueBox
	if caja:
		caja.choice_position = choice_position
	start(d, speaker, speaker_node)
