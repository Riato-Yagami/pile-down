extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var output := OS.get_environment("PILE_DOWN_PIP_AUDIT")
	if not output.is_empty():
		DirAccess.make_dir_recursive_absolute(output)
	var files := DirAccess.get_files_at("res://resources/data/fonts")
	files.sort()
	var results: Array[Dictionary] = []
	for filename in files:
		if not filename.ends_with(".tres"):
			continue
		var data := load("res://resources/data/fonts/" + filename) as FontData
		var font := data.get_render_font()
		var glyph := TilePips.dot_visual(font, data.tile_font_size)
		var bitmap: Image = glyph["image"]
		if data.pip_shape == FontData.PipShape.PIXEL_CIRCLE:
			assert(glyph.get("circle", false))
			assert(bitmap.get_pixel(0, 0).a == 0.0 and bitmap.get_pixel(3, 3).a == 1.0)
			for y in bitmap.get_height():
				for x in bitmap.get_width():
					assert(bitmap.get_pixel(x, y).a in [0.0, 1.0], "Pixel circles must have no antialiasing")
		else:
			assert(not glyph.get("circle", false))
		assert(bitmap.get_used_rect() == Rect2i(Vector2i.ZERO, bitmap.get_size()), "%s must have no transparent outer padding" % data.id)
		var tile := Control.new()
		tile.size = Vector2(34, 37)
		root.add_child(tile)
		var label := Label.new()
		tile.add_child(label)
		label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		label.offset_left = data.tile_font_offset.x
		label.offset_right = data.tile_font_offset.x
		label.offset_top = data.tile_font_offset.y
		label.offset_bottom = data.tile_font_offset.y - 2
		label.add_theme_font_override("font", font)
		label.add_theme_font_size_override("font_size", data.tile_font_size)
		TilePips.apply(label, 9, &"dots", false, true, data.tile_font_offset)
		await process_frame
		var pips := label.get_node("ValuePips") as TilePips
		var area := pips.drawing_area()
		assert((area.get_center() + label.position).is_equal_approx(Vector2(17, 17.5)), "%s must ignore the digit's optical offset" % data.id)
		var image := Image.create(400, 43, false, Image.FORMAT_RGBA8)
		image.fill(Color("f7f6f2"))
		for value in 10:
			var origin := Vector2i(value * 40 + 2, 2)
			image.fill_rect(Rect2i(origin, Vector2i(34, 37)), Color("4f83bf"))
			image.fill_rect(Rect2i(origin + Vector2i.ONE, Vector2i(32, 34)), Color.WHITE)
			var rects := TilePips.dot_rects(area, glyph["extent"], value, glyph["weight"], glyph["center"])
			assert(rects.size() == value)
			for rect in rects:
				assert(maxf(rect.size.x, rect.size.y) >= (5 if data.pip_shape == FontData.PipShape.PIXEL_CIRCLE else 6) and maxf(rect.size.x, rect.size.y) <= 8, "%s points must have a readable diameter" % data.id)
				assert(area.encloses(rect))
				var stamp := (TilePips.circle_glyph(int(rect.size.x))["image"] as Image).duplicate() as Image if glyph.get("circle", false) else bitmap.duplicate() as Image
				stamp.resize(int(rect.size.x), int(rect.size.y), Image.INTERPOLATE_NEAREST)
				var pixels := stamp.get_data()
				for pixel in range(0, pixels.size(), 4):
					pixels[pixel] = 52
					pixels[pixel + 1] = 97
					pixels[pixel + 2] = 165
				stamp.set_data(stamp.get_width(), stamp.get_height(), false, Image.FORMAT_RGBA8, pixels)
				image.blend_rect(stamp, Rect2i(Vector2i.ZERO, stamp.get_size()), origin + Vector2i((rect.position + label.position).round()))
		if not output.is_empty():
			image.save_png(output.path_join(String(data.id) + ".png"))
		results.append({"id": data.id, "title": data.display_name, "font_size": data.tile_font_size,
			"shape": "circle" if data.pip_shape == FontData.PipShape.PIXEL_CIRCLE else "glyph", "ink_size": str(bitmap.get_size()), "weight": glyph["weight"], "ink_center": str(glyph["center"]), "fallback": glyph["font"] != font,
			"offset": str(data.tile_font_offset), "center": str(area.get_center() + label.position)})
		tile.queue_free()
		await process_frame
	if not output.is_empty():
		var report := FileAccess.open(output.path_join("fonts.json"), FileAccess.WRITE)
		report.store_string(JSON.stringify(results, "\t"))
		var html := "<!doctype html><meta charset='utf-8'><title>Points — toutes les polices</title><style>body{background:#f7f6f2;color:#333;font:16px sans-serif;margin:24px}article{margin:24px 0}img{width:800px;max-width:100%;image-rendering:pixelated}small{display:block}</style><h1>Points — toutes les polices</h1><p>Glyphes réels et rectangles utilisés par TilePips, composés sur CPU. Valeurs 0 à 9 ; tuiles de 34 × 37 px, agrandies ×2.</p>"
		for row in results:
			html += "<article><strong>%s</strong><small>%s · %s</small><img src='%s.png'></article>" % [row["title"], row["id"], "Cercle pixel" if row["shape"] == "circle" else "Point de la police", row["id"]]
		FileAccess.open(output.path_join("index.html"), FileAccess.WRITE).store_string(html)
	print("Pip audit passed for all %d declared fonts, values 0–9: cropped ink, 5–8 px diameter and tile-centered geometry." % results.size())
	quit()
