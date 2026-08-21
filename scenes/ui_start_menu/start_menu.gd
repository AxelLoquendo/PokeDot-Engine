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

		menu_button.pressed.connect(
			_on_option_selected.bind(menu_button.name)
		)

		menu_button.focus_entered.connect(
			actualizar_brillo_botones
		)


# ============================================================
# ABRIR / CERRAR
# ============================================================

func toggle_menu() -> void:

	is_open = not is_open

	visible = is_open
	set_process_input(is_open)


	if is_open:

		if sfx_uimenuopen:
			sfx_uimenuopen.play()

		_reactivate_menu()

	else:

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

	var focused_button: Control = (
		viewport.gui_get_focus_owner()
		as Control
	)

	if (
		focused_button != null
		and focused_button.get_parent() == menu
	):
		actualizar_brillo_botones()
		return

	if menu.get_child_count() > 0:

		var first_button: Control = (
			menu.get_child(0)
			as Control
		)

		if first_button:
			first_button.grab_focus()

	actualizar_brillo_botones()

# ============================================================
# BRILLO DE BOTONES
# ============================================================

func actualizar_brillo_botones() -> void:

	var viewport: Viewport = get_viewport()

	if viewport == null:
		return


	var focused: Control = (
		viewport.gui_get_focus_owner()
		as Control
	)


	for button: Node in menu.get_children():

		var menu_button: BaseButton = (
			button as BaseButton
		)

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

	if (
		not is_open
		or event.is_echo()
		or not event.is_pressed()
	):
		return


	# --------------------------------------------------------
	# B / START
	# --------------------------------------------------------

	if (
		event.is_action_pressed("buttonStart")
		or event.is_action_pressed("buttonB")
	):

		toggle_menu()

		get_viewport().set_input_as_handled()

		return


	# --------------------------------------------------------
	# A
	# --------------------------------------------------------

	if event.is_action_pressed("buttonA"):

		var focused_button: BaseButton = (
			get_viewport().gui_get_focus_owner()
			as BaseButton
		)

		if (
			focused_button != null
			and focused_button.get_parent() == menu
		):
			focused_button.pressed.emit()

		get_viewport().set_input_as_handled()

		return


	# --------------------------------------------------------
	# NAVEGACIÓN
	# --------------------------------------------------------

	var focused: Control = (
		get_viewport().gui_get_focus_owner()
		as Control
	)

	if (
		focused == null
		or focused.get_parent() != menu
	):
		return


	var current_index: int = focused.get_index()
	var next_index: int = current_index


	if (
		event.is_action_pressed("Right")
		and current_index % 2 == 0
	):

		next_index = min(
			current_index + 1,
			menu.get_child_count() - 1
		)


	elif (
		event.is_action_pressed("Left")
		and current_index % 2 == 1
	):

		next_index = current_index - 1


	elif event.is_action_pressed("Down"):

		next_index = min(
			current_index + 2,
			menu.get_child_count() - 1
		)


	elif event.is_action_pressed("Up"):

		next_index = max(
			current_index - 2,
			0
		)


	else:

		return


	if next_index != current_index:

		var next_button: Control = (
			menu.get_child(next_index)
			as Control
		)

		if next_button:
			next_button.grab_focus()

		if sfx_tilegamecursor:
			sfx_tilegamecursor.play()


	actualizar_brillo_botones()

	get_viewport().set_input_as_handled()


# ============================================================
# OPCIÓN SELECCIONADA
# ============================================================

func _on_option_selected(option: String) -> void:

	match option:

		# ------------------------------------------------------
		# SAVE
		# ------------------------------------------------------

		"Save":

			SaveManager.request_save(
				get_tree(),
				self
			)


		# ------------------------------------------------------
		# POKÉMON
		# ------------------------------------------------------

		"Pokemon":

			_open_party_menu()


		# ------------------------------------------------------
		# TRAINER CARD
		# ------------------------------------------------------

		"TrainerCard":

			_open_trainer_card()


		# ------------------------------------------------------
		# BAG
		# ------------------------------------------------------

		"Bag":

			_open_bag()


		# ------------------------------------------------------
		# POKÉDEX / OPTIONS
		# ------------------------------------------------------

		"Pokedex", "Options":

			print(
				"%s: próximamente" % option
			)


# ============================================================
# TRAINER CARD
# ============================================================

func _open_trainer_card() -> void:

	toggle_menu()


	var card: CanvasLayer = preload(
		"res://scenes/ui_trainer_card/trainer_card.tscn"
	).instantiate()


	get_tree().current_scene.add_child(card)


	var jugador: CharacterController = (
		get_tree().get_first_node_in_group("player")
		as CharacterController
	)


	if jugador:

		jugador.trainer_card = card

		card.tree_exited.connect(
			func() -> void:

				if is_instance_valid(jugador):
					jugador.trainer_card = null

				_reactivate_menu()
		)

	else:

		card.tree_exited.connect(
			_reactivate_menu
		)


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

	var bag_scene: PackedScene = preload(
		"res://scenes/ui_bag/bag.tscn"
	)


	bag_ui = (
		bag_scene.instantiate()
		as BagUI
	)


	if bag_ui == null:

		push_error(
			"StartMenu: no se pudo crear BagUI."
		)

		_reactivate_menu()

		return


	# --------------------------------------------------------
	# Añadir BagUI encima de la escena actual
	# --------------------------------------------------------

	get_tree().current_scene.add_child(
		bag_ui
	)


	# --------------------------------------------------------
	# Obtener jugador
	# --------------------------------------------------------

	var jugador: CharacterController = (
		get_tree().get_first_node_in_group("player")
		as CharacterController
	)


	if jugador == null:

		push_error(
			"StartMenu: no se encontró "
			+ "CharacterController del jugador."
		)

		bag_ui.queue_free()
		bag_ui = null

		_reactivate_menu()

		return


	# --------------------------------------------------------
	# Inicializar mochila
	# --------------------------------------------------------

	bag_ui.setup(
		jugador.character_data
	)


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

	var party_scene: PackedScene = preload(
		"res://scenes/ui_party_menu/party_menu.tscn"
	)


	party_menu = (
		party_scene.instantiate()
		as PartyMenu
	)


	if party_menu == null:

		push_error(
			"StartMenu: no se pudo crear PartyMenu."
		)

		_reactivate_menu()

		return


	# --------------------------------------------------------
	# Añadir PartyMenu encima de la escena actual
	# --------------------------------------------------------

	get_tree().current_scene.add_child(
		party_menu
	)


	# --------------------------------------------------------
	# Obtener jugador
	# --------------------------------------------------------

	var jugador: CharacterController = (
		get_tree().get_first_node_in_group("player")
		as CharacterController
	)


	if jugador == null:

		push_error(
			"StartMenu: no se encontró "
			+ "CharacterController del jugador."
		)

		party_menu.queue_free()
		party_menu = null

		_reactivate_menu()

		return


	# --------------------------------------------------------
	# Inicializar PartyMenu
	# --------------------------------------------------------

	party_menu.setup(
		jugador.character_data
	)


	# --------------------------------------------------------
	# Detectar cierre del PartyMenu
	# --------------------------------------------------------

	party_menu.party_closed.connect(
		_on_party_closed
	)

func _on_party_closed() -> void:

	party_menu.queue_free()
	party_menu = null

	_reactivate_menu()
