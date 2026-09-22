class_name ThemePaletteData
extends Resource

@export var id: StringName
@export var display_name: String
@export var tile_colors: Array[Color] = []

@export var ui_bg_color: Color = Color("f7f6f2")
@export var ui_panel_color: Color = Color("ffffff")
@export var ui_panel_alt_color: Color = Color("e8edf3")
@export var ui_text_color: Color = Color("3c3c3c")
@export var ui_muted_text_color: Color = Color("8a8882")
@export var ui_button_color: Color = Color("4d82c2")
@export var ui_button_hover_color: Color = Color("6da7e5")
@export var ui_button_text_color: Color = Color("ffffff")
@export var ui_accent_color: Color = Color("4d82c2")
@export var bg_base_color: Color = Color("f7f6f2")
@export var bg_secondary_color: Color = Color(0.31, 0.49, 0.72, 0.16)


func normalized_tile_colors() -> Array[Color]:
	var result := tile_colors.duplicate()
	if result.is_empty():
		result.assign(GameSettings.TILE_COLORS.slice(0, 10))
	while result.size() < 10:
		result.append(result[result.size() % maxi(result.size(), 1)])
	result.resize(10)
	return result
