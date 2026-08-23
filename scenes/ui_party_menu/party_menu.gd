extends CanvasLayer
class_name PartyMenu

signal party_closed


# ============================================================
# REFERENCIAS
# ============================================================

@export var summary_scene: PackedScene  # asigna summary.tscn en el Inspector

var summary_abierto: SummaryScreen = null
var party_actual: Array[PokemonInstance] = []

@onready var contenedor_party: GridContainer = $Party

@onready var cursor: AudioStreamPlayer = $Cursor

var jugador_bloqueado: CharacterController = null
var player_data: CharacterPlayer = null

# ============================================================
# SLOTS
# ============================================================

var slots: Array[PartySlot] = []


# ============================================================
# SELECCIÓN
# ============================================================

var indice_seleccion: int = 0

var seleccion_cancel: bool = false

@onready var boton_cancel: Sprite2D = $Button_Cancel

@export var cancel_focus_modulate: Color = Color(1.5, 1.5, 1.5, 1.0)
@export var cancel_normal_modulate: Color = Color.WHITE

# ============================================================
# CONFIGURACIÓN DE NAVEGACIÓN
# ============================================================

# Nuestro Party está organizado en 2 columnas:
#
# [ 0 ] [ 1 ]
# [ 2 ] [ 3 ]
# [ 4 ] [ 5 ]

@export var columnas: int = 2


# ============================================================
# READY
# ============================================================

var pokemon_prueba: PokemonInstance
var pokemon_prueba2: PokemonInstance
var pokemon_prueba3: PokemonInstance

func _ready() -> void:
	_inicializar_slots()

	process_mode = Node.PROCESS_MODE_ALWAYS

	# --------------------------------------------------------
	# Pokémon de prueba
	# --------------------------------------------------------

	pokemon_prueba = PokemonInstance.create(
		Species.SpeciesID.SPECIES_ANNIHILAPE,
		5
	)
	pokemon_prueba2 = PokemonInstance.create(
		Species.SpeciesID.SPECIES_ARCANINE_HISUI,
		50
	)

	pokemon_prueba3 = PokemonInstance.create(
		Species.SpeciesID.SPECIES_ABRA,
		10
	)

	var party_prueba: Array[PokemonInstance] = [
	pokemon_prueba,
	pokemon_prueba2,
	pokemon_prueba3,
	]
	party_actual = party_prueba
	set_party(party_prueba)

	# --------------------------------------------------------
	# Bloquear jugador
	# --------------------------------------------------------

	_bloquear_jugador()

	# --------------------------------------------------------
	# Selección inicial
	# --------------------------------------------------------

	indice_seleccion = 0
	_seleccionar_slot(indice_seleccion)

# ============================================================
# REPRODUCIR CURSOR
# ============================================================

func _reproducir_cursor() -> void:

	if cursor == null:
		return

	cursor.play()

func setup(datos_jugador: CharacterPlayer) -> void:
	player_data = datos_jugador

	_actualizar_cajas_genero()

	# Reestablecer selección visual después de configurar las cajas.
	if slots.size() > 0:
		call_deferred("_seleccionar_slot", 0)

func _actualizar_cajas_genero() -> void:
	if player_data == null:
		return

	var es_chica: bool = player_data.gender == 1

	for slot: PartySlot in slots:
		if not is_instance_valid(slot):
			continue

		slot.configurar_caja_genero(es_chica)

# ============================================================
# ENFOCAR SLOT
# ============================================================

func _enfocar_slot(indice: int) -> void:

	if indice < 0:
		return

	if indice >= slots.size():
		return

	var slot: PartySlot = slots[indice]

	if not is_instance_valid(slot):
		return

	if not slot.visible:
		return

	slot.enfocar()

	indice_seleccion = indice


# ============================================================
# BLOQUEAR JUGADOR
# ============================================================

func _bloquear_jugador() -> void:

	var jugador: CharacterController = (
		get_tree().get_first_node_in_group("player")
		as CharacterController
	)


	if jugador == null:
		return


	jugador_bloqueado = jugador


	jugador.set_process(false)
	jugador.set_physics_process(false)
	jugador.set_process_input(false)
	jugador.set_process_unhandled_input(false)


# ============================================================
# DESBLOQUEAR JUGADOR
# ============================================================

func _desbloquear_jugador() -> void:

	if jugador_bloqueado == null:
		return


	if not is_instance_valid(jugador_bloqueado):

		jugador_bloqueado = null

		return


	jugador_bloqueado.set_process(true)
	jugador_bloqueado.set_physics_process(true)
	jugador_bloqueado.set_process_input(true)
	jugador_bloqueado.set_process_unhandled_input(true)


	jugador_bloqueado = null


# ============================================================
# INICIALIZAR SLOTS
# ============================================================

func _inicializar_slots() -> void:

	slots.clear()

	if contenedor_party == null:

		push_error(
			"PartyMenu: No se encontró el nodo Party."
		)

		return


	for slot_node: Node in contenedor_party.get_children():

		var slot: PartySlot = (
			slot_node as PartySlot
		)

		if slot == null:
			continue

		slots.append(slot)

# ============================================================
# ASIGNAR PARTY
# ============================================================

func set_party(party: Array[PokemonInstance]) -> void:
	party_actual = party
	for i: int in range(slots.size()):

		if i < party.size():

			slots[i].visible = true

			slots[i].set_pokemon(
				party[i]
			)

		else:

			slots[i].clear()
			slots[i].visible = false

	_actualizar_cajas_genero()

# ============================================================
# INPUT
# ============================================================

func _input(event: InputEvent) -> void:

	if event.is_echo():
		return

	if not event.is_pressed():
		return

	# B
	if event.is_action_pressed("buttonB"):

		get_viewport().set_input_as_handled()

		close()

		return


	# ARRIBA
	if event.is_action_pressed("Up"):

		_mover_vertical(-1)

		get_viewport().set_input_as_handled()

		return


	# ABAJO
	if event.is_action_pressed("Down"):

		_mover_vertical(1)

		get_viewport().set_input_as_handled()

		return


	# IZQUIERDA
	if event.is_action_pressed("Left"):

		_mover_horizontal(-1)

		get_viewport().set_input_as_handled()

		return


	# DERECHA
	if event.is_action_pressed("Right"):

		_mover_horizontal(1)

		get_viewport().set_input_as_handled()

		return

	# ========================================================
	# A
	# ========================================================

	if event.is_action_pressed("buttonA"):
		get_viewport().set_input_as_handled()

		if seleccion_cancel:
			close()
			return

		# Abrir summary del Pokémon seleccionado
		_abrir_summary()
		return

# ============================================================
# MOVER VERTICALMENTE
# ============================================================

func _mover_vertical(direccion: int) -> void:

	# --------------------------------------------------------
	# Estamos en CANCEL
	# --------------------------------------------------------

	if seleccion_cancel:

		if direccion < 0:

			@warning_ignore("confusable_local_declaration")
			var ultimo: int = _obtener_ultimo_slot_visible()

			if ultimo >= 0:
				_seleccionar_slot(ultimo)

		return


	# --------------------------------------------------------
	# ARRIBA
	# --------------------------------------------------------

	if direccion < 0:

		var anterior: int = indice_seleccion - columnas

		if anterior >= 0 and slots[anterior].visible:
			_seleccionar_slot(anterior)

		return


	# --------------------------------------------------------
	# ABAJO
	# --------------------------------------------------------

	var siguiente: int = indice_seleccion + columnas

	if (
		siguiente < slots.size()
		and slots[siguiente].visible
	):
		_seleccionar_slot(siguiente)

		return


	# --------------------------------------------------------
	# No hay Pokémon debajo.
	# Si estamos en la última fila visible,
	# pasar a CANCEL.
	# --------------------------------------------------------

	var ultimo: int = _obtener_ultimo_slot_visible()

	if ultimo < 0:
		return

	@warning_ignore("integer_division")
	var fila_actual: int = indice_seleccion / columnas

	@warning_ignore("integer_division")
	var fila_ultimo: int = ultimo / columnas

	if fila_actual == fila_ultimo:
		_seleccionar_cancel()

# ============================================================
# MOVER HORIZONTALMENTE
# ============================================================

func _mover_horizontal(direccion: int) -> void:

	if seleccion_cancel:
		return


	var siguiente: int = (
		indice_seleccion + direccion
	)

	if siguiente < 0:
		return

	if siguiente >= slots.size():
		return

	if not slots[siguiente].visible:
		return


	@warning_ignore("integer_division")
	var fila_actual: int = indice_seleccion / columnas
	@warning_ignore("integer_division")
	var fila_siguiente: int = siguiente / columnas

	if fila_actual != fila_siguiente:
		return

	_seleccionar_slot(siguiente)

func _obtener_ultimo_slot_visible() -> int:

	for i: int in range(slots.size() - 1, -1, -1):

		if slots[i].visible:
			return i

	return -1

# ============================================================
# SELECCIONAR SLOT
# ============================================================

func _seleccionar_slot(indice: int) -> void:

	if indice < 0:
		return

	if indice >= slots.size():
		return

	if not slots[indice].visible:
		return

	if seleccion_cancel:
		boton_cancel.modulate = cancel_normal_modulate

	seleccion_cancel = false
	indice_seleccion = indice

	slots[indice].enfocar()

	_reproducir_cursor()

func _seleccionar_cancel() -> void:

	# --------------------------------------------------------
	# Quitar focus del Pokémon actual
	# --------------------------------------------------------

	if indice_seleccion >= 0 and indice_seleccion < slots.size():

		var slot: PartySlot = slots[indice_seleccion]

		if is_instance_valid(slot):
			slot.quitar_focus()


	# --------------------------------------------------------
	# Seleccionar CANCEL
	# --------------------------------------------------------

	seleccion_cancel = true

	boton_cancel.modulate = cancel_focus_modulate

	_reproducir_cursor()

func _abrir_summary() -> void:
	if summary_scene == null:
		push_error("PartyMenu: summary_scene no asignada.")
		return

	if indice_seleccion < 0 or indice_seleccion >= slots.size():
		return

	var slot: PartySlot = slots[indice_seleccion]
	if slot == null or slot.pokemon == null:
		return

	set_process_input(false)

	summary_abierto = summary_scene.instantiate() as SummaryScreen
	add_child(summary_abierto)

	# party + índice actual
	summary_abierto.setup_from_party(party_actual, indice_seleccion)
	summary_abierto.summary_closed.connect(_on_summary_closed)
	# Si cambió de Pokémon con Up/Down, sincronizar el party al cerrar
	summary_abierto.party_index_changed.connect(_on_summary_index_changed)


func _on_summary_index_changed(nuevo_indice: int) -> void:
	indice_seleccion = nuevo_indice

func _on_summary_closed() -> void:
	summary_abierto = null
	set_process_input(true)

	# Re-enfocar el slot del Pokémon que estabas viendo
	if not seleccion_cancel and indice_seleccion >= 0 and indice_seleccion < slots.size():
		if slots[indice_seleccion].visible:
			_seleccionar_slot(indice_seleccion)

# ============================================================
# CERRAR
# ============================================================

func close() -> void:

	_desbloquear_jugador()

	party_closed.emit()

	queue_free()
