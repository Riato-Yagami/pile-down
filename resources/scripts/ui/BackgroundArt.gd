class_name BackgroundArt
extends Control

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("#F7F6F2"))
	var center := Vector2(size.x * 0.5, size.y * 0.43)
	var radius := maxf(size.x, size.y) * 0.72
	for step in range(12, 0, -1):
		var ratio := float(step) / 12.0
		draw_circle(center, radius * ratio, Color(1.0, 1.0, 1.0, 0.012))
