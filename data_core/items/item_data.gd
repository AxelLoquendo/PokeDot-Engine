extends Resource

class_name ItemData

@export var item_id: Items.ItemId
@export var secondary_id: int = 0

@export var item_name: String
@export var plural_name: String
@export_multiline var item_description: String

@export var price: int = 0

@export var pocket: ItemConstants.Pocket = ItemConstants.Pocket.POCKET_ITEMS
@export var item_type: Items.ItemType = Items.ItemType.ITEM_USE_FIELD

@export var hold_effect: HoldEffects.HoldEffect = HoldEffects.HoldEffect.HOLD_EFFECT_NONE
@export var hold_effect_param: int = 0

@export var battle_usage: Items.BattleUsage = Items.BattleUsage.NONE
@export var fling_power: int = 0

@export var importance: bool = false
@export var not_consumed: bool = false

@export var icon: Texture2D

# efecto real del objeto
@export var effect: Items.ItemEffect = Items.ItemEffect.NONE


func _validate() -> Array[String]:
	var errors: Array[String] = []
	if item_id == Items.ItemId.ITEM_NONE:
		errors.append("item_id no puede ser ITEM_NONE.")
	if item_name.strip_edges().is_empty():
		errors.append("item_name está vacío.")
	if plural_name.strip_edges().is_empty():
		errors.append("plural_name está vacío.")
	if item_description.strip_edges().is_empty():
		errors.append("item_description está vacío.")
	if price < 0:
		errors.append("price no puede ser negativo.")
	if fling_power < 0:
		errors.append("fling_power no puede ser negativo.")
	if not int(item_id) in Items.ItemId.values():
		errors.append("item_id no pertenece al enum Items.ItemId.")
	if not int(item_type) in Items.ItemType.values():
		errors.append("item_type no es válido.")
	if not int(pocket) in ItemConstants.Pocket.values():
		errors.append("pocket no es válido.")
	return errors


func is_valid() -> bool:
	return _validate().is_empty()
