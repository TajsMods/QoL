extends Node

const LOG_NAME := "TajemnikTV-QoL:FocusMute"
const BUS_INDEX := 0

var _enabled: bool = true
var _background_volume: float = 0.0
var _was_focused: bool = true
var _stored_master_volume_db: float = 0.0


func setup() -> void:
	_stored_master_volume_db = AudioServer.get_bus_volume_db(BUS_INDEX)


func set_enabled(enabled: bool) -> void:
	_enabled = enabled
	if not _enabled and not _was_focused:
		_restore_volume()


func is_enabled() -> bool:
	return _enabled


func set_background_volume(volume: float) -> void:
	_background_volume = clampf(volume, 0.0, 100.0)
	if not _was_focused and _enabled:
		_apply_background_volume()


func get_background_volume() -> float:
	return _background_volume


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_APPLICATION_FOCUS_OUT:
			_on_focus_lost()
		NOTIFICATION_APPLICATION_FOCUS_IN:
			_on_focus_gained()


func _on_focus_lost() -> void:
	if _was_focused:
		_was_focused = false
		if _enabled:
			_stored_master_volume_db = AudioServer.get_bus_volume_db(BUS_INDEX)
			_apply_background_volume()


func _on_focus_gained() -> void:
	if not _was_focused:
		_was_focused = true
		if _enabled:
			_restore_volume()


func _apply_background_volume() -> void:
	var linear_volume: float = _background_volume / 100.0
	var db_volume: float = linear_to_db(linear_volume) if linear_volume > 0.0 else -80.0
	AudioServer.set_bus_volume_db(BUS_INDEX, db_volume)


func _restore_volume() -> void:
	AudioServer.set_bus_volume_db(BUS_INDEX, _stored_master_volume_db)
