extends PanelContainer

var _label: Label
var _style: StyleBoxFlat
var _status: String = "WIP"


func _init(text: String = "OK") -> void:
	_build()
	set_status(text)


func _build() -> void:
	_style = StyleBoxFlat.new()
	_style.set_corner_radius_all(12)
	_style.set_content_margin_all(6)
	_style.content_margin_left = 12
	_style.content_margin_right = 12
	_style.set_border_width_all(1)
	add_theme_stylebox_override("panel", _style)
	custom_minimum_size = Vector2(60, 30)

	_label = Label.new()
	_label.add_theme_font_size_override("font_size", 16)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_child(_label)


func set_status(status: String) -> void:
	var normalized := status.to_lower()
	_status = "WIP"
	if normalized == "ok":
		_status = "OK"
	elif normalized == "meme":
		_status = "Meme"
	elif normalized == "meta":
		_status = "Meta"
	elif normalized == "blocked":
		_status = "Blocked"

	match _status:
		"OK":
			# Green - success/ready state
			_style.bg_color = Color(0.25, 0.55, 0.35, 0.95)
			_style.border_color = Color(0.45, 0.75, 0.55, 0.9)
			_label.add_theme_color_override("font_color", Color(0.75, 1.0, 0.85, 1.0))
		"Meme":
			# Pink/magenta - fun/meme state
			_style.bg_color = Color(0.55, 0.25, 0.48, 0.95)
			_style.border_color = Color(0.75, 0.45, 0.68, 0.9)
			_label.add_theme_color_override("font_color", Color(1.0, 0.80, 0.95, 1.0))
		"Meta":
			# Blue - meta/special state
			_style.bg_color = Color(0.22, 0.45, 0.65, 0.95)
			_style.border_color = Color(0.42, 0.65, 0.85, 0.9)
			_label.add_theme_color_override("font_color", Color(0.80, 0.92, 1.0, 1.0))
		"Blocked":
			# Orange/red - blocked/error state
			_style.bg_color = Color(0.65, 0.32, 0.22, 0.95)
			_style.border_color = Color(0.85, 0.50, 0.38, 0.9)
			_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.78, 1.0))
		_:
			# Yellow - WIP/in-progress state
			_status = "WIP"
			_style.bg_color = Color(0.58, 0.50, 0.22, 0.95)
			_style.border_color = Color(0.78, 0.70, 0.38, 0.9)
			_label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.75, 1.0))

	_label.text = _status
	add_theme_stylebox_override("panel", _style)


func get_status() -> String:
	return _status
