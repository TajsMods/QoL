# ==============================================================================
# Taj's QoL - Bin Window Extension
# Adds extra input slots when enabled in settings.
# ==============================================================================
extends "res://scenes/windows/window_bin.gd"

const SETTINGS_EXTRA_INPUTS_ENABLED := "tajs_qol.extra_inputs_enabled"
const BinInputScript = preload("res://mods-unpacked/TajemnikTV-QoL/extensions/scenes/bin_input.gd")

var _extra_inputs: Array[Control] = []


func _enter_tree() -> void:
	if not _is_extra_inputs_enabled():
		super ()
		return

	# Skip extra inputs during tutorial to preserve required connections.
	if not Globals.tutorial_done:
		super ()
		return

	var original_input = get_node_or_null("PanelContainer/MainContainer/Input")
	if original_input and BinInputScript:
		original_input.set_script(BinInputScript)
		if not original_input.is_in_group("persistent_container"):
			original_input.add_to_group("persistent_container")

		var parent_container = original_input.get_parent()
		for i in range(5):
			var new_input = original_input.duplicate()
			new_input.name = "Input_" + str(i + 2)
			new_input.set_script(BinInputScript)
			if not new_input.is_in_group("persistent_container"):
				new_input.add_to_group("persistent_container")
			parent_container.add_child(new_input)
			_extra_inputs.append(new_input)

	super ()


func _ready() -> void:
	super ()
	if not _is_extra_inputs_enabled():
		return
	if not Globals.tutorial_done:
		return

	var enable_tick = func(node):
		if "containers" in self and not containers.has(node):
			containers.append(node)

		if has_method("should_tick"):
			node.set_ticking(should_tick())
		else:
			node.set_ticking(true)

	var original_input = get_node_or_null("PanelContainer/MainContainer/Input")
	if original_input:
		enable_tick.call(original_input)

	for input in _extra_inputs:
		enable_tick.call(input)


func process(delta: float) -> void:
	super.process(delta)
	for input in _extra_inputs:
		if input.has_method("pop_all"):
			input.pop_all()


func _is_extra_inputs_enabled() -> bool:
	var settings = _get_core_settings()
	if settings == null:
		return false
	return settings.get_bool(SETTINGS_EXTRA_INPUTS_ENABLED, false)


func _get_core_settings():
	var core = TajsCoreRuntime.instance()
	if core != null and core.settings != null:
		return core.settings
	if Engine.has_meta("TajsCore"):
		var meta_core = Engine.get_meta("TajsCore")
		if meta_core != null and meta_core.settings != null:
			return meta_core.settings
	return null
