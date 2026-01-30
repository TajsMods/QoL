# ==============================================================================
# Taj's QoL - WireColorChangedCommand
# Undoable command for wire color changes
# ==============================================================================
extends "res://mods-unpacked/TajemnikTV-Core/core/commands/undo/undo_command.gd"

var _feature_ref: WeakRef = null
var _resource_id: String = ""
var _before_hex: String = ""  # Empty string means "use original"
var _after_hex: String = ""

## Setup the command
func setup(feature: RefCounted, resource_id: String, before_hex: String, after_hex: String) -> void:
    _feature_ref = weakref(feature)
    _resource_id = resource_id
    _before_hex = before_hex
    _after_hex = after_hex
    
    # Generate a nice description
    var wire_name := resource_id.replace("_", " ").capitalize()
    if after_hex.is_empty():
        description = "Reset %s Color" % wire_name
    else:
        description = "Change %s Color" % wire_name


## Execute (apply after state)
func execute() -> bool:
    var feature = _feature_ref.get_ref()
    if feature == null:
        return false
    
    if _after_hex.is_empty():
        feature.reset_color(_resource_id)
    else:
        feature.set_color(_resource_id, Color(_after_hex))
    return true


## Undo (apply before state)
func undo() -> bool:
    var feature = _feature_ref.get_ref()
    if feature == null:
        return false
    
    if _before_hex.is_empty():
        feature.reset_color(_resource_id)
    else:
        feature.set_color(_resource_id, Color(_before_hex))
    return true


## Merge with subsequent command
func merge_with(other: RefCounted) -> bool:
    if other.get_script() != get_script():
        return false
    
    # Must be same resource
    if other._resource_id != _resource_id:
        return false
    
    # Time-based merge limit
    if other.timestamp - timestamp > MERGE_WINDOW_MS:
        return false
    
    # Merge: Update after_hex to be other's after_hex
    _after_hex = other._after_hex
    timestamp = other.timestamp
    return true


## Check if command is valid
func is_valid() -> bool:
    var feature = _feature_ref.get_ref()
    return feature != null
