extends "res://scenes/schematic_container.gd"

const DEFAULT_ICON_PATH := "res://textures/icons/blueprint.png"


func _ready() -> void:
    super._ready()
    _update_icon()


func _update_icon() -> void:
    var icon_id := ""
    if Data.schematics.has(schematic):
        icon_id = str(Data.schematics[schematic].icon)
    if icon_id == "":
        $SchematicButton/Icon.texture = load(DEFAULT_ICON_PATH)
        return
    var tex := _resolve_icon_texture(icon_id)
    if tex != null:
        $SchematicButton/Icon.texture = tex
        return
    $SchematicButton/Icon.texture = load(DEFAULT_ICON_PATH)


func _normalize_icon_id(icon_value: String) -> String:
    if icon_value == "":
        return "base:blueprint.png"
    # Already a full res:// path
    if icon_value.begins_with("res://"):
        return icon_value
    # Already in source:path format
    if icon_value.find(":") != -1:
        return icon_value
    # Old vanilla-style icon name without extension (e.g., "blueprint")
    return "base:%s.png" % icon_value


func _resolve_icon_texture(icon_id: String) -> Texture2D:
    # Normalize legacy icon IDs before resolving
    icon_id = _normalize_icon_id(icon_id)
    
    var core = Engine.get_meta("TajsCore", null)
    if core != null:
        var registry = core.get_icon_registry()
        if registry != null:
            var resolved: Dictionary = registry.resolve_icon(icon_id)
            if resolved.get("texture", null) != null:
                return resolved.texture
    if icon_id.begins_with("res://") and ResourceLoader.exists(icon_id):
        return load(icon_id)
    if icon_id.find(":") != -1:
        var parts := icon_id.split(":", false, 1)
        if parts.size() == 2 and parts[1] != "":
            var mapped_path := "res://textures/icons".path_join(parts[1])
            if ResourceLoader.exists(mapped_path):
                return load(mapped_path)
    var icon_path := "res://textures/icons/" + icon_id + ".png"
    if ResourceLoader.exists(icon_path):
        return load(icon_path)
    return null
