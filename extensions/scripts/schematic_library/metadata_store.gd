extends RefCounted

const META_SCHEMA_VERSION := 1
const META_SUFFIX := ".meta.json"
const TEMP_SUFFIX := ".tmp"
const SCHEMATIC_DIR := "user://schematics"
const LIBRARY_STATE_PATH := "user://schematics/library_state.json"


func ensure_meta(schematic: String, data: Dictionary) -> Dictionary:
	var meta := load_meta(schematic)
	if meta.is_empty():
		meta = _build_default_meta(schematic, data)
		_save_meta_internal(schematic, meta)
		return meta
	if int(meta.get("schema_version", 0)) != META_SCHEMA_VERSION:
		meta = _migrate_meta(meta)
		_save_meta_internal(schematic, meta)
		return meta
	return _normalize_meta(meta)


func load_meta(schematic: String) -> Dictionary:
	var path := _get_meta_path(schematic)
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		return _normalize_meta(parsed)
	return {}


func save_meta(schematic: String, meta: Dictionary) -> bool:
	meta = _normalize_meta(meta)
	meta["schema_version"] = META_SCHEMA_VERSION
	meta["updated_at"] = int(Time.get_unix_time_from_system())
	return _save_meta_internal(schematic, meta)


func delete_meta(schematic: String) -> void:
	var path := _get_meta_path(schematic)
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)


func get_categories() -> Array[String]:
	var state := _load_library_state()
	return _normalize_string_list(state.get("categories", []))


func add_category(name: String) -> bool:
	var cleaned := name.strip_edges()
	if cleaned == "":
		return false
	var categories := get_categories()
	if categories.has(cleaned):
		return false
	categories.append(cleaned)
	categories.sort()
	return _save_library_state({"categories": categories})


func remove_category(name: String) -> bool:
	var cleaned := name.strip_edges()
	if cleaned == "":
		return false
	var categories := get_categories()
	if not categories.has(cleaned):
		return false
	categories.erase(cleaned)
	return _save_library_state({"categories": categories})


func get_schematic_path(schematic: String) -> String:
	return SCHEMATIC_DIR.path_join(schematic + ".dat")


func get_meta_path(schematic: String) -> String:
	return _get_meta_path(schematic)


func get_schematic_modified_time(schematic: String) -> int:
	var path := get_schematic_path(schematic)
	if FileAccess.file_exists(path):
		return FileAccess.get_modified_time(path)
	return 0


func _build_default_meta(schematic: String, _data: Dictionary) -> Dictionary:
	var created_at := get_schematic_modified_time(schematic)
	if created_at <= 0:
		created_at = int(Time.get_unix_time_from_system())
	return {
		"schema_version": META_SCHEMA_VERSION,
		"name": schematic,
		"description": "",
		"tags": [],
		"categories": [],
		"status": "WIP",
		"notes": "",
		"created_at": created_at,
		"updated_at": created_at,
		"extra": {}
	}


func _normalize_meta(meta: Dictionary) -> Dictionary:
	var normalized := meta.duplicate(true)
	normalized["schema_version"] = int(meta.get("schema_version", META_SCHEMA_VERSION))
	normalized["name"] = str(meta.get("name", ""))
	normalized["description"] = str(meta.get("description", ""))
	normalized["notes"] = str(meta.get("notes", ""))
	normalized["status"] = _normalize_status(str(meta.get("status", "WIP")))
	normalized["created_at"] = int(meta.get("created_at", 0))
	normalized["updated_at"] = int(meta.get("updated_at", normalized["created_at"]))
	normalized["tags"] = _normalize_string_list(meta.get("tags", []))
	normalized["categories"] = _normalize_string_list(meta.get("categories", []))
	if not (meta.get("extra", {}) is Dictionary):
		normalized["extra"] = {}
	else:
		normalized["extra"] = meta.get("extra", {})
	return normalized


func _normalize_string_list(value: Variant) -> Array[String]:
	var output: Array[String]
	if value is Array:
		for entry in value:
			var cleaned := str(entry).strip_edges()
			if cleaned != "":
				output.append(cleaned)
	elif value is String:
		for entry in str(value).split(",", false):
			var cleaned := entry.strip_edges()
			if cleaned != "":
				output.append(cleaned)
	return output


func _migrate_meta(meta: Dictionary) -> Dictionary:
	var migrated := _normalize_meta(meta)
	migrated["schema_version"] = META_SCHEMA_VERSION
	return migrated


func _normalize_status(status: String) -> String:
	var normalized := status.strip_edges().to_lower()
	match normalized:
		"ok", "works":
			return "OK"
		"meta":
			return "Meta"
		"meme":
			return "Meme"
		_:
			return "WIP"


func _save_meta_internal(schematic: String, meta: Dictionary) -> bool:
	_ensure_dir()
	var path := _get_meta_path(schematic)
	var temp_path := path + TEMP_SUFFIX
	var file := FileAccess.open(temp_path, FileAccess.WRITE)
	if file == null:
		return false
	var json_text := JSON.stringify(meta)
	file.store_string(json_text)
	file.close()
	var err := DirAccess.rename_absolute(temp_path, path)
	if err != OK:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)
		err = DirAccess.rename_absolute(temp_path, path)
	return err == OK


func _get_meta_path(schematic: String) -> String:
	return SCHEMATIC_DIR.path_join(schematic + META_SUFFIX)


func _ensure_dir() -> void:
	var dir := DirAccess.open("user://")
	if dir != null and not dir.dir_exists("schematics"):
		dir.make_dir("schematics")


func _load_library_state() -> Dictionary:
	if not FileAccess.file_exists(LIBRARY_STATE_PATH):
		return {}
	var file := FileAccess.open(LIBRARY_STATE_PATH, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		return parsed
	return {}


func _save_library_state(state: Dictionary) -> bool:
	_ensure_dir()
	var safe_state := {"categories": _normalize_string_list(state.get("categories", []))}
	var temp_path := LIBRARY_STATE_PATH + TEMP_SUFFIX
	var file := FileAccess.open(temp_path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(safe_state))
	file.close()
	var err := DirAccess.rename_absolute(temp_path, LIBRARY_STATE_PATH)
	if err != OK:
		if FileAccess.file_exists(LIBRARY_STATE_PATH):
			DirAccess.remove_absolute(LIBRARY_STATE_PATH)
		err = DirAccess.rename_absolute(temp_path, LIBRARY_STATE_PATH)
	return err == OK
