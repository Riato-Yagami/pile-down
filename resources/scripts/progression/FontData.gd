@tool
class_name FontData
extends Data

enum PipShape { PIXEL_CIRCLE, FONT_GLYPH }

@export_category("Points")
@export var pip_shape: PipShape = PipShape.PIXEL_CIRCLE:
	set(value):
		pip_shape = value
		emit_changed()
@export_range(0.5, 2.0, 0.05) var pip_scale := 1.0:
	set(value):
		pip_scale = value
		emit_changed()
@export_category("Font")
@export var display_name: String
@export var font: Font:
	set(value):
		font = value
		_render_font = null
		emit_changed()
@export var tile_font_size := 20:
	set(value):
		tile_font_size = value
		emit_changed()
@export var tile_font_offset := Vector2.ZERO:
	set(value):
		tile_font_offset = value
		emit_changed()
@export var title_font_offset := Vector2.ZERO:
	set(value):
		title_font_offset = value
		emit_changed()
## Zero keeps the title synchronized with Tile Font Size.
@export_range(0, 32, 1) var title_font_size := 0:
	set(value):
		title_font_size = value
		emit_changed()
@export var override_hidden_tile_with_font := true:
	set(value):
		override_hidden_tile_with_font = value
		emit_changed()
@export var secret := false
## Smooth scalable rendering instead of pixel font rasterization.
@export var hd := false:
	set(value):
		hd = value
		_render_font = null
		emit_changed()
var _render_font: Font

@export var default_unlocked := false
@export var required_achievement: AchievementData


func _init(
	font_id: StringName = &"", name := "", resource: Font = null,
	unlocked := false, achievement: AchievementData = null, font_size := 20
) -> void:
	id = font_id
	display_name = name
	font = resource
	tile_font_size = font_size
	default_unlocked = unlocked
	required_achievement = achievement


func get_render_font() -> Font:
	if not hd or not font is FontFile:
		return _with_pip_settings(font)
	if _render_font == null:
		var scalable := font.duplicate() as FontFile
		scalable.antialiasing = TextServer.FONT_ANTIALIASING_GRAY
		scalable.multichannel_signed_distance_field = true
		_render_font = scalable
	return _with_pip_settings(_render_font)


func _with_pip_settings(render_font: Font) -> Font:
	if render_font != null:
		render_font.set_meta("pip_shape", pip_shape)
		render_font.set_meta("pip_scale", pip_scale)
	return render_font
