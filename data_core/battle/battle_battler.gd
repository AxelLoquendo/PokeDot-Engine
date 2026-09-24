extends RefCounted
class_name BattleBattler

var pokemon: PokemonInstance
var is_player_side: bool = true
var slot_index: int = 0

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
## Focus Energy aumenta dos niveles la probabilidad de golpe crítico.
var focus_energy: bool = false
## Drenadoras: pierde 1/8 PS al final del turno; cura al sembrador del lado rival.
var leech_seeded: bool = false
## Mean Look / Block / Spider Web: no puede huir ni cambiar (salvo efectos de forzado).
var cannot_escape: bool = false
## Destiny Bond: si el usuario debilita a este mon el mismo turno... se debilita el atacante.
var destiny_bond_active: bool = false
## Taunt: solo puede usar movimientos de daño (turnos restantes).
var taunt_turns: int = 0
## Torment: no puede repetir el mismo movimiento.
var torment_active: bool = false
var torment_last_move_id: int = -1
## Disable: un move_id bloqueado N turnos.
var disable_turns: int = 0
var disable_move_id: int = -1
## Encore: obligado a un movimiento.
var encore_turns: int = 0
var encore_move_id: int = -1
## Heal Block: no puede curar.
var heal_block_turns: int = 0
## Lock-On / Mind Reader: el siguiente ataque del marcador siempre acierta.
var locked_on_by_side: int = -1  # 1 = player marcó a este, 0 = enemy
## Substitute HP (0 = sin sustituto).
var substitute_hp: int = 0
## Nightmare (solo si duerme).
var has_nightmare: bool = false
## Curse (Ghost): pierde PS al final del turno.
var is_cursed: bool = false
## Último movimiento usado este combate (para Disable/Encore/Torment).
var last_move_used_id: int = -1
var used_protect_this_turn: bool = false

## Stockpile capas (0-3).
var stockpile_count: int = 0
## Ingrain / Aqua Ring.
var has_ingrain: bool = false
var has_aqua_ring: bool = false
## Magnet Rise / Telekinesis turns.
var magnet_rise_turns: int = 0
## No Retreat / Octolock.
var no_retreat: bool = false
var octolocked: bool = false
## Foresight / Odor Sleuth / Miracle Eye.
var is_identified: bool = false
## Laser Focus: próximo golpe crítico garantizado.
var laser_focus: bool = false
## Wish recibido (turnos hasta curar, -1 inactivo).
var wish_turns: int = -1
var wish_hp: int = 0
## Bide: turnos restantes (-1 inactivo), daño acumulado.
var bide_turns: int = -1
var bide_damage: int = 0
## Future Sight / Doom Desire pendientes sobre este mon.
var future_sight_turns: int = -1
var future_sight_damage: int = 0
var future_sight_from_player: bool = true
## Beak Blast / Shell Trap armado este turno.
var beak_blast_armed: bool = false
var shell_trap_armed: bool = false
## Uproar turns.
var uproar_turns: int = 0

## ─── Habilidades (ver ability_runtime.gd) ────────────────
## Si es false, la habilidad de este Pokémon no tiene ningún efecto
## en combate (p. ej. tras Gas Neutralizante / Mold Breaker, a futuro).
var ability_active: bool = true
## Se activa cuando Flash Fire absorbe un movimiento de Fuego; potencia
## un 50% sus propios movimientos de Fuego mientras siga en combate.
var flash_fire_boosted: bool = false

## Slow Start: 5 turnos con Atk/Spe a la mitad
var slow_start_turns: int = 0
## Unburden: se activa al perder el objeto en combate
var unburden_active: bool = false
## Última baya consumida (Harvest)
var last_berry_id: int = 0  # Items.ItemId
## Cute Charm / Attract: lado del Pokémon que causa atracción (-1 = libre)
var infatuated_by_player_side: int = -1  # 1 player, 0 enemy, -1 none
## Perish Body / Perish Song
var perish_count: int = -1  # -1 inactivo; 3..0 cuenta atrás
## Cud Chew: baya a re-comer el turno siguiente
var cud_chew_berry_id: int = 0
var cud_chew_pending: bool = false
## Zero to Hero / forma combatiente
var zero_to_hero_transformed: bool = false
## Shields Down / Zen Mode tracking
var form_ability_active: bool = false
var truant_skip_turn: bool = false
var just_switched_in: bool = false
var battle_type_1: int = -1
var battle_type_2: int = -1
var charged: bool = false

## Illusion: se ve como otro Pokémon del equipo hasta que reciba daño.
var illusion_active: bool = false
var illusion_species_id: int = -1          # species_id del mon disfraz
var illusion_nickname: String = ""
var illusion_gender: int = 0               # PokemonData.Gender
var illusion_shiny: bool = false
var illusion_form_id: int = 0

## Imposter: copia temporal del rival (Transform).
var is_transformed: bool = false
var transform_backup: Dictionary = {}      # para restaurar al salir si hace falta

func setup(p: PokemonInstance, player_side: bool, p_slot: int = 0) -> void:
	pokemon = p
	is_player_side = player_side
	slot_index = p_slot
	_reset_stages()
	clear_illusion()
	is_transformed = false
	transform_backup.clear()

func clear_illusion() -> void:
	illusion_active = false
	illusion_species_id = -1
	illusion_nickname = ""
	illusion_gender = 0
	illusion_shiny = false
	illusion_form_id = 0

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
	slow_start_turns = 0
	unburden_active = false
	infatuated_by_player_side = -1
	perish_count = -1
	cud_chew_berry_id = 0
	cud_chew_pending = false
	zero_to_hero_transformed = false
	form_ability_active = false
	last_berry_id = 0
	truant_skip_turn = false
	just_switched_in = true
	battle_type_1 = -1
	battle_type_2 = -1
	charged = false
	protect_active = false
	protect_kind = ProtectResolver.Kind.NONE
	endure_active = false
	protect_counter = 0
	charging_move = null
	charging_target = null
	charging_slot_index = -1
	semi_invulnerable = false
	must_recharge = false
	focus_energy = false
	leech_seeded = false
	cannot_escape = false
	destiny_bond_active = false
	taunt_turns = 0
	torment_active = false
	torment_last_move_id = -1
	disable_turns = 0
	disable_move_id = -1
	encore_turns = 0
	encore_move_id = -1
	heal_block_turns = 0
	locked_on_by_side = -1
	substitute_hp = 0
	has_nightmare = false
	is_cursed = false
	last_move_used_id = -1
	used_protect_this_turn = false
	stockpile_count = 0
	has_ingrain = false
	has_aqua_ring = false
	magnet_rise_turns = 0
	no_retreat = false
	octolocked = false
	is_identified = false
	laser_focus = false
	wish_turns = -1
	wish_hp = 0
	bide_turns = -1
	bide_damage = 0
	future_sight_turns = -1
	future_sight_damage = 0
	beak_blast_armed = false
	shell_trap_armed = false
	uproar_turns = 0
	clear_illusion()
	is_transformed = false
	transform_backup.clear()

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
	var value: float = float(base) * _stage_multiplier(stage)

	# Slow Start: Atk y Spe a la mitad
	if slow_start_turns > 0:
		if stat == PokemonInstance.Stat.ATTACK or stat == PokemonInstance.Stat.SPEED:
			value *= 0.5

	# Velocidad: parálisis, Quick Feet, Unburden.
	# Clima/terreno (Chlorophyll, Swift Swim, etc.) vía AbilityRuntime.speed_multiplier.
	if stat == PokemonInstance.Stat.SPEED:
		var has_quick_feet: bool = AbilityRuntime.has(self, AbilityId.Id.QUICK_FEET)
		# Parálisis ×0.5 salvo Quick Feet
		if pokemon.status == PokemonInstance.Status.PARALYSIS and not has_quick_feet:
			value *= 0.5
		if has_quick_feet and pokemon.has_status():
			value *= 1.5
		if unburden_active and AbilityRuntime.has(self, AbilityId.Id.UNBURDEN):
			value *= 2.0

	return maxi(1, int(floor(value)))

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
	if illusion_active and not illusion_nickname.is_empty():
		return illusion_nickname
	return pokemon.get_display_name() if pokemon else "???"

func get_visual_species_id() -> int:
	if illusion_active and illusion_species_id >= 0:
		return illusion_species_id
	if pokemon == null:
		return -1
	return pokemon.species_id

func get_visual_form_id() -> int:
	if illusion_active:
		return illusion_form_id
	if pokemon == null:
		return 0
	return pokemon.form_id if "form_id" in pokemon else 0

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


func get_battle_type_1() -> PokemonData.Type:
	if battle_type_1 >= 0:
		return battle_type_1 as PokemonData.Type
	return pokemon.get_type_1() if pokemon else PokemonData.Type.TYPE_NONE


func get_battle_type_2() -> PokemonData.Type:
	if battle_type_1 >= 0:
		if battle_type_2 >= 0:
			return battle_type_2 as PokemonData.Type
		return PokemonData.Type.TYPE_NONE
	return pokemon.get_type_2() if pokemon else PokemonData.Type.TYPE_NONE


func set_battle_types(type_1: PokemonData.Type, type_2: PokemonData.Type = PokemonData.Type.TYPE_NONE) -> void:
	battle_type_1 = int(type_1)
	battle_type_2 = int(type_2) if type_2 != PokemonData.Type.TYPE_NONE else -1


func clear_battle_types() -> void:
	battle_type_1 = -1
	battle_type_2 = -1


func is_infatuated() -> bool:
	return infatuated_by_player_side >= 0


func clear_infatuation() -> void:
	infatuated_by_player_side = -1
