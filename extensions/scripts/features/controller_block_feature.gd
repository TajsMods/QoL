extends Node

const LOG_NAME := "TajemnikTV-QoL:ControllerBlock"

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
    if event is InputEventJoypadMotion or event is InputEventJoypadButton:
        get_viewport().set_input_as_handled()
