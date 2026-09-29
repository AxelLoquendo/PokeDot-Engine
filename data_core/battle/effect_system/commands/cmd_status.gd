## Aplica un estado no volátil.
## Uso: status BURN
##      status PARALYSIS target=attacker
##
## Estados: BURN POISON TOXIC PARALYSIS SLEEP FREEZE
## target= user | target | attacker | opponent
## Por defecto en on_hit_by: attacker (quien golpeó al dueño de la habilidad).
class_name CmdStatus
extends EffectCommand

const STATUS_MAP: Dictionary = {
	"burn": PokemonInstance.Status.BURN,
	"poison": PokemonInstance.Status.POISON,
	"toxic": PokemonInstance.Status.TOXIC,
	"paralysis": PokemonInstance.Status.PARALYSIS,
	"paralyze": PokemonInstance.Status.PARALYSIS,
	"sleep": PokemonInstance.Status.SLEEP,
	"freeze": PokemonInstance.Status.FREEZE,
}


func _init(p_args: PackedStringArray = []) -> void:
	super._init("status", p_args)


func execute(ctx: EffectContext) -> bool:
	if ctx.battle == null:
		return true

	var status_key: String = arg_string(0).to_lower()
	if not STATUS_MAP.has(status_key):
		push_warning("CmdStatus: estado desconocido '%s'" % status_key)
		return true

	var target_mode: String = "attacker"
	for i: int in range(1, args.size()):
		var a: String = args[i].to_lower()
		if a.begins_with("target="):
			target_mode = a.substr(7)

	var who: BattleBattler = _resolve_target(ctx, target_mode)
	var source: BattleBattler = ctx.user
	if who == null or who.is_fainted() or source == null:
		return true

	var status: PokemonInstance.Status = STATUS_MAP[status_key] as PokemonInstance.Status
	# Solo habilidades abren Ability Bar al aplicar estado
	if ctx.source_type == EffectContext.SourceType.ABILITY:
		await ctx.battle.ability_announce(source)
	await ctx.battle.ability_apply_status(who, status, source)
	return true


func _resolve_target(ctx: EffectContext, mode: String) -> BattleBattler:
	match mode:
		"user":
			return ctx.user
		"target":
			return ctx.target
		"attacker":
			return ctx.attacker if ctx.attacker != null else ctx.target
		"opponent", "foe":
			return ctx.target
		_:
			return ctx.attacker if ctx.attacker != null else ctx.target
