extends RefCounted
class_name CaptureResolver

## Captura estilo Gen 5+ (sin animación de sacudidas en UI).
## Devuelve shakes 0–4; 4 = capturado. Master Ball siempre 4.

class Result:
	var success: bool = false
	## 0 = falló al instante; 1–3 = falló tras N sacudidas; 4 = capturado.
	var shakes: int = 0
	var message: String = ""
	var captured: PokemonInstance = null


## Bonus de estado (Gen 5+).
static func status_bonus(status: PokemonInstance.Status) -> float:
	match status:
		PokemonInstance.Status.SLEEP, PokemonInstance.Status.FREEZE:
			return 2.5
		PokemonInstance.Status.POISON, PokemonInstance.Status.TOXIC, \
		PokemonInstance.Status.BURN, PokemonInstance.Status.PARALYSIS:
			return 1.5
		_:
			return 1.0


## Multiplicador de la ball según tipo y contexto de combate.
static func ball_bonus(
	ball_id: Items.ItemId,
	target: PokemonInstance,
	battle: BattleManager,
	turn_count: int,
	already_owned: bool
) -> float:
	if target == null:
		return 1.0
	var species: PokemonDataStruct = target.get_species()
	var t1: PokemonData.Type = PokemonData.Type.TYPE_NONE
	var t2: PokemonData.Type = PokemonData.Type.TYPE_NONE
	if species != null:
		t1 = species.type_1
		t2 = species.type_2

	match ball_id:
		Items.ItemId.ITEM_MASTER_BALL, Items.ItemId.ITEM_PARK_BALL:
			return 255.0  # se trata como captura garantizada fuera
		Items.ItemId.ITEM_POKE_BALL, Items.ItemId.ITEM_PREMIER_BALL, \
		Items.ItemId.ITEM_LUXURY_BALL, Items.ItemId.ITEM_HEAL_BALL, \
		Items.ItemId.ITEM_CHERISH_BALL, Items.ItemId.ITEM_FRIEND_BALL:
			return 1.0
		Items.ItemId.ITEM_GREAT_BALL, Items.ItemId.ITEM_SAFARI_BALL, \
		Items.ItemId.ITEM_SPORT_BALL:
			return 1.5
		Items.ItemId.ITEM_ULTRA_BALL:
			return 2.0
		Items.ItemId.ITEM_NET_BALL:
			if t1 == PokemonData.Type.TYPE_BUG or t2 == PokemonData.Type.TYPE_BUG \
					or t1 == PokemonData.Type.TYPE_WATER or t2 == PokemonData.Type.TYPE_WATER:
				return 3.5
			return 1.0
		Items.ItemId.ITEM_NEST_BALL:
			# Gen 5+: ((41 - level) / 10), mínimo 1
			var nest: float = float(41 - target.level) / 10.0
			return maxf(1.0, nest)
		Items.ItemId.ITEM_DIVE_BALL:
			# Sin dato de buceo: ×1.0; si el combate expone is_underwater, ×3.5
			if battle != null and battle.get("is_underwater") == true:
				return 3.5
			return 1.0
		Items.ItemId.ITEM_DUSK_BALL:
			# Noche o cueva
			var night: bool = false
			if DnsManager != null and DnsManager.has_method("get") or true:
				if DnsManager.current_time_state == DnsManager.TimeOfDay.NIGHT \
						or DnsManager.current_time_state == DnsManager.TimeOfDay.DUSK:
					night = true
			if battle != null and battle.get("is_dark_place") == true:
				night = true
			return 3.0 if night else 1.0
		Items.ItemId.ITEM_TIMER_BALL:
			# 1 + turns * 1229/4096, máx 4 (Gen 5+)
			var tb: float = 1.0 + float(turn_count) * 1229.0 / 4096.0
			return minf(4.0, tb)
		Items.ItemId.ITEM_QUICK_BALL:
			return 5.0 if turn_count <= 1 else 1.0
		Items.ItemId.ITEM_REPEAT_BALL:
			return 3.5 if already_owned else 1.0
		Items.ItemId.ITEM_LEVEL_BALL:
			return 1.0  # requiere nivel del jugador; se ajusta en attempt si hay actor
		Items.ItemId.ITEM_LURE_BALL:
			if battle != null and battle.get("is_fishing") == true:
				return 5.0  # Gen 7+
			return 1.0
		Items.ItemId.ITEM_MOON_BALL:
			# Evoluciona con Piedra Lunar: sin tabla completa → 1.0 por defecto
			return 1.0
		Items.ItemId.ITEM_LOVE_BALL:
			return 1.0  # se ajusta con género en attempt
		Items.ItemId.ITEM_FAST_BALL:
			if species != null and species.base_speed >= 100:
				return 4.0
			return 1.0
		Items.ItemId.ITEM_HEAVY_BALL:
			if species == null:
				return 1.0
			# weight en hectogramos típico de datos
			var w: int = species.weight
			if w < 1000:
				return 0.5  # más bien penaliza; se suma al rate en gen clásica
			if w < 2000:
				return 1.0
			if w < 3000:
				return 2.0
			return 3.0
		Items.ItemId.ITEM_DREAM_BALL:
			if target.status == PokemonInstance.Status.SLEEP:
				return 4.0
			return 1.0
		Items.ItemId.ITEM_BEAST_BALL:
			return 0.1  # Ultra Beasts no modelados → genérico bajo
		_:
			return 1.0


## Tasa modificada a (0–inf). Si >= 255, captura segura.
static func modified_catch_rate(
	target: PokemonInstance,
	ball_id: Items.ItemId,
	battle: BattleManager,
	turn_count: int,
	already_owned: bool,
	player_active: BattleBattler = null
) -> float:
	if target == null or target.max_hp <= 0:
		return 0.0
	if ball_id == Items.ItemId.ITEM_MASTER_BALL or ball_id == Items.ItemId.ITEM_PARK_BALL:
		return 255.0

	var species: PokemonDataStruct = target.get_species()
	var catch_rate: int = 255
	if species != null:
		catch_rate = clampi(species.catch_rate, 1, 255)

	var bonus: float = ball_bonus(ball_id, target, battle, turn_count, already_owned)

	# Level Ball con atacante
	if ball_id == Items.ItemId.ITEM_LEVEL_BALL and player_active != null and player_active.pokemon != null:
		var pl: int = player_active.pokemon.level
		var ol: int = target.level
		if pl > ol * 4:
			bonus = 8.0
		elif pl > ol * 2:
			bonus = 4.0
		elif pl > ol:
			bonus = 2.0
		else:
			bonus = 1.0

	# Love Ball
	if ball_id == Items.ItemId.ITEM_LOVE_BALL and player_active != null and player_active.pokemon != null:
		var pg: PokemonData.Gender = player_active.pokemon.gender
		var tg: PokemonData.Gender = target.gender
		if pg != PokemonData.Gender.GENDERLESS and tg != PokemonData.Gender.GENDERLESS \
				and player_active.pokemon.species_id == target.species_id and pg != tg:
			bonus = 8.0

	var hp_term: float = float(3 * target.max_hp - 2 * target.current_hp)
	hp_term = maxf(1.0, hp_term)
	var a: float = (hp_term * float(catch_rate) * bonus) / float(3 * target.max_hp)
	a *= status_bonus(target.status)
	return a


## Probabilidad de cada sacudida (0–65535 threshold).
static func shake_threshold(a: float) -> int:
	if a <= 0.0:
		return 0
	if a >= 255.0:
		return 65536
	# b = floor(65536 / (255/a)^0.25)
	var inv: float = 255.0 / a
	var root: float = sqrt(sqrt(inv))
	if root <= 0.0:
		return 65536
	return int(floor(65536.0 / root))


static func attempt(
	ball_id: Items.ItemId,
	target: PokemonInstance,
	battle: BattleManager,
	turn_count: int = 1,
	already_owned: bool = false,
	player_active: BattleBattler = null
) -> Result:
	var result: Result = Result.new()
	if target == null:
		result.message = "No hay objetivo."
		return result

	var a: float = modified_catch_rate(target, ball_id, battle, turn_count, already_owned, player_active)

	if a >= 255.0:
		result.success = true
		result.shakes = 4
		result.message = "¡Capturado!"
		return result

	var b: int = shake_threshold(a)
	var shakes: int = 0
	for i: int in range(4):
		var roll: int = randi() % 65536
		if roll >= b:
			result.success = false
			result.shakes = shakes
			result.message = _fail_message(shakes)
			return result
		shakes += 1

	result.success = true
	result.shakes = 4
	result.message = "¡Capturado!"
	return result


static func _fail_message(shakes: int) -> String:
	match shakes:
		0:
			return "¡Oh no! ¡El Pokémon se liberó!"
		1:
			return "¡Vaya! ¡Parecía que se había atrapado!"
		2:
			return "¡Qué pena! ¡Casi lo consigues!"
		3:
			return "¡Caray! ¡Estuvo a punto de atraparse!"
		_:
			return "¡Falló la captura!"


## Copia independiente del salvaje para meter en el equipo.
static func clone_for_party(source: PokemonInstance, ball_used: Items.ItemId) -> PokemonInstance:
	if source == null:
		return null
	var copy: PokemonInstance = PokemonInstance.from_dict(source.to_dict())
	# Friend Ball sube amistad base
	if ball_used == Items.ItemId.ITEM_FRIEND_BALL:
		copy.friendship = 200
	# Heal Ball cura
	if ball_used == Items.ItemId.ITEM_HEAL_BALL:
		copy.current_hp = copy.max_hp
		copy.cure_status()
	return copy
