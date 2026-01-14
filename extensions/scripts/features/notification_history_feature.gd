extends Node

const LOG_NAME := "TajemnikTV-QoL:NotificationHistory"
const NotificationLogPanelScript = preload("res://mods-unpacked/TajemnikTV-QoL/extensions/scripts/ui/notification_log_panel.gd")

var _core
var _enabled: bool = true
var _max_entries: int = 20
var _panel: Control = null
var _pending: Array = []
var _signals_connected: bool = false


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
	_panel = NotificationLogPanelScript.new()
	_panel.call("set_max_notifications", _max_entries)
	_panel.visible = _enabled
	_core.ui_manager.inject_hud_widget(TajsCoreHudInjector.HudZone.TOP_RIGHT, _panel, 10)
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
