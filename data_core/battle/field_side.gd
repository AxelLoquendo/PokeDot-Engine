extends RefCounted
class_name FieldSide

var reflect_turns: int = 0
var light_screen_turns: int = 0
var aurora_veil_turns: int = 0
## Evita que el rival reduzca estadísticas durante cinco turnos.
var mist_turns: int = 0
## Evita status no volátiles del rival durante 5 turnos.
var safeguard_turns: int = 0
var spikes_layers: int = 0
var toxic_spikes_layers: int = 0
var stealth_rock: bool = false
var sticky_web: bool = false
var tailwind_turns: int = 0
var lucky_chant_turns: int = 0


func has_screen(is_physical: bool) -> bool:
	if is_physical:
		return reflect_turns > 0 or aurora_veil_turns > 0
	return light_screen_turns > 0 or aurora_veil_turns > 0


func tick_down() -> void:
	reflect_turns = maxi(reflect_turns - 1, 0)
	light_screen_turns = maxi(light_screen_turns - 1, 0)
	aurora_veil_turns = maxi(aurora_veil_turns - 1, 0)
	mist_turns = maxi(mist_turns - 1, 0)
	safeguard_turns = maxi(safeguard_turns - 1, 0)
	tailwind_turns = maxi(tailwind_turns - 1, 0)
	lucky_chant_turns = maxi(lucky_chant_turns - 1, 0)


func clear_screens() -> void:
	reflect_turns = 0
	light_screen_turns = 0
	aurora_veil_turns = 0


func clear_hazards() -> void:
	spikes_layers = 0
	toxic_spikes_layers = 0
	stealth_rock = false
	sticky_web = false
