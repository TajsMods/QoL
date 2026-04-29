class_name TajsQolDataStore
extends RefCounted

const MODULE_ID := "TajemnikTV-QoL"

const FILE_STICKY_NOTES := "sticky_notes.json"
const FILE_GROUP_LOCKS := "group_locks.json"
const FILE_GROUP_PATTERNS := "group_patterns.json"
const FILE_COLOR_PICKER := "color_picker.json"

var _core: Variant
var _settings: Variant

func setup(core: Variant, settings: Variant) -> void:
    _core = core
    _settings = settings

func read_data(file_name: String, default_items: Variant) -> Variant:
    var payload = _read_payload(file_name, default_items)
    return payload.get("items", _duplicate(default_items))

func write_data(file_name: String, items: Variant, kind: String) -> void:
    var payload = {
        "meta": _make_meta(kind),
        "items": _duplicate(items)
    }
    _write_payload(file_name, payload)

func get_color_picker_proxy() -> RefCounted:
    return TajsQolDataStoreSettingsProxy.new(self)

func migrate_from_legacy() -> void:
    if _core == null or _core.storage == null or _settings == null:
        return
    _migrate_key_if_missing("tajs_qol.sticky_notes_data", FILE_STICKY_NOTES, [], "sticky_notes")
    _migrate_key_if_missing("tajs_qol.group_lock_data", FILE_GROUP_LOCKS, {}, "group_locks")
    _migrate_key_if_missing("tajs_qol.group_patterns", FILE_GROUP_PATTERNS, {}, "group_patterns")
    _migrate_key_if_missing("tajs_qol.color_picker", FILE_COLOR_PICKER, {}, "color_picker")
    _settings.set_migration_version("tajs_qol_storage_split", "1.0.0")

func _migrate_key_if_missing(key: String, file_name: String, default_items: Variant, kind: String) -> void:
    var path = _core.storage.get_data_path(MODULE_ID, file_name)
    if FileAccess.file_exists(path):
        return
    var legacy = _settings.get_value(key, _duplicate(default_items))
    write_data(file_name, legacy, kind)

func _read_payload(file_name: String, default_items: Variant) -> Dictionary:
    if _core == null or _core.storage == null:
        return {"meta": _make_meta(file_name.trim_suffix(".json")), "items": _duplicate(default_items)}
    var path = _core.storage.get_data_path(MODULE_ID, file_name)
    var payload = _core.storage.read_json(path, {})
    if not (payload is Dictionary):
        payload = {}
    if not payload.has("meta"):
        payload["meta"] = _make_meta(file_name.trim_suffix(".json"))
    if not payload.has("items"):
        payload["items"] = _duplicate(default_items)
    return payload

func _write_payload(file_name: String, payload: Dictionary) -> void:
    if _core == null or _core.storage == null:
        return
    var path = _core.storage.get_data_path(MODULE_ID, file_name)
    _core.storage.write_json(path, payload, true)

func _make_meta(kind: String) -> Dictionary:
    if _core != null and _core.storage != null and _core.storage.has_method("make_meta"):
        return _core.storage.make_meta(MODULE_ID, kind)
    return {
        "schema_version": "1.0.0",
        "module": MODULE_ID,
        "kind": kind
    }

func _duplicate(value: Variant) -> Variant:
    if value is Dictionary or value is Array:
        return value.duplicate(true)
    return value


class TajsQolDataStoreSettingsProxy:
    extends RefCounted
    var _store: TajsQolDataStore
    func _init(store: TajsQolDataStore) -> void:
        _store = store
    func get_dict(_key: String, default_value: Variant = null) -> Dictionary:
        var fallback: Dictionary = {}
        if default_value is Dictionary:
            fallback = default_value
        var data = _store.read_data(TajsQolDataStore.FILE_COLOR_PICKER, fallback)
        if data is Dictionary:
            return data.duplicate(true)
        return fallback
    func set_value(_key: String, value: Variant) -> void:
        var data: Dictionary = {}
        if value is Dictionary:
            data = value
        _store.write_data(TajsQolDataStore.FILE_COLOR_PICKER, data, "color_picker")
