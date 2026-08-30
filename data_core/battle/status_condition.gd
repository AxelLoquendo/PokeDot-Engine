extends RefCounted
class_name StatusConditions

## Resultado de comprobar si un Pokémon puede actuar este turno.
class ActionCheck:
	var can_act: bool = true
	var message: String = ""
	var is_confusion_hit: bool = false


static func check_can_act(battler: BattleBattler) -> ActionCheck:
	var check: ActionCheck = ActionCheck.new()
	var mon: PokemonInstance = battler.pokemon
	if mon == null:
		return check

	if battler.flinched:
		check.can_act = false
		check.message = "¡%s se detuvo por el retroceso!" % battler.get_display_name()
		return check

	match mon.status:
		PokemonInstance.Status.SLEEP:
			mon.status_counter -= 1
			if mon.status_counter <= 0:
				mon.cure_status()
				check.message = "¡%s se despertó!" % battler.get_display_name()
			else:
				check.can_act = false
				check.message = "%s está dormido." % battler.get_display_name()
		PokemonInstance.Status.FREEZE:
			if randf() < 0.2:
				mon.cure_status()
				check.message = "¡%s se descongeló!" % battler.get_display_name()
			else:
				check.can_act = false
				check.message = "%s está congelado." % battler.get_display_name()
		PokemonInstance.Status.PARALYSIS:
			if randf() < 0.25:
				check.can_act = false
				check.message = "¡%s está paralizado! No puede moverse." % battler.get_display_name()

	if check.can_act and battler.is_confused():
		battler.confusion_turns -= 1
		if randf() < 1.0 / 3.0:
			check.can_act = false
			check.is_confusion_hit = true
			check.message = "%s está confundido... ¡y se hizo daño a sí mismo!" % battler.get_display_name()

	return check


## Golpe de confusión: físico fijo, potencia 40, contra las propias stats.
static func self_hit_confusion(battler: BattleBattler) -> int:
	var atk: int = battler.get_effective_stat(PokemonInstance.Stat.ATTACK)
	var def: int = battler.get_effective_stat(PokemonInstance.Stat.DEFENSE)
	var level: int = battler.pokemon.level
	var base: float = ((2.0 * float(level) / 5.0 + 2.0) * 40.0 * float(atk) / maxf(float(def), 1.0)) / 50.0 + 2.0
	var random: float = randf_range(0.85, 1.0)
	return maxi(int(floor(base * random)), 1)


static func end_of_turn_damage(battler: BattleBattler) -> Dictionary:
	var mon: PokemonInstance = battler.pokemon
	var result: Dictionary = {"damage": 0, "message": ""}
	if mon == null or mon.is_fainted():
		return result

	match mon.status:
		PokemonInstance.Status.POISON:
			@warning_ignore("integer_division")
			result.damage = maxi(1, mon.max_hp / 8)
			result.message = "%s sufre por el veneno." % battler.get_display_name()
		PokemonInstance.Status.TOXIC:
			mon.status_counter += 1
			@warning_ignore("integer_division")
			result.damage = maxi(1, (mon.max_hp * mon.status_counter) / 16)
			result.message = "%s sufre mucho por el veneno." % battler.get_display_name()
		PokemonInstance.Status.BURN:
			@warning_ignore("integer_division")
			result.damage = maxi(1, mon.max_hp / 16)
			result.message = "%s sufre por la quemadura." % battler.get_display_name()

	return result


static func status_name(status: PokemonInstance.Status) -> String:
	match status:
		PokemonInstance.Status.POISON: return "envenenado"
		PokemonInstance.Status.TOXIC: return "gravemente envenenado"
		PokemonInstance.Status.BURN: return "quemado"
		PokemonInstance.Status.PARALYSIS: return "paralizado"
		PokemonInstance.Status.SLEEP: return "dormido"
		PokemonInstance.Status.FREEZE: return "congelado"
		_: return ""
