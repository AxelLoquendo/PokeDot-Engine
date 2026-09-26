extends RefCounted
class_name TrainerPartyParser

## Lee archivos de entrenadores (formato trainers.party, Pokémon en formato
## Showdown). Nombres en inglés o como constante del enum.

const MAX_PARTY_SIZE: int = 6
const MAX_MOVES: int = 4
const MAX_EV_TOTAL: int = 510

const TRAINER_FIELDS: Array[String] = ["name", "class", "pic", "money", "reward", "double battle", "music"]
const MON_FIELDS: Array[String] = ["level", "ability", "shiny", "happiness", "friendship", "tera type", "evs", "ivs"]
## Se aceptan pero todavía no hacen nada.
const UNUSED_TRAINER_FIELDS: Array[String] = ["gender", "items", "ai", "mugshot", "starting status", "party size"]
const UNUSED_MON_FIELDS: Array[String] = ["ball", "pokeball", "dynamax level", "gigantamax", "hidden power"]

## Stat de Showdown -> índice en PokemonInstance.
const STAT_INDEX: Dictionary = {"HP": 0, "ATK": 1, "DEF": 2, "SPE": 3, "SPA": 4, "SPD": 5}

## Music -> BattleSession.BattleType.
const MUSIC_TYPES: Dictionary = {
	"TRAINER": 2, "ENTRENADOR": 2,
	"GYM LEADER": 3, "LIDER": 3, "LIDER DE GIMNASIO": 3,
	"ELITE FOUR": 4, "ALTO MANDO": 4,
	"CHAMPION": 5, "CAMPEON": 5,
}

const ACCENTS: Dictionary = {
	"Á": "A", "É": "E", "Í": "I", "Ó": "O", "Ú": "U", "Ü": "U", "Ñ": "N",
}

var trainers: Array[TrainerData] = []
## Mensajes "archivo:línea: texto".
var errors: Array[String] = []
var warnings: Array[String] = []

var _source: String = ""
var _mon_line: int = 0
var _mon_has_level: bool = false


func parse_file(path: String) -> void:
	if not FileAccess.file_exists(path):
		errors.append("%s: el archivo no existe." % path)
		return
	parse_text(FileAccess.get_file_as_string(path), path)


func parse_text(text: String, source: String) -> void:
	_source = source
	var trainer: TrainerData = null
	var mon: TrainerPokemon = null
	var in_header: bool = false
	var skipping_block: bool = false
	var lines: PackedStringArray = text.replace("\r", "").split("\n")

	for index: int in lines.size():
		var line_number: int = index + 1
		var line: String = lines[index].strip_edges()
		if line.begins_with("#") or line.begins_with("//"):
			continue
		if line.is_empty():
			_finish_pokemon(mon)
			mon = null
			in_header = false
			skipping_block = false
			continue
		if line.begins_with("==="):
			_finish_pokemon(mon)
			_finish_trainer(trainer)
			mon = null
			trainer = _start_trainer(line, line_number)
			in_header = trainer != null
			skipping_block = trainer == null
			continue
		if skipping_block:
			continue
		if trainer == null:
			_error(line_number, "falta la cabecera \"=== TRAINER_ID ===\" antes de esta línea.")
			skipping_block = true
			continue
		if in_header:
			_parse_trainer_field(trainer, line, line_number)
		elif mon == null:
			mon = _start_pokemon(trainer, line, line_number)
			skipping_block = mon == null
		else:
			_parse_pokemon_field(mon, line, line_number)

	_finish_pokemon(mon)
	_finish_trainer(trainer)


# ------------------------------------------------------------
# Entrenador
# ------------------------------------------------------------

func _start_trainer(line: String, line_number: int) -> TrainerData:
	var trainer_id: String = line.trim_prefix("===").trim_suffix("===").strip_edges().to_upper()
	if not RegEx.create_from_string("^[A-Z0-9_]+$").search(trainer_id):
		_error(line_number, "el ID \"%s\" solo puede tener letras, números y _ (ej. TRAINER_ROCIO)." % trainer_id)
		return null
	for existing: TrainerData in trainers:
		if existing.trainer_id == trainer_id:
			_error(line_number, "%s ya está definido en la línea %d." % [trainer_id, existing.source_line])
			return null
	var trainer: TrainerData = TrainerData.new()
	trainer.trainer_id = trainer_id
	trainer.source_path = _source
	trainer.source_line = line_number
	return trainer


func _parse_trainer_field(trainer: TrainerData, line: String, line_number: int) -> void:
	var separator: int = line.find(":")
	if separator < 0:
		_error(line_number, "se esperaba \"Campo: valor\". ¿Falta una línea en blanco entre la cabecera y el primer Pokémon?")
		return
	var key: String = line.substr(0, separator).strip_edges().to_lower()
	var value: String = line.substr(separator + 1).strip_edges()
	match key:
		"name":
			trainer.trainer_name = value
		"class":
			trainer.trainer_class = value
		"pic":
			trainer.pic = value
		"money", "reward":
			if value.is_valid_int() and int(value) >= 0:
				trainer.money = int(value)
			else:
				_error(line_number, "Money debe ser un número entero, no \"%s\"." % value)
		"double battle":
			trainer.double_battle = _parse_yes_no(value, line_number)
		"music":
			var music_key: String = _plain_upper(value)
			if MUSIC_TYPES.has(music_key):
				trainer.battle_type = int(MUSIC_TYPES[music_key])
			else:
				_warning(line_number, "Music \"%s\" no existe; usa Trainer, Gym Leader, Elite Four o Champion." % value)
		_:
			if not UNUSED_TRAINER_FIELDS.has(key):
				_warning(line_number, "campo de entrenador desconocido \"%s\".%s" % [key, _suggest_field(key, TRAINER_FIELDS)])


func _finish_trainer(trainer: TrainerData) -> void:
	if trainer == null:
		return
	if trainer.party.is_empty():
		_error(trainer.source_line, "%s no tiene ningún Pokémon." % trainer.trainer_id)
		return
	if trainer.double_battle and trainer.party.size() < 2:
		_warning(trainer.source_line, "%s es combate doble pero solo tiene un Pokémon." % trainer.trainer_id)
	trainers.append(trainer)


# ------------------------------------------------------------
# Pokémon
# ------------------------------------------------------------

## "Apodo (Especie) (M) @ Objeto". Si la especie no existe no se añade al
## equipo, pero sus líneas se siguen revisando.
func _start_pokemon(trainer: TrainerData, line: String, line_number: int) -> TrainerPokemon:
	if trainer.party.size() >= MAX_PARTY_SIZE:
		_error(line_number, "%s ya tiene %d Pokémon; este se ignora." % [trainer.trainer_id, MAX_PARTY_SIZE])
		return null
	var mon: TrainerPokemon = TrainerPokemon.new()
	_mon_line = line_number
	_mon_has_level = false
	var left: String = line
	var at: int = line.rfind("@")
	if at >= 0:
		left = line.substr(0, at).strip_edges()
		var item: int = _resolve(Items.ItemId, "ITEM_", line.substr(at + 1), "Objeto desconocido", line_number)
		if item >= 0:
			mon.held_item = item as Items.ItemId
	if left.ends_with("(M)") or left.ends_with("(F)"):
		mon.gender = 0 if left.ends_with("(M)") else 1
		left = left.substr(0, left.length() - 3).strip_edges()

	var species_name: String = left
	var nickname_match: RegExMatch = RegEx.create_from_string("^(.+)\\(([^()]+)\\)$").search(left)
	if nickname_match:
		mon.nickname = nickname_match.get_string(1).strip_edges()
		species_name = nickname_match.get_string(2)

	var species: int = _resolve(Species.SpeciesID, "SPECIES_", species_name, "Especie desconocida", line_number)
	if species >= 0:
		mon.species_id = species as Species.SpeciesID
		trainer.party.append(mon)
	return mon


func _parse_pokemon_field(mon: TrainerPokemon, line: String, line_number: int) -> void:
	if line.begins_with("-"):
		if mon.moves.size() >= MAX_MOVES:
			_error(line_number, "un Pokémon solo puede tener %d movimientos." % MAX_MOVES)
			return
		# Quita el tipo de "Hidden Power [Fire]"
		var move_name: String = line.substr(1).get_slice("[", 0)
		var move: int = _resolve(Moves.MoveId, "MOVE_", move_name, "Movimiento desconocido", line_number)
		if move >= 0:
			mon.moves.append(move as Moves.MoveId)
		return
	if line.ends_with(" Nature"):
		var nature: int = _resolve(PokemonData.Nature, "NATURE_", line.trim_suffix(" Nature"), "Naturaleza desconocida", line_number)
		if nature >= 0:
			mon.nature = nature as PokemonData.Nature
		return

	var separator: int = line.find(":")
	if separator < 0:
		_warning(line_number, "línea no reconocida \"%s\"." % line)
		return
	var key: String = line.substr(0, separator).strip_edges().to_lower()
	var value: String = line.substr(separator + 1).strip_edges()
	match key:
		"level":
			_mon_has_level = true
			if value.is_valid_int() and int(value) >= 1 and int(value) <= 100:
				mon.level = int(value)
			else:
				_error(line_number, "Level debe estar entre 1 y 100, no \"%s\"." % value)
		"ability":
			var ability: int = _resolve(AbilityId.Id, "", value, "Habilidad desconocida", line_number)
			if ability >= 0:
				mon.ability_id = ability as AbilityId.Id
		"shiny":
			mon.shiny = _parse_yes_no(value, line_number)
		"happiness", "friendship":
			if value.is_valid_int() and int(value) >= 0 and int(value) <= 255:
				mon.friendship = int(value)
			else:
				_error(line_number, "Happiness debe estar entre 0 y 255, no \"%s\"." % value)
		"tera type":
			var tera: int = _resolve(PokemonData.Type, "TYPE_", value, "Tipo Tera desconocido", line_number)
			if tera >= 0:
				mon.tera_type = tera as PokemonData.Type
		"evs":
			_parse_stat_spread(mon.evs, value, 255, line_number)
			var total: int = 0
			for ev: int in mon.evs:
				total += ev
			if total > MAX_EV_TOTAL:
				_warning(line_number, "los EVs suman %d; el máximo en los juegos es %d." % [total, MAX_EV_TOTAL])
		"ivs":
			_parse_stat_spread(mon.ivs, value, 31, line_number)
		_:
			if UNUSED_MON_FIELDS.has(key):
				_warning(line_number, "\"%s\" todavía no tiene efecto y se ignora." % key)
			else:
				_warning(line_number, "campo desconocido \"%s\".%s" % [key, _suggest_field(key, MON_FIELDS)])


func _finish_pokemon(mon: TrainerPokemon) -> void:
	if mon != null and not _mon_has_level:
		_warning(_mon_line, "sin \"Level:\"; se usa nivel %d como en Showdown." % mon.level)


## Solo cambia las stats que aparecen.
func _parse_stat_spread(target: Array[int], value: String, max_value: int, line_number: int) -> void:
	for part: String in value.split("/"):
		var pieces: PackedStringArray = part.strip_edges().split(" ", false)
		if pieces.size() != 2 or not pieces[0].is_valid_int() or not STAT_INDEX.has(pieces[1].to_upper()):
			_error(line_number, "\"%s\" no es válido; usa por ejemplo \"252 Atk / 4 SpD\"." % part.strip_edges())
			continue
		var amount: int = int(pieces[0])
		if amount < 0 or amount > max_value:
			_error(line_number, "%s debe estar entre 0 y %d." % [pieces[1], max_value])
			continue
		target[int(STAT_INDEX[pieces[1].to_upper()])] = amount


func _parse_yes_no(value: String, line_number: int) -> bool:
	match _plain_upper(value):
		"YES", "SI", "TRUE":
			return true
		"NO", "FALSE":
			return false
	_warning(line_number, "se esperaba Yes o No, no \"%s\"." % value)
	return false


# ------------------------------------------------------------
# Nombres a enums
# ------------------------------------------------------------

## Ej.: "Mr. Mime" = MR_MIME, "Nidoran♀" = NIDORAN_F.
static func to_constant(text: String) -> String:
	var value: String = _plain_upper(text.replace("♀", "-F").replace("♂", "-M"))
	value = value.replace("'", "").replace("’", "").replace(".", "")
	var result: String = ""
	for character: String in value:
		var code: int = character.unicode_at(0)
		if (code >= 65 and code <= 90) or (code >= 48 and code <= 57):
			result += character
		elif not result.is_empty() and not result.ends_with("_"):
			result += "_"
	return result.trim_suffix("_")


static func _plain_upper(text: String) -> String:
	var value: String = text.strip_edges().to_upper()
	for accented: String in ACCENTS.keys():
		value = value.replace(accented, ACCENTS[accented])
	return value


## Exacto o sin "_" (Softboiled = SOFT_BOILED). unknown_label va en el error.
func _resolve(enum_values: Dictionary, prefix: String, name: String, unknown_label: String, line_number: int) -> int:
	var constant: String = to_constant(name)
	if constant.is_empty():
		_error(line_number, "%s: falta el nombre." % unknown_label)
		return -1
	if not constant.begins_with(prefix):
		constant = prefix + constant
	if enum_values.has(constant):
		return int(enum_values[constant])
	var squashed: String = constant.replace("_", "")
	for key: String in enum_values.keys():
		if key.replace("_", "") == squashed:
			return int(enum_values[key])
	_error(line_number, "%s: \"%s\".%s" % [unknown_label, name.strip_edges(), _suggest(enum_values, constant)])
	return -1


func _suggest(enum_values: Dictionary, constant: String) -> String:
	var scored: Array[Array] = []
	for key: String in enum_values.keys():
		var score: float = key.similarity(constant)
		if score >= 0.5:
			scored.append([score, key])
	if scored.is_empty():
		return ""
	scored.sort_custom(func(a: Array, b: Array) -> bool: return float(a[0]) > float(b[0]))
	var names: Array[String] = []
	for entry: Array in scored.slice(0, 3):
		names.append(str(entry[1]))
	return " ¿Quisiste decir %s?" % ", ".join(names)


func _suggest_field(key: String, fields: Array[String]) -> String:
	var best: String = ""
	var best_score: float = 0.5
	for field: String in fields:
		var score: float = field.similarity(key)
		if score > best_score:
			best_score = score
			best = field
	if best.is_empty():
		return ""
	var shown: String = {"evs": "EVs", "ivs": "IVs"}.get(best, best.capitalize())
	return " ¿Quisiste decir \"%s\"?" % shown


func _error(line_number: int, message: String) -> void:
	errors.append("%s:%d: %s" % [_source, line_number, message])


func _warning(line_number: int, message: String) -> void:
	warnings.append("%s:%d: %s" % [_source, line_number, message])
