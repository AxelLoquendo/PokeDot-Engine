## Cambia la especie del battler (Species.SpeciesID).
## Uso:
##   change_species SPECIES_PALAFIN
##   change_species 964
##   change_species SPECIES_CASTFORM form=castform_rainy
##
## Conserva HP actual en proporción, recalcula stats, emite apariencia.
class_name CmdChangeSpecies
extends EffectCommand


func _init(p_args: PackedStringArray = []) -> void:
	super._init("change_species", p_args)


func execute(ctx: EffectContext) -> bool:
	if ctx.battle == null:
		return true
	var who: BattleBattler = ctx.user
	var form_override: String = ""
	for i: int in range(1, args.size()):
		var a: String = args[i]
		if a.to_lower().begins_with("target="):
			var mode: String = a.substr(7).to_lower()
			if mode == "target":
				who = ctx.target
		elif a.to_lower().begins_with("form="):
			form_override = a.substr(5)

	if who == null or who.pokemon == null:
		return true

	var species_arg: String = arg_string(0)
	var species_id: int = _parse_species(species_arg)
	if species_id <= 0:
		push_warning("CmdChangeSpecies: especie inválida '%s'" % species_arg)
		return true

	var mon: PokemonInstance = who.pokemon
	var old_max: int = mon.max_hp if mon.max_hp > 0 else 1
	var old_hp: int = mon.current_hp

	mon.species_id = species_id as Species.SpeciesID
	if not form_override.is_empty():
		if mon.has_method("set_form"):
			mon.set_form(StringName(form_override))
		else:
			mon.form_id = StringName(form_override)
	if mon.has_method("recalculate_stats"):
		mon.recalculate_stats()

	# Mantener proporción de HP
	if mon.max_hp > 0 and old_max > 0:
		var ratio: float = float(old_hp) / float(old_max)
		mon.current_hp = clampi(int(round(float(mon.max_hp) * ratio)), 1 if old_hp > 0 else 0, mon.max_hp)

	ctx.battle.battler_appearance_changed.emit(who.is_player_side)
	if ctx.battle.has_method("_emit_hp_battler"):
		ctx.battle._emit_hp_battler(who)
	elif ctx.battle.has_method("_emit_hp"):
		ctx.battle._emit_hp(who.is_player_side)

	ctx.battle.message.emit("¡%s cambió de forma!" % who.get_display_name())
	await ctx.battle._wait(0.55)
	return true


func _parse_species(arg: String) -> int:
	if arg.is_valid_int():
		return int(arg)
	var key: String = arg.to_upper()
	if not key.begins_with("SPECIES_"):
		key = "SPECIES_" + key
	if Species.SpeciesID.has(key):
		return int(Species.SpeciesID[key])
	return 0
