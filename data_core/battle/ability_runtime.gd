extends RefCounted
class_name AbilityRuntime

## Fachada de habilidades.
## No contiene efectos de ninguna habilidad concreta.
## Solo arma EffectContext y delega en AbilitySystem (scripts .txt).
## Tipado estricto en toda la API pública.

const WeatherId = AbilityBattleEffect.weatherAbilityID


# ═══════════════════════════════════════════════════════════
# Identidad (lectura de estado, no efectos)
# ═══════════════════════════════════════════════════════════

static func get_id(battler: BattleBattler) -> AbilityId.Id:
	if battler == null or battler.pokemon == null:
		return AbilityId.Id.NONE
	if not battler.ability_active:
		return AbilityId.Id.NONE
	return battler.pokemon.ability_id


static func has(battler: BattleBattler, id: AbilityId.Id) -> bool:
	return get_id(battler) == id


static func ability_name(battler: BattleBattler) -> String:
	var id: AbilityId.Id = get_id(battler)
	if id == AbilityId.Id.NONE:
		return ""
	if AbilityDatabase != null and AbilityDatabase.has_ability(id):
		return AbilityDatabase.get_ability_name(id)
	return ""


static func get_ally(battler: BattleBattler, battle: BattleManager) -> BattleBattler:
	if battler == null or battle == null or not battle.is_multi_battle():
		return null
	if not battle.has_method("get_allies"):
		return null
	var allies: Array = battle.get_allies(battler)
	for a: Variant in allies:
		var ally: BattleBattler = a as BattleBattler
		if ally != null and ally != battler and not ally.is_fainted():
			return ally
	return null


# ═══════════════════════════════════════════════════════════
# Eventos de secuencia (async)
# ═══════════════════════════════════════════════════════════

## Rating de IA del .tres AbilityData (−100…100). 0 si no hay datos.
static func get_ai_rating(battler: BattleBattler) -> int:
	if battler == null:
		return 0
	var id: AbilityId.Id = get_id(battler)
	if id == AbilityId.Id.NONE or id == AbilityId.Id.COUNT:
		return 0
	if AbilityDatabase == null or not AbilityDatabase.has_ability(id):
		return 0
	var data: AbilityData = AbilityDatabase.get_ability(id)
	if data == null:
		return 0
	return data.ai_rating


static func on_switch_in(battler: BattleBattler, opponent: BattleBattler, battle: BattleManager) -> void:
	if battler == null or battler.pokemon == null or battle == null:
		return
	var ctx: EffectContext = EffectContext.new(battler, opponent, null, battle)
	await AbilitySystem.on_event("on_switch_in", ctx)


static func on_switch_out(battler: BattleBattler, battle: BattleManager) -> void:
	if battler == null or battle == null:
		return
	var ctx: EffectContext = EffectContext.new(battler, null, null, battle)
	await AbilitySystem.on_event("on_switch_out", ctx)


static func on_contact_hit(
	attacker: BattleBattler,
	defender: BattleBattler,
	move: MoveData,
	battle: BattleManager
) -> void:
	if move == null or attacker == null or defender == null or battle == null:
		return
	if attacker.is_fainted():
		return
	var ctx_def: EffectContext = EffectContext.new(defender, attacker, move, battle)
	ctx_def.attacker = attacker
	ctx_def.is_contact = move.makes_contact
	await AbilitySystem.on_event("on_hit_by", ctx_def)
	var ctx_atk: EffectContext = EffectContext.new(attacker, defender, move, battle)
	ctx_atk.attacker = attacker
	ctx_atk.is_contact = move.makes_contact
	await AbilitySystem.on_event("on_hit", ctx_atk)


static func on_damaged_by_move(
	defender: BattleBattler,
	attacker: BattleBattler,
	move: MoveData,
	was_critical: bool,
	battle: BattleManager
) -> void:
	if defender == null or defender.is_fainted() or move == null or battle == null:
		return
	var ctx: EffectContext = EffectContext.new(defender, attacker, move, battle)
	ctx.attacker = attacker
	ctx.was_critical = was_critical
	ctx.is_contact = move.makes_contact
	await AbilitySystem.on_event("on_damaged", ctx)


static func end_of_turn(battler: BattleBattler, weather: int, battle: BattleManager) -> void:
	if battler == null or battler.pokemon == null or battle == null or battler.is_fainted():
		return
	var opp: BattleBattler = null
	if battle.has_method("get_opponents"):
		var foes: Array = battle.get_opponents(battler)
		if not foes.is_empty():
			opp = foes[0] as BattleBattler
	var ctx: EffectContext = EffectContext.new(battler, opp, null, battle)
	ctx.weather = weather
	ctx.terrain = battle.terrain
	await AbilitySystem.on_event("on_end_turn", ctx)


static func on_flinched(battler: BattleBattler, battle: BattleManager) -> void:
	if battler == null or battle == null:
		return
	var ctx: EffectContext = EffectContext.new(battler, null, null, battle)
	await AbilitySystem.on_event("on_flinch", ctx)


static func after_own_stat_drop(
	battler: BattleBattler,
	actual: int,
	caused_by_foe: bool,
	battle: BattleManager
) -> void:
	if not caused_by_foe or actual >= 0 or battler == null or battle == null:
		return
	var ctx: EffectContext = EffectContext.new(battler, null, null, battle)
	ctx.query_int = actual
	await AbilitySystem.on_event("on_stat_drop", ctx)


static func on_berry_eaten(battler: BattleBattler, battle: BattleManager) -> void:
	if battler == null or battle == null or battler.is_fainted():
		return
	var ctx: EffectContext = EffectContext.new(battler, null, null, battle)
	await AbilitySystem.on_event("on_berry_eaten", ctx)


static func notify_berry_eaten(battler: BattleBattler, berry_id: int) -> void:
	if battler == null:
		return
	battler.set_meta("last_berry_id", berry_id)
	battler.set_meta("cud_chew_pending", true)


static func notify_item_lost(battler: BattleBattler) -> void:
	if battler == null:
		return
	var ctx: EffectContext = EffectContext.new(battler, null, null, null)
	AbilitySystem.query("on_item_lost", ctx)


# ═══════════════════════════════════════════════════════════
# Consultas síncronas
# ═══════════════════════════════════════════════════════════

static func type_immunity_reaction(defender: BattleBattler, move: MoveData) -> String:
	if move == null or move.category == MoveStruct.DamageCategory.STATUS:
		return ""
	var ctx: EffectContext = EffectContext.new(defender, null, move, null)
	AbilitySystem.query("on_immunity", ctx)
	return ctx.immunity_reaction


static func blocks_unless_super_effective(defender: BattleBattler) -> bool:
	var ctx: EffectContext = EffectContext.new(defender, null, null, null)
	return AbilitySystem.query_bool("on_wonder_guard", ctx)


static func attack_stat_multiplier(attacker: BattleBattler, category: MoveStruct.DamageCategory) -> float:
	if attacker == null or attacker.pokemon == null:
		return 1.0
	var ctx: EffectContext = EffectContext.new(attacker, null, null, null)
	ctx.move_category = int(category)
	return AbilitySystem.query_float("on_attack_stat", ctx, 1.0)


static func power_multiplier(
	attacker: BattleBattler,
	move: MoveData,
	defender: BattleBattler = null
) -> float:
	if move == null or attacker == null or attacker.pokemon == null:
		return 1.0
	var ctx: EffectContext = EffectContext.new(attacker, defender, move, null)
	ctx.multiplier = 1.0
	if attacker.charged:
		ctx.multiplier *= 2.0
	AbilitySystem.query("on_power", ctx)
	return ctx.multiplier


static func damage_taken_multiplier(defender: BattleBattler, move: MoveData, effectiveness: float) -> float:
	if move == null:
		return 1.0
	var ctx: EffectContext = EffectContext.new(defender, null, move, null)
	ctx.effectiveness = effectiveness
	return AbilitySystem.query_float("on_damage_taken", ctx, 1.0)


static func should_survive_with_sturdy(defender: BattleBattler, incoming_damage: int) -> bool:
	if defender == null or defender.pokemon == null:
		return false
	if defender.pokemon.current_hp != defender.pokemon.max_hp:
		return false
	if incoming_damage < defender.pokemon.current_hp:
		return false
	var ctx: EffectContext = EffectContext.new(defender, null, null, null)
	return AbilitySystem.query_bool("on_sturdy", ctx)


static func blocks_status(battler: BattleBattler, status: PokemonInstance.Status, weather: int = -1) -> bool:
	var ctx: EffectContext = EffectContext.new(battler, null, null, null)
	ctx.query_status = int(status)
	ctx.weather = weather
	return AbilitySystem.query_bool("on_blocks_status", ctx)


static func blocks_confusion(battler: BattleBattler) -> bool:
	var ctx: EffectContext = EffectContext.new(battler, null, null, null)
	return AbilitySystem.query_bool("on_blocks_confusion", ctx)


static func blocks_flinch(battler: BattleBattler) -> bool:
	var ctx: EffectContext = EffectContext.new(battler, null, null, null)
	return AbilitySystem.query_bool("on_blocks_flinch", ctx)


static func blocks_critical(defender: BattleBattler) -> bool:
	var ctx: EffectContext = EffectContext.new(defender, null, null, null)
	return AbilitySystem.query_bool("on_blocks_critical", ctx)


static func blocks_recoil(battler: BattleBattler) -> bool:
	var ctx: EffectContext = EffectContext.new(battler, null, null, null)
	return AbilitySystem.query_bool("on_blocks_recoil", ctx)


static func blocks_indirect_damage(battler: BattleBattler) -> bool:
	var ctx: EffectContext = EffectContext.new(battler, null, null, null)
	return AbilitySystem.query_bool("on_blocks_indirect", ctx)


static func blocks_foe_stat_drop(battler: BattleBattler, stat: PokemonInstance.Stat) -> bool:
	var ctx: EffectContext = EffectContext.new(battler, null, null, null)
	ctx.query_int = int(stat)
	return AbilitySystem.query_bool("on_blocks_stat_drop", ctx)


static func blocks_foe_accuracy_drop(battler: BattleBattler) -> bool:
	var ctx: EffectContext = EffectContext.new(battler, null, null, null)
	# Accuracy no está en PokemonInstance.Stat; consulta dedicada.
	return AbilitySystem.query_bool("on_blocks_accuracy_drop", ctx)


static func blocks_intimidate(battler: BattleBattler) -> bool:
	var ctx: EffectContext = EffectContext.new(battler, null, null, null)
	return AbilitySystem.query_bool("on_blocks_intimidate", ctx)


static func speed_multiplier(battler: BattleBattler, weather: int, terrain: int = -1) -> float:
	if battler == null:
		return 1.0
	var ctx: EffectContext = EffectContext.new(battler, null, null, null)
	ctx.weather = weather
	ctx.terrain = terrain
	return AbilitySystem.query_float("on_speed", ctx, 1.0)


static func stab_multiplier(attacker: BattleBattler) -> float:
	var ctx: EffectContext = EffectContext.new(attacker, null, null, null)
	ctx.multiplier = 1.5
	AbilitySystem.query("on_stab", ctx)
	return ctx.multiplier


static func always_max_hits(attacker: BattleBattler) -> bool:
	var ctx: EffectContext = EffectContext.new(attacker, null, null, null)
	return AbilitySystem.query_bool("on_always_max_hits", ctx)


static func attacker_damage_multiplier(attacker: BattleBattler, effectiveness: float, _is_critical: bool) -> float:
	var ctx: EffectContext = EffectContext.new(attacker, null, null, null)
	ctx.effectiveness = effectiveness
	return AbilitySystem.query_float("on_attacker_damage", ctx, 1.0)


static func crit_damage_multiplier(attacker: BattleBattler) -> float:
	var ctx: EffectContext = EffectContext.new(attacker, null, null, null)
	ctx.multiplier = 1.5
	AbilitySystem.query("on_crit", ctx)
	return ctx.multiplier


static func ignores_defender_ability(attacker: BattleBattler) -> bool:
	var ctx: EffectContext = EffectContext.new(attacker, null, null, null)
	return AbilitySystem.query_bool("on_ignores_ability", ctx)


static func priority_bonus(battler: BattleBattler, move: MoveData) -> int:
	if battler == null or move == null:
		return 0
	var ctx: EffectContext = EffectContext.new(battler, null, move, null)
	return AbilitySystem.query_int("on_priority", ctx, 0)


static func blocks_priority_move(defender: BattleBattler, move: MoveData) -> bool:
	if defender == null or move == null or move.priority <= 0:
		return false
	var ctx: EffectContext = EffectContext.new(defender, null, move, null)
	return AbilitySystem.query_bool("on_blocks_priority", ctx)


static func blocks_status_move(defender: BattleBattler, move: MoveData) -> bool:
	if defender == null or move == null:
		return false
	if move.category != MoveStruct.DamageCategory.STATUS:
		return false
	var ctx: EffectContext = EffectContext.new(defender, null, move, null)
	return AbilitySystem.query_bool("on_blocks_status_move", ctx)


static func effective_move_type(attacker: BattleBattler, move: MoveData) -> PokemonData.Type:
	if move == null:
		return PokemonData.Type.TYPE_NONE
	var t: PokemonData.Type = move.type
	if attacker == null:
		return t
	var ctx: EffectContext = EffectContext.new(attacker, null, move, null)
	ctx.query_int = int(t)
	AbilitySystem.query("on_move_type", ctx)
	return ctx.query_int as PokemonData.Type


static func type_change_power_multiplier(attacker: BattleBattler, move: MoveData) -> float:
	if move == null:
		return 1.0
	var ctx: EffectContext = EffectContext.new(attacker, null, move, null)
	return AbilitySystem.query_float("on_type_power", ctx, 1.0)


static func weight_multiplier(battler: BattleBattler) -> float:
	var ctx: EffectContext = EffectContext.new(battler, null, null, null)
	return AbilitySystem.query_float("on_weight", ctx, 1.0)


static func berry_hp_threshold(battler: BattleBattler) -> float:
	var ctx: EffectContext = EffectContext.new(battler, null, null, null)
	ctx.multiplier = 0.25
	AbilitySystem.query("on_berry_threshold", ctx)
	return ctx.multiplier


static func berry_effect_multiplier(battler: BattleBattler) -> float:
	var ctx: EffectContext = EffectContext.new(battler, null, null, null)
	return AbilitySystem.query_float("on_berry_effect", ctx, 1.0)


static func ignores_held_item(battler: BattleBattler) -> bool:
	var ctx: EffectContext = EffectContext.new(battler, null, null, null)
	return AbilitySystem.query_bool("on_ignores_held_item", ctx)


static func blocks_forced_switch(battler: BattleBattler) -> bool:
	var ctx: EffectContext = EffectContext.new(battler, null, null, null)
	return AbilitySystem.query_bool("on_blocks_forced_switch", ctx)


static func ignores_redirection(battler: BattleBattler) -> bool:
	var ctx: EffectContext = EffectContext.new(battler, null, null, null)
	return AbilitySystem.query_bool("on_ignores_redirection", ctx)


static func blocks_mental_effect(battler: BattleBattler) -> bool:
	var ctx: EffectContext = EffectContext.new(battler, null, null, null)
	return AbilitySystem.query_bool("on_blocks_mental", ctx)


static func reflects_stat_drop(battler: BattleBattler) -> bool:
	var ctx: EffectContext = EffectContext.new(battler, null, null, null)
	return AbilitySystem.query_bool("on_reflects_stat_drop", ctx)


static func status_move_ignores_abilities(attacker: BattleBattler, move: MoveData) -> bool:
	if move == null or move.category != MoveStruct.DamageCategory.STATUS:
		return false
	var ctx: EffectContext = EffectContext.new(attacker, null, move, null)
	return AbilitySystem.query_bool("on_status_ignores_abilities", ctx)


static func mycelium_goes_last(attacker: BattleBattler, move: MoveData) -> bool:
	return status_move_ignores_abilities(attacker, move)


static func quick_draw_wins_speed_tie(battler: BattleBattler) -> bool:
	var ctx: EffectContext = EffectContext.new(battler, null, null, null)
	return AbilitySystem.query_bool("on_speed_tie_win", ctx)


static func always_crits(attacker: BattleBattler, defender: BattleBattler) -> bool:
	if attacker == null or defender == null:
		return false
	var ctx: EffectContext = EffectContext.new(attacker, defender, null, null)
	ctx.target = defender
	return AbilitySystem.query_bool("on_always_crit", ctx)


static func move_makes_contact(attacker: BattleBattler, move: MoveData) -> bool:
	if move == null or not move.makes_contact:
		return false
	var ctx: EffectContext = EffectContext.new(attacker, null, move, null)
	if AbilitySystem.query_bool("on_removes_contact", ctx):
		return false
	return true


static func damp_blocks_explosion(blocker: BattleBattler, move: MoveData) -> bool:
	if move == null or not move.is_explosion:
		return false
	var ctx: EffectContext = EffectContext.new(blocker, null, move, null)
	return AbilitySystem.query_bool("on_blocks_explosion", ctx)


static func ignores_protect_contact(attacker: BattleBattler, move: MoveData) -> bool:
	if move == null or not move.makes_contact:
		return false
	var ctx: EffectContext = EffectContext.new(attacker, null, move, null)
	return AbilitySystem.query_bool("on_ignores_protect_contact", ctx)


static func corrosion_can_poison(attacker: BattleBattler) -> bool:
	var ctx: EffectContext = EffectContext.new(attacker, null, null, null)
	return AbilitySystem.query_bool("on_corrosion", ctx)


static func bypasses_ghost_immunity(attacker: BattleBattler, move: MoveData) -> bool:
	if move == null:
		return false
	var ctx: EffectContext = EffectContext.new(attacker, null, move, null)
	return AbilitySystem.query_bool("on_bypasses_ghost", ctx)


static func adjust_own_stage_change(battler: BattleBattler, amount: int) -> int:
	var ctx: EffectContext = EffectContext.new(battler, null, null, null)
	ctx.query_int = amount
	AbilitySystem.query("on_stage_change", ctx)
	return ctx.query_int


static func should_skip_turn(battler: BattleBattler) -> bool:
	if battler == null:
		return false
	var ctx: EffectContext = EffectContext.new(battler, null, null, null)
	return AbilitySystem.query_bool("on_skip_turn", ctx)


static func is_immune_to_weather_damage(battler: BattleBattler, weather: int) -> bool:
	if battler == null or battler.pokemon == null:
		return true
	var t1: PokemonData.Type = battler.pokemon.get_type_1()
	var t2: PokemonData.Type = battler.pokemon.get_type_2()
	match weather:
		WeatherId.WEATHER_SANDSTORM:
			if t1 == PokemonData.Type.TYPE_ROCK or t2 == PokemonData.Type.TYPE_ROCK:
				return true
			if t1 == PokemonData.Type.TYPE_GROUND or t2 == PokemonData.Type.TYPE_GROUND:
				return true
			if t1 == PokemonData.Type.TYPE_STEEL or t2 == PokemonData.Type.TYPE_STEEL:
				return true
		WeatherId.WEATHER_SNOW:
			if t1 == PokemonData.Type.TYPE_ICE or t2 == PokemonData.Type.TYPE_ICE:
				return true
		_:
			return true
	var ctx: EffectContext = EffectContext.new(battler, null, null, null)
	ctx.weather = weather
	return AbilitySystem.query_bool("on_weather_immunity", ctx)


static func prevents_escape(blocker: BattleBattler, runner: BattleBattler) -> bool:
	if blocker == null or runner == null or blocker.is_fainted() or runner.is_fainted():
		return false
	var ctx_run: EffectContext = EffectContext.new(runner, blocker, null, null)
	if AbilitySystem.query_bool("on_always_escape", ctx_run):
		return false
	var rt1: PokemonData.Type = runner.get_battle_type_1()
	var rt2: PokemonData.Type = runner.get_battle_type_2()
	if rt1 == PokemonData.Type.TYPE_GHOST or rt2 == PokemonData.Type.TYPE_GHOST:
		return false
	var ctx: EffectContext = EffectContext.new(blocker, runner, null, null)
	ctx.target = runner
	return AbilitySystem.query_bool("on_blocks_escape", ctx)


static func victory_star_active(battler: BattleBattler, battle: BattleManager = null) -> bool:
	if battler == null:
		return false
	var ctx: EffectContext = EffectContext.new(battler, null, null, battle)
	if AbilitySystem.query_bool("on_victory_star", ctx):
		return true
	if battle != null and battle.is_multi_battle():
		var ally: BattleBattler = get_ally(battler, battle)
		if ally != null and not ally.is_fainted():
			var ctx_a: EffectContext = EffectContext.new(ally, null, null, battle)
			if AbilitySystem.query_bool("on_victory_star", ctx_a):
				return true
	return false


## Compat: el multiplicador real de Rivalry está en on_power (rivalry.txt) vía power_multiplier.
## Esta API queda en 1.0 para no aplicar dos veces en DamageCalculator.
static func rivalry_multiplier(attacker: BattleBattler, defender: BattleBattler) -> float:
	if attacker == null or defender == null:
		return 1.0
	return 1.0


static func analytic_multiplier(attacker: BattleBattler, acted_after_target: bool) -> float:
	if attacker == null:
		return 1.0
	var ctx: EffectContext = EffectContext.new(attacker, null, null, null)
	ctx.acted_after_target = acted_after_target
	return AbilitySystem.query_float("on_analytic", ctx, 1.0)


static func stakeout_multiplier(attacker: BattleBattler, defender: BattleBattler) -> float:
	if attacker == null or defender == null:
		return 1.0
	var ctx: EffectContext = EffectContext.new(attacker, defender, null, null)
	ctx.target = defender
	ctx.target_just_switched = defender.just_switched_in
	return AbilitySystem.query_float("on_stakeout", ctx, 1.0)


static func supreme_overlord_multiplier(attacker: BattleBattler, battle: BattleManager) -> float:
	if attacker == null or battle == null:
		return 1.0
	var ctx: EffectContext = EffectContext.new(attacker, null, null, battle)
	var party: Array[PokemonInstance] = battle.player_party if attacker.is_player_side else battle.enemy_party
	var fainted: int = 0
	for mon: PokemonInstance in party:
		if mon != null and mon.is_fainted():
			fainted += 1
	ctx.query_int = mini(fainted, 5)
	return AbilitySystem.query_float("on_supreme_overlord", ctx, 1.0)


static func sand_force_active(battler: BattleBattler, move: MoveData, weather: int) -> float:
	if battler == null or move == null:
		return 1.0
	var ctx: EffectContext = EffectContext.new(battler, null, move, null)
	ctx.weather = weather
	return AbilitySystem.query_float("on_sand_force", ctx, 1.0)


static func solar_power_multiplier(battler: BattleBattler, category: MoveStruct.DamageCategory, weather: int) -> float:
	var ctx: EffectContext = EffectContext.new(battler, null, null, null)
	ctx.move_category = int(category)
	ctx.weather = weather
	return AbilitySystem.query_float("on_solar_power", ctx, 1.0)


static func hadron_orichalcum_multiplier(
	battler: BattleBattler,
	category: MoveStruct.DamageCategory,
	weather: int,
	terrain: int
) -> float:
	var ctx: EffectContext = EffectContext.new(battler, null, null, null)
	ctx.move_category = int(category)
	ctx.weather = weather
	ctx.terrain = terrain
	return AbilitySystem.query_float("on_engine_pulse", ctx, 1.0)


static func grass_pelt_multiplier(defender: BattleBattler, move: MoveData, terrain: int) -> float:
	if move == null:
		return 1.0
	var ctx: EffectContext = EffectContext.new(defender, null, move, null)
	ctx.terrain = terrain
	return AbilitySystem.query_float("on_grass_pelt", ctx, 1.0)


static func marvel_scale_multiplier(defender: BattleBattler, move: MoveData) -> float:
	if move == null:
		return 1.0
	var ctx: EffectContext = EffectContext.new(defender, null, move, null)
	return AbilitySystem.query_float("on_marvel_scale", ctx, 1.0)


## Deprecated: Technician vive en scripts/abilities/technician.txt (on_power).
## Se mantiene por compat; siempre 1.0 para no duplicar con power_multiplier.
static func technician_multiplier(_attacker: BattleBattler, _move: MoveData) -> float:
	return 1.0


static func aura_multiplier(
	_attacker: BattleBattler,
	_defender: BattleBattler,
	move_type: PokemonData.Type,
	battle: BattleManager
) -> float:
	if battle == null:
		return 1.0
	var mult: float = 1.0
	for b: BattleBattler in _all_actives(battle):
		if b == null or b.is_fainted():
			continue
		var c: EffectContext = EffectContext.new(b, null, null, battle)
		c.query_int = int(move_type)
		c.multiplier = 1.0
		AbilitySystem.query("on_aura", c)
		mult *= c.multiplier
	return mult


static func ruin_stat_multiplier(stat_owner: BattleBattler, stat: PokemonInstance.Stat, battle: BattleManager) -> float:
	if battle == null or stat_owner == null:
		return 1.0
	var mult: float = 1.0
	for b: BattleBattler in _all_actives(battle):
		if b == null or b.is_fainted() or b == stat_owner:
			continue
		var ctx: EffectContext = EffectContext.new(b, stat_owner, null, battle)
		ctx.query_int = int(stat)
		ctx.multiplier = 1.0
		AbilitySystem.query("on_ruin_stat", ctx)
		mult *= ctx.multiplier
	return mult


static func plus_minus_spatk_multiplier(battler: BattleBattler, ally: BattleBattler) -> float:
	if battler == null or ally == null or ally.is_fainted():
		return 1.0
	var ctx: EffectContext = EffectContext.new(battler, ally, null, null)
	ctx.target = ally
	return AbilitySystem.query_float("on_plus_minus", ctx, 1.0)


static func friend_guard_multiplier(defender: BattleBattler, ally: BattleBattler) -> float:
	if defender == null or ally == null or ally.is_fainted():
		return 1.0
	var ctx: EffectContext = EffectContext.new(ally, defender, null, null)
	return AbilitySystem.query_float("on_friend_guard", ctx, 1.0)


static func telepathy_blocks_ally_damage(defender: BattleBattler, attacker: BattleBattler) -> bool:
	if defender == null or attacker == null:
		return false
	if defender.is_player_side != attacker.is_player_side:
		return false
	var ctx: EffectContext = EffectContext.new(defender, attacker, null, null)
	return AbilitySystem.query_bool("on_telepathy", ctx)


static func battery_multiplier(attacker: BattleBattler, ally: BattleBattler, move: MoveData) -> float:
	if attacker == null or ally == null or move == null or ally.is_fainted():
		return 1.0
	var ctx: EffectContext = EffectContext.new(ally, attacker, move, null)
	return AbilitySystem.query_float("on_battery", ctx, 1.0)


static func power_spot_multiplier(attacker: BattleBattler, ally: BattleBattler) -> float:
	if attacker == null or ally == null or ally.is_fainted():
		return 1.0
	var ctx: EffectContext = EffectContext.new(ally, attacker, null, null)
	return AbilitySystem.query_float("on_power_spot", ctx, 1.0)


static func flower_gift_stat_multiplier(
	battler: BattleBattler,
	stat: PokemonInstance.Stat,
	weather: int,
	battle: BattleManager
) -> float:
	if battler == null:
		return 1.0
	var ctx: EffectContext = EffectContext.new(battler, null, null, battle)
	ctx.weather = weather
	ctx.query_int = int(stat)
	return AbilitySystem.query_float("on_flower_gift_stat", ctx, 1.0)


# ═══════════════════════════════════════════════════════════
# Secuencias que el BattleManager invoca por nombre
# ═══════════════════════════════════════════════════════════

static func try_protean(battler: BattleBattler, move: MoveData, battle: BattleManager) -> void:
	if battler == null or move == null or battle == null:
		return
	var ctx: EffectContext = EffectContext.new(battler, null, move, battle)
	await AbilitySystem.on_event("on_move_use", ctx)


static func try_magician(attacker: BattleBattler, defender: BattleBattler, battle: BattleManager) -> void:
	if attacker == null or defender == null or battle == null:
		return
	var ctx: EffectContext = EffectContext.new(attacker, defender, null, battle)
	ctx.target = defender
	await AbilitySystem.on_event("on_steal_item", ctx)


static func check_wimp_or_emergency(battler: BattleBattler, hp_before: int, battle: BattleManager) -> bool:
	if battler == null or battler.pokemon == null or battle == null or battler.is_fainted():
		return false
	var max_hp: int = battler.get_max_hp()
	if max_hp <= 0:
		return false
	var half: float = float(max_hp) / 2.0
	if float(hp_before) <= half or float(battler.pokemon.current_hp) > half:
		return false
	var ctx: EffectContext = EffectContext.new(battler, null, null, battle)
	ctx.query_bool = false
	await AbilitySystem.on_event("on_hp_half", ctx)
	return ctx.query_bool or ctx.blocked


static func try_booster_energy_style(
	battler: BattleBattler, weather: int, terrain: int, battle: BattleManager
) -> void:
	if battler == null or battle == null:
		return
	var ctx: EffectContext = EffectContext.new(battler, null, null, battle)
	ctx.weather = weather
	ctx.terrain = terrain
	await AbilitySystem.on_event("on_booster", ctx)


static func try_opportunist(
	battler: BattleBattler, foe: BattleBattler, stat: PokemonInstance.Stat, stages: int, battle: BattleManager
) -> void:
	if stages <= 0 or battler == null or foe == null or battle == null:
		return
	var ctx: EffectContext = EffectContext.new(battler, foe, null, battle)
	ctx.query_int = int(stat)
	ctx.stage_delta = stages
	await AbilitySystem.on_event("on_foe_stat_up", ctx)


static func try_cute_charm(_d: BattleBattler, _a: BattleBattler, _m: MoveData, _b: BattleManager) -> void:
	pass


static func try_perish_body(_d: BattleBattler, _a: BattleBattler, _m: MoveData, _b: BattleManager) -> void:
	pass


static func try_cursed_body(_d: BattleBattler, _a: BattleBattler, _m: MoveData, _b: BattleManager) -> void:
	pass


static func tick_perish(battler: BattleBattler, battle: BattleManager) -> void:
	if battler == null or battle == null:
		return
	var ctx: EffectContext = EffectContext.new(battler, null, null, battle)
	await AbilitySystem.on_event("on_perish_tick", ctx)


static func try_cud_chew(battler: BattleBattler, battle: BattleManager) -> void:
	if battler == null or battle == null:
		return
	var ctx: EffectContext = EffectContext.new(battler, null, null, battle)
	await AbilitySystem.on_event("on_cud_chew", ctx)


static func try_healer(battler: BattleBattler, ally: BattleBattler, battle: BattleManager) -> void:
	if battler == null or ally == null or battle == null:
		return
	var ctx: EffectContext = EffectContext.new(battler, ally, null, battle)
	await AbilitySystem.on_event("on_heal_ally", ctx)


static func try_symbiosis(battler: BattleBattler, ally: BattleBattler, battle: BattleManager) -> void:
	if battler == null or ally == null or battle == null:
		return
	var ctx: EffectContext = EffectContext.new(battler, ally, null, battle)
	await AbilitySystem.on_event("on_symbiosis", ctx)


static func try_receiver_or_alchemy(battler: BattleBattler, fainted: BattleBattler, battle: BattleManager) -> void:
	if battler == null or fainted == null or battle == null:
		return
	var ctx: EffectContext = EffectContext.new(battler, fainted, null, battle)
	await AbilitySystem.on_event("on_ally_faint", ctx)


static func try_curious_medicine(battler: BattleBattler, ally: BattleBattler, battle: BattleManager) -> void:
	if battler == null or battle == null:
		return
	var ctx: EffectContext = EffectContext.new(battler, ally, null, battle)
	await AbilitySystem.on_event("on_switch_in", ctx)


static func try_costar(battler: BattleBattler, ally: BattleBattler, battle: BattleManager) -> void:
	if battler == null or ally == null or battle == null:
		return
	var ctx: EffectContext = EffectContext.new(battler, ally, null, battle)
	await AbilitySystem.on_event("on_switch_in", ctx)


static func try_commander(battler: BattleBattler, ally: BattleBattler, battle: BattleManager) -> void:
	if battler == null or ally == null or battle == null:
		return
	var ctx: EffectContext = EffectContext.new(battler, ally, null, battle)
	await AbilitySystem.on_event("on_switch_in", ctx)


static func try_dancer(battler: BattleBattler, move: MoveData, original: BattleBattler, battle: BattleManager) -> void:
	if battler == null or move == null or battle == null:
		return
	var ctx: EffectContext = EffectContext.new(battler, original, move, battle)
	await AbilitySystem.on_event("on_dance", ctx)


static func redirect_single_target(
	actor: BattleBattler, target: BattleBattler, move: MoveData, battle: BattleManager
) -> BattleBattler:
	if actor == null or move == null or battle == null:
		return target
	for b: BattleBattler in _all_actives(battle):
		if b == null or b.is_fainted() or b.is_player_side == actor.is_player_side:
			continue
		var ctx: EffectContext = EffectContext.new(b, actor, move, battle)
		ctx.redirect_target = null
		AbilitySystem.query("on_redirect", ctx)
		if ctx.redirect_target != null:
			return ctx.redirect_target as BattleBattler
	return target


static func apply_early_bird_sleep(battler: BattleBattler) -> void:
	if battler == null or battler.pokemon == null:
		return
	var ctx: EffectContext = EffectContext.new(battler, null, null, null)
	AbilitySystem.query("on_sleep_applied", ctx)


static func check_infatuation_blocks_move(battler: BattleBattler, battle: BattleManager) -> bool:
	if battler == null or battle == null:
		return false
	var ctx: EffectContext = EffectContext.new(battler, null, null, battle)
	return AbilitySystem.query_bool("on_infatuation_block", ctx)


## Activa Illusion en silencio (sin Ability Bar). Disfraz = último del party no KO.
static func prepare_illusion(battler: BattleBattler, battle: BattleManager) -> bool:
	if battler == null or battler.pokemon == null or battle == null:
		return false
	if get_id(battler) != AbilityId.Id.ILLUSION:
		return false
	if battler.illusion_active:
		return true

	var party: Array[PokemonInstance] = (
		battle.player_party if battler.is_player_side else battle.enemy_party
	)
	var disguise: PokemonInstance = null
	for i: int in range(party.size() - 1, -1, -1):
		var mon: PokemonInstance = party[i]
		if mon == null or mon == battler.pokemon:
			continue
		if mon.is_fainted():
			continue
		disguise = mon
		break

	if disguise == null:
		battler.clear_illusion()
		return false

	battler.illusion_active = true
	battler.illusion_species_id = int(disguise.species_id)
	battler.illusion_nickname = disguise.get_display_name()
	battler.illusion_gender = disguise.gender
	if "shiny" in disguise:
		battler.illusion_shiny = bool(disguise.shiny)
	if "form_id" in disguise:
		battler.illusion_form_id = int(disguise.form_id)
	# Sin announce: el truco es que no se note al entrar
	battle.battler_appearance_changed.emit(battler.is_player_side)
	return true


## Solo al recibir daño real: anuncia, limpia disfraz y avisa a la UI.
static func break_illusion(battler: BattleBattler, battle: BattleManager) -> void:
	if battler == null or not battler.illusion_active or battle == null:
		return
	battler.clear_illusion()
	await battle.ability_announce(battler)
	if battle.has_signal("illusion_broken"):
		battle.illusion_broken.emit(battler.is_player_side)
	battle.battler_appearance_changed.emit(battler.is_player_side)
	battle.message.emit("¡La ilusión de %s se disipó!" % battler.get_display_name())
	await battle._wait(0.7)


static func _setup_imposter(battler: BattleBattler, opponent: BattleBattler, battle: BattleManager) -> void:
	## Imposter (habilidad): anuncia y transforma al entrar.
	await apply_transform(battler, opponent, battle, true)


## Transformación completa (movimiento Transform o habilidad Imposter).
## announce_ability: true solo para Imposter (barra de habilidad).
static func apply_transform(
	battler: BattleBattler,
	opponent: BattleBattler,
	battle: BattleManager,
	announce_ability: bool = false
) -> void:
	if battler == null or opponent == null or opponent.pokemon == null or battle == null:
		return
	if battler.pokemon == null:
		return
	if battler.is_transformed:
		if battle.has_method("_wait"):
			battle.message.emit("¡No surtirá efecto!")
			await battle._wait(0.55)
		return
	# No transformarse en alguien ya transformado / sin datos
	if opponent.is_transformed and opponent.transform_backup.is_empty():
		pass  # aún tiene species del disfraz; válido
	if announce_ability:
		await battle.ability_announce(battler)

	var src: PokemonInstance = opponent.pokemon
	var dst: PokemonInstance = battler.pokemon

	# Backup de identidad real (Ditto, etc.)
	var moves_copy: Array = []
	for slot: Variant in dst.moves:
		if slot is PokemonMoveSlot:
			var s: PokemonMoveSlot = slot as PokemonMoveSlot
			var c: PokemonMoveSlot = PokemonMoveSlot.new()
			c.move_id = s.move_id
			c.pp_ups = s.pp_ups
			c.current_pp = s.current_pp
			moves_copy.append(c)
	battler.transform_backup = {
		"species_id": dst.species_id,
		"form_id": dst.form_id if "form_id" in dst else 0,
		"ability_id": dst.ability_id,
		"moves": moves_copy,
		"max_hp": dst.max_hp,
		"current_hp": dst.current_hp,
	}

	# Conservar PS del usuario (Transform no cambia HP actual/máx)
	var keep_hp: int = dst.current_hp
	var keep_max: int = dst.max_hp

	dst.species_id = src.species_id
	if "form_id" in src and "form_id" in dst:
		dst.form_id = src.form_id
	dst.ability_id = src.ability_id

	# Movimientos independientes, 5 PP cada uno
	var new_moves: Array[PokemonMoveSlot] = []
	for slot2: Variant in src.moves:
		var src_slot: PokemonMoveSlot = slot2 as PokemonMoveSlot
		if src_slot == null:
			continue
		var mid: int = int(src_slot.move_id)
		if mid <= 0:
			continue
		var copy2: PokemonMoveSlot = PokemonMoveSlot.new()
		copy2.move_id = src_slot.move_id
		copy2.pp_ups = 0
		var md: MoveData = MoveDatabase.get_move(src_slot.move_id)
		var base_pp: int = md.pp if md != null else 5
		copy2.current_pp = mini(5, base_pp)
		new_moves.append(copy2)
	dst.moves = new_moves

	# Stages del objetivo
	battler.stage_attack = opponent.stage_attack
	battler.stage_defense = opponent.stage_defense
	battler.stage_sp_attack = opponent.stage_sp_attack
	battler.stage_sp_defense = opponent.stage_sp_defense
	battler.stage_speed = opponent.stage_speed
	battler.stage_accuracy = opponent.stage_accuracy
	battler.stage_evasion = opponent.stage_evasion

	# Tipos de combate = tipos del objetivo
	if battler.has_method("set_battle_types"):
		battler.set_battle_types(opponent.get_battle_type_1(), opponent.get_battle_type_2())

	battler.is_transformed = true
	battler.clear_illusion()

	# Stats de combate según nueva especie, pero HP intacto
	if dst.has_method("recalculate_stats"):
		dst.recalculate_stats()
	dst.max_hp = keep_max
	dst.current_hp = mini(keep_hp, keep_max)

	battle.message.emit("¡%s se transformó en %s!" % [
		battler.get_display_name(), opponent.get_display_name()
	])
	battle.battler_appearance_changed.emit(battler.is_player_side)
	if battle.has_method("_wait"):
		await battle._wait(0.85)


static func revert_transform(battler: BattleBattler) -> void:
	if battler == null or not battler.is_transformed:
		return
	if battler.pokemon == null:
		battler.is_transformed = false
		battler.transform_backup.clear()
		return
	var dst: PokemonInstance = battler.pokemon
	var bak: Dictionary = battler.transform_backup
	if bak.is_empty():
		battler.is_transformed = false
		return

	dst.species_id = bak.get("species_id", dst.species_id)
	if "form_id" in dst:
		dst.form_id = bak.get("form_id", dst.form_id)
	dst.ability_id = bak.get("ability_id", dst.ability_id)

	var moves_bak: Variant = bak.get("moves", null)
	if moves_bak is Array:
		dst.moves.clear()
		for slot3: Variant in moves_bak:
			if slot3 is PokemonMoveSlot:
				dst.moves.append(slot3 as PokemonMoveSlot)

	# Restaurar HP máximos reales; conservar ratio de PS actuales si es posible
	var old_max: int = int(bak.get("max_hp", dst.max_hp))
	var cur: int = dst.current_hp
	if dst.has_method("recalculate_stats"):
		dst.recalculate_stats()
	# Tras KO, current_hp es 0; tras salir del campo, restaurar max del mon real
	if old_max > 0:
		dst.max_hp = old_max
	if cur <= 0:
		dst.current_hp = 0
	else:
		dst.current_hp = mini(cur, dst.max_hp)

	if battler.has_method("clear_battle_types"):
		battler.clear_battle_types()

	battler.is_transformed = false
	battler.transform_backup.clear()
	# Reset stages al salir (salvo baton pass — el BM decide)


static func try_forecast(battler: BattleBattler, weather: int, battle: BattleManager) -> void:
	if battler == null or battle == null:
		return
	var ctx: EffectContext = EffectContext.new(battler, null, null, battle)
	ctx.weather = weather
	await AbilitySystem.on_event("on_weather", ctx)


static func try_flower_gift(battler: BattleBattler, weather: int, battle: BattleManager) -> void:
	if battler == null or battle == null:
		return
	var ctx: EffectContext = EffectContext.new(battler, null, null, battle)
	ctx.weather = weather
	await AbilitySystem.on_event("on_weather", ctx)


static func try_zen_mode(battler: BattleBattler, battle: BattleManager) -> void:
	if battler == null or battle == null:
		return
	var ctx: EffectContext = EffectContext.new(battler, null, null, battle)
	await AbilitySystem.on_event("on_hp_change", ctx)


static func try_shields_down(battler: BattleBattler, battle: BattleManager) -> void:
	if battler == null or battle == null:
		return
	var ctx: EffectContext = EffectContext.new(battler, null, null, battle)
	await AbilitySystem.on_event("on_hp_change", ctx)


static func shields_down_blocks_status(battler: BattleBattler) -> bool:
	return blocks_status(battler, PokemonInstance.Status.NONE)


static func try_zero_to_hero(battler: BattleBattler, battle: BattleManager) -> void:
	if battler == null or battle == null:
		return
	var ctx: EffectContext = EffectContext.new(battler, null, null, battle)
	await AbilitySystem.on_event("on_switch_out", ctx)


static func try_tera_shift(battler: BattleBattler, battle: BattleManager) -> void:
	if battler == null or battle == null:
		return
	var ctx: EffectContext = EffectContext.new(battler, null, null, battle)
	await AbilitySystem.on_event("on_switch_in", ctx)


static func try_teraform_zero(battler: BattleBattler, battle: BattleManager) -> void:
	if battler == null or battle == null:
		return
	var ctx: EffectContext = EffectContext.new(battler, null, null, battle)
	await AbilitySystem.on_event("on_switch_in", ctx)


static func revert_battle_forms(battler: BattleBattler) -> void:
	if battler == null:
		return
	if battler.has_method("clear_battle_types"):
		battler.clear_battle_types()


static func _all_actives(battle: BattleManager) -> Array[BattleBattler]:
	var out: Array[BattleBattler] = []
	if battle == null:
		return out
	if battle.has_method("get_all_actives"):
		for b: Variant in battle.get_all_actives():
			var bb: BattleBattler = b as BattleBattler
			if bb != null:
				out.append(bb)
		return out
	if "player" in battle and battle.player != null:
		out.append(battle.player as BattleBattler)
	if "enemy" in battle and battle.enemy != null:
		out.append(battle.enemy as BattleBattler)
	return out


# ═══════════════════════════════════════════════════════════
# API requerida por BattleManager / overworld / session
# ═══════════════════════════════════════════════════════════


static func try_poison_puppeteer(attacker: BattleBattler, defender: BattleBattler, battle: BattleManager) -> void:
	if attacker == null or defender == null or battle == null:
		return
	var ctx: EffectContext = EffectContext.new(attacker, defender, null, battle)
	ctx.target = defender
	await AbilitySystem.on_event("on_poison_applied", ctx)


static func wild_encounter_rate_multiplier(party: Array) -> float:
	var mult: float = 1.0
	for mon: Variant in party:
		var inst: PokemonInstance = mon as PokemonInstance
		if inst == null or inst.is_fainted():
			continue
		# Illuminate / Arena Trap etc. vía script on_encounter_rate
		# Sin battler de combate: consulta por ID de habilidad conocida en script path
		var id: AbilityId.Id = inst.ability_id
		if id == AbilityId.Id.ILLUMINATE:
			mult *= 2.0
		elif id == AbilityId.Id.ARENA_TRAP or id == AbilityId.Id.NO_GUARD:
			mult *= 2.0
		elif id == AbilityId.Id.SAND_VEIL or id == AbilityId.Id.SNOW_CLOAK:
			mult *= 1.0  # clima se aplica fuera
		elif id == AbilityId.Id.QUICK_FEET or id == AbilityId.Id.STENCH:
			mult *= 0.5
	return mult


static func try_pickup_after_battle(party: Array) -> Array:
	var results: Array = []
	for mon: Variant in party:
		var inst: PokemonInstance = mon as PokemonInstance
		if inst == null or inst.is_fainted():
			continue
		if inst.ability_id != AbilityId.Id.PICKUP:
			continue
		if inst.held_item != Items.ItemId.ITEM_NONE:
			continue
		if randf() >= 0.10:
			continue
		var item: Items.ItemId = Items.ItemId.ITEM_POTION
		inst.held_item = item
		results.append({"pokemon": inst, "item": item})
	return results


static func try_honey_gather_after_battle(party: Array) -> Array:
	var results: Array = []
	for mon: Variant in party:
		var inst: PokemonInstance = mon as PokemonInstance
		if inst == null or inst.is_fainted():
			continue
		if inst.ability_id != AbilityId.Id.HONEY_GATHER:
			continue
		if inst.held_item != Items.ItemId.ITEM_NONE:
			continue
		if randf() >= 0.15:
			continue
		var item: Items.ItemId = Items.ItemId.ITEM_POTION
		inst.held_item = item
		results.append({"pokemon": inst, "item": item})
	return results


static func try_ball_fetch(party: Array, ball_item: Items.ItemId = Items.ItemId.ITEM_NONE) -> bool:
	if ball_item == Items.ItemId.ITEM_NONE:
		return false
	for mon: Variant in party:
		var inst: PokemonInstance = mon as PokemonInstance
		if inst == null or inst.is_fainted():
			continue
		if inst.ability_id != AbilityId.Id.BALL_FETCH:
			continue
		if inst.held_item != Items.ItemId.ITEM_NONE:
			continue
		inst.held_item = ball_item
		return true
	return false


static func try_hospitality(battler: BattleBattler, ally: BattleBattler, battle: BattleManager) -> void:
	if battler == null or ally == null or battle == null:
		return
	var ctx: EffectContext = EffectContext.new(battler, ally, null, battle)
	await AbilitySystem.on_event("on_switch_in", ctx)


static func try_harvest(battler: BattleBattler, weather: int, battle: BattleManager) -> void:
	if battler == null or battle == null:
		return
	var ctx: EffectContext = EffectContext.new(battler, null, null, battle)
	ctx.weather = weather
	await AbilitySystem.on_event("on_end_turn", ctx)

static func _apply_form_change(
	battler: BattleBattler,
	battle: BattleManager,
	new_form_id: StringName,
	announce: bool = true
) -> bool:
	if battler == null or battler.pokemon == null or battle == null:
		return false
	if battler.pokemon.form_id == new_form_id:
		return false
	if announce:
		await battle.ability_announce(battler)
	var ok: bool = false
	if new_form_id == &"base" or new_form_id.is_empty():
		battler.pokemon.reset_form()
		ok = true
	else:
		ok = battler.pokemon.set_form(new_form_id)
	if not ok:
		return false
	battler.pokemon.recalculate_stats()
	battle.battler_appearance_changed.emit(battler.is_player_side)
	battle.message.emit("¡%s cambió de forma!" % battler.get_display_name())
	await battle._wait(0.55)
	return true



## Tras debilitar a un rival (Moxie, Beast Boost, etc.).
static func on_ko(attacker: BattleBattler, fainted: BattleBattler, battle: BattleManager) -> void:
	if attacker == null or battle == null or attacker.is_fainted():
		return
	var ctx: EffectContext = EffectContext.new(attacker, fainted, null, battle)
	ctx.target = fainted
	await AbilitySystem.on_event("on_ko", ctx)


## El debilitado puede reaccionar (Aftermath vía script on_faint, etc.).
static func on_faint(fainted: BattleBattler, killer: BattleBattler, battle: BattleManager) -> void:
	if fainted == null or battle == null:
		return
	var ctx: EffectContext = EffectContext.new(fainted, killer, null, battle)
	ctx.attacker = killer
	ctx.target = fainted
	await AbilitySystem.on_event("on_faint", ctx)


## Soul-Heart / similares: alguien se debilita en el campo.
static func on_any_faint(observer: BattleBattler, fainted: BattleBattler, battle: BattleManager) -> void:
	if observer == null or battle == null or observer.is_fainted():
		return
	var ctx: EffectContext = EffectContext.new(observer, fainted, null, battle)
	await AbilitySystem.on_event("on_any_faint", ctx)

## Pressure: +1 PP gastado por el movimiento del rival.
static func extra_pp_cost(defender: BattleBattler) -> int:
	if defender == null:
		return 0
	if has(defender, AbilityId.Id.PRESSURE):
		return 1
	# Campo: cualquier Pressure activo en el lado defensor
	return 0



## Magic Bounce / similar: el movimiento de estado se refleja.
static func reflects_status_move(defender: BattleBattler) -> bool:
	if defender == null:
		return false
	var ctx: EffectContext = EffectContext.new(defender, null, null, null)
	return AbilitySystem.query_bool("on_reflects_status_move", ctx)



## Unnerve en el campo: el bando rival no puede comer bayas.
static func unnerve_active(for_side_battler: BattleBattler, battle: BattleManager) -> bool:
	if for_side_battler == null or battle == null:
		return false
	for foe: BattleBattler in (battle.get_opponents(for_side_battler) if battle.has_method("get_opponents") else []):
		if foe != null and not foe.is_fainted() and has(foe, AbilityId.Id.UNNERVE):
			return true
	return false
