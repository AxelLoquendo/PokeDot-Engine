@tool
extends RefCounted
class_name AbilityEditorValidator

## Editor-side validation. AbilityData._validate() remains the source of truth;
## this adds repository-level checks that need the catalog.

func validate(data: AbilityData, catalog: AbilityEditorCatalog = null) -> Array[String]:
	var errors: Array[String] = []
	if data == null:
		errors.append("No hay una habilidad seleccionada.")
		return errors
	for message: String in data._validate():
		errors.append(message)
	if int(data.id) <= 0:
		errors.append("El ID debe ser mayor que cero (NONE está reservado).")
	if int(data.id) >= int(AbilityId.Id.COUNT):
		errors.append("El ID no puede ser COUNT ni superar el último AbilityId.Id.")
	if catalog != null:
		var duplicate_count := 0
		for record: Dictionary in catalog.records:
			var other := record.get("data") as AbilityData
			if other != null and not bool(record.get("trashed", false)) and int(other.id) == int(data.id):
				duplicate_count += 1
		if duplicate_count > 1:
			errors.append("El ID %d está duplicado en el catálogo." % int(data.id))
	if data.ai_rating < 0 or data.ai_rating > 10:
		errors.append("ai_rating debe estar entre 0 y 10.")
	return errors

func format_errors(errors: Array[String]) -> String:
	if errors.is_empty():
		return "✓ Válida"
	var lines := ["✗ %d problema(s):" % errors.size()]
	for error: String in errors:
		lines.append("• " + error)
	return "\n".join(lines)
