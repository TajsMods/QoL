extends Node

const LOG_NAME := "TajemnikTV-QoL:BreachThreat"

var _core
var _safe_ops

var _enabled: bool = true
var _deescalation_enabled: bool = true
var _threshold: int = 3
var _deescalation_threshold: int = 5
var _escalation_cooldown: int = 10

var _success_streak: Dictionary = {}
var _failure_streak: Dictionary = {}
var _cooldown_remaining: Dictionary = {}


func setup(core) -> void:
    _core = core
    _safe_ops = _core.get("safe_ops") if _core != null else null


func _ready() -> void:
    _connect_signals()


func set_enabled(enabled: bool) -> void:
    _enabled = enabled


func set_deescalation_enabled(enabled: bool) -> void:
    _deescalation_enabled = enabled


func set_threshold(threshold: int) -> void:
    _threshold = max(1, threshold)


func set_deescalation_threshold(threshold: int) -> void:
    _deescalation_threshold = max(1, threshold)


func set_escalation_cooldown(cooldown: int) -> void:
    _escalation_cooldown = max(0, cooldown)


func _connect_signals() -> void:
    if Signals != null and Signals.has_signal("breached"):
        _safe_connect(Signals.breached, Callable(self , "_on_breach_success"))
    else:
        _log_warn("Signals.breached not found; auto breach escalation disabled.")


func _on_breach_success(window) -> void:
    if not _enabled:
        return
    if window == null:
        return
    if not window.has_method("get_level") or not window.has_method("get_max_level") or not window.has_method("level_up"):
        _log_warn("Window missing required methods, skipping success tracking.")
        return

    var id = window.get_instance_id()
    _success_streak[id] = int(_success_streak.get(id, 0)) + 1
    _failure_streak[id] = 0

    if _cooldown_remaining.get(id, 0) > 0:
        _cooldown_remaining[id] = int(_cooldown_remaining[id]) - 1

    var current_streak = int(_success_streak[id])
    var current_level = window.get_level()
    var max_level = window.get_max_level()
    var cooldown_left = int(_cooldown_remaining.get(id, 0))

    if current_streak < _threshold:
        return

    if cooldown_left > 0:
        _success_streak[id] = 0
        return

    if current_level < max_level:
        window.level_up(1)
        _notify("Threat escalated! Level %d" % (current_level + 1))
        _success_streak[id] = 0
        return

    _success_streak[id] = 0


func on_breach_failed(window) -> void:
    if not _enabled or not _deescalation_enabled:
        return
    if window == null:
        return
    if not window.has_method("get_level") or not window.has_method("level_down"):
        _log_warn("Window missing required methods, skipping failure tracking.")
        return

    var id = window.get_instance_id()
    _failure_streak[id] = int(_failure_streak.get(id, 0)) + 1
    _success_streak[id] = 0

    var current_streak = int(_failure_streak[id])
    var current_level = window.get_level()

    if current_streak < _deescalation_threshold:
        return

    if current_level > 0:
        window.level_down(1)
        _notify("Threat reduced! Level %d" % (current_level - 1))
        _cooldown_remaining[id] = _escalation_cooldown

    _failure_streak[id] = 0


func _notify(message: String) -> void:
    if _core != null and _core.has_method("notify"):
        _core.notify("breach", message)
        return
    if Signals != null and Signals.has_signal("notify"):
        Signals.notify.emit("breach", message)


func _safe_connect(signal_ref: Signal, callable: Callable) -> void:
    if _safe_ops != null and _safe_ops.has_method("safe_connect"):
        _safe_ops.safe_connect(signal_ref, callable)
        return
    if signal_ref == null or callable == null or not callable.is_valid():
        return
    if not signal_ref.is_connected(callable):
        signal_ref.connect(callable)


func _log_warn(message: String) -> void:
    if _core != null and _core.has_method("logw"):
        _core.logw("TajemnikTV-QoL", message)
    elif _has_global_class("ModLoaderLog"):
        ModLoaderLog.warning(message, LOG_NAME)
    else:
        print("%s %s" % [LOG_NAME, message])


static func _has_global_class(class_name_str: String) -> bool:
    for entry in ProjectSettings.get_global_class_list():
        if entry.get("class", "") == class_name_str:
            return true
    return false
