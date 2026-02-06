extends Node
class_name TajsGotoToolbarButtonsFeature

const LOG_NAME := "TajsQoL:GotoToolbarButtons"
const GROUP_COMMAND_ID := "tajs_qol.goto_group"
const NOTE_COMMAND_ID := "tajs_qol.goto_note"
const GROUP_ICON_PATH := "res://textures/icons/crosshair.png"
const NOTE_ICON_PATH := "res://textures/icons/document.png"
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
var _initialized: bool = false
var _group_enabled: bool = true
var _note_enabled: bool = true

var _group_button: Button = null
var _note_button: Button = null


func setup(core) -> void:
    _core = core
    if _core == null:
        return
    if _core.event_bus != null:
        _core.event_bus.on("game.desktop_ready", Callable(self , "_on_desktop_ready"), self , true)
    call_deferred("_check_existing_desktop")


func set_group_button_enabled(enabled: bool) -> void:
    _group_enabled = enabled
    _update_button_visibility()


func set_note_button_enabled(enabled: bool) -> void:
    _note_enabled = enabled
    _update_button_visibility()


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
    _update_button_visibility()


func _add_toolbar_buttons() -> void:
    var tools_container = _get_tools_container()
    if tools_container == null:
        ModLoaderLog.warning("ToolsBar/Tools container not found", LOG_NAME)
        return

    var separator = _ensure_separator(tools_container)

    _group_button = tools_container.get_node_or_null("GotoGroupButton")
    _note_button = tools_container.get_node_or_null("GotoNoteButton")

    var group = _get_tools_button_group(tools_container)

    if _group_button == null:
        _group_button = _create_button(
            "GotoGroupButton",
            GROUP_ICON_PATH,
            "Go To Group",
            Callable(self , "_on_goto_group_pressed"),
            group
        )
        tools_container.add_child(_group_button)
    else:
        _apply_toolbar_button_style(_group_button, group)

    if _note_button == null:
        _note_button = _create_button(
            "GotoNoteButton",
            NOTE_ICON_PATH,
            "Go To Sticky Note",
            Callable(self , "_on_goto_note_pressed"),
            group
        )
        tools_container.add_child(_note_button)
    else:
        _apply_toolbar_button_style(_note_button, group)

    var insert_index := separator.get_index() + 1 if separator != null else tools_container.get_child_count()
    var redo_button = tools_container.get_node_or_null("RedoButton")
    var undo_button = tools_container.get_node_or_null("UndoButton")
    if undo_button != null:
        insert_index = maxi(insert_index, undo_button.get_index() + 1)
    if redo_button != null:
        insert_index = maxi(insert_index, redo_button.get_index() + 1)

    tools_container.move_child(_group_button, insert_index)
    tools_container.move_child(_note_button, insert_index + 1)
    _update_separator_visibility(tools_container)
    ModLoaderLog.success("Go To buttons added to tools bar", LOG_NAME)


func _create_button(btn_name: String, icon_path: String, tooltip: String, pressed_action: Callable, group: ButtonGroup) -> Button:
    var button = Button.new()
    button.name = btn_name

    button.icon = load(icon_path)
    button.tooltip_text = tooltip
    button.pressed.connect(pressed_action)

    _apply_toolbar_button_style(button, group)

    return button


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


func _get_tools_button_group(tools_container: Control) -> ButtonGroup:
    if tools_container == null:
        return null
    for child in tools_container.get_children():
        if child is Button:
            return child.button_group
    return null


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


func _get_tools_container() -> Control:
    var tree = get_tree()
    if tree == null:
        return null
    return tree.root.get_node_or_null(TOOLS_PATH)


func _on_goto_group_pressed() -> void:
    _run_command(GROUP_COMMAND_ID)


func _on_goto_note_pressed() -> void:
    _run_command(NOTE_COMMAND_ID)


func _run_command(command_id: String) -> void:
    if _core != null:
        if _core.has_method("run_command"):
            if _core.run_command(command_id):
                _play_sound("click2")
                return
        var registry = _core.commands if _core.commands != null else _core.command_registry
        if registry != null and registry.has_method("execute"):
            registry.execute(command_id)
            _play_sound("click2")
            return
    _notify("exclamation", "Command not available")


func _update_button_visibility() -> void:
    if _group_button != null:
        _group_button.visible = _group_enabled
    if _note_button != null:
        _note_button.visible = _note_enabled
    _update_separator_visibility(_get_tools_container())


func _notify(icon: String, message: String) -> void:
    if _core != null and _core.has_method("notify"):
        _core.notify(icon, message)
        return
    var signals = _get_autoload("Signals")
    if signals != null and signals.has_signal("notify"):
        signals.emit_signal("notify", icon, message)


func _play_sound(sound_id: String) -> void:
    if _core != null and _core.has_method("play_sound"):
        _core.play_sound(sound_id)
        return
    var sound = _get_autoload("Sound")
    if sound != null and sound.has_method("play"):
        sound.call("play", sound_id)


func _get_autoload(autoload_name: String) -> Node:
    if Engine.get_main_loop() == null:
        return null
    var root = Engine.get_main_loop().root
    if root == null:
        return null
    return root.get_node_or_null(autoload_name)
