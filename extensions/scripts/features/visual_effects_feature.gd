extends RefCounted

const LOG_NAME := "TajemnikTV-QoL:VisualEffects"

var _core
var _glow_enabled: bool = false
var _glow_intensity: float = 2.0
var _glow_strength: float = 1.3
var _glow_bloom: float = 0.2
var _glow_sensitivity: float = 0.8

var _ui_opacity: float = 100.0
var _ui_defaults_captured: bool = false
var _ui_default_alpha: float = 1.0

var _glow_defaults_captured: bool = false
var _glow_defaults: Dictionary = {}


func setup(core) -> void:
	_core = core


func set_glow_enabled(enabled: bool) -> void:
	_glow_enabled = enabled
	_apply_glow()


func set_glow_settings(intensity: float, strength: float, bloom: float, sensitivity: float) -> void:
	_glow_intensity = intensity
	_glow_strength = strength
	_glow_bloom = bloom
	_glow_sensitivity = sensitivity
	_apply_glow()


func set_ui_opacity(value: float) -> void:
	_ui_opacity = value
	_apply_ui_opacity()


func apply_all() -> void:
	_apply_glow()
	_apply_ui_opacity()


func _apply_glow() -> void:
	var env = _get_environment()
	if env == null:
		return
	if not _glow_defaults_captured:
		_glow_defaults = {
			"enabled": env.glow_enabled,
			"intensity": env.glow_intensity,
			"strength": env.glow_strength,
			"bloom": env.glow_bloom,
			"sensitivity": env.glow_hdr_threshold
		}
		_glow_defaults_captured = true

	if _glow_enabled:
		env.glow_enabled = true
		env.glow_intensity = _glow_intensity
		env.glow_strength = _glow_strength
		env.glow_bloom = _glow_bloom
		env.glow_hdr_threshold = _glow_sensitivity
	elif _glow_defaults_captured:
		env.glow_enabled = _glow_defaults["enabled"]
		env.glow_intensity = _glow_defaults["intensity"]
		env.glow_strength = _glow_defaults["strength"]
		env.glow_bloom = _glow_defaults["bloom"]
		env.glow_hdr_threshold = _glow_defaults["sensitivity"]
	else:
		env.glow_enabled = false


func _apply_ui_opacity() -> void:
	var main_container = _get_main_container()
	if main_container == null:
		return
	if not _ui_defaults_captured:
		_ui_default_alpha = main_container.modulate.a
		_ui_defaults_captured = true

	var alpha = clampf(_ui_opacity / 100.0, 0.0, 1.0)
	if _ui_opacity >= 100.0:
		main_container.modulate.a = _ui_default_alpha
	else:
		main_container.modulate.a = alpha


func _get_environment() -> Environment:
	var main = _get_main_node()
	if main == null:
		return null
	var env_node = main.find_child("WorldEnvironment", true, false)
	if env_node == null:
		return null
	var env = env_node.environment
	if env == null:
		return null
	return env


func _get_main_container() -> CanvasItem:
	var main = _get_main_node()
	if main == null:
		return null
	var hud = main.get_node_or_null("HUD")
	if hud == null:
		return null
	return hud.get_node_or_null("Main/MainContainer")


func _get_main_node() -> Node:
	var tree = Engine.get_main_loop()
	if tree == null:
		return null
	return tree.root.get_node_or_null("Main")
