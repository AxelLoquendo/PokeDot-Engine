extends Resource
class_name TrainerData

## Entrenador definido en un archivo de res://game/trainers/.
## Ver docs/ENTRENADORES.md para el formato.

## Identificador usado en los scripts (trainerbattle TRAINER_ROCIO). Al ganarle
## se activa una flag con este mismo nombre.
@export var trainer_id: String = ""
@export var trainer_name: String = ""
@export var trainer_class: String = ""
## Ruta al sprite del entrenador. Todavía no se muestra en combate.
@export var pic: String = ""
## Dinero que recibe el jugador al ganar.
@export var money: int = 0
@export var double_battle: bool = false
## Valor de BattleSession.BattleType; decide la música del combate.
@export var battle_type: int = 2
@export var party: Array[TrainerPokemon] = []

## Dónde se definió, para los mensajes de error.
var source_path: String = ""
var source_line: int = 0


## "Cazabichos Rocío", o solo el nombre si no tiene clase.
func get_display_name() -> String:
	return ("%s %s" % [trainer_class, trainer_name]).strip_edges()


func build_party() -> Array[PokemonInstance]:
	var result: Array[PokemonInstance] = []
	for entry: TrainerPokemon in party:
		if entry != null:
			result.append(entry.create_instance())
	return result
