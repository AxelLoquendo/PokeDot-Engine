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
	# Custom Region
	REGION_VALTHERION,
	# Regiones oficiales
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
}
