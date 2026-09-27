## Registra todos los comandos. Llamar una vez al iniciar el combate.
class_name EffectBootstrap
extends RefCounted

static var _registered: bool = false


static func register_all() -> void:
	if _registered:
		return
	_registered = true

	EffectParser.register_command("announce", _make_announce)
	EffectParser.register_command("chance", _make_chance)
	EffectParser.register_command("endchance", _make_endchance)
	EffectParser.register_command("if", _make_if)
	EffectParser.register_command("endif", _make_endif)
	EffectParser.register_command("status", _make_status)
	EffectParser.register_command("message", _make_message)
	EffectParser.register_command("lower_stat", _make_lower_stat)
	EffectParser.register_command("raise_stat", _make_raise_stat)


static func _make_announce(args: PackedStringArray) -> EffectCommand:
	return CmdAnnounce.new(args)

static func _make_chance(args: PackedStringArray) -> EffectCommand:
	return CmdChance.new(args, false)


static func _make_endchance(args: PackedStringArray) -> EffectCommand:
	return CmdChance.new(args, true)


static func _make_if(args: PackedStringArray) -> EffectCommand:
	return EffectCommand.new("if", args)


static func _make_endif(args: PackedStringArray) -> EffectCommand:
	return EffectCommand.new("endif", args)


static func _make_status(args: PackedStringArray) -> EffectCommand:
	return CmdStatus.new(args)


static func _make_message(args: PackedStringArray) -> EffectCommand:
	return CmdMessage.new(args)


static func _make_lower_stat(args: PackedStringArray) -> EffectCommand:
	return CmdLowerStat.new(args, "lower_stat")


static func _make_raise_stat(args: PackedStringArray) -> EffectCommand:
	return CmdLowerStat.new(args, "raise_stat")
