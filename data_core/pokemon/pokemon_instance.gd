extends Resource
class_name PokemonInstance

## Datos variables de una criatura concreta.
## Las estadísticas base y sprites viven en PokemonDataStruct.

enum Stat {
	HP = 0,
	ATTACK = 1,
	DEFENSE = 2,
	SPEED = 3,
	SP_ATTACK = 4,
	SP_DEFENSE = 5,
}

const STAT_COUNT: int = 6

# ------------------------------------------------------------
# Identidad / progreso
# ------------------------------------------------------------
@export var species_id: Species.SpeciesID = Species.SpeciesID.SPECIES_NONE
## Identificador de variante. "base" usa los datos normales de la especie.
@export var form_id: StringName = &"base"
@export_range(1, 100) var level: int = 1
@export var experience: int = 0
@export var nickname: String = ""

# ------------------------------------------------------------
# Combate / estado
# ------------------------------------------------------------
@export var current_hp: int = 0
@export var max_hp: int = 0
@export var ability_id: AbilityId.Id = AbilityId.Id.NONE
@export var held_item: Items.ItemId = Items.ItemId.ITEM_NONE
@export var moves: Array[PokemonMoveSlot] = []

# ------------------------------------------------------------
# Individualidad
# ------------------------------------------------------------
@export_range(0, 255) var friendship: int = 70
@export var nature: PokemonData.Nature = PokemonData.Nature.NATURE_HARDY
@export var gender: PokemonData.Gender = PokemonData.Gender.GENDERLESS
@export var personality_value: int = 0

## IVs y EVs en orden: HP, Atk, Def, Spe, SpAtk, SpDef
@export var ivs: Array[int] = [0, 0, 0, 0, 0, 0]
@export var evs: Array[int] = [0, 0, 0, 0, 0, 0]

## Stats finales cacheados (mismo orden que IVs/EVs).
## Se recalculan con recalculate_stats().
@export var stats: Array[int] = [0, 0, 0, 0, 0, 0]

## Tipo Tera de esta criatura (por defecto el type_1 de la especie).
@export var tera_type: PokemonData.Type = PokemonData.Type.TYPE_NONE

# ============================================================
# ESPECIE
# ============================================================

func get_species() -> PokemonDataStruct:
	return SpeciesDatabase.get_species(species_id)


func set_form(new_form_id: StringName) -> bool:
	if new_form_id.is_empty() or new_form_id == &"base":
		form_id = &"base"
		return true
	var species: PokemonDataStruct = get_species()
	if species == null:
		return false
	for form: PokemonFormData in species.forms:
		if form != null and form.form_id == new_form_id:
			form_id = new_form_id
			return true
	return false

func reset_form() -> void:
	form_id = &"base"

func get_active_form() -> PokemonFormData:
	return PokemonFormResolver.get_form(self)

func get_front_sprite(shiny: bool = false) -> Texture2D:
	return PokemonFormResolver.get_front_sprite(self, shiny)

func get_back_sprite(shiny: bool = false) -> Texture2D:
	return PokemonFormResolver.get_back_sprite(self, shiny)

func get_icon_sprite() -> Texture2D:
	return PokemonFormResolver.get_icon_sprite(self)

func get_cry() -> AudioStream:
	return PokemonFormResolver.get_cry(self)

func get_type_1() -> PokemonData.Type:
	return PokemonFormResolver.get_type_1(self)

func get_type_2() -> PokemonData.Type:
	return PokemonFormResolver.get_type_2(self)

func set_species(new_species: Species.SpeciesID) -> bool:
	if new_species == Species.SpeciesID.SPECIES_NONE:
		return false
	if not SpeciesDatabase.has_species(new_species):
		return false
	species_id = new_species
	form_id = &"base"
	return true


func get_display_name() -> String:
	if not nickname.strip_edges().is_empty():
		return nickname
	var species: PokemonDataStruct = get_species()
	return species.species_name if species else "???"


# ============================================================
# HP / ESTADO
# ============================================================

func is_fainted() -> bool:
	return current_hp <= 0


func get_hp_percent() -> float:
	if max_hp <= 0:
		return 0.0
	return clampf(float(current_hp) / float(max_hp), 0.0, 1.0)


func heal_full() -> void:
	recalculate_stats()
	current_hp = max_hp
	restore_pp()


func apply_damage(amount: int) -> void:
	if amount <= 0:
		return
	current_hp = maxi(0, current_hp - amount)


func apply_heal(amount: int) -> void:
	if amount <= 0:
		return
	current_hp = mini(max_hp, current_hp + amount)


# ============================================================
# STATS
# ============================================================

func get_stat(stat: Stat) -> int:
	var index: int = int(stat)
	if index < 0 or index >= stats.size():
		return 0
	return stats[index]


func get_base_stat(stat: Stat, species: PokemonDataStruct) -> int:
	if species == null:
		return 1
	match stat:
		Stat.HP:
			return species.base_hp
		Stat.ATTACK:
			return species.base_attack
		Stat.DEFENSE:
			return species.base_defense
		Stat.SPEED:
			return species.base_speed
		Stat.SP_ATTACK:
			return species.base_sp_attack
		Stat.SP_DEFENSE:
			return species.base_sp_defense
		_:
			return 1


## Multiplicador de naturaleza: 1.1 / 1.0 / 0.9
func get_nature_modifier(stat: Stat) -> float:
	# HP no se ve afectado por naturaleza.
	if stat == Stat.HP:
		return 1.0

	var raised: Stat = _nature_raised_stat(nature)
	var lowered: Stat = _nature_lowered_stat(nature)

	if raised == stat and lowered != stat:
		return 1.1
	if lowered == stat and raised != stat:
		return 0.9
	return 1.0


func recalculate_stats() -> void:
	var species: PokemonDataStruct = get_species()
	if species == null:
		stats = [1, 1, 1, 1, 1, 1]
		max_hp = 1
		current_hp = mini(current_hp, max_hp)
		return

	_ensure_iv_ev_size()

	var old_max_hp: int = max_hp
	var new_stats: Array[int] = []
	new_stats.resize(STAT_COUNT)

	for i: int in range(STAT_COUNT):
		var stat: Stat = i as Stat
		var base: int = get_base_stat(stat, species)
		var iv: int = clampi(ivs[i], 0, 31)
		var ev: int = clampi(evs[i], 0, 255)

		if stat == Stat.HP:
			# floor((2*B + IV + EV/4) * N / 100) + N + 10
			new_stats[i] = int(
				floor((2.0 * base + iv + floor(ev / 4.0)) * level / 100.0)
			) + level + 10
		else:
			# floor((floor((2*B + IV + EV/4) * N / 100) + 5) * Nature)
			var raw: int = int(
				floor((2.0 * base + iv + floor(ev / 4.0)) * level / 100.0)
			) + 5
			new_stats[i] = maxi(1, int(floor(raw * get_nature_modifier(stat))))

	stats = new_stats
	max_hp = stats[Stat.HP]

	# Mantener proporción de HP al recalcular (level up, etc.).
	if old_max_hp <= 0:
		current_hp = max_hp
	else:
		var ratio: float = float(current_hp) / float(old_max_hp)
		current_hp = clampi(int(round(ratio * max_hp)), 0, max_hp)
		if current_hp == 0 and not is_fainted():
			current_hp = 1


# ============================================================
# MOVIMIENTOS
# ============================================================

func learn_move(move_id: Moves.MoveId) -> bool:
	if move_id == Moves.MoveId.MOVE_NONE:
		return false

	for slot: PokemonMoveSlot in moves:
		if slot and slot.move_id == move_id:
			return false

	var new_slot: PokemonMoveSlot = PokemonMoveSlot.new()
	new_slot.setup(move_id)

	if moves.size() >= 4:
		moves.pop_front()

	moves.append(new_slot)
	return true


func restore_pp() -> void:
	for slot: PokemonMoveSlot in moves:
		if slot and not slot.is_empty():
			var move_data: MoveData = MoveDatabase.get_move(slot.move_id)
			if move_data:
				slot.current_pp = move_data.pp


# ============================================================
# CREACIÓN
# ============================================================

static func create(species: Species.SpeciesID, initial_level: int = 5) -> PokemonInstance:
	var pokemon: PokemonInstance = PokemonInstance.new()
	pokemon.species_id = species
	pokemon.level = clampi(initial_level, 1, 100)

	var data: PokemonDataStruct = SpeciesDatabase.get_species(species)

	if data == null:
		pokemon.recalculate_stats()
		return pokemon

	# La experiencia inicial debe corresponder al nivel creado.
	pokemon.experience = ExperienceSystem.get_total_exp_for_level(pokemon.level, data.growth_rate)

	# Personalidad
	pokemon.personality_value = randi()
	pokemon.nature = (randi() % PokemonData.NUM_NATURES) as PokemonData.Nature
	pokemon.gender = _roll_gender(data.gender_ratio, pokemon.personality_value)
	pokemon.friendship = clampi(data.friendship, 0, 255)

	# Habilidad (por ahora siempre ability_1; luego puedes usar PID)
	pokemon.ability_id = data.ability_1
	# Tera Type: por defecto el tipo primario de la especie
	pokemon.tera_type = data.type_1
	pokemon.tera_type = _roll_tera_type(data)
	# IVs aleatorios 0-31
	pokemon.ivs = []
	for i: int in range(STAT_COUNT):
		pokemon.ivs.append(randi_range(0, 31))

	pokemon.evs = [0, 0, 0, 0, 0, 0]

	# Movimientos por nivel
	var learnable: Array[LevelUpMove] = data.level_up_moves.duplicate()
	learnable.sort_custom(func(a: LevelUpMove, b: LevelUpMove) -> bool:
		return a.level < b.level
	)
	for entry: LevelUpMove in learnable:
		if entry and entry.level <= pokemon.level:
			pokemon.learn_move(entry.move)

	pokemon.recalculate_stats()
	pokemon.current_hp = pokemon.max_hp
	return pokemon

static func _roll_tera_type(species: PokemonDataStruct) -> PokemonData.Type:
	if species == null:
		return PokemonData.Type.TYPE_NONE
	# Default oficial: tipo primario
	return species.type_1

# ============================================================
# INTERNOS
# ============================================================

func _ensure_iv_ev_size() -> void:
	while ivs.size() < STAT_COUNT:
		ivs.append(0)
	while evs.size() < STAT_COUNT:
		evs.append(0)
	if ivs.size() > STAT_COUNT:
		ivs.resize(STAT_COUNT)
	if evs.size() > STAT_COUNT:
		evs.resize(STAT_COUNT)


static func _roll_gender(ratio: PokemonData.GenderRatio, pid: int) -> PokemonData.Gender:
	match ratio:
		PokemonData.GenderRatio.GENDER_MALE_100:
			return PokemonData.Gender.MALE
		PokemonData.GenderRatio.GENDER_FEMALE_100:
			return PokemonData.Gender.FEMALE
		PokemonData.GenderRatio.GENDER_GENDERLESS:
			return PokemonData.Gender.GENDERLESS
		_:
			# Thresholds aproximados estilo juegos principales (byte bajo del PID).
			var value: int = pid & 0xFF
			var threshold: int = 127
			match ratio:
				PokemonData.GenderRatio.GENDER_FEMALE_87_5:
					threshold = 31
				PokemonData.GenderRatio.GENDER_FEMALE_75:
					threshold = 63
				PokemonData.GenderRatio.GENDER_FEMALE_50:
					threshold = 127
				PokemonData.GenderRatio.GENDER_FEMALE_25:
					threshold = 191
				PokemonData.GenderRatio.GENDER_FEMALE_12_5:
					threshold = 223
				_:
					threshold = 127
			return PokemonData.Gender.FEMALE if value < threshold else PokemonData.Gender.MALE


static func _nature_raised_stat(n: PokemonData.Nature) -> Stat:
	match n:
		PokemonData.Nature.NATURE_LONELY, PokemonData.Nature.NATURE_BRAVE, \
		PokemonData.Nature.NATURE_ADAMANT, PokemonData.Nature.NATURE_NAUGHTY:
			return Stat.ATTACK
		PokemonData.Nature.NATURE_BOLD, PokemonData.Nature.NATURE_RELAXED, \
		PokemonData.Nature.NATURE_IMPISH, PokemonData.Nature.NATURE_LAX:
			return Stat.DEFENSE
		PokemonData.Nature.NATURE_TIMID, PokemonData.Nature.NATURE_HASTY, \
		PokemonData.Nature.NATURE_JOLLY, PokemonData.Nature.NATURE_NAIVE:
			return Stat.SPEED
		PokemonData.Nature.NATURE_MODEST, PokemonData.Nature.NATURE_MILD, \
		PokemonData.Nature.NATURE_QUIET, PokemonData.Nature.NATURE_RASH:
			return Stat.SP_ATTACK
		PokemonData.Nature.NATURE_CALM, PokemonData.Nature.NATURE_GENTLE, \
		PokemonData.Nature.NATURE_SASSY, PokemonData.Nature.NATURE_CAREFUL:
			return Stat.SP_DEFENSE
		_:
			return Stat.HP  # neutrales: sin cambio real


static func _nature_lowered_stat(n: PokemonData.Nature) -> Stat:
	match n:
		PokemonData.Nature.NATURE_BOLD, PokemonData.Nature.NATURE_TIMID, \
		PokemonData.Nature.NATURE_MODEST, PokemonData.Nature.NATURE_CALM:
			return Stat.ATTACK
		PokemonData.Nature.NATURE_LONELY, PokemonData.Nature.NATURE_HASTY, \
		PokemonData.Nature.NATURE_MILD, PokemonData.Nature.NATURE_GENTLE:
			return Stat.DEFENSE
		PokemonData.Nature.NATURE_BRAVE, PokemonData.Nature.NATURE_RELAXED, \
		PokemonData.Nature.NATURE_QUIET, PokemonData.Nature.NATURE_SASSY:
			return Stat.SPEED
		PokemonData.Nature.NATURE_ADAMANT, PokemonData.Nature.NATURE_IMPISH, \
		PokemonData.Nature.NATURE_JOLLY, PokemonData.Nature.NATURE_CAREFUL:
			return Stat.SP_ATTACK
		PokemonData.Nature.NATURE_NAUGHTY, PokemonData.Nature.NATURE_LAX, \
		PokemonData.Nature.NATURE_NAIVE, PokemonData.Nature.NATURE_RASH:
			return Stat.SP_DEFENSE
		_:
			return Stat.HP


# ============================================================
# SERIALIZACIÓN OPCIONAL (por si el save lo necesita explícito)
# ============================================================

func to_dict() -> Dictionary:
	var move_dicts: Array = []
	for slot: PokemonMoveSlot in moves:
		if slot == null:
			continue
		move_dicts.append({
			"move_id": int(slot.move_id),
			"current_pp": slot.current_pp,
			"pp_ups": slot.pp_ups,
		})

	return {
		"species_id": int(species_id),
		"form_id": str(form_id),
		"level": level,
		"experience": experience,
		"nickname": nickname,
		"current_hp": current_hp,
		"max_hp": max_hp,
		"ability_id": int(ability_id),
		"tera_type": int(tera_type),
		"held_item": int(held_item),
		"friendship": friendship,
		"nature": int(nature),
		"gender": int(gender),
		"personality_value": personality_value,
		"ivs": ivs.duplicate(),
		"evs": evs.duplicate(),
		"stats": stats.duplicate(),
		"moves": move_dicts,
	}


static func from_dict(data: Dictionary) -> PokemonInstance:
	var pokemon: PokemonInstance = PokemonInstance.new()
	pokemon.species_id = int(data.get("species_id", 0)) as Species.SpeciesID
	pokemon.form_id = StringName(str(data.get("form_id", "base")))
	pokemon.level = int(data.get("level", 1))
	pokemon.experience = int(data.get("experience", 0))
	pokemon.nickname = str(data.get("nickname", ""))
	pokemon.current_hp = int(data.get("current_hp", 0))
	pokemon.max_hp = int(data.get("max_hp", 0))
	pokemon.ability_id = int(data.get("ability_id", 0)) as AbilityId.Id
	pokemon.tera_type = int(data.get("tera_type", 0)) as PokemonData.Type
	pokemon.held_item = int(data.get("held_item", 0)) as Items.ItemId
	pokemon.friendship = int(data.get("friendship", 70))
	pokemon.nature = int(data.get("nature", 0)) as PokemonData.Nature
	pokemon.gender = int(data.get("gender", 0)) as PokemonData.Gender
	pokemon.personality_value = int(data.get("personality_value", 0))

	var loaded_ivs: Variant = data.get("ivs", [0, 0, 0, 0, 0, 0])
	var loaded_evs: Variant = data.get("evs", [0, 0, 0, 0, 0, 0])
	pokemon.ivs = []
	pokemon.evs = []
	if loaded_ivs is Array:
		for v: Variant in loaded_ivs:
			pokemon.ivs.append(int(v))
	if loaded_evs is Array:
		for v: Variant in loaded_evs:
			pokemon.evs.append(int(v))

	pokemon.moves.clear()
	var loaded_moves: Variant = data.get("moves", [])
	if loaded_moves is Array:
		for entry: Variant in loaded_moves:
			if entry is Dictionary:
				var slot: PokemonMoveSlot = PokemonMoveSlot.new()
				slot.move_id = int(entry.get("move_id", 0)) as Moves.MoveId
				slot.current_pp = int(entry.get("current_pp", 0))
				slot.pp_ups = int(entry.get("pp_ups", 0))
				pokemon.moves.append(slot)

	pokemon.recalculate_stats()
	# Si venía current_hp del save, respetarlo tras recalcular max.
	if data.has("current_hp"):
		pokemon.current_hp = clampi(int(data["current_hp"]), 0, pokemon.max_hp)
	else:
		pokemon.current_hp = pokemon.max_hp

	return pokemon
