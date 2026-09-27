## Sistema de habilidades basado en scripts.
## Si existe el .txt de la habilidad, lo ejecuta y el código viejo puede omitirla.
class_name AbilitySystem
extends RefCounted

static var _cache: Dictionary = {}
const SCRIPTS_PATH: String = "res://data_core/battle/effect_system/scripts/abilities/"


static func has_script(id: AbilityId.Id) -> bool:
	if id == AbilityId.Id.NONE:
		return false
	var script: EffectScript = _get_script(id)
	return script != null and not script.blocks.is_empty()


static func on_event(event_name: String, ctx: EffectContext) -> void:
	if ctx == null or ctx.user == null:
		return

	var ability_id: AbilityId.Id = _get_ability_id(ctx.user)
	if ability_id == AbilityId.Id.NONE:
		return

	var script: EffectScript = _get_script(ability_id)
	if script == null or not script.has_block(event_name):
		return

	ctx.source_type = EffectContext.SourceType.ABILITY
	ctx.source_name = str(ability_id)
	await EffectRunner.run_block(script.get_block(event_name), ctx)


static func _get_script(id: AbilityId.Id) -> EffectScript:
	if _cache.has(id):
		return _cache[id] as EffectScript

	var file_name: String = _id_to_filename(id)
	if file_name.is_empty():
		_cache[id] = null
		return null

	var path: String = SCRIPTS_PATH + file_name
	if not FileAccess.file_exists(path):
		_cache[id] = null
		return null

	var script: EffectScript = EffectParser.parse_file(path)
	_cache[id] = script
	return script


static func _get_ability_id(battler: BattleBattler) -> AbilityId.Id:
	if battler == null or battler.pokemon == null:
		return AbilityId.Id.NONE
	if not battler.ability_active:
		return AbilityId.Id.NONE
	return battler.pokemon.ability_id


static func _id_to_filename(id: AbilityId.Id) -> String:
	var keys: Array = AbilityId.Id.keys()
	if id < 0 or id >= keys.size():
		return ""
	var key: String = str(keys[id])
	if key.is_empty() or key == "NONE" or key == "COUNT":
		return ""
	return key.to_lower() + ".txt"


static func clear_cache() -> void:
	_cache.clear()
