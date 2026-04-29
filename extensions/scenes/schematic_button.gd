extends "res://scenes/schematic_button.gd"

const DEFAULT_ICON_PATH := "res://textures/icons/blueprint.png"
const IconResolverScript = preload("res://mods-unpacked/TajemnikTV-QoL/extensions/scripts/schematic_library/icon_resolver.gd")


func _ready() -> void:
    Signals.deleted_schematic.connect(_on_delete_schematic)
    $Name.text = schematic
    _update_icon()


func _update_icon() -> void:
    var icon_id := ""
    if Data.schematics.has(schematic):
        icon_id = str(Data.schematics[schematic].icon)
    if icon_id == "":
        $Icon.texture = load(DEFAULT_ICON_PATH)
        return
    var tex := IconResolverScript.resolve_icon_texture(icon_id)
    if tex != null:
        $Icon.texture = tex
        return
    $Icon.texture = load(DEFAULT_ICON_PATH)
