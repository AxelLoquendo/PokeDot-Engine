extends Node2D
class_name SummaryPageMemo


var pokemon: PokemonInstance = null


@onready var nature_name: Label = $Memo_1/Nature/Nature_Name
@onready var fecha: Label = $Memo_1/Fecha
@onready var lugar_captura: Label = $Memo_1/U_Cap
@onready var encontrado: Label = $Memo_1/Encontrado


const NATURE_NAMES: Array[String] = [
	"Fuerte",
	"Huraña",
	"Audaz",
	"Firme",
	"Pícara",
	"Osada",
	"Dócil",
	"Plácida",
	"Agitada",
	"Floja",
	"Miedosa",
	"Activa",
	"Seria",
	"Alegre",
	"Ingenua",
	"Modesta",
	"Afable",
	"Mansa",
	"Tímida",
	"Alocada",
	"Serena",
	"Amable",
	"Grosera",
	"Cauta",
	"Rara",
]


func setup(nuevo_pokemon: PokemonInstance) -> void:
	pokemon = nuevo_pokemon

	if pokemon == null:
		return

	_actualizar_ui()


func _actualizar_ui() -> void:
	_actualizar_naturaleza()

	_actualizar_procedencia()

func _actualizar_naturaleza() -> void:
	if nature_name == null or pokemon == null:
		return

	var nature_index: int = int(pokemon.nature)

	if nature_index < 0 or nature_index >= NATURE_NAMES.size():
		nature_name.text = "Desconocida"
		return

	nature_name.text = NATURE_NAMES[nature_index]

func _actualizar_procedencia() -> void:
	if pokemon == null:
		return

	if fecha:
		fecha.text = (
			pokemon.met_date
			if not pokemon.met_date.is_empty()
			else "---"
		)

	if lugar_captura:
		lugar_captura.text = (
			pokemon.met_location
			if not pokemon.met_location.is_empty()
			else "---"
		)

	if encontrado:
		encontrado.text = "Encontrado con Nv. %d" % pokemon.met_level
