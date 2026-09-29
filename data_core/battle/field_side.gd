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
## 1 turno: protege al lado de movimientos spread / prioridad / estado
var wide_guard_turns: int = 0
var quick_guard_turns: int = 0
var crafty_shield_turns: int = 0

## Efectos por posición (slot 0/1). Wish / Future Sight / Healing Wish.
## wish[slot] = { "turns": int, "hp": int } o vacío
var wish: Array = [{}, {}]
## future_sight[slot] = { "turns": int, "damage": int, "from_player": bool }
var future_sight: Array = [{}, {}]
## healing_wish_pending[slot] = true → curar al entrante (HP + estado; lunar_dance también PP)
var healing_wish_pending: Array = [false, false]
var lunar_dance_pending: Array = [false, false]


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
	wide_guard_turns = maxi(wide_guard_turns - 1, 0)
	quick_guard_turns = maxi(quick_guard_turns - 1, 0)
	crafty_shield_turns = maxi(crafty_shield_turns - 1, 0)


func clear_screens() -> void:
	reflect_turns = 0
	light_screen_turns = 0
	aurora_veil_turns = 0


func clear_hazards() -> void:
	spikes_layers = 0
	toxic_spikes_layers = 0
	stealth_rock = false
	sticky_web = false


func set_wish(slot: int, turns: int, hp: int) -> void:
	slot = clampi(slot, 0, 1)
	while wish.size() < 2:
		wish.append({})
	wish[slot] = {"turns": turns, "hp": hp}


func set_future_sight(slot: int, turns: int, damage: int, from_player: bool) -> void:
	slot = clampi(slot, 0, 1)
	while future_sight.size() < 2:
		future_sight.append({})
	future_sight[slot] = {"turns": turns, "damage": damage, "from_player": from_player}


func queue_healing_wish(slot: int, lunar: bool = false) -> void:
	slot = clampi(slot, 0, 1)
	while healing_wish_pending.size() < 2:
		healing_wish_pending.append(false)
	while lunar_dance_pending.size() < 2:
		lunar_dance_pending.append(false)
	if lunar:
		lunar_dance_pending[slot] = true
	else:
		healing_wish_pending[slot] = true
