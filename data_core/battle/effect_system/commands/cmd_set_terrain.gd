## set_terrain ELECTRIC 5
class_name CmdSetTerrain
extends EffectCommand


func _init(p_args: PackedStringArray = []) -> void:
	super._init("set_terrain", p_args)


func execute(ctx: EffectContext) -> bool:
	if ctx.battle == null:
		return true
	var key: String = arg_string(0).to_lower()
	var turns: int = arg_int(1, 5)
	var terrain_id: int = BattleManager.TerrainId.TERRAIN_NONE
	match key:
		"electric":
			terrain_id = BattleManager.TerrainId.TERRAIN_ELECTRIC
		"grassy", "grass":
			terrain_id = BattleManager.TerrainId.TERRAIN_GRASSY
		"misty":
			terrain_id = BattleManager.TerrainId.TERRAIN_MISTY
		"psychic":
			terrain_id = BattleManager.TerrainId.TERRAIN_PSYCHIC
		_:
			terrain_id = BattleManager.TerrainId.TERRAIN_NONE
	ctx.battle.set_terrain(terrain_id, turns)
	return true
