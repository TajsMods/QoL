# ==============================================================================
# Taj's QoL - Window Inventory Extension
# Adds an optional 6th input slot when enabled in settings.
# ==============================================================================
extends "res://scenes/windows/window_inventory.gd"

const SETTINGS_EXTRA_INPUTS_ENABLED := "tajs_qol.extra_inputs_enabled"

var _sixth_input: ResourceContainer = null


func _enter_tree() -> void:
	if _is_extra_inputs_enabled():
		_add_sixth_input_early()
	super ()


func _ready() -> void:
	super ()
	if not _is_extra_inputs_enabled():
		return
	if _sixth_input:
		if "containers" in self and not containers.has(_sixth_input):
			containers.append(_sixth_input)

		_sixth_input.connection_in_set.connect(_on_connection_set)
		_sixth_input.resource_set.connect(_on_5_resource_set)

		if has_method("should_tick"):
			_sixth_input.set_ticking(should_tick())
		else:
			_sixth_input.set_ticking(true)

		var first_input = get_node_or_null("PanelContainer/MainContainer/Input/0")
		if first_input and not first_input.resource.is_empty():
			_sixth_input.call_deferred("set_resource", first_input.resource, first_input.variation)

	update_visible_inputs()


func _add_sixth_input_early() -> void:
	var input_container = get_node_or_null("PanelContainer/MainContainer/Input")
	if input_container == null:
		return

	if input_container.get_child_count() >= 6:
		return

	var input_scene = load("res://scenes/input_container.tscn")
	if input_scene == null:
		return

	var first_input: ResourceContainer = input_container.get_child(0) if input_container.get_child_count() > 0 else null

	_sixth_input = input_scene.instantiate()
	_sixth_input.name = "5"

	if first_input:
		_sixth_input.placeholder_name = first_input.placeholder_name
		_sixth_input.override_connector = first_input.override_connector
		_sixth_input.override_color = first_input.override_color
		_sixth_input.default_resource = first_input.default_resource
		_sixth_input.default_variation = first_input.default_variation
	else:
		_sixth_input.placeholder_name = "input_currency"
		_sixth_input.override_connector = "triangle"
		_sixth_input.override_color = "white"

	var output_node = get_node_or_null("PanelContainer/MainContainer/Output")
	if output_node:
		_sixth_input.exporting = [output_node]

	if not _sixth_input.is_in_group("persistent_container"):
		_sixth_input.add_to_group("persistent_container")

	input_container.add_child(_sixth_input)


func _on_5_resource_set() -> void:
	var input_5 = get_node_or_null("PanelContainer/MainContainer/Input/5")
	if input_5:
		set_resources(input_5.resource, input_5.variation)


func _is_extra_inputs_enabled() -> bool:
	var settings = _get_core_settings()
	if settings == null:
		return false
	return settings.get_bool(SETTINGS_EXTRA_INPUTS_ENABLED, false)


func _get_core_settings():
	# Access TajsCore via Engine metadata to avoid parse-time dependency
	if Engine.has_meta("TajsCore"):
		var core = Engine.get_meta("TajsCore")
		if core != null and core.settings != null:
			return core.settings
	return null
