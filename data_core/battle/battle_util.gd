extends RefCounted
class_name BattleUtil
## Helpers puros de campo: slots, aliados, rivales, targets, reservas.
## No modifica estado salvo helpers de lectura sobre BattleState / BattleManager.


static func player_battler_at(battle: Object, slot: int) -> BattleBattler:
	var actives: Array = _player_actives(battle)
	if slot < 0 or slot >= actives.size():
		return null
	var b: BattleBattler = actives[slot]
	if b == null or b.pokemon == null:
		return null
	return b


static func enemy_battler_at(battle: Object, slot: int) -> BattleBattler:
	var actives: Array = _enemy_actives(battle)
	if slot < 0 or slot >= actives.size():
		return null
	var b: BattleBattler = actives[slot]
	if b == null or b.pokemon == null:
		return null
	return b


static func get_ally(battle: Object, battler: BattleBattler) -> BattleBattler:
	if battler == null:
		return null
	var actives: Array = (
		_player_actives(battle) if battler.is_player_side else _enemy_actives(battle)
	)
	for b: BattleBattler in actives:
		if b != null and b != battler and b.pokemon != null and not b.is_fainted():
			return b
	return null


static func get_opponents(battle: Object, battler: BattleBattler) -> Array[BattleBattler]:
	var result: Array[BattleBattler] = []
	if battler == null:
		return result
	var actives: Array = (
		_enemy_actives(battle) if battler.is_player_side else _player_actives(battle)
	)
	for b: BattleBattler in actives:
		if b != null and b.pokemon != null and not b.is_fainted():
			result.append(b)
	return result



static func get_all_actives(battle: Object) -> Array[BattleBattler]:
	var result: Array[BattleBattler] = []
	for b: BattleBattler in _player_actives(battle):
		if b != null:
			result.append(b)
	for b2: BattleBattler in _enemy_actives(battle):
		if b2 != null:
			result.append(b2)
	return result


static func get_side_actives(battle: Object, is_player_side: bool) -> Array[BattleBattler]:
	return _player_actives(battle) if is_player_side else _enemy_actives(battle)

static func side_has_conscious(battle: Object, is_player_side: bool) -> bool:
	var actives: Array = (
		_player_actives(battle) if is_player_side else _enemy_actives(battle)
	)
	for b: BattleBattler in actives:
		if b != null and b.pokemon != null and not b.is_fainted():
			return true
	return false


static func party_has_conscious(battle: Object, is_player_side: bool) -> bool:
	var party: Array = _party(battle, is_player_side)
	for mon: PokemonInstance in party:
		if mon != null and not mon.is_fainted():
			return true
	return false


static func party_has_reserve(battle: Object, is_player_side: bool) -> bool:
	var party: Array = _party(battle, is_player_side)
	var actives: Array = (
		_player_actives(battle) if is_player_side else _enemy_actives(battle)
	)
	for mon: PokemonInstance in party:
		if mon == null or mon.is_fainted():
			continue
		var on_field: bool = false
		for b: BattleBattler in actives:
			if b != null and b.pokemon == mon:
				on_field = true
				break
		if not on_field:
			return true
	return false


static func first_reserve(battle: Object, is_player_side: bool) -> PokemonInstance:
	var party: Array = _party(battle, is_player_side)
	var actives: Array = (
		_player_actives(battle) if is_player_side else _enemy_actives(battle)
	)
	for mon: PokemonInstance in party:
		if mon == null or mon.is_fainted():
			continue
		var on_field: bool = false
		for b: BattleBattler in actives:
			if b != null and b.pokemon == mon:
				on_field = true
				break
		if not on_field:
			return mon
	return null


static func pick_leads_from_party(
	preferred: Array,  ## Array[PokemonInstance] o compatible
	party: Array,
	slots: int
) -> Array[PokemonInstance]:
	var leads: Array[PokemonInstance] = []
	var used: Dictionary = {}
	for item: Variant in preferred:
		if not (item is PokemonInstance):
			continue
		var mon: PokemonInstance = item as PokemonInstance
		if mon == null or mon.is_fainted():
			continue
		if used.has(mon.get_instance_id()):
			continue
		leads.append(mon)
		used[mon.get_instance_id()] = true
		if leads.size() >= slots:
			return leads
	for item2: Variant in party:
		if not (item2 is PokemonInstance):
			continue
		var mon2: PokemonInstance = item2 as PokemonInstance
		if mon2 == null or mon2.is_fainted():
			continue
		if used.has(mon2.get_instance_id()):
			continue
		leads.append(mon2)
		used[mon2.get_instance_id()] = true
		if leads.size() >= slots:
			break
	return leads


## Resuelve targets de un movimiento según formato y target_slot de la acción.
## target_slot: -1 auto, -2 aliado, 0/1 slot rival concreto.
static func resolve_move_targets(
	battle: Object,
	actor: BattleBattler,
	move: MoveData,
	target_slot: int = -1
) -> Array[BattleBattler]:
	var targets: Array[BattleBattler] = []
	if actor == null or move == null:
		return targets

	# Movimientos de campo / self: el actor es el único “target” lógico.
	# (La resolución de efecto decide si aplica a lado/campo.)
	if target_slot == -2:
		var ally: BattleBattler = get_ally(battle, actor)
		if ally != null:
			targets.append(ally)
		return targets

	var opponents: Array[BattleBattler] = get_opponents(battle, actor)
	if opponents.is_empty():
		return targets

	if target_slot >= 0:
		for o: BattleBattler in opponents:
			if o.slot_index == target_slot:
				targets.append(o)
				return targets
		# Slot inválido → primer rival vivo
		targets.append(opponents[0])
		return targets

	# Auto: primer rival vivo (single / default)
	targets.append(opponents[0])
	return targets


static func is_multi_battle(battle: Object) -> bool:
	if battle is BattleState:
		return (battle as BattleState).is_multi_battle()
	if battle.get("format") != null:
		return int(battle.format) != 0
	return false


# ─── acceso flexible a BattleManager o BattleState ─────────────────

static func _player_actives(battle: Object) -> Array[BattleBattler]:
	var result: Array[BattleBattler] = []
	var raw: Variant = (
		(battle as BattleState).player_actives if battle is BattleState
		else battle.get("player_actives")
	)
	if raw is Array:
		for item: Variant in raw as Array:
			if item is BattleBattler:
				result.append(item as BattleBattler)
	return result


static func _enemy_actives(battle: Object) -> Array[BattleBattler]:
	var result: Array[BattleBattler] = []
	var raw: Variant = (
		(battle as BattleState).enemy_actives if battle is BattleState
		else battle.get("enemy_actives")
	)
	if raw is Array:
		for item: Variant in raw as Array:
			if item is BattleBattler:
				result.append(item as BattleBattler)
	return result


static func _party(battle: Object, is_player_side: bool) -> Array[PokemonInstance]:
	var result: Array[PokemonInstance] = []
	var raw: Variant
	if battle is BattleState:
		raw = (battle as BattleState).get_party(is_player_side)
	else:
		raw = battle.player_party if is_player_side else battle.enemy_party
	if raw is Array:
		for item: Variant in raw as Array:
			if item is PokemonInstance:
				result.append(item as PokemonInstance)
	return result
