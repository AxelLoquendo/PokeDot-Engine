@tool
extends EditorScript


func _run() -> void:

	print("")
	print("================================")
	print("POKÉMON EVOLUTION TEST")
	print("================================")


	# Crear Pokémon
	var pokemon: PokemonInstance = PokemonInstance.create(
		Species.SpeciesID.SPECIES_BULBASAUR,
		15
	)

	print("")
	print("Pokémon creado:")
	print("  Especie: ", pokemon.get_display_name())
	print("  ID: ", pokemon.species_id)
	print("  Nivel: ", pokemon.level)


	# Subir nivel
	pokemon.level += 1

	print("")
	print("Pokémon subió de nivel:")
	print("  Especie: ", pokemon.get_display_name())
	print("  Nivel: ", pokemon.level)


	# Buscar evoluciones disponibles
	var evolutions: Array[EvolutionResult] = (
		EvolutionSystem.get_available_evolutions(
			pokemon,
			PokemonData.EvolutionMode.EVO_MODE_NORMAL
		)
	)

	print("")
	print("Evoluciones disponibles: ", evolutions.size())


	for result: EvolutionResult in evolutions:

		print(
			"  → ",
			result.target_species
		)


	# Ejecutar primera evolución encontrada
	if evolutions.is_empty():

		print("")
		print("❌ No se encontró ninguna evolución.")
		return


	var result: EvolutionResult = evolutions[0]

	var success: bool = EvolutionSystem.evolve(
		pokemon,
		result,
		PokemonData.EvolutionMode.EVO_MODE_NORMAL
	)


	print("")
	print("Resultado:")
	print("  Evolución exitosa: ", success)
	print("  Nueva especie: ", pokemon.species_id)
	print("  Nuevo nombre: ", pokemon.get_display_name())
	print("  Nivel: ", pokemon.level)

	print("")
	print("================================")
	print("TEST FINALIZADO")
	print("================================")
