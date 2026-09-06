extends Node
class_name MapSection

enum SectionId {
	MAPSEC_NONE,
	# Valtherion
	MAPSEC_PRADO_NATAL,
	MAPSEC_PUEBLO_ALBA,
	# Kanto
	MAPSEC_PALLET_TOWN,
}

enum RegionId {
	REGION_NONE,
	REGION_VALTHERION,
	REGION_KANTO,
	REGION_JOHTO,
	REGION_HOENN,
	REGION_SINNOH,
	REGION_UNOVA,
	REGION_KALOS,
	REGION_ALOLA,
	REGION_GALAR,
	REGION_PALDEA,
}

const SECTION_TO_SCENE: Dictionary = {
	SectionId.MAPSEC_NONE: "",
	SectionId.MAPSEC_PRADO_NATAL: "res://game/data_core_eb/map_eb/prado_natal/prado_natal.tscn",
	SectionId.MAPSEC_PUEBLO_ALBA: "res://game/data_core_eb/map_eb/pueblo_alba/pueblo_alba.tscn",
}
