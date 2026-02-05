class_name TajsQoLSchematicsMenu
extends "res://scripts/schematics_menu.gd"

const MetadataStoreScript = preload("res://mods-unpacked/TajemnikTV-QoL/extensions/scripts/schematic_library/metadata_store.gd")
const SchematicListRowScript = preload("res://mods-unpacked/TajemnikTV-QoL/extensions/scripts/schematic_library/ui/schematic_list_row.gd")
const StatusBadgeScript = preload("res://mods-unpacked/TajemnikTV-QoL/extensions/scripts/schematic_library/ui/status_badge.gd")
const TagChipScript = preload("res://mods-unpacked/TajemnikTV-QoL/extensions/scripts/schematic_library/ui/tag_chip.gd")
const ToggleSwitchScript = preload("res://mods-unpacked/TajemnikTV-QoL/extensions/scripts/schematic_library/ui/toggle_switch.gd")
const IconPickerPopupScript = preload("res://mods-unpacked/TajemnikTV-QoL/extensions/scripts/ui/icon_picker_popup.gd")

const LEGACY_SETTING_KEY := "tajs_qol.schematic_legacy_view"
const DEFAULT_ICON_PATH := "res://textures/icons/blueprint.png"
const SEARCH_ICON_PATH := "res://textures/icons/magnifying_glass.png"
const STATUS_OPTIONS := ["WIP", "OK", "Meme", "Meta"]
const SORT_OPTIONS := ["Name (A-Z)", "Name (Z-A)", "Modified (Newest)", "Node Count (High)"]
const UNCATEGORIZED := "Uncategorized"
const ALL_CATEGORIES := "All"

var _metadata_store
var _settings

var _legacy_container: Control
var _root_margin: MarginContainer
var _toolbar_left: HBoxContainer
var _custom_body: HBoxContainer
var _legacy_switch
var _search_wrap: PanelContainer
var _search_input: LineEdit
var _sort_dropdown: OptionButton
var _result_count: Label
var _clear_filters_button: Button

var _category_list: VBoxContainer
var _category_create_input: LineEdit
var _category_delete_button: Button
var _selected_tags_flow: HFlowContainer
var _tag_pool_flow: HFlowContainer
var _tag_empty_label: Label
var _tags_add_prompt_button: Button

var _list_rows: VBoxContainer
var _list_rows_scroll: ScrollContainer
var _row_nodes: Dictionary = {}

var _detail_name: Label
var _detail_badge
var _detail_category_chips: HFlowContainer
var _detail_preview: TextureRect
var _detail_stats: Label
var _detail_types: Label
var _detail_warning: Label
var _detail_tags_flow: HFlowContainer
var _add_tag_button: Button
var _add_tag_input: LineEdit
var _detail_category_select: OptionButton
var _detail_desc: TextEdit
var _detail_notes: TextEdit
var _detail_status: OptionButton

var _place_button: Button
var _duplicate_button: Button
var _export_button: Button
var _edit_button: Button
var _delete_button: Button

var _edit_dialog: AcceptDialog
var _edit_name_input: LineEdit
var _edit_icon_button: Button
var _edit_icon_preview: TextureRect
var _edit_icon_id: String = "blueprint"

var _selected_name: String = ""
var _visible_names: Array[String] = []
var _selected_category: String = ALL_CATEGORIES
var _selected_tags: Array[String] = []
var _all_tags: Array[String] = []
var _meta_cache: Dictionary = {}
var _library_categories: Array[String] = []
var _legacy_enabled: bool = false
var _suppress_detail_events: bool = false


func _ready() -> void:
    super._ready()
    _legacy_container = $MarginContainer
    _metadata_store = MetadataStoreScript.new()
    var core = Engine.get_meta("TajsCore", null)
    if core != null and core.has_method("get"):
        _settings = core.get("settings")

    _build_ui()
    _sync_legacy_setting()
    _apply_legacy_mode()
    _apply_layout()
    _bring_to_front()
    _refresh_library()

    var viewport := get_viewport()
    if viewport != null and not viewport.size_changed.is_connected(_on_viewport_resized):
        viewport.size_changed.connect(_on_viewport_resized)
    if _settings != null and _settings.has_signal("value_changed") and not _settings.value_changed.is_connected(_on_setting_changed):
        _settings.value_changed.connect(_on_setting_changed)


func toggle(toggle_on: bool) -> void:
    open = toggle_on
    if toggle_on:
        visible = true
        modulate.a = 1.0
        _bring_to_front()
        _apply_layout()
        _refresh_library()
        if not _legacy_enabled:
            call_deferred("_focus_search")
    else:
        visible = false


func _unhandled_key_input(event: InputEvent) -> void:
    if not open or not visible:
        return
    if not (event is InputEventKey) or not event.pressed:
        return

    var key := event as InputEventKey
    if key.ctrl_pressed and key.keycode == KEY_F and not _legacy_enabled:
        _focus_search()
        get_viewport().set_input_as_handled()
        return
    if key.keycode == KEY_ESCAPE:
        _close_panel()
        get_viewport().set_input_as_handled()
        return
    if _legacy_enabled:
        return
    if _is_text_focus_active() and key.keycode != KEY_BACKSPACE:
        return
    if _add_tag_input != null and _add_tag_input.has_focus() and key.keycode == KEY_BACKSPACE and _add_tag_input.text.strip_edges() == "":
        _remove_last_tag()
        get_viewport().set_input_as_handled()
        return
    if key.keycode == KEY_UP:
        _select_relative(-1)
        get_viewport().set_input_as_handled()
    elif key.keycode == KEY_DOWN:
        _select_relative(1)
        get_viewport().set_input_as_handled()
    elif key.keycode == KEY_ENTER or key.keycode == KEY_KP_ENTER:
        _on_place_pressed()
        get_viewport().set_input_as_handled()


func _on_new_schematic(schematic: String) -> void:
    super._on_new_schematic(schematic)
    if Data.schematics.has(schematic):
        _meta_cache[schematic] = _metadata_store.ensure_meta(schematic, Data.schematics[schematic])
    _refresh_library()


func _on_deleted_schematic(schematic: String) -> void:
    super._on_deleted_schematic(schematic)
    _meta_cache.erase(schematic)
    _metadata_store.delete_meta(schematic)
    if _selected_name == schematic:
        _selected_name = ""
    _refresh_library()


func _build_ui() -> void:
    _root_margin = MarginContainer.new()
    _root_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(_root_margin)

    var root := VBoxContainer.new()
    root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    root.size_flags_vertical = Control.SIZE_EXPAND_FILL
    root.add_theme_constant_override("separation", 10)
    _root_margin.add_child(root)

    var toolbar_panel := PanelContainer.new()
    _apply_panel_style(toolbar_panel)
    root.add_child(toolbar_panel)

    var toolbar := HBoxContainer.new()
    toolbar.add_theme_constant_override("separation", 8)
    toolbar_panel.add_child(toolbar)

    _toolbar_left = HBoxContainer.new()
    _toolbar_left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _toolbar_left.add_theme_constant_override("separation", 8)
    toolbar.add_child(_toolbar_left)

    _build_toolbar_left(_toolbar_left)
    _build_toolbar_right(toolbar)

    _custom_body = HBoxContainer.new()
    _custom_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _custom_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
    _custom_body.add_theme_constant_override("separation", 4)
    root.add_child(_custom_body)

    _build_filters_column()
    _build_library_column()
    _build_details_column()
    _build_edit_dialog()


func _build_toolbar_left(parent: HBoxContainer) -> void:
    _search_wrap = PanelContainer.new()
    _search_wrap.size_flags_horizontal = Control.SIZE_FILL
    _search_wrap.custom_minimum_size = Vector2(560, 0)
    _apply_field_style(_search_wrap)
    parent.add_child(_search_wrap)

    var search_row := HBoxContainer.new()
    search_row.add_theme_constant_override("separation", 6)
    _search_wrap.add_child(search_row)

    var search_icon := TextureRect.new()
    search_icon.custom_minimum_size = Vector2(18, 18)
    search_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    search_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    if ResourceLoader.exists(SEARCH_ICON_PATH):
        search_icon.texture = load(SEARCH_ICON_PATH)
    search_row.add_child(search_icon)

    _search_input = LineEdit.new()
    _search_input.placeholder_text = "Search schematics..."
    _search_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _search_input.custom_minimum_size = Vector2(420, 48)
    _search_input.clear_button_enabled = true
    _search_input.add_theme_font_size_override("font_size", 26)
    _search_input.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
    _search_input.text_changed.connect(_on_search_changed)
    search_row.add_child(_search_input)

    var hint := Label.new()
    hint.text = "Ctrl+F"
    hint.add_theme_font_size_override("font_size", 10)
    hint.add_theme_color_override("font_color", Color(0.66, 0.77, 0.89, 0.6))
    search_row.add_child(hint)

    var search_sort_gap := Control.new()
    search_sort_gap.custom_minimum_size = Vector2(10, 0)
    parent.add_child(search_sort_gap)

    var sort_label := Label.new()
    sort_label.text = "Sort by:"
    sort_label.add_theme_font_size_override("font_size", 24)
    parent.add_child(sort_label)

    _sort_dropdown = OptionButton.new()
    for option in SORT_OPTIONS:
        _sort_dropdown.add_item(option)
    _sort_dropdown.custom_minimum_size = Vector2(240, 48)
    _sort_dropdown.add_theme_font_size_override("font_size", 24)
    _sort_dropdown.item_selected.connect(_on_sort_changed)
    parent.add_child(_sort_dropdown)

    _result_count = Label.new()
    _result_count.add_theme_font_size_override("font_size", 16)
    _result_count.add_theme_color_override("font_color", Color(0.66, 0.77, 0.89, 1.0))
    parent.add_child(_result_count)


func _build_toolbar_right(parent: HBoxContainer) -> void:
    var right_wrap := HBoxContainer.new()
    right_wrap.add_theme_constant_override("separation", 8)
    parent.add_child(right_wrap)

    var import_btn := Button.new()
    import_btn.text = "Import"
    import_btn.focus_mode = Control.FOCUS_NONE
    import_btn.custom_minimum_size = Vector2(112, 48)
    import_btn.add_theme_font_size_override("font_size", 24)
    import_btn.pressed.connect(_on_import_button_pressed)
    right_wrap.add_child(import_btn)

    var refresh_btn := Button.new()
    refresh_btn.text = "Refresh"
    refresh_btn.focus_mode = Control.FOCUS_NONE
    refresh_btn.custom_minimum_size = Vector2(120, 48)
    refresh_btn.add_theme_font_size_override("font_size", 24)
    refresh_btn.pressed.connect(_refresh_library)
    right_wrap.add_child(refresh_btn)

    _legacy_switch = ToggleSwitchScript.new("Legacy View", false)
    _legacy_switch.toggled.connect(_on_legacy_toggled)
    right_wrap.add_child(_legacy_switch)

    var close_btn := Button.new()
    close_btn.text = "X"
    close_btn.focus_mode = Control.FOCUS_NONE
    close_btn.custom_minimum_size = Vector2(38, 38)
    close_btn.pressed.connect(_close_panel)
    right_wrap.add_child(close_btn)

func _build_filters_column() -> void:
    var panel := PanelContainer.new()
    panel.custom_minimum_size = Vector2(300, 0)
    panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
    _apply_panel_style(panel)
    _custom_body.add_child(panel)

    var box := VBoxContainer.new()
    box.size_flags_vertical = Control.SIZE_EXPAND_FILL
    box.add_theme_constant_override("separation", 8)
    panel.add_child(box)

    var filters_head := HBoxContainer.new()
    filters_head.add_theme_constant_override("separation", 8)
    box.add_child(filters_head)

    var filters_title := _build_section_title("FILTERS")
    filters_head.add_child(filters_title)

    var filters_spacer := Control.new()
    filters_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    filters_head.add_child(filters_spacer)

    _clear_filters_button = Button.new()
    _clear_filters_button.text = "Clear"
    _clear_filters_button.visible = false
    _clear_filters_button.focus_mode = Control.FOCUS_NONE
    _clear_filters_button.custom_minimum_size = Vector2(78, 34)
    _clear_filters_button.add_theme_font_size_override("font_size", 16)
    _clear_filters_button.pressed.connect(_on_clear_filters_pressed)
    filters_head.add_child(_clear_filters_button)

    box.add_child(_build_section_divider())

    var category_head := HBoxContainer.new()
    box.add_child(category_head)

    var category_label := Label.new()
    category_label.text = "CATEGORIES"
    category_label.add_theme_font_size_override("font_size", 24)
    category_label.add_theme_color_override("font_color", Color(0.86, 0.93, 1.0, 1.0))
    category_head.add_child(category_label)

    var category_actions_row := HBoxContainer.new()
    category_actions_row.add_theme_constant_override("separation", 6)
    box.add_child(category_actions_row)

    var add_category_btn := Button.new()
    add_category_btn.text = "+ New"
    add_category_btn.focus_mode = Control.FOCUS_NONE
    add_category_btn.custom_minimum_size = Vector2(88, 42)
    add_category_btn.add_theme_font_size_override("font_size", 24)
    add_category_btn.pressed.connect(_on_start_new_category)
    category_actions_row.add_child(add_category_btn)

    _category_delete_button = Button.new()
    _category_delete_button.text = "- Del"
    _category_delete_button.focus_mode = Control.FOCUS_NONE
    _category_delete_button.custom_minimum_size = Vector2(84, 42)
    _category_delete_button.add_theme_font_size_override("font_size", 24)
    _category_delete_button.pressed.connect(_on_delete_selected_category_pressed)
    category_actions_row.add_child(_category_delete_button)

    _category_create_input = LineEdit.new()
    _category_create_input.visible = false
    _category_create_input.placeholder_text = "Category name"
    _category_create_input.custom_minimum_size = Vector2(0, 34)
    _category_create_input.text_submitted.connect(_on_new_category_submitted)
    _category_create_input.focus_exited.connect(func() -> void:
        _category_create_input.visible = false
    )
    box.add_child(_category_create_input)

    _category_list = VBoxContainer.new()
    _category_list.custom_minimum_size = Vector2(0, 272)
    _category_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _category_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
    _category_list.add_theme_constant_override("separation", 4)
    box.add_child(_category_list)

    box.add_child(_build_section_divider())

    var tags_label := Label.new()
    tags_label.text = "TAGS"
    tags_label.add_theme_font_size_override("font_size", 24)
    tags_label.add_theme_color_override("font_color", Color(0.86, 0.93, 1.0, 1.0))
    box.add_child(tags_label)

    _selected_tags_flow = HFlowContainer.new()
    _selected_tags_flow.add_theme_constant_override("h_separation", 6)
    _selected_tags_flow.add_theme_constant_override("v_separation", 6)
    box.add_child(_selected_tags_flow)

    _tag_pool_flow = HFlowContainer.new()
    _tag_pool_flow.add_theme_constant_override("h_separation", 6)
    _tag_pool_flow.add_theme_constant_override("v_separation", 6)
    box.add_child(_tag_pool_flow)

    _tag_empty_label = Label.new()
    _tag_empty_label.text = "No tags yet. Add tags in the Details panel."
    _tag_empty_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    _tag_empty_label.add_theme_font_size_override("font_size", 22)
    _tag_empty_label.add_theme_color_override("font_color", Color(0.66, 0.77, 0.89, 1.0))
    box.add_child(_tag_empty_label)

    _tags_add_prompt_button = Button.new()
    _tags_add_prompt_button.text = "Add tag"
    _tags_add_prompt_button.visible = false
    _tags_add_prompt_button.focus_mode = Control.FOCUS_NONE
    _tags_add_prompt_button.custom_minimum_size = Vector2(0, 42)
    _tags_add_prompt_button.add_theme_font_size_override("font_size", 22)
    _tags_add_prompt_button.pressed.connect(func() -> void:
        if _selected_name != "":
            _focus_tag_input()
    )
    box.add_child(_tags_add_prompt_button)

    var filler := Control.new()
    filler.size_flags_vertical = Control.SIZE_EXPAND_FILL
    box.add_child(filler)


func _build_library_column() -> void:
    var panel := PanelContainer.new()
    panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
    _apply_panel_style(panel)
    _custom_body.add_child(panel)

    var root := VBoxContainer.new()
    root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    root.size_flags_vertical = Control.SIZE_EXPAND_FILL
    root.add_theme_constant_override("separation", 6)
    panel.add_child(root)

    # Header row with title and view toggle buttons
    var header_row := HBoxContainer.new()
    header_row.add_theme_constant_override("separation", 8)
    root.add_child(header_row)

    header_row.add_child(_build_section_title("SCHEMATIC LIBRARY"))

    var header_spacer := Control.new()
    header_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    header_row.add_child(header_spacer)

    # View toggle buttons (list/grid)
    var view_list_btn := Button.new()
    view_list_btn.text = "≡"
    view_list_btn.focus_mode = Control.FOCUS_NONE
    view_list_btn.custom_minimum_size = Vector2(28, 28)
    view_list_btn.add_theme_font_size_override("font_size", 16)
    _apply_mini_button_style(view_list_btn, true)
    header_row.add_child(view_list_btn)

    var view_grid_btn := Button.new()
    view_grid_btn.text = "▦"
    view_grid_btn.focus_mode = Control.FOCUS_NONE
    view_grid_btn.custom_minimum_size = Vector2(28, 28)
    view_grid_btn.add_theme_font_size_override("font_size", 14)
    _apply_mini_button_style(view_grid_btn, false)
    header_row.add_child(view_grid_btn)

    _list_rows_scroll = ScrollContainer.new()
    _list_rows_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    _list_rows_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _list_rows_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    root.add_child(_list_rows_scroll)

    _list_rows = VBoxContainer.new()
    _list_rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _list_rows.add_theme_constant_override("separation", 6)
    _list_rows_scroll.add_child(_list_rows)


func _build_details_column() -> void:
    var panel := PanelContainer.new()
    panel.custom_minimum_size = Vector2(420, 0)
    panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
    _apply_panel_style(panel)
    _custom_body.add_child(panel)

    var panel_root := VBoxContainer.new()
    panel_root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    panel_root.size_flags_vertical = Control.SIZE_EXPAND_FILL
    panel_root.add_theme_constant_override("separation", 8)
    panel.add_child(panel_root)

    var scroll := ScrollContainer.new()
    scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    panel_root.add_child(scroll)

    var box := VBoxContainer.new()
    box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    box.add_theme_constant_override("separation", 6)
    scroll.add_child(box)

    # Category chips at the very top (like in the mock)
    _detail_category_chips = HFlowContainer.new()
    _detail_category_chips.add_theme_constant_override("h_separation", 6)
    _detail_category_chips.add_theme_constant_override("v_separation", 4)
    box.add_child(_detail_category_chips)

    var top := HBoxContainer.new()
    top.add_theme_constant_override("separation", 10)
    box.add_child(top)

    _detail_name = Label.new()
    _detail_name.text = "Select a schematic"
    _detail_name.add_theme_font_size_override("font_size", 34)
    _detail_name.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
    _detail_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _detail_name.clip_text = true
    _detail_name.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
    top.add_child(_detail_name)

    _detail_badge = StatusBadgeScript.new("WIP")
    top.add_child(_detail_badge)

    var preview_center := CenterContainer.new()
    box.add_child(preview_center)

    _detail_preview = TextureRect.new()
    _detail_preview.custom_minimum_size = Vector2(100, 100)
    _detail_preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    _detail_preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    if ResourceLoader.exists(DEFAULT_ICON_PATH):
        _detail_preview.texture = load(DEFAULT_ICON_PATH)
    preview_center.add_child(_detail_preview)

    _detail_stats = Label.new()
    _detail_stats.text = "Nodes: 0 | Resources: 0 | Links: 0"
    _detail_stats.add_theme_font_size_override("font_size", 26)
    _detail_stats.add_theme_color_override("font_color", Color(0.85, 0.92, 1.0, 1.0))
    box.add_child(_detail_stats)

    _detail_types = Label.new()
    _detail_types.text = "Top Types: -"
    _detail_types.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    _detail_types.add_theme_font_size_override("font_size", 24)
    _detail_types.add_theme_color_override("font_color", Color(0.70, 0.80, 0.90, 1.0))
    box.add_child(_detail_types)

    _detail_warning = Label.new()
    _detail_warning.visible = false
    _detail_warning.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    _detail_warning.add_theme_color_override("font_color", Color(1.0, 0.72, 0.3, 1.0))
    box.add_child(_detail_warning)

    box.add_child(_build_section_divider())
    box.add_child(_build_section_title("TAGS"))

    _detail_tags_flow = HFlowContainer.new()
    _detail_tags_flow.add_theme_constant_override("h_separation", 6)
    _detail_tags_flow.add_theme_constant_override("v_separation", 6)
    box.add_child(_detail_tags_flow)

    var add_tag_row := HBoxContainer.new()
    box.add_child(add_tag_row)

    _add_tag_button = Button.new()
    _add_tag_button.text = "+ Add Tag"
    _add_tag_button.focus_mode = Control.FOCUS_NONE
    _add_tag_button.custom_minimum_size = Vector2(0, 42)
    _add_tag_button.add_theme_font_size_override("font_size", 22)
    _add_tag_button.pressed.connect(func() -> void:
        _focus_tag_input()
    )
    add_tag_row.add_child(_add_tag_button)

    _add_tag_input = LineEdit.new()
    _add_tag_input.visible = false
    _add_tag_input.placeholder_text = "Tag name"
    _add_tag_input.custom_minimum_size = Vector2(0, 42)
    _add_tag_input.add_theme_font_size_override("font_size", 22)
    _add_tag_input.text_submitted.connect(_on_add_tag_submitted)
    _add_tag_input.focus_exited.connect(func() -> void:
        if _add_tag_input.text.strip_edges() == "":
            _add_tag_input.visible = false
            _add_tag_button.visible = true
    )
    add_tag_row.add_child(_add_tag_input)

    box.add_child(_build_section_divider())
    box.add_child(_build_section_title("CATEGORY"))

    var category_row := HBoxContainer.new()
    category_row.add_theme_constant_override("separation", 8)
    box.add_child(category_row)

    _detail_category_select = OptionButton.new()
    _detail_category_select.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _detail_category_select.custom_minimum_size = Vector2(0, 48)
    _detail_category_select.add_theme_font_size_override("font_size", 24)
    _detail_category_select.item_selected.connect(_on_detail_category_selected)
    category_row.add_child(_detail_category_select)

    box.add_child(_build_section_divider())

    box.add_child(_build_section_title("STATUS"))

    _detail_status = OptionButton.new()
    for option in STATUS_OPTIONS:
        _detail_status.add_item(option)
    _detail_status.item_selected.connect(_on_status_selected)
    _detail_status.custom_minimum_size = Vector2(0, 48)
    _detail_status.add_theme_font_size_override("font_size", 24)
    box.add_child(_detail_status)

    box.add_child(_build_section_divider())
    box.add_child(_build_section_title("DESCRIPTION"))

    _detail_desc = TextEdit.new()
    _detail_desc.custom_minimum_size = Vector2(0, 140)
    _detail_desc.size_flags_vertical = Control.SIZE_EXPAND_FILL
    _detail_desc.placeholder_text = "Add a description..."
    _detail_desc.add_theme_font_size_override("font_size", 24)
    _detail_desc.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
    _detail_desc.text_changed.connect(_on_desc_changed)
    box.add_child(_detail_desc)

    box.add_child(_build_section_divider())

    box.add_child(_build_section_title("PRIVATE NOTES"))

    _detail_notes = TextEdit.new()
    _detail_notes.custom_minimum_size = Vector2(0, 140)
    _detail_notes.size_flags_vertical = Control.SIZE_EXPAND_FILL
    _detail_notes.placeholder_text = "Add private notes..."
    _detail_notes.add_theme_font_size_override("font_size", 24)
    _detail_notes.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
    _detail_notes.text_changed.connect(_on_notes_changed)
    box.add_child(_detail_notes)

    var footer := VBoxContainer.new()
    footer.add_theme_constant_override("separation", 8)
    panel_root.add_child(footer)
    footer.add_child(_build_section_divider())

    _place_button = Button.new()
    _place_button.text = "Place"
    _place_button.custom_minimum_size = Vector2(0, 56)
    _place_button.add_theme_font_size_override("font_size", 26)
    _place_button.pressed.connect(_on_place_pressed)
    footer.add_child(_place_button)
    _apply_button_style(_place_button, Color(0.73, 0.87, 1.0, 1.0), Color(0.10, 0.19, 0.31, 1.0), Color(0.53, 0.70, 0.93, 1.0))

    var action_row := HBoxContainer.new()
    action_row.add_theme_constant_override("separation", 8)
    footer.add_child(action_row)

    _duplicate_button = Button.new()
    _duplicate_button.text = "Duplicate"
    _duplicate_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _duplicate_button.custom_minimum_size = Vector2(0, 44)
    _duplicate_button.add_theme_font_size_override("font_size", 24)
    _duplicate_button.pressed.connect(_on_duplicate_pressed)
    action_row.add_child(_duplicate_button)

    _edit_button = Button.new()
    _edit_button.text = "Edit"
    _edit_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _edit_button.custom_minimum_size = Vector2(0, 44)
    _edit_button.add_theme_font_size_override("font_size", 24)
    _edit_button.pressed.connect(_on_edit_pressed)
    action_row.add_child(_edit_button)

    _export_button = Button.new()
    _export_button.text = "Export"
    _export_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _export_button.custom_minimum_size = Vector2(0, 44)
    _export_button.add_theme_font_size_override("font_size", 24)
    _export_button.pressed.connect(_on_export_pressed)
    action_row.add_child(_export_button)

    _delete_button = Button.new()
    _delete_button.text = "Delete"
    _delete_button.custom_minimum_size = Vector2(0, 50)
    _delete_button.add_theme_font_size_override("font_size", 26)
    _delete_button.pressed.connect(_on_delete_pressed)
    footer.add_child(_delete_button)
    _apply_button_style(_delete_button, Color(0.90, 0.40, 0.40, 1.0), Color(0.26, 0.06, 0.08, 1.0), Color(0.70, 0.18, 0.22, 1.0))


func _apply_panel_style(panel: PanelContainer) -> void:
    var style := StyleBoxFlat.new()
    style.bg_color = Color(0.09, 0.12, 0.18, 0.95)
    style.border_color = Color(0.28, 0.38, 0.56, 1.0)
    style.set_border_width_all(2)
    style.set_corner_radius_all(12)
    style.set_content_margin_all(12)
    style.shadow_color = Color(0.04, 0.07, 0.12, 0.45)
    style.shadow_size = 8
    panel.add_theme_stylebox_override("panel", style)


func _apply_field_style(panel: PanelContainer) -> void:
    var style := StyleBoxFlat.new()
    style.bg_color = Color(0.11, 0.16, 0.24, 0.98)
    style.border_color = Color(0.40, 0.54, 0.76, 1.0)
    style.set_border_width_all(2)
    style.set_corner_radius_all(10)
    style.set_content_margin_all(8)
    panel.add_theme_stylebox_override("panel", style)


func _apply_button_style(button: Button, bg: Color, font_color: Color, border_color: Color) -> void:
    var style := StyleBoxFlat.new()
    style.bg_color = bg
    style.border_color = border_color
    style.set_border_width_all(2)
    style.set_corner_radius_all(10)
    style.set_content_margin_all(8)
    button.add_theme_stylebox_override("normal", style)
    button.add_theme_stylebox_override("hover", style)
    button.add_theme_stylebox_override("pressed", style)
    button.add_theme_color_override("font_color", font_color)


func _apply_mini_button_style(button: Button, active: bool) -> void:
    var style := StyleBoxFlat.new()
    if active:
        style.bg_color = Color(0.20, 0.28, 0.40, 0.95)
        style.border_color = Color(0.45, 0.60, 0.85, 0.9)
        button.add_theme_color_override("font_color", Color(0.85, 0.92, 1.0, 1.0))
    else:
        style.bg_color = Color(0.12, 0.16, 0.22, 0.8)
        style.border_color = Color(0.28, 0.38, 0.52, 0.6)
        button.add_theme_color_override("font_color", Color(0.55, 0.65, 0.78, 0.8))
    style.set_border_width_all(1)
    style.set_corner_radius_all(6)
    style.set_content_margin_all(4)
    button.add_theme_stylebox_override("normal", style)
    button.add_theme_stylebox_override("hover", style)
    button.add_theme_stylebox_override("pressed", style)


func _build_section_title(text: String) -> Label:
    var label := Label.new()
    label.text = text
    label.add_theme_font_size_override("font_size", 22)
    label.add_theme_color_override("font_color", Color(0.78, 0.88, 0.98, 0.95))
    return label


func _build_section_divider() -> HSeparator:
    var separator := HSeparator.new()
    separator.add_theme_color_override("separator", Color(0.30, 0.42, 0.60, 0.8))
    return separator


func _build_edit_dialog() -> void:
    _edit_dialog = AcceptDialog.new()
    _edit_dialog.title = "Edit Schematic"
    _edit_dialog.dialog_hide_on_ok = true
    _edit_dialog.min_size = Vector2i(520, 220)
    _edit_dialog.confirmed.connect(_on_edit_dialog_confirmed)
    add_child(_edit_dialog)

    var ok_button := _edit_dialog.get_ok_button()
    if ok_button != null:
        ok_button.text = "Save"

    var body := VBoxContainer.new()
    body.add_theme_constant_override("separation", 8)
    _edit_dialog.add_child(body)

    var name_label := Label.new()
    name_label.text = "Title"
    body.add_child(name_label)

    _edit_name_input = LineEdit.new()
    _edit_name_input.placeholder_text = "Schematic title"
    _edit_name_input.custom_minimum_size = Vector2(0, 36)
    body.add_child(_edit_name_input)

    var icon_label := Label.new()
    icon_label.text = "Icon"
    body.add_child(icon_label)

    var icon_row := HBoxContainer.new()
    icon_row.add_theme_constant_override("separation", 8)
    body.add_child(icon_row)

    _edit_icon_preview = TextureRect.new()
    _edit_icon_preview.custom_minimum_size = Vector2(42, 42)
    _edit_icon_preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    _edit_icon_preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    icon_row.add_child(_edit_icon_preview)

    _edit_icon_button = Button.new()
    _edit_icon_button.text = "Choose Icon"
    _edit_icon_button.custom_minimum_size = Vector2(0, 36)
    _edit_icon_button.pressed.connect(_on_edit_pick_icon_pressed)
    icon_row.add_child(_edit_icon_button)


func _build_category_chip(text: String) -> PanelContainer:
    var chip := PanelContainer.new()
    var style := StyleBoxFlat.new()
    style.bg_color = Color(0.18, 0.25, 0.36, 0.95)
    style.border_color = Color(0.38, 0.52, 0.70, 0.85)
    style.set_border_width_all(1)
    style.set_corner_radius_all(8)
    style.set_content_margin_all(5)
    style.content_margin_left = 10
    style.content_margin_right = 10
    chip.add_theme_stylebox_override("panel", style)

    var label := Label.new()
    label.text = text
    label.add_theme_font_size_override("font_size", 20)
    label.add_theme_color_override("font_color", Color(0.82, 0.90, 0.98, 1.0))
    chip.add_child(label)

    return chip

func _refresh_library() -> void:
    if _legacy_enabled:
        return
    _reload_categories()
    _rebuild_filter_ui()
    _rebuild_visible_names()
    _rebuild_rows()
    _result_count.text = "%d schematics" % _visible_names.size()

    if _selected_name == "" or not Data.schematics.has(_selected_name):
        if not _visible_names.is_empty():
            _select_schematic(_visible_names[0])
        else:
            _update_details("")
    else:
        if _visible_names.has(_selected_name):
            _select_schematic(_selected_name)
        elif not _visible_names.is_empty():
            _select_schematic(_visible_names[0])
        else:
            _update_details("")


func _reload_categories() -> void:
    _library_categories = _metadata_store.get_categories()
    var recovered: Array[String] = []
    for schematic_name in Data.schematics.keys():
        var meta: Dictionary = _get_meta(schematic_name, Data.schematics[schematic_name])
        var category := _get_category(meta)
        if category != "" and not _library_categories.has(category) and not recovered.has(category):
            recovered.append(category)
    for category in recovered:
        _metadata_store.add_category(category)
    _library_categories = _metadata_store.get_categories()
    _library_categories.sort()
    if _selected_category != ALL_CATEGORIES and _selected_category != UNCATEGORIZED and not _library_categories.has(_selected_category):
        _selected_category = ALL_CATEGORIES


func _rebuild_filter_ui() -> void:
    _clear_children(_category_list)
    _clear_children(_selected_tags_flow)
    _clear_children(_tag_pool_flow)

    var counts := _build_category_counts()
    var ordered: Array[String] = [ALL_CATEGORIES, UNCATEGORIZED]
    for category in _library_categories:
        ordered.append(category)

    for category in ordered:
        var count := int(counts.get(category, 0))
        var button := Button.new()
        button.text = "%s (%d)" % [category, count]
        button.custom_minimum_size = Vector2(0, 52)
        button.add_theme_font_size_override("font_size", 24)
        button.toggle_mode = true
        button.focus_mode = Control.FOCUS_NONE
        button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        button.alignment = HORIZONTAL_ALIGNMENT_LEFT
        button.clip_text = true
        button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
        button.set_pressed_no_signal(_selected_category == category)
        button.pressed.connect(_on_category_filter_pressed.bind(category))
        if category == _selected_category:
            var glow := StyleBoxFlat.new()
            glow.bg_color = Color(0.16, 0.22, 0.32, 0.95)
            glow.border_color = Color(0.50, 0.70, 1.0, 0.95)
            glow.set_border_width_all(1)
            glow.set_corner_radius_all(8)
            glow.set_content_margin_all(8)
            button.add_theme_stylebox_override("normal", glow)
            button.add_theme_color_override("font_color", Color(0.95, 0.98, 1.0, 1.0))
        else:
            button.add_theme_color_override("font_color", Color(0.80, 0.90, 1.0, 1.0))
        _category_list.add_child(button)
    if _category_delete_button != null:
        _category_delete_button.disabled = not _can_delete_selected_category()
    if _library_categories.is_empty():
        var empty_label := Label.new()
        empty_label.text = "No categories yet. Create your first category."
        empty_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        empty_label.add_theme_color_override("font_color", Color(0.66, 0.77, 0.89, 1.0))
        _category_list.add_child(empty_label)

    _all_tags = _collect_tags_from_library()
    var valid_selected: Array[String] = []
    for tag in _selected_tags:
        if _all_tags.has(tag):
            valid_selected.append(tag)
    _selected_tags = valid_selected
    for tag in _selected_tags:
        if _all_tags.has(tag):
            var selected_chip = TagChipScript.new(tag, true)
            selected_chip.removed.connect(func(value: String) -> void:
                _selected_tags.erase(value)
                _refresh_library()
            )
            _selected_tags_flow.add_child(selected_chip)

    if _all_tags.is_empty():
        _tag_empty_label.visible = true
        _tags_add_prompt_button.visible = _selected_name != ""
    else:
        _tag_empty_label.visible = false
        _tags_add_prompt_button.visible = false
        for tag in _all_tags:
            var chip := TagChipScript.new(tag, false)
            chip.mouse_filter = Control.MOUSE_FILTER_STOP
            chip.gui_input.connect(_on_tag_pool_input.bind(tag))
            if _selected_tags.has(tag):
                var style := StyleBoxFlat.new()
                style.bg_color = Color(0.27, 0.34, 0.47, 0.98)
                style.border_color = Color(0.72, 0.84, 1.0, 1.0)
                style.set_border_width_all(1)
                style.set_corner_radius_all(12)
                style.set_content_margin_all(7)
                chip.add_theme_stylebox_override("panel", style)
            _tag_pool_flow.add_child(chip)

    _clear_filters_button.visible = _selected_category != ALL_CATEGORIES or not _selected_tags.is_empty() or _search_input.text.strip_edges() != ""


func _build_category_counts() -> Dictionary:
    var counts := {
        ALL_CATEGORIES: Data.schematics.size(),
        UNCATEGORIZED: 0
    }
    for category in _library_categories:
        counts[category] = 0
    for schematic_name in Data.schematics.keys():
        var meta: Dictionary = _get_meta(schematic_name, Data.schematics[schematic_name])
        var category := _get_category(meta)
        if category == "":
            counts[UNCATEGORIZED] = int(counts.get(UNCATEGORIZED, 0)) + 1
        else:
            counts[category] = int(counts.get(category, 0)) + 1
    return counts


func _collect_tags_from_library() -> Array[String]:
    var tag_set: Dictionary = {}
    for schematic_name in Data.schematics.keys():
        var meta: Dictionary = _get_meta(schematic_name, Data.schematics[schematic_name])
        for tag in _get_tags(meta):
            tag_set[tag] = true
    var tags: Array[String] = []
    for key in tag_set.keys():
        tags.append(key)
    tags.sort()
    return tags


func _rebuild_visible_names() -> void:
    _visible_names.clear()
    var query := _search_input.text.strip_edges().to_lower()

    for schematic_name in Data.schematics.keys():
        var data: Dictionary = Data.schematics[schematic_name]
        var meta: Dictionary = _get_meta(schematic_name, data)

        if _selected_category != ALL_CATEGORIES:
            var category := _get_category(meta)
            if _selected_category == UNCATEGORIZED:
                if category != "":
                    continue
            elif category != _selected_category:
                continue

        if not _selected_tags.is_empty():
            var tags := _get_tags(meta)
            var matches_tag := false
            for tag in _selected_tags:
                if tags.has(tag):
                    matches_tag = true
                    break
            if not matches_tag:
                continue

        if query != "":
            var hay: String = (schematic_name + " " + str(meta.get("description", "")) + " " + str(meta.get("notes", "")) + " " + ", ".join(_get_tags(meta))).to_lower()
            if hay.find(query) == -1:
                continue

        _visible_names.append(schematic_name)

    _sort_visible_names()


func _sort_visible_names() -> void:
    match _sort_dropdown.selected:
        1:
            _visible_names.sort_custom(func(a: String, b: String) -> bool:
                return a.to_lower() > b.to_lower()
            )
        2:
            _visible_names.sort_custom(func(a: String, b: String) -> bool:
                return _metadata_store.get_schematic_modified_time(a) > _metadata_store.get_schematic_modified_time(b)
            )
        3:
            _visible_names.sort_custom(func(a: String, b: String) -> bool:
                return int(_compute_stats(Data.schematics[a]).get("node_count", 0)) > int(_compute_stats(Data.schematics[b]).get("node_count", 0))
            )
        _:
            _visible_names.sort_custom(func(a: String, b: String) -> bool:
                return a.to_lower() < b.to_lower()
            )


func _rebuild_rows() -> void:
    _clear_children(_list_rows)
    _row_nodes.clear()

    for schematic_name in _visible_names:
        var data: Dictionary = Data.schematics[schematic_name]
        var meta: Dictionary = _get_meta(schematic_name, data)
        var stats := _compute_stats(data)
        var category := _get_category(meta)
        if category == "":
            category = UNCATEGORIZED
        var modified := _format_short_date(_metadata_store.get_schematic_modified_time(schematic_name))
        var row := SchematicListRowScript.new()
        row.setup(_get_preview_texture(data), schematic_name, "Nodes: %d | %s, Modified: %s" % [int(stats.get("node_count", 0)), category, modified], _get_status(meta))
        row.pressed.connect(_on_row_pressed.bind(schematic_name))
        _list_rows.add_child(row)
        _row_nodes[schematic_name] = row
        if schematic_name == _selected_name:
            row.set_pressed_no_signal(true)


func _select_schematic(schematic_name: String) -> void:
    if schematic_name == "" or not Data.schematics.has(schematic_name):
        _update_details("")
        return
    _selected_name = schematic_name
    for key in _row_nodes.keys():
        var button: Button = _row_nodes[key]
        button.set_pressed_no_signal(key == schematic_name)
    _update_details(schematic_name)


func _update_details(schematic_name: String) -> void:
    _suppress_detail_events = true

    if schematic_name == "" or not Data.schematics.has(schematic_name):
        _clear_children(_detail_category_chips)
        _detail_name.text = "Select a schematic"
        (_detail_badge as Object).set_status("WIP")
        if ResourceLoader.exists(DEFAULT_ICON_PATH):
            _detail_preview.texture = load(DEFAULT_ICON_PATH)
        _detail_stats.text = "Nodes: 0 | Resources: 0 | Links: 0"
        _detail_types.text = "Top Types: -"
        _detail_warning.visible = false
        _detail_desc.text = ""
        _detail_notes.text = ""
        _detail_status.select(0)
        _clear_children(_detail_tags_flow)
        _rebuild_detail_category_dropdown("")
        _set_actions_enabled(false)
        _suppress_detail_events = false
        return

    var data: Dictionary = Data.schematics[schematic_name]
    var meta: Dictionary = _get_meta(schematic_name, data)
    var stats := _compute_stats(data)
    var preflight := _compute_preflight(schematic_name, stats)

    _detail_name.text = schematic_name
    (_detail_badge as Object).set_status(_get_status(meta))
    _detail_preview.texture = _get_preview_texture(data)
    _detail_stats.text = "Nodes: %d | Resources: %d | Links: %d" % [int(stats.get("node_count", 0)), int(stats.get("resource_count", 0)), int(stats.get("link_count", 0))]
    _detail_types.text = "Top Types: %s" % [", ".join(stats.get("top_types", [])) if not stats.get("top_types", []).is_empty() else "-"]
    _detail_warning.text = "\n".join(preflight.get("warnings", []))
    _detail_warning.visible = _detail_warning.text != ""
    _detail_desc.text = str(meta.get("description", ""))
    _detail_notes.text = str(meta.get("notes", ""))
    _detail_status.select(_status_index(_get_status(meta)))

    # Populate category chips at the top
    _clear_children(_detail_category_chips)
    var category := _get_category(meta)
    if category != "":
        var cat_chip := _build_category_chip(category)
        _detail_category_chips.add_child(cat_chip)
    for tag in _get_tags(meta):
        var tag_chip := _build_category_chip(tag)
        _detail_category_chips.add_child(tag_chip)

    _clear_children(_detail_tags_flow)
    for tag in _get_tags(meta):
        var chip = TagChipScript.new(tag, true)
        chip.removed.connect(func(value: String) -> void:
            _remove_tag(value)
        )
        _detail_tags_flow.add_child(chip)

    _rebuild_detail_category_dropdown(_get_category(meta))
    _set_actions_enabled(true)
    _place_button.disabled = bool(preflight.get("blocked", false))
    _suppress_detail_events = false


func _rebuild_detail_category_dropdown(selected: String) -> void:
    _detail_category_select.clear()
    _detail_category_select.add_item(UNCATEGORIZED)
    for category in _library_categories:
        _detail_category_select.add_item(category)

    var selected_index := 0
    if selected != "":
        for i in _detail_category_select.item_count:
            if _detail_category_select.get_item_text(i) == selected:
                selected_index = i
                break
    _detail_category_select.select(selected_index)


func _set_actions_enabled(enabled: bool) -> void:
    _place_button.disabled = not enabled
    _duplicate_button.disabled = not enabled
    _edit_button.disabled = not enabled
    _export_button.disabled = not enabled
    _delete_button.disabled = not enabled


func _can_delete_selected_category() -> bool:
    return _selected_category != ALL_CATEGORIES and _selected_category != UNCATEGORIZED and _library_categories.has(_selected_category)


func _on_delete_selected_category_pressed() -> void:
    var category := _selected_category
    if _detail_category_select != null and _detail_category_select.item_count > 0:
        var detail_category := _detail_category_select.get_item_text(_detail_category_select.selected)
        if detail_category != "" and detail_category != UNCATEGORIZED:
            category = detail_category
    if category == ALL_CATEGORIES or category == UNCATEGORIZED or not _library_categories.has(category):
        return
    Signals.prompt.emit(
        "prompt_delete_category",
        "Delete category '%s'? Schematics in this category will become Uncategorized." % category,
        func() -> void:
            _delete_category_everywhere(category)
    )


func _delete_category_everywhere(category: String) -> void:
    if not _metadata_store.remove_category(category):
        return
    for schematic_name in Data.schematics.keys():
        var meta: Dictionary = _get_meta(schematic_name, Data.schematics[schematic_name])
        var categories: Array[String] = meta.get("categories", [])
        var changed := false
        while categories.has(category):
            categories.erase(category)
            changed = true
        if changed:
            meta["categories"] = categories
            _save_meta(schematic_name, meta)
    if _selected_category == category:
        _selected_category = ALL_CATEGORIES
    _refresh_library()


func _on_category_filter_pressed(category: String) -> void:
    _selected_category = category
    _refresh_library()


func _on_tag_pool_input(event: InputEvent, tag: String) -> void:
    if not (event is InputEventMouseButton):
        return
    var mouse := event as InputEventMouseButton
    if not mouse.pressed or mouse.button_index != MOUSE_BUTTON_LEFT:
        return
    if _selected_tags.has(tag):
        _selected_tags.erase(tag)
    else:
        _selected_tags.append(tag)
    _refresh_library()


func _on_row_pressed(schematic_name: String) -> void:
    _select_schematic(schematic_name)


func _on_add_tag_submitted(text: String) -> void:
    if _selected_name == "":
        return
    var cleaned := text.strip_edges()
    if cleaned == "":
        return
    var meta: Dictionary = _get_meta(_selected_name, Data.schematics[_selected_name])
    var tags := _get_tags(meta)
    if not tags.has(cleaned):
        tags.append(cleaned)
        tags.sort()
    meta["tags"] = tags
    _save_meta(_selected_name, meta)
    _add_tag_input.text = ""
    _add_tag_input.visible = false
    _add_tag_button.visible = true
    _refresh_library()


func _on_start_new_category() -> void:
    _category_create_input.text = ""
    _category_create_input.visible = true
    _category_create_input.grab_focus()


func _on_new_category_submitted(value: String) -> void:
    var cleaned := value.strip_edges()
    if cleaned == "":
        _category_create_input.visible = false
        return
    if _metadata_store.add_category(cleaned):
        _reload_categories()
        _selected_category = cleaned
        if _selected_name != "":
            var meta: Dictionary = _get_meta(_selected_name, Data.schematics[_selected_name])
            if _get_category(meta) == "":
                meta["categories"] = [cleaned]
                _save_meta(_selected_name, meta)
    _category_create_input.text = ""
    _category_create_input.visible = false
    _refresh_library()


func _focus_tag_input() -> void:
    _add_tag_button.visible = false
    _add_tag_input.visible = true
    _add_tag_input.grab_focus()


func _remove_last_tag() -> void:
    if _selected_name == "":
        return
    var meta: Dictionary = _get_meta(_selected_name, Data.schematics[_selected_name])
    var tags := _get_tags(meta)
    if tags.is_empty():
        return
    tags.remove_at(tags.size() - 1)
    meta["tags"] = tags
    _save_meta(_selected_name, meta)
    _refresh_library()


func _remove_tag(tag: String) -> void:
    if _selected_name == "":
        return
    var meta: Dictionary = _get_meta(_selected_name, Data.schematics[_selected_name])
    var tags := _get_tags(meta)
    tags.erase(tag)
    meta["tags"] = tags
    _save_meta(_selected_name, meta)
    _refresh_library()


func _on_detail_category_selected(_idx: int) -> void:
    if _suppress_detail_events or _selected_name == "":
        return
    var value := _detail_category_select.get_item_text(_detail_category_select.selected)
    var meta: Dictionary = _get_meta(_selected_name, Data.schematics[_selected_name])
    if value == UNCATEGORIZED:
        meta["categories"] = []
    else:
        meta["categories"] = [value]
    _save_meta(_selected_name, meta)
    _refresh_library()


func _on_desc_changed() -> void:
    if _suppress_detail_events or _selected_name == "":
        return
    var meta: Dictionary = _get_meta(_selected_name, Data.schematics[_selected_name])
    meta["description"] = _detail_desc.text
    _save_meta(_selected_name, meta)


func _on_notes_changed() -> void:
    if _suppress_detail_events or _selected_name == "":
        return
    var meta: Dictionary = _get_meta(_selected_name, Data.schematics[_selected_name])
    meta["notes"] = _detail_notes.text
    _save_meta(_selected_name, meta)


func _on_status_selected(_idx: int) -> void:
    if _suppress_detail_events or _selected_name == "":
        return
    var meta: Dictionary = _get_meta(_selected_name, Data.schematics[_selected_name])
    meta["status"] = STATUS_OPTIONS[_detail_status.selected]
    _save_meta(_selected_name, meta)
    _refresh_library()


func _on_place_pressed() -> void:
    if _selected_name == "" or _legacy_enabled:
        return
    var preflight := _compute_preflight(_selected_name, _compute_stats(Data.schematics[_selected_name]))
    if preflight.get("blocked", false):
        Sound.play("error")
        return
    Signals.place_schematic.emit(_selected_name)
    Sound.play("click2")


func _on_edit_pressed() -> void:
    if _selected_name == "" or not Data.schematics.has(_selected_name):
        return
    var data: Dictionary = Data.schematics[_selected_name]
    _edit_name_input.text = _selected_name
    _edit_icon_id = str(data.get("icon", "blueprint"))
    _edit_icon_preview.texture = _resolve_icon_texture(_edit_icon_id)
    if _edit_icon_preview.texture == null and ResourceLoader.exists(DEFAULT_ICON_PATH):
        _edit_icon_preview.texture = load(DEFAULT_ICON_PATH)
    _edit_dialog.popup_centered(Vector2i(560, 240))
    _edit_name_input.grab_focus()
    _edit_name_input.select_all()


func _on_edit_pick_icon_pressed() -> void:
    IconPickerPopupScript.open(
        {
            "title": "Pick Schematic Icon",
            "initial_selected_id": _edit_icon_id
        },
        Callable(self , "_on_edit_icon_selected")
    )


func _on_edit_icon_selected(icon_id: Variant, _entry: Variant) -> void:
    var cleaned_icon := str(icon_id).strip_edges()
    if cleaned_icon == "":
        return
    _edit_icon_id = cleaned_icon
    _edit_icon_preview.texture = _resolve_icon_texture(_edit_icon_id)
    if _edit_icon_preview.texture == null and ResourceLoader.exists(DEFAULT_ICON_PATH):
        _edit_icon_preview.texture = load(DEFAULT_ICON_PATH)


func _on_edit_dialog_confirmed() -> void:
    if _selected_name == "" or not Data.schematics.has(_selected_name):
        return
    var target_name := _sanitize_schematic_name(_edit_name_input.text)
    if target_name == "":
        target_name = _selected_name
    _commit_schematic_edit(_selected_name, target_name, _edit_icon_id)


func _commit_schematic_edit(old_name: String, target_name: String, icon_id: String) -> void:
    if not Data.schematics.has(old_name):
        return
    var edited_data: Dictionary = Data.schematics[old_name].duplicate(true)
    edited_data["icon"] = icon_id
    var old_meta: Dictionary = _get_meta(old_name, Data.schematics[old_name]).duplicate(true)

    if target_name == old_name:
        _write_schematic_file(old_name, edited_data)
        Data.schematics[old_name] = edited_data
        old_meta["name"] = old_name
        _save_meta(old_name, old_meta)
        _refresh_library()
        _select_schematic(old_name)
        return

    var before: Array = Data.schematics.keys()
    Data.save_schematic(target_name, edited_data)
    var new_name := target_name
    for key in Data.schematics.keys():
        if not before.has(key):
            new_name = key
            break
    old_meta["name"] = new_name
    _save_meta(new_name, old_meta)
    _meta_cache.erase(old_name)
    _metadata_store.delete_meta(old_name)
    Data.delete_schematic(old_name)
    _selected_name = new_name
    _refresh_library()
    _select_schematic(new_name)


func _write_schematic_file(schematic_name: String, data: Dictionary) -> void:
    var file := ConfigFile.new()
    file.set_value("schematic", "windows", data["windows"])
    file.set_value("schematic", "connectors", data["connectors"])
    file.set_value("schematic", "rect", data.get("rect", {}))
    file.set_value("schematic", "icon", data.get("icon", "blueprint"))
    var path := "user://schematics/%s.dat" % schematic_name
    file.save(path)


func _sanitize_schematic_name(value: String) -> String:
    var cleaned := value.strip_edges()
    var forbidden := ["/", "\\", ":", "*", "?", "\"", "<", ">", "|"]
    for ch in forbidden:
        cleaned = cleaned.replace(ch, "_")
    return cleaned


func _on_duplicate_pressed() -> void:
    if _selected_name == "":
        return
    var data: Dictionary = Data.schematics[_selected_name].duplicate(true)
    var meta_copy: Dictionary = _get_meta(_selected_name, Data.schematics[_selected_name]).duplicate(true)
    var before: Array = Data.schematics.keys()
    Data.save_schematic(_selected_name + " Copy", data)
    var after: Array = Data.schematics.keys()
    for schematic_name in after:
        if not before.has(schematic_name):
            meta_copy["name"] = schematic_name
            _save_meta(schematic_name, meta_copy)
            _selected_name = schematic_name
            break
    _refresh_library()


func _on_export_pressed() -> void:
    if _selected_name == "":
        return
    DisplayServer.clipboard_set(Data.get_schematic_as_file(Data.schematics[_selected_name]).encode_to_text())
    Sound.play("click2")


func _on_delete_pressed() -> void:
    if _selected_name == "":
        return
    var schematic_to_delete := _selected_name
    Signals.prompt.emit("prompt_delete_schematic", "prompt_delete_schematic_desc", func() -> void:
        Data.delete_schematic(schematic_to_delete)
    )


func _save_meta(schematic_name: String, meta: Dictionary) -> void:
    meta["status"] = _normalize_status(str(meta.get("status", "WIP")))
    _meta_cache[schematic_name] = meta
    _metadata_store.save_meta(schematic_name, meta)


func _get_meta(schematic_name: String, schematic_data: Dictionary) -> Dictionary:
    if _meta_cache.has(schematic_name):
        return _meta_cache[schematic_name]
    var meta: Dictionary = _metadata_store.ensure_meta(schematic_name, schematic_data)
    meta["status"] = _normalize_status(str(meta.get("status", "WIP")))
    _meta_cache[schematic_name] = meta
    return meta


func _normalize_status(status: String) -> String:
    var normalized := status.to_lower()
    match normalized:
        "ok", "works":
            return "OK"
        "meme":
            return "Meme"
        "meta":
            return "Meta"
        _:
            return "WIP"


func _status_index(status: String) -> int:
    for i in STATUS_OPTIONS.size():
        if STATUS_OPTIONS[i].to_lower() == status.to_lower():
            return i
    return 0


func _get_status(meta: Dictionary) -> String:
    return _normalize_status(str(meta.get("status", "WIP")))


func _get_tags(meta: Dictionary) -> Array[String]:
    var output: Array[String] = []
    for item in meta.get("tags", []):
        var cleaned := str(item).strip_edges()
        if cleaned != "":
            output.append(cleaned)
    return output


func _get_category(meta: Dictionary) -> String:
    for item in meta.get("categories", []):
        var cleaned := str(item).strip_edges()
        if cleaned != "":
            return cleaned
    return ""


func _select_relative(delta: int) -> void:
    if _visible_names.is_empty():
        return
    var idx := _visible_names.find(_selected_name)
    if idx == -1:
        idx = 0
    idx = clampi(idx + delta, 0, _visible_names.size() - 1)
    _select_schematic(_visible_names[idx])
    var row: Control = _row_nodes.get(_selected_name, null)
    if row != null:
        _list_rows_scroll.ensure_control_visible(row)


func _compute_stats(data: Dictionary) -> Dictionary:
    var node_count := 0
    var resource_count := 0
    var link_count := 0
    var type_counts: Dictionary = {}
    if data.has("windows"):
        var windows_data: Variant = data.windows
        if windows_data is Dictionary:
            for window_id in windows_data.keys():
                node_count += 1
                var wd: Dictionary = windows_data[window_id]
                var wt := str(wd.get("window", ""))
                if wt != "":
                    type_counts[wt] = int(type_counts.get(wt, 0)) + 1
                if wd.has("container_data"):
                    var container_data: Variant = wd.container_data
                    if container_data is Dictionary:
                        for rid in container_data.keys():
                            resource_count += 1
                            var outputs: Variant = container_data[rid].get("outputs_id", [])
                            if outputs is Array:
                                link_count += outputs.size()
                    elif container_data is Array:
                        for entry in container_data:
                            resource_count += 1
                            if entry is Dictionary:
                                var outputs: Variant = entry.get("outputs_id", [])
                                if outputs is Array:
                                    link_count += outputs.size()
        elif windows_data is Array:
            for entry in windows_data:
                if not (entry is Dictionary):
                    continue
                node_count += 1
                var wt := str(entry.get("window", ""))
                if wt != "":
                    type_counts[wt] = int(type_counts.get(wt, 0)) + 1
                if entry.has("container_data"):
                    var container_data: Variant = entry.container_data
                    if container_data is Dictionary:
                        for rid in container_data.keys():
                            resource_count += 1
                            var outputs: Variant = container_data[rid].get("outputs_id", [])
                            if outputs is Array:
                                link_count += outputs.size()
                    elif container_data is Array:
                        for item in container_data:
                            resource_count += 1
                            if item is Dictionary:
                                var outputs: Variant = item.get("outputs_id", [])
                                if outputs is Array:
                                    link_count += outputs.size()
    return {
        "node_count": node_count,
        "resource_count": resource_count,
        "link_count": link_count,
        "type_counts": type_counts,
        "top_types": _get_top_types(type_counts, 3)
    }


func _get_top_types(counts: Dictionary, limit: int) -> Array[String]:
    var arr: Array = []
    for key in counts.keys():
        arr.append({"k": key, "v": int(counts[key])})
    arr.sort_custom(func(a, b): return int(a.v) > int(b.v))
    var out: Array[String] = []
    for item in arr:
        if out.size() >= limit:
            break
        out.append("%s (%d)" % [item.k, item.v])
    return out


func _compute_preflight(_name: String, stats: Dictionary) -> Dictionary:
    var required := int(stats.get("node_count", 0))
    var limit := _get_node_limit()
    var available := limit - Globals.max_window_count if limit >= 0 else -1
    var blocked := limit >= 0 and required > available
    var warnings: Array[String] = []
    if blocked:
        warnings.append("Node limit exceeded: %d needed, %d available" % [required, available])
    var type_counts: Dictionary = stats.get("type_counts", {})
    for wt in type_counts.keys():
        if Data.windows.has(wt):
            var req := str(Data.windows[wt].requirement)
            if req != "" and not Globals.unlocks.get(req, false):
                blocked = true
                warnings.append("Missing unlock: %s" % wt)
    return {"blocked": blocked, "warnings": warnings}

func _get_preview_texture(data: Dictionary) -> Texture2D:
    var icon_id := str(data.get("icon", ""))
    var tex := _resolve_icon_texture(icon_id)
    if tex != null:
        return tex
    if ResourceLoader.exists(DEFAULT_ICON_PATH):
        return load(DEFAULT_ICON_PATH)
    return null


func _resolve_icon_texture(icon_id: String) -> Texture2D:
    if icon_id == "":
        return null
    var core = Engine.get_meta("TajsCore", null)
    if core != null:
        var registry = core.get_icon_registry()
        if registry != null:
            var resolved: Dictionary = registry.resolve_icon(icon_id)
            if resolved.get("texture", null) != null:
                return resolved.texture
    if icon_id.find(":") != -1:
        var parts := icon_id.split(":", false, 1)
        if parts.size() == 2 and parts[1] != "":
            var mapped := "res://textures/icons".path_join(parts[1])
            if ResourceLoader.exists(mapped):
                return load(mapped)
    var path := "res://textures/icons/%s.png" % icon_id
    if ResourceLoader.exists(path):
        return load(path)
    return null


func _format_short_date(unix_time: int) -> String:
    if unix_time <= 0:
        return "--"
    var dt := Time.get_datetime_dict_from_unix_time(unix_time)
    var months := ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
    return "%02d-%s" % [int(dt.day), months[clampi(int(dt.month) - 1, 0, 11)]]


func _get_node_limit() -> int:
    var core = Engine.get_meta("TajsCore", null)
    if core != null and core.has_method("get"):
        var helper = core.get("node_limit_helpers")
        if helper != null and helper.has_method("get_node_limit"):
            return helper.get_node_limit()
    return Utils.MAX_WINDOW


func _clear_children(node: Node) -> void:
    for child in node.get_children():
        child.queue_free()


func _on_viewport_resized() -> void:
    _apply_layout()


func _apply_layout() -> void:
    call_deferred("_commit_layout")


func _commit_layout() -> void:
    set_anchors_preset(Control.PRESET_FULL_RECT)
    var viewport_size := get_viewport().get_visible_rect().size
    var side: float = clamp(viewport_size.x * 0.018, 16.0, 46.0)
    var top: float = clamp(viewport_size.y * 0.018, 14.0, 34.0)
    var bottom: float = clamp(viewport_size.y * 0.13, 100.0, 170.0)
    if _search_wrap != null:
        var search_width: float = clamp(viewport_size.x * 0.40, 520.0, 860.0)
        _search_wrap.custom_minimum_size.x = search_width
    offset_left = side
    offset_top = top
    offset_right = - side
    offset_bottom = - bottom


func _bring_to_front() -> void:
    move_to_front()
    var parent := get_parent()
    if parent != null:
        parent.move_child(self , parent.get_child_count() - 1)
    z_index = 200


func _close_panel() -> void:
    toggle(false)
    Signals.set_menu.emit(Utils.menu_types.NONE, 0)


func _focus_search() -> void:
    if _search_input != null:
        _search_input.grab_focus()
        _search_input.select_all()


func _is_text_focus_active() -> bool:
    var focus := get_viewport().gui_get_focus_owner()
    return focus is LineEdit or focus is TextEdit


func _on_search_changed(_text: String) -> void:
    _refresh_library()


func _on_sort_changed(_idx: int) -> void:
    _refresh_library()


func _on_import_button_pressed() -> void:
    super._on_import_pressed()
    call_deferred("_refresh_library")


func _on_clear_filters_pressed() -> void:
    _selected_category = ALL_CATEGORIES
    _selected_tags.clear()
    _search_input.text = ""
    _refresh_library()


func _on_legacy_toggled(value: bool) -> void:
    _legacy_enabled = value
    if _settings != null:
        _settings.set_value(LEGACY_SETTING_KEY, value)
    _apply_legacy_mode()
    _refresh_library()


func _apply_legacy_mode() -> void:
    _legacy_container.visible = _legacy_enabled
    _custom_body.visible = not _legacy_enabled
    _toolbar_left.visible = not _legacy_enabled


func _sync_legacy_setting() -> void:
    if _settings != null:
        _legacy_enabled = _settings.get_bool(LEGACY_SETTING_KEY, false)
    if _legacy_switch != null:
        _legacy_switch.set_pressed_no_signal(_legacy_enabled)


func _on_setting_changed(key: String, value: Variant, _old_value: Variant) -> void:
    if key != LEGACY_SETTING_KEY:
        return
    _legacy_enabled = bool(value)
    if _legacy_switch != null:
        _legacy_switch.set_pressed_no_signal(_legacy_enabled)
    _apply_legacy_mode()
