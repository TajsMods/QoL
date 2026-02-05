extends RefCounted

const LOG_NAME := "TajemnikTV-QoL:Screenshot"
const CAPTURE_DELAY := 5
const WATERMARK_PATH := ""

var quality: int = 2
var screenshot_folder: String = "user://screenshots"
var watermark_enabled: bool = false

var _tree: SceneTree = null
var _core = null
var _enabled: bool = true


func setup(core) -> void:
    _core = core


func set_tree(tree: SceneTree) -> void:
    _tree = tree


func set_quality(value: int) -> void:
    quality = clampi(value, 0, 3)


func set_screenshot_folder(path: String) -> void:
    screenshot_folder = path


func set_watermark_enabled(enabled: bool) -> void:
    watermark_enabled = enabled


func set_enabled(enabled: bool) -> void:
    _enabled = enabled


func is_enabled() -> bool:
    return _enabled


func get_display_folder() -> String:
    if screenshot_folder.begins_with("user://"):
        return ProjectSettings.globalize_path(screenshot_folder)
    return screenshot_folder


func take_screenshot() -> void:
    if not _enabled:
        return
    if _tree == null:
        _log("ERROR: SceneTree not available", true)
        return
    var desktop = Globals.desktop if is_instance_valid(Globals.desktop) else null
    if desktop == null:
        _log("ERROR: Desktop not found", true)
        _notify("exclamation", "Could not capture - desktop not found")
        return
    var windows_container = desktop.get_node_or_null("Windows")
    if windows_container == null:
        _log("ERROR: Windows container not found", true)
        _notify("exclamation", "Could not capture - no windows")
        return
    var bounds = Rect2()
    var first = true
    for child in windows_container.get_children():
        if child is Control:
            var child_rect = Rect2(child.position, child.size)
            if first:
                bounds = child_rect
                first = false
            else:
                bounds = bounds.merge(child_rect)
    if first:
        _log("No windows to capture", true)
        _notify("exclamation", "No windows to capture")
        return
    _capture_bounds(bounds, "fullboard")


func take_screenshot_selection() -> void:
    if not _enabled:
        return
    if _tree == null:
        _log("ERROR: SceneTree not available", true)
        return
    if Globals == null or Globals.selections.is_empty():
        _notify("exclamation", "No nodes selected")
        return
    var bounds = _compute_selection_bounds()
    if bounds.size == Vector2.ZERO:
        _notify("exclamation", "Could not determine selection bounds")
        return
    bounds = bounds.grow(64)
    _capture_bounds(bounds, "selection_%dnodes" % Globals.selections.size())


func open_screenshot_folder() -> void:
    DirAccess.make_dir_recursive_absolute(screenshot_folder)
    var global_path = screenshot_folder
    if screenshot_folder.begins_with("user://"):
        global_path = ProjectSettings.globalize_path(screenshot_folder)
    var err = OS.shell_open(global_path)
    if err != OK:
        _notify("exclamation", "Could not open folder")


func show_folder_dialog(on_changed: Callable) -> void:
    if _tree == null:
        return
    var dialog = FileDialog.new()
    dialog.file_mode = FileDialog.FILE_MODE_OPEN_DIR
    dialog.access = FileDialog.ACCESS_FILESYSTEM
    dialog.title = "Select Screenshot Folder"
    dialog.size = Vector2(800, 500)
    var initial_path = screenshot_folder
    if initial_path.begins_with("user://"):
        initial_path = ProjectSettings.globalize_path(initial_path)
    dialog.current_dir = initial_path
    dialog.dir_selected.connect(func(dir: String):
        screenshot_folder = dir
        if on_changed != null and on_changed.is_valid():
            on_changed.call(dir)
        _notify("check", "Screenshot folder updated")
        dialog.queue_free()
    )
    dialog.canceled.connect(func():
        dialog.queue_free()
    )
    _tree.root.call_deferred("add_child", dialog)
    dialog.popup_centered()


func _capture_bounds(bounds: Rect2, prefix: String) -> void:
    var desktop = Globals.desktop if is_instance_valid(Globals.desktop) else null
    if desktop == null:
        _notify("exclamation", "Could not capture - desktop not found")
        return

    var capture_zoom = [0.5, 0.6, 0.8, 1.5][quality]
    var use_jpg = quality < 2

    var viewport = _tree.root.get_viewport()
    viewport.set_disable_input(true)
    _notify("check", "Capturing screenshot... please wait")

    var hud = _tree.root.get_node_or_null("Main/HUD")
    var hud_was_visible = true
    if hud:
        hud_was_visible = hud.visible
        hud.visible = false

    var main_camera = _tree.root.get_node_or_null("Main/Main2D/Camera2D")
    if main_camera == null:
        _notify("exclamation", "Camera not found")
        viewport.set_disable_input(false)
        return

    var saved_cam_pos = main_camera.position
    var saved_cam_zoom = main_camera.zoom
    var saved_target_zoom = main_camera.get("target_zoom") if main_camera.get("target_zoom") else saved_cam_zoom
    var saved_zooming = main_camera.get("zooming") if main_camera.get("zooming") != null else false

    main_camera.set_block_signals(true)
    main_camera.set_process(false)
    main_camera.set_physics_process(false)
    main_camera.set_process_input(false)
    main_camera.set_process_unhandled_input(false)
    main_camera.set_process_unhandled_key_input(false)
    main_camera.set_process_shortcut_input(false)

    var dragger = _tree.root.get_node_or_null("Main/Main2D/Dragger")
    var saved_dragger_mouse_filter = Control.MOUSE_FILTER_PASS
    if dragger and dragger is Control:
        saved_dragger_mouse_filter = dragger.mouse_filter
        dragger.mouse_filter = Control.MOUSE_FILTER_IGNORE

    if main_camera.get("zooming") != null:
        main_camera.set("zooming", false)

    var lines_node = desktop.get_node_or_null("Lines")
    var saved_lines_visible = true
    if lines_node:
        saved_lines_visible = lines_node.visible
        lines_node.visible = true

    var viewport_size = viewport.size
    var tile_world_size = viewport_size / capture_zoom
    bounds = bounds.grow(max(tile_world_size.x, tile_world_size.y) * 0.15)

    var tiles_x = int(ceil(bounds.size.x / tile_world_size.x))
    var tiles_y = int(ceil(bounds.size.y / tile_world_size.y))

    var final_width = int(tiles_x * viewport_size.x)
    var final_height = int(tiles_y * viewport_size.y)

    var max_dimension = 16384
    if final_width > max_dimension or final_height > max_dimension:
        var scale_down = min(float(max_dimension) / final_width, float(max_dimension) / final_height)
        capture_zoom = capture_zoom * scale_down
        tile_world_size = viewport_size / capture_zoom
        tiles_x = int(ceil(bounds.size.x / tile_world_size.x))
        tiles_y = int(ceil(bounds.size.y / tile_world_size.y))
        final_width = int(tiles_x * viewport_size.x)
        final_height = int(tiles_y * viewport_size.y)

    var final_image = Image.create(final_width, final_height, false, Image.FORMAT_RGBA8)
    final_image.fill(Color(0.12, 0.14, 0.18, 1.0))

    for ty in range(tiles_y):
        for tx in range(tiles_x):
            var tile_center = Vector2(
                bounds.position.x + (tx + 0.5) * tile_world_size.x,
                bounds.position.y + (ty + 0.5) * tile_world_size.y
            )
            main_camera.position = tile_center
            main_camera.zoom = Vector2(capture_zoom, capture_zoom)
            if main_camera.get("target_zoom") != null:
                main_camera.set("target_zoom", Vector2(capture_zoom, capture_zoom))

            var frames_to_wait = CAPTURE_DELAY
            if tx == 0 and ty == 0:
                frames_to_wait += 5
            for _frame in range(frames_to_wait):
                main_camera.position = tile_center
                main_camera.zoom = Vector2(capture_zoom, capture_zoom)
                await _tree.process_frame

            RenderingServer.force_sync()
            await _tree.process_frame

            main_camera.position = tile_center
            main_camera.zoom = Vector2(capture_zoom, capture_zoom)

            var tile_image = viewport.get_texture().get_image()
            tile_image.convert(Image.FORMAT_RGBA8)
            var paste_x = tx * int(viewport_size.x)
            var paste_y = ty * int(viewport_size.y)
            final_image.blit_rect(tile_image, Rect2i(0, 0, int(viewport_size.x), int(viewport_size.y)), Vector2i(paste_x, paste_y))

    var target_width = int(bounds.size.x * capture_zoom)
    var target_height = int(bounds.size.y * capture_zoom)
    if target_width < final_width or target_height < final_height:
        var cropped = Image.create(target_width, target_height, false, Image.FORMAT_RGBA8)
        cropped.blit_rect(final_image, Rect2i(0, 0, target_width, target_height), Vector2i.ZERO)
        final_image = cropped
        final_width = target_width
        final_height = target_height

    _apply_watermark(final_image, final_width, final_height)

    viewport.set_disable_input(false)
    main_camera.set_block_signals(false)
    main_camera.set_process(true)
    main_camera.set_physics_process(true)
    main_camera.set_process_input(true)
    main_camera.set_process_unhandled_input(true)
    main_camera.set_process_unhandled_key_input(true)
    main_camera.set_process_shortcut_input(true)

    if dragger and dragger is Control:
        dragger.mouse_filter = saved_dragger_mouse_filter

    main_camera.position = saved_cam_pos
    main_camera.zoom = saved_cam_zoom
    if main_camera.get("target_zoom") != null:
        main_camera.set("target_zoom", saved_target_zoom)
    if main_camera.get("zooming") != null:
        main_camera.set("zooming", saved_zooming)
    if lines_node:
        lines_node.visible = saved_lines_visible
    if hud:
        hud.visible = hud_was_visible

    var time = Time.get_datetime_string_from_system().replace(":", "-")
    var quality_names = ["low", "med", "high", "original"]
    var extension = ".jpg" if use_jpg else ".png"
    var path = screenshot_folder.path_join("%s_%s_%s%s" % [prefix, quality_names[quality], time, extension])
    DirAccess.make_dir_recursive_absolute(screenshot_folder)

    if use_jpg:
        var jpg_quality = 0.80 if quality == 0 else 0.90
        final_image.save_jpg(path, jpg_quality)
    else:
        final_image.save_png(path)

    _notify("check", "Screenshot saved! (%dx%d)" % [final_width, final_height])


func _apply_watermark(image: Image, final_width: int, final_height: int) -> void:
    if not watermark_enabled:
        return
    if WATERMARK_PATH == "" or not ResourceLoader.exists(WATERMARK_PATH):
        _log("Watermark enabled but no watermark asset configured", true)
        return
    var watermark_texture = load(WATERMARK_PATH) as Texture2D
    if watermark_texture == null:
        return
    var watermark_image = watermark_texture.get_image()
    watermark_image.convert(Image.FORMAT_RGBA8)
    var target_watermark_width = int(final_width * 0.15)
    var scale_factor = float(target_watermark_width) / watermark_image.get_width()
    var scaled_width = int(watermark_image.get_width() * scale_factor)
    var scaled_height = int(watermark_image.get_height() * scale_factor)
    if scaled_width < 100:
        scaled_width = 100
        scaled_height = int(watermark_image.get_height() * (100.0 / watermark_image.get_width()))
    watermark_image.resize(scaled_width, scaled_height, Image.INTERPOLATE_LANCZOS)
    for y in range(scaled_height):
        for x in range(scaled_width):
            var pixel = watermark_image.get_pixel(x, y)
            pixel.a *= 0.5
            watermark_image.set_pixel(x, y, pixel)
    var padding = int(final_width * 0.02)
    var paste_x = final_width - scaled_width - padding
    var paste_y = final_height - scaled_height - padding
    image.blend_rect(watermark_image, Rect2i(0, 0, scaled_width, scaled_height), Vector2i(paste_x, paste_y))


func _compute_selection_bounds() -> Rect2:
    var first = true
    var bounds = Rect2()
    for window in Globals.selections:
        if window is Control:
            var window_rect = Rect2(window.position, window.size)
            if first:
                bounds = window_rect
                first = false
            else:
                bounds = bounds.merge(window_rect)
    return bounds


func _notify(icon: String, message: String) -> void:
    if _core != null and _core.has_method("notify"):
        _core.notify(icon, message)
    else:
        Signals.notify.emit(icon, message)


func _log(message: String, is_error: bool = false) -> void:
    if _core != null and _core.logger != null:
        if is_error:
            _core.logger.warn("qol_screenshot", message)
        else:
            _core.logger.info("qol_screenshot", message)
    elif is_error:
        ModLoaderLog.warning(message, LOG_NAME)
    else:
        ModLoaderLog.info(message, LOG_NAME)
