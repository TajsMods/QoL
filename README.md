# Taj's QoL

Quality-of-life utilities for Upload Labs, refactored to use Taj's Core services.

## Features Included

- Smart Selection (Ctrl+A) with "no text input" guard
- Right-click Wire Clear on connectors
- Wire Drop Menu (drop wires on empty canvas to pick a compatible node)
- Disable Slider Scroll (prevents mouse wheel from changing sliders)
- Mute on Focus Loss with background volume slider
- Toast History panel with configurable length and clear button
- Disable Controller Input toggle
- Smart Screenshots (full board + selection capture, tiled/HQ)
- Visual tweaks: wire colors, extra glow/bloom, UI opacity, group patterns/colors, custom boot screen

## Commands and Keybinds

- Keybind: Ctrl+A (Select All Nodes)
- Command palette integration via Core command registry (screenshots, toggles, notification actions)

## Settings

- Settings are registered under Taj's Core > Mods > Taj's QoL
- Group pattern/color data is stored in mod config via Core (vanilla saves untouched)
- If TajemnikTV-WireDrop is active, QoL disables its built-in Wire Drop to avoid conflicts

## Dependencies

- Requires Taj's Core (TajemnikTV-Core) v1.0.0+
- No hard dependency on CommandPalette or WireDrop

## Excluded Features (from TajsModded)

These were intentionally left out to avoid overlaps, cheats, or gameplay tweaks.

- Command Palette and Palette autocomplete (handled by TajemnikTV-CommandPalette)
- Wire Drop menu (now included in Taj's QoL)
- Cheats panel, node limit changes, extended caps, and other progression changes
- Large tools that need heavy patching (undo/redo, sticky notes, bin, workspace expansion)

## Discovery Table (TajsModded -> QoL)

| Feature | Source in TajsModded | Category | Keep? | QoL location + Core APIs |
| --- | --- | --- | --- | --- |
| Smart Selection (Ctrl+A) | `mods-unpacked/mods disabled/TajemnikTV-TajsModded/extensions/scripts/keybinds/keybinds_registration.gd` + `mods-unpacked/mods disabled/TajemnikTV-TajsModded/extensions/scripts/desktop.gd` | QoL | Yes | `mods-unpacked/TajemnikTV-QoL/extensions/scripts/features/smart_select_feature.gd` (Core keybinds, commands, settings) |
| Right-click Wire Clear | `mods-unpacked/mods disabled/TajemnikTV-TajsModded/extensions/scripts/wire_drop/wire_clear_handler.gd` | QoL | Yes | `mods-unpacked/TajemnikTV-QoL/extensions/scripts/features/wire_clear_feature.gd` (Core settings) |
| Mute on Focus Loss | `mods-unpacked/mods disabled/TajemnikTV-TajsModded/extensions/scripts/utilities/focus_handler.gd` | QoL | Yes | `mods-unpacked/TajemnikTV-QoL/extensions/scripts/features/focus_mute_feature.gd` (Core settings) |
| Toast History | `mods-unpacked/mods disabled/TajemnikTV-TajsModded/extensions/scripts/ui/notification_log_panel.gd` | QoL | Yes | `mods-unpacked/TajemnikTV-QoL/extensions/scripts/features/notification_history_feature.gd` + `mods-unpacked/TajemnikTV-QoL/extensions/scripts/ui/notification_log_panel.gd` (Core UI, settings) |
| Disable Controller Input | `mods-unpacked/mods disabled/TajemnikTV-TajsModded/mod_main.gd` | QoL | Yes | `mods-unpacked/TajemnikTV-QoL/extensions/scripts/features/controller_block_feature.gd` (Core settings) |
| Smart Screenshots (full + selection) | `mods-unpacked/mods disabled/TajemnikTV-TajsModded/extensions/scripts/utilities/screenshot_manager.gd` | QoL | Yes | `mods-unpacked/TajemnikTV-QoL/extensions/scripts/features/screenshot_feature.gd` (Core settings, commands, UI) |
| Command Palette | `mods-unpacked/mods disabled/TajemnikTV-TajsModded/extensions/scripts/palette/*` | Tool/UI | No | Overlaps with TajemnikTV-CommandPalette |
| Palette Tab Autocomplete | `mods-unpacked/mods disabled/TajemnikTV-TajsModded/extensions/scripts/palette/palette_config.gd` | Tool/UI | No | Overlaps with TajemnikTV-CommandPalette |
| Wire Drop Menu | `mods-unpacked/mods disabled/TajemnikTV-TajsModded/extensions/scripts/wire_drop/*` | QoL | Yes | `mods-unpacked/TajemnikTV-QoL/extensions/scripts/features/wire_drop_feature.gd` + `mods-unpacked/TajemnikTV-QoL/extensions/scripts/features/wire_drop/*` (Core settings, commands, keybinds) |
| Go To Group Button | `mods-unpacked/mods disabled/TajemnikTV-TajsModded/extensions/scripts/utilities/goto_group_manager.gd` | Tool | No | Out of QoL scope (could be its own tool mod) |
| Sticky Notes | `mods-unpacked/mods disabled/TajemnikTV-TajsModded/extensions/scripts/utilities/sticky_note_manager.gd` | Tool | No | Out of QoL scope (large UI/tooling) |
| Undo/Redo | `mods-unpacked/mods disabled/TajemnikTV-TajsModded/extensions/scripts/undo/*` | Tool | No | Heavy patching required; excluded for safety |
| Smooth Scrolling | `mods-unpacked/mods disabled/TajemnikTV-TajsModded/extensions/scripts/utilities/smooth_scroll_manager.gd` | QoL | No | Optional QoL; excluded to keep scope tight |
| Disable Slider Scroll | `mods-unpacked/mods disabled/TajemnikTV-TajsModded/mod_main.gd` | QoL | Yes | `mods-unpacked/TajemnikTV-QoL/extensions/scripts/features/slider_scroll_block_feature.gd` (Core settings) |
| Group Z-Order Fix | `mods-unpacked/mods disabled/TajemnikTV-TajsModded/extensions/scripts/utilities/node_group_z_order_fix.gd` | Visual | No | Visual tweak (out of QoL scope) |
| Disconnected Node Highlighter | `mods-unpacked/mods disabled/TajemnikTV-TajsModded/extensions/scripts/utilities/disconnected_node_highlighter.gd` | Visual | No | Visual-only |
| Wire Colors | `mods-unpacked/mods disabled/TajemnikTV-TajsModded/extensions/scripts/utilities/wire_color_overrides.gd` | Visual | Yes | `mods-unpacked/TajemnikTV-QoL/extensions/scripts/features/wire_colors_feature.gd` (Core settings + UI) |
| Group Node Patterns | `mods-unpacked/mods disabled/TajemnikTV-TajsModded/extensions/scripts/ui/pattern_*` + `mods-unpacked/mods disabled/TajemnikTV-TajsModded/extensions/scenes/windows/window_group.gd` | Visual | Yes | `mods-unpacked/TajemnikTV-QoL/extensions/scenes/windows/window_group.gd` + `mods-unpacked/TajemnikTV-QoL/extensions/scripts/ui/pattern_*` (Core settings) |
| UI Opacity | `mods-unpacked/mods disabled/TajemnikTV-TajsModded/mod_settings.gd` | Visual | Yes | `mods-unpacked/TajemnikTV-QoL/extensions/scripts/features/visual_effects_feature.gd` (Core settings) |
| Extra Glow/Bloom | `mods-unpacked/mods disabled/TajemnikTV-TajsModded/mod_settings.gd` | Visual | Yes | `mods-unpacked/TajemnikTV-QoL/extensions/scripts/features/visual_effects_feature.gd` (Core settings) |
| Custom Boot Screen | `mods-unpacked/mods disabled/TajemnikTV-TajsModded/mod_main.gd` | Visual | Yes | `mods-unpacked/TajemnikTV-QoL/extensions/scripts/features/boot_screen_feature.gd` (Core settings) |
| The Bin (trash node) | `mods-unpacked/mods disabled/TajemnikTV-TajsModded/extensions/scenes/windows/window_bin.gd` | Tool | No | Tooling feature; excluded |
| 6-Input Containers | `mods-unpacked/mods disabled/TajemnikTV-TajsModded/extensions/scenes/windows/window_inventory.gd` | Gameplay tweak | No | Progression/balance impact |
| Buy Max Button | `mods-unpacked/mods disabled/TajemnikTV-TajsModded/extensions/scripts/utilities/buy_max_manager.gd` | Gameplay tweak | No | Progression/balance impact |
| Upgrade Multiplier / Modifier Keys | `mods-unpacked/mods disabled/TajemnikTV-TajsModded/extensions/scripts/utilities/upgrade_manager.gd` | Gameplay tweak | No | Progression/balance impact |
| Node Limit Control | `mods-unpacked/mods disabled/TajemnikTV-TajsModded/mod_main.gd` | Cheat | No | Explicitly excluded |
| Cheats Panel | `mods-unpacked/mods disabled/TajemnikTV-TajsModded/extensions/scripts/utilities/cheat_manager.gd` | Cheat | No | Explicitly excluded |
| Breach Threat Escalation | `mods-unpacked/mods disabled/TajemnikTV-TajsModded/extensions/scripts/utilities/breach_threat_manager.gd` | Gameplay tweak | No | Progression/balance impact |
| Expanded Workspace | `mods-unpacked/mods disabled/TajemnikTV-TajsModded/extensions/scripts/utilities/workspace_bounds.gd` | Gameplay tweak | No | Progression/balance impact |
| Extended Caps | `mods-unpacked/mods disabled/TajemnikTV-TajsModded/extensions/scripts/mechanics/extended_caps_manager.gd` | Gameplay tweak | No | Progression/balance impact |
| Workshop Sync / Mod Manager | `mods-unpacked/mods disabled/TajemnikTV-TajsModded/extensions/scripts/utilities/workshop_sync.gd` | Tool | No | Handled by Core services |
| Attribute Tweaker / Icon Browser / Rich Text Menu | `mods-unpacked/mods disabled/TajemnikTV-TajsModded/extensions/scripts/ui/*` | Tool/UI | No | UI helpers for excluded features |
