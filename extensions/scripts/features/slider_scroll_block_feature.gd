extends Node

const LOG_NAME := "TajemnikTV-QoL:SliderScrollBlock"

var _enabled: bool = false


func setup() -> void:
	set_process_input(false)


func set_enabled(enabled: bool) -> void:
	_enabled = enabled
	set_process_input(enabled)


func is_enabled() -> bool:
	return _enabled


func _input(event: InputEvent) -> void:
	if not _enabled:
		return
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP or event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			var hovered = _get_hovered_slider()
			if hovered:
				get_viewport().set_input_as_handled()


func _get_hovered_slider() -> Control:
	var mouse_pos := get_viewport().get_mouse_position()
	var root := get_tree().root
	return _find_slider_at_point(root, mouse_pos)


func _find_slider_at_point(node: Node, point: Vector2) -> Control:
	for i in range(node.get_child_count() - 1, -1, -1):
		var child = node.get_child(i)
		var result := _find_slider_at_point(child, point)
		if result:
			return result

	if node is HSlider or node is VSlider:
		var slider := node as Control
		if slider.visible and slider.get_global_rect().has_point(point):
			if _is_control_visible_in_tree(slider):
				return slider

	return null


func _is_control_visible_in_tree(control: Control) -> bool:
	var current: Control = control
	while current:
		if not current.visible:
			return false
		current = current.get_parent() as Control
	return true
