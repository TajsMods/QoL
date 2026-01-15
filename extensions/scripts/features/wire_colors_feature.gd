extends RefCounted

const LOG_NAME := "TajemnikTV-QoL:WireColors"

const CONFIGURABLE_WIRES := {
    "download_speed": "Download Speed",
    "upload_speed": "Upload Speed",
    "clock_speed": "Clock Speed",
    "gpu_speed": "GPU Speed",
    "code_speed": "Code Speed",
    "work_speed": "Work Speed",
    "money": "Money",
    "research": "Research",
    "token": "Token",
    "power": "Power",
    "research_power": "Research Power",
    "contribution": "Contribution",
    "hack_power": "Hack Power",
    "hack_experience": "Hack Experience",
    "virus": "Virus",
    "trojan": "Trojan",
    "infected_computer": "Infected Computer",
    "bool": "Bool",
    "char": "Char",
    "int": "Int",
    "float": "Float",
    "bitflag": "Bitflag",
    "bigint": "BigInt",
    "decimal": "Decimal",
    "string": "String",
    "vector": "Vector",
    "ai": "AI",
    "neuron_text": "Neuron (Text)",
    "neuron_image": "Neuron (Image)",
    "neuron_sound": "Neuron (Sound)",
    "neuron_video": "Neuron (Video)",
    "neuron_program": "Neuron (Program)",
    "neuron_game": "Neuron (Game)",
    "boost_component": "Boost Component",
    "boost_research": "Boost Research",
    "boost_hack": "Boost Hack",
    "boost_code": "Boost Code",
    "overclock": "Overclock",
    "heat": "Heat",
    "vulnerability": "Vulnerability",
    "storage": "Storage",
    "corporation_data": "Corporation Data",
    "government_data": "Government Data",
    "litecoin": "Litecoin",
    "bitcoin": "Bitcoin",
    "ethereum": "Ethereum"
}

var _core
var _enabled: bool = true
var _custom_hex: Dictionary = {}
var _original_colors: Dictionary = {}
var _tree: SceneTree = null


func setup(core) -> void:
    _core = core
    _capture_original_colors()


func set_tree(tree: SceneTree) -> void:
    _tree = tree


func set_enabled(enabled: bool) -> void:
    _enabled = enabled
    if _enabled:
        apply_overrides()
    else:
        revert_overrides()
    _refresh_connectors()


func is_enabled() -> bool:
    return _enabled


func set_custom_hex(custom_hex: Dictionary) -> void:
    _custom_hex = custom_hex.duplicate(true)
    _rebuild_custom_connectors()
    if _enabled:
        apply_overrides()
    else:
        revert_overrides()
    _refresh_connectors()


func get_custom_hex() -> Dictionary:
    return _custom_hex.duplicate(true)


func refresh_original_colors() -> void:
    _capture_original_colors()
    if _enabled:
        apply_overrides()
    else:
        revert_overrides()
    _refresh_connectors()


func set_color(resource_id: String, color: Color) -> void:
    var hex = color.to_html(false)
    _custom_hex[resource_id] = hex
    _ensure_custom_connector(resource_id, hex)
    if _enabled and Data != null and Data.resources != null and Data.resources.has(resource_id):
        Data.resources[resource_id].color = "custom_" + resource_id
    _refresh_connectors()


func reset_color(resource_id: String) -> void:
    if _custom_hex.has(resource_id):
        _custom_hex.erase(resource_id)
    if _original_colors.has(resource_id) and Data != null and Data.resources != null and Data.resources.has(resource_id):
        Data.resources[resource_id].color = _original_colors[resource_id]
    _refresh_connectors()


func reset_all() -> void:
    _custom_hex.clear()
    revert_overrides()
    _refresh_connectors()


func apply_overrides() -> void:
    if Data == null or Data.resources == null:
        return
    for resource_id in _custom_hex:
        var color_key = "custom_" + resource_id
        if Data.resources.has(resource_id):
            Data.resources[resource_id].color = color_key


func revert_overrides() -> void:
    if Data == null or Data.resources == null:
        return
    for resource_id in _original_colors:
        if Data.resources.has(resource_id):
            Data.resources[resource_id].color = _original_colors[resource_id]


func get_color(resource_id: String) -> Color:
    if _custom_hex.has(resource_id):
        return Color(_custom_hex[resource_id])
    if Data != null and Data.resources != null and Data.resources.has(resource_id):
        var color_name = Data.resources[resource_id].color
        if Data.connectors != null and Data.connectors.has(color_name):
            return Color(Data.connectors[color_name].color)
    return Color.WHITE


func get_original_color(resource_id: String) -> Color:
    if _original_colors.has(resource_id):
        var color_name = _original_colors[resource_id]
        if Data != null and Data.connectors != null and Data.connectors.has(color_name):
            return Color(Data.connectors[color_name].color)
    return Color.WHITE


func get_configurable_wires() -> Dictionary:
    return CONFIGURABLE_WIRES


func _capture_original_colors() -> void:
    _original_colors.clear()
    if Data == null or Data.resources == null:
        return
    for resource_id in CONFIGURABLE_WIRES:
        if Data.resources.has(resource_id):
            _original_colors[resource_id] = Data.resources[resource_id].color


func _ensure_custom_connector(resource_id: String, hex_color: String) -> void:
    if Data == null or Data.connectors == null:
        return
    var color_key = "custom_" + resource_id
    Data.connectors[color_key] = {
        "letter": resource_id.substr(0, 1).to_upper(),
        "color": hex_color
    }


func _rebuild_custom_connectors() -> void:
    if Data == null or Data.connectors == null:
        return
    for resource_id in _custom_hex:
        _ensure_custom_connector(resource_id, _custom_hex[resource_id])


func _refresh_connectors() -> void:
    if _tree == null:
        return
    if Data == null or Data.connectors == null:
        return
    var connectors = _tree.get_nodes_in_group("connector")
    for connector in connectors:
        if connector is Connector:
            var output_res = connector.output
            if output_res and output_res is ResourceContainer:
                var resource_id: String = output_res.resource
                if resource_id.is_empty():
                    continue
                var target_color: Color = Color.WHITE
                if _enabled and _custom_hex.has(resource_id):
                    # Use custom color
                    target_color = Color(_custom_hex[resource_id])
                else:
                    # Use original color from Data.connectors
                    var original_color_name = _original_colors.get(resource_id, "")
                    if original_color_name.is_empty() and Data.resources != null and Data.resources.has(resource_id):
                        original_color_name = Data.resources[resource_id].color
                    if not original_color_name.is_empty() and Data.connectors.has(original_color_name):
                        target_color = Color(Data.connectors[original_color_name].color)
                connector.color = target_color
                if connector.pivot:
                    connector.pivot.self_modulate = target_color
                connector.draw_update()
    
    var windows = _tree.get_nodes_in_group("window")
    for window in windows:
        var buttons = _find_connector_buttons(window)
        for btn in buttons:
            if btn.has_method("update_connector_button"):
                btn.update_connector_button()


func _find_connector_buttons(node: Node) -> Array:
    var result: Array = []
    if node.has_method("update_connector_button"):
        result.append(node)
    for child in node.get_children():
        result.append_array(_find_connector_buttons(child))
    return result
