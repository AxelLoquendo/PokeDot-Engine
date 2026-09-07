extends Resource
class_name PokedexData

## Pokédex del jugador (estilo Essentials: seen / owned).
## species_id usa el int de Species.SpeciesID / national dex según tu enum.

@export var seen: Dictionary = {}    # int -> true
@export var owned: Dictionary = {}   # int -> true


func clear() -> void:
	seen.clear()
	owned.clear()


func set_seen(species_id: int) -> void:
	if species_id <= 0:
		return
	seen[species_id] = true


func set_owned(species_id: int) -> void:
	if species_id <= 0:
		return
	seen[species_id] = true
	owned[species_id] = true


func is_seen(species_id: int) -> bool:
	return bool(seen.get(species_id, false))


func is_owned(species_id: int) -> bool:
	return bool(owned.get(species_id, false))


func seen_count() -> int:
	return seen.size()


func owned_count() -> int:
	return owned.size()


## Serialización para el save (JSON-friendly).
func to_dict() -> Dictionary:
	var seen_arr: Array = []
	var owned_arr: Array = []
	for k: Variant in seen.keys():
		if seen[k]:
			seen_arr.append(int(k))
	for k: Variant in owned.keys():
		if owned[k]:
			owned_arr.append(int(k))
	return {
		"seen": seen_arr,
		"owned": owned_arr,
	}


func from_dict(data: Dictionary) -> void:
	clear()
	var seen_val: Variant = data.get("seen", [])
	if seen_val is Array:
		for id_val: Variant in seen_val:
			seen[int(id_val)] = true
	var owned_val: Variant = data.get("owned", [])
	if owned_val is Array:
		for id_val: Variant in owned_val:
			var id: int = int(id_val)
			owned[id] = true
			seen[id] = true  # owned implica seen
