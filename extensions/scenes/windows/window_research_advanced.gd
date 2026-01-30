extends "res://scenes/windows/window_research_advanced.gd"

const ETA_UPDATE_INTERVAL := 0.5
const ETA_SAMPLE_LIMIT := 6
const MAX_ETA_SECONDS := 9.22e18 # Clamp to int64-safe range for formatting.

var _eta_container: VBoxContainer = null
var _eta_label: Label = null
var _eta_update_accum: float = 0.0
var _eta_last_text: String = ""
var _eta_last_tooltip: String = ""
var _speed_samples: Array[float] = []


func _ready() -> void:
	super._ready()
	_ensure_eta_ui()
	_update_eta(true)


func _process(delta: float) -> void:
	super._process(delta)
	_eta_update_accum += delta
	if _eta_update_accum >= ETA_UPDATE_INTERVAL:
		_eta_update_accum = fmod(_eta_update_accum, ETA_UPDATE_INTERVAL)
		_update_eta()


func _ensure_eta_ui() -> void:
	if _eta_container != null and is_instance_valid(_eta_container):
		return
	var bottom_panel := get_node_or_null("PanelContainer/MainContainer/Researched")
	if bottom_panel == null:
		return
	if bottom_panel.has_node("QolEtaContainer"):
		_eta_container = bottom_panel.get_node("QolEtaContainer")
		_eta_label = _eta_container.get_node_or_null("EtaLabel")
		return

	_eta_container = VBoxContainer.new()
	_eta_container.name = "QolEtaContainer"
	_eta_container.layout_mode = 0
	_eta_container.anchor_left = 1.0
	_eta_container.anchor_right = 1.0
	_eta_container.offset_left = -200.0
	_eta_container.offset_right = -10.0
	_eta_container.offset_top = 6.0
	_eta_container.offset_bottom = 54.0
	_eta_container.size_flags_horizontal = Control.SIZE_SHRINK_END
	_eta_container.alignment = BoxContainer.ALIGNMENT_END
	_eta_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_eta_container.add_theme_constant_override("separation", -2)

	_eta_label = Label.new()
	_eta_label.name = "EtaLabel"
	_eta_label.text = "ETA: --"
	_eta_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_eta_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_eta_label.add_theme_font_size_override("font_size", 18)
	_eta_label.add_theme_color_override("font_color", Color(0.627451, 0.776471, 0.811765))
	_eta_container.add_child(_eta_label)

	bottom_panel.add_child(_eta_container)


func _update_eta(force: bool = false) -> void:
	if _eta_label == null or research == null:
		return

	# ETA uses remaining = required - current count, speed = research.production.
	# Updates every ETA_UPDATE_INTERVAL seconds with a light rolling average for stability.
	var remaining := maxf(research.required - research.count, 0.0)
	var speed := _get_smoothed_speed()

	if is_nan(remaining) or is_inf(remaining):
		_set_eta_display("ETA: --", "ETA unavailable.", force)
		return

	if speed <= 0.0:
		# Speed is zero or missing: show placeholder instead of dividing by zero.
		_set_eta_display("ETA: --", "No research speed (paused or no input).", force)
		return

	if remaining <= 0.0:
		_set_eta_display("ETA: 00:00", _build_tooltip(remaining, speed), force)
		return

	var eta_seconds := remaining / speed
	if is_nan(eta_seconds) or is_inf(eta_seconds) or eta_seconds < 0.0:
		_set_eta_display("ETA: --", "ETA unavailable.", force)
		return

	_set_eta_display("ETA: " + _format_eta(eta_seconds), _build_tooltip(remaining, speed), force)


func _get_smoothed_speed() -> float:
	var raw_speed := 0.0
	if research != null:
		raw_speed = float(research.production)
	if is_nan(raw_speed) or is_inf(raw_speed) or raw_speed < 0.0:
		raw_speed = 0.0
	if raw_speed <= 0.0:
		_speed_samples.clear()
		return 0.0

	_speed_samples.append(raw_speed)
	while _speed_samples.size() > ETA_SAMPLE_LIMIT:
		_speed_samples.pop_front()

	var sum := 0.0
	for sample in _speed_samples:
		sum += sample
	return sum / maxf(1.0, float(_speed_samples.size()))


func _format_eta(seconds: float) -> String:
	var clamped := minf(seconds, MAX_ETA_SECONDS)
	var total := maxi(0, int(ceil(clamped)))
	var hours := total / 3600
	var minutes := (total % 3600) / 60
	var secs := total % 60
	if hours > 0:
		var text := "%02d:%02d:%02d" % [hours, minutes, secs]
		if seconds > MAX_ETA_SECONDS:
			text += "+"
		return text
	return "%02d:%02d" % [minutes, secs]


func _build_tooltip(remaining: float, speed: float) -> String:
	var remaining_text := Utils.print_string(remaining, false)
	var speed_text := Utils.print_string(speed, false)
	return "Remaining: %s research\nSpeed: %s/s" % [remaining_text, speed_text]


func _set_eta_display(text: String, tooltip: String, force: bool = false) -> void:
	if _eta_label == null:
		return
	if force or text != _eta_last_text:
		_eta_label.text = text
		_eta_last_text = text
	if force or tooltip != _eta_last_tooltip:
		_eta_label.tooltip_text = tooltip
		_eta_last_tooltip = tooltip
