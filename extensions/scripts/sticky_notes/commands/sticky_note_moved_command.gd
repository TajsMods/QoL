# ==============================================================================
# Taj's QoL - StickyNoteMovedCommand
# Undoable command for sticky note movement
# ==============================================================================
extends "res://mods-unpacked/TajemnikTV-Core/core/commands/undo/undo_command.gd"

var _manager = null
var _note_id: String = ""
var _before_pos: Vector2 = Vector2.ZERO
var _after_pos: Vector2 = Vector2.ZERO

## Setup the command
func setup(manager, note_id: String, before: Vector2, after: Vector2) -> void:
    _manager = manager
    _note_id = note_id
    _before_pos = before
    _after_pos = after
    description = "Move Sticky Note"

## Execute (move to after)
func execute() -> bool:
    if not is_instance_valid(_manager):
        return false
        
    var note = _manager._notes.get(_note_id)
    if is_instance_valid(note):
        note.position = _after_pos
        _manager.save_notes()
        return true
        
    return false

## Undo (move to before)
func undo() -> bool:
    if not is_instance_valid(_manager):
        return false
        
    var note = _manager._notes.get(_note_id)
    if is_instance_valid(note):
        note.position = _before_pos
        _manager.save_notes()
        return true
        
    return false

## Check if command is valid
func is_valid() -> bool:
    if not is_instance_valid(_manager): return false
    return _manager._notes.has(_note_id)
