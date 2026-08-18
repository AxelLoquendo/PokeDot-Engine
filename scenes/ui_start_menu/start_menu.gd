extends CanvasLayer

@onready var menu: GridContainer = $Control/GridContainer
@onready var sfx_tilegamecursor: AudioStreamPlayer = $TileGameCursor
@onready var sfx_uimenuopen: AudioStreamPlayer = $UImenuOpen
@onready var sfx_uimenuclose: AudioStreamPlayer = $UImenuClose

var is_open: bool = false


func _ready() -> void:
	visible = false
	set_process_input(false)
	for button: Node in menu.get_children():
		var menu_button: BaseButton = button as BaseButton
		if menu_button == null:
			continue
		menu_button.focus_mode = Control.FOCUS_ALL
		menu_button.pressed.connect(_on_option_selected.bind(menu_button.name))
		menu_button.focus_entered.connect(actualizar_brillo_botones)


func toggle_menu() -> void:
	is_open = not is_open
	visible = is_open
	set_process_input(is_open)
	if is_open:
		if sfx_uimenuopen:
			sfx_uimenuopen.play()
		var first_button: Control = menu.get_child(0) as Control
		if first_button:
			first_button.grab_focus()
		actualizar_brillo_botones()
	else:
		if sfx_uimenuclose:
			sfx_uimenuclose.play()
		get_viewport().gui_release_focus()


func actualizar_brillo_botones() -> void:
	var focused: Control = get_viewport().gui_get_focus_owner()
	for button: Node in menu.get_children():
		var menu_button: BaseButton = button as BaseButton
		if menu_button:
			menu_button.self_modulate = Color(1.703, 1.752, 1.8, 0.863) if menu_button == focused else Color(1, 1, 1, 0.902)


func _input(event: InputEvent) -> void:
	if not is_open or event.is_echo() or not event.is_pressed():
		return
	if event.is_action_pressed("buttonStart") or event.is_action_pressed("buttonB"):
		toggle_menu()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("buttonA"):
		var focused_button: BaseButton = get_viewport().gui_get_focus_owner() as BaseButton
		if focused_button and focused_button.get_parent() == menu:
			focused_button.pressed.emit()
		get_viewport().set_input_as_handled()
		return

	var focused: Control = get_viewport().gui_get_focus_owner()
	if focused == null or focused.get_parent() != menu:
		return
	var current_index: int = focused.get_index()
	var next_index: int = current_index
	if event.is_action_pressed("Right") and current_index % 2 == 0:
		next_index = min(current_index + 1, menu.get_child_count() - 1)
	elif event.is_action_pressed("Left") and current_index % 2 == 1:
		next_index = current_index - 1
	elif event.is_action_pressed("Down"):
		next_index = min(current_index + 2, menu.get_child_count() - 1)
	elif event.is_action_pressed("Up"):
		next_index = max(current_index - 2, 0)
	else:
		return
	if next_index != current_index:
		(menu.get_child(next_index) as Control).grab_focus()
		if sfx_tilegamecursor:
			sfx_tilegamecursor.play()
	actualizar_brillo_botones()
	get_viewport().set_input_as_handled()


func _on_option_selected(option: String) -> void:
	match option:
		"Save":
			SaveManager.request_save(get_tree(), self)
		"Pokemon":  
			print("Abriendo menú de equipo (próximamente)")  
		"TrainerCard":  
			toggle_menu()  
			var card: CanvasLayer = preload("res://scenes/ui_trainer_card/trainer_card.tscn").instantiate()  
			get_tree().current_scene.add_child(card)  
			var jugador: CharacterController = get_tree().get_first_node_in_group("player") as CharacterController  
			if jugador:  
				jugador.trainer_card = card  
				card.tree_exited.connect(func() -> void: jugador.trainer_card = null)
		"Pokedex", "Bag", "Options":  
			print("%s: próximamente" % option)
