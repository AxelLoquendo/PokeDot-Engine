extends RefCounted
class_name FieldItemResolver

## Objetos de campo que no requieren party: Repels, flautas, Honey.
## Escape Rope queda fuera hasta sistema de triggers.


class Result:
	var success: bool = false
	var consume_item: bool = false
	var message: String = ""
	## Si > 0, el overworld debería forzar un intento de encuentro.
	var force_encounter: bool = false


static func is_field_tool(item: ItemData) -> bool:
	if item == null:
		return false
	match item.item_id:
		Items.ItemId.ITEM_REPEL, \
		Items.ItemId.ITEM_SUPER_REPEL, \
		Items.ItemId.ITEM_MAX_REPEL, \
		Items.ItemId.ITEM_BLACK_FLUTE, \
		Items.ItemId.ITEM_WHITE_FLUTE, \
		Items.ItemId.ITEM_HONEY, \
		Items.ItemId.ITEM_MAX_HONEY:
			return true
		_:
			return false


static func repel_steps_for(item_id: Items.ItemId) -> int:
	match item_id:
		Items.ItemId.ITEM_REPEL:
			return 100
		Items.ItemId.ITEM_SUPER_REPEL:
			return 200
		Items.ItemId.ITEM_MAX_REPEL:
			return 250
		_:
			return 0


static func use_on_player(item: ItemData, player_data: CharacterPlayer) -> Result:
	var result: Result = Result.new()
	if item == null or player_data == null:
		result.message = "No se puede usar ese objeto ahora."
		return result

	match item.item_id:
		Items.ItemId.ITEM_REPEL, \
		Items.ItemId.ITEM_SUPER_REPEL, \
		Items.ItemId.ITEM_MAX_REPEL:
			var steps: int = repel_steps_for(item.item_id)
			if player_data.repel_steps > 0:
				result.message = "Ya hay un repelente activo (%d pasos)." % player_data.repel_steps
				# Permitir reiniciar con el nuevo valor
			player_data.repel_steps = steps
			result.success = true
			result.consume_item = not item.not_consumed
			result.message = "El repelente evitará Pokémon salvajes durante %d pasos." % steps
			return result

		Items.ItemId.ITEM_BLACK_FLUTE:
			player_data.encounter_rate_modifier = 0.5
			result.success = true
			result.consume_item = not item.not_consumed
			result.message = "La Flauta Negra reduce los encuentros salvajes."
			return result

		Items.ItemId.ITEM_WHITE_FLUTE:
			player_data.encounter_rate_modifier = 1.5
			result.success = true
			result.consume_item = not item.not_consumed
			result.message = "La Flauta Blanca aumenta los encuentros salvajes."
			return result

		Items.ItemId.ITEM_HONEY, \
		Items.ItemId.ITEM_MAX_HONEY:
			result.success = true
			result.consume_item = not item.not_consumed
			result.force_encounter = true
			result.message = "¡El olor del miel atrajo un Pokémon salvaje!"
			return result

		_:
			result.message = "Ese objeto no se puede usar aquí todavía."
			return result
