extends Resource
class_name Bag

## Inventario persistente. La cantidad se guarda por ID de ítem.
@export var quantities: Dictionary = {}


func get_quantity(item_id: Items.ItemId) -> int:
	return int(quantities.get(int(item_id), 0))


func add_item(item_id: Items.ItemId, amount: int = 1) -> bool:
	if item_id == Items.ItemId.ITEM_NONE or amount <= 0:
		return false
	quantities[int(item_id)] = get_quantity(item_id) + amount
	return true


func remove_item(item_id: Items.ItemId, amount: int = 1) -> bool:
	if amount <= 0 or get_quantity(item_id) < amount:
		return false
	var remaining: int = get_quantity(item_id) - amount
	if remaining == 0:
		quantities.erase(int(item_id))
	else:
		quantities[int(item_id)] = remaining
	return true


func has_item(item_id: Items.ItemId, amount: int = 1) -> bool:
	return get_quantity(item_id) >= amount
