@tool
extends RefCounted

class_name MoveEditorValidator

func validate(data: MoveData) -> Array[String]:
	var errors: Array[String] = []
	if data == null:
		return ["No hay un movimiento seleccionado."]
	errors.append_array(data._validate())
	if data.min_hits > data.max_hits:
		errors.append("min_hits no puede ser mayor que max_hits.")
	if data.min_hits < 1 or data.max_hits < 1:
		errors.append("Los golpes mínimos y máximos deben ser mayores que cero.")
	if data.accuracy < 0 or data.accuracy > 100:
		errors.append("accuracy debe estar entre 0 y 100.")
	if data.pp < 1:
		errors.append("pp debe ser mayor que cero.")
	if data.secondary_chance < 0 or data.secondary_chance > 100:
		errors.append("secondary_chance debe estar entre 0 y 100.")
	if data.drain_percent < 0 or data.drain_percent > 100:
		errors.append("drain_percent debe estar entre 0 y 100.")
	if data.recoil_percent < 0 or data.recoil_percent > 100:
		errors.append("recoil_percent debe estar entre 0 y 100.")
	return errors

func format_errors(errors: Array[String]) -> String:
	if errors.is_empty():
		return "✓ MoveData válido"
	return "✗ %d problema(s):\n• %s" % [errors.size(), "\n• ".join(errors)]
