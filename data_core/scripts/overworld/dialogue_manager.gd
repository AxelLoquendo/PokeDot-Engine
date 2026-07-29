extends Node

func start(dialogue: Dialogue, speaker_name: String = "", speaker: CharacterController = null) -> void:
	var caja: DialogueBox = get_tree().get_first_node_in_group("dialogue_box") as DialogueBox

	if caja == null:
		return

	if speaker:
		speaker.preparar_dialogo(CharacterController.global_position)

	caja.iniciar(dialogue, speaker_name, speaker)

func show_text(texto: String, speaker: String = "") -> void:
	var d: Dialogue = Dialogue.new()

	var p: DialoguePage = DialoguePage.new()
	p.text = texto

	d.pages.append(p)

	start(d, speaker)
