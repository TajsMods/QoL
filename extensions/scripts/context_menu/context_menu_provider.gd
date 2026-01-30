# ==============================================================================
# Taj's QoL - Context Menu Provider
# Author: TajemnikTV
# Description: Default context actions for canvas, nodes, groups, and sticky notes.
# ==============================================================================
extends RefCounted

const LOG_NAME := "TajemnikTV-QoL:ContextMenuProvider"

const TYPE_CANVAS := "canvas"
const TYPE_NODE := "node"
const TYPE_GROUP := "group_node"
const TYPE_STICKY_NOTE := "sticky_note"
const TYPE_SELECTION := "selection"

const StickyNoteChangedCommandScript = preload("res://mods-unpacked/TajemnikTV-QoL/extensions/scripts/sticky_notes/commands/sticky_note_changed_command.gd")

var _core = null
var _sticky_note_manager = null


func setup(core, sticky_note_manager) -> void:
    _core = core
    _sticky_note_manager = sticky_note_manager


func get_id() -> String:
    return "tajs_qol.context_menu"


func get_actions(context: Dictionary) -> Array:
    var actions: Array = []
    var ctx_type := str(context.get("type", ""))
    match ctx_type:
        TYPE_CANVAS:
            actions.append_array(_get_canvas_actions(context))
        TYPE_NODE:
            actions.append_array(_get_node_actions(context))
        TYPE_GROUP:
            actions.append_array(_get_group_actions(context))
        TYPE_STICKY_NOTE:
            actions.append_array(_get_note_actions(context))
        TYPE_SELECTION:
            actions.append_array(_get_node_actions(context))
    return actions


func _get_canvas_actions(_context: Dictionary) -> Array:
    return [
        {
            "id": "tajs_qol.context.add_node",
            "title": "Add Node (WIP)",
            "icon_path": "res://textures/icons/add.png",
            "order": 0,
            "run": Callable(self, "_run_add_node")
        },
        {
            "id": "tajs_qol.context.add_sticky_note",
            "title": "Add Sticky Note",
            "icon_path": "res://textures/icons/document.png",
            "order": 1,
            "run": Callable(self, "_run_add_note")
        }
    ]


func _get_node_actions(context: Dictionary) -> Array:
    var targets := _get_target_windows(context)
    var multi := targets.size() > 1
    var delete_title := "Delete Selected" if multi else "Delete Node"
    var clear_title := "Clear Wires" if multi else "Clear All Wires"
    var upgrade_title := "Upgrade Selected" if multi else "Upgrade"
    var confirm_delete := _needs_delete_confirm(targets)

    return [
        {
            "id": "tajs_qol.context.delete_nodes",
            "title": delete_title,
            "icon_path": "res://textures/icons/trash_bin.png",
            "priority": 20,
            "confirm": {
                "prompt_id": "prompt_delete_node",
                "prompt_desc": "prompt_delete_node_desc"
            } if confirm_delete else {},
            "run": Callable(self, "_run_delete_nodes")
        },
        {
            "id": "tajs_qol.context.clear_wires",
            "title": clear_title,
            "icon_path": "res://textures/icons/connections.png",
            "priority": 10,
            "run": Callable(self, "_run_clear_wires")
        },
        {
            "id": "tajs_qol.context.upgrade_nodes",
            "title": upgrade_title,
            "icon_path": "res://textures/icons/up_arrow.png",
            "priority": 5,
            "is_visible": Callable(self, "_is_upgrade_visible"),
            "is_enabled": Callable(self, "_is_upgrade_enabled"),
            "run": Callable(self, "_run_upgrade_nodes")
        }
    ]


func _get_group_actions(_context: Dictionary) -> Array:
    return [
        {
            "id": "tajs_qol.context.group_remove_all",
            "title": "Remove Group + Nodes",
            "icon_path": "res://textures/icons/trash_bin.png",
            "priority": 20,
            "confirm": {
                "prompt_title": "Delete Group",
                "prompt_message": "Delete group and enclosed nodes? This action cannot be undone."
            },
            "run": Callable(self, "_run_group_remove_all")
        },
        {
            "id": "tajs_qol.context.group_remove_group",
            "title": "Remove Group Only",
            "icon_path": "res://textures/icons/trash_bin.png",
            "priority": 15,
            "confirm": {
                "prompt_title": "Delete Group",
                "prompt_message": "Delete this group? This action cannot be undone."
            },
            "run": Callable(self, "_run_group_remove_group")
        },
        {
            "id": "tajs_qol.context.group_remove_nodes",
            "title": "Remove Nodes Inside",
            "icon_path": "res://textures/icons/trash_bin.png",
            "priority": 14,
            "confirm": {
                "prompt_title": "Delete Nodes",
                "prompt_message": "Delete nodes inside this group? This action cannot be undone."
            },
            "run": Callable(self, "_run_group_remove_nodes")
        },
        {
            "id": "tajs_qol.context.group_customize_pattern",
            "title": "Change Pattern",
            "icon_path": "res://textures/icons/grid.png",
            "category_path": ["Customize"],
            "priority": 5,
            "is_visible": Callable(self, "_is_group_pattern_visible"),
            "is_enabled": Callable(self, "_is_group_pattern_enabled"),
            "run": Callable(self, "_run_group_pattern")
        },
        {
            "id": "tajs_qol.context.group_customize_title",
            "title": "Change Title and Icon",
            "icon_path": "res://textures/icons/pen.png",
            "category_path": ["Customize"],
            "priority": 4,
            "run": Callable(self, "_run_group_title")
        }
    ]


func _get_note_actions(_context: Dictionary) -> Array:
    return [
        {
            "id": "tajs_qol.context.note_duplicate",
            "title": "Duplicate Sticky Note",
            "icon_path": "res://textures/icons/plus.png",
            "priority": 10,
            "run": Callable(self, "_run_note_duplicate")
        },
        {
            "id": "tajs_qol.context.note_customize_pattern",
            "title": "Customize Pattern",
            "icon_path": "res://textures/icons/grid.png",
            "category_path": ["Customize"],
            "priority": 5,
            "run": Callable(self, "_run_note_pattern")
        },
        {
            "id": "tajs_qol.context.note_customize_title",
            "title": "Customize Title and Icon",
            "icon_path": "res://textures/icons/pen.png",
            "category_path": ["Customize"],
            "priority": 4,
            "run": Callable(self, "_run_note_title")
        },
        {
            "id": "tajs_qol.context.note_delete",
            "title": "Delete Sticky Note",
            "icon_path": "res://textures/icons/trash_bin.png",
            "priority": 3,
            "confirm": {
                "prompt_title": "Delete Note",
                "prompt_message": "Delete this sticky note? This action cannot be undone."
            },
            "run": Callable(self, "_run_note_delete")
        },
        {
            "id": "tajs_qol.context.note_clear",
            "title": "Clear Sticky Note",
            "icon_path": "res://textures/icons/document.png",
            "priority": 2,
            "confirm": {
                "prompt_title": "Clear Note",
                "prompt_message": "Clear the note content? This action cannot be undone."
            },
            "run": Callable(self, "_run_note_clear")
        }
    ]


func _run_add_node(_context: Dictionary) -> void:
    if _core == null:
        return
    var controller = _core.command_palette_controller
    var overlay = _core.command_palette_overlay
    if controller != null and overlay != null and overlay.has_method("enter_node_browser"):
        if controller.has_method("open"):
            controller.open()
        overlay.enter_node_browser()
        return
    _notify("exclamation", "Command Palette not available. Add Node is disabled.")


func _run_add_note(context: Dictionary) -> void:
    if _sticky_note_manager == null:
        return
    var pos: Vector2 = context.get("position", Vector2.ZERO)
    if pos == Vector2.ZERO:
        _sticky_note_manager.create_note_at_camera_center()
    else:
        _sticky_note_manager.create_note(pos)


func _run_delete_nodes(context: Dictionary) -> void:
    var targets := _get_target_windows(context)
    if targets.is_empty():
        _notify("exclamation", "No nodes to delete")
        return
    _delete_windows(targets)


func _run_clear_wires(context: Dictionary) -> void:
    var targets := _get_target_windows(context)
    if targets.is_empty():
        _notify("exclamation", "No nodes selected")
        return
    var result = _clear_wires_for_windows(targets)
    if result.cleared > 0:
        _play_sound("close")
        _notify("check", "Cleared %d connections from %d nodes" % [result.cleared, result.nodes])
    else:
        _notify("exclamation", "No connections to clear")


func _run_upgrade_nodes(context: Dictionary) -> void:
    var targets := _get_target_windows(context)
    if targets.is_empty():
        _notify("exclamation", "No upgradeable nodes")
        return
    _upgrade_nodes(targets)


func _run_group_remove_all(context: Dictionary) -> void:
    var group = context.get("window", null)
    if not is_instance_valid(group):
        return
    var nodes := _get_group_nodes(group)
    nodes.append(group)
    _delete_windows(nodes)


func _run_group_remove_group(context: Dictionary) -> void:
    var group = context.get("window", null)
    if not is_instance_valid(group):
        return
    _delete_windows([group])


func _run_group_remove_nodes(context: Dictionary) -> void:
    var group = context.get("window", null)
    if not is_instance_valid(group):
        return
    var nodes := _get_group_nodes(group)
    _delete_windows(nodes)


func _run_group_pattern(context: Dictionary) -> void:
    var group = context.get("window", null)
    if not is_instance_valid(group):
        return
    if group.has_method("_open_pattern_picker"):
        group._open_pattern_picker()


func _run_group_title(context: Dictionary) -> void:
    var group = context.get("window", null)
    if not is_instance_valid(group):
        return
    if Signals != null and Signals.has_signal("edit_group"):
        Signals.edit_group.emit(group)


func _run_note_duplicate(context: Dictionary) -> void:
    var note = context.get("note", null)
    if not is_instance_valid(note):
        return
    if note.has_method("_on_duplicate_pressed"):
        note._on_duplicate_pressed()
    elif _sticky_note_manager != null and note.has_method("get"):
        _sticky_note_manager.duplicate_note(note.get("note_id"), note.position + Vector2(30, 30))


func _run_note_pattern(context: Dictionary) -> void:
    var note = context.get("note", null)
    if not is_instance_valid(note):
        return
    if note.has_method("_open_pattern_picker"):
        note._open_pattern_picker()


func _run_note_title(context: Dictionary) -> void:
    var note = context.get("note", null)
    if not is_instance_valid(note):
        return
    if note.has_method("_open_edit_popup"):
        note._open_edit_popup()


func _run_note_delete(context: Dictionary) -> void:
    var note = context.get("note", null)
    if not is_instance_valid(note):
        return
    if note.has_method("_on_delete_pressed"):
        note._on_delete_pressed()
    elif _sticky_note_manager != null and note.has_method("get"):
        _sticky_note_manager.delete_note(note.get("note_id"))


func _run_note_clear(context: Dictionary) -> void:
    var note = context.get("note", null)
    if not is_instance_valid(note):
        return
    var before: Dictionary = note.get_data() if note.has_method("get_data") else {}
    if note.has_method("set_body"):
        note.set_body("")
        if note.has_method("_emit_changed"):
            note._emit_changed()
    if _sticky_note_manager != null and _sticky_note_manager.has_method("save_notes"):
        _sticky_note_manager.save_notes()
    var undo = _get_undo_manager()
    if undo != null and before is Dictionary and not before.is_empty():
        var after: Dictionary = note.get_data() if note.has_method("get_data") else {}
        var cmd = StickyNoteChangedCommandScript.new()
        cmd.setup(_sticky_note_manager, str(before.get("id", "")), before, after)
        undo.push_command(cmd)


func _is_upgrade_visible(context: Dictionary) -> bool:
    var targets := _get_target_windows(context)
    for window in targets:
        if is_instance_valid(window) and window.has_method("upgrade"):
            return true
    return false


func _is_upgrade_enabled(context: Dictionary) -> bool:
    var targets := _get_target_windows(context)
    var money := _get_money()
    for window in targets:
        if not is_instance_valid(window):
            continue
        if not window.has_method("upgrade"):
            continue
        if window.has_method("can_upgrade"):
            if window.can_upgrade():
                return true
            continue
        var cost = window.get("cost")
        if cost == null:
            return true
        if cost <= money:
            return true
    return false


func _is_group_pattern_visible(context: Dictionary) -> bool:
    var group = context.get("window", null)
    if not is_instance_valid(group):
        return false
    return group.has_method("_open_pattern_picker")


func _is_group_pattern_enabled(context: Dictionary) -> bool:
    var group = context.get("window", null)
    if not is_instance_valid(group):
        return false
    var enabled = group.get("_patterns_enabled")
    if enabled == null:
        return true
    return bool(enabled)


func _get_target_windows(context: Dictionary) -> Array:
    var selection: Array = context.get("selection", [])
    var target = context.get("window", null)
    if target != null and selection.size() > 1 and selection.has(target):
        return selection
    if target != null:
        return [target]
    if selection.size() > 0:
        return selection
    return []


func _get_group_nodes(group: WindowContainer) -> Array:
    var nodes: Array = []
    if group == null:
        return nodes
    var rect: Rect2 = group.get_global_rect()
    var tree = Engine.get_main_loop()
    if not (tree is SceneTree):
        return nodes
    for node in tree.get_nodes_in_group("selectable"):
        if node == group:
            continue
        if not (node is WindowContainer):
            continue
        if rect.encloses(node.get_global_rect()):
            nodes.append(node)
    return nodes


func _delete_windows(windows: Array) -> void:
    if windows.is_empty():
        return
    
    # Wrap multi-window deletion in a transaction for single undo
    var undo_manager = _get_undo_manager()
    var use_transaction := windows.size() > 1 and undo_manager != null
    if use_transaction:
        undo_manager.begin_action("Delete %d Windows" % windows.size())
    
    for window in windows:
        if not is_instance_valid(window):
            continue
        if window.has_method("get") and window.get("can_delete") == false:
            continue
        if window.has_method("get") and window.get("closing"):
            continue
        window.propagate_call("close")
    
    if use_transaction:
        undo_manager.commit_action()
    
    if Globals != null:
        Globals.set_selection([], [], 0)
    _play_sound("close")


func _upgrade_nodes(windows: Array) -> void:
    var upgraded_count := 0
    var skipped_count := 0
    var money := _get_money()
    for window in windows:
        if window == null:
            continue
        if not window.has_method("upgrade"):
            continue
        if window.has_method("can_upgrade"):
            if not window.can_upgrade():
                skipped_count += 1
                continue
            if window.has_method("_on_upgrade_button_pressed"):
                window._on_upgrade_button_pressed()
                upgraded_count += 1
                continue
        var cost = window.get("cost")
        if cost != null and cost > 0:
            if cost > money:
                skipped_count += 1
                continue
            money -= cost
            if Globals != null and "currencies" in Globals:
                Globals.currencies["money"] = money
        var arg_count = _get_method_arg_count(window, "upgrade")
        if arg_count == 0:
            window.upgrade()
        else:
            window.upgrade(1)
        upgraded_count += 1

    if upgraded_count > 0:
        _play_sound("upgrade")
        var msg = "Upgraded " + str(upgraded_count) + " nodes"
        if skipped_count > 0:
            msg += " (" + str(skipped_count) + " skipped)"
        _notify("check", msg)
    else:
        _play_sound("error")
        if skipped_count > 0:
            _notify("exclamation", "Can't afford any upgrades (" + str(skipped_count) + " nodes)")
        else:
            _notify("exclamation", "No upgradeable nodes")


func _get_method_arg_count(obj: Object, method_name: String) -> int:
    var script = obj.get_script()
    if script:
        for method in script.get_script_method_list():
            if method.name == method_name:
                return method.args.size()
    return 1


func _clear_wires_for_windows(windows: Array) -> Dictionary:
    var cleared := 0
    var nodes_with_wires := 0
    for window in windows:
        if not is_instance_valid(window):
            continue
        var containers := _find_resource_containers_in_window(window)
        var had_wires := false
        for rc: ResourceContainer in containers:
            if not is_instance_valid(rc):
                continue
            var outputs: Array[String] = rc.outputs_id.duplicate()
            for output_id in outputs:
                Signals.delete_connection.emit(rc.id, output_id)
                cleared += 1
                had_wires = true
            if not rc.input_id.is_empty():
                Signals.delete_connection.emit(rc.input_id, rc.id)
                cleared += 1
                had_wires = true
        if had_wires:
            nodes_with_wires += 1
    return {"cleared": cleared, "nodes": nodes_with_wires}


func _find_resource_containers_in_window(node: Node) -> Array[ResourceContainer]:
    var containers: Array[ResourceContainer] = []
    _collect_resource_containers(node, containers)
    return containers


func _collect_resource_containers(node: Node, containers: Array[ResourceContainer]) -> void:
    if node is ResourceContainer:
        containers.append(node as ResourceContainer)
    for child in node.get_children():
        _collect_resource_containers(child, containers)


func _notify(icon: String, message: String) -> void:
    if _core != null and _core.has_method("notify"):
        _core.notify(icon, message)
        return
    if Signals != null and Signals.has_signal("notify"):
        Signals.notify.emit(icon, message)


func _play_sound(sound_id: String) -> void:
    if _core != null and _core.has_method("play_sound"):
        _core.play_sound(sound_id)
        return
    if Sound != null and Sound.has_method("play"):
        Sound.play(sound_id)


func _get_undo_manager():
    if _sticky_note_manager != null and _sticky_note_manager.has_method("_get_undo_manager"):
        return _sticky_note_manager._get_undo_manager()
    if _core != null and "undo_manager" in _core:
        return _core.undo_manager
    return null


func _get_money() -> float:
    if Globals != null and "currencies" in Globals:
        return float(Globals.currencies.get("money", 0))
    return 0.0


func _needs_delete_confirm(windows: Array) -> bool:
    for window in windows:
        if not is_instance_valid(window):
            continue
        if window.has_method("get") and window.get("importing"):
            continue
        if window.has_method("get") and window.get("warn_deletion"):
            return true
    return false


func _log_debug(message: String) -> void:
    if _core != null and _core.logger != null:
        _core.logger.info(LOG_NAME, message)
    else:
        print("[%s] %s" % [LOG_NAME, message])
