@tool
class_name MenuPanelLayout
extends Control

@export_category("Panel Layout")
@export var panel_margins := Vector4(12.0, 4.0, 12.0, 12.0):
	set(value):
		panel_margins = value
		_apply_panel_margins()

var _preserving_panel_rect := false


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		preserve_panel_rect()


func apply_panel_layout() -> void:
	_apply_panel_margins()
	preserve_panel_rect()


func preserve_panel_rect() -> void:
	if _preserving_panel_rect or not is_inside_tree():
		return
	var parent_control := get_parent() as Control
	if parent_control == null or parent_control.size.x <= 0.0:
		return
	_preserving_panel_rect = true
	custom_minimum_size = Vector2.ZERO
	offset_left = position.x
	offset_top = 0.0
	offset_right = position.x
	offset_bottom = 0.0
	_preserving_panel_rect = false


func panel_body_width(
	navigation_width: float, body_separation: float, scrollbar_margin: float
) -> float:
	var horizontal_margins := panel_margins.x + panel_margins.z
	var available := size.x - horizontal_margins - navigation_width
	available -= body_separation + scrollbar_margin
	return maxf(available, 80.0)


func _apply_panel_margins() -> void:
	if not is_node_ready():
		return
	var margin := get_node_or_null("Margin") as MarginContainer
	if margin == null:
		return
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.offset_left = panel_margins.x
	margin.offset_top = panel_margins.y
	margin.offset_right = -panel_margins.z
	margin.offset_bottom = -panel_margins.w
