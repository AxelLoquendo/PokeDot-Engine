extends Resource
class_name AbilityBattleEffect

enum weatherAbilityID {
	WEATHER_NONE,
	WEATHER_RAIN,
	WEATHER_SNOW,
	WEATHER_SANDSTORM,
	WEATHER_DROUGHT,
	WEATHER_
}

enum terrainID{
	TERRAIN_NONE,
	TERRAIN_ELECTRIC,
	TERRAIN_GRASSY,
	TERRAIN_MISTY,
	TERRAIN_PSYCHIC
}

const BG_TERRAIN_SPRITES: Dictionary = {
	terrainID.TERRAIN_NONE: "",
	terrainID.TERRAIN_ELECTRIC: "res://graphics/battle_ground/BG_Electric_Surge.png",
	terrainID.TERRAIN_GRASSY: "res://graphics/battle_ground/BG_Grassy_Surge.png",
	terrainID.TERRAIN_MISTY: "res://graphics/battle_ground/BG_Misty_Surge.png",
	terrainID.TERRAIN_PSYCHIC: "res://graphics/battle_ground/BG_Psychic_Surge.png"
}
