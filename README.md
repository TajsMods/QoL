# Taj's Mods: QoL

[![Ask DeepWiki](https://deepwiki.com/badge.svg)](https://deepwiki.com/TajsMods/QoL)

Quality-of-life utilities for Upload Labs.

## Features Included

- Smart Selection (Ctrl+A)
- Right-click Wire Clear on connectors
- Wire Drop Menu (drop wires on empty canvas to pick a compatible node)
- Disable Slider Scroll (prevents mouse wheel from changing sliders)
- Extra input slots for Inventory/Bin windows (disabled by default)
- Mute on Focus Loss with background volume slider
- Toast History panel with configurable length, clear button, category filters, unread tracking, and actionable inbox items (dismiss/snooze/custom actions)
- Disable Controller Input toggle
- Lock Group Nodes (prevents moving/resizing group windows)
- Find Anything board search/jump (nodes, groups, sticky notes, disconnected/problem nodes)
- Camera Bookmarks / Workspace Waypoints (named camera position + zoom bookmarks with jump/cycle/quick slots)
- Smart Screenshots (full board + selection capture, tiled/HQ)
- Visual tweaks: wire colors, disconnected node highlight, extra glow/bloom, UI opacity, group patterns/colors, custom boot screen
- Detached Schematics Browser window (viewport-safe modal for the new browser UI, with legacy browser fallback in the in-menu tab)

## Find Anything

- Action id: `TajemnikTV-QoL.find_anything`
- Command alias: `tajs_qol.find_anything`
- Default hotkey: `Ctrl+K` (configurable through Core Keybinds)

## Camera Bookmarks

- Action ids:
  - `TajemnikTV-QoL.bookmarks_panel`
  - `TajemnikTV-QoL.bookmarks_save_current`
  - `TajemnikTV-QoL.bookmarks_next`
  - `TajemnikTV-QoL.bookmarks_previous`
- Commands:
  - `tajs_qol.bookmarks.panel`
  - `tajs_qol.bookmarks.save_current`
  - `tajs_qol.bookmarks.next`
  - `tajs_qol.bookmarks.previous`
- Default hotkeys:
  - `Ctrl+B` toggle panel
  - `Ctrl+Shift+B` save current camera bookmark
  - `[` previous bookmark
  - `]` next bookmark
  - `Alt+1..9` jump quick slots

## Dependencies

- Requires Taj's Core (TajemnikTV-Core) v1.0.0+
