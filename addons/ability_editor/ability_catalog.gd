@tool
extends RefCounted
class_name AbilityEditorCatalog

## Presentation/query layer over AbilityEditorRepository. Keeps the dock free of
## filesystem and enum-discovery details.

const REPOSITORY_SCRIPT := preload("res://addons/ability_editor/ability_repository.gd")

var repository: AbilityEditorRepository
var records: Array[Dictionary] = []
var ability_names: Array[String] = []
var ability_values: Array[int] = []
var weather_names: Array[String] = []
var weather_values: Array[int] = []
var load_errors: Array[String] = []

func _init() -> void:
	repository = REPOSITORY_SCRIPT.new()
	_refresh_enum_lists()

func load() -> Array[Dictionary]:
	records = repository.load_all()
	load_errors = repository.get_errors()
	return records

func reload() -> Array[Dictionary]:
	records = repository.reload()
	load_errors = repository.get_errors()
	return records

func search(term: String, include_trash := true) -> Array[Dictionary]:
	var needle := term.strip_edges().to_lower()
	var result: Array[Dictionary] = []
	for record: Dictionary in records:
		if not include_trash and bool(record.get("trashed", false)):
			continue
		var data := record.get("data") as AbilityData
		var id_text := str(int(record.get("id", -1)))
		var enum_text := enum_name(int(record.get("id", -1)))
		var name_text := data.name_key if data != null else ""
		if needle.is_empty() or needle in id_text or needle in enum_text.to_lower() or needle in name_text.to_lower():
			result.append(record)
	return result

func enum_name(id_value: int) -> String:
	var index := ability_values.find(id_value)
	if index >= 0:
		return ability_names[index]
	return "ID_%d" % id_value

func weather_name(value: int) -> String:
	var index := weather_values.find(value)
	return weather_names[index] if index >= 0 else "WEATHER_%d" % value

func name_for(data: AbilityData) -> String:
	if data == null:
		return "(sin datos)"
	var enum_text := enum_name(int(data.id)).capitalize()
	return "%03d · %s" % [int(data.id), data.name_key if not data.name_key.is_empty() else enum_text]

func _refresh_enum_lists() -> void:
	ability_names.clear()
	ability_values.clear()
	for key in AbilityId.Id.keys():
		ability_names.append(str(key))
		ability_values.append(int(AbilityId.Id[key]))
	weather_names.clear()
	weather_values.clear()
	for key in WeatherEffect.WeatherID.keys():
		weather_names.append(str(key))
		weather_values.append(int(WeatherEffect.WeatherID[key]))
