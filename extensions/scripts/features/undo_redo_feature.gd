extends Node
class_name TajsUndoRedoFeature

const LOG_NAME = "TajsQoL:UndoRedoFeature"
const UNDO_ICON_PATH := "res://textures/icons/return.png"
const TOOLS_PATH := "Main/HUD/Main/MainContainer/Overlay/ToolsBar/Tools"
const SEPARATOR_NODE_NAME := "QolToolsSeparator"

const VANILLA_TOOL_NAMES := [
    "Cursor",
    "Move",
    "Select",
    "ConnectionEdit"
]

const MOD_TOOL_NAMES := [
    "UndoButton",
    "RedoButton",
    "GotoGroupButton",
    "GotoNoteButton"
]

var _core = null
var _undo_manager = null
var _enabled: bool = true
var _buttons_enabled: bool = true
var _initialized: bool = false

var _undo_button: Button = null
var _redo_button: Button = null
var _separator: VSeparator = null

func setup(core) -> void:
    _core = core
    if _core == null:
        return
    _undo_manager = _core.undo_manager
    if _undo_manager == null:
        ModLoaderLog.warning("UndoManager not available", LOG_NAME)
        return

    # Connect to undo manager signals
    if not _undo_manager.history_changed.is_connected(_on_history_changed):
        _undo_manager.history_changed.connect(_on_history_changed)
    if not _undo_manager.undo_performed.is_connected(_on_undo_performed):
        _undo_manager.undo_performed.connect(_on_undo_performed)
    if not _undo_manager.redo_performed.is_connected(_on_redo_performed):
        _undo_manager.redo_performed.connect(_on_redo_performed)

    # Wait for desktop to be ready to add buttons
    if _core.event_bus != null:
        _core.event_bus.on("game.desktop_ready", Callable(self , "_on_desktop_ready"), self , true)

    # Check if desktop already exists
    call_deferred("_check_existing_desktop")


func _check_existing_desktop() -> void:
    if _initialized:
        return
    if Globals != null and is_instance_valid(Globals.desktop):
        _on_desktop_ready({})


func _on_desktop_ready(_payload: Dictionary) -> void:
    if _initialized:
        return
    _initialized = true
    _add_toolbar_buttons()
    _update_button_states()


func set_enabled(enabled: bool) -> void:
    _enabled = enabled


func set_buttons_enabled(enabled: bool) -> void:
    _buttons_enabled = enabled
    if _initialized:
        if enabled and _undo_button == null:
            _add_toolbar_buttons()
        _update_buttons_visibility()


func _add_toolbar_buttons() -> void:
    if not _buttons_enabled:
        return

    var tools_container = _get_tools_container()
    if tools_container == null:
        ModLoaderLog.warning("ToolsBar/Tools container not found", LOG_NAME)
        return

    var group = _get_tools_button_group(tools_container)

    _separator = _ensure_separator(tools_container)

    _undo_button = tools_container.get_node_or_null("UndoButton")
    if _undo_button == null:
        _undo_button = Button.new()
        _undo_button.name = "UndoButton"
        _undo_button.pressed.connect(_on_undo_button_pressed)
        tools_container.add_child(_undo_button)
    _apply_toolbar_button_style(_undo_button, group)
    _undo_button.icon = load(UNDO_ICON_PATH)

    _redo_button = tools_container.get_node_or_null("RedoButton")
    if _redo_button == null:
        _redo_button = Button.new()
        _redo_button.name = "RedoButton"
        _redo_button.pressed.connect(_on_redo_button_pressed)
        tools_container.add_child(_redo_button)
    _apply_toolbar_button_style(_redo_button, group)
    _redo_button.icon = _build_redo_icon()

    var insert_index := _separator.get_index() + 1 if _separator != null else tools_container.get_child_count()
    tools_container.move_child(_undo_button, insert_index)
    tools_container.move_child(_redo_button, insert_index + 1)

    _update_separator_visibility(tools_container)

    ModLoaderLog.success("Undo/Redo buttons added to toolbar", LOG_NAME)


func _get_tools_container() -> Control:
    var tree = get_tree()
    if tree == null:
        return null
    return tree.root.get_node_or_null(TOOLS_PATH)


func _get_tools_button_group(tools_container: Control) -> ButtonGroup:
    if tools_container == null:
        return null
    for child in tools_container.get_children():
        if child is Button:
            return child.button_group
    return null


func _apply_toolbar_button_style(button: Button, group: ButtonGroup) -> void:
    button.custom_minimum_size = Vector2(80, 80)
    button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER | Control.SIZE_EXPAND
    button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
    button.focus_mode = Control.FOCUS_NONE
    button.theme_type_variation = "ButtonMenu"
    button.toggle_mode = true
    button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
    button.expand_icon = true
    if group != null:
        button.button_group = group
    var toggle_cb = Callable(self, "_on_toolbar_button_toggled").bind(button)
    if not button.toggled.is_connected(toggle_cb):
        button.toggled.connect(toggle_cb)


func _build_redo_icon() -> Texture2D:
    var base_texture = load(UNDO_ICON_PATH) as Texture2D
    if base_texture == null:
        return null
    var img = base_texture.get_image()
    img.flip_x()
    return ImageTexture.create_from_image(img)


func _ensure_separator(tools_container: Control) -> VSeparator:
    var separator = tools_container.get_node_or_null(SEPARATOR_NODE_NAME) as VSeparator
    if separator == null:
        separator = VSeparator.new()
        separator.name = SEPARATOR_NODE_NAME
        separator.mouse_filter = Control.MOUSE_FILTER_IGNORE
        separator.custom_minimum_size = Vector2(2, 58)
        separator.size_flags_vertical = Control.SIZE_SHRINK_CENTER
        separator.modulate = Color(0.75, 0.84, 1.0, 0.28)
        tools_container.add_child(separator)
    tools_container.move_child(separator, _get_separator_boundary_index(tools_container))
    return separator


func _get_separator_boundary_index(tools_container: Control) -> int:
    var last_vanilla_index := -1
    for node_name in VANILLA_TOOL_NAMES:
        var node = tools_container.get_node_or_null(node_name)
        if node != null:
            last_vanilla_index = maxi(last_vanilla_index, node.get_index())
    if last_vanilla_index >= 0:
        return last_vanilla_index + 1

    var first_mod_index := tools_container.get_child_count()
    var has_mod := false
    for node_name in MOD_TOOL_NAMES:
        var node = tools_container.get_node_or_null(node_name)
        if node != null:
            first_mod_index = mini(first_mod_index, node.get_index())
            has_mod = true
    if has_mod:
        return first_mod_index

    return tools_container.get_child_count()


func _update_separator_visibility(tools_container: Control) -> void:
    if tools_container == null:
        return
    var separator = tools_container.get_node_or_null(SEPARATOR_NODE_NAME)
    if separator == null:
        return
    var has_visible_mod := false
    for node_name in MOD_TOOL_NAMES:
        var node = tools_container.get_node_or_null(node_name)
        if node != null and node.visible:
            has_visible_mod = true
            break
    separator.visible = has_visible_mod


func _on_toolbar_button_toggled(toggled: bool, button: Button) -> void:
    if toggled and button != null:
        button.set_pressed_no_signal(false)


func _on_undo_button_pressed() -> void:
    if _undo_manager != null and _undo_manager.can_undo():
        _undo_manager.undo()


func _on_redo_button_pressed() -> void:
    if _undo_manager != null and _undo_manager.can_redo():
        _undo_manager.redo()


func _on_history_changed() -> void:
    _update_button_states()


func _on_undo_performed(description: String) -> void:
    if not _enabled:
        return
    var message := "Undone"
    if description != "" and description != "Unknown Command":
        message = "Undone: %s" % description
    Signals.notify.emit("return", message)
    Sound.play("close")


func _on_redo_performed(description: String) -> void:
    if not _enabled:
        return
    var message := "Redone"
    if description != "" and description != "Unknown Command":
        message = "Redone: %s" % description
    Signals.notify.emit("return", message)
    Sound.play("open")


func _update_button_states() -> void:
    if _undo_manager == null:
        return

    var can_undo: bool = _undo_manager.can_undo()
    var can_redo: bool = _undo_manager.can_redo()

    if _undo_button != null:
        _undo_button.disabled = not can_undo
        if can_undo:
            var desc: String = _undo_manager.get_undo_description()
            _undo_button.tooltip_text = "Undo: %s (Ctrl+Z)" % desc if desc != "" else "Undo (Ctrl+Z)"
        else:
            _undo_button.tooltip_text = "Undo (Ctrl+Z)"

    if _redo_button != null:
        _redo_button.disabled = not can_redo
        if can_redo:
            var desc: String = _undo_manager.get_redo_description()
            _redo_button.tooltip_text = "Redo: %s (Ctrl+Y)" % desc if desc != "" else "Redo (Ctrl+Y)"
        else:
            _redo_button.tooltip_text = "Redo (Ctrl+Y)"


func _update_buttons_visibility() -> void:
    if _undo_button != null:
        _undo_button.visible = _buttons_enabled
    if _redo_button != null:
        _redo_button.visible = _buttons_enabled
    _update_separator_visibility(_get_tools_container())
