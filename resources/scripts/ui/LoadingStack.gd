@tool
extends Control

@export var tile_texture: Texture2D = preload("res://resources/sprites/tiles/tile-back.png")
@export_range(1, 12) var tile_count := UISettings.LOADING_TILE_COUNT
@export var tile_size := UISettings.LOADING_TILE_SIZE
@export var stack_step := UISettings.LOADING_STACK_STEP
@export var drop_height := UISettings.LOADING_DROP_HEIGHT
@export_range(0.05, 2.0, 0.05) var drop_seconds := UISettings.LOADING_DROP_SECONDS
## Multiplier: 0 pauses, 1 is normal speed, 2 is twice as fast.
@export_range(0.0, 8.0, 0.05) var animation_speed := UISettings.LOADING_ANIMATION_SPEED
@export var animate_in_editor := true
@export_group("Face Up Tiles")
@export var show_face_up_tiles := UISettings.LOADING_FACE_UP_TILES
@export var face_texture: Texture2D = preload("res://resources/sprites/tiles/tile-face.png")
@export var face_font: Font = preload("res://resources/fonts/VCR_OSD_MONO_1.001.ttf")
@export_range(1, 40) var face_font_size := 20
## Editor preview value. In game, the saved maximum discovered tile takes priority.
@export_range(0, 9) var first_value := UISettings.LOADING_FIRST_VALUE
@export var face_colors: Array[Color] = GameColors.FALLBACK_TILE_COLORS.duplicate()

var _elapsed := 0.0
var _face_textures: Array[Texture2D] = []
var _cached_face_source: Texture2D
var _cached_colors: Array[Color] = []
var _discovered_max := -1


func _ready() -> void:
	if not Engine.is_editor_hint():
		# Read only the small config file, before LoadingScreen starts its worker.
		# This does not depend on GameManager or any gameplay scene.
		configure_from_progress(SaveConfig.load_current())


func configure_from_progress(config: ConfigFile) -> void:
	_discovered_max = clampi(
		int(config.get_value("progression", "max_discovered_tile_value", DifficultySettings.START_CARD_VALUE)),
		DifficultySettings.START_CARD_VALUE,
		DifficultySettings.MAX_CARD_VALUE
	)
	first_value = _discovered_max


func _process(delta: float) -> void:
	if not Engine.is_editor_hint() or animate_in_editor:
		_elapsed += delta * maxf(animation_speed, 0.0)
	queue_redraw()


func _draw() -> void:
	if _active_texture() == null:
		return
	if show_face_up_tiles:
		_prepare_face_textures()
	var count := maxi(tile_count, 1)
	var cycle := int(floor(_elapsed / maxf(drop_seconds, 0.05)))
	var phase := fposmod(_elapsed / maxf(drop_seconds, 0.05), 1.0)
	var motion := smoothstep(0.0, 1.0, phase)
	var fitted_size := _fitted_tile_size()
	var base := (size - fitted_size) * 0.5 - Vector2(0, stack_step * (count - 1) * 0.5)
	# Each arriving tile becomes the top of the next cycle. The pile sinks by
	# one layer while the bottom fades, instead of disappearing on reset.
	for index in range(count, 0, -1):
		var tile_position := base + Vector2(0, (index - 1 + motion) * stack_step)
		var opacity := 1.0 - motion if index == count else 1.0
		_draw_tile(Rect2(tile_position, fitted_size), cycle - index + 1, opacity)
	var incoming := base - Vector2(0, (1.0 - motion) * drop_height)
	var incoming_opacity := smoothstep(0.0, 0.2, phase)
	_draw_tile(Rect2(incoming, fitted_size), cycle + 1, incoming_opacity)


func _active_texture() -> Texture2D:
	return face_texture if show_face_up_tiles else tile_texture


func _tile_value(sequence: int) -> int:
	var maximum := clampi(first_value if _discovered_max < 0 else _discovered_max, 0, 9)
	return posmod(clampi(first_value, 0, maximum) - sequence, maximum + 1)


func _palette() -> Array[Color]:
	return face_colors if face_colors.size() == 10 else GameColors.FALLBACK_TILE_COLORS


func _draw_tile(rect: Rect2, sequence: int, opacity: float) -> void:
	if not show_face_up_tiles:
		draw_texture_rect(tile_texture, rect, false, Color(GameColors.WHITE, opacity))
		return
	if _face_textures.size() != 10:
		return
	var value := _tile_value(sequence)
	draw_texture_rect(_face_textures[value], rect, false, Color(GameColors.WHITE, opacity))
	if face_font == null:
		return
	var font_size := maxi(1, roundi(face_font_size * rect.size.y / face_texture.get_height()))
	var text := str(value)
	var text_width := face_font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var baseline := rect.position + Vector2(
		(rect.size.x - text_width) * 0.5,
		(rect.size.y - face_font.get_height(font_size)) * 0.5 + face_font.get_ascent(font_size) - rect.size.y / 37.0
	)
	var color := GameColors.tile_text_color(_palette()[value])
	color.a *= opacity
	draw_string(face_font, baseline.round(), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)


func _prepare_face_textures() -> void:
	var colors := _palette()
	if _cached_face_source == face_texture and _cached_colors == colors:
		return
	_cached_face_source = face_texture
	_cached_colors = colors.duplicate()
	_face_textures.clear()
	var source := face_texture.get_image()
	if source == null or source.is_empty():
		return
	if source.is_compressed():
		source.decompress()
	# Cache only these tiny sprites; never instantiate gameplay or load its
	# script graph on the UI thread just to animate the loading screen.
	for color in colors:
		var tinted := source.duplicate() as Image
		for y in tinted.get_height():
			for x in tinted.get_width():
				var pixel := source.get_pixel(x, y)
				if pixel.g > 0.65 and pixel.g > pixel.r * 1.6 and pixel.g > pixel.b * 1.6:
					tinted.set_pixel(x, y, Color(color, pixel.a * color.a))
		_face_textures.append(ImageTexture.create_from_image(tinted))


func _fitted_tile_size() -> Vector2:
	var texture := _active_texture()
	if texture == null:
		return Vector2.ZERO
	var source := texture.get_size()
	if source.x <= 0.0 or source.y <= 0.0:
		return Vector2.ZERO
	# The inspector size is a bounding box, never an independent X/Y stretch.
	var factor := minf(maxf(tile_size.x, 0.0) / source.x, maxf(tile_size.y, 0.0) / source.y)
	return source * factor
