extends ItemList

class_name SpeciesList

## Displays a filterable list of species with ID and name

var _species_data: Array[PokemonDataStruct] = []
var _filtered_indices: Array[int] = []

func set_species(species_array: Array[PokemonDataStruct]) -> void:
	_species_data = species_array
	refresh_view()

func refresh_view() -> void:
	clear()
	_filtered_indices.clear()

	for i in range(_species_data.size()):
		var species = _species_data[i]
		if species == null:
			continue

		var item_text = "[%d] %s" % [species.species_id, species.species_name]
		add_item(item_text)
		_filtered_indices.append(i)

func filter_by_search(search_text: String) -> void:
	clear()
	_filtered_indices.clear()

	var search_lower = search_text.to_lower()

	for i in range(_species_data.size()):
		var species = _species_data[i]
		if species == null:
			continue

		var id_match = str(species.species_id).contains(search_lower)
		var name_match = species.species_name.to_lower().contains(search_lower)

		if id_match or name_match:
			var item_text = "[%d] %s" % [species.species_id, species.species_name]
			add_item(item_text)
			_filtered_indices.append(i)

func get_selected_species() -> PokemonDataStruct:
	var selected_idx = get_selected_items()
	if selected_idx.is_empty():
		return null

	var idx = selected_idx[0]
	if idx < 0 or idx >= _filtered_indices.size():
		return null

	var original_idx = _filtered_indices[idx]
	if original_idx < 0 or original_idx >= _species_data.size():
		return null

	return _species_data[original_idx]
