extends Node
class_name TajsFindAnythingFeature

const LOG_NAME := "TajemnikTV-QoL:FindAnything"
const PANEL_WIDTH := 760.0
const PANEL_HEIGHT := 520.0
const MAX_RESULTS := 300

var _core: Variant = null
var _sticky_note_manager: Variant = null
var _goto_group_manager: Variant = null
var _connectivity_helpers: Variant = null

var _layer: CanvasLayer = null
var _panel: PanelContainer = null
var _query_input: LineEdit = null
var _results_list: ItemList = null
var _status_label: Label = null

var _items_cache: Array[Dictionary] = []
var _filtered_results: Array[Dictionary] = []
var _item_id_to_node: Dictionary = {}
var _cache_dirty: bool = true

func setup(core: Variant, sticky_note_manager: Variant, goto_group_manager: Variant) -> void:
    _core = core
    _sticky_note_manager = sticky_note_manager
    _goto_group_manager = goto_group_manager
    set_process_unhandled_input(true)
    if _core != null:
        _connectivity_helpers = _core.get("connectivity_helpers")
    _build_ui()
    _connect_invalidation_signals()

func open_finder() -> void:
    if _panel == null:
        return
    _refresh_index_if_needed(true)
    _panel.visible = true
    _query_input.text = ""
    _query_input.grab_focus()
    _apply_filter("")

func close_finder() -> void:
    if _panel != null:
        _panel.visible = false

func toggle_finder() -> void:
    if _panel == null:
        return
    if _panel.visible:
        close_finder()
    else:
        open_finder()

func build_jump_picker_entries() -> Array[Dictionary]:
    _refresh_index_if_needed(true)
    var out: Array[Dictionary] = []
    for item: Dictionary in _items_cache:
        var item_id := str(item.get("id", ""))
        var item_type := str(item.get("type", ""))
        var title := str(item.get("title", "Unknown"))
        var hint := str(item.get("group", ""))
        if hint == "":
            hint = str(item.get("note_text", ""))
        var icon := str(item.get("icon", ""))
        var icon_path := "res://textures/icons/%s.png" % icon
        if icon.begins_with("res://"):
            icon_path = icon
        out.append({
            "item_id": item_id,
            "title": "[%s] %s" % [item_type, title],
            "type": item_type,
            "hint": hint,
            "icon_path": icon_path,
            "badge": str(item.get("badge", "SAFE")),
            "target_ref": item.get("node_ref", null)
        })
    return out

func jump_to_selection(selection: Dictionary) -> void:
    if selection.is_empty():
        return
    var item_id := str(selection.get("item_id", ""))
    if item_id == "":
        return
    for item: Dictionary in _items_cache:
        if str(item.get("id", "")) == item_id:
            _jump_to_result(item)
            return

func _build_ui() -> void:
    if _layer != null:
        return

    _layer = CanvasLayer.new()
    _layer.layer = 90
    add_child(_layer)

    _panel = PanelContainer.new()
    _panel.name = "FindAnythingPanel"
    _panel.visible = false
    _panel.custom_minimum_size = Vector2(PANEL_WIDTH, PANEL_HEIGHT)
    _panel.size = Vector2(PANEL_WIDTH, PANEL_HEIGHT)
    _panel.focus_mode = Control.FOCUS_ALL
    _panel.mouse_filter = Control.MOUSE_FILTER_STOP
    _panel.set_anchors_preset(Control.PRESET_CENTER)
    _layer.add_child(_panel)

    var content := VBoxContainer.new()
    content.add_theme_constant_override("separation", 8)
    _panel.add_child(content)

    var title := Label.new()
    title.text = "Find Anything"
    title.add_theme_font_size_override("font_size", 26)
    content.add_child(title)

    _query_input = LineEdit.new()
    _query_input.placeholder_text = "Search by name, type, icon, group, note text..."
    _query_input.text_changed.connect(_on_query_changed)
    _query_input.text_submitted.connect(func(_text: String): _activate_selected())
    content.add_child(_query_input)

    _results_list = ItemList.new()
    _results_list.select_mode = ItemList.SELECT_SINGLE
    _results_list.allow_reselect = true
    _results_list.allow_rmb_select = false
    _results_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
    _results_list.item_activated.connect(_on_result_activated)
    content.add_child(_results_list)

    _status_label = Label.new()
    _status_label.text = "Type to search"
    _status_label.add_theme_font_size_override("font_size", 16)
    content.add_child(_status_label)

func _connect_invalidation_signals() -> void:
    var tree := get_tree()
    if tree != null:
        if not tree.node_added.is_connected(_on_tree_changed):
            tree.node_added.connect(_on_tree_changed)
        if not tree.node_removed.is_connected(_on_tree_changed):
            tree.node_removed.connect(_on_tree_changed)
    if _sticky_note_manager != null:
        if _sticky_note_manager.has_signal("note_added") and not _sticky_note_manager.note_added.is_connected(_on_note_changed):
            _sticky_note_manager.note_added.connect(_on_note_changed)
        if _sticky_note_manager.has_signal("note_removed") and not _sticky_note_manager.note_removed.is_connected(_on_note_removed):
            _sticky_note_manager.note_removed.connect(_on_note_removed)

func _on_tree_changed(_node: Node) -> void:
    _cache_dirty = true

func _on_note_changed(_note: Control) -> void:
    _cache_dirty = true

func _on_note_removed(_note_id: String, _note_data: Dictionary) -> void:
    _cache_dirty = true

func _on_query_changed(new_text: String) -> void:
    _apply_filter(new_text)

func _refresh_index_if_needed(force: bool = false) -> void:
    if not force and not _cache_dirty:
        return
    _items_cache.clear()
    _item_id_to_node.clear()

    var disconnected_windows: Dictionary = _get_disconnected_window_map()

    for item in _collect_board_items():
        var node_ref: Variant = item.get("node_ref", null)
        var item_id: String = str(item.get("id", ""))
        var title: String = str(item.get("title", ""))
        var type_name: String = str(item.get("type", ""))
        var icon_name: String = str(item.get("icon", ""))
        var group_name: String = str(item.get("group", ""))
        var note_text: String = str(item.get("note_text", ""))
        var subtype: String = str(item.get("subtype", ""))

        var searchable := "%s %s %s %s %s %s" % [title, type_name, subtype, icon_name, group_name, note_text]
        item["search_blob"] = searchable.to_lower()

        if type_name == "Node" and disconnected_windows.has(str(item.get("window_name", ""))):
            item["badge"] = "DISCONNECTED"

        _items_cache.append(item)
        if node_ref != null and item_id != "":
            _item_id_to_node[item_id] = node_ref

    _cache_dirty = false

func _collect_board_items() -> Array[Dictionary]:
    var items: Array[Dictionary] = []

    if _core != null and _core.has_method("board_get_bounds") and _core.has_method("board_query_rect"):
        var board_bounds: Rect2 = _core.board_get_bounds({"include_hidden": true})
        var board_items: Array = []
        if board_bounds.size != Vector2.ZERO:
            board_items = _core.board_query_rect(board_bounds, {"include_hidden": true})
        for board_item_var in board_items:
            if typeof(board_item_var) != TYPE_DICTIONARY:
                continue
            var board_item: Dictionary = board_item_var
            var item_id := str(board_item.get("id", ""))
            var item_type := str(board_item.get("type", ""))
            var node_path := str(board_item.get("path", ""))
            var node := get_node_or_null(node_path)
            if node == null or not is_instance_valid(node):
                continue

            if item_type == "window" or item_type == "group" or item_type == "node":
                items.append(_build_window_or_group_item(node, board_item))
            elif item_type == "note":
                items.append(_build_note_item(node, board_item))

            if item_id != "":
                _item_id_to_node[item_id] = node

    if items.is_empty():
        items = _collect_board_items_fallback()

    return items

func _collect_board_items_fallback() -> Array[Dictionary]:
    var out: Array[Dictionary] = []
    if Globals == null or not is_instance_valid(Globals.desktop):
        return out

    var windows: Node = Globals.desktop.get_node_or_null("Windows")
    if windows != null:
        for child in windows.get_children():
            if child is Control:
                var item: Dictionary = _build_window_or_group_item(child, {})
                if not item.is_empty():
                    out.append(item)

    var notes: Array = []
    if _sticky_note_manager != null and _sticky_note_manager.has_method("get_all_notes"):
        notes = _sticky_note_manager.get_all_notes()
    for note in notes:
        if is_instance_valid(note):
            out.append(_build_note_item(note, {}))

    return out

func _build_window_or_group_item(window: Variant, board_item: Dictionary) -> Dictionary:
    var board_type := str(board_item.get("type", ""))
    var window_kind := str(window.get("window")) if "window" in window else ""
    var is_group := window_kind == "group" or board_type == "group"
    var item_type := "Group" if is_group else "Node"
    var window_type_id := window_kind if window_kind != "" else str(board_item.get("window_type_id", ""))
    var window_name := str(window.name)
    var display_name := _get_window_display_name(window)
    var icon_id := _resolve_window_icon(window, window_type_id, is_group)
    var item_id := str(board_item.get("id", ""))
    if item_id == "":
        item_id = ("group:%s" if is_group else "window:%s") % window_name

    var group_name := ""
    if not is_group:
        group_name = _find_group_for_window(window)

    return {
        "id": item_id,
        "title": display_name,
        "type": item_type,
        "subtype": window_type_id,
        "icon": icon_id,
        "group": group_name,
        "note_text": "",
        "window_name": window_name,
        "node_ref": window
    }

func _build_note_item(note: Variant, board_item: Dictionary) -> Dictionary:
    var title := str(note.title_text if "title_text" in note else "Note").strip_edges()
    if title == "":
        title = "Note"
    var body := str(note.body_text if "body_text" in note else "")
    var icon_id := str(note.note_icon if "note_icon" in note else "document")
    var item_id := str(board_item.get("id", ""))
    if item_id == "":
        item_id = "note:%s" % str(note.note_id if "note_id" in note else note.name)

    return {
        "id": item_id,
        "title": title,
        "type": "Sticky Note",
        "subtype": "note",
        "icon": icon_id,
        "group": "",
        "note_text": body,
        "window_name": "",
        "node_ref": note
    }

func _get_window_display_name(window: Variant) -> String:
    if window == null:
        return "Unknown"
    if window.has_method("get_window_name"):
        var by_method := str(window.get_window_name()).strip_edges()
        if by_method != "":
            return by_method
    var custom_name := str(window.custom_name if "custom_name" in window else "").strip_edges()
    if custom_name != "":
        return custom_name
    var fallback := str(window.name).strip_edges()
    return fallback if fallback != "" else "Window"

func _resolve_window_icon(window: Variant, window_type_id: String, is_group: bool) -> String:
    if is_group:
        return str(window.custom_icon) if "custom_icon" in window else "window"
    if window != null and window.has_method("get_icon"):
        var icon_path := str(window.get_icon())
        if icon_path != "":
            return icon_path.get_file().get_basename()
    if Data != null and Data.windows != null and Data.windows.has(window_type_id):
        var data_icon := str(Data.windows[window_type_id].get("icon", ""))
        if data_icon != "":
            return data_icon
    return "window"

func _find_group_for_window(window: Variant) -> String:
    if _goto_group_manager == null or not _goto_group_manager.has_method("get_all_groups"):
        return ""
    var target_rect: Rect2 = window.get_rect() if window.has_method("get_rect") else Rect2(window.position, window.size)
    for group in _goto_group_manager.get_all_groups():
        if not is_instance_valid(group):
            continue
        if not group.has_method("get_rect"):
            continue
        var group_rect: Rect2 = group.get_rect()
        if group_rect.encloses(target_rect):
            if _goto_group_manager.has_method("get_group_name"):
                return str(_goto_group_manager.get_group_name(group))
            return _get_window_display_name(group)
    return ""

func _get_disconnected_window_map() -> Dictionary:
    if _connectivity_helpers != null and _connectivity_helpers.has_method("scan_disconnected_windows"):
        var scan: Dictionary = _connectivity_helpers.scan_disconnected_windows(2)
        var disconnected: Variant = scan.get("disconnected", {})
        return disconnected if disconnected is Dictionary else {}
    return {}

func _apply_filter(query_text: String) -> void:
    _filtered_results.clear()
    _results_list.clear()

    var query := query_text.strip_edges().to_lower()
    for item in _items_cache:
        if query == "" or query in str(item.get("search_blob", "")):
            _filtered_results.append(item)

    _filtered_results.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
        return str(a.get("title", "")) < str(b.get("title", ""))
    )

    var limit := mini(_filtered_results.size(), MAX_RESULTS)
    for i in range(limit):
        var item: Dictionary = _filtered_results[i]
        var label := "[%s] %s" % [item.get("type", "?"), item.get("title", "Unknown")]
        if str(item.get("group", "")) != "":
            label += "  •  Group: %s" % item.get("group", "")
        var badge := str(item.get("badge", ""))
        if badge != "":
            label += "  •  %s" % badge
        _results_list.add_item(label)

    if limit > 0:
        _results_list.select(0)
    _status_label.text = "%d result(s)%s" % [
        _filtered_results.size(),
        " (showing %d)" % MAX_RESULTS if _filtered_results.size() > MAX_RESULTS else ""
    ]

func _on_result_activated(index: int) -> void:
    if index < 0 or index >= _filtered_results.size():
        return
    _jump_to_result(_filtered_results[index])

func _activate_selected() -> void:
    var selected := _results_list.get_selected_items()
    if selected.is_empty():
        return
    var index: int = int(selected[0])
    _on_result_activated(index)

func _jump_to_result(item: Dictionary) -> void:
    var item_id := str(item.get("id", ""))
    var target := _item_id_to_node.get(item_id, item.get("node_ref", null))

    var focused := false
    if _core != null and _core.has_method("board_focus_item") and item_id != "":
        focused = _core.board_focus_item(item_id, {"fit": false})

    if not focused and is_instance_valid(target) and target is Control:
        var center: Vector2 = target.position + target.size * 0.5
        if Signals != null and Signals.has_signal("center_camera"):
            Signals.center_camera.emit(center)
            focused = true

    if is_instance_valid(target):
        if item.get("type", "") == "Sticky Note":
            if Globals != null:
                Globals.set_selection([], [])
            if target.has_method("_set_selected"):
                target._set_selected(true)
        else:
            if Globals != null:
                Globals.set_selection([target], [])
        _pulse_target(target)

    if focused and _core != null and _core.has_method("play_sound"):
        _core.play_sound("click2")

    close_finder()

func _pulse_target(target: Variant) -> void:
    if not (target is CanvasItem):
        return
    var canvas_item: CanvasItem = target
    var start_modulate: Color = canvas_item.modulate
    var tween := create_tween()
    tween.tween_property(canvas_item, "modulate", Color(1.2, 1.2, 0.8, 1.0), 0.12)
    tween.tween_property(canvas_item, "modulate", start_modulate, 0.3)

func _unhandled_input(event: InputEvent) -> void:
    if _panel == null or not _panel.visible:
        return
    if event.is_action_pressed("ui_cancel"):
        close_finder()
        get_viewport().set_input_as_handled()
