# ==============================================================================
# Group Layer Feature
# Manages reparenting of group windows to a dedicated layer that renders
# below wires/connectors, fixing the visual issue where groups obscure wires.
# ==============================================================================
extends Node

const LOG_NAME := "TajemnikTV-QoL:GroupLayer"
const LAYER_ID := "qol_groups"

var _core
var _enabled: bool = true
var _layer: Control = null
var _reparented_groups: Array = []


func setup(core) -> void:
	_core = core
	if _core == null:
		return
	# Wait for desktop to be ready before setting up the layer
	if _core.event_bus != null:
		_core.event_bus.on("game.desktop_ready", Callable(self, "_on_desktop_ready"), self, true)


func set_enabled(enabled: bool) -> void:
	_enabled = enabled
	if _enabled:
		_setup_layer()
		_reparent_existing_groups()
	else:
		_restore_groups_to_windows()


func _on_desktop_ready(_payload: Dictionary) -> void:
	if _enabled:
		call_deferred("_setup_layer")
		call_deferred("_reparent_existing_groups")
		call_deferred("_connect_signals")


func _setup_layer() -> void:
	if _core == null or _core.desktop_layers == null:
		_log_warn("desktop_layers not available")
		return
	
	if _layer != null:
		return
	
	# Register a layer BEFORE_CONNECTORS so groups render below wires
	# LayerPosition.BEFORE_CONNECTORS = 1 (after Lines, before Connectors)
	_layer = _core.desktop_layers.register_layer(LAYER_ID, 1, "TajemnikTV-QoL")
	
	if _layer != null:
		_log_info("Groups layer registered successfully")
	else:
		_log_warn("Failed to register groups layer")


func _connect_signals() -> void:
	# Hook into window creation to catch new group windows
	if get_tree() != null:
		if not get_tree().node_added.is_connected(_on_node_added):
			get_tree().node_added.connect(_on_node_added)


func _on_node_added(node: Node) -> void:
	if not _enabled:
		return
	if _layer == null:
		return
	# Check if this is a group window being added
	if _is_group_window(node):
		# Defer reparenting to avoid issues during tree modification
		call_deferred("_try_reparent_group", node)


func _try_reparent_group(node: Node) -> void:
	if not is_instance_valid(node):
		return
	if not _enabled or _layer == null:
		return
	if node.get_parent() == _layer:
		return # Already in our layer
	
	_reparent_group_to_layer(node)


func _reparent_existing_groups() -> void:
	if _layer == null:
		return
	if Globals == null or not is_instance_valid(Globals.desktop):
		return
	
	var windows_container = Globals.desktop.get_node_or_null("Windows")
	if windows_container == null:
		return
	
	var groups_to_reparent: Array = []
	for child in windows_container.get_children():
		if _is_group_window(child):
			groups_to_reparent.append(child)
	
	for group in groups_to_reparent:
		_reparent_group_to_layer(group)
	
	if groups_to_reparent.size() > 0:
		_log_info("Reparented %d existing groups to layer" % groups_to_reparent.size())


func _reparent_group_to_layer(group: Node) -> void:
	if not is_instance_valid(group) or _layer == null:
		return
	if group.get_parent() == _layer:
		return
	
	var old_parent = group.get_parent()
	if old_parent != null:
		old_parent.remove_child(group)
	_layer.add_child(group)
	
	if not _reparented_groups.has(group):
		_reparented_groups.append(group)


func _restore_groups_to_windows() -> void:
	if Globals == null or not is_instance_valid(Globals.desktop):
		return
	
	var windows_container = Globals.desktop.get_node_or_null("Windows")
	if windows_container == null:
		return
	
	for group in _reparented_groups:
		if is_instance_valid(group) and group.get_parent() != windows_container:
			var old_parent = group.get_parent()
			if old_parent != null:
				old_parent.remove_child(group)
			windows_container.add_child(group)
	
	_reparented_groups.clear()


func _is_group_window(node: Node) -> bool:
	# Check if this is a group window by checking its window type
	if node.has_method("get") and node.get("window") == "group":
		return true
	# Also check script path as fallback
	var script = node.get_script()
	if script != null:
		var path: String = script.resource_path
		if "window_group" in path:
			return true
	return false


func _log_info(message: String) -> void:
	if _core != null and _core.logger != null:
		_core.logger.info(LOG_NAME, message)


func _log_warn(message: String) -> void:
	if _core != null and _core.logger != null:
		_core.logger.warn(LOG_NAME, message)
	else:
		push_warning("%s: %s" % [LOG_NAME, message])
