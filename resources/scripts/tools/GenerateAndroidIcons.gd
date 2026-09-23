extends SceneTree

## Rebuild launcher layers from the existing pixel-art mark without resampling it.
const ICON_DIR := "res://resources/sprites/android/"
const BACKGROUND := Color("f7f6f2")


func _init() -> void:
	var foreground := Image.load_from_file(ProjectSettings.globalize_path(
		ICON_DIR + "adaptive-foreground.png"
	))
	var mark := foreground.get_region(foreground.get_used_rect())
	var centered := Image.create(432, 432, false, Image.FORMAT_RGBA8)
	var origin := (Vector2i(432, 432) - mark.get_size()) / 2
	centered.blit_rect(mark, Rect2i(Vector2i.ZERO, mark.get_size()), origin)
	centered.save_png(ICON_DIR + "adaptive-foreground.png")
	var monochrome := centered.duplicate() as Image
	for y in monochrome.get_height():
		for x in monochrome.get_width():
			var alpha := monochrome.get_pixel(x, y).a
			monochrome.set_pixel(x, y, Color(1, 1, 1, alpha))
	monochrome.save_png(ICON_DIR + "adaptive-monochrome.png")
	var background := Image.create(432, 432, false, Image.FORMAT_RGBA8)
	background.fill(BACKGROUND)
	background.save_png(ICON_DIR + "adaptive-background.png")
	# Legacy icons have no adaptive mask; use the original larger mark size.
	mark.resize(88, 94, Image.INTERPOLATE_NEAREST)
	var launcher := Image.create(192, 192, false, Image.FORMAT_RGBA8)
	launcher.fill(BACKGROUND)
	launcher.blend_rect(mark, Rect2i(Vector2i.ZERO, mark.get_size()), Vector2i(52, 49))
	launcher.save_png(ICON_DIR + "launcher-icon.png")
	quit()
