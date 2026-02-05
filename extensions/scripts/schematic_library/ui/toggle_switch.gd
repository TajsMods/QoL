extends HBoxContainer

signal toggled(value: bool)

var _label: Label
var _switch: Button
var _switch_style_off: StyleBoxFlat
var _switch_style_on: StyleBoxFlat


func _init(text: String = "Legacy View", value: bool = false) -> void:
    add_theme_constant_override("separation", 8)
    alignment = BoxContainer.ALIGNMENT_CENTER

    _label = Label.new()
    _label.text = text
    _label.add_theme_font_size_override("font_size", 15)
    _label.add_theme_color_override("font_color", Color(0.78, 0.88, 0.98, 1.0))
    add_child(_label)

    _switch = Button.new()
    _switch.toggle_mode = true
    _switch.focus_mode = Control.FOCUS_NONE
    _switch.custom_minimum_size = Vector2(60, 28)
    _switch.text = "OFF"
    _switch.clip_text = true
    _switch.add_theme_font_size_override("font_size", 13)
    _switch.add_theme_color_override("font_color", Color(0.88, 0.94, 1.0, 1.0))
    _switch_style_off = _build_style(Color(0.15, 0.20, 0.30, 0.95), Color(0.32, 0.42, 0.58, 0.9))
    _switch_style_on = _build_style(Color(0.30, 0.50, 0.75, 0.95), Color(0.55, 0.75, 1.0, 1.0))
    _switch.add_theme_stylebox_override("normal", _switch_style_off)
    _switch.add_theme_stylebox_override("hover", _switch_style_off)
    _switch.add_theme_stylebox_override("pressed", _switch_style_on)
    _switch.set_pressed_no_signal(value)
    _update_visual(value)
    _switch.toggled.connect(func(v: bool) -> void:
        _update_visual(v)
        emit_signal("toggled", v)
    )
    add_child(_switch)


func set_pressed_no_signal(value: bool) -> void:
    if _switch != null:
        _switch.set_pressed_no_signal(value)
        _update_visual(value)


func is_pressed() -> bool:
    return _switch != null and _switch.button_pressed


func _update_visual(value: bool) -> void:
    if _switch == null:
        return
    _switch.text = "ON" if value else "OFF"
    var style := _switch_style_on if value else _switch_style_off
    _switch.add_theme_stylebox_override("normal", style)
    _switch.add_theme_stylebox_override("hover", style)


func _build_style(bg: Color, border: Color) -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = bg
    style.border_color = border
    style.set_border_width_all(1)
    style.set_corner_radius_all(10)
    style.set_content_margin_all(4)
    return style
