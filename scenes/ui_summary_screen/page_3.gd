extends Node2D
class_name SummaryPageBaseIvEv


var pokemon: PokemonInstance = null


@onready var number_hp_total: Label = (
	$BaseIvEv2/HP/Number_Hp_Total
)
@onready var number_hp_iv: Label = (
	$BaseIvEv2/HP/Number_Hp_IV
)
@onready var number_hp_ev: Label = (
	$BaseIvEv2/HP/Number_Hp_EV
)

@onready var number_attack_total: Label = (
	$BaseIvEv2/Attack/Number_Attack_Total
)
@onready var number_attack_iv: Label = (
	$BaseIvEv2/Attack/Number_Attack_IV
)
@onready var number_attack_ev: Label = (
	$BaseIvEv2/Attack/Number_Attack_EV
)

@onready var number_defense_total: Label = (
	$BaseIvEv2/Defense/Number_Defense_Total
)
@onready var number_defense_iv: Label = (
	$BaseIvEv2/Defense/Number_Defense_IV
)
@onready var number_defense_ev: Label = (
	$BaseIvEv2/Defense/Number_Defense_EV
)

@onready var number_sp_attack_total: Label = (
	$BaseIvEv2/SP_Attack/Number_Sp_Attack_Total
)
@onready var number_sp_attack_iv: Label = (
	$BaseIvEv2/SP_Attack/Number_Sp_Attack_IV
)
@onready var number_sp_attack_ev: Label = (
	$BaseIvEv2/SP_Attack/Number_Sp_Attack_EV
)

@onready var number_sp_defense_total: Label = (
	$BaseIvEv2/SP_Defense/Number_Sp_Defense_Total
)
@onready var number_sp_defense_iv: Label = (
	$BaseIvEv2/SP_Defense/Number_Sp_Defense_IV
)
@onready var number_sp_defense_ev: Label = (
	$BaseIvEv2/SP_Defense/Number_Sp_Defense_EV
)

@onready var number_speed_total: Label = (
	$BaseIvEv2/Speed/Number_Speed_Total
)
@onready var number_speed_iv: Label = (
	$BaseIvEv2/Speed/Number_Speed_IV
)
@onready var number_speed_ev: Label = (
	$BaseIvEv2/Speed/Number_Speed_EV
)

@onready var number_evs: Label = (
	$BaseIvEv2/EVs_Total/Number_EVs
)

@onready var secret_power_type: Sprite2D = (
	$BaseIvEv2/Secret_Power/Type
)


const MAX_TOTAL_EVS: int = 510

const HIDDEN_POWER_TYPES: Array = [
	PokemonData.Type.TYPE_FIGHTING,
	PokemonData.Type.TYPE_FLYING,
	PokemonData.Type.TYPE_POISON,
	PokemonData.Type.TYPE_GROUND,
	PokemonData.Type.TYPE_ROCK,
	PokemonData.Type.TYPE_BUG,
	PokemonData.Type.TYPE_GHOST,
	PokemonData.Type.TYPE_STEEL,
	PokemonData.Type.TYPE_FIRE,
	PokemonData.Type.TYPE_WATER,
	PokemonData.Type.TYPE_GRASS,
	PokemonData.Type.TYPE_ELECTRIC,
	PokemonData.Type.TYPE_PSYCHIC,
	PokemonData.Type.TYPE_ICE,
	PokemonData.Type.TYPE_DRAGON,
	PokemonData.Type.TYPE_DARK,
]



func setup(nuevo_pokemon: PokemonInstance) -> void:
	pokemon = nuevo_pokemon

	if pokemon == null:
		return

	_actualizar_ui()


func _actualizar_ui() -> void:
	_actualizar_estadistica(
		number_hp_total,
		number_hp_iv,
		number_hp_ev,
		PokemonInstance.Stat.HP
	)

	_actualizar_estadistica(
		number_attack_total,
		number_attack_iv,
		number_attack_ev,
		PokemonInstance.Stat.ATTACK
	)

	_actualizar_estadistica(
		number_defense_total,
		number_defense_iv,
		number_defense_ev,
		PokemonInstance.Stat.DEFENSE
	)

	_actualizar_estadistica(
		number_sp_attack_total,
		number_sp_attack_iv,
		number_sp_attack_ev,
		PokemonInstance.Stat.SP_ATTACK
	)

	_actualizar_estadistica(
		number_sp_defense_total,
		number_sp_defense_iv,
		number_sp_defense_ev,
		PokemonInstance.Stat.SP_DEFENSE
	)

	_actualizar_estadistica(
		number_speed_total,
		number_speed_iv,
		number_speed_ev,
		PokemonInstance.Stat.SPEED
	)

	_actualizar_total_evs()
	_actualizar_potencia_oculta()



func _actualizar_estadistica(
	total_label: Label,
	iv_label: Label,
	ev_label: Label,
	stat: PokemonInstance.Stat
) -> void:
	if pokemon == null:
		return

	var stat_index: int = int(stat)

	if total_label:
		total_label.text = str(
			_obtener_stat_final(stat_index)
		)

	if iv_label:
		iv_label.text = str(
			_obtener_valor_array(pokemon.ivs, stat_index)
		)

	if ev_label:
		ev_label.text = str(
			_obtener_valor_array(pokemon.evs, stat_index)
		)


func _obtener_stat_final(stat_index: int) -> int:
	if stat_index < 0:
		return 0

	if stat_index >= pokemon.stats.size():
		return 0

	return pokemon.stats[stat_index]


func _obtener_valor_array(
	valores: Array[int],
	indice: int
) -> int:
	if indice < 0:
		return 0

	if indice >= valores.size():
		return 0

	return valores[indice]


func _actualizar_total_evs() -> void:
	if number_evs == null or pokemon == null:
		return

	var total_evs: int = 0

	for ev: int in pokemon.evs:
		total_evs += ev

	number_evs.text = "%d/%d" % [
		total_evs,
		MAX_TOTAL_EVS
	]


func _actualizar_potencia_oculta() -> void:
	if pokemon == null or secret_power_type == null:
		return

	var hidden_power_type: PokemonData.Type = (
		_obtener_tipo_potencia_oculta()
	)

	var icon: Texture2D = TypeIconsDb.get_icon(
		hidden_power_type
	)

	if icon:
		secret_power_type.texture = icon

func _obtener_tipo_potencia_oculta() -> PokemonData.Type:
	var hp_bit: int = _obtener_iv(PokemonInstance.Stat.HP) % 2
	var attack_bit: int = (
		_obtener_iv(PokemonInstance.Stat.ATTACK) % 2
	)
	var defense_bit: int = (
		_obtener_iv(PokemonInstance.Stat.DEFENSE) % 2
	)
	var speed_bit: int = (
		_obtener_iv(PokemonInstance.Stat.SPEED) % 2
	)
	var sp_attack_bit: int = (
		_obtener_iv(PokemonInstance.Stat.SP_ATTACK) % 2
	)
	var sp_defense_bit: int = (
		_obtener_iv(PokemonInstance.Stat.SP_DEFENSE) % 2
	)

	var bits_de_tipo: int = (
		hp_bit
		+ 2 * attack_bit
		+ 4 * defense_bit
		+ 8 * speed_bit
		+ 16 * sp_attack_bit
		+ 32 * sp_defense_bit
	)

	@warning_ignore("integer_division")
	var type_index: int = int((bits_de_tipo * 15) / 63)

	return HIDDEN_POWER_TYPES[type_index]


func _obtener_iv(stat: PokemonInstance.Stat) -> int:
	if pokemon == null:
		return 0

	var stat_index: int = int(stat)

	if stat_index < 0:
		return 0

	if stat_index >= pokemon.ivs.size():
		return 0

	return clampi(pokemon.ivs[stat_index], 0, 31)
