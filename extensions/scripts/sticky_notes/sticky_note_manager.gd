# ==============================================================================
# Taj's QoL - Sticky Note Manager
# Manages all sticky notes on the canvas
# Ported from TajsModded
# ==============================================================================
extends Node
class_name TajsStickyNoteManager

const LOG_NAME = "TajsQoL:StickyNoteManager"
const StickyNoteScript = preload("res://mods-unpacked/TajemnikTV-QoL/extensions/scripts/sticky_notes/ui/sticky_note.gd")

# Undo Commands
const StickyNoteCreatedCommandScript = preload("res://mods-unpacked/TajemnikTV-QoL/extensions/scripts/sticky_notes/commands/sticky_note_created_command.gd")
const StickyNoteDeletedCommandScript = preload("res://mods-unpacked/TajemnikTV-QoL/extensions/scripts/sticky_notes/commands/sticky_note_deleted_command.gd")
const StickyNoteMovedCommandScript = preload("res://mods-unpacked/TajemnikTV-QoL/extensions/scripts/sticky_notes/commands/sticky_note_moved_command.gd")
const StickyNoteChangedCommandScript = preload("res://mods-unpacked/TajemnikTV-QoL/extensions/scripts/sticky_notes/commands/sticky_note_changed_command.gd")

# Signals for external tracking
signal note_added(note: Control)
signal note_removed(note_id: String, note_data: Dictionary)

# References
var _config = null
var _desktop: Control = null
var _notes_container: Control = null
var _mod_main = null

# State
var _notes: Dictionary = {} # note_id -> TajsStickyNote
var _next_id: int = 0
var _debug_enabled := false

# Undo State Tracking
var _note_drag_start_pos: Dictionary = {} # note_id -> Vector2
var _note_edit_start_data: Dictionary = {} # note_id -> Dictionary

func setup(config, _tree: SceneTree, mod_main = null) -> void:
    _config = config
    _mod_main = mod_main

    # Try to initialize immediately, or defer if not ready
    if not _try_initialize():
        # Retry until desktop is available
        call_deferred("_deferred_init")

func _deferred_init() -> void:
    if _notes_container: # Already initialized
        return
    if _try_initialize():
        return
    # Still not ready, try again next frame
    await get_tree().process_frame
    _deferred_init()

func _try_initialize() -> bool:
    if not Globals or not is_instance_valid(Globals.desktop):
        return false

    _desktop = Globals.desktop

    _notes_container = Control.new()
    _notes_container.name = "StickyNotesContainer"
    _notes_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _notes_container.set_anchors_preset(Control.PRESET_FULL_RECT)
    _notes_container.z_index = 5
    _desktop.add_child(_notes_container)

    load_notes()

    _log("Sticky Note Manager initialized", true)
    return true

func _log(message: String, force: bool = false) -> void:
    if force or _debug_enabled:
        ModLoaderLog.info(message, LOG_NAME)

func set_debug_enabled(enabled: bool) -> void:
    _debug_enabled = enabled

# ==============================================================================
# NOTE CRUD OPERATIONS
# ==============================================================================

func create_note_at_camera_center():
    var camera_center = Globals.camera_center if Globals else Vector2(500, 300)
    return create_note(camera_center - Vector2(125, 75))

func create_note(world_pos: Vector2, note_size: Vector2 = Vector2(250, 150)):
    if not _notes_container:
        return null

    var note = StickyNoteScript.new()
    var note_id = _generate_id()

    note.set_note_id(note_id)
    note.position = world_pos
    note.size = note_size
    note.set_manager(self )

    _connect_note_signals(note)

    _notes_container.add_child(note)
    _notes[note_id] = note

    save_notes()
    Signals.notify.emit("check", "Note created!")
    note_added.emit(note)

    # Undo Command
    if _get_undo_manager():
        var cmd = StickyNoteCreatedCommandScript.new()
        cmd.setup(self , note)
        _get_undo_manager().push_command(cmd)

    return note

func delete_note(note_id: String) -> void:
    if not _notes.has(note_id):
        return

    var note = _notes[note_id]
    var note_data = note.get_data() if is_instance_valid(note) else {}

    _notes.erase(note_id)

    if is_instance_valid(note):
        note.queue_free()

    save_notes()
    Signals.notify.emit("check", "Note deleted")

    if not note_data.is_empty():
        note_removed.emit(note_id, note_data)

        # Undo Command
        if _get_undo_manager():
            var cmd = StickyNoteDeletedCommandScript.new()
            cmd.setup(self , note_id, note_data)
            _get_undo_manager().push_command(cmd)

func duplicate_note(note_id: String, new_position: Vector2):
    if not _notes.has(note_id):
        return null

    var original = _notes[note_id]
    var data = original.get_data()

    # We use _create_note_from_data directly to handle undo logic here manually if needed?
    # Or just use create_note and populate it?
    # create_note pushes a command. If we populate it after, that's a change command.
    # We want one command for "Duplicate".
    # Implementation: Create blank note (pushes command), then set data (pushes command).
    # This creates 2 undo steps. Ideally one.

    # Better: Create note without pushing command, then push specific "Created" command with full data.
    # But create_note pushes command.

    # Let's just use create_note and accept 2 steps or combine them?
    # Actually, let's just make create_note take optional data?

    # For now, simplistic approach:
    var new_note = create_note(new_position, original.size)
    if new_note:
        var dup_data = data.duplicate()
        dup_data.erase("id")
        dup_data.erase("position")

        # This will trigger note_changed and push a change command
        new_note.load_from_data(dup_data)

        Signals.notify.emit("check", "Note duplicated!")

    return new_note

func _generate_id() -> String:
    _next_id += 1
    return "note_%d_%d" % [Time.get_ticks_msec(), _next_id]

func _connect_note_signals(note: Control) -> void:
    # note_changed already provides note_id as parameter, don't bind
    note.note_changed.connect(_on_note_changed)
    note.note_deleted.connect(_on_note_deleted)
    note.note_duplicated.connect(_on_note_duplicated)
    note.drag_started.connect(_on_note_drag_started.bind(note.note_id))
    note.drag_ended.connect(_on_note_drag_ended.bind(note.note_id))
    note.selection_changed.connect(_on_note_selection_changed.bind(note.note_id))

# ==============================================================================
# SIGNAL HANDLERS & UNDO LOGIC
# ==============================================================================

func _on_note_changed(_note_id: String) -> void:
    # This signal is emitted when something changes.
    # We rely on selection_changed to capture start/end state for Undo.
    save_notes()

func _on_note_deleted(note_id: String) -> void:
    delete_note(note_id)

func _on_note_duplicated(_original_id: String, note_id: String, new_position: Vector2) -> void:
    # Signal signature from StickyNote: note_id, new_position
    # Wait, the signal in StickyNote is: signal note_duplicated(note_id: String, new_position: Vector2)
    # The bind above was: .connect(_on_note_duplicated.bind(note.note_id))
    # So we get (bound_id, emitted_id, pos). They are same.
    duplicate_note(note_id, new_position)

# --- UNDO TRACKING ---

func _on_note_drag_started(note_id: String) -> void:
    if _notes.has(note_id):
        _note_drag_start_pos[note_id] = _notes[note_id].position

func _on_note_drag_ended(note_id: String) -> void:
    if not _notes.has(note_id) or not _note_drag_start_pos.has(note_id):
        return

    var start_pos = _note_drag_start_pos[note_id]
    var current_pos = _notes[note_id].position

    if start_pos.distance_to(current_pos) > 1.0: # Threshold
        if _get_undo_manager():
            var cmd = StickyNoteMovedCommandScript.new()
            cmd.setup(self , note_id, start_pos, current_pos)
            _get_undo_manager().push_command(cmd)

func _on_note_selection_changed(selected: bool, note_id: String) -> void:
    if not _notes.has(note_id): return

    if selected:
        # Cache start state
        _note_edit_start_data[note_id] = _notes[note_id].get_data().duplicate()
    else:
        # Compare and push change if needed
        if _note_edit_start_data.has(note_id):
            var before = _note_edit_start_data[note_id]
            var after = _notes[note_id].get_data()

            # Check for differences
            if str(before) != str(after):
                if _get_undo_manager():
                    var cmd = StickyNoteChangedCommandScript.new()
                    cmd.setup(self , note_id, before, after)
                    _get_undo_manager().push_command(cmd)


func _get_undo_manager():
    if not Engine.has_meta("TajsCore"): return null
    var core = Engine.get_meta("TajsCore")
    # Access runtime -> undo_manager
    if core.has_method("get_runtime"):
        pass

    # Better way: Use the same method as mod_main uses
    return core.undo_manager if core and "undo_manager" in core else null


# ==============================================================================
# PERSISTENCE
# ==============================================================================

const NOTES_KEY = "tajs_qol.sticky_notes_data"

func save_notes() -> void:
    if not _config:
        _log("Cannot save notes - no config", true)
        return
    var notes_data: Array = []
    for note_id in _notes:
        var note = _notes[note_id]
        if is_instance_valid(note):
            notes_data.append(note.get_data())
    _config.set_value(NOTES_KEY, notes_data)
    _log("Saved %d notes" % notes_data.size(), true)

func load_notes() -> void:
    if not _config:
        _log("Cannot load notes - no config", true)
        return
    var notes_data = _config.get_value(NOTES_KEY, [])
    _log("Loading notes, found %d entries" % (notes_data.size() if notes_data is Array else 0), true)
    if not notes_data is Array: notes_data = []

    for note_id in _notes:
        var note = _notes[note_id]
        if is_instance_valid(note): note.queue_free()
    _notes.clear()

    for data in notes_data:
        if data is Dictionary:
            _log("Loading note data: %s" % str(data), true)
            _create_note_from_data(data)

func _create_note_from_data(data: Dictionary):
    if not _notes_container: return null
    var note = StickyNoteScript.new()
    note.set_manager(self )

    # Set the note_id FIRST from data, before connecting signals
    if data.has("id"):
        note.set_note_id(data["id"])

    # Add note to dictionary BEFORE connecting signals and loading data
    # This prevents save_notes() from being called with an empty dictionary
    # when load_from_data() triggers note_changed signals
    _notes[note.note_id] = note

    _connect_note_signals(note)

    # Add to tree first so _ready() builds UI elements
    _notes_container.add_child(note)

    # Now load data (which calls update_color/update_pattern and may emit note_changed)
    note.load_from_data(data)

    return note

# ==============================================================================
# PUBLIC API
# ==============================================================================

func get_note_count() -> int:
    return _notes.size()

func get_all_notes() -> Array:
    var result = []
    for note_id in _notes:
        if is_instance_valid(_notes[note_id]):
            result.append(_notes[note_id])
    return result

func navigate_to_note(note: Control) -> void:
    if not is_instance_valid(note): return
    Signals.center_camera.emit(note.position + note.size / 2)
    Globals.set_selection([], [], 0)
    note._set_selected(true)

func clear_all_notes() -> void:
    for note_id in _notes.keys():
        delete_note(note_id)
