extends RefCounted
class_name ExperienceSystem


const MAX_LEVEL: int = 100


static func get_total_exp_for_level(
	level: int,
	growth_rate: PokemonData.GrowthRate
) -> int:
	var n: int = clampi(level, 1, MAX_LEVEL)

	if n <= 1:
		return 0

	var cube: float = float(n * n * n)

	match growth_rate:
		PokemonData.GrowthRate.GROWTH_ERRATIC:
			if n <= 50:
				return _floor_exp(
					cube * float(100 - n) / 50.0
				)

			if n <= 68:
				return _floor_exp(
					cube * float(150 - n) / 100.0
				)

			if n <= 98:
				var factor: float = floor(
					(1911.0 - 10.0 * float(n)) / 3.0
				)

				return _floor_exp(
					cube * factor / 500.0
				)

			return _floor_exp(
				cube * float(160 - n) / 100.0
			)


		PokemonData.GrowthRate.GROWTH_FLUCTUATING:
			if n <= 15:
				var first_factor: float = (
					floor(float(n + 1) / 3.0) + 24.0
				)

				return _floor_exp(
					cube * first_factor / 50.0
				)

			if n <= 35:
				return _floor_exp(
					cube * float(n + 14) / 50.0
				)

			return _floor_exp(
				cube * (floor(float(n) / 2.0) + 32.0) / 50.0
			)


		PokemonData.GrowthRate.GROWTH_MEDIUM_SLOW:
			return maxi(
				_floor_exp(
					(6.0 / 5.0) * cube
					- 15.0 * float(n * n)
					+ 100.0 * float(n)
					- 140.0
				),
				0
			)


		PokemonData.GrowthRate.GROWTH_FAST:
			return _floor_exp(
				(4.0 / 5.0) * cube
			)


		PokemonData.GrowthRate.GROWTH_SLOW:
			return _floor_exp(
				(5.0 / 4.0) * cube
			)


		# También cubre GROWTH_MEDIUM_FAST.
		_:
			return _floor_exp(cube)


static func get_exp_to_next_level(
	current_level: int,
	current_exp: int,
	growth_rate: PokemonData.GrowthRate
) -> int:
	if current_level >= MAX_LEVEL:
		return 0

	var next_level_exp: int = get_total_exp_for_level(
		current_level + 1,
		growth_rate
	)

	return maxi(next_level_exp - current_exp, 0)


static func _floor_exp(value: float) -> int:
	return maxi(int(floor(value)), 0)
