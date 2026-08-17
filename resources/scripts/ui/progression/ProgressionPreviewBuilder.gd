class_name ProgressionPreviewBuilder
extends RefCounted


static func build(menu: ProgressionMenu) -> Dictionary:
	var catalog := menu.font_catalog
	var preview_font: Font = menu.entry_heading_font
	var preview_font_size := 20
	var preview_font_offset := Vector2.ZERO
	var preview_title_font_offset := Vector2.ZERO
	var preview_title_font_size := 20
	var preview_override_hidden_tile := false
	var preview_font_title := "CURRENT FONT"
	if catalog.editor_preview_font != null:
		var editor_font := catalog.editor_preview_font
		preview_font = editor_font.font
		preview_font_size = editor_font.tile_font_size
		preview_font_offset = editor_font.tile_font_offset
		preview_title_font_offset = editor_font.title_font_offset
		preview_title_font_size = (
			editor_font.title_font_size
			if editor_font.title_font_size > 0
			else editor_font.tile_font_size
		)
		preview_override_hidden_tile = editor_font.override_hidden_tile_with_font
		preview_font_title = editor_font.display_name
	var preview_palettes: Array[Dictionary] = []
	if catalog.editor_preview_palette != null:
		var editor_palette := catalog.editor_preview_palette
		preview_palettes.append({
			"id": editor_palette.id,
			"title": editor_palette.display_name,
			"colors": editor_palette.colors.duplicate(),
			"unlocked": true,
			"selected": true,
		})
	return {
		"max_discovered_tile_value": catalog.editor_preview_tile_count - 1,
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
				"progress": "Rounds completed: 6 / 10",
				"progress_current": 6,
				"progress_target": 10,
			},
			{
				"title": "PERFECT ROUND",
				"description": "Complete a round without a mistake.",
				"hidden": false,
				"unlocked": false,
			},
		],
		"bonuses": [
			{
				"title": "OPEN BOOK",
				"description": "Pile values stay visible.",
				"seen": true,
				"discovered": true,
				"highest_level": 3,
				"max_level": 3,
			},
			{
				"title": "REDRAW", "description": "", "seen": true,
				"discovered": false, "max_level": 3,
			},
		],
		"special_rules": [
			{
				"title": "LIGHTS OUT",
				"description": "Darkness covers the board except around your pointer.",
				"discovered": true,
				"obtained": false,
			},
			{"title": "UNKNOWN", "description": "", "discovered": false},
		],
		"fonts": [
			{
				"id": &"preview",
				"title": preview_font_title,
				"font": preview_font,
				"font_size": preview_font_size,
				"font_offset": preview_font_offset,
				"title_font_offset": preview_title_font_offset,
				"title_font_size": preview_title_font_size,
				"override_hidden_tile_with_font": preview_override_hidden_tile,
				"unlocked": true,
				"selected": true,
			},
			{
				"id": &"locked", "title": "LOCKED FONT",
				"unlocked": false, "selected": false,
			},
		],
		"palettes": preview_palettes,
		"unread_progression_pages": [ProgressionMenu.Page.ACHIEVEMENTS],
	}
