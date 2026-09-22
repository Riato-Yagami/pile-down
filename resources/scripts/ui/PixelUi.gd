class_name PixelUi
extends RefCounted

const ProgressionScrollVisualScript := preload(
	"res://resources/scripts/ui/ProgressionScrollVisual.gd"
)
const SCROLLBAR_STYLE_NAMES: Array[StringName] = [
	&"scroll",
	&"scroll_focus",
	&"grabber",
	&"grabber_highlight",
	&"grabber_pressed",
]


static func style_vertical_scrollbar(
	scrollbar: VScrollBar,
	track_texture: Texture2D,
	selector_texture: Texture2D
) -> void:
	if scrollbar == null:
		return
	scrollbar.custom_minimum_size.x = 8.0
	var empty_style := StyleBoxEmpty.new()
	for style_name in SCROLLBAR_STYLE_NAMES:
		scrollbar.add_theme_stylebox_override(style_name, empty_style)
	var visual := scrollbar.get_node_or_null("ScrollVisual") as Control
	if visual == null:
		visual = Control.new()
		visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
		visual.set_script(ProgressionScrollVisualScript)
		scrollbar.add_child(visual)
	visual.call("setup", scrollbar, track_texture, selector_texture)


static func style_scroll_container(
	scroll: ScrollContainer,
	track_texture: Texture2D,
	selector_texture: Texture2D
) -> void:
	if scroll == null:
		return
	style_vertical_scrollbar(
		scroll.get_v_scroll_bar(),
		track_texture,
		selector_texture
	)


static func set_interactive_cursor(control: Control, enabled: bool) -> void:
	if control == null:
		return
	control.mouse_default_cursor_shape = (
		Control.CURSOR_POINTING_HAND if enabled else Control.CURSOR_ARROW
	)
	if not enabled:
		control.focus_mode = Control.FOCUS_NONE


static func queue_free_children(container: Node, detach_first := false) -> void:
	if container == null:
		return
	for child in container.get_children():
		if detach_first:
			container.remove_child(child)
		child.queue_free()


static func button_style(texture: Texture2D, content_right := 9.0) -> StyleBoxTexture:
	var atlas := AtlasTexture.new()
	atlas.atlas = texture
	atlas.region = Rect2(0, 0, 86, 31)
	var style := StyleBoxTexture.new()
	style.texture = atlas
	style.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_TILE
	style.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_TILE
	style.texture_margin_left = 8.0
	style.texture_margin_top = 6.0
	style.texture_margin_right = 8.0
	style.texture_margin_bottom = 6.0
	style.content_margin_left = 9.0
	style.content_margin_top = 4.0
	style.content_margin_right = content_right
	style.content_margin_bottom = 4.0
	return style

