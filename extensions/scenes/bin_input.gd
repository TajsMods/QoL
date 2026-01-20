# ==============================================================================
# Taj's QoL - Bin Input
# Universal receiver logic for extra bin inputs.
# ==============================================================================
extends "res://scenes/resource_container.gd"


func get_connection_shape() -> String:
	if not Globals.connecting.is_empty() and Globals.desktop:
		var source = Globals.desktop.get_resource(Globals.connecting)
		if source and source != self:
			return source.get_connection_shape()

	if input:
		return input.get_connection_shape()

	return super.get_connection_shape()


func get_connector_color() -> String:
	if not Globals.connecting.is_empty() and Globals.desktop:
		var source = Globals.desktop.get_resource(Globals.connecting)
		if source and source != self:
			return source.get_connector_color()

	if input:
		return input.get_connector_color()

	return super.get_connector_color()


func can_set(_to: String) -> bool:
	return true


func can_connect(_to: ResourceContainer) -> bool:
	return true


func should_tick() -> bool:
	return true
