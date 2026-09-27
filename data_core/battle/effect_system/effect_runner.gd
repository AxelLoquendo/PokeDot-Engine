## Ejecutor de bloques con chance / if. Soporta await en comandos.
class_name EffectRunner
extends RefCounted


static func run_block(commands: Array, ctx: EffectContext) -> void:
	var i: int = 0
	var skip_until_endchance: bool = false
	var skip_until_endif: bool = false
	var chance_depth: int = 0
	var if_depth: int = 0

	while i < commands.size():
		var cmd: EffectCommand = commands[i] as EffectCommand
		var name: String = cmd.command_name.to_lower()

		if name == "chance":
			chance_depth += 1
			await cmd.execute(ctx)
			var success: bool = bool(ctx.get_meta("last_chance_success", true))
			if not success:
				skip_until_endchance = true
			i += 1
			continue

		if name == "endchance":
			if chance_depth > 0:
				chance_depth -= 1
			skip_until_endchance = false
			i += 1
			continue

		if skip_until_endchance:
			i += 1
			continue

		if name == "if":
			if_depth += 1
			var condition_ok: bool = _eval_condition(cmd, ctx)
			if not condition_ok:
				skip_until_endif = true
			i += 1
			continue

		if name == "endif":
			if if_depth > 0:
				if_depth -= 1
			skip_until_endif = false
			i += 1
			continue

		if skip_until_endif:
			i += 1
			continue

		var cont: bool = await cmd.execute(ctx)
		if not cont:
			break
		i += 1


static func _eval_condition(cmd: EffectCommand, ctx: EffectContext) -> bool:
	var cond: String = cmd.arg_string(0).to_lower()
	match cond:
		"is_contact":
			return ctx.is_contact
		"hp_percent":
			var op: String = cmd.arg_string(1)
			var value: float = cmd.arg_float(2)
			var current: float = ctx.user_hp_percent() * 100.0
			return _compare(current, op, value)
		_:
			push_warning("EffectRunner: condición desconocida '%s'" % cond)
			return false


static func _compare(a: float, op: String, b: float) -> bool:
	match op:
		"<":
			return a < b
		"<=":
			return a <= b
		">":
			return a > b
		">=":
			return a >= b
		"==":
			return is_equal_approx(a, b)
		"!=":
			return not is_equal_approx(a, b)
	return false
