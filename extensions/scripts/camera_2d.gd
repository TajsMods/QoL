extends "res://scripts/camera_2d.gd"

const SETTINGS_PREFIX := "tajs_qol"
const SETTING_CAMERA_SMOOTH_ZOOM := "%s.camera_smooth_zoom" % SETTINGS_PREFIX
const SETTING_CAMERA_ZOOM_STEP := "%s.camera_zoom_step" % SETTINGS_PREFIX

const DEFAULT_ZOOM_STEP := 0.1
const MAX_WHEEL_ZOOM := 1.2


func handle_movement_input(event: InputEvent, from: Vector2) -> void:
	if _handle_zoom_input(event, from):
		return
	super (event, from)


func _handle_zoom_input(event: InputEvent, from: Vector2) -> bool:
	if event is InputEventMouseButton:
		return _handle_mouse_wheel_zoom(event, from)
	if event is InputEventMagnifyGesture:
		return _handle_magnify_zoom(event, from)
	return false


func _handle_mouse_wheel_zoom(event: InputEventMouseButton, from: Vector2) -> bool:
	if event.button_index != MOUSE_BUTTON_WHEEL_UP and event.button_index != MOUSE_BUTTON_WHEEL_DOWN:
		return false
	if not event.pressed:
		return true
	if not _get_bool_setting(SETTING_CAMERA_SMOOTH_ZOOM, true):
		return false

	var step := clampf(_get_float_setting(SETTING_CAMERA_ZOOM_STEP, DEFAULT_ZOOM_STEP), 0.01, 0.5)
	var steps := event.factor
	if steps <= 0.0:
		steps = 1.0
	var direction := 1.0 if event.button_index == MOUSE_BUTTON_WHEEL_UP else -1.0
	var zoom_factor := pow(1.0 + step, direction * steps)
	var new_zoom := (target_zoom * zoom_factor).clamp(min_zoom, Vector2(MAX_WHEEL_ZOOM, MAX_WHEEL_ZOOM))
	if new_zoom.is_equal_approx(target_zoom):
		return true

	zoom_to(new_zoom, event.position + from)
	return true


func _handle_magnify_zoom(event: InputEventMagnifyGesture, from: Vector2) -> bool:
	if not _get_bool_setting(SETTING_CAMERA_SMOOTH_ZOOM, true):
		return false
	var factor := event.factor
	if factor <= 0.0:
		return true
	if is_equal_approx(factor, 1.0):
		return true

	var new_zoom := (target_zoom * factor).clamp(min_zoom, Vector2(MAX_WHEEL_ZOOM, MAX_WHEEL_ZOOM))
	if new_zoom.is_equal_approx(target_zoom):
		return true

	zoom_to(new_zoom, event.position + from)
	return true


func _get_settings() -> Object:
	if Engine.has_meta("TajsCore"):
		var core = Engine.get_meta("TajsCore")
		if core != null and core.has_method("get"):
			var settings = core.get("settings")
			if settings != null:
				return settings
	return null


func _get_bool_setting(key: String, fallback: bool) -> bool:
	var settings = _get_settings()
	if settings != null and settings.has_method("get_bool"):
		return settings.get_bool(key, fallback)
	return fallback


func _get_float_setting(key: String, fallback: float) -> float:
	var settings = _get_settings()
	if settings != null and settings.has_method("get_float"):
		return settings.get_float(key, fallback)
	return fallback
