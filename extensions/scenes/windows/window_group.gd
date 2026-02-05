extends "res://scenes/windows/window_group.gd"

const SETTINGS_ENABLED_KEY := "tajs_qol.group_patterns_enabled"
const SETTINGS_DATA_KEY := "tajs_qol.group_patterns"
const SETTINGS_COLOR_PICKER_ENABLED_KEY := "tajs_qol.group_color_picker_enabled"
const SETTINGS_LOCK_DATA_KEY := "tajs_qol.group_lock_data"
const DEFAULT_ICON_PATH := "res://textures/icons/window.png"

const VANILLA_COLORS: Array[String] = ["1a202c", "1a2b22", "1a292b", "1a1b2b", "211a2b", "2b1a27", "2b1a1a"]

const PatternDrawerScript = preload("res://mods-unpacked/TajemnikTV-QoL/extensions/scripts/ui/pattern_drawer.gd")
const PatternPickerPanelScript = preload("res://mods-unpacked/TajemnikTV-QoL/extensions/scripts/ui/pattern_picker_panel.gd")
const ColorPickerPanelScript = preload("res://mods-unpacked/TajemnikTV-Core/core/ui/color_picker_panel.gd")
const GroupPatternChangedCommand = preload("res://mods-unpacked/TajemnikTV-QoL/extensions/scripts/features/commands/group_pattern_changed_command.gd")

var pattern_index: int = 0
var pattern_color: Color = Color(0, 0, 0, 1.0)
var pattern_alpha: float = 0.4
var pattern_spacing: float = 20.0
var pattern_thickness: float = 4.0
var pattern_drawers: Array[Control] = []

var custom_color: Color = Color.TRANSPARENT
var qol_group_style_id: String = ""
var _patterns_enabled: bool = true
var _color_picker_enabled: bool = true

var _pattern_picker_layer: CanvasLayer = null
var _pattern_picker: Control = null
var _color_picker_layer: CanvasLayer = null
var _color_picker = null
var locked: bool = false
var _undo_before_state: Dictionary = {}


func _ready() -> void:
    super._ready()
    _ensure_group_style_id()
    qol_migrate_style_keys()
    _patterns_enabled = _is_patterns_enabled()
    _color_picker_enabled = _is_color_picker_enabled()
    _load_lock_from_settings()
    update_icon()
    if not _patterns_enabled:
        return
    _ensure_pattern_ui()
    _load_from_settings()
    update_color()
    update_pattern()


func update_icon() -> void:
    var tex := _resolve_icon_texture(custom_icon)
    if tex != null:
        $TitlePanel/TitleContainer/Icon.texture = tex
    else:
        $TitlePanel/TitleContainer/Icon.texture = load(DEFAULT_ICON_PATH)


func get_icon() -> String:
    var icon_id := str(custom_icon)
    if icon_id == "":
        return DEFAULT_ICON_PATH
    var core = Engine.get_meta("TajsCore", null)
    if core != null:
        var registry = core.get_icon_registry()
        if registry != null:
            var resolved: Dictionary = registry.resolve_icon(icon_id)
            var path := str(resolved.get("path", ""))
            if path != "":
                return path
    if icon_id.begins_with("res://"):
        return icon_id
    if icon_id.find(":") != -1:
        var parts := icon_id.split(":", false, 1)
        if parts.size() == 2 and parts[1] != "":
            return "res://textures/icons".path_join(parts[1])
    return "res://textures/icons/" + icon_id + ".png"


func _resolve_icon_texture(icon_id: String) -> Texture2D:
    var core = Engine.get_meta("TajsCore", null)
    if core != null:
        var registry = core.get_icon_registry()
        if registry != null:
            var resolved: Dictionary = registry.resolve_icon(icon_id)
            if resolved.get("texture", null) != null:
                return resolved.texture
    if icon_id == "":
        return load(DEFAULT_ICON_PATH)
    if icon_id.begins_with("res://") and ResourceLoader.exists(icon_id):
        return load(icon_id)
    if icon_id.find(":") != -1:
        var parts := icon_id.split(":", false, 1)
        if parts.size() == 2 and parts[1] != "":
            var mapped_path := "res://textures/icons".path_join(parts[1])
            if ResourceLoader.exists(mapped_path):
                return load(mapped_path)
    var fallback_path := "res://textures/icons/" + icon_id + ".png"
    if ResourceLoader.exists(fallback_path):
        return load(fallback_path)
    return null


func set_qol_patterns_enabled(enabled: bool) -> void:
    _patterns_enabled = enabled
    if _patterns_enabled:
        _ensure_pattern_ui()
        _load_from_settings()
        update_color()
        update_pattern()
    else:
        _remove_pattern_drawers()
        _hide_pattern_ui()
        custom_color = Color.TRANSPARENT
        pattern_index = 0
        color = clampi(color, 0, VANILLA_COLORS.size() - 1)
        update_color()
        update_pattern()


func set_qol_color_picker_enabled(enabled: bool) -> void:
    _color_picker_enabled = enabled
    if not _patterns_enabled:
        return
    if _color_picker_enabled:
        _setup_color_picker()
    else:
        _hide_color_picker_ui()
    update_color()


func update_color() -> void:
    if not _patterns_enabled:
        color = clampi(color, 0, VANILLA_COLORS.size() - 1)
        super.update_color()
        return
    if not _color_picker_enabled:
        color = clampi(color, 0, VANILLA_COLORS.size() - 1)
        var vanilla_color = Color(VANILLA_COLORS[color])
        $TitlePanel.self_modulate = vanilla_color
        $PanelContainer.self_modulate = vanilla_color
        return
    var use_color: Color
    if custom_color != Color.TRANSPARENT:
        use_color = custom_color
    else:
        use_color = Color(VANILLA_COLORS[clampi(color, 0, VANILLA_COLORS.size() - 1)])
    $TitlePanel.self_modulate = use_color
    $PanelContainer.self_modulate = use_color


func cycle_color() -> void:
    if not _patterns_enabled:
        super.cycle_color()
        return
    if _open_color_picker():
        return
    color += 1
    if color >= VANILLA_COLORS.size():
        color = 0
    custom_color = Color.TRANSPARENT
    update_color()
    color_changed.emit()


func _on_color_button_pressed() -> void:
    if not _patterns_enabled:
        super._on_color_button_pressed()
        return
    cycle_color()


func update_pattern() -> void:
    for drawer in pattern_drawers:
        drawer.set_pattern(pattern_index)
        drawer.set_style(pattern_color, pattern_alpha, pattern_spacing, pattern_thickness)


func _setup_color_picker() -> void:
    if not _color_picker_enabled:
        return
    if _color_picker_layer != null:
        if not _color_picker_layer.is_inside_tree() and get_tree() != null:
            get_tree().root.call_deferred("add_child", _color_picker_layer)
        if _color_picker == null:
            _create_color_picker_panel()
        return
    _color_picker_layer = CanvasLayer.new()
    _color_picker_layer.name = "QolColorPickerLayer"
    _color_picker_layer.layer = 100
    _color_picker_layer.visible = false
    if get_tree() != null:
        get_tree().root.call_deferred("add_child", _color_picker_layer)
    else:
        call_deferred("_ensure_color_picker_in_tree")

    var bg_overlay = ColorRect.new()
    bg_overlay.name = "BackgroundOverlay"
    bg_overlay.color = Color(0, 0, 0, 0.4)
    bg_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    bg_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
    bg_overlay.gui_input.connect(func(event):
        if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
            _color_picker_layer.visible = false
    )
    _color_picker_layer.add_child(bg_overlay)

    _create_color_picker_panel()


func _create_color_picker_panel() -> void:
    if _color_picker != null:
        return
    if _color_picker_layer == null:
        return
    _color_picker = ColorPickerPanelScript.new()
    _color_picker.name = "QolColorPickerPanel"
    if _color_picker.has_method("setup"):
        _color_picker.call("setup", _get_core_settings(), "tajs_qol.color_picker")
    var initial_color = custom_color if custom_color != Color.TRANSPARENT else Color(VANILLA_COLORS[clampi(color, 0, VANILLA_COLORS.size() - 1)])
    _color_picker.set_color(initial_color)
    _color_picker.color_changed.connect(_on_color_picked)
    _color_picker.color_committed.connect(func(_c):
        _color_picker_layer.visible = false
    )
    _color_picker_layer.add_child(_color_picker)


func _ensure_color_picker_in_tree() -> void:
    if _color_picker_layer != null and not _color_picker_layer.is_inside_tree() and get_tree() != null:
        get_tree().root.call_deferred("add_child", _color_picker_layer)


func _setup_pattern_picker() -> void:
    if _pattern_picker_layer != null:
        if not _pattern_picker_layer.is_inside_tree() and get_tree() != null:
            get_tree().root.call_deferred("add_child", _pattern_picker_layer)
        _add_pattern_button()
        return
    _pattern_picker_layer = CanvasLayer.new()
    _pattern_picker_layer.name = "QolPatternPickerLayer"
    _pattern_picker_layer.layer = 101
    _pattern_picker_layer.visible = false

    var bg_overlay = ColorRect.new()
    bg_overlay.name = "BackgroundOverlay"
    bg_overlay.color = Color(0, 0, 0, 0.4)
    bg_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    bg_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
    bg_overlay.gui_input.connect(func(event):
        if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
            _close_pattern_picker()
    )
    _pattern_picker_layer.add_child(bg_overlay)

    _pattern_picker = PatternPickerPanelScript.new()
    _pattern_picker.name = "QolPatternPickerPanel"
    _pattern_picker.set_settings(pattern_index, pattern_color, pattern_alpha, pattern_spacing, pattern_thickness)
    _pattern_picker.settings_changed.connect(_on_pattern_settings_changed)
    _pattern_picker.settings_committed.connect(func(_idx, _c, _a, _sp, _th):
        _close_pattern_picker()
    )
    _pattern_picker_layer.add_child(_pattern_picker)

    if get_tree() != null:
        get_tree().root.call_deferred("add_child", _pattern_picker_layer)
    _add_pattern_button()


func _ensure_pattern_ui() -> void:
    _setup_color_picker()
    _setup_pattern_picker()
    _inject_pattern_drawers()


func _add_pattern_button() -> void:
    var title_panel = get_node_or_null("TitlePanel")
    if title_panel == null:
        return
    var title_container = title_panel.get_node_or_null("TitleContainer")
    if title_container == null:
        return
    if title_container.has_node("PatternButton"):
        return
    var pattern_btn = Button.new()
    pattern_btn.name = "PatternButton"
    pattern_btn.custom_minimum_size = Vector2(40, 40)
    pattern_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
    pattern_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
    pattern_btn.focus_mode = Control.FOCUS_NONE
    pattern_btn.theme_type_variation = "SettingButton"
    pattern_btn.add_theme_constant_override("icon_max_width", 20)
    pattern_btn.icon = load("res://textures/icons/grid.png")
    pattern_btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
    pattern_btn.expand_icon = true
    pattern_btn.tooltip_text = "Pattern Settings"
    pattern_btn.pressed.connect(_open_pattern_picker)
    var color_btn = title_container.get_node_or_null("ColorButton")
    if color_btn != null:
        title_container.add_child(pattern_btn)
        title_container.move_child(pattern_btn, color_btn.get_index())
    else:
        title_container.add_child(pattern_btn)


func _inject_pattern_drawers() -> void:
    if not pattern_drawers.is_empty():
        return
    var body_panel = get_node_or_null("PanelContainer")
    if body_panel:
        var body_drawer = PatternDrawerScript.new()
        body_drawer.set_anchors_preset(Control.PRESET_FULL_RECT)
        body_drawer.mouse_filter = Control.MOUSE_FILTER_IGNORE
        body_panel.add_child(body_drawer)
        body_panel.move_child(body_drawer, 0)
        pattern_drawers.append(body_drawer)


func _remove_pattern_drawers() -> void:
    for drawer in pattern_drawers:
        if is_instance_valid(drawer):
            drawer.queue_free()
    pattern_drawers.clear()


func _hide_pattern_ui() -> void:
    if _pattern_picker_layer:
        _pattern_picker_layer.visible = false
    if _color_picker_layer:
        _color_picker_layer.visible = false
    var title_panel = get_node_or_null("TitlePanel")
    if title_panel:
        var title_container = title_panel.get_node_or_null("TitleContainer")
        if title_container and title_container.has_node("PatternButton"):
            title_container.get_node("PatternButton").queue_free()


func _hide_color_picker_ui() -> void:
    if _color_picker_layer:
        _color_picker_layer.visible = false


func _open_pattern_picker() -> void:
    if _pattern_picker_layer:
        _undo_before_state = GroupPatternChangedCommand.capture_state(self )
        _pattern_picker.set_settings(pattern_index, pattern_color, pattern_alpha, pattern_spacing, pattern_thickness)
        _pattern_picker_layer.visible = true
        _pattern_picker.position = (_pattern_picker.get_viewport_rect().size - _pattern_picker.size) / 2
        Sound.play("click2")


func _open_color_picker() -> bool:
    if not _color_picker_enabled:
        return false
    _setup_color_picker()
    if _color_picker_layer and _color_picker:
        _undo_before_state = GroupPatternChangedCommand.capture_state(self )
        _color_picker_layer.visible = true
        _color_picker.position = (_color_picker.get_viewport_rect().size - _color_picker.size) / 2
        Sound.play("click2")
        return true
    return false


func _close_pattern_picker() -> void:
    if _pattern_picker_layer:
        _pattern_picker_layer.visible = false


func _on_pattern_settings_changed(idx: int, c: Color, a: float, sp: float, th: float) -> void:
    pattern_index = idx
    pattern_color = c
    pattern_alpha = a
    pattern_spacing = sp
    pattern_thickness = th
    update_pattern()
    _save_to_settings()
    _push_pattern_undo_command()


func _on_color_picked(new_color: Color) -> void:
    custom_color = new_color
    color = _find_nearest_vanilla_color_index(new_color)
    update_color()
    color_changed.emit()
    _save_to_settings()
    _push_pattern_undo_command()
    Sound.play("click2")


func toggle_lock() -> void:
    locked = !locked
    _save_lock_to_settings()
    if locked:
        Signals.notify.emit("lock", "Group locked")
    else:
        Signals.notify.emit("unlock", "Group unlocked")


func is_locked() -> bool:
    return locked


func grab(g: bool) -> void:
    if locked and g:
        Sound.play("error")
        return
    super.grab(g)


func _on_move_selection(to: Vector2) -> void:
    if locked:
        return


func set_resizing(l: bool, t: bool, r: bool, b: bool) -> void:
    if locked and (l or t or r or b):
        Sound.play("error")
        return
    super.set_resizing(l, t, r, b)


func _find_nearest_vanilla_color_index(target: Color) -> int:
    var best_index := 0
    var best_distance := INF
    for i in range(VANILLA_COLORS.size()):
        var vanilla_color = Color(VANILLA_COLORS[i])
        var distance = sqrt(
            pow(target.r - vanilla_color.r, 2) +
            pow(target.g - vanilla_color.g, 2) +
            pow(target.b - vanilla_color.b, 2)
        )
        if distance < best_distance:
            best_distance = distance
            best_index = i
    return best_index


func _load_from_settings() -> void:
    var pattern_data = _get_group_data()
    if pattern_data.is_empty():
        return
    if pattern_data.has("pattern_index"):
        pattern_index = int(pattern_data["pattern_index"])
    if pattern_data.has("pattern_color"):
        pattern_color = Color.html(str(pattern_data["pattern_color"]))
    if pattern_data.has("pattern_alpha"):
        pattern_alpha = float(pattern_data["pattern_alpha"])
    if pattern_data.has("pattern_spacing"):
        pattern_spacing = float(pattern_data["pattern_spacing"])
    if pattern_data.has("pattern_thickness"):
        pattern_thickness = float(pattern_data["pattern_thickness"])
    if pattern_data.has("custom_color") and str(pattern_data["custom_color"]) != "":
        custom_color = Color.html(str(pattern_data["custom_color"]))


func _save_to_settings() -> void:
    var settings = _get_core_settings()
    if settings == null:
        return
    var all_data: Dictionary = settings.get_dict(SETTINGS_DATA_KEY, {})
    var entry := {
        "pattern_index": pattern_index,
        "pattern_color": pattern_color.to_html(true),
        "pattern_alpha": pattern_alpha,
        "pattern_spacing": pattern_spacing,
        "pattern_thickness": pattern_thickness,
    }
    if custom_color != Color.TRANSPARENT:
        entry["custom_color"] = custom_color.to_html(true)
    all_data[_get_group_key()] = entry
    settings.set_value(SETTINGS_DATA_KEY, all_data)


func _get_group_data() -> Dictionary:
    var settings = _get_core_settings()
    if settings == null:
        return {}
    var all_data: Dictionary = settings.get_dict(SETTINGS_DATA_KEY, {})
    var key := _get_group_key()
    var entry = all_data.get(key, {})
    if entry is Dictionary:
        return entry

    var legacy_key := str(name)
    if legacy_key != "" and legacy_key != key:
        var legacy_entry = all_data.get(legacy_key, {})
        if legacy_entry is Dictionary:
            all_data[key] = legacy_entry
            all_data.erase(legacy_key)
            settings.set_value(SETTINGS_DATA_KEY, all_data)
            return legacy_entry

    return {}


func _get_group_key() -> String:
    return _ensure_group_style_id()


func _ensure_group_style_id() -> String:
    if qol_group_style_id != "":
        return qol_group_style_id
    qol_group_style_id = Utils.generate_simple_id()
    return qol_group_style_id


func qol_migrate_style_keys() -> void:
    _ensure_group_style_id()
    _migrate_pattern_settings_entry()
    _migrate_lock_settings_entry()


func _migrate_pattern_settings_entry() -> void:
    var settings = _get_core_settings()
    if settings == null:
        return
    var all_data: Dictionary = settings.get_dict(SETTINGS_DATA_KEY, {})
    var key := _get_group_key()
    var legacy_key := str(name)
    if legacy_key == "" or legacy_key == key:
        return

    var id_entry = all_data.get(key, null)
    var legacy_entry = all_data.get(legacy_key, null)
    if not (legacy_entry is Dictionary):
        return

    if id_entry is Dictionary:
        if id_entry == legacy_entry:
            all_data.erase(legacy_key)
            settings.set_value(SETTINGS_DATA_KEY, all_data)
        return

    all_data[key] = legacy_entry
    all_data.erase(legacy_key)
    settings.set_value(SETTINGS_DATA_KEY, all_data)


func _migrate_lock_settings_entry() -> void:
    var settings = _get_core_settings()
    if settings == null:
        return
    var all_data: Dictionary = settings.get_dict(SETTINGS_LOCK_DATA_KEY, {})
    var key := _get_group_key()
    var legacy_key := str(name)
    if legacy_key == "" or legacy_key == key:
        return

    var id_entry = all_data.get(key, null)
    var legacy_entry = all_data.get(legacy_key, null)
    if not (legacy_entry is bool):
        return

    if id_entry is bool:
        if id_entry == legacy_entry:
            all_data.erase(legacy_key)
            settings.set_value(SETTINGS_LOCK_DATA_KEY, all_data)
        return

    all_data[key] = legacy_entry
    all_data.erase(legacy_key)
    settings.set_value(SETTINGS_LOCK_DATA_KEY, all_data)


func _load_lock_from_settings() -> void:
    var settings = _get_core_settings()
    if settings == null:
        return
    var all_data: Dictionary = settings.get_dict(SETTINGS_LOCK_DATA_KEY, {})
    var key := _get_group_key()
    var entry = all_data.get(key, null)
    if entry is bool:
        locked = entry
        return

    var legacy_key := str(name)
    if legacy_key != "" and legacy_key != key:
        var legacy_entry = all_data.get(legacy_key, null)
        if legacy_entry is bool:
            locked = legacy_entry
            all_data[key] = legacy_entry
            all_data.erase(legacy_key)
            settings.set_value(SETTINGS_LOCK_DATA_KEY, all_data)
            return

    locked = false


func _save_lock_to_settings() -> void:
    var settings = _get_core_settings()
    if settings == null:
        return
    var all_data: Dictionary = settings.get_dict(SETTINGS_LOCK_DATA_KEY, {})
    if locked:
        all_data[_get_group_key()] = true
    else:
        all_data.erase(_get_group_key())
    settings.set_value(SETTINGS_LOCK_DATA_KEY, all_data)


func _is_patterns_enabled() -> bool:
    var settings = _get_core_settings()
    if settings == null:
        return true
    return settings.get_bool(SETTINGS_ENABLED_KEY, true)


func _is_color_picker_enabled() -> bool:
    var settings = _get_core_settings()
    if settings == null:
        return true
    return settings.get_bool(SETTINGS_COLOR_PICKER_ENABLED_KEY, true)


func _push_pattern_undo_command() -> void:
    if _undo_before_state.is_empty():
        return
    var core = Engine.get_meta("TajsCore", null)
    if core == null:
        return
    var undo_manager = core.undo_manager
    if undo_manager == null or not undo_manager.is_enabled():
        return
    var after_state := GroupPatternChangedCommand.capture_state(self )
    # Only push if something actually changed
    if _undo_before_state == after_state:
        return
    var cmd = GroupPatternChangedCommand.new()
    cmd.setup(self , _undo_before_state, after_state)
    undo_manager.push_command(cmd)
    _undo_before_state = after_state


func export() -> Dictionary:
    return super.export().merged({
        "qol_group_style_id": _ensure_group_style_id()
    })


func save() -> Dictionary:
    return super.save().merged({
        "qol_group_style_id": _ensure_group_style_id()
    })


func _get_core_settings():
    if Engine.has_meta("TajsCore"):
        var core = Engine.get_meta("TajsCore")
        if core != null and core.settings != null:
            return core.settings
    return null
