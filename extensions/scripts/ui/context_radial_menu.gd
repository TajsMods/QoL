extends CanvasLayer

signal action_selected(action: Dictionary)
signal closed

const ITEM_SIZE := 88.0
const CENTER_SIZE := 64.0
const ICON_SIZE := 28.0
const LABEL_FONT_SIZE := 14
const RADIUS_BASE := 120.0
const RADIUS_STEP := 6.0
const MAX_RADIUS := 180.0
const EDGE_PADDING := 12.0
const CATEGORY_ICON := "res://textures/icons/cog.png"

const COLOR_BG := Color(0, 0, 0, 0.28)
const COLOR_PANEL := Color(0.0862745, 0.101961, 0.137255, 0.95)
const COLOR_PANEL_HOVER := Color(0.14, 0.2, 0.29, 0.95)
const COLOR_PANEL_DISABLED := Color(0.08, 0.08, 0.09, 0.7)
const COLOR_BORDER := Color(0.270064, 0.332386, 0.457031, 1.0)
const COLOR_TEXT := Color(0.85, 0.97, 1.0, 1.0)
const COLOR_TEXT_DISABLED := Color(0.6, 0.6, 0.65, 1.0)

var _background: ColorRect
var _root: Control
var _center_button: Button
var _items: Array[Control] = []
var _stack: Array = []
var _center_pos: Vector2 = Vector2.ZERO
var _is_open: bool = false
var _style_normal: StyleBoxFlat
var _style_hover: StyleBoxFlat
var _style_disabled: StyleBoxFlat
var _style_center: StyleBoxFlat


func _init() -> void:
    layer = 120
    name = "TajsQolContextRadialMenu"
    visible = false
    set_process_unhandled_input(true)


func _ready() -> void:
    _build_styles()
    _build_ui()


func _unhandled_input(event: InputEvent) -> void:
    if not _is_open:
        return
    if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
        close()
        get_viewport().set_input_as_handled()


func open(actions: Array, _context: Dictionary, screen_pos: Vector2) -> void:
    if actions.is_empty():
        return
    _stack.clear()
    _center_pos = screen_pos
    _stack.append(_build_state(actions, ""))
    _is_open = true
    visible = true
    _render_current()


func close() -> void:
    if not _is_open:
        return
    _is_open = false
    visible = false
    _clear_items()
    _stack.clear()
    closed.emit()


func is_open() -> bool:
    return _is_open


func _build_styles() -> void:
    _style_normal = _make_style(COLOR_PANEL, COLOR_BORDER, ITEM_SIZE * 0.5, 6)
    _style_hover = _make_style(COLOR_PANEL_HOVER, COLOR_BORDER, ITEM_SIZE * 0.5, 8)
    _style_disabled = _make_style(COLOR_PANEL_DISABLED, COLOR_BORDER, ITEM_SIZE * 0.5, 4)
    _style_center = _make_style(COLOR_PANEL, COLOR_BORDER, CENTER_SIZE * 0.5, 6)


func _build_ui() -> void:
    _background = ColorRect.new()
    _background.color = COLOR_BG
    _background.mouse_filter = Control.MOUSE_FILTER_STOP
    _background.set_anchors_preset(Control.PRESET_FULL_RECT)
    _background.gui_input.connect(_on_background_input)
    add_child(_background)

    _root = Control.new()
    _root.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _root.set_anchors_preset(Control.PRESET_FULL_RECT)
    add_child(_root)

    _center_button = Button.new()
    _center_button.text = "Close"
    _center_button.focus_mode = Control.FOCUS_NONE
    _center_button.custom_minimum_size = Vector2(CENTER_SIZE, CENTER_SIZE)
    _center_button.add_theme_stylebox_override("normal", _style_center)
    _center_button.add_theme_stylebox_override("hover", _style_hover)
    _center_button.add_theme_stylebox_override("pressed", _style_hover)
    _center_button.add_theme_color_override("font_color", COLOR_TEXT)
    _center_button.add_theme_font_size_override("font_size", LABEL_FONT_SIZE)
    _center_button.pressed.connect(_on_center_pressed)
    _center_button.visible = false
    _root.add_child(_center_button)


func _on_background_input(event: InputEvent) -> void:
    if event is InputEventMouseButton and event.pressed:
        close()


func _on_center_pressed() -> void:
    if _stack.size() > 1:
        _stack.pop_back()
        _render_current()
    else:
        close()


func _render_current() -> void:
    if _stack.is_empty():
        close()
        return
    var state: Dictionary = _stack[_stack.size() - 1]
    var items: Array = state.get("items", [])
    if items.is_empty():
        close()
        return

    _clear_items()

    var count := items.size()
    _center_pos = _clamp_center(_center_pos, count)
    var radius := _calc_radius(count)

    for i in range(count):
        var action: Dictionary = items[i]
        var item := _create_item(action)
        var angle := -PI / 2 + TAU * float(i) / float(count)
        var item_offset := Vector2(cos(angle), sin(angle)) * radius
        item.position = _center_pos + item_offset - item.size / 2
        _root.add_child(item)
        _items.append(item)

    _center_button.text = "Back" if _stack.size() > 1 else "Close"
    _center_button.visible = true
    _center_button.position = _center_pos - Vector2(CENTER_SIZE, CENTER_SIZE) / 2


func _create_item(action: Dictionary) -> Control:
    var enabled := bool(action.get("enabled", true))
    var is_category := bool(action.get("is_category", false))
    var panel := PanelContainer.new()
    panel.custom_minimum_size = Vector2(ITEM_SIZE, ITEM_SIZE)
    panel.size = panel.custom_minimum_size
    panel.mouse_filter = Control.MOUSE_FILTER_STOP
    panel.add_theme_stylebox_override("panel", _style_normal if enabled else _style_disabled)

    var vbox := VBoxContainer.new()
    vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
    vbox.alignment = BoxContainer.ALIGNMENT_CENTER
    vbox.add_theme_constant_override("separation", 4)
    panel.add_child(vbox)

    var icon_path := str(action.get("icon_path", ""))
    if is_category and icon_path == "":
        icon_path = CATEGORY_ICON
    if icon_path != "" and ResourceLoader.exists(icon_path):
        var icon := TextureRect.new()
        icon.texture = load(icon_path)
        icon.custom_minimum_size = Vector2(ICON_SIZE, ICON_SIZE)
        icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
        vbox.add_child(icon)

    var label := Label.new()
    label.text = str(action.get("title", action.get("id", "")))
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    label.autowrap_mode = TextServer.AUTOWRAP_WORD
    label.add_theme_font_size_override("font_size", LABEL_FONT_SIZE)
    label.add_theme_color_override("font_color", COLOR_TEXT if enabled else COLOR_TEXT_DISABLED)
    label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    vbox.add_child(label)

    panel.gui_input.connect(func(event: InputEvent):
        if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
            panel.accept_event()
            if not enabled:
                return
            if is_category:
                _enter_category(action)
                return
            action_selected.emit(action)
    )
    if enabled:
        panel.mouse_entered.connect(func():
            panel.add_theme_stylebox_override("panel", _style_hover)
        )
        panel.mouse_exited.connect(func():
            panel.add_theme_stylebox_override("panel", _style_normal)
        )

    return panel


func _enter_category(action: Dictionary) -> void:
    var children: Array = action.get("children", [])
    if children.is_empty():
        return
    _stack.append(_build_state(children, str(action.get("title", ""))))
    _render_current()


func _build_state(actions: Array, title: String) -> Dictionary:
    var direct: Array = []
    var categories: Dictionary = {}

    for action in actions:
        var path := _normalize_path(action.get("category_path", []))
        if path.is_empty():
            direct.append(action)
        else:
            var key := path[0]
            var entry: Dictionary = categories.get(key, {
                "title": key,
                "actions": [],
                "priority": 0,
                "order": 0
            })
            var child: Dictionary = action.duplicate(true)
            child["category_path"] = path.slice(1, path.size())
            entry["actions"].append(child)
            entry["priority"] = maxi(int(entry["priority"]), int(action.get("priority", 0)))
            entry["order"] = mini(int(entry["order"]), int(action.get("order", 0)))
            categories[key] = entry

    var items: Array = []
    for entry in categories.values():
        items.append({
            "id": "__category__/" + str(entry.get("title", "")),
            "title": str(entry.get("title", "")),
            "is_category": true,
            "children": entry.get("actions", []),
            "priority": int(entry.get("priority", 0)),
            "order": int(entry.get("order", 0)),
            "icon_path": str(entry.get("icon_path", ""))
        })
    items.append_array(direct)
    items.sort_custom(func(a, b): return _compare_items(a, b))
    return {"title": title, "items": items}


func _compare_items(a: Dictionary, b: Dictionary) -> bool:
    var pa: int = int(a.get("priority", 0))
    var pb: int = int(b.get("priority", 0))
    if pa != pb:
        return pa > pb
    var oa: int = int(a.get("order", 0))
    var ob: int = int(b.get("order", 0))
    if oa != ob:
        return oa < ob
    var ta: String = str(a.get("title", a.get("id", "")))
    var tb: String = str(b.get("title", b.get("id", "")))
    if ta != tb:
        return ta < tb
    return false


func _normalize_path(path_val: Variant) -> Array[String]:
    var result: Array[String] = []
    if path_val is Array:
        for entry in path_val:
            var text := str(entry).strip_edges()
            if text != "":
                result.append(text)
    elif path_val is String:
        var text := str(path_val).strip_edges()
        if text != "":
            result.append(text)
    return result


func _clear_items() -> void:
    for item in _items:
        if is_instance_valid(item):
            item.queue_free()
    _items.clear()


func _calc_radius(count: int) -> float:
    if count <= 1:
        return RADIUS_BASE
    return clampf(RADIUS_BASE + float(count) * RADIUS_STEP, RADIUS_BASE, MAX_RADIUS)


func _clamp_center(center: Vector2, count: int) -> Vector2:
    var viewport_size := get_viewport().get_visible_rect().size
    var radius := _calc_radius(count)
    var margin := radius + ITEM_SIZE * 0.5 + EDGE_PADDING
    center.x = clampf(center.x, margin, viewport_size.x - margin)
    center.y = clampf(center.y, margin, viewport_size.y - margin)
    return center


func _make_style(bg_color: Color, border_color: Color, radius: float, shadow_size: int) -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = bg_color
    style.border_color = border_color
    style.set_border_width_all(2)
    style.set_corner_radius_all(int(radius))
    style.shadow_color = Color(0, 0, 0, 0.3)
    style.shadow_size = shadow_size
    return style
