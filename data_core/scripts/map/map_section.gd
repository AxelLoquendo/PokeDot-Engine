extends Node
class_name MapSection

## Cada número queda guardado en las escenas (.tscn) y en las partidas:
## no cambies ni reutilices un valor ya asignado.
## "Proyecto → Herramientas → Crear nuevo mapa" añade las entradas nuevas solo.
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


## Ruta de la escena del mapa. Sale de MapRegistry (data_core/generated),
## que se regenera al guardar un mapa en el editor.
static func get_scene_path(section_id: int) -> String:
	var entry: Dictionary = MapRegistry.MAPS.get(section_id, {})
	return str(entry.get("path", ""))


static func get_map_name(section_id: int) -> String:
	var entry: Dictionary = MapRegistry.MAPS.get(section_id, {})
	return str(entry.get("name", SectionId.find_key(section_id)))


static func is_registered(section_id: int) -> bool:
	return MapRegistry.MAPS.has(section_id)


## IDs de todos los mapas con escena, en orden numérico.
static func get_registered_ids() -> Array[int]:
	var ids: Array[int] = []
	for id: int in MapRegistry.MAPS.keys():
		ids.append(id)
	ids.sort()
	return ids
