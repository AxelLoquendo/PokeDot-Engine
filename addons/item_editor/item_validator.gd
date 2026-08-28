@tool
extends RefCounted

## Validation is intentionally based on ItemData._validate(), then adds editor
## checks that need the repository (notably duplicate IDs).
class_name ItemEditorValidator

func validate(item: ItemData, repository: ItemEditorRepository = null, path: String = "") -> Array[String]:
	var errors: Array[String] = []
	if item == null:
		return ["El ItemData es null."]
	errors.append_array(item._validate())
	if not int(item.hold_effect) in HoldEffects.HoldEffect.values():
		errors.append("hold_effect no es válido.")
	if not int(item.battle_usage) in Items.BattleUsage.values():
		errors.append("battle_usage no es válido.")
	# EffectItem no define NONE; 0 representa un objeto sin efecto real.
	var raw_effect: Variant = item.effect
	var effect_value: int = 0 if raw_effect is Dictionary else int(raw_effect)
	if effect_value != 0 and not effect_value in Items.EffectItem.values():
		errors.append("effect no es válido.")
	if item.secondary_id < 0:
		errors.append("secondary_id no puede ser negativo.")
	if item.hold_effect_param < 0:
		errors.append("hold_effect_param no puede ser negativo.")
	if repository != null and repository.id_is_used(int(item.item_id), path):
		errors.append("item_id %d ya está usado por otro recurso." % int(item.item_id))
	return errors
