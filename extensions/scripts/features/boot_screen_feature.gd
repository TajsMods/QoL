extends RefCounted

const LOG_NAME := "TajemnikTV-QoL:BootScreen"

var _core
var _enabled: bool = false
var _patched: bool = false
var _mod_version: String = "0.0.0"
var _icon_path: String = "res://textures/icons/puzzle.png"


func setup(core, mod_version: String) -> void:
	_core = core
	_mod_version = mod_version


func set_enabled(enabled: bool) -> void:
	_enabled = enabled


func is_enabled() -> bool:
	return _enabled


func try_patch() -> void:
	if not _enabled or _patched:
		return
	var tree = Engine.get_main_loop()
	if tree == null:
		return
	var boot = tree.root.get_node_or_null("Boot")
	if boot == null:
		return
	_patch_boot_screen(boot)
	_patched = true


func _patch_boot_screen(boot_node: Node) -> void:
	var name_label = boot_node.get_node_or_null("LogoContainer/Name")
	var init_label = boot_node.get_node_or_null("LogoContainer/Label")
	if name_label and not str(name_label.text).begins_with("Taj's QoL"):
		name_label.text = "Taj's QoL OS " + ProjectSettings.get_setting("application/config/version")
		if init_label:
			init_label.text = "Initializing - Mod v" + _mod_version

	var logo_rect = boot_node.get_node_or_null("LogoContainer/Logo")
	if logo_rect and not logo_rect.has_node("TajsQolIcon"):
		var icon_tex: Texture2D = null
		if ResourceLoader.exists(_icon_path):
			icon_tex = load(_icon_path) as Texture2D
		if icon_tex:
			var new_icon = TextureRect.new()
			new_icon.name = "TajsQolIcon"
			new_icon.texture = icon_tex
			new_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			new_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			new_icon.custom_minimum_size = Vector2(110, 110)
			new_icon.size = Vector2(110, 110)
			new_icon.position = Vector2(
				(logo_rect.size.x - new_icon.size.x) / 2,
				- new_icon.size.y - 10
			)
			logo_rect.add_child(new_icon)
