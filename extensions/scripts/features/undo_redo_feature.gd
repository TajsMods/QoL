# ==============================================================================
# Taj's QoL - Undo/Redo Feature
# Author: TajemnikTV
# Description: Adds undo/redo toolbar buttons and toast notifications
# ==============================================================================
extends Node
class_name TajsUndoRedoFeature

const LOG_NAME = "TajsQoL:UndoRedoFeature"
const UNDO_ICON_PATH := "res://textures/icons/return.png"

var _core = null
var _undo_manager = null
var _enabled: bool = true
var _buttons_enabled: bool = true
var _initialized: bool = false

var _undo_button: Button = null
var _redo_button: Button = null
var _spacer: Control = null

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
    
    # Check if buttons already exist
    if tools_container.has_node("UndoButton"):
        _undo_button = tools_container.get_node("UndoButton")
        _redo_button = tools_container.get_node_or_null("RedoButton")
        return
    
    # Get the button group from existing tools
    var group: ButtonGroup = null
    if tools_container.get_child_count() > 0:
        var first_child = tools_container.get_child(0)
        if first_child is Button:
            group = first_child.button_group
    
    # Create spacer
    _spacer = Control.new()
    _spacer.name = "UndoSpacer"
    _spacer.custom_minimum_size = Vector2(5, 0)
    _spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
    tools_container.add_child(_spacer)
    
    # Create Undo button
    _undo_button = Button.new()
    _undo_button.name = "UndoButton"
    
    var img: Image = load(UNDO_ICON_PATH).get_image()
    img.resize(35, 35, Image.INTERPOLATE_TRILINEAR)
    _undo_button.icon = ImageTexture.create_from_image(img)
    
    _undo_button.flat = true
    _undo_button.custom_minimum_size = Vector2(60, 40)
    _undo_button.tooltip_text = "Undo (Ctrl+Z)"
    _undo_button.focus_mode = Control.FOCUS_NONE
    _undo_button.pressed.connect(_on_undo_button_pressed)
    
    # Match style with tools bar
    _undo_button.toggle_mode = true
    if group != null:
        _undo_button.button_group = group
    _undo_button.toggled.connect(func(t): if t: _undo_button.set_pressed_no_signal(false))
    
    tools_container.add_child(_undo_button)
    
    # Create Redo button
    _redo_button = Button.new()
    _redo_button.name = "RedoButton"
    
    # Use same icon and flip it for Redo
    var img_redo: Image = load(UNDO_ICON_PATH).get_image()
    img_redo.flip_x()
    img_redo.resize(35, 35, Image.INTERPOLATE_TRILINEAR)
    _redo_button.icon = ImageTexture.create_from_image(img_redo)
    
    _redo_button.flat = true
    _redo_button.custom_minimum_size = Vector2(60, 40)
    _redo_button.tooltip_text = "Redo (Ctrl+Y)"
    _redo_button.focus_mode = Control.FOCUS_NONE
    _redo_button.pressed.connect(_on_redo_button_pressed)
    
    _redo_button.toggle_mode = true
    if group != null:
        _redo_button.button_group = group
    _redo_button.toggled.connect(func(t): if t: _redo_button.set_pressed_no_signal(false))
    
    tools_container.add_child(_redo_button)
    
    ModLoaderLog.success("Undo/Redo buttons added to toolbar", LOG_NAME)


func _get_tools_container() -> Control:
    var tree = get_tree()
    if tree == null:
        return null
    return tree.root.get_node_or_null("Main/HUD/Main/MainContainer/Overlay/ToolsBar/Tools")


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
        _undo_button.modulate = Color(1, 1, 1, 1) if can_undo else Color(1, 1, 1, 0.5)
        if can_undo:
            var desc: String = _undo_manager.get_undo_description()
            _undo_button.tooltip_text = "Undo: %s (Ctrl+Z)" % desc if desc != "" else "Undo (Ctrl+Z)"
        else:
            _undo_button.tooltip_text = "Undo (Ctrl+Z)"
    
    if _redo_button != null:
        _redo_button.disabled = not can_redo
        _redo_button.modulate = Color(1, 1, 1, 1) if can_redo else Color(1, 1, 1, 0.5)
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
    if _spacer != null:
        _spacer.visible = _buttons_enabled
