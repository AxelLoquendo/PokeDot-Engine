extends Node

## El selector vive en una capa independiente de DialogueBox: puede usarse
## sobre menús, combate o escenas que ya dibujan su propio texto.
const MULTICHOICE_SCENE: PackedScene = preload("res://scenes/ui_dialogue_box/multichoice_box.tscn")
var _multichoice_layer: CanvasLayer = null

func _ready() -> void:
	call_deferred("_ensure_multichoice")

## Capa por encima de Bag (120), Party, etc. Evita que el menú de acciones
## quede invisible aunque el input siga funcionando.
const MULTICHOICE_LAYER: int = 200

func _ensure_multichoice() -> MultichoiceBox:
	if _multichoice_layer != null and is_instance_valid(_multichoice_layer):
		_multichoice_layer.layer = MULTICHOICE_LAYER
		return _multichoice_layer.get_node_or_null("MultichoiceBox") as MultichoiceBox
	var tree: SceneTree = get_tree()
	if tree == null or tree.root == null:
		return null
	_multichoice_layer = MULTICHOICE_SCENE.instantiate() as CanvasLayer
	_multichoice_layer.layer = MULTICHOICE_LAYER
	tree.root.add_child(_multichoice_layer)
	return _multichoice_layer.get_node_or_null("MultichoiceBox") as MultichoiceBox

func get_multichoice() -> MultichoiceBox:
	return _ensure_multichoice()

## Muestra solo las opciones; no abre ni modifica DialogueBox.
func show_choices_only(options: Array[String], position: Vector2 = Vector2(-1, -1)) -> MultichoiceBox:
	var box: MultichoiceBox = _ensure_multichoice()
	if box == null or options.is_empty():
		return null
	var choices: Array[DialogueChoice] = []
	for index: int in range(options.size()):
		var choice: DialogueChoice = DialogueChoice.new()
		choice.text = options[index]
		choice.choice_id = str(index)
		choices.append(choice)
	box.show_choices(choices, _default_choice_position(position), false)
	return box

## Conveniencia asíncrona. Devuelve -1 al cancelar o si no se pudo abrir.
func choose(options: Array[String], position: Vector2 = Vector2(-1, -1)) -> int:
	var box: MultichoiceBox = show_choices_only(options, position)
	if box == null:
		return -1
	var selected: Array = await box.choice_selected
	return int(selected[0]) if not selected.is_empty() else -1

func _default_choice_position(position: Vector2) -> Vector2:
	if position.x >= 0.0 and position.y >= 0.0:
		return position
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	return Vector2(viewport_size.x - 12.0, viewport_size.y - 12.0)

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
