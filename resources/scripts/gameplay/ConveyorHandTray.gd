@tool
class_name ConveyorHandTray
extends Control

const DEFAULT_OFFSETS := Rect2(18.0, -55.0, -36.0, 46.0)
const CONVEYOR_OFFSETS := Rect2(18.0, -55.0, -18.0, 55.0)

@onready var regular_background: NinePatchRect = %RegularHandBackground
@onready var conveyor_background: NinePatchRect = %ConveyorBackground

@export_category("Conveyor Belt")
@export_range(0.0, 256.0, 1.0, "suffix:px") var conveyor_turn_point_x := 36.0:
	set(value):
		conveyor_turn_point_x = value
		queue_redraw()

@export var preview_conveyor_belt := true:
	set(value):
		preview_conveyor_belt = value
		_refresh_editor_preview()


func _ready() -> void:
	_refresh_editor_preview()


func set_conveyor_enabled(enabled: bool) -> void:
	regular_background.visible = not enabled
	conveyor_background.visible = enabled
	var tray_offsets := CONVEYOR_OFFSETS if enabled else DEFAULT_OFFSETS
	offset_left = tray_offsets.position.x
	offset_top = tray_offsets.position.y
	offset_right = tray_offsets.end.x
	offset_bottom = tray_offsets.end.y


func _draw() -> void:
	if not Engine.is_editor_hint() or not preview_conveyor_belt:
		return
	var local_x := conveyor_turn_point_x - global_position.x
	draw_dashed_line(
		Vector2(local_x, 0.0),
		Vector2(local_x, size.y),
		Color("e2554f"),
		1.0,
		3.0
	)
	draw_circle(Vector2(local_x, size.y * 0.5), 2.0, Color("e2554f"))


func _refresh_editor_preview() -> void:
	if not Engine.is_editor_hint() or not is_inside_tree():
		return
	set_conveyor_enabled(preview_conveyor_belt)
	queue_redraw()
