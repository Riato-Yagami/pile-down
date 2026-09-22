@tool
class_name ProgressionMenu
extends "res://resources/scripts/ui/MenuPanelLayout.gd"

signal closed()
signal font_selected(font_id: StringName)
signal palette_selected(palette_id: StringName)
signal page_viewed(page: int)

const ProgressionCosmeticsViewScript := preload(
	"res://resources/scripts/ui/progression/ProgressionCosmeticsView.gd"
)
const ProgressionEntryBuilderScript := preload(
	"res://resources/scripts/ui/progression/ProgressionEntryBuilder.gd"
)

const CHECKED_TEXTURE := preload(
	"res://resources/materials/textures/ui/check/checked.tres"
)
const UNCHECKED_TEXTURE := preload(
	"res://resources/sprites/ui/check/unchecked.png"
)
const SELECTED_TEXTURE := preload(
	"res://resources/materials/textures/ui/check/selected.tres"
)
const HighlightButtonScript := preload(
	"res://resources/scripts/ui/HighlightButton.gd"
)
const SELECTABLE_TEXT_SCENE := preload("res://resources/scenes/ui/SelectableText.tscn")
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
const ProgressionPreviewBuilderScript := preload(
	"res://resources/scripts/ui/progression/ProgressionPreviewBuilder.gd"
)
const PixelUiScript := preload("res://resources/scripts/ui/PixelUi.gd")
const SubmenuPageAnimatorScript := preload(
	"res://resources/scripts/ui/SubmenuPageAnimator.gd"
)
const PROGRESS_BAR_SHADER := preload("res://resources/shaders/ui/ProgressionFill.gdshader")
const Settings := preload("res://resources/scripts/settings/settings.gd")
const SELECTED_COLOR := Color("4d82c2")
const SELECTION_TEXT_COLOR := SELECTED_COLOR
const LOCKED_ENTRY_OPACITY := 0.55
# The main icon is 23x25. Panel buttons are 30x34 and center that same texture,
# so its notification needs the rounded (3.5, 4.5) centering compensation.
const PANEL_NOTIFICATION_RECT := Rect2(0.0, 21.0, 10.0, 11.0)
# Kept for a possible later reactivation of the LOCKED/BOTH/UNLOCKED control.
const SHOW_LOCK_FILTER := true
const GOLD_STATUS_SHADER := preload("res://resources/shaders/ui/GoldStatus.gdshader")

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
@export_category("Page Transition")
@export_range(0.05, 0.5, 0.01, "suffix:s") var page_transition_duration := 0.18
@export_range(4.0, 64.0, 1.0, "suffix:px") var page_transition_distance := 18.0
@export_range(0.05, 0.5, 0.01, "suffix:s") var lock_transition_duration := 0.16

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
@onready var page_panel: VBoxContainer = $Margin/Layout/Body/Page
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
var _page_animator := SubmenuPageAnimatorScript.new()
var _lock_visibility_tween: Tween
var _lock_visibility_generation := 0


func get_available_fonts() -> Array[FontData]:
	return font_catalog.get_available_fonts()


func get_achievements() -> Array[AchievementData]:
	return achievement_catalog.get_achievements()


func get_available_palettes() -> Array[ColorPaletteData]:
	return font_catalog.get_available_palettes()


func get_default_font() -> FontData:
	return font_catalog.default_font


func get_default_palette() -> ColorPaletteData:
	return font_catalog.default_palette


func _ready() -> void:
	apply_panel_layout()
	_page_animator.duration = page_transition_duration
	_page_animator.travel_distance = page_transition_distance
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
	resized.connect(_constrain_list_widths)
	visibility_changed.connect(preserve_panel_rect)
	if Engine.is_editor_hint() and show_editor_preview:
		_show_editor_preview()
	else:
		visible = false


func _style_vertical_scrollbars() -> void:
	var scrolls: Array[ScrollContainer] = [
		main_scroll, fonts_scroll, palettes_scroll,
	]
	for scroll in scrolls:
		PixelUiScript.style_scroll_container(
			scroll, VERTICAL_SCROLL_TRACK_TEXTURE,
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
	_show_page(page, true)
	if page < _page_badges.size():
		_page_badges[page].visible = false
	page_viewed.emit(page)


func close() -> void:
	if not visible:
		return
	visible = false
	closed.emit()


func _show_page(page: int, animate := false) -> void:
	preserve_panel_rect()
	var previous_page := _page
	_page = clampi(page, Page.HIGHSCORES, Page.FONTS)
	_set_lock_filter_visible(
		SHOW_LOCK_FILTER and _page != Page.HIGHSCORES,
		animate
	)
	font_preview_scroll.visible = _page == Page.FONTS
	font_preview_scroll.modulate.a = 1.0
	font_preview_scroll.mouse_filter = (
		Control.MOUSE_FILTER_STOP
		if _page == Page.FONTS
		else Control.MOUSE_FILTER_IGNORE
	)
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
	if animate and previous_page != _page:
		_page_animator.play(page_panel, signi(_page - previous_page))
	_constrain_list_widths()


func _set_lock_filter_visible(should_show: bool, animate: bool) -> void:
	_lock_visibility_generation += 1
	var generation := _lock_visibility_generation
	if _lock_visibility_tween != null and _lock_visibility_tween.is_valid():
		_lock_visibility_tween.kill()
	_lock_visibility_tween = null
	lock_filter.pivot_offset = lock_filter.size * 0.5
	if not animate or lock_transition_duration <= 0.0:
		lock_filter.visible = should_show
		lock_filter.modulate.a = 1.0
		lock_filter.scale = Vector2.ONE
		return
	if should_show:
		if lock_filter.visible and is_equal_approx(lock_filter.modulate.a, 1.0):
			return
		lock_filter.visible = true
		lock_filter.modulate.a = 0.0
		lock_filter.scale = Vector2(0.8, 0.8)
	else:
		if not lock_filter.visible:
			return
		lock_filter.modulate.a = 1.0
		lock_filter.scale = Vector2.ONE
	_lock_visibility_tween = create_tween().set_parallel(true)
	_lock_visibility_tween.set_trans(Tween.TRANS_QUAD).set_ease(
		Tween.EASE_OUT if should_show else Tween.EASE_IN
	)
	_lock_visibility_tween.tween_property(
		lock_filter, "modulate:a", 1.0 if should_show else 0.0,
		lock_transition_duration
	)
	_lock_visibility_tween.tween_property(
		lock_filter, "scale", Vector2.ONE if should_show else Vector2(0.8, 0.8),
		lock_transition_duration
	)
	_lock_visibility_tween.finished.connect(
		_finish_lock_visibility.bind(should_show, generation)
	)


func _finish_lock_visibility(should_show: bool, generation: int) -> void:
	if generation != _lock_visibility_generation:
		return
	lock_filter.visible = should_show
	lock_filter.modulate.a = 1.0
	lock_filter.scale = Vector2.ONE
	_lock_visibility_tween = null


func _constrain_list_widths() -> void:
	if not is_node_ready():
		return
	var list_width := _progression_list_width()
	for target in [content, fonts_content, palettes_content]:
		target.custom_minimum_size.x = 0.0
		target.size.x = list_width
		_constrain_wrap_labels(target, list_width)


func _progression_list_width() -> float:
	return panel_body_width(30.0, 5.0, 10.0)


func _constrain_wrap_labels(root: Node, list_width: float) -> void:
	if root is SelectableText:
		return
	for child in root.get_children():
		if child is Control:
			var control := child as Control
			if child.has_meta("progression_wrap_width"):
				var width := list_width - float(child.get_meta("progression_wrap_width"))
				control.custom_minimum_size.x = maxf(width, 24.0)
				control.size.x = control.custom_minimum_size.x
			elif child is Container:
				control.custom_minimum_size.x = 0.0
		_constrain_wrap_labels(child, list_width)


func _clear_content() -> void:
	for target in [content, fonts_content, palettes_content]:
		PixelUiScript.queue_free_children(target, true)


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
	for font_data in font_catalog.get_available_fonts():
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
	ProgressionCosmeticsViewScript.populate_fonts(self)


func _selected_first(entries: Array) -> Array:
	return ProgressionCosmeticsViewScript.selected_first(self, entries)


func _vector2_or_zero(value: Variant) -> Vector2:
	return ProgressionCosmeticsViewScript.vector2_or_zero(self, value)


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
	ProgressionCosmeticsViewScript.add_cosmetic_choice(
		self, target, title, unlocked, selected, selection, choice_font, palette_colors, choice_font_size, choice_font_offset
	)


func _add_font_title(
	button: Button, title: String, font: Font, font_size: int, font_offset: Vector2
) -> void:
	ProgressionCosmeticsViewScript.add_font_title(self, button, title, font, font_size, font_offset)


func _add_palette_title(
	button: Button, title: String, colors: Array, font: Font
) -> void:
	ProgressionCosmeticsViewScript.add_palette_title(self, button, title, colors, font)


func _connect_choice_title_highlight(button: Button, label: Control) -> void:
	ProgressionCosmeticsViewScript.connect_choice_title_highlight(self, button, label)


func _set_choice_title_highlight(label: Control, highlighted: bool) -> void:
	ProgressionCosmeticsViewScript.set_choice_title_highlight(self, label, highlighted)


func _resize_palette_choice(button: Button, label: RichTextLabel) -> void:
	ProgressionCosmeticsViewScript.resize_palette_choice(self, button, label)


func _resize_font_choice(button: Button, label: Label, font_offset: Vector2) -> void:
	ProgressionCosmeticsViewScript.resize_font_choice(self, button, label, font_offset)


func _update_font_preview(font_data: Dictionary) -> void:
	ProgressionCosmeticsViewScript.update_font_preview(self, font_data)


func _select_font(font_id: StringName) -> void:
	ProgressionCosmeticsViewScript.select_font(self, font_id)


func _select_palette(palette_id: StringName) -> void:
	ProgressionCosmeticsViewScript.select_palette(self, palette_id)


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
	ProgressionEntryBuilderScript.add_entry(
		self, heading, details, accent, status_texture, muted, status_text, gold_status, progress_ratio, progress_tooltip, is_new
	)


func _add_progress_bar(
	entry: VBoxContainer, progress_ratio: float, progress_tooltip: String
) -> void:
	ProgressionEntryBuilderScript.add_progress_bar(self, entry, progress_ratio, progress_tooltip)


func _set_progress_bar_highlight(
	material: ShaderMaterial, highlighted: bool
) -> void:
	ProgressionEntryBuilderScript.set_progress_bar_highlight(self, material, highlighted)


func refresh(snapshot: Dictionary) -> void:
	_snapshot = snapshot
	_show_page(_page)
