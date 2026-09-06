extends Node2D

class_name SummaryPageMoveLearned

## Se emite cuando el jugador confirma con qué movimiento (slot_index: 0-3)
## quiere reemplazar el movimiento nuevo.
signal move_slot_chosen(slot_index: int)

## Se emite cuando el jugador cancela el aprendizaje: ya sea con el botón B,
## o seleccionando con A la fila del propio movimiento nuevo (igual que en
## los juegos originales, "reemplazar" el movimiento nuevo por sí mismo
## equivale a no aprenderlo).
signal learn_cancelled

@onready var Cursor: Sprite2D = $Cursor_box
@onready var move_detail_panel: Sprite2D = $MoveInfo
@onready var PkmnIcon: Sprite2D = $MoveInfo/Icon
@onready var Category: Sprite2D = $MoveInfo/Category/Category_sprite
@onready var Power: Label = $MoveInfo/Power/Power_Number
@onready var Presision: Label = $MoveInfo/Presision/Percent
@onready var move_description: Label = $MoveInfo/Move_Description

@onready var move_type_sprites: Array[Sprite2D] = [
	$MoveLearned_1/Type_Move0,
	$MoveLearned_1/Type_Move1,
	$MoveLearned_1/Type_Move2,
	$MoveLearned_1/Type_Move3,
	$MoveLearned_1/Type_Move4,
]

@onready var move_names: Array[Label] = [
	$MoveLearned_1/Type_Move0/Move_Name,
	$MoveLearned_1/Type_Move1/Move_Name,
	$MoveLearned_1/Type_Move2/Move_Name,
	$MoveLearned_1/Type_Move3/Move_Name,
	$MoveLearned_1/Type_Move4/Move_Name,
]

@onready var move_pp_labels: Array[Label] = [
	$MoveLearned_1/Type_Move0/PP/Number_PP,
	$MoveLearned_1/Type_Move1/PP/Number_PP,
	$MoveLearned_1/Type_Move2/PP/Number_PP,
	$MoveLearned_1/Type_Move3/PP/Number_PP,
	$MoveLearned_1/Type_Move4/PP/Number_PP,
]

const CATEGORY_ICONS: Dictionary = {
	MoveStruct.DamageCategory.PHYSICAL: preload("res://graphics/ui_summary_screen/physical.png"),
	MoveStruct.DamageCategory.SPECIAL: preload("res://graphics/ui_summary_screen/special.png"),
	MoveStruct.DamageCategory.STATUS: preload("res://graphics/ui_summary_screen/status.png"),
}

## Índice de la fila que representa el movimiento nuevo (la 5ta fila, no un
## slot real del Pokémon).
const NEW_MOVE_INDEX: int = 4

## Posición Y (local) del cursor para cada una de las 5 filas.
## Ajusta estos 5 números en el Inspector si no calzan con tus filas.
@export var row_positions_y: PackedFloat32Array = [24.0, 82.0, 140.0, 198.0, 270.0]

var pokemon: PokemonInstance = null
var new_move_id: Moves.MoveId = Moves.MoveId.MOVE_NONE
var selected_index: int = 0


## pokemon: el Pokémon que va a aprender el movimiento.
## move_id: el movimiento nuevo que está tratando de aprender.
func setup(nuevo_pokemon: PokemonInstance, move_id: Moves.MoveId) -> void:
	pokemon = nuevo_pokemon
	new_move_id = move_id
	selected_index = 0

	_actualizar_lista()
	set_cursor_index(selected_index)
	_actualizar_detalle()


func _actualizar_lista() -> void:
	for i: int in range(move_names.size()):
		if i == NEW_MOVE_INDEX:
			_actualizar_espacio_nuevo(i)
		else:
			_actualizar_espacio_conocido(i)


func _actualizar_espacio_conocido(indice: int) -> void:
	move_names[indice].text = "---"
	move_pp_labels[indice].text = "--/--"
	move_type_sprites[indice].texture = null

	if pokemon == null or indice >= pokemon.moves.size():
		return

	var slot: PokemonMoveSlot = pokemon.moves[indice]
	if slot == null or slot.is_empty():
		return

	var move_data: MoveData = MoveDatabase.get_move(slot.move_id)
	if move_data == null:
		return

	move_names[indice].text = move_data.move_name
	move_pp_labels[indice].text = "%d/%d" % [slot.current_pp, move_data.pp]
	move_type_sprites[indice].texture = TypeIconsDb.get_icon(move_data.type)


func _actualizar_espacio_nuevo(indice: int) -> void:
	var move_data: MoveData = MoveDatabase.get_move(new_move_id)

	if move_data == null:
		move_names[indice].text = "---"
		move_pp_labels[indice].text = "--/--"
		move_type_sprites[indice].texture = null
		return

	move_names[indice].text = move_data.move_name
	# El movimiento nuevo siempre se muestra con sus PP al máximo.
	move_pp_labels[indice].text = "%d/%d" % [move_data.pp, move_data.pp]
	move_type_sprites[indice].texture = TypeIconsDb.get_icon(move_data.type)


func set_cursor_index(index: int) -> void:
	if index < 0 or index >= row_positions_y.size():
		return
	Cursor.position.y = row_positions_y[index]


## Mueve el cursor entre las 5 filas (los 4 movimientos conocidos + el nuevo).
## Devuelve true si el cursor cambió de fila.
func move_cursor(direction: int) -> bool:
	var nuevo: int = clampi(selected_index + direction, 0, move_names.size() - 1)
	if nuevo == selected_index:
		return false

	selected_index = nuevo
	set_cursor_index(selected_index)
	_actualizar_detalle()
	return true


func _get_move_id_at(indice: int) -> Moves.MoveId:
	if indice == NEW_MOVE_INDEX:
		return new_move_id

	if pokemon == null or indice >= pokemon.moves.size():
		return Moves.MoveId.MOVE_NONE

	var slot: PokemonMoveSlot = pokemon.moves[indice]
	if slot == null or slot.is_empty():
		return Moves.MoveId.MOVE_NONE

	return slot.move_id


func _actualizar_detalle() -> void:
	var species: PokemonDataStruct = pokemon.get_species() if pokemon != null else null
	PkmnIcon.texture = species.icon_sprite if species != null else null

	var move_data: MoveData = MoveDatabase.get_move(_get_move_id_at(selected_index))

	if move_data == null:
		Category.texture = null
		Power.text = "---"
		Presision.text = "---"
		move_description.text = ""
		return

	Category.texture = CATEGORY_ICONS.get(move_data.category)
	Power.text = str(move_data.power) if move_data.power > 0 else "---"
	Presision.text = (
		"---" if move_data.always_hits or move_data.accuracy <= 0
		else "%d%%" % move_data.accuracy
	)
	move_description.text = move_data.description


## true si la fila seleccionada actualmente es la del movimiento nuevo.
func is_new_move_selected() -> bool:
	return selected_index == NEW_MOVE_INDEX


## Botón A: confirma la elección actual.
## Si la fila seleccionada es la del movimiento nuevo, equivale a cancelar
## (no tiene sentido "reemplazar" el movimiento nuevo por sí mismo).
func handle_button_a() -> void:
	if is_new_move_selected():
		learn_cancelled.emit()
	else:
		move_slot_chosen.emit(selected_index)


## Botón B: cancela el aprendizaje sin elegir ningún movimiento.
func handle_button_b() -> void:
	learn_cancelled.emit()
