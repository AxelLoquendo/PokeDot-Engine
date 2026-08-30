extends CanvasLayer
class_name PartyMenu

signal party_closed
signal battle_pokemon_selected(pokemon: PokemonInstance)
signal battle_cancelled

# ============================================================
# REFERENCIAS
# ============================================================
@export var summary_scene: PackedScene
var summary_abierto: SummaryScreen = null
var party_actual: Array[PokemonInstance] = []
@onready var contenedor_party: GridContainer = $Party
@onready var cursor: AudioStreamPlayer = $Cursor
var jugador_bloqueado: CharacterController = null
var player_data: CharacterPlayer = null
@onready var context_help: Label = $Box_Text/Text
@onready var context_panel: NinePatchRect = $ContextPanel
@onready var context_label: Label = $ContextPanel/ContextLabel
@onready var context_cursor: Sprite2D = $ContextPanel/ContextCursor

## Offset del cursor respecto al panel (ajústalo en el inspector o aquí)
@export var context_cursor_base: Vector2 = Vector2(19, 24)
@export var context_line_height: float = 32.0  # altura de una línea de tu fuente

var bag_ui_dar: BagUI = null

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
# [ 0 ] [ 1 ]
# [ 2 ] [ 3 ]
# [ 4 ] [ 5 ]
@export var columnas: int = 2

enum MenuMode {
	SLOTS,
	CONTEXT,
	ITEM_CONTEXT,
	SWAP_POKEMON,
	SWAP_ITEM,
	BATTLE_SELECT,
}

var menu_mode: MenuMode = MenuMode.SLOTS
var context_index: int = 0
var item_context_index: int = 0
var swap_from_index: int = -1

var battle_active: PokemonInstance = null
var battle_force_switch: bool = false

const CONTEXT_OPTIONS: PackedStringArray = ["Resumen", "Cambiar", "Objeto"]
const ITEM_OPTIONS: PackedStringArray = ["Dar", "Quitar", "Mover"]

const CONTEXT_HELP: PackedStringArray = [
	"Ver la información.",
	"Cambiar posición.",
	"Gestionar objeto.",
]

const ITEM_HELP: PackedStringArray = [
	"Dar un objeto de la mochila.",
	"Quitar el objeto que lleva.",
	"Mover el objeto.",
]

# ============================================================
# READY
# ============================================================
#var pokemon_prueba: PokemonInstance
#var pokemon_prueba2: PokemonInstance
#var pokemon_prueba3: PokemonInstance
func _ready() -> void:
	_inicializar_slots()
	process_mode = Node.PROCESS_MODE_ALWAYS
#	pokemon_prueba = PokemonInstance.create(Species.SpeciesID.SPECIES_HYDRAPPLE, 100)
#	pokemon_prueba2 = PokemonInstance.create(Species.SpeciesID.SPECIES_ARCEUS_FAIRY, 50)
#	pokemon_prueba3 = PokemonInstance.create(Species.SpeciesID.SPECIES_BULBASAUR, 5)
#	var party_prueba: Array[PokemonInstance] = [pokemon_prueba, pokemon_prueba2, pokemon_prueba3]
#	party_actual = party_prueba
#	set_party(player_data.party)
	_bloquear_jugador()
	indice_seleccion = 0
	_seleccionar_slot(indice_seleccion)
	_ocultar_ui_contexto()

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
	if player_data != null:
		set_party(player_data.party)
	else:
		set_party([])
	indice_seleccion = 0
	seleccion_cancel = false
	if slots.size() > 0:
		call_deferred("_after_setup_focus")

func setup_battle(datos_jugador: CharacterPlayer, activo: PokemonInstance, forzar: bool = false) -> void:
	battle_active = activo
	battle_force_switch = forzar
	setup(datos_jugador)
	menu_mode = MenuMode.BATTLE_SELECT
	if context_help != null:
		if forzar:
			context_help.text = "¡Elige un Pokémon!"
		else:
			context_help.text = "¿Qué Pokémon quieres sacar?"

func _after_setup_focus() -> void:
	var ultimo: int = _obtener_ultimo_slot_visible()
	if ultimo >= 0:
		_seleccionar_slot(0)
	else:
		_seleccionar_cancel()

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
	var jugador: CharacterController = (get_tree().get_first_node_in_group("player") as CharacterController)
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
		push_error("PartyMenu: No se encontró el nodo Party.")
		return

	for slot_node: Node in contenedor_party.get_children():
		var slot: PartySlot = (slot_node as PartySlot)
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
			slots[i].set_pokemon(party[i])
		else:
			slots[i].clear()
			slots[i].visible = false
	_actualizar_cajas_genero()

# ============================================================
# INPUT
# ============================================================
func _input(event: InputEvent) -> void:
	if event.is_echo() or not event.is_pressed():
		return

	# Summary abierto: no procesar party
	if summary_abierto != null:
		return

	# ---------- B ----------
	if event.is_action_pressed("buttonB"):
		get_viewport().set_input_as_handled()
		match menu_mode:
			MenuMode.SLOTS:
				close()
			MenuMode.CONTEXT, MenuMode.SWAP_POKEMON, MenuMode.SWAP_ITEM:
				_cerrar_contextos()
			MenuMode.ITEM_CONTEXT:
				_abrir_menu_contexto()  # vuelve al menú anterior
			MenuMode.BATTLE_SELECT:
				if battle_force_switch:
					return  # no se puede cancelar
				battle_cancelled.emit()
				close()
			MenuMode.BATTLE_SELECT:
				if seleccion_cancel:
					if battle_force_switch:
						return
					battle_cancelled.emit()
					close()
				else:
					_confirmar_seleccion_batalla()
		return

	# ---------- A ----------
	if event.is_action_pressed("buttonA"):
		get_viewport().set_input_as_handled()
		match menu_mode:
			MenuMode.SLOTS:
				if seleccion_cancel:
					close()
				else:
					_abrir_menu_contexto()
			MenuMode.CONTEXT:
				_confirmar_contexto()
			MenuMode.ITEM_CONTEXT:
				_confirmar_item_contexto()
			MenuMode.SWAP_POKEMON, MenuMode.SWAP_ITEM:
				_confirmar_swap()
		return

	# ---------- D-pad ----------
	if event.is_action_pressed("Up"):
		_navegar(-1, true)
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("Down"):
		_navegar(1, true)
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("Left"):
		_navegar(-1, false)
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("Right"):
		_navegar(1, false)
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
		_abrir_summary()
		return

func _confirmar_seleccion_batalla() -> void:
	if indice_seleccion < 0 or indice_seleccion >= party_actual.size():
		return
	var mon: PokemonInstance = party_actual[indice_seleccion]
	if mon == null:
		return
	if mon.is_fainted():
		if context_help != null:
			context_help.text = "¡No puede combatir!"
		return
	if mon == battle_active:
		if context_help != null:
			context_help.text = "¡Ese Pokémon ya está en combate!"
		return

	battle_pokemon_selected.emit(mon)
	close()

func _navegar(direccion: int, vertical: bool) -> void:
	match menu_mode:
		MenuMode.SLOTS, MenuMode.SWAP_POKEMON, MenuMode.SWAP_ITEM:
			if vertical:
				_mover_vertical(direccion)
			else:
				_mover_horizontal(direccion)
		MenuMode.CONTEXT:
			var n: int = CONTEXT_OPTIONS.size()
			context_index = posmod(context_index + direccion, n)
			_reproducir_cursor()
			_actualizar_ui_contexto()
		MenuMode.ITEM_CONTEXT:
			var n2: int = ITEM_OPTIONS.size()
			item_context_index = posmod(item_context_index + direccion, n2)
			_reproducir_cursor()
			_actualizar_ui_item_contexto()

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
	if (siguiente < slots.size() and slots[siguiente].visible):
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
	var siguiente: int = (indice_seleccion + direccion)
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
	menu_mode = MenuMode.SLOTS  # por si acaso
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

func _abrir_menu_contexto() -> void:
	if seleccion_cancel:
		return
	if indice_seleccion < 0 or indice_seleccion >= party_actual.size():
		return
	if party_actual[indice_seleccion] == null:
		return

	menu_mode = MenuMode.CONTEXT
	context_index = 0
	swap_from_index = indice_seleccion
	_reproducir_cursor()
	_actualizar_ui_contexto()


func _cerrar_contextos() -> void:
	menu_mode = MenuMode.SLOTS
	context_index = 0
	item_context_index = 0
	swap_from_index = -1
	_ocultar_ui_contexto()
	if not seleccion_cancel and indice_seleccion >= 0:
		_seleccionar_slot(indice_seleccion)


func _confirmar_contexto() -> void:
	match context_index:
		0:  # Resumen
			_cerrar_contextos()
			_abrir_summary()
		1:  # Cambiar
			menu_mode = MenuMode.SWAP_POKEMON
			_ocultar_ui_contexto()
			# opcional: mensaje "¿Con quién?"
		2:  # Objeto
			menu_mode = MenuMode.ITEM_CONTEXT
			item_context_index = 0
			_actualizar_ui_item_contexto()


func _confirmar_item_contexto() -> void:
	match item_context_index:
		0:  # Dar
			_ocultar_ui_contexto()
			_abrir_bag_para_dar()
		1:  # Quitar
			_quitar_held(swap_from_index)
			_cerrar_contextos()
		2:  # Mover
			menu_mode = MenuMode.SWAP_ITEM
			_ocultar_ui_contexto()


func _confirmar_swap() -> void:
	if seleccion_cancel:
		_cerrar_contextos()
		return
	if indice_seleccion == swap_from_index:
		return  # mismo slot: ignorar o cancelar
	if indice_seleccion < 0 or indice_seleccion >= party_actual.size():
		return

	if menu_mode == MenuMode.SWAP_POKEMON:
		_swap_pokemon(swap_from_index, indice_seleccion)
	elif menu_mode == MenuMode.SWAP_ITEM:
		_swap_held(swap_from_index, indice_seleccion)

	_cerrar_contextos()

func _swap_pokemon(i: int, j: int) -> void:
	if i < 0 or j < 0 or i >= party_actual.size() or j >= party_actual.size():
		return
	var tmp: PokemonInstance = party_actual[i]
	party_actual[i] = party_actual[j]
	party_actual[j] = tmp
	set_party(party_actual)
	_seleccionar_slot(j)


func _swap_held(i: int, j: int) -> void:
	var a: PokemonInstance = party_actual[i]
	var b: PokemonInstance = party_actual[j]
	if a == null or b == null:
		return
	var tmp: Items.ItemId = a.held_item
	a.held_item = b.held_item
	b.held_item = tmp
	set_party(party_actual)
	_seleccionar_slot(j)


func _quitar_held(i: int) -> void:
	if i < 0 or i >= party_actual.size():
		return
	var mon: PokemonInstance = party_actual[i]
	if mon == null or mon.held_item == Items.ItemId.ITEM_NONE:
		return
	var old: Items.ItemId = mon.held_item
	mon.held_item = Items.ItemId.ITEM_NONE
	# Devolver a la mochila si existe
	if player_data and player_data.bag:
		player_data.bag.add_item(old, 1)
	set_party(party_actual)

func _ocultar_ui_contexto() -> void:
	if context_panel:
		context_panel.visible = false
	if context_label:
		context_label.text = ""
	if context_cursor:
		context_cursor.visible = false
	if context_help:
		context_help.text = "Elegir un Pokémon."

func _actualizar_ui_contexto() -> void:
	if context_panel:
		context_panel.visible = true
	if context_label:
		context_label.visible = true
		context_label.text = "\n".join(CONTEXT_OPTIONS)
	_actualizar_cursor_contexto(context_index)
	_actualizar_texto_ayuda(CONTEXT_HELP, context_index)


func _actualizar_ui_item_contexto() -> void:
	if context_panel:
		context_panel.visible = true
	if context_label:
		context_label.visible = true
		context_label.text = "\n".join(ITEM_OPTIONS)
	_actualizar_cursor_contexto(item_context_index)
	_actualizar_texto_ayuda(ITEM_HELP, item_context_index)

func _actualizar_texto_ayuda(lineas: PackedStringArray, index: int) -> void:
	if context_help == null:
		return
	context_help.visible = true
	if index >= 0 and index < lineas.size():
		context_help.text = lineas[index]
	else:
		context_help.text = ""

func _actualizar_cursor_contexto(index: int) -> void:
	if context_cursor == null:
		return
	context_cursor.visible = true
	context_cursor.position = context_cursor_base + Vector2(0, context_line_height * float(index))

func _abrir_bag_para_dar() -> void:
	if player_data == null:
		return
	if is_instance_valid(bag_ui_dar):
		return

	var bag_scene: PackedScene = preload("res://scenes/ui_bag/bag.tscn")
	bag_ui_dar = bag_scene.instantiate() as BagUI
	if bag_ui_dar == null:
		return

	add_child(bag_ui_dar)
	set_process_input(false)

	bag_ui_dar.setup(player_data, BagUI.BagMode.GIVE_HELD)
	bag_ui_dar.item_chosen.connect(_on_item_chosen_for_held)
	bag_ui_dar.bag_closed.connect(_on_give_bag_closed)


func _on_item_chosen_for_held(item_id: Items.ItemId) -> void:
	if swap_from_index < 0 or swap_from_index >= party_actual.size():
		return
	var mon: PokemonInstance = party_actual[swap_from_index]
	if mon == null or player_data == null or player_data.bag == null:
		return
	if item_id == Items.ItemId.ITEM_NONE:
		return

	# Devolver el held anterior a la mochila
	if mon.held_item != Items.ItemId.ITEM_NONE:
		player_data.bag.add_item(mon.held_item, 1)

	if not player_data.bag.remove_item(item_id, 1):
		return

	mon.held_item = item_id
	set_party(party_actual)


func _on_give_bag_closed() -> void:
	bag_ui_dar = null
	_bloquear_jugador()
	set_process_input(true)
	_cerrar_contextos()

# ============================================================
# CERRAR
# ============================================================
func close() -> void:
	_desbloquear_jugador()
	party_closed.emit()
	queue_free()
