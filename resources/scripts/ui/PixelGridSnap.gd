@tool
class_name PixelGridSnap
extends Control

@export var snap_size := true

var _snap_queued := false


func _ready() -> void:
	_queue_snap()


func _notification(what: int) -> void:
	if what in [
		NOTIFICATION_ENTER_TREE,
		NOTIFICATION_RESIZED,
		NOTIFICATION_VISIBILITY_CHANGED,
	]:
		_queue_snap()


func _queue_snap() -> void:
	if _snap_queued or not is_inside_tree():
		return
	_snap_queued = true
	call_deferred("_snap_to_pixel_grid")


func _snap_to_pixel_grid() -> void:
	_snap_queued = false
	_snap_now()


func _process(_delta: float) -> void:
	_snap_now()


func _snap_now() -> void:
	global_position = global_position.round()
	if snap_size:
		size = size.floor()
