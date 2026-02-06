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
    var windows: Array[WindowContainer] = []
    for node in Globals.desktop.get_tree().get_nodes_in_group("selectable"):
        if node is WindowContainer:
            windows.append(node)

    var notes_selected := 0
    var sticky_notes = _get_sticky_note_manager()
    if sticky_notes != null and sticky_notes.has_method("select_all_notes"):
        notes_selected = int(sticky_notes.call("select_all_notes"))

    if windows.is_empty() and notes_selected <= 0:
        return
    Globals.set_selection(windows, [])

    if notes_selected > 0 and _core != null and _core.has_method("notify"):
        _core.notify("check", "Selected %d nodes and %d notes" % [windows.size(), notes_selected])
        return

    if _core != null and _core.has_method("notify"):
        _core.notify("check", "Selected %d nodes" % windows.size())


func _get_sticky_note_manager():
    if _core != null and _core.has_method("get_extended_global"):
        return _core.get_extended_global("sticky_note_manager", null)
    if Engine.has_meta("TajsCore"):
        var core = Engine.get_meta("TajsCore")
        if core != null and core.has_method("get_extended_global"):
            return core.get_extended_global("sticky_note_manager", null)
    return null
