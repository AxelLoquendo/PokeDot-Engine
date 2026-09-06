extends CanvasLayer

class_name MoveLearnScreen

## Se emite una sola vez con el resultado final de la pantalla.
## cancelado = true si el jugador decidió no aprender el movimiento
## (botón B, o seleccionó con A la fila del propio movimiento nuevo).
## slot_index solo es válido cuando cancelado es false (0-3): el movimiento
## del Pokémon que debe ser reemplazado por el nuevo.
signal resolved(cancelado: bool, slot_index: int)

@onready var pagina: SummaryPageMoveLearned = $Page_4_2

var _resuelto: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if pagina:
		pagina.move_slot_chosen.connect(_on_slot_chosen)
		pagina.learn_cancelled.connect(_on_cancelled)


## pokemon: el Pokémon que va a aprender el movimiento.
## move_id: el movimiento nuevo que está tratando de aprender.
func setup(pokemon: PokemonInstance, move_id: Moves.MoveId) -> void:
	_resuelto = false
	if pagina:
		pagina.setup(pokemon, move_id)


func _input(event: InputEvent) -> void:
	if event.is_echo() or not event.is_pressed():
		return
	if pagina == null or _resuelto:
		return

	if event.is_action_pressed("buttonA"):
		get_viewport().set_input_as_handled()
		pagina.handle_button_a()
		return

	if event.is_action_pressed("buttonB"):
		get_viewport().set_input_as_handled()
		pagina.handle_button_b()
		return

	if event.is_action_pressed("Up"):
		get_viewport().set_input_as_handled()
		pagina.move_cursor(-1)
		return

	if event.is_action_pressed("Down"):
		get_viewport().set_input_as_handled()
		pagina.move_cursor(1)
		return


func _on_slot_chosen(slot_index: int) -> void:
	if _resuelto:
		return
	_resuelto = true
	resolved.emit(false, slot_index)


func _on_cancelled() -> void:
	if _resuelto:
		return
	_resuelto = true
	resolved.emit(true, -1)
