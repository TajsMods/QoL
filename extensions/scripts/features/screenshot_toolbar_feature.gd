extends Node
class_name TajsScreenshotToolbarFeature

const CAMERA_ICON_PATH := "res://textures/icons/image.png"
const SELECTION_ICON_PATH := "res://textures/icons/selection.png"
const ACTIONS_EXPANDED_WIDTH := 190.0
const TOOLBAR_MARGIN_BOTTOM := -212.0
const TOOLBAR_MARGIN_TOP := -112.0
const TOOLBAR_LEFT := 0.0
const BUTTON_SIZE := 80.0
const BUTTON_GAP := 10.0
const PANEL_SIZE := 100.0

var _core = null
var _tree: SceneTree = null
var _enabled: bool = true
var _initialized: bool = false
var _expanded: bool = false
var _full_action: Callable = Callable()
var _selection_action: Callable = Callable()

var _container: Control = null
var _camera_panel: PanelContainer = null
var _camera_button: Button = null
var _actions_clip: Control = null
var _actions_panel: PanelContainer = null
var _actions_row: HBoxContainer = null
var _full_button: Button = null
var _selection_button: Button = null
var _slide_tween: Tween = null


func setup(core, full_action: Callable, selection_action: Callable) -> void:
    _core = core
    _full_action = full_action
    _selection_action = selection_action
    if _core != null and _core.event_bus != null:
        _core.event_bus.on("game.desktop_ready", Callable(self, "_on_desktop_ready"), self, true)
    call_deferred("_check_existing_hud")


func set_tree(tree: SceneTree) -> void:
    _tree = tree
    if _initialized:
        _update_selection_state()


func set_enabled(enabled: bool) -> void:
    _enabled = enabled
    if _container != null:
        _container.visible = enabled
    if not _enabled and _expanded:
        _set_expanded(false, false)


func _check_existing_hud() -> void:
    if _initialized:
        return
    if _get_overlay() != null:
        _on_desktop_ready({})


func _on_desktop_ready(_payload: Dictionary) -> void:
    if _initialized:
        return
    var overlay = _get_overlay()
    if overlay == null:
        return
    _initialized = true
    _build_ui(overlay)
    _connect_signals()
    _update_selection_state()
    if _container != null:
        _container.visible = _enabled


func _build_ui(overlay: Control) -> void:
    _container = Control.new()
    _container.name = "QolScreenshotToolbar"
    _container.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
    _container.anchor_top = 1.0
    _container.anchor_bottom = 1.0
    _container.offset_left = TOOLBAR_LEFT
    _container.offset_top = TOOLBAR_MARGIN_BOTTOM
    _container.offset_right = TOOLBAR_LEFT + 360.0
    _container.offset_bottom = TOOLBAR_MARGIN_TOP
    _container.mouse_filter = Control.MOUSE_FILTER_PASS
    overlay.add_child(_container)

    _camera_panel = PanelContainer.new()
    _camera_panel.name = "CameraPanel"
    _camera_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
    _camera_panel.offset_left = 0.0
    _camera_panel.offset_top = 0.0
    _camera_panel.offset_right = PANEL_SIZE
    _camera_panel.offset_bottom = PANEL_SIZE
    _camera_panel.theme_type_variation = "MenuButtonsPanel2"
    _container.add_child(_camera_panel)

    var camera_row := HBoxContainer.new()
    camera_row.name = "CameraRow"
    _camera_panel.add_child(camera_row)

    _camera_button = _create_icon_button("ScreenshotToggleButton", CAMERA_ICON_PATH, "Screenshot Tools")
    _camera_button.pressed.connect(_on_camera_pressed)
    camera_row.add_child(_camera_button)

    _actions_clip = Control.new()
    _actions_clip.name = "ActionsClip"
    _actions_clip.set_anchors_preset(Control.PRESET_TOP_LEFT)
    _actions_clip.offset_left = PANEL_SIZE + BUTTON_GAP
    _actions_clip.offset_top = 0.0
    _actions_clip.offset_right = PANEL_SIZE + BUTTON_GAP
    _actions_clip.offset_bottom = PANEL_SIZE
    _actions_clip.clip_contents = true
    _actions_clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _actions_clip.visible = false
    _container.add_child(_actions_clip)

    _actions_panel = PanelContainer.new()
    _actions_panel.name = "ActionsPanel"
    _actions_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
    _actions_panel.offset_left = 0.0
    _actions_panel.offset_top = 0.0
    _actions_panel.offset_right = 0.0
    _actions_panel.offset_bottom = 0.0
    _actions_panel.theme_type_variation = "MenuButtonsPanel2"
    _actions_panel.modulate.a = 0.0
    _actions_clip.add_child(_actions_panel)

    _actions_row = HBoxContainer.new()
    _actions_row.name = "ActionsRow"
    _actions_row.set_anchors_preset(Control.PRESET_FULL_RECT)
    _actions_row.offset_left = 0.0
    _actions_row.offset_top = 0.0
    _actions_row.offset_right = 0.0
    _actions_row.offset_bottom = 0.0
    _actions_row.add_theme_constant_override("separation", 10)
    _actions_panel.add_child(_actions_row)

    _full_button = _create_action_button("ScreenshotFullButton", "Full Board", CAMERA_ICON_PATH, "Capture full board screenshot")
    _full_button.pressed.connect(_on_full_pressed)
    _actions_row.add_child(_full_button)

    _selection_button = _create_action_button("ScreenshotSelectionButton", "Selection", SELECTION_ICON_PATH, "Capture selected nodes screenshot")
    _selection_button.pressed.connect(_on_selection_pressed)
    _actions_row.add_child(_selection_button)


func _connect_signals() -> void:
    if Signals != null and Signals.has_signal("selection_set"):
        if not Signals.selection_set.is_connected(_on_selection_set):
            Signals.selection_set.connect(_on_selection_set)


func _on_selection_set() -> void:
    _update_selection_state()


func _update_selection_state() -> void:
    if _selection_button == null:
        return
    var has_selection := Globals != null and not Globals.selections.is_empty()
    _selection_button.disabled = not has_selection
    _selection_button.modulate = Color(1, 1, 1, 1) if has_selection else Color(1, 1, 1, 0.45)


func _on_camera_pressed() -> void:
    _play_sound("click2")
    _set_expanded(not _expanded)


func _on_full_pressed() -> void:
    _play_sound("click2")
    if _full_action.is_valid():
        _full_action.call()


func _on_selection_pressed() -> void:
    if _selection_button != null and _selection_button.disabled:
        return
    _play_sound("click2")
    if _selection_action.is_valid():
        _selection_action.call()


func _set_expanded(expanded: bool, animate: bool = true) -> void:
    _expanded = expanded
    if _actions_clip == null or _actions_panel == null:
        return

    var left := PANEL_SIZE + BUTTON_GAP
    var target_right := left + ACTIONS_EXPANDED_WIDTH if expanded else left
    var target_alpha := 1.0 if expanded else 0.0
    _actions_clip.mouse_filter = Control.MOUSE_FILTER_PASS if expanded else Control.MOUSE_FILTER_IGNORE
    if expanded:
        _actions_clip.visible = true

    if _slide_tween != null:
        _slide_tween.kill()
        _slide_tween = null

    if not animate:
        _actions_clip.offset_right = target_right
        _actions_panel.modulate.a = target_alpha
        _actions_clip.visible = expanded
        return

    _slide_tween = create_tween()
    _slide_tween.set_parallel()
    _slide_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
    _slide_tween.tween_property(_actions_clip, "offset_right", target_right, 0.2)
    _slide_tween.tween_property(_actions_panel, "modulate:a", target_alpha, 0.14)
    if not expanded:
        _slide_tween.finished.connect(func() -> void:
            if not _expanded and _actions_clip != null:
                _actions_clip.visible = false
        )


func _get_overlay() -> Control:
    var tree = _tree if _tree != null else get_tree()
    if tree == null:
        return null
    return tree.root.get_node_or_null("Main/HUD/Main/MainContainer/Overlay")


func _create_icon_button(name: String, icon_path: String, tooltip: String) -> Button:
    var button = Button.new()
    button.name = name
    button.custom_minimum_size = Vector2(80, 80)
    button.focus_mode = Control.FOCUS_NONE
    button.theme_type_variation = "ButtonMenu"
    button.icon = load(icon_path)
    button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
    button.expand_icon = true
    button.tooltip_text = tooltip
    return button


func _create_action_button(name: String, label: String, icon_path: String, tooltip: String) -> Button:
    var button = Button.new()
    button.name = name
    button.custom_minimum_size = Vector2(BUTTON_SIZE, BUTTON_SIZE)
    button.focus_mode = Control.FOCUS_NONE
    button.theme_type_variation = "ButtonMenu"
    button.icon = load(icon_path)
    button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
    button.expand_icon = true
    button.tooltip_text = label + " - " + tooltip
    return button


func _play_sound(sound_id: String) -> void:
    if _core != null and _core.has_method("play_sound"):
        _core.play_sound(sound_id)
        return
    if Sound != null and Sound.has_method("play"):
        Sound.play(sound_id)
