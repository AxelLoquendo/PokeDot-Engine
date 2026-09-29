## Sistema de efectos de objetos equipados (scripts .txt).
## Ruta: res://data_core/battle/effect_system/scripts/items/<hold_effect>.txt
class_name ItemSystem
extends RefCounted

static var _cache: Dictionary = {}
const SCRIPTS_PATH: String = "res://data_core/battle/effect_system/scripts/items/"


static func _effect_key(he: int) -> String:
	var names: PackedStringArray = HoldEffects.HoldEffect.keys()
	if he < 0 or he >= names.size():
		return ""
	var raw: String = str(names[he])
	if raw.begins_with("HOLD_EFFECT_"):
		raw = raw.substr(12)
	return raw.to_lower()


static func _get_script(key: String) -> EffectScript:
	if key.is_empty():
		return null
	if _cache.has(key):
		return _cache[key] as EffectScript
	var path: String = SCRIPTS_PATH + key + ".txt"
	if not FileAccess.file_exists(path):
		_cache[key] = null
		return null
	var script: EffectScript = EffectParser.parse_file(path)
	_cache[key] = script
	return script


static func has_script(he: int) -> bool:
	var key: String = _effect_key(he)
	if key.is_empty() or key == "none" or key == "count":
		return false
	var script: EffectScript = _get_script(key)
	return script != null and not script.blocks.is_empty()


static func has_block(he: int, event_name: String) -> bool:
	var key: String = _effect_key(he)
	var script: EffectScript = _get_script(key)
	return script != null and script.has_block(event_name)


static func _ctx_for(battler: BattleBattler, battle: BattleManager, move: MoveData = null) -> EffectContext:
	var ctx: EffectContext = EffectContext.new(battler, null, move, battle)
	ctx.source_type = EffectContext.SourceType.ITEM
	var he: int = int(HoldItemRuntime.get_hold_effect(battler))
	ctx.source_name = _effect_key(he)
	ctx.query_int = HoldItemRuntime.get_hold_param(battler)
	return ctx


static func query(event_name: String, ctx: EffectContext) -> void:
	if ctx == null or ctx.user == null:
		return
	var he: int = int(HoldItemRuntime.get_hold_effect(ctx.user))
	var key: String = _effect_key(he)
	var script: EffectScript = _get_script(key)
	if script == null or not script.has_block(event_name):
		return
	ctx.source_type = EffectContext.SourceType.ITEM
	ctx.source_name = key
	EffectRunner.run_block_sync(script.get_block(event_name), ctx)


static func query_float(event_name: String, ctx: EffectContext, default_value: float = 1.0) -> float:
	if ctx == null:
		return default_value
	ctx.multiplier = default_value
	query(event_name, ctx)
	return ctx.multiplier


static func query_bool(event_name: String, ctx: EffectContext) -> bool:
	if ctx == null:
		return false
	ctx.blocked = false
	ctx.query_bool = false
	query(event_name, ctx)
	return ctx.query_bool or ctx.blocked


static func on_event(event_name: String, ctx: EffectContext) -> void:
	if ctx == null or ctx.user == null:
		return
	var he: int = int(HoldItemRuntime.get_hold_effect(ctx.user))
	var key: String = _effect_key(he)
	var script: EffectScript = _get_script(key)
	if script == null or not script.has_block(event_name):
		return
	ctx.source_type = EffectContext.SourceType.ITEM
	ctx.source_name = key
	await EffectRunner.run_block(script.get_block(event_name), ctx)


## Residual de fin de turno (Leftovers, Orbs, Sitrus…).
static func on_end_turn(battler: BattleBattler, battle: BattleManager) -> bool:
	if battler == null or battle == null:
		return false
	var he: int = int(HoldItemRuntime.get_hold_effect(battler))
	if not has_block(he, "on_end_turn"):
		return false
	var ctx: EffectContext = _ctx_for(battler, battle)
	await on_event("on_end_turn", ctx)
	return true


## Bayas de apuro (≤25% PS).
static func on_pinch(battler: BattleBattler, battle: BattleManager) -> bool:
	if battler == null or battle == null:
		return false
	var he: int = int(HoldItemRuntime.get_hold_effect(battler))
	if not has_block(he, "on_pinch"):
		return false
	var ctx: EffectContext = _ctx_for(battler, battle)
	await on_event("on_pinch", ctx)
	return true


static func clear_cache() -> void:
	_cache.clear()
