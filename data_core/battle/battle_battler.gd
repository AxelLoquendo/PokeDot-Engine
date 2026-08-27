extends RefCounted
class_name BattleBattler

var pokemon: PokemonInstance
var is_player_side: bool = true

var stage_attack: int = 0
var stage_defense: int = 0
var stage_sp_attack: int = 0
var stage_sp_defense: int = 0
var stage_speed: int = 0
var stage_accuracy: int = 0
var stage_evasion: int = 0


func setup(p: PokemonInstance, player_side: bool) -> void:
	pokemon = p
	is_player_side = player_side
	_reset_stages()


func _reset_stages() -> void:
	stage_attack = 0
	stage_defense = 0
	stage_sp_attack = 0
	stage_sp_defense = 0
	stage_speed = 0
	stage_accuracy = 0
	stage_evasion = 0


func is_fainted() -> bool:
	return pokemon == null or pokemon.current_hp <= 0


func get_current_hp() -> int:
	return pokemon.current_hp if pokemon else 0


func get_max_hp() -> int:
	return pokemon.max_hp if pokemon else 1


func apply_damage(amount: int) -> int:
	if pokemon == null or amount <= 0:
		return 0
	var before: int = pokemon.current_hp
	pokemon.apply_damage(amount)
	return before - pokemon.current_hp


func get_effective_stat(stat: PokemonInstance.Stat) -> int:
	if pokemon == null:
		return 1
	var base: int = maxi(pokemon.get_stat(stat), 1)
	var stage: int = 0
	match stat:
		PokemonInstance.Stat.ATTACK:
			stage = stage_attack
		PokemonInstance.Stat.DEFENSE:
			stage = stage_defense
		PokemonInstance.Stat.SP_ATTACK:
			stage = stage_sp_attack
		PokemonInstance.Stat.SP_DEFENSE:
			stage = stage_sp_defense
		PokemonInstance.Stat.SPEED:
			stage = stage_speed
		_:
			stage = 0
	return maxi(1, int(floor(float(base) * _stage_multiplier(stage))))


static func _stage_multiplier(stage: int) -> float:
	stage = clampi(stage, -6, 6)
	if stage >= 0:
		return (2.0 + float(stage)) / 2.0
	return 2.0 / (2.0 - float(stage))


func consume_pp(slot_index: int) -> bool:
	if pokemon == null:
		return false
	if slot_index < 0 or slot_index >= pokemon.moves.size():
		return false
	var slot: PokemonMoveSlot = pokemon.moves[slot_index]
	if slot == null or slot.is_empty() or slot.current_pp <= 0:
		return false
	slot.current_pp -= 1
	return true


func get_display_name() -> String:
	return pokemon.get_display_name() if pokemon else "???"
