extends RefCounted
class_name BattleMessage
## Emisión tipada de mensajes de combate.


static func say(battle: Object, text: String) -> void:
	if battle != null and battle.has_signal("message"):
		battle.message.emit(text)


static func say_wait(battle: Object, text: String, seconds: float = 0.6) -> void:
	say(battle, text)
	if battle != null and battle.has_method("_wait"):
		await battle._wait(seconds)
	else:
		await Engine.get_main_loop().create_timer(seconds).timeout
