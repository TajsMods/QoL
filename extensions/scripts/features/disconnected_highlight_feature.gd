extends Node

const LOG_NAME := "TajemnikTV-QoL:DisconnectedHighlight"

const PULSE_DURATION := 1.0
const DEBOUNCE_TIME := 0.15
const HIGHLIGHT_COLOR := Color(1.0, 0.0, 0.0)

var _core
var _connectivity
var _node_finder
var _safe_ops

var _enabled: bool = true
var _style: String = "pulse"
var _intensity: float = 0.5

var _disconnected_windows: Dictionary = {}
var _cached_windows: Dictionary = {}

var _draw_control: Control = null
var _pulse_tween: Tween = null
var _pulse_alpha: float = 0.0
var _last_redraw_time: float = 0.0
var _debounce_timer: Timer = null


func setup(core) -> void:
    _core = core
    _connectivity = _core.get("connectivity_helpers") if _core != null else null
    _node_finder = _core.get("node_finder") if _core != null else null
    _safe_ops = _core.get("safe_ops") if _core != null else null
    set_process(true)
    _setup_debouncer()
    _connect_signals()


func _ready() -> void:
    _start_pulse_tween()
    _try_setup_desktop()


func set_enabled(enabled: bool) -> void:
    _enabled = enabled
    if _draw_control != null:
        _draw_control.visible = enabled
        _draw_control.queue_redraw()
    if enabled:
        recompute_disconnected()


func set_style(style: String) -> void:
    _style = style
    if _draw_control != null:
        _draw_control.queue_redraw()


func set_intensity(value: float) -> void:
    _intensity = clampf(value, 0.0, 1.0)
    if _draw_control != null:
        _draw_control.queue_redraw()


func recompute_disconnected() -> void:
    if not _enabled:
        return
    
    # Try to use core's connectivity_helpers if available
    if _connectivity != null and _connectivity.has_method("scan_disconnected_windows"):
        var result: Dictionary = _connectivity.scan_disconnected_windows(2)
        var disconnected = result.get("disconnected", {})
        _disconnected_windows = disconnected if disconnected is Dictionary else {}
        _cached_windows.clear()
        if _draw_control != null:
            _draw_control.queue_redraw()
        return
    
    # Fallback: Built-in connectivity scanning logic
    if not is_instance_valid(Globals.desktop):
        return
    
    var windows_container = Globals.desktop.get_node_or_null("Windows")
    if not windows_container:
        return
    
    # 1. Gather all resources and map them to their Windows
    var all_res_ids: Dictionary = {} # id -> ResourceContainer
    var res_to_window: Dictionary = {} # id -> WindowContainer
    
    for window in windows_container.get_children():
        if window is WindowContainer:
            var resources = _get_window_resources(window, [])
            for res in resources:
                if res.id and not res.id.is_empty():
                    all_res_ids[res.id] = res
                    res_to_window[res.id] = window
    
    if all_res_ids.is_empty():
        _disconnected_windows.clear()
        if _draw_control != null:
            _draw_control.queue_redraw()
        return
    
    # 2. Build Adjacency Graph (Global)
    var adjacency: Dictionary = {} # id -> Array[id]
    
    # Initialize list
    for id in all_res_ids:
        adjacency[id] = []
    
    for id in all_res_ids:
        var res = all_res_ids[id]
        
        # External Connections (Wires)
        for out_id in res.outputs_id:
            if all_res_ids.has(out_id):
                adjacency[id].append(out_id)
                adjacency[out_id].append(id) # Bidirectional
    
    # Add Internal Connections (All Resources in Same Window)
    for window in windows_container.get_children():
        if window is WindowContainer:
            var resources = _get_window_resources(window, [])
            var ids = []
            for res in resources:
                if res.id and not res.id.is_empty():
                    ids.append(res.id)
            
            # Connect all resources within the same window to each other
            for i in range(ids.size()):
                for j in range(i + 1, ids.size()):
                    var id1 = ids[i]
                    var id2 = ids[j]
                    adjacency[id1].append(id2)
                    adjacency[id2].append(id1)
    
    # 3. BFS to find Connected Components
    var visited: Dictionary = {}
    var components = []
    
    for start_id in all_res_ids:
        if visited.has(start_id):
            continue
        
        # Start BFS
        var component = []
        var queue = [start_id]
        visited[start_id] = true
        
        var idx = 0
        while idx < queue.size():
            var curr = queue[idx]
            idx += 1
            component.append(curr)
            
            if adjacency.has(curr):
                for neighbor in adjacency[curr]:
                    if not visited.has(neighbor):
                        visited[neighbor] = true
                        queue.append(neighbor)
        
        components.append(component)
    
    # 4. Validate Components - Must span >= 2 Distinct Windows
    var newly_disconnected_windows: Dictionary = {}
    
    for comp in components:
        var distinct_windows = {}
        for r_id in comp:
            var w = res_to_window[r_id]
            distinct_windows[w.name] = true
        
        if distinct_windows.size() < 2:
            # Invalid (Isolated) - mark windows
            for r_id in comp:
                var w = res_to_window[r_id]
                newly_disconnected_windows[w.name] = true
    
    # Update State
    _disconnected_windows = newly_disconnected_windows
    _cached_windows.clear() # Clear cache to avoid stale references
    
    if _draw_control != null:
        _draw_control.queue_redraw()


func _process(_delta: float) -> void:
    if not _enabled or _disconnected_windows.is_empty() or _draw_control == null:
        return
    # Always redraw at ~30 FPS to track window position changes (e.g., when dragged)
    var now = Time.get_ticks_msec() / 1000.0
    if now - _last_redraw_time < 0.033:
        return
    _last_redraw_time = now
    _draw_control.queue_redraw()


func _setup_debouncer() -> void:
    _debounce_timer = Timer.new()
    _debounce_timer.wait_time = DEBOUNCE_TIME
    _debounce_timer.one_shot = true
    _debounce_timer.timeout.connect(recompute_disconnected)
    add_child(_debounce_timer)


func _connect_signals() -> void:
    if _core != null:
        var event_bus = _core.get("event_bus")
        if event_bus != null and event_bus.has_method("on"):
            event_bus.on("game.desktop_ready", Callable(self , "_on_desktop_ready"), self , true)
    if Signals != null:
        if Signals.has_signal("connection_created"):
            _safe_connect(Signals.connection_created, Callable(self , "_on_connection_changed"))
        if Signals.has_signal("connection_deleted"):
            _safe_connect(Signals.connection_deleted, Callable(self , "_on_connection_changed"))


func _on_desktop_ready(_payload: Dictionary) -> void:
    call_deferred("_setup_draw_control")
    call_deferred("_connect_windows_container_signals")
    call_deferred("recompute_disconnected")


func _try_setup_desktop() -> void:
    if is_instance_valid(Globals.desktop):
        _on_desktop_ready({})


func _connect_windows_container_signals() -> void:
    if not is_instance_valid(Globals.desktop):
        return
    var windows_container = Globals.desktop.get_node_or_null("Windows")
    if windows_container == null:
        return
    _safe_connect(windows_container.child_entered_tree, Callable(self , "_on_window_added"))
    _safe_connect(windows_container.child_exiting_tree, Callable(self , "_on_window_removed"))


func _on_window_added(node: Node) -> void:
    if node is WindowContainer:
        _trigger_recompute()


func _on_window_removed(node: Node) -> void:
    if node is WindowContainer:
        _trigger_recompute()


func _on_connection_changed(_a = null, _b = null) -> void:
    _trigger_recompute()


func _trigger_recompute() -> void:
    if _enabled and _debounce_timer != null:
        _debounce_timer.start()


func _setup_draw_control() -> void:
    if not is_instance_valid(Globals.desktop):
        return
    if _draw_control != null and is_instance_valid(_draw_control):
        if _draw_control.get_parent() == Globals.desktop:
            _draw_control.visible = _enabled
            return
        _draw_control.queue_free()
        _draw_control = null

    _draw_control = Control.new()
    _draw_control.name = "DisconnectedHighlightOverlay"
    _draw_control.position = Vector2(-20000, -20000)
    _draw_control.size = Vector2(40000, 40000)
    _draw_control.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _draw_control.z_index = 100
    _draw_control.draw.connect(_on_draw_highlights)
    _draw_control.visible = _enabled
    Globals.desktop.add_child(_draw_control)


func _start_pulse_tween() -> void:
    if _pulse_tween != null and _pulse_tween.is_valid():
        _pulse_tween.kill()
    _pulse_tween = create_tween()
    _pulse_tween.set_loops()
    _pulse_tween.tween_property(self , "_pulse_alpha", 1.0, PULSE_DURATION / 2.0).set_trans(Tween.TRANS_SINE)
    _pulse_tween.tween_property(self , "_pulse_alpha", 0.0, PULSE_DURATION / 2.0).set_trans(Tween.TRANS_SINE)


func _on_draw_highlights() -> void:
    if not _enabled or _disconnected_windows.is_empty():
        return
    if _draw_control == null:
        return
    if _style == "pulse":
        var max_a = 0.3 + (_intensity * 0.5)
        var min_a = 0.1
        var cur_a = min_a + (max_a - min_a) * _pulse_alpha
        var col = HIGHLIGHT_COLOR
        col.a = cur_a
        for win_name in _disconnected_windows:
            var win = _get_cached_window(win_name)
            if win != null:
                var local_pos = win.global_position - _draw_control.global_position
                var win_size = win.custom_minimum_size if win.custom_minimum_size != Vector2.ZERO else win.size
                var rect = Rect2(local_pos, win_size)
                _draw_control.draw_rect(rect, col, true)
    else:
        var col = HIGHLIGHT_COLOR
        col.a = 0.3 + (_intensity * 0.7)
        var border_width = 4
        for win_name in _disconnected_windows:
            var win = _get_cached_window(win_name)
            if win != null:
                var local_pos = win.global_position - _draw_control.global_position
                var win_size = win.custom_minimum_size if win.custom_minimum_size != Vector2.ZERO else win.size
                var rect = Rect2(local_pos, win_size)
                _draw_control.draw_rect(rect, col, false, border_width)


func _get_cached_window(win_name: String) -> WindowContainer:
    if _cached_windows.has(win_name) and is_instance_valid(_cached_windows[win_name]):
        return _cached_windows[win_name]
    var win = _find_window_by_name(win_name)
    if win != null:
        _cached_windows[win_name] = win
    return win


func _find_window_by_name(window_name: String) -> WindowContainer:
    if _node_finder != null and _node_finder.has_method("get_window_by_name"):
        return _node_finder.get_window_by_name(window_name)
    if Globals == null or Globals.desktop == null:
        return null
    var windows_root = Globals.desktop.get_node_or_null("Windows")
    if windows_root == null:
        return null
    return windows_root.get_node_or_null(window_name)


func _get_window_resources(node: Node, result: Array = []) -> Array:
    if node is ResourceContainer:
        result.append(node)
    for child in node.get_children():
        _get_window_resources(child, result)
    return result


func _safe_connect(signal_ref: Signal, callable: Callable) -> void:
    if _safe_ops != null and _safe_ops.has_method("safe_connect"):
        _safe_ops.safe_connect(signal_ref, callable)
        return
    if signal_ref == null or callable == null or not callable.is_valid():
        return
    if not signal_ref.is_connected(callable):
        signal_ref.connect(callable)
