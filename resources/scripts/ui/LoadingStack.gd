@tool
extends Control

@export var tile_texture: Texture2D = preload("res://resources/sprites/tiles/tile-back.png")
@export_range(1, 12) var tile_count := UISettings.LOADING_TILE_COUNT
@export var tile_size := UISettings.LOADING_TILE_SIZE
@export var stack_step := UISettings.LOADING_STACK_STEP
@export var drop_height := UISettings.LOADING_DROP_HEIGHT
@export_range(0.05, 2.0, 0.05) var drop_seconds := UISettings.LOADING_DROP_SECONDS
@export var animate_in_editor := true

var _elapsed := 0.0


func _process(delta: float) -> void:
	if not Engine.is_editor_hint() or animate_in_editor:
		_elapsed += delta
	queue_redraw()


func _draw() -> void:
	if tile_texture == null:
		return
	var count := maxi(tile_count, 1)
	var phase := fposmod(_elapsed / maxf(drop_seconds, 0.05), 1.0)
	var motion := smoothstep(0.0, 1.0, phase)
	var fitted_size := _fitted_tile_size()
	var base := (size - fitted_size) * 0.5 - Vector2(0, stack_step * (count - 1) * 0.5)
	# Each arriving tile becomes the top of the next cycle. The pile sinks by
	# one layer while the bottom fades, instead of disappearing on reset.
	for index in range(count, 0, -1):
		var tile_position := base + Vector2(0, (index - 1 + motion) * stack_step)
		var opacity := 1.0 - motion if index == count else 1.0
		draw_texture_rect(tile_texture, Rect2(tile_position, fitted_size), false, Color(GameColors.WHITE, opacity))
	var incoming := base - Vector2(0, (1.0 - motion) * drop_height)
	var incoming_opacity := smoothstep(0.0, 0.2, phase)
	draw_texture_rect(tile_texture, Rect2(incoming, fitted_size), false, Color(GameColors.WHITE, incoming_opacity))


func _fitted_tile_size() -> Vector2:
	var source := tile_texture.get_size()
	if source.x <= 0.0 or source.y <= 0.0:
		return Vector2.ZERO
	# The inspector size is a bounding box, never an independent X/Y stretch.
	var factor := minf(maxf(tile_size.x, 0.0) / source.x, maxf(tile_size.y, 0.0) / source.y)
	return source * factor
