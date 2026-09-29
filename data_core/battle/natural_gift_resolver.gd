extends RefCounted
class_name NaturalGiftResolver

## Don Natural: tipo y potencia según la baya equipada.
## Sin tabla por ItemId completa: usa hold_effect_param como tipo si > 0,
## y fling_power (mín. 60) como potencia base (valores oficiales ~60–80).


static func can_use(attacker: BattleBattler) -> bool:
	if attacker == null or attacker.pokemon == null:
		return false
	if attacker.pokemon.held_item == Items.ItemId.ITEM_NONE:
		return false
	var data: ItemData = ItemDatabase.get_item(attacker.pokemon.held_item)
	if data == null:
		return false
	if data.pocket == ItemConstants.Pocket.POCKET_BERRIES:
		return true
	return false


static func resolve_type(attacker: BattleBattler) -> PokemonData.Type:
	var data: ItemData = HoldItemRuntime.get_item_data(attacker)
	if data == null:
		return PokemonData.Type.TYPE_NORMAL
	# Muchas bayas guardan el tipo en hold_effect_param (resist / natural gift data)
	var p: int = data.hold_effect_param
	# Tipos válidos 0..17 (Normal..Fairy) según PokemonData.Type
	if p >= 0 and p <= 17:
		return p as PokemonData.Type
	return PokemonData.Type.TYPE_NORMAL


static func resolve_power(attacker: BattleBattler) -> int:
	var data: ItemData = HoldItemRuntime.get_item_data(attacker)
	if data == null:
		return 60
	# Fling power de bayas suele correlacionar; Don Natural oficial 60–80
	var p: int = data.fling_power
	if p <= 0:
		return 60
	if p < 60:
		return 60
	if p > 80:
		return 80
	return p


static func consume_berry(attacker: BattleBattler) -> void:
	if attacker == null:
		return
	HoldItemRuntime.consume_held(attacker)
	if attacker.has_meta("natural_gift_active"):
		attacker.remove_meta("natural_gift_active")
