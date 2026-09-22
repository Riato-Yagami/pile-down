extends RefCounted

const REVEAL_DURATION := 0.24


static func animate(
	host: Label, changes: PackedStringArray, reveal_delay: float, extra_hold: float
) -> Tween:
	host.text = ""
	host.visible = true
	host.modulate.a = 1.0
	var lines: Array[Label] = []
	var font := host.get_theme_font("font")
	var font_size := host.get_theme_font_size("font_size")
	var spacing := ceilf(font.get_height(font_size)) + 6.0
	for change in changes:
		var line := Label.new()
		line.text = change
		line.mouse_filter = Control.MOUSE_FILTER_IGNORE
		line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		line.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		line.add_theme_font_override("font", font)
		line.add_theme_font_size_override("font_size", font_size)
		line.add_theme_color_override("font_color", host.get_theme_color("font_color"))
		host.add_child(line)
		line.size = host.size
		line.pivot_offset = line.size * 0.5
		line.modulate.a = 0.0
		lines.append(line)
	var tween := host.create_tween()
	tween.tween_property(lines[0], "modulate:a", 1.0, 0.2)
	for index in range(1, lines.size()):
		var incoming := lines[index]
		var destination_y := spacing * index * 0.5
		incoming.position.y = destination_y + 8.0
		incoming.scale = Vector2.ONE * 0.94
		tween.tween_interval(reveal_delay)
		# Recenter the existing lines continuously instead of replacing the
		# centered text block, which made the first upgrade jump abruptly.
		for previous in index:
			if previous > 0:
				tween.parallel()
			tween.tween_property(
				lines[previous], "position:y",
				spacing * (previous - index * 0.5), REVEAL_DURATION
			).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
		tween.parallel().tween_property(incoming, "position:y", destination_y, REVEAL_DURATION
		).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.parallel().tween_property(incoming, "modulate:a", 1.0, REVEAL_DURATION)
		tween.parallel().tween_property(incoming, "scale", Vector2.ONE, REVEAL_DURATION
		).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_interval(0.75 + extra_hold if lines.size() > 1 else 0.75)
	tween.tween_property(host, "modulate:a", 0.0, 0.2)
	tween.tween_callback(func() -> void:
		for line in lines:
			line.queue_free()
	)
	return tween
