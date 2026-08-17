@tool
class_name ProgressionMenu
extends Control

signal closed()
signal font_selected(font_id: StringName)
signal palette_selected(palette_id: StringName)
signal page_viewed(page: int)

const CHECKED_TEXTURE := preload(
	"res://resources/materials/textures/ui/check/checked.tres"
)
const UNCHECKED_TEXTURE := preload(
	"res://resources/materials/textures/ui/check/unchecked.tres"
)
const SELECTED_TEXTURE := preload(
	"res://resources/materials/textures/ui/check/selected.tres"
)
const HighlightButtonScript := preload(
	"res://resources/scripts/ui/HighlightButton.gd"
)
const TILE_FACE_TEXTURE := preload(
	"res://resources/sprites/tiles/tile-face.png"
)
const TILE_BACK_TEXTURE := preload(
	"res://resources/sprites/tiles/tile-back.png"
)
const PROGRESS_BAR_TEXTURE := preload(
	"res://resources/materials/textures/ui/panels/bar.tres"
)
const VERTICAL_SCROLL_TRACK_TEXTURE := preload(
	"res://resources/materials/textures/ui/buttons/slide-bar/vertical/bar.tres"
)
const VERTICAL_SCROLL_SELECTOR_TEXTURE := preload(
	"res://resources/materials/textures/ui/buttons/slide-bar/vertical/selector.tres"
)
const ProgressionCompletionBarScript := preload(
	"res://resources/scripts/ui/ProgressionCompletionBar.gd"
)
const ProgressionScrollVisualScript := preload(
	"res://resources/scripts/ui/ProgressionScrollVisual.gd"
)
const ProgressionPreviewBuilderScript := preload(
	"res://resources/scripts/ui/progression/ProgressionPreviewBuilder.gd"
)
const PROGRESS_BAR_SHADER := """
shader_type canvas_item;
uniform float progress : hint_range(0.0, 1.0) = 1.0;
uniform vec4 fill_color : source_color = vec4(0.302, 0.51, 0.761, 1.0);
uniform vec4 empty_color : source_color = vec4(0.725, 0.765, 0.812, 1.0);
uniform vec4 highlight_color : source_color = vec4(0.427, 0.655, 0.898, 1.0);
uniform float highlighted : hint_range(0.0, 1.0) = 0.0;
void fragment() {
	vec4 source = texture(TEXTURE, UV);
	vec4 highlighted_fill = mix(fill_color, highlight_color, highlighted);
	vec4 level_color = UV.x <= progress ? highlighted_fill : empty_color;
	bool green_mask = source.g > 0.9 && source.r < 0.1 && source.b < 0.1;
	COLOR = green_mask
		? vec4(level_color.rgb, source.a * level_color.a)
		: source;
}
"""
const Settings := preload("res://resources/scripts/settings/settings.gd")
const SELECTED_COLOR := Color("4d82c2")
const LOCKED_ENTRY_OPACITY := 0.55
# The main icon is 23x25. Panel buttons are 30x34 and center that same texture,
# so its notification needs the rounded (3.5, 4.5) centering compensation.
const PANEL_NOTIFICATION_RECT := Rect2(0.0, 21.0, 10.0, 11.0)
# Kept for a possible later reactivation of the LOCKED/BOTH/UNLOCKED control.
const SHOW_LOCK_FILTER := false
const GOLD_STATUS_SHADER := """
shader_type canvas_item;
uniform vec4 gold_color : source_color = vec4(0.851, 0.647, 0.078, 1.0);
void fragment() {
	vec4 source = texture(TEXTURE, UV) * COLOR;
	float vertical_shine = mix(1.12, 0.82, UV.y);
	COLOR = vec4(gold_color.rgb * vertical_shine, source.a * gold_color.a);
}
"""

enum Page {
	HIGHSCORES,
	ACHIEVEMENTS,
	BONUSES,
	SPECIAL_RULES,
	FONTS,
}

enum ProgressFilter {
	BOTH,
	UNLOCKED,
	LOCKED,
}

@export_tool_button("Copy Notification Placement", "Duplicate")
var copy_notification_placement_action: Callable = _copy_notification_placement

@export_category("Menu Editor Preview")
@export var show_editor_preview := false:
	set(value):
		show_editor_preview = value
		if Engine.is_editor_hint() and is_node_ready():
			if show_editor_preview:
				_show_editor_preview()
			else:
				visible = false

@export_category("Entry Style")
@export var entry_heading_font: Font:
	set(value):
		entry_heading_font = value
		_refresh_editor_preview()
@export_range(8, 32, 1) var entry_heading_font_size := 15:
	set(value):
		entry_heading_font_size = value
		_refresh_editor_preview()
@export var entry_heading_text_offset := Vector2(2.0, 2.0):
	set(value):
		entry_heading_text_offset = value
		_refresh_editor_preview()
@export var entry_details_font: Font:
	set(value):
		entry_details_font = value
		_refresh_editor_preview()
@export_range(8, 24, 1) var entry_details_font_size := 11:
	set(value):
		entry_details_font_size = value
		_refresh_editor_preview()
@export var font_button_style: StyleBox
@export var font_button_highlight_material: ShaderMaterial
@export_category("Bonus Level Style")
@export var bonus_level_font: Font:
	set(value):
		bonus_level_font = value
		_refresh_editor_preview()
@export_range(8, 24, 1) var bonus_level_font_size := 11:
	set(value):
		bonus_level_font_size = value
		_refresh_editor_preview()
@export var bonus_level_text_offset := Vector2(1.0, -1.0):
	set(value):
		bonus_level_text_offset = value
		_refresh_editor_preview()
@export_category("Font Preview")
@export var font_preview_tile_material: ShaderMaterial

@onready var title_label: Label = %PageTitle
@onready var lock_filter: ProgressionLockFilter = %LockFilter
@onready var font_preview_scroll: ScrollContainer = %FontPreviewScroll
@onready var font_preview: HFlowContainer = %FontPreview
@onready var content: VBoxContainer = %PageContent
@onready var main_scroll: ScrollContainer = %Scroll
@onready var fonts_scroll: ScrollContainer = %FontsScroll
@onready var palettes_scroll: ScrollContainer = %PalettesScroll
@onready var cosmetic_lists: VBoxContainer = %CosmeticLists
@onready var fonts_content: VBoxContainer = %FontsContent
@onready var palettes_content: VBoxContainer = %PalettesContent
@onready var font_catalog: ProgressionFontCatalog = %FontCatalog
@onready var achievement_catalog: ProgressionAchievementCatalog = %AchievementCatalog
@onready var page_buttons: Array[TextureButton] = [
	%HighscoresButton,
	%AchievementsButton,
	%BonusesButton,
	%SpecialRulesButton,
	%FontsButton,
]

var _snapshot: Dictionary = {}
var _page := Page.HIGHSCORES
var _page_badges: Array[TextureRect] = []


func get_available_fonts() -> Array[FontData]:
	return font_catalog.available_fonts


func get_achievements() -> Array[AchievementData]:
	return achievement_catalog.achievements


func get_available_palettes() -> Array[ColorPaletteData]:
	return font_catalog.available_palettes


func get_default_font() -> FontData:
	return font_catalog.default_font


func get_default_palette() -> ColorPaletteData:
	return font_catalog.default_palette


func _ready() -> void:
	if not font_catalog.editor_preview_changed.is_connected(_refresh_editor_preview):
		font_catalog.editor_preview_changed.connect(_refresh_editor_preview)
	_style_vertical_scrollbars()
	lock_filter.set_mode(ProgressFilter.BOTH)
	lock_filter.mode_changed.connect(_on_filter_selected)
	for index in page_buttons.size():
		var show_callable := _on_page_button_pressed.bind(index)
		if not page_buttons[index].pressed.is_connected(show_callable):
			page_buttons[index].pressed.connect(show_callable)
	_setup_page_badges()
	if not %BackButton.pressed.is_connected(close):
		%BackButton.pressed.connect(close)
	if Engine.is_editor_hint() and show_editor_preview:
		_show_editor_preview()
	else:
		visible = false


func _style_vertical_scrollbars() -> void:
	var scrolls: Array[ScrollContainer] = [
		main_scroll, fonts_scroll, palettes_scroll,
	]
	for scroll in scrolls:
		var scrollbar: VScrollBar = scroll.get_v_scroll_bar()
		scrollbar.custom_minimum_size.x = 8.0
		var empty_style := StyleBoxEmpty.new()
		for style_name in [
			&"scroll", &"scroll_focus", &"grabber",
			&"grabber_highlight", &"grabber_pressed",
		]:
			scrollbar.add_theme_stylebox_override(style_name, empty_style)
		var visual := Control.new()
		visual.set_script(ProgressionScrollVisualScript)
		scrollbar.add_child(visual)
		visual.call(
			"setup", scrollbar, VERTICAL_SCROLL_TRACK_TEXTURE,
			VERTICAL_SCROLL_SELECTOR_TEXTURE
		)


func _refresh_editor_preview() -> void:
	if Engine.is_editor_hint() and is_node_ready() and show_editor_preview:
		call_deferred("_show_editor_preview")


func _show_editor_preview() -> void:
	if not Engine.is_editor_hint() or not is_node_ready():
		return
	visible = show_editor_preview and font_catalog.editor_preview_enabled
	if not visible:
		return
	_snapshot = ProgressionPreviewBuilderScript.build(self)
	_refresh_page_badges(_snapshot["unread_progression_pages"])
	_show_page(font_catalog.editor_preview_page)


func open(snapshot: Dictionary) -> void:
	_snapshot = snapshot
	_refresh_page_badges(_snapshot.get("unread_progression_pages", []))
	visible = true
	_show_page(_page)
	page_buttons[_page].grab_focus()


func _setup_page_badges() -> void:
	var template := %StatsNotification as TextureRect
	_page_badges.append(template)
	for index in range(1, page_buttons.size()):
		var badge := template.duplicate() as TextureRect
		badge.name = "Notification"
		page_buttons[index].add_child(badge)
		_page_badges.append(badge)
	for badge in _page_badges:
		badge.visible = false


func _copy_notification_placement() -> void:
	if not is_node_ready() or _page_badges.is_empty():
		return
	for badge in _page_badges:
		badge.position = PANEL_NOTIFICATION_RECT.position
		badge.size = PANEL_NOTIFICATION_RECT.size


func _refresh_page_badges(unread_pages: Array) -> void:
	for index in _page_badges.size():
		_page_badges[index].visible = unread_pages.has(index)


func _on_page_button_pressed(page: int) -> void:
	_show_page(page)
	if page < _page_badges.size():
		_page_badges[page].visible = false
	page_viewed.emit(page)


func close() -> void:
	if not visible:
		return
	visible = false
	closed.emit()


func _show_page(page: int) -> void:
	_page = clampi(page, Page.HIGHSCORES, Page.FONTS)
	lock_filter.visible = SHOW_LOCK_FILTER and _page != Page.HIGHSCORES
	font_preview_scroll.visible = _page == Page.FONTS
	main_scroll.visible = _page != Page.FONTS
	cosmetic_lists.visible = _page == Page.FONTS
	for index in page_buttons.size():
		page_buttons[index].modulate = (
			SELECTED_COLOR if index == _page else Color.WHITE
		)
	_clear_content()
	match _page:
		Page.HIGHSCORES:
			title_label.text = "HIGHSCORES"
			_populate_highscores()
		Page.ACHIEVEMENTS:
			title_label.text = "ACHIEVEMENTS"
			_populate_achievements()
		Page.BONUSES:
			title_label.text = "BONUSES"
			_populate_discoveries(_snapshot.get("bonuses", []))
		Page.SPECIAL_RULES:
			title_label.text = "SPECIAL RULES"
			_populate_discoveries(_snapshot.get("special_rules", []))
		Page.FONTS:
			title_label.text = "FONTS"
			_populate_fonts()


func _clear_content() -> void:
	for target in [content, fonts_content, palettes_content]:
		for child in target.get_children():
			target.remove_child(child)
			child.queue_free()


func _populate_highscores() -> void:
	var scores: Array = _snapshot.get("highscores", [])
	for score_value in scores:
		var score := score_value as Dictionary
		_add_entry(str(score.get("title", "")), str(score.get("value", "--")), true)


func _populate_achievements() -> void:
	var achievements: Array = _snapshot.get("achievements", [])
	var current_category := ""
	for achievement_value in achievements:
		var achievement := achievement_value as Dictionary
		var unlocked := bool(achievement.get("unlocked", false))
		if not _matches_progress_filter(unlocked):
			continue
		var category := str(achievement.get("category", "ROUNDS"))
		if category != current_category:
			current_category = category
			_add_category_heading(category)
		var hidden := bool(achievement.get("hidden", false))
		var title := str(achievement.get("title", "???")) if unlocked or not hidden else "???"
		var description := str(achievement.get("description", "")) if unlocked or not hidden else "Hidden achievement"
		var progress := str(achievement.get("progress", ""))
		var progress_target := int(achievement.get("progress_target", 0))
		var shows_progress := (
			not progress.is_empty()
			and progress_target > 0
			and (unlocked or not hidden)
		)
		var progress_ratio := -1.0
		if shows_progress:
			progress_ratio = clampf(
				float(achievement.get("progress_current", 0)) / progress_target,
				0.0,
				1.0
			)
		var reward_font := StringName(achievement.get("reward_font", &""))
		if reward_font != &"" and (unlocked or not hidden):
			description += "\nReward: %s" % _font_display_name(reward_font)
		var unlock_date := str(achievement.get("date", ""))
		if unlocked and not unlock_date.is_empty():
			description += "\nUnlocked: %s" % unlock_date
		_add_entry(
			title,
			description,
			false,
			CHECKED_TEXTURE if unlocked else UNCHECKED_TEXTURE,
			not unlocked,
			"",
			false,
			progress_ratio,
			progress if shows_progress else "",
			bool(achievement.get("new", false))
		)


func _font_display_name(font_id: StringName) -> String:
	for font_data in font_catalog.available_fonts:
		if font_data != null and font_data.id == font_id:
			return font_data.display_name
	return String(font_id)


func _add_category_heading(category: String) -> void:
	var label := Label.new()
	label.text = category
	if entry_heading_font != null:
		label.add_theme_font_override("font", entry_heading_font)
	label.add_theme_font_size_override("font_size", entry_heading_font_size)
	label.add_theme_color_override("font_color", SELECTED_COLOR)
	content.add_child(label)


func _populate_discoveries(entries_value: Variant) -> void:
	var entries := entries_value as Array
	for entry_value in entries:
		var entry := entry_value as Dictionary
		var seen := bool(entry.get("seen", entry.get("discovered", false)))
		var discovered := bool(entry.get("discovered", false))
		var obtained := bool(entry.get("obtained", discovered))
		var max_level := int(entry.get("max_level", 1))
		var highest_level := int(entry.get("highest_level", 0))
		# A leveled bonus at zero was only seen, never acquired. This also
		# repairs inconsistent discovery data from older saves at display time.
		if max_level > 1 and highest_level <= 0:
			obtained = false
		if not _matches_progress_filter(obtained):
			continue
		var level_text := ""
		if obtained and max_level > 1:
			level_text = str(highest_level)
		_add_entry(
			str(entry.get("title", "")) if seen else "???",
			str(entry.get("description", "")) if obtained else "???",
			false,
			CHECKED_TEXTURE if obtained and max_level <= 1 else UNCHECKED_TEXTURE,
			not obtained,
			level_text,
			obtained and max_level > 1 and highest_level >= max_level,
			-1.0,
			"",
			bool(entry.get("new", false))
		)


func _populate_fonts() -> void:
	var fonts: Array = _snapshot.get("fonts", [])
	var palettes: Array = _snapshot.get("palettes", [])
	var preview_data: Dictionary = {}
	var ordered_fonts := fonts
	if Engine.is_editor_hint():
		ordered_fonts = _selected_first(fonts)
	for font_value in ordered_fonts:
		var font_data := font_value as Dictionary
		var unlocked := bool(font_data.get("unlocked", false))
		if unlocked and (preview_data.is_empty() or bool(font_data.get("selected", false))):
			preview_data = font_data
		if not _matches_progress_filter(unlocked):
			continue
		var selected := bool(font_data.get("selected", false))
		_add_cosmetic_choice(
			fonts_content,
			str(font_data.get("title", "FONT")),
			unlocked,
			selected,
			_select_font.bind(StringName(font_data.get("id", &""))),
			font_data.get("font") as Font,
			[],
			int(font_data.get(
				"title_font_size",
				font_data.get("font_size", entry_heading_font_size)
			)),
			_vector2_or_zero(font_data.get("title_font_offset"))
		)
	var ordered_palettes := palettes
	if Engine.is_editor_hint():
		ordered_palettes = _selected_first(palettes)
	for palette_value in ordered_palettes:
		var palette_data := palette_value as Dictionary
		var palette_unlocked := bool(palette_data.get("unlocked", false))
		var palette_selected_now := bool(palette_data.get("selected", false))
		if palette_selected_now:
			preview_data["colors"] = palette_data.get("colors", [])
		if not _matches_progress_filter(palette_unlocked):
			continue
		_add_cosmetic_choice(
			palettes_content,
			str(palette_data.get("title", "PALETTE")),
			palette_unlocked,
			palette_selected_now,
			_select_palette.bind(StringName(palette_data.get("id", &""))),
			null,
			palette_data.get("colors", []) as Array
		)
	_update_font_preview(preview_data)


func _selected_first(entries: Array) -> Array:
	var ordered: Array = []
	for entry_value in entries:
		if bool((entry_value as Dictionary).get("selected", false)):
			ordered.append(entry_value)
	for entry_value in entries:
		if not bool((entry_value as Dictionary).get("selected", false)):
			ordered.append(entry_value)
	return ordered


func _vector2_or_zero(value: Variant) -> Vector2:
	if value is Vector2:
		return value
	if value is Vector2i:
		return Vector2(value)
	return Vector2.ZERO


func _add_cosmetic_choice(
	target: VBoxContainer,
	title: String,
	unlocked: bool,
	selected: bool,
	selection: Callable,
	choice_font: Font = null,
	palette_colors: Array = [],
	choice_font_size := -1,
	choice_font_offset := Vector2.ZERO
) -> void:
	var button := Button.new()
	button.set_script(HighlightButtonScript)
	button.set("highlight_material", font_button_highlight_material)
	button.custom_minimum_size.y = 24.0
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.flat = true
	button.icon = SELECTED_TEXTURE if selected else UNCHECKED_TEXTURE
	var displayed_title := title if unlocked else "???"
	button.text = displayed_title
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var displayed_font := choice_font if choice_font != null else entry_heading_font
	if displayed_font != null:
		button.add_theme_font_override("font", displayed_font)
	button.add_theme_font_size_override(
		"font_size",
		choice_font_size if choice_font_size > 0 else entry_heading_font_size
	)
	for color_name in [
		&"font_color", &"font_hover_color", &"font_pressed_color",
		&"font_disabled_color"
	]:
		button.add_theme_color_override(color_name, Color("3c3c3c"))
	button.modulate = Color.WHITE
	button.disabled = not unlocked
	if unlocked and not selected:
		button.pressed.connect(selection)
	target.add_child(button)
	if not palette_colors.is_empty():
		_add_palette_title(button, displayed_title, palette_colors, displayed_font)
	elif unlocked and choice_font != null:
		_add_font_title(
			button,
			displayed_title,
			displayed_font,
			choice_font_size if choice_font_size > 0 else entry_heading_font_size,
			choice_font_offset
		)


func _add_font_title(
	button: Button, title: String, font: Font, font_size: int, font_offset: Vector2
) -> void:
	button.text = ""
	var label := Label.new()
	label.name = "FontTitle"
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	label.offset_left = 18.0 + font_offset.x
	label.offset_right += font_offset.x
	label.offset_top += font_offset.y
	label.offset_bottom += font_offset.y
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.text = title
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color("3c3c3c"))
	button.add_child(label)


func _add_palette_title(
	button: Button, title: String, colors: Array, font: Font
) -> void:
	button.text = ""
	var label := RichTextLabel.new()
	label.name = "PaletteTitle"
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	label.offset_left = 18.0
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.fit_content = false
	label.scroll_active = false
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.use_parent_material = true
	if font != null:
		label.add_theme_font_override("normal_font", font)
	label.add_theme_font_size_override("normal_font_size", entry_heading_font_size)
	label.set_meta("palette_colors", colors.duplicate())
	for index in title.length():
		label.push_color(colors[index % colors.size()] as Color)
		label.add_text(title.substr(index, 1))
		label.pop()
	button.add_child(label)
	button.resized.connect(_resize_palette_choice.bind(button, label))
	call_deferred("_resize_palette_choice", button, label)


func _resize_palette_choice(button: Button, label: RichTextLabel) -> void:
	if not is_instance_valid(button) or not is_instance_valid(label):
		return
	# The full-rect anchors already give the label its final wrapped width.
	var required_height := maxf(24.0, ceilf(label.get_content_height()) + 4.0)
	if not is_equal_approx(button.custom_minimum_size.y, required_height):
		button.custom_minimum_size.y = required_height


func _update_font_preview(font_data: Dictionary) -> void:
	for child in font_preview.get_children():
		font_preview.remove_child(child)
		child.queue_free()
	if font_data.is_empty():
		return
	var font := font_data.get("font") as Font
	var font_size := int(font_data.get("font_size", 20))
	var font_offset := _vector2_or_zero(font_data.get("font_offset"))
	var override_hidden_tile := true
	var override_hidden_value: Variant = font_data.get(
		"override_hidden_tile_with_font", true
	)
	if override_hidden_value is bool:
		override_hidden_tile = override_hidden_value
	var colors: Array = font_data.get("colors", [])
	var maximum_value := clampi(
		int(_snapshot.get("max_discovered_tile_value", 3)), 0, 9
	)
	var preview_values: Array[Variant] = ["?"]
	for value in range(maximum_value + 1):
		preview_values.append(value)
	for preview_index in preview_values.size():
		var value: Variant = preview_values[preview_index]
		var is_hidden_tile := preview_index == 0
		var tile := TextureRect.new()
		tile.custom_minimum_size = Vector2(34.0, 37.0)
		tile.texture = (
			TILE_FACE_TEXTURE if is_hidden_tile and override_hidden_tile
			else TILE_BACK_TEXTURE if is_hidden_tile
			else TILE_FACE_TEXTURE
		)
		tile.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		tile.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tile.stretch_mode = TextureRect.STRETCH_SCALE
		if is_hidden_tile and not override_hidden_tile:
			font_preview.add_child(tile)
			continue
		var tile_material := font_preview_tile_material.duplicate() as ShaderMaterial
		var color_index := int(value) if not is_hidden_tile else 0
		var tile_color: Color = (
			Color("b8b8b8")
			if is_hidden_tile
			else colors[color_index % colors.size()]
			if not colors.is_empty()
			else Settings.TILE_COLORS[color_index % Settings.TILE_COLORS.size()]
		)
		tile_material.set_shader_parameter("tile_color", tile_color)
		tile.material = tile_material
		var label := Label.new()
		label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		# Match the two-pixel optical lift used by Card and Pile value labels.
		label.offset_left = font_offset.x
		label.offset_right = font_offset.x
		label.offset_top = font_offset.y
		label.offset_bottom = font_offset.y - 2.0
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.text = "?" if is_hidden_tile else str(value)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_color_override(
			"font_color", tile_color if is_hidden_tile else tile_color.darkened(0.35)
		)
		label.add_theme_font_size_override("font_size", font_size)
		if font != null:
			label.add_theme_font_override("font", font)
		tile.add_child(label)
		font_preview.add_child(tile)


func _select_font(font_id: StringName) -> void:
	font_selected.emit(font_id)


func _select_palette(palette_id: StringName) -> void:
	palette_selected.emit(palette_id)


func _on_filter_selected(_index: int) -> void:
	_show_page(_page)


func _matches_progress_filter(unlocked: bool) -> bool:
	match lock_filter.mode:
		ProgressFilter.UNLOCKED:
			return unlocked
		ProgressFilter.LOCKED:
			return not unlocked
		_:
			return true


func _add_entry(
	heading: String,
	details: String,
	accent := false,
	status_texture: Texture2D = null,
	muted := false,
	status_text := "",
	gold_status := false,
	progress_ratio := -1.0,
	progress_tooltip := "",
	is_new := false
) -> void:
	var entry := VBoxContainer.new()
	entry.add_theme_constant_override("separation", 1)
	var heading_row := HBoxContainer.new()
	heading_row.add_theme_constant_override("separation", 3)
	if is_new:
		var new_label := Label.new()
		new_label.name = "NewLabel"
		new_label.text = "NEW"
		new_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		if entry_details_font != null:
			new_label.add_theme_font_override("font", entry_details_font)
		new_label.add_theme_font_size_override("font_size", entry_details_font_size)
		new_label.add_theme_color_override("font_color", SELECTED_COLOR)
		heading_row.add_child(new_label)
	if status_texture != null:
		var status_icon := TextureRect.new()
		status_icon.custom_minimum_size = Vector2(12.0, 13.0)
		status_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		status_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		status_icon.texture = status_texture
		status_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		status_icon.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
		status_icon.modulate.a = LOCKED_ENTRY_OPACITY if muted else 1.0
		if gold_status:
			var shader := Shader.new()
			shader.code = GOLD_STATUS_SHADER
			var material := ShaderMaterial.new()
			material.shader = shader
			status_icon.material = material
		heading_row.add_child(status_icon)
		if not status_text.is_empty():
			var level_label := Label.new()
			level_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			level_label.offset_left += bonus_level_text_offset.x
			level_label.offset_right += bonus_level_text_offset.x
			level_label.offset_top += bonus_level_text_offset.y
			level_label.offset_bottom += bonus_level_text_offset.y
			level_label.text = status_text
			level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			level_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			if bonus_level_font != null:
				level_label.add_theme_font_override("font", bonus_level_font)
			elif entry_details_font != null:
				level_label.add_theme_font_override("font", entry_details_font)
			level_label.add_theme_font_size_override("font_size", bonus_level_font_size)
			level_label.add_theme_color_override("font_color", Color.WHITE)
			status_icon.add_child(level_label)
	elif not status_text.is_empty():
		var status_label := Label.new()
		status_label.text = status_text
		status_label.custom_minimum_size.x = 31.0
		status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		if entry_details_font != null:
			status_label.add_theme_font_override("font", entry_details_font)
		status_label.add_theme_font_size_override(
			"font_size", entry_details_font_size
		)
		status_label.add_theme_color_override("font_color", SELECTED_COLOR)
		status_label.modulate.a = LOCKED_ENTRY_OPACITY if muted else 1.0
		heading_row.add_child(status_label)
	var heading_label := Label.new()
	heading_label.text = heading
	heading_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	if entry_heading_font != null:
		heading_label.add_theme_font_override("font", entry_heading_font)
	heading_label.add_theme_font_size_override("font_size", entry_heading_font_size)
	var heading_offset_style := StyleBoxEmpty.new()
	heading_offset_style.content_margin_left = entry_heading_text_offset.x
	heading_offset_style.content_margin_top = entry_heading_text_offset.y
	heading_label.add_theme_stylebox_override("normal", heading_offset_style)
	heading_label.add_theme_color_override(
		"font_color",
		Color("4d82c2") if accent else Color("3c3c3c")
	)
	heading_label.modulate.a = LOCKED_ENTRY_OPACITY if muted else 1.0
	var details_label := Label.new()
	details_label.text = details
	details_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if entry_details_font != null:
		details_label.add_theme_font_override("font", entry_details_font)
	details_label.add_theme_font_size_override("font_size", entry_details_font_size)
	details_label.add_theme_color_override("font_color", Color("8a8882"))
	details_label.modulate.a = LOCKED_ENTRY_OPACITY if muted else 1.0
	heading_row.add_child(heading_label)
	entry.add_child(heading_row)
	entry.add_child(details_label)
	if progress_ratio >= 0.0:
		_add_progress_bar(entry, progress_ratio, progress_tooltip)
	content.add_child(entry)


func _add_progress_bar(
	entry: VBoxContainer, progress_ratio: float, progress_tooltip: String
) -> void:
	var bar := NinePatchRect.new()
	bar.set_script(ProgressionCompletionBarScript)
	bar.custom_minimum_size.y = 6.0
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	bar.texture = PROGRESS_BAR_TEXTURE
	bar.patch_margin_left = 2
	bar.patch_margin_top = 2
	bar.patch_margin_right = 2
	bar.patch_margin_bottom = 2
	bar.mouse_default_cursor_shape = Control.CURSOR_HELP
	bar.tooltip_text = progress_tooltip
	bar.set("progress_hint", progress_tooltip)
	var shader := Shader.new()
	shader.code = PROGRESS_BAR_SHADER
	var material := ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("progress", clampf(progress_ratio, 0.0, 1.0))
	bar.material = material
	bar.mouse_entered.connect(_set_progress_bar_highlight.bind(material, true))
	bar.mouse_exited.connect(_set_progress_bar_highlight.bind(material, false))
	entry.add_child(bar)


func _set_progress_bar_highlight(
	material: ShaderMaterial, highlighted: bool
) -> void:
	material.set_shader_parameter("highlighted", 1.0 if highlighted else 0.0)


func refresh(snapshot: Dictionary) -> void:
	_snapshot = snapshot
	_show_page(_page)
