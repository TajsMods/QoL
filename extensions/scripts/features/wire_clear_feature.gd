extends Node

const LOG_NAME := "TajemnikTV-QoL:WireClear"

var _core
var _enabled: bool = true


func setup(core) -> void:
	_core = core
	set_process_input(false)


func set_enabled(enabled: bool) -> void:
	_enabled = enabled
	set_process_input(enabled)


func is_enabled() -> bool:
	return _enabled


func _input(event: InputEvent) -> void:
	if not _enabled:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		var connector := _get_hovered_connector()
		if connector:
			_clear_connector_wires(connector)
			get_viewport().set_input_as_handled()


func _get_hovered_connector() -> ConnectorButton:
	if not is_instance_valid(Globals.desktop):
		return null
	var windows_container = Globals.desktop.get_node_or_null("Windows")
	if windows_container == null:
		return null
	var mouse_pos := Globals.desktop.get_global_mouse_position()
	for window in windows_container.get_children():
		if not window is WindowContainer:
			continue
		if not is_instance_valid(window):
			continue
		var connector := _find_connector_at_position(window, mouse_pos)
		if connector:
			return connector
	return null


func _find_connector_at_position(node: Node, mouse_pos: Vector2) -> ConnectorButton:
	if node is ConnectorButton:
		var rect: Rect2 = node.get_global_rect()
		if rect.has_point(mouse_pos):
			return node
	for child in node.get_children():
		var result := _find_connector_at_position(child, mouse_pos)
		if result:
			return result
	return null


func _clear_connector_wires(connector: ConnectorButton) -> void:
	var container: ResourceContainer = connector.container
	if not is_instance_valid(container):
		return
	var had_connections := false
	if connector.type == Utils.connections_types.OUTPUT:
		if container.outputs_id.size() > 0:
			had_connections = true
			var outputs: Array[String] = container.outputs_id.duplicate()
			for output_id: String in outputs:
				Signals.delete_connection.emit(container.id, output_id)
	elif connector.type == Utils.connections_types.INPUT:
		if not container.input_id.is_empty():
			had_connections = true
			Signals.delete_connection.emit(container.input_id, container.id)
	if had_connections:
		if _core != null and _core.has_method("play_sound"):
			_core.play_sound("close")
		elif is_instance_valid(Sound):
			Sound.play("close")
