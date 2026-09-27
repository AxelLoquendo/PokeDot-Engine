## Sistema de efectos de movimientos basado en scripts .txt (misma lógica que habilidades).
## Si existe scripts/moves/<effect_snake>.txt, se ejecuta ese bloque en lugar del match de BattleManager.
class_name MoveSystem
extends RefCounted

static var _cache: Dictionary = {}  # StringName effect key -> EffectScript
const SCRIPTS_PATH: String = "res://data_core/battle/effect_system/scripts/moves/"


static func _effect_key(effect: int) -> String:
	# MoveStruct.MoveEffect → "attack_up", "light_screen", ...
	var names: PackedStringArray = MoveStruct.MoveEffect.keys()
	if effect < 0 or effect >= names.size():
		return ""
	var raw: String = str(names[effect])
	if raw.begins_with("EFFECT_"):
		raw = raw.substr(7)
	return raw.to_lower()


static func has_script(effect: int) -> bool:
	var key: String = _effect_key(effect)
	if key.is_empty() or key == "none" or key == "hit" or key == "placeholder":
		return false
	var script: EffectScript = _get_script(key)
	return script != null and not script.blocks.is_empty()


static func _get_script(key: String) -> EffectScript:
	if key.is_empty():
		return null
	if _cache.has(key):
		return _cache[key] as EffectScript
	var path: String = SCRIPTS_PATH + key + ".txt"
	var script: EffectScript = null
	if FileAccess.file_exists(path):
		script = EffectParser.parse_file(path)
	_cache[key] = script
	return script


static func clear_cache() -> void:
	_cache.clear()


## Efecto principal de un movimiento de estado (o post-golpe de un daño con efecto).
static func run_on_use(actor: BattleBattler, target: BattleBattler, move: MoveData, battle: BattleManager) -> bool:
	if move == null or battle == null:
		return false
	var key: String = _effect_key(int(move.effect))
	var script: EffectScript = _get_script(key)
	if script == null or not script.has_block("on_use"):
		return false
	var ctx: EffectContext = EffectContext.new(actor, target, move, battle)
	ctx.source_type = EffectContext.SourceType.MOVE
	ctx.source_name = key
	await EffectRunner.run_block(script.get_block("on_use"), ctx)
	return true


## Tras infligir daño (Rapid Spin, Knock Off, etc.).
static func run_on_hit(
	actor: BattleBattler,
	target: BattleBattler,
	move: MoveData,
	battle: BattleManager,
	damage_dealt: int = 0
) -> bool:
	if move == null or battle == null:
		return false
	var key: String = _effect_key(int(move.effect))
	var script: EffectScript = _get_script(key)
	if script == null or not script.has_block("on_hit"):
		return false
	var ctx: EffectContext = EffectContext.new(actor, target, move, battle)
	ctx.source_type = EffectContext.SourceType.MOVE
	ctx.source_name = key
	ctx.set_meta("damage_dealt", damage_dealt)
	await EffectRunner.run_block(script.get_block("on_hit"), ctx)
	return true


## Efecto secundario (chance ya resuelta por BattleManager).
static func run_on_secondary(
	actor: BattleBattler,
	target: BattleBattler,
	move: MoveData,
	battle: BattleManager
) -> bool:
	if move == null or battle == null:
		return false
	# Prioridad: script del efecto primario si define on_secondary;
	# si no, script genérico del secondary_effect.
	var key: String = _effect_key(int(move.effect))
	var script: EffectScript = _get_script(key)
	if script != null and script.has_block("on_secondary"):
		var ctx: EffectContext = EffectContext.new(actor, target, move, battle)
		ctx.source_type = EffectContext.SourceType.MOVE
		ctx.source_name = key
		await EffectRunner.run_block(script.get_block("on_secondary"), ctx)
		return true
	return false


## Consulta síncrona (potencia, flags de fallo, etc.).
static func query(event_name: String, ctx: EffectContext) -> void:
	if ctx == null or ctx.move == null:
		return
	var key: String = _effect_key(int(ctx.move.effect))
	var script: EffectScript = _get_script(key)
	if script == null or not script.has_block(event_name):
		return
	ctx.source_type = EffectContext.SourceType.MOVE
	ctx.source_name = key
	EffectRunner.run_block_sync(script.get_block(event_name), ctx)


static func query_float(event_name: String, ctx: EffectContext, default: float = 1.0) -> float:
	if ctx == null:
		return default
	ctx.multiplier = default
	query(event_name, ctx)
	return ctx.multiplier


static func query_bool(event_name: String, ctx: EffectContext) -> bool:
	if ctx == null:
		return false
	ctx.blocked = false
	query(event_name, ctx)
	return ctx.blocked
