class_name EffectBootstrap
extends RefCounted

static var _registered: bool = false


static func register_all() -> void:
	if _registered:
		return
	_registered = true

	EffectParser.register_command("chance", _c_chance)
	EffectParser.register_command("endchance", _c_endchance)
	EffectParser.register_command("if", _c_if)
	EffectParser.register_command("else", _c_else)
	EffectParser.register_command("endif", _c_endif)
	EffectParser.register_command("for_each", _c_for_each)
	EffectParser.register_command("end_for", _c_end_for)
	EffectParser.register_command("announce", _c_announce)
	EffectParser.register_command("message", _c_message)
	EffectParser.register_command("lower_stat", _c_lower_stat)
	EffectParser.register_command("raise_stat", _c_raise_stat)
	EffectParser.register_command("status", _c_status)
	EffectParser.register_command("cure_status", _c_cure_status)
	EffectParser.register_command("infatuate", _c_infatuate)
	EffectParser.register_command("damage_percent", _c_damage_percent)
	EffectParser.register_command("heal_percent", _c_heal_percent)
	EffectParser.register_command("set_weather", _c_set_weather)
	EffectParser.register_command("set_terrain", _c_set_terrain)
	EffectParser.register_command("clear_screens", _c_clear_screens)
	EffectParser.register_command("change_form", _c_change_form)
	EffectParser.register_command("change_species", _c_change_species)
	EffectParser.register_command("setup_illusion", _c_setup_illusion)
	EffectParser.register_command("setup_imposter", _c_setup_imposter)
	EffectParser.register_command("set_ability", _c_set_ability)
	EffectParser.register_command("swap_ability", _c_swap_ability)
	EffectParser.register_command("set_meta", _c_set_meta)
	EffectParser.register_command("multiply", _c_multiply)
	EffectParser.register_command("immunity", _c_immunity)
	EffectParser.register_command("block", _c_block)
	EffectParser.register_command("block_status", _c_block_status)
	EffectParser.register_command("set", _c_set)
	EffectParser.register_command("add", _c_add)
	EffectParser.register_command("sub", _c_sub)
	EffectParser.register_command("mul", _c_mul)
	EffectParser.register_command("div", _c_div)
	EffectParser.register_command("set_move_type", _c_set_move_type)
	EffectParser.register_command("priority", _c_priority)

	var specials: Array[String] = [
		"download_boost", "trace_ability", "frisk", "anticipation", "forewarn",
		"hospitality", "curious_medicine", "delta_stream", "mimicry", "booster_energy",
		"teraform_zero", "forecast", "flower_gift", "zen_mode", "shields_down",
		"moody", "bad_dreams", "harvest", "healer", "cud_chew", "pickpocket",
		"tick_slow_start", "status_random", "flinch", "lower_evasion",
	]
	for s: String in specials:
		EffectParser.register_command(s, _c_special.bind(s))


static func _c_chance(a: PackedStringArray) -> EffectCommand:
	return CmdChance.new(a, false)
static func _c_endchance(a: PackedStringArray) -> EffectCommand:
	return CmdChance.new(a, true)
static func _c_if(a: PackedStringArray) -> EffectCommand:
	return EffectCommand.new("if", a)
static func _c_else(a: PackedStringArray) -> EffectCommand:
	return EffectCommand.new("else", a)
static func _c_endif(a: PackedStringArray) -> EffectCommand:
	return EffectCommand.new("endif", a)
static func _c_for_each(a: PackedStringArray) -> EffectCommand:
	return EffectCommand.new("for_each", a)
static func _c_end_for(a: PackedStringArray) -> EffectCommand:
	return EffectCommand.new("end_for", a)
static func _c_announce(a: PackedStringArray) -> EffectCommand:
	return CmdAnnounce.new(a)
static func _c_message(a: PackedStringArray) -> EffectCommand:
	return CmdMessage.new(a)
static func _c_lower_stat(a: PackedStringArray) -> EffectCommand:
	return CmdLowerStat.new(a, "lower_stat")
static func _c_raise_stat(a: PackedStringArray) -> EffectCommand:
	return CmdLowerStat.new(a, "raise_stat")
static func _c_status(a: PackedStringArray) -> EffectCommand:
	return CmdStatus.new(a)
static func _c_cure_status(a: PackedStringArray) -> EffectCommand:
	return CmdCureStatus.new(a)
static func _c_infatuate(a: PackedStringArray) -> EffectCommand:
	return CmdInfatuate.new(a)
static func _c_damage_percent(a: PackedStringArray) -> EffectCommand:
	return CmdDamagePercent.new(a)
static func _c_heal_percent(a: PackedStringArray) -> EffectCommand:
	return CmdHealPercent.new(a)
static func _c_set_weather(a: PackedStringArray) -> EffectCommand:
	return CmdSetWeather.new(a)
static func _c_set_terrain(a: PackedStringArray) -> EffectCommand:
	return CmdSetTerrain.new(a)
static func _c_clear_screens(a: PackedStringArray) -> EffectCommand:
	return CmdClearScreens.new(a)
static func _c_change_form(a: PackedStringArray) -> EffectCommand:
	return CmdChangeForm.new(a)
static func _c_change_species(a: PackedStringArray) -> EffectCommand:
	return CmdChangeSpecies.new(a)
static func _c_setup_illusion(a: PackedStringArray) -> EffectCommand:
	return CmdSetupIllusion.new(a)
static func _c_setup_imposter(a: PackedStringArray) -> EffectCommand:
	return CmdSetupImposter.new(a)
static func _c_set_ability(a: PackedStringArray) -> EffectCommand:
	return CmdSetAbility.new(a)
static func _c_swap_ability(a: PackedStringArray) -> EffectCommand:
	return CmdSwapAbility.new(a)
static func _c_set_meta(a: PackedStringArray) -> EffectCommand:
	return CmdSetMeta.new(a)
static func _c_multiply(a: PackedStringArray) -> EffectCommand:
	return CmdMultiply.new(a)
static func _c_immunity(a: PackedStringArray) -> EffectCommand:
	return CmdImmunity.new(a)
static func _c_block(a: PackedStringArray) -> EffectCommand:
	return CmdBlock.new(a, "block")
static func _c_block_status(a: PackedStringArray) -> EffectCommand:
	return CmdBlock.new(a, "block_status")
static func _c_set(a: PackedStringArray) -> EffectCommand:
	return CmdArith.new(a, "set")
static func _c_add(a: PackedStringArray) -> EffectCommand:
	return CmdArith.new(a, "add")
static func _c_sub(a: PackedStringArray) -> EffectCommand:
	return CmdArith.new(a, "sub")
static func _c_mul(a: PackedStringArray) -> EffectCommand:
	return CmdArith.new(a, "mul")
static func _c_div(a: PackedStringArray) -> EffectCommand:
	return CmdArith.new(a, "div")
static func _c_set_move_type(a: PackedStringArray) -> EffectCommand:
	return CmdSetMoveType.new(a)
static func _c_priority(a: PackedStringArray) -> EffectCommand:
	return CmdPriority.new(a)
static func _c_special(sname: String, a: PackedStringArray) -> EffectCommand:
	return CmdSpecial.new(sname, a)
