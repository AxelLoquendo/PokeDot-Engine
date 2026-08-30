extends CanvasLayer
class_name BagUI

signal bag_closed
signal item_chosen(item_id: Items.ItemId)

enum BagMode {
	NORMAL,
	GIVE_HELD,
}

var bag_mode: BagMode = BagMode.NORMAL

# ============================================================
# CONFIGURACIÓN
# ============================================================

@export_group("Background")

@export var bg_male: Texture2D
@export var bg_female: Texture2D


@export_group("Bag Sprite")

# Índices:
#
# 0 = Bayas
# 1 = Objetos
# 2 = Poké Balls / MT
# 3 = Objetos Clave / Otros
#
@export var bag_male: Array[Texture2D] = []
@export var bag_female: Array[Texture2D] = []


@export_group("Item List")

# Cantidad máxima de slots visibles.
@export var items_visibles_max: int = 6


# ============================================================
# SELECCIÓN DE SLOT
# ============================================================

@export_group("Slot Selection")

# Color utilizado para resaltar el slot seleccionado.
@export var slot_seleccionado_modulate: Color = Color(
	1.703,
	1.752,
	1.8,
	0.863
)

# Color normal de los slots no seleccionados.
@export var slot_normal_modulate: Color = Color.WHITE

@export_group("Exit Button")

# Gráfico que se mostrará cuando "Salir" esté seleccionado.
@export var salir_icono: Texture2D

# ============================================================
# REFERENCIAS
# ============================================================

@onready var sprite_fondo: Sprite2D = $Fondo
@onready var sprite_mochila: Sprite2D = $Mochila
@onready var sprite_item: Sprite2D = $Item
@onready var sprite_selected: Sprite2D = $Selected

@onready var label_categoria: Label = $Category
@onready var label_descripcion: Label = $Item_Description

@onready var audio_cursor: AudioStreamPlayer = $Bag_Cursor
@onready var audio_pocket: AudioStreamPlayer = $Bag_Pocket

# ============================================================
# SLOTS
# ============================================================

@onready var contenedor_slots: Node = $Slots

# Nodos completos de los seis slots.
#
# Esto permite resaltar el SLOT entero y no solamente
# el nombre/cantidad.

var slot_nodos: Array[CanvasItem] = []

# Labels de los seis slots.

var slot_nombres: Array[Label] = []
var slot_cantidades: Array[Label] = []
# Desplazamiento del gráfico Selected respecto al primer slot.
#
# Esto permite colocar Selected manualmente en el editor
# y conservar esa posición relativa al slot.
var selected_offset: Vector2 = Vector2.ZERO

# ============================================================
# ESTADO DEL JUGADOR
# ============================================================

var player_data: CharacterPlayer = null

var jugador_bloqueado: CharacterController = null


# ============================================================
# ESTADO DE LA MOCHILA
# ============================================================

var pocket_actual: ItemConstants.Pocket = (
	ItemConstants.Pocket.POCKET_ITEMS
)

var indice_seleccion: int = 0
var scroll_offset: int = 0

# La escena se instancia ya abierta.

var es_abierto: bool = true


# ============================================================
# ITEMS DEL BOLSILLO ACTUAL
# ============================================================

var items_actuales: Array[Items.ItemId] = []


# ============================================================
# ORDEN DE LOS BOLSILLOS
# ============================================================

var pockets: Array[ItemConstants.Pocket] = []

# ============================================================
# READY
# ============================================================

func _ready() -> void:

	visible = true
	es_abierto = true

	# La mochila debe seguir recibiendo input
	# aunque posteriormente el juego utilice pausa.
	process_mode = Node.PROCESS_MODE_ALWAYS

	label_descripcion.text = ""

	_inicializar_pockets()
	_inicializar_slots()
	_bloquear_jugador()


# ============================================================
# INICIALIZAR BOLSILLOS
# ============================================================

func _inicializar_pockets() -> void:

	pockets.clear()

	# --------------------------------------------------------
	# Orden completo de bolsillos
	# --------------------------------------------------------

	pockets.append(
		ItemConstants.Pocket.POCKET_ITEMS
	)

	pockets.append(
		ItemConstants.Pocket.POCKET_MEDICINE
	)

	pockets.append(
		ItemConstants.Pocket.POCKET_POKE_BALLS
	)

	pockets.append(
		ItemConstants.Pocket.POCKET_TMS_HMS
	)

	pockets.append(
		ItemConstants.Pocket.POCKET_TMS
	)

	pockets.append(
		ItemConstants.Pocket.POCKET_TM_MATERIALS
	)

	pockets.append(
		ItemConstants.Pocket.POCKET_BATTLE_ITEMS
	)

	pockets.append(
		ItemConstants.Pocket.POCKET_BERRIES
	)

	pockets.append(
		ItemConstants.Pocket.POCKET_KEY_ITEMS
	)

	pockets.append(
		ItemConstants.Pocket.POCKET_MAIL
	)

	pockets.append(
		ItemConstants.Pocket.POCKET_MEGA_STONES
	)

	pockets.append(
		ItemConstants.Pocket.POCKET_Z_CRYSTALS
	)

	pockets.append(
		ItemConstants.Pocket.POCKET_ROTOM_POWERS
	)

	pockets.append(
		ItemConstants.Pocket.POCKET_INGREDIENTS
	)

	pockets.append(
		ItemConstants.Pocket.POCKET_TREASURES
	)

	pockets.append(
		ItemConstants.Pocket.POCKET_PICNIC_ITEMS
	)

	pockets.append(
		ItemConstants.Pocket.POCKET_CANDY
	)

	pockets.append(
		ItemConstants.Pocket.POCKET_CATCHING
	)

	pockets.append(
		ItemConstants.Pocket.POCKET_POWER_UP
	)

	pockets.append(
		ItemConstants.Pocket.POCKET_OTHER
	)


# ============================================================
# INICIALIZAR SLOTS
# ============================================================

func _inicializar_slots() -> void:

	slot_nodos.clear()
	slot_nombres.clear()
	slot_cantidades.clear()

	if contenedor_slots == null:

		push_error(
			"BagUI: No se encontró el nodo Slots."
		)

		return


	# --------------------------------------------------------
	# Obtener los seis Slot
	# --------------------------------------------------------

	for slot_node: Node in contenedor_slots.get_children():

		# ----------------------------------------------------
		# El Slot completo
		# ----------------------------------------------------

		var slot_canvas_item: CanvasItem = (
			slot_node as CanvasItem
		)

		if slot_canvas_item == null:
			continue


		var nombre: Label = (
			slot_node.get_node_or_null("Name")
			as Label
		)

		var cantidad: Label = (
			slot_node.get_node_or_null("Quantity")
			as Label
		)


		# Si el Slot no tiene ambos Labels,
		# simplemente lo ignoramos.
		if nombre == null or cantidad == null:
			continue


		# Guardar el Slot completo.
		slot_nodos.append(
			slot_canvas_item
		)

		# Guardar sus Labels.
		slot_nombres.append(
			nombre
		)

		slot_cantidades.append(
			cantidad
		)


	# --------------------------------------------------------
	# Limitar al número de slots visibles
	# --------------------------------------------------------

	if slot_nodos.size() > items_visibles_max:
		slot_nodos.resize(items_visibles_max)

	if slot_nombres.size() > items_visibles_max:
		slot_nombres.resize(items_visibles_max)

	if slot_cantidades.size() > items_visibles_max:
		slot_cantidades.resize(items_visibles_max)


	# --------------------------------------------------------
	# Limpiar inicialmente
	# --------------------------------------------------------

	_limpiar_slots()


	# --------------------------------------------------------
	# Guardar la posición inicial de Selected
	#
	# La posición que tú colocaste manualmente en el editor
	# se toma como referencia para el primer slot.
	# --------------------------------------------------------

	if sprite_selected != null and not slot_nodos.is_empty():

		var posicion_slot: Vector2 = (slot_nodos[0].get_global_transform_with_canvas().origin)

		var posicion_selected: Vector2 = (sprite_selected.get_global_transform_with_canvas().origin)

		selected_offset = (posicion_selected - posicion_slot)


# ============================================================
# LIMPIAR SLOTS
# ============================================================

func _limpiar_slots() -> void:

	# --------------------------------------------------------
	# Limpiar nombres
	# --------------------------------------------------------

	for nombre: Label in slot_nombres:

		if is_instance_valid(nombre):

			nombre.text = ""

			nombre.self_modulate = Color.WHITE


	# --------------------------------------------------------
	# Limpiar cantidades
	# --------------------------------------------------------

	for cantidad: Label in slot_cantidades:

		if is_instance_valid(cantidad):

			cantidad.text = ""

			cantidad.self_modulate = Color.WHITE


	# --------------------------------------------------------
	# Restablecer apariencia de los slots
	# --------------------------------------------------------

	for slot: CanvasItem in slot_nodos:

		if is_instance_valid(slot):

			slot.self_modulate = slot_normal_modulate


# ============================================================
# ACTUALIZAR SELECCIÓN VISUAL
# ============================================================

func _actualizar_seleccion_visual() -> void:

	# --------------------------------------------------------
	# Restablecer todos los slots
	# --------------------------------------------------------

	for slot: CanvasItem in slot_nodos:

		if is_instance_valid(slot):

			slot.self_modulate = slot_normal_modulate


	# --------------------------------------------------------
	# No hay selección válida
	# --------------------------------------------------------

	if indice_seleccion < 0:
		return


	# --------------------------------------------------------
	# La entrada "Salir" también es seleccionable.
	#
	# Por eso NO comprobamos items_actuales.is_empty().
	# --------------------------------------------------------

	var slot_seleccionado: int = (
		indice_seleccion
		- scroll_offset
	)


	if slot_seleccionado < 0:
		return


	if slot_seleccionado >= slot_nodos.size():
		return


	# --------------------------------------------------------
	# Resaltar el Slot completo
	# --------------------------------------------------------

	var slot: CanvasItem = (
		slot_nodos[slot_seleccionado]
	)


	if is_instance_valid(slot):

		slot.self_modulate = (
			slot_seleccionado_modulate
		)

	# --------------------------------------------------------
	# Mover el gráfico Selected.
	#
	# Selected está fuera de Slots, por lo que se mueve
	# independientemente del nodo Slot.
	# --------------------------------------------------------

	_actualizar_selected()

# ============================================================
# ACTUALIZAR GRÁFICO DE SELECCIÓN
# ============================================================

func _actualizar_selected() -> void:

	if sprite_selected == null:
		return


	# --------------------------------------------------------
	# No mostrar si no existe una selección válida.
	# --------------------------------------------------------

	if indice_seleccion < 0:
		
		sprite_selected.visible = false
		
		return


	# --------------------------------------------------------
	# Convertir el índice global de selección al slot visible.
	# --------------------------------------------------------

	var slot_seleccionado: int = (
		indice_seleccion
		- scroll_offset
	)


	if slot_seleccionado < 0:
		
		sprite_selected.visible = false
		
		return


	if slot_seleccionado >= slot_nodos.size():
		
		sprite_selected.visible = false
		
		return


	# --------------------------------------------------------
	# Obtener el slot seleccionado.
	# --------------------------------------------------------

	var slot: CanvasItem = (
		slot_nodos[slot_seleccionado]
	)


	if not is_instance_valid(slot):
		
		sprite_selected.visible = false
		
		return


	# --------------------------------------------------------
	# Mover Selected manteniendo el desplazamiento que
	# definimos manualmente en el editor.
	# --------------------------------------------------------

	var posicion_slot: Vector2 = (
		slot
		.get_global_transform_with_canvas()
		.origin
	)


	sprite_selected.global_position = (
		posicion_slot
		+ selected_offset
	)


	sprite_selected.visible = true

# ============================================================
# SETUP
# ============================================================

func setup(datos_jugador: CharacterPlayer, mode: BagMode = BagMode.NORMAL) -> void:
	player_data = datos_jugador
	bag_mode = mode

	indice_seleccion = 0
	scroll_offset = 0

	pocket_actual = ItemConstants.Pocket.POCKET_ITEMS

	_update_bag_graphics()
	_update_ui()

func _get_selected_item_id() -> Items.ItemId:
	if _esta_seleccionado_salir():
		return Items.ItemId.ITEM_NONE
	if indice_seleccion < 0 or indice_seleccion >= items_actuales.size():
		return Items.ItemId.ITEM_NONE
	return items_actuales[indice_seleccion]

# ============================================================
# ACTUALIZAR GRÁFICOS DEL JUGADOR
# ============================================================

func _update_bag_graphics() -> void:

	if player_data == null:
		return


	match player_data.gender:

		0:
			# Boy
			sprite_fondo.texture = bg_male

		1:
			# Girl
			sprite_fondo.texture = bg_female

		_:
			# Fallback
			sprite_fondo.texture = bg_male


	_update_bag_pocket_graphic()


# ============================================================
# ACTUALIZAR GRÁFICO SEGÚN BOLSILLO
# ============================================================

func _update_bag_pocket_graphic() -> void:

	if player_data == null:
		return


	var graphic_index: int = (
		_get_pocket_graphic_index()
	)


	var textures: Array[Texture2D]


	match player_data.gender:

		1:
			textures = bag_female

		_:
			textures = bag_male


	if textures.is_empty():

		sprite_mochila.texture = null

		return


	if graphic_index < 0:

		sprite_mochila.texture = null

		return


	if graphic_index >= textures.size():

		sprite_mochila.texture = null

		return


	# No es una animación.
	# Cada bolsillo tiene directamente su textura.
	sprite_mochila.texture = textures[graphic_index]


# ============================================================
# OBTENER ÍNDICE DEL GRÁFICO DEL BOLSILLO
# ============================================================

func _get_pocket_graphic_index() -> int:

	match pocket_actual:

		# ----------------------------------------------------
		# Gráfico de Objetos
		# ----------------------------------------------------

		ItemConstants.Pocket.POCKET_ITEMS:
			return 0


		# ----------------------------------------------------
		# Medicina
		# ----------------------------------------------------

		ItemConstants.Pocket.POCKET_MEDICINE:
			return 1


		# ----------------------------------------------------
		# Poké Balls
		# ----------------------------------------------------

		ItemConstants.Pocket.POCKET_POKE_BALLS:
			return 2


		# ----------------------------------------------------
		# MT/MO
		# ----------------------------------------------------

		ItemConstants.Pocket.POCKET_TMS_HMS:
			return 2


		# ----------------------------------------------------
		# MT
		# ----------------------------------------------------

		ItemConstants.Pocket.POCKET_TMS:
			return 2


		# ----------------------------------------------------
		# Materiales MT
		# ----------------------------------------------------

		ItemConstants.Pocket.POCKET_TM_MATERIALS:
			return 2


		# ----------------------------------------------------
		# Objetos de combate
		# ----------------------------------------------------

		ItemConstants.Pocket.POCKET_BATTLE_ITEMS:
			return 2


		# ----------------------------------------------------
		# Bayas
		# ----------------------------------------------------

		ItemConstants.Pocket.POCKET_BERRIES:
			return 0


		# ----------------------------------------------------
		# Objetos Clave
		# ----------------------------------------------------

		ItemConstants.Pocket.POCKET_KEY_ITEMS:
			return 3


		# ----------------------------------------------------
		# Correo
		# ----------------------------------------------------

		ItemConstants.Pocket.POCKET_MAIL:
			return 3


		# ----------------------------------------------------
		# Megapiedras
		# ----------------------------------------------------

		ItemConstants.Pocket.POCKET_MEGA_STONES:
			return 2


		# ----------------------------------------------------
		# Cristales Z
		# ----------------------------------------------------

		ItemConstants.Pocket.POCKET_Z_CRYSTALS:
			return 2


		# ----------------------------------------------------
		# Poderes Rotom
		# ----------------------------------------------------

		ItemConstants.Pocket.POCKET_ROTOM_POWERS:
			return 3


		# ----------------------------------------------------
		# Ingredientes
		# ----------------------------------------------------

		ItemConstants.Pocket.POCKET_INGREDIENTS:
			return 0


		# ----------------------------------------------------
		# Tesoros
		# ----------------------------------------------------

		ItemConstants.Pocket.POCKET_TREASURES:
			return 3


		# ----------------------------------------------------
		# Objetos de Picnic
		# ----------------------------------------------------

		ItemConstants.Pocket.POCKET_PICNIC_ITEMS:
			return 0


		# ----------------------------------------------------
		# Caramelos
		# ----------------------------------------------------

		ItemConstants.Pocket.POCKET_CANDY:
			return 1


		# ----------------------------------------------------
		# Captura
		# ----------------------------------------------------

		ItemConstants.Pocket.POCKET_CATCHING:
			return 2


		# ----------------------------------------------------
		# Potenciadores
		# ----------------------------------------------------

		ItemConstants.Pocket.POCKET_POWER_UP:
			return 1


		# ----------------------------------------------------
		# Otros
		# ----------------------------------------------------

		ItemConstants.Pocket.POCKET_OTHER:
			return 1


		_:
			return 0


# ============================================================
# CERRAR MOCHILA
# ============================================================

func close_bag() -> void:

	if not es_abierto:
		return


	es_abierto = false


	sprite_item.texture = null
	label_descripcion.text = ""

	_limpiar_slots()


	visible = false


	_desbloquear_jugador()


	bag_closed.emit()


	queue_free()


# ============================================================
# CAMBIAR DE BOLSILLO
# ============================================================

func _select_pocket(
	nuevo_pocket: ItemConstants.Pocket
) -> void:

	if pocket_actual == nuevo_pocket:

		_update_ui()

		return


	pocket_actual = nuevo_pocket

	indice_seleccion = 0
	scroll_offset = 0


	# Cambiar inmediatamente el gráfico de la mochila.
	_update_bag_pocket_graphic()


	_reproducir_sonido_pocket()

	_update_ui()


# ============================================================
# CAMBIAR BOLSILLO
# ============================================================

func _cambiar_pocket(direccion: int) -> void:

	if pockets.is_empty():
		return


	var indice_actual: int = (
		pockets.find(pocket_actual)
	)


	if indice_actual == -1:
		return


	var nuevo_indice: int = (
		indice_actual + direccion
	)


	# --------------------------------------------------------
	# Navegación circular
	#
	# Desde el último bolsillo → primero.
	# Desde el primero → último.
	# --------------------------------------------------------

	if nuevo_indice < 0:

		nuevo_indice = pockets.size() - 1

	elif nuevo_indice >= pockets.size():

		nuevo_indice = 0


	_select_pocket(
		pockets[nuevo_indice]
	)


# ============================================================
# NOMBRE DEL BOLSILLO
# ============================================================

func _get_pocket_name(
	pocket: ItemConstants.Pocket
) -> String:

	match pocket:

		ItemConstants.Pocket.POCKET_ITEMS:
			return "Objetos"

		ItemConstants.Pocket.POCKET_MEDICINE:
			return "Medicina"

		ItemConstants.Pocket.POCKET_POKE_BALLS:
			return "Poké Balls"

		ItemConstants.Pocket.POCKET_TMS_HMS:
			return "MT/MO"

		ItemConstants.Pocket.POCKET_TMS:
			return "MT"

		ItemConstants.Pocket.POCKET_TM_MATERIALS:
			return "Materiales MT"

		ItemConstants.Pocket.POCKET_BATTLE_ITEMS:
			return "Batalla"

		ItemConstants.Pocket.POCKET_BERRIES:
			return "Bayas"

		ItemConstants.Pocket.POCKET_KEY_ITEMS:
			return "Obj. Clave"

		ItemConstants.Pocket.POCKET_MAIL:
			return "Correo"

		ItemConstants.Pocket.POCKET_MEGA_STONES:
			return "Megapiedras"

		ItemConstants.Pocket.POCKET_Z_CRYSTALS:
			return "Cristales Z"

		ItemConstants.Pocket.POCKET_ROTOM_POWERS:
			return "Rotom"

		ItemConstants.Pocket.POCKET_INGREDIENTS:
			return "Ingredientes"

		ItemConstants.Pocket.POCKET_TREASURES:
			return "Tesoros"

		ItemConstants.Pocket.POCKET_PICNIC_ITEMS:
			return "Obj. Picnic"

		ItemConstants.Pocket.POCKET_CANDY:
			return "Caramelos"

		ItemConstants.Pocket.POCKET_CATCHING:
			return "Captura"

		ItemConstants.Pocket.POCKET_POWER_UP:
			return "Potenciadores"

		ItemConstants.Pocket.POCKET_OTHER:
			return "Otros"

		_:
			return "Objetos"


# ============================================================
# OBTENER ITEMS DEL BOLSILLO
# ============================================================

func _get_items_in_pocket(
	pocket: ItemConstants.Pocket
) -> Array[Items.ItemId]:

	var resultado: Array[Items.ItemId] = []


	if player_data == null:
		return resultado


	var todos_los_items: Array[ItemData] = (
		ItemDatabase.get_all_items()
	)


	for item_data: ItemData in todos_los_items:

		if item_data == null:
			continue


		if item_data.pocket != pocket:
			continue


		var cantidad: int = (
			player_data.bag.get_quantity(
				item_data.item_id
			)
		)


		if cantidad <= 0:
			continue


		resultado.append(
			item_data.item_id
		)


	return resultado


# ============================================================
# COMPROBAR SI ESTÁ SELECCIONADO "SALIR"
# ============================================================

func _esta_seleccionado_salir() -> bool:

	# "Salir" siempre está inmediatamente después
	# del último objeto real.

	return (
		indice_seleccion == items_actuales.size()
	)


# ============================================================
# CANTIDAD TOTAL DE ENTRADAS
# ============================================================

func _get_total_entradas() -> int:

	# --------------------------------------------------------
	# Objetos reales + entrada virtual "Salir"
	# --------------------------------------------------------

	return items_actuales.size() + 1


# ============================================================
# ACTUALIZAR UI
# ============================================================

func _update_ui() -> void:

	if player_data == null:
		return


	# --------------------------------------------------------
	# Nombre del bolsillo
	# --------------------------------------------------------

	label_categoria.text = (
		_get_pocket_name(
			pocket_actual
		)
	)


	# --------------------------------------------------------
	# Obtener objetos
	# --------------------------------------------------------

	items_actuales = (
		_get_items_in_pocket(
			pocket_actual
		)
	)


	# --------------------------------------------------------
	# "Salir" SIEMPRE existe.
	#
	# Por lo tanto incluso un bolsillo vacío tiene
	# una entrada seleccionable.
	# --------------------------------------------------------

	var total_entradas: int = (
		_get_total_entradas()
	)


	# --------------------------------------------------------
	# Corregir índice
	# --------------------------------------------------------

	if indice_seleccion < 0:

		indice_seleccion = 0


	if indice_seleccion >= total_entradas:

		indice_seleccion = (
			total_entradas - 1
		)


	# --------------------------------------------------------
	# Scroll
	# --------------------------------------------------------

	if indice_seleccion < scroll_offset:

		scroll_offset = indice_seleccion


	elif (
		indice_seleccion
		>= scroll_offset + items_visibles_max
	):

		scroll_offset = (
			indice_seleccion
			- items_visibles_max
			+ 1
		)


	var max_scroll: int = maxi(
		0,
		total_entradas - items_visibles_max
	)


	scroll_offset = mini(
		scroll_offset,
		max_scroll
	)


	# --------------------------------------------------------
	# Dibujar los seis slots
	# --------------------------------------------------------

	_actualizar_lista_items()


	# --------------------------------------------------------
	# Actualizar resaltado del slot seleccionado
	# --------------------------------------------------------

	_actualizar_seleccion_visual()


	# --------------------------------------------------------
	# "Salir" seleccionado
	# --------------------------------------------------------

	if _esta_seleccionado_salir():
	# ----------------------------------------------------
	# Mostrar gráfico personalizado de "Salir"
	# ----------------------------------------------------
		sprite_item.texture = salir_icono
		label_descripcion.text = ("Cerrar la mochila.")
		return


	# --------------------------------------------------------
	# Obtener objeto seleccionado
	# --------------------------------------------------------

	if items_actuales.is_empty():

		sprite_item.texture = null

		label_descripcion.text = (
			"Cerrar la mochila."
		)

		return


	var item_id: Items.ItemId = (
		items_actuales[
			indice_seleccion
		]
	)


	var datos_item: ItemData = (
		ItemDatabase.get_item(
			item_id
		)
	)


	# --------------------------------------------------------
	# Mostrar detalle del objeto
	# --------------------------------------------------------

	if datos_item == null:

		sprite_item.texture = null

		label_descripcion.text = (
			"Error de datos."
		)

		return


	sprite_item.texture = datos_item.icon


	# IMPORTANTE:
	# Aquí solamente va la descripción.
	#
	# El nombre y cantidad se muestran arriba,
	# dentro de los slots.

	label_descripcion.text = (
		datos_item.item_description
	)


# ============================================================
# ACTUALIZAR LOS 6 SLOTS
# ============================================================

func _actualizar_lista_items() -> void:

	# --------------------------------------------------------
	# Limpiar todos los slots
	# --------------------------------------------------------

	_limpiar_slots()


	var total_entradas: int = (
		_get_total_entradas()
	)


	if total_entradas <= 0:
		return


	# --------------------------------------------------------
	# Dibujar objetos visibles
	# --------------------------------------------------------

	for slot: int in range(
		min(
			items_visibles_max,
			slot_nombres.size()
		)
	):

		var indice_entrada: int = (
			scroll_offset + slot
		)


		if indice_entrada >= total_entradas:
			break


		# ----------------------------------------------------
		# ENTRADA "SALIR"
		# ----------------------------------------------------

		if indice_entrada == items_actuales.size():

			slot_nombres[slot].text = "Salir"

			# "Salir" no es un objeto.
			# No mostramos cantidad.
			slot_cantidades[slot].text = ""

			continue


		# ----------------------------------------------------
		# OBJETO REAL
		# ----------------------------------------------------

		var item_id: Items.ItemId = (
			items_actuales[
				indice_entrada
			]
		)


		var datos_item: ItemData = (
			ItemDatabase.get_item(
				item_id
			)
		)


		if datos_item == null:
			continue


		var cantidad: int = (
			player_data.bag.get_quantity(
				item_id
			)
		)


		# ----------------------------------------------------
		# NOMBRE
		# ----------------------------------------------------

		slot_nombres[slot].text = (
			datos_item.item_name
		)


		# ----------------------------------------------------
		# CANTIDAD
		# ----------------------------------------------------

		slot_cantidades[slot].text = (
			"x %d" % cantidad
		)


	# --------------------------------------------------------
	# La selección visual del Slot completo se realiza
	# después de dibujar la lista.
	# --------------------------------------------------------

	_actualizar_seleccion_visual()


# ============================================================
# INPUT
# ============================================================

func _input(event: InputEvent) -> void:

	if not es_abierto:
		return


	if event.is_echo():
		return


	if not event.is_pressed():
		return


	# --------------------------------------------------------
	# B
	# --------------------------------------------------------

	if event.is_action_pressed("buttonB"):

		close_bag()

		get_viewport().set_input_as_handled()

		return


	# --------------------------------------------------------
	# A
	# --------------------------------------------------------

	if event.is_action_pressed("buttonA"):
		if _esta_seleccionado_salir():
			close_bag()
			get_viewport().set_input_as_handled()
			return

		if bag_mode == BagMode.GIVE_HELD:
			var item_id: Items.ItemId = _get_selected_item_id()
			if item_id != Items.ItemId.ITEM_NONE:
				item_chosen.emit(item_id)
				close_bag()
			get_viewport().set_input_as_handled()
			return

		# NORMAL: usar ítem en campo (más adelante)
		get_viewport().set_input_as_handled()
		return


	# --------------------------------------------------------
	# ARRIBA
	# --------------------------------------------------------

	if event.is_action_pressed("Up"):

		_mover_seleccion(-1)

		get_viewport().set_input_as_handled()

		return


	# --------------------------------------------------------
	# ABAJO
	# --------------------------------------------------------

	if event.is_action_pressed("Down"):

		_mover_seleccion(1)

		get_viewport().set_input_as_handled()

		return


	# --------------------------------------------------------
	# IZQUIERDA
	# --------------------------------------------------------

	if event.is_action_pressed("Left"):

		_cambiar_pocket(-1)

		get_viewport().set_input_as_handled()

		return


	# --------------------------------------------------------
	# DERECHA
	# --------------------------------------------------------

	if event.is_action_pressed("Right"):

		_cambiar_pocket(1)

		get_viewport().set_input_as_handled()

		return


	# --------------------------------------------------------
	# Cualquier otro input
	# --------------------------------------------------------
	#
	# La mochila consume el input para que no continúe
	# hacia otros sistemas de la escena.
	#

	get_viewport().set_input_as_handled()


# ============================================================
# MOVER SELECCIÓN
# ============================================================

func _mover_seleccion(direccion: int) -> void:

	if player_data == null:
		return


	# --------------------------------------------------------
	# Ahora también podemos movernos aunque el bolsillo
	# no tenga objetos, porque "Salir" siempre existe.
	# --------------------------------------------------------

	var total_entradas: int = (
		_get_total_entradas()
	)


	if total_entradas <= 0:
		return


	var nuevo_indice: int = (
		indice_seleccion + direccion
	)


	# --------------------------------------------------------
	# Límites
	# --------------------------------------------------------

	if nuevo_indice < 0:
		return


	if nuevo_indice >= total_entradas:
		return


	indice_seleccion = nuevo_indice


	_reproducir_sonido_cursor()
	_update_ui()


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


	# --------------------------------------------------------
	# Desactivar procesamiento del jugador.
	#
	# Esto es importante porque consumir el InputEvent NO
	# impide que un CharacterController que utiliza:
	#
	# Input.is_action_pressed(...)
	#
	# siga detectando el movimiento.
	# --------------------------------------------------------

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
# SONIDO
# ============================================================

func _reproducir_sonido_cursor() -> void:

	if audio_cursor == null:
		return

	if audio_cursor.stream == null:
		return

	audio_cursor.play()

func _reproducir_sonido_pocket() -> void:

	if audio_pocket == null:
		return

	if audio_pocket.stream == null:
		return

	audio_pocket.play()
