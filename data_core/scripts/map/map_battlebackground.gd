extends Node2D
class_name BattleBackground

enum Background {
	BG_LONG_GRASS,
	BG_FOREST,
	BG_SAND,
	BG_UNDERWATER,
	BG_WATER,
	BG_POND,
	BG_MOUNTAIN,
	BG_MOUNTAIN_2,
	BG_CAVE,
	BG_DESERT,
	BG_BUILDING,
	BG_PLAIN,
#    BG_FRONTIER,
	BG_GYM,
	BG_LEADER,
#    BG_MAGMA,
#    BG_AQUA,
#    BG_SIDNEY,
#    BG_PHOEBE,
#    BG_GLACIA,
#    BG_DRAKE,
	BG_CHAMPION,
#    BG_GROUDON,
#    BG_KYOGRE,
#    BG_RAYQUAZA,
#    BG_SOARING,
#    BG_SKY_PILLAR,
#    BG_BURIAL_GROUND,
	BG_PUDDLE,
#    BG_MARSH,
#    BG_SWAMP,
	BG_SNOW,
	BG_ICE,
	BG_VOLCANO,
	BG_DISTORTION_WORLD,
	BG_SPACE,
	BG_ULTRA_SPACE,
}

const BG_SPRITES: Dictionary = {
	Background.BG_LONG_GRASS:"res://graphics/battle_ground/BG_LongGrass.png",
	Background.BG_FOREST:"res://graphics/battle_ground/BG_Forest.png",
	Background.BG_SAND:"res://graphics/battle_ground/BG_Sand.png",
	Background.BG_UNDERWATER:"res://graphics/battle_ground/BG_Underwater.png",
	Background.BG_WATER:"res://graphics/battle_ground/BG_Water.png",
	Background.BG_POND:"res://graphics/battle_ground/BG_Pond.png",
	Background.BG_MOUNTAIN:"res://graphics/battle_ground/BG_Mountain.png",
	Background.BG_MOUNTAIN_2:"res://graphics/battle_ground/BG_Mountain_2.png",
	Background.BG_CAVE:"res://graphics/battle_ground/BG_Cave.png",
	Background.BG_GYM:"res://graphics/battle_ground/BG_Gym.png",
	Background.BG_SNOW:"res://graphics/battle_ground/BG_Snow.png",
	Background.BG_DESERT:"res://graphics/battle_ground/BG_Desert.png",
}

static func get_texture(background: Background) -> Texture2D:
	var path: String = BG_SPRITES.get(background, "")
	if path.is_empty() or not ResourceLoader.exists(path):
		path = BG_SPRITES.get(Background.BG_LONG_GRASS, "") # fallback
	if path.is_empty() or not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D
