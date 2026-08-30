extends Resource
class_name WildEncounterTable

## Probabilidad (0–100) de intento de encuentro por paso en hierba.
@export_range(0, 100) var encounter_rate: int = 25
@export var entries: Array[WildEncounterEntry] = []


func esta_vacia() -> bool:
	return entries.is_empty()


func intentar_encuentro() -> PokemonInstance:
	if esta_vacia():
		return null
	if randi_range(1, 100) > encounter_rate:
		return null
	return _elegir_pokemon()


func _elegir_pokemon() -> PokemonInstance:
	var total: int = 0
	for e: WildEncounterEntry in entries:
		if e == null or e.species_id == Species.SpeciesID.SPECIES_NONE:
			continue
		total += maxi(e.weight, 0)
	if total <= 0:
		return null

	var roll: int = randi_range(1, total)
	var acumulado: int = 0
	for e: WildEncounterEntry in entries:
		if e == null or e.species_id == Species.SpeciesID.SPECIES_NONE:
			continue
		acumulado += maxi(e.weight, 0)
		if roll <= acumulado:
			var nivel_min: int = mini(e.min_level, e.max_level)
			var nivel_max: int = maxi(e.min_level, e.max_level)
			var nivel: int = randi_range(nivel_min, nivel_max)
			return _crear_instancia(e.species_id, nivel)
	return null


func _crear_instancia(species_id: Species.SpeciesID, nivel: int) -> PokemonInstance:
	return PokemonInstance.create(species_id, nivel)
