extends Node

const LOG_NAME := "TajemnikTV-QoL:ContextRadial"
const DEADZONE_PX := 12.0

const ContextRadialMenuScript = preload("res://mods-unpacked/TajemnikTV-QoL/extensions/scripts/ui/context_radial_menu.gd")

var _core = null
var _menu: CanvasLayer = null
var _enabled := true
var _pending_open := false
var _cancelled := false
var _press_screen_pos := Vector2.ZERO
var _press_world_pos := Vector2.ZERO
var _press_target = null
var _current_context: Dictionary = {}


func setup(core) -> void:
    _core = core
    set_process_input(true)
    set_process(true)
    _menu = ContextRadialMenuScript.new()
    _menu.action_selected.connect(_on_action_selected)
    _menu.closed.connect(_on_menu_closed)
    call_deferred("_add_menu_to_root")


func set_enabled(value: bool) -> void:
    _enabled = value
    if not _enabled and _menu != null and _menu.is_open():
        _menu.close()


func _ready() -> void:
    _add_menu_to_root()


func _add_menu_to_root() -> void:
    if _menu == null or _menu.is_inside_tree():
        return
    var tree = get_tree()
    if tree == null:
        # Retry when we're actually in the tree
        call_deferred("_add_menu_to_root")
        return
    tree.root.add_child(_menu)


func _process(_delta: float) -> void:
    if not _pending_open:
        return
    if not Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
        return
    var current_pos := get_viewport().get_mouse_position()
    if current_pos.distance_to(_press_screen_pos) > DEADZONE_PX:
        _cancelled = true


func _input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
        if _menu != null and _menu.is_open():
            _menu.close()
            get_viewport().set_input_as_handled()
        return

    if not (event is InputEventMouseButton):
        return
    if event.button_index != MOUSE_BUTTON_RIGHT:
        return

    if event.pressed:
        if _menu != null and _menu.is_open():
            _menu.close()
            get_viewport().set_input_as_handled()
            return
        if not _can_open_menu():
            return
        _press_screen_pos = event.position
        _press_world_pos = _screen_to_world(event.position)
        _press_target = _get_hovered_control()
        _pending_open = true
        _cancelled = false
    else:
        if _pending_open and not _cancelled:
            _open_menu()
        _pending_open = false
        _cancelled = false


func _open_menu() -> void:
    if _core == null or _core.context_menu == null:
        return
    if _menu != null and not _menu.is_inside_tree():
        _add_menu_to_root()
    if _menu == null or not _menu.is_inside_tree():
        return
    var context = _core.context_menu.resolve_context({
        "screen_position": _press_screen_pos,
        "position": _press_world_pos,
        "target": _press_target,
        "ui_target": _press_target
    })
    var actions: Array = _core.context_menu.query_actions(context)
    if actions.is_empty():
        return
    _current_context = context
    _menu.open(actions, context, _press_screen_pos)
    get_viewport().set_input_as_handled()


func _on_action_selected(action: Dictionary) -> void:
    # Save context BEFORE closing the menu, since close() triggers _on_menu_closed
    # which would clear _current_context
    var context := _current_context
    _current_context = {}
    
    if _menu != null and _menu.is_open():
        _menu.close()
    if not bool(action.get("enabled", true)):
        return
    var confirm: Dictionary = action.get("confirm", {})
    if confirm is Dictionary and not confirm.is_empty():
        _request_confirm(confirm, action, context)
        return
    _run_action(action, context)


func _run_action(action: Dictionary, context: Dictionary) -> void:
    if _core == null or _core.context_menu == null:
        return
    _core.context_menu.run_action(action, context)


func _request_confirm(confirm: Dictionary, action: Dictionary, context: Dictionary) -> void:
    if _has_prompt(confirm):
        _show_prompt(confirm, func(): _run_action(action, context))
        return
    var title := str(confirm.get("title", "Confirm"))
    var message := str(confirm.get("message", "Are you sure?"))
    if _core != null and _core.ui_manager != null and _core.ui_manager.has_method("show_confirmation"):
        _core.ui_manager.show_confirmation(title, message, func(): _run_action(action, context))
        return
    _run_action(action, context)


func _has_prompt(confirm: Dictionary) -> bool:
    return confirm.has("prompt_id") or confirm.has("prompt_title")


func _show_prompt(confirm: Dictionary, on_confirm: Callable) -> void:
    var title := str(confirm.get("prompt_id", confirm.get("prompt_title", "")))
    var desc := str(confirm.get("prompt_desc", confirm.get("prompt_message", "")))
    if title == "" and desc == "":
        on_confirm.call()
        return
    if Engine.get_main_loop() == null:
        on_confirm.call()
        return
    var root = Engine.get_main_loop().root
    if root == null:
        on_confirm.call()
        return
    var signals = root.get_node_or_null("Signals")
    if signals != null and signals.has_signal("prompt"):
        signals.emit_signal("prompt", title, desc, on_confirm)
        return
    on_confirm.call()


func _on_menu_closed() -> void:
    _current_context = {}


func _can_open_menu() -> bool:
    if not _enabled:
        return false
    if _core == null or _core.context_menu == null:
        return false
    if Globals != null and Globals.cur_screen != 0:
        return false
    if Globals != null and Globals.dragging:
        return false
    if _is_text_input_focused():
        return false
    if _is_menu_open():
        return false
    if _is_hovering_connector():
        return false
    if _hovered_outside_desktop():
        return false
    return true


func _hovered_outside_desktop() -> bool:
    var hovered = _get_hovered_control()
    if hovered == null:
        return false
    if Globals == null or Globals.desktop == null:
        # Desktop not ready yet, allow opening
        return false
    
    # The Dragger control is a global overlay for window dragging.
    # It's only visible when hovering over a draggable window, so allow it.
    if hovered.name == "Dragger":
        return false
    
    # Walk up the parent chain to check if we're inside an allowed area
    var node: Node = hovered
    while node != null:
        # Allow if we reach the desktop
        if node == Globals.desktop:
            return false
        # Allow if we're inside a WindowContainer (nodes, groups, etc.)
        if node is WindowContainer:
            return false
        # Allow if we're inside a sticky note
        if node.is_in_group("tajs_sticky_note"):
            return false
        # Check if this is a child of the desktop
        if Globals.desktop.is_ancestor_of(node):
            return false
        node = node.get_parent()
    return true


func _is_text_input_focused() -> bool:
    var focus: Control = get_viewport().gui_get_focus_owner()
    if focus == null:
        return false
    return focus is LineEdit or focus is TextEdit or focus is CodeEdit or focus is SpinBox


func _is_menu_open() -> bool:
    var hud := _get_hud()
    if hud == null:
        return false
    if hud.has_method("get"):
        var menu_val = hud.get("cur_menu")
        if menu_val != null:
            return int(menu_val) != Utils.menu_types.NONE
    return false


func _get_hud() -> Node:
    var tree = get_tree()
    if tree == null:
        return null
    return tree.root.get_node_or_null("Main/HUD")


func _get_hovered_control() -> Control:
    if get_viewport().has_method("gui_get_hovered_control"):
        return get_viewport().gui_get_hovered_control()
    return null


func _is_hovering_connector() -> bool:
    var hovered = _get_hovered_control()
    if hovered == null:
        return false
    # Walk up the parent chain to find a ConnectorButton
    var node: Node = hovered
    while node != null:
        if node is ConnectorButton:
            return true
        # Stop at WindowContainer to avoid going too far
        if node is WindowContainer:
            break
        node = node.get_parent()
    return false


func _screen_to_world(screen_pos: Vector2) -> Vector2:
    if _has_autoload("Utils") and Utils.has_method("screen_to_world_pos"):
        return Utils.screen_to_world_pos(screen_pos)
    return screen_pos


func _has_autoload(autoload_name: String) -> bool:
    if Engine.has_singleton(autoload_name):
        return true
    var tree = get_tree()
    if tree == null:
        return false
    return tree.root.has_node(autoload_name)
