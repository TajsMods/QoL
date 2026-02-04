extends "res://scripts/edit_group_popup.gd"

const DEFAULT_ICON_ID := ""
const IconPickerPopupScript = preload("res://mods-unpacked/TajemnikTV-QoL/extensions/scripts/ui/icon_picker_popup.gd")
const ICON_PREVIEW_SIZE := 56
const ICON_PREVIEW_SIZE_COMPACT := 48
const POPUP_MIN_SIZE := Vector2(760, 580)
const POPUP_MAX_SIZE := Vector2(1180, 880)
const POPUP_SIZE_RATIO := Vector2(0.88, 0.88)
const COMPACT_VIEWPORT := Vector2(1200, 700)
const BUTTON_SIZE := Vector2(96, 32)
const BUTTON_SIZE_COMPACT := Vector2(86, 28)
const BUTTON_FONT_SIZE := 18
const BUTTON_FONT_SIZE_COMPACT := 16

# Static signal for sticky notes (not typed to WindowIndexed)
static var edit_sticky_note_signal: Signal
signal edit_sticky_note(sticky: Control)

var _selected_icon_id: String = DEFAULT_ICON_ID
var _icon_preview: TextureRect
var _icon_name_label: Label
var _icon_change_btn: Button

# Reference to sticky note (when editing a sticky note instead of WindowIndexed)
var _sticky_note = null


func _ready() -> void:
	super._ready()
	_setup_icon_picker()
	_apply_layout()
	var viewport := get_viewport()
	if viewport != null:
		if not viewport.size_changed.is_connected(_on_viewport_resized):
			viewport.size_changed.connect(_on_viewport_resized)
	
	# Register the sticky note signal handler
	edit_sticky_note_signal = Signal(self , "edit_sticky_note")
	if not edit_sticky_note_signal.is_connected(_on_edit_sticky_note):
		edit_sticky_note_signal.connect(_on_edit_sticky_note)


func set_node(group_node: WindowIndexed) -> void:
	_sticky_note = null
	super.set_node(group_node)
	_set_selected_icon(_normalize_icon_id(str(group_node.custom_icon)))


func set_sticky_note(sticky: Control) -> void:
	# Handle sticky notes which don't extend WindowIndexed
	_sticky_note = sticky
	node = null
	$EditContainer/MainPanel/InfoContainer/Label.text = sticky.custom_name
	_set_selected_icon(_normalize_icon_id(str(sticky.custom_icon)))


func _on_edit_sticky_note(sticky: Control) -> void:
	# Called when editing a sticky note
	set_sticky_note(sticky)
	# Trigger the popup display
	get_parent().popup()
	get_parent().set_popup("EditGroup")


func set_icon(icon: int) -> void:
	icon_index = icon


func _on_icon_button_pressed(_index: int) -> void:
	pass


func _on_confirm_pressed() -> void:
	var group_name: String = $EditContainer/MainPanel/InfoContainer/Label.text
	
	if _sticky_note != null:
		# Editing a sticky note
		_sticky_note.set_custom_name(group_name)
		_sticky_note.set_icon(_selected_icon_id)
	elif node != null:
		# Editing a regular WindowIndexed
		node.set_custom_name(group_name)
		node.set_icon(_selected_icon_id)

	close()
	Sound.play("click2")


func hide() -> void:
	super.hide()
	_set_selected_icon(DEFAULT_ICON_ID)
	_apply_layout()

func _on_viewport_resized() -> void:
	_apply_layout()

func _apply_layout() -> void:
	var viewport := get_viewport()
	if viewport == null:
		return
	var viewport_size := viewport.get_visible_rect().size
	var compact := viewport_size.x <= COMPACT_VIEWPORT.x or viewport_size.y <= COMPACT_VIEWPORT.y
	var cancel_btn := $EditContainer/Buttons/Cancel
	if cancel_btn:
		cancel_btn.custom_minimum_size = BUTTON_SIZE_COMPACT if compact else BUTTON_SIZE
		cancel_btn.add_theme_font_size_override("font_size", BUTTON_FONT_SIZE_COMPACT if compact else BUTTON_FONT_SIZE)
	var confirm_btn := $EditContainer/Buttons/Confirm
	if confirm_btn:
		confirm_btn.custom_minimum_size = BUTTON_SIZE_COMPACT if compact else BUTTON_SIZE
		confirm_btn.add_theme_font_size_override("font_size", BUTTON_FONT_SIZE_COMPACT if compact else BUTTON_FONT_SIZE)
	if _icon_preview:
		var icon_size := ICON_PREVIEW_SIZE_COMPACT if compact else ICON_PREVIEW_SIZE
		_icon_preview.custom_minimum_size = Vector2(icon_size, icon_size)
	if _icon_change_btn:
		_icon_change_btn.add_theme_font_size_override("font_size", BUTTON_FONT_SIZE_COMPACT if compact else BUTTON_FONT_SIZE)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_WHEEL_UP or mouse_event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			accept_event()


func _setup_icon_picker() -> void:
	var info_container := $EditContainer/MainPanel/InfoContainer
	var icons_container := info_container.get_node_or_null("IconsContainer")
	if icons_container != null:
		icons_container.visible = false
	if info_container.has_node("IconPickerRow"):
		return
	var row := HBoxContainer.new()
	row.name = "IconPickerRow"
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 12)
	_icon_preview = TextureRect.new()
	_icon_preview.custom_minimum_size = Vector2(ICON_PREVIEW_SIZE, ICON_PREVIEW_SIZE)
	_icon_preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_icon_preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	row.add_child(_icon_preview)
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var label := Label.new()
	label.text = "Icon"
	label.add_theme_font_size_override("font_size", 14)
	info.add_child(label)
	_icon_name_label = Label.new()
	info.add_child(_icon_name_label)
	row.add_child(info)
	_icon_change_btn = Button.new()
	_icon_change_btn.text = "Change Icon"
	_icon_change_btn.focus_mode = Control.FOCUS_NONE
	_icon_change_btn.pressed.connect(_on_change_icon_pressed)
	row.add_child(_icon_change_btn)
	info_container.add_child(row)
	info_container.move_child(row, 0)
	_set_selected_icon(_selected_icon_id)


func _set_selected_icon(icon_id: String) -> void:
	_selected_icon_id = icon_id
	_update_icon_preview()


func _on_change_icon_pressed() -> void:
	var options := {
		"title": "Select Icon",
		"allow_clear": true,
		"initial_selected_id": _selected_icon_id,
		"auto_confirm": true,
		"show_select_button": false
	}
	IconPickerPopupScript.open(options, func(selected_id, _entry):
		if selected_id == null:
			_selected_icon_id = ""
		else:
			_selected_icon_id = str(selected_id)
		_update_icon_preview()
		Sound.play("click_toggle2")
	)


func _normalize_icon_id(icon_value: String) -> String:
	if icon_value == "":
		return ""
	if icon_value.begins_with("res://"):
		return icon_value
	if icon_value.find(":") != -1:
		return icon_value
	return "base:%s.png" % icon_value


func _update_icon_preview() -> void:
	if _icon_preview == null:
		return
	var icon_id := _selected_icon_id
	var tex := _resolve_icon_texture(icon_id)
	if tex != null:
		_icon_preview.texture = tex
	else:
		_icon_preview.texture = load("res://textures/icons/window.png")
	if _icon_name_label != null:
		_icon_name_label.text = _get_icon_label(icon_id)


func _get_icon_label(icon_id: String) -> String:
	if icon_id == "":
		return "Default"
	var entry := _get_icon_entry(icon_id)
	if entry is Dictionary:
		var label := str(entry.get("display_name", entry.get("name", "")))
		if label != "":
			return label
	if icon_id.begins_with("res://"):
		return icon_id.get_file().get_basename().capitalize()
	if icon_id.find(":") != -1:
		var parts := icon_id.split(":", false, 1)
		if parts.size() == 2 and parts[1] != "":
			var base := parts[1].get_file().get_basename().replace("_", " ").replace("-", " ")
			return base.capitalize()
	return icon_id


func _get_icon_entry(icon_id: String) -> Dictionary:
	var core = Engine.get_meta("TajsCore", null)
	if core != null:
		var registry = core.get_icon_registry()
		if registry != null:
			var resolved: Dictionary = registry.resolve_icon(icon_id)
			var entry = resolved.get("entry", null)
			if entry is Dictionary:
				return entry
	return {}


func _resolve_icon_texture(icon_id: String) -> Texture2D:
	var core = Engine.get_meta("TajsCore", null)
	if core != null:
		var registry = core.get_icon_registry()
		if registry != null:
			var resolved: Dictionary = registry.resolve_icon(icon_id)
			if resolved.get("texture", null) != null:
				return resolved.texture
	if icon_id == "":
		return null
	if icon_id.begins_with("res://") and ResourceLoader.exists(icon_id):
		return load(icon_id)
	if icon_id.find(":") != -1:
		var parts := icon_id.split(":", false, 1)
		if parts.size() == 2 and parts[1] != "":
			var mapped_path := "res://textures/icons".path_join(parts[1])
			if ResourceLoader.exists(mapped_path):
				return load(mapped_path)
	var icon_path := "res://textures/icons/" + icon_id + ".png"
	if ResourceLoader.exists(icon_path):
		return load(icon_path)
	return null
