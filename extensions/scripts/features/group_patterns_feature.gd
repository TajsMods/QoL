extends RefCounted

const LOG_NAME := "TajemnikTV-QoL:GroupPatterns"

var _enabled: bool = true
var _color_picker_enabled: bool = true


func set_enabled(enabled: bool) -> void:
    _enabled = enabled
    _apply_to_existing_groups()

func set_color_picker_enabled(enabled: bool) -> void:
    _color_picker_enabled = enabled
    _apply_to_existing_groups()


func is_enabled() -> bool:
    return _enabled


func _apply_to_existing_groups() -> void:
    var tree = Engine.get_main_loop()
    if tree == null:
        return
    var nodes = tree.get_nodes_in_group("selectable")
    for node in nodes:
        if node.has_method("set_qol_patterns_enabled"):
            node.call("set_qol_patterns_enabled", _enabled)
        if node.has_method("set_qol_color_picker_enabled"):
            node.call("set_qol_color_picker_enabled", _color_picker_enabled)


func cleanup_legacy_group_style_keys() -> void:
    var tree = Engine.get_main_loop()
    if tree == null:
        return
    var nodes = tree.get_nodes_in_group("selectable")
    for node in nodes:
        if not node.has_method("qol_migrate_style_keys"):
            continue
        if node.has_method("get") and str(node.get("window")) != "group":
            continue
        node.call("qol_migrate_style_keys")
