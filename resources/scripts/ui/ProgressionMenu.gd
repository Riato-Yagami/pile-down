@tool
class_name ProgressionMenu
extends Control

signal closed()
signal font_selected(font_id: StringName)

const CHECKED_TEXTURE := preload(
	"res://resources/sprites/ui/check/checked.png"
)
const UNCHECKED_TEXTURE := preload(
	"res://resources/sprites/ui/check/unchecked.png"
)
const TILE_FACE_TEXTURE := preload(
	"res://resources/sprites/tiles/tile-face.png"
)
const Settings := preload("res://resources/scripts/settings/settings.gd")
const SELECTED_COLOR := Color("4d82c2")
const LOCKED_ENTRY_OPACITY := 0.55

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

@export_category("Editor Preview")
@export var editor_preview_enabled := true:
	set(value):
		editor_preview_enabled = value
		_refresh_editor_preview()
@export_enum("Highscores", "Achievements", "Bonuses", "Special Rules", "Fonts")
var editor_preview_page: int = Page.HIGHSCORES:
	set(value):
		editor_preview_page = clampi(value, Page.HIGHSCORES, Page.FONTS)
		_refresh_editor_preview()

@export_category("Entry Style")
@export var entry_heading_font: Font:
	set(value):
		entry_heading_font = value
		_refresh_editor_preview()
@export_range(8, 32, 1) var entry_heading_font_size := 15:
	set(value):
		entry_heading_font_size = value
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
@export_category("Font Preview")
@export_range(1, 9, 1) var font_preview_tile_count := 9:
	set(value):
		font_preview_tile_count = clampi(value, 1, 9)
		_refresh_editor_preview()
@export var font_preview_tile_material: ShaderMaterial

@onready var title_label: Label = %PageTitle
@onready var filter_button: OptionButton = %FilterButton
@onready var font_preview_scroll: ScrollContainer = %FontPreviewScroll
@onready var font_preview: HBoxContainer = %FontPreview
@onready var content: VBoxContainer = %PageContent
@onready var page_buttons: Array[TextureButton] = [
	%HighscoresButton,
	%AchievementsButton,
	%BonusesButton,
	%SpecialRulesButton,
	%FontsButton,
]

var _snapshot: Dictionary = {}
var _page := Page.HIGHSCORES


func _ready() -> void:
	filter_button.clear()
	filter_button.add_item("BOTH", ProgressFilter.BOTH)
	filter_button.add_item("UNLOCKED", ProgressFilter.UNLOCKED)
	filter_button.add_item("LOCKED", ProgressFilter.LOCKED)
	filter_button.select(ProgressFilter.BOTH)
	filter_button.item_selected.connect(_on_filter_selected)
	for index in page_buttons.size():
		var show_callable := _show_page.bind(index)
		if not page_buttons[index].pressed.is_connected(show_callable):
			page_buttons[index].pressed.connect(show_callable)
	if not %BackButton.pressed.is_connected(close):
		%BackButton.pressed.connect(close)
	if Engine.is_editor_hint():
		_show_editor_preview()
	else:
		visible = false


func _refresh_editor_preview() -> void:
	if Engine.is_editor_hint() and is_node_ready():
		call_deferred("_show_editor_preview")


func _show_editor_preview() -> void:
	if not Engine.is_editor_hint() or not is_node_ready():
		return
	visible = editor_preview_enabled
	if not editor_preview_enabled:
		return
	_snapshot = {
		"highscores": [
			{"title": "CLASSIC", "value": "12 ROUNDS LEFT"},
			{"title": "ENDLESS", "value": "ROUND 24"},
			{"title": "CHECKPOINTS", "value": "8 ROUNDS LEFT"},
		],
		"achievements": [
			{
				"title": "FIRST STEPS",
				"description": "Complete your first round.",
				"hidden": false,
				"unlocked": true,
			},
			{
				"title": "PERFECT ROUND",
				"description": "Complete a round without a mistake.",
				"hidden": false,
				"unlocked": false,
			},
		],
		"bonuses": [
			{"title": "OPEN BOOK", "description": "Pile values stay visible.", "discovered": true},
			{"title": "REDRAW", "description": "", "discovered": false},
		],
		"special_rules": [
			{
				"title": "LIGHTS OUT",
				"description": "Darkness covers the board except around your pointer.",
				"discovered": true,
			},
			{"title": "UNKNOWN", "description": "", "discovered": false},
		],
		"fonts": [
			{
				"id": &"preview",
				"title": "CURRENT FONT",
				"font": entry_heading_font,
				"font_size": 20,
				"unlocked": true,
				"selected": true,
			},
			{"id": &"locked", "title": "LOCKED FONT", "unlocked": false, "selected": false},
		],
	}
	_show_page(editor_preview_page)


func open(snapshot: Dictionary) -> void:
	_snapshot = snapshot
	visible = true
	_show_page(_page)
	page_buttons[_page].grab_focus()


func close() -> void:
	if not visible:
		return
	visible = false
	closed.emit()


func _show_page(page: int) -> void:
	_page = clampi(page, Page.HIGHSCORES, Page.FONTS)
	filter_button.visible = _page != Page.HIGHSCORES
	font_preview_scroll.visible = _page == Page.FONTS
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
	for child in content.get_children():
		content.remove_child(child)
		child.queue_free()


func _populate_highscores() -> void:
	var scores: Array = _snapshot.get("highscores", [])
	for score_value in scores:
		var score := score_value as Dictionary
		_add_entry(str(score.get("title", "")), str(score.get("value", "--")), true)


func _populate_achievements() -> void:
	var achievements: Array = _snapshot.get("achievements", [])
	for achievement_value in achievements:
		var achievement := achievement_value as Dictionary
		var unlocked := bool(achievement.get("unlocked", false))
		if not _matches_progress_filter(unlocked):
			continue
		var hidden := bool(achievement.get("hidden", false))
		var title := str(achievement.get("title", "???")) if unlocked or not hidden else "???"
		var description := str(achievement.get("description", "")) if unlocked or not hidden else "UNKNOWN ACHIEVEMENT"
		_add_entry(
			title,
			description,
			false,
			CHECKED_TEXTURE if unlocked else UNCHECKED_TEXTURE,
			not unlocked
		)


func _populate_discoveries(entries_value: Variant) -> void:
	var entries := entries_value as Array
	for entry_value in entries:
		var entry := entry_value as Dictionary
		var discovered := bool(entry.get("discovered", false))
		if not _matches_progress_filter(discovered):
			continue
		_add_entry(
			str(entry.get("title", "")) if discovered else "???",
			str(entry.get("description", "")) if discovered else "NOT DISCOVERED",
			false,
			CHECKED_TEXTURE if discovered else UNCHECKED_TEXTURE,
			not discovered
		)


func _populate_fonts() -> void:
	var fonts: Array = _snapshot.get("fonts", [])
	var preview_data: Dictionary = {}
	for font_value in fonts:
		var font_data := font_value as Dictionary
		var unlocked := bool(font_data.get("unlocked", false))
		if unlocked and (preview_data.is_empty() or bool(font_data.get("selected", false))):
			preview_data = font_data
		if not _matches_progress_filter(unlocked):
			continue
		var selected := bool(font_data.get("selected", false))
		var entry := VBoxContainer.new()
		entry.add_theme_constant_override("separation", 3)
		var button := HighlightButton.new()
		button.custom_minimum_size = Vector2(86.0, 31.0)
		button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		button.highlight_material = font_button_highlight_material
		for state in [&"normal", &"hover", &"disabled"]:
			button.add_theme_stylebox_override(state, font_button_style)
		for state in [&"font_color", &"font_hover_color", &"font_disabled_color"]:
			button.add_theme_color_override(state, Color.WHITE)
		if entry_heading_font != null:
			button.add_theme_font_override("font", entry_heading_font)
		button.add_theme_font_size_override("font_size", entry_heading_font_size)
		button.text = (
			str(font_data.get("title", "FONT"))
			if unlocked
			else "LOCKED FONT"
		)
		button.modulate = SELECTED_COLOR if selected else Color.WHITE
		button.disabled = not unlocked or selected
		if unlocked and not selected:
			button.pressed.connect(
				_select_font.bind(StringName(font_data.get("id", &"")))
			)
		entry.add_child(button)
		content.add_child(entry)
	_update_font_preview(preview_data)


func _update_font_preview(font_data: Dictionary) -> void:
	for child in font_preview.get_children():
		font_preview.remove_child(child)
		child.queue_free()
	if font_data.is_empty():
		return
	var font := font_data.get("font") as Font
	var font_size := clampi(int(font_data.get("font_size", 20)), 8, 32)
	for value in range(1, font_preview_tile_count + 1):
		var tile := TextureRect.new()
		tile.custom_minimum_size = Vector2(34.0, 37.0)
		tile.texture = TILE_FACE_TEXTURE
		tile.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		tile.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tile.stretch_mode = TextureRect.STRETCH_SCALE
		var tile_material := font_preview_tile_material.duplicate() as ShaderMaterial
		var tile_color: Color = Settings.TILE_COLORS[value % Settings.TILE_COLORS.size()]
		tile_material.set_shader_parameter("tile_color", tile_color)
		tile.material = tile_material
		var label := Label.new()
		label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.text = str(value)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_color_override("font_color", tile_color.darkened(0.35))
		label.add_theme_font_size_override("font_size", font_size)
		if font != null:
			label.add_theme_font_override("font", font)
		tile.add_child(label)
		font_preview.add_child(tile)


func _select_font(font_id: StringName) -> void:
	font_selected.emit(font_id)


func _on_filter_selected(_index: int) -> void:
	_show_page(_page)


func _matches_progress_filter(unlocked: bool) -> bool:
	match filter_button.get_selected_id():
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
	muted := false
) -> void:
	var entry := VBoxContainer.new()
	entry.add_theme_constant_override("separation", 1)
	var heading_row := HBoxContainer.new()
	heading_row.add_theme_constant_override("separation", 3)
	if status_texture != null:
		var status_icon := TextureRect.new()
		status_icon.custom_minimum_size = Vector2(12.0, 13.0)
		status_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		status_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		status_icon.texture = status_texture
		status_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		status_icon.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
		status_icon.modulate.a = LOCKED_ENTRY_OPACITY if muted else 1.0
		heading_row.add_child(status_icon)
	var heading_label := Label.new()
	heading_label.text = heading
	heading_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	if entry_heading_font != null:
		heading_label.add_theme_font_override("font", entry_heading_font)
	heading_label.add_theme_font_size_override("font_size", entry_heading_font_size)
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
	content.add_child(entry)


func refresh(snapshot: Dictionary) -> void:
	_snapshot = snapshot
	_show_page(_page)
