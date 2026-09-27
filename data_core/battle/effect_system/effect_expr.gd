## Evaluador aritmético para comandos.
## Soporta: números, + - * /, paréntesis, identificadores del contexto y vars.
## Ejemplos: 1.5   3 / 4   (2 + 1) * 0.5   hp_percent / 100   damage * 0.125
class_name EffectExpr
extends RefCounted


static func eval(expr: String, ctx: EffectContext) -> float:
	var tokens: PackedStringArray = _tokenize(expr.strip_edges())
	if tokens.is_empty():
		return 0.0
	var pos: Array[int] = [0]
	var value: float = _parse_expr(tokens, pos, ctx)
	return value


static func _tokenize(s: String) -> PackedStringArray:
	var out: PackedStringArray = []
	var i: int = 0
	while i < s.length():
		var c: String = s[i]
		if c == " " or c == "\t":
			i += 1
			continue
		if c in ["+", "-", "*", "/", "(", ")"]:
			out.append(c)
			i += 1
			continue
		if c == "<" or c == ">" or c == "=" or c == "!":
			var op: String = c
			if i + 1 < s.length() and s[i + 1] == "=":
				op += "="
				i += 1
			out.append(op)
			i += 1
			continue
		var start: int = i
		while i < s.length():
			var ch: String = s[i]
			if ch == " " or ch in ["+", "-", "*", "/", "(", ")", "<", ">", "=", "!"]:
				break
			i += 1
		out.append(s.substr(start, i - start))
	return out


static func _parse_expr(tokens: PackedStringArray, pos: Array[int], ctx: EffectContext) -> float:
	var left: float = _parse_term(tokens, pos, ctx)
	while pos[0] < tokens.size():
		var op: String = tokens[pos[0]]
		if op != "+" and op != "-":
			break
		pos[0] += 1
		var right: float = _parse_term(tokens, pos, ctx)
		if op == "+":
			left += right
		else:
			left -= right
	return left


static func _parse_term(tokens: PackedStringArray, pos: Array[int], ctx: EffectContext) -> float:
	var left: float = _parse_factor(tokens, pos, ctx)
	while pos[0] < tokens.size():
		var op: String = tokens[pos[0]]
		if op != "*" and op != "/":
			break
		pos[0] += 1
		var right: float = _parse_factor(tokens, pos, ctx)
		if op == "*":
			left *= right
		else:
			left = left / right if right != 0.0 else 0.0
	return left


static func _parse_factor(tokens: PackedStringArray, pos: Array[int], ctx: EffectContext) -> float:
	if pos[0] >= tokens.size():
		return 0.0
	var t: String = tokens[pos[0]]
	if t == "-":
		pos[0] += 1
		return -_parse_factor(tokens, pos, ctx)
	if t == "+":
		pos[0] += 1
		return _parse_factor(tokens, pos, ctx)
	if t == "(":
		pos[0] += 1
		var v: float = _parse_expr(tokens, pos, ctx)
		if pos[0] < tokens.size() and tokens[pos[0]] == ")":
			pos[0] += 1
		return v
	pos[0] += 1
	if t.is_valid_float():
		return t.to_float()
	return _resolve_ident(t, ctx)


static func _resolve_ident(name: String, ctx: EffectContext) -> float:
	var key: String = name.to_lower()
	if ctx.vars.has(key):
		return float(ctx.vars[key])
	match key:
		"multiplier":
			return ctx.multiplier
		"damage":
			return float(ctx.damage)
		"effectiveness":
			return ctx.effectiveness
		"hp_percent":
			return ctx.user_hp_percent() * 100.0
		"hp_ratio":
			return ctx.user_hp_percent()
		"max_hp":
			return float(ctx.user.get_max_hp()) if ctx.user != null else 0.0
		"current_hp":
			return float(ctx.user.get_current_hp()) if ctx.user != null else 0.0
		"power":
			return float(ctx.move.power) if ctx.move != null else 0.0
		"recoil_percent":
			return float(ctx.move.recoil_percent) if ctx.move != null else 0.0
		"drain_percent":
			return float(ctx.move.drain_percent) if ctx.move != null else 0.0
		"priority":
			return float(ctx.move.priority) if ctx.move != null else 0.0
		"secondary_chance":
			return float(ctx.move.secondary_chance) if ctx.move != null else 0.0
	push_warning("EffectExpr: identificador desconocido '%s'" % name)
	return 0.0
