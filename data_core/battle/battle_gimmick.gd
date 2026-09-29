extends RefCounted
class_name BattleGimmick
## Orquestador de mecánicas especiales: Mega, Z-Move, Dynamax, Terastal.
## Cada gimmick tiene su módulo; este decide cuál está activo y valida reglas.


enum Kind { NONE, MEGA, Z_MOVE, DYNAMAX, GIGANTAMAX, TERASTAL }


static func can_use(battle: Object, battler: BattleBattler, kind: Kind) -> bool:
	if battler == null or battler.is_fainted():
		return false
	match kind:
		Kind.MEGA:
			return BattleMega.can_mega(battle, battler)
		Kind.Z_MOVE:
			return BattleZMove.can_z(battle, battler)
		Kind.DYNAMAX, Kind.GIGANTAMAX:
			return BattleDynamax.can_dynamax(battle, battler)
		Kind.TERASTAL:
			return BattleTerastal.can_tera(battle, battler)
		_:
			return false


static func activate(battle: Object, battler: BattleBattler, kind: Kind) -> bool:
	if not can_use(battle, battler, kind):
		return false
	match kind:
		Kind.MEGA:
			return await BattleMega.activate(battle, battler)
		Kind.Z_MOVE:
			return await BattleZMove.activate(battle, battler)
		Kind.DYNAMAX, Kind.GIGANTAMAX:
			return await BattleDynamax.activate(battle, battler, kind == Kind.GIGANTAMAX)
		Kind.TERASTAL:
			return await BattleTerastal.activate(battle, battler)
		_:
			return false


static func end_of_battle_cleanup(battle: Object) -> void:
	for b: BattleBattler in BattleUtil.get_all_actives(battle):
		if b == null:
			continue
		BattleDynamax.force_end(battle, b)
		BattleTerastal.force_end(battle, b)
		BattleMega.force_end(battle, b)
