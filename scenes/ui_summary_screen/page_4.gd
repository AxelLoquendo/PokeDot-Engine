extends Node2D
class_name SummaryPageMove


var pokemon: PokemonInstance = null


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

	if pokemon == null:
		return

	_actualizar_ui()


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
