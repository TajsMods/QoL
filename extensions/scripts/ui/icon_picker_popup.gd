class_name TajsQolIconPickerPopup
extends Node

const IconBrowserClass = preload("res://mods-unpacked/TajemnikTV-Core/core/ui/icon_browser.gd")

static func open(options: Dictionary = {}, on_selected: Callable = Callable(), on_cancel: Callable = Callable()) -> bool:
    var instance: Variant = _get_instance()
    if instance == null:
        return false
    return instance._open(options, on_selected, on_cancel)


static func _get_instance() -> Variant:
    if Engine.has_meta("TajsQolIconPicker"):
        var existing: Variant = Engine.get_meta("TajsQolIconPicker")
        if existing != null and existing.has_method("_open"):
            return existing
    var tree := Engine.get_main_loop()
    if tree == null:
        return null
    var root: Node = tree.root
    if root == null:
        return null
    var script_ref: Script = load("res://mods-unpacked/TajemnikTV-QoL/extensions/scripts/ui/icon_picker_popup.gd")
    if script_ref == null:
        return null
    var instance: Variant = script_ref.new()
    instance.name = "TajsQolIconPicker"
    root.add_child(instance)
    Engine.set_meta("TajsQolIconPicker", instance)
    return instance


var _layer: CanvasLayer
var _overlay: ColorRect
var _panel: PanelContainer
var _margin: MarginContainer
var _content: VBoxContainer
var _title_label: Label
var _close_btn: Button
var _browser
var _options: Dictionary = {}
var _on_selected: Callable
var _on_cancel: Callable


func _open(options: Dictionary, on_selected: Callable, on_cancel: Callable) -> bool:
    _options = options.duplicate(true) if typeof(options) == TYPE_DICTIONARY else {}
    _on_selected = on_selected if on_selected != null else Callable()
    _on_cancel = on_cancel if on_cancel != null else Callable()
    _ensure_layer()
    _build_content()
    _apply_layout()
    _layer.visible = true
    return true


func _ensure_layer() -> void:
    if _layer != null and is_instance_valid(_layer):
        return
    _layer = CanvasLayer.new()
    _layer.name = "QolIconPickerLayer"
    _layer.layer = 200
    _layer.visible = false
    add_child(_layer)

    _overlay = ColorRect.new()
    _overlay.name = "Overlay"
    _overlay.color = Color(0, 0, 0, 0.55)
    _overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
    _overlay.mouse_filter = Control.MOUSE_FILTER_STOP
    _overlay.gui_input.connect(_on_overlay_input)
    _layer.add_child(_overlay)

    _panel = PanelContainer.new()
    _panel.name = "IconPickerPanel"
    _panel.set_anchors_preset(Control.PRESET_CENTER)
    _panel.mouse_filter = Control.MOUSE_FILTER_STOP
    _panel.theme = load("res://themes/desktop_main.tres")
    _panel.theme_type_variation = &"ShadowPanelContainer"
    var panel_style := StyleBoxFlat.new()
    panel_style.bg_color = Color(0.12, 0.14, 0.19, 0.98)
    panel_style.set_corner_radius_all(12)
    panel_style.set_border_width_all(1)
    panel_style.border_color = Color(0.22, 0.26, 0.33, 0.85)
    _panel.add_theme_stylebox_override("panel", panel_style)
    _layer.add_child(_panel)

    _margin = MarginContainer.new()
    _margin.name = "Margin"
    _margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
    _margin.add_theme_constant_override("margin_left", 16)
    _margin.add_theme_constant_override("margin_right", 16)
    _margin.add_theme_constant_override("margin_top", 14)
    _margin.add_theme_constant_override("margin_bottom", 14)
    _panel.add_child(_margin)

    _content = VBoxContainer.new()
    _content.name = "Content"
    _content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _content.size_flags_vertical = Control.SIZE_EXPAND_FILL
    _content.add_theme_constant_override("separation", 10)
    _margin.add_child(_content)

    var viewport := get_viewport()
    if viewport != null:
        if not viewport.size_changed.is_connected(_on_viewport_resized):
            viewport.size_changed.connect(_on_viewport_resized)


func _build_content() -> void:
    if _content == null:
        return
    for child in _content.get_children():
        child.queue_free()
    if _browser != null:
        _browser = null
    _title_label = null
    _close_btn = null

    var header := HBoxContainer.new()
    header.name = "Header"
    header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    header.add_theme_constant_override("separation", 8)
    _title_label = Label.new()
    _title_label.text = str(_options.get("title", "Select Icon"))
    _title_label.add_theme_font_size_override("font_size", 18)
    header.add_child(_title_label)
    var spacer := Control.new()
    spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    header.add_child(spacer)
    _close_btn = Button.new()
    _close_btn.text = str(_options.get("cancel_text", "Close"))
    _close_btn.focus_mode = Control.FOCUS_NONE
    _close_btn.theme_type_variation = &"TabButton"
    _close_btn.add_theme_font_size_override("font_size", 16)
    _close_btn.pressed.connect(_on_cancel_pressed)
    header.add_child(_close_btn)
    _content.add_child(header)

    var browser_container := VBoxContainer.new()
    browser_container.name = "BrowserContainer"
    browser_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    browser_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
    _content.add_child(browser_container)

    _browser = IconBrowserClass.new()
    var opts := _options.duplicate(true)
    opts["owns_popup"] = false
    if not opts.has("show_select_button"):
        opts["show_select_button"] = false
    if not opts.has("auto_confirm"):
        opts["auto_confirm"] = true
    if _on_selected != null and _on_selected.is_valid():
        opts["selection_callback"] = _on_selected
    _browser.build_ui(browser_container, opts)
    _browser.icon_confirmed.connect(_on_browser_confirmed)
    _browser.selection_cleared.connect(_on_browser_cleared)


func _apply_layout() -> void:
    if _panel == null:
        return
    var viewport := get_viewport()
    if viewport == null:
        return
    var viewport_size := viewport.get_visible_rect().size
    var ratio: Vector2 = _options.get("popup_size_ratio", Vector2(0.76, 0.72))
    var target_size := Vector2(viewport_size.x * ratio.x, viewport_size.y * ratio.y)
    var min_size: Vector2 = _options.get("popup_min_size", Vector2(640, 480))
    var max_size: Vector2 = _options.get("popup_max_size", Vector2(1100, 840))
    var viewport_limit := viewport_size * 0.92
    min_size.x = min(min_size.x, viewport_limit.x)
    min_size.y = min(min_size.y, viewport_limit.y)
    max_size.x = min(max_size.x, viewport_limit.x)
    max_size.y = min(max_size.y, viewport_limit.y)
    target_size.x = clamp(target_size.x, min_size.x, max_size.x)
    target_size.y = clamp(target_size.y, min_size.y, max_size.y)
    _panel.custom_minimum_size = target_size
    _panel.offset_left = - target_size.x * 0.5
    _panel.offset_right = target_size.x * 0.5
    _panel.offset_top = - target_size.y * 0.5
    _panel.offset_bottom = target_size.y * 0.5
    if _browser != null and _browser.has_method("update_layout"):
        _browser.call("update_layout")


func _close() -> void:
    if _layer != null:
        _layer.visible = false


func _on_overlay_input(event: InputEvent) -> void:
    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
        _on_cancel_pressed()


func _on_cancel_pressed() -> void:
    if _on_cancel != null and _on_cancel.is_valid():
        _on_cancel.call()
    _close()


func _on_browser_confirmed(_icon_id: String, _entry: Dictionary) -> void:
    _close()


func _on_browser_cleared() -> void:
    _close()


func _on_viewport_resized() -> void:
    if _layer != null and _layer.visible:
        _apply_layout()
