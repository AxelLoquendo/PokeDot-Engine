extends RefCounted
class_name HoldItemRuntime

## Efectos de objetos equipados en combate.
## Lee ItemData.hold_effect / hold_effect_param del ítem en held_item.


static func get_item_data(battler: BattleBattler) -> ItemData:
	if battler == null or battler.pokemon == null:
		return null
	if battler.pokemon.held_item == Items.ItemId.ITEM_NONE:
		return null
	return ItemDatabase.get_item(battler.pokemon.held_item)


static func get_hold_effect(battler: BattleBattler) -> HoldEffects.HoldEffect:
	var data: ItemData = get_item_data(battler)
	if data == null:
		return HoldEffects.HoldEffect.HOLD_EFFECT_NONE
	return data.hold_effect


static func get_hold_param(battler: BattleBattler) -> int:
	var data: ItemData = get_item_data(battler)
	if data == null:
		return 0
	return data.hold_effect_param


static func consume_held(battler: BattleBattler) -> void:
	if battler == null or battler.pokemon == null:
		return
	var id: int = int(battler.pokemon.held_item)
	if id != 0:
		battler.last_berry_id = id
	battler.pokemon.held_item = Items.ItemId.ITEM_NONE


## Multiplicador de potencia del atacante (Life Orb, Expert Belt, Muscle Band…).
static func attacker_power_multiplier(attacker: BattleBattler, move: MoveData, effectiveness: float) -> float:
	var he: HoldEffects.HoldEffect = get_hold_effect(attacker)
	var mult: float = 1.0
	match he:
		HoldEffects.HoldEffect.HOLD_EFFECT_LIFE_ORB:
			mult *= 1.3
		HoldEffects.HoldEffect.HOLD_EFFECT_EXPERT_BELT:
			if effectiveness > 1.0:
				mult *= 1.2
		HoldEffects.HoldEffect.HOLD_EFFECT_MUSCLE_BAND:
			if move != null and move.category == MoveStruct.DamageCategory.PHYSICAL:
				mult *= 1.1
		HoldEffects.HoldEffect.HOLD_EFFECT_WISE_GLASSES:
			if move != null and move.category == MoveStruct.DamageCategory.SPECIAL:
				mult *= 1.1
		HoldEffects.HoldEffect.HOLD_EFFECT_TYPE_POWER, \
		HoldEffects.HoldEffect.HOLD_EFFECT_PLATE, \
		HoldEffects.HoldEffect.HOLD_EFFECT_DRIVE, \
		HoldEffects.HoldEffect.HOLD_EFFECT_MEMORY:
			if move != null and int(move.type) == get_hold_param(attacker):
				mult *= 1.2
		HoldEffects.HoldEffect.HOLD_EFFECT_LIGHT_BALL:
			# Solo Pikachu: el chequeo de especie queda en AbilityRuntime/species si existe
			if attacker.pokemon != null:
				mult *= 2.0
		HoldEffects.HoldEffect.HOLD_EFFECT_THICK_CLUB:
			if attacker.pokemon != null:
				mult *= 2.0
		HoldEffects.HoldEffect.HOLD_EFFECT_CHOICE_BAND:
			if move != null and move.category == MoveStruct.DamageCategory.PHYSICAL:
				mult *= 1.5
		HoldEffects.HoldEffect.HOLD_EFFECT_CHOICE_SPECS:
			if move != null and move.category == MoveStruct.DamageCategory.SPECIAL:
				mult *= 1.5
		_:
			pass
	return mult


## Multiplicador de daño recibido (Eviolite, Assault Vest vía stats, Metal Powder…).
static func defender_damage_multiplier(defender: BattleBattler, move: MoveData) -> float:
	var he: HoldEffects.HoldEffect = get_hold_effect(defender)
	match he:
		HoldEffects.HoldEffect.HOLD_EFFECT_EVIOLITE:
			return 0.5  # simplificado: -50% daño (oficial es +50% Def/SpD)
		HoldEffects.HoldEffect.HOLD_EFFECT_METAL_POWDER:
			if move != null and move.category == MoveStruct.DamageCategory.PHYSICAL:
				return 0.5
		_:
			return 1.0
	return 1.0


static func speed_multiplier(battler: BattleBattler) -> float:
	match get_hold_effect(battler):
		HoldEffects.HoldEffect.HOLD_EFFECT_CHOICE_SCARF:
			return 1.5
		HoldEffects.HoldEffect.HOLD_EFFECT_IRON_BALL:
			return 0.5
		HoldEffects.HoldEffect.HOLD_EFFECT_QUICK_POWDER:
			return 2.0
		_:
			return 1.0


static func accuracy_multiplier(attacker: BattleBattler, defender: BattleBattler) -> float:
	var mult: float = 1.0
	match get_hold_effect(attacker):
		HoldEffects.HoldEffect.HOLD_EFFECT_WIDE_LENS:
			mult *= 1.1
		HoldEffects.HoldEffect.HOLD_EFFECT_ZOOM_LENS:
			if defender != null and bool(defender.get_meta("acted_this_turn", false)):
				mult *= 1.2
		HoldEffects.HoldEffect.HOLD_EFFECT_MICLE_BERRY:
			if bool(attacker.get_meta("micle_active", false)):
				mult *= 1.2
		_:
			pass
	return mult


static func crit_stage_bonus(battler: BattleBattler) -> int:
	match get_hold_effect(battler):
		HoldEffects.HoldEffect.HOLD_EFFECT_SCOPE_LENS, \
		HoldEffects.HoldEffect.HOLD_EFFECT_LEEK, \
		HoldEffects.HoldEffect.HOLD_EFFECT_LUCKY_PUNCH, \
		HoldEffects.HoldEffect.HOLD_EFFECT_CRITICAL_UP:
			return 1
		_:
			return 0


## Focus Sash / Focus Band: evita KO desde PS llenos.
static func try_endure_ko(defender: BattleBattler, damage: int) -> int:
	if defender == null or defender.pokemon == null or damage <= 0:
		return damage
	var hp: int = defender.get_current_hp()
	var max_hp: int = defender.get_max_hp()
	if damage < hp:
		return damage
	var he: HoldEffects.HoldEffect = get_hold_effect(defender)
	if he == HoldEffects.HoldEffect.HOLD_EFFECT_FOCUS_SASH:
		if hp >= max_hp:
			consume_held(defender)
			return maxi(0, hp - 1)
	elif he == HoldEffects.HoldEffect.HOLD_EFFECT_FOCUS_BAND:
		var chance: int = maxi(1, get_hold_param(defender))
		if chance <= 0:
			chance = 10
		if randi_range(1, 100) <= chance:
			return maxi(0, hp - 1)
	return damage


## Life Orb recoil tras golpear.
static func life_orb_recoil(attacker: BattleBattler, did_damage: bool) -> int:
	if not did_damage:
		return 0
	if get_hold_effect(attacker) != HoldEffects.HoldEffect.HOLD_EFFECT_LIFE_ORB:
		return 0
	return maxi(1, int(attacker.get_max_hp() / 10))


## Shell Bell: cura tras daño infligido.
static func shell_bell_heal(attacker: BattleBattler, damage_dealt: int) -> int:
	if damage_dealt <= 0:
		return 0
	if get_hold_effect(attacker) != HoldEffects.HoldEffect.HOLD_EFFECT_SHELL_BELL:
		return 0
	return maxi(1, int(damage_dealt / 8))


## Big Root: multiplica drain.
static func big_root_multiplier(battler: BattleBattler) -> float:
	if get_hold_effect(battler) == HoldEffects.HoldEffect.HOLD_EFFECT_BIG_ROOT:
		return 1.3
	return 1.0


## Rocky Helmet contact.
static func rocky_helmet_damage(defender: BattleBattler, attacker: BattleBattler) -> int:
	if get_hold_effect(defender) != HoldEffects.HoldEffect.HOLD_EFFECT_ROCKY_HELMET:
		return 0
	return maxi(1, int(attacker.get_max_hp() / 6))


## Fin de turno: Leftovers, Black Sludge, Sticky Barb, Flame/Toxic Orb.
static func end_of_turn_effect(battler: BattleBattler) -> Dictionary:
	## { "heal": int, "damage": int, "status": int (-1 none), "message": String, "consume": bool }
	var out: Dictionary = {
		"heal": 0,
		"damage": 0,
		"status": -1,
		"message": "",
		"consume": false,
	}
	if battler == null or battler.is_fainted() or battler.pokemon == null:
		return out
	var he: HoldEffects.HoldEffect = get_hold_effect(battler)
	var name: String = battler.get_display_name()
	match he:
		HoldEffects.HoldEffect.HOLD_EFFECT_LEFTOVERS, \
		HoldEffects.HoldEffect.HOLD_EFFECT_RESTORE_HP:
			@warning_ignore("integer_division")
			out["heal"] = maxi(1, int(battler.get_max_hp() / 16))
			out["message"] = "¡%s recuperó un poco de PS con su objeto!" % name
		HoldEffects.HoldEffect.HOLD_EFFECT_BLACK_SLUDGE:
			var t1: PokemonData.Type = battler.pokemon.get_type_1()
			var t2: PokemonData.Type = battler.pokemon.get_type_2()
			var poison: bool = t1 == PokemonData.Type.TYPE_POISON or t2 == PokemonData.Type.TYPE_POISON
			if poison:
				@warning_ignore("integer_division")
				out["heal"] = maxi(1, int(battler.get_max_hp() / 16))
				out["message"] = "¡%s recuperó PS con el Lodo Negro!" % name
			else:
				@warning_ignore("integer_division")
				out["damage"] = maxi(1, int(battler.get_max_hp() / 8))
				out["message"] = "¡El Lodo Negro restó PS a %s!" % name
		HoldEffects.HoldEffect.HOLD_EFFECT_STICKY_BARB:
			@warning_ignore("integer_division")
			out["damage"] = maxi(1, int(battler.get_max_hp() / 8))
			out["message"] = "¡%s es herido por el Toxiestrella!" % name
		HoldEffects.HoldEffect.HOLD_EFFECT_FLAME_ORB:
			if not battler.pokemon.has_status():
				out["status"] = int(PokemonInstance.Status.BURN)
				out["message"] = "¡%s se quemó por la Llama Orbe!" % name
		HoldEffects.HoldEffect.HOLD_EFFECT_TOXIC_ORB:
			if not battler.pokemon.has_status():
				out["status"] = int(PokemonInstance.Status.TOXIC)
				out["message"] = "¡%s fue gravemente envenenado por el Toxisfera!" % name
		HoldEffects.HoldEffect.HOLD_EFFECT_RESTORE_PCT_HP:
			# Sitrus-style: solo si HP <= 50%
			if battler.get_current_hp() * 2 <= battler.get_max_hp():
				var frac: int = maxi(1, get_hold_param(battler))
				if frac <= 0:
					frac = 4
				@warning_ignore("integer_division")
				out["heal"] = maxi(1, int(battler.get_max_hp() / frac))
				out["message"] = "¡%s recuperó PS con su baya!" % name
				out["consume"] = true
		_:
			pass
	return out


## Bayas de status / HP bajo tras recibir daño o al EOT bajo.
static func try_pinch_berry(battler: BattleBattler) -> Dictionary:
	var out: Dictionary = {"heal": 0, "message": "", "consume": false, "stat": -1, "stat_stages": 0, "cure_status": false, "cure_confusion": false}
	if battler == null or battler.is_fainted() or battler.pokemon == null:
		return out
	if battler.get_current_hp() * 4 > battler.get_max_hp():
		return out  # solo bajo 25% salvo sitrus (50% en RESTORE_PCT)
	var he: HoldEffects.HoldEffect = get_hold_effect(battler)
	var name: String = battler.get_display_name()
	match he:
		HoldEffects.HoldEffect.HOLD_EFFECT_ATTACK_UP:
			out["stat"] = int(PokemonInstance.Stat.ATTACK)
			out["stat_stages"] = 1
			out["message"] = "¡El Ataque de %s subió!" % name
			out["consume"] = true
		HoldEffects.HoldEffect.HOLD_EFFECT_DEFENSE_UP:
			out["stat"] = int(PokemonInstance.Stat.DEFENSE)
			out["stat_stages"] = 1
			out["message"] = "¡La Defensa de %s subió!" % name
			out["consume"] = true
		HoldEffects.HoldEffect.HOLD_EFFECT_SPEED_UP:
			out["stat"] = int(PokemonInstance.Stat.SPEED)
			out["stat_stages"] = 1
			out["message"] = "¡La Velocidad de %s subió!" % name
			out["consume"] = true
		HoldEffects.HoldEffect.HOLD_EFFECT_SP_ATTACK_UP:
			out["stat"] = int(PokemonInstance.Stat.SP_ATTACK)
			out["stat_stages"] = 1
			out["message"] = "¡El At. Esp. de %s subió!" % name
			out["consume"] = true
		HoldEffects.HoldEffect.HOLD_EFFECT_SP_DEFENSE_UP:
			out["stat"] = int(PokemonInstance.Stat.SP_DEFENSE)
			out["stat_stages"] = 1
			out["message"] = "¡La Def. Esp. de %s subió!" % name
			out["consume"] = true
		HoldEffects.HoldEffect.HOLD_EFFECT_CURE_STATUS, \
		HoldEffects.HoldEffect.HOLD_EFFECT_CURE_PAR, \
		HoldEffects.HoldEffect.HOLD_EFFECT_CURE_SLP, \
		HoldEffects.HoldEffect.HOLD_EFFECT_CURE_PSN, \
		HoldEffects.HoldEffect.HOLD_EFFECT_CURE_BRN, \
		HoldEffects.HoldEffect.HOLD_EFFECT_CURE_FRZ:
			if battler.pokemon.has_status():
				out["cure_status"] = true
				out["message"] = "¡%s se curó con su baya!" % name
				out["consume"] = true
		HoldEffects.HoldEffect.HOLD_EFFECT_CURE_CONFUSION:
			if battler.is_confused():
				out["cure_confusion"] = true
				out["message"] = "¡%s se libró de la confusión!" % name
				out["consume"] = true
		_:
			pass
	return out


static func is_choice_item(battler: BattleBattler) -> bool:
	var he: HoldEffects.HoldEffect = get_hold_effect(battler)
	return he == HoldEffects.HoldEffect.HOLD_EFFECT_CHOICE_BAND \
		or he == HoldEffects.HoldEffect.HOLD_EFFECT_CHOICE_SPECS \
		or he == HoldEffects.HoldEffect.HOLD_EFFECT_CHOICE_SCARF
