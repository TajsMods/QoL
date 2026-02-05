extends Node

const LOG_NAME := "TajemnikTV-QoL:NotificationHistory"
const NotificationLogPanelScript = preload("res://mods-unpacked/TajemnikTV-QoL/extensions/scripts/ui/notification_log_panel.gd")

var _core
var _enabled: bool = true
var _max_entries: int = 20
var _panel: Control = null
var _pending: Array = []
var _signals_connected: bool = false
var _retry_count: int = 0


func setup(core) -> void:
    _core = core
    call_deferred("_connect_notifications")


func set_enabled(enabled: bool) -> void:
    _enabled = enabled
    if _panel:
        _panel.visible = enabled


func is_enabled() -> bool:
    return _enabled


func set_max_entries(value: int) -> void:
    _max_entries = maxi(1, value)
    if _panel and _panel.has_method("set_max_notifications"):
        _panel.call("set_max_notifications", _max_entries)


func on_hud_ready() -> void:
    if _panel != null:
        return
    if _core == null or _core.ui_manager == null:
        return
    # Try to find the extras container, with retry if not ready yet
    var extras_container = _get_extras_container()
    if extras_container == null:
        # Container not ready yet, retry after a frame
        if _retry_count < 10:
            _retry_count += 1
            if Engine.get_main_loop():
                Engine.get_main_loop().process_frame.connect(_on_retry_hud_ready, CONNECT_ONE_SHOT)
            return
    _setup_panel(extras_container)


func _on_retry_hud_ready() -> void:
    on_hud_ready()


func _setup_panel(extras_container: Node) -> void:
    _panel = NotificationLogPanelScript.new()
    _panel.call("set_max_notifications", _max_entries)
    _panel.visible = _enabled
    # Add to ExtrasButtons container (same as Puzzle/Core button) so they appear side by side
    if extras_container != null:
        extras_container.add_child(_panel)
        # Move to position 1 (after the Puzzle button at index 0)
        extras_container.move_child(_panel, 1)
    else:
        # Fallback to HUD zone if container not found after all retries
        # Use integer value 1 (TOP_RIGHT) instead of TajsCoreHudInjector.HudZone.TOP_RIGHT
        # to avoid issues with global class availability in shipped builds
        _core.ui_manager.inject_hud_widget(1, _panel, 10)
    if not _pending.is_empty():
        for entry in _pending:
            _panel.call("add_notification", entry.get("icon", ""), entry.get("text", ""))
        _pending.clear()


func open_panel() -> void:
    if _panel and _panel.has_method("_open_popup"):
        _panel.call("_open_popup")


func clear_panel() -> void:
    if _panel and _panel.has_method("clear_notifications"):
        _panel.call("clear_notifications")


func _connect_notifications() -> void:
    if _signals_connected:
        return
    if not is_instance_valid(Signals) or Signals == null:
        if Engine.get_main_loop():
            Engine.get_main_loop().process_frame.connect(_connect_notifications, CONNECT_ONE_SHOT)
        return
    if not Signals.notify.is_connected(_on_notification):
        Signals.notify.connect(_on_notification)
    _signals_connected = true


func _on_notification(icon: String, text: String) -> void:
    if not _enabled:
        return
    if _panel:
        _panel.call("add_notification", icon, text)
    else:
        _pending.append({"icon": icon, "text": text})


func _get_extras_container() -> Node:
    if Engine.get_main_loop() == null:
        return null
    var root = Engine.get_main_loop().root
    if root == null:
        return null
    return root.get_node_or_null("Main/HUD/Main/MainContainer/Overlay/ExtrasButtons/Container")
