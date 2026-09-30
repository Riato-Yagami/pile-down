class_name ThemePaletteData
extends Resource

@export var id: StringName
@export var display_name: String
@export var tile_colors: Array[Color] = []

@export var ui_bg_color: Color = GameColors.MENU_BACKGROUND
@export var ui_panel_color: Color = GameColors.WHITE
@export var ui_panel_alt_color: Color = GameColors.PANEL_ALT
@export var ui_text_color: Color = GameColors.TEXT
@export var ui_muted_text_color: Color = GameColors.TEXT_MUTED
@export var ui_button_color: Color = GameColors.ACCENT
@export var ui_button_hover_color: Color = GameColors.ACCENT_HOVER
@export var ui_button_text_color: Color = GameColors.WHITE
@export var ui_accent_color: Color = GameColors.ACCENT
@export var bg_base_color: Color = GameColors.MENU_BACKGROUND
@export var bg_secondary_color: Color = GameColors.BACKGROUND_PATTERN


func normalized_tile_colors() -> Array[Color]:
	var result := tile_colors.duplicate()
	if result.is_empty():
		result.assign(GameSettings.TILE_COLORS.slice(0, 10))
	while result.size() < 10:
		result.append(result[result.size() % maxi(result.size(), 1)])
	result.resize(10)
	return result
