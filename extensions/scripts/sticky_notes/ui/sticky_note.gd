# ==============================================================================
# Taj's QoL - Sticky Note
# Draggable, editable text notes for canvas labeling
# Ported from TajsModded
# ==============================================================================
extends Control
class_name TajsStickyNote

const LOG_NAME = "TajsQoL:StickyNote"

# Preload dependencies
const ColorPickerPanelScript = preload("res://mods-unpacked/TajemnikTV-Core/core/ui/color_picker_panel.gd")
const PatternPickerPanelScript = preload("res://mods-unpacked/TajemnikTV-QoL/extensions/scripts/ui/pattern_picker_panel.gd")
const PatternDrawerScript = preload("res://mods-unpacked/TajemnikTV-QoL/extensions/scripts/ui/pattern_drawer.gd")
const RichTextContextMenuScript = preload("res://mods-unpacked/TajemnikTV-QoL/extensions/scripts/sticky_notes/ui/rich_text_context_menu.gd")
const StickyNoteEditPopupScript = preload("res://mods-unpacked/TajemnikTV-QoL/extensions/scripts/sticky_notes/ui/sticky_note_edit_popup.gd")

# Signals for manager synchronization
signal note_changed(note_id: String)
signal note_deleted(note_id: String)
signal note_duplicated(note_id: String, new_position: Vector2)
signal drag_started()
signal drag_ended()
signal selection_changed(selected: bool)

# Note properties
var note_id: String = ""
var title_text: String = "Note"
var note_icon: String = "document" # Icon name for the note header
var body_text: String = ""
var note_color: Color = Color("1a202c")

# Pattern state
var pattern_index: int = 0
var pattern_color: Color = Color(0, 0, 0, 1.0)
var pattern_alpha: float = 0.4
var pattern_spacing: float = 20.0
var pattern_thickness: float = 4.0
var pattern_drawers: Array[Control] = []

# UI References
var _title_panel: Panel
var _body_panel: Panel
var _title_icon: TextureRect # Icon display in header
var _title_label: Label # Title text label
var _edit_title_btn: Button # Pen button to open edit popup
var _body_edit: TextEdit
var _body_display: RichTextLabel # Rich text view (shown when not editing)
var _context_menu = null # RichTextContextMenu instance
var _context_menu_layer: CanvasLayer = null
var _color_btn: Button
var _pattern_btn: Button
var _duplicate_btn: Button
var _delete_btn: Button

# Edit popup
var _edit_popup_layer: CanvasLayer = null
var _edit_popup = null

# Edit/View mode state
var _is_edit_mode: bool = false

# Resize Handles (Controls)
var _resize_handles: Dictionary = {}

# Pickers
var _color_picker_layer: CanvasLayer = null
var _color_picker = null
var _pattern_picker_layer: CanvasLayer = null
var _pattern_picker = null

# State
var _is_dragging := false
var _drag_offset := Vector2.ZERO
var _is_resizing := false
var _resize_dir := Vector2.ZERO # Direction of resize (-1, 0, 1)
var _resize_start_rect := Rect2()
var _resize_start_mouse := Vector2.ZERO
var _min_size := Vector2(200, 100)
var _is_hovered := false
var _is_selected := false: set = _set_selected

# Manager reference
var _manager = null

# Visual Constants
const HANDLE_SIZE = 8.0 # Radius
const HANDLE_OFFSET = 10.0 # Further offset
const HANDLE_COLOR = Color("ff8500")
const OUTLINE_COLOR = Color("ff8500")
const OUTLINE_WIDTH = 2.0

func _init() -> void:
    custom_minimum_size = Vector2(200, 100)
    size = Vector2(280, 140)
    mouse_filter = Control.MOUSE_FILTER_PASS # Allow scroll events to pass through for camera zoom

func _ready() -> void:
    _build_ui()
    _setup_pickers()
    _setup_context_menu()
    
    # Apply initial content
    if _title_label:
        _title_label.text = title_text if title_text else "Note"
    if _body_edit:
        _body_edit.text = body_text
    if _body_display:
        _body_display.clear()
        _body_display.append_text(body_text) # Use append_text for BBCode parsing
    
    # Start in view mode
    _set_edit_mode(false)
        
    # Apply initial visuals
    update_color()
    update_pattern()
    _update_visual_state()
    
    mouse_entered.connect(func():
        _is_hovered = true
        queue_redraw()
    )
    mouse_exited.connect(func():
        _is_hovered = false
        queue_redraw()
    )
    
    z_index = 10

func _build_ui() -> void:
    # === TITLE PANEL ===
    _title_panel = Panel.new()
    _title_panel.name = "TitlePanel"
    # TITLE HEIGHT: 56px
    _title_panel.anchor_left = 0
    _title_panel.anchor_top = 0
    _title_panel.anchor_right = 1
    _title_panel.anchor_bottom = 0
    _title_panel.offset_bottom = 56
    _title_panel.mouse_filter = Control.MOUSE_FILTER_STOP # Stop input to prevent camera panning when dragging note
    _title_panel.gui_input.connect(_on_title_panel_input)
    
    # Styling
    var title_style = StyleBoxFlat.new()
    title_style.bg_color = Color(1, 1, 1, 0.5)
    title_style.corner_radius_top_left = 12
    title_style.corner_radius_top_right = 12
    title_style.corner_radius_bottom_right = 0
    title_style.corner_radius_bottom_left = 0
    title_style.shadow_color = Color(0, 0, 0, 0.1)
    title_style.shadow_size = 2
    # Ensure no borders
    title_style.set_border_width_all(0)
    _title_panel.add_theme_stylebox_override("panel", title_style)
    add_child(_title_panel)
    
    # Title container
    var title_container = HBoxContainer.new()
    title_container.name = "TitleContainer"
    title_container.set_anchors_preset(Control.PRESET_FULL_RECT)
    title_container.add_theme_constant_override("separation", 4)
    
    # Margins
    var title_margin = MarginContainer.new()
    title_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
    title_margin.add_theme_constant_override("margin_left", 6)
    title_margin.add_theme_constant_override("margin_right", 6)
    title_margin.add_theme_constant_override("margin_top", 4)
    title_margin.add_theme_constant_override("margin_bottom", 4)
    title_margin.add_child(title_container)
    _title_panel.add_child(title_margin)
    
    # Note icon (TextureRect)
    _title_icon = TextureRect.new()
    _title_icon.name = "TitleIcon"
    _title_icon.custom_minimum_size = Vector2(32, 32)
    _title_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    _title_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    _title_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _update_title_icon()
    title_container.add_child(_title_icon)
    
    # Title label (non-interactive so dragging works on the entire title bar)
    _title_label = Label.new()
    _title_label.name = "TitleLabel"
    _title_label.text = "Note"
    _title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
    _title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    _title_label.add_theme_font_size_override("font_size", 24)
    _title_label.add_theme_color_override("font_color", Color("b0cff9")) # Light blue
    
    # Soft Shadow
    _title_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.3))
    _title_label.add_theme_constant_override("shadow_offset_x", 1)
    _title_label.add_theme_constant_override("shadow_offset_y", 1)
    
    # Make label non-interactive so clicks pass through to title panel for dragging
    _title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    title_container.add_child(_title_label)
    
    # Edit title button (pen icon) - opens the edit popup
    _edit_title_btn = _create_header_button("pen.png", "Edit Note")
    _edit_title_btn.pressed.connect(_open_edit_popup)
    title_container.add_child(_edit_title_btn)
    
    # Color button
    _color_btn = _create_header_button("contrast.png", "Change Color")
    _color_btn.pressed.connect(_open_color_picker)
    title_container.add_child(_color_btn)
    
    # Pattern button
    _pattern_btn = _create_header_button("grid.png", "Pattern Settings")
    _pattern_btn.pressed.connect(_open_pattern_picker)
    title_container.add_child(_pattern_btn)
    
    # Duplicate button
    _duplicate_btn = _create_header_button("plus.png", "Duplicate Note")
    _duplicate_btn.pressed.connect(_on_duplicate_pressed)
    title_container.add_child(_duplicate_btn)
    
    # Delete button
    _delete_btn = _create_header_button("trash_bin.png", "Delete Note")
    _delete_btn.pressed.connect(_on_delete_pressed)
    title_container.add_child(_delete_btn)
    
    # === BODY PANEL ===
    _body_panel = Panel.new()
    _body_panel.name = "BodyPanel"
    _body_panel.anchor_left = 0
    _body_panel.anchor_top = 0
    _body_panel.anchor_right = 1
    _body_panel.anchor_bottom = 1
    _body_panel.offset_top = 56
    _body_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
    
    var body_style = StyleBoxFlat.new()
    body_style.bg_color = Color(1, 1, 1, 0.4) # Very transparent (glassy)
    body_style.corner_radius_top_left = 0
    body_style.corner_radius_top_right = 0
    body_style.corner_radius_bottom_right = 12
    body_style.corner_radius_bottom_left = 12
    body_style.shadow_color = Color(0, 0, 0, 0.1)
    body_style.shadow_size = 2
    body_style.set_border_width_all(0)
    _body_panel.add_theme_stylebox_override("panel", body_style)
    add_child(_body_panel)
    
    # Pattern Drawer for Body
    var body_pattern = PatternDrawerScript.new()
    body_pattern.set_anchors_preset(Control.PRESET_FULL_RECT)
    _body_panel.add_child(body_pattern)
    pattern_drawers.append(body_pattern)
    
    # === Rich Text Display (RichTextLabel - VIEW mode) ===
    _body_display = RichTextLabel.new()
    _body_display.name = "BodyDisplay"
    _body_display.bbcode_enabled = true
    _body_display.scroll_active = false # Disable scroll to allow zoom passthrough
    _body_display.selection_enabled = false
    _body_display.mouse_filter = Control.MOUSE_FILTER_PASS # Allow scroll for camera zoom
    _body_display.anchor_left = 0
    _body_display.anchor_top = 0
    _body_display.anchor_right = 1
    _body_display.anchor_bottom = 1
    _body_display.offset_left = 8
    _body_display.offset_top = 8
    _body_display.offset_right = -8
    _body_display.offset_bottom = -8
    _body_display.add_theme_font_size_override("normal_font_size", 24)
    _body_display.add_theme_color_override("default_color", Color(1, 1, 1))
    # Click on RichTextLabel to enter edit mode
    _body_display.gui_input.connect(_on_view_gui_input)
    _body_panel.add_child(_body_display)
    
    # === Body TextEdit (EDIT mode) ===
    _body_edit = TextEdit.new()
    _body_edit.name = "BodyEdit"
    _body_edit.placeholder_text = "Write notes here..."
    _body_edit.anchor_left = 0
    _body_edit.anchor_top = 0
    _body_edit.anchor_right = 1
    _body_edit.anchor_bottom = 1
    _body_edit.offset_left = 8
    _body_edit.offset_top = 8
    _body_edit.offset_right = -8
    _body_edit.offset_bottom = -8
    _body_edit.add_theme_font_size_override("font_size", 24)
    _body_edit.add_theme_color_override("font_color", Color(1, 1, 1))
    _body_edit.add_theme_color_override("font_placeholder_color", Color(0.8, 0.8, 0.8, 0.5))
    _body_edit.add_theme_color_override("caret_color", Color(1, 1, 1))
    _body_edit.add_theme_color_override("selection_color", Color(0.3, 0.5, 0.8, 0.5))
    _body_edit.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
    _body_edit.context_menu_enabled = false
    
    var body_edit_style = StyleBoxFlat.new()
    body_edit_style.bg_color = Color(0, 0, 0, 0.15)
    body_edit_style.set_corner_radius_all(4)
    _body_edit.add_theme_stylebox_override("normal", body_edit_style)
    _body_edit.add_theme_stylebox_override("focus", body_edit_style)
    
    _body_edit.text_changed.connect(_on_body_changed)
    _body_edit.gui_input.connect(_on_body_gui_input)
    _body_edit.focus_entered.connect(func(): _set_selected(true))
    _body_edit.focus_exited.connect(_on_body_focus_exited)
    # Note: Scrollbar mouse filter left as default so text scrolling works in edit mode
    # Zoom forwarding is controlled by checking _is_edit_mode in input handlers
    
    _body_panel.add_child(_body_edit)
    
    # === RESIZE HANDLES ===
    _build_resize_handles()

func _build_resize_handles() -> void:
    var dirs = [
        Vector2(-1, -1), Vector2(0, -1), Vector2(1, -1),
        Vector2(-1, 0), Vector2(1, 0),
        Vector2(-1, 1), Vector2(0, 1), Vector2(1, 1)
    ]
    
    for dir in dirs:
        var handle = Control.new()
        handle.name = "ResizeHandle_%s_%s" % [dir.x, dir.y]
        handle.custom_minimum_size = Vector2(HANDLE_SIZE * 2 + 4, HANDLE_SIZE * 2 + 4) # Expanded hit area
        handle.mouse_filter = Control.MOUSE_FILTER_STOP # Block input
        handle.mouse_default_cursor_shape = _get_cursor_for_dir(dir)
        handle.gui_input.connect(func(event): _on_handle_gui_input(event, dir))
        
        add_child(handle)
        _resize_handles[dir] = handle

    _update_handle_positions()
    resized.connect(_update_handle_positions)

func _update_handle_positions() -> void:
    if _resize_handles.is_empty(): return
    
    var r = Rect2(Vector2.ZERO, size)
    r = r.grow(HANDLE_OFFSET)
    
    var positions = {
        Vector2(-1, -1): r.position, # Top-Left
        Vector2(0, -1): Vector2(r.position.x + r.size.x / 2, r.position.y), # Top
        Vector2(1, -1): Vector2(r.end.x, r.position.y), # Top-Right
        
        Vector2(-1, 0): Vector2(r.position.x, r.position.y + r.size.y / 2), # Left
        Vector2(1, 0): Vector2(r.end.x, r.position.y + r.size.y / 2), # Right
        
        Vector2(-1, 1): Vector2(r.position.x, r.end.y), # Bottom-Left
        Vector2(0, 1): Vector2(r.position.x + r.size.x / 2, r.end.y), # Bottom
        Vector2(1, 1): r.end # Bottom-Right
    }
    
    for dir in _resize_handles:
        var handle = _resize_handles[dir]
        var center = positions[dir]
        handle.position = center - handle.custom_minimum_size / 2

func _create_header_button(icon_name: String, tooltip: String) -> Button:
    var btn = Button.new()
    btn.custom_minimum_size = Vector2(40, 40)
    btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
    btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
    btn.focus_mode = Control.FOCUS_NONE
    btn.theme_type_variation = "SettingButton"
    btn.add_theme_constant_override("icon_max_width", 20)
    
    # Try to load icon
    var icon_path = "res://textures/icons/" + icon_name
    if ResourceLoader.exists(icon_path):
        btn.icon = load(icon_path)
    
    btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
    btn.expand_icon = true
    btn.tooltip_text = tooltip
    btn.pressed.connect(func(): _set_selected(true))
    return btn

func _setup_pickers() -> void:
    # Color Picker
    _color_picker_layer = _create_picker_layer("NoteColorPickerLayer")
    _color_picker = ColorPickerPanelScript.new()
    _color_picker.set_color(note_color)
    _color_picker.color_changed.connect(_on_color_changed)
    _color_picker.color_committed.connect(func(_c): _close_picker(_color_picker_layer))
    _color_picker_layer.add_child(_color_picker)
    
    # Pattern Picker
    _pattern_picker_layer = _create_picker_layer("NotePatternPickerLayer")
    _pattern_picker = PatternPickerPanelScript.new()
    _pattern_picker.set_settings(pattern_index, pattern_color, pattern_alpha, pattern_spacing, pattern_thickness)
    _pattern_picker.settings_changed.connect(_on_pattern_settings_changed)
    _pattern_picker.settings_committed.connect(func(_idx, _c, _a, _sp, _th): _close_picker(_pattern_picker_layer))
    _pattern_picker_layer.add_child(_pattern_picker)

func _create_picker_layer(layer_name: String) -> CanvasLayer:
    var layer = CanvasLayer.new()
    layer.name = layer_name
    layer.layer = 100
    layer.visible = false
    # Add to root deferred to safe add
    call_deferred("_add_layer_to_root", layer)
    
    var bg = ColorRect.new()
    bg.color = Color(0, 0, 0, 0.4)
    bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    bg.mouse_filter = Control.MOUSE_FILTER_STOP
    bg.gui_input.connect(func(event):
        if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
            _close_picker(layer)
    )
    layer.add_child(bg)
    return layer

func _add_layer_to_root(layer: CanvasLayer) -> void:
    if not is_instance_valid(layer): return
    if layer.is_inside_tree() or layer.get_parent() != null: return
    get_tree().root.add_child(layer)

func _setup_context_menu() -> void:
    _context_menu_layer = CanvasLayer.new()
    _context_menu_layer.name = "NoteContextMenuLayer"
    _context_menu_layer.layer = 101 # Above pickers
    call_deferred("_add_layer_to_root", _context_menu_layer)
    
    _context_menu = RichTextContextMenuScript.new()
    # Format requested signal
    _context_menu.format_requested.connect(_on_format_requested)
    _context_menu.clear_format_requested.connect(_on_clear_format_requested)
    _context_menu.closed.connect(func():
        # Optional: return focus to edit
        if _is_edit_mode and is_instance_valid(_body_edit):
            _body_edit.grab_focus()
    )
    _context_menu_layer.add_child(_context_menu)

func _open_color_picker() -> void:
    if _color_picker_layer:
        _color_picker.set_color(note_color)
        _open_picker(_color_picker_layer, _color_picker)

func _open_pattern_picker() -> void:
    if _pattern_picker_layer:
        _pattern_picker.set_settings(pattern_index, pattern_color, pattern_alpha, pattern_spacing, pattern_thickness)
        _open_picker(_pattern_picker_layer, _pattern_picker)

func _open_picker(layer: CanvasLayer, panel: Control) -> void:
    layer.visible = true
    if panel:
        panel.position = (panel.get_viewport_rect().size - panel.size) / 2
    _play_sound("click2")

func _close_picker(layer: CanvasLayer) -> void:
    if layer:
        layer.visible = false

# === Update Visuals ===
func update_color() -> void:
    if _title_panel:
        _title_panel.self_modulate = note_color
    if _body_panel:
        _body_panel.self_modulate = note_color

func update_pattern() -> void:
    for drawer in pattern_drawers:
        drawer.set_pattern(pattern_index)
        drawer.set_style(pattern_color, pattern_alpha, pattern_spacing, pattern_thickness)

func _set_selected(value: bool) -> void:
    if _is_selected != value:
        # If deselecting, save changes and exit edit mode
        if _is_selected and not value:
            _set_edit_mode(false)
            _emit_changed()
            
        _is_selected = value
        _update_visual_state()
        queue_redraw()
        
        selection_changed.emit(_is_selected)

func _update_visual_state() -> void:
    # Show/Hide handles based on selection
    for dir in _resize_handles:
        var handle = _resize_handles[dir]
        handle.visible = _is_selected

func _draw() -> void:
    if _is_selected:
        var r = Rect2(Vector2.ZERO, size)
        
        # Draw Outline
        draw_rect(r, OUTLINE_COLOR, false, OUTLINE_WIDTH)
        
        # Draw Dots
        for dir in _resize_handles:
            var handle = _resize_handles[dir]
            var center = handle.position + handle.custom_minimum_size / 2
            draw_circle(center, HANDLE_SIZE, HANDLE_COLOR)

func _get_cursor_for_dir(dir: Vector2) -> CursorShape:
    if dir == Vector2(-1, -1) or dir == Vector2(1, 1): return CURSOR_FDIAGSIZE
    if dir == Vector2(1, -1) or dir == Vector2(-1, 1): return CURSOR_BDIAGSIZE
    if dir.x != 0: return CURSOR_HSIZE
    if dir.y != 0: return CURSOR_VSIZE
    return CURSOR_ARROW

# === Input Handling ===
func _gui_input(event: InputEvent) -> void:
    # Forward scroll wheel events to camera for zoom (only when not editing)
    if event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_WHEEL_UP or event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
            if not _is_edit_mode: # Only forward scroll when not editing text
                Signals.movement_input.emit(event, global_position)
                accept_event()
            return
        if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
            _set_selected(true)
            accept_event()
    # Forward screen touch/drag for panning (use Vector2.ZERO for correct speed)
    elif event is InputEventScreenTouch or event is InputEventScreenDrag:
        Signals.movement_input.emit(event, Vector2.ZERO)

func _input(event: InputEvent) -> void:
    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
        if _is_selected:
            # Check if click is on any handle.
            var local_mouse = get_local_mouse_position()
            var on_handle = false
            for dir in _resize_handles:
                var handle = _resize_handles[dir]
                if handle.get_rect().has_point(local_mouse):
                    on_handle = true
                    break
            
            if not get_global_rect().has_point(get_global_mouse_position()) and not on_handle:
                _set_selected(false)

const GRID_SIZE = 50.0

func _on_handle_gui_input(event: InputEvent, dir: Vector2) -> void:
    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
        if event.pressed:
            _is_resizing = true
            _resize_dir = dir
            _resize_start_rect = Rect2(position, size)
            _resize_start_mouse = get_global_mouse_position()
            accept_event()
        else:
            if _is_resizing:
                _is_resizing = false
                # Snap final position and size to grid
                position = position.snappedf(GRID_SIZE)
                size = size.snappedf(GRID_SIZE)
                size = size.max(_min_size) # Ensure minimum size
                _update_handle_positions()
                _emit_changed()
                queue_redraw()
                accept_event()
    
    elif event is InputEventMouseMotion:
        if _is_resizing:
            var current_mouse = get_global_mouse_position()
            var delta = current_mouse - _resize_start_mouse
            var new_rect = _resize_start_rect
            
            # Apply X resize
            if _resize_dir.x == 1: # Right
                new_rect.size.x = max(_min_size.x, _resize_start_rect.size.x + delta.x)
            elif _resize_dir.x == -1: # Left
                var max_delta = _resize_start_rect.size.x - _min_size.x
                var actual_delta = min(delta.x, max_delta)
                new_rect.position.x += actual_delta
                new_rect.size.x -= actual_delta
                
            # Apply Y resize
            if _resize_dir.y == 1: # Bottom
                new_rect.size.y = max(_min_size.y, _resize_start_rect.size.y + delta.y)
            elif _resize_dir.y == -1: # Top
                var max_delta = _resize_start_rect.size.y - _min_size.y
                var actual_delta = min(delta.y, max_delta)
                new_rect.position.y += actual_delta
                new_rect.size.y -= actual_delta
            
            # Snap to grid during resize
            position = new_rect.position.snappedf(GRID_SIZE)
            size = new_rect.size.snappedf(GRID_SIZE)
            size = size.max(_min_size)
            
            if not is_nan(position.x) and not is_nan(position.y):
                _update_handle_positions()
                queue_redraw()
            
            accept_event()

# === Event Handlers ===
func _on_color_changed(new_color: Color) -> void:
    note_color = new_color
    update_color()
    _emit_changed()

func _on_pattern_settings_changed(idx: int, c: Color, a: float, sp: float, th: float) -> void:
    pattern_index = idx
    pattern_color = c
    pattern_alpha = a
    pattern_spacing = sp
    pattern_thickness = th
    update_pattern()
    _emit_changed()

func _setup_edit_popup() -> void:
    _edit_popup_layer = CanvasLayer.new()
    _edit_popup_layer.name = "NoteEditPopupLayer"
    _edit_popup_layer.layer = 100
    _edit_popup_layer.visible = false
    call_deferred("_add_layer_to_root", _edit_popup_layer)
    
    var bg = ColorRect.new()
    bg.color = Color(0, 0, 0, 0.4)
    bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    bg.mouse_filter = Control.MOUSE_FILTER_STOP
    bg.gui_input.connect(func(event):
        if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
            _on_edit_cancelled()
    )
    _edit_popup_layer.add_child(bg)
    
    var center = CenterContainer.new()
    center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _edit_popup_layer.add_child(center)
    
    _edit_popup = StickyNoteEditPopupScript.new()
    _edit_popup.confirmed.connect(_on_edit_confirmed)
    _edit_popup.cancelled.connect(_on_edit_cancelled)
    center.add_child(_edit_popup)

func _update_title_icon() -> void:
    if not _title_icon:
        return
    
    # Try to load from res:// first (base game icons)
    var icon_path = "res://textures/icons/" + note_icon + ".png"
    if ResourceLoader.exists(icon_path):
        _title_icon.texture = load(icon_path)
        return
    
    # Try icon from sticky notes directory just in case
    # For now fallback to document
    if not _title_icon.texture:
        var fallback = "res://textures/icons/document.png"
        if ResourceLoader.exists(fallback):
           _title_icon.texture = load(fallback)

func _open_edit_popup() -> void:
    _set_selected(true)
    if not _edit_popup_layer:
        _setup_edit_popup()
        await get_tree().process_frame
    
    _edit_popup_layer.visible = true
    _edit_popup.open(title_text, note_icon)
    _play_sound("click2")

func _on_edit_confirmed(new_title: String, new_icon: String) -> void:
    title_text = new_title
    note_icon = new_icon
    
    if _title_label:
        _title_label.text = title_text
    _update_title_icon()
    
    _edit_popup_layer.visible = false
    _emit_changed()

func _on_edit_cancelled() -> void:
    _edit_popup_layer.visible = false

func _on_title_panel_input(event: InputEvent) -> void:
    # Forward scroll wheel events to camera for zoom
    if event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_WHEEL_UP or event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
            Signals.movement_input.emit(event, global_position)
            accept_event()
            return
        if event.button_index == MOUSE_BUTTON_LEFT:
            if event.pressed:
                _is_dragging = true
                _drag_offset = get_global_mouse_position() - global_position
                drag_started.emit()
                _set_selected(true)
            else:
                if _is_dragging:
                    _is_dragging = false
                    global_position = global_position.snappedf(GRID_SIZE)
                    _update_handle_positions()
                    drag_ended.emit()
                    _emit_changed()
            accept_event()
    
    elif event is InputEventMouseMotion and _is_dragging:
        var new_pos = get_global_mouse_position() - _drag_offset
        global_position = new_pos.snappedf(GRID_SIZE)
        _update_handle_positions()
        accept_event()
    
    # Handle touch events for dragging - DO NOT forward to camera
    elif event is InputEventScreenTouch:
        if event.pressed:
            _is_dragging = true
            _drag_offset = event.position - global_position
            drag_started.emit()
            _set_selected(true)
        else:
            if _is_dragging:
                _is_dragging = false
                global_position = global_position.snappedf(GRID_SIZE)
                _update_handle_positions()
                drag_ended.emit()
                _emit_changed()
        accept_event()
    
    elif event is InputEventScreenDrag and _is_dragging:
        var new_pos = event.position - _drag_offset
        global_position = new_pos.snappedf(GRID_SIZE)
        _update_handle_positions()
        accept_event()

func _on_duplicate_pressed() -> void:
    _play_sound("click2")
    note_duplicated.emit(note_id, position + Vector2(30, 30))

func _on_delete_pressed() -> void:
    _play_sound("close")
    note_deleted.emit(note_id)

# === Edit Mode Logic ===

func _set_edit_mode(enabled: bool) -> void:
    _is_edit_mode = enabled
    
    if _is_edit_mode:
        _body_display.visible = false
        _body_edit.visible = true
        _body_edit.grab_focus()
        # Ensure text matches
        _body_edit.text = body_text
        # Optional: Select all
    else:
        _body_display.visible = true
        _body_edit.visible = false
        # Update BBCode display
        _update_display_text()

func _update_display_text() -> void:
    # Use clear + append_text for proper BBCode parsing
    _body_display.clear()
    _body_display.append_text(body_text)

func _on_view_gui_input(event: InputEvent) -> void:
    # Forward scroll wheel events to camera for zoom
    if event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_WHEEL_UP or event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
            Signals.movement_input.emit(event, global_position)
            accept_event()
            return
        if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
            if event.double_click:
                _set_edit_mode(true)
                accept_event()
            else:
                _set_selected(true)
    # Forward screen touch/drag for panning (use Vector2.ZERO for correct speed)
    elif event is InputEventScreenTouch or event is InputEventScreenDrag:
        Signals.movement_input.emit(event, Vector2.ZERO)

func _on_body_changed() -> void:
    body_text = _body_edit.text

func _on_body_focus_exited() -> void:
    # If we clicked outside entirely, this might trigger.
    # But usually we only want to exit edit mode if we deselect?
    # Actually, clicking buttons or other elements takes focus.
    # Let's keep edit mode until explicitly closed or deselected.
    pass

func _on_body_gui_input(event: InputEvent) -> void:
    # In edit mode, don't forward scroll - let TextEdit handle text scrolling
    # Scroll forwarding only happens when NOT in edit mode (handled by _on_view_gui_input)
    # Handle right-click for context menu
    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
        if event.pressed:
            accept_event()
            _open_context_menu(event.global_position)
        return
    
    if event is InputEventKey and event.pressed:
        # Handle Enter key manually (game has disabled ui_text_newline action)
        if event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
            if not event.ctrl_pressed and not event.alt_pressed:
                _body_edit.insert_text_at_caret("\n")
                accept_event()
                return
        
        if event.keycode == KEY_A and event.ctrl_pressed:
            _body_edit.select_all()
            accept_event()
        # Keyboard shortcuts for formatting (Ctrl+B/I/U)
        elif event.ctrl_pressed and _body_edit.has_selection():
            var handled = true
            match event.keycode:
                KEY_B:
                    _perform_formatting("bold", null)
                KEY_I:
                    _perform_formatting("italic", null)
                KEY_U:
                    _perform_formatting("underline", null)
                _:
                    handled = false
            if handled:
                accept_event()

func _open_context_menu(pos: Vector2) -> void:
    if not _context_menu: return
    var has_sel = _body_edit.has_selection()
    _context_menu.show_at(pos, has_sel, get_tree())

func _on_format_requested(property: String, value) -> void:
    _perform_formatting(property, value)

func _perform_formatting(property: String, value) -> void:
    if not _body_edit.has_selection():
        return

    # var sel_start_line = _body_edit.get_selection_from_line()
    # var sel_start_col = _body_edit.get_selection_from_column()
    # var sel_end_line = _body_edit.get_selection_to_line()
    # var sel_end_col = _body_edit.get_selection_to_column()
    
    var selected_text = _body_edit.get_selected_text()
    var open_tag = ""
    var close_tag = ""
    
    match property:
        "bold":
            open_tag = "[b]"; close_tag = "[/b]"
        "italic":
            open_tag = "[i]"; close_tag = "[/i]"
        "underline":
            open_tag = "[u]"; close_tag = "[/u]"
        "color":
            if value is Color:
                open_tag = "[color=#%s]" % value.to_html(false)
                close_tag = "[/color]"
        "font_size":
            if value == -1: # Small
                open_tag = "[font_size=10]"; close_tag = "[/font_size]"
            elif value == 0: # Normal (Clear size)
                 pass # Just remove?
            elif value == 1: # Large
                open_tag = "[font_size=20]"; close_tag = "[/font_size]"

    if open_tag != "":
        var new_text = open_tag + selected_text + close_tag
        
        _body_edit.insert_text_at_caret(new_text)
        
        # Restore selection? usually not needed after replace
        _on_body_changed() # Force update

func _on_clear_format_requested() -> void:
    # A simple regex based stripper or just remove all tags in selection would be complex
    # For now, just a placeholder or minimal implementation
    pass

func _emit_changed() -> void:
    note_changed.emit(note_id)

# === Public API ===
func set_note_id(id: String) -> void:
    note_id = id

func set_note_color(color: Color) -> void:
    note_color = color
    update_color()

func set_title(text: String) -> void:
    title_text = text if text else "Note"
    if _title_label: _title_label.text = title_text

func set_icon(icon_name: String) -> void:
    note_icon = icon_name if icon_name else "document"
    _update_title_icon()

func set_body(text: String) -> void:
    body_text = text
    if _body_edit:
        _body_edit.text = text
    if _body_display:
        _update_display_text()

func set_manager(manager) -> void:
    _manager = manager

func get_data() -> Dictionary:
    var data := {
        "id": note_id,
        "position": [position.x, position.y],
        "size": [size.x, size.y],
        "title": title_text,
        "icon": note_icon,
        "body": body_text,
        "color": note_color.to_html(true),
        "pattern_index": pattern_index,
        "pattern_color": pattern_color.to_html(true),
        "pattern_alpha": pattern_alpha,
        "pattern_spacing": pattern_spacing,
        "pattern_thickness": pattern_thickness
    }
    return data

func load_from_data(data: Dictionary) -> void:
    if data.has("id"): note_id = data["id"]
    if data.has("position"): position = Vector2(data["position"][0], data["position"][1])
    if data.has("size"): size = Vector2(data["size"][0], data["size"][1])
    if data.has("title"): set_title(data["title"])
    if data.has("icon"): set_icon(data["icon"])
    if data.has("body"): set_body(data["body"])
    if data.has("color"): set_note_color(Color.html(data["color"]))
    
    if data.has("pattern_index"): pattern_index = data["pattern_index"]
    if data.has("pattern_color"): pattern_color = Color.html(data["pattern_color"])
    if data.has("pattern_alpha"): pattern_alpha = data["pattern_alpha"]
    if data.has("pattern_spacing"): pattern_spacing = data["pattern_spacing"]
    if data.has("pattern_thickness"): pattern_thickness = data["pattern_thickness"]
    
    update_color()
    update_pattern()

func _notification(what):
    if what == NOTIFICATION_PREDELETE:
        if is_instance_valid(_color_picker_layer): _color_picker_layer.queue_free()
        if is_instance_valid(_pattern_picker_layer): _pattern_picker_layer.queue_free()
        if is_instance_valid(_context_menu_layer): _context_menu_layer.queue_free()
        if is_instance_valid(_edit_popup_layer): _edit_popup_layer.queue_free()

func _play_sound(sound_id: String) -> void:
    var sound = Engine.get_main_loop().root.get_node_or_null("Sound")
    if sound: sound.play(sound_id)
