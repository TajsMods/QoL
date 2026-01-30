# ==============================================================================
# Taj's QoL - Go To Toolbar Buttons Feature
# Author: TajemnikTV
# Description: Adds Go To Group and Go To Sticky Note buttons to the tools bar.
# ==============================================================================
extends Node
class_name TajsGotoToolbarButtonsFeature

const LOG_NAME := "TajsQoL:GotoToolbarButtons"
const GROUP_COMMAND_ID := "tajs_qol.goto_group"
const NOTE_COMMAND_ID := "tajs_qol.goto_note"
const GROUP_ICON_PATH := "res://textures/icons/crosshair.png"
const NOTE_ICON_PATH := "res://textures/icons/document.png"

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
		_core.event_bus.on("game.desktop_ready", Callable(self, "_on_desktop_ready"), self, true)
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

	_group_button = tools_container.get_node_or_null("GotoGroupButton")
	_note_button = tools_container.get_node_or_null("GotoNoteButton")
	if _group_button != null and _note_button != null:
		return

	var insert_index := tools_container.get_child_count()
	var redo_button = tools_container.get_node_or_null("RedoButton")
	var undo_button = tools_container.get_node_or_null("UndoButton")
	if redo_button != null:
		insert_index = redo_button.get_index() + 1
	elif undo_button != null:
		insert_index = undo_button.get_index() + 1

	var group: ButtonGroup = null
	if tools_container.get_child_count() > 0:
		var first_child = tools_container.get_child(0)
		if first_child is Button:
			group = first_child.button_group

	if _group_button == null:
		_group_button = _create_button(
			"GotoGroupButton",
			GROUP_ICON_PATH,
			"Go To Group",
			Callable(self, "_on_goto_group_pressed"),
			group
		)
		tools_container.add_child(_group_button)

	if _note_button == null:
		_note_button = _create_button(
			"GotoNoteButton",
			NOTE_ICON_PATH,
			"Go To Sticky Note",
			Callable(self, "_on_goto_note_pressed"),
			group
		)
		tools_container.add_child(_note_button)

	tools_container.move_child(_group_button, insert_index)
	tools_container.move_child(_note_button, insert_index + 1)
	ModLoaderLog.success("Go To buttons added to tools bar", LOG_NAME)


func _create_button(name: String, icon_path: String, tooltip: String, pressed_action: Callable, group: ButtonGroup) -> Button:
	var button = Button.new()
	button.name = name

	var img: Image = load(icon_path).get_image()
	img.resize(35, 35, Image.INTERPOLATE_TRILINEAR)
	button.icon = ImageTexture.create_from_image(img)

	button.flat = true
	button.custom_minimum_size = Vector2(60, 40)
	button.tooltip_text = tooltip
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(pressed_action)

	button.toggle_mode = true
	if group != null:
		button.button_group = group
	button.toggled.connect(func(t): if t: button.set_pressed_no_signal(false))

	return button


func _get_tools_container() -> Control:
	var tree = get_tree()
	if tree == null:
		return null
	return tree.root.get_node_or_null("Main/HUD/Main/MainContainer/Overlay/ToolsBar/Tools")


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


func _get_autoload(name: String) -> Node:
	if Engine.get_main_loop() == null:
		return null
	var root = Engine.get_main_loop().root
	if root == null:
		return null
	return root.get_node_or_null(name)
