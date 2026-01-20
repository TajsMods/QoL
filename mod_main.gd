# ==============================================================================
# Taj's QoL - Main
# Author: TajemnikTV
# Description: Adds QoL features to the game
# ==============================================================================
extends Node

const MOD_ID := "TajemnikTV-QoL"
const LOG_NAME := "TajemnikTV-QoL:Main"
const CORE_META_KEY := "TajsCore"
const CORE_MIN_VERSION := "1.0.0"
const SETTINGS_PREFIX := "tajs_qol"
const KEYBIND_CATEGORY_ID := "tajs_qol"

const SmartSelectFeatureScript = preload("res://mods-unpacked/TajemnikTV-QoL/extensions/scripts/features/smart_select_feature.gd")
const WireClearFeatureScript = preload("res://mods-unpacked/TajemnikTV-QoL/extensions/scripts/features/wire_clear_feature.gd")
const WireDropFeatureScript = preload("res://mods-unpacked/TajemnikTV-QoL/extensions/scripts/features/wire_drop_feature.gd")
const SliderScrollBlockFeatureScript = preload("res://mods-unpacked/TajemnikTV-QoL/extensions/scripts/features/slider_scroll_block_feature.gd")
const FocusMuteFeatureScript = preload("res://mods-unpacked/TajemnikTV-QoL/extensions/scripts/features/focus_mute_feature.gd")
const ControllerBlockFeatureScript = preload("res://mods-unpacked/TajemnikTV-QoL/extensions/scripts/features/controller_block_feature.gd")
const NotificationHistoryFeatureScript = preload("res://mods-unpacked/TajemnikTV-QoL/extensions/scripts/features/notification_history_feature.gd")
const ScreenshotFeatureScript = preload("res://mods-unpacked/TajemnikTV-QoL/extensions/scripts/features/screenshot_feature.gd")
const WireColorsFeatureScript = preload("res://mods-unpacked/TajemnikTV-QoL/extensions/scripts/features/wire_colors_feature.gd")
const VisualEffectsFeatureScript = preload("res://mods-unpacked/TajemnikTV-QoL/extensions/scripts/features/visual_effects_feature.gd")
const DisconnectedHighlightFeatureScript = preload("res://mods-unpacked/TajemnikTV-QoL/extensions/scripts/features/disconnected_highlight_feature.gd")
const BreachThreatFeatureScript = preload("res://mods-unpacked/TajemnikTV-QoL/extensions/scripts/features/breach_threat_feature.gd")
const GroupPatternsFeatureScript = preload("res://mods-unpacked/TajemnikTV-QoL/extensions/scripts/features/group_patterns_feature.gd")
const GroupLayerFeatureScript = preload("res://mods-unpacked/TajemnikTV-QoL/extensions/scripts/features/group_layer_feature.gd")
const GotoGroupManagerScript = preload("res://mods-unpacked/TajemnikTV-Core/core/util/goto_group_manager.gd")
const CoreColorPickerPanelScript = preload("res://mods-unpacked/TajemnikTV-Core/core/ui/color_picker_panel.gd")

const SETTING_SMART_SELECT_ENABLED := "%s.smart_select_enabled" % SETTINGS_PREFIX
const SETTING_WIRE_CLEAR_ENABLED := "%s.wire_clear_enabled" % SETTINGS_PREFIX
const SETTING_WIRE_DROP_ENABLED := "%s.wire_drop_enabled" % SETTINGS_PREFIX
const SETTING_DISABLE_SLIDER_SCROLL := "%s.disable_slider_scroll" % SETTINGS_PREFIX
const SETTING_BREACH_ESCALATION_ENABLED := "%s.breach_escalation_enabled" % SETTINGS_PREFIX
const SETTING_BREACH_ESCALATION_THRESHOLD := "%s.breach_escalation_threshold" % SETTINGS_PREFIX
const SETTING_BREACH_DEESCALATION_ENABLED := "%s.breach_deescalation_enabled" % SETTINGS_PREFIX
const SETTING_BREACH_DEESCALATION_THRESHOLD := "%s.breach_deescalation_threshold" % SETTINGS_PREFIX
const SETTING_BREACH_ESCALATION_COOLDOWN := "%s.breach_escalation_cooldown" % SETTINGS_PREFIX
const SETTING_FOCUS_MUTE_ENABLED := "%s.focus_mute_enabled" % SETTINGS_PREFIX
const SETTING_FOCUS_BG_VOLUME := "%s.focus_background_volume" % SETTINGS_PREFIX
const SETTING_NOTIFICATION_HISTORY_ENABLED := "%s.notification_history_enabled" % SETTINGS_PREFIX
const SETTING_NOTIFICATION_HISTORY_MAX := "%s.notification_history_max" % SETTINGS_PREFIX
const SETTING_CONTROLLER_BLOCK_ENABLED := "%s.disable_controller_input" % SETTINGS_PREFIX
const SETTING_SCREENSHOT_ENABLED := "%s.screenshot_enabled" % SETTINGS_PREFIX
const SETTING_SCREENSHOT_QUALITY := "%s.screenshot_quality" % SETTINGS_PREFIX
const SETTING_SCREENSHOT_FOLDER := "%s.screenshot_folder" % SETTINGS_PREFIX
const SETTING_SCREENSHOT_WATERMARK := "%s.screenshot_watermark" % SETTINGS_PREFIX
const ACTION_SCREENSHOT_FULL := "%s.screenshot_action_full" % SETTINGS_PREFIX
const ACTION_SCREENSHOT_SELECTION := "%s.screenshot_action_selection" % SETTINGS_PREFIX
const ACTION_SCREENSHOT_OPEN_FOLDER := "%s.screenshot_action_open_folder" % SETTINGS_PREFIX
const ACTION_SCREENSHOT_CHANGE_FOLDER := "%s.screenshot_action_change_folder" % SETTINGS_PREFIX
const SETTING_WIRE_COLORS_ENABLED := "%s.wire_colors_enabled" % SETTINGS_PREFIX
const SETTING_WIRE_COLORS_HEX := "%s.wire_colors_hex" % SETTINGS_PREFIX
const ACTION_RESET_WIRE_COLORS := "%s.wire_colors_reset" % SETTINGS_PREFIX
const SETTING_GLOW_ENABLED := "%s.glow_enabled" % SETTINGS_PREFIX
const SETTING_GLOW_INTENSITY := "%s.glow_intensity" % SETTINGS_PREFIX
const SETTING_GLOW_STRENGTH := "%s.glow_strength" % SETTINGS_PREFIX
const SETTING_GLOW_BLOOM := "%s.glow_bloom" % SETTINGS_PREFIX
const SETTING_GLOW_SENSITIVITY := "%s.glow_sensitivity" % SETTINGS_PREFIX
const SETTING_UI_OPACITY := "%s.ui_opacity" % SETTINGS_PREFIX
const SETTING_HIGHLIGHT_DISCONNECTED_ENABLED := "%s.highlight_disconnected_enabled" % SETTINGS_PREFIX
const SETTING_HIGHLIGHT_DISCONNECTED_STYLE := "%s.highlight_disconnected_style" % SETTINGS_PREFIX
const SETTING_HIGHLIGHT_DISCONNECTED_INTENSITY := "%s.highlight_disconnected_intensity" % SETTINGS_PREFIX
const SETTING_GROUP_PATTERNS_ENABLED := "%s.group_patterns_enabled" % SETTINGS_PREFIX
const SETTING_GROUP_COLOR_PICKER_ENABLED := "%s.group_color_picker_enabled" % SETTINGS_PREFIX
const SETTING_GROUP_PATTERNS_DATA := "%s.group_patterns" % SETTINGS_PREFIX
const SETTING_GROUP_LOCK_DATA := "%s.group_lock_data" % SETTINGS_PREFIX
const SETTING_COLOR_PICKER_DATA := "%s.color_picker" % SETTINGS_PREFIX
const SETTING_HIDE_PURCHASED_TOKENS := "%s.hide_purchased_tokens" % SETTINGS_PREFIX
const SETTING_HIDE_MAXED_UPGRADES := "%s.hide_maxed_upgrades" % SETTINGS_PREFIX
const SETTING_HIDE_CLAIMED_REQUESTS := "%s.hide_claimed_requests" % SETTINGS_PREFIX

const SETTINGS_KEYS := [
    SETTING_SMART_SELECT_ENABLED,
    SETTING_WIRE_CLEAR_ENABLED,
    SETTING_WIRE_DROP_ENABLED,
    SETTING_DISABLE_SLIDER_SCROLL,
    SETTING_BREACH_ESCALATION_ENABLED,
    SETTING_BREACH_ESCALATION_THRESHOLD,
    SETTING_BREACH_DEESCALATION_ENABLED,
    SETTING_BREACH_DEESCALATION_THRESHOLD,
    SETTING_BREACH_ESCALATION_COOLDOWN,
    SETTING_FOCUS_MUTE_ENABLED,
    SETTING_FOCUS_BG_VOLUME,
    SETTING_NOTIFICATION_HISTORY_ENABLED,
    SETTING_NOTIFICATION_HISTORY_MAX,
    SETTING_CONTROLLER_BLOCK_ENABLED,
    SETTING_SCREENSHOT_ENABLED,
    SETTING_SCREENSHOT_QUALITY,
    SETTING_SCREENSHOT_FOLDER,
    SETTING_SCREENSHOT_WATERMARK,
    SETTING_WIRE_COLORS_ENABLED,
    SETTING_WIRE_COLORS_HEX,
    SETTING_GLOW_ENABLED,
    SETTING_GLOW_INTENSITY,
    SETTING_GLOW_STRENGTH,
    SETTING_GLOW_BLOOM,
    SETTING_GLOW_SENSITIVITY,
    SETTING_UI_OPACITY,
    SETTING_HIGHLIGHT_DISCONNECTED_ENABLED,
    SETTING_HIGHLIGHT_DISCONNECTED_STYLE,
    SETTING_HIGHLIGHT_DISCONNECTED_INTENSITY,
    SETTING_GROUP_PATTERNS_ENABLED,
    SETTING_GROUP_COLOR_PICKER_ENABLED,
    SETTING_GROUP_PATTERNS_DATA
]
const StickyNoteManagerScript = preload("res://mods-unpacked/TajemnikTV-QoL/extensions/scripts/sticky_notes/sticky_note_manager.gd")

var _core
var _settings
var _ui_manager
var _sticky_note_manager
var _goto_group_manager
var _palette_controller
var _palette_overlay

var _smart_select
var _wire_clear
var _wire_drop
var _slider_scroll_block
var _focus_mute
var _controller_block
var _notification_history
var _screenshot
var _wire_colors
var _visual_effects
var _disconnected_highlight
var _breach_threat
var _group_patterns
var _group_layer

var _hud_ready: bool = false
var _setting_handlers: Dictionary = {}
var _setting_ui_updaters: Dictionary = {}
var _settings_tab: VBoxContainer = null
var _folder_label: Label = null
var _quality_dropdown: OptionButton = null
var _wire_color_buttons: Dictionary = {}
var _settings_retry_count: int = 0
var _settings_ui_built: bool = false
var _color_picker_layer: CanvasLayer = null
var _color_picker_panel: Control = null
var _color_picker_callback: Callable = Callable()


func _init() -> void:
    if _has_global_class("ModLoaderMod"):
        ModLoaderMod.install_script_extension("res://mods-unpacked/TajemnikTV-QoL/extensions/scenes/windows/window_group.gd")
        ModLoaderMod.install_script_extension("res://mods-unpacked/TajemnikTV-QoL/extensions/scripts/options_bar.gd")
        ModLoaderMod.install_script_extension("res://mods-unpacked/TajemnikTV-QoL/extensions/scripts/tokens_tab.gd")
        ModLoaderMod.install_script_extension("res://mods-unpacked/TajemnikTV-QoL/extensions/scripts/upgrades_tab.gd")
        ModLoaderMod.install_script_extension("res://mods-unpacked/TajemnikTV-QoL/extensions/scenes/request_panel.gd")
        ModLoaderMod.install_script_extension("res://mods-unpacked/TajemnikTV-QoL/extensions/scripts/requests_tab.gd")
        ModLoaderMod.install_script_extension("res://mods-unpacked/TajemnikTV-QoL/extensions/scripts/window_breach.gd")
    _core = _get_core()
    if _core == null:
        _log_warn("Taj's Core not found; QoL disabled.")
        return
    if not _core.require(CORE_MIN_VERSION):
        _log_warn("Taj's Core %s+ required; QoL disabled." % CORE_MIN_VERSION)
        return
    _settings = _core.settings
    _register_module()
    _register_settings()
    _init_features()
    _register_keybinds()
    _register_commands()
    _register_events()
    _apply_initial_settings()


func _ready() -> void:
    if _screenshot != null:
        _screenshot.set_tree(get_tree())
    if _wire_colors != null:
        _wire_colors.set_tree(get_tree())
    # Settings UI is auto-generated from schema in Core.


func _get_core():
    if Engine.has_meta(CORE_META_KEY):
        var core = Engine.get_meta(CORE_META_KEY)
        if core != null and core.has_method("require"):
            return core
    return null


func _register_module() -> void:
    if _core.has_method("register_module"):
        _core.register_module({
            "id": MOD_ID,
            "name": "QoL",
            "version": "0.1.0",
            "min_core_version": CORE_MIN_VERSION
        })


func _register_settings() -> void:
    if _settings == null:
        return
    var missing_sentinel := "__missing__"
    var existing_wire_drop = _settings.get_value(SETTING_WIRE_DROP_ENABLED, missing_sentinel)
    var legacy_wire_drop = _settings.get_value("wire_drop.menu_enabled", null)
    var schema := {
        SETTING_SMART_SELECT_ENABLED: {
            "type": "bool",
            "default": true,
            "label": "Smart Selection (Ctrl+A)",
            "description": "Select all nodes on the desktop with Ctrl+A.",
            "category": "Quality of Life"
        },
        SETTING_WIRE_CLEAR_ENABLED: {
            "type": "bool",
            "default": true,
            "label": "Right-click Wire Clear",
            "description": "Right-click connectors to disconnect wires.",
            "category": "Quality of Life"
        },
        SETTING_WIRE_DROP_ENABLED: {
            "type": "bool",
            "default": true,
            "label": "Wire Drop Menu",
            "description": "Show a node picker when wires are dropped on empty canvas.",
            "category": "Quality of Life"
        },
        SETTING_DISABLE_SLIDER_SCROLL: {
            "type": "bool",
            "default": false,
            "label": "Disable Slider Scroll",
            "description": "Prevent mouse wheel from changing slider values.",
            "category": "Input"
        },
        SETTING_BREACH_ESCALATION_ENABLED: {
            "type": "bool",
            "default": true,
            "label": "Auto Threat Adjustment",
            "description": "Automatically adjust breach threat level after consecutive successes/failures.",
            "category": "Breach Threat"
        },
        SETTING_BREACH_ESCALATION_THRESHOLD: {
            "type": "int",
            "default": 3,
            "label": "Escalation Threshold (Successes)",
            "description": "Successful breaches required before escalating threat level.",
            "category": "Breach Threat",
            "min": 1,
            "max": 15,
            "step": 1,
            "depends_on": {"key": SETTING_BREACH_ESCALATION_ENABLED, "equals": true}
        },
        SETTING_BREACH_DEESCALATION_ENABLED: {
            "type": "bool",
            "default": true,
            "label": "Auto De-escalation",
            "description": "Auto-decrease breach threat level after consecutive failures.",
            "category": "Breach Threat"
        },
        SETTING_BREACH_DEESCALATION_THRESHOLD: {
            "type": "int",
            "default": 5,
            "label": "De-escalation Threshold (Failures)",
            "description": "Failed breaches required before de-escalating threat level.",
            "category": "Breach Threat",
            "min": 1,
            "max": 15,
            "step": 1,
            "depends_on": {"key": SETTING_BREACH_DEESCALATION_ENABLED, "equals": true}
        },
        SETTING_BREACH_ESCALATION_COOLDOWN: {
            "type": "int",
            "default": 10,
            "label": "Escalation Cooldown (Successes)",
            "description": "Successful breaches to wait after de-escalation before escalating again.",
            "category": "Breach Threat",
            "min": 0,
            "max": 30,
            "step": 1,
            "depends_on": {"key": SETTING_BREACH_ESCALATION_ENABLED, "equals": true}
        },
        SETTING_FOCUS_MUTE_ENABLED: {
            "type": "bool",
            "default": true,
            "label": "Mute on Focus Loss",
            "description": "Lower volume when the game loses focus.",
            "category": "Audio"
        },
        SETTING_FOCUS_BG_VOLUME: {
            "type": "float",
            "default": 0.0,
            "label": "Background Volume",
            "description": "Background volume percentage.",
            "category": "Audio",
            "min": 0.0,
            "max": 100.0,
            "step": 5.0,
            "depends_on": {"key": SETTING_FOCUS_MUTE_ENABLED, "equals": true}
        },
        SETTING_NOTIFICATION_HISTORY_ENABLED: {
            "type": "bool",
            "default": true,
            "label": "Toast History Panel",
            "description": "Show a notification history panel in the HUD.",
            "category": "Notifications"
        },
        SETTING_NOTIFICATION_HISTORY_MAX: {
            "type": "int",
            "default": 20,
            "label": "Toast History Length",
            "description": "Maximum toast history items.",
            "category": "Notifications",
            "min": 5,
            "max": 100,
            "step": 5,
            "depends_on": {"key": SETTING_NOTIFICATION_HISTORY_ENABLED, "equals": true}
        },
        SETTING_CONTROLLER_BLOCK_ENABLED: {
            "type": "bool",
            "default": false,
            "label": "Disable Controller Input",
            "description": "Block all controller/joypad input.",
            "category": "Input"
        },
        SETTING_SCREENSHOT_ENABLED: {
            "type": "bool",
            "default": true,
            "label": "Screenshot Tools",
            "description": "Enable HQ/tiled screenshot tools.",
            "category": "Screenshots"
        },
        SETTING_SCREENSHOT_QUALITY: {
            "type": "enum",
            "default": 2,
            "label": "Screenshot Quality",
            "description": "Screenshot quality preset.",
            "category": "Screenshots",
            "options": [
                {"label": "Low (JPG)", "value": 0},
                {"label": "Medium (JPG)", "value": 1},
                {"label": "High (PNG)", "value": 2},
                {"label": "Original (PNG)", "value": 3}
            ],
            "depends_on": {"key": SETTING_SCREENSHOT_ENABLED, "equals": true}
        },
        SETTING_SCREENSHOT_FOLDER: {
            "type": "string",
            "default": "user://screenshots",
            "label": "Screenshot Folder",
            "description": "Screenshot output folder.",
            "category": "Screenshots",
            "depends_on": {"key": SETTING_SCREENSHOT_ENABLED, "equals": true}
        },
        SETTING_SCREENSHOT_WATERMARK: {
            "type": "bool",
            "default": false,
            "label": "Screenshot Watermark",
            "description": "Include a watermark on screenshots when available.",
            "category": "Screenshots",
            "depends_on": {"key": SETTING_SCREENSHOT_ENABLED, "equals": true}
        },
        ACTION_SCREENSHOT_FULL: {
            "type": "action",
            "default": false,
            "label": "Take Full Screenshot",
            "description": "Capture a full desktop screenshot.",
            "category": "Screenshots",
            "action": Callable(self, "_on_screenshot_full"),
            "depends_on": {"key": SETTING_SCREENSHOT_ENABLED, "equals": true}
        },
        ACTION_SCREENSHOT_SELECTION: {
            "type": "action",
            "default": false,
            "label": "Capture Selection",
            "description": "Capture only selected nodes.",
            "category": "Screenshots",
            "action": Callable(self, "_on_screenshot_selection"),
            "depends_on": {"key": SETTING_SCREENSHOT_ENABLED, "equals": true}
        },
        ACTION_SCREENSHOT_OPEN_FOLDER: {
            "type": "action",
            "default": false,
            "label": "Open Screenshot Folder",
            "description": "Open the screenshot folder in your file explorer.",
            "category": "Screenshots",
            "action": Callable(self, "_on_screenshot_folder")
        },
        ACTION_SCREENSHOT_CHANGE_FOLDER: {
            "type": "action",
            "default": false,
            "label": "Change Screenshot Folder",
            "description": "Choose a new screenshot output folder.",
            "category": "Screenshots",
            "action": Callable(self, "_change_screenshot_folder"),
            "depends_on": {"key": SETTING_SCREENSHOT_ENABLED, "equals": true}
        },
        SETTING_WIRE_COLORS_ENABLED: {
            "type": "bool",
            "default": true,
            "label": "Wire Color Overrides",
            "description": "Enable custom wire colors per resource.",
            "category": "Visuals"
        },
        SETTING_WIRE_COLORS_HEX: {
            "type": "dict",
            "default": {},
            "label": "Wire Color Overrides",
            "description": "Custom wire colors for each resource.",
            "category": "Visuals",
            "ui_control": "color_map",
            "color_options": WireColorsFeatureScript.CONFIGURABLE_WIRES,
            "color_get": Callable(self, "_get_wire_color"),
            "depends_on": {"key": SETTING_WIRE_COLORS_ENABLED, "equals": true}
        },
        ACTION_RESET_WIRE_COLORS: {
            "type": "action",
            "default": false,
            "label": "Reset Wire Colors",
            "description": "Reset all custom wire colors.",
            "category": "Visuals",
            "action": Callable(self, "_reset_wire_colors"),
            "depends_on": {"key": SETTING_WIRE_COLORS_ENABLED, "equals": true}
        },
        SETTING_GLOW_ENABLED: {
            "type": "bool",
            "default": false,
            "label": "Enable Extra Glow",
            "description": "Boost glow/bloom intensity.",
            "category": "Visuals"
        },
        SETTING_GLOW_INTENSITY: {
            "type": "float",
            "default": 2.0,
            "label": "Glow Intensity",
            "description": "Glow intensity.",
            "category": "Visuals",
            "min": 0.0,
            "max": 5.0,
            "step": 0.1,
            "depends_on": {"key": SETTING_GLOW_ENABLED, "equals": true}
        },
        SETTING_GLOW_STRENGTH: {
            "type": "float",
            "default": 1.3,
            "label": "Glow Strength",
            "description": "Glow strength.",
            "category": "Visuals",
            "min": 0.5,
            "max": 2.0,
            "step": 0.05,
            "depends_on": {"key": SETTING_GLOW_ENABLED, "equals": true}
        },
        SETTING_GLOW_BLOOM: {
            "type": "float",
            "default": 0.2,
            "label": "Glow Bloom",
            "description": "Glow bloom.",
            "category": "Visuals",
            "min": 0.0,
            "max": 0.5,
            "step": 0.05,
            "depends_on": {"key": SETTING_GLOW_ENABLED, "equals": true}
        },
        SETTING_GLOW_SENSITIVITY: {
            "type": "float",
            "default": 0.8,
            "label": "Glow Sensitivity",
            "description": "Glow sensitivity.",
            "category": "Visuals",
            "min": 0.0,
            "max": 1.0,
            "step": 0.05,
            "depends_on": {"key": SETTING_GLOW_ENABLED, "equals": true}
        },
        SETTING_UI_OPACITY: {
            "type": "float",
            "default": 100.0,
            "label": "UI Opacity",
            "description": "UI opacity percentage.",
            "category": "Visuals",
            "min": 50.0,
            "max": 100.0,
            "step": 5.0,
            "ui_control": "input"
        },
        SETTING_HIGHLIGHT_DISCONNECTED_ENABLED: {
            "type": "bool",
            "default": true,
            "label": "Disconnected Highlighting",
            "description": "Highlight windows not connected to the main graph.",
            "category": "Visuals"
        },
        SETTING_HIGHLIGHT_DISCONNECTED_STYLE: {
            "type": "enum",
            "default": "pulse",
            "label": "Highlight Style",
            "description": "Highlight style for disconnected windows.",
            "category": "Visuals",
            "options": [
                {"label": "Pulse Tint", "value": "pulse"},
                {"label": "Outline Tint", "value": "outline"}
            ],
            "depends_on": {"key": SETTING_HIGHLIGHT_DISCONNECTED_ENABLED, "equals": true}
        },
        SETTING_HIGHLIGHT_DISCONNECTED_INTENSITY: {
            "type": "float",
            "default": 0.5,
            "label": "Highlight Intensity",
            "description": "Highlight intensity.",
            "category": "Visuals",
            "min": 0.0,
            "max": 1.0,
            "step": 0.05,
            "ui_control": "input",
            "depends_on": {"key": SETTING_HIGHLIGHT_DISCONNECTED_ENABLED, "equals": true}
        },
        SETTING_GROUP_PATTERNS_ENABLED: {
            "type": "bool",
            "default": true,
            "label": "Group Patterns & Colors",
            "description": "Enable custom group patterns and colors.",
            "category": "Visuals"
        },
        SETTING_GROUP_COLOR_PICKER_ENABLED: {
            "type": "bool",
            "default": true,
            "label": "Group Custom Color Picker",
            "description": "Enable custom color picker for group nodes.",
            "category": "Visuals",
            "depends_on": {"key": SETTING_GROUP_PATTERNS_ENABLED, "equals": true}
        },
        SETTING_GROUP_PATTERNS_DATA: {
            "type": "dict",
            "default": {},
            "label": "Group Pattern Data",
            "description": "Stored group pattern settings.",
            "category": "Visuals",
            "hidden": true
        },
        SETTING_GROUP_LOCK_DATA: {
            "type": "dict",
            "default": {},
            "label": "Group Lock Data",
            "description": "Stored group lock state.",
            "category": "Quality of Life",
            "hidden": true
        },
        SETTING_COLOR_PICKER_DATA: {
            "type": "dict",
            "default": {},
            "label": "Color Picker Data",
            "description": "Color picker swatches and recents.",
            "category": "Visuals",
            "hidden": true
        },
        SETTING_HIDE_PURCHASED_TOKENS: {
            "type": "bool",
            "default": true,
            "label": "Hide Purchased Tokens",
            "description": "Hide purchased tokens in the shop.",
            "category": "Shop & Requests"
        },
        SETTING_HIDE_MAXED_UPGRADES: {
            "type": "bool",
            "default": true,
            "label": "Hide Maxed Upgrades",
            "description": "Hide maxed upgrades in the shop.",
            "category": "Shop & Requests"
        },
        SETTING_HIDE_CLAIMED_REQUESTS: {
            "type": "bool",
            "default": true,
            "label": "Hide Claimed Requests",
            "description": "Hide claimed requests.",
            "category": "Shop & Requests"
        }
    }
    _settings.register_schema(MOD_ID, schema, SETTINGS_PREFIX)
    if existing_wire_drop is String and existing_wire_drop == missing_sentinel and legacy_wire_drop != null:
        _settings.set_value(SETTING_WIRE_DROP_ENABLED, bool(legacy_wire_drop))


func _init_features() -> void:
    _smart_select = SmartSelectFeatureScript.new()
    _smart_select.setup(_core)

    _wire_clear = WireClearFeatureScript.new()
    _wire_clear.setup(_core)
    add_child(_wire_clear)

    _wire_drop = WireDropFeatureScript.new()
    _wire_drop.setup(_core)
    add_child(_wire_drop)

    _slider_scroll_block = SliderScrollBlockFeatureScript.new()
    _slider_scroll_block.setup()
    add_child(_slider_scroll_block)

    _focus_mute = FocusMuteFeatureScript.new()
    _focus_mute.setup()
    add_child(_focus_mute)

    _controller_block = ControllerBlockFeatureScript.new()
    _controller_block.setup()
    add_child(_controller_block)

    _notification_history = NotificationHistoryFeatureScript.new()
    _notification_history.setup(_core)
    add_child(_notification_history)

    _screenshot = ScreenshotFeatureScript.new()
    _screenshot.setup(_core)

    _wire_colors = WireColorsFeatureScript.new()
    _wire_colors.setup(_core)

    _visual_effects = VisualEffectsFeatureScript.new()
    _visual_effects.setup(_core)

    _disconnected_highlight = DisconnectedHighlightFeatureScript.new()
    _disconnected_highlight.setup(_core)
    add_child(_disconnected_highlight)

    _breach_threat = BreachThreatFeatureScript.new()
    _breach_threat.setup(_core)
    add_child(_breach_threat)
    if _core != null and _core.has_method("extend_globals"):
        _core.extend_globals("breach_threat_manager", _breach_threat)

    _group_patterns = GroupPatternsFeatureScript.new()

    _group_layer = GroupLayerFeatureScript.new()
    _group_layer.setup(_core)
    add_child(_group_layer)

    _goto_group_manager = GotoGroupManagerScript.new()
    if _goto_group_manager.has_method("setup"):
        _goto_group_manager.setup(_core)
    add_child(_goto_group_manager)
    if _core != null and _core.has_method("extend_globals"):
        _core.extend_globals("goto_group_manager", _goto_group_manager)

    _sticky_note_manager = StickyNoteManagerScript.new()
    _sticky_note_manager.setup(_settings, get_tree(), self)
    add_child(_sticky_note_manager)

    _setting_handlers = {
        SETTING_SMART_SELECT_ENABLED: func(value): _smart_select.set_enabled(bool(value)),
        SETTING_WIRE_CLEAR_ENABLED: func(value): _wire_clear.set_enabled(bool(value)),
        SETTING_WIRE_DROP_ENABLED: func(value): _wire_drop.set_enabled(bool(value)),
        SETTING_DISABLE_SLIDER_SCROLL: func(value): _slider_scroll_block.set_enabled(bool(value)),
        SETTING_BREACH_ESCALATION_ENABLED: func(value): _breach_threat.set_enabled(bool(value)),
        SETTING_BREACH_ESCALATION_THRESHOLD: func(value): _breach_threat.set_threshold(int(value)),
        SETTING_BREACH_DEESCALATION_ENABLED: func(value): _breach_threat.set_deescalation_enabled(bool(value)),
        SETTING_BREACH_DEESCALATION_THRESHOLD: func(value): _breach_threat.set_deescalation_threshold(int(value)),
        SETTING_BREACH_ESCALATION_COOLDOWN: func(value): _breach_threat.set_escalation_cooldown(int(value)),
        SETTING_FOCUS_MUTE_ENABLED: func(value): _focus_mute.set_enabled(bool(value)),
        SETTING_FOCUS_BG_VOLUME: func(value): _focus_mute.set_background_volume(float(value)),
        SETTING_NOTIFICATION_HISTORY_ENABLED: func(value): _notification_history.set_enabled(bool(value)),
        SETTING_NOTIFICATION_HISTORY_MAX: func(value): _notification_history.set_max_entries(int(value)),
        SETTING_CONTROLLER_BLOCK_ENABLED: func(value): _controller_block.set_enabled(bool(value)),
        SETTING_SCREENSHOT_ENABLED: func(value): _screenshot.set_enabled(bool(value)),
        SETTING_SCREENSHOT_QUALITY: func(value): _screenshot.set_quality(int(value)),
        SETTING_SCREENSHOT_FOLDER: func(value): _screenshot.set_screenshot_folder(str(value)),
        SETTING_SCREENSHOT_WATERMARK: func(value): _screenshot.set_watermark_enabled(bool(value)),
        SETTING_WIRE_COLORS_ENABLED: func(value): _wire_colors.set_enabled(bool(value)),
        SETTING_WIRE_COLORS_HEX: func(value): _wire_colors.set_custom_hex(value if value is Dictionary else {}),
        SETTING_GLOW_ENABLED: func(value): _visual_effects.set_glow_enabled(bool(value)),
        SETTING_GLOW_INTENSITY: func(value): _visual_effects.set_glow_settings(float(value), _settings.get_float(SETTING_GLOW_STRENGTH, 1.3), _settings.get_float(SETTING_GLOW_BLOOM, 0.2), _settings.get_float(SETTING_GLOW_SENSITIVITY, 0.8)),
        SETTING_GLOW_STRENGTH: func(value): _visual_effects.set_glow_settings(_settings.get_float(SETTING_GLOW_INTENSITY, 2.0), float(value), _settings.get_float(SETTING_GLOW_BLOOM, 0.2), _settings.get_float(SETTING_GLOW_SENSITIVITY, 0.8)),
        SETTING_GLOW_BLOOM: func(value): _visual_effects.set_glow_settings(_settings.get_float(SETTING_GLOW_INTENSITY, 2.0), _settings.get_float(SETTING_GLOW_STRENGTH, 1.3), float(value), _settings.get_float(SETTING_GLOW_SENSITIVITY, 0.8)),
        SETTING_GLOW_SENSITIVITY: func(value): _visual_effects.set_glow_settings(_settings.get_float(SETTING_GLOW_INTENSITY, 2.0), _settings.get_float(SETTING_GLOW_STRENGTH, 1.3), _settings.get_float(SETTING_GLOW_BLOOM, 0.2), float(value)),
        SETTING_UI_OPACITY: func(value): _visual_effects.set_ui_opacity(float(value)),
        SETTING_HIGHLIGHT_DISCONNECTED_ENABLED: func(value): _disconnected_highlight.set_enabled(bool(value)),
        SETTING_HIGHLIGHT_DISCONNECTED_STYLE: func(value): _disconnected_highlight.set_style(str(value)),
        SETTING_HIGHLIGHT_DISCONNECTED_INTENSITY: func(value): _disconnected_highlight.set_intensity(float(value)),
        SETTING_GROUP_PATTERNS_ENABLED: func(value): _group_patterns.set_enabled(bool(value)),
        SETTING_GROUP_COLOR_PICKER_ENABLED: func(value): _group_patterns.set_color_picker_enabled(bool(value))
    }


func _apply_initial_settings() -> void:
    if _settings == null:
        return
    for key in SETTINGS_KEYS:
        _apply_setting(key, _settings.get_value(key))


func _apply_setting(key: String, value: Variant) -> void:
    if _setting_handlers.has(key):
        var handler: Callable = _setting_handlers[key]
        if handler.is_valid():
            handler.call(value)
    if _setting_ui_updaters.has(key):
        var updater: Callable = _setting_ui_updaters[key]
        if updater.is_valid():
            updater.call(value)


func _register_events() -> void:
    if _settings != null and not _settings.value_changed.is_connected(_on_setting_changed):
        _settings.value_changed.connect(_on_setting_changed)
    if _core.event_bus != null:
        _core.event_bus.on("game.hud_ready", Callable(self, "_on_hud_ready"), self, true)
        _core.event_bus.on("game.desktop_ready", Callable(self, "_on_desktop_ready"), self, true)
        _core.event_bus.on("command_palette.ready", Callable(self, "_on_palette_ready"), self, true)
    if get_tree() != null and not get_tree().node_added.is_connected(_on_node_added):
        get_tree().node_added.connect(_on_node_added)
    call_deferred("_check_existing_hud")


func _check_existing_hud() -> void:
    if _hud_ready:
        return
    var root = get_tree().root if get_tree() != null else null
    if root == null:
        return
    var hud = root.get_node_or_null("Main/HUD")
    if hud != null:
        _on_hud_ready({})


func _on_desktop_ready(_payload: Dictionary) -> void:
    if _wire_colors != null and _settings != null:
        _wire_colors.set_custom_hex(_settings.get_dict(SETTING_WIRE_COLORS_HEX, {}))
        _wire_colors.set_enabled(_settings.get_bool(SETTING_WIRE_COLORS_ENABLED, true))
        _wire_colors.refresh_original_colors()
    if _visual_effects != null:
        _visual_effects.apply_all()
    if _group_patterns != null and _settings != null:
        _group_patterns.set_enabled(_settings.get_bool(SETTING_GROUP_PATTERNS_ENABLED, true))
        _group_patterns.set_color_picker_enabled(_settings.get_bool(SETTING_GROUP_COLOR_PICKER_ENABLED, true))


func _on_node_added(_node: Node) -> void:
    pass


func _on_hud_ready(_payload: Dictionary) -> void:
    if _hud_ready:
        return
    _hud_ready = true
    _ui_manager = _core.ui_manager if _core != null else null
    if _notification_history != null:
        _notification_history.on_hud_ready()
    if _visual_effects != null:
        _visual_effects.apply_all()


func _ensure_settings_tab() -> void:
    if _settings_ui_built:
        return
    if _core == null or _core.ui_manager == null:
        return
    _settings_tab = _core.get_settings_tab(MOD_ID)
    if _settings_tab == null:
        _settings_tab = _core.register_settings_tab(MOD_ID, "Taj's QoL", "res://mods-unpacked/TajemnikTV-Core/textures/icons/Align-Stroke-To-Center.png")
    if _settings_tab != null:
        _build_settings_ui(_settings_tab)
        _settings_ui_built = true
    elif _settings_retry_count < 3:
        _settings_retry_count += 1
        call_deferred("_ensure_settings_tab")


func _register_keybinds() -> void:
    if _core.keybinds == null:
        return
    _core.keybinds.register_keybind_category(KEYBIND_CATEGORY_ID, "Taj's QoL", "res://textures/icons/puzzle.png")
    var select_event = _core.keybinds.make_key_event(KEY_A, true)
    _core.keybinds.register_action_scoped(
        MOD_ID,
        "select_all",
        "Select All Nodes",
        [select_event],
        _core.keybinds.CONTEXT_GAMEPLAY,
        Callable(self, "_on_select_all"),
        0,
        KEYBIND_CATEGORY_ID
    )
    _core.keybinds.register_action_scoped(
        MOD_ID,
        "toggle_wire_drop",
        "Toggle Wire Drop Menu",
        [],
        _core.keybinds.CONTEXT_ANY,
        Callable(self, "_on_wire_drop_toggle"),
        0,
        KEYBIND_CATEGORY_ID
    )


func _register_commands() -> void:
    var registry = _core.commands if _core.commands != null else _core.command_registry
    if registry == null or _settings == null:
        return

    # Register the "Taj's QoL" category so it appears on the Command Palette home screen
    registry.register({
        "id": "cat_tajs_qol",
        "title": "Taj's QoL",
        "category_path": [],
        "keywords": ["qol", "tajs", "quality", "life", "features"],
        "hint": "Quality of Life features and toggles",
        "icon_path": "res://mods-unpacked/TajemnikTV-Core/textures/icons/Align-Stroke-To-Center.png",
        "is_category": true,
        "badge": "SAFE"
    })

    registry.register_command("tajs_qol.select_all", {
        "title": "Select All Nodes",
        "description": "Select all nodes on the desktop",
        "category_path": ["Taj's QoL"],
        "keywords": ["select", "all", "nodes"],
        "icon_path": "res://textures/icons/selection.png",
        "badge": "SAFE"
    }, Callable(self, "_on_select_all"))

    _register_toggle_command(registry, "tajs_qol.toggle_smart_select", "Smart Selection", SETTING_SMART_SELECT_ENABLED, true, "res://textures/icons/selection.png", ["ctrl", "select"])
    _register_toggle_command(registry, "tajs_qol.toggle_wire_clear", "Wire Clear", SETTING_WIRE_CLEAR_ENABLED, true, "res://textures/icons/wire.png", ["wire", "clear", "disconnect"])
    _register_toggle_command(registry, "tajs_qol.toggle_wire_drop", "Wire Drop Menu", SETTING_WIRE_DROP_ENABLED, true, "res://textures/icons/connections.png", ["wire", "drop", "menu", "spawn"])
    _register_toggle_command(registry, "tajs_qol.toggle_slider_scroll", "Disable Slider Scroll", SETTING_DISABLE_SLIDER_SCROLL, false, "res://textures/icons/chevron_down.png", ["slider", "scroll", "wheel"])
    _register_toggle_command(registry, "tajs_qol.toggle_focus_mute", "Focus Mute", SETTING_FOCUS_MUTE_ENABLED, true, "res://textures/icons/sound.png", ["audio", "mute", "focus"])
    _register_toggle_command(registry, "tajs_qol.toggle_notifications", "Notification History", SETTING_NOTIFICATION_HISTORY_ENABLED, true, "res://textures/icons/exclamation.png", ["toast", "log", "history"])
    _register_toggle_command(registry, "tajs_qol.toggle_controller_block", "Disable Controller Input", SETTING_CONTROLLER_BLOCK_ENABLED, false, "res://textures/icons/controller.png", ["controller", "gamepad", "input"])
    _register_toggle_command(registry, "tajs_qol.toggle_screenshots", "Screenshot Tools", SETTING_SCREENSHOT_ENABLED, true, "res://textures/icons/image.png", ["screenshot", "capture"])
    _register_toggle_command(registry, "tajs_qol.toggle_wire_colors", "Wire Colors", SETTING_WIRE_COLORS_ENABLED, true, "res://textures/icons/connections.png", ["wire", "color", "visual"])
    _register_toggle_command(registry, "tajs_qol.toggle_disconnected_highlight", "Disconnected Node Highlight", SETTING_HIGHLIGHT_DISCONNECTED_ENABLED, true, "res://textures/icons/eye_ball.png", ["highlight", "disconnected", "visual"])
    _register_toggle_command(registry, "tajs_qol.toggle_extra_glow", "Extra Glow", SETTING_GLOW_ENABLED, false, "res://textures/icons/eye_ball.png", ["glow", "bloom", "visual"])
    _register_toggle_command(registry, "tajs_qol.toggle_group_patterns", "Group Patterns", SETTING_GROUP_PATTERNS_ENABLED, true, "res://textures/icons/grid.png", ["group", "pattern", "visual"])

    registry.register_command("tajs_qol.goto_group", {
        "title": "Go To Group",
        "description": "Open the group picker to navigate to a node group",
        "category_path": ["Tools"],
        "keywords": ["goto", "go to", "group", "node", "navigate", "jump"],
        "icon_path": "res://textures/icons/crosshair.png",
        "badge": "SAFE",
        "keep_open": true
    }, Callable(self, "_on_goto_group"))

    # Register "Notes" subcategory under "Tools"
    registry.register({
        "id": "cat_tools_notes",
        "title": "Notes",
        "category_path": ["Tools"],
        "keywords": ["notes", "sticky", "memo"],
        "hint": "Sticky notes and annotations",
        "icon_path": "res://textures/icons/document.png",
        "is_category": true,
        "badge": "SAFE"
    })

    registry.register_command("tajs_qol.create_sticky_note", {
        "title": "Create Sticky Note",
        "description": "Create a new sticky note at camera center",
        "category_path": ["Tools", "Notes"],
        "keywords": ["note", "sticky", "create", "add"],
        "icon_path": "res://textures/icons/document.png",
        "badge": "SAFE"
    }, Callable(self, "_on_create_sticky_note"))

    registry.register_command("tajs_qol.goto_note", {
        "title": "Go To Note",
        "description": "Open the note picker to navigate to a sticky note",
        "category_path": ["Tools", "Notes"],
        "keywords": ["note", "sticky", "goto", "go to", "navigate", "jump"],
        "icon_path": "res://textures/icons/crosshair.png",
        "badge": "SAFE",
        "keep_open": true
    }, Callable(self, "_on_goto_note"))

    registry.register_command("tajs_qol.notifications.open", {
        "title": "Open Notification History",
        "description": "Open the toast history panel",
        "category_path": ["Taj's QoL", "Notifications"],
        "keywords": ["toast", "history", "open"],
        "icon_path": "res://textures/icons/exclamation.png",
        "badge": "SAFE",
        "can_run": func(_ctx): return _notification_history != null and _settings.get_bool(SETTING_NOTIFICATION_HISTORY_ENABLED, true)
    }, Callable(self, "_on_notification_open"))

    registry.register_command("tajs_qol.notifications.clear", {
        "title": "Clear Notification History",
        "description": "Clear stored toast history",
        "category_path": ["Taj's QoL", "Notifications"],
        "keywords": ["toast", "history", "clear"],
        "icon_path": "res://textures/icons/exclamation.png",
        "badge": "SAFE",
        "can_run": func(_ctx): return _notification_history != null and _settings.get_bool(SETTING_NOTIFICATION_HISTORY_ENABLED, true)
    }, Callable(self, "_on_notification_clear"))

    registry.register_command("tajs_qol.screenshot.full", {
        "title": "Take Screenshot",
        "description": "Capture a full desktop screenshot",
        "category_path": ["Taj's QoL", "Screenshots"],
        "keywords": ["screenshot", "capture", "full"],
        "icon_path": "res://textures/icons/image.png",
        "badge": "SAFE",
        "can_run": func(_ctx): return _screenshot != null and _settings.get_bool(SETTING_SCREENSHOT_ENABLED, true)
    }, Callable(self, "_on_screenshot_full"))

    registry.register_command("tajs_qol.screenshot.selection", {
        "title": "Screenshot: Capture Selection",
        "description": "Capture selected nodes only",
        "category_path": ["Taj's QoL", "Screenshots"],
        "keywords": ["screenshot", "selection", "nodes"],
        "icon_path": "res://textures/icons/image.png",
        "badge": "SAFE",
        "can_run": func(_ctx): return _screenshot != null and _settings.get_bool(SETTING_SCREENSHOT_ENABLED, true) and Globals != null and not Globals.selections.is_empty()
    }, Callable(self, "_on_screenshot_selection"))

    registry.register_command("tajs_qol.screenshot.folder", {
        "title": "Open Screenshot Folder",
        "description": "Open the screenshot folder in your file explorer",
        "category_path": ["Taj's QoL", "Screenshots"],
        "keywords": ["screenshot", "folder", "open"],
        "icon_path": "res://textures/icons/folder.png",
        "badge": "SAFE",
        "can_run": func(_ctx): return _screenshot != null
    }, Callable(self, "_on_screenshot_folder"))


func _register_toggle_command(registry, command_id: String, label: String, setting_key: String, default_value: bool, icon_path: String, keywords: Array) -> void:
    registry.register_command(command_id, {
        "title": label,
        "get_title": func(): return _format_toggle_title(label, setting_key, default_value),
        "description": "Toggle " + label,
        "category_path": ["Taj's QoL"],
        "keywords": keywords,
        "icon_path": icon_path,
        "badge": "SAFE"
    }, Callable(self, "_toggle_setting_command").bind(setting_key, default_value))


func _format_toggle_title(label: String, setting_key: String, default_value: bool) -> String:
    var enabled := default_value
    if _settings != null:
        enabled = _settings.get_bool(setting_key, default_value)
    return "%s [%s]" % [label, "ON" if enabled else "OFF"]


func _toggle_setting_command(_ctx, setting_key: String, default_value: bool) -> void:
    _toggle_setting(setting_key, default_value)


func _toggle_setting(setting_key: String, default_value: bool) -> bool:
    if _settings == null:
        return default_value
    var next: bool = not _settings.get_bool(setting_key, default_value)
    _settings.set_value(setting_key, next)
    return next


func _build_settings_ui(container: VBoxContainer) -> void:
    var ui = _ui_manager
    if ui == null or _settings == null:
        return

    ui.add_section_header(container, "Quality-of-Life")
    _bind_toggle(ui, container, "Smart Selection (Ctrl+A)", SETTING_SMART_SELECT_ENABLED, true, "Select all nodes on the desktop with Ctrl+A.")
    _bind_toggle(ui, container, "Right-click Wire Clear", SETTING_WIRE_CLEAR_ENABLED, true, "Right-click connectors to disconnect wires.")
    _bind_toggle(ui, container, "Wire Drop Menu", SETTING_WIRE_DROP_ENABLED, true, "Show a node picker when wires are dropped on empty canvas.")
    _bind_toggle(ui, container, "Disable Slider Scroll", SETTING_DISABLE_SLIDER_SCROLL, false, "Prevent mouse wheel from changing slider values.")

    _bind_toggle(ui, container, "Mute on Focus Loss", SETTING_FOCUS_MUTE_ENABLED, true, "Lower volume when the game loses focus.")
    var volume_slider = ui.add_slider(container, "Background Volume", _settings.get_float(SETTING_FOCUS_BG_VOLUME, 0.0), 0.0, 100.0, 5.0, "%", func(v):
        _settings.set_value(SETTING_FOCUS_BG_VOLUME, v)
    )
    _setting_ui_updaters[SETTING_FOCUS_BG_VOLUME] = func(value): volume_slider.value = float(value)

    _bind_toggle(ui, container, "Toast History Panel", SETTING_NOTIFICATION_HISTORY_ENABLED, true, "Show a notification history panel in the HUD.")
    var max_slider = ui.add_slider(container, "Toast History Length", _settings.get_int(SETTING_NOTIFICATION_HISTORY_MAX, 20), 5, 100, 5, "", func(v):
        _settings.set_value(SETTING_NOTIFICATION_HISTORY_MAX, int(v))
    )
    _setting_ui_updaters[SETTING_NOTIFICATION_HISTORY_MAX] = func(value): max_slider.value = int(value)

    _bind_toggle(ui, container, "Disable Controller Input", SETTING_CONTROLLER_BLOCK_ENABLED, false, "Block all controller/joypad input.")

    ui.add_separator(container)
    ui.add_section_header(container, "Breach Threat")

    _bind_toggle(ui, container, "Auto Threat Adjustment", SETTING_BREACH_ESCALATION_ENABLED, true, "Automatically adjust breach threat level based on consecutive successes/failures.")
    var escalation_slider = ui.add_slider(container, "Escalation Threshold (Successes)", _settings.get_int(SETTING_BREACH_ESCALATION_THRESHOLD, 3), 1, 15, 1, "", func(v):
        _settings.set_value(SETTING_BREACH_ESCALATION_THRESHOLD, int(v))
    )
    _setting_ui_updaters[SETTING_BREACH_ESCALATION_THRESHOLD] = func(value): escalation_slider.value = int(value)

    _bind_toggle(ui, container, "Auto De-escalation", SETTING_BREACH_DEESCALATION_ENABLED, true, "Reduce threat level after consecutive failed breaches.")
    var deesc_slider = ui.add_slider(container, "De-escalation Threshold (Failures)", _settings.get_int(SETTING_BREACH_DEESCALATION_THRESHOLD, 5), 1, 15, 1, "", func(v):
        _settings.set_value(SETTING_BREACH_DEESCALATION_THRESHOLD, int(v))
    )
    _setting_ui_updaters[SETTING_BREACH_DEESCALATION_THRESHOLD] = func(value): deesc_slider.value = int(value)

    var cooldown_slider = ui.add_slider(container, "Escalation Cooldown (Successes)", _settings.get_int(SETTING_BREACH_ESCALATION_COOLDOWN, 10), 0, 30, 1, "", func(v):
        _settings.set_value(SETTING_BREACH_ESCALATION_COOLDOWN, int(v))
    )
    _setting_ui_updaters[SETTING_BREACH_ESCALATION_COOLDOWN] = func(value): cooldown_slider.value = int(value)

    ui.add_separator(container)
    ui.add_section_header(container, "Visuals")

    _bind_toggle(ui, container, "Wire Color Overrides", SETTING_WIRE_COLORS_ENABLED, true, "Enable custom wire colors per resource.")
    var wire_section = ui.add_collapsible_section(container, "Wire Colors", false)
    if wire_section and _wire_colors != null:
        var wire_defs = _wire_colors.get_configurable_wires()
        for resource_id in wire_defs:
            var label = wire_defs[resource_id]
            var row = HBoxContainer.new()
            row.add_theme_constant_override("separation", 10)
            wire_section.add_child(row)

            var name_label = Label.new()
            name_label.text = label
            name_label.add_theme_font_size_override("font_size", 24)
            name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
            row.add_child(name_label)

            var color_btn = Button.new()
            color_btn.custom_minimum_size = Vector2(90, 36)
            color_btn.focus_mode = Control.FOCUS_NONE

            var style = StyleBoxFlat.new()
            style.bg_color = _wire_colors.get_color(resource_id)
            style.border_width_left = 2
            style.border_width_top = 2
            style.border_width_right = 2
            style.border_width_bottom = 2
            style.border_color = Color(0.3, 0.3, 0.3)
            style.set_corner_radius_all(4)
            color_btn.add_theme_stylebox_override("normal", style)
            color_btn.add_theme_stylebox_override("hover", style)
            color_btn.add_theme_stylebox_override("pressed", style)

            var res_id = resource_id
            color_btn.pressed.connect(func():
                _open_color_picker(style.bg_color, func(new_col: Color):
                    var data = _settings.get_dict(SETTING_WIRE_COLORS_HEX, {})
                    data[res_id] = new_col.to_html(false)
                    _settings.set_value(SETTING_WIRE_COLORS_HEX, data)
                    style.bg_color = new_col
                )
            )
            row.add_child(color_btn)

            var reset_btn = Button.new()
            reset_btn.text = "Reset"
            reset_btn.custom_minimum_size = Vector2(70, 36)
            reset_btn.focus_mode = Control.FOCUS_NONE
            reset_btn.pressed.connect(func():
                var data = _settings.get_dict(SETTING_WIRE_COLORS_HEX, {})
                data.erase(res_id)
                _settings.set_value(SETTING_WIRE_COLORS_HEX, data)
                style.bg_color = _wire_colors.get_original_color(res_id)
            )
            row.add_child(reset_btn)

            _wire_color_buttons[resource_id] = {"style": style, "button": color_btn}

        ui.add_button(wire_section, "Reset Wire Colors", func():
            _settings.set_value(SETTING_WIRE_COLORS_HEX, {})
        )
        _setting_ui_updaters[SETTING_WIRE_COLORS_HEX] = func(_value):
            for wire_id in _wire_color_buttons:
                var entry: Dictionary = _wire_color_buttons[wire_id]
                var style: StyleBoxFlat = entry.get("style", null)
                var btn: Button = entry.get("button", null)
                var color = _wire_colors.get_color(wire_id)
                if style:
                    style.bg_color = color
                if btn and is_instance_valid(btn):
                    btn.queue_redraw()

    var highlight_section = ui.add_collapsible_section(container, "Disconnected Node Highlight", false)
    _bind_toggle(ui, highlight_section, "Enable Highlighting", SETTING_HIGHLIGHT_DISCONNECTED_ENABLED, true, "Highlight windows that are not connected to the main graph.")
    var style_value = _settings.get_string(SETTING_HIGHLIGHT_DISCONNECTED_STYLE, "pulse")
    var style_selected = 1 if style_value == "outline" else 0
    var style_dropdown = ui.add_dropdown(highlight_section, "Highlight Style", ["Pulse Tint", "Outline Tint"], style_selected, func(idx):
        var next_style = "outline" if idx == 1 else "pulse"
        _settings.set_value(SETTING_HIGHLIGHT_DISCONNECTED_STYLE, next_style)
    )
    _setting_ui_updaters[SETTING_HIGHLIGHT_DISCONNECTED_STYLE] = func(value):
        var selected = 1 if str(value) == "outline" else 0
        style_dropdown.selected = selected
    var intensity_slider = ui.add_slider(highlight_section, "Intensity", _settings.get_float(SETTING_HIGHLIGHT_DISCONNECTED_INTENSITY, 0.5) * 100.0, 0.0, 100.0, 5.0, "%", func(v):
        _settings.set_value(SETTING_HIGHLIGHT_DISCONNECTED_INTENSITY, v / 100.0)
    )
    _setting_ui_updaters[SETTING_HIGHLIGHT_DISCONNECTED_INTENSITY] = func(value):
        intensity_slider.value = float(value) * 100.0

    var glow_container = ui.add_collapsible_section(container, "Extra Glow", false)
    _bind_toggle(ui, glow_container, "Enable Extra Glow", SETTING_GLOW_ENABLED, false, "Boost glow/bloom intensity.")
    var glow_intensity = ui.add_slider(glow_container, "Intensity", _settings.get_float(SETTING_GLOW_INTENSITY, 2.0), 0.0, 5.0, 0.1, "x", func(v):
        _settings.set_value(SETTING_GLOW_INTENSITY, v)
    )
    var glow_strength = ui.add_slider(glow_container, "Strength", _settings.get_float(SETTING_GLOW_STRENGTH, 1.3), 0.5, 2.0, 0.05, "x", func(v):
        _settings.set_value(SETTING_GLOW_STRENGTH, v)
    )
    var glow_bloom = ui.add_slider(glow_container, "Bloom", _settings.get_float(SETTING_GLOW_BLOOM, 0.2), 0.0, 0.5, 0.05, "", func(v):
        _settings.set_value(SETTING_GLOW_BLOOM, v)
    )
    var glow_sensitivity = ui.add_slider(glow_container, "Sensitivity", _settings.get_float(SETTING_GLOW_SENSITIVITY, 0.8), 0.0, 1.0, 0.05, "", func(v):
        _settings.set_value(SETTING_GLOW_SENSITIVITY, v)
    )
    _setting_ui_updaters[SETTING_GLOW_INTENSITY] = func(value): glow_intensity.value = float(value)
    _setting_ui_updaters[SETTING_GLOW_STRENGTH] = func(value): glow_strength.value = float(value)
    _setting_ui_updaters[SETTING_GLOW_BLOOM] = func(value): glow_bloom.value = float(value)
    _setting_ui_updaters[SETTING_GLOW_SENSITIVITY] = func(value): glow_sensitivity.value = float(value)

    var opacity_slider = ui.add_slider(container, "UI Opacity", _settings.get_float(SETTING_UI_OPACITY, 100.0), 50.0, 100.0, 5.0, "%", func(v):
        _settings.set_value(SETTING_UI_OPACITY, v)
    )
    _setting_ui_updaters[SETTING_UI_OPACITY] = func(value): opacity_slider.value = float(value)

    _bind_toggle(ui, container, "Group Patterns & Colors", SETTING_GROUP_PATTERNS_ENABLED, true, "Enable custom group patterns and colors.")
    _bind_toggle(ui, container, "Group Custom Color Picker", SETTING_GROUP_COLOR_PICKER_ENABLED, true, "Enable custom color picker for group nodes.")

    ui.add_separator(container)
    ui.add_section_header(container, "Screenshots")
    _bind_toggle(ui, container, "Screenshot Tools", SETTING_SCREENSHOT_ENABLED, true, "Enable HQ/tiled screenshot tools.")

    var quality_options = ["Low (JPG)", "Medium (JPG)", "High (PNG)", "Original (PNG)"]
    _quality_dropdown = ui.add_dropdown(container, "Screenshot Quality", quality_options, _settings.get_int(SETTING_SCREENSHOT_QUALITY, 2), func(idx):
        _settings.set_value(SETTING_SCREENSHOT_QUALITY, idx)
    )
    _setting_ui_updaters[SETTING_SCREENSHOT_QUALITY] = func(value): _quality_dropdown.selected = clampi(int(value), 0, 3)

    _bind_toggle(ui, container, "Screenshot Watermark", SETTING_SCREENSHOT_WATERMARK, false, "Include a watermark on screenshots when available.")

    ui.add_button(container, "Take Full Screenshot", func(): _on_screenshot_full())
    ui.add_button(container, "Capture Selection", func(): _on_screenshot_selection())

    ui.add_section_header(container, "Screenshot Folder")
    _folder_label = Label.new()
    _folder_label.text = _screenshot.get_display_folder()
    _folder_label.add_theme_font_size_override("font_size", 14)
    _folder_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
    _folder_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    container.add_child(_folder_label)

    var folder_row = HBoxContainer.new()
    folder_row.add_theme_constant_override("separation", 8)
    container.add_child(folder_row)

    var open_btn = ui.create_button("Open Folder", func(): _on_screenshot_folder())
    folder_row.add_child(open_btn)

    var change_btn = ui.create_button("Change Folder", func():
        _screenshot.show_folder_dialog(func(dir: String):
            _settings.set_value(SETTING_SCREENSHOT_FOLDER, dir)
        )
    )
    folder_row.add_child(change_btn)

    _setting_ui_updaters[SETTING_SCREENSHOT_FOLDER] = func(_value):
        if _folder_label:
            _folder_label.text = _screenshot.get_display_folder()


func _on_create_sticky_note(_ctx = null) -> void:
    if _sticky_note_manager:
        _sticky_note_manager.create_note_at_camera_center()

func _on_goto_group(_ctx = null) -> void:
    if _goto_group_manager == null:
        _notify("exclamation", "Group manager not initialized")
        return
    var groups = _goto_group_manager.get_all_groups()
    if groups.is_empty():
        _notify("exclamation", "No groups on desktop")
        return
    var overlay = _get_palette_overlay()
    if overlay == null or not overlay.has_method("show_group_picker"):
        _notify("exclamation", "Command Palette not available")
        return
    _connect_palette_signals()
    overlay.show_group_picker(groups, _goto_group_manager)

func _on_goto_note(_ctx = null) -> void:
    if _sticky_note_manager == null:
        _notify("exclamation", "Sticky notes not initialized")
        return
    var notes = _sticky_note_manager.get_all_notes()
    if notes.is_empty():
        _notify("exclamation", "No notes on desktop")
        return
    var overlay = _get_palette_overlay()
    if overlay == null or not overlay.has_method("show_note_picker"):
        _notify("exclamation", "Command Palette not available")
        return
    _connect_palette_signals()
    overlay.show_note_picker(notes, _sticky_note_manager)

func _on_palette_ready(payload: Dictionary) -> void:
    _palette_controller = payload.get("controller", null)
    _palette_overlay = payload.get("overlay", null)
    _connect_palette_signals()

func _get_palette_overlay():
    if _palette_overlay != null and is_instance_valid(_palette_overlay):
        return _palette_overlay
    if _core != null:
        var overlay = _core.get("command_palette_overlay")
        if overlay != null and is_instance_valid(overlay):
            _palette_overlay = overlay
            _palette_controller = _core.get("command_palette_controller")
            _connect_palette_signals()
            return _palette_overlay
    return null

func _connect_palette_signals() -> void:
    if _palette_overlay == null or not is_instance_valid(_palette_overlay):
        return
    if _palette_overlay.has_signal("group_selected"):
        if not _palette_overlay.group_selected.is_connected(_on_palette_group_selected):
            _palette_overlay.group_selected.connect(_on_palette_group_selected)
    if _palette_overlay.has_signal("note_picker_selected"):
        if not _palette_overlay.note_picker_selected.is_connected(_on_palette_note_selected):
            _palette_overlay.note_picker_selected.connect(_on_palette_note_selected)

func _on_palette_group_selected(group) -> void:
    if _goto_group_manager != null:
        _goto_group_manager.navigate_to_group(group)

func _on_palette_note_selected(note) -> void:
    if _sticky_note_manager != null:
        _sticky_note_manager.navigate_to_note(note)

func _notify(icon: String, message: String) -> void:
    if _core != null and _core.has_method("notify"):
        _core.notify(icon, message)
        return
    var root = Engine.get_main_loop().root if Engine.get_main_loop() != null else null
    if root != null:
        var signals = root.get_node_or_null("Signals")
        if signals != null and signals.has_signal("notify"):
            signals.emit_signal("notify", icon, message)
            return
    print("%s %s" % [LOG_NAME, message])


func _bind_toggle(ui, container: VBoxContainer, label: String, setting_key: String, default_value: bool, tooltip: String) -> void:
    var current = _settings.get_bool(setting_key, default_value)
    var toggle = ui.add_toggle(container, label, current, func(v):
        _settings.set_value(setting_key, v)
    , tooltip)
    _setting_ui_updaters[setting_key] = func(value):
        if toggle and is_instance_valid(toggle):
            toggle.set_pressed_no_signal(bool(value))


func _on_setting_changed(key: String, value: Variant, _old_value: Variant) -> void:
    _apply_setting(key, value)


func _on_select_all() -> void:
    if _smart_select != null:
        _smart_select.select_all()

func _on_wire_drop_toggle() -> void:
    _toggle_setting(SETTING_WIRE_DROP_ENABLED, true)


func _on_notification_open() -> void:
    if _notification_history != null:
        _notification_history.open_panel()


func _on_notification_clear() -> void:
    if _notification_history != null:
        _notification_history.clear_panel()


func _on_screenshot_full() -> void:
    if _screenshot != null:
        _screenshot.take_screenshot()


func _on_screenshot_selection() -> void:
    if _screenshot != null:
        _screenshot.take_screenshot_selection()


func _on_screenshot_folder() -> void:
    if _screenshot != null:
        _screenshot.open_screenshot_folder()

func _change_screenshot_folder() -> void:
    if _screenshot == null or _settings == null:
        return
    _screenshot.show_folder_dialog(func(dir: String):
        _settings.set_value(SETTING_SCREENSHOT_FOLDER, dir)
    )

func _reset_wire_colors() -> void:
    if _settings == null:
        return
    _settings.set_value(SETTING_WIRE_COLORS_HEX, {})

func _get_wire_color(resource_id: String) -> Color:
    if _wire_colors != null:
        return _wire_colors.get_color(resource_id)
    return Color.WHITE

func _ensure_color_picker() -> void:
    if _color_picker_layer != null:
        return
    if get_tree() == null:
        return
    _color_picker_layer = CanvasLayer.new()
    _color_picker_layer.name = "QolColorPickerLayer"
    _color_picker_layer.layer = 120
    _color_picker_layer.visible = false

    var overlay := ColorRect.new()
    overlay.name = "ColorPickerOverlay"
    overlay.color = Color(0, 0, 0, 0.4)
    overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    overlay.mouse_filter = Control.MOUSE_FILTER_STOP
    overlay.gui_input.connect(func(event: InputEvent):
        if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
            _close_color_picker()
    )
    _color_picker_layer.add_child(overlay)

    _color_picker_panel = CoreColorPickerPanelScript.new()
    if _color_picker_panel.has_method("setup"):
        _color_picker_panel.call("setup", _settings, SETTING_COLOR_PICKER_DATA)
    _color_picker_panel.color_changed.connect(_on_color_picker_changed)
    _color_picker_panel.color_committed.connect(func(_c: Color):
        _close_color_picker()
    )
    _color_picker_layer.add_child(_color_picker_panel)
    get_tree().root.add_child(_color_picker_layer)


func _open_color_picker(start_color: Color, callback: Callable) -> void:
    if get_tree() == null:
        return
    _ensure_color_picker()
    if _color_picker_panel == null:
        return
    _color_picker_callback = callback
    if _color_picker_panel.has_method("set_color"):
        _color_picker_panel.call("set_color", start_color)
    _color_picker_layer.visible = true
    if _color_picker_panel is Control:
        var panel := _color_picker_panel as Control
        panel.position = (panel.get_viewport_rect().size - panel.size) / 2


func _close_color_picker() -> void:
    if _color_picker_layer:
        _color_picker_layer.visible = false
    _color_picker_callback = Callable()


func _on_color_picker_changed(color: Color) -> void:
    if _color_picker_callback != null and _color_picker_callback.is_valid():
        _color_picker_callback.call(color)


func _get_mod_version() -> String:
    var manifest_path = get_script().resource_path.get_base_dir().path_join("manifest.json")
    if FileAccess.file_exists(manifest_path):
        var file := FileAccess.open(manifest_path, FileAccess.READ)
        if file:
            var json := JSON.new()
            if json.parse(file.get_as_text()) == OK:
                var data = json.get_data()
                if data is Dictionary and data.has("version_number"):
                    return str(data["version_number"])
    return "0.1.0"


func get_mod_name() -> String:
    return "Taj's QoL"


func _log_warn(message: String) -> void:
    if _core != null and _core.has_method("logw"):
        _core.logw(MOD_ID, message)
    elif _has_global_class("ModLoaderLog"):
        ModLoaderLog.warning(message, LOG_NAME)
    else:
        print("%s %s" % [LOG_NAME, message])


static func _has_global_class(class_name_str: String) -> bool:
    for entry in ProjectSettings.get_global_class_list():
        if entry.get("class", "") == class_name_str:
            return true
    return false
