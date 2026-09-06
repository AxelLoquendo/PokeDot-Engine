extends Node2D
class_name SummaryPageMove


var pokemon: PokemonInstance = null
signal selection_changed
signal view_mode_changed

enum ViewMode { BROWSE, DETAIL, SWAP }

var selected_index: int = 0
var view_mode: ViewMode = ViewMode.BROWSE
var swap_from_index: int = -1

@onready var move_type_sprites: Array[Sprite2D] = [
	$Move_1/Type_Move0,
	$Move_1/Type_Move1,
	$Move_1/Type_Move2,
	$Move_1/Type_Move3,
]


@onready var move_names: Array[Label] = [
	$Move_1/Type_Move0/Move_Name,
	$Move_1/Type_Move1/Move_Name,
	$Move_1/Type_Move2/Move_Name,
	$Move_1/Type_Move3/Move_Name,
]


@onready var move_pp_labels: Array[Label] = [
	$Move_1/Type_Move0/PP/Number_PP,
	$Move_1/Type_Move1/PP/Number_PP,
	$Move_1/Type_Move2/PP/Number_PP,
	$Move_1/Type_Move3/PP/Number_PP,
]


func setup(nuevo_pokemon: PokemonInstance) -> void:
	pokemon = nuevo_pokemon
	selected_index = 0
	view_mode = ViewMode.BROWSE
	swap_from_index = -1

	if pokemon == null:
		return

	_actualizar_ui()
	view_mode_changed.emit()
	selection_changed.emit()


func _actualizar_ui() -> void:
	for i: int in range(move_names.size()):
		_limpiar_espacio(i)

		if pokemon == null:
			continue

		if i >= pokemon.moves.size():
			continue

		var slot: PokemonMoveSlot = pokemon.moves[i]

		if slot == null or slot.is_empty():
			continue

		var move_data: MoveData = (
			MoveDatabase.get_move(slot.move_id)
		)

		if move_data == null:
			continue

		_actualizar_espacio(i, slot, move_data)


func _limpiar_espacio(indice: int) -> void:
	if indice < 0 or indice >= move_names.size():
		return

	move_names[indice].text = "---"
	move_pp_labels[indice].text = "--/--"

	# El Sprite2D tiene inicialmente un icono Normal en la escena.
	# Lo ocultamos para los espacios vacíos.
	move_type_sprites[indice].texture = null


func _actualizar_espacio(
	indice: int,
	slot: PokemonMoveSlot,
	move_data: MoveData
) -> void:
	if indice < 0 or indice >= move_names.size():
		return

	move_names[indice].text = move_data.move_name

	move_pp_labels[indice].text = "%d/%d" % [
		slot.current_pp,
		move_data.pp
	]

	# Usamos el mismo sistema de iconos que en la pantalla de combate.
	var type_icon: Texture2D = TypeIconsDb.get_icon(
		move_data.type
	)

	move_type_sprites[indice].texture = type_icon

func _known_move_count() -> int:
	if pokemon == null:
		return 0
	var count: int = 0
	for i: int in mini(pokemon.moves.size(), move_type_sprites.size()):
		var slot: PokemonMoveSlot = pokemon.moves[i]
		if slot != null and not slot.is_empty():
			count += 1
		else:
			break
	return count


func move_cursor(direction: int) -> bool:
	var known: int = _known_move_count()
	if known <= 1:
		return false
	var nuevo: int = clampi(selected_index + direction, 0, known - 1)
	if nuevo == selected_index:
		return false
	selected_index = nuevo
	selection_changed.emit()
	return true


func get_selected_move() -> MoveData:
	if pokemon == null or selected_index < 0 or selected_index >= pokemon.moves.size():
		return null
	var slot: PokemonMoveSlot = pokemon.moves[selected_index]
	if slot == null or slot.is_empty():
		return null
	return MoveDatabase.get_move(slot.move_id)


func handle_button_a() -> void:
	match view_mode:
		ViewMode.BROWSE:
			view_mode = ViewMode.DETAIL
			view_mode_changed.emit()
		ViewMode.DETAIL:
			view_mode = ViewMode.SWAP
			swap_from_index = selected_index
			view_mode_changed.emit()
		ViewMode.SWAP:
			_confirm_swap()


## Devuelve true si consumió el botón B (no debe cerrar el resumen).
func handle_button_b() -> bool:
	match view_mode:
		ViewMode.DETAIL:
			view_mode = ViewMode.BROWSE
			view_mode_changed.emit()
			return true
		ViewMode.SWAP:
			view_mode = ViewMode.DETAIL
			swap_from_index = -1
			view_mode_changed.emit()
			return true
	return false


func _confirm_swap() -> void:
	if swap_from_index >= 0 and swap_from_index < pokemon.moves.size() and swap_from_index != selected_index:
		var moves: Array[PokemonMoveSlot] = pokemon.moves
		var temp: PokemonMoveSlot = moves[swap_from_index]
		moves[swap_from_index] = moves[selected_index]
		moves[selected_index] = temp
		_actualizar_ui()

	view_mode = ViewMode.DETAIL
	swap_from_index = -1
	view_mode_changed.emit()
	selection_changed.emit()
