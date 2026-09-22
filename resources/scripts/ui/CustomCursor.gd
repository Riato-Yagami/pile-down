class_name CustomCursor
extends Node

const BASE_CURSOR := preload("res://resources/sprites/ui/mouse/mouse.png")
const HOVER_CURSOR := preload("res://resources/sprites/ui/mouse/hover.png")
const HOLD_CURSOR := preload("res://resources/sprites/ui/mouse/hold.png")
const BASE_HOTSPOT := Vector2.ZERO
const BASE_VIEWPORT_SIZE := Vector2i(256, 320)
const MAX_CURSOR_SCALE := 8
const BASE_CURSOR_SHAPES := [
	Input.CURSOR_ARROW,
	Input.CURSOR_POINTING_HAND,
	Input.CURSOR_HELP,
	Input.CURSOR_DRAG,
	Input.CURSOR_CAN_DROP,
	Input.CURSOR_FORBIDDEN,
]
const HOVER_CURSOR_SHAPES := [
	Input.CURSOR_POINTING_HAND,
	Input.CURSOR_HELP,
	Input.CURSOR_DRAG,
	Input.CURSOR_CAN_DROP,
]

static var _cursor_scale := 0
static var _base_cursor: Texture2D = BASE_CURSOR
static var _hover_cursor: Texture2D = HOVER_CURSOR
static var _hold_cursor: Texture2D = HOLD_CURSOR
static var _sticky_base_cursor: Texture2D = BASE_CURSOR
static var _sticky_hover_cursor: Texture2D = HOVER_CURSOR
static var _sticky_hold_cursor: Texture2D = HOLD_CURSOR
static var _base_hotspot := BASE_HOTSPOT
static var _holding_card := false
static var _sticky_enabled := false


func _ready() -> void:
	var viewport := get_viewport()
	if viewport != null and not viewport.size_changed.is_connected(_refresh_cursor):
		viewport.size_changed.connect(_refresh_cursor)
	_refresh_cursor.call_deferred()


func _exit_tree() -> void:
	var viewport := get_viewport()
	if viewport != null and viewport.size_changed.is_connected(_refresh_cursor):
		viewport.size_changed.disconnect(_refresh_cursor)
	# Libérer les curseurs système et leurs textures avant le serveur de rendu.
	for cursor_shape in BASE_CURSOR_SHAPES:
		Input.set_custom_mouse_cursor(null, cursor_shape)
	_base_cursor = BASE_CURSOR
	_hover_cursor = HOVER_CURSOR
	_hold_cursor = HOLD_CURSOR
	_sticky_base_cursor = BASE_CURSOR
	_sticky_hover_cursor = HOVER_CURSOR
	_sticky_hold_cursor = HOLD_CURSOR
	_cursor_scale = 0
	_base_hotspot = BASE_HOTSPOT
	_holding_card = false
	_sticky_enabled = false


func _refresh_cursor() -> void:
	if not is_inside_tree():
		return
	# Le resize ne change pas le curseur tant que son échelle entière reste identique.
	if _cursor_scale == _cursor_scale_for_window(get_window()):
		return
	_update_scaled_cursor(get_window())
	apply_base_cursors()


static func apply_base_cursors() -> void:
	if _sticky_enabled:
		if _holding_card:
			_apply_texture_to_shapes(
				_sticky_hold_cursor, _base_hotspot, BASE_CURSOR_SHAPES
			)
			return
		for cursor_shape in BASE_CURSOR_SHAPES:
			Input.set_custom_mouse_cursor(
				_sticky_base_cursor, cursor_shape, _base_hotspot
			)
		_apply_texture_to_shapes(
			_sticky_hover_cursor, _base_hotspot, HOVER_CURSOR_SHAPES
		)
		return
	if _holding_card:
		_apply_texture_to_shapes(_hold_cursor, _base_hotspot, BASE_CURSOR_SHAPES)
		return
	for cursor_shape in BASE_CURSOR_SHAPES:
		Input.set_custom_mouse_cursor(_base_cursor, cursor_shape, _base_hotspot)
	_apply_texture_to_shapes(_hover_cursor, _base_hotspot, HOVER_CURSOR_SHAPES)


static func set_holding_card(holding: bool) -> void:
	if _holding_card == holding:
		return
	_holding_card = holding
	apply_base_cursors()


static func set_sticky_cursor_enabled(enabled: bool) -> void:
	if _sticky_enabled == enabled:
		return
	_sticky_enabled = enabled
	apply_base_cursors()


static func _update_scaled_cursor(window: Window) -> void:
	var scale := _cursor_scale_for_window(window)
	if _cursor_scale == scale:
		return
	_cursor_scale = scale
	_base_hotspot = BASE_HOTSPOT * scale
	if scale <= 1:
		_base_cursor = BASE_CURSOR
		_hover_cursor = HOVER_CURSOR
		_hold_cursor = HOLD_CURSOR
		_sticky_base_cursor = _green_sticky_cursor(BASE_CURSOR)
		_sticky_hover_cursor = _green_sticky_cursor(HOVER_CURSOR)
		_sticky_hold_cursor = _green_sticky_cursor(HOLD_CURSOR)
		return
	_base_cursor = _scaled_texture(BASE_CURSOR, scale)
	_hover_cursor = _scaled_texture(HOVER_CURSOR, scale)
	_hold_cursor = _scaled_texture(HOLD_CURSOR, scale)
	_sticky_base_cursor = _scaled_texture(
		_green_sticky_cursor(BASE_CURSOR), scale
	)
	_sticky_hover_cursor = _scaled_texture(
		_green_sticky_cursor(HOVER_CURSOR), scale
	)
	_sticky_hold_cursor = _scaled_texture(
		_green_sticky_cursor(HOLD_CURSOR), scale
	)


static func _apply_texture_to_shapes(
	texture: Texture2D, hotspot: Vector2, shapes: Array
) -> void:
	for cursor_shape in shapes:
		Input.set_custom_mouse_cursor(texture, cursor_shape, hotspot)


static func _scaled_texture(texture: Texture2D, scale: int) -> Texture2D:
	var base_image := texture.get_image()
	if base_image == null:
		return texture
	var scaled_image := base_image.duplicate()
	scaled_image.resize(
		base_image.get_width() * scale,
		base_image.get_height() * scale,
		Image.INTERPOLATE_NEAREST
	)
	return ImageTexture.create_from_image(scaled_image)


static func _green_sticky_cursor(texture: Texture2D) -> Texture2D:
	var image := texture.get_image()
	if image == null:
		return texture
	image = image.duplicate()
	for y in image.get_height():
		for x in image.get_width():
			var pixel := image.get_pixel(x, y)
			if pixel.a <= 0.0:
				continue
			if pixel.b > pixel.r and pixel.b >= pixel.g:
				var lightness := maxf(pixel.r, maxf(pixel.g, pixel.b))
				pixel.r = minf(pixel.r * 0.6, lightness * 0.45)
				pixel.g = maxf(pixel.g, lightness)
				pixel.b = minf(pixel.b * 0.35, lightness * 0.45)
				image.set_pixel(x, y, pixel)
	return ImageTexture.create_from_image(image)


static func _cursor_scale_for_window(window: Window) -> int:
	if window == null:
		return 1
	var window_size := Vector2(window.size)
	var scale := floorf(minf(
		window_size.x / maxf(float(BASE_VIEWPORT_SIZE.x), 1.0),
		window_size.y / maxf(float(BASE_VIEWPORT_SIZE.y), 1.0)
	))
	return clampi(int(scale), 1, MAX_CURSOR_SCALE)
