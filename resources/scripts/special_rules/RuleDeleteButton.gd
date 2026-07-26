class_name RuleDeleteButton
extends Button

@export var strike_color := Color.WHITE
@export var strike_width := 2.0
@export var strike_padding := 4.0

var struck_through := false


func _ready() -> void:
	focus_mode = Control.FOCUS_NONE
	flat = true
	mouse_entered.connect(_set_struck.bind(true))
	mouse_exited.connect(_set_struck.bind(false))


func _draw() -> void:
	if not struck_through:
		return
	var font := get_theme_font("font")
	var font_size := get_theme_font_size("font_size")
	var text_width := font.get_string_size(
		text,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1.0,
		font_size
	).x
	var start_x := maxf((size.x - text_width) * 0.5 - strike_padding, 0.0)
	var end_x := minf(
		(size.x + text_width) * 0.5 + strike_padding,
		size.x
	)
	draw_line(
		Vector2(start_x, size.y * 0.5),
		Vector2(end_x, size.y * 0.5),
		strike_color,
		strike_width
	)


func _set_struck(active: bool) -> void:
	struck_through = active and not disabled and visible
	queue_redraw()
