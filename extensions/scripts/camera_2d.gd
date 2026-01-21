extends "res://scripts/camera_2d.gd"

const SETTINGS_PREFIX := "tajs_qol"
const SETTING_CAMERA_WASD_SPEED := "%s.camera_wasd_speed" % SETTINGS_PREFIX
const SETTING_CAMERA_SMOOTH_ZOOM := "%s.camera_smooth_zoom" % SETTINGS_PREFIX
const SETTING_CAMERA_ZOOM_STEP := "%s.camera_zoom_step" % SETTINGS_PREFIX
const ACTION_CAMERA_BOOST := "TajemnikTV-QoL.camera_boost"

const DEFAULT_WASD_SPEED := 1.0
const MIN_WASD_SPEED := 0.25
const MAX_WASD_SPEED := 3.0
const DEFAULT_ZOOM_STEP := 0.1
const MAX_WHEEL_ZOOM := 1.2

var _menu_open: bool = false


func _ready() -> void:
	super()
	if Signals != null and Signals.has_signal("menu_set"):
		if not Signals.menu_set.is_connected(_on_menu_set):
			Signals.menu_set.connect(_on_menu_set)


func _process(delta: float) -> void:
	var movement := Vector2.ZERO
	var allow_keyboard := _should_handle_keyboard_input()
	if allow_keyboard:
		movement = Vector2(Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left"), Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up"))
		if _is_boost_pressed():
			movement *= 2.0
		movement *= _get_wasd_speed_multiplier()
	if movement or joystick_movement:
		position = clamp_pos(position + ((movement * 1000) + joystick_movement) * delta)

	var zoom_movement := Vector2.ZERO
	if allow_keyboard:
		if Input.is_action_pressed("ui_zoom_in"):
			zoom_movement = Vector2(0.4, 0.4) * delta
		elif Input.is_action_pressed("ui_zoom_out"):
			zoom_movement = - Vector2(0.4, 0.4) * delta
		if _is_boost_pressed():
			zoom_movement *= 2.0

	zoom_movement += Vector2.ONE * (joystick_zoom / sqrt(zoom.x)) * delta

	if zoom_movement:
		zoom = (zoom + zoom_movement).clamp(min_zoom, Vector2(1.6, 1.6))
		target_zoom = zoom

	if zooming:
		zoom = zoom.lerp(target_zoom, 1.0 - exp(-10 * delta))
		zooming = !zoom.is_equal_approx(target_zoom)

	var new_distance: int
	if zoom.x <= 0.2:
		new_distance = 2
	elif zoom.x <= 0.3:
		new_distance = 1
	else:
		new_distance = 0

	if new_distance != distance_level:
		distance_level = new_distance
		Signals.distance_level_set.emit(distance_level)

	Globals.camera_center = get_screen_center_position()
	Globals.camera_zoom = zoom
	position_smoothing_enabled = zooming


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


func _get_wasd_speed_multiplier() -> float:
	return clampf(_get_float_setting(SETTING_CAMERA_WASD_SPEED, DEFAULT_WASD_SPEED), MIN_WASD_SPEED, MAX_WASD_SPEED)


func _is_boost_pressed() -> bool:
	if not InputMap.has_action(ACTION_CAMERA_BOOST):
		return false
	return Input.is_action_pressed(ACTION_CAMERA_BOOST)


func _should_handle_keyboard_input() -> bool:
	if _menu_open:
		return false
	var focus: Control = get_viewport().gui_get_focus_owner()
	return focus == null


func _on_menu_set(menu: int, _tab: int) -> void:
	_menu_open = menu != Utils.menu_types.NONE
