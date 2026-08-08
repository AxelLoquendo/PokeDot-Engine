extends Node
class_name WeatherBase

func start() -> void:
	pass

func stop() -> void:
	pass

func fade_in() -> Signal:
	return get_tree().process_frame

func fade_out() -> Signal:
	return get_tree().process_frame

func update_weather(_delta: float) -> void:
	pass
