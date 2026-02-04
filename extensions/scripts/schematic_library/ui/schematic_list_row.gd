extends Button

const StatusBadgeScript = preload("res://mods-unpacked/TajemnikTV-QoL/extensions/scripts/schematic_library/ui/status_badge.gd")

var _icon: TextureRect
var _icon_panel: PanelContainer
var _name_label: Label
var _meta_label: Label
var _badge_holder: HBoxContainer
var _badge


func _init() -> void:
	toggle_mode = true
	focus_mode = Control.FOCUS_NONE
	custom_minimum_size = Vector2(0, 76)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	clip_contents = true
	_build()


func setup(icon_texture: Texture2D, schematic_name: String, meta: String, status: String) -> void:
	_icon.texture = icon_texture
	_name_label.text = schematic_name
	_meta_label.text = meta
	if _badge != null:
		_badge.queue_free()
	_badge = StatusBadgeScript.new(status)
	_badge_holder.add_child(_badge)


func _build() -> void:
	# Subtle base style
	var base := _build_style(Color(0.09, 0.12, 0.18, 0.9), Color(0.24, 0.32, 0.46, 0.7), 1)
	# Hover effect - slightly brighter
	var hover := _build_style(Color(0.12, 0.16, 0.24, 0.95), Color(0.38, 0.50, 0.70, 0.85), 1)
	# Selected/pressed state - blue tint with prominent border
	var pressed_style := _build_style(Color(0.14, 0.20, 0.30, 1.0), Color(0.50, 0.70, 1.0, 1.0), 2)
	pressed_style.shadow_color = Color(0.45, 0.65, 1.0, 0.2)
	pressed_style.shadow_size = 4
	add_theme_stylebox_override("normal", base)
	add_theme_stylebox_override("hover", hover)
	add_theme_stylebox_override("pressed", pressed_style)
	add_theme_stylebox_override("focus", pressed_style)

	var row := HBoxContainer.new()
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.add_theme_constant_override("separation", 12)
	add_child(row)

	# Icon with subtle background panel
	_icon_panel = PanelContainer.new()
	_icon_panel.custom_minimum_size = Vector2(52, 52)
	var icon_style := StyleBoxFlat.new()
	icon_style.bg_color = Color(0.14, 0.18, 0.26, 0.8)
	icon_style.set_corner_radius_all(10)
	icon_style.set_content_margin_all(8)
	_icon_panel.add_theme_stylebox_override("panel", icon_style)
	row.add_child(_icon_panel)

	_icon = TextureRect.new()
	_icon.custom_minimum_size = Vector2(36, 36)
	_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_icon_panel.add_child(_icon)

	var labels := VBoxContainer.new()
	labels.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	labels.alignment = BoxContainer.ALIGNMENT_CENTER
	labels.add_theme_constant_override("separation", 4)
	row.add_child(labels)

	_name_label = Label.new()
	_name_label.add_theme_font_size_override("font_size", 22)
	_name_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
	_name_label.clip_text = true
	_name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	labels.add_child(_name_label)

	_meta_label = Label.new()
	_meta_label.add_theme_font_size_override("font_size", 16)
	_meta_label.add_theme_color_override("font_color", Color(0.75, 0.85, 0.95, 1.0))
	_meta_label.clip_text = true
	_meta_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	labels.add_child(_meta_label)

	_badge_holder = HBoxContainer.new()
	_badge_holder.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_badge_holder.alignment = BoxContainer.ALIGNMENT_END
	var badge_wrap := MarginContainer.new()
	badge_wrap.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	badge_wrap.add_theme_constant_override("margin_left", 8)
	badge_wrap.add_theme_constant_override("margin_right", 8)
	row.add_child(badge_wrap)

	_badge_holder.custom_minimum_size = Vector2(80, 0)
	badge_wrap.add_child(_badge_holder)


func _build_style(bg: Color, border: Color, border_width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(10)
	style.set_content_margin_all(12)
	return style
