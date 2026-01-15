extends Node

const LOG_NAME := "TajemnikTV-QoL:WireDrop"

const WireDropHandlerScript = preload("res://mods-unpacked/TajemnikTV-QoL/extensions/scripts/features/wire_drop/wire_drop_handler.gd")
const WireDropConnectorScript = preload("res://mods-unpacked/TajemnikTV-QoL/extensions/scripts/features/wire_drop/wire_drop_connector.gd")
const NodeCompatibilityFilterScript = preload("res://mods-unpacked/TajemnikTV-Core/core/nodes/node_compatibility_filter.gd")

var _core
var _handler
var _connector
var _node_filter
var _palette_controller
var _palette_overlay
var _enabled: bool = true


func setup(core) -> void:
	_core = core
	_node_filter = NodeCompatibilityFilterScript.new(_core.logger if _core != null else null)
	call_deferred("_build_node_filter_cache")

	_handler = WireDropHandlerScript.new()
	_handler.setup(_core.settings if _core != null else null, _core.logger if _core != null else null)
	_handler.wire_dropped_on_canvas.connect(_on_wire_dropped_on_canvas)

	_connector = WireDropConnectorScript.new()
	_connector.setup(_core, _core.logger if _core != null else null)

	_register_events()


func set_enabled(enabled: bool) -> void:
	_enabled = enabled
	_apply_enabled()


func is_enabled() -> bool:
	return _enabled


func _apply_enabled() -> void:
	if _handler != null:
		_handler.set_enabled(_enabled)


func _register_events() -> void:
	if _core != null and _core.event_bus != null:
		_core.event_bus.on("command_palette.ready", Callable(self, "_on_palette_ready"), self, true)


func _on_palette_ready(payload: Dictionary) -> void:
	_palette_controller = payload.get("controller", null)
	_palette_overlay = payload.get("overlay", null)
	if _palette_overlay != null and _palette_overlay.has_signal("node_selected"):
		if not _palette_overlay.node_selected.is_connected(_on_palette_node_selected):
			_palette_overlay.node_selected.connect(_on_palette_node_selected)


func _on_wire_dropped_on_canvas(origin_info: Dictionary, drop_position: Vector2) -> void:
	if _node_filter == null:
		return
	var origin_shape: String = origin_info.get("connection_shape", "")
	var origin_color: String = origin_info.get("connection_color", "")
	var origin_is_output: bool = origin_info.get("is_output", true)

	var compatible: Array[Dictionary] = _node_filter.get_compatible_nodes(origin_shape, origin_color, origin_is_output)
	if compatible.is_empty():
		_notify("exclamation", "No compatible nodes found")
		return

	if _palette_overlay != null and _palette_overlay.has_method("show_node_picker"):
		_palette_overlay.show_node_picker(compatible, origin_info, drop_position)
		return

	_spawn_fallback(compatible, origin_info, drop_position)


func _on_palette_node_selected(window_id: String, spawn_pos: Vector2, origin_info: Dictionary) -> void:
	if _connector == null:
		return
	_connector.spawn_and_connect(window_id, spawn_pos, origin_info)


func _spawn_fallback(compatible: Array[Dictionary], origin_info: Dictionary, drop_position: Vector2) -> void:
	if compatible.is_empty():
		return
	var chosen = compatible[0]
	var window_id: String = chosen.get("id", "")
	if window_id == "":
		return
	_notify("check", "Palette not available; spawning %s" % chosen.get("name", window_id))
	_connector.spawn_and_connect(window_id, drop_position, origin_info)


func _build_node_filter_cache() -> void:
	if _node_filter != null:
		_node_filter.build_cache()


func _notify(icon: String, message: String) -> void:
	if _core != null and _core.has_method("notify"):
		_core.notify(icon, message)
	else:
		print("%s %s" % [LOG_NAME, message])
