extends RefCounted
class_name ItemUseResolver

## Lógica compartida para usar objetos sobre un Pokémon. No depende de una UI,
## así la mochila, los scripts y el combate pueden reutilizar las mismas reglas.

class Result:
	var success: bool = false
	var consume_item: bool = false
	var message: String = ""
	var evolved: EvolutionResult = null


static func use_on_pokemon(item: ItemData, pokemon: PokemonInstance, context: EvolutionContext = null, move_slot_index: int = -1) -> Result:
	var result: Result = Result.new()
	if item == null or pokemon == null:
		result.message = "No se puede usar ese objeto ahora."
		return result

	match item.effect:
		Items.EffectItem.EFFECT_ITEM_RESTORE_HP:
			return _restore_hp(item, pokemon)
		Items.EffectItem.EFFECT_ITEM_CURE_STATUS:
			return _cure_status(item, pokemon)
		Items.EffectItem.EFFECT_ITEM_HEAL_AND_CURE_STATUS:
			return _heal_and_cure(item, pokemon)
		Items.EffectItem.EFFECT_ITEM_REVIVE:
			return _revive(item, pokemon)
		Items.EffectItem.EFFECT_ITEM_RESTORE_PP:
			return _restore_pp(item, pokemon, move_slot_index)
		Items.EffectItem.EFFECT_ITEM_INCREASE_STAT:
			return _increase_ev(item, pokemon)
		Items.EffectItem.EFFECT_ITEM_USE_POKE_FLUTE:
			return _wake_up(item, pokemon)

	# Las piedras y objetos de evolución se identifican por la regla de la
	# especie, no por una lista rígida de IDs. Esto permite añadir .tres nuevos.
	var evo_context: EvolutionContext = context if context != null else EvolutionContext.new(pokemon)
	evo_context.pokemon = pokemon
	evo_context.used_item_id = item.item_id
	evo_context.mode = PokemonData.EvolutionMode.EVO_MODE_ITEM_USE
	var evolution: EvolutionResult = EvolutionSystem.try_evolve(pokemon, PokemonData.EvolutionMode.EVO_MODE_ITEM_USE, evo_context)
	if evolution != null:
		result.success = true
		result.consume_item = not item.not_consumed
		result.evolved = evolution
		result.message = "%s reacciona al objeto." % pokemon.get_display_name()
		return result

	result.message = "No surtirá efecto en %s." % pokemon.get_display_name()
	return result


static func _restore_hp(item: ItemData, pokemon: PokemonInstance) -> Result:
	var result: Result = Result.new()
	if pokemon.is_fainted() or pokemon.current_hp >= pokemon.max_hp:
		result.message = "No surtirá efecto."
		return result
	var amount: int = item.effect_amount
	if amount >= ItemEffects.ITEM6_HEAL_HP_FULL:
		amount = pokemon.max_hp
	elif amount == ItemEffects.ITEM6_HEAL_HP_HALF:
		amount = maxi(1, pokemon.max_hp / 2)
	elif amount == ItemEffects.ITEM6_HEAL_HP_QUARTER:
		amount = maxi(1, pokemon.max_hp / 4)
	if amount <= 0:
		result.message = "El objeto no tiene una cantidad de curación válida."
		return result
	pokemon.apply_heal(amount)
	result.success = true
	result.consume_item = not item.not_consumed
	result.message = "%s recuperó PS." % pokemon.get_display_name()
	return result


static func _cure_status(item: ItemData, pokemon: PokemonInstance) -> Result:
	var result: Result = Result.new()
	if not pokemon.has_status():
		result.message = "No surtirá efecto."
		return result
	pokemon.cure_status()
	result.success = true
	result.consume_item = not item.not_consumed
	result.message = "%s se curó de su estado." % pokemon.get_display_name()
	return result


static func _heal_and_cure(item: ItemData, pokemon: PokemonInstance) -> Result:
	var result: Result = _restore_hp(item, pokemon)
	var cured: bool = pokemon.has_status()
	if cured:
		pokemon.cure_status()
	if result.success or cured:
		result.success = true
		result.consume_item = not item.not_consumed
		result.message = "%s quedó totalmente recuperado." % pokemon.get_display_name()
	return result


static func _revive(item: ItemData, pokemon: PokemonInstance) -> Result:
	var result: Result = Result.new()
	if not pokemon.is_fainted():
		result.message = "No surtirá efecto."
		return result
	var amount: int = pokemon.max_hp if item.effect_amount >= ItemEffects.ITEM6_HEAL_HP_FULL else maxi(1, pokemon.max_hp / 2)
	pokemon.current_hp = amount
	pokemon.cure_status()
	result.success = true
	result.consume_item = not item.not_consumed
	result.message = "%s volvió a combatir." % pokemon.get_display_name()
	return result


static func _restore_pp(item: ItemData, pokemon: PokemonInstance, move_slot_index: int) -> Result:
	var result: Result = Result.new()
	if move_slot_index < 0 or move_slot_index >= pokemon.moves.size():
		result.message = "Debes elegir un movimiento."
		return result
	var slot: PokemonMoveSlot = pokemon.moves[move_slot_index]
	var move: MoveData = MoveDatabase.get_move(slot.move_id) if slot != null else null
	if slot == null or move == null or slot.current_pp >= move.pp:
		result.message = "No surtirá efecto."
		return result
	var amount: int = item.effect_amount
	if amount >= ItemEffects.ITEM6_HEAL_PP_FULL:
		amount = move.pp
	slot.current_pp = mini(move.pp, slot.current_pp + maxi(1, amount))
	result.success = true
	result.consume_item = not item.not_consumed
	result.message = "Se restauraron los PP de %s." % move.move_name
	return result


static func _increase_ev(item: ItemData, pokemon: PokemonInstance) -> Result:
	var result: Result = Result.new()
	var stat_index: int = int(item.effect_stat)
	var amount: int = item.effect_amount
	if stat_index < 0 or stat_index >= pokemon.evs.size() or amount == 0:
		result.message = "No surtirá efecto."
		return result
	var old_value: int = pokemon.evs[stat_index]
	pokemon.evs[stat_index] = clampi(old_value + amount, 0, 252)
	if pokemon.evs[stat_index] == old_value:
		result.message = "No surtirá efecto."
		return result
	pokemon.recalculate_stats()
	result.success = true
	result.consume_item = not item.not_consumed
	result.message = "%s mejoró su entrenamiento." % pokemon.get_display_name()
	return result


static func _wake_up(item: ItemData, pokemon: PokemonInstance) -> Result:
	var result: Result = Result.new()
	if pokemon.status != PokemonInstance.Status.SLEEP:
		result.message = "No surtirá efecto."
		return result
	pokemon.cure_status()
	result.success = true
	result.consume_item = not item.not_consumed
	result.message = "%s despertó." % pokemon.get_display_name()
	return result
