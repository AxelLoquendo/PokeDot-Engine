extends CanvasLayer

@onready var menu: GridContainer = $Control/GridContainer
@onready var sfx_tilegamecursor: AudioStreamPlayer = $TileGameCursor
@onready var sfx_uimenuopen: AudioStreamPlayer = $UImenuOpen
@onready var sfx_uimenuclose: AudioStreamPlayer = $UImenuClose
# ============================================================
# ESTADO
# ============================================================
var is_open: bool = false

var bag_ui: BagUI = null
var party_menu: PartyMenu = null
var last_option: String = ""

# ============================================================
# READY
# ============================================================
func _ready() -> void:
	visible = false
	set_process_input(false)
	for button: Node in menu.get_children():
		var menu_button: BaseButton = button as BaseButton
		if menu_button == null:
			continue
		menu_button.focus_mode = Control.FOCUS_ALL
		menu_button.pressed.connect(_on_option_selected.bind(menu_button.name))
		menu_button.focus_entered.connect(_on_button_focus_entered.bind(menu_button))

func _on_button_focus_entered(button: BaseButton) -> void:
	if button != null and not button.name.is_empty():
		last_option = button.name
	actualizar_brillo_botones()

# ============================================================
# ABRIR / CERRAR
# ============================================================
func toggle_menu() -> void:
	is_open = not is_open
	visible = is_open
	set_process_input(is_open)

	if is_open:
		_actualizar_opcion_pokemon()
		if sfx_uimenuopen:
			sfx_uimenuopen.play()
		_reactivate_menu()
	else:
		var focused: Control = get_viewport().gui_get_focus_owner() as Control
		if focused != null and focused.get_parent() == menu:
			last_option = focused.name
		if sfx_uimenuclose:
			sfx_uimenuclose.play()
		get_viewport().gui_release_focus()

# ============================================================
# REACTIVAR MENU
# ============================================================
func _reactivate_menu() -> void:
	if not is_inside_tree():
		return
	is_open = true
	visible = true
	set_process_input(true)

	var viewport: Viewport = get_viewport()
	if viewport == null:
		return
		
	_actualizar_opcion_pokemon()

	var restore: Control = null
	if not last_option.is_empty():
		var btn: Control = menu.get_node_or_null(last_option) as Control
		if btn != null and btn.visible:
			restore = btn

	if restore:
		restore.grab_focus()
	else:
		var first_button: Control = _primer_boton_visible()
		if first_button:
			first_button.grab_focus()

	actualizar_brillo_botones()

func _primer_boton_visible() -> Control:
	for button: Node in menu.get_children():
		var c: Control = button as Control
		if c != null and c.visible:
			return c
	return null

# ============================================================
# BRILLO DE BOTONES
# ============================================================
func actualizar_brillo_botones() -> void:
	var viewport: Viewport = get_viewport()
	if viewport == null:
		return
	var focused: Control = (viewport.gui_get_focus_owner() as Control)
	for button: Node in menu.get_children():
		var menu_button: BaseButton = (button as BaseButton)
		if menu_button == null:
			continue
		menu_button.self_modulate = (
			Color(1.703, 1.752, 1.8, 0.863)
			if menu_button == focused
			else Color(1, 1, 1, 0.902)
		)

# ============================================================
# INPUT
# ============================================================
func _input(event: InputEvent) -> void:
	if (not is_open or event.is_echo() or not event.is_pressed()):
		return

	# --------------------------------------------------------
	# B / START
	# --------------------------------------------------------
	if (event.is_action_pressed("buttonStart") or event.is_action_pressed("buttonB")):
		toggle_menu()
		get_viewport().set_input_as_handled()
		return

	# --------------------------------------------------------
	# A
	# --------------------------------------------------------
	if event.is_action_pressed("buttonA"):
		var focused_button: BaseButton = (get_viewport().gui_get_focus_owner() as BaseButton)
		if (focused_button != null and focused_button.get_parent() == menu):
			focused_button.pressed.emit()
		get_viewport().set_input_as_handled()
		return

	# --------------------------------------------------------
	# NAVEGACIÓN (solo botones visibles)
	# --------------------------------------------------------
	var focused: Control = get_viewport().gui_get_focus_owner() as Control
	if focused == null or focused.get_parent() != menu or not focused.visible:
		return

	if not (
		event.is_action_pressed("Right")
		or event.is_action_pressed("Left")
		or event.is_action_pressed("Down")
		or event.is_action_pressed("Up")
	):
		return

	var visibles: Array[Control] = _botones_visibles()
	if visibles.is_empty():
		return

	var current_vis: int = visibles.find(focused)
	if current_vis < 0:
		return

	var next_vis: int = current_vis
	var columnas: int = 2

	if event.is_action_pressed("Right"):
		# Misma fila, columna derecha (si existe)
		if current_vis % columnas == 0 and current_vis + 1 < visibles.size():
			next_vis = current_vis + 1

	elif event.is_action_pressed("Left"):
		if current_vis % columnas == 1:
			next_vis = current_vis - 1

	elif event.is_action_pressed("Down"):
		if current_vis + columnas < visibles.size():
			next_vis = current_vis + columnas

	elif event.is_action_pressed("Up"):
		if current_vis - columnas >= 0:
			next_vis = current_vis - columnas

	if next_vis != current_vis:
		visibles[next_vis].grab_focus()
		if sfx_tilegamecursor:
			sfx_tilegamecursor.play()

	actualizar_brillo_botones()
	get_viewport().set_input_as_handled()

func _botones_visibles() -> Array[Control]:
	var result: Array[Control] = []
	for button: Node in menu.get_children():
		var c: Control = button as Control
		if c != null and c.visible:
			result.append(c)
	return result

# ============================================================
# OPCIÓN SELECCIONADA
# ============================================================
func _on_option_selected(option: String) -> void:
	last_option = option
	match option:
		"Save":
			SaveManager.request_save(get_tree(), self)
		"Pokemon":
			if not _player_has_pokemon():
				return
			_open_party_menu()
		"TrainerCard":
			_open_trainer_card()
		"Bag":
			_open_bag()
		"Pokedex", "Options":
			print("%s: próximamente" % option)

# ============================================================
# TRAINER CARD
# ============================================================
func _open_trainer_card() -> void:
	toggle_menu()
	var card: CanvasLayer = preload("res://scenes/ui_trainer_card/trainer_card.tscn").instantiate()
	get_tree().current_scene.add_child(card)
	var jugador: CharacterController = (get_tree().get_first_node_in_group("player") as CharacterController)
	if jugador:
		jugador.trainer_card = card
		card.tree_exited.connect(
			func() -> void:
				if is_instance_valid(jugador):
					jugador.trainer_card = null
				_reactivate_menu()
		)
	else:
		card.tree_exited.connect(_reactivate_menu)

# ============================================================
# ABRIR MOCHILA
# ============================================================
func _open_bag() -> void:
	# --------------------------------------------------------
	# Ocultar StartMenu
	# --------------------------------------------------------
	toggle_menu()

	# --------------------------------------------------------
	# Evitar crear dos mochilas
	# --------------------------------------------------------
	if is_instance_valid(bag_ui):
		return

	# --------------------------------------------------------
	# Crear BagUI
	# --------------------------------------------------------
	var bag_scene: PackedScene = preload("res://scenes/ui_bag/bag.tscn")

	bag_ui = (bag_scene.instantiate() as BagUI)

	if bag_ui == null:
		push_error("StartMenu: no se pudo crear BagUI.")
		_reactivate_menu()
		return

	# --------------------------------------------------------
	# Añadir BagUI encima de la escena actual
	# --------------------------------------------------------
	get_tree().current_scene.add_child(bag_ui)

	# --------------------------------------------------------
	# Obtener jugador
	# --------------------------------------------------------
	var jugador: CharacterController = (get_tree().get_first_node_in_group("player") as CharacterController)
	if jugador == null:
		push_error("StartMenu: no se encontró " + "CharacterController del jugador.")
		bag_ui.queue_free()
		bag_ui = null
		_reactivate_menu()
		return

	# --------------------------------------------------------
	# Inicializar mochila
	# --------------------------------------------------------
	bag_ui.setup(jugador.character_data)

	# --------------------------------------------------------
	# Detectar cierre de la mochila
	# --------------------------------------------------------
	bag_ui.bag_closed.connect(_on_bag_closed)

func _on_bag_closed() -> void:

	bag_ui = null

	_reactivate_menu()

# ============================================================
# MOCHILA CERRADA
# ============================================================

# ============================================================
# ABRIR PARTY MENU
# ============================================================

func _open_party_menu() -> void:
	# --------------------------------------------------------
	# Ocultar StartMenu
	# --------------------------------------------------------
	toggle_menu()

	# --------------------------------------------------------
	# Evitar crear dos PartyMenu
	# --------------------------------------------------------
	if is_instance_valid(party_menu):
		return

	# --------------------------------------------------------
	# Crear PartyMenu
	# --------------------------------------------------------
	var party_scene: PackedScene = preload("res://scenes/ui_party_menu/party_menu.tscn")
	party_menu = (party_scene.instantiate() as PartyMenu)
	if party_menu == null:
		push_error("StartMenu: no se pudo crear PartyMenu.")
		_reactivate_menu()
		return


	# --------------------------------------------------------
	# Añadir PartyMenu encima de la escena actual
	# --------------------------------------------------------
	get_tree().current_scene.add_child(party_menu)

	# --------------------------------------------------------
	# Obtener jugador
	# --------------------------------------------------------
	var jugador: CharacterController = (get_tree().get_first_node_in_group("player") as CharacterController)
	if jugador == null:
		push_error("StartMenu: no se encontró " + "CharacterController del jugador.")
		party_menu.queue_free()
		party_menu = null
		_reactivate_menu()
		return

	# --------------------------------------------------------
	# Inicializar PartyMenu
	# --------------------------------------------------------

	party_menu.setup(jugador.character_data)

	# --------------------------------------------------------
	# Detectar cierre del PartyMenu
	# --------------------------------------------------------

	party_menu.party_closed.connect(_on_party_closed)

func _on_party_closed() -> void:

	party_menu.queue_free()
	party_menu = null

	_reactivate_menu()

func _player_has_pokemon() -> bool:
	var jugador: CharacterController = (get_tree().get_first_node_in_group("player") as CharacterController)
	if jugador == null:
		return false
	var data: CharacterPlayer = jugador.character_data as CharacterPlayer
	if data == null:
		return false
	for mon: PokemonInstance in data.party:
		if mon != null:
			return true
	return false

func _actualizar_opcion_pokemon() -> void:
	var btn: CanvasItem = menu.get_node_or_null("Pokemon") as CanvasItem
	if btn == null:
		return
	var hay: bool = _player_has_pokemon()
	btn.visible = hay
	# Evita que el foco de Godot entre en un botón oculto
	if btn is BaseButton:
		(btn as BaseButton).focus_mode = (Control.FOCUS_ALL if hay else Control.FOCUS_NONE)
