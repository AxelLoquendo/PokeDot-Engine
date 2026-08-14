extends AbilityEffect
class_name StenchEffect

func on_hit(battler: Battler, target: Battler, move: MoveData) -> void:
	print("Stench activado por: ", battler)
	print("Objetivo: ", target)
	print("Movimiento: ", move)
