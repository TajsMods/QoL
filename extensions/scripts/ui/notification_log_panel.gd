extends Control

const LOG_NAME := "TajemnikTV-QoL:NotificationLog"
const STORAGE_MODULE_ID := "TajemnikTV-QoL"
const STORAGE_FILE_NAME := "notification_inbox.json"
const STORAGE_KIND := "notification_inbox"

const FILTER_ALL := "all"
const FILTER_UNREAD := "unread"
const FILTER_WARNINGS_ERRORS := "warnings_errors"
const FILTER_UNLOCKS := "unlocks"

const CATEGORY_UNLOCKS := "unlocks"
const CATEGORY_WARNINGS := "warnings"
const CATEGORY_ERRORS := "errors"
const CATEGORY_DIAGNOSTICS := "diagnostics"
const CATEGORY_ACHIEVEMENTS := "achievements"
const CATEGORY_QOL_ACTIONS := "qol_actions"

const ACTION_JUMP_TO_NODE := "jump_to_node"
const ACTION_OPEN_SETTINGS := "open_settings"
const ACTION_OPEN_DIAGNOSTICS := "open_diagnostics"
const ACTION_DISMISS := "dismiss"
const ACTION_SNOOZE := "snooze"
const ACTION_CORE_ACTION := "core_action"

var max_notifications: int = 20

var toggle_btn: Button = null
var popup_panel: PanelContainer = null
var scroll_container: ScrollContainer = null
var notifications_container: VBoxContainer = null
var clear_btn: Button = null
var empty_label: Label = null
var filter_dropdown: OptionButton = null

var is_popup_open: bool = false
var notifications: Array[Dictionary] = []
var unread_count: int = 0
var unread_badge: Label = null
var current_filter: String = FILTER_ALL

var _core: Variant = null
var _next_id: int = 1


func setup(core: Variant) -> void:
    _core = core
    _load_state()


func _ready() -> void:
    _build_ui()
    if popup_panel:
        popup_panel.visible = false
    _recalculate_unread_count()
    _update_badge()


func set_max_notifications(value: int) -> void:
    max_notifications = maxi(1, value)
    _trim_notifications()
    _save_state()
    if is_popup_open:
        _refresh_notifications_display()


func _build_ui() -> void:
    name = "NotificationLogPanel"
    custom_minimum_size = Vector2(80, 80)
    size_flags_horizontal = Control.SIZE_SHRINK_CENTER
    size_flags_vertical = Control.SIZE_SHRINK_CENTER

    toggle_btn = Button.new()
    toggle_btn.name = "NotificationLogButton"
    toggle_btn.custom_minimum_size = Vector2(80, 80)
    toggle_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER | Control.SIZE_EXPAND
    toggle_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
    toggle_btn.focus_mode = Control.FOCUS_NONE
    toggle_btn.theme_type_variation = "ButtonMenu"
    toggle_btn.icon = load("res://textures/icons/exclamation.png")
    toggle_btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
    toggle_btn.expand_icon = true
    toggle_btn.tooltip_text = "Notification History"
    toggle_btn.pressed.connect(_on_toggle_pressed)
    add_child(toggle_btn)

    unread_badge = Label.new()
    unread_badge.name = "UnreadBadge"
    unread_badge.text = ""
    unread_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    unread_badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    unread_badge.add_theme_font_size_override("font_size", 12)
    unread_badge.add_theme_color_override("font_color", Color.WHITE)
    unread_badge.custom_minimum_size = Vector2(18, 18)
    unread_badge.visible = false

    var badge_style = StyleBoxFlat.new()
    badge_style.bg_color = Color(0.9, 0.2, 0.2, 1.0)
    badge_style.set_corner_radius_all(9)
    unread_badge.add_theme_stylebox_override("normal", badge_style)

    unread_badge.position = Vector2(32, -4)
    toggle_btn.add_child(unread_badge)

    popup_panel = PanelContainer.new()
    popup_panel.name = "NotificationLogPopup"
    popup_panel.visible = false
    popup_panel.custom_minimum_size = Vector2(460, 0)
    popup_panel.theme_type_variation = "MenuPanel"
    add_child(popup_panel)

    var main_vbox = VBoxContainer.new()
    main_vbox.add_theme_constant_override("separation", 12)
    popup_panel.add_child(main_vbox)

    var header = HBoxContainer.new()
    header.add_theme_constant_override("separation", 12)
    main_vbox.add_child(header)

    var title = Label.new()
    title.text = "Notification History"
    title.add_theme_font_size_override("font_size", 24)
    title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    header.add_child(title)

    clear_btn = Button.new()
    clear_btn.text = "Clear"
    clear_btn.custom_minimum_size = Vector2(80, 36)
    clear_btn.focus_mode = Control.FOCUS_NONE
    clear_btn.theme_type_variation = "TabButton"
    clear_btn.pressed.connect(_on_clear_pressed)
    header.add_child(clear_btn)

    filter_dropdown = OptionButton.new()
    filter_dropdown.custom_minimum_size = Vector2(170, 36)
    filter_dropdown.focus_mode = Control.FOCUS_NONE
    filter_dropdown.theme_type_variation = "TabButton"
    filter_dropdown.add_item("All")
    filter_dropdown.add_item("Unread")
    filter_dropdown.add_item("Warnings/Errors")
    filter_dropdown.add_item("Unlocks")
    filter_dropdown.selected = _filter_index_for_value(current_filter)
    filter_dropdown.item_selected.connect(_on_filter_selected)
    header.add_child(filter_dropdown)

    var sep = HSeparator.new()
    sep.add_theme_constant_override("separation", 8)
    main_vbox.add_child(sep)

    scroll_container = ScrollContainer.new()
    scroll_container.name = "NotificationsScroll"
    scroll_container.custom_minimum_size = Vector2(430, 80)
    scroll_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    scroll_container.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
    scroll_container.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    scroll_container.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
    main_vbox.add_child(scroll_container)

    notifications_container = VBoxContainer.new()
    notifications_container.name = "NotificationsList"
    notifications_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    notifications_container.add_theme_constant_override("separation", 6)
    scroll_container.add_child(notifications_container)

    empty_label = Label.new()
    empty_label.text = "No notifications yet"
    empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    empty_label.add_theme_color_override("font_color", Color(0.5, 0.55, 0.65))
    empty_label.add_theme_font_size_override("font_size", 18)
    notifications_container.add_child(empty_label)


func _process(_delta: float) -> void:
    if is_popup_open and Input.is_action_just_pressed("ui_cancel"):
        _close_popup()


func _input(event: InputEvent) -> void:
    if is_popup_open and event is InputEventMouseButton:
        if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
            var local_pos = popup_panel.get_local_mouse_position()
            var btn_local = toggle_btn.get_local_mouse_position()
            var in_popup = Rect2(Vector2.ZERO, popup_panel.size).has_point(local_pos)
            var in_btn = Rect2(Vector2.ZERO, toggle_btn.size).has_point(btn_local)
            if not in_popup and not in_btn:
                _close_popup()


func _on_toggle_pressed() -> void:
    Sound.play("click2")
    if is_popup_open:
        _close_popup()
    else:
        _open_popup()


func _open_popup() -> void:
    is_popup_open = true
    _mark_all_visible_as_read()
    _refresh_notifications_display()
    scroll_container.scroll_vertical = 0
    popup_panel.visible = true
    _position_popup()


func _close_popup() -> void:
    is_popup_open = false
    popup_panel.visible = false


func _position_popup() -> void:
    await get_tree().process_frame
    var btn_global = toggle_btn.global_position
    var popup_size = popup_panel.size
    var viewport_size = get_viewport().get_visible_rect().size
    popup_panel.global_position = Vector2(btn_global.x, 0)
    if popup_panel.global_position.x + popup_size.x > viewport_size.x - 10:
        popup_panel.global_position.x = viewport_size.x - popup_size.x - 10
    if popup_panel.global_position.x < 10:
        popup_panel.global_position.x = 10


func add_notification(icon: String, text: String) -> void:
    var category := _infer_category(icon, text)
    add_notification_entry({
        "icon": icon,
        "text": text,
        "category": category
    })


func add_notification_entry(entry: Dictionary) -> int:
    var normalized := _normalize_entry(entry)
    notifications.insert(0, normalized)
    _trim_notifications()
    if is_popup_open:
        normalized["unread"] = false
    _recalculate_unread_count()
    _update_badge()
    _save_state()
    if is_popup_open:
        _refresh_notifications_display()
    return int(normalized.get("id", -1))


func clear_notifications() -> void:
    notifications.clear()
    unread_count = 0
    _next_id = 1
    _update_badge()
    _save_state()
    _refresh_notifications_display()


func _trim_notifications() -> void:
    while notifications.size() > max_notifications:
        notifications.pop_back()


func _update_badge() -> void:
    if unread_count > 0:
        unread_badge.text = str(unread_count) if unread_count < 100 else "99+"
        unread_badge.visible = true
    else:
        unread_badge.visible = false


func _on_clear_pressed() -> void:
    Sound.play("click2")
    clear_notifications()


func _on_filter_selected(index: int) -> void:
    match index:
        1:
            current_filter = FILTER_UNREAD
        2:
            current_filter = FILTER_WARNINGS_ERRORS
        3:
            current_filter = FILTER_UNLOCKS
        _:
            current_filter = FILTER_ALL
    if is_popup_open:
        _mark_all_visible_as_read()
    _refresh_notifications_display()
    _save_state()


func _refresh_notifications_display() -> void:
    for child in notifications_container.get_children():
        if child != empty_label:
            notifications_container.remove_child(child)
            child.queue_free()

    var visible_entries := _get_visible_notifications()
    if visible_entries.is_empty():
        empty_label.visible = true
        scroll_container.custom_minimum_size.y = 40
        return

    empty_label.visible = false
    var item_height = 92
    var max_visible = 6
    var total_height = visible_entries.size() * item_height + (visible_entries.size() - 1) * 6
    var max_height = max_visible * item_height
    scroll_container.custom_minimum_size.y = min(total_height, max_height)

    for entry in visible_entries:
        var row = _create_notification_row(entry)
        notifications_container.add_child(row)


func _create_notification_row(entry: Dictionary) -> Control:
    var row_panel = PanelContainer.new()
    row_panel.custom_minimum_size = Vector2(0, 88)

    var row_style = StyleBoxFlat.new()
    row_style.bg_color = Color(0.1, 0.12, 0.16, 0.9)
    row_style.border_color = _category_border_color(str(entry.get("category", CATEGORY_QOL_ACTIONS)))
    row_style.set_border_width_all(1)
    row_style.set_corner_radius_all(8)
    row_style.set_content_margin_all(10)
    row_panel.add_theme_stylebox_override("panel", row_style)

    var outer = VBoxContainer.new()
    outer.add_theme_constant_override("separation", 8)
    row_panel.add_child(outer)

    var top_row = HBoxContainer.new()
    top_row.add_theme_constant_override("separation", 10)
    top_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    outer.add_child(top_row)

    var icon_tex = TextureRect.new()
    icon_tex.custom_minimum_size = Vector2(24, 24)
    icon_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    icon_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE

    var icon_name := str(entry.get("icon", ""))
    var icon_path = "res://textures/icons/" + icon_name + ".png"
    if ResourceLoader.exists(icon_path):
        icon_tex.texture = load(icon_path)
    else:
        icon_tex.texture = load("res://textures/icons/exclamation.png")
    top_row.add_child(icon_tex)

    var text_label = Label.new()
    text_label.text = tr(str(entry.get("text", "")))
    text_label.add_theme_font_size_override("font_size", 18)
    text_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    text_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
    text_label.clip_text = true
    top_row.add_child(text_label)

    var category_label = Label.new()
    category_label.text = _category_display_name(str(entry.get("category", CATEGORY_QOL_ACTIONS)))
    category_label.add_theme_font_size_override("font_size", 13)
    category_label.add_theme_color_override("font_color", Color(0.62, 0.72, 0.9))
    top_row.add_child(category_label)

    var time_label = Label.new()
    time_label.text = _format_time_ago(int(entry.get("time", 0)))
    time_label.add_theme_font_size_override("font_size", 14)
    time_label.add_theme_color_override("font_color", Color(0.5, 0.55, 0.65))
    time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    time_label.custom_minimum_size = Vector2(45, 0)
    top_row.add_child(time_label)

    var actions_row = HBoxContainer.new()
    actions_row.add_theme_constant_override("separation", 6)
    outer.add_child(actions_row)

    var actions = _effective_actions(entry)
    for action_entry in actions:
        var button = Button.new()
        button.custom_minimum_size = Vector2(0, 28)
        button.focus_mode = Control.FOCUS_NONE
        button.theme_type_variation = "TabButton"
        button.text = str(action_entry.get("label", "Action"))
        button.pressed.connect(func():
            _run_notification_action(entry, action_entry)
        )
        actions_row.add_child(button)

    return row_panel


func _effective_actions(entry: Dictionary) -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    var custom_actions: Variant = entry.get("actions", [])
    if custom_actions is Array:
        for candidate in custom_actions:
            if candidate is Dictionary:
                var normalized = _normalize_action(candidate)
                if not normalized.is_empty():
                    result.append(normalized)
    if result.is_empty():
        result.append({"type": ACTION_DISMISS, "label": "Dismiss"})
        result.append({"type": ACTION_SNOOZE, "label": "Snooze"})
    return result


func _run_notification_action(entry: Dictionary, action_entry: Dictionary) -> void:
    var action_type := str(action_entry.get("type", "")).strip_edges()
    if action_type == "":
        return

    var success := true
    match action_type:
        ACTION_DISMISS:
            _set_notification_dismissed(int(entry.get("id", -1)), true)
        ACTION_SNOOZE:
            var snooze_seconds := maxi(60, int(action_entry.get("snooze_seconds", 600)))
            _snooze_notification(int(entry.get("id", -1)), snooze_seconds)
        ACTION_CORE_ACTION:
            success = _run_core_action(str(action_entry.get("command_id", "")), action_entry.get("context", {}))
        ACTION_OPEN_SETTINGS:
            success = _open_settings(action_entry)
        ACTION_OPEN_DIAGNOSTICS:
            success = _open_diagnostics(action_entry)
        ACTION_JUMP_TO_NODE:
            success = _jump_to_node(action_entry)
        _:
            success = false

    if not success:
        _notify_failure("Notification action failed")


func _set_notification_dismissed(notification_id: int, dismissed: bool) -> void:
    for i in range(notifications.size()):
        if int(notifications[i].get("id", -1)) == notification_id:
            notifications[i]["dismissed"] = dismissed
            notifications[i]["unread"] = false
            break
    _recalculate_unread_count()
    _update_badge()
    _save_state()
    _refresh_notifications_display()


func _snooze_notification(notification_id: int, seconds: int) -> void:
    var until := int(Time.get_unix_time_from_system()) + seconds
    for i in range(notifications.size()):
        if int(notifications[i].get("id", -1)) == notification_id:
            notifications[i]["snoozed_until"] = until
            notifications[i]["unread"] = false
            break
    _recalculate_unread_count()
    _update_badge()
    _save_state()
    _refresh_notifications_display()


func _jump_to_node(action_entry: Dictionary) -> bool:
    if _core == null:
        return false
    var command_id := str(action_entry.get("command_id", "")).strip_edges()
    if command_id != "":
        return _run_core_action(command_id, action_entry.get("context", {}))
    return false


func _open_settings(action_entry: Dictionary) -> bool:
    if _core == null or _core.ui_manager == null:
        return false
    if action_entry.has("command_id"):
        return _run_core_action(str(action_entry.get("command_id", "")), action_entry.get("context", {}))
    if _core.ui_manager.has_method("_on_settings_button_pressed"):
        _core.ui_manager.call("_on_settings_button_pressed")
        return true
    return false


func _open_diagnostics(action_entry: Dictionary) -> bool:
    if action_entry.has("command_id"):
        return _run_core_action(str(action_entry.get("command_id", "")), action_entry.get("context", {}))
    if _core == null or _core.diagnostics == null:
        return false
    if _core.diagnostics.has_method("generate_dump"):
        var _dump: String = _core.diagnostics.generate_dump()
        return true
    return false


func _run_core_action(command_id: String, context: Variant = null) -> bool:
    if command_id == "" or _core == null:
        return false
    if _core.has_method("run_command"):
        return bool(_core.run_command(command_id, context))
    return false


func _notify_failure(message: String) -> void:
    if _core != null and _core.has_method("notify"):
        _core.notify("cross", message)
    else:
        print("%s %s" % [LOG_NAME, message])


func _get_visible_notifications() -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    var now := int(Time.get_unix_time_from_system())
    for entry in notifications:
        if bool(entry.get("dismissed", false)):
            continue
        var snoozed_until := int(entry.get("snoozed_until", 0))
        if snoozed_until > now:
            continue
        if _matches_filter(entry):
            result.append(entry)
    return result


func _matches_filter(entry: Dictionary) -> bool:
    match current_filter:
        FILTER_UNREAD:
            return bool(entry.get("unread", false))
        FILTER_WARNINGS_ERRORS:
            var category := str(entry.get("category", CATEGORY_QOL_ACTIONS))
            return category == CATEGORY_WARNINGS or category == CATEGORY_ERRORS
        FILTER_UNLOCKS:
            return str(entry.get("category", CATEGORY_QOL_ACTIONS)) == CATEGORY_UNLOCKS
        _:
            return true


func _mark_all_visible_as_read() -> void:
    var changed := false
    var now := int(Time.get_unix_time_from_system())
    for i in range(notifications.size()):
        var entry := notifications[i]
        if bool(entry.get("dismissed", false)):
            continue
        if int(entry.get("snoozed_until", 0)) > now:
            continue
        if not _matches_filter(entry):
            continue
        if bool(entry.get("unread", false)):
            notifications[i]["unread"] = false
            changed = true
    if changed:
        _recalculate_unread_count()
        _update_badge()
        _save_state()


func _recalculate_unread_count() -> void:
    var count := 0
    var now := int(Time.get_unix_time_from_system())
    for entry in notifications:
        if bool(entry.get("dismissed", false)):
            continue
        if int(entry.get("snoozed_until", 0)) > now:
            continue
        if bool(entry.get("unread", false)):
            count += 1
    unread_count = mini(count, 999)


func _normalize_entry(entry: Dictionary) -> Dictionary:
    var normalized: Dictionary = {}
    normalized["id"] = int(entry.get("id", _next_id))
    normalized["icon"] = str(entry.get("icon", "exclamation"))
    normalized["text"] = str(entry.get("text", ""))
    normalized["time"] = int(entry.get("time", Time.get_unix_time_from_system()))
    normalized["category"] = _sanitize_category(str(entry.get("category", _infer_category(str(entry.get("icon", "")), str(entry.get("text", ""))))))
    normalized["unread"] = true if entry.get("unread", true) else false
    normalized["dismissed"] = true if entry.get("dismissed", false) else false
    normalized["snoozed_until"] = int(entry.get("snoozed_until", 0))

    var actions_raw: Variant = entry.get("actions", [])
    var actions: Array[Dictionary] = []
    if actions_raw is Array:
        for candidate in actions_raw:
            if candidate is Dictionary:
                var normalized_action = _normalize_action(candidate)
                if not normalized_action.is_empty():
                    actions.append(normalized_action)
    normalized["actions"] = actions

    _next_id = maxi(_next_id, int(normalized["id"]) + 1)
    return normalized


func _normalize_action(action_entry: Dictionary) -> Dictionary:
    var action_type := str(action_entry.get("type", "")).strip_edges()
    if action_type == "":
        return {}
    var normalized := action_entry.duplicate(true)
    normalized["type"] = action_type
    if str(normalized.get("label", "")).strip_edges() == "":
        normalized["label"] = _default_action_label(action_type)
    return normalized


func _default_action_label(action_type: String) -> String:
    match action_type:
        ACTION_JUMP_TO_NODE:
            return "Jump"
        ACTION_OPEN_SETTINGS:
            return "Settings"
        ACTION_OPEN_DIAGNOSTICS:
            return "Diagnostics"
        ACTION_DISMISS:
            return "Dismiss"
        ACTION_SNOOZE:
            return "Snooze"
        ACTION_CORE_ACTION:
            return "Run"
        _:
            return "Action"


func _sanitize_category(category: String) -> String:
    match category:
        CATEGORY_UNLOCKS, CATEGORY_WARNINGS, CATEGORY_ERRORS, CATEGORY_DIAGNOSTICS, CATEGORY_ACHIEVEMENTS, CATEGORY_QOL_ACTIONS:
            return category
        _:
            return CATEGORY_QOL_ACTIONS


func _infer_category(icon: String, text: String) -> String:
    var icon_l := icon.to_lower()
    var text_l := text.to_lower()
    if icon_l == "cross" or "error" in text_l or "failed" in text_l:
        return CATEGORY_ERRORS
    if icon_l == "exclamation" or "warning" in text_l or "warn" in text_l:
        return CATEGORY_WARNINGS
    if "unlock" in text_l:
        return CATEGORY_UNLOCKS
    if "achievement" in text_l:
        return CATEGORY_ACHIEVEMENTS
    if "diagnostic" in text_l or "debug" in text_l:
        return CATEGORY_DIAGNOSTICS
    return CATEGORY_QOL_ACTIONS


func _category_display_name(category: String) -> String:
    match category:
        CATEGORY_UNLOCKS:
            return "Unlock"
        CATEGORY_WARNINGS:
            return "Warning"
        CATEGORY_ERRORS:
            return "Error"
        CATEGORY_DIAGNOSTICS:
            return "Diagnostics"
        CATEGORY_ACHIEVEMENTS:
            return "Achievement"
        CATEGORY_QOL_ACTIONS:
            return "QoL"
        _:
            return "Notification"


func _category_border_color(category: String) -> Color:
    match category:
        CATEGORY_UNLOCKS:
            return Color(0.2, 0.7, 0.4, 0.7)
        CATEGORY_WARNINGS:
            return Color(0.95, 0.7, 0.2, 0.8)
        CATEGORY_ERRORS:
            return Color(0.95, 0.3, 0.3, 0.85)
        CATEGORY_DIAGNOSTICS:
            return Color(0.45, 0.65, 0.95, 0.75)
        CATEGORY_ACHIEVEMENTS:
            return Color(0.75, 0.55, 0.95, 0.75)
        CATEGORY_QOL_ACTIONS:
            return Color(0.4, 0.8, 0.9, 0.7)
        _:
            return Color(0.2, 0.25, 0.35, 0.5)


func _format_time_ago(timestamp: int) -> String:
    var now = Time.get_unix_time_from_system()
    var diff = int(now - timestamp)
    if diff < 60:
        return "now"
    if diff < 3600:
        var mins = int(diff / 60.0)
        return str(mins) + "m"
    if diff < 86400:
        var hours = int(diff / 3600.0)
        return str(hours) + "h"
    var days = int(diff / 86400.0)
    return str(days) + "d"


func _filter_index_for_value(value: String) -> int:
    match value:
        FILTER_UNREAD:
            return 1
        FILTER_WARNINGS_ERRORS:
            return 2
        FILTER_UNLOCKS:
            return 3
        _:
            return 0


func _load_state() -> void:
    var payload := _read_storage_payload()
    if payload.is_empty():
        return

    notifications.clear()
    _next_id = int(payload.get("next_id", 1))
    current_filter = str(payload.get("filter", FILTER_ALL))

    var stored_entries: Variant = payload.get("items", [])
    if stored_entries is Array:
        for raw in stored_entries:
            if raw is Dictionary:
                notifications.append(_normalize_entry(raw))

    _trim_notifications()
    _recalculate_unread_count()


func _save_state() -> void:
    var payload := {
        "meta": _make_storage_meta(),
        "next_id": _next_id,
        "filter": current_filter,
        "items": notifications.duplicate(true)
    }
    _write_storage_payload(payload)


func _read_storage_payload() -> Dictionary:
    if _core == null or _core.storage == null:
        return {}
    var path: String = str(_core.storage.get_data_path(STORAGE_MODULE_ID, STORAGE_FILE_NAME))
    var payload: Variant = _core.storage.read_json(path, {})
    if payload is Dictionary:
        return payload
    return {}


func _write_storage_payload(payload: Dictionary) -> void:
    if _core == null or _core.storage == null:
        return
    var path: String = str(_core.storage.get_data_path(STORAGE_MODULE_ID, STORAGE_FILE_NAME))
    _core.storage.write_json(path, payload, true)


func _make_storage_meta() -> Dictionary:
    if _core != null and _core.storage != null and _core.storage.has_method("make_meta"):
        return _core.storage.make_meta(STORAGE_MODULE_ID, STORAGE_KIND)
    return {
        "schema_version": "1.0.0",
        "module": STORAGE_MODULE_ID,
        "kind": STORAGE_KIND
    }
