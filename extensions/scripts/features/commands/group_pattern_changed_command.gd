# ==============================================================================
# Taj's QoL - GroupPatternChangedCommand
# Undoable command for group pattern and custom color changes
# ==============================================================================
extends "res://mods-unpacked/TajemnikTV-Core/core/commands/undo/undo_command.gd"

var _group_ref: WeakRef = null
var _group_name: String = ""
var _before_data: Dictionary = {}
var _after_data: Dictionary = {}
var _changed_keys: Array = []

## Setup the command
func setup(group: Node, before: Dictionary, after: Dictionary) -> void:
	_group_ref = weakref(group)
	_group_name = str(group.name) if group != null else "Unknown"
	_before_data = before.duplicate()
	_after_data = after.duplicate()
	description = "Edit Group Pattern"
	
	# Identify what changed for merge comparison
	_changed_keys = []
	for key in after.keys():
		if not before.has(key) or str(before[key]) != str(after[key]):
			_changed_keys.append(key)
	for key in before.keys():
		if not after.has(key):
			if not key in _changed_keys:
				_changed_keys.append(key)
	_changed_keys.sort()
	
	# Customize description based on what changed
	if _changed_keys.size() == 1:
		match _changed_keys[0]:
			"pattern_index":
				description = "Change Group Pattern"
			"custom_color":
				description = "Change Group Color"
			"pattern_color":
				description = "Change Pattern Color"
			"pattern_alpha":
				description = "Change Pattern Opacity"
			"pattern_spacing":
				description = "Change Pattern Spacing"
			"pattern_thickness":
				description = "Change Pattern Thickness"


## Get current pattern data from group
static func capture_state(group: Node) -> Dictionary:
	return {
		"pattern_index": group.pattern_index,
		"pattern_color": group.pattern_color.to_html(true),
		"pattern_alpha": group.pattern_alpha,
		"pattern_spacing": group.pattern_spacing,
		"pattern_thickness": group.pattern_thickness,
		"custom_color": group.custom_color.to_html(true) if group.custom_color != Color.TRANSPARENT else "",
	}


## Apply data to group
func _apply_data(data: Dictionary) -> bool:
	var group = _group_ref.get_ref()
	if not is_instance_valid(group):
		return false
	
	if data.has("pattern_index"):
		group.pattern_index = int(data["pattern_index"])
	if data.has("pattern_color"):
		group.pattern_color = Color.html(str(data["pattern_color"]))
	if data.has("pattern_alpha"):
		group.pattern_alpha = float(data["pattern_alpha"])
	if data.has("pattern_spacing"):
		group.pattern_spacing = float(data["pattern_spacing"])
	if data.has("pattern_thickness"):
		group.pattern_thickness = float(data["pattern_thickness"])
	if data.has("custom_color"):
		var cc_str = str(data["custom_color"])
		if cc_str == "":
			group.custom_color = Color.TRANSPARENT
		else:
			group.custom_color = Color.html(cc_str)
	
	# Update visuals
	if group.has_method("update_pattern"):
		group.update_pattern()
	if group.has_method("update_color"):
		group.update_color()
	
	# Save to settings
	if group.has_method("_save_to_settings"):
		group._save_to_settings()
	
	return true


## Execute (apply after data)
func execute() -> bool:
	return _apply_data(_after_data)


## Undo (apply before data)
func undo() -> bool:
	return _apply_data(_before_data)


## Merge with subsequent command
func merge_with(other: RefCounted) -> bool:
	if other.get_script() != get_script():
		return false
	
	# Must be same group
	var my_group: Variant = _group_ref.get_ref()
	var other_group: Variant = other._group_ref.get_ref()
	if my_group != other_group:
		return false
	
	# Check if same properties changed
	if _changed_keys != other._changed_keys:
		return false
	
	# Time-based merge limit
	if other.timestamp - timestamp > MERGE_WINDOW_MS:
		return false
	
	# Merge: Update after_data to be other's after_data
	_after_data = other._after_data
	timestamp = other.timestamp
	return true


## Check if command is valid
func is_valid() -> bool:
	var group = _group_ref.get_ref()
	return is_instance_valid(group) and group.is_inside_tree()
