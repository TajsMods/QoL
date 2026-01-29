[![Ask DeepWiki](https://deepwiki.com/badge.svg)](https://deepwiki.com/TajsMods/QoL)

# Taj's QoL

Quality-of-life utilities for Upload Labs, refactored to use Taj's Core services.

## Features Included

- Smart Selection (Ctrl+A) with "no text input" guard
- Right-click Wire Clear on connectors
- Wire Drop Menu (drop wires on empty canvas to pick a compatible node)
- Disable Slider Scroll (prevents mouse wheel from changing sliders)
- Extra input slots for Inventory/Bin windows (disabled by default)
- Mute on Focus Loss with background volume slider
- Toast History panel with configurable length and clear button
- Disable Controller Input toggle
- Breach threat auto-adjustment (auto up/down with cooldown)
- Lock Group Nodes (prevents moving/resizing group windows)
- Smart Screenshots (full board + selection capture, tiled/HQ)
- Visual tweaks: wire colors, disconnected node highlight, extra glow/bloom, UI opacity, group patterns/colors, custom boot screen

## Commands and Keybinds

- Keybind: Ctrl+A (Select All Nodes)
- Command palette integration via Core command registry (screenshots, toggles, notification actions)

## Settings

- Settings are registered under Taj's Core > Mods > Taj's QoL
- Group pattern/color data is stored in mod config via Core (vanilla saves untouched)
- If TajemnikTV-WireDrop is active, QoL disables its built-in Wire Drop to avoid conflicts
- Group custom color picker is optional and can be toggled in settings

## Dependencies

- Requires Taj's Core (TajemnikTV-Core) v1.0.0+
