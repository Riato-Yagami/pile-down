@tool
class_name ProgressionScrollVisual
extends Control

var scrollbar: VScrollBar
var selector: TextureRect


func setup(
	target: VScrollBar, track_texture: Texture2D, selector_texture: Texture2D
) -> void:
	scrollbar = target
	name = "ScrollVisual"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var track := NinePatchRect.new()
	track.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	track.mouse_filter = Control.MOUSE_FILTER_IGNORE
	track.texture = track_texture
	track.patch_margin_top = 4
	track.patch_margin_bottom = 4
	add_child(track)
	selector = TextureRect.new()
	selector.mouse_filter = Control.MOUSE_FILTER_IGNORE
	selector.texture = selector_texture
	selector.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	selector.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	selector.size = Vector2(6.0, 14.0)
	add_child(selector)
	set_process(true)
	_refresh()


func _process(_delta: float) -> void:
	_refresh()


func _refresh() -> void:
	if scrollbar == null or selector == null:
		return
	selector.position.x = floorf((size.x - selector.size.x) * 0.5)
	var maximum_scroll := maxf(
		scrollbar.max_value - scrollbar.page, scrollbar.min_value
	)
	var ratio := 0.0
	if maximum_scroll > scrollbar.min_value:
		ratio = inverse_lerp(
			scrollbar.min_value, maximum_scroll, scrollbar.value
		)
	selector.position.y = roundf(
		clampf(ratio, 0.0, 1.0) * maxf(size.y - selector.size.y, 0.0)
	)
