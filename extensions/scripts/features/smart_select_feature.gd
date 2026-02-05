extends RefCounted

const LOG_NAME := "TajemnikTV-QoL:SmartSelect"

var _core
var _enabled: bool = true


func setup(core) -> void:
    _core = core


func set_enabled(enabled: bool) -> void:
    _enabled = enabled


func is_enabled() -> bool:
    return _enabled


func select_all() -> void:
    if not _enabled:
        return
    if not is_instance_valid(Globals.desktop):
        return
    var windows_container = Globals.desktop.get_node_or_null("Windows")
    if windows_container == null:
        return
    var windows: Array[WindowContainer] = []
    for child in windows_container.get_children():
        if child is WindowContainer:
            windows.append(child)
    if windows.is_empty():
        return
    Globals.set_selection(windows, [])
    if _core != null and _core.has_method("notify"):
        _core.notify("check", "Selected %d nodes" % windows.size())
