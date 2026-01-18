# ==============================================================================
# Taj's QoL - Window Breach Extension
# Author: TajemnikTV
# Description: Notifies the breach threat manager when a breach fails.
# ==============================================================================
extends "res://scenes/windows/window_breach.gd"


func fail() -> void:
	var manager = _get_breach_threat_manager()
	if manager != null and manager.has_method("on_breach_failed"):
		manager.on_breach_failed(self)
	super ()


func _get_breach_threat_manager():
	if Engine.has_meta("TajsCore"):
		var core = Engine.get_meta("TajsCore")
		if core != null and core.has_method("get_extended_global"):
			return core.get_extended_global("breach_threat_manager")
	return null
