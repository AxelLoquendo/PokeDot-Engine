## Efectos de lado de campo: pantallas, hazards, mist, safeguard, tailwind, etc.
class_name CmdSide
extends EffectCommand


func _init(p_name: String = "side", p_args: PackedStringArray = []) -> void:
	super._init(p_name, p_args)

## Sintaxis:
##   side reflect 5
##   side light_screen 5
##   side aurora_veil 5
##   side mist 5
##   side safeguard 5
##   side tailwind 4
##   side lucky_chant 5
##   side spikes +1
##   side toxic_spikes +1
##   side stealth_rock
##   side sticky_web
##   side clear_hazards
##   side clear_screens
##   side clear_hazards both
## target implícito: lado del user (o del target si arg termina en opponent)

func execute(ctx: EffectContext) -> bool:
	if ctx == null or ctx.battle == null:
		return false
	var kind: String = arg_string(0).to_lower()
	if kind.is_empty():
		return false

	var for_opponent: bool = false
	for i: int in range(1, args.size()):
		var a: String = arg_string(i).to_lower()
		if a == "opponent" or a == "foe" or a == "rival":
			for_opponent = true

	# Siempre anclar al user; for_opponent hace el único flip en _side_for.
	# NO reasignar a ctx.target (doble inversión → hazards en el lado propio).
	var side: FieldSide = _side_for(ctx, ctx.user, for_opponent)
	if side == null:
		return false

	match kind:
		"reflect":
			var turns: int = arg_int(1, 5)
			if side.reflect_turns > 0:
				_msg(ctx, "¡Pero falló!")
				return true
			side.reflect_turns = turns
			_msg(ctx, "¡Se alzó un muro de reflejos!")
		"light_screen":
			var turns2: int = arg_int(1, 5)
			if side.light_screen_turns > 0:
				_msg(ctx, "¡Pero falló!")
				return true
			side.light_screen_turns = turns2
			_msg(ctx, "¡Se alzó una pantalla de luz!")
		"aurora_veil":
			var turns3: int = arg_int(1, 5)
			if side.aurora_veil_turns > 0:
				_msg(ctx, "¡Pero falló!")
				return true
			side.aurora_veil_turns = turns3
			_msg(ctx, "¡Se alzó un velo aurora!")
		"mist":
			var turns4: int = arg_int(1, 5)
			if side.mist_turns > 0:
				_msg(ctx, "¡No surtirá efecto!")
				return true
			side.mist_turns = turns4
			_msg(ctx, "¡El equipo quedó envuelto en neblina!")
		"safeguard":
			var turns5: int = arg_int(1, 5)
			if side.safeguard_turns > 0:
				_msg(ctx, "¡No surtirá efecto!")
				return true
			side.safeguard_turns = turns5
			_msg(ctx, "¡El equipo quedó protegido por Velo Sagrado!")
		"tailwind":
			var turns6: int = arg_int(1, 4)
			side.tailwind_turns = turns6
			_msg(ctx, "¡El Viento Afín sopla a favor del equipo!")
		"lucky_chant":
			var turns7: int = arg_int(1, 5)
			side.lucky_chant_turns = turns7
			_msg(ctx, "¡El Conjuro se alzó!")
		"spikes":
			if side.spikes_layers >= 3:
				_msg(ctx, "¡Pero falló!")
				return true
			side.spikes_layers += 1
			_msg(ctx, "¡Se esparcieron púas alrededor del equipo rival!")
		"toxic_spikes":
			if side.toxic_spikes_layers >= 2:
				_msg(ctx, "¡Pero falló!")
				return true
			side.toxic_spikes_layers += 1
			_msg(ctx, "¡Se esparcieron púas tóxicas alrededor del equipo rival!")
		"stealth_rock":
			if side.stealth_rock:
				_msg(ctx, "¡Pero falló!")
				return true
			side.stealth_rock = true
			_msg(ctx, "¡Aparecieron rocas puntiagudas alrededor del equipo rival!")
		"sticky_web":
			if side.sticky_web:
				_msg(ctx, "¡Pero falló!")
				return true
			side.sticky_web = true
			_msg(ctx, "¡Se tejió una red pegajosa!")
		"clear_hazards":
			var both: bool = arg_string(1).to_lower() == "both"
			if both:
				ctx.battle.player_side.clear_hazards()
				ctx.battle.enemy_side.clear_hazards()
			else:
				side.clear_hazards()
			_msg(ctx, "¡Se eliminaron los peligros del terreno!")
		"clear_screens":
			var both2: bool = arg_string(1).to_lower() == "both"
			if both2:
				ctx.battle.player_side.clear_screens()
				ctx.battle.enemy_side.clear_screens()
			else:
				side.clear_screens()
			_msg(ctx, "¡Se disiparon las pantallas!")
		_:
			push_warning("CmdSide: kind desconocido '%s'" % kind)
			return false
	return true


func _side_for(ctx: EffectContext, battler: BattleBattler, for_opponent: bool) -> FieldSide:
	if ctx.battle == null:
		return null
	var is_player: bool = true
	if battler != null:
		is_player = battler.is_player_side
	if for_opponent:
		is_player = not is_player
	return ctx.battle.player_side if is_player else ctx.battle.enemy_side


func _msg(ctx: EffectContext, text: String) -> void:
	if ctx.battle != null and ctx.battle.has_method("message"):
		ctx.battle.message.emit(text)
	ctx.add_message(text)
