extends Node
class_name MapSection

## Los números se guardan en escenas y partidas: no cambiarlos ni reutilizarlos.
## "Crear nuevo mapa" añade las entradas solo.
enum SectionId {
	MAPSEC_NONE = 0,
	# Valtherion
	MAPSEC_PRADO_NATAL = 1,
	MAPSEC_PUEBLO_ALBA = 2,
	# Kanto
	MAPSEC_PALLET_TOWN = 3,
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

## Sale de MapRegistry (se regenera al guardar un mapa).
static func get_scene_path(section_id: int) -> String:
	var entry: Dictionary = MapRegistry.MAPS.get(section_id, {})
	return str(entry.get("path", ""))


static func get_map_name(section_id: int) -> String:
	var entry: Dictionary = MapRegistry.MAPS.get(section_id, {})
	return str(entry.get("name", SectionId.find_key(section_id)))


static func is_registered(section_id: int) -> bool:
	return MapRegistry.MAPS.has(section_id)


## Mapas con escena, ordenados.
static func get_registered_ids() -> Array[int]:
	var ids: Array[int] = []
	for id: int in MapRegistry.MAPS.keys():
		ids.append(id)
	ids.sort()
	return ids
