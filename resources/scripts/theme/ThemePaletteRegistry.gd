class_name ThemePaletteRegistry
extends RefCounted

const FIXED_BG_BASE_COLOR := Color("f7f6f2")
const FIXED_BG_SECONDARY_COLOR := Color(0.31, 0.49, 0.72, 0.16)


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
			theme.ui_bg_color = Color("f7f6f2")
			theme.ui_panel_color = Color("ffffff")
			theme.ui_panel_alt_color = Color("e2e9ef")
			theme.ui_accent_color = Color("4d82c2")
			theme.ui_button_color = Color("4d82c2")
			theme.ui_button_hover_color = Color("6da7e5")
		&"monochrome":
			theme.ui_bg_color = Color("f1f3f4")
			theme.ui_panel_color = Color("ffffff")
			theme.ui_panel_alt_color = Color("d5dbe1")
			theme.ui_accent_color = Color("5d6670")
			theme.ui_button_color = Color("626a73")
			theme.ui_button_hover_color = Color("7b858f")
		&"vaporwave":
			theme.ui_bg_color = Color("2a2140")
			theme.ui_panel_color = Color("34294d")
			theme.ui_panel_alt_color = Color("48345f")
			theme.ui_text_color = Color("f6eaff")
			theme.ui_muted_text_color = Color("c9b8db")
			theme.ui_accent_color = Color("ef6fe7")
			theme.ui_button_color = Color("2bbfd2")
			theme.ui_button_hover_color = Color("ef6fe7")
		&"rainbow", &"vibrant_rainbow_delight", &"soft_rainbow":
			theme.ui_bg_color = Color("f7f6f2")
			theme.ui_panel_color = Color("ffffff")
			theme.ui_panel_alt_color = Color("e6eceb")
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
		Color("ffffff") if theme.ui_button_color.get_luminance() < 0.55 else Color("242424")
	)
	if theme.ui_bg_color.get_luminance() < 0.45:
		theme.ui_text_color = Color("f7f6f2")
		theme.ui_muted_text_color = Color(0.86, 0.84, 0.88, 0.82)
	theme.bg_base_color = FIXED_BG_BASE_COLOR
	theme.bg_secondary_color = FIXED_BG_SECONDARY_COLOR


static func _average(colors: Array[Color]) -> Color:
	var sum := Color.BLACK
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
