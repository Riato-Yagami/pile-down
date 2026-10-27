@tool
class_name TilePips
extends Control

const BASE_FONT := preload("res://resources/fonts/VCR_OSD_MONO_1.001.ttf")
static var _glyph_cache: Dictionary = {}
static var _circle_cache: Dictionary = {}

const PATTERNS := [[], [4], [0, 8], [0, 4, 8], [0, 2, 6, 8], [0, 2, 4, 6, 8], [0, 2, 3, 5, 6, 8], [0, 2, 3, 4, 5, 6, 8], [0, 1, 2, 3, 5, 6, 7, 8], [0, 1, 2, 3, 4, 5, 6, 7, 8]]
@export var value := 0
@export var color := Color.BLACK
@export var dot_font: Font = BASE_FONT
@export var dot_font_size := 16
@export var font_offset := Vector2.ZERO
@export var tile_rect := Rect2()


func drawing_area() -> Rect2:
	var label := get_parent() as Label
	if label != null and label.get_parent() is Control:
		var tile := label.get_parent() as Control
		if tile.size.x > 0.0 and tile.size.y > 0.0:
			# Cancel font-specific optical offsets while keeping the card's animated lift.
			var pose_y := label.offset_top - font_offset.y
			tile_rect = Rect2(-label.position + Vector2(0, pose_y), tile.size - Vector2(0, 2))
	return tile_rect if tile_rect.has_area() else Rect2(-font_offset, size)


static func dot_rects(area: Rect2, extent: Vector2, number: int, weight := 1.0, ink_center := Vector2(0.5, 0.5)) -> Array[Rect2]:
	var result: Array[Rect2] = []
	var side := minf(area.size.x, area.size.y)
	var diameter := maxf(1.0, minf(roundf(side * 0.19 * weight), roundf(side * 0.23)))
	var dot_size := (extent * diameter / maxf(extent.x, extent.y)).round()
	var spacing := roundf(side * 0.25)
	for index: int in PATTERNS[clampi(number, 0, 9)]:
		var offset := Vector2(index % 3 - 1, index / 3 - 1) * spacing
		var center := area.get_center() + offset + Vector2(0, -1)
		result.append(Rect2((center - dot_size * ink_center).round(), dot_size))
	return result


func _draw() -> void:
	var area := drawing_area()
	if value == 0 or not area.has_area():
		return
	var glyph := dot_visual(dot_font, dot_font_size)
	for rect in dot_rects(area, glyph["extent"], value, glyph["weight"], glyph["center"]):
		var texture: Texture2D = circle_glyph(int(rect.size.x))["texture"] if glyph.get("circle", false) else glyph["texture"]
		draw_texture_rect(texture, rect, false, color)


static func circle_glyph(diameter: int) -> Dictionary:
	diameter = maxi(diameter, 1)
	if _circle_cache.has(diameter):
		return _circle_cache[diameter]
	var bitmap := Image.create(diameter, diameter, false, Image.FORMAT_RGBA8)
	bitmap.fill(Color.TRANSPARENT)
	var radius := diameter * 0.5
	for y in diameter:
		for x in diameter:
			if (Vector2(x, y) + Vector2(0.5, 0.5) - Vector2.ONE * radius).length_squared() <= radius * radius:
				bitmap.set_pixel(x, y, Color.WHITE)
	var data := {"extent": Vector2.ONE * diameter, "center": Vector2(0.5, 0.5), "weight": 1.0,
		"image": bitmap, "texture": ImageTexture.create_from_image(bitmap), "circle": true}
	_circle_cache[diameter] = data
	return data


static func dot_visual(font: Font, font_size: int) -> Dictionary:
	var circle := font != null and int(font.get_meta("pip_shape", FontData.PipShape.FONT_GLYPH)) == FontData.PipShape.PIXEL_CIRCLE
	var data: Dictionary = (circle_glyph(6) if circle else dot_glyph(font, font_size)).duplicate()
	if circle:
		data["font"] = font
	data["weight"] *= float(font.get_meta("pip_scale", 1.0)) if font != null else 1.0
	return data


static func dot_glyph(font: Font, font_size: int) -> Dictionary:
	var server := TextServerManager.get_primary_interface()
	if font == null or font.get_rids().is_empty() or not server.font_has_char(font.get_rids()[0], 46):
		font = BASE_FONT
	font_size = maxi(font_size, 1)
	var sizes: Dictionary = _glyph_cache.get(font, {})
	if sizes.has(font_size):
		return sizes[font_size]
	# Bitmap glyph rectangles contain transparent atlas padding. Crop the ink itself
	# so a tiny period and a large period have the same visible size and center.
	var raster_font := font
	if font is FontFile and font.multichannel_signed_distance_field:
		raster_font = font.duplicate() as FontFile
		(raster_font as FontFile).multichannel_signed_distance_field = false
	var rid: RID = raster_font.get_rids()[0]
	var index := server.font_get_glyph_index(rid, font_size, 46, 0)
	var raster_size := Vector2i(font_size, 0)
	server.font_render_glyph(rid, raster_size, index)
	var texture_index := server.font_get_glyph_texture_idx(rid, raster_size, index)
	var uv := Rect2i(server.font_get_glyph_uv_rect(rid, raster_size, index))
	if texture_index < 0 or not uv.has_area():
		return dot_glyph(BASE_FONT, font_size)
	var atlas := server.font_get_texture_image(rid, raster_size, texture_index)
	var bitmap := atlas.get_region(uv)
	bitmap.convert(Image.FORMAT_RGBA8)
	var ink := bitmap.get_used_rect()
	if not ink.has_area():
		return dot_glyph(BASE_FONT, font_size)
	bitmap = bitmap.get_region(ink)
	var mass := 0.0
	var center := Vector2.ZERO
	for y in bitmap.get_height():
		for x in bitmap.get_width():
			var alpha := bitmap.get_pixel(x, y).a
			mass += alpha
			center += (Vector2(x, y) + Vector2(0.5, 0.5)) * alpha
	center /= mass * Vector2(bitmap.get_size())
	var weight := sqrt(float(bitmap.get_width() * bitmap.get_height()) / mass)
	var data := {"font": font, "extent": Vector2(bitmap.get_size()), "center": center, "weight": weight,
		"offset": server.font_get_glyph_offset(rid, raster_size, index) + Vector2(ink.position),
		"image": bitmap, "texture": ImageTexture.create_from_image(bitmap)}
	sizes[font_size] = data
	_glyph_cache[font] = sizes
	return data


static func apply(label: Label, value: int, style: StringName, roman: bool, revealed: bool, optical_offset := Vector2.ZERO) -> void:
	if label.has_meta("symbol_font_size"):
		if label.get_theme_font_size("font_size") == int(label.get_meta("symbol_fitted_size")):
			label.add_theme_font_size_override("font_size", int(label.get_meta("symbol_font_size")))
		label.remove_meta("symbol_font_size")
		label.remove_meta("symbol_fitted_size")
	var pips := label.get_node_or_null("ValuePips") as TilePips
	var data := ValueStyleManager.find(&"numbers" if roman and style == &"roman" else style)
	var use_pips := data != null and data.use_dots and not roman and revealed
	if pips == null and use_pips:
		pips = TilePips.new()
		pips.name = "ValuePips"
		pips.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pips.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		label.add_child(pips)
		pips.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if pips != null:
		pips.visible = use_pips
		var new_color := label.get_theme_color("font_color")
		var new_font := label.get_theme_font("font")
		var new_size := label.get_theme_font_size("font_size")
		var changed := pips.color != new_color or pips.dot_font != new_font or pips.dot_font_size != new_size or pips.value != clampi(value, 0, 9)
		pips.font_offset = optical_offset
		pips.value = clampi(value, 0, 9)
		pips.color = new_color
		pips.dot_font = new_font
		pips.dot_font_size = new_size
		if changed:
			pips.queue_redraw()
	if use_pips:
		label.text = ""
	elif revealed and (not roman or style == &"roman") and data != null and value >= 0 and value < data.symbols.size():
		label.text = data.symbols[value]

		var base_size := label.get_theme_font_size("font_size")
		var font := label.get_theme_font("font")
		var available := label.size.x if label.size.x > 0.0 else 32.0
		var fitted_size := base_size
		while fitted_size > 8 and font.get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, fitted_size).x > available:
			fitted_size -= 1
		if fitted_size != base_size:
			label.set_meta("symbol_font_size", base_size)
			label.set_meta("symbol_fitted_size", fitted_size)
			label.add_theme_font_size_override("font_size", fitted_size)
