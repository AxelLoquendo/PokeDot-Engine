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

var confusion_turns: int = 0
var flinched: bool = false

var protect_active: bool = false
var protect_kind: int = ProtectResolver.Kind.NONE
var endure_active: bool = false
var protect_counter: int = 0
var charging_move: MoveData = null
var charging_target: BattleBattler = null
var charging_slot_index: int = -1
var semi_invulnerable: bool = false
var must_recharge: bool = false

## ─── Habilidades (ver ability_runtime.gd) ────────────────
## Si es false, la habilidad de este Pokémon no tiene ningún efecto
## en combate (p. ej. tras Gas Neutralizante / Mold Breaker, a futuro).
var ability_active: bool = true
## Se activa cuando Flash Fire absorbe un movimiento de Fuego; potencia
## un 50% sus propios movimientos de Fuego mientras siga en combate.
var flash_fire_boosted: bool = false

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
	confusion_turns = 0
	flinched = false
	ability_active = true
	flash_fire_boosted = false
	protect_active = false
	protect_kind = ProtectResolver.Kind.NONE
	endure_active = false
	protect_counter = 0
	charging_move = null
	charging_target = null
	charging_slot_index = -1
	semi_invulnerable = false
	must_recharge = false

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

func is_confused() -> bool:
	return confusion_turns > 0


## Aplica un cambio de stage. Devuelve el cambio REAL (puede ser 0 si ya estaba al tope).
func modify_stage(stat: PokemonInstance.Stat, amount: int) -> int:
	var before: int
	match stat:
		PokemonInstance.Stat.ATTACK: before = stage_attack
		PokemonInstance.Stat.DEFENSE: before = stage_defense
		PokemonInstance.Stat.SP_ATTACK: before = stage_sp_attack
		PokemonInstance.Stat.SP_DEFENSE: before = stage_sp_defense
		PokemonInstance.Stat.SPEED: before = stage_speed
		_: before = 0
	var after: int = clampi(before + amount, -6, 6)
	match stat:
		PokemonInstance.Stat.ATTACK: stage_attack = after
		PokemonInstance.Stat.DEFENSE: stage_defense = after
		PokemonInstance.Stat.SP_ATTACK: stage_sp_attack = after
		PokemonInstance.Stat.SP_DEFENSE: stage_sp_defense = after
		PokemonInstance.Stat.SPEED: stage_speed = after
	return after - before


func modify_accuracy_stage(amount: int) -> int:
	var before: int = stage_accuracy
	stage_accuracy = clampi(before + amount, -6, 6)
	return stage_accuracy - before


func modify_evasion_stage(amount: int) -> int:
	var before: int = stage_evasion
	stage_evasion = clampi(before + amount, -6, 6)
	return stage_evasion - before
