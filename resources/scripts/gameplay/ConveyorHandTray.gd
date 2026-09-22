@tool
class_name ConveyorHandTray
extends Control

const DEFAULT_OFFSETS := Rect2(18.0, -55.0, -36.0, 46.0)
const CONVEYOR_OFFSETS := Rect2(18.0, -55.0, -18.0, 55.0)

@onready var regular_background: NinePatchRect = %RegularHandBackground
@onready var conveyor_background: NinePatchRect = %ConveyorBackground

var _conveyor_enabled := false

@export_category("Conveyor Belt")
@export_range(0.0, 256.0, 1.0, "suffix:px") var conveyor_turn_point_x := 36.0:
	set(value):
		conveyor_turn_point_x = value
		queue_redraw()

@export_category("Screen Edges")
@export var screen_edge_margins := Vector4(12.0, 8.0, 12.0, 12.0):
	set(value):
		screen_edge_margins = Vector4(
			maxf(value.x, 0.0),
			maxf(value.y, 0.0),
			maxf(value.z, 0.0),
			maxf(value.w, 0.0)
		)
		_apply_offsets()
@export_range(0.0, 32.0, 1.0, "suffix:px") var conveyor_right_bleed := 2.0:
	set(value):
		conveyor_right_bleed = maxf(value, 0.0)
		_apply_offsets()

@export var preview_conveyor_belt := true:
	set(value):
		preview_conveyor_belt = value
		_refresh_editor_preview()


func _ready() -> void:
	_conveyor_enabled = preview_conveyor_belt if Engine.is_editor_hint() else false
	_refresh_editor_preview()


func set_conveyor_enabled(enabled: bool) -> void:
	_conveyor_enabled = enabled
	regular_background.visible = not enabled
	conveyor_background.visible = enabled
	_apply_offsets()


func set_screen_edge_margins(margins: Vector4) -> void:
	screen_edge_margins = margins


func _apply_offsets() -> void:
	if not is_node_ready():
		return
	var enabled := _conveyor_enabled
	var tray_offsets := CONVEYOR_OFFSETS if enabled else DEFAULT_OFFSETS
	offset_left = screen_edge_margins.x if not enabled else tray_offsets.position.x
	offset_top = tray_offsets.position.y
	offset_right = -screen_edge_margins.z if not enabled else tray_offsets.end.x
	offset_bottom = tray_offsets.end.y
	if not enabled:
		return
	var parent_control := get_parent() as Control
	if parent_control == null:
		return
	var parent_rect := parent_control.get_global_rect()
	var viewport_size := get_viewport_rect().size
	offset_left = screen_edge_margins.x - parent_rect.position.x
	offset_right = viewport_size.x + conveyor_right_bleed - parent_rect.end.x


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
