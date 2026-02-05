extends PanelContainer

signal removed(value: String)

var _label: Label
var _close_button: Button
var _value: String = ""


func _init(value: String = "", removable: bool = true) -> void:
    _value = value
    _build(removable)
    _set_value(value)


func _build(removable: bool) -> void:
    var style := StyleBoxFlat.new()
    style.bg_color = Color(0.16, 0.22, 0.30, 0.95)
    style.border_color = Color(0.32, 0.42, 0.56, 0.85)
    style.set_border_width_all(1)
    style.set_corner_radius_all(10)
    style.set_content_margin_all(6)
    style.content_margin_left = 10
    style.content_margin_right = 10
    add_theme_stylebox_override("panel", style)

    var row := HBoxContainer.new()
    row.add_theme_constant_override("separation", 5)
    add_child(row)

    _label = Label.new()
    _label.add_theme_font_size_override("font_size", 14)
    _label.add_theme_color_override("font_color", Color(0.85, 0.92, 1.0, 1.0))
    row.add_child(_label)

    _close_button = Button.new()
    _close_button.text = "×"
    _close_button.focus_mode = Control.FOCUS_NONE
    _close_button.visible = removable
    _close_button.flat = true
    _close_button.custom_minimum_size = Vector2(16, 16)
    _close_button.add_theme_font_size_override("font_size", 13)
    _close_button.add_theme_color_override("font_color", Color(0.65, 0.75, 0.88, 0.95))
    _close_button.pressed.connect(func() -> void:
        emit_signal("removed", _value)
    )
    row.add_child(_close_button)


func set_removable(removable: bool) -> void:
    if _close_button != null:
        _close_button.visible = removable


func set_value(value: String) -> void:
    _set_value(value)


func get_value() -> String:
    return _value


func _set_value(value: String) -> void:
    _value = value
    if _label != null:
        _label.text = value
