@tool
class_name ConveyorHandTray
extends Control

const REDUCED_TEXTURE := preload("res://resources/sprites/hand/reduced.png")
const FOLD_DURATION := 0.45

const DEFAULT_OFFSETS := Rect2(18.0, -55.0, -36.0, 46.0)
const CONVEYOR_OFFSETS := Rect2(18.0, -55.0, -18.0, 55.0)

@onready var regular_background: NinePatchRect = %RegularHandBackground
@onready var conveyor_bottom: TextureRect = %ConveyorBottom
@onready var conveyor_background: NinePatchRect = %ConveyorBackground

var _conveyor_enabled := false
var _reduced_enabled := false
var _fold_progress := 0.0
var _fold_tween: Tween
var _reduced_background: TextureRect


@export_category("Conveyor Belt")
@export_range(0.0, 256.0, 1.0, "suffix:px") var conveyor_turn_point_x := 36.0:
	set(value):
		conveyor_turn_point_x = value
		queue_redraw()

@export_category("Screen Edges")
@export var screen_edge_margins := UISettings.SCREEN_MARGINS:
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
	_reduced_background = TextureRect.new()
	_reduced_background.name = "ReducedHandBackground"
	_reduced_background.texture = REDUCED_TEXTURE
	_reduced_background.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_reduced_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_reduced_background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	add_child(_reduced_background)
	move_child(_reduced_background, regular_background.get_index() + 1)
	resized.connect(_apply_fold)
	resized.connect(_fit_conveyor_bottom)
	_conveyor_enabled = preview_conveyor_belt if Engine.is_editor_hint() else false
	set_conveyor_enabled(_conveyor_enabled)
	_refresh_editor_preview()


func set_conveyor_enabled(enabled: bool) -> void:
	_conveyor_enabled = enabled
	regular_background.visible = not enabled and _fold_progress < 1.0
	conveyor_background.visible = enabled
	conveyor_bottom.visible = enabled
	_apply_offsets()
	_apply_fold()


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
	_fit_conveyor_bottom()


func _draw() -> void:
	if not Engine.is_editor_hint() or not preview_conveyor_belt:
		return
	var local_x := conveyor_turn_point_x - global_position.x
	draw_dashed_line(
		Vector2(local_x, 0.0),
		Vector2(local_x, size.y),
		GameColors.DANGER,
		1.0,
		3.0
	)
	draw_circle(Vector2(local_x, size.y * 0.5), 2.0, GameColors.DANGER)


func _refresh_editor_preview() -> void:
	if not Engine.is_editor_hint() or not is_inside_tree():
		return
	set_conveyor_enabled(preview_conveyor_belt)
	queue_redraw()


func _fit_conveyor_bottom() -> void:
	if not is_node_ready() or Engine.is_editor_hint():
		return
	# The authored top and horizontal placement remain editable in the scene.
	var bottom := get_global_transform_with_canvas().affine_inverse() * get_viewport_rect().end
	conveyor_bottom.offset_bottom = maxf(bottom.y, conveyor_bottom.offset_top)


func set_reduced_enabled(enabled: bool, animate := true) -> void:
	if _reduced_enabled == enabled:
		return
	_reduced_enabled = enabled
	if _fold_tween != null and _fold_tween.is_valid():
		_fold_tween.kill()
	var target := 1.0 if enabled else 0.0
	if not animate or Engine.is_editor_hint():
		_set_fold_progress(target)
		return
	_fold_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	_fold_tween.tween_method(_set_fold_progress, _fold_progress, target, FOLD_DURATION)


func _set_fold_progress(value: float) -> void:
	_fold_progress = value
	_apply_fold()


func _apply_fold() -> void:
	if not is_node_ready() or not is_instance_valid(_reduced_background):
		return
	# Only the background folds; life icons and card layout keep their coordinates.
	var progress := 0.0 if _conveyor_enabled else _fold_progress
	var reduced_width := float(REDUCED_TEXTURE.get_width())
	regular_background.offset_right = lerpf(0.0, reduced_width - size.x, progress)
	regular_background.patch_margin_right = roundi(lerpf(18.0, 4.0, progress))
	var blend := smoothstep(0.75, 1.0, progress)
	regular_background.modulate.a = 1.0 - blend
	regular_background.visible = not _conveyor_enabled and progress < 1.0
	_reduced_background.size = Vector2(reduced_width, size.y)
	_reduced_background.modulate.a = blend
	_reduced_background.visible = not _conveyor_enabled and progress > 0.75
