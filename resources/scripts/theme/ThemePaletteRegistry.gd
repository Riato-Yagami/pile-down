class_name ThemePaletteRegistry
extends RefCounted

const FIXED_BG_BASE_COLOR := GameColors.MENU_BACKGROUND
const FIXED_BG_SECONDARY_COLOR := GameColors.BACKGROUND_PATTERN


static func create_all(palettes: Array[ColorPaletteData] = []) -> Array[ThemePaletteData]:
	var palette_source := palettes
	if palette_source.is_empty():
		palette_source = ColorPaletteRegistry.create_all()
	var result: Array[ThemePaletteData] = []
	for palette in palette_source:
		if palette == null:
			continue
		result.append(from_color_palette(palette))
	return result


static func from_color_palette(palette: ColorPaletteData) -> ThemePaletteData:
	var theme := ThemePaletteData.new()
	theme.id = palette.id
	theme.display_name = palette.display_name
	theme.tile_colors = palette.normalized_colors()
	_apply_derived_colors(theme)
	return theme


static func _apply_derived_colors(theme: ThemePaletteData) -> void:
	var colors := theme.normalized_tile_colors()
	var accent := _highest_saturation(colors)
	var secondary := colors[(colors.find(accent) + 3) % colors.size()]
	var light := _average(colors).lightened(0.72)
	match theme.id:
		&"arcade":
			theme.ui_bg_color = GameColors.MENU_BACKGROUND
			theme.ui_panel_color = GameColors.WHITE
			theme.ui_panel_alt_color = GameColors.ARCADE_PANEL_ALT
			theme.ui_accent_color = GameColors.ACCENT
			theme.ui_button_color = GameColors.ACCENT
			theme.ui_button_hover_color = GameColors.ACCENT_HOVER
		&"monochrome":
			theme.ui_bg_color = GameColors.MONO_BACKGROUND
			theme.ui_panel_color = GameColors.WHITE
			theme.ui_panel_alt_color = GameColors.MONO_PANEL_ALT
			theme.ui_accent_color = GameColors.MONO_ACCENT
			theme.ui_button_color = GameColors.MONO_BUTTON
			theme.ui_button_hover_color = GameColors.MONO_HOVER
		&"vaporwave":
			theme.ui_bg_color = GameColors.VAPOR_BACKGROUND
			theme.ui_panel_color = GameColors.VAPOR_PANEL
			theme.ui_panel_alt_color = GameColors.VAPOR_PANEL_ALT
			theme.ui_text_color = GameColors.VAPOR_TEXT
			theme.ui_muted_text_color = GameColors.VAPOR_TEXT_MUTED
			theme.ui_accent_color = GameColors.VAPOR_ACCENT
			theme.ui_button_color = GameColors.VAPOR_BUTTON
			theme.ui_button_hover_color = GameColors.VAPOR_ACCENT
		&"rainbow", &"vibrant_rainbow_delight", &"soft_rainbow":
			theme.ui_bg_color = GameColors.MENU_BACKGROUND
			theme.ui_panel_color = GameColors.WHITE
			theme.ui_panel_alt_color = GameColors.RAINBOW_PANEL_ALT
			theme.ui_accent_color = accent
			theme.ui_button_color = accent.darkened(0.12)
			theme.ui_button_hover_color = secondary.lightened(0.12)
		_:
			theme.ui_bg_color = light
			theme.ui_panel_color = light.lightened(0.12)
			theme.ui_panel_alt_color = light.darkened(0.08)
			theme.ui_accent_color = accent
			theme.ui_button_color = accent.darkened(0.08)
			theme.ui_button_hover_color = accent.lightened(0.16)
	theme.ui_button_text_color = (
		GameColors.WHITE if theme.ui_button_color.get_luminance() < 0.55 else GameColors.TEXT_ON_LIGHT_BUTTON
	)
	if theme.id != &"vaporwave" and theme.ui_bg_color.get_luminance() < 0.45:
		theme.ui_text_color = GameColors.MENU_BACKGROUND
		theme.ui_muted_text_color = GameColors.DARK_THEME_MUTED
	theme.bg_base_color = FIXED_BG_BASE_COLOR
	theme.bg_secondary_color = FIXED_BG_SECONDARY_COLOR


static func _average(colors: Array[Color]) -> Color:
	var sum := GameColors.BLACK
	for color in colors:
		sum.r += color.r
		sum.g += color.g
		sum.b += color.b
	sum.r /= maxf(float(colors.size()), 1.0)
	sum.g /= maxf(float(colors.size()), 1.0)
	sum.b /= maxf(float(colors.size()), 1.0)
	sum.a = 1.0
	return sum


static func _highest_saturation(colors: Array[Color]) -> Color:
	var best := colors[0]
	var best_score := -1.0
	for color in colors:
		var max_channel := maxf(color.r, maxf(color.g, color.b))
		var min_channel := minf(color.r, minf(color.g, color.b))
		var score := (max_channel - min_channel) * (0.35 + color.get_luminance())
		if score > best_score:
			best = color
			best_score = score
	return best
