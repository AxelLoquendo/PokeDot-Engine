
extends RefCounted
class_name BattleSetup
## Construye el campo al inicio del combate: actives, format, sides.
## No emite mensajes de intro (eso es BattleIntro / start_battle_intro).


static func build_field(
	battle: Object,
	player_pokemon: PokemonInstance,
	enemy_pokemon: PokemonInstance,
	party: Array[PokemonInstance] = [],
	enemy_trainer_party: Array[PokemonInstance] = [],
	p_format: int = 0,
	p_is_wild: bool = false
) -> void:
	EffectBootstrap.register_all()

	_set_prop(battle, "format", p_format)
	_set_prop(battle, "player_party", party)
	_set_prop(battle, "enemy_party", enemy_trainer_party)
	_set_prop(battle, "is_trainer_battle", (not p_is_wild) and (not enemy_trainer_party.is_empty()))
	_set_prop(battle, "is_running", true)

	if battle is BattleState:
		(battle as BattleState).reset_field_effects()
	else:
		# Compat BattleManager actual
		battle.weather = AbilityBattleEffect.weatherAbilityID.WEATHER_NONE
		battle.weather_turns = -1
		battle.terrain = 0
		battle.terrain_turns = 0
		battle.weather_primal = false
		battle.battle_turn_count = 0
		battle.is_underwater = false
		battle.is_dark_place = false
		battle.is_fishing = false
		if battle.get("_pending_player_actions") != null:
			battle._pending_player_actions.clear()
		if battle.get("exp_participants") != null:
			battle.exp_participants.clear()
		if battle.get("_exp_awarded_to") != null:
			battle._exp_awarded_to.clear()
		battle.player_side = FieldSide.new()
		battle.enemy_side = FieldSide.new()

	var player_slots: int = _slot_count(battle, true)
	var enemy_slots: int = _slot_count(battle, false)

	var player_actives: Array[BattleBattler] = []
	var enemy_actives: Array[BattleBattler] = []

	var preferred_player: Array = []
	if player_pokemon != null:
		preferred_player.append(player_pokemon)
	var p_leads: Array[PokemonInstance] = BattleUtil.pick_leads_from_party(
		preferred_player, party, player_slots
	)
	for i: int in range(player_slots):
		var mon: PokemonInstance = p_leads[i] if i < p_leads.size() else null
		var b: BattleBattler = BattleBattler.new()
		if mon != null:
			b.setup(mon, true, i)
			if battle is BattleManager:
				AbilityRuntime.prepare_illusion(b, battle)
		player_actives.append(b)

	var e_pool: Array = []
	if enemy_pokemon != null:
		e_pool.append(enemy_pokemon)
	for m: PokemonInstance in enemy_trainer_party:
		if m != null and m != enemy_pokemon:
			e_pool.append(m)
	var e_leads: Array[PokemonInstance] = BattleUtil.pick_leads_from_party(
		e_pool, enemy_trainer_party, enemy_slots
	)
	for j: int in range(enemy_slots):
		var emon: PokemonInstance = e_leads[j] if j < e_leads.size() else null
		var eb: BattleBattler = BattleBattler.new()
		if emon != null:
			eb.setup(emon, false, j)
			if battle is BattleManager:
				AbilityRuntime.prepare_illusion(eb, battle)
		enemy_actives.append(eb)

	_set_prop(battle, "player_actives", player_actives)
	_set_prop(battle, "enemy_actives", enemy_actives)
	_sync_primary(battle)


static func _slot_count(battle: Object, is_player: bool) -> int:
	if battle is BattleState:
		return (
			(battle as BattleState).player_slot_count()
			if is_player
			else (battle as BattleState).enemy_slot_count()
		)
	if battle.has_method("_player_slot_count"):
		return battle._player_slot_count() if is_player else battle._enemy_slot_count()
	return 1


static func _sync_primary(battle: Object) -> void:
	if battle is BattleState:
		(battle as BattleState).sync_primary_refs()
	elif battle.has_method("_sync_primary_refs"):
		battle._sync_primary_refs()
	else:
		var pa: Array = battle.player_actives
		var ea: Array = battle.enemy_actives
		battle.player = pa[0] if not pa.is_empty() else null
		battle.enemy = ea[0] if not ea.is_empty() else null


static func _set_prop(battle: Object, prop: String, value: Variant) -> void:
	battle.set(prop, value)
