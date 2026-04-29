extends RefCounted

const DEFAULT_ICON_ID := "base:blueprint.png"


static func normalize_icon_id(icon_value: String) -> String:
    if icon_value == "":
        return DEFAULT_ICON_ID
    if icon_value.begins_with("res://"):
        return icon_value
    if icon_value.find(":") != -1:
        return icon_value
    return "base:%s.png" % icon_value


static func resolve_icon_texture(icon_value: String) -> Texture2D:
    var icon_id := normalize_icon_id(icon_value)
    if icon_id == "":
        return null

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
            var source := str(parts[0]).to_lower()
            var source_mapped_path := ""
            if source == "tajemniktv-core":
                source_mapped_path = "res://mods-unpacked/TajemnikTV-Core/textures/icons".path_join(parts[1])
            elif source == "tajemniktv-qol":
                source_mapped_path = "res://mods-unpacked/TajemnikTV-QoL/textures/icons".path_join(parts[1])
            elif source == "tajemniktv-cheats":
                source_mapped_path = "res://mods-unpacked/TajemnikTV-Cheats/textures/icons".path_join(parts[1])
            elif source == "tajemniktv-commandpalette":
                source_mapped_path = "res://mods-unpacked/TajemnikTV-CommandPalette/textures/icons".path_join(parts[1])
            if source_mapped_path != "" and ResourceLoader.exists(source_mapped_path):
                return load(source_mapped_path)
        return null

    var icon_path := "res://textures/icons/%s.png" % icon_id
    if ResourceLoader.exists(icon_path):
        return load(icon_path)
    return null
