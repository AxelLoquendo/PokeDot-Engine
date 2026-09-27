class_name EffectBootstrap
extends RefCounted

static var _registered: bool = false


static func register_all() -> void:
	if _registered:
		return
	_registered = true

	# Flujo
	_reg("chance", _make_chance)
	_reg("endchance", _make_endchance)
	_reg("if", _make_tag.bind("if"))
	_reg("else", _make_tag.bind("else"))
	_reg("endif", _make_tag.bind("endif"))
	_reg("for_each", _make_tag.bind("for_each"))
	_reg("end_for", _make_tag.bind("end_for"))

	# Presentación
	_reg("announce", _make_announce)
	_reg("message", _make_message)

	# Stats / estados / PS
	_reg("lower_stat", _make_lower_stat)
	_reg("raise_stat", _make_raise_stat)
	_reg("status", _make_status)
	_reg("cure_status", _make_cure_status)
	_reg("infatuate", _make_infatuate)
	_reg("damage_percent", _make_damage_percent)
	_reg("heal_percent", _make_heal_percent)

	# Campo
	_reg("set_weather", _make_set_weather)
	_reg("set_terrain", _make_set_terrain)
	_reg("clear_screens", _make_clear_screens)

	# Identidad / formas
	_reg("change_form", _make_change_form)
	_reg("change_species", _make_change_species)
	_reg("setup_illusion", _make_setup_illusion)
	_reg("setup_imposter", _make_setup_imposter)
	_reg("set_ability", _make_set_ability)
	_reg("swap_ability", _make_swap_ability)
	_reg("set_meta", _make_set_meta)


static func _reg(name: String, factory: Callable) -> void:
	EffectParser.register_command(name, factory)


static func _make_chance(args: PackedStringArray) -> EffectCommand:
	return CmdChance.new(args, false)

static func _make_endchance(args: PackedStringArray) -> EffectCommand:
	return CmdChance.new(args, true)

static func _make_tag(tag: String, args: PackedStringArray) -> EffectCommand:
	return EffectCommand.new(tag, args)

static func _make_announce(args: PackedStringArray) -> EffectCommand:
	return CmdAnnounce.new(args)

static func _make_message(args: PackedStringArray) -> EffectCommand:
	return CmdMessage.new(args)

static func _make_lower_stat(args: PackedStringArray) -> EffectCommand:
	return CmdLowerStat.new(args, "lower_stat")

static func _make_raise_stat(args: PackedStringArray) -> EffectCommand:
	return CmdLowerStat.new(args, "raise_stat")

static func _make_status(args: PackedStringArray) -> EffectCommand:
	return CmdStatus.new(args)

static func _make_cure_status(args: PackedStringArray) -> EffectCommand:
	return CmdCureStatus.new(args)

static func _make_infatuate(args: PackedStringArray) -> EffectCommand:
	return CmdInfatuate.new(args)

static func _make_damage_percent(args: PackedStringArray) -> EffectCommand:
	return CmdDamagePercent.new(args)

static func _make_heal_percent(args: PackedStringArray) -> EffectCommand:
	return CmdHealPercent.new(args)

static func _make_set_weather(args: PackedStringArray) -> EffectCommand:
	return CmdSetWeather.new(args)

static func _make_set_terrain(args: PackedStringArray) -> EffectCommand:
	return CmdSetTerrain.new(args)

static func _make_clear_screens(args: PackedStringArray) -> EffectCommand:
	return CmdClearScreens.new(args)

static func _make_change_form(args: PackedStringArray) -> EffectCommand:
	return CmdChangeForm.new(args)

static func _make_change_species(args: PackedStringArray) -> EffectCommand:
	return CmdChangeSpecies.new(args)

static func _make_setup_illusion(args: PackedStringArray) -> EffectCommand:
	return CmdSetupIllusion.new(args)

static func _make_setup_imposter(args: PackedStringArray) -> EffectCommand:
	return CmdSetupImposter.new(args)

static func _make_set_ability(args: PackedStringArray) -> EffectCommand:
	return CmdSetAbility.new(args)

static func _make_swap_ability(args: PackedStringArray) -> EffectCommand:
	return CmdSwapAbility.new(args)

static func _make_set_meta(args: PackedStringArray) -> EffectCommand:
	return CmdSetMeta.new(args)
