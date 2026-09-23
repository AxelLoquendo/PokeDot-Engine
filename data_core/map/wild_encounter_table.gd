extends Resource
class_name WildEncounterTable

## Probabilidad exacta (0–100) de encuentro por paso completado en hierba.
## 12 es una frecuencia moderada para rutas normales. Cada mapa puede subirla
## o bajarla desde su recurso WildEncounterTable.
@export_range(0, 100) var encounter_rate: int = 12
@export var entries: Array[WildEncounterEntry] = []


func esta_vacia() -> bool:
	return entries.is_empty()


## rate_multiplier: Illuminate (y similares) multiplica la tasa de encuentro.
func intentar_encuentro(rate_multiplier: float = 1.0) -> PokemonInstance:
	if esta_vacia():
		return null
	var rate: int = clampi(int(round(float(encounter_rate) * rate_multiplier)), 0, 100)
	# El intervalo 0..99 hace que rate sea un porcentaje exacto.
	if randi_range(0, 99) >= rate:
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
