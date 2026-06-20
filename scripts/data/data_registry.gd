extends RefCounted
class_name DataRegistry

const DEFAULT_DATA_PATH = "res://scripts/data/prototype_data.json"

var source_path := DEFAULT_DATA_PATH
var data: Dictionary = {}
var config: Dictionary = {}

func _init(path := DEFAULT_DATA_PATH) -> void:
	source_path = path

func load() -> bool:
	var file = FileAccess.open(source_path, FileAccess.READ)
	if file == null:
		push_error("%s not found" % source_path)
		data = {}
		config = {}
		return false
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("%s did not parse to a Dictionary" % source_path)
		data = {}
		config = {}
		return false
	data = parsed
	config = data.get("CONFIG", {})
	return true

func table(name: String) -> Array:
	return data.get(name, [])

func section(name: String) -> Dictionary:
	return data.get(name, {})

func find_by_id(table_name: String, id: String) -> Dictionary:
	for entry in table(table_name):
		if entry.get("id", "") == id:
			return entry
	return {}

