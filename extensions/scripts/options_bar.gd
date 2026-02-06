extends "res://scripts/options_bar.gd"

const SETTING_DELETE_CONFIRM_THRESHOLD := "tajs_qol.delete_confirm_threshold"

var lock_button: Button = null


func _ready() -> void:
    super._ready()
    _inject_lock_button()
    _update_lock_button()


func update_buttons() -> void:
    super.update_buttons()
    _update_lock_button()


func _inject_lock_button() -> void:
    var window_options = get_node_or_null("WindowOptions")
    if window_options == null:
        push_error("[Taj's QoL] WindowOptions not found in options_bar")
        return

    lock_button = Button.new()
    lock_button.name = "Lock"
    lock_button.custom_minimum_size = Vector2(80, 80)
    lock_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER | Control.SIZE_EXPAND
    lock_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
    lock_button.focus_mode = Control.FOCUS_NONE
    lock_button.theme_type_variation = "ButtonMenu"
    lock_button.icon = load("res://textures/icons/padlock.png")
    lock_button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
    lock_button.expand_icon = true
    lock_button.visible = false
    lock_button.tooltip_text = "Lock/Unlock Group Position"
    lock_button.pressed.connect(_on_lock_pressed)

    window_options.add_child(lock_button)
    var delete_btn = window_options.get_node_or_null("Delete")
    if delete_btn:
        var delete_idx = delete_btn.get_index()
        window_options.move_child(lock_button, delete_idx)


func _update_lock_button() -> void:
    if lock_button == null:
        return

    var show_lock = false
    var any_locked = false

    for window in Globals.selections:
        var has_toggle = window.has_method("toggle_lock")
        if has_toggle:
            show_lock = true
            if window.has_method("is_locked") and window.is_locked():
                any_locked = true

    lock_button.visible = show_lock
    if any_locked:
        lock_button.icon = load("res://textures/icons/padlock_open.png")
        lock_button.tooltip_text = "Unlock Group Position"
    else:
        lock_button.icon = load("res://textures/icons/padlock.png")
        lock_button.tooltip_text = "Lock Group Position"


func _on_lock_pressed() -> void:
    for window in Globals.selections:
        if window.has_method("toggle_lock"):
            window.toggle_lock()
    _update_lock_button()
    Sound.play("click2")


func _on_pause_pressed() -> void:
    # Capture pause states before toggle for undo
    var undo_manager = _get_undo_manager()
    var before_states: Dictionary = {}
    var pausable_windows: Array = []

    for window in Globals.selections:
        if window.can_pause:
            pausable_windows.append(window)
            before_states[window.name] = window.paused if "paused" in window else false

    # Call parent to do the actual toggle
    super._on_pause_pressed()

    # Capture pause states after toggle and record undo
    if undo_manager != null and not before_states.is_empty():
        var after_states: Dictionary = {}
        for window in pausable_windows:
            if is_instance_valid(window):
                after_states[window.name] = window.paused if "paused" in window else false

        # Only record if states actually changed
        var changed := false
        for window_name in before_states:
            if before_states[window_name] != after_states.get(window_name, before_states[window_name]):
                changed = true
                break

        if changed:
            undo_manager.record_pause_change(before_states, after_states)


func begin_deletion() -> void:
    var warn := false
    var deletable_count := 0

    for window in Globals.selections:
        if window.can_delete and not window.closing:
            deletable_count += 1
        if not window.importing and window.warn_deletion:
            warn = true

    if deletable_count >= _get_delete_confirm_threshold():
        var shown := _show_large_delete_popup(deletable_count, func():
            _continue_deletion(warn)
        )
        if shown:
            return

    _continue_deletion(warn)


func _continue_deletion(warn: bool) -> void:
    if warn:
        Signals.prompt.emit("prompt_delete_node", "prompt_delete_node_desc", delete)
    else:
        delete()


func _get_delete_confirm_threshold() -> int:
    var threshold := 20
    var core = Engine.get_meta("TajsCore", null)
    if core != null and core.settings != null:
        threshold = core.settings.get_int(SETTING_DELETE_CONFIRM_THRESHOLD, threshold)
    return maxi(threshold, 1)


func _show_large_delete_popup(deletable_count: int, on_confirm: Callable) -> bool:
    var core = Engine.get_meta("TajsCore", null)
    if core == null or core.ui_manager == null:
        return false
    if not core.ui_manager.has_method("show_checkbox_confirmation"):
        return false

    var threshold := _get_delete_confirm_threshold()
    core.ui_manager.show_checkbox_confirmation(
        "Large Deletion Warning",
        "You are deleting %d selected windows. This action is protected." % deletable_count,
        "I understand and want to delete this selection.",
        on_confirm,
        Callable(),
        "Delete Selection",
        "Cancel",
        "Protection threshold: %d+ selected windows. Tip: use Undo afterward if needed." % threshold
    )
    return true


func delete() -> void:
    # Wrap multi-window deletion in a transaction for single undo
    var undo_manager = _get_undo_manager()
    var deletable_count := 0
    for window in Globals.selections:
        if window.can_delete and not window.closing:
            deletable_count += 1

    var use_transaction := deletable_count > 1 and undo_manager != null
    if use_transaction:
        undo_manager.begin_action("Delete %d Windows" % deletable_count)

    super.delete()

    if use_transaction:
        undo_manager.commit_action()


func _get_undo_manager():
    var core = Engine.get_meta("TajsCore", null)
    if core != null and "undo_manager" in core:
        return core.undo_manager
    return null
