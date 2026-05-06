extends Node
class_name TajsCameraBookmarksFeature

const SAVE_SCOPE := "workspace"
const SAVE_OWNER_ID := "qol_camera_bookmarks"
const SAVE_KEY := "TajemnikTV-QoL.camera_bookmarks"
const FALLBACK_FILE := "camera_bookmarks.json"
const MAX_BOOKMARKS := 32
const QUICK_SLOT_COUNT := 9
const CAMERA_PATH := "Main/Main2D/Camera2D"

var _core: Variant = null
var _settings: Variant = null
var _data_store: Variant = null
var _bookmarks: Array[Dictionary] = []
var _selected_index: int = -1

var _layer: CanvasLayer = null
var _panel: PanelContainer = null
var _list: ItemList = null

func setup(core: Variant, settings: Variant, data_store: Variant) -> void:
    _core = core
    _settings = settings
    _data_store = data_store
    _load_bookmarks()
    _build_ui()

func toggle_panel() -> void:
    if _panel == null:
        return
    _panel.visible = not _panel.visible
    if _panel.visible:
        _refresh_list()

func save_current_bookmark() -> void:
    var camera := _get_camera()
    if camera == null:
        _notify("exclamation", "Camera not available")
        return
    if _bookmarks.size() >= MAX_BOOKMARKS:
        _notify("exclamation", "Bookmark limit reached")
        return
    var next_idx := _bookmarks.size() + 1
    var bookmark := _capture_bookmark("Bookmark %d" % next_idx)
    _bookmarks.append(bookmark)
    _persist()
    _refresh_list()
    _notify("check", "Saved camera bookmark")

func jump_next() -> void:
    if _bookmarks.is_empty():
        _notify("exclamation", "No camera bookmarks")
        return
    var next := 0
    if _selected_index >= 0:
        next = (_selected_index + 1) % _bookmarks.size()
    jump_to_index(next)

func jump_previous() -> void:
    if _bookmarks.is_empty():
        _notify("exclamation", "No camera bookmarks")
        return
    var next := _bookmarks.size() - 1
    if _selected_index >= 0:
        next = posmod(_selected_index - 1, _bookmarks.size())
    jump_to_index(next)

func jump_to_slot(slot: int) -> void:
    if slot < 1 or slot > QUICK_SLOT_COUNT:
        return
    var bookmark_index := slot - 1
    if bookmark_index >= _bookmarks.size():
        _notify("exclamation", "Bookmark slot %d is empty" % slot)
        return
    jump_to_index(bookmark_index)

func jump_to_index(index: int) -> void:
    if index < 0 or index >= _bookmarks.size():
        return
    var bookmark := _bookmarks[index]
    var camera := _get_camera()
    if camera == null:
        _notify("exclamation", "Camera not available")
        return

    var center := _to_vector2(bookmark.get("center", Vector2.ZERO))
    var zoom_value := _to_vector2(bookmark.get("zoom", Vector2.ONE))
    if zoom_value.x <= 0.0 or zoom_value.y <= 0.0:
        zoom_value = Vector2.ONE

    camera.position = center
    camera.zoom = zoom_value
    if camera.get("target_zoom") != null:
        camera.set("target_zoom", zoom_value)
    if camera.get("zooming") != null:
        camera.set("zooming", false)
    if Globals != null:
        Globals.camera_center = center
        Globals.camera_zoom = zoom_value

    var target_name := str(bookmark.get("target_name", "")).strip_edges()
    if target_name != "":
        var target := _find_selectable_by_name(target_name)
        if target != null and is_instance_valid(target) and Globals != null:
            Globals.set_selection([target], [])

    _selected_index = index
    _refresh_list()
    _notify("check", "Jumped to: %s" % str(bookmark.get("name", "Bookmark")))

func _build_ui() -> void:
    if _layer != null:
        return
    _layer = CanvasLayer.new()
    _layer.layer = 95
    add_child(_layer)

    _panel = PanelContainer.new()
    _panel.name = "CameraBookmarksPanel"
    _panel.visible = false
    _panel.custom_minimum_size = Vector2(360, 320)
    _panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
    _panel.position = Vector2(16, 120)
    _panel.mouse_filter = Control.MOUSE_FILTER_STOP
    _layer.add_child(_panel)

    var content := VBoxContainer.new()
    content.add_theme_constant_override("separation", 6)
    _panel.add_child(content)

    var title := Label.new()
    title.text = "Camera Bookmarks"
    title.add_theme_font_size_override("font_size", 22)
    content.add_child(title)

    _list = ItemList.new()
    _list.size_flags_vertical = Control.SIZE_EXPAND_FILL
    _list.select_mode = ItemList.SELECT_SINGLE
    _list.allow_reselect = true
    _list.item_selected.connect(func(index: int): _selected_index = index)
    _list.item_activated.connect(func(index: int): jump_to_index(index))
    content.add_child(_list)

    var row := HBoxContainer.new()
    row.add_theme_constant_override("separation", 6)
    content.add_child(row)

    row.add_child(_make_button("Add Current", func(): save_current_bookmark()))
    row.add_child(_make_button("Jump", func(): jump_to_index(_selected_index)))
    row.add_child(_make_button("Rename", func(): _open_rename_dialog()))
    row.add_child(_make_button("Delete", func(): _delete_selected()))

    _refresh_list()

func _make_button(text: String, callback: Callable) -> Button:
    var button := Button.new()
    button.text = text
    button.focus_mode = Control.FOCUS_NONE
    button.pressed.connect(callback)
    return button

func _open_rename_dialog() -> void:
    if _selected_index < 0 or _selected_index >= _bookmarks.size():
        return
    var dialog := AcceptDialog.new()
    dialog.title = "Rename Bookmark"
    dialog.dialog_text = "Enter a new name:"
    dialog.size = Vector2(360, 120)
    var input := LineEdit.new()
    input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    input.text = str(_bookmarks[_selected_index].get("name", "Bookmark"))
    dialog.add_child(input)
    dialog.confirmed.connect(func():
        var new_name := input.text.strip_edges()
        if new_name == "":
            new_name = "Bookmark"
        _bookmarks[_selected_index]["name"] = new_name
        _persist()
        _refresh_list()
        _notify("check", "Bookmark renamed")
    )
    dialog.canceled.connect(func(): dialog.queue_free())
    dialog.confirmed.connect(func(): dialog.queue_free())
    _layer.add_child(dialog)
    dialog.popup_centered()
    input.grab_focus()

func _delete_selected() -> void:
    if _selected_index < 0 or _selected_index >= _bookmarks.size():
        return
    _bookmarks.remove_at(_selected_index)
    if _bookmarks.is_empty():
        _selected_index = -1
    elif _selected_index >= _bookmarks.size():
        _selected_index = _bookmarks.size() - 1
    _persist()
    _refresh_list()
    _notify("check", "Bookmark deleted")

func _refresh_list() -> void:
    if _list == null:
        return
    _list.clear()
    for i in range(_bookmarks.size()):
        var entry := _bookmarks[i]
        var label := str(entry.get("name", "Bookmark"))
        if i < QUICK_SLOT_COUNT:
            label = "%d. %s" % [i + 1, label]
        _list.add_item(label)
    if _selected_index >= 0 and _selected_index < _bookmarks.size():
        _list.select(_selected_index)

func _capture_bookmark(name: String) -> Dictionary:
    var center := Vector2.ZERO
    var zoom_value := Vector2.ONE
    if Globals != null:
        center = Globals.camera_center
        zoom_value = Globals.camera_zoom
    var target_name := _get_first_selected_name()
    return {
        "name": name,
        "center": {"x": center.x, "y": center.y},
        "zoom": {"x": zoom_value.x, "y": zoom_value.y},
        "target_name": target_name
    }

func _get_first_selected_name() -> String:
    if Globals == null:
        return ""
    var selections: Array = Globals.selections
    for entry in selections:
        if entry is Node and is_instance_valid(entry):
            return str(entry.name)
    return ""

func _load_bookmarks() -> void:
    var payload: Variant = null
    if _core != null and _core.has_method("metadata_get"):
        payload = _core.metadata_get(SAVE_SCOPE, SAVE_OWNER_ID, SAVE_KEY, null)
    if payload == null and _data_store != null and _data_store.has_method("read_data"):
        payload = _data_store.read_data(FALLBACK_FILE, [])
    _bookmarks = _normalize_bookmarks(payload)
    if _bookmarks.is_empty():
        _selected_index = -1
    else:
        _selected_index = 0

func _persist() -> void:
    var payload := _bookmarks.duplicate(true)
    if _core != null and _core.has_method("metadata_set"):
        _core.metadata_set(SAVE_SCOPE, SAVE_OWNER_ID, SAVE_KEY, payload)
    elif _data_store != null and _data_store.has_method("write_data"):
        _data_store.write_data(FALLBACK_FILE, payload, "camera_bookmarks")

func _normalize_bookmarks(raw: Variant) -> Array[Dictionary]:
    var out: Array[Dictionary] = []
    if not (raw is Array):
        return out
    for entry_var in raw:
        if not (entry_var is Dictionary):
            continue
        if out.size() >= MAX_BOOKMARKS:
            break
        var entry: Dictionary = entry_var
        var center := _to_vector2(entry.get("center", Vector2.ZERO))
        var zoom_value := _to_vector2(entry.get("zoom", Vector2.ONE))
        if zoom_value.x <= 0.0 or zoom_value.y <= 0.0:
            zoom_value = Vector2.ONE
        out.append({
            "name": str(entry.get("name", "Bookmark")).strip_edges() if str(entry.get("name", "")).strip_edges() != "" else "Bookmark",
            "center": {"x": center.x, "y": center.y},
            "zoom": {"x": zoom_value.x, "y": zoom_value.y},
            "target_name": str(entry.get("target_name", ""))
        })
    return out

func _to_vector2(value: Variant) -> Vector2:
    if value is Vector2:
        return value
    if value is Dictionary:
        return Vector2(float(value.get("x", 0.0)), float(value.get("y", 0.0)))
    return Vector2.ZERO

func _get_camera() -> Camera2D:
    var tree := get_tree()
    if tree == null:
        return null
    return tree.root.get_node_or_null(CAMERA_PATH)

func _find_selectable_by_name(node_name: String) -> Node:
    if node_name == "":
        return null
    var tree := get_tree()
    if tree == null:
        return null
    for node in tree.get_nodes_in_group("selectable"):
        if node is Node and str(node.name) == node_name:
            return node
    return null

func _notify(icon: String, text: String) -> void:
    if _core != null and _core.has_method("notify"):
        _core.notify(icon, text)
    elif Signals != null and Signals.has_signal("notify"):
        Signals.notify.emit(icon, text)
